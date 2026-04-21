---
urn: urn:piao:proposal:kernel:m7_closeout_kickoff@v1
kind: proposal
rev: v1
status: published
produced_by: m6-milestone-closeout + m6-tail-followup
published_at: 2026-04-20T00:30:00+08:00
upstream:
  - urn:piao:snapshot:kernel:m6_final_decisions@v1
  - urn:piao:artifact:kernel:m6_mvp_smoke_report@v1
  - urn:piao:artifact:kernel:m6_debt_consumption@v1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v9
  - urn:piao:spec:architecture:identity_model@v1.2
  - urn:piao:spec:architecture:extensibility@v1.1
supersedes: urn:piao:proposal:kernel:m6_evolution_kickoff@v1
wordcheck_exempt: true
---

# M7 Closeout Kickoff · M6 milestone 收官后的 closeout 决策与 v0.1 收官路径

> 本文档是 **M6 milestone 收官后（2026-04-19 21:34）** + **M6 扫尾续收敛完成后（2026-04-20 00:10）** 的工作编排 proposal · 承接 `m6_evolution_kickoff@v1 (superseded)` 的角色——由 M6 milestone 推进到 **M7 closeout + v0.1 里程碑收官** 阶段。
>
> **定位**：`kind: proposal`（不是 snapshot · 因为计划可能被 Q29 裁定结果调整 · 沿用 `post-m1-kickoff / m5_drift_kickoff / m6_evolution_kickoff` 三代前例范式 · 为 **kernel 层 kickoff 范式第四代实例**）。
>
> **消费方式**：进入任一工作项前，把对应段落转为 `task.*` L1 事件并关联回本 proposal 的 URN。
>
> **阅读路径**：先读 `m6-final-decisions @v1 §4.5 M7 入口预声明` + `§6 m6_evolution_kickoff 生命周期闭合` → 再读 `M1-debt-ledger @v9 §1.7 Q29 登记`（Q29 是 M7 决议 1-2 优先裁定项 · 证据密度最高的前置约束）→ 再读 `07-extensibility.md @v1.1 published`（M7 宪法层 · 本 milestone 的处置对象）→ 最后读本文档（下一步去哪）。

---

## 0. 当前位置总览

按 `00-overview.md §1 核心公式` 的 7 维进度（M6 收官 + 扫尾续收敛完成时刻 · 2026-04-20 00:10）：

| 维度 | 状态 | 下一步触发条件 |
|------|------|---------------|
| Identity（M1） | ✅ @v1.2 published | **Q29 若裁定为选项 B'（扩展 01 §5 事件域分类系统）· 可能触发 @v1.2 → @v1.3 升版** |
| Artifact（M2） | ✅ @v1.4 published（带 6 条 BAN 遗留 + Q4 WARN） | 阶段 3 `02@v2` 清理 §1.1 六条 BAN + §1.2 Q4 |
| Layering × Event（M3） | 🔄 @v1 draft（§3.3.1 R22 已泛化为 N 条同 txn） | **Q29 裁定后可能涉及 03 §3.2 L1 事件骨架字段扩展** |
| Snapshot（M4） | ✅ @v1.2 published（R21 + R24 落地） | 无未决项 |
| Drift（M5） | ✅ @v1.1 published（2026-04-19 15:40 收官） | 无未决项 |
| Evolution（M6） | ✅ @v1.1 published（2026-04-19 22:40 收官 + 23:17 遗留收敛 + 00:10 扫尾续收敛） | 无未决项；`piao-evolution-scan.sh @v0.1 MVP` + smoke 1-4 全通 |
| **Extensibility（M7） · closeout** | 🚧 @v1.1 published · **本 proposal 的核心处置对象** | 见 §2 两分支路径 |

**结论**：kernel 侧的 7 维中 6 维已 published · 1 维（M3）仍 draft（受 M7 裁定影响）· **M7 不是"新起规格"而是"对 07 宪法层的升版评估 + v0.1 里程碑收官"**。

但 **Q29 的发现使 M7 不再是纯形式收官**——需要先裁定 Q29（event_id 前缀分类系统缺口）· 才能决定 07 / 01 / 03 三文档是否需要**第二轮小升**。

