# Evidence: 2026-04 retro-v2 trace 证据

这里存放 2026-04-21 retro-v2 **及其后续 E1/E2 落地**期间产出的 trace jsonl。

## v1 快照（手工 bash 模拟）— 已被 v2 工具替换
之前这里的 jsonl 是用 trace-emit.sh 手工 shell 调度得到的。
v2 落地后**由 pl-runner.sh + pl-smoke.sh 真实产出**覆盖：

## v2 快照（pl-runner.sh + pl-smoke.sh）

| 文件 | 事件数 | 工具 | 场景 |
|---|---|---|---|
| `demo-fastapi-users.events.jsonl` | 13 | `pl-runner --gate D` + `pl-smoke` | D 阶段 2 check / SMOKE 3 probe |
| `demo-nextjs-todo.events.jsonl` | 7 | `pl-runner --gate D` + `pl-smoke` (skip) | D 阶段 2 check / SMOKE 优雅 skip |

## 读这些 trace 能看到什么

1. **gate.eval 从 check 结果自动派生** —— 不再是口头承诺
   ```
   {"event":"check.run","data":{"checker":"lint","status":"fail",...}}
   {"event":"gate.eval","data":{"gate":"D","result":"blocked","pass":1,"fail":1}}
   ```
2. **SMOKE 阶段真启动 + 关停** —— 抓 B5/B6 类运行时 bug
   ```
   {"event":"smoke.boot","data":{"pid":6930,"cmd":"uvicorn app.main:app..."}}
   {"event":"smoke.ready","data":{"attempts":2}}
   {"event":"check.run","data":{"checker":"probe:register_happy","status_code":201,"status":"pass"}}
   {"event":"smoke.shutdown","data":{"pid":6930}}
   ```
3. **skipped 也有事件**（opt-out 不是静默）
   ```
   {"event":"smoke.skip","data":{"reason":"no_smoke_config_in_adapter"}}
   {"event":"gate.eval","data":{"gate":"E_smoke","result":"skipped"}}
   ```

## 重现

```bash
export PL_PROJECT=$PWD/examples/demo-fastapi-users

# D 门禁
bash scripts/pl-runner.sh --change add-users-api --gate D --json

# SMOKE 门禁
SMOKE_PORT=38765 bash scripts/pl-smoke.sh --change add-users-api --json

# trace 自动落到 $PL_PROJECT/pipeline-output/trace/
```

## 与 retro 的关系

本目录是 [`../2026-04-demo-first-run-retro-v2.md`](../2026-04-demo-first-run-retro-v2.md)
§4 "实验证据" 的原始数据，也是 §5 中 E1/E2 落地效果的**真实度量**。

