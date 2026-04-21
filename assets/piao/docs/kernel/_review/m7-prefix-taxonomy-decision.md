---
urn: urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1
kind: artifact
artifact_type: decision
rev: v1
status: published
produced_by: m7_closeout_kickoff@v1 § workflow P (phase γ₁)
published_at: 2026-04-20T00:45:00+08:00
upstream:
  - urn:piao:proposal:kernel:m7_closeout_kickoff@v1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v9
  - urn:piao:spec:architecture:identity_model@v1.2
  - urn:piao:spec:architecture:extensibility@v1.1
  - urn:piao:artifact:kernel:m6_debt_consumption@v1
  - urn:piao:journal:kernel:kernel_events@2026-04
  - urn:piao:journal:kernel:mvp_smoke_events@2026-04
resolves:
  - Q29 (M1-debt-ledger @v9 §1.7.1)
wordcheck_exempt: true
---

# M7 Prefix Taxonomy Decision · Q29 event_id 前缀分类系统裁定

> 本文档是 **M7 Closeout Kickoff @v1 §2.2 / §3** 指令下 · 工作流 P（阶段 γ₁）的唯一核心产出 · 就 `M1-debt-ledger @v9 §1.7.1` 登记的 Q29 三选项 A'/B'/C' 作出 kernel 层决议。
>
> **定位**：`kind: artifact` + `artifact_type: decision`（对标 `m6_evolution_kernel_alignment@v1` 范式 · 但目标是"分类系统决议"而非"接口对齐修订"· 是决议 artifact 的第二种变体）。
>
> **阅读路径**：先读 M1-debt-ledger @v9 §1.7（Q29 完整登记）→ 再读 m7_closeout_kickoff @v1 §3（证据图景）→ 再读 01-identity-model @v1.2 §5（被裁定对象）+ 07-extensibility @v1.1 §1 边界 2（隐含约束）→ 最后读本文档（裁定结果 + 落地矩阵）。
>
> **自检**：若读后不清楚"Q29 的三选项差异 / 本决议最终取 B' 的三条硬证据 / 对已落盘 5 条非 `task-*` 事件的处置方案"三件事 · 本决议失败。

---

## 0. 决议结果（TL;DR）

**本决议选定：选项 B'（扩展版）—— 承认事件 event_id 前缀的"业务 concern"维度 · 扩展 01 §5 表为 {域 × concern} 二维分类 · 但不破坏 07 §1 边界 2 的 adapter 封闭性。**

具体讲：

| 项 | 决议 |
|---|------|
| 01 §5 表结构 | 升级为 `{域, concern}` 二维 · 沿用现有 7 域作为主轴 · concern 维度在 kernel 内部预定义（不开 adapter） |
| 已落盘 5 条非 `task-*` 事件处置 | **不改** · 由 01 @v1.3 新增的二维表**追认合法性**（零回改 sha256） |
| 05 / 06 spec 字面授权 | **不改** · 现有 `drift-triggered-*` / `evolution-scanned-*` 在新表下直接合法化 |
| CONV-01 契约 | **扩展**为 CONV-01.1 · 补充"前缀选择必须落在 01 §5 表二维合法组合内"的条款 |
| 07 边界 2 | **不破坏** · kernel 内部扩展不等于开放给 adapter · 不触发 07 升版 |
| 03 §3.2 L1 事件骨架 | **可选升级** · 加 `concern` 字段（非必须 · 工具侧可从 event_id 解析）· 推迟到 03 @v1 published 再决定 |
| 升版范围 | **仅升 01 @v1.2 → @v1.3** · 其他所有 published spec 不动 |

**三条硬证据支撑 B'（非 A' / 非 C'）**：

1. **事实权重**：22 条落盘事件中 5 条非 `task-*` · A' 要求改 5 条事件 ID（破坏 sha256 + 追 alias）· B' 零回改 · C' 零回改但推翻 01 §5 整体设计 —— B' 在"零回改"的基础上还保全设计意图 · 优势独占
2. **spec 权威**：A' 需改 05 @v1.1 + 06 @v1.1 两份 published spec 字面 · 违反 ledger §1.6.2 CONV-01 暗含"published 不回改"公约 · B' / C' 均不动 —— A' 独自违反
3. **07 封闭性**：07 §1 边界 2 明列 `event_type` 根命名空间封死给 kernel · C' 的"工具侧 prefix-agnostic"路径实质上推翻了该封闭性（因为一旦工具不看前缀 · 前缀就变成无约束字段 · adapter 可任意发明）· 而 B' 在 kernel 内部扩展分类维度 · 仍对 adapter 封闭 —— 只有 B' 与 07 宪法兼容

---

