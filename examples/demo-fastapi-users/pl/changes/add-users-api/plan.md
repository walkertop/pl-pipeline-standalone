# Plan: 用户管理 API

> 由 `fastapi-architect` agent 基于 spec.md 产出。

---

## 1. 技术选型

| 关注点 | 选择 | 理由 |
|------|-----|-----|
| Web 框架 | FastAPI 0.110+ | spec 契约化 + 异步原生 |
| 数据校验 | Pydantic v2 + email-validator | 与 FastAPI 深度整合 |
| ORM | SQLAlchemy 2.x async | 成熟 / 类型友好 |
| 数据库 | aiosqlite（demo） / PostgreSQL（生产） | 单机跑最简 |
| 测试 | pytest-asyncio + httpx ASGITransport | 无需起真实端口 |
| 依赖管理 | uv | 速度 / lockfile 稳定 |
| 类型检查 | mypy --strict + pydantic.mypy plugin | - |
| 代码风格 | ruff | lint + format |
| 密码哈希 | passlib[bcrypt] | 行业通用 |
| JWT | python-jose[cryptography] | 无额外外部服务 |

---

## 2. 架构分层

```
app/
├── main.py                    ← FastAPI app + handlers
├── settings.py                ← Pydantic Settings
├── db.py                      ← engine + SessionLocal
├── deps.py                    ← get_db / get_current_user / get_user_service
├── errors.py                  ← DomainError + 映射
├── security.py                ← hash_password / verify / create_access_token
├── api/v1/
│   ├── __init__.py
│   ├── router.py              ← include_router 聚合
│   ├── auth.py                ← /auth/{register,token}
│   └── users.py               ← /api/v1/users
├── schemas/
│   ├── common.py              ← Paginated[T], Pagination
│   └── user.py                ← UserBase/Create/Read/Update, TokenResponse
├── models/
│   └── user.py                ← SQLAlchemy Base + User
├── repositories/
│   └── user_repo.py           ← 单条 CRUD（不开事务）
└── services/
    └── user_service.py        ← 事务边界在此层
```

### 分层契约

| 层 | 职责 | 禁止 |
|----|-----|-----|
| `api/` | 解析请求 → 调 service → 返回 Pydantic | 直接操作 DB |
| `services/` | 业务规则 / 事务 | 知道 HTTP |
| `repositories/` | ORM 查询 | 含业务规则 |
| `models/` | SQLAlchemy 表映射 | - |
| `schemas/` | 请求/响应 | 含业务逻辑 |

---

## 3. 关键决策 (ADR-lite)

### D1: aiosqlite 还是 asyncpg？
- **选择**: aiosqlite（demo），README 说明生产切 asyncpg
- **理由**: demo 单文件就能跑，零外部依赖
- **代价**: 生产前换 PostgreSQL + Alembic 迁移脚本

### D2: 事务边界在 Service 层
- **选择**: `async with session.begin()` 包裹业务
- **理由**: Repository 只做单条 CRUD，business invariant 靠 service 守护

### D3: UUID 主键存 BLOB（SQLite）
- **选择**: SQLite 下把 UUID bytes 存 BLOB；Pydantic 序列化回 str
- **理由**: 零依赖；生产 PG 换原生 UUID 类型

### D4: JWT 简化为 HS256
- **选择**: HS256 对称密钥
- **理由**: 无需非对称；生产可升级 RS256 + JWKS

---

## 4. 风险与对策

| 风险 | 概率 | 影响 | 对策 |
|------|-----|-----|------|
| 密码哈希阻塞事件循环 | 中 | 中 | passlib 用 `asyncio.to_thread` 包裹 |
| UUID 主键在 SQLite 反序列化繁琐 | 中 | 低 | Pydantic 用 `field_validator` 归一 |
| 测试互相污染（模块级 Map） | 低 | 高 | 每个测试一个新 engine (in-memory) |

---

## 5. 里程碑

| 里程碑 | 交付物 | 预估 |
|-------|-------|------|
| M1 | db / models / migrations | 30m |
| M2 | repo + service + 单元测试 | 45m |
| M3 | auth 路由（register/token）+ 集成测试 | 45m |
| M4 | /users 路由 + 分页 + 权限 | 45m |
| M5 | OpenAPI 快照 + mypy / ruff 过 | 30m |

---

## 6. 回滚预案

- **代码**: git revert
- **数据**: demo 用 in-memory，重启即回滚；生产用 Alembic `downgrade`
- **密钥**: JWT_SECRET 换新，旧 token 立即失效
