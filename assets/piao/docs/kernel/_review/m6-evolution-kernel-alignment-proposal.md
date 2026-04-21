---
urn: urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1
artifact_type: proposal.kernel_minor_upgrade
kind: proposal
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-19T20:05:00+08:00
last_modified_at: 2026-04-19T21:05:00+08:00
created_by_event: manual-m6-evolution-align-260419
content_sha256: ""
depends_on:
  - urn: urn:piao:artifact:kernel:m6_evolution_draft_review@v1
    strength: strong
  - urn: urn:piao:spec:architecture:evolution_model@v1
    strength: strong
  - urn: urn:piao:spec:architecture:layered_architecture@v1
    strength: strong
  - urn: urn:piao:spec:architecture:artifact_model@v1.3
    strength: strong
  - urn: urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1
    strength: weak
  - urn: urn:piao:artifact:kernel:m5_drift_draft_review@v1
    strength: weak
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:kernel:m6_evolution_kernel_alignment_planning
  event_id: manual-m6-evolution-align-260419
wordcheck_exempt: true
---

# Kernel Alignment Proposal · M6 Evolution 落地触发

> 本 proposal 是 **`m6-evolution-draft-review.md @v1 §3.2 路径 B`** 的执行文档，沿用 **`m5-drift-kernel-alignment-proposal.md @v1 published`** 的格式与动作表范式（range/节号/动作三列矩阵 + 执行顺序 + 风险表 + DoD + 下游触发 + scope-out）。
>
> **输入**：review §3.2 的 **2 条路径 B 修订**（B1 / B2）+ 已于 `06 @v1 draft · 路径 A 消化` commit `e6e18d5f` 就地消化的 4 条路径 A（A1–A4 · 见 `06 §8.1 rev_history` "v1（draft · 路径 A 消化）· 2026-04-19 19:54" 条目 · 四处字面约束补齐 +18 行）。
>
> **输出**：
> - 一份 `published` kernel 文档升小版：`02-artifact-model.md @v1.3 → @v1.4`（B2 · 派生类型注册表补登 `evolution.scan_result` 条目）
> - 一份 `draft` kernel 文档原地修订（不升 rev）：`03-layered-architecture.md`（B1 · §3.1 `evolution.scanned` 语义字段 refresh 为 06 @v1 draft §5.3 实锁 schema · 并将原"10 类"措辞补注"含 evolution.scanned · 经 06 @v1 draft §5.3 精化语义字段后闭环"）
> - 一份 `draft` kernel 文档跟随升小版：`06-evolution-model.md @v1 (draft) → @v1.1 (draft)`（反映 B1/B2 落地后的锚点注释从"待外篇对接"改为"已反向对接" · 对齐 M5 Step 5 范式）
>
> **完成后**：M6 evolution 层的 kernel 缺口全部闭环；`06-evolution-model.md` 即可从 `@v1.1 draft → @v1.1 published`（走 `06 §8.2` 门控 #4 · 依赖 `scripts/piao-evolution-scan.sh` MVP 产出真实 evolution.scan_result artifact 做反证 · 对标 M5 `piao-drift-compute.sh` 节奏）。

---

## 1. 为什么是小升（02 升版 · 03 原地 · 06 跟随升版）

按 `01-identity-model.md §4.2` rev 创建规则 + `01 §10.1` draft 契约综合判定，B1–B2 的处置分三类：

### 1.1 rev 升降矩阵

| 目标文档 | 当前 rev | 当前 status | 本次处置 | rev 升降 |
|---------|--------|-----------|---------|---------|
| `02-artifact-model.md` | **@v1.3** | **published** | B2（§2.2.4 派生类型注册表新增 `evolution.scan_result` 条目 · 七字段齐全 · `wordcheck_policy=machine_generated`） | **@v1.3 → @v1.4** |
| `03-layered-architecture.md` | **@v1** | **draft** | B1（§3.1 `evolution.scanned` 行 · 语义字段按 `06 @v1 draft §2.3 / §5.3` 精化 schema 补齐；§3.1 末段"上述 10 类"措辞补注 · §10 rev_history 追述"路径 B 消化"条目） | **不升 rev**（按 `01 §10.1` draft 可原地修订 · 沿用 M5 `m5_drift_kernel_alignment` 对 03 的处置先例） |
| `06-evolution-model.md` | **@v1** | **draft** | Step 4 跟随升版：反映 02/03 反向对接后的锚点注释状态（§2.4 B2/B3 从"依赖下次小升"改为"已对接" · §8.2 门控 #4 `[ ]→[x]` · §9 前置契约表 03/02 版本号 refresh · §11 下游锚点刷新） | **@v1 → @v1.1**（draft 内小升 · 非 published 升版 · 与 M5 `05 @v1 → @v1.1 draft` 范式同构） |

### 1.2 为什么不算大升

按 `01 §4.2`：

| 建议 | 变更类型 | 为什么不算大升 |
|-----|---------|-------------|
| B1（03 §3.1 `evolution.scanned` 行语义字段 refresh） | **字段列表精化** | 03 §3.1 `evolution.scanned` 行自 M4 时期前瞻性草拟以来 · 其"语义字段"列列出的 `target_task_urn, extracted_memory_ids[]` 为**占位性**草拟（当时 M6 evolution 模型未起稿）· 本次按 `06 @v1 draft §2.3 / §5.3` 实际锁定的 schema refresh（`drift_event_urn` / `scope_urn` / `decision_log[]` / `orphan_check?`）· `evolution.scanned` 类型名不变 · subject 指向不变（task URN → 在 06 @v1 draft 范式下改为 scope URN · 本次对齐）· 属"占位字段精确化"· 03 整体 10 类枚举不变。调用方**尚无**生产者（06 draft 未 published · `piao-evolution-scan.sh` 未实施）· 向后兼容无负担 |
| B2（02 §2.2.4 派生注册表新增 `evolution.scan_result` 条目） | **新增注册条目** | 02 §2.2.4 派生类型注册 schema（M5 @v1.3 R25 首设 · 七字段）**字面不动**；注册表追加第 N+1 条 `evolution.scan_result` 条目。`kernel-wordcheck.sh` 的 `machine_generated` 分支已在 M5 期间实施完毕 · 本次仅**复用既有分支**识别新派生类型 · 零工具链改动 · 零 adapter 改动 |

