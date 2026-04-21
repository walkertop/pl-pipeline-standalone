/**
 * e2e 骨架 —— 真实运行请选 Playwright 或 Vitest + @testing-library。
 * 本 demo 不引入测试运行器，仅保留用例描述作为验收矩阵。
 */

export const scenarios = [
  {
    id: 'empty-state',
    story: '首次访问 /todos，若 store 为空，展示 "No todos yet."',
  },
  {
    id: 'create-success',
    story: '输入 "买菜" 点击 Add，列表立刻出现该项',
  },
  {
    id: 'create-too-long',
    story: '输入 101 字，提交后表单显示 "标题不能超过 100 字"',
  },
  {
    id: 'toggle-completed',
    story: '点击 checkbox，条目出现 line-through 样式，刷新后状态保留',
  },
] as const
