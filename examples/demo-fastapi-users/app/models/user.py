"""User 模型。SQLite 下把 UUID 存为 BLOB，生产切 PostgreSQL 用原生 UUID。"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import BINARY, TypeDecorator

from app.db import Base


class _UuidBlob(TypeDecorator[UUID]):  # pragma: no cover - trivial adapter
    """SQLite 下 UUID ↔ BLOB 互转。PostgreSQL 可直接换 sqlalchemy.dialects.postgresql.UUID。"""

    impl = BINARY(16)
    cache_ok = True

    def process_bind_param(self, value: UUID | None, dialect: object) -> bytes | None:
        return value.bytes if value else None

    def process_result_value(self, value: bytes | None, dialect: object) -> UUID | None:
        return UUID(bytes=value) if value else None


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(_UuidBlob, primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