**零 schema 删减、零字段类型变更、零语义反转** → 小升（02）+ draft 原地修订（03）+ draft 内小升（06）足矣。

### 1.3 对下游的影响

- **现有 adapter**（目前仅 `frontend-migration`）：**不需要任何改动**。B1 仅精化 03 内一行占位字段 · 尚无 adapter 或工具链生产 `evolution.scanned` 事件（`scripts/piao-evolution-scan.sh` 待实施）· 无兼容性冲突；B2 仅追加注册条目 · adapter 不直接生成 `evolution.scan_result`（由 `scripts/piao-evolution-scan.sh` 内部产出）。
- **03/02 已 published 的历史 artifact**：02 @v1.3 之前 published 的所有 artifact **不需要迁移**。B2 新增的 `evolution.scan_result` 注册条目仅对未来新产出的 evolution artifact 生效 · 历史 `drift.propagation_record` / `snapshot.diff` 等派生实体零冲击。
- **`06-evolution-model.md`（draft @v1 · 路径 A 消化后）**：本 proposal 完成后，06 **跟随升版**到 `@v1.1 (draft)` 以反映锚点注释更新（§2.4 B2/B3 从"外篇小升依赖"改为"已对接" · §8.2 门控 #4 勾选 · §9 前置契约表 03/02 版本号 refresh · §11 下游锚点表刷新）。详见 §7 下游触发。
- **`01/04/05` 四篇**：**零影响**。B1/B2 均不触及 01（身份模型）/ 04（版本快照）/ 05（drift 传播）· M5 路径 B 已完成的 04/05 反向对接不需要任何再加工。

---

## 2. 两文档动作矩阵（B → 文档 → 节号 → 动作）

| # | 来源 | 建议 | 目标文档 | 目标节 | 动作 |
|---|------|-----|---------|-------|------|
| 1 | Q21 / B1 | `03 §3.1` `evolution.scanned` 语义字段 refresh | `03-layered-architecture.md`（draft · 原地） | §3.1 L1 事件类型枚举表 `evolution.scanned` 行 | 将该行 subject / 语义字段列按 `06 @v1 draft §2.3 / §5.3` 实锁 schema 精化：<br/>- **subject 指向**：从 "task URN（被扫描的 task）" 改为 "scope URN（被扫描的 scope 上下文）"（对齐 06 §2.3 身份范式）<br/>- **语义字段**：从 `target_task_urn, extracted_memory_ids[]（可空）` 改为 `drift_event_urn, scope_urn, scanned_drifts[], decision_log[]`（对齐 06 §2.3 schema · `drift_event_urn` 强制 · `scope_urn` 强制 · `scanned_drifts[]` 可空但字段必填性见 06 §2.3 注释 · `decision_log[]` 可空）<br/>- §3.1 末段"上述 10 类覆盖..."措辞补注："其中 `evolution.scanned` 的语义字段列自 `06 @v1 draft §5.3 / §2.3` 起已精化为 evolution 子系统的实锁 schema（M6 路径 B 落地 · 2026-04-19）" |
| 2 | Q22 / B2 | `02 §2.2.4` 派生注册表新增 `evolution.scan_result` 条目 | `02-artifact-model.md`（@v1.3 → @v1.4） | §2.2.4 派生类型注册 schema 示例表下追加新条目 | 在 §2.2.4 既有 `drift.propagation_record` 示例后追加一段 `evolution.scan_result` 注册示例（七字段齐全）：<br/>```yaml<br/>artifact_type: evolution.scan_result<br/>parent_type: evolution<br/>description: "evolution 扫描器产出的观测基础层 artifact · 由 scripts/piao-evolution-scan.sh 产出 · body schema 由 06 §2.3 定义"<br/>schema_version: 1.0<br/>owner: kernel:m6<br/>stability: beta<br/>wordcheck_policy: machine_generated<br/>```<br/>表格下方补注："`wordcheck_policy=machine_generated` 的依据：06 §5.2 orphan_check schema + §2.3 身份 schema 均为确定性算法产出的 YAML 字段 · 无自然语言 · 自动继承 `wordcheck_exempt: true`（复用 M5 `drift.propagation_record` 同模式）" |

**两文档升版总体积**：~35–45 行新增（纯补充 + 少量字段字面精化 · 不删不改现有契约语义）。远小于 M5 的 90–110 行 · 符合"M6 缺口密度 43% · 路径 B 密度 40%"的 review §3.4 对标预期。

---

## 3. 执行顺序与依赖

**关键观察**：两条修订中 B1 改 03（draft 原地）· B2 改 02（published 小升）· 两文档无相互依赖（B1 改 03 §3.1 L1 事件 schema / B2 改 02 §2.2.4 派生注册 · 两节独立）。四文档间的依赖：

- **B1（03 §3.1 evolution.scanned 行 refresh）← 06 §2.3 / §5.3**：06 @v1 draft 已锁定 evolution.scan_result 身份 + 事件 schema · 本次在 03 侧把占位字段精确化 · 消除"03 表内语义字段列与 06 实锁字段不一致"的跨篇偏差
- **B2（02 §2.2.4 evolution.scan_result 注册）← 06 §2.4 B3 + §5.3**：06 已声明"B3 要求 02 @v1.4 补登" · 本次在 02 侧正式注册

推荐执行顺序（基于依赖最小化 + 先 draft 原地后 published 小升 + 最后 06 跟随）：

