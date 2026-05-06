# TASKDAG: Codex CLI Executor

| ID | Task | Files | Depends | Status |
|---|---|---|---|---|
| T01 | 写 codex-cli executor 红灯测试 | `tests/cli/test-pl-agent.sh` | - | DONE |
| T02 | 实现 codex-cli 命令构造 | `scripts/pl-agent-run.sh` | T01 | DONE |
| T03 | 写 fake Codex demo 红灯测试 | `tests/cli/test-pl-agent.sh` | T02 | DONE |
| T04 | 新增 fake Codex demo | `examples/demo-agent-codex-cli/` | T03 | DONE |
| T05 | 更新文档与忽略规则 | docs + `.gitignore` | T04 | DONE |
| T06 | 跑完整验证并提交 | tests + demo + git | T05 | DONE |
