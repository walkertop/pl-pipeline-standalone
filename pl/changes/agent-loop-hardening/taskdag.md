# TASKDAG: Agent Loop Hardening

| ID | Task | Files | Depends | Status |
|---|---|---|---|---|
| T01 | 写 policy repair 红灯测试 | `tests/cli/test-pl-agent.sh` | - | DONE |
| T02 | 实现 config repair policy | `scripts/pl-agent-run.sh` | T01 | DONE |
| T03 | 写 CRUD demo 红灯测试 | `tests/cli/test-pl-agent.sh` | T02 | DONE |
| T04 | 新增 CRUD service demo | `examples/demo-agent-crud-service/` | T03 | DONE |
| T05 | 补 agent loop 文档 | `docs/agent-execution-loop.md` | T02,T04 | DONE |
| T06 | 跑完整验证并提交 | tests + demo + git | T05 | DONE |
