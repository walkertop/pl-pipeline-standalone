# Working With Fuzzy Intent

> **副标题**：模糊、反复、渐进 —— 怎么用 pl-pipeline 而不被它框死

pl-pipeline 是个**格式化工具**（structured artifacts, measurable gates, event trace），但**需求本质是模糊的、意图是随沟通演进的**。这两者的张力如果处理不好，工具会逼着你把还没想清楚的事情假装想清楚了，然后在后面阶段反弹、返工、打脸。

这份文档是一份**辩证的使用方法论**，不是用法手册（用法看 [`dashboard-guide.md`](../dashboard-guide.md)、[`CHANGELOG.md`](../../CHANGELOG.md) 和各阶段命令文档）。

---

## 核心态度

> **SPEC 不是你跟工具的一次性握手，而是你跟自己意图的一场持续对话。**

| 常见误解 | 实际情况 |
|----------|---------|
| "敲 `/pl:proposal` 一次就有完美 spec.md" | 一次只写出**能开始讨论**的骨架，真正的 spec 是 3~10 轮往返后凝结出来的 |
| "SPEC 定了就不许改" | SPEC 可以（且应该）在 PLAN/IMPLEMENT 阶段反向修订，工具会记录每次修订 |
| "所有需求都要有答案" | 允许 `(TBD)` / `(defer)` / `(assume)` 标记，让不确定性可见而不是被强行消除 |
| "不通过 A0 就不能进 PLAN" | A0 可"软通过"：有 TBD 但**不阻塞**，只在 Dashboard 上亮黄让你心里有数 |

---

## 四种"模糊"的处理方式

不同类型的模糊需要不同的处理器。硬把它们都塞成 `R1 / R2 / R3` 是粗暴的格式化。

### A 类 · 已知未知（Known Unknowns）
你**知道有这件事**，但还没想好具体怎么做。

**例**："需要搜索功能，但还没想好要不要支持模糊匹配和拼音。"

**处理**：写进 spec，标 `(TBD)`，在 `open_questions` 段落集中追问。
```markdown
## R2: 搜索
- R2.1 关键字搜索（精确匹配至少要）
- R2.2 (TBD) 是否支持模糊匹配？见 Q-002
- R2.3 (TBD) 是否支持拼音？见 Q-003

## Open Questions
- Q-002: 模糊匹配方案 —— 前端 fuse.js / 后端 pg_trgm / 都上？
- Q-003: 拼音 —— 如果 Q-002 上了 pg_trgm，拼音可以免费得；否则需要单独加库
```

**门禁语义**：A0 软通过（亮黄），进 PLAN 时让 planner 专门把 Q-002/003 单独提交一轮**定点对话**。

### B 类 · 未知未知（Unknown Unknowns）
你**不知道有这件事**，但做着做着发现"原来这也要考虑"。

**例**：做到一半发现 "移动端 Safari 不允许 `getUserMedia` 在非 HTTPS 域名用"。

**处理**：**反向修 SPEC**。这是被鼓励的行为，不是失败。
```bash
# 在 IMPLEMENT 阶段发现后
/pl:explore   # 进入探索模式讨论这个新约束
# 讨论完后回到 spec.md 加新条目
```

SPEC 追加一条 `## NF4: HTTPS-only for camera access`，带 `added_at: 2026-04-23 during IMPLEMENT T05`。**trace 会自动记录 `spec.revision` 事件**，审计链路完整。

### C 类 · 假装已知（False Certainty）
你**以为自己知道**，但其实没想清楚。**这是最危险的一类**。

**例**："用 SQLite 就行" —— 但实际上你没想过并发写入、备份、迁移策略。

**处理**：让 planner 在 B1 门禁前做一次"假设挑战"（assumption challenge），列出 spec 里所有**隐含的、未明说的、但技术决策会依赖的**前提。

Planner 应该问："你写了用 SQLite，我假设单机单用户，不支持并发写入，备份靠手动拷文件 —— 如果有一条不对，现在告诉我。"

### D 类 · 暂时搁置（Deferred）
你**知道要做，但不是现在**。

**例**："先做 v1 只支持个人使用，后面 v2 再做多用户。"

**处理**：明确标 `(defer to v2)`，spec.md 有 `## Out of Scope` 段落。门禁 A0 不要求这些条目有实现路径。
```markdown
## Out of Scope (v1)
- 多用户账号体系（deferred to v2）
- 社交分享功能（deferred to v2）
- 离线完整可写（v1 只做离线可读）
```

