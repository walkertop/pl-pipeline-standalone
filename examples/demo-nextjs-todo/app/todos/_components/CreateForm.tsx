'use client'

import { useActionState } from 'react'
import { useFormStatus } from 'react-dom'
import { createTodo, type CreateState } from '../_actions/todos'

const INITIAL: CreateState = { ok: null }

const ERROR_MESSAGE = {
  title_required: '请输入标题',
  title_too_long: '标题不能超过 100 字',
} as const

export function CreateForm() {
  const [state, formAction] = useActionState(createTodo, INITIAL)
  return (
    <form action={formAction}>
      <label htmlFor="title">New todo</label>
      <input id="title" name="title" maxLength={100} required />
      <SubmitButton />
      {state.ok === false && (
        <p role="alert">{ERROR_MESSAGE[state.error]}</p>
      )}
    </form>
  )
}

function SubmitButton() {
  const { pending } = useFormStatus()
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Adding…' : 'Add'}
    </button>
  )
}
