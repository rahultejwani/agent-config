#!/usr/bin/env bash
# Launch Claude Code with devpod agent defaults.
set -eu
ROOT="${FM_HOME:-$HOME/firstmate}"
export CLAUDE_CODE_AUTO_COMPACT_WINDOW="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-400000}"
export FM_HOME="$ROOT"
exec claude \
  --dangerously-skip-permissions \
  --autocompact 400000 \
  --model sonnet[1m] \
  --effort medium \
  "$@"
