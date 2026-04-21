# Plan: [变更名称]

> **模板版本**: v0.1 (adapter-python-fastapi)
> **前置产物**: `spec.md`
> **后继产物**: `taskdag.md` / `api.md` / `testmatrix.md`

---

## 1. 技术选型

| 关注点 | 选择 | 理由 |
|------|-----|-----|
| Web 框架 | FastAPI 0.110+ | 异步原生 / 类型驱动 |
| 数据校验 | Pydantic v2 | 与 FastAPI 深度整合 |
| ORM | SQLAlchemy 2.x async | 成熟 / 类型完整 |
| 数据库 | PostgreSQL 15 | JSONB / 时序 / 事务 |
| 迁移 | Alembic | SQLAlchemy 配套 |
| 测试 | pytest + pytest-asyncio + httpx | 异步友好 |
| 依赖管理 | uv | 速度快 / lockfile 稳定 |
| 类型检查 | mypy (--strict) 或 pyright | 强制 |
| 代码风格 | ruff | lint + format 一把刀 |

---

## 2. 架构分层

```
app/
├── main.py                      ← FastAPI app 实例
├── api/
│   └── v1/
│       ├── __init__.py
│       ├── router.py            ← include_router 集合
│       └── items.py             ← /items 端点
├── schemas/
│   └── item.py                  ← Pydantic 模型
├── models/
│   └── item.py                  ← SQLAlchemy ORM
├── services/
│   └── item_service.py          ← 业务逻辑（纯函数 / 不依赖 HTTP）
├── repositories/
│   └── item_repo.py             ← 数据访问层（隔离 ORM）
├── deps.py                      ← Depends 工厂
├── db.py                        ← engine / SessionLocal
├── settings.py                  ← Pydantic Settings
└── errors.py                    ← 业务错误 + HTTP 映射
```

### 分层职责

| 层 | 职责 | 禁止 |
|----|-----|-----|
| `api/` | 解析请求、调用 service、返回响应 | 直接操作 DB |
| `services/` | 业务规则、编排、事务 | 知道 HTTP |
| `repositories/` | ORM 查询封装 | 包含业务规则 |
| `models/` | SQLAlchemy 表映射 | - |
| `schemas/` | 请求/响应/领域数据结构 | 含业务逻辑 |

---

## 3. 关键决策 (ADR-lite)

### D1: 同步 vs 异步？
- **选择**: 全异步（`async def` + AsyncSession + asyncpg）
- **理由**: FastAPI 的价值就是异步；同步会阻塞事件循环
- **代价**: 测试需 pytest-asyncio；事务上下文管理严格

### D2: Repository 还是直接在 Service 里写 ORM？
- **选择**: 有 Repository 层
- **理由**: 单元测试更容易 mock；未来换 ORM 不用动业务
- **代价**: 多一层代码

### D3: 事务边界在哪一层？
- **选择**: Service 层。Repository 不开事务（除非是批量特殊场景）
- **理由**: 业务语义由 service 决定，repo 只做读写

---

## 4. 风险与对策

| 风险 | 概率 | 影响 | 对策 |
|------|-----|-----|------|
| N+1 查询 | 高 | 中 | `selectinload` / `joinedload` 检查表 |
| 事务未回滚导致脏数据 | 中 | 高 | Service 用 `async with session.begin()` 包裹 |
| Pydantic v1 残留 | 中 | 低 | CI 固定 `pydantic>=2,<3` |
| 异步阻塞（意外调同步 IO） | 中 | 高 | 代码审查盯 `requests` / `time.sleep` |

---

## 5. 里程碑

| 里程碑 | 交付物 | 预估 |
|-------|-------|------|
| M1 | 模型 + 迁移 + repository | 0.5d |
| M2 | Service 层 + 单元测试 | 0.5d |
| M3 | API 端点 + httpx 集成测试 | 0.5d |
| M4 | OpenAPI / 认证接入 | 0.5d |
| M5 | 性能压测 + 优化 | 0.5d |

---

## 6. 回滚预案

- **代码**: git revert
- **数据库**: 每次 Alembic migration 必须有 `downgrade`
- **特性开关**: 关键 endpoint 挂 `@app.router.include_router(..., include_in_schema=settings.enable_items)`
