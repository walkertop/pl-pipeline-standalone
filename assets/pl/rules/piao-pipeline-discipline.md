---
id: piao-pipeline-discipline
version: 1.0.0
scope: generic
category: meta
severity: warning
description: 演进式 artifact pipeline 的三条通用纪律（sha256 时序 / kickoff 接力 / deferred 触发条件）。违反不会立即出错，但会在事后回溯时找不到真相，代价极高。
applies_to:
  - "docs/**/_review/*final-decisions*.md"
  - "pipeline-output/**/events*.jsonl"
  - "**/kernel-events/*.jsonl"
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Piao-Pipeline 演进三纪律

> **Rule-ID**: `PIAO-001`
> **适用范围**: 任何基于"事件流 + 版本化 artifact"的演进式研发 pipeline
> **优先级**: P1（非阻塞，但违反会造成 drift 和信任损失）
> **来源**: 从一次真实演进型 pipeline（2026-04 某子系统 v0.1）封版过程的经验沉淀

---

## 变更日志

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0.0 | 2026-04-23 | 从源项目脱敏迁入独立仓 |

---

## 设计原则

> 演进式 pipeline 的核心承诺是 **可追溯性**。本 Rule 收录的三条纪律都是为了兑现这个承诺——
> 违反它们不会立即出错，但会在事后回溯时 **找不到真相**，届时代价极高。

本 Rule 是 **元级规范**，不规定"代码怎么写"，只规定"过程怎么治理"。若项目不涉及演进式
artifact pipeline（比如纯业务迭代、纯组件开发），可以忽略本 Rule。

---

## 1. sha256 时序自洽纪律（sha256-temporal-integrity）

### Rule `PIAO-001-SHA256`: 事件中登记的 sha256 必须与 commit 落盘态字节一致

**Rationale**: sha256 是 artifact 的唯一身份指纹。如果 journal 里记录的 sha256 和
git 落盘态不一致（典型场景：事件写在前、改动写在后），那么 **整条事件链的信任就全塌了**——
后人回溯时无法判断哪个是真相。真实案例中已记录一次此类陷阱（某 ledger @v10 事件行
sha256 指向的是上一轮字节态，而非落盘态），代价是必须留一条 deferred 补偿项。

**要求**：
- 每次为 artifact 生成 `content_sha256` 之前，必须 **先完成所有文件改动并落盘**
- 然后计算 sha256 → 写入事件 → 在 **同一个 commit** 内落盘事件与 artifact
- 禁止"先写事件、后改内容"或"先改内容、commit 后补登事件"两种顺序

**违规检测**：
```bash
# 对任一事件行，提取 artifact_urn 与 content_sha256
# 在事件所在 commit 处 checkout，重新计算 artifact 的 sha256
# 两者必须字节一致
```

**补偿路径（已违规时）**：
登记 `deferred` 条目到 debt-ledger，字段必须含：
- 触发条件（什么时候必须修复）
- 影响范围（当前产生的污染面）
- 修复方案（怎么补登一条更正事件）

**关联**：`PIAO-001-DEFERRED`（补偿机制）

---

## 2. kickoff supersede 接力纪律（kickoff-relay-discipline）

### Rule `PIAO-001-KICKOFF`: 每代里程碑必须由 kickoff 启动、由 final-decisions 闭合，显式 supersede

**Rationale**: 多代演进中最容易发生的漂移是 **"里程碑边界模糊"**——改着改着不知道现在是
第几代、上一代有没有封好、这一代起点在哪里。真实案例的四代接力链
（post-m1 → m5 → m6 → m7 → v0_1_final）验证了一个简单但关键的范式：每代必须
**显式启动、显式闭合、显式 supersede 上一代**。缺一个环节就会留下边界不清的隐患。

**要求**：

每代里程碑必须产出两份 artifact：

| Artifact | 角色 | 必填字段 |
|---|---|---|
| `MN-kickoff@v1` | 启动 | `triggers`（上一代 final-decisions URN）+ `scope`（本代要做什么）+ `paradigm_innovation`（与上一代相比的范式升级） |
| `MN-final-decisions@v1` | 闭合 | `supersedes`（本代 kickoff URN）+ `scope_hash`（封版哈希）+ `next_trigger_hint`（触发下一代 kickoff 的条件） |

**接力关系**：
```
MN-final-decisions.supersedes  = MN-kickoff.urn
MN+1-kickoff.triggers          = MN-final-decisions.urn
```

**范式演进要求（kickoff 的 `paradigm_innovation` 字段）**：
每代 kickoff 与前代相比 **必须有方法论层面的创新**（比如问题清单先行 / 反向审查先行 /
决议先行），而不是机械重复。这是识别 **"虚假演进"** 的防线——如果新一代 kickoff 和上一代
完全同构，说明这一代其实没必要存在。

**违规检测**：
```bash
# 扫描所有 kickoff/final artifact，验证：
# 1. 每个 kickoff 都有对应的 final-decisions
# 2. supersede 链是连续的（不丢代、不并行）
# 3. 每个 kickoff 的 paradigm_innovation 字段非空且与上一代不同
```