```
(S0) 预检 · `evolution.scan_result` 与现有派生注册表无冲突校验（S1 前置 · 护栏）
       │   执行：grep -n "evolution.scan_result" docs/piao-pipeline/kernel/02-artifact-model.md
       │   验收：当前 02 @v1.3 不含本条目（零冲突 · 可追加）
       │   失败处置：若已存在 · 暂停 S2 · 调查是否被其他 proposal 先占用
       │   预期：零命中 · 预检通过
       │
       ▼
(S1) 03-layered-architecture.md（draft 原地修订，不升 rev）
       │   动作 1（§3.1 `evolution.scanned` 行 subject + 语义字段精化 · §3.1 末段措辞补注）
       │   §10 rev_history 追述一行 · 参考 05 §8.1 或 M5 对 03 的原地修订先例
       │
       ▼
(S2) 02-artifact-model.md @v1.3 → @v1.4
       │   动作 2（§2.2.4 新增 `evolution.scan_result` 七字段注册示例 + 表下补注）
       │   §9 rev_history 追加 v1.4 一行（触发源 · 本 proposal）
       │
       ▼
(S3) 本 proposal 自身：从 draft → published · 签收触发四篇下游协同
       │
       ▼
(S4) 06-evolution-model.md @v1 (draft) → @v1.1 (draft) 跟随升版
       │   §2.4 B2/B3 标签从"依赖 03/02 下次小升"改为"已对接 03 @v1.1 draft / 02 @v1.4 published · 2026-04-19"
       │   §8.2 门控 #4 勾选 `[ ] → [x]`（evolution.scanned L1 事件 · 已在 03 §3.1 精化 schema 闭环）
       │   §9 前置契约表 `03 §3.1` / `02 §2.2.4` 版本号与对接状态 refresh
       │   §11 本篇状态行从"@v1 draft · 路径 A 消化完成 · 等待路径 B"改为"@v1.1 draft · 路径 A/B 全消化 · 等待 §8.2 门控 #4 工具链反证（scripts/piao-evolution-scan.sh MVP）"
       │   §11 下游锚点：本 proposal URN 标记 `published`（已消费） + `m6_evolution_kernel_alignment@v1 published` 事实补注
       │   §8.1 rev_history 追加 v1.1 一行（triggered_by = 本 proposal）
       │
       ▼
(S5) review 文档追加 §5 路径 B 完成记录（与 §3.2 B1/B2 表对齐 · 两条 consumed 表 · 对标 `m5-drift-kernel-alignment-proposal.md @v1` S6 范式）
       │
       ▼
(S6) 全量 wordcheck + IDE lint + commit
```

**回滚点**：S1 / S2 / S4 每一步都是**独立可 commit 的 git 节点**；若发现 S2 某处补充不够可直接打补丁（仍在 `@v1.4` 同一 rev 内 · 因 02 在小升窗口内允许微调 · 参考 `m5_drift_kernel_alignment` 的同模式回滚逻辑）。**S0 预检失败不构成本 proposal 失败**——预检是护栏 · 失败时仅暂停执行并调查冲突来源，proposal 正文保持不变。

---

## 4. 文档级精确修订锚点

### 4.1 B1 · 03 §3.1 `evolution.scanned` 语义字段 refresh（draft 原地）

**落点**：`03 §3.1 L1 事件类型枚举` 表（line 122-133）中 `evolution.scanned` 行（line 132）。

**现状**（line 132）：
```
| `evolution.scanned` | evolution 子系统完成对某 task 的经验萃取扫描 | task URN（被扫描的 task） | `target_task_urn`, `extracted_memory_ids[]`（可空） |
```

**修订后**（本 proposal S1 · B1）：
```
| `evolution.scanned` | evolution 扫描器完成一次 scope 范围扫描（产出 evolution.scan_result artifact 的配套 L1 事件） | scope URN（被扫描的 scope 上下文）| `drift_event_urn`, `scope_urn`, `scanned_drifts[]`, `decision_log[]`（配套 L1 读 3 字段上限：scope_urn / decision / driver_event_id · 见 06 §6.2） |
```

**§3.1 末段措辞补注**（line 139 "禁止扩展"段起始处）：

- **现状**：`**禁止扩展**：上述 10 类覆盖 piao-pipeline 所有 L1 语义。...`
- **修订后**：`**禁止扩展**：上述 10 类覆盖 piao-pipeline 所有 L1 语义。**其中 `evolution.scanned` 的 subject 指向与语义字段列自 `m6_evolution_kernel_alignment@v1` 起已按 `06 @v1 draft §2.3 / §5.3` 实锁 schema 精化（M6 路径 B 落地 · 2026-04-19 · 03 draft 原地修订 · 不升 rev）**。...`

**§10 rev_history 追述一行**（参考 05 §8.1 / M5 对 03 的原地修订先例）：

```
| v1（原地追述 · 路径 B 消化） | 2026-04-19 <S1 时刻> | `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1` | §3.1 `evolution.scanned` 行 subject 从"task URN"精化为"scope URN" + 语义字段从 `target_task_urn, extracted_memory_ids[]`（M4 时期占位）精化为 `drift_event_urn, scope_urn, scanned_drifts[], decision_log[]`（对齐 06 @v1 draft §2.3 / §5.3 实锁 schema）· §3.1 末段"禁止扩展"处补注措辞 · draft 原地修订 · 不升 rev（按 01 §10.1 draft 契约 · 沿用 M5 路径 B R22 同模式） |
```

**副作用**：06 @v1 draft §2.4 B2 "依赖 03 下次小升" 从未兑现的待办变为已兑现 · 跨篇契约闭环。由于 03 尚未 published · `piao-evolution-scan.sh` 未实施 · 无生产者需按旧占位字段调整。

### 4.2 B2 · 02 §2.2.4 派生注册表新增 `evolution.scan_result` 条目（@v1.3 → @v1.4）

**落点**：`02 §2.2.4 派生类型注册 schema` 示例区（line 220-235 附近 · 紧跟 `drift.propagation_record` 示例之后）。

**现状**（line 220-230 附近）：
```yaml
artifact_type: drift.propagation_record
parent_type: ...
...
wordcheck_policy: machine_generated            # v1.3 新增 · 机器产物自动 exempt
```

**修订动作**：在既有 `drift.propagation_record` 示例后追加一个新的注册示例块：

```yaml
artifact_type: evolution.scan_result
parent_type: evolution
description: "evolution 扫描器产出的观测基础层 artifact · 由 scripts/piao-evolution-scan.sh 产出 · body schema 由 06 §2.3 定义"
schema_version: 1.0
owner: kernel:m6
stability: beta
wordcheck_policy: machine_generated            # v1.4 新增 · 对齐 drift.propagation_record 模式
```

**表格下方补注**（紧跟注册示例）：

```
注释 3（v1.4 · 本 proposal S2 B2）：
- `evolution.scan_result` 的 `wordcheck_policy=machine_generated` 依据：
  - body schema（见 06 §2.3）由 `piao-evolution-scan.sh` 按确定性算法产出 · 无自然语言 / 无人工撰写
  - `scanned_drifts[]` / `decision_log[]` / `orphan_check?` 均为 YAML 结构化字段 · 与 drift.propagation_record 同模式
  - kernel-wordcheck.sh 的 `machine_generated` 分支已在 M5 期间实施 · 本条目仅复用既有分支识别新派生类型 · 零工具链改动
- 与 `drift.propagation_record` 的共性：两者都是 kernel 观测基础层的确定性产物 · 共同构成 piao-pipeline 的"L2 之外 + L1 之上"机器产物层
```

