# StructuredSpec: [变更/API 名称]

> **模板版本**: v0.1 (adapter-python-fastapi)
> **适用**: Python 3.11+ / FastAPI / Pydantic v2 后端
> **消费者**: PLAN 阶段的 Planner Agent

---

## 1. 变更概述

| 字段 | 值 |
|------|-----|
| Change ID | `change-id` (kebab-case) |
| 变更类型 | API 新增 / API 重构 / 数据模型变更 / 性能优化 / Bug 修复 |
| 资源路径 | `/api/v1/<resource>`（REST 资源名复数） |
| HTTP 方法 | GET / POST / PATCH / PUT / DELETE（列出全部） |
| 关联领域 | 由项目定义（如 用户 / 订单 / 商品 / 支付） |
| 复杂度预估 | 🔴高 / 🟡中 / 🟢低 |
| 是否涉及数据迁移 | 是 / 否 |

---

## 2. 端点清单 (Endpoint List)

| ID | Method | Path | 描述 | 优先级 | 是否破坏兼容 |
|----|--------|------|------|--------|------------|
| E1 | GET | `/api/v1/items` | 列表 | P0 | - |
| E2 | GET | `/api/v1/items/{id}` | 详情 | P0 | - |
| E3 | POST | `/api/v1/items` | 创建 | P0 | - |
| E4 | PATCH | `/api/v1/items/{id}` | 部分更新 | P1 | - |
| E5 | DELETE | `/api/v1/items/{id}` | 删除（软删） | P1 | - |

---

## 3. 请求/响应契约

### E1 GET /api/v1/items

**Query params**:

| 参数 | 类型 | 默认 | 约束 |
|------|------|-----|------|
| `page` | int | 1 | >= 1 |
| `size` | int | 20 | 1 <= size <= 100 |
| `q` | str? | - | max_len=100 |

**Response 200**:

```json
{
  "items": [{"id": "uuid", "name": "str", "created_at": "datetime"}],
  "page": 1,
  "size": 20,
  "total": 42
}
```

**Errors**: 400 参数错误 / 401 未授权 / 500 内部错误

### E3 POST /api/v1/items

**Body**:

```json
{
  "name": "string, 1..100",
  "description": "string, 0..500"
}
```

**Response 201**: 同 E2 详情结构
**Errors**: 400 / 401 / 409 name 冲突 / 422 校验失败

---

## 4. 数据模型 (Data Model)

### 表/集合

| 名称 | 类型 | 主键 | 新增 / 修改 |
|------|-----|------|-----------|
| `items` | table | `id uuid` | ✅ 新增 |

### 字段

```sql
CREATE TABLE items (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX items_name_idx ON items(name) WHERE deleted_at IS NULL;
```

### Pydantic 模型

```python
class ItemBase(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str | None = Field(default=None, max_length=500)

class ItemCreate(ItemBase): ...

class ItemRead(ItemBase):
    id: UUID
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

---

## 5. 依赖注入计划

| 依赖 | 来源 | 作用域 | 用途 |
|------|------|------|------|
| `db_session` | `get_db` | per-request | SQLAlchemy AsyncSession |
| `current_user` | `get_current_user` | per-request | JWT 解析后 User |
| `cache` | `get_cache` | app | Redis 客户端 |
| `settings` | `get_settings` (`@lru_cache`) | app | Pydantic Settings |

---

## 6. 认证与授权

| 端点 | 认证 | 授权规则 |
|------|-----|---------|
| E1/E2 | ✅ JWT | 任意登录用户 |
| E3/E4/E5 | ✅ JWT | 仅 `role in {admin, editor}` |

---

## 7. 性能目标

| 指标 | 目标 | 验证 |
|------|-----|------|
| p95 latency | E1 < 150ms / E2 < 50ms | k6 / locust |
| QPS | 单实例 >= 200 | 压测 |
| DB 查询数 | E1 <= 2 (含 count) | SQLAlchemy echo |

---

## 8. 不确定项 (Open Questions)

| ID | 问题 | 阻塞等级 | 建议 | 找谁 |
|----|------|---------|-----|------|
| Q1 | 软删还是硬删？ | BLOCKING | 软删（deleted_at） | @产品 |

---

## 9. 验收基线

### 功能验收
- [ ] P0 端点 E1/E2/E3 全部通过集成测试
- [ ] 边界用例：空列表、非法 UUID、重复 name、超长字段
- [ ] 权限：未登录 401、权限不足 403

### 契约验收
- [ ] OpenAPI schema 与 `api.md` 一致
- [ ] 破坏性变更有 deprecation 注释

### 非功能验收
- [ ] pytest 覆盖率 >= 80%
- [ ] `ruff check` 0 错误
- [ ] `mypy --strict app/` 0 错误
