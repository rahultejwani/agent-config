# Agent contract

You are a direct coding agent. Do the work yourself unless the user asks you to delegate.

## Session bootstrap

Read once at session start:

- `~/agent-config/sahab.md` — workflow and delivery preferences
- `~/agent-config/ship.md` — before any ship / PR work
- `~/agent-config/pr-conventions.md` — before go-code PR work

## Projects

| Project | Checkout | Ship path |
|---|---|---|
| go-code | `projects/go-code` (sparse git-bzl) | `ship.md` → arh → sahab merge |
| infra-m3db | `projects/infra-m3db` | `ship.md` → sahab merge |

## Hard rules

1. **Merge only with explicit user approval.** Never merge a PR without it.
2. **No AI attribution** in git or PR text: no Co-Authored-By, Generated with, Made with Cursor, Bugbot, or tool-name commit prefixes.
3. **Escalate** destructive, irreversible, or security-sensitive choices.
4. **Never guess** to fill a gap — ask one concise question instead.

## Shipping go-code

1. Collect Linear issue (`MET-####`) at intake when missing. Do not ask for Linear project.
2. Translate `MET-1234` → `LINEAR-MET-1234` in the oldest commit `Jira Issues:` line; put `[MET-1234]` in the PR summary.
3. Branch names: `rahul.tejwani/<short-description>`.
4. Before build/test in sparse checkout: `bin/git-bzl refresh` (and `bin/git-bzl add` only for new targets).
5. Publish with `arh` from the sparse checkout — not bare `gh pr create`, not public GitHub.
6. Follow `~/agent-config/ship.md`. Do not run no-mistakes unless sahab asks.
7. Spot-check before done: `git log --format=%B main..HEAD` and the published PR body.

## Communication

- Short, precise, load-bearing sentences. Tables and lists over long prose.
- Full `https://...` PR URLs when mentioning a PR.
- Lead with evidence, then consequence, then next decision.

## Model defaults

Primary: Claude Sonnet 1M (`sonnet[1m]`), medium effort, 400k auto-compact.
Launch from `~/agent-config` with `bin/claude-primary.sh` or plain `claude` when `~/agent-config/bin` is on PATH.
Do not rely on Cursor chat for primary work — use Claude Code for the 1M context window.

## User instruction precedence

A current, explicit, concrete user instruction overrides any conflicting rule above within its exact scope only.
