"""密码哈希 + JWT。"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.errors import InvalidCredentials
from app.settings import get_settings

_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def hash_password(raw: str) -> str:
    """bcrypt 不是异步的；用 to_thread 避免阻塞事件循环。"""
    return await asyncio.to_thread(_pwd.hash, raw)


async def verify_password(raw: str, hashed: str) -> bool:
    return await asyncio.to_thread(_pwd.verify, raw, hashed)


def create_access_token(user_id: UUID) -> str:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=settings.jwt_ttl_seconds)).timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> UUID:
    settings = get_settings()
    try:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
        sub = payload.get("sub")
        if not isinstance(sub, str):
            raise InvalidCredentials()
        return UUID(sub)
    except JWTError as exc:  # pragma: no cover - path covered by tests
        raise InvalidCredentials() from exc