---

## 1. 工作流总览

本 proposal 管理三条工作流：

- **工作流 P · Prefix Taxonomy 裁定**（Q29 三选项 A'/B'/C' · 详见 §3）—— 阶段 γ₁ 执行主体
- **工作流 X · Extensibility 宪章压测**（07 @v1.1 是否需要补升 · 详见 §4）—— 阶段 γ₂ 执行主体 · 依赖工作流 P 输出
- **工作流 C · v0.1 Closeout**（kernel 层收官快照 · 详见 §5）—— 阶段 γ₃ 执行主体 · 依赖 P 与 X 两条工作流收敛

执行顺序锁定为 **"P 先行 → X 跟进 → C 收官"**（详见 §2）。这与前三代 kickoff 的范式存在**关键差异**——前三代均为"工具链先行、规格跟进"（post-m1 / m5 / m6 同构）· 本代为 **"meta 债裁定先行 → 规格评估跟进"**· 是 **kernel 层 kickoff 范式第四代变体**（非同构复用 · 首次出现**决议层**作为入口工作流）。

这个差异是合理的——因为 M1-M6 每一代都是"新建规格 + 支撑工具"· 而 M7 面对的不是新建而是收官 · 起点不是"缺口"而是"已落盘 journal 中的事实矛盾"· 天然需要先做"事实对账"才能进入规格决议。

---

## 2. 执行顺序：P 优先（三阶段门控）

> 本节是 `status: draft` 锁定的**候选路径**。曾评估过的 X 优先 / P + X 并行 两个选项及其淘汰理由见本节末 · 待 Q29 裁定后本节升 published 时锁死。

### 2.1 核心判断

**背景事实**（Q29 活证据 · 落盘 journal 实测）：

1. **`kernel-events/2026-04.jsonl`** 18 行事件 · 17 条 `task-*`（01 §5 合规 · 含 Q27 补发 14 + N1 + N2 + ledger@v9 自指）+ 1 条 `artifact-published-*`（01 §5 **不合规** · 非 7 域任一）
2. **`mvp-smoke/events/2026-04.jsonl`** 4 行事件 · 2 条 `drift-triggered-*`（01 §5 **边缘合规** · `drift` 域延伸为三段式）+ 2 条 `evolution-scanned-*`（01 §5 **不合规** · `evolution-` 不等于 `evo` 域前缀）
3. **综合合规率**：22 行 journal 事件中 · **01 §5 严格合规 17 条**（77.3%）+ **边缘合规 2 条**（9.1%）+ **不合规 3 条**（13.6%）
4. **合规偏差根因**：`piao-drift-compute.sh` / `piao-evolution-scan.sh` 两份工具的 event_id 生成逻辑字面约定是 spec 字面授权域的"扩展命名"（参考 05 / 06 原稿）· 但该授权与 01 §5 顶层域表事实冲突
5. **`01 §5` 当前明列 7 域**：`pipe` / `tdag` / `task` / `trace` / `evo` / `drift` / `gate`
6. `smoke-report @v1` 的预占前缀 `artifact-published-*` 是**第三类违规**——根本不属于 7 域任一 · 但已 published + 落盘 · 追改即破坏 sha256 锚定

**依赖方向判断**：

- **工作流 P（Q29 裁定）不依赖任何 spec 升版**——它是对既有 7 域分类系统的**决议层动作**· 可立即执行
- **工作流 X（07 评估）依赖 P 输出**——Q29 的三选项裁定结果直接决定 07 是否需要在 "Extensibility Boundary" 中追加 "event_id 前缀域" 作为 adapter 可扩展点（选项 B'）· 还是反之收紧 kernel 内部分类（选项 A'）· 还是维持现状 + 工具侧兼容（选项 C'）
- **工作流 C（v0.1 收官）依赖 X 输出**——X 若判定 07 无需补升 · C 可直接封版；X 若判定需补升 · C 等待 07 @v1.2 published 后再封版

**触发顺序锁定为 P → X → C**：P 是前置约束 · X 是中间执行 · C 是终态快照。

### 2.2 阶段 γ₁（立即）· 工作流 P · Q29 裁定决议

