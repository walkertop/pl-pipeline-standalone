---
id: fastapi-no-sync-blocking-in-async
severity: error
scope: always
applies_to:
  glob:
    - "app/api/**/*.py"
    - "app/services/**/*.py"
    - "app/repositories/**/*.py"
  exclude_glob:
    - "**/__pycache__/**"
    - "**/.venv/**"
    - "tests/**"
detect:
  - kind: file_contains
    pattern: "async def "
  - kind: line_contains
    pattern: "^(?!\\s*#).*\\b(time\\.sleep|requests\\.(get|post|put|delete|patch)|urllib\\.request\\.)"
message: |
  检测到 async 代码里使用了同步阻塞调用（time.sleep / requests.* / urllib.request）。
  这会阻塞整个事件循环 —— 不只是当前协程，整个 FastAPI worker 都会卡住，
  吞掉异步框架的核心收益。
fix_hint: 用 asyncio.sleep() / httpx.AsyncClient / aiofiles 替代；必要时用 asyncio.to_thread() 封装 CPU bound
version: 1.0.0
---

# Rule: async 代码不要用同步阻塞调用

## 背景

```python
# ❌ 错
@router.get("/slow")
async def slow():
    time.sleep(5)            # 阻塞事件循环 5 秒！
    resp = requests.get(url) # 阻塞整个 worker
    return resp.json()
```

FastAPI 的并发模型是：**一个 event loop 跑多个协程**。上面这段代码会让
这个 loop 的所有请求都停 5 秒，而不只是这一条请求。在高并发场景下这会
直接让 QPS 塌掉。

## 修复

```python
# ✅ 对
import asyncio
import httpx

@router.get("/slow")
async def slow():
    await asyncio.sleep(5)
    async with httpx.AsyncClient() as client:
        resp = await client.get(url)
    return resp.json()
```

CPU 密集任务：

```python
# ✅ 对
import asyncio

@router.post("/compute")
async def compute(data: dict):
    result = await asyncio.to_thread(heavy_cpu_work, data)
    return result
```

## 检测算法

- 文件匹配 `app/api/**`、`app/services/**`、`app/repositories/**`
- 文件含 `async def `
- **同时**存在非注释行包含 `time.sleep` / `requests.(get|post|...)` / `urllib.request`

## 参考

- [FastAPI async docs](https://fastapi.tiangolo.com/async/)
