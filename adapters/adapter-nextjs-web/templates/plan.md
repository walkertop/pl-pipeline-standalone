# Plan: [变更名称]

> **模板版本**: v0.1 (adapter-nextjs-web)
> **前置产物**: `spec.md`
> **后继产物**: `taskdag.md` / `api.md` / `testmatrix.md`

---

## 1. 技术选型

### 1.1 渲染策略

| 路由 | 模式 | 理由 |
|------|-----|-----|
| `/app/(marketing)/*` | SSG | 静态内容，构建时生成 |
| `/app/dashboard/*` | RSC + Server Actions | 动态 + 需授权 |
| `/app/api/*` | Route Handler | 对外 API |

### 1.2 数据获取

| 场景 | 工具 | 缓存/失效 |
|------|------|---------|
| 首屏数据 | RSC 内 `await fetch(..., { next: { revalidate } })` | tag-based |
| 客户端实时 | SWR | focus revalidation |
| 表单提交 | Server Action + `revalidatePath` | 立即 |

### 1.3 状态管理

- **无全局状态**：优先用 URL / Server State
- **如需**：Zustand（轻）/ Redux Toolkit（重）
- **避免**：context over everything（破坏 RSC 边界）

---

## 2. 架构分层

```
app/(scope)/<route>/
├── page.tsx              ← 页面入口 (RSC 默认)
├── layout.tsx            ← 布局 (RSC 默认)
├── loading.tsx           ← Suspense fallback
├── error.tsx             ← 'use client' 错误边界
├── not-found.tsx         ← 404
├── _components/          ← 本路由私有组件
│   └── InteractiveForm.tsx (use client)
└── _actions/             ← Server Actions
    └── submit.ts (use server)
```

---

## 3. 关键决策 (ADR-lite)

### D1: RSC 还是 Client Component？
- **选择**: [RSC / Client]
- **理由**: [...]
- **代价**: [...]

### D2: 缓存粒度？
- **选择**: [per-tag / per-path / per-request]
- **理由**: [...]

---

## 4. 风险与对策

| 风险 | 概率 | 影响 | 对策 |
|------|-----|-----|------|
| Next.js 版本升级破坏 API | 中 | 高 | pin next@<x.y> 到 CI |
| RSC → Client 边界被越界 import | 高 | 中 | `react-server` lint rule |
| 缓存失效遗漏 | 中 | 高 | 所有 Server Action 显式 `revalidateTag/Path` |

---

## 5. 里程碑

| 里程碑 | 交付物 | 预估 |
|-------|-------|------|
| M1 | 骨架页面（静态 UI 跑通） | 0.5d |
| M2 | 数据接入 + RSC 完成 | 1d |
| M3 | 交互完成（Client 组件 + Server Action） | 1d |
| M4 | 验证通过（Lighthouse / tsc / lint） | 0.5d |

---

## 6. 回滚预案

- **路由级**：在 `app/` 下复制原 `page.tsx` 为 `page.backup.tsx`
- **发布级**：Vercel revert
- **数据库**：迁移脚本必须可逆（`up.sql` + `down.sql`）
