# Agent Execution Loop

`pl agent run` 是 pl-pipeline 的 agent 控制面入口。它不实现 coding agent，而是把任意 executor 的一次代码尝试纳入 PL-Pipeline：

```text
executor command -> gate verification -> failure classification -> repair context -> repair retry -> trace
```

## Basic Usage

```bash
pl agent run \
  --change add-search \
  --task T03 \
  --executor local \
  --cmd "./scripts/agent-implement.sh" \
  --verify-gate D \
  --repair-cmd "./scripts/agent-repair.sh" \
  --max-retries 1
```

`--repair-cmd` 是显式 override，适合一次性调试。

## Repair Policy

稳定项目建议把 repair 策略放进 `pl/config.yaml`：

```yaml
agent:
  repair:
    max_retries: 1
    strategy:
      test_failure: "./scripts/repair_test_failure.sh"
      syntax_error: "./scripts/repair_syntax_error.sh"
      missing_file: "./scripts/repair_missing_file.sh"
      default: "./scripts/repair_default.sh"
```

优先级：

1. CLI `--repair-cmd`
2. `agent.repair.strategy.<failure_kind>`
3. `agent.repair.strategy.default`
4. 无 repair，停止为 blocked

`--max-retries` 同样优先于 `agent.repair.max_retries`。

## Failure Kinds

当前内置分类是保守文本分类：

| failure_kind | 典型信号 |
|---|---|
| `test_failure` | `AssertionError`, `FAIL:`, `FAILED`, `unittest`, `pytest` |
| `syntax_error` | `SyntaxError`, `IndentationError`, `syntax error` |
| `missing_file` | `ModuleNotFoundError`, `ImportError`, `No such file` |
| `timeout` | `timeout`, `timed out` |
| `contract_violation` | `contract`, `pact`, `schema`, `violation` |
| `unknown` | 其他无法识别的 gate 失败 |

## Repair Context

每次 repair 前会生成：

```text
pipeline-output/agent-runs/<change>/<run-id>/repair-context-attempt-<n>.md
```

repair 命令会收到这些环境变量：

| Variable | Meaning |
|---|---|
| `PL_CHANGE` | change id |
| `PL_TASK_ID` | task id |
| `PL_RUN_ID` | agent run id |
| `PL_RUN_DIR` | 当前 run 目录 |
| `PL_AGENT_EXECUTOR` | executor id |
| `PL_AGENT_ATTEMPT` | 当前 attempt |
| `PL_FAILURE_KIND` | gate 失败分类 |
| `PL_REPAIR_SOURCE` | `cli` / `policy:<kind>` / `policy:default` |
| `PL_REPAIR_CONTEXT` | repair context Markdown 路径 |

## Trace Events

`pl agent run` 写入同一条 trace：

- `agent.run.start`
- `agent.run.result`
- `agent.gate.start`
- `agent.gate.result`
- `agent.repair.context`
- `agent.repair.result`
- `agent.run.complete`

关键字段：

- `failure_kind`
- `repair_source`
- `run_id`
- `task_id`
- `executor`
- `attempt`

## Demos

```bash
bash examples/demo-agent-loop/run-demo.sh
bash examples/demo-agent-crud-service/run-demo.sh
```

`demo-agent-loop` 是最小计算器闭环；`demo-agent-crud-service` 展示通过 `agent.repair.strategy.test_failure` 自动选择修复脚本。