**目标**：就 `M1-debt-ledger @v9 §1.7.1` 登记的 Q29 三选项 A'/B'/C' 作出 kernel 层决议 · 产出 `m7_prefix_taxonomy_decision@v1` 作为独立决议 artifact（类比 `m6_evolution_kernel_alignment@v1` 范式）。

**决议对象回顾**（完整表述见 `M1-debt-ledger @v9 §1.7.1`）：

- **选项 A'**：收敛到 7 域 · 要求 `drift-triggered-` / `evolution-scanned-` / `artifact-published-` 三类变体在 M7 改名对齐 `drift-*` / `evo-*` / `task-*` · 代价是否定 05 / 06 spec 字面授权 + 已落盘 5 条事件需 alias 映射
- **选项 B'**：承认事件 event_id 前缀的"事件类型维度"· 扩展 `01 §5` 为二维分类（域 × concern）· 工具链按多维索引 · 需 M7 阶段 γ₁ 重新设计 01 §5 分类表
- **选项 C'**：维持现状 · 工具侧实现 prefix-agnostic 扫描（依赖 `event_type` + `artifact_kind` + `producer_task_urn` 三元组）· 零 kernel 变更 · 但推翻 01 §5 将 event_id 前缀作为"域分隔符"的设计意图

**产出**：`_review/m7-prefix-taxonomy-decision.md @v1` · 内容五段式：

1. §1 三选项对比矩阵（合规代价 / 工具变更代价 / spec 升版范围 / 现网落盘事件处置路径 / 未来扩展性）
2. §2 选定决议 + 理由（预估倾向 B' · 基于"与事实对齐比与设计对齐更稳"的 M5 范式）
3. §3 落地指令矩阵（若选 A'：5 条事件 alias 映射清单 + `piao-drift-compute.sh` / `piao-evolution-scan.sh` 前缀改名 · 若选 B'：01 §5 表升级草稿 + CONV-01 契约扩展 + 03 §3.2 L1 事件骨架是否加 `concern` 字段 · 若选 C'：`piao-event-scan.sh` 新工具立项 + `01 §5.1/5.3` 补注"前缀非规约"）
4. §4 对 03 / 01 / 07 三份 spec 的升版建议（配套升版矩阵）
5. §5 self-review 签收（对标 M5 / M6 alignment-proposal 范式）

**门控（全部满足方可退出阶段 γ₁）**：

- [ ] `_review/m7-prefix-taxonomy-decision.md @v1 published` · 三选项对比矩阵齐全 · 选定决议有 ≥3 条硬证据支撑
- [ ] CONV-01（ledger v9 §1.6.2 建立的通用契约）在本决议中**是否扩展**须明确裁定（B' 下强扩展 + C' 下需补注"CONV-01 不约束前缀"）
- [ ] 本决议对"已落盘 5 条非 `task-*` 事件"的处置路径必须明确（不改 / alias / 追改三选一）· 不允许"留给实施时定"
- [ ] 若选 B' · 01 §5 表升级草稿（`m7-kernel-alignment-proposal@v1` 独立 artifact）必须在阶段 γ₂ 入口前产出
- [ ] 本决议的 `artifact.published` L1 事件同 txn 发射（严格遵循 CONV-01 主条款）· 本次不再用 CONV-01 EX1 延迟路径（v9 自指已验证同 commit 发射可行）

**阶段 γ₁ 预估时长**：2-4 小时（类比 M6 kernel alignment proposal · 无需工具链实施环节）

### 2.3 阶段 γ₂（γ₁ 后）· 工作流 X · 07 Extensibility 宪章压测

**目标**：基于阶段 γ₁ 的 Q29 裁定结果 · 对 `07-extensibility.md @v1.1 published` 进行第二轮压测 · 判定是否需要 @v1.1 → @v1.2 升版（或 @v2 大升）。

**压测维度**（五条必答问题）：