---

## 三种修订回流的正确做法

SPEC 不是单行道。下游反向修 SPEC 的动作要被**记录**、**受控**、**可审计**。

### 修订 1 · PLAN → SPEC（"方案让我发现需求没说全"）
```bash
# 在 PLAN 阶段
/pl:explore
# 讨论后
# 1. 修 spec.md（加新条目 R1.4 或 NF4）
# 2. 修 .state.md：记 spec_revision_reason
# 3. 重新走一遍 /pl:plan 让 taskdag / api.md 同步更新
```

**trace 事件**：`spec.revision { stage: PLAN, reason: "...", delta: {added: [...], modified: [...]} }`

### 修订 2 · IMPLEMENT → SPEC（"代码写出来才知道原需求不合理"）
```bash
# 在 IMPLEMENT 阶段发现 bug
/pl:explore   # 暂停编码，先讨论
```
最常见：**测试矩阵发现某个场景 spec 没考虑**，或**API 真实调用发现字段设计有矛盾**。

**修法同上**，但额外要做：
- testmatrix.md 新增场景
- 可能需要 rollback 某些 task（在 taskdag 标 `status: superseded`）

### 修订 3 · VERIFY/SMOKE → PLAN（"跑起来才知道方案不对"）
最贵的一种。典型是：smoke probe 失败，发现架构决策错了（例如选了错误的 state 管理方案）。
```bash
# 不要硬改代码让 probe 过
/pl:explore   # 先想清楚
# 然后：
# 1. 修 plan.md（记新的架构决策 + 为什么之前的错了）
# 2. 修 taskdag.md（旧 task 标 superseded，新 task 标 replaces=T0x）
# 3. 回到 /pl:implement 按新 taskdag 跑
```

**retro-miner** 会把这种"IMPLEMENT 后期回流到 PLAN"的模式挖成 anti-pattern，下次做类似项目时 planner 会被警示。

---

## 意图澄清的反模式（不要这样做）

### 反模式 1：一次性把模糊全问完（assumption dump）
```
AI: "在开始前我需要你回答 27 个问题：
1. 数据库选什么？
2. 部署在哪？
...
27. 国际化支持哪些语言？"
```
**为什么不好**：用户在这个时候既没耐心也没思路回答 27 个问题；强行回答会得到大量 C 类（假装已知）答案，埋雷。

**正确做法**：planner 只问**阻塞下一步的关键 3 个问题**，其他的标 `(TBD)` 放 open_questions，到真要做那块时再问。

### 反模式 2：AI 把"未明说的"自动补全成决策
```
你说："做个图书管理"
AI 自动生成 spec："技术栈 Next.js + FastAPI + PostgreSQL + Redis + Docker + K8s..."
```
**为什么不好**：这不是辅助你思考，这是强塞一套意见。

**正确做法**：AI 应该说 "我推测你倾向 [A/B/C]，基于 ... 理由；但这是个决策点，你的选择会影响后续 X / Y / Z —— 你想怎么定？"

### 反模式 3：门禁见绿就闭嘴
Spec 通过 A0 → AI 说 "spec 已就绪，进入 PLAN" → 再也不回看 spec。
**实际上**：SPEC 应该被**持续质疑**，尤其每次 gate 过门时问一次 "这条 spec 条目我们真的要实现吗？"

---

## 作为用户，你的"模糊权利"清单

在任何阶段，你都有权：

| 权利 | 说明 |
|------|------|
| **保留 TBD** | 不是所有事都要现在有答案。spec.md 里允许 `(TBD)` 标记，占位不阻塞 |
| **延迟到 v2** | `## Out of Scope` 是一等公民，不写明是 v1 scope 的都默认 out |
| **反向改 spec** | PLAN/IMPLEMENT 任何阶段都可以改 spec，工具负责记录理由 |
| **让 AI 挑战你的假设** | 随时 `/pl:explore` 请求 AI 列出"我以为是这样但其实没说清"的前提 |
| **拒绝工具推荐** | AI 推荐的技术栈 / 架构 / 命名只是**候选**，你有权全部推翻 |
| **中途改项目 scope** | 发现"这不是一个 change 能覆盖的"时，允许把一个 change split 成多个 |

---

## 作为 AI，我的约束清单

当我在 pl-pipeline 里帮你时，我必须：

