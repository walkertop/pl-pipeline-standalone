"""密码哈希 + JWT。直接使用 bcrypt，避免 passlib 在新版 bcrypt 下的兼容 bug。"""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from uuid import UUID

import bcrypt
from jose import JWTError, jwt

from app.errors import InvalidCredentials
from app.settings import get_settings

# bcrypt 的 72 字节限制：先 utf-8 截断到 72，再 hash
_MAX_BCRYPT_BYTES = 72


def _sync_hash(raw: str) -> str:
    b = raw.encode("utf-8")[:_MAX_BCRYPT_BYTES]
    return bcrypt.hashpw(b, bcrypt.gensalt()).decode("utf-8")


def _sync_verify(raw: str, hashed: str) -> bool:
    b = raw.encode("utf-8")[:_MAX_BCRYPT_BYTES]
    try:
        return bcrypt.checkpw(b, hashed.encode("utf-8"))
    except ValueError:
        return False


async def hash_password(raw: str) -> str:
    """bcrypt 是同步库；用 to_thread 避免阻塞事件循环。"""
    return await asyncio.to_thread(_sync_hash, raw)


async def verify_password(raw: str, hashed: str) -> bool:
    return await asyncio.to_thread(_sync_verify, raw, hashed)


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