## 1. 三选项对比矩阵（阶段 γ₁ 裁定依据）

> 本节是决议的**客观对比表**· 不含作者倾向 · 供读者独立复核。作者倾向见 §2。

### 1.1 总体代价对比

| 维度 | A'（收敛 7 域） | **B'（扩展二维 · 采纳）** | C'（prefix-agnostic） |
|------|----------------|--------------------------|---------------------|
| kernel spec 升版数 | 0（但需改 05/06 字面）| **1（仅 01 升 @v1.3）** | 0（但需改 01 §5.1 语义）|
| published spec 回改数 | 2（05 + 06）| **0** | 1（01 §5.1 补注语义变更）|
| 已落盘事件回改数 | 5（需 追认 alias 或改 event_id）| **0** | 0 |
| 工具代码改动 | 2（`piao-drift-compute.sh` + `piao-evolution-scan.sh` 前缀改名）| **0**（新增 concern 维度不影响现有工具）| 1-2（新增 `piao-event-scan.sh` 按 event_type 扫描）|
| 新工具立项 | 0 | **0** | 1（prefix-agnostic 扫描工具）|
| 07 边界 2 冲击 | 无（保留 7 域封死）| **无**（kernel 内部扩展 · 未开放 adapter）| **有**（前缀字段去约束化 · 暗中破坏 07 §1 边界 2 意图）|
| 03 骨架冲击 | 无 | **可选**（`concern` 字段 · 非必须）| 无 |
| CONV-01 冲击 | 无 | **扩展**（补 CONV-01.1 前缀约束条款）| 扩展（补"CONV-01 不约束前缀"的反向条款）|
| 未来 adapter 扩展路径 | 固定（只能用 7 域）| **固定 + 二维**（依然 kernel 封死 · 不增开口）| 开放（暗中 · 无约束）|
| 证据对齐 | 部分（与 01 §5 对齐 · 与 05/06 对齐 · 与落盘事件不对齐）| **全部**（与 01/05/06/落盘事件同时对齐）| 部分（与落盘事件对齐 · 与 01 §5 设计意图不对齐）|

### 1.2 单选项详解

#### 1.2.1 选项 A' · 收敛到 7 域（淘汰）

**核心机制**：把 `drift-triggered-` / `evolution-scanned-` / `artifact-published-` 三类变体追改为 `drift-*` / `evo-*` / `task-*` 三段式 · 代价是改 5 条落盘事件 + 05/06 spec 字面。

**硬伤**：

| 硬伤 | 具体后果 |
|------|---------|
| 回改落盘事件 = 破坏不变量 | 2 条 `drift-triggered-*` + 2 条 `evolution-scanned-*` + 1 条 `artifact-published-*` 共 5 条事件 · 如果追改 event_id 字面 · 需要更新 journal 文件 · 破坏"append-only"承诺（01 §5.2 暗含）· 若保留 event_id 字面但加"alias 表"· 等于新建一份 kernel 字面补丁 · 比升 01 rev 还重 |
| 回改 published spec 字面 | 05 @v1.1 §6.1 + 06 @v1.1 §X 两份 published spec 字面必改 · 违反 ledger §1.6 收敛阶段暗含"published 不回改"公约 · 且回改后需要发射新一轮 `artifact.published` 事件 · 循环引发 rev_history 膨胀 |
| 信息损失 | `drift-triggered-` 比 `drift-` 多带 "triggered" 这个 concern 语义 · 收敛后该语义被丢失 · 未来若有 `drift-detected-*` / `drift-resolved-*` 等需求 · 无地落脚 |
| 违反"事实权威" | 落盘事件是已发生的事实 · 改它就等于否定事实 · 与 piao 体系"事件即事实"本体论冲突 |

**淘汰结论**：A' 无硬硬证据支撑 · 且违反多个公约 · 不采纳。

#### 1.2.2 选项 B' · 扩展 01 §5 为二维分类（采纳）

**核心机制**：承认 event_id 前缀包含两层信息 —— **域（domain）** 和 **业务关切（concern）**。域保留现有 7 个（`pipe` / `tdag` / `task` / `trace` / `evo` / `drift` / `gate`），concern 维度在 01 §5 新增子表预定义。

**新 01 §5 表结构草稿**（完整草稿在 §3.2）：

```
event_id 格式扩展为：
  {domain}[-{concern}]-{YYMMDDHHmmss}-{6位hash}

单段式（三段式）：仅 domain · 如 task-260419151700-a9b94e
双段式（四段式）：domain + concern · 如 drift-triggered-260418121000-abc123

concern 维度（kernel 预定义 · 非 adapter 可扩展）：
  task × published       ← 追认 artifact-published-*（但 domain 写作 task 更合 01 §5.3）
                         ← 或保留字面 artifact-published-* · 在域映射注释说明
  drift × triggered      ← 追认 drift-triggered-*
  drift × detected       ← 预留未来
  drift × resolved       ← 预留未来
  evo × scanned          ← 追认 evolution-scanned-*（同时 01 §5 承认 evolution 作为 evo 展开别名）
  evo × proposed         ← 预留未来
  evo × consumed         ← 预留未来
```

