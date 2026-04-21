'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
  }, [error])

  return (
    <div role="alert">
      <p>Something went wrong loading todos.</p>
      <button onClick={() => reset()}>Try again</button>
    </div>
  )
}