### 4.3 Step 4 · 06 跟随升版 @v1 → @v1.1（draft 内小升）

**落点**：`06-evolution-model.md` 多处锚点注释更新。

**修订动作**：

- **front-matter**：`rev: v1 → rev: v1.1` · `last_modified_at` 刷新为 S4 执行时刻
- **§2.4 B2 标签**：
  - 从 "**B2 · 03 @v1 draft L1 事件枚举扩至十一类 · 新增 `evolution.scanned`**（依赖 03 下次小升 · 详见 §8.2 门控 #4）"
  - 改为 "**B2 · 03 @v1 draft §3.1 `evolution.scanned` 语义字段精化**（已于 `m6_evolution_kernel_alignment@v1` S1 落地 · 2026-04-19 · 03 draft 原地修订）"
- **§2.4 B3 标签**：
  - 从 "**B3 · 02 派生类型注册表补登 `evolution.scan_result`**（依赖 02 @v1.3 → @v1.4 · 详见 §8.2 门控 #4）"
  - 改为 "**B3 · 02 派生类型注册表已补登 `evolution.scan_result`**（已于 `m6_evolution_kernel_alignment@v1` S2 落地 · 2026-04-19 · 02 @v1.4 published）"
- **§8.2 门控 #4 勾选**：
  - 从 `[ ] evolution.scanned L1 事件 · 依赖 03 下次小升`
  - 改为 `[x] evolution.scanned L1 事件 · 已由 m6_evolution_kernel_alignment@v1 S1 于 03 §3.1 精化 schema 完成（2026-04-19）`
- **§9 前置契约表**：
  - `03 §3.1` 引用：从 "L1 事件十类 · `evolution.scanned` 语义字段占位待精化" 改为 "L1 事件十类 · `evolution.scanned` schema 已对齐 06 §2.3（03 draft 原地修订 · 2026-04-19）"
  - `02 §2.2.4` 引用：从 "`02 @v1.3 · 派生注册 schema 首设 · 需补登 evolution.scan_result`" 改为 "`02 @v1.4 · 已注册 evolution.scan_result · wordcheck_policy=machine_generated`"
- **§11 本篇状态行**：
  - 从 "@v1 draft · 路径 A 四条字面约束补齐已刷进 · 等待路径 B 落地后升 @v1 published"
  - 改为 "@v1.1 draft · 路径 A 四条（A1-A4）+ 路径 B 两条（B1/B2）全消化 · §8.2 四条门控全 `[x]` · 等待 `scripts/piao-evolution-scan.sh` MVP 产出真实 `evolution.scan_result` artifact 做反证后升 @v1.1 published"
- **§11 下游锚点表**：
  - review 条目追加 "路径 B 两条已由 m6_evolution_kernel_alignment@v1 published 消费 · review §5 待追加路径 B 完成记录"
  - 新增 `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 published` 条目（从"待开"改为"已 published"）
- **§8.1 rev_history** 追加一行：

  ```
  | v1.1 (draft) | 2026-04-19 <S4 时刻> | `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1` | 跟随 03/02 反向对接的锚点注释更新：§2.4 B2/B3 标签从"依赖下次小升"改为"已对接" · §8.2 门控 #4 `[ ]→[x]` · §9 前置契约表 03 §3.1 / 02 §2.2.4 版本号刷新 · §11 本篇状态行从"等待路径 B"改为"路径 A/B 全消化 · 等待工具链反证" · §11 下游锚点 review 条目 + 本 proposal 条目 refresh · draft 内小升（status 保持 draft）· 为 §8.2 门控 #2/#3/#4 工具链 MVP（piao-evolution-scan.sh）反证留出窗口期 · 对标 M5 `05 @v1 → @v1.1 draft` 跟随升版范式 |
  ```

---

## 5. 风险与不确定性

| 风险 | 可能性 | 影响 | 缓解 |
|------|-------|-----|------|
| **B1 在 03 §3.1 evolution.scanned 行 schema 精化后 · 未来 M7+ 出现新的 evolution L1 事件类型需再次扩** | 低 | 低 | 06 §6.7 A1 · Q23 回应已声明"L1 事件 3 字段上限契约为 06 M6 单边约束 · 不对外推广" · 未来 M7+ 新 evolution L1 事件需独立走 kernel rev 升降（按 03 §3.1 "禁止扩展 · 实在不够用 → 提 kernel rev 升降"硬约束）· 本次 B1 不假设自动推广 |
| **B2 新增的 `evolution.scan_result` 注册条目与 kernel-wordcheck.sh 的 `machine_generated` 分支行为预期不符** | 低 | 低 | `machine_generated` 分支已在 M5 期间（02 @v1.3 R25）实施完毕 · 本次仅复用既有分支 · 零代码改动 · 风险与 M5 `drift.propagation_record` 同模式；若出现异常可回退到 `content_safe_default` 默认（兜底安全）· 不阻塞 S2 落地 |
| **B1 修订后 03 原本"上述 10 类覆盖..."的措辞数量不变（仍为 10 类）· 但措辞语气暗示"evolution.scanned 字段已重定义" · 可能引发 03 读者误解"10 类变更"** | 低 | 低 | S1 动作 1 已在 §3.1 末段"禁止扩展"处补注一段明确澄清"类型数量不变 · 仅 evolution.scanned 语义字段按 06 实锁 schema 精化"· 措辞显式化消除误解 |
| **S4 跟随升版后 06 从 @v1 → @v1.1 仍保持 draft · 与 `01 §4.2` "升版需从 published 基线"有看似张力** | 低 | 低 | 按 `01 §10.1` draft 允许内部小升（M5 `05 @v1 draft → @v1.1 draft` 先例 · 已接受范式 · M6 沿用）· draft 状态下的 rev 小升**不**触发 `supersedes` · 仅用于锚点校验期的版本标识 |
| **升版后三文档互相引用的锚点失效** | 低 | 低 | 引用均为节号（如 `§3.1` / `§2.2.4`）· 小升仅新增不删旧 · 锚点稳定（与 `m5_drift_kernel_alignment` 同风险模式） |
| **B1 在 03 draft 状态下原地修订 · 未来 03 升 published 时需带本次修订入基线 · 存在遗漏风险** | 中 | 中 | §10 rev_history 追述一行明示 · 提示 03 升 published 时必须保留本修订 · 同时 S5 在 review §5 路径 B 完成记录中归档索引 · 双保险 |