- **Q-X1**：Q29 三选项（尤其 B'）落地后 · 07 §1 "kernel / adapter 五条硬边界"是否需要第六条（`event_id 前缀域` 作为 adapter 可扩展点）？
- **Q-X2**：07 §0 "过早抽象是万恶之源"原则是否需要在 event_id 前缀分类系统下重新表述？Q29 的本质是"事实驱动的抽象需求浮现"· 刚好是 §0 反面教材 · 可作 07 自洽性压测
- **Q-X3**：07 当前列出的 kernel / adapter 五硬边界是否覆盖 Q29 所暴露的"事件分类系统扩展点"？若未覆盖 · 是缺失（需补）还是设计有意为之（需注明）？
- **Q-X4**：若选 B'（01 §5 扩展为二维）· 07 是否需要定义"扩展维度上 adapter 的权利边界"（即 adapter 是否可定义自己的 `concern` · 以及如何避免 adapter 侧 `concern` 命名空间污染）？
- **Q-X5**：v0.1 milestone 收官前 · 07 是否需要承担"前置 M1-M6 所有 kernel 层 milestone 的反向审查"（类似 M6 对 05/06 的反向审查）？

**产出**：`_review/m7-closeout-draft-review.md @v1`（对标 `m5-drift-draft-review @v1` / `m6-evolution-draft-review @v1` 范式）· 但**目标不是 07 新 draft 的审查**· 而是"**07 @v1.1 published 是否应升 draft 的入口评估**"——若五问全答"无须升版"· 则 07 保持 @v1.1 进入 C · 若有一问需升版 · 则转阶段 γ₂' 起 draft。

**门控（全部满足方可退出阶段 γ₂）**：

- [ ] `_review/m7-closeout-draft-review.md @v1 published` · Q-X1 至 Q-X5 五问逐条答复 + 证据指向
- [ ] 若任一问答"需升版"· 则 `07-extensibility.md @v1.1 → @v1.2 draft` 起稿 · 依循 M6 路径 A/B 双路径决策模型
- [ ] 若所有问题答"无须升版"· 则产出 `_review/m7-closeout-extensibility-acceptance@v1 published`（对标 `m6-mvp-smoke-report @v1` 但无工具链主体 · 仅宪章自洽性 sign-off）

**阶段 γ₂ 预估时长**：1-3 小时（若无需升版）· 4-8 小时（若需升版走路径 A）· 1-2 天（若需升版走路径 B 外篇升降）

### 2.4 阶段 γ₃（γ₂ 后）· 工作流 C · v0.1 Closeout 快照

**目标**：kernel 七大模型全部 published 态确认 + `v0_1_final_decisions@v1 published` 快照封版 + `ARCHITECTURE_SNAPSHOT.md` 同步更新。

**产出**：

1. `_review/v0_1-final-decisions.md @v1 published`（对标 `m6-final-decisions @v1` · 但承担 kernel 层全局快照而非单 milestone）· 内容六段式：
   - §0 快照覆盖范围（7 维全量）
   - §1 三代 kickoff 接力链完整闭合（post-m1 / m5 / m6 / m7 · 第四代验证）
   - §2 kernel 七大模型终态矩阵（URN + rev + 每份 spec 的 @最终 rev published_at）
   - §3 CONV-* 通用契约矩阵（CONV-01 主条款 + EX1/EX2/EX3 + 可能的 Q29 裁定后扩展）
   - §4 adapter 接入入口清单（M2 frontend_migration 起点 + 未来 adapter 模板）
   - §5 本快照 self-review 签收（对标 M5 / M6 六项签收 · 扩展为 v0.1 级别八项）
2. `m7_closeout_kickoff @v1 status: draft → published → superseded`（由本快照 supersede）· 与 `m6_evolution_kickoff @v1` 生命周期闭合同构
3. `M1-debt-ledger @v9 → @v10`（登记 Q29 consumed 或 continued-to-v0.2 视裁定而定 · 对标 v7→v8→v9 收敛批次节奏）
4. `ARCHITECTURE_SNAPSHOT.md` 同步至 v0.1 终态（所有 URN + rev + sha256 三元组全量）

**门控（全部满足方可退出阶段 γ₃ · v0.1 milestone 宣告收官）**：

