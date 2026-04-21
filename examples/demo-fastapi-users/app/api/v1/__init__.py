"""API v1 聚合路由。"""

from fastapi import APIRouter

from app.api.v1 import auth, users

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/api/v1/users", tags=["users"])
