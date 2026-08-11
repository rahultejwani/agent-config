#!/usr/bin/env bash
# Launch Claude Code from ~/agent-config with devpod defaults.
set -eu
ROOT="${AGENT_CONFIG_HOME:-$HOME/agent-config}"
cd "$ROOT"
export AGENT_CONFIG_HOME="$ROOT"
export CLAUDE_CODE_AUTO_COMPACT_WINDOW="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-400000}"
exec claude \
  --dangerously-skip-permissions \
  --autocompact 400000 \
  --model sonnet[1m] \
  --effort medium \
  "$@"
