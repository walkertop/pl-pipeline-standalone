# SPEC: Codex CLI Executor

## Intent

把 `pl agent run` 从本地 shell executor 推进到第一个外部 coding agent executor：`codex-cli`。

本次目标不是依赖真实登录态跑在线 Codex，而是先把控制面协议打通：

- `pl agent run --executor codex-cli`
- 从 `--prompt-path` 读取 prompt
- 构造 `codex exec ... - < prompt`
- 写入统一 agent trace
- 保持 fake Codex demo 可离线验证

## Problem

上一阶段已经补齐 agent trace metadata，但 executor 仍然本质上是 `bash -c --cmd`。如果不先抽象出 Codex CLI executor，后续接 Claude Code / Cursor 会继续散落成临时脚本。

## Scope

新增：

- `--executor codex-cli`
- `--codex-bin <path>`，默认 `codex`，也可用 `CODEX_BIN` 环境变量
- `--codex-sandbox <mode>`，默认 `workspace-write`
- `--codex-approval <policy>`，默认 `never`
- `--codex-arg <arg>`，可重复

行为：

- `codex-cli` executor 在未传 `--cmd` 时要求 `--prompt-path`。
- 默认构造：

```bash
codex exec --cd "$PL_PROJECT" --sandbox workspace-write --ask-for-approval never - < "$prompt"
```

- 如果传了 `--model`，追加 `-m <model>`。
- 自动补 trace metadata：`provider=openai`、`tool_calls=["codex.exec"]`。

## Non-Goals

- 不自动登录 Codex。
- 不调用真实网络服务作为 CI 前提。
- 不解析 Codex JSONL 事件来自动统计 token。
- 不启用 `--dangerously-bypass-approvals-and-sandbox`。

## Success Criteria

- `bash tests/cli/test-pl-agent.sh` 通过。
- `bash examples/demo-agent-codex-cli/run-demo.sh` 通过。
- demo 能证明 prompt 通过 stdin 传给 `codex exec`。
- trace 中能看到 `executor=codex-cli`、`provider=openai`、`tool_calls=["codex.exec"]`。
