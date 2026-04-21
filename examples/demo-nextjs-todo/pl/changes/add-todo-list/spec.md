# StructuredSpec: 添加 Todo 列表

> 本文按 `adapter-nextjs-web` 提供的 `templates/spec.md` 模板填写。
> 这是一份**真实**跑过的 SPEC 文档，是 IMPLEMENT 阶段 Next.js 源码的依据。

---

## 1. 变更概述

| 字段 | 值 |
|------|-----|
| Change ID | `add-todo-list` |
| 变更类型 | 页面新增 |
| 路由路径 | `/app/todos` |
| 渲染模式 | RSC（列表） + Client island（表单） |
| 关联产品线 | Demo / 教学 |
| 复杂度预估 | 🟢 低 |
| 预估组件数 | 3 |

---

## 2. 功能清单 (Feature List)

| ID | 功能名称 | 优先级 | 来源 | 验收标准 |
|----|---------|--------|------|---------|
| F1 | 展示 Todo 列表（空态/非空态） | P0 | demo 设计 | 初次访问 `/todos` 返回 HTML 包含所有 todo 项；空库时显示 "No todos yet." |
| F2 | 创建 Todo（表单 + Server Action） | P0 | demo 设计 | 提交表单后页面立刻反映新项；触发 `revalidateTag('todos')`；校验 title 非空、≤100 字符 |
| F3 | 切换完成状态 | P1 | demo 设计 | 点击 checkbox 即时更新 completed 状态；无闪烁；状态持久 |

---

## 3. UI 结构 (Screen Map)

```
┌─────────────────────────────┐
│  <Header />      (Server)   │  ← 复用: layout.tsx 全局 header
├─────────────────────────────┤
│  [F2] <CreateForm />        │  ← 新建: 'use client'，表单 + useFormState
├─────────────────────────────┤
│  [F1/F3] <TodoList />       │  ← 新建: RSC，内部 <TodoItem> 可为 Client
│    ┌──────────────────────┐ │
│    │ [ ] 买菜             │ │
│    │ [✓] 看医生           │ │
│    └──────────────────────┘ │
├─────────────────────────────┤
│  <Footer />      (Server)   │
└─────────────────────────────┘
```

组件说明：
- `app/todos/page.tsx` — RSC 入口
- `app/todos/_components/CreateForm.tsx` — `'use client'` 表单
- `app/todos/_components/TodoList.tsx` — RSC 渲染列表
- `app/todos/_components/TodoItem.tsx` — `'use client'` 单行（含 checkbox）

---

## 4. 数据依赖 (Data Dependencies)

### 4.1 Server-side

| 数据源 | 获取方式 | 缓存策略 | 失效触发 |
|------|---------|---------|---------|
| 内存 Map (`app/todos/lib/data.ts`) | 直接调用 `getTodos()` 同步函数 | 无（demo 用 module-level Map，生产应换 DB） | Server Action 后 `revalidateTag('todos')` |

### 4.2 Client-side

无。

---

## 5. Server Actions

| Action | 签名 | 作用域 | 副作用 | 关联 F# |
|------|------|-------|-------|---------|
| `createTodo` | `(prev: State, formData: FormData) => Promise<State>` | `'use server'` | Map 插入 + `revalidateTag('todos')` | F2 |
| `toggleTodo` | `(id: string) => Promise<void>` | `'use server'` | Map 更新 + `revalidateTag('todos')` | F3 |

---

## 6. 路由与跳转

### 入口
| 来源路由 | 触发方式 | 携带参数 |
|---------|---------|---------|
| `/` | `<Link href="/todos">` | 无 |

### 出口
无（本 change 是终端页面）。

---

## 7. SEO / Metadata

| 字段 | 值 | 实现 |
|------|-----|------|
| `<title>` | `"Todos"` | 静态 `export const metadata` |
| `<meta description>` | `"Manage your todo list"` | 同上 |
| Open Graph | 本 demo 跳过 | — |

---

## 8. Web Vitals 目标

| 指标 | 目标值 | 验证方式 |
|------|-------|---------|
| LCP | < 1.5s | 本地 Lighthouse |
| INP | < 200ms | 手动交互验证 |
| CLS | < 0.1 | Lighthouse |
| Bundle (First Load JS) | < 120KB | `next build` 输出 |

---

## 9. 不确定项 (Open Questions)

| ID | 问题 | 阻塞等级 | 建议 | 状态 |
|----|------|---------|-----|------|
| Q1 | 数据层用内存 Map 还是引入 Prisma+SQLite？ | NON_BLOCKING | demo 用内存 Map 更聚焦流水线本身；生产 adapter 案例说明切换方式 | 已决（内存 Map） |

---

## 10. 验收基线

### 功能验收
- [x] F1 列表展示（空态 + 非空态）覆盖
- [x] F2 创建表单提交 + revalidate 成功
- [x] F3 toggle 切换正确
- [x] error.tsx / loading.tsx 占位

### 非功能验收
- [x] `npx tsc --noEmit` 0 错误（由 `scripts/adapter-nextjs-web-verify.sh` 驱动）
- [x] `next lint` 0 错误
- [x] RSC 边界清晰（仅叶子 Client 组件）
