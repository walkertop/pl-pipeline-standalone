'use server'

import { revalidatePath } from 'next/cache'
import { z } from 'zod'
import { createTodoRecord, toggleTodoRecord, type Todo } from '../lib/data'

const CreateSchema = z.object({
  title: z
    .string()
    .trim()
    .min(1, 'title_required')
    .max(100, 'title_too_long'),
})

export type CreateState =
  | { ok: true; todo: Todo }
  | { ok: false; error: 'title_required' | 'title_too_long' }
  | { ok: null }

export async function createTodo(
  _prev: CreateState,
  formData: FormData
): Promise<CreateState> {
  const parsed = CreateSchema.safeParse({
    title: formData.get('title'),
  })
  if (!parsed.success) {
    const issue = parsed.error.issues[0]?.message
    const code =
      issue === 'title_too_long' ? 'title_too_long' : 'title_required'
    return { ok: false, error: code }
  }
  const todo = await createTodoRecord(parsed.data.title)
  // 数据源是模块级 Map（非 fetch），用 revalidatePath 让 RSC 重渲染
  revalidatePath('/todos')
  return { ok: true, todo }
}

export async function toggleTodo(id: string): Promise<void> {
  await toggleTodoRecord(id)
  revalidatePath('/todos')
}

