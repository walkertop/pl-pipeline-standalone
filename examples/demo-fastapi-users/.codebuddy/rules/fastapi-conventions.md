# Rule: FastAPI Conventions

> **Scope**: always

## 路由命名

### 资源路径

- 复数名词：`/users`, `/orders`, `/items`
- 嵌套只到一层：`/orders/{id}/items`（再深就要重新设计）
- 版本前缀：`/api/v1/...`

### HTTP 方法语义

| 方法 | 语义 | status_code |
|------|-----|-----------|
| `GET /xs` | 列表 | 200 |
| `GET /xs/{id}` | 详情 | 200 / 404 |
| `POST /xs` | 创建 | 201 |
| `PUT /xs/{id}` | 全量替换 | 200 / 404 |
| `PATCH /xs/{id}` | 部分更新 | 200 / 404 |
| `DELETE /xs/{id}` | 删除 | 204 / 404 |

## 路由声明约定

```python
from fastapi import APIRouter, Depends, status, HTTPException

router = APIRouter()

@router.get(
    "",
    response_model=ItemList,
    summary="List items",
    description="Returns paginated active items.",
    status_code=status.HTTP_200_OK,
)
async def list_items(
    p: Pagination = Depends(),
    db: AsyncSession = Depends(get_db),
) -> ItemList:
    ...

@router.post(
    "",
    response_model=ItemRead,
    status_code=status.HTTP_201_CREATED,
    responses={
        409: {"description": "Item name already exists"},
    },
)
async def create_item(
    body: ItemCreate,
    db: AsyncSession = Depends(get_db),
) -> ItemRead:
    ...
```

### 硬要求

1. **`response_model`**：所有非 204 路由都必须声明
2. **`status_code`**：POST/DELETE 不能用默认 200
3. **`summary`** / **`description`**：给 OpenAPI 消费者（前端 / 自动测试生成 / 文档）
4. **返回值类型注解**：让 mypy 能查出错
5. **路径参数类型**：`{id}` → `id: UUID`（让 FastAPI 自动校验）

## 响应模型分离

- **输入**：`XxxCreate` / `XxxUpdate`
- **输出**：`XxxRead`
- **内部**：`XxxModel`（SQLAlchemy），永远不做 response_model

## 错误处理

### 业务错误 → HTTPException

```python
from fastapi import HTTPException, status

if not item:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail={"code": "item_not_found", "id": str(id)},
    )

if exists:
    raise HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail={"code": "name_conflict", "name": data.name},
    )
```

### 全局异常处理器

```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError):
    return JSONResponse(
        status_code=exc.http_status,
        content={"code": exc.code, "message": exc.message},
    )
```

### 结构化 detail

统一 detail schema：

```python
class ErrorDetail(BaseModel):
    code: str            # 机器可读，如 "item_not_found"
    message: str | None = None
    meta: dict[str, Any] | None = None
```

## 分页

```python
class Pagination(BaseModel):
    page: int = Field(default=1, ge=1)
    size: int = Field(default=20, ge=1, le=100)

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size

class Paginated(BaseModel, Generic[T]):
    items: list[T]
    page: int
    size: int
    total: int
```

## 标签 & 分组

```python
app.include_router(items.router, prefix="/api/v1/items", tags=["items"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
```

`tags` 让 Swagger UI 分组。

## 禁忌

- ❌ 把 SQLAlchemy 模型作 `response_model`（暴露内部字段 / N+1）
- ❌ 业务逻辑写在路由函数里（违反分层）
- ❌ 路由里直接 `await session.commit()`（事务外泄）
- ❌ `response_model_exclude_unset=True` 滥用（客户端以为字段不存在）
- ❌ `from fastapi import *`
- ❌ 用默认 200 status_code 返回创建成功（应 201）
