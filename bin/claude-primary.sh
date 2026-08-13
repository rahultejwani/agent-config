#!/usr/bin/env bash
# Launch Claude Code from ~/agent-config with devpod defaults.
set -eu
ROOT="${AGENT_CONFIG_HOME:-$HOME/agent-config}"
cd "$ROOT"
export AGENT_CONFIG_HOME="$ROOT"
export CLAUDE_CODE_AUTO_COMPACT_WINDOW="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-400000}"
# Resolve the real Claude Code binary — not ~/agent-config/bin/claude (this wrapper).
if [[ -z "${CLAUDE_CODE_BIN:-}" ]]; then
  _path="${PATH//:$HOME\/agent-config\/bin:/}"
  _path="${_path/#$HOME\/agent-config\/bin:/}"
  CLAUDE_CODE_BIN="$(PATH="$_path" command -v claude)"
fi
exec "$CLAUDE_CODE_BIN" \
  --dangerously-skip-permissions \
  --autocompact 400000 \
  --model sonnet[1m] \
  --effort medium \
  "$@"
