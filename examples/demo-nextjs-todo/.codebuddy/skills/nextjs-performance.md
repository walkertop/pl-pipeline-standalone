---
id: nextjs-performance
name: nextjs-performance
triggers: ["perf", "web vitals", "lcp", "bundle size", "lighthouse"]
description: Next.js Web Vitals 优化与 Bundle 瘦身实战手册
version: 1.0.0
---

# Next.js 性能优化手册

## 指标目标

| 指标 | 目标 | 含义 |
|------|-----|------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 首屏最大元素显示时间 |
| **INP** (Interaction to Next Paint) | < 200ms | 交互响应时间（取代 FID） |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 布局稳定性 |
| **TTFB** (Time to First Byte) | < 0.8s | 首字节响应 |
| **First Load JS** | < 150KB | 路由首次加载的 JS 体积 |

## 一、图片优化

### 永远用 `next/image`

```tsx
import Image from 'next/image'

// 首屏关键图片加 priority
<Image src="/hero.jpg" alt="..." width={1200} height={600} priority />

// 列表图片懒加载（默认就是）
<Image src={item.cover} alt="" width={400} height={300} />
```

好处：
- 自动 `<img loading="lazy">`
- 自动 srcset / AVIF / WebP
- 自动布局保留（避免 CLS）

## 二、字体优化

### 用 `next/font/google` 或 `next/font/local`

```tsx
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'], display: 'swap' })

export default function Layout({children}) {
  return <html className={inter.className}>{children}</html>
}
```

好处：
- 自动托管到同源（避免第三方 DNS）
- 构建时内联 `@font-face`
- 消除 FOUT (Flash of Unstyled Text)

## 三、代码分割

### 动态导入重依赖

```tsx
import dynamic from 'next/dynamic'

// 只有用到才加载
const HeavyChart = dynamic(() => import('./heavy-chart'), {
  loading: () => <Skeleton />,
  ssr: false,   // 如果这个组件只在浏览器有意义
})
```

### 按需加载 icons

```tsx
// ❌ 整个 icon 库都进 bundle
import * as Icons from 'lucide-react'

// ✅ 只加载用到的
import { Check } from 'lucide-react'
```

## 四、Bundle 分析

```bash
# next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
})

module.exports = withBundleAnalyzer({...})

# 运行
ANALYZE=true npm run build
```

查看 `client.html` / `server.html` 报告，识别：
- 意外进入 bundle 的服务端库
- 过大的第三方依赖
- 重复打包的模块

## 五、Streaming + Suspense

慢的部分不要阻塞整个页面：

```tsx
export default function Page() {
  return (
    <>
      <FastHeader />
      <Suspense fallback={<Skeleton />}>
        <SlowDataList />   {/* 5s 才 fetch 完 */}
      </Suspense>
      <FastFooter />
    </>
  )
}
```

HTML 会分块 flush，浏览器逐步渲染。

## 六、避免不必要的 re-render

### Client 组件 memo

```tsx
'use client'
import { memo } from 'react'

export const ExpensiveItem = memo(function ExpensiveItem({item}) {
  // ...
})
```

### 稳定的 props

```tsx
// ❌ 每次都是新对象，子组件无法 memo
<Child style={{ padding: 10 }} />

// ✅
const style = { padding: 10 }    // 模块级常量
<Child style={style} />
```

## 七、CSS 优化

- 用 **Tailwind** / CSS Modules / styled-components 都行，但保持单一
- 避免 runtime CSS-in-JS（emotion）进入 client bundle
- 全局 CSS 只放真正全局的（reset / tokens）

## 八、监控

### Next.js 自带

```tsx
// app/layout.tsx
export function reportWebVitals(metric) {
  // 发给 analytics
  console.log(metric)
}
```

### Vercel Analytics / Speed Insights

```tsx
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'

<Analytics />
<SpeedInsights />
```

## 九、CI 性能守护

```yaml
# .github/workflows/lighthouse.yml
- uses: treosh/lighthouse-ci-action@v10
  with:
    urls: |
      https://preview.myapp.com/
    budgetPath: ./lighthouse-budget.json
```

`lighthouse-budget.json`：

```json
[
  { "resourceSizes": [{ "resourceType": "script", "budget": 170 }] },
  { "timings": [{ "metric": "largest-contentful-paint", "budget": 2500 }] }
]
```

## 参考

- https://web.dev/vitals/
- https://nextjs.org/docs/app/building-your-application/optimizing
