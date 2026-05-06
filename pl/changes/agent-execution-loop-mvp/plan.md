# PLAN: Agent Execution Loop MVP

## PL Pipeline Mapping

| Stage | Output |
|---|---|
| SPEC | 明确项目方向：控制平面补执行闭环，而不是重做 coding agent |
| PLAN | 将执行闭环切成 CLI、trace、demo、docs、tests |
| IMPLEMENT | 新增 `scripts/pl-agent-run.sh` 和 `bin/pl agent run` 路由 |
| VERIFY | 新增 CLI 测试和 demo 自测，复用 `pl-runner.sh` gate |
| OBSERVE | 统一写入 `pipeline-output/trace/<change>.events.jsonl` |
| ARCHIVE | 文档化下一步外部 executor/OTel/gate repair 演进方向 |

## Design

`pl agent run` 是编排器，不是 gate runner：

1. 在宿主项目根目录执行 `--cmd`。
2. 如配置 `--verify-gate`，调用 `pl-runner.sh`。
3. gate 失败时，把命令输出和 gate 输出写成 repair context。
4. 设置 `PL_REPAIR_CONTEXT` 等环境变量，执行 `--repair-cmd`。
5. 重试 gate，直到通过或超过 `--max-retries`。

## Trace Events

- `agent.run.start`
- `agent.run.result`
- `agent.gate.start`
- `agent.gate.result`
- `agent.repair.context`
- `agent.repair.result`
- `agent.run.complete`

## Demo Strategy

`examples/demo-agent-loop` 使用 Python `unittest`：

- `write_bad_impl.sh` 写入错误的 `add(a, b) = a - b`。
- gate D 执行单测并失败。
- `repair_impl.sh` 读取 `PL_REPAIR_CONTEXT`，写回 `a + b`。
- gate D 再次执行并通过。

这样可以证明 PL-Pipeline 能把一次失败的 AI 代码尝试变成可观测、可修复、可验证的闭环。