**反模式**：
- ❌ 只有 kickoff 没有 final-decisions（开了坑没填）
- ❌ 只有 final-decisions 没有 kickoff（突然封版，边界模糊）
- ❌ 多个 kickoff 并行（演进成多叉树）
- ❌ paradigm_innovation 与上一代雷同（机械重复）

---

## 3. Deferred 机制必须带触发条件（deferred-with-trigger）

### Rule `PIAO-001-DEFERRED`: 所有 deferred 条目必须声明"触发条件"字段

**Rationale**: **"延后处理"是演进式 pipeline 最危险的措辞**——没有触发条件的 deferred
条目实际等于 **永久遗忘**。封版时显式要求每条 `deferred` 条目必须回答 **"什么时候必须重新
审视？"**，这是对完美主义的克制（不追求 v0.1 零遗留），也是对健忘症的防御（遗留项不会消失）。

**要求**：

每条 deferred 条目必须含以下字段（缺一不可）：

| 字段 | 用途 | 示例 |
|---|---|---|
| `id` | 唯一标识 | `DISC-V01-001` |
| `content` | 延后的内容 | "ledger @v10 事件 sha256 时序失真" |
| `defer_to` | 延后目标版本 | `v0.2` 或 `M8` 或具体日期 |
| `trigger_condition` | **触发条件**（必填） | "01 @v1.4 升表时"、"下次 ledger 升版时"、"收到第一个扩展需求时" |
| `compensation_path` | 补偿方案 | "补登一条更正事件指向当前 @v10 sha256" |
| `impact` | 当前影响 | "不阻塞 v0.1 封版，但 journal 回溯可信度下降" |

**触发条件的写法要求**：
- ✅ 可观察（有明确的外部信号能触发）：`"M1 ledger 下次升版"`、`"收到 <feature> 需求"`
- ✅ 或者可验证（有明确的时间/里程碑锚点）：`"v0.2 kickoff 起草前"`、`"2026 Q3 前"`
- ❌ 禁止使用模糊措辞：`"以后"`、`"有空时"`、`"需要时"`、`"尽快"`

**违规检测**：
```bash
# 扫描所有 deferred 条目，验证 trigger_condition 字段：
# 1. 非空
# 2. 不含禁用词（"以后"/"有空"/"需要时"等）
# 3. 含可观察锚点（URN / 事件名 / 日期 / 里程碑）
```

**反模式**：
- ❌ "这个问题我们先 defer 到 v0.2" → 没说什么触发
- ❌ "有时间再修" → 永远没时间
- ❌ "作为技术债记录" → 没人会回来看
- ✅ "defer 到 v0.2，由 m7-closeout-kickoff 在扩展层需求浮现时重新评估"

---

## 4. 速查表（Rule 一页纸）

```
┌─── 演进三纪律 ───────────────────────────────────────┐
│                                                      │
│  1. sha256 时序一致                                  │
│     → 先落盘 · 再算 sha · 再写事件 · 同 commit       │
│                                                      │
│  2. kickoff 接力显式                                 │
│     → 每代 kickoff↔final 成对 · 显式 supersede       │
│     → paradigm_innovation 必填且与上一代不同         │
│                                                      │
│  3. Deferred 带触发条件                              │
│     → 禁用"以后/有空/需要时"                         │
│     → 必填 trigger_condition（可观察/可验证锚点）    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 5. 本 Rule 的应用场景

### 场景 A · 启动下一代（扩展层）时
- `PIAO-001-KICKOFF`：需产出 `<next-version>-kickoff@v1`，triggers 指向 `<prev>-final-decisions@v1`
- `PIAO-001-DEFERRED`：上一代遗留的 DISC-* 在此刻必须评估是否兑现

### 场景 B · 发现新的 meta-level 问题
- `PIAO-001-DEFERRED`：若决定延后，登记到 ledger 时必须带齐六个字段

### 场景 C · 事件 journal 追加时
- `PIAO-001-SHA256`：计算 sha256 之前必须确认 artifact 已落盘

---

## 6. 关联

- 上游文档：对应项目的 `v0_1-final-decisions.md` §1 / §2 / §4
- 导读：对应项目的 `GUIDED-TOUR.md`（封版决策三件套）
- 关联 Rule：
  - `ACC-001`（验收标准）—— 本 Rule 可作为 P1 级交付自检项
  - `BUILD-001`（构建验证）—— `PIAO-001-SHA256` 依赖 "先落盘再 commit" 的纪律
  - `GIT-001`（提交规范）—— 一次 commit 一次变更

---

## 7. NO-list（本 Rule 不做的事）

显式声明本 Rule **不**涉及以下内容，避免范围蔓延：

- ❌ 不规定 URN 命名规则 → 见项目的 identity-model 文档
- ❌ 不规定 artifact 物理存储 → 见项目的 artifact-model 文档
- ❌ 不规定分层架构 → 见项目的 layered-architecture 文档
- ❌ 不替代具体的 spec/plan/archive 流程 → 与它们正交，可叠加使用
- ❌ 不要求所有项目都用 → 仅适用于演进式 artifact pipeline 场景
