# Ship — what to do for every change

Canonical ship path. Do not run no-mistakes unless sahab says `/no-mistakes` or “run no-mistakes”.

Read `~/agent-config/pr-conventions.md` before commit or PR. Do not copy those rules here.

## Intake

- Linear id (`MET-####`) if the work maps to a ticket. Ask once if missing.
- Do **not** ask for Linear project. The ticket already has it.
- `MET-1234` → oldest commit `Jira Issues: LINEAR-MET-1234`. PR summary ends with `[MET-1234]`.

## Default path

1. Classify hot path (below). If unsure, **stop and ask** before writing benches or fuzzers.
2. Implement on `rahul.tejwani/<short-description>`.
3. When code is ready, start **in the same turn**:
   - Main: local validate
   - Not hot: Reviewer A only — GPT-5.6 sol (`gpt-5.6-sol-high`)
   - Hot: Reviewer A + Reviewer B (Opus 5, `claude-opus-5-thinking-high`) + bench/fuzz below
4. Collate the review(s). Fix what is clear. If findings conflict or the intent is unclear, **summarize and ask** — include the flow you followed and the original intent. Do not pick a side.
5. Commit (only if asked, or as part of an explicit ship request).
6. Publish with `arh` from the sparse checkout.
7. Stop. Sahab merges.

## Hot path

A change is **hot path** if it runs per datapoint, per series, per fetch, or per ingest/aggregate window on a live query or write path.

| Hot (treat as yes) | Not hot |
|---|---|
| Query execute / pipeline / fetch / pushdown | Docs, rules, dashboards |
| Aggregator / collector ingest, encode, merge | Handler wiring, config, KV, crane |
| Sketch merge, percentile, annotation encode | Tests-only, generated BUILD |
| Per-series or per-step loops in `pkg/ts`, `pkg/tsdb`, `pkg/storage` | One-off tools |

If the diff touches both, treat the whole change as hot path.

**If hot path:**

1. Add or extend a **benchmark** on the changed function or the nearest existing `*_benchmark_test.go`. Report before/after if the change is meant to be faster or allocation-neutral.
2. Add **fuzzing for accuracy** when the change can silently return a wrong number: merge, encode/decode, quantile, consolidation, tag grouping, histogram math. Skip fuzz if the change cannot affect numeric or merge correctness (say so in the Test Plan).

If in doubt whether it is hot path, ask. Do not invent a bench “just in case”.

## Review

Launch reviewer(s) as **background subagents** while local validate runs. They read the diff only. They do not edit, commit, or publish.

Prompt each with: the user intent, the file list, “hot path: yes/no”, and “findings only — no drive-by refactors”.

| Path | Reviewers | Extra checks |
|---|---|---|
| Not hot | GPT-5.6 sol only (`gpt-5.6-sol-high`) | None — no bench, no fuzz, no Opus |
| Hot | GPT-5.6 sol **and** Opus 5 (`claude-opus-5-thinking-high`) | Bench + fuzz rules in **Hot path** above |

| Lane | When | Model | Job |
|---|---|---|---|
| Main | always | this agent | `git-bzl` / gazelle / targeted `bazel test` (+ bench/fuzz if hot) |
| Review A | always | `gpt-5.6-sol-high` | Bugs, wrong semantics, missing tests, hot-path cost |
| Review B | hot path only | `claude-opus-5-thinking-high` | Same prompt as A, independent |

Do not launch Review B on a not-hot change.

### Collate

| Case | Action |
|---|---|
| One reviewer (not hot), finding is a real bug/test gap matching intent | Fix, then re-run that reviewer. |
| One reviewer (not hot), finding is style/drive-by or unclear vs intent | Do **not** guess. Summarize and ask. |
| Both agree (hot) | Implement the fix, then re-run **only** the failed lane (tests or the reviewers). |
| One finding, other silent (hot) | Implement if it matches intent and is a real bug/test gap. Else ask. |
| Contradict or unclear vs intent | Do **not** guess. Short summary: finding A, finding B, original intent, what you would do. Ask. |

Do not `arh` until collation is done (fixes landed, or sahab answered).

## Local validate

Run only what the change touched. Never `bazel build //...` or `bazel test //...`. Never gazelle the whole repo.

| Change | Command |
|---|---|
| Sparse checkout, before first build/test | `bin/git-bzl refresh` |
| New Bazel targets | `bin/git-bzl add` those targets only |
| Go imports added/removed | `bin/gazelle <package-dir>` from repo root |
| Go library/test | `bazel test //path/to/pkg:go_default_test` |
| Hot-path bench | `bazel test //path/to/pkg:go_default_test --test_arg=-test.bench=... --test_arg=-test.benchtime=...` as the package already does |
| Docs / rules / comments only | no Bazel |

If a leftover no-mistakes run owns the branch (`pipeline_owned`), abort it before committing: `no-mistakes axi abort`. Do not wait for it.

## Done check

```
git log --format=%B main..HEAD
```

Every commit has a body. Oldest has `Jira Issues: LINEAR-MET-####`. Published PR summary has `[MET-####]`. Test Plan lists what you actually ran, GPT-5.6 review, and — if hot path — Opus 5 plus bench/fuzz.

## Explicitly out

| Skip | Unless |
|---|---|
| `no-mistakes axi run` | sahab invoked `/no-mistakes` |
| Waiting on CI in chat | sahab asked to watch CI |
| Merge | sahab said merge |
| Linear project question | never — it is on the ticket |
| Public GitHub / bare `gh pr create` | never |
