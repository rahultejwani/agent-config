#!/usr/bin/env bash
# Idempotent devpod bootstrap for ~/agent-config. Safe on every restart.
set -eu

CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONFIG_HOME="${AGENT_CONFIG_HOME:-$CONFIG_ROOT}"
CLAUDE_DIR="$AGENT_CONFIG_HOME/.claude"
CURSOR_RULES="$HOME/.cursor/rules"

log() { printf 'agent-config: %s\n' "$*"; }

ensure_no_mistakes() {
  if command -v no-mistakes >/dev/null 2>&1; then
    log "no-mistakes already installed"
    return 0
  fi
  log "installing no-mistakes..."
  curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
  command -v no-mistakes >/dev/null 2>&1 || {
    echo "agent-config: no-mistakes install failed" >&2
    exit 1
  }
}

ensure_layout() {
  mkdir -p "$AGENT_CONFIG_HOME/bin" "$CLAUDE_DIR"
  ln -sfn AGENTS.md "$AGENT_CONFIG_HOME/CLAUDE.md"
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
}

install_launcher() {
  install -m 0755 "$CONFIG_ROOT/bin/claude-primary.sh" "$AGENT_CONFIG_HOME/bin/claude-primary.sh"
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
ensure_layout
install_launcher
install_claude_settings
install_cursor_rules
ensure_path
log "ready at $AGENT_CONFIG_HOME"
