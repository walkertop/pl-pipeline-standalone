"""异步引擎 + SessionLocal + Base 基类。"""

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.settings import get_settings


class Base(DeclarativeBase):
    """SQLAlchemy 声明式基类。"""


_settings = get_settings()

engine = create_async_engine(_settings.db_url, echo=False, future=True)

SessionLocal: async_sessionmaker[AsyncSession] = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def init_db() -> None:
    """开发期用：启动时 create_all。生产请改用 Alembic。"""
    # 注意：导入 models 让 metadata 识别到表定义
    from app.models import user as _user  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
