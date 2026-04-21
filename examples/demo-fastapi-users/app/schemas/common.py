"""通用 schema。"""

from __future__ import annotations

from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class Pagination(BaseModel):
    page: int = Field(default=1, ge=1)
    size: int = Field(default=20, ge=1, le=100)

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size


class Paginated(BaseModel, Generic[T]):
    items: list[T]
    page: int
    size: int
    total: int


class ApiError(BaseModel):
    code: str
    message: str | None = None
    meta: dict[str, object] | None = None
