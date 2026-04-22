---
id: fastapi-depends-pass-callable
severity: error
scope: always
applies_to:
  glob:
    - "app/api/**/*.py"
    - "app/services/**/*.py"
  exclude_glob:
    - "**/__pycache__/**"
    - "tests/**"
detect:
  - kind: line_contains
    pattern: "Depends\\([a-zA-Z_][a-zA-Z0-9_]*\\(\\)\\)"
message: |
  检测到 Depends(foo()) 的用法。Depends() 的参数必须是可调用对象本身，
  不是它的返回值。Depends(foo()) 会在 import 时就执行 foo()，依赖注入
  体系完全失效（尤其 yield-type dependency 的生命周期被短路）。
fix_hint: 改成 Depends(foo)，FastAPI 会在每次请求进来时调用它
---

# Rule: `Depends(foo)` 传可调用，不是 `Depends(foo())`

## 背景

```python
# ❌ 错
def get_db() -> AsyncSession: ...

@router.get("/users")
async def list_users(db: AsyncSession = Depends(get_db())):   # ← 调用了！
    ...
```

上面的 `get_db()` 会在**模块 import 时就执行一次**，返回值被当作依赖。
`Depends` 拿到的是**一个已经解析过的 AsyncSession**，而不是"每次请求新建
一个会话"的契约。结果：

- yield-type dependency 的 teardown 永远跑不到
- session 在全局被复用 → 并发安全出问题 / 事务混乱
- 测试替身（dependency_overrides）失效

## 修复

```python
# ✅ 对
@router.get("/users")
async def list_users(db: AsyncSession = Depends(get_db)):   # ← 传 callable
    ...
```

## 检测算法

- 匹配行正则 `Depends\([a-zA-Z_]\w*\(\)\)` — 即 `Depends(identifier())`
- 对所有 `app/api/**`、`app/services/**` 的 Python 文件扫

> ⚠️ 本规则会漏报 `Depends(MyCallableClass())`（传实例）这种**有时正确**
> 的写法，但这是 FastAPI 官方不推荐的风格，漏报代价低。

## 参考

- [FastAPI Dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/)