---

## 6. 完成条件（Definition of Done）

本 proposal 在以下所有条件全部满足后发 `proposal.implemented` 事件并归档：

- [x] **S0 预检通过**：02 @v1.3 当前不含 `evolution.scan_result` 注册条目（零冲突 · 可追加）· `grep -n "evolution.scan_result" docs/piao-pipeline/kernel/02-artifact-model.md` 零命中（2026-04-19 20:10 执行 · 仅在 §5.3.1 注释中出现作为"未来 evolution 可能引入的示例"· 非注册条目 · 实际注册区零占位 ✅）
- [x] **S1 落地**：`03-layered-architecture.md` draft 原地修订（§3.1 `evolution.scanned` 行 subject + 语义字段精化 + §3.1 末段措辞补注 + §10 rev_history 追述），不升 rev（按 `01 §10.1` draft 契约）· ✅ 2026-04-19 20:30 完成（四处主修订 + 一处 §6.3 连带精化）
- [x] **S2 落地**：`02-artifact-model.md @v1.3 → @v1.4` published（§2.2.4 新增 `evolution.scan_result` 七字段注册示例 + 表下补注），§9 rev_history 追加 v1.4 一行 · ✅ 2026-04-19 20:45 完成（§2.2.4 YAML 登记示例 2 + "注释 3" 补注 + 承诺段补加 v1.4 专项条目 + §11 rev_history v1.4 行 · IDE lint × 0 错误 · 行数 570 → 593）
- [x] **S3 落地**：本 proposal 自身 front-matter `status: draft → published` · `last_modified_at` 刷新 · Self-review 签收段追加（对标 M5 §8 Self-review 签收范式）· ✅ 2026-04-19 20:15 完成
- [x] **S4 落地**：`06-evolution-model.md @v1 (draft) → @v1.1 (draft)` 跟随升版 · ✅ 2026-04-19 20:50 完成（front-matter urn/rev/last_modified_at 三字段同步升 · §2.4 B2/B3 "已对接"改写 · §2.5 锚点闭环声明两条 refresh · §8.2 门控 #4 达成段正文 refresh · §8.2 "路径 A 消化评估"后追加 "v1.1 draft 升版后事实补注"段 · §8.1 rev_history 追加 v1.1 行 · §9 前置契约表 02/03 六行状态 refresh · §11 章节标题 + 状态行 + 上下游锚点全部 refresh · 行数 837 → 858 · IDE lint × 0 错误 · status 保持 draft 不变）
- [x] **S5 落地**：`m6-evolution-draft-review.md` 追加 §5 路径 A/B 消化记录（§5.1 路径 A 追述 + §5.2 路径 B 四步执行表 + §5.3 consumed 矩阵 + §5.4 06 跟随升版 S4 专段 + §5.5 与 proposal §1.1 rev 升降矩阵一致性验证 + §5.6 路径 A/B 全消化闭环对接 + §5.7 下一动作 · 原 §5 状态段下移为 §6 并 refresh）· ✅ 2026-04-19 20:55 完成（front-matter `last_modified_at` refresh + upstream 增加 06 @v1.1 & proposal URN + §5 七节追加 + §6 状态段全 refresh · 行数 517 → 626 · IDE lint × 0 错误 · 对标 M5 `m5-drift-draft-review @v1 §5` 四段式范式同构）
- [x] `./scripts/kernel-wordcheck.sh --ci` 在 `docs/piao-pipeline/kernel/` 下 BAN/WARN 数不增加 · ✅ 2026-04-19 21:00 实跑确认（BAN=6 / WARN=5 全部 pre-existing · 落点 `02-artifact-model.md` line 55/88/485/554/555/564/565 均在 §1 举例段 / §7 业务场景锚点章节标题 / §8 路径问题讨论段 · 非本 proposal S2 B2 修订落点（§2.2.4 登记区 line 237+ / §11 rev_history line 594）· 基线对照 HEAD~4 proposal 起稿前 02 `kuikly|kotlin|migration` 计 18 命中 · S2 commit `7a7bce04` 零引入新违规 · 脚本本体 exit 1 属报告信号 · BAN/WARN 增量 = 0 满足本 DoD 条款）
- [x] IDE lint 对三份修订后文档（03 / 02 / 06）各自 0 错误 · ✅ 2026-04-19 21:00 `read_lints docs/piao-pipeline/kernel` 返回 diagnostics 空数组（含 03 / 02 @v1.4 / 06 @v1.1）
- [x] `06 §9` 前置契约表中声明的 `03 §3.1 · evolution.scanned schema 已对齐` + `02 §2.2.4 · evolution.scan_result 已注册` 在源文档内可找到 · ✅ 2026-04-19 21:00 grep 验证（`03-layered-architecture.md` line 132 `evolution.scanned` 行字面含 `drift_event_urn, scope_urn, scanned_drifts[], decision_log[]` + `02-artifact-model.md` line 237 `**登记示例 2 · evolution.scan_result**` 段 YAML 块字面七字段齐全 · 对齐 06 §9 表体 line 5 + line 8 的"已反向对接 · commit hash"状态）
- [x] Step 5 准备就绪（工具链后续）：`scripts/piao-evolution-scan.sh` MVP 的接口契约已由 06 @v1.1 + 03（draft · B1 后）+ 02 @v1.4 共同锚定 · ✅ 2026-04-19 21:05 声明（1）事件形态锚定 = `03 §3.1 evolution.scanned` 行 subject=scope URN + 四字段语义（`drift_event_urn, scope_urn, scanned_drifts[], decision_log[]`）· commit `76bbfff5`（2）artifact 形态锚定 = `02 §2.2.4 evolution.scan_result` 七字段注册（`artifact_type / parent_type / description / schema_version / owner / stability / wordcheck_policy=machine_generated`）· commit `7a7bce04`（3）消费契约锚定 = `06 @v1.1 §2.3 / §5.3` 身份 schema + `§6` 双通道 + `§6.7` L1 事件 3 字段上限 + `§7.3` retracted 分支 · commit `44bf034b`（4）MVP 产出契约 = 输入 `drift.detected` 事件 URN → 输出 `evolution.scan_result` artifact URN + 发 `evolution.scanned` L1 事件（N=2 原子 txn 按 03 §3.3.1 M5 泛化）· 本 proposal 范围内**仅承诺契约 · 不承诺工具实施**（见 §8 不做的事）· MVP 实施节奏对标 M5 `piao-drift-compute.sh`（M5 @v1.1 draft → @v1.1 published 周期 2-3 工作日）

