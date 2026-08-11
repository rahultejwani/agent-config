#!/usr/bin/env bash
# Idempotent apply of agent-config onto ~/firstmate. Safe on every devpod restart.
set -eu

CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FM_HOME="${FM_HOME:-$HOME/firstmate}"
DATA_DIR="$FM_HOME/data"
CLAUDE_DIR="$FM_HOME/.claude"
CURSOR_RULES="$HOME/.cursor/rules"

log() { printf 'agent-config: %s\n' "$*"; }

ensure_no_mistakes() {
  if command -v no-mistakes >/dev/null 2>&1; then
    log "no-mistakes already installed ($(no-mistakes version 2>/dev/null | head -1 || echo present))"
    return 0
  fi
  log "installing no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
  command -v no-mistakes >/dev/null 2>&1 || {
    echo "agent-config: no-mistakes install failed" >&2
    exit 1
  }
}

ensure_firstmate_layout() {
  mkdir -p "$DATA_DIR" "$CLAUDE_DIR" "$FM_HOME/bin"
}

install_files() {
  cp "$CONFIG_ROOT/AGENTS.md" "$FM_HOME/AGENTS.md"
  ln -sfn AGENTS.md "$FM_HOME/CLAUDE.md"

  cp "$CONFIG_ROOT/captain.md" "$DATA_DIR/captain.md"
  cp "$CONFIG_ROOT/pr-conventions.md" "$DATA_DIR/pr-conventions.md"

  install -m 0755 "$CONFIG_ROOT/bin/claude-primary.sh" "$FM_HOME/bin/claude-primary.sh"
  ln -sfn claude-primary.sh "$FM_HOME/bin/claude"
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

  mkdir -p "$HOME/.claude/skills"
  if command -v no-mistakes >/dev/null 2>&1 && [[ -d "$HOME/.claude/skills/no-mistakes" ]]; then
    log "no-mistakes skill present"
  elif [[ -f "$HOME/.claude/skills/no-mistakes/SKILL.md" ]]; then
    log "no-mistakes skill present"
  else
    log "no-mistakes skill will appear after first no-mistakes init in a repo"
  fi
}

install_cursor_rules() {
  if [[ -f "$CONFIG_ROOT/cursor/agent.mdc" ]]; then
    mkdir -p "$CURSOR_RULES"
    cp "$CONFIG_ROOT/cursor/agent.mdc" "$CURSOR_RULES/agent.mdc"
  fi
}

ensure_path() {
  local line='export PATH="$HOME/firstmate/bin:$PATH"'
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    [[ -f "$rc" ]] || touch "$rc"
    if ! grep -Fq 'firstmate/bin' "$rc"; then
      printf '\n# agent-config\n%s\n' "$line" >> "$rc"
      log "appended PATH to $(basename "$rc")"
    fi
  done
}

ensure_no_mistakes
ensure_firstmate_layout
install_files
install_claude_settings
install_cursor_rules
ensure_path
log "applied to $FM_HOME"
