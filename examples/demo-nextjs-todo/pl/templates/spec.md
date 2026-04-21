# StructuredSpec: [变更/页面名称]

> **模板版本**: v0.1 (adapter-nextjs-web)
> **适用**: Next.js 13.4+ App Router 项目
> **消费者**: PLAN 阶段的 Planner Agent

---

## 1. 变更概述

| 字段 | 值 |
|------|-----|
| Change ID | `change-id` (kebab-case) |
| 变更类型 | 页面新增 / 页面重构 / 组件提取 / Server Action 新增 / 性能优化 / Bug 修复 |
| 路由路径 | `/app/<...>`（App Router 路径，如 `/app/(marketing)/pricing`） |
| 渲染模式 | RSC / Client Component / Hybrid / SSG / ISR |
| 关联产品线 | 由项目定义（如 Marketing / Console / Checkout） |
| 复杂度预估 | 🔴高 / 🟡中 / 🟢低 |
| 预估组件数 | 数字（基于 UI 拆分估算） |

---

## 2. 功能清单 (Feature List)

| ID | 功能名称 | 优先级 | 来源 | 验收标准 |
|----|---------|--------|------|---------|
| F1 | [功能描述] | P0 | PRD / Figma / Issue | [可测试的验收条件] |
| F2 | [功能描述] | P0 | ... | ... |
| F3 | [功能描述] | P1 | ... | ... |

> **优先级**: P0 核心（缺则页面不可用）/ P1 重要（有替代方案）/ P2 增强

---

## 3. UI 结构 (Screen Map)

```
┌─────────────────────────────┐
│  <Header />  (Server)       │  ← 复用: components/Header.tsx
├─────────────────────────────┤
│  [F1] 主内容区 (Server)     │  ← RSC，直接 fetch 数据
├─────────────────────────────┤
│  [F2] 交互区 (Client)       │  ← 'use client'，useState/useEffect
├─────────────────────────────┤
│  <Footer />  (Server)       │  ← 复用
└─────────────────────────────┘
```

> **标注规范**:
> - `(Server)` — React Server Component，默认，可直接访问 DB/ENV
> - `(Client)` — 加 `'use client'`，用于交互、浏览器 API、第三方库
> - `复用: <path>` — 已有组件路径
> - `新建: <path>` — 需新开发组件路径

---

## 4. 数据依赖 (Data Dependencies)

### 4.1 Server-side 数据源

| 数据源 | 获取方式 | 缓存策略 | 失效触发 |
|------|---------|---------|---------|
| `/api/items` | `fetch(..., { next: { tags: ['items'] } })` | `revalidate: 60` | `revalidateTag('items')` |
| DB `users` 表 | Prisma / Drizzle 直接查 | force-cache / no-store | Server Action 后 `revalidatePath` |

### 4.2 Client-side 数据源

| 数据源 | 库 | 用途 |
|------|-----|------|
| SWR / React Query | swr | 客户端轮询 |
| WebSocket | ws | 实时更新 |

---

## 5. Server Actions

> 列出本变更需要新增或修改的 Server Actions（若有）。

| Action | 签名 | 作用域 | 副作用 | 关联 F# |
|------|------|-------|-------|---------|
| `createItem` | `(data: FormData) => Promise<Item>` | 'use server' | INSERT + `revalidateTag('items')` | F2 |

---

## 6. 路由与跳转 (Navigation)

### 6.1 入口

| 来源路由 | 触发方式 | 携带参数 |
|---------|---------|---------|
| `/dashboard` | `<Link href>` / `router.push` | `?id=xxx` |

### 6.2 出口

| 目标路由 | 触发方式 | 携带参数 | 对应 F# |
|---------|---------|---------|---------|
| `/dashboard/items/[id]` | `redirect()` in action | `id` | F2 |

---

## 7. SEO / Metadata

| 字段 | 值 | 实现 |
|------|-----|------|
| `<title>` | 动态 | `generateMetadata` |
| `<meta description>` | 动态 | `generateMetadata` |
| Open Graph | ✅ | `/opengraph-image.tsx` |
| Sitemap 条目 | 是/否 | `/sitemap.ts` |

---

## 8. Web Vitals 目标

| 指标 | 目标值 | 验证方式 |
|------|-------|---------|
| LCP | < 2.5s | Lighthouse / Real User Monitoring |
| INP | < 200ms | Lighthouse |
| CLS | < 0.1 | Lighthouse |
| Bundle (First Load JS) | < 150KB | `next build` 输出表 |

---

## 9. 不确定项 (Open Questions)

| ID | 问题描述 | 阻塞等级 | 建议处理 | 找谁确认 |
|----|---------|---------|---------|---------|
| Q1 | [问题描述] | BLOCKING | [建议方案] | @产品 / @设计 / @后端 |

---

## 10. 验收基线

### 功能验收
- [ ] P0 功能全部实现
- [ ] 所有 Server Action 的成功/失败分支有测试
- [ ] 错误边界（`error.tsx`）和加载状态（`loading.tsx`）覆盖

### 非功能验收
- [ ] Lighthouse Performance ≥ 90
- [ ] TypeScript `tsc --noEmit` 0 错误
- [ ] `next lint` 0 错误
- [ ] `next build` 成功