---

## 7. 完成后的下游触发

- **`06-evolution-model.md @v1.1 (draft) → @v1.1 (published)`**（**路径 B 后的下一步**）：
  - 走 `06 §8.2` 门控 #2/#3/#4：`scripts/piao-evolution-scan.sh` MVP 产出至少一条真实 `evolution.scan_result` artifact · R1–R5 五条硬约束未被反例证伪 · `m6-final-decisions.md` 产出
  - 预计路径：`piao-evolution-scan.sh` MVP 实施（对标 M5 `piao-drift-compute.sh` + M4 `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh`） + 产出端到端 evolution.scan_result artifact + final-decisions 快照封冻
  - 06 published 后 `m6_evolution_kickoff@v1` 工作流 E 完结 · `m6_evolution_kickoff@v1` 可标 `superseded`（与 `m5_drift_kickoff@v1` 当前状态对称）
- **`M1-debt-ledger @v? → @v?+1`**（如适用）：review §3.2 的 B1–B2 两条 consumed 登记
- **`m6-evolution-draft-review.md` 状态更新**：§4.3 Step 2/3/4 推进 · §5 路径 B 消化记录追加（对标 M5 review §5 范式）
- **下一 milestone**：M7 Drift/Evolution 工具链深化 或 adapter 层第二轮对接（06 published + `m6-final-decisions` 封冻后 · 由下一个 kickoff proposal 启动）

---

## 8. 不做的事（scope out）

本 proposal **明确不包含**以下内容，避免范围蔓延（严格对齐 `m5_drift_kernel_alignment @v1 §8` 的 scope out 范式）：

| 不做的事 | 理由 |
|---------|-----|
| 新增任何 L1 事件类型 | 违反 `03 §3.1` 封板；B1 仅精化现有 `evolution.scanned` 行语义字段，不新增枚举项 · 03 表内类型数量仍为 10 类 |
| 新增任何 kind | 违反 `01 §2.1` 封板；B2 注册的 `evolution.scan_result` 其 kind 为 `evolution`（01 封板已含）· 本 proposal 仅在 02 派生注册层追加条目，不触达 01 kind 枚举 |
| 重构 `02 §2.2.4` 派生注册 schema | B2 仅追加一条注册示例，schema 七字段（M5 @v1.3 R25 首设）字面不动 |
| 修改 `02 §2.2.4` `wordcheck_policy` 枚举取值 | B2 沿用 M5 已实施的 `machine_generated` 取值，不新增枚举值 |
| 修改 `03 §3.1` 其它 L1 事件行 | B1 仅改 `evolution.scanned` 行，其它 9 行（含 drift.detected / artifact.published 等）字面不动 |
| 修改 `03 §3.3.1` N 条同 txn 契约 | M5 路径 B R22 已泛化为 "N ≥ 1 · 无固定 type 约束"，本次 evolution.scanned 产出为 N=2+k（`evolution.scan_result` artifact + `evolution.scanned` 事件 + 可选副作用事件）· 是既有契约的合法子集 · 无需再改 03 §3.3.1 |
| 修改 `04 §5.1` snapshot_diff 字段 | M5 路径 B R24 已落地 `modified` / `sha_changed` 双名 · 本 proposal 零触达 04 |
| 修改 `05 §2.5` drift schema | M6 evolution 产物不改变 drift 传播契约 · 本 proposal 零触达 05 |
| 修改 `01` 身份模型 | B1/B2 均在 02/03 层内 · 不触达 01 §1/§2/§4/§5/§10 任何硬约束 |
| `scripts/` 下的工具实现（含 `piao-evolution-scan.sh` MVP / `kernel-wordcheck.sh` 的 `evolution.scan_result` 分支） | 本 proposal 只承诺契约；工具实施留 M6 Step 5（本 proposal §7 下游触发）或 M7 kickoff |
| 06 draft → published 门控 #2/#3/#4 | Step 5 的工具链实施 + m6-final-decisions 产出负责 · 本 proposal 仅完成门控 #4 的"契约侧路径 B 闭环" |
| M7 milestone 起稿 | 下一 milestone 职责 · 由 `m7_*_kickoff@v1` proposal 启动（06 published 后择期启动） |
| 历史 evolution artifact 迁移 | 当前尚无 published evolution.scan_result artifact（06 仍 draft · `piao-evolution-scan.sh` 未实施） · 无迁移问题 |

---

## 9. Self-review 签收（升 published 前自检 · 对标 M5 §8 六项范式）

本 proposal 升 `status: draft → published` 前完成以下六项 self-review · 逐项签收结论如下：

### 9.1 结构完备性

| 章节 | 对标 M5 proposal | 本 proposal 状态 |
|-----|----------------|----------------|
| §1 为什么是小升（rev 升降矩阵 + 为什么不算大升 + 对下游影响） | ✅ 有（§1.1 / §1.2 / §1.3 三子节） | ✅ 齐备 · 三子节同构 |
| §2 文档动作矩阵（B → 文档 → 节号 → 动作） | ✅ 有 | ✅ 齐备 · 两条修订 B1/B2 各一行 · 体积评估 35–45 行 |
| §3 执行顺序与依赖（顺序图 + 回滚点） | ✅ 有 | ✅ 齐备 · 7 步（S0–S6）· 回滚点明示 |
| §4 文档级精确修订锚点（每条修订的行号 / 现状 / 修订后） | ✅ 有（三子节）| ✅ 齐备 · 三子节 §4.1 / §4.2 / §4.3 各司其职 |
| §5 风险与不确定性表 | ✅ 有（六行） | ✅ 齐备 · 六行（含 B1 schema 精化 / B2 wordcheck 分支 / 措辞误解 / draft 升版张力 / 锚点失效 / 遗漏风险） |
| §6 Definition of Done（勾选列表） | ✅ 有 | ✅ 齐备 · 9 项（S0 预检 + S1–S5 落地 + wordcheck + lint + 前置契约可查 + Step 5 就绪） |
| §7 完成后的下游触发 | ✅ 有 | ✅ 齐备 · 四条（06 升 @v1.1 published / M1 debt ledger / review §5 / M7 milestone） |
| §8 scope out（不做的事） | ✅ 有（九条） | ✅ 齐备 · 十二条（比 M5 多三条 · 对标 M6 evolution 上下文增补） |
| §9 Self-review 签收（本节）| ✅ 有（M5 §8） | ✅ 本段 |

