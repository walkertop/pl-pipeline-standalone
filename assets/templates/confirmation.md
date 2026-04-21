# Confirmation Request: [标题]

> **模板版本**: v1.1 (pl-pipeline)
> **用途**: 在 SPEC/PLAN 阶段遇到 BLOCKING Open Question 时，生成人机确认请求
> **消费者**: 人类决策者（产品/设计/后端）
> **门禁**: 收到 `APPROVED` / `REJECTED` / `MODIFIED` 明确答复后方可解除阻塞

---

## 元信息

| 字段 | 值 |
|------|-----|
| Change ID | `change-id` |
| 阶段 | SPEC / PLAN / IMPLEMENT |
| 请求编号 | CR-001 |
| 创建日期 | YYYY-MM-DD |
| 超时日期 | YYYY-MM-DD（T+2 工作日） |
| 阻塞等级 | BLOCKING / NON_BLOCKING |

---

## 请求内容

### 问题描述
[简洁描述当前遇到的问题，包括背景]

### 已有假设
[如果有默认假设，在此列出]

### 候选方案
| 方案 | 描述 | 优点 | 缺点 |
|------|------|------|------|
| A | ... | ... | ... |
| B | ... | ... | ... |

### 推荐方案
[推荐其中一个方案并说明原因]

---

## 待确认事项

- [ ] 确认方案选择
- [ ] 确认字段含义/接口行为/视觉规格（按需）
- [ ] 确认验收条件

---

## 影响范围

| 范围 | 影响 |
|------|------|
| 任务 | T5, T7 |
| 组件 | XxxComponent |
| 接口 | `URL_KEY_NAME` |
| 工时 | ± Xh |

---

## 答复区（由决策者填写）

- 决策: [ ] APPROVED  [ ] REJECTED  [ ] MODIFIED
- 选定方案: A / B / 自定义
- 补充说明:
- 决策者: @xxx
- 决策日期: YYYY-MM-DD
