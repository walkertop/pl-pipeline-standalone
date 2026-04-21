# piao-pipeline · 新人导读（GUIDED TOUR）

> **目标受众**：想真正理解 piao-pipeline、并可能接手推进 v0.2 的人。
>
> **时间预算**：半天（约 4 小时）。
>
> **结束条件**：能回答 [Chapter 6 自检清单](#chapter-6--自检清单15-分钟)的全部 6 个问题。

**阅读原则**：本导读按**认知顺序**组织，而非按目录顺序。请不要跳章——每一章建立的直觉是下一章的前提。

---

## Chapter 0 · 建立直觉（10 分钟）

### 做什么
读 [`README.md`](README.md) 与 [`00-overview.md`](00-overview.md) §0-§1。

### 要回答
- 这个项目**是什么**？（答：一套契约 + 可观测语义 + 演化机制）
- 这个项目**不是什么**？（答：不是 Airflow 皮肤、不是 Agent Framework、不是 Build System）
- 它解决的**具体问题**是什么？（答：Agent 出错时能感知/定位/传播/修复/沉淀）

### 常见误解（预先排除）
| 误解 | 真相 |
|---|---|
| "这是另一个工作流引擎" | ❌ 它不调度执行，它定义**契约和可观测性** |
| "它是给 Agent 用的" | ⚠️ 更准确的说法：它**约束** Agent，让 Agent 的错误不会被吞掉 |
| "kernel 层就是抽象基类" | ❌ kernel 是**场景无关的宪章**，禁止出现场景词（见 `kernel/scenario-wordlist.md`） |

---

## Chapter 1 · 骨架（30 分钟）

### 做什么
读 [`00-overview.md`](00-overview.md) §2-§6（架构图 / 端到端叙事 / 设计底线 / NO-list / 版本目标）。

### 核心公式（背下来）
```
Identity × Artifact × Layering × Event × Snapshot × Drift × Evolution × Extensibility
```

### 七大模型速览（只记一句话定义）
| 维度 | 一句话职责 | 状态 |
|---|---|---|
| 01 Identity | 谁是谁（URN 命名空间） | @v1.3 ✅ |
| 02 Artifact | 产出的"东西"是什么（契约 + 内容寻址） | @v1.4 ✅ |
| 03 Layered Arch | 分几层 + 层间怎么流动（含事件模型） | @v1 draft（v0.2 候选升版） |
| 04 Snapshot | 某一时刻系统的冻结照片 | @v1.2 ✅ |
| 05 Drift | 照片之间不一致时，影响怎么传播和止血 | @v1.1 ✅ |
| 06 Evolution | 经验和错误怎么反哺系统（lazy-load） | @v1.1 ✅ |
| 07 Extensibility | 哪些是通用的、哪些可扩展 | @v1.1 ✅ |

### 本章通关条件
能在脑子里画出 `00-overview §2` 的架构图，不看原文也能描述"kernel 和 adapter 的关系"。

---

## Chapter 2 · 挑一个模型深入（60 分钟）

### 做什么
**推荐从 `kernel/02-artifact-model.md` 入手**（最具象、最好抓手）。

### 关注三件事
1. **URN 三段结构**：`urn:piao:<kind>:<namespace>:<name>@<rev>`——这是整个系统的原子身份。
2. **三元组 (URN + rev + content_sha256)**：这是 piao-pipeline 对"可追溯"的定义，也是 byte-traceable 语义的来源。
3. **artifact.published 事件**：每次 rev 转换必发一条（CONV-01 主条款）。

### 验证理解
读完 02 后，回到 [`v0_1-final-decisions.md §2`](kernel/_review/v0_1-final-decisions.md)，对照七份 spec 的三元组表——你应该能看懂**为什么要记录 sha256**、以及**为什么 sha256 时序失真（DISC-V01-001）是个问题**。

### 扩展阅读（可选）
- `01-identity-model.md §5.1.1` concern 预定义表（URN 之下的第二层命名空间）
- `04-version-snapshot.md` 快照的打法与时机

---

## Chapter 3 · 看事件流（30 分钟）

### 做什么
用编辑器打开 `pipeline-output/piao/kernel-events/2026-04.jsonl`（26 行 JSONL）。

### 对照看
`kernel/01-identity-model.md §5.1.1` 的 concern 预定义表——检查每一行 event_id 前缀是否合法。

### 关键字段（逐个理解）
```json
{
  "event_id":         "task-published-260419181500-a5969c",  // 二维前缀 · CONV-01.1
  "event_type":       "artifact.published",                   // 业务语义
  "subject":          "urn:piao:artifact:kernel:v0_1_final_decisions@v1",
  "content_sha256":   "bc7676f0...",                          // byte-traceable 锚
  "producer_task_urn":"urn:piao:task:kernel:v0_1_final_decisions_publish",
  "emitted_at":       "2026-04-19T18:15:00Z",
  "reconstructed":    false                                   // true = 历史补录（EX1）
}
```

### 要看出来
- L24/L25/L26 三行是 v0.1 封版三部曲：**published → superseded → synced**。
- 头几行是 `reconstructed: true` 的历史补录（M6 期间批量追认，EX1 例外豁免）。
- 前缀形态有三种：三段式（兼容）/ 二维前缀（新标准）/ 历史无前缀（EX1）。

### 本章通关条件
能解释"为什么事件要 append-only"、"reconstructed=true 意味着什么"、"为什么 event_id 前缀要做合法性约束（CONV-01.1）"。

---

## Chapter 4 · 看一次完整的封版决策（60 分钟）

### 做什么
读 [`kernel/_review/v0_1-final-decisions.md`](kernel/_review/v0_1-final-decisions.md) 全文。

### 按顺序看四件事

#### 1. §1 四代 kickoff 接力链
```
post-m1-kickoff → m5-drift-kickoff → m6-evolution-kickoff → m7-closeout-kickoff
                                                                  ↓ superseded by
                                                    v0_1-final-decisions @v1
```
这是 piao-pipeline 自己演化自己的方式。注意"范式演进"的四代——从**工具先行**到**问题清单先行**到**反向审查先行**再到**决议先行**。

#### 2. §2 七维终态矩阵
URN + rev + sha256 三元组——**单一事实源**在此。任何时候有人争论"v0.1 到底封了什么版本"，翻这张表。

#### 3. §4 发现项登记（DISC-V01-001/002/003）
学会看"**已知缺陷但有补偿路径**"这种姿态——不是装没看见，是**显式 deferred 到有触发条件的明确未来**。

特别是 DISC-V01-001（sha256 时序失真）——这是 piao-pipeline 第一次用自己的工具抓自己的 bug。

#### 4. §6 self-review 8/8
封版门禁长什么样。注意它不是"全绿才通过"，而是"**所有未通过项都有登记和补偿**"。

### 本章通关条件
能讲清楚"**为什么 piao-pipeline 要自己定义封版决议文档格式，而不是直接打 git tag**"。

---

## Chapter 5 · 关键 commit 地图（30 分钟）

### 做什么
按时间顺序走一遍以下 commit，体会"演进节奏"。

```bash
# 看 piao-pipeline 的完整演进历史
git log --oneline -- docs/piao-pipeline/ pipeline-output/piao/
```

### 关键节点（按时间倒序）

| commit | 节点意义 |
|---|---|
| `a2273031` | **v0.1 封版** · final-decisions + kickoff supersede + overview doc-sync |
| `e8f16db5` | γ₂ · m7-closeout-extensibility-acceptance @v1（07 反向审查通过） |
| `2f7f7d1b` | γ₁ · M1-debt-ledger @v10（CONV-01.1 引入） |
| `2ea5a49e` | 01-identity-model @v1.3（Q29 裁定 B'-1 落地 · event_id 二维前缀） |
| `862774bb` | M7 工作流 P · Q29 裁定决议（前缀分类学选型） |
| `484b628c` | M6 封版 · evolution-model 定稿 |
| `7a7bce04` | 02 @v1.4 · evolution.scan_result 派生注册 |
| `f2678870` | 补发 14 条 kernel spec 历史 published 事件（EX1 大规模使用） |

### 要看出来
- **M5 → M6 → M7 的三次"范式升级"**：每次都在上一次的基础上抽象出新方法论。
- **ledger v5 → v10 的五轮演进**：技术债不是被"清"掉的，是被"规范化"的（resolved / continued / conventioned 三态）。
- **事件流的填充节奏**：历史事件批量补录 → 近实时发射 → 二维前缀迁移。

---

## Chapter 6 · 自检清单（15 分钟）

能独立回答以下 6 个问题，则本导读通关：

☐ **Q1** · URN 的三段结构是什么？为什么必须带 `@rev`？
> 提示：身份 = 空间 × 时间；rev 缺失会让事件流失去时间锚。

☐ **Q2** · `content_sha256` 和 `revision` 的职责差异是什么？
> 提示：revision 管"语义版本"，sha256 管"字节级真相"。两者互相校验。

☐ **Q3** · `concern` 预定义表为什么设计成**封闭的**？扩展路径是什么？
> 提示：kernel-closed 是为了防止 event_id 前缀爆炸；扩展需经 spec 升版 + ledger 登记（见 01 §5.1.1）。

☐ **Q4** · 四代 kickoff 接力链要解决的根本问题是什么？
> 提示：让每个 milestone 的启动都**显式指向**上一代的封版，避免"无主的演进"。

☐ **Q5** · 发现项的 `deferred` 机制为什么必须带**触发条件**？不带会怎样？
> 提示：不带触发条件的 deferred 等于遗忘；带了触发条件才是"有账可追"。

☐ **Q6** · v0.1 / v0.2 分界线是怎么划的？为什么不直接做 v1.0？
> 提示：v0.1 = kernel 宪章自洽；v0.2 = 首个 adapter 压测契约。**没有 adapter 压测的 kernel 只是理论。** 直接跳 v1.0 会导致契约漂移。

---

## Chapter 7 · 接手 v0.2 的起点（可选 · 30 分钟）

如果你真的要推进 v0.2，按以下顺序做事：

1. **读 `v0_1-final-decisions §5`** · adapter 接入入口清单（4 个扩展点 A/B/C/D）。
2. **读 `kernel/07-extensibility.md §4`** · 四问准入（什么才配成为新 spec / 新 adapter）。
3. **等真实业务需求触发**（最可能是 `prop_confirm` 业务单元迁移）。
4. **触发 `v0_2-kickoff`**，按四代 kickoff 范式编排（这一代延续"决议先行"还是发明第五代，由你决定）。

⚠️ **警告**：切勿在没有真实业务需求的情况下"预起草" adapter——这是 piao-pipeline 明确反对的 over-engineering（见 `07-extensibility §0` 过早抽象原则）。

---

## 附录 · 如果卡住了

| 症状 | 查哪里 |
|---|---|
| "这个 URN 格式哪里定义的" | `kernel/01-identity-model.md` |
| "这个 sha256 怎么算的" | `v0_1-final-decisions.md §附1` |
| "这个 concern 合法吗" | `kernel/01-identity-model.md §5.1.1` |
| "kernel 能不能出现 xxx 词" | `kernel/scenario-wordlist.md` |
| "为什么这个决定是这样的" | 先查 `_review/M*-final-decisions.md`，再查 ledger |
| "这个术语是啥意思" | `00-overview.md §0-§1` 的定义 |

---

**读完本导读，你已经有能力**：
- 向第三方解释 piao-pipeline 的定位与边界
- 审查新的 rev 升版是否符合契约
- 判断一条事件是否合规
- 发起 v0.2 的 kickoff 讨论

**还不具备的能力**（需要实践）：
- 设计一个新的 kernel 模型（需要经历过完整的 M* 流程）
- 实施 adapter（需要 v0.2 阶段的真实压测经验）
