---
name: fastapi-dependency-injection
triggers: ["depends", "dependency", "di", "fastapi depends"]
description: FastAPI Depends 依赖注入模式完整参考
---

# FastAPI Depends 依赖注入

## 心智模型

`Depends(f)` = "调用 `f()`，把返回值作为当前函数参数注入"。FastAPI 对
**同一个请求内相同的 Depends** 只调用一次（request-scoped cache）。

## 四类依赖

### 1. 配置类（app 单例）

```python
from functools import lru_cache

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

用法：
```python
@router.get("/info")
async def info(settings: Settings = Depends(get_settings)):
    return {"env": settings.env}
```

### 2. 资源类（请求作用域 + yield）

```python
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session
        # 退出时自动关闭
```

**注意**：不要在 yield 之后手写 commit/rollback——那是 Service 层的事。

### 3. 派生类（依赖链）

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    user_id = verify_jwt(token)
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED)
    return user

def require_role(role: str):
    async def _checker(user: User = Depends(get_current_user)) -> User:
        if role not in user.roles:
            raise HTTPException(status.HTTP_403_FORBIDDEN)
        return user
    return _checker

# 使用
@router.delete("/items/{id}")
async def delete_item(
    id: UUID,
    admin: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    ...
```

### 4. 参数聚合类（Pydantic Depends）

```python
from pydantic import BaseModel, Field

class Pagination(BaseModel):
    page: int = Field(default=1, ge=1)
    size: int = Field(default=20, ge=1, le=100)

@router.get("/items")
async def list_items(
    p: Pagination = Depends(),   # FastAPI 自动从 query 构造
    db: AsyncSession = Depends(get_db),
):
    ...
```

## Sub-dependency 缓存

```python
async def get_common(db: AsyncSession = Depends(get_db)): ...
async def get_a(c = Depends(get_common)): ...
async def get_b(c = Depends(get_common)): ...

@router.get("/")
async def ep(a = Depends(get_a), b = Depends(get_b)): ...
# get_common 只被调用一次（request-scoped）
```

如果希望每次调用都重新构造：`Depends(get_common, use_cache=False)`。

## 依赖注入测试

pytest 里替换依赖：

```python
from app.main import app
from app.deps import get_db

async def override_get_db():
    async with TestSessionLocal() as session:
        yield session

app.dependency_overrides[get_db] = override_get_db
# 测试完记得 app.dependency_overrides.clear()
```

或用 fixture：

```python
@pytest.fixture(autouse=True)
def _override_db():
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.clear()
```

## 常见坑

### 坑 1: 同步 Depends 里 await 异步

```python
# ❌
def get_x(db = Depends(get_db)):
    return await db.query(...)   # SyntaxError，或更糟：没 await 返回 coroutine

# ✅
async def get_x(db: AsyncSession = Depends(get_db)):
    result = await db.execute(...)
    return result.scalar_one()
```

### 坑 2: yield 的 cleanup 失败吞错误

```python
async def get_db():
    async with SessionLocal() as session:
        yield session
        await session.commit()   # ❌ 抛错会被 FastAPI 吞
```

正确：让 `async with` 管理生命周期，不要在 yield 之后写业务。

### 坑 3: 过度拆分 Depends

Depends 链太深会让调试困难。超过 3 层请考虑：
- 合并
- 用类作 Depends（`Depends(MyService)`，FastAPI 会 `__init__`）

## 参考

- https://fastapi.tiangolo.com/tutorial/dependencies/
- https://fastapi.tiangolo.com/advanced/advanced-dependencies/
