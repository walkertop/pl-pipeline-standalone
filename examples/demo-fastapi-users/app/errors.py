"""领域错误 + HTTP 映射。"""

from __future__ import annotations

from typing import Any


class DomainError(Exception):
    """业务错误基类。HTTP 状态码、机器可读 code、可选 meta。"""

    code: str = "domain_error"
    http_status: int = 400

    def __init__(self, message: str = "", meta: dict[str, Any] | None = None) -> None:
        self.message = message or self.code
        self.meta = meta or {}
        super().__init__(self.message)


class NotFoundError(DomainError):
    code = "not_found"
    http_status = 404


class ConflictError(DomainError):
    code = "conflict"
    http_status = 409


class UnauthorizedError(DomainError):
    code = "unauthorized"
    http_status = 401


class ForbiddenError(DomainError):
    code = "forbidden"
    http_status = 403


# 具体错误
class EmailAlreadyRegistered(ConflictError):
    code = "email_already_registered"


class InvalidCredentials(UnauthorizedError):
    code = "invalid_credentials"


class UserNotFound(NotFoundError):
    code = "user_not_found"
