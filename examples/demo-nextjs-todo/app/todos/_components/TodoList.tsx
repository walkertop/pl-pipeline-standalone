import type { Todo } from '../lib/data'
import { TodoItem } from './TodoItem'

export function TodoList({ todos }: { todos: Todo[] }) {
  if (todos.length === 0) {
    return <p>No todos yet.</p>
  }
  return (
    <ul>
      {todos.map((t) => (
        <TodoItem key={t.id} todo={t} />
      ))}
    </ul>
  )
}
