---
urn: urn:piao:kernel:spec:competitive/knowledge_flywheel@v1
kind: spec
rev: v1
status: draft
category: competitive-research
---

# 知识飞轮产品对标：Cursor Rules / Claude Skills / Continue / RAG 系

> 这一类产品回答的是：**LLM agent 如何"越用越聪明"**？如何把"每次对话的发现"沉淀为"下次自动可用的规则"？
> piao-pipeline 的 Skills / Rules / Evolution 三层本质上就是这个问题。对标对象的成败经验非常锐利。

---

## 1. 代表产品

| 项目 | 类别 | 核心模式 |
|------|------|---------|
| **Cursor Rules** | IDE 内 rules | `.cursor/rules/*.mdc` + glob 触发 + 手动或 AI 维护 |
| **Claude Skills** | Anthropic 官方 skill 系统 | SKILL.md + progressive disclosure + bundled scripts |
| **Continue.dev** | 开源 AI IDE | Rules + prompts + context providers (不分层) |
| **Aider conventions** | Aider 的 `.aider.conf` + `CONVENTIONS.md` | 单文件约定 + 每次注入 |
| **GitHub Copilot instructions** | `.github/copilot-instructions.md` | 仓库级单文件 |
| **经典 RAG** (LlamaIndex / LangChain RAG) | 文档检索增强 | 分块 + embedding + 向量检索 + 注入 |
| **Mem0 / GPTMe memory** | Agent 长期记忆 | 对话中自动抽取 + 持久化 + 检索回注 |
| **Letta (ex-MemGPT)** | OS-like memory 管理 | 分层记忆（working / archival） + self-edit |

## 2. 它们解决了什么问题

**共同问题**：LLM 的 context window 是有限的、一次性的。如何把**跨会话的经验**持久化并在合适的时机调回？

**分流**：
- **Rules 系**（Cursor / Continue / Aider）：**显式规则 + 触发条件**，人写或 AI 提议，强制注入
- **Skills 系**（Claude / Claude Code）：**分层文档 + 可选加载**，agent 自己决定加载哪个
- **RAG 系**：**检索召回**，问题相似度高则召回
- **Memory 系**（Mem0 / Letta）：**自动抽取 + 分层存储**，追求"越用越熟"

## 3. 架构模式提取

### 3.1 Cursor Rules 的模式：**glob 触发 + metadata 匹配**

Cursor 的 `.cursor/rules/*.mdc` 每个文件头部：
```yaml
---
description: React component conventions
globs: ["**/*.tsx", "**/*.jsx"]
alwaysApply: false
---
```

agent 打开某文件时，匹配 glob 的 rule 自动注入 context。

**关键洞察**：**把"rule 什么时候该生效"显式声明出来**，而不是靠 agent 自己判断。

→ **对 piao-pipeline 的启发**：
  - 我们当前 `.codebuddy/rules/*.md` **没有**触发条件，全靠 agent 读 description 自己决定
  - **改进**：rule 的 front-matter 应该包含一个 `applies_to` 字段（URN pattern 或 glob），kernel 强制的 Rule 契约里写入
  - 这能把 "什么时候看 rule" 的判断从 LLM 挪到文件系统 / kernel 层面，降低失误

### 3.2 Claude Skills 的模式：**Progressive Disclosure**

