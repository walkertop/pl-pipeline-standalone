---
urn: urn:piao:kernel:spec:competitive/evolution_governance@v1
kind: spec
rev: v1
status: draft
category: competitive-research
---

# 演化治理工具对标：OpenSpec / OpenRewrite / Structurizr / RFC 系统

> 这一类产品回答的是：**如何让架构/规范/代码的演化"被记录、被评审、被追溯"**？
> piao-pipeline 的 evolution 层直接脱胎于 OpenSpec，本篇重点在"我们应该**从 OpenSpec 继承什么、改造什么、抛弃什么**"。

---

## 1. 代表产品

| 项目 | 类别 | 核心模式 |
|------|------|---------|
| **OpenSpec** | Spec-driven dev for LLM | 变更提案 + tasks.md + acceptance + 归档 |
| **OpenRewrite** (Moderne) | 自动化代码演化 | recipe + LST + AST 重写 + dry run |
| **Structurizr** | 架构图 as code | C4 model + DSL + diagram export |
| **arc42** | 架构文档模板 | 12 节固定结构 + 可追溯 decision records |
| **ADR (Architecture Decision Records)** | 轻量架构决策 | 单文件 markdown + status + context + decision + consequences |
| **Rust RFC** | 语言演化治理 | RFC PR + public review + 签入后作为规范 |
| **Kubernetes KEP** | 项目演化治理 | 分层提案 + alpha/beta/stable 状态机 |
| **Python PEP** | 语言/库演化 | 固定章节 + BDFL/Steering Council 决议 |

## 2. 它们解决了什么问题

**共同问题**：
- 架构/规范的演化**不可避免**，但演化历史经常丢失
- 后来者看到代码时不知道"为什么这样设计"
- 改动影响范围难以评估，容易踩前人的坑

**关键难题**：
- 把 "decision + context + consequences" 持久化
- 让演化提案**前置审议**而不是既成事实
- 演化前后的**可逆性**（能回到前一个版本的理解）

## 3. 架构模式提取

### 3.1 OpenSpec 的模式：**Change = Proposal + Tasks + Specs + Archive**

OpenSpec 的目录结构：
```
openspec/
├── specs/                  # 已归档的 capability 规范
├── changes/                # 未归档的变更提案
│   └── <change-id>/
│       ├── proposal.md     # 需求描述
│       ├── tasks.md        # 任务拆解
│       ├── design.md       # 设计
│       └── specs/          # 该变更要动的 capability delta
└── project.md / AGENTS.md  # 项目元数据
```

**关键洞察**：**变更是一等公民**。它不是 git commit 的附属物，而是有独立的目录、独立的生命周期（draft → active → archived）、独立的关联物。

→ piao-pipeline 对应物：我们已经在项目里跑 OpenSpec 了，M1 kernel 直接把 OpenSpec 升格为**标准的演化记录形态**。

**继承什么**：
- 变更目录结构（change-id 目录 + proposal / tasks / specs delta）
- 归档机制（archive 时合并 delta 到 specs/）
- 状态机（draft / in-progress / ready / archived）

**改造什么**：
- OpenSpec 当前**没有 URN**——所有引用靠相对路径和 change-id 字符串。piao-pipeline 给每个 proposal / tasks / spec delta 都加 URN
- OpenSpec 当前**没有 trace 事件**——我们补上一层，所有 spec/proposal 的 rev 升降都落到 trace
- OpenSpec 当前**演化触发源只有"人提 proposal"**——piao-pipeline 扩展为 error_log / insight / outage / review_note 等多种 evolution_source 自动触发

**抛弃什么**：
- OpenSpec 的"命令式命令体系"（`/openspec proposal`、`/openspec archive`）在我们现有项目里已经在跑，**不需要作为 kernel 概念**。它属于 adapter.kuikly 的特化。kernel 只定义 artifact 契约和状态机，**不定义命令**。

### 3.2 OpenRewrite 的模式：**Recipe = 可验证的演化**

OpenRewrite 的 recipe 是**可执行的 AST 重写规则**，每个 recipe：
- 有 YAML/Java 定义
- 有 dry-run 模式（只生成 diff，不落盘）
- 有测试（before/after 代码对照）
- 有影响范围预览

**关键洞察**：**架构演化不只是文档，可以是"可跑的代码"**。

→ **对 piao-pipeline 的启发**：
  - 我们目前的 evolution_proposal 都是"文档描述 + 人去改"
  - 未来**有些演化可以升级为可执行 recipe**（比如"把所有 Card 的 onMount 改名为 onAppear"这种纯机械重构）
  - **v0.1 不做**，但要在 `06-evolution-layer.md` 的 "future work" 里记一笔
  - 长期看，piao-pipeline 的 rule 可以和 detekt/ktlint/OpenRewrite recipe 打通

### 3.3 ADR 的模式：**Decision 的"最小必需字段"**

ADR 格式极简：
- Title
- Status（proposed / accepted / deprecated / superseded）
- Context
- Decision
- Consequences

一个决策一个 markdown，一页纸。

**关键洞察**：**决策的价值不在篇幅，在于"后来者能快速理解 why"**。

→ **对 piao-pipeline 的启发**：
  - 我们目前的 evolution_proposal 格式还没定，应该**直接借鉴 ADR 的 5 字段**作为 evolution_proposal 的最小结构
  - 额外加 `urn / rev / produced_by / supersedes` 是我们的 identity 契约
  - 这是一个具体的 M6 (evolution layer) 设计点，先记下

