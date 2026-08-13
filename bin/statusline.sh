#!/usr/bin/env bash
# Claude Code status line — project, ticket, branch, model, context, cost.
set -eu

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

cwd="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
model="$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "?"')"
ctx_pct="$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')"
cost="$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')"
rate_reset="$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')"

project="?"
branch="?"
ticket=""

if [[ -n "$cwd" && -d "$cwd" ]]; then
  case "$cwd" in
    *go-code-sparse*|*/projects/go-code|*/projects/go-code-sparse)
      project="go-code"
      ;;
    *infra-m3db*|*/projects/infra-m3db)
      project="infra-m3db"
      ;;
    *agent-config*)
      project="agent-config"
      ;;
    *)
      project="$(basename "$cwd")"
      ;;
  esac

  if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
    if [[ -z "$branch" ]]; then
      branch="$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo detached)"
    fi
    if [[ "$branch" =~ (MET-[0-9]+) ]]; then
      ticket="${BASH_REMATCH[1]}"
    fi
  fi
fi

ctx_label=""
if [[ -n "$ctx_pct" && "$ctx_pct" != "null" ]]; then
  pct_int="${ctx_pct%.*}"
  if (( pct_int >= 80 )); then
    ctx_label=$'\033[31m'"ctx ${pct_int}%"$'\033[0m'
  elif (( pct_int >= 50 )); then
    ctx_label=$'\033[33m'"ctx ${pct_int}%"$'\033[0m'
  else
    ctx_label="ctx ${pct_int}%"
  fi
fi

parts=("$project")
[[ -n "$ticket" ]] && parts+=("$ticket")
[[ -n "$branch" && "$branch" != "?" ]] && parts+=("$branch")
parts+=("$model")
[[ -n "$ctx_label" ]] && parts+=("$ctx_label")
parts+=("$(printf '$%.2f' "$cost")")

if [[ -n "$rate_reset" && "$rate_reset" != "null" ]]; then
  if reset_ts="$(date -d "$rate_reset" +%s 2>/dev/null)"; then
    now_ts="$(date +%s)"
    mins_left=$(( (reset_ts - now_ts) / 60 ))
    if (( mins_left > 0 )); then
      parts+=("block ${mins_left}m")
    fi
  fi
fi

(IFS=' │ '; printf '%s' "${parts[*]}")
