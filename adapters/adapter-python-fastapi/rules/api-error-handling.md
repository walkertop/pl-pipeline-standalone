---
id: api-error-handling
version: 1.0.0
frontmatter_added_by: backfill-v1.3
---

# Rule: API 错误处理

> **Scope**: on-demand（设计/审查错误相关代码时加载）

## HTTP Status 映射

| Status | 语义 | 典型场景 |
|--------|-----|---------|
| 200 OK | 成功，返回资源 | GET 成功 / PUT 更新成功 |
| 201 Created | 创建成功 | POST 创建资源 |
| 204 No Content | 成功但无返回体 | DELETE / PATCH 无需返回 |
| 400 Bad Request | 客户端请求错误（格式） | JSON 解析失败 / 字段类型错 |
| 401 Unauthorized | 未认证 | token 缺失 / 过期 |
| 403 Forbidden | 已认证但无权限 | role 不足 |
| 404 Not Found | 资源不存在 | ID 无效 |
| 409 Conflict | 冲突 | unique 违反 / 乐观锁失败 |
| 410 Gone | 资源永久删除 | 软删 + 不再恢复 |
| 422 Unprocessable Entity | 语义错误 | Pydantic 校验失败（FastAPI 默认） |
| 429 Too Many Requests | 限流 | rate limit |
| 500 Internal Server Error | 未预期错误 | 代码 bug / 第三方崩 |
| 502/503/504 | 上游问题 | 依赖服务异常 / 超时 |

### 400 vs 422 的辨析

- **400**：请求**根本没法解析**（JSON 格式错）
- **422**：能解析但**业务语义错**（Pydantic 校验失败，FastAPI 默认就用 422）

两者皆客户端错误，统一用 422 更清晰。

## 响应结构（推荐 problem+json 风格）

```json
{
  "code": "item_not_found",
  "message": "Item with id xxx does not exist",
  "meta": { "id": "uuid-..." }
}
```

对应 Pydantic：

```python
class ApiError(BaseModel):
    code: str                        # machine-readable
    message: str | None = None       # human-readable
    meta: dict[str, Any] | None = None
```

## 业务错误分层

```python
# app/errors.py
class DomainError(Exception):
    code: str = "domain_error"
    http_status: int = 400

    def __init__(self, message: str = "", meta: dict | None = None):
        self.message = message or self.code
        self.meta = meta or {}

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
```

## 全局 handler

```python
# app/main.py
from fastapi import Request
from fastapi.responses import JSONResponse
from app.errors import DomainError

@app.exception_handler(DomainError)
async def domain_exc(req: Request, exc: DomainError):
    return JSONResponse(
        status_code=exc.http_status,
        content={"code": exc.code, "message": exc.message, "meta": exc.meta},
    )

@app.exception_handler(Exception)
async def unhandled_exc(req: Request, exc: Exception):
    # 生产：日志 + 5xx
    logger.exception("unhandled", extra={"path": req.url.path})
    return JSONResponse(
        status_code=500,
        content={"code": "internal_error", "message": "Internal server error"},
    )
```

## 客户端错误 vs 服务端错误

- **4xx 不应触发告警**：日志 info 级
- **5xx 必须触发告警**：日志 error 级 + Sentry / Pagerduty
- **429 / 503 有重试意义**：在 header 带 `Retry-After`

## 日志字段

每条错误日志至少带：

```python
logger.error(
    "error handling request",
    extra={
        "path": req.url.path,
        "method": req.method,
        "code": exc.code,
        "user_id": getattr(req.state, "user_id", None),
        "request_id": req.headers.get("x-request-id"),
    },
)
```

## 幂等性

- **GET / HEAD / OPTIONS**：天然幂等
- **PUT / DELETE**：必须幂等（删除不存在资源也返回 204 或 404，随约定）
- **POST**：默认非幂等。若需要：在 header 带 `Idempotency-Key`

## 禁忌

- ❌ 把堆栈信息原样返回客户端（泄漏实现）
- ❌ 把 2xx 用来表达失败（"业务失败但 HTTP 200"的反模式）
- ❌ `detail="something wrong"` 这种无结构字符串
- ❌ 对外 API 返回原生 SQLAlchemy 错误消息