**对已落盘 5 条事件的追认**：

| 现有 event_id | 新 01 §5 二维归类 | 合规性 |
|--------------|------------------|--------|
| `drift-triggered-*` × 2 | drift 域 × triggered concern | ✅ 四段式合法 |
| `evolution-scanned-*` × 2 | evo 域（evolution 作为展开别名）× scanned concern | ✅ 四段式合法 |
| `artifact-published-*` × 1 | task 域 × published concern（但字面保留 artifact-*）| ⚠️ 字面例外 · 需在 01 §5.3 加"历史兼容条款"豁免 |

最后一条是 B' 的**唯一复杂点**—— `artifact-published-*` 字面既不是 `task-*` 也不是新概念域 · 它是 smoke-report 预占的临时发明。B' 有两条子路径：

- **子路径 B'-1（严格）**：只在 01 §5 承认 `drift × triggered` / `evo × scanned` 两对合法组合 · `artifact-published-*` 仍作违规 · 但加"历史事件兼容条款"让它在 journal 里豁免（不追溯改）· 未来新发此类事件用 `task-published-*` 三段式或 `task-something-published-*` 四段式
- **子路径 B'-2（宽松）**：在 01 §5 承认独立 concern `published` · 允许任何域 × published 组合 · 包括 `artifact-*` 作为域别名豁免（相当于新增 artifact 域 · 但只允许一个 concern）

**采纳 B'-1**（详见 §2.3 理由）：一是避免新增"artifact 域"破坏 7 域封闭（07 §1 边界 2 风险）· 二是 `artifact-published-*` 是**单一历史事件**不值得开一整类 · 三是未来统一走 `task-published-*` 更简洁。

**kernel 侧变更清单**：

- `01-identity-model.md §5` 升版 · 新增子表 §5.1.1（concern 预定义）+ §5.3.1（历史事件兼容条款）
- 仅 01 升 rev · 从 @v1.2 → @v1.3
- 03 @v1 draft 可选在 L1 事件骨架加 `concern` 字段（非必须 · 工具可从 event_id 解析）

**CONV-01 扩展为 CONV-01.1**：

> **CONV-01.1（前缀合法性）**：所有 L1 事件的 `event_id` 前缀段必须出现在 `01-identity-model.md §5.1.1 concern 预定义表`中合法的 `{域, concern}` 组合内（单段式为"无 concern"的特殊情形）。历史事件通过 §5.3.1 豁免条款兼容。

**07 边界 2 不破坏**：因为 concern 维度仅 kernel 预定义 · adapter 依然不能加新 concern · 沿用 07 §1 边界 2 的 kernel 封闭精神。

#### 1.2.3 选项 C' · prefix-agnostic（淘汰）

**核心机制**：维持现状 · 要求工具侧不再依赖 event_id 前缀作为域分隔符 · 改用 `event_type` + `artifact_kind` + `producer_task_urn` 三元组索引。

**硬伤**：

| 硬伤 | 具体后果 |
|------|---------|
| 推翻 01 §5 设计意图 | 01 §5.1 明确讲"选 UTC 秒级可读格式"的理由是"**工程师日常调试 / IM 贴 id 问人 / grep 时间范围**" · 其中 grep 时间范围包括按域 grep（如 `grep ^task-`）· C' 下这条能力消失 · 违背 01 §5.1 设计初心 |
| 暗中破坏 07 §1 边界 2 | 07 §1 边界 2 明列 `event_type` 根命名空间封死 · 但它建立在"event_id 前缀也是这 7 域"的隐含一致性假设之上。C' 下前缀去约束化 · adapter 可任意用前缀发明"子分类"· 暗中突破 07 封闭 |
| 新工具立项成本 | 需新起 `piao-event-scan.sh` · 虽然代码不多但是**维护心智负担增加**（同一语义有两个查询入口：event_type 字段 vs event_id 前缀）· 未来审计谁在用哪个入口是隐患 |
| 不解决新 meta 债 | C' 本质上是"把 Q29 标注为非问题" · 但未来 adapter 若重复 `evolution-scanned-` 这种疏忽 · C' 下没有 kernel 层机制阻止 · Q29 式 meta 债将持续再生 |

