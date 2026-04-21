"""/auth 路由：register + token。"""

from __future__ import annotations

from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import get_db, get_user_service
from app.schemas.user import TokenResponse, UserCreate, UserRead
from app.services.user_service import UserService

router = APIRouter()


@router.post(
    "/register",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
async def register(
    data: UserCreate,
    db: AsyncSession = Depends(get_db),
    svc: UserService = Depends(get_user_service),
) -> UserRead:
    user = await svc.register(db, data)
    return UserRead.model_validate(user)


@router.post(
    "/token",
    response_model=TokenResponse,
    summary="Exchange credentials for an access token",
)
async def token(
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
    svc: UserService = Depends(get_user_service),
) -> TokenResponse:
    access = await svc.authenticate(db, form.username, form.password)
    return TokenResponse(access_token=access)
