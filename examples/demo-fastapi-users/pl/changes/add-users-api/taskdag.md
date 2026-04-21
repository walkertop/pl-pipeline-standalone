# TaskDAG: 用户管理 API

> 由 `/pl:plan` 基于 plan.md 生成。**本文件最后真实状态：12/12 任务完成**。

---

## 任务列表

| ID | 任务 | 类型 | 依赖 | 产物 | 状态 |
|----|-----|------|-----|-----|------|
| T01 | Settings + db engine + Base | bootstrap | - | `app/{settings,db}.py`, `app/models/__init__.py` | ✅ DONE |
| T02 | User SQLAlchemy 模型 | model | T01 | `app/models/user.py` | ✅ DONE |
| T03 | User Pydantic schemas（三件套 + Token） | schema | - | `app/schemas/user.py` | ✅ DONE |
| T04 | Paginated / Pagination 公共 schema | schema | - | `app/schemas/common.py` | ✅ DONE |
| T05 | Security 工具：hash/verify/JWT | util | T01 | `app/security.py` | ✅ DONE |
| T06 | UserRepository | repo | T02 | `app/repositories/user_repo.py` | ✅ DONE |
| T07 | UserService（事务边界） | service | T06, T03, T05 | `app/services/user_service.py` | ✅ DONE |
| T08 | DI：get_db / get_current_user / get_user_service | di | T01, T05 | `app/deps.py` | ✅ DONE |
| T09 | errors.py + 全局 exception handler | err | - | `app/errors.py` | ✅ DONE |
| T10 | /auth 路由（register + token） | api | T07, T08 | `app/api/v1/auth.py` | ✅ DONE |
| T11 | /api/v1/users 路由（list + detail） | api | T07, T08 | `app/api/v1/users.py` | ✅ DONE |
| T12 | main.py 聚合 + httpx 集成测试骨架 | integration | T09, T10, T11 | `app/main.py`, `tests/api/test_users.py` | ✅ DONE |

---

## 依赖图

```
T01 ──▶ T02 ──▶ T06 ──▶ T07 ──▶ T10 ──▶ T12
  │                        │     │
  ├──▶ T05 ────▶──────────┘     │
  │                              │
T03 ──▶ T07                      │
T03 ──▶ T10 / T11 ──▶────────────┘
T04 ──▶ T11
T01 / T05 ──▶ T08 ──▶ T10 / T11
T09 ──▶ T12
```

---

## 执行节拍

- `app/**.py` 每次改动后跑 `scripts/adapter-python-fastapi-lint.sh`（ruff）
- T12 完成后跑 `scripts/adapter-python-fastapi-verify.sh`（ruff + mypy + pytest）
- 全部通过才算 D/E 门禁 PASSED，阶段推进到 VERIFY → OBSERVE

## 契约对齐

`api.md` 定义的 4 个端点是 T10/T11 实施的唯一依据；request/response schema 由
T03/T04 先行声明，保证前后一致。