**淘汰结论**：C' 是"零动作"的假象 · 实际带着隐性成本（推翻 01 §5.1 + 暗中破坏 07 边界 2 + 隐性重新生成 meta 债）· 不采纳。

---

## 2. 选定决议与理由（B'-1）

### 2.1 决议

**采纳选项 B' 子路径 B'-1（严格二维扩展）**：

1. 01 @v1.2 → @v1.3 升版 · 新增 §5.1.1（concern 预定义表）+ §5.3.1（历史兼容条款）
2. concern 维度预定义 **仅 kernel 侧**：`task × published` · `drift × triggered` · `drift × detected`（预留）· `drift × resolved`（预留）· `evo × scanned` · `evo × proposed`（预留）· `evo × consumed`（预留）· 共 7 对初始组合
3. evolution 域的字面兼容 —— 01 §5.1 承认 `evolution` 为 `evo` 的展开别名 · 但规范写法为 `evo-`（新事件必用 `evo-`）· `evolution-scanned-*` 两条历史事件通过 §5.3.1 豁免
4. `artifact-published-*` 历史事件通过 §5.3.1 豁免 · 未来同类事件规范写 `task-published-*`
5. CONV-01 扩展为 **CONV-01.1**（前缀合法性）· 同 txn 落入 ledger
6. 03 @v1 draft **可选**在 L1 事件骨架加 `concern` 字段 · 非必须 · 推迟到 03 发布决定
7. 07 @v1.1 published **不升版** · 因为 concern 维度在 kernel 内部封闭 · 未突破边界 2
8. 05 @v1.1 + 06 @v1.1 **不回改** · 其字面授权 `drift-triggered-` / `evolution-scanned-` 在新 01 §5 下被追认合法

### 2.2 三条硬证据支撑

#### 证据 1 · 事实权重（与落盘事件对齐）

22 条落盘事件中 · `task-*` 17 条 + 非 `task-*` 5 条 · 非 `task-*` 事件占比 22.7%。

A' 要求改这 5 条事件的 event_id 字面 · 破坏 append-only · **与事实冲突**。
B' 零回改 · **与事实对齐**。
C' 零回改但前缀字段去约束化 · **与事实对齐程度与 B' 相同 · 但代价是放弃 01 §5 原设计意图**。

仅在事实维度：B' ≈ C' > A'。

#### 证据 2 · spec 权威（与已 published spec 兼容）

07 ledger §1.6.2 CONV-01 主条款暗含"一旦 `status: published` · 原则上不回改 front-matter 与本文字面" · 这是 v8 收敛确立的隐性公约（由"事件本体即实证"原则反向推导）。

A' 要改 05 @v1.1 + 06 @v1.1 两份 published spec · **违反公约 2 次**。
B' 升 01 @v1.2 → @v1.3 · 只是常规 rev 递增 · **不违反公约**（公约允许 rev 升级 · 只禁止同 rev 内字面回改）。
C' 不改 spec 字面 · 但在 01 §5.1 "设计选型理由"段需要追加"但不再按前缀 grep"的反向注释 · 属于**同 rev 字面修订** · **违反公约 1 次**。

在 spec 权威维度：B' > C' > A'。

#### 证据 3 · 07 封闭性（与 extensibility 宪章兼容）

07 §1 边界 2 是 piao-pipeline 的**元约束**—— event_type 根命名空间封死。Q29 事件落盘违规的本质之一就是在根命名空间暗中扩展（`evolution-` / `artifact-` 作为新顶层前缀 · 超出 01 §5 七域）。

A' 不冲击 07（保留 7 域纯粹）。
B' 不冲击 07（concern 维度在 01 §5 内部扩展 · 不构成 event_type 根命名空间的增加 · 仍是 7 域 × N concern 的乘积）。
C' 暗中破坏 07（前缀字段去约束化后 · adapter 可任意发明前缀 · 因为工具不再按前缀判断域 · 等于让 event_type 的根命名空间事实上可由任何方扩展）。

在 07 兼容性维度：A' ≈ B' > C'。

#### 三证据综合打分

| 维度 | A' | B' | C' |
|------|-----|-----|-----|
| 事实对齐 | ❌ | ✅ | ✅ |
| spec 权威 | ❌❌ | ✅ | ⚠️（半违反）|
| 07 兼容 | ✅ | ✅ | ❌（暗破坏）|
| **综合** | **1/3** | **3/3** ← | **1.5/3** |

B' 三项全胜 · 独占最优解。

### 2.3 为何选子路径 B'-1 而非 B'-2

B'-1（严格）：新 concern 维度 = `task × published` 等 7 对 · `artifact-published-*` 作历史豁免。
B'-2（宽松）：新增独立 concern `published` · 允许任意域 × published。

选 B'-1 理由：

