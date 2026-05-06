# SPEC: Agent Execution Loop MVP

## Intent

把 pl-pipeline 从“AI 编码流程治理文档/门禁工具”推进到一个最小可执行的 **Agentic Coding Control Plane**：

- 不自研完整 coding agent。
- 不替代 Codex / Claude Code / Cursor 等执行器。
- 先补上控制平面最薄但最关键的一环：`任务命令 -> gate 验证 -> 失败上下文 -> repair retry -> trace 归档`。

## Problem

现有项目已经具备 6 阶段、gate、trace、CDC、adapter 和 IDE sync，但“AI 写代码”的实际执行环节仍在工具外部。

这会造成三个断点：

- gate 失败后，失败信息没有被整理成下一轮 agent 可消费的修复上下文。
- trace 能记录脚本/gate，但不能表达一次 agent 执行尝试、repair 尝试和最终结果。
- demo 侧缺少一个小而完整的可验证闭环，无法证明 PL-Pipeline 能约束真实代码产出。

## Scope

本次只做 MVP：

- 新增 `pl agent run`。
- 使用本地 shell executor 作为最小执行器。
- 调用现有 `pl run --gate <gate>` 做机器验证。
- gate 失败时生成 Markdown repair context，并在 `--max-retries` 预算内执行 `--repair-cmd`。
- 将 agent/gate/repair 事件写入同一条 trace。
- 新增一个 Python stdlib demo，无 npm/pip 依赖。

## Non-Goals

- 不接入外部 Codex / Claude / Cursor API。
- 不实现模型选择、token 统计、沙箱权限策略。
- 不重写 trace 到 OpenTelemetry。
- 不替代已有 `pl-runner.sh` 的 gate 判定职责。

## Success Criteria

- `bash tests/cli/test-pl-agent.sh` 通过。
- `bash examples/demo-agent-loop/run-demo.sh` 能从错误实现修复到单测通过。
- trace 文件中存在 `agent.run.start`、`agent.repair.context`、`agent.run.complete`。
- README / CLI reference 能说明该能力的边界。
