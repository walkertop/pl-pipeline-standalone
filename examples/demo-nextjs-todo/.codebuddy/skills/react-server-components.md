---
id: react-server-components
name: react-server-components
triggers: ["rsc", "server component", "use server", "use client"]
description: React Server Components 使用指南 —— 何时 RSC/Client，如何传 props，常见坑位
version: 1.0.0
---

# React Server Components (RSC) 使用指南

## 核心心智模型

> **App Router 下组件默认是 Server Component**，`'use client'` 是显式下沉边界。

```
┌─────────────────────────────────────┐
│  Server Component (default)         │
│  - 直接 await fetch / DB            │
│  - 不能用 hooks / 浏览器 API         │
│  - bundle size = 0（不发到浏览器）   │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 'use client' Component        │  │
│  │  - useState/useEffect         │  │
│  │  - onClick/onChange           │  │
│  │  - 打包发到浏览器              │  │
│  │                               │  │
│  │  可以嵌 Server Component      │  │
│  │  作为 children / slot 传入    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 何时用 RSC（默认）

- 纯展示组件
- 需要服务端数据（DB / API / 文件系统）
- SEO 关键内容（让爬虫拿到完整 HTML）
- 大体积依赖（不想发到浏览器）

## 何时必须 `'use client'`

| 触发条件 | 示例 |
|------|------|
| 用 React Hooks | `useState`, `useEffect`, `useContext`, `useReducer` |
| 事件监听 | `onClick`, `onChange`, `onSubmit` |
| 浏览器 API | `window`, `document`, `localStorage` |
| 第三方库明确 client | `framer-motion`, `react-dnd` |
| 用 Class 组件 / Error Boundary | `class extends React.Component` |

## Props 传递规则

**可以** 从 RSC → Client 传：
- 基本类型（string / number / boolean / null）
- 数组 / 对象（只要内部是可序列化的）
- React 元素（`<ServerChild />`）
- Server Action 函数（有 `'use server'` 标记）

**不能** 传：
- 普通函数（`() => {}`）
- Date / Map / Set（Next 15 已部分支持，但谨慎用）
- Class 实例
- Symbol / BigInt（部分）

## 常见坑位

### 坑 1: Client 组件里 import Server 模块

```tsx
// ❌ 错误
'use client'
import { db } from '@/lib/db'   // 构建失败或把 db 发到浏览器

// ✅ 正确
'use client'
import { getItems } from '@/app/actions'  // Server Action 可以
```

### 坑 2: 以为 RSC 能热更新状态

```tsx
// ❌ 错误 — RSC 不在浏览器跑，useState 根本没意义
export default function Page() {
  const [count, setCount] = useState(0)  // 报错
  return ...
}
```

### 坑 3: 把 `'use client'` 放在 layout 顶层

```tsx
// ❌ 不好 — 整棵树都会被打包发到浏览器
'use client'
export default function Layout({children}) {...}

// ✅ 好 — 只把需要交互的那一小块标 client
export default function Layout({children}) {
  return <><Navbar /><InteractiveSearch />{children}</>
}
```

### 坑 4: Composition vs Import

```tsx
// ✅ 允许：Client 组件通过 children 嵌套 Server 组件
<ClientWrapper>
  <ServerData />   {/* Server 组件作为 children 传入 */}
</ClientWrapper>

// ❌ 禁止：Client 组件 import Server 组件
'use client'
import ServerComponent from './server-component'  // 会报错
```

## 调试技巧

- 编译错误 "Ecmascript file had an error" 多半是 RSC 里用了 hooks
- React Devtools 标签 `(Server)` 的是 RSC
- `next build` 会列出每个 route 的 First Load JS，看到异常大的多半是意外引入了 client bundle

## 参考

- 官方：https://nextjs.org/docs/app/building-your-application/rendering/server-components
- React RFC：https://github.com/reactjs/rfcs/blob/main/text/0188-server-components.md
