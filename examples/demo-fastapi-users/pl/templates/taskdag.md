# TaskDAG: [变更名称]

> **模板版本**: v0.1 (adapter-python-fastapi)

---

## 任务列表

| ID | 任务 | 类型 | 依赖 | 产物 | 预估 |
|----|-----|------|-----|-----|------|
| T01 | 创建 SQLAlchemy 模型 | model | - | `app/models/<resource>.py` | 20m |
| T02 | 编写 Alembic migration | migration | T01 | `alembic/versions/<hash>_<name>.py` | 15m |
| T03 | 创建 Pydantic schemas | schema | - | `app/schemas/<resource>.py` | 20m |
| T04 | 实现 Repository | repo | T01 | `app/repositories/<resource>_repo.py` | 30m |
| T05 | Repository 单元测试 | test | T04 | `tests/repositories/test_<resource>.py` | 30m |
| T06 | 实现 Service | service | T04, T03 | `app/services/<resource>_service.py` | 45m |
| T07 | Service 单元测试 | test | T06 | `tests/services/test_<resource>.py` | 45m |
| T08 | 实现 FastAPI 路由 | api | T06, T03 | `app/api/v1/<resource>.py` | 45m |
| T09 | 注册到 main.py | integration | T08 | `app/main.py` | 10m |
| T10 | httpx 集成测试 | test | T09 | `tests/api/test_<resource>.py` | 1h |
| T11 | OpenAPI schema 快照 | contract | T09 | `tests/snapshots/openapi.json` | 20m |
| T12 | 认证/授权接入 | auth | T08 | `Depends(current_user)` 加到路由 | 30m |

---

## 依赖图

```
T01 ──▶ T02
  └───▶ T04 ──▶ T05
                 └──▶ T06 ──▶ T07
                         └──▶ T08 ──▶ T09 ──▶ T10
                                              └──▶ T11
                                        T08 ──▶ T12
T03 ──▶ T06
T03 ──▶ T08
```

---

## 执行指引

- 完成一个任务即更新 `.state.md` 的 `<last_task_done>`
- T02 迁移必须可 upgrade + downgrade 往返测试
- T05/T07/T10 是 VERIFY 阶段硬门禁
- T11 用 `pytest-snapshot` 冻结 OpenAPI，后续破坏性变更会被 CI 拦住
