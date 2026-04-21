"""/auth + /users 的 httpx 集成测试骨架。

本文件只负责描述期望行为（场景矩阵），并给出可运行的示例断言。
实际运行需：`uv sync --dev && uv run pytest -q`。
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


async def test_register_success(client: AsyncClient) -> None:
    resp = await client.post(
        "/auth/register",
        json={"email": "alice@example.com", "password": "secret123"},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["email"] == "alice@example.com"
    assert "id" in body


async def test_register_duplicate_email_conflicts(client: AsyncClient) -> None:
    payload = {"email": "bob@example.com", "password": "secret123"}
    r1 = await client.post("/auth/register", json=payload)
    assert r1.status_code == 201
    r2 = await client.post("/auth/register", json=payload)
    assert r2.status_code == 409
    assert r2.json()["code"] == "email_already_registered"


@pytest.mark.parametrize(
    "payload,expected_code",
    [
        ({"email": "not-email", "password": "secret123"}, 422),
        ({"email": "c@e.com", "password": "short"}, 422),
    ],
)
async def test_register_validation(
    client: AsyncClient, payload: dict, expected_code: int
) -> None:
    resp = await client.post("/auth/register", json=payload)
    assert resp.status_code == expected_code


async def test_token_and_list_users(client: AsyncClient) -> None:
    # register
    await client.post(
        "/auth/register",
        json={"email": "carol@example.com", "password": "secret123"},
    )
    # token
    tok_resp = await client.post(
        "/auth/token",
        data={"username": "carol@example.com", "password": "secret123"},
    )
    assert tok_resp.status_code == 200
    token = tok_resp.json()["access_token"]
    assert token

    # list (authorized)
    list_resp = await client.get(
        "/api/v1/users", headers={"Authorization": f"Bearer {token}"}
    )
    assert list_resp.status_code == 200
    body = list_resp.json()
    assert body["total"] >= 1
    assert any(u["email"] == "carol@example.com" for u in body["items"])


async def test_list_users_unauthorized(client: AsyncClient) -> None:
    resp = await client.get("/api/v1/users")
    assert resp.status_code == 401


async def test_openapi_endpoints_present(client: AsyncClient) -> None:
    resp = await client.get("/openapi.json")
    assert resp.status_code == 200
    paths = resp.json()["paths"]
    assert "/auth/register" in paths
    assert "/auth/token" in paths
    assert "/api/v1/users" in paths
    assert "/api/v1/users/{user_id}" in paths
