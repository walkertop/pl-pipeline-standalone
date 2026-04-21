import { getTodos } from './lib/data'
import { CreateForm } from './_components/CreateForm'
import { TodoList } from './_components/TodoList'

export const metadata = {
  title: 'Todos',
  description: 'Manage your todo list',
}

export default async function TodosPage() {
  const todos = await getTodos()
  return (
    <>
      <CreateForm />
      <TodoList todos={todos} />
    </>
  )
}
