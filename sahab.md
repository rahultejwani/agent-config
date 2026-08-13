# Sahab preferences

## Writing documents

- **Be precise and short.** Cut every sentence that is not load-bearing. No throat-clearing, no restating the same point in different words.
- **Simple language.** Anyone picking the document up should follow it without insider context. Plain words over jargon; explain a term the first time it is unavoidable.
- **Prefer tables, lists, and short sections** over long prose paragraphs.
- **Never guess to fill a gap.** Where the answer is not actually known, ask sahab instead of writing a plausible-sounding placeholder. An explicit open question in the document is correct; an invented detail presented as fact is not.
- Applies to Google Docs, design docs, plans, and reports — not commit messages or PR text (those follow the delivery rules below).

## Projects

| Project | Checkout | Delivery path |
|---|---|---|
| go-code | `projects/go-code` (sparse git-bzl) | no-mistakes → arh → sahab merge |
| infra-m3db | `projects/infra-m3db` | no-mistakes → sahab merge |

## Uber devpod workflow

- Work on go-code through the sparse git-bzl checkout (`projects/go-code` → `~/go-code-sparse`), not the full `~/go-code` tree.
- Before build or test in a sparse tree, run `bin/git-bzl refresh` (and `bin/git-bzl add` only when new targets are needed).
- Never edit `BUILD.bazel` or other build files to fix build or lint drift unless the change is in the PR scope — try `git-bzl refresh` first.
- To rebase onto main: checkout `main`, sync with `origin/main`, checkout the feature branch, then `arh rebase` (prefer over raw `git rebase`; `arh rebase --sync` is faster when syncing main is needed).
- Publish stacked PRs with `arh` on `github.uberinternal.com`; do not push to public GitHub.
- For `gh` / `gh-axi` on this devpod, use uSSO bearer auth against uberinternal (not `gh auth login --web`).

## go-code delivery

- **New-line coverage:** keep modified-line coverage above **85%** on every change (target 90%+). Run `bazel coverage` on touched packages before publish.
1. Collect Linear issue (`MET-####`) and project at intake when missing.
2. Translate `MET-1234` → `LINEAR-MET-1234` in the oldest commit `Jira Issues:` line; put `[MET-1234]` in the PR summary.
3. Branch names: `rahul.tejwani/<short-description>`.
4. Publish with `arh` from the sparse checkout — not bare `gh pr create`, not public GitHub.
5. Run `/no-mistakes` (or `no-mistakes axi run`) before reporting work complete.
6. Spot-check before done: `git log --format=%B main..HEAD` and the published PR body.

## Delivery and review

- go-code validates through no-mistakes: full validation pipeline, green CI, sahab merge approval.
- Escalate destructive, irreversible, or security-sensitive choices; routine gates stay within task scope.
- **No AI attribution in git or PR text:** never add `Co-Authored-By`, `Made with Cursor`, `Generated with`, Bugbot, or similar markers to commit messages or PR titles/bodies.
- Before landing, spot-check the stack: `git log --format=%B` on the branch and the PR body in arh/gh.

## Linear (task tracking)

- Default team: **MET** — [linear.app/uber/team/MET/overview](https://linear.app/uber/team/MET/overview). Assume `MET-####` issue ids unless sahab names another team.
- At intake, collect **Linear issue** (id or URL) when the work maps to an existing ticket; prefer `MET-####` in branch or PR title when useful.
- At intake, **ask for the Linear project** when dispatching PR work if sahab did not name one (MET team has multiple projects — do not guess).
- **ARH propagation (automatic):** when sahab supplies a Linear id such as `MET-1234`, translate it to **`LINEAR-MET-1234`** for Arrowhead without asking again. Include that token in the oldest commit message under `Jira Issues:` and may repeat it in the branch name.
- On PR ready, sahab updates Linear (In Review / Done); surface the PR URL, not Linear state changes, unless explicitly asked.

## ARH (uberinternal stacks)

- Publish and merge through `arh` from `go-code-sparse`, not raw `gh pr create` alone.
- **Branch names start with `rahul.tejwani/...`** (e.g. `rahul.tejwani/m3db-block-bytes-metric`).
- Commit messages for PR work use ARH's structured format; the `Jira Issues:` line carries the propagated `LINEAR-MET-####` token when a Linear id was given at intake.
- **`~/agent-config/pr-conventions.md` is the canonical PR contract.** Do not restate its rules inline — one source of truth, updated in place.

## Model expectations

- Primary Claude session: Sonnet 1M (`sonnet[1m]`), medium effort, 400k auto-compact, bypass-permissions mode. Launch with `bin/claude-primary.sh` or `bin/claude` from `~/agent-config` (prepend `~/agent-config/bin` to PATH). Do not rely on Cursor chat for the primary — Cursor shows its own ~200k limit.
- Hard or ambiguous work: Claude Opus or Fable at high/xhigh effort.
