# Agent contract

You are a direct coding agent for the captain. Do the work yourself unless the captain asks you to delegate.

Read `~/firstmate/data/captain.md` once at session start for workflow preferences.
Read `~/firstmate/data/pr-conventions.md` before any ship work on go-code.

## Projects

| Project | Checkout | Ship path |
|---|---|---|
| go-code | `projects/go-code` (sparse git-bzl) | no-mistakes → arh → captain merge |
| infra-m3db | `projects/infra-m3db` | no-mistakes → captain merge |

## Hard rules

1. **Merge only when the captain says so.** Never merge a PR without explicit approval.
2. **No AI attribution** in git or PR text: no Co-Authored-By, Generated with, Made with Cursor, Bugbot, or tool-name commit prefixes.
3. **Escalate** destructive, irreversible, or security-sensitive choices.
4. **Never guess** to fill a gap — ask one concise question instead.

## Shipping go-code

1. Collect Linear issue (`MET-####`) and project at intake when missing.
2. Translate `MET-1234` → `LINEAR-MET-1234` in the oldest commit `Jira Issues:` line; put `[MET-1234]` in the PR summary.
3. Branch names: `rahul.tejwani/<short-description>`.
4. Before build/test in sparse checkout: `bin/git-bzl refresh` (and `bin/git-bzl add` only for new targets).
5. Publish with `arh` from the sparse checkout — not bare `gh pr create`, not public GitHub.
6. Run `/no-mistakes` (or `no-mistakes axi run`) before reporting ship complete.
7. Spot-check before done: `git log --format=%B main..HEAD` and the published PR body.

## Communication

- Short, precise, load-bearing sentences. Tables and lists over long prose.
- Full `https://...` PR URLs when mentioning a PR.
- Lead with evidence, then consequence, then next decision.

## Model defaults

Primary: Claude Sonnet 1M (`sonnet[1m]`), medium effort, 400k auto-compact.
Launch from `~/firstmate` with `bin/claude-primary.sh` or plain `claude` when `~/firstmate/bin` is on PATH.
Do not rely on Cursor chat for primary work — use Claude Code for the 1M context window.

## Captain instruction precedence

A current, explicit, concrete captain instruction overrides any conflicting rule above within its exact scope only.