1. **先给建议，再等你拍板** —— 我可以推荐，但不替你决定
2. **把"推理链路"亮出来** —— 说"我建议 SQLite 因为你说了单用户且不想运维"而不是直接写 `db: sqlite`
3. **发现 C 类模糊时主动暂停** —— 即使流程压力要求推进，发现你"假装已知"时我必须先提醒
4. **允许回流** —— 你改 spec 时我不能说"这打乱了流程"，只能说"好的，我来同步 plan.md 和 taskdag.md"
5. **记录每次决策背后的前提** —— plan.md 的每个决策都要标 `assumes: [R1.1 + NF2]`，这样前提变化时能知道哪些决策要重看

---

## 工具层面的"辩证配合"（v1.5+ 计划）

目前 pl-pipeline 的门禁偏 "是/否" 二值判断，未来几个 patch 会加入**软约束**概念：

| 现状 | 未来 |
|------|------|
| 门禁 A0：spec.md 完整才能过 | 门禁 A0：有 TBD 可软通过，Dashboard 亮黄 + trace 事件 `gate.soft_pass` |
| spec 修订没有专用事件 | 新增 `spec.revision` 事件，记录 delta + 原因 + 触发阶段 |
| 反向回流只能靠注释 | taskdag.md 支持 `status: superseded` / `replaces: T0x` 字段 |
| 假设挑战靠 AI 自觉 | planner skill 里强制"assumption challenge"子步骤 |

这些都是 **v1.5+ roadmap** 的组成部分，与"核心资产迁移"（见 `docs/milestones/v1.5-migrate-core-assets.md`）一起落地。

---

## 一个真实例子：从"做个藏书管理"到可运行

为了避免上一版文档的线性错觉，我重写一次，**刻意保留反复和模糊**。

### 第 1 轮 · 你：
> "我想做个藏书管理，扫 ISBN 录入，能搜索。"

### 第 1 轮 · AI：
> 我先把骨架搭一下。几个问题必须先定，其他先标 TBD：
> - **关键问题 1**：单用户还是多用户？这影响整个架构。
> - **关键问题 2**：移动端为主还是 Web 为主？扫描 ISBN 基本上要移动端 camera。
> - **关键问题 3**：数据放在你个人设备还是云端？
>
> 其他的我都列成 TBD 了，等下确定。spec 初稿见 `spec.md`。

### 第 1 轮 · 你：
> "单用户，移动端为主但 Web 也要看，数据本地就行。"

### 第 2 轮 · AI：
> 好，那我把 spec 更新了。注意以下"隐含前提"我帮你显性化出来了：
> - 单用户 → 不需要登录系统（省一大块）
> - 本地数据 → 备份策略你要决定：完全不备份 / 手动导出 / 云盘自动同步？这是 Q-004
> - 移动 + Web 共用 → "本地数据"其实是移动端本地，Web 端怎么访问？你用 tailscale？还是 Web 直接连手机的 localhost？这是 Q-005
>
> 这两个是 **C 类模糊**（你可能以为定了，其实没）。要不要 explore 一下？

### 第 2 轮 · 你：
> "Q-004 先不备份，Q-005 先只做移动端，Web 端 defer 到 v2。"

### 第 3 轮 · AI：
> 收到。那 spec v0.3 定下来了：
> - v1 scope：**移动端 only**
> - Out of Scope (v2)：Web 端、备份
> - 可以进 PLAN 了。
>
> 门禁 A0 **软通过**（有 2 个 TBD：分类规则、导出格式），不阻塞，Dashboard 会亮黄。

### ...然后才进 PLAN。

注意这里面：
- SPEC 经历了 **3 轮**，不是一轮
- 有些需求被**下降到 v2**
- 有些模糊**保留为 TBD** 而不是强行定死
- AI 的每个问题都是 **"为什么现在必须问"**，不是一次性大轰炸

这才是"辩证地把模糊变成格式化"。

---

## 相关文档

- [`dashboard-guide.md`](../dashboard-guide.md) — Dashboard 使用手册
- [`docs/milestones/2026-04-v1.3.x-summary.md`](../milestones/2026-04-v1.3.x-summary.md) — 观察层里程碑
- [`docs/milestones/v1.5-migrate-core-assets.md`](../milestones/v1.5-migrate-core-assets.md) — 核心资产迁移计划（含 `spec-normalizer` 脱敏）
- [`CHANGELOG.md`](../../CHANGELOG.md) — 完整变更
