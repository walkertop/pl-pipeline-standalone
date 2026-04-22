---
id: sqlalchemy-async
name: sqlalchemy-async
triggers: ["sqlalchemy", "async session", "asyncpg", "alembic"]
description: SQLAlchemy 2.x 异步会话与事务模式
version: 1.0.0
---

# SQLAlchemy 2.x 异步模式

## 引擎与会话

```python
# app/db.py
from sqlalchemy.ext.asyncio import (
    create_async_engine, AsyncSession, async_sessionmaker
)

engine = create_async_engine(
    settings.db_url,              # postgresql+asyncpg://...
    echo=settings.db_echo,        # 调试期 True，生产 False
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,           # 连接断开自动重试
)

SessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,       # 避免 commit 后属性被过期失效
    autoflush=False,              # 显式 flush 更可控
)
```

## 声明式模型

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import String, DateTime, func
from uuid import UUID, uuid4
from datetime import datetime

class Base(DeclarativeBase): ...

class Item(Base):
    __tablename__ = "items"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
```

## 查询（2.x 风格）

**不要**再用 `session.query()`（v1 风格）。v2 用 `select()`：

```python
from sqlalchemy import select

# 按主键
item = await session.get(Item, item_id)

# select + where
stmt = select(Item).where(Item.deleted_at.is_(None))
result = await session.execute(stmt)
items = result.scalars().all()

# 单条 .scalar_one_or_none() / .scalar_one()
stmt = select(Item).where(Item.name == name)
item = (await session.execute(stmt)).scalar_one_or_none()

# 计数
from sqlalchemy import func
cnt = await session.scalar(select(func.count(Item.id)).where(Item.deleted_at.is_(None)))
```

## 关联加载（避免 N+1）

```python
from sqlalchemy.orm import selectinload, joinedload

# selectinload：发两条 SQL（主 + IN(...)），适合 to-many
stmt = select(Order).options(selectinload(Order.items))

# joinedload：一条 JOIN，适合 to-one
stmt = select(Order).options(joinedload(Order.user))

# 嵌套
stmt = select(Order).options(
    selectinload(Order.items).joinedload(Item.category)
)
```

## 事务

**推荐：Service 层用 `async with session.begin()`**。

```python
async def create_order(session: AsyncSession, data: OrderCreate) -> Order:
    async with session.begin():                # 开启事务
        order = Order(**data.model_dump())
        session.add(order)
        await session.flush()                  # 拿到 order.id，此时未 commit
        for item in data.items:
            session.add(OrderItem(order_id=order.id, **item.model_dump()))
        return order
    # 离开 with：commit（无异常）或 rollback（有异常）
```

手动 commit/rollback（不推荐，容易漏）：

```python
try:
    session.add(x)
    await session.commit()
    await session.refresh(x)
except Exception:
    await session.rollback()
    raise
```

## Repository 模式

```python
# app/repositories/item_repo.py
class ItemRepo:
    async def get(self, s: AsyncSession, id: UUID) -> Item | None:
        return await s.get(Item, id)

    async def list_active(self, s: AsyncSession, offset: int, limit: int) -> list[Item]:
        stmt = (
            select(Item)
            .where(Item.deleted_at.is_(None))
            .order_by(Item.created_at.desc())
            .offset(offset).limit(limit)
        )
        return list((await s.execute(stmt)).scalars())

    async def create(self, s: AsyncSession, data: ItemCreate) -> Item:
        item = Item(**data.model_dump())
        s.add(item)
        await s.flush()              # 让 id 就位，但不 commit
        return item
```

Repository **不开事务**。事务边界在 Service。

## Alembic（迁移）

### 初始化

```bash
uv add alembic
uv run alembic init alembic
```

### 配置异步 env.py

```python
# alembic/env.py 核心片段
from sqlalchemy.ext.asyncio import AsyncEngine
from app.db import engine
from app.models import Base

target_metadata = Base.metadata

async def run_async_migrations():
    async with engine.connect() as conn:
        await conn.run_sync(do_run_migrations)

def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

asyncio.run(run_async_migrations())
```

### 工作流

```bash
# 自动生成
uv run alembic revision --autogenerate -m "add items table"

# 应用
uv run alembic upgrade head

# 回滚
uv run alembic downgrade -1
```

**要求**：每个 migration 的 `downgrade()` 必须真实可用。

## 常见坑

### 坑 1: 忘记 expire_on_commit=False

默认 True 会让 commit 后对象的属性访问触发重新 query（甚至失败）。

### 坑 2: 在 async 会话里用同步 API

```python
# ❌
session.execute(stmt)                          # 同步 API
# ✅
await session.execute(stmt)
```

### 坑 3: 用 `session.begin()` 嵌套

SQLAlchemy 默认不允许嵌套事务。若需要 savepoint：
```python
async with session.begin_nested():             # savepoint
    ...
```

### 坑 4: 连接池耗尽

症状：`TimeoutError: QueuePool limit of size ... overflow`。原因：某处忘了关闭
session，或长事务持有连接。检查：
- `get_db` 用 `async with`
- 不要在路由层手动 `SessionLocal()`，一定走 Depends

## 参考

- https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- https://alembic.sqlalchemy.org/en/latest/