- [ ] kernel 七份 spec 全部 published（01@v1.2 / 02@v1.4 / 03@未来 published / 04@v1.2 / 05@v1.1 / 06@v1.1 / 07@v1.1 或 @v1.2）
- [ ] `M1-debt-ledger` 状态为 `consumed` 或明确 continued-to-v0.2 的剩余项清单（§1.1 六条 BAN + §1.2 Q4 必须完全 consumed 或明确推迟至 v0.2）
- [ ] 所有 `published` 态 artifact 在对应 journal 中都有 `artifact.published` L1 事件（CONV-01 闭合审计：对 `docs/piao-pipeline/kernel/` 下所有 kind=spec/artifact 的文档作事件可见性 grep 审计 · 全 100% 覆盖）
- [ ] 三代 kickoff 接力链闭合（v0.1 final-decisions 承接 m7_closeout_kickoff · 形成 **4 代同构范式验证完成**）
- [ ] `_review/v0_1-final-decisions.md @v1 published` 的 self-review §5 八项全签收通过

**阶段 γ₃ 预估时长**：3-6 小时（类比 m6-final-decisions 的 self-review + commit 批次节奏）

---

## 3. Q29 核心证据图景（工作流 P 决议前置）

> 本节承担**阶段 γ₁ 入口的证据基线**· 在工作流 P 的 `m7-prefix-taxonomy-decision.md` 之前必须先达成共识 · 否则裁定本身会浮空。

### 3.1 01 §5 表的七域清单

`01-identity-model @v1.2 published §5` 当前明列：

| # | 域前缀 | 对应 event_type 命名空间 |
|---|-------|--------------------------|
| 1 | `pipe` | `pipeline.*` |
| 2 | `tdag` | `taskdag.*` |
| 3 | `task` | `task.*`, `artifact.*`（artifact 事件归入 task 域） |
| 4 | `trace` | `trace.*`, `verify.*` 等执行细粒度事件 |
| 5 | `evo` | `evolution.*` |
| 6 | `drift` | `drift.*` |
| 7 | `gate` | `gate.*`, `stage.*` |

event_id 规约形式：`{域}-{YYMMDDHHmmss}-{6位hash}`（三段式）。

### 3.2 现网落盘 21 条事件合规性精确对账

| 事件 ID | 前缀字面 | 三段式合规 | 01 §5 域对应 | 合规结论 |
|--------|---------|-----------|-------------|---------|
| `task-260418121000-abc123` 类（14 条 Q27 补发）| `task-*` | ✅ | 3. task（artifact 归入）| ✅ 严格合规 |
| `task-260419144000-86e9a2`（06@v1.1 published）| `task-*` | ✅ | 3. task | ✅ 严格合规 |
| `task-260419151700-a9b94e`（consumption@v1 · N1）| `task-*` | ✅ | 3. task | ✅ 严格合规 |
| `task-260419151700-2121e1`（ledger@v8 · N2）| `task-*` | ✅ | 3. task | ✅ 严格合规 |
| `task-260419161000-0ece84`（ledger@v9 · 自指）| `task-*` | ✅ | 3. task | ✅ 严格合规 |
| `drift-triggered-*` × 2（mvp-smoke）| `drift-triggered-*` | ❌（**四段式**：域-业务-时间戳-hash）| 6. drift（边缘）| ⚠️ 字面扩展为四段式 · 与 01 §5 三段式模板不符 |
| `evolution-scanned-*` × 2（mvp-smoke）| `evolution-scanned-*` | ❌（**四段式**）| **非任一域**（`evo` 而非 `evolution`）| ❌ 双重违规（域名不对 + 四段式） |
| `artifact-published-260419223000-rpt001`（smoke-report@v1 · N3'）| `artifact-published-*` | ❌（**四段式**）| **非任一域**（无独立 `artifact` 域 · 01 §5 明确 artifact 归入 task 域）| ❌ 双重违规 |

**合规率统计**（基数 21）：

| 层级 | 数量 | 占比 |
|------|------|------|
| ✅ 严格合规（`task-*` 三段式） | 17 条 | **81.0%** |
| ⚠️ 边缘合规（`drift-*` 正确但扩展为四段式） | 2 条 | 9.5% |
| ❌ 不合规（域名错误 + 四段式） | 2 + 1 = 3 条 | 14.3% |
| ❌ 双重不合规 | 3 条 | 14.3% |

