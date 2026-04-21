"""User 业务层。事务边界在此。"""

from __future__ import annotations

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import EmailAlreadyRegistered, InvalidCredentials, UserNotFound
from app.models.user import User
from app.repositories.user_repo import UserRepo
from app.schemas.user import UserCreate
from app.security import create_access_token, hash_password, verify_password


class UserService:
    def __init__(self, repo: UserRepo) -> None:
        self.repo = repo

    async def register(self, s: AsyncSession, data: UserCreate) -> User:
        async with s.begin():
            existing = await self.repo.get_by_email(s, data.email)
            if existing is not None:
                raise EmailAlreadyRegistered(meta={"email": data.email})
            user = User(email=data.email, password_hash=await hash_password(data.password))
            await self.repo.add(s, user)
            return user

    async def authenticate(self, s: AsyncSession, email: str, password: str) -> str:
        user = await self.repo.get_by_email(s, email)
        if user is None:
            raise InvalidCredentials()
        if not await verify_password(password, user.password_hash):
            raise InvalidCredentials()
        return create_access_token(user.id)

    async def get(self, s: AsyncSession, user_id: UUID) -> User:
        user = await self.repo.get(s, user_id)
        if user is None:
            raise UserNotFound(meta={"id": str(user_id)})
        return user

    async def list_page(
        self, s: AsyncSession, offset: int, limit: int
    ) -> tuple[list[User], int]:
        return await self.repo.list_page(s, offset, limit)
