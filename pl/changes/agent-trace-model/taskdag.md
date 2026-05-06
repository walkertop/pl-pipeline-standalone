# TASKDAG: Agent Trace Model

| ID | Task | Files | Depends | Status |
|---|---|---|---|---|
| T01 | 写 agent trace metadata 红灯测试 | `tests/cli/test-pl-agent.sh` | - | DONE |
| T02 | 新增 metadata CLI 参数 | `scripts/pl-agent-run.sh` | T01 | DONE |
| T03 | 将 metadata 合入 trace / JSON 输出 | `scripts/pl-agent-run.sh` | T02 | DONE |
| T04 | 补文档 | `docs/agent-execution-loop.md` | T03 | DONE |
| T05 | 跑完整验证并提交 | tests + demo + git | T04 | DONE |
