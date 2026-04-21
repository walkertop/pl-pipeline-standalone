---
name: nextjs-app-router
triggers: ["app router", "layout.tsx", "route group", "parallel route", "intercepting route"]
description: Next.js App Router 路由/布局/并行路由/拦截路由完整参考
---

# Next.js App Router 路由模式

## 文件约定速查

| 文件 | 作用 | 是否必须 |
|------|-----|--------|
| `page.tsx` | 页面入口，路由可达 | ✅（要能访问时） |
| `layout.tsx` | 嵌套布局（保持状态） | ❌ |
| `loading.tsx` | Suspense fallback | ❌（推荐） |
| `error.tsx` | 错误边界（自动 `'use client'`） | ❌（推荐） |
| `not-found.tsx` | 404 页面 | ❌ |
| `template.tsx` | 像 layout 但每次重建实例 | 罕用 |
| `default.tsx` | 并行路由回退 | 并行路由需要 |
| `route.ts` | 对外 API (HTTP 方法 handler) | ❌ |

## 路由分组 `(group)`

不影响 URL，仅用于组织代码 + 共享 layout。

```
app/
├── (marketing)/
│   ├── layout.tsx          ← 仅对营销页生效
│   ├── page.tsx            → /
│   ├── about/page.tsx      → /about
│   └── pricing/page.tsx    → /pricing
├── (dashboard)/
│   ├── layout.tsx          ← 要求登录
│   ├── dashboard/page.tsx  → /dashboard
│   └── settings/page.tsx   → /settings
```

## 动态段

| 模式 | 例 | 语义 |
|------|-----|-----|
| `[id]` | `/posts/[id]` | 单个动态值 |
| `[...slug]` | `/docs/[...slug]` | catch-all（1 个及以上） |
| `[[...slug]]` | `/docs/[[...slug]]` | 可选 catch-all（0 个及以上） |

用 `params` 获取：
```tsx
export default async function Page({
  params
}: { params: Promise<{ id: string }> }) {
  const { id } = await params
  return <>{id}</>
}
```

> Next.js 15 起 `params` 是 Promise，必须 await

## 并行路由 `@slot`

同屏同时渲染多块内容，每块独立 loading/error。

```
app/dashboard/
├── @analytics/page.tsx  ← 渲染到 {analytics} slot
├── @team/page.tsx       ← 渲染到 {team} slot
├── layout.tsx
└── default.tsx          ← 必需：其他 slot 不活动时的回退
```

```tsx
// layout.tsx
export default function Layout({
  children,
  analytics,
  team,
}: {
  children: React.ReactNode
  analytics: React.ReactNode
  team: React.ReactNode
}) {
  return <>
    {children}
    <aside>{analytics}</aside>
    <aside>{team}</aside>
  </>
}
```

## 拦截路由 `(.)...`

点击链接时弹 modal，直接访问 URL 显示独立页面。

```
app/
├── feed/
│   ├── page.tsx                    → /feed
│   └── (..)photo/[id]/page.tsx     → 从 /feed 点进 /photo/1 走这个
├── photo/
│   └── [id]/page.tsx               → 直接访问 /photo/1 走这个
```

约定前缀：
- `(.)` — 同级
- `(..)` — 上一级
- `(..)(..)` — 上两级
- `(...)` — 从 app 根开始

## metadata

### 静态

```tsx
export const metadata = {
  title: 'Home',
  description: '...',
}
```

### 动态

```tsx
export async function generateMetadata(
  { params }: { params: Promise<{id: string}> }
) {
  const { id } = await params
  const post = await fetch(`/api/post/${id}`).then(r => r.json())
  return { title: post.title }
}
```

## Route Handler (`route.ts`)

```ts
// app/api/items/route.ts
import { NextResponse } from 'next/server'

export async function GET(req: Request) {
  const items = await db.item.findMany()
  return NextResponse.json(items)
}

export async function POST(req: Request) {
  const body = await req.json()
  // ...
  return NextResponse.json({ ok: true }, { status: 201 })
}
```

默认**不缓存**。要缓存加 `export const revalidate = 60`。

## 参考

- https://nextjs.org/docs/app/building-your-application/routing