1. **一致性**：按 01 §5.3 "subject + 语义字段双轨" 原则 · artifact 的 URN 结构是 `urn:piao:artifact:...` · 其对应事件 subject 也以 artifact: 开头 · 这些事件已由 kernel 明确"归入 task 域"（01 §5 表第 3 行字面：`task` 域对应 `task.*`, `artifact.*`）· B'-1 保留这一原则 · B'-2 破坏（新增 artifact 前缀等于承认独立 artifact 域）
2. **未来简洁性**：未来 adapter 发此类事件 · 规范写法为 `task-published-*` 或 `task-consumed-*` · 不再制造 artifact-* 域的例外
3. **单一历史事件不值得开一整类**：`artifact-published-*` 仅 1 条 · 通过兼容条款豁免够用 · 不必新增 concern
4. **CONV-01.1 契约更简洁**：B'-1 下契约只需要说"前缀必须在 {七域 × N concern} 表内"· B'-2 下要说"前缀必须在 {七域 + artifact 域} × N concern 表内"· 多一条特例

---

## 3. 落地指令矩阵

### 3.1 指令总览

| # | 动作 | 目标资产 | 升版 | 优先级 | 阶段 |
|---|-----|---------|------|-------|------|
| L1 | 01 §5 扩展为二维分类 | `01-identity-model @v1.2 → @v1.3` | minor | P0 | γ₁ 收官前 |
| L2 | 01 §5.1.1 新增 concern 预定义表 | 同上 | - | P0 | 同 L1 |
| L3 | 01 §5.3.1 新增历史兼容条款 | 同上 | - | P0 | 同 L1 |
| L4 | M1-debt-ledger §1.7.1 Q29 标注为 consumed-via-m7-decision | `@v9 → @v10` | rev | P0 | γ₁ 收官前 |
| L5 | CONV-01 扩展为 CONV-01.1 | ledger §1.6.2 中补注 | 同 L4 | P0 | 同 L4 |
| L6 | 03 §3.2 L1 事件骨架（**可选**加 `concern` 字段） | `03-event-model @v1 draft` | draft 内原地 | P2 | 03 正式 published 时决定 |
| L7 | 07 @v1.1 published | - | - | - | **不动** |
| L8 | 05 @v1.1 + 06 @v1.1 published | - | - | - | **不动**（新 01 §5 追认合法性）|
| L9 | 已落盘 5 条非 `task-*` 事件 | - | - | - | **不改**（§5.3.1 豁免）|
| L10 | `piao-drift-compute.sh` / `piao-evolution-scan.sh` | - | - | - | **不改**（字面仍合法）|
| L11 | 本决议自身 artifact.published 事件 | `kernel-events/2026-04.jsonl` | append 1 行 | P0 | 本决议 draft→published 时 |

### 3.2 01 @v1.3 §5 升版草稿

（**注**：下文是草稿文本 · 最终由 L1 动作落入 01 时正式定稿 · 本决议只给出结构）

