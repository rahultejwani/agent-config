#!/usr/bin/env bash
# Idempotent devpod bootstrap for ~/agent-config. Safe on every restart.
set -eu

CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONFIG_HOME="${AGENT_CONFIG_HOME:-$CONFIG_ROOT}"
CLAUDE_DIR="$AGENT_CONFIG_HOME/.claude"
CURSOR_RULES="$HOME/.cursor/rules"

log() { printf 'agent-config: %s\n' "$*"; }

ensure_local_bin_path() {
  export PATH="$HOME/.local/bin:$PATH"
  local line='export PATH="$HOME/.local/bin:$PATH"'
  local marker='.local/bin'
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [[ -f "$rc" ]] || touch "$rc"
    grep -Fq '.local/bin' "$rc" || {
      printf '\n# user-local binaries (treehouse, no-mistakes)\n%s\n' "$line" >> "$rc"
      log "appended ~/.local/bin to $(basename "$rc")"
    }
  done
}

load_fork_env() {
  local repo_env="$CONFIG_ROOT/no-mistakes/fork.env"
  local override_env="$HOME/.agent-config/no-mistakes-fork.env"
  if [[ -f "$repo_env" ]]; then
    # shellcheck disable=SC1090
    source "$repo_env"
    log "loaded no-mistakes fork env from $repo_env"
  fi
  if [[ -f "$override_env" ]]; then
    # shellcheck disable=SC1090
    source "$override_env"
    log "applied no-mistakes fork override from $override_env"
  fi
}

install_no_mistakes_config() {
  local dest="$HOME/.no-mistakes/config.yaml"
  local template="$CONFIG_ROOT/no-mistakes/config.yaml"
  [[ -f "$template" ]] || return 0
  mkdir -p "$HOME/.no-mistakes"
  if [[ ! -f "$dest" ]]; then
    cp "$template" "$dest"
    log "installed default ~/.no-mistakes/config.yaml"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$template" "$dest" <<'PY'
import sys
from pathlib import Path
import yaml

template = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
current = yaml.safe_load(Path(sys.argv[2]).read_text()) or {}

def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        elif key not in dst:
            dst[key] = value

merge(current, template)
Path(sys.argv[2]).write_text(yaml.dump(current, default_flow_style=False, sort_keys=False))
PY
    log "merged missing keys into ~/.no-mistakes/config.yaml"
  fi
}

ensure_no_mistakes() {
  load_fork_env
  if [[ -n "${NO_MISTAKES_FORK:-}" ]]; then
    log "installing no-mistakes from fork: $NO_MISTAKES_FORK"
    NO_MISTAKES_FORK="$NO_MISTAKES_FORK" \
      NO_MISTAKES_FORK_BRANCH="${NO_MISTAKES_FORK_BRANCH:-main}" \
      NO_MISTAKES_SRC="${NO_MISTAKES_SRC:-$HOME/src/no-mistakes}" \
      "$CONFIG_ROOT/bin/install-no-mistakes-fork.sh"
    install_no_mistakes_config
    return 0
  fi
  if command -v no-mistakes >/dev/null 2>&1; then
    log "no-mistakes already installed"
    install_no_mistakes_config
    return 0
  fi
  log "installing no-mistakes from upstream release..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
  command -v no-mistakes >/dev/null 2>&1 || {
    echo "agent-config: no-mistakes install failed" >&2
    exit 1
  }
  install_no_mistakes_config
}

ensure_layout() {
  mkdir -p "$AGENT_CONFIG_HOME/bin" "$CLAUDE_DIR"
  ln -sfn AGENTS.md "$AGENT_CONFIG_HOME/CLAUDE.md"
}

install_githooks() {
  local hook="$CONFIG_ROOT/githooks/commit-msg"
  [[ -f "$hook" ]] || return 0
  mkdir -p "$CONFIG_ROOT/.git/hooks"
  install -m 0755 "$hook" "$CONFIG_ROOT/.git/hooks/commit-msg"
  log "installed .git/hooks/commit-msg (strip AI co-author trailers)"
}

ensure_projects() {
  local projects="$AGENT_CONFIG_HOME/projects"
  mkdir -p "$projects"
  if [[ -d "$HOME/go-code-sparse" ]]; then
    ln -sfn "$HOME/go-code-sparse" "$projects/go-code"
    ln -sfn "$HOME/go-code-sparse" "$projects/go-code-sparse"
  fi
  if [[ -d "$HOME/infra-m3db" ]]; then
    ln -sfn "$HOME/infra-m3db" "$projects/infra-m3db"
  fi
}

