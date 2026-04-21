import Link from 'next/link'

export default function Home() {
  return (
    <main>
      <h1>demo-nextjs-todo</h1>
      <p>
        这是 pl-pipeline <code>adapter-nextjs-web</code> 的端到端示范工程。
        所有可见产物（模板 / agents / skills / rules / change 文档 /
        Next.js 源码）都来自真实跑过五阶段的流水线。
      </p>
      <p>
        <Link href="/todos">进入 Todo 列表 →</Link>
      </p>
    </main>
  )
}
