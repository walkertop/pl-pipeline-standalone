"""User 数据访问层。不开事务，由 service 层统一管理。"""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepo:
    async def get(self, s: AsyncSession, user_id: UUID) -> User | None:
        return await s.get(User, user_id)

    async def get_by_email(self, s: AsyncSession, email: str) -> User | None:
        stmt = select(User).where(User.email == email)
        return (await s.execute(stmt)).scalar_one_or_none()

    async def add(self, s: AsyncSession, user: User) -> User:
        s.add(user)
        await s.flush()
        return user

    async def list_page(
        self, s: AsyncSession, offset: int, limit: int
    ) -> tuple[list[User], int]:
        stmt = (
            select(User)
            .order_by(User.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        items = list((await s.execute(stmt)).scalars())
        total = await s.scalar(select(func.count(User.id))) or 0
        return items, int(total)
