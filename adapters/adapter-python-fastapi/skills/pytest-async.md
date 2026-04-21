---
name: pytest-async
triggers: ["pytest", "pytest-asyncio", "httpx", "test client", "asgi"]
description: pytest + httpx 异步测试完整模式
---

# pytest + httpx 异步测试

## 依赖

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[dependency-groups]
dev = [
  "pytest>=8",
  "pytest-asyncio>=0.23",
  "httpx>=0.27",
  "pytest-cov>=5",
]
```

`asyncio_mode = "auto"` 让所有 `async def test_*` 自动跑。

## conftest.py 基础设施

```python
# tests/conftest.py
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from app.main import app
from app.db import Base
from app.deps import get_db

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"

@pytest.fixture
async def engine():
    engine = create_async_engine(TEST_DB_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest.fixture
async def session(engine):
    async_session = async_sessionmaker(engine, expire_on_commit=False)
    async with async_session() as s:
        yield s

@pytest.fixture
async def client(session):
    async def _get_db_override():
        yield session

    app.dependency_overrides[get_db] = _get_db_override

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()
```

## 端点测试

```python
# tests/api/test_items.py
import pytest

pytestmark = pytest.mark.asyncio

async def test_list_items_empty(client):
    r = await client.get("/api/v1/items")
    assert r.status_code == 200
    assert r.json()["items"] == []
    assert r.json()["total"] == 0

async def test_create_item(client):
    r = await client.post(
        "/api/v1/items",
        json={"name": "book", "description": "a nice book"},
    )
    assert r.status_code == 201
    body = r.json()
    assert body["name"] == "book"
    assert "id" in body

async def test_create_item_invalid(client):
    r = await client.post("/api/v1/items", json={"name": ""})
    assert r.status_code == 422

async def test_get_item_not_found(client):
    r = await client.get("/api/v1/items/00000000-0000-0000-0000-000000000000")
    assert r.status_code == 404
```

## 参数化

```python
@pytest.mark.parametrize("payload,status_code,error_field", [
    ({"name": ""},         422, "name"),
    ({"name": "x" * 101},  422, "name"),
    ({"name": "ok"},       201, None),
    ({},                   422, "name"),
])
async def test_create_item_validation(client, payload, status_code, error_field):
    r = await client.post("/api/v1/items", json=payload)
    assert r.status_code == status_code
    if error_field:
        loc = r.json()["detail"][0]["loc"]
        assert error_field in loc
```

## 认证测试

```python
@pytest.fixture
async def auth_client(client):
    # 注册 / 登录
    await client.post("/auth/register", json={"email": "u@e.com", "password": "pw123456"})
    r = await client.post("/auth/token", data={"username": "u@e.com", "password": "pw123456"})
    token = r.json()["access_token"]
    client.headers["Authorization"] = f"Bearer {token}"
    yield client

async def test_protected(auth_client):
    r = await auth_client.get("/api/v1/me")
    assert r.status_code == 200
```

## Service 单元测试（不经 HTTP）

```python
from app.services.item_service import ItemService
from app.schemas.item import ItemCreate

async def test_item_service_create(session):
    svc = ItemService(ItemRepo())
    item = await svc.create(session, ItemCreate(name="test"))
    assert item.name == "test"
```

## OpenAPI 快照测试

```python
import json
from pathlib import Path

async def test_openapi_snapshot(client):
    r = await client.get("/openapi.json")
    assert r.status_code == 200
    snapshot_path = Path("tests/snapshots/openapi.json")

    if not snapshot_path.exists():
        snapshot_path.parent.mkdir(parents=True, exist_ok=True)
        snapshot_path.write_text(json.dumps(r.json(), indent=2, ensure_ascii=False, sort_keys=True))
        pytest.skip("snapshot created")

    expected = json.loads(snapshot_path.read_text())
    actual = json.loads(json.dumps(r.json(), sort_keys=True))
    assert actual == expected, "OpenAPI schema changed, review and update snapshot if intended"
```

更新快照：`pytest --snapshot-update`（需装 `syrupy` 或自己的 flag）。

## 覆盖率

```bash
uv run pytest --cov=app --cov-report=term-missing --cov-fail-under=80
```

## 常见坑

### 坑 1: pytest-asyncio 模式

没配 `asyncio_mode = "auto"` 必须每个 test 加 `@pytest.mark.asyncio`。

### 坑 2: httpx AsyncClient 废弃 API

老版本用 `AsyncClient(app=app)` 已废，现在用：
```python
AsyncClient(transport=ASGITransport(app=app), base_url="http://test")
```

### 坑 3: `dependency_overrides` 测试间泄漏

fixture 结束必须 `app.dependency_overrides.clear()`。

### 坑 4: SQLite in-memory 没跨连接共享

同一 engine 的不同连接看不到对方数据。解决：engine 用 `poolclass=StaticPool` +
`connect_args={"check_same_thread": False}`，或直接用文件 SQLite。

## 参考

- https://pytest-asyncio.readthedocs.io/
- https://www.python-httpx.org/async/