install_claude_settings() {
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$CONFIG_ROOT/claude-settings.json" "$CLAUDE_DIR/settings.local.json" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
dest = Path(sys.argv[2])
incoming = json.loads(src.read_text())
if dest.exists():
    current = json.loads(dest.read_text())
    for key, value in incoming.items():
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            current[key].update(value)
        else:
            current[key] = value
    dest.write_text(json.dumps(current, indent=2) + "\n")
else:
    dest.write_text(json.dumps(incoming, indent=2) + "\n")
PY
  else
    cp "$CONFIG_ROOT/claude-settings.json" "$CLAUDE_DIR/settings.local.json"
  fi

  local user_settings="$HOME/.claude/settings.json"
  mkdir -p "$HOME/.claude"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$CONFIG_ROOT/claude-settings.json" "$user_settings" <<'PY'
import json
import sys
from pathlib import Path

src = Path(sys.argv[1])
dest = Path(sys.argv[2])
incoming = json.loads(src.read_text())
keep = {"env", "statusLine"}
incoming = {k: v for k, v in incoming.items() if k in keep}
if dest.exists():
    current = json.loads(dest.read_text())
    for key, value in incoming.items():
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            current[key].update(value)
        else:
            current[key] = value
    dest.write_text(json.dumps(current, indent=2) + "\n")
else:
    dest.write_text(json.dumps(incoming, indent=2) + "\n")
PY
    log "merged Claude user settings (statusLine, env)"
  fi
}

install_tool_scripts() {
  chmod 0755 \
    "$CONFIG_ROOT/bin/statusline.sh" \
    "$CONFIG_ROOT/bin/treehouse-post-create.sh" \
    "$CONFIG_ROOT/bin/verify-setup.sh"
}

ensure_treehouse() {
  if command -v treehouse >/dev/null 2>&1; then
    log "treehouse already installed ($(treehouse --version 2>/dev/null || echo ok))"
    return 0
  fi
  log "installing treehouse..."
  curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
  command -v treehouse >/dev/null 2>&1 || {
    echo "agent-config: treehouse install failed" >&2
    exit 1
  }
}

install_treehouse_config() {
  local dest="$HOME/.config/treehouse/config.toml"
  local template="$CONFIG_ROOT/treehouse/config.toml"
  [[ -f "$template" ]] || return 0
  mkdir -p "$HOME/.config/treehouse"
  sed "s|\$HOME|$HOME|g" "$template" > "$dest"
  log "installed $dest"
}

write_repo_treehouse_config() {
  local repo="$1" max="$2"
  [[ -d "$repo/.git" || -f "$repo/.git" ]] || return 0
  cat > "$repo/treehouse.toml" <<TOML
# Managed by agent-config setup.sh — pool size for parallel agent worktrees.
max_trees = $max
TOML
  log "wrote $repo/treehouse.toml (max_trees=$max)"
}

ensure_repo_treehouse_configs() {
  write_repo_treehouse_config "$HOME/go-code-sparse" 3
  write_repo_treehouse_config "$HOME/infra-m3db" 5
}

install_launcher() {
  local dest="$AGENT_CONFIG_HOME/bin/claude-primary.sh"
  if [[ "$CONFIG_ROOT/bin/claude-primary.sh" -ef "$dest" ]]; then
    chmod 0755 "$dest"
  else
    install -m 0755 "$CONFIG_ROOT/bin/claude-primary.sh" "$dest"
  fi
  ln -sfn claude-primary.sh "$AGENT_CONFIG_HOME/bin/claude"
}

install_cursor_rules() {
  if [[ -f "$CONFIG_ROOT/cursor/agent.mdc" ]]; then
    mkdir -p "$CURSOR_RULES"
    cp "$CONFIG_ROOT/cursor/agent.mdc" "$CURSOR_RULES/agent.mdc"
  fi
}

ensure_path() {
  local line='export PATH="$HOME/agent-config/bin:$PATH"'
  local marker='agent-config/bin'
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [[ -f "$rc" ]] || touch "$rc"
    if grep -Fq 'firstmate/bin' "$rc"; then
      sed -i '/firstmate\/bin/d' "$rc"
      log "removed legacy firstmate PATH from $(basename "$rc")"
    fi
    if ! grep -Fq "$marker" "$rc"; then
      printf '\n# agent-config\n%s\n' "$line" >> "$rc"
      log "appended PATH to $(basename "$rc")"
    fi
  done
}

ensure_no_mistakes
ensure_local_bin_path
ensure_layout
install_githooks
ensure_projects
install_tool_scripts
ensure_treehouse
install_treehouse_config
ensure_repo_treehouse_configs
install_launcher
install_claude_settings
install_cursor_rules
ensure_path
if [[ -f "$CONFIG_ROOT/shell/setup.sh" ]]; then
  bash "$CONFIG_ROOT/shell/setup.sh"
fi
chmod 0755 "$CONFIG_ROOT/bin/verify-setup.sh" 2>/dev/null || true
if "$CONFIG_ROOT/bin/verify-setup.sh"; then
  log "verification passed"
else
  echo "agent-config: verification reported failures (see above)" >&2
  exit 1
fi
log "ready at $AGENT_CONFIG_HOME"