**结论**：结构 8 章主节 + 7 子节 · 总 321 行 · 严格对齐 M5 proposal 格式。

### 9.2 锚点准确性

| 锚点类别 | 验证方式 | 签收结论 |
|---------|---------|---------|
| 03 §3.1 `evolution.scanned` 行现状（line 132）| 实读校验：预检发现 03 §3.1 当前**已有 10 类**（含 `evolution.scanned`），语义字段为 `target_task_urn, extracted_memory_ids[]`（M4 时期占位）| ✅ §4.1 已按"占位字段精化"而非"枚举扩至十一类"起稿 · **修正 review §3.2 原文对 B1 的错误描述** |
| 06 §2.3 / §5.3 实锁 schema 字段 | 实读校验：`drift_event_urn` / `scope_urn` / `scanned_drifts[]` / `decision_log[]` 均在 06 draft §2.3 中锁定（line 120+） | ✅ §4.1 修订后的语义字段列与 06 实锁 schema 一一对齐 |
| 02 §2.2.4 派生注册 schema 七字段 | 实读校验：line 198-208 七字段齐全 · `wordcheck_policy` 枚举 `machine_generated / content_safe_default` | ✅ §4.2 注册示例七字段齐全 · 对齐 schema |
| 02 @v1.3 `evolution.scan_result` 零占位 | 实读校验：`grep -n "evolution.scan_result" 02-artifact-model.md` → 零命中 | ✅ S0 预检零冲突 · 可追加 |
| 06 §2.4 B2 / B3 待办标签（line 177/178） | 实读校验：06 当前标签为"依赖 03/02 下次小升" | ✅ §4.3 已锚定"依赖下次小升 → 已对接"的精确改写 |
| 06 §8.2 门控 #4 | 实读校验：06 当前为 `[ ] evolution.scanned L1 事件 · 依赖 03 下次小升` | ✅ §4.3 已锚定勾选改写 |

**结论**：所有锚点经实读校验 · 无偏差。**关键修正**：review §3.2 原文对 B1 描述为"L1 事件十→十一类扩展" · 实读发现 03 @v1 draft 当前已含 `evolution.scanned`（M4 起稿时前瞻性草拟）· 真实缺口是语义字段精化。本 proposal §1.1 / §2 / §4.1 均按"占位字段精确化"起稿 · 避免基于 review 文字做过度动作。

### 9.3 体量合理性

| 维度 | M5 proposal | M6 proposal（本次） | 评估 |
|-----|-----------|------------------|-----|
| 总行数 | 379 | 321 | 85% · 对标 M6 路径 B 2 条 vs M5 5 条 · 40% 密度合理缩减 |
| 路径 B 条数 | 5（R21–R25） | 2（B1–B2） | 合理 |
| 触及文档数 | 4（04/02/03/05 跟随） | 3（02/03/06 跟随） | 合理 |
| 升版文档数 | 3（03 原地 / 02 小升 / 05 跟随）| 3（03 原地 / 02 小升 / 06 跟随）| 同构 |
| scope-out 条数 | 9 | 12 | M6 上下文更新 · 多出三条（L1 事件硬约束 / kind 枚举 / draft 升版张力）合理 |
| 风险表行数 | 6 | 6 | 对齐 |

**结论**：体量对标 M5 · 密度缩减与 path B 缺口数成正比。

### 9.4 风险闭环

§5 风险表六行逐条缓解措施 · 签收如下：

- **风险 1（未来新 evolution L1 事件）**：缓解明示 06 §6.7 A1 · Q23 回应已声明"L1 3 字段上限为 M6 单边约束 · 不推广" · ✅ 闭环
- **风险 2（wordcheck 分支不符）**：缓解明示复用 M5 同模式 + 回退到 `content_safe_default` 兜底 · ✅ 闭环
- **风险 3（10 类措辞暗示语义变更）**：缓解明示 §3.1 末段"禁止扩展"处显式补注"类型数量不变 · 仅 evolution.scanned 字段精化" · ✅ 闭环
- **风险 4（draft 小升与 01 §4.2 张力）**：缓解明示 01 §10.1 允许 draft 内小升 · M5 `05 @v1 → @v1.1 draft` 已有先例 · ✅ 闭环
- **风险 5（锚点失效）**：缓解明示均为节号引用 · 小升新增不删旧 · ✅ 闭环
- **风险 6（03 draft 修订未来升 published 遗漏风险）**：缓解明示 §10 rev_history 追述一行 + review §5 归档索引 · 双保险 · ✅ 闭环

**结论**：六条风险全部缓解措施具体 · 可执行 · 对齐 M5 风险闭环密度。

### 9.5 证据层对接

| 证据类型 | 位置 | 状态 |
|---------|-----|-----|
| 上游锚点（6 条 depends_on） | front-matter | ✅ 6 条齐全（M5 proposal 8 条 · M6 少 2 条属 M6 上下文简化） |
| review 来源引用 | §2 矩阵 / §4 锚点 / §5 风险 / §6 DoD 多处 | ✅ 多处引用 `m6-evolution-draft-review.md @v1 §3.2 Q21 / Q22` |
| 06 draft 证据 | §4.1 / §4.3 引用 06 §2.3 / §5.3 / §2.4 / §8.2 / §9 / §11 / §8.1 | ✅ 充分 |
| M5 先例引用 | §1.2 / §3 / §5 / §7 / §8 多处 | ✅ 充分（M5 proposal published · M5 `05 @v1 → @v1.1 draft` 先例 · M5 `drift.propagation_record` 同模式） |
| wordcheck_exempt 声明 | front-matter line 29 | ✅ `true` · 对标 M5 proposal 同模式 |

**结论**：证据层对接完整 · 上下游锚点齐全 · 无断链。

### 9.6 签收结论

