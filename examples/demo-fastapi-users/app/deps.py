"""依赖注入工厂。"""

from __future__ import annotations

from collections.abc import AsyncGenerator

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionLocal
from app.errors import InvalidCredentials
from app.models.user import User
from app.repositories.user_repo import UserRepo
from app.security import decode_token
from app.services.user_service import UserService

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Request 作用域 session。"""
    async with SessionLocal() as session:
        yield session


def get_user_repo() -> UserRepo:
    return UserRepo()


def get_user_service(repo: UserRepo = Depends(get_user_repo)) -> UserService:
    return UserService(repo)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
    repo: UserRepo = Depends(get_user_repo),
) -> User:
    user_id = decode_token(token)
    user = await repo.get(db, user_id)
    if user is None:
        raise InvalidCredentials()
    return user
