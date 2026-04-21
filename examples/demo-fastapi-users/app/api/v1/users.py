"""/api/v1/users 路由。"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_current_user, get_db, get_user_service
from app.models.user import User
from app.schemas.common import Paginated, Pagination
from app.schemas.user import UserRead
from app.services.user_service import UserService

router = APIRouter()


@router.get("", response_model=Paginated[UserRead], summary="List users")
async def list_users(
    p: Pagination = Depends(),
    _auth: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    svc: UserService = Depends(get_user_service),
) -> Paginated[UserRead]:
    items, total = await svc.list_page(db, p.offset, p.size)
    return Paginated[UserRead](
        items=[UserRead.model_validate(u) for u in items],
        page=p.page,
        size=p.size,
        total=total,
    )


@router.get("/{user_id}", response_model=UserRead, summary="Get a user")
async def get_user(
    user_id: UUID,
    _auth: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    svc: UserService = Depends(get_user_service),
) -> UserRead:
    user = await svc.get(db, user_id)
    return UserRead.model_validate(user)
