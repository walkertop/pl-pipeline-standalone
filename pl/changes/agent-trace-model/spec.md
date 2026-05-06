# SPEC: Agent Trace Model

## Intent

在 `pl agent run` 已具备执行、验证、repair policy 的基础上，补齐 agent 观测模型，让后续 Codex / Claude Code / Cursor executor 可以复用同一套 trace 字段。

## Problem

当前 trace 已能表达：

- run id
- executor
- task id
- attempt
- failure_kind
- repair_source

但外部 agent 接入还需要回答：

- 谁提供了 agent？provider 是什么？
- 使用了哪个模型？
- prompt / spec / taskdag / 产物路径是什么？
- 这次执行调用了哪些工具？
- token 用量是多少？

如果这些字段不标准化，后续每接一个 executor 都会产生一套私有 trace。

## Scope

本次新增 `pl agent run` 可选参数：

- `--provider <id>`
- `--model <id>`
- `--prompt-path <path>`
- `--input-artifact <path>`，可重复
- `--output-artifact <path>`，可重复
- `--tool-call <name>`，可重复
- `--tokens-input <n>`
- `--tokens-output <n>`

并将这些字段写入：

- `task.start`
- `agent.run.start`
- `agent.run.result`
- `agent.repair.result`
- `agent.run.complete`
- `--json` 输出

## Non-Goals

- 不改写全局 trace schema 到 OpenTelemetry。
- 不实现真实 token 统计采集。
- 不接外部 agent API。
- 不实现 trace report UI。

## Success Criteria

- `bash tests/cli/test-pl-agent.sh` 通过。
- trace 中能看到 `provider`、`model`、`prompt_path`、`input_artifacts`、`output_artifacts`、`tool_calls`、`tokens`。
- 旧 demo 和 policy repair 不回归。