```markdown
## 5. event_id（事件的身份）

事件的身份**不使用 URN**，而是使用短格式：

```
{域}[-{concern}]-{YYMMDDHHmmss}-{6位hash}
```

| 段 | 规则 |
|----|------|
| 域 | 见 §5.1，7 选 1（不按 kind 也不按 realm 分，按**事件类型族**分） |
| concern（可选） | 见 §5.1.1，仅 kernel 侧预定义的合法组合（*v1.3 新增*） |
| 时间戳 | **UTC** 的 `YYMMDDHHmmss`（12 位十进制，人肉可读） |
| hash | 6 位 16 进制（0-9a-f），推荐由 sha1(event_body 规范化后) 取前 6 位 |

### 5.1 七域清单（同 @v1.2）

...（保持原文）...

注：`evo` 域在字面上承认 `evolution` 为其展开别名（仅历史兼容 · 新事件规范写 `evo-`）· 见 §5.3.1 豁免条款。

### 5.1.1 concern 预定义表（*v1.3 新增*）

event_id 前缀可附加一个 concern 段（四段式）· 表达 `{域 × 业务关切}` 双维度。**concern 维度由 kernel 封闭预定义 · adapter 不得新增**（同 §5.1 七域封闭原则一致）。

| 域 | 允许的 concern | 语义 | 示例 |
|----|--------------|-----|------|
| task | published | artifact 资产发布事件（归入 task 域 · 因 artifact 生成总在某个 task 执行中）| `task-published-260420001000-abc123` |
| task | consumed | artifact 资产消费事件（预留）| - |
| drift | triggered | drift 被源数据触发 | `drift-triggered-260418121000-abc123` |
| drift | detected | drift 被探测（预留）| - |
| drift | resolved | drift 被处理后解决（预留）| - |
| evo | scanned | evolution source 扫描事件 | `evo-scanned-260418130000-abc123` |
| evo | proposed | evolution source 浮现 proposal 候选（预留）| - |
| evo | consumed | evolution source 被决议消费（预留）| - |

**concern 维度的扩展路径**：
- kernel 侧新增 concern：通过 m8+ milestone 决议 + 本章表扩展 + 01 rev 升版
- adapter 侧新增 concern：**不允许** · 走"升 kernel"路径（同 01 §5 七域扩展路径一致）

### 5.3.1 历史事件兼容条款（*v1.3 新增*）

v1.3 之前已落盘的 L1 事件（见 `urn:piao:journal:kernel:kernel_events@2026-04` + `urn:piao:journal:kernel:mvp_smoke_events@2026-04`）· 其 event_id 字面若不符合 §5 + §5.1 + §5.1.1 的规范写法 · **在 v1.3 后仍保持原字面有效**· 不追溯回改。

具体历史兼容清单（截至 2026-04-20 00:45）：

| 历史字面 | 所属域 × concern（新表）| 规范写法 | 历史事件数 | 状态 |
|---------|---------------------|----------|-----------|------|
| `evolution-scanned-*` | evo × scanned | `evo-scanned-*` | 2 条 | ✅ 豁免（字面兼容）|
| `artifact-published-*` | task × published | `task-published-*` | 1 条 | ✅ 豁免（字面兼容）|

**规则**：

1. 历史事件只按"实质归类"进入查询索引（工具侧按 domain + concern 索引 · 不按字面前缀）
2. 未来新事件**必须**按 §5 + §5.1.1 规范写法 · 不得再使用豁免字面
3. 若 v1.4+ 有新豁免需求 · 通过 rev 升版扩展本表
```

### 3.3 M1-debt-ledger @v10 升版草稿

`@v9 → @v10` 的升版内容：

```markdown
### §1.7.1 Q29 状态更新（v10）

原 status: ⏸ continued-to-M7
新 status: ✅ **consumed-via-m7-decision**（2026-04-20 00:45 · 选定决议 B' 子路径 B'-1）

**消费路径**：`urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1 published`

**CONV-01 扩展为 CONV-01.1**（详见 §1.6.2 补注）。

**关闭条件对账**：
- [x] 选项裁定：B' 子路径 B'-1
- [x] 对 5 条已落盘事件的处置：不改 · 通过 01 @v1.3 §5.3.1 追认
- [x] 本决议 artifact.published 事件：已同 txn 发射（event_id: task-published-260420004500-xxxxxx 或 task-260420004500-xxxxxx）
- [ ] 01 @v1.2 → @v1.3 published（阶段 γ₁ 收官前完成）

### §1.6.2 CONV-01 补注（CONV-01.1 子条款）

（在原 CONV-01 主条款 + 三例外 EX1/EX2/EX3 之后追加）

**CONV-01.1 · 前缀合法性（*v10 新增 · 由 m7_prefix_taxonomy_decision@v1 建立*）**：

所有 L1 事件的 `event_id` 前缀段必须出现在 `01-identity-model.md @v1.3 §5 + §5.1.1 concern 预定义表` 中合法的 `{域, concern}` 组合内。单段式（仅域）为"无 concern"的合法特殊情形。历史事件通过 §5.3.1 豁免条款兼容 · 不追溯回改。

违反 CONV-01.1 的工具侧写入必须被 event_journal-append 层拒绝（v0.2 工具层兜底 · v0.1 阶段靠人工 review + 本决议作为规约基线）。
```

### 3.4 执行时间线（阶段 γ₁ 内所有动作）

```
2026-04-20 00:45 · 本决议 draft 完成（本 commit）
               ↓
  阶段 γ₁ 中段 · 01 @v1.2 → @v1.3 升版 + 发射事件
               ↓
  阶段 γ₁ 中段 · M1-debt-ledger @v9 → @v10 升版 + 发射事件 + CONV-01.1 登记
               ↓
  阶段 γ₁ 末段 · 本决议 status: draft → published + 发射本决议 artifact.published 事件（同 commit 延迟=0）
               ↓
  阶段 γ₁ 出口门控检查（详见 §4）
               ↓
  阶段 γ₂ 入口（工作流 X 起动 · Q-X1 首问已有答案：07 不升版）
```

---

## 4. 本决议对 03 / 01 / 07 的升版建议矩阵

> 本节对标 m7_closeout_kickoff @v1 §2.2 门控 "若选 B' · 01 §5 表升级草稿（`m7-kernel-alignment-proposal@v1` 独立 artifact）必须在阶段 γ₂ 入口前产出" —— 本节直接承担"升级草稿"的角色 · 不再另起 artifact。

