# Evidence: 2026-04 retro-v2 trace 证据

这里存放 2026-04-21 retro-v2 **及其后续 E1/E2/E4 落地**期间产出的 trace jsonl
与 drift artifact。

## v1 快照（手工 bash 模拟）— 已被 v2 工具替换
之前这里的 jsonl 是用 trace-emit.sh 手工 shell 调度得到的。
v2 落地后**由 pl-runner.sh + pl-smoke.sh + piao-contract-drift-compute.sh 真实产出**。

## v2 快照（最新 — 含 E4）

| 文件 | 事件数 / 大小 | 工具 | 场景 |
|---|---|---|---|
| `demo-fastapi-users.events.jsonl` | 14 | `pl-runner D` + `pl-smoke` + `piao-contract-drift` | D+SMOKE+piao drift 三阶段合流 |
| `demo-fastapi-users-contract-drift.yaml` | — | `piao-contract-drift-compute` | 0 entries（host 对齐 contract） |
| `demo-nextjs-todo.events.jsonl` | 7 | 同上 | D+piao drift（SMOKE opt-out skipped） |
| `demo-nextjs-todo-contract-drift.yaml` | — | 同上 | 0 entries |

## 读这些 trace 能看到什么

### 1. gate.eval 从 check 结果自动派生（E1）
```
{"event":"check.run","data":{"checker":"lint","status":"fail",...}}
{"event":"gate.eval","data":{"gate":"D","result":"blocked","pass":1,"fail":1}}
```

### 2. SMOKE 阶段真启动 + 关停（E2）
```
{"event":"smoke.boot","data":{"pid":6930,"cmd":"uvicorn app.main:app..."}}
{"event":"smoke.ready","data":{"attempts":2}}
{"event":"check.run","data":{"checker":"probe:register_happy","status_code":201,"status":"pass"}}
{"event":"smoke.shutdown","data":{"pid":6930}}
```

### 3. piao ↔ pl trace 首次合流（E4）
```
{"phase":"IMPLEMENT","event":"gate.eval",...}       ← pl-core
{"phase":"SMOKE","event":"smoke.boot",...}          ← pl-core
{"phase":"OBSERVE","event":"piao.contract_drift.detected","data":{"adapter":"python-fastapi","counts":{"total":0,...}}}   ← piao
```

所有事件落到**同一条** `pipeline-output/trace/<change>.events.jsonl`，下游工具
（dashboard / eventjournal / 未来 M6 evolution）不用分通道即可消费 piao+pl 全链路。

### 4. skipped 也有事件（不静默）
```
{"event":"smoke.skip","data":{"reason":"no_smoke_config_in_adapter"}}
{"event":"gate.eval","data":{"gate":"E_smoke","result":"skipped"}}
```

## 反证实验（retro-v2 E4 章节）

把 Next.js demo 的 package.json 回滚到 retro-v1 修之前的状态（React 18 +
`@types/react-dom@18.3`）→ E4 抓到 6 个 error：
- 5 × `peer_version_violation`（next/react/react-dom/@types/react/@types/react-dom）
- 1 × `bad_combo_hit: types-react-dom-18-with-useFormState`

这直接证明**如果在第一次跑 demo 前就有 E4，那 7 个 bug 里的 B1/B4/B6/B7 都能被
机器一眼抓住**，无需人肉触发运行时报错。

## 重现

```bash
export PL_PROJECT=$PWD/examples/demo-fastapi-users

# D 门禁
bash scripts/pl-runner.sh --change add-users-api --gate D --json

# SMOKE 门禁
SMOKE_PORT=38765 bash scripts/pl-smoke.sh --change add-users-api --json

# piao contract drift
bash scripts/piao-contract-drift-compute.sh --change add-users-api --json

# trace 合流到 $PL_PROJECT/pipeline-output/trace/<change>.events.jsonl
```

## 与 retro 的关系

本目录是 [`../2026-04-demo-first-run-retro-v2.md`](../2026-04-demo-first-run-retro-v2.md)
§4 "实验证据" 的原始数据，也是 §5 中 E1/E2/E4 落地效果的**真实度量**。


