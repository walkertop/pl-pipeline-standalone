"""FastAPI app 入口。"""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.v1 import api_router
from app.db import init_db
from app.errors import DomainError


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    # demo：启动时建表；生产请改成 Alembic 迁移
    await init_db()
    yield


app = FastAPI(
    title="demo-fastapi-users",
    version="0.0.1",
    description="pl-pipeline adapter-python-fastapi end-to-end demo",
    lifespan=lifespan,
)
app.include_router(api_router)


@app.exception_handler(DomainError)
async def _domain_handler(_: Request, exc: DomainError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.http_status,
        content={"code": exc.code, "message": exc.message, "meta": exc.meta},
    )


@app.get("/health", tags=["meta"])
async def health() -> dict[str, str]:
    return {"status": "ok"}