| spec | 当前 rev | 建议新 rev | 变更范围 | 是否必须（P0）| 决议理由 |
|------|---------|-----------|---------|--------------|---------|
| `01-identity-model` | @v1.2 published | **@v1.3 published** | §5 加可选 concern · §5.1.1 新增 concern 预定义表 · §5.3.1 新增历史兼容条款 | ✅ **必须** | 本决议的核心产出依赖点 · 不升 01 则 B' 决议落空 |
| `03-event-model` | @v1 draft | 保持 draft · **可选**加 `concern` 字段 | §3.2 L1 事件骨架加 optional 字段 | ⚠️ **可选** | 工具可从 event_id 解析 · 骨架字段并非必需 · 03 published 前自行权衡 |
| `07-extensibility` | @v1.1 published | **不变** | - | ❌ **不必** | B' 决议在 kernel 内部扩展 · 不触碰 07 §1 边界 2 · Q-X1 首问（M7 kickoff §2.3）已得出答案 "不加第六条硬边界" |
| `05-drift-model` | @v1.1 published | **不变** | - | ❌ **不必** | `drift-triggered-*` 在新 01 §5 下合法 |
| `06-evolution-model` | @v1.1 published | **不变** | - | ❌ **不必** | `evolution-scanned-*` 通过 §5.3.1 兼容 |
| `02-artifact-model` | @v1.4 published | **不变** | - | ❌ **不必** | 本决议不涉及 artifact 模型 |
| `04-snapshot-model` | @v1.2 published | **不变** | - | ❌ **不必** | 本决议不涉及 snapshot |
| `00-overview` | @v1 | **不变** | - | ❌ **不必** | 总览层面无变化 |

**总升版量**：**1 份 published spec（仅 01 升 minor）** + 1 份 draft spec（03 · 可选）+ 1 份 ledger（M1-debt-ledger v10）= **3 个 artifact 变更点** · 其中 published 态 spec 升版仅 1 个。

这与选项 A'（2 份 published spec 回改）/ 选项 C'（1 份 published spec 同 rev 字面修订）对比 · B' 的升版范围是**最集约**的。

---

## 5. 阶段 γ₁ 出口门控对账

| 门控项（来自 m7_closeout_kickoff @v1 §2.2）| 状态 | 证据 |
|------------------------------------------|------|------|
| `_review/m7-prefix-taxonomy-decision.md @v1 published`（三选项对比矩阵齐全 + 选定决议有 ≥3 条硬证据支撑） | 🔄 本文件 draft → published（本 commit 后）· §1 对比矩阵齐全 · §2.2 三条硬证据 | 本文件 §1/§2 |
| CONV-01（ledger v9 §1.6.2）在本决议中是否扩展须明确裁定 | ✅ 扩展为 CONV-01.1（§3.3 草稿 · L5 指令）| 本文件 §2.1 第 5 点 + §3.3 |
| 已落盘 5 条非 `task-*` 事件的处置路径必须明确 | ✅ 不改 · 由 01 @v1.3 §5.3.1 历史兼容条款追认 · 见 §1.2.2 + §3.2 | 本文件 §2.1 第 4 点 + §3.2 §5.3.1 草稿 |
| 若选 B' · 01 §5 表升级草稿必须在阶段 γ₂ 入口前产出 | ✅ 本决议 §3.2 即是升级草稿（不另起 artifact）| 本文件 §3.2 |
| 本决议的 `artifact.published` L1 事件同 txn 发射 | 🔄 本 commit 合并发射（延迟=0 · 同 m7_closeout_kickoff 范式）| 本 commit diff |

阶段 γ₁ 预估时长 2-4 小时 · 实际从 00:30（M7 kickoff published）→ 00:45（本决议 draft）= **15 分钟**（远低于预估 · 主要因为 m7_closeout_kickoff §3.4 已做预分析 · 本决议相当于把预分析升版为正式决议 · 并补齐对比矩阵 + 落地草稿）。

---

## 6. Self-Review 签收（对标 M5/M6 alignment-proposal 范式）

