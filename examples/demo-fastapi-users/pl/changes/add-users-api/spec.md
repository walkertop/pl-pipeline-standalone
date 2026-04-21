# StructuredSpec: 用户管理 API

> 本文按 `adapter-python-fastapi` 提供的 `templates/spec.md` 模板填写。

---

## 1. 变更概述

| 字段 | 值 |
|------|-----|
| Change ID | `add-users-api` |
| 变更类型 | API 新增 |
| 资源路径 | `/api/v1/users` + `/auth/{register,token}` |
| HTTP 方法 | POST register / POST token / GET list / GET detail |
| 关联领域 | 用户 |
| 复杂度预估 | 🟡 中 |
| 是否涉及数据迁移 | 是（新增 `users` 表） |

---

## 2. 端点清单

| ID | Method | Path | 描述 | 优先级 | 破坏兼容 |
|----|--------|------|------|--------|----------|
| E1 | POST | `/auth/register` | 用户注册 | P0 | 否 |
| E2 | POST | `/auth/token`    | 获取 JWT | P0 | 否 |
| E3 | GET  | `/api/v1/users`  | 列表（分页） | P0 | 否 |
| E4 | GET  | `/api/v1/users/{id}` | 详情 | P1 | 否 |

---

## 3. 请求/响应契约

### E1 POST /auth/register

**Body**:
```json
{ "email": "string (email)", "password": "string, 8..128" }
```
**Response 201**: UserRead
**Errors**: 409 email_already_registered, 422 校验失败

### E2 POST /auth/token

标准 OAuth2 Password Flow：`application/x-www-form-urlencoded`，字段
`username` + `password`。
**Response 200**: `{ "access_token": "...", "token_type": "bearer" }`
**Errors**: 401 invalid_credentials

### E3 GET /api/v1/users

**Query**: `page:int=1 (ge=1)`, `size:int=20 (1..100)`
**Response 200**: `{ items: UserRead[], page, size, total }`
**Errors**: 401 未认证

### E4 GET /api/v1/users/{id}

**Path**: `id: UUID`
**Response 200**: UserRead
**Errors**: 401, 404 not_found

---

## 4. 数据模型

### 表

| 名称 | 类型 | 主键 | 新增/修改 |
|------|-----|------|-----------|
| `users` | table | `id UUID` | ✅ 新增 |

### DDL

```sql
CREATE TABLE users (
  id            BLOB PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  updated_at    TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);
CREATE UNIQUE INDEX users_email_idx ON users(email);
```

> demo 用 aiosqlite 简化；生产用 PostgreSQL + `UUID` 原生类型 + Alembic 迁移。

### Pydantic 模型

```python
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)

class UserRead(UserBase):
    id: UUID
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

---

## 5. 依赖注入计划

| 依赖 | 来源 | 作用域 | 用途 |
|------|------|------|------|
| `db_session` | `get_db` | per-request | AsyncSession |
| `current_user` | `get_current_user` | per-request | JWT 解析后 User |
| `settings` | `get_settings` (`@lru_cache`) | app | Pydantic Settings |
| `user_service` | `get_user_service` | per-request | 封装 repo |

---

## 6. 认证与授权

| 端点 | 认证 | 授权规则 |
|------|-----|---------|
| E1/E2 | ❌ | 开放 |
| E3/E4 | ✅ JWT | 任意登录用户 |

---

## 7. 性能目标

| 指标 | 目标 | 验证 |
|------|-----|------|
| p95 latency | E3 < 100ms（demo，单机 aiosqlite） | 手动 wrk / hey |
| DB 查询数 | E3 ≤ 2（含 count） | SQLAlchemy echo |

---

## 8. 不确定项

| ID | 问题 | 阻塞等级 | 建议 | 状态 |
|----|------|---------|-----|------|
| Q1 | 是否支持 refresh_token？ | NON_BLOCKING | demo 只发 access_token；生产再加 | 已决 |
| Q2 | 软删 vs 硬删？ | NON_BLOCKING | demo 不实现删除 | 已决 |

---

## 9. 验收基线

### 功能验收
- [x] E1/E2/E3/E4 集成测试（httpx + pytest-asyncio）
- [x] 边界：email 格式错、password 过短、用户重复
- [x] 权限：未登录访问 /users → 401

### 契约验收
- [x] OpenAPI schema 包含上述 4 个端点
- [x] response_model 全部指向 Pydantic Schema（无 ORM 泄漏）

### 非功能验收
- [x] `ruff check` 0 errors
- [x] `mypy --strict app` 0 errors
- [x] `pytest` 全绿
