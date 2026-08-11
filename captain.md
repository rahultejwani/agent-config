# Captain preferences

## Writing documents for the captain

- **Be precise and short.** Cut every sentence that is not load-bearing. No throat-clearing, no restating the same point in different words.
- **Simple language.** Anyone picking the document up should follow it without insider context. Plain words over jargon; explain a term the first time it is unavoidable.
- **Prefer tables, lists, and short sections** over long prose paragraphs.
- **Never guess to fill a gap.** Where the answer is not actually known, ask the captain instead of writing a plausible-sounding placeholder. An explicit open question in the document is correct; an invented detail presented as fact is not.
- Applies to Google Docs, design docs, plans, and reports. This is about the captain's own documents, not commit messages or PR text (those follow the delivery rules below).

## Uber devpod workflow

- Work on go-code through the sparse git-bzl checkout (`projects/go-code` → `~/go-code-sparse`), not the full `~/go-code` tree.
- Before build or test in a sparse tree, run `bin/git-bzl refresh` (and `bin/git-bzl add` only when new targets are needed).
- Publish stacked PRs with `arh` on `github.uberinternal.com`; do not push to public GitHub.
- For `gh` / `gh-axi` on this devpod, use uSSO bearer auth against uberinternal (not `gh auth login --web`).

## Delivery and review

- go-code ships through no-mistakes: full validation pipeline, green CI, captain merge approval.
- Escalate destructive, irreversible, or security-sensitive choices; routine gates stay within task scope.
- **No AI attribution in git or PR text:** never add `Co-Authored-By`, `Made with Cursor`, `Generated with`, Bugbot, or similar markers to commit messages or PR titles/bodies. Commits and PR descriptions read as normal human engineering work.
- Before landing, spot-check the stack: `git log --format=%B` on the branch and the PR body in arh/gh.

## Linear (task tracking)

- Default team: **MET** — [linear.app/uber/team/MET/overview](https://linear.app/uber/team/MET/overview). Assume `MET-####` issue ids unless the captain names another team.
- At intake, collect **Linear issue** (id or URL) when the work maps to an existing ticket; record it in notes when useful; prefer `MET-####` in branch or PR title when useful.
- At intake, **ask for the Linear project** when dispatching ship work if the captain did not name one (MET team has multiple projects — do not guess).
- **ARH propagation (automatic):** when the captain supplies a Linear id such as `MET-1234`, translate it to **`LINEAR-MET-1234`** for Arrowhead without asking again. Include that token in the oldest commit message under `Jira Issues:` (ARH's structured publish format) and may repeat it in the branch name.
- On PR ready, captain updates Linear (In Review / Done); surface the PR URL, not Linear state changes, unless explicitly asked.

## ARH (uberinternal stacks)

- Publish and merge through `arh` from `go-code-sparse`, not raw `gh pr create` alone.
- **Branch names start with the captain's username: `rahul.tejwani/...`** (e.g. `rahul.tejwani/m3db-block-bytes-metric`).
- Commit messages for ship work use ARH's structured format; the `Jira Issues:` line carries the propagated `LINEAR-MET-####` token when a Linear id was given at intake.
- **`~/firstmate/data/pr-conventions.md` is the canonical worker-facing PR contract.** Do not restate its rules inline — one source of truth, updated in place.

## Model expectations

- Primary Claude session: Sonnet 1M (`sonnet[1m]`), medium effort, 400k auto-compact window, bypass-permissions mode. Launch with `bin/claude-primary.sh` or `bin/claude` from `~/firstmate` (prepend `~/firstmate/bin` to PATH). Do not rely on Cursor chat for the primary — Cursor shows its own ~200k limit.
- Hard or ambiguous work: Claude Opus or Fable at high/xhigh effort.
