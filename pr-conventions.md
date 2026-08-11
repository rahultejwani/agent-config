# PR conventions (all projects, all workers)

Canonical worker-facing contract. Briefs reference this file rather than
restating it. The captain owns the rules; update this file in agent-config.

## Linear id — two forms, both required, never interchanged

| Where | Form | Example |
|---|---|---|
| Oldest commit body, `Jira Issues:` line | `LINEAR-MET-####` | `Jira Issues: LINEAR-MET-556` |
| PR summary line, appended at the end | `[MET-####]` | `[dbnode] Add block-bytes histogram metric [MET-556]` |

Do not put `LINEAR-MET-####` in the summary. Do not drop it from the commit body.

## Commit messages

- **Every commit gets a real body.** Explain *why*, not a restatement of the
  subject. An empty body on a follow-up commit is a defect — arh publishes the
  whole stack and a blank body is permanent.
- Wrap bodies at 72 characters.
- No tool-name prefixes in subjects (`no-mistakes(review):`, `fix:` from a
  linter, etc.). Commits read as normal human engineering work.

## PR description

- Describe the **net work across all commits**, not a commit-by-commit
  changelog. A reader should understand what the branch does without opening
  the diff.
- Cover: what changed, why that approach, and any non-obvious constraint or
  trade-off.
- **Fill the Test Plan section** with what was actually run, not what could be
  run. arh leaves it blank by default.

## Branch names

Start with the captain's username: `rahul.tejwani/<short-description>`.
Never a bare `fm/` prefix.

## Absolute constraints

- **No AI attribution** anywhere in git or PR text: no `Co-Authored-By`, no
  `Generated with`, no `Made with Cursor`, no Bugbot markers, no tool names.
- Publish with `arh` from the sparse checkout. Not `arc diff`, not bare
  `gh pr create`. Consult current `arh --help` rather than assuming flags.
- Never push to public GitHub; uberinternal only.

## Before reporting done

Verify, do not assume:

```
git log --format=%B main..HEAD    # every commit has a body; oldest has Jira Issues:
```

Then re-read the published PR body and confirm the summary carries `[MET-####]`
and the Test Plan is filled.
