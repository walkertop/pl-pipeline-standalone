import type { ReactNode } from 'react'

export const metadata = {
  title: 'demo-nextjs-todo',
  description: 'pl-pipeline adapter-nextjs-web end-to-end demo',
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body
        style={{
          fontFamily: 'system-ui, -apple-system, sans-serif',
          maxWidth: 640,
          margin: '40px auto',
          padding: '0 16px',
          lineHeight: 1.6,
        }}
      >
        {children}
      </body>
    </html>
  )
}
