# Native histogram release

Remaining work to take native histograms live. Updated 2026-10-06.
Lookup commands: `docs/m3db-odin-reference.md`.

Done: #303472 (`67822d6`) and #304566 (`bf348bd`) merged and rolled out to all
zones. Glacier ingesters know the native-histogram glacier clusters; both
switches are off. Verified 2026-10-06: `native-histogram-glacier-{dca,phx}` at
0 series in every namespace, and `glacier-a-regional` / `glacier-b-regional`
holding normal series counts.

## 1. Aggregator histogram carry (hot path, blocks 10m/1h)

10m/1h gauge native histograms are glacier-forwarded as 0 today, and the glacier aggregator rejects histogram payloads (`GaugeElem.AddExpoHistogram` returns `errExpoHistogramNotSupported`). Timers already do both halves over `TimedMetric.expo_histogram`, so no wire change is needed.

- [ ] Hot gauge glacier flush attaches the histogram bytes
- [ ] Glacier gauge merges and de-duplicates them
- [ ] Gates default off; when off, drop and count instead of storing 0
- [ ] Benchmarks, tests, two reviewers, deploy

## 2. Staging validation

- [ ] Decide storage: add 10m/1h sketch namespaces to `sketch_test_dca`, or stop the check at the glacier aggregator
- [ ] Gates on, one 10m and one 1h staging rule
- [ ] Histograms arrive, ten 1m windows equal one 10m, no zero series, reads back

## 3. Enable glacier writes

- [ ] `enableSketchIngest: true` on glacier ingesters, deploy
- [ ] `m3db.ingester.writes.sketch-enabled` = true for glacier envs
- [ ] Aggregator gates on, per region
- [ ] Canary: one 10m rule, one service; watch writes and errors; read it back; widen

## 4. Hot path, 10s and 1m (independent of 1-3)

- [ ] Wire hot ingesters to the short and hist clusters, KV gate emitted false, deploy
- [ ] `enableSketchIngest: true` per zone, deploy, then flip the KV gate per zone
- [ ] Canary 10s/1m rule, read it back

## 5. Query

- [ ] Confirm scalar queries skip annotated-only sources, then add the native-histogram sources to the production query shims
- [ ] `type:native-histogram` query returns the canary series

## Rollback

KV sketch gate off, then aggregator gates off. Redeploy with `enableSketchIngest: false` only if the route itself must go.