### 3.4 Rust RFC / Kubernetes KEP 的模式：**分层 + 状态机**

KEP 把一个提案拆成阶段：
- **Provisional**：想法阶段，低门槛
- **Implementable**：已设计清楚，等实现
- **Implemented**：在 alpha channel 跑
- **Stable**：正式进入规范
- **Deprecated / Withdrawn**

每个阶段有不同的门槛（代码进度 / 测试覆盖 / graduation criteria）。

**关键洞察**：**不同成熟度的演化走不同门槛**。

→ **对 piao-pipeline 的启发**：
  - 我们的 evolution_proposal 应该有类似的状态机
  - 但不要照搬 6 状态，piao-pipeline v0.1 建议 3 状态：**proposed → accepted → promoted**
  - `promoted` 对应 KEP 的 stable，意味着已经升入 kernel/adapter 的正式 rule/spec
  - 状态流转事件落入 trace

### 3.5 Structurizr / arc42 的模式：**架构文档也是代码**

Structurizr 的 C4 model 用 DSL 声明架构，diagram 从 DSL 生成。arc42 则提供了一个固定模板让所有项目的架构文档有可比性。

**关键洞察**：**文档结构本身是契约**，而不是自由写作。

→ **对 piao-pipeline 的启发**：
  - piao-pipeline 本身就是 arc42 精神的产物——我们用固定的 14 篇结构写 kernel
  - **不借鉴 Structurizr 的图形 DSL**，因为我们的价值在 artifact/trace/evolution，不在可视化
  - 但可以借鉴"**所有架构 decision 有固定字段**"这个 arc42 原则

## 4. 对 piao-pipeline 的启发（正反两面）

### 4.1 正向启发 ✅

1. **变更是一等公民**（OpenSpec）—— 已在做
2. **演化可以升级为可执行 recipe**（OpenRewrite）—— v0.2/v0.3 方向
3. **决策的最小必需字段**（ADR 5 字段）—— 作为 evolution_proposal 模板
4. **演化状态机**（KEP）—— 采纳 3 状态简化版
5. **文档结构即契约**（arc42）—— kernel 本身就是这么设计的

### 4.2 反向启发 ⚠️

1. **不要把 OpenSpec 的命令耦合进 kernel**：kernel 只定义 artifact 契约，命令是 adapter 的事
2. **不要学 Rust RFC 的长周期**：Rust 的 RFC 平均 6 个月，我们是内部项目，周期应该**周级而非月级**
3. **不要做 Structurizr 的图形化**：价值低代价高
4. **不要追求 OpenRewrite 的 AST-level 自动化**：v0.1 绝对过度；v0.2 再评估

## 5. 风险 / 反例

**反例 1：OpenSpec 的 `/openspec archive` 经常被跳过**。
人容易忘记 archive，导致 changes/ 堆满完成但未归档的变更。
**对策**：piao-pipeline 的归档触发必须和 **trace 事件 + quality_gate** 绑定——任务完成时自动生成"pending_archive" 事件，超过 N 天未归档报警。这是 orchestrator 层的工作。

**反例 2：ADR 写了没人看**。
团队引入 ADR 三个月后，新人经常不看 ADR 直接开码。
**对策**：piao-pipeline 的 evolution_proposal 如果涉及某 artifact，kernel 在该 artifact 被编辑时**自动注入对应的 proposal** 作为上下文（通过 rule 的触发机制）。让决策"自动出现在决策被需要的地方"。

**反例 3：KEP 的状态机被"僵尸提案"堵满**。
Kubernetes 有大量 provisional 阶段提案永远不进展。
**对策**：piao-pipeline 的 evolution_proposal 有 `last_activity_at` 字段，超过 N 天无活动自动转 `withdrawn`。可审计，可恢复。

**反例 4：OpenRewrite recipe 的副作用难以预测**。
机械重构经常破坏"看起来无关但实际依赖"的代码。
**对策**：如果 v0.2 引入可执行 recipe，**必须依赖 artifact lineage** 先计算影响范围，影响范围外的修改一律拒绝。

## 6. 不采纳清单

| 对标做法 | 不采纳原因 |
|---------|-----------|
| **kernel 层耦合命令系统** | 命令是 adapter 的事 |
| **月级 RFC 周期** (Rust RFC) | 内部项目周期要短 |
| **图形化架构 DSL** (Structurizr) | 价值低 |
| **AST 级自动演化** (OpenRewrite) | v0.1 过度 |
| **BDFL 决议模型** (Python PEP) | 团队协作项目不适用，我们走评审模型 |

---

**本篇结论**：演化治理工具给 piao-pipeline 的最大贡献是**"演化本身必须有结构 + 状态机 + 可追溯"**。

- OpenSpec 是我们的直接祖先，我们保留其骨架，**补上 URN/trace/多源触发**
- ADR 给了我们 evolution_proposal 的最小字段
- KEP 给了我们状态机的参考（简化为 3 态）
- OpenRewrite 指向了未来"可执行演化"的可能性（v0.2+）

→ synthesis 中会把这一篇浓缩为 "**演化是一等公民 + 演化有状态机 + evolution_source 多样化**" 三条。
