#!/usr/bin/env bash
# Smoke-test agent-config bootstrap. Safe to run after setup.sh.
set -eu

CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

ok() { printf 'verify-setup: OK %s\n' "$*"; PASS=$((PASS + 1)); }
bad() { printf 'verify-setup: FAIL %s\n' "$*" >&2; FAIL=$((FAIL + 1)); }
warn() { printf 'verify-setup: WARN %s\n' "$*"; }

check_file() {
  local label="$1" path="$2"
  [[ -e "$path" ]] && ok "$label" || bad "$label ($path missing)"
}

check_exec() {
  local label="$1" path="$2"
  [[ -x "$path" ]] && ok "$label" || bad "$label ($path not executable)"
}

check_exec statusline "$CONFIG_ROOT/bin/statusline.sh"
check_exec treehouse-hook "$CONFIG_ROOT/bin/treehouse-post-create.sh"
check_file claude-launcher "$CONFIG_ROOT/bin/claude-primary.sh"
check_file treehouse-user-config "$HOME/.config/treehouse/config.toml"

if command -v jq >/dev/null 2>&1; then
  ok jq
else
  bad jq
fi

export PATH="$HOME/.local/bin:$HOME/agent-config/bin:$PATH"

for tool in treehouse no-mistakes; do
  command -v "$tool" >/dev/null 2>&1 && ok "$tool" || bad "$tool"
done

if [[ -L "$CONFIG_ROOT/projects/go-code" ]]; then
  readlink -f "$CONFIG_ROOT/projects/go-code" | grep -q 'go-code-sparse' && ok projects-go-code || bad projects-go-code-target
else
  warn 'projects/go-code symlink missing (go-code-sparse not on this pod yet)'
fi

if [[ -L "$CONFIG_ROOT/projects/infra-m3db" ]]; then
  readlink -f "$CONFIG_ROOT/projects/infra-m3db" | grep -q 'infra-m3db' && ok projects-infra-m3db || bad projects-infra-m3db-target
else
  warn 'projects/infra-m3db symlink missing (infra-m3db not on this pod yet)'
fi

if [[ -f "$HOME/go-code-sparse/treehouse.toml" ]]; then
  grep -q 'max_trees = 3' "$HOME/go-code-sparse/treehouse.toml" && ok go-code-pool || bad go-code-pool
else
  warn 'go-code-sparse/treehouse.toml missing (repo not on this pod yet)'
fi

if [[ -f "$HOME/infra-m3db/treehouse.toml" ]]; then
  grep -q 'max_trees = 5' "$HOME/infra-m3db/treehouse.toml" && ok infra-m3db-pool || bad infra-m3db-pool
else
  warn 'infra-m3db/treehouse.toml missing (repo not on this pod yet)'
fi

if [[ -f "$HOME/.claude/settings.json" ]] && python3 -c "import json; json.load(open('$HOME/.claude/settings.json'))['statusLine']" >/dev/null 2>&1; then
  ok claude-statusline
else
  bad claude-statusline
fi

out="$(printf '%s' '{"workspace":{"current_dir":"/home/user/agent-config/projects/infra-m3db"},"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":12},"cost":{"total_cost_usd":0.25}}' | "$CONFIG_ROOT/bin/statusline.sh")"
[[ -n "$out" ]] && ok statusline-render || bad statusline-render

if [[ -d "$HOME/go-code-sparse" ]]; then
  (cd "$HOME/go-code-sparse" && treehouse status >/dev/null 2>&1) && ok treehouse-go-code || bad treehouse-go-code
fi

printf 'verify-setup: %s passed, %s failed\n' "$PASS" "$FAIL"
exit "$FAIL"