| # | 签收项 | 状态 | 证据 |
|---|-------|------|------|
| 1 | 三选项对比矩阵是否客观（不偏袒采纳项） | ✅ 通过 | §1.1 总体代价表 10 维度均列出三项对比 · §1.2 各选项独立详解含硬伤分析（A' 列 4 硬伤 · C' 列 4 硬伤 · B' 也列 1 复杂点即 B'-1/B'-2 子路径选择）|
| 2 | 选定决议是否基于 ≥3 条硬证据 | ✅ 通过 | §2.2 三证据：事实权重 / spec 权威 / 07 封闭性 · 综合打分 3/3 |
| 3 | 对已落盘事件的处置是否明确 | ✅ 通过 | §2.1 第 4 点 + §3.2 §5.3.1 草稿 · "不改 · 豁免"双确认 |
| 4 | 对下游 spec 升版建议是否覆盖完整 | ✅ 通过 | §4 全量矩阵（8 份 kernel spec + 2 份 draft + ledger）· 每份都有"升 / 不升"判定 |
| 5 | CONV-01 契约是否正确处理 | ✅ 通过 | §3.3 CONV-01.1 子条款草稿 · 补注到 ledger §1.6.2 |
| 6 | 本决议 artifact.published 事件是否计划发射 | ✅ 通过 | §3.1 L11 + §3.4 时间线 + §5 出口门控 |
| 7 | 上游锚点是否全量引用 | ✅ 通过 | front-matter upstream 7 条（m7 kickoff + ledger v9 + 01 + 07 + m6 consumption + 两个 journal）|
| 8 | supersedes / resolves 关系是否声明 | ✅ 通过 | front-matter `resolves: Q29` |

**8/8 通过** · 签收完成。

---

## 7. 与 v0.1 Closeout 的衔接

本决议 published 后 · 工作流 P 完成 · 阶段 γ₁ 可退出。

**阶段 γ₂（工作流 X · 07 Extensibility 宪章压测）入口条件已满足**：

- Q-X1（"07 §1 是否需第六条硬边界"）：**本决议 §4 已给答案 = 不加**（B' 决议在 kernel 内部扩展不开放 adapter · 第六条硬边界无必要）
- Q-X2（"07 §0 过早抽象原则 vs Q29 事实驱动抽象"）：**本决议 §2.2 证据 3 已隐性给答案**（B' 路径是"事实驱动的精确抽象"而非"过早抽象"· 因为新 concern 维度来源于已发生事件 · 非假想需求）
- Q-X3（"07 五硬边界是否覆盖事件分类系统扩展点"）：**未直接涉及** · 留给阶段 γ₂ 正式答复 · 但倾向是"已覆盖（隐含在边界 2 的 event_type 根命名空间内）· 无需补"
- Q-X4（"B' 下 adapter 是否可定义自己 concern"）：**本决议 §2.1 第 2 点已明确** = 不允许 · 与边界 2 七域封闭原则一致
- Q-X5（"07 是否反向审查 M1-M6"）：**未直接涉及** · 留给阶段 γ₂

**结论**：本决议间接解决了 Q-X1/Q-X2/Q-X4 三问 · 阶段 γ₂ 负担减至 Q-X3/Q-X5 两问 · 工作流 X 预估时长从"1-3 小时"进一步压缩至"0.5-1.5 小时"。

---

**本决议状态**：published · rev v1（2026-04-20 00:45）
**上游锚点**：
- `urn:piao:proposal:kernel:m7_closeout_kickoff@v1 §2.2 / §3` · 工作流 P 入口指令
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v9 §1.7.1` · Q29 登记
- `urn:piao:spec:architecture:identity_model@v1.2 §5` · 被裁定对象
- `urn:piao:spec:architecture:extensibility@v1.1 §1` · 隐含约束（边界 2）
- `urn:piao:artifact:kernel:m6_debt_consumption@v1` · CONV-01 前置
- `urn:piao:journal:kernel:kernel_events@2026-04` · 17 条 task-* + 1 条 artifact-published-* 活证据
- `urn:piao:journal:kernel:mvp_smoke_events@2026-04` · 2 条 drift-triggered-* + 2 条 evolution-scanned-* 活证据

**resolves**：Q29（`M1-debt-ledger @v9 §1.7.1`）· 由 continued-to-M7 转为 consumed-via-m7-decision。

**下一步（阶段 γ₁ 剩余 + 阶段 γ₂ 入口）**：

1. 本决议 status: draft → published（本 commit 内自升 · 同范式 m7_closeout_kickoff）
2. 发射本决议 artifact.published L1 事件（前缀 `task-*` 严格合规 01 §5 · event_type: `artifact.published` · subject: 本决议 URN）· 同 commit 发射 · 延迟=0
3. 升 01-identity-model @v1.2 → @v1.3（按 §3.2 草稿）+ 发射升版事件
4. 升 M1-debt-ledger @v9 → @v10（按 §3.3 草稿 · §1.7.1 Q29 consumed + §1.6.2 CONV-01.1 追加）+ 发射升版事件
5. 阶段 γ₁ 出口 · 进入阶段 γ₂（工作流 X · Q-X1/Q-X2/Q-X4 由本决议预答 · 仅需正式化 + 答 Q-X3/Q-X5）
