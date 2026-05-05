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

## Agent Trace Metadata

外部 executor adapter 可以把 agent 身份、prompt、产物、工具和 token 用量一起写进 trace：

```bash
pl agent run \
  --change add-search \
  --task T03 \
  --executor codex-cli \
  --provider openai \
  --model codex-local-test \
  --prompt-path prompts/implement.md \
  --input-artifact specs/spec.md \
  --input-artifact pl/changes/add-search/taskdag.md \
  --output-artifact app/search.py \
  --tool-call shell \
  --tool-call apply_patch \
  --tokens-input 1200 \
  --tokens-output 450 \
  --cmd "./scripts/agent-implement.sh" \
  --verify-gate D
```

这些字段会合并进 `task.start`、`agent.run.start`、`agent.run.result`、`agent.repair.result`、`agent.run.complete` 和 `--json` 输出：

| Field | Meaning |
|---|---|
| `provider` | 模型或 agent 服务提供方，例如 `openai` / `anthropic` / `local` |
| `model` | executor 使用的模型或 agent id |
| `prompt_path` | 本次执行的主要 prompt 文件 |
| `input_artifacts[]` | 输入上下文产物，例如 spec / plan / taskdag |
| `output_artifacts[]` | 期望或实际输出产物 |
| `tool_calls[]` | executor 使用的工具名 |
| `tokens.input` | 输入 token 数 |
| `tokens.output` | 输出 token 数 |
| `tokens.total` | 输入 + 输出 |

字段为空时不会写入 trace。当前不会自动统计 token；外部 executor adapter 负责传入真实数值。

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
- `provider`
- `model`
- `prompt_path`
- `input_artifacts`
- `output_artifacts`
- `tool_calls`
- `tokens`
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
