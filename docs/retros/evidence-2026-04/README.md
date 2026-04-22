# Evidence: 2026-04 retro-v2 trace 证据

这里存放 2026-04-21 retro-v2 **及其后续 E1/E2/E4 落地**期间产出的 trace jsonl
与 drift artifact。

## v1 快照（手工 bash 模拟）— 已被 v2 工具替换
之前这里的 jsonl 是用 trace-emit.sh 手工 shell 调度得到的。
v2 落地后**由 pl-runner.sh + pl-smoke.sh + piao-contract-drift-compute.sh 真实产出**。

## v2 快照（最新 — 含 E3 + E4）

| 文件 | 事件数 / 大小 | 工具 | 场景 |
|---|---|---|---|
| `demo-fastapi-users.events.jsonl` | 15 | D-gate + SMOKE + piao-drift + rule-scan **四阶段合流** | lint fail → D blocked；uvicorn SMOKE 3 probe pass；0 contract drift；0 rule violation |
| `demo-fastapi-users-contract-drift.yaml` | — | `piao-contract-drift-compute` | 0 entries |
| `demo-fastapi-users-rule-scan.yaml` | — | `pl-rule-scan` | 2 executable rules, 0 violations |
| `demo-nextjs-todo.events.jsonl` | 8 | 同上（SMOKE opt-out） | D blocked；SMOKE skipped；0 drift；0 violation |
| `demo-nextjs-todo-contract-drift.yaml` | — | `piao-contract-drift-compute` | 0 entries |
| `demo-nextjs-todo-rule-scan.yaml` | — | `pl-rule-scan` | 1 executable rule, 0 violations |

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

### 3. piao ↔ pl 四通道合流（E1 + E2 + E4 + E3）
```
{"phase":"IMPLEMENT","event":"gate.eval",...}                   ← pl-core E1
{"phase":"SMOKE","event":"smoke.boot",...}                       ← pl-core E2
{"phase":"OBSERVE","event":"piao.contract_drift.detected",...}   ← piao-kernel E4
{"phase":"OBSERVE","event":"pl.rule_scan.completed",...}         ← pl-core E3
```

所有事件落到**同一条** `pipeline-output/trace/<change>.events.jsonl`，下游工具
（dashboard / eventjournal / 未来 M6 evolution）不用分通道即可消费 piao + pl 全链路。

### 4. E3 rule-scan 示例（命中反证实验）
```
{"phase":"OBSERVE","event":"pl.rule_scan.completed",
 "data":{"artifact":"...rule-scan/<change>.yaml",
         "counts":{"total":1,"error":0,"warn":1},
         "executable_rules":1}}
```
配套的 YAML artifact 记录每条违规的 file / line / evidence / message / fix_hint。

### 5. skipped 也有事件（不静默）
```
{"event":"smoke.skip","data":{"reason":"no_smoke_config_in_adapter"}}
{"event":"gate.eval","data":{"gate":"E_smoke","result":"skipped"}}
```

## 反证实验（retro-v2 E3/E4 章节）

### E4 反证
把 Next.js demo 的 package.json 回滚到 retro-v1 修之前（React 18 +
`@types/react-dom@18.3`）→ E4 抓到 6 个 error：
- 5 × `peer_version_violation`（next/react/react-dom/@types/*）
- 1 × `bad_combo_hit: types-react-dom-18-with-useFormState`

### E3 反证
- **Next.js**：把 `_actions/todos.ts` 的 `revalidatePath('/todos')` 改回
  `revalidateTag('todos')`（retro-v2 B3 的原始 bug）→ E3 抓到
  `nextjs-revalidate-for-non-fetch` warn 违规，精确指向 `app/todos/_actions/todos.ts :line 1`
- **FastAPI**：放一个含 `Depends(get_db())` + `time.sleep` 的 `bad_example.py`
  → E3 同时抓到 `fastapi-depends-pass-callable-not-result` 和
  `fastapi-no-sync-blocking-in-async` 两条 error，精确到行号

**关键结论**：retro-v2 原始 7 个 bug 里 B1/B3/B4/B6/B7 共 **5 个都能被 E3+E4 在 pre-runtime 机器抓住**，不需要人肉触发运行时报错。

## 重现

```bash
export PL_PROJECT=$PWD/examples/demo-fastapi-users

# D 门禁
bash scripts/pl-runner.sh --change add-users-api --gate D --json

# SMOKE 门禁
SMOKE_PORT=38765 bash scripts/pl-smoke.sh --change add-users-api --json

# piao contract drift
bash scripts/piao-contract-drift-compute.sh --change add-users-api --json

# pl rule scan
bash scripts/pl-rule-scan.sh --change add-users-api --json

# 四个脚本产的事件合流到 $PL_PROJECT/pipeline-output/trace/<change>.events.jsonl
```

## 与 retro 的关系

本目录是 [`../2026-04-demo-first-run-retro-v2.md`](../2026-04-demo-first-run-retro-v2.md)
§4 "实验证据" 的原始数据，也是 §5 中 E1/E2/E3/E4 落地效果的**真实度量**。