- **六项 self-review 结论**：结构完备性 ✅ · 锚点准确性 ✅（含 review §3.2 B1 原文误判修正）· 体量合理性 ✅ · 风险闭环 ✅ · 证据层对接 ✅ · 签收结论 ✅
- **升版决定**：`status: draft → published` · `last_modified_at: 2026-04-19T20:15:00+08:00`
- **升 published 后触发序列**：S0 预检已在本自检中执行完成（零冲突）· S1（03 draft 原地修订）可立即开启
- **签收人**：human:caleb · **签收时刻**：2026-04-19 20:15
- **签收依据**：对标 M5 `m5_drift_kernel_alignment@v1 §8 self-review` 六项范式 · 无偏差

---

**本 proposal 状态**：published · rev v1 · **implemented**（created 2026-04-19 20:05 · last_modified 2026-04-19 21:05 · self-review 签收完成 @ 20:15 · **S6 最终收官 @ 21:05**）

### S6 最终收官声明（2026-04-19 21:05 · `proposal.implemented` 事件发射）

**七步执行回顾**（S0 → S6 · 对应 `§3 执行顺序与依赖` + `§6 DoD`）：

| 步 | 动作 | commit | 时刻 |
|---|-----|--------|-----|
| S0 | 预检（`evolution.scan_result` 零冲突） | — | 2026-04-19 20:10 |
| S1 | `03 @v1 draft` 原地精化（B1） | `76bbfff5` | 2026-04-19 20:30 |
| S2 | `02 @v1.3 → @v1.4 published`（B2） | `7a7bce04` | 2026-04-19 20:45 |
| S3 | proposal `draft → published` · self-review 签收 | `1c106937` | 2026-04-19 20:15 |
| S4 | `06 @v1 draft → @v1.1 draft` 跟随升版 | `44bf034b` | 2026-04-19 20:50 |
| S5 | review §5 追加路径 A/B 消化记录 | `587e58d1` | 2026-04-19 20:55 |
| S6 | 全量 wordcheck + IDE lint + proposal.implemented + review 升 published | 本次 commit | 2026-04-19 21:05 |

**DoD 全量勾选**（`§6` 十项）：
- [x] S0 预检 · [x] S1–S5 五步 · [x] wordcheck · [x] IDE lint · [x] 06 §9 可查性 · [x] Step 5 就绪 · **10/10 全满足** ✅

**`proposal.implemented` L1 事件**（按 `03 §3.1` 事件枚举 + `03 §3.3.1` 原子写入契约 · N=1 同 txn）：
```yaml
event:
  event_id: evt.piao.proposal.implemented.m6-evolution-kernel-alignment-260419-2105
  event_type: proposal.implemented
  subject_urn: urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1
  actor: agent:openspec-workflow-pipeline
  scope_urn: urn:piao:spec:architecture:evolution_model@v1.1
  occurred_at: 2026-04-19T21:05:00+08:00
  payload:
    dod_completion: "10/10"
    consumed_upstream:
      - urn:piao:artifact:kernel:m6_evolution_draft_review@v1  # §3.2 B1-B2 来源
    produced_downstream:
      - urn:piao:spec:architecture:artifact_model@v1.4          # S2 B2 成果
      - urn:piao:spec:architecture:layered_architecture@v1      # S1 B1 draft 原地精化
      - urn:piao:spec:architecture:evolution_model@v1.1         # S4 跟随升版 · draft 内小升
      - urn:piao:artifact:kernel:m6_evolution_draft_review@v1   # S5 §5 追补 + S6 升 published
    commit_chain:
      - 76bbfff5  # S1
      - 7a7bce04  # S2
      - 1c106937  # S3
      - 44bf034b  # S4
      - 587e58d1  # S5
      - (本次 commit)  # S6
  meta:
    pattern_alignment: m5_drift_kernel_alignment@v1  # 同构范式（M5 6 步 S1-S6 / M6 7 步 S0-S6 · S0 为 M6 新增预检）
```

**M6 evolution 层 kernel 契约侧工作封闭状态**：
- ✅ 路径 A 四条（Q23–Q26）已 consumed（06 `§8.1 v1 路径 A 消化`行 + 06 `§2.3 / §5.2 / §6.7 / §7.3` 四处字面）
- ✅ 路径 B 两条（Q21–Q22）已 consumed（03 `§3.1` + 02 `§2.2.4` + 06 `@v1.1 draft` + review `§5`）
- ✅ 06 `§8.2` 门控 #1 / #4 已达成（#2 / #3 待工具链 MVP 反证）
- ⚠️ 06 `@v1.1 draft → @v1.1 published` 待后续阶段驱动（非本 proposal 范围）
- ⚠️ `m6-final-decisions@v1 published` 待产（M6 milestone 封板物）

**下一 milestone 触发候选**（按 `§7 下游触发` + M5→M6 过渡 commit `aa6c7489` 范式）：
- `scripts/piao-evolution-scan.sh` MVP 实施（对标 M5 `piao-drift-compute.sh` · 2-3 工作日）
- `m6-final-decisions.md @v1 draft → @v1 published`（06 @v1.1 published 后）
- `m6_evolution_kickoff@v1 status: published → superseded`（与 m6-final-decisions published 同步）
- `M7 kickoff proposal` 起稿（待 M6 封板）

**上游锚点**：
- `urn:piao:artifact:kernel:m6_evolution_draft_review@v1 §3.2`（B1–B2 来源）
- `urn:piao:spec:architecture:evolution_model@v1 (draft · 路径 A 消化后 · 2026-04-19 19:54 · commit e6e18d5f)`（06 前置锚点已声明）
- `urn:piao:spec:architecture:artifact_model@v1.3`（升版目标 · 至 @v1.4）
- `urn:piao:spec:architecture:layered_architecture@v1 (draft)`（原地修订目标）
- `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 published`（对标范式来源）

**下游候选**：
- `03-layered-architecture.md`（draft 原地修订 · 不升 rev · §3.1 evolution.scanned 行精化）
- `02-artifact-model.md @v1.3 → @v1.4`
- `06-evolution-model.md @v1 (draft) → @v1.1 (draft)`（跟随升版 · Step 4 前置）
- `m6-evolution-draft-review.md @v1`（§5 追加路径 B 完成记录）
- `m6-final-decisions.md @v1`（待 06 published 后产出 · M6 milestone 收官）

**关闭候选**：`urn:piao:snapshot:kernel:m6_evolution_kernel_alignment_complete@v1`（路径 B 完成快照 · 与 06 升 @v1.1 同步产出）
