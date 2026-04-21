'use client'

import { useTransition } from 'react'
import { toggleTodo } from '../_actions/todos'
import type { Todo } from '../lib/data'

export function TodoItem({ todo }: { todo: Todo }) {
  const [pending, startTransition] = useTransition()
  return (
    <li>
      <label>
        <input
          type="checkbox"
          checked={todo.completed}
          disabled={pending}
          onChange={() => startTransition(() => toggleTodo(todo.id))}
        />
        <span
          style={{
            textDecoration: todo.completed ? 'line-through' : 'none',
          }}
        >
          {todo.title}
        </span>
      </label>
    </li>
  )
}
