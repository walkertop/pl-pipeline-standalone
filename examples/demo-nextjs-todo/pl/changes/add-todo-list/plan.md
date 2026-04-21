# Plan: 添加 Todo 列表

> 由 `nextjs-architect` agent 基于 spec.md 产出；消费者 = `coder` + `guardian`。

---

## 1. 技术选型

### 1.1 渲染策略

| 路由 | 模式 | 理由 |
|------|-----|-----|
| `/todos` | RSC + Client island | 列表静态由服务端渲染利于 SEO；表单交互需 Client |

### 1.2 数据获取

| 场景 | 工具 | 缓存/失效 |
|------|------|---------|
| 列表数据 | 模块级 Map + 同步 getter | `revalidateTag('todos')` 驱动 |
| 创建/切换 | Server Action + `revalidateTag` | 立即失效 |

### 1.3 状态管理

- 服务端：模块级 Map（demo 用，生产请换 DB）
- 客户端：不引入全局状态；表单用 `useFormState`

---

## 2. 架构分层

```
app/todos/
├── page.tsx                      ← RSC 入口（export metadata + async Page）
├── layout.tsx                    ← 最小布局（共享 <h1>）
├── error.tsx                     ← 'use client' 错误边界
├── loading.tsx                   ← Suspense fallback
├── _components/
│   ├── CreateForm.tsx            ← 'use client'
│   ├── TodoList.tsx              ← RSC
│   └── TodoItem.tsx              ← 'use client'（checkbox 交互）
├── _actions/
│   └── todos.ts                  ← 'use server'
└── lib/
    └── data.ts                   ← 内存 Map + CRUD helpers
```

---

## 3. 关键决策 (ADR-lite)

### D1: 用内存 Map 而不是 Prisma/SQLite
- **选择**: 模块级 `Map<string, Todo>`
- **理由**: 本 demo 首要目标是展示 pl-pipeline，不想让读者被 ORM/migration 分心
- **代价**: 服务重启丢数据；生产**必须**替换

### D2: TodoItem 标 `'use client'` 而不是整列 Client
- **选择**: 只在 `<TodoItem>` 加 `'use client'`
- **理由**: 列表渲染保持 RSC（避免整棵树进浏览器）；只有 checkbox 交互需要 Client
- **代价**: 多一次组件边界切换，但可以忽略

### D3: 用 `useFormState` 而非 `useState + fetch`
- **选择**: `useFormState(createTodo, initialState)`
- **理由**: 原生对接 Server Action；表单错误反馈无需额外 state
- **代价**: 需要 React 18.3+

---

## 4. 风险与对策

| 风险 | 概率 | 影响 | 对策 |
|------|-----|-----|------|
| 忘记 `revalidateTag` 导致 UI 不更新 | 中 | 高 | VERIFY 阶段 `nextjs-reviewer` 强制审查所有 action |
| 模块级 Map 在 serverless 环境不 persist | 高 | 低（demo 不上线） | README 声明 demo 限制 |
| `'use client'` 越界导致 bundle 膨胀 | 低 | 低 | `next build` 检查 First Load JS < 120KB |

---

## 5. 里程碑

| 里程碑 | 交付物 | 实际耗时 |
|-------|-------|---------|
| M1 | 骨架路由 + data.ts | 20m |
| M2 | RSC TodoList + 初始数据 | 25m |
| M3 | Client CreateForm + Server Action | 35m |
| M4 | TodoItem toggle + 完整验收 | 20m |
| **合计** | — | **~1.7h** |

---

## 6. 回滚预案

- **路由级**: 删除 `app/todos/` 目录即可；不触及其他路由
- **数据级**: 无持久化数据，无需回滚
