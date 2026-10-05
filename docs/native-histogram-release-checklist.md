# Native histogram production release checklist

Status tracker for taking native histograms live. Update the checkboxes and
the log at the bottom as steps land. Last verified 2026-10-01.

Background and lookup commands: `docs/m3db-odin-reference.md`.

## A. Land the stack

- [x] #303472 merge (names, namespaces, shared etcd) — on main as `67822d6f54825`
- [x] #304566 merge (glacier ingester wiring, both switches off) — on main as `bf348bd8715e9`
- [ ] CD rolls glacier + glacier-regional `statsdex_m3dbingester` — in progress (2026-10-05)

## B. Verify the glacier rollout (no traffic change expected)

- [ ] One restart per host, no crash loops
- [ ] `kvconfig.optional-cluster-resolve-errors` stays 0
- [ ] No `annotated-only source` or `failed to resolve UNS` log lines
- [ ] Glacier ingester write rate, errors, latency flat
- [ ] Active series on `native-histogram-glacier-{dca,phx}` stays 0
- [ ] A known 10m/1h series reads back unchanged

## C. Aggregator histogram carry (code, hot path)

- [ ] Hot gauge glacier flush attaches the histogram instead of 0
- [ ] Glacier gauge merges and de-duplicates it (mirror timers)
- [ ] Zero guard: drop and count when the gate is off
- [ ] Both gates default off
- [ ] Benchmarks, tests, two reviewers
- [ ] Merge and deploy the aggregators

## D. Staging validation

- [ ] Decide staging storage: add 10m/1h sketch namespaces to `sketch_test_dca`, or validate only up to the glacier aggregator
- [ ] Turn on the staging gates
- [ ] 10m:180d and 1h:1y staging rule
- [ ] Histograms arrive, ten 1m windows equal one 10m, no zero series, reads back
- [ ] Turn the staging gates back off

## E. Enable glacier writes in production

- [ ] `enableSketchIngest: true` on glacier ingesters, deploy
- [ ] Flip `m3db.ingester.writes.sketch-enabled` to true for glacier envs
- [ ] Glacier-accept gate on, then hot-carry gate, per region
- [ ] One canary 10m native-histogram rule, single service
- [ ] Watch sketch writes, errors, series growth on `native-histogram-glacier-*`
- [ ] Read the series back
- [ ] Widen the rule

## F. Hot path, 10s and 1m (independent of C)

- [ ] Wire hot ingesters: short + hist sources, optional etcd, KV gate emitted false, deploy
- [ ] `enableSketchIngest: true` per zone, deploy
- [ ] Flip the KV gate per zone
- [ ] Canary 10s/1m rule, read it back

## G. Query

- [ ] Confirm scalar queries use a read mode that skips annotated-only sources
- [ ] Add native-histogram sources to production query shims, deploy
- [ ] `type:native-histogram` query returns the canary series

## Rollback

Flip the KV sketch gate off, then the aggregator gates. Set
`enableSketchIngest: false` and redeploy only if the route itself must go.

## Log

- 2026-10-05: both PRs merged to main (`67822d6` #303472, `bf348bd` #304566);
  CD rollout of glacier ingesters in progress. Native-histogram glacier
  clusters still at 0 active series. Rollout health not yet verified
  (ingester process metrics not found via statsdex_query).
- 2026-10-01: checklist created. A–G all open. Verified: both PRs open;
  `enableSketchIngest` true only in staging-dca60; KV sketch gate emitted
  false for glacier envs; glacier shims contain the NH glacier sources;
  `GaugeElem.AddExpoHistogram` still returns `errExpoHistogramNotSupported`
  on main; R2 validator allows `NativeHistogram`; query shims have no NH
  sources. Six clusters, namespaces and sketch schema verified live
  2026-09-30.