（⚠️ + ❌ 叠加不唯一 · 见 3.3 解释）

### 3.3 违规细分与 05 / 06 spec 字面授权链

**①**：`drift-triggered-*` 来源链 —— `05 @v1.1 §6.1` → `piao-drift-compute.sh --emit-events` → 落盘事件。05 原稿字面授权 `drift-triggered-` 前缀为 drift 触发事件标识 · 虽在 01 §5 `drift` 域内 · 但**字面扩展为四段式**（`drift-triggered-{time}-{hash}`）是 05 特有规约（未在 01 §5 反映）。

**②**：`evolution-scanned-*` 来源链 —— `06 @v1.1 §X` → `piao-evolution-scan.sh` → 落盘事件。06 原稿字面授权 `evolution-scanned-` 前缀为 evolution 扫描事件标识 · 但 01 §5 明列的是 `evo-` 而非 `evolution-` · **存在字面分歧**（Q29 根源之一）· 且同样扩展为四段式。

**③**：`artifact-published-*` 来源链 —— `smoke-report @v1` front-matter 预占。**无任何 spec 字面授权**· 是本次 M6 扫尾中临时预占造成的 · 与 01 §5 的"artifact 事件归入 task 域"条款**直接冲突**。

**综合判断**：违规不是工具实施的随意选择 · 而是 **05 / 06 spec 字面与 01 §5 的规约分歧**（①②）+ **本次扫尾的预占疏失**（③）的混合产物。Q29 裁定必须同时处理三条路径 · 不能只选一条。

### 3.4 选项压测（为阶段 γ₁ 裁定预热）

> 以下为本 proposal 作者预分析 · 非决议 · 以便 γ₁ 阶段有起点。

**A' 成本最高**：需改 05 §6.1 + 06 §X 两份 published spec 的字面 · 破坏"一旦 published 原则上不回改"公约 · 且 5 条落盘事件需追认 alias · 属"逆流而上"路径。

**B' 成本中等、收益最高**：扩展 01 §5 表为 `{域, 业务 concern}` 二维 · 把 `drift-triggered-` 合法化为 `drift × triggered` · `evolution-scanned-` 合法化为 `evo × scanned`（同时 01 §5 需承认 `evolution` 作为 `evo` 的完整展开别名）· `artifact-published-` 合法化为 `task × published`（因为 artifact 归入 task 域 · 扩展后表达为 task 域下 `published` concern）。**代价**：01 升 @v1.3 + 03 §3.2 L1 事件骨架可能加可选 `concern` 字段。**收益**：与落盘事实对齐 · 05/06 spec 不改 · 未来 adapter 可定义自己的 `concern` 名（通过 07 §1 补第六条硬边界约束）。

**C' 成本低但推翻设计意图**：零改 spec · 工具侧纯兼容。**代价**：01 §5 §5.1 设计意图推翻 · 未来新工具侧需自觉不再用前缀域分类 · 埋新的 meta 债。

**预估倾向**：**B'**（与 M6 路径 B"外篇升降"范式同构 · 事实驱动 spec 升版 · 而非 spec 驱动事实改名）。

---

## 4. 关闭条件

本 proposal 在满足以下全部条件后由阶段 γ₃ 产出的 `v0_1_final_decisions @v1` supersede：

- [ ] **工作流 P 完成**：`_review/m7-prefix-taxonomy-decision @v1 published` · Q29 选定决议 A'/B'/C' · 落地指令矩阵齐全
- [ ] **工作流 X 完成**：`_review/m7-closeout-draft-review @v1 published` Q-X1 至 Q-X5 五问答毕 · 07 是否升版已判定
- [ ] **工作流 X' 完成（若需）**：`07-extensibility.md @v1.2 published`（仅在 X 判定需升版时）
- [ ] **工作流 C 完成**：`_review/v0_1-final-decisions @v1 published` self-review 八项全签收通过
- [ ] **CONV-01 闭合审计通过**：kernel 目录下所有 `status: published` 文档的 `artifact.published` 事件 100% 在 journal 可见
- [ ] **M1-debt-ledger @v10**：Q29 按决议置 consumed 或明确推迟 · §1.1 六条 BAN 清零（阶段 3 目标）或推迟至 v0.2
- [ ] **三代 kickoff 接力链成四代闭合**：`m7_closeout_kickoff @v1 status: draft → published → superseded`
- [ ] **ARCHITECTURE_SNAPSHOT.md 同步至 v0.1 终态**（URN + rev + sha256 全量）

