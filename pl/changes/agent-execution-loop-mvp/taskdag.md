# TASKDAG: Agent Execution Loop MVP

| ID | Task | Files | Depends | Status |
|---|---|---|---|---|
| T01 | 写失败测试锁定 agent loop 行为 | `tests/cli/test-pl-agent.sh` | - | DONE |
| T02 | 新增 agent loop CLI 执行器 | `scripts/pl-agent-run.sh` | T01 | DONE |
| T03 | 接入 `bin/pl agent run` 路由 | `bin/pl` | T02 | DONE |
| T04 | 新增可跑 demo 项目 | `examples/demo-agent-loop/` | T02 | DONE |
| T05 | 更新 README / CLI / Roadmap | `README.md`, `docs/cli-reference.md`, `ROADMAP.md` | T03 | DONE |
| T06 | 跑完整验证并提交 | tests + demo + git | T04,T05 | DONE |

## Ownership

本次变更只触碰 CLI 控制面、demo、文档和测试，不改 adapter 协议、不改 gate runner 的判定逻辑。
