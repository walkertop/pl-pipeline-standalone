import type { ReactNode } from 'react'

export default function TodosLayout({ children }: { children: ReactNode }) {
  return (
    <section>
      <h1>Todos</h1>
      {children}
    </section>
  )
}