---

## 5. 附录

### 5.1 与前三代 kickoff 的范式对照

| 维度 | post-m1-kickoff | m5-drift-kickoff | m6-evolution-kickoff | **m7-closeout-kickoff** |
|------|----------------|------------------|---------------------|------------------------|
| 代数 | 第一代（根范式） | 第二代 | 第三代 | **第四代** |
| 工作流数 | 2（B+A）| 2（T+D）| 2（T'+E）| **3（P+X+C）** |
| 入口工作流 | B · 证据先行 | T · 工具先行 | T' · 工具扩展先行 | **P · 决议先行** |
| 入口工作流性质 | 工具链 | 工具链 | 工具链 | **决议层** |
| 变体类型 | 根 | 同构复用 | 同构复用 | **首次同构变体**（决议层替代工具层入口） |
| 封版承接 | m4_final_decisions | m5_final_decisions | m6_final_decisions | **v0_1_final_decisions**（首次承接 milestone 级而非 milestone 单项） |

**变体原因**：M1-M6 每代都面对"新建规格缺口"· 需要"工具/证据先行 · 规格跟进"。M7 面对的是"已落盘事实的分类矛盾"· 需要"决议层对账"作为规格升版前置。这是**范式的合理演化**· 不是偏离。

### 5.2 淘汰选项与理由

**选项 X 优先（P 并行）**：淘汰 · 理由 = 若 07 评估脱离 Q29 裁定结果 · 五问中 Q-X1/Q-X3/Q-X4 三问均无法答复（必须依赖 P 输出才能决定 07 是否加"事件前缀 concern 扩展点"硬边界）· 会导致 γ₂ 阶段死循环。

**选项 P + X 并行**：淘汰 · 理由 = 同上 · Q-X 五问对 P 的依赖性是硬依赖 · 不是软耦合 · 无法并行。

**选项 P 优先（X 在 P 完成后跟进）**：**采纳**· 如本 §2 描述。

---

**本 proposal 状态**：published · rev v1（2026-04-20 00:30）
**上游锚点**：
- `urn:piao:snapshot:kernel:m6_final_decisions@v1 §4.5` · M7 入口预声明 + `§6` 三代 kickoff 接力链
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v9 §1.7` · Q29 登记（M7 决议 1-2 优先裁定项）
- `urn:piao:spec:architecture:identity_model@v1.2 §5` · 七域清单（Q29 裁定对象）
- `urn:piao:spec:architecture:extensibility@v1.1` · 07 宪章（工作流 X 压测对象）
- `urn:piao:artifact:kernel:m6_mvp_smoke_report@v1` · evolution MVP 反证（γ₁ 前置事实基线的一部分）
- `urn:piao:artifact:kernel:m6_debt_consumption@v1` · CONV-01 通用契约建立（γ₁ 可能扩展的契约）

**supersedes**：`urn:piao:proposal:kernel:m6_evolution_kickoff@v1` · 本 proposal 是三代 kickoff 接力链的第四代 · 承接 m6_evolution_kickoff 的角色由 m6_final_decisions 承接后 · 再由本 proposal 承接至 v0_1_final_decisions。

**下一步（阶段 γ₁ 立即动作）**：
1. 起 `_review/m7-prefix-taxonomy-decision.md @v1 draft`（作为工作流 P 的核心决议 artifact）
2. 发射本 proposal 的 `artifact.published` L1 事件到 `kernel-events/2026-04.jsonl`（CONV-01 主条款 · 同 commit 发射 · 压测延迟为 0）· 与本 commit 合并
3. 下次 rev 升降（若需修订 §2/§3 本 proposal draft 内容）按 CONV-01 EX2 不发射事件（draft 内原地修订） · rev 递增至 `@v2` 时才再次发射（`rev_N → rev_N+k`）