Claude Skills 的三层结构：
- **SKILL.md**：简短描述 + 触发词 + 何时使用（只有这个被所有 agent 看到）
- **scripts/**：bundled 可执行代码（按需加载）
- **references/**：详细参考文档（按需加载）

**关键洞察**：**默认最少暴露，agent 需要时才展开**。避免 context 膨胀。

→ **对 piao-pipeline 的启发**：
  - 我们的 skill 体系已经是这个设计，做得不错
  - 但 **rule 和 skill 在 progressive disclosure 上不对齐**——rule 是整个文件全文注入，skill 是分层注入
  - **改进**：把 rule 也统一到 progressive disclosure，rule front-matter 的 `description` 字段是第一层，正文是第二层
  - 这对应我们 kernel 的 Rule artifact 模型

### 3.3 Continue.dev 的反面教材：**不分层导致不好用**

Continue 早期把 rules / prompts / context providers 混在一起，导致用户不知道什么情况该用哪个。

→ **对 piao-pipeline 的反面启发**：
  - 我们的 **Rule vs Skill 的边界必须清晰**
  - 当前的分法（Rule = 约束"怎么做"，Skill = 实现"做得快"）是对的，但需要在 kernel 文档里**强化**这个分工
  - 具体到边界的**判断规则**，可以写进 `07-extensibility.md` 的 §2 扩展点说明里（下次 rev）

### 3.4 RAG 的教训：**"聪明检索"经常不如"精准触发"**

RAG 系的经典失败：embedding 检索召回 top-k 文档，但其中有 3/5 是不相关的噪声，反而污染 context。

**关键洞察**：**与其追求"检索聪明"，不如追求"触发精准"**。

→ **对 piao-pipeline 的启发**：
  - 我们**不应该**在 v0.1 引入向量检索
  - rule 和 skill 都应该靠**结构化触发条件**（glob / URN pattern / 事件类型）决定何时生效
  - 这也符合我们一贯的"契约 > 智能"哲学

### 3.5 Mem0 / Letta 的模式：**自动抽取 + 分层遗忘**

Mem0 在每次对话结束时让 LLM 抽取"这次对话里值得记住的 fact"，存入向量库；Letta 更激进，有 working memory（活跃）和 archival memory（归档），agent 可以 self-edit。

**关键洞察**：**记忆不是存原始对话，是存"抽取后的结构化 fact"**。

→ **对 piao-pipeline 的启发（大）**：
  - 这**完全对应** evolution_source → evolution_proposal → promotion 的流程
  - 我们的 `error-log.md` 就是一种 Mem0 式的"抽取后的 fact"
  - **改进**：evolution_source 的 kind 应该**不止 error_log**，还可以包括：
    - `insight`（从 trace 事件里发现的模式）
    - `outage`（生产事故复盘）
    - `review_note`（code review 中的反复提醒）
  - 每种都走同一个 promotion 链路（→ rule / → skill / → spec）
  - 这对应 M3 的 event 模型 和 M4 的 evolution 层设计

### 3.6 GitHub Copilot / Aider 的反面教材：**单文件上限很快撞**

Copilot instructions 和 Aider CONVENTIONS 都是**单文件**，组织大了就变成几千行的巨型文件，LLM 根本读不细。

→ **对 piao-pipeline 的反面启发**：
  - 我们**不能走单文件路线**
  - Rule 和 Skill 都必须是**多文件 + 精准触发**
  - 这是我们已经在做的，对标验证了选择正确

## 4. 对 piao-pipeline 的启发（正反两面）

### 4.1 正向启发 ✅

1. **Rule 要有显式触发条件**（Cursor glob）—— 要加 `applies_to` 字段
2. **Progressive disclosure 要统一到 rule**（Claude Skills） —— 下次 rule 模型 rev 时做
3. **evolution_source 种类应该扩展**（Mem0 / Letta）—— 不止 error_log，还有 insight / outage / review_note
4. **触发精准 > 检索聪明**（RAG 教训）—— v0.1 绝不引入向量检索
5. **多文件 + 按需加载**（Skill vs 单文件路线）—— 已做对，继续坚持

### 4.2 反向启发 ⚠️

1. **不要让 rule 变成 LLM 的 "prompt 补丁"**：Cursor 社区已有这个苗头，用户用 rule 打补丁修 Cursor 的 bug。piao-pipeline 的 rule 必须是"约束规范"，不能是"修 agent 缺陷"
2. **不要追求完全自动的 evolution**：Mem0 自动抽取有幻觉风险。piao-pipeline 的 evolution_proposal **必须有人的 review**，kernel 强制 `approved_by` 字段不为空才能 promote
3. **不要混 rule 和 skill**：Continue 的教训——边界不清用户就用不好。我们保持 Rule = 约束，Skill = 能力

## 5. 风险 / 反例

**反例 1：Rule 膨胀**。
任何团队用 Cursor 超过 3 个月，`.cursor/rules/` 会积累几十个 rule，其中一半过期。
**对策**：piao-pipeline 的 rule 必须有 **lifecycle 状态**（draft / active / deprecated / archived），且 drift 检查会标记"从未被引用的 rule" 提醒审计

**反例 2：Skill 过度 bundle**。
Claude Skills 的 scripts/ 塞进任意 Python 代码，容易变成 "不受 artifact 管理的魔法脚本"。
**对策**：piao-pipeline 的 skill 里的 scripts 必须**本身是 artifact**（有 URN 和 rev），不能是"黑箱附件"

**反例 3：Memory 会"记住错误信息"**。
Mem0 的失败案例：早期对话中的错误结论被抽取为"fact"，后续反复污染。
**对策**：piao-pipeline 的 evolution_source 引入必须有**证据链**（指向具体的 trace_event URN），不能是"我觉得应该这样"的裸文字

**反例 4：过度依赖 AI 自己决定该加载什么**。
Claude Skills 把"该加载哪个 skill"完全交给 LLM 判断。LLM 经常"想不起来"某个 skill。
**对策**：piao-pipeline 的 skill / rule 触发条件**既支持 LLM 主动加载，也支持 kernel 根据 URN 自动注入**（尤其是在特定 pipeline 阶段，直接按 `applies_to` 规则注入对应 rule）

## 6. 不采纳清单

| 对标做法 | 不采纳原因 |
|---------|-----------|
| **向量检索 / embedding 召回** | 触发精准 > 检索聪明 |
| **单文件 instructions** | 扩展性差 |
| **全自动 evolution**（Mem0 风） | 幻觉风险，必须有人 review |
| **rule 作为 prompt 补丁**（Cursor 常见误用） | 违背 rule 的"约束"定位 |
| **skill 内任意脚本** | 必须本身是 artifact |

---

**本篇结论**：知识飞轮产品给 piao-pipeline 的最大贡献是**"结构化触发 + 分层暴露"**。
- Cursor 教我们 rule 要有触发条件
- Claude Skills 教我们 progressive disclosure 的分层
- RAG 教我们**不要**追求聪明检索
- Mem0 / Letta 教我们 evolution_source 应该扩展种类，但必须有证据链

→ synthesis 中会把这一篇浓缩为 "**Rule 触发条件是第一等公民**" 这一条硬性设计启示。
