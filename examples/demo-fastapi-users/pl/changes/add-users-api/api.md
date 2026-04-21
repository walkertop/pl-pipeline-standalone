# API Contract: add-users-api

> 4 个端点的签名、入参、响应、错误码。本文是 T10/T11 实施的唯一依据。

---

## 数据类型（Pydantic schemas）

```python
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)

class UserRead(UserBase):
    id: UUID
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class TokenResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"

class Paginated(BaseModel, Generic[T]):
    items: list[T]
    page: int
    size: int
    total: int
```

---

## E1 POST /auth/register

**Auth**: 无
**Body** (`application/json`): `UserCreate`
**Response 201**: `UserRead`
**Errors**:
| status | code | 语义 |
|---|---|---|
| 409 | `email_already_registered` | email 已存在 |
| 422 | Pydantic | 校验失败 |

---

## E2 POST /auth/token

**Auth**: 无
**Body** (`application/x-www-form-urlencoded`):
- `username: str`（实际传 email）
- `password: str`

**Response 200**: `TokenResponse`
**Errors**:
| status | code | 语义 |
|---|---|---|
| 401 | `invalid_credentials` | 账密不匹配 |

---

## E3 GET /api/v1/users

**Auth**: Bearer JWT
**Query**:
| 参数 | 类型 | 默认 | 约束 |
|---|---|---|---|
| `page` | int | 1 | ≥ 1 |
| `size` | int | 20 | 1..100 |

**Response 200**: `Paginated[UserRead]`
**Errors**:
| status | code | 语义 |
|---|---|---|
| 401 | `unauthorized` | 未登录 |

---

## E4 GET /api/v1/users/{id}

**Auth**: Bearer JWT
**Path**: `id: UUID`
**Response 200**: `UserRead`
**Errors**:
| status | code | 语义 |
|---|---|---|
| 401 | `unauthorized` | 未登录 |
| 404 | `user_not_found` | id 不存在 |

---

## 通用错误体

所有 4xx/5xx 响应统一结构：

```json
{
  "code": "machine_readable_snake",
  "message": "Human readable text",
  "meta": { "...": "optional context" }
}
```

## OpenAPI 自动文档

- Swagger UI: `GET /docs`
- ReDoc: `GET /redoc`
- Schema JSON: `GET /openapi.json`（可作为快照测试基线）
