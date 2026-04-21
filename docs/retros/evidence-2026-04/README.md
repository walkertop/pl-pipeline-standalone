# Evidence: 2026-04 retro-v2 trace 证据

这里存放 2026-04-21 retro-v2 期间**真实执行** pl 流水线 VERIFY + (模拟) SMOKE 阶段
产出的 trace jsonl。保留它们是为了：

1. 证明 "pl 流水线现有 trace 基础设施已经够用"
2. 作为未来 `pl-runner.sh` / `pl-smoke.sh` 落地后**输出格式的回归基线**
3. 供 v1 vs v2 retro 对比阅读

## 文件清单

| 文件 | 事件数 | 阶段 | 结论 |
|---|---|---|---|
| `demo-nextjs-todo.events.jsonl` | 10 | VERIFY (tsc) + SMOKE (next build) | ✅ gate D passed / E_smoke passed |
| `demo-fastapi-users.events.jsonl` | 14 | VERIFY (lint/compile/test) + SMOKE (uvicorn + 4 probe) | ⚠️ lint fail 但 gate.eval 仍写 passed（证明闭环缺失） |

## 如何读

每条事件是一行 JSON，带 `ts / trace_id / phase / actor / event / data`。
用 `jq` 过滤：

```bash
# 看所有 check.run
cat demo-fastapi-users.events.jsonl | jq 'select(.event=="check.run")'

# 看所有 smoke probe
cat demo-fastapi-users.events.jsonl | jq 'select(.event=="smoke.probe")'

# gate 评估
cat demo-fastapi-users.events.jsonl | jq 'select(.event=="gate.eval")'
```

## 原位重现

```bash
export PL_PROJECT="$PWD/examples/demo-fastapi-users"
bash scripts/_env.sh   # 自动导出 PL_OUTPUT
# 本 retro 里用的 trace-emit 调用序列见 retro-v2 文档 §4
```

## 与 retro 的关系

本目录的 jsonl 是 [`../2026-04-demo-first-run-retro-v2.md`](../2026-04-demo-first-run-retro-v2.md)
§1 "证据" 和 §4 "实验证据" 引用的原始数据。
