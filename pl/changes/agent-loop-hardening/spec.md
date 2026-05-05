# SPEC: Agent Loop Hardening

## Intent

把上一阶段的 `Agent Execution Loop MVP` 从“命令 + repair-cmd demo”打磨成更接近真实项目控制面的闭环：

- gate 失败后能给出粗粒度失败类型。
- repair 命令可以从 `pl/config.yaml` 的策略表自动选择。
- demo 从计算器提升到业务 CRUD 服务。

## Problem

MVP 已经证明 `cmd -> gate -> repair context -> retry -> trace` 能跑通，但仍有两个缺口：

- 修复动作必须在 CLI 上手写 `--repair-cmd`，不适合稳定项目复用。
- trace/context 没有失败分类，后续无法统计“哪类失败最多”“哪类 repair 最有效”。

## Scope

本次增强：

- 支持 `agent.repair.max_retries`。
- 支持 `agent.repair.strategy.<failure_kind>`。
- 支持内置失败分类：
  - `test_failure`
  - `syntax_error`
  - `missing_file`
  - `timeout`
  - `contract_violation`
  - `unknown`
- 将 `failure_kind` / `repair_source` 写入 trace 和 repair context。
- 新增 `examples/demo-agent-crud-service`。

## Non-Goals

- 不接外部 Codex / Claude / Cursor。
- 不做复杂 LLM prompt 生成。
- 不引入第三方 Python / Node 依赖。
- 不把失败分类做成机器学习或完整错误本体。

## Success Criteria

- `bash tests/cli/test-pl-agent.sh` 通过。
- `bash examples/demo-agent-crud-service/run-demo.sh` 能跑出 `policy:test_failure`。
- 文档解释 `agent.repair` 配置格式和 CLI override 关系。
