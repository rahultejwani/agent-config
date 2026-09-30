# M3DB / Odin / Grail reference

Read before M3DB cluster, namespace, etcd, or native-histogram wiring work.
Facts verified 2026-09-30 unless noted. Re-check live state before relying on
anything that could have changed (namespaces, schemas, instance names).

## Mental model

| Layer | What it is | Where it lives |
|---|---|---|
| Odin instance | One M3DB cluster, e.g. `glacier-a-regional`, `native-histogram-hist-dca`. Scope regional or zonal. Hosts spread across zones. | Odin / Grail `m3db::instance:<name>` |
| Odin cluster | Sub-object of an instance: `<instance>-cluster-<region>` (+ `cluster1`, `cluster2` when `sub_cluster_enabled`). | Grail `m3db::cluster:<name>` |
| etcd | Control plane. Often **shared** by many instances of a type/region; each instance is an env inside it (env = instance name when `use_zone_in_env=false`). Holds placement, namespace registry `m3db.node.namespaces`, runtime KV. | UDG `udg://o-p-et-...` |
| Placement | Shards → hosts, RF=3 across zones. Service `m3dbnode-docker`. | etcd |
| Namespace | Storage unit with exactly **one** retention/block size; optional proto schema. Same series ID across namespaces, so each storage policy needs its own namespace. Every cluster also has `pingless` (health). | etcd namespace registry; Odin goal state |

Naming convention: scalar and native-histogram clusters both use
`metrics-<resolution>:<retention>` (e.g. `metrics-10m:180d`). Metric tags show
`:` as `_` (`metrics-10m_180d`). Staging test clusters differ (`sketch_test_dca`
uses `sketch`).

## Statsdex config mapping (go-code)

| Config | Must equal |
|---|---|
| `m3db_clusters.star` `cluster_metadata.cluster_type` | Odin instance name (config-service env) |
| `cluster_metadata.etcd_zone` / name | a key in `etcd_clusters.star` `kv_config` whose UDG resolves |
| `pkg/tsdb/source/registry.go` `SourceDef.Namespace` | a namespace in that instance |
| `SourceDef.StoragePolicy` | that namespace's resolution:retention |
| Sketch (annotated) writes | namespace proto schema `uber.m3.sketch.Sketch` |

Generated configs show the real pairing: `statsdex-config/conf/gen/query_worker/production-part_logical-<zone>-service.yaml`
→ `m3db.clusters.<cluster>.configService.env` + `etcdClusters[].zone`.
Examples: `glacier-a-regional` → etcd key `odin-m3db-m3-glacier-regional`;
`hist-a-dca22` → `odin-m3db-m3-regional-dca22`. Sparse checkout lacks most gen
files — use `git show origin/main:<path>`.

## Tools that work (and how)

| Need | Command |
|---|---|
| Namespaces + retention per instance | `storage m3db namespace -i <instance> -r <region>` (no schema column) |
| Placement | `storage m3db placement -i <instance> -r <region>` |
| etcd UDG, proto schemas, goal state | Grail via aifx (below), node `m3db::GoalState.etcd` / `.schemas` |
| Does a UDG exist? | `uns udg://<name>:http` (FATAL "failed to find group" = does not exist) |
| Live series per namespace | `cerberus -s statsdex_query` then `curl -G localhost:5436/m3ql/render -H 'RPC-Service: statsdex_query' -H 'RPC-Caller: <user>' --data-urlencode 'target=fetch service:m3dbnode-docker name:database.status.active-series odininstance:<inst> \| sum namespace' --data-urlencode from=-15min --data-urlencode until=now` |
| Odin instance goal state | `aifx mcp call odin-mcp get_instance_goalstate --args '{"technology":"m3db","instance_name":"<inst>"}'` |
| M3DB source (namespace/schema protos) | `~/infra-m3db` (= `uber-code/infra-m3dbnode`); `src/dbnode/generated/proto/namespace/{namespace,schema}.proto` (`NamespaceOptions.schemaOptions`, `defaultMessageName`) |

Grail query for etcd + schemas of any M3DB instance:

```bash
aifx mcp call grail-mcp execute_yql_query --args '{"query":"m3db::instance:<inst> storage::cluster / storage::node (FIELD m3db::GoalState.etcd AS etcd FIELD m3db::GoalState.schemas AS schemas FIELD m3db::GoalState.use_zone_in_env AS zenv LIMIT 1)"}'
```

Other Grail tips: `aifx mcp call grail-mcp --list-tools`; `get_yql_spec` for
syntax; `m3db::instance:<inst> (FIELD *::*)` dumps instance props
(`storage::UDGPaths` = dbnode UDG, `storage::UNSPaths`). Instance has no direct
etcd association; etcd is only in node goal state.

Find more MCPs: `aifx mcp list | rg -i <term>`; call without installing via
`aifx mcp call <server> <tool> --args '<json>'` (USSO auth, no cerberus).

## Tools that did not work

- Odin web UI from the agent browser: blocked by USSO; needs the user.
- `m3admin-mcp` via cerberus (`cerberus -s m3admin-mcp`, POST `localhost:5436/mcp`): resolves zones but `kv_get` / `placement_get` on prod m3db etcd time out. Useful only to test whether an etcd key's UDG resolves.
- `storage etcd get -i <etcd>`: needs a grail etcd instance name; guessed names return "cannot find result in grail".
- No `m3admin` CLI on devpod.
- Cerberus: kill with `pkill -f "cerberus -s"` before restarting, or ports stay bound.

## Production native-histogram clusters (verified 2026-09-30)

| Odin instance | etcd UDG | Namespaces | Proto schema |
|---|---|---|---|
| `native-histogram-short-{dca,phx}` | `o-p-et-m3db-native-histogram-reg-{dca,phx}` | `metrics-10s:2d` | `uber.m3.sketch.Sketch` |
| `native-histogram-hist-{dca,phx}` | same | `metrics-1m:40d` | `uber.m3.sketch.Sketch` |
| `native-histogram-glacier-{dca,phx}` | same | `metrics-10m:{180d,1y,3y,5y}`, `metrics-1h:{1y,3y,5y}` | `uber.m3.sketch.Sketch` on all 7 |

- All three instances in a region share one etcd; env = instance name.
- Instances are sub-clustered: base `<inst>-cluster-<region>` holds 2-3
  subcluster coordinators (goal state `schemas: null`, no data); data nodes
  live in `-cluster1` / `-cluster2` and carry the schemas. **Never check
  schemas with `LIMIT 1`** — aggregate over all nodes, ignoring the base
  cluster.
- Stale instances `glacier-native-histogram-{dca,phx}` exist but report no data.
- Staging `sketch_test_dca`: etcd `o-p-et-m3db-staging-2-{dca,phx}`, namespace `sketch`, schema `uber.m3.sketch.Sketch`. Retention: Grail 40d/24h block vs `storage` CLI 48h/1h (unresolved).
- go-code main (#288421) originally had wrong instance names (`native_histogram_*`, `glacier_native_histogram_*`), namespace `sketch`, and six non-existent per-cluster UDGs; fix tracked under MET-782.
