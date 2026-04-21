---
urn: urn:piao:evolution_source:kernel:m1_debt_ledger@v10
kind: evolution_source
rev: v10
status: published
produced_by: m7-prefix-taxonomy-decision-consumption-2026-04-20
supersedes: urn:piao:evolution_source:kernel:m1_debt_ledger@v9
rev_history:
  - rev: v1
    published_at: 2026-04-18T~18:00+08:00
    summary: "M1 review 定稿遗留：§1.1 六条 BAN 登记"
  - rev: v2
    published_at: 2026-04-18T22:55:00+08:00
    summary: "阶段 1 charter review 反馈：新增 §1.2 Post-M1 发现的 kernel 缺口 4 条"
    triggered_by: urn:piao:artifact:adapter/frontend_migration:charter_review@v1
  - rev: v3
    published_at: 2026-04-18T23:10:00+08:00
    summary: "阶段 2 task-types review 反馈：§1.2 追加 3 条 kernel 缺口（Q5-Q7）"
    triggered_by: urn:piao:artifact:adapter/frontend_migration:task_types_review@v1
  - rev: v4
    published_at: 2026-04-18T23:35:00+08:00
    summary: "阶段 2 路径 A 收敛：kernel 三文档 @v1.1 小升完成，§1.2 Q1/Q2/Q3/Q5/Q6/Q7 六条 consumed；Q4 延期至阶段 3"
    triggered_by: urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1
  - rev: v5
    published_at: 2026-04-19T02:10:00+08:00
    summary: "M4 snapshot milestone 收官：§1.2 追加 Q8-Q14 七条 kernel 缺口（来自 m4-snapshot-draft-review §2），并同步标全部 consumed（证据指向 04@v1.1 published / 03 draft 原地修订 / 01@v1.2 / 02@v1.2 / m4_final_decisions@v1）；§1.1 六条 BAN 仍保留至阶段 3 处理"
    triggered_by: urn:piao:snapshot:kernel:m4_final_decisions@v1
  - rev: v6
    published_at: 2026-04-19T15:40:00+08:00
    summary: "M5 drift milestone 收官：§1.4 新增 Q15-Q20 六条 kernel 缺口（来自 m5-drift-draft-review §2）+ R17-R25 九条修订落地矩阵（路径 A 四条 draft 内原地 · 路径 B 五条外篇升降），并同步标全部 consumed（证据指向 05@v1.1 published / 04@v1.2 / 03 draft 原地 / 02@v1.3 / m5_final_decisions@v1）；§1.1 六条 BAN 仍保留至阶段 3 处理"
    triggered_by: urn:piao:snapshot:kernel:m5_final_decisions@v1
  - rev: v7
    published_at: 2026-04-19T21:34:00+08:00
    summary: "M6 evolution milestone 收官：§1.5 新增 Q21-Q26 六条 kernel 缺口（来自 m6-evolution-draft-review §2）+ A1-A4/B1-B2 六条消化路径矩阵（路径 A 四条 06 @v1 draft 内原地 · 路径 B 两条外篇升降），并同步标全部 consumed（证据指向 06@v1.1 draft / 03 draft 原地 §3.1 refresh / 02@v1.3→@v1.4 published 派生注册新增 evolution.scan_result 条目 / m6_evolution_kernel_alignment@v1 published+implemented / m6_final_decisions@v1 published）；§1.1 六条 BAN 仍保留至阶段 3 处理"
    triggered_by: urn:piao:snapshot:kernel:m6_final_decisions@v1
  - rev: v8
    published_at: 2026-04-19T23:17:00+08:00
    summary: "M6 遗留项收敛：§1.6 新增 Q27（kernel spec published 事件 journal 可见性债 · 14 条历史 rev 补发落盘 kernel-events/2026-04.jsonl · reconstructed=true · 最终 rev 附真 sha256 · 中间 rev null + historical_untraceable 标注）+ Q28（kernel spec published 事件 event_id 前缀字面规约冲突债 · 06 §11 原稿类比 M5 drift artifact 用 snap-published-* · 与 01 §5 顶层 task 域规约冲突 · 本次按 01 §5 顶层规约走 task-* · 06 §11 字面勘误补注）；两条同轮登记 + 消费（Q27 consumed · Q28 continued-to-M7 续论）"
    triggered_by: urn:piao:artifact:kernel:m6_debt_consumption@v1
  - rev: v9
    published_at: 2026-04-20T00:10:00+08:00
    summary: "M6 扫尾续收敛：§1.7 新增 Q29（event_id 前缀规约分化 meta 债 · Q28 升级为分类系统缺口）· 在 N1+N2 近实时发射 consumption@v1/ledger@v8 两条 artifact.published 事件 + N3' 补发 smoke-report@v1 事件后 · 落盘 journal 已事实并存至少 4 种 event_id 前缀变体（task-* / drift-triggered-* / evolution-scanned-* / artifact-published-*）· Q29 将 Q28 三选项裁定升级为分类系统决议 · 仍 continued-to-M7 · 但新增 3 条活证据（本 rev 升版同时登记 + 附证据清单）· §1.6 原文保真不动"
    triggered_by:
      - urn:piao:journal:kernel:kernel_events@2026-04
      - urn:piao:journal:kernel:mvp_smoke_events@2026-04
  - rev: v10
    published_at: 2026-04-20T00:55:00+08:00
    summary: "M7 工作流 P 阶段 γ₁ 收官：Q29 由 m7_prefix_taxonomy_decision@v1 裁定为 **选项 B'-1（严格二维扩展）** · §1.7.1 状态从 continued-to-M7 改为 consumed-via-m7-decision · §1.6.2 新增 CONV-01.1 子条款（event_id 前缀合法性约束 · 由 01 @v1.3 §5.1.1 兜底）· §1.6.2 Q28 续论三条补注标注\"由 Q29 B'-1 实际裁定为选项 B 的升级版（扩展 01 §5）\"· §1.8 新增 v10 收尾章节（CONV-01.1 契约 + B'-1 落地清单 + CONV-01 EX1 第三阶段压测 7 次延迟=0）· §1.7 原文保真不动"
    triggered_by: urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1
    also_triggered_by: urn:piao:spec:architecture:identity_model@v1.3
wordcheck_exempt: true
---

# M1 Kernel Debt Ledger · 场景词清理遗留账

> 本文档是 **M1 review（2026-04-18）收尾** 时产出的技术债账本，登记**决议 4"强化 kernel 场景词白名单"在 M1 阶段未能完成的清理项**。
>
> 定位：`evolution_source` —— 任何一条遗留都会触发后续的 `artifact.superseded` 或 `rule.updated` 事件；清完即本账归档。
>
> 本账本的**产出逻辑**而非规范——它本质是对"为什么 M1 验收时仍然有场景词"的诚实记账，**不阻断 M1 定稿**，但为 M2 锚定第一批输入。

---

## 0. 扫描基线

- 工具：`./scripts/kernel-wordcheck.sh --ci`（v0.1，2026-04-18）
- 基线扫描时刻：M1 review 定稿最后一次提交前
- 初始命中：**15 条 BAN + 多条 WARN**
- M1 收尾实际清理：**9 条 BAN**（全部来自 `00-overview.md` / `07-extensibility.md` / `03-layered-architecture.md` / `01-identity-model.md`）

---

## 1. 遗留违规清单

以下条目在 M1 定稿点仍未清理，**允许带入 M2**。每条都是一次 `rule.updated` 事件的候选输入。

### 1.1 `02-artifact-model.md` · §7 业务场景锚点段（6 条）

| 行号 | 命中词 | 上下文摘要 | 处置方案 |
|------|-------|-----------|---------|
| 88 | kuikly | `artifact_type: spec.structured  # 细化（kuikly 迁移场景）` | 改为 `# 细化（<adapter_name> 场景）` 或显式标注 "示例：首个落地 adapter" |
| 276 | kuikly | 章节标题 `## 7. 业务场景锚点：Kuikly 迁移举例` | 改为 `## 7. 业务场景锚点（以首个落地 adapter 为例）`，把"Kuikly"降为 §7 内部段落示意 |
| 345 | kuikly | §10.1 决议 1 理由段 "典型单位（以 Kuikly 迁移业务场景为例）" | 改为 "典型单位（以首个落地 adapter 的业务场景为例）" |
| 346 | kuikly | "一个 Kuikly 页面的根目录（如 `shared/.../page/...`）" | 改为 "一个业务 UI 单元的根目录（如 `shared/.../page/...`）"；反引号内路径示例保留（已被启发式豁免） |
| 355 | kotlin | §10.1 决议 1 理由段 "Kotlin 代码在重构时文件拆合非常频繁（ViewModel 拆分、Card 化）" | 改为 "宿主语言代码在重构时文件拆合非常频繁（如 ViewModel 拆分、组件化重构）"；保留论证核心即"文件级粒度会导致 rev 通胀"的因果 |
| 356 | kuikly | "目录级粒度天然对齐 Kuikly 项目的\"page / feature / module\"概念" | 改为 "目录级粒度天然对齐首个落地 adapter 的\"unit / feature / module\"概念" |

**为什么留到 M2**：

1. §7 被**有意**设计为"业务场景锚点"小节，M1 决议 4 的词表收紧发生在本小节定稿之后；
2. §10.1 决议 1 的**理由段**深度依赖具体例子（Kuikly / Kotlin），粗暴替换为通用词会削弱论证的直观性；
3. 正确处理是在 M2 构建 adapter 文档（`docs/piao-pipeline/adapters/kuikly/`）时，把这些"业务场景示例"**迁移**过去，留 kernel 只做通用契约陈述；
4. M1 review 的首要目标是**身份模型收敛**（决议 1–3），场景词清理是第二序任务，不应阻塞 M1 交付。

**清理触发条件**：M2 启动首个 adapter 文档骨架之后，本账本中 6 条自动转为一次 `rule.updated` 事件 + 一次 `02-artifact-model.md` 的 rev 升降（从 v1 → v2）。

---

### 1.2 Post-M1 阶段发现的 kernel 缺口（4 条）

> **入库依据**：`urn:piao:artifact:adapter/frontend_migration:charter_review@v1` §2 产出；按 `post-m1-kickoff.md §2.3` 分支判定规则（缺口 ≥ 3 条且至少一条高严重性）进入分支 2a。
>
> 与 §1.1 不同，§1.2 不是"场景词违规"，而是 **kernel 层面的描述缺口或澄清诉求**。每条都由一次真实 adapter 写作卡点驱动。

| 编号 | 来源 | 严重性 | kernel 改动点 | 处置节点 | 状态 |
|------|-----|--------|-------------|---------|------|
| [Q1] | charter-review §2 Q1 | **高** | 新增 `01-identity-model.md §3.4` "adapter 自身资产 scope 约定" | 阶段 2 结束后，即启动工作流 A 前的一次 kernel 小版本升 (`01@v1.1`) | ✅ consumed · `01@v1.1 §3.4` |
| [Q2] | charter-review §2 Q2 | 中 | 在 `02-artifact-model.md §2` 派生类型段补"派生注册方式"小节（adapter 自用不登记 / 多 adapter 共用须升 kernel） | 可与阶段 3 `02@v2` 清理合并，或独立 `02@v1.1` 小升 | ✅ consumed · `02@v1.1 §2.2` |
| [Q3] | charter-review §2 Q3 | 低 | 在 `07-extensibility.md §2` 末尾补"扩展点占位声明建议格式"非强制模板 | 低优先，待阶段 2 积累 2–3 份 adapter 的实际写法后再收敛 | ✅ consumed · `07@v1.1 §2.5` |
| [Q4] | charter-review §2 Q4 | 低 | `00-overview.md:93` 的 `viewmodel` WARN（属于 kernel 内部 §1.1 遗漏）→ 随阶段 3 `02@v2` 清理同步处置 | 并入阶段 3 | ⏸ 延期至阶段 3（wordcheck v0.1 不支持行内豁免，与 §1.1 合并清理） |
| [Q5] | task-types-review §2 Q5 | 中 | 在 `02-artifact-model.md §2` 派生示例表扩充 `artifact.*` 派生路径示范（如 `artifact.build_output` / `artifact.asset_bundle`），并显式说明"kind 作为 dot 前缀合法" | 与 [Q2] 合并为 `02@v1.1` 小升 | ✅ consumed · `02@v1.1 §2.1.1` |
| [Q6] | task-types-review §2 Q6 | 低 | 在 kernel `01 §4` 或 `07 §2` 末尾增补"派生名命名风格"非强制建议（task `type` → snake_case；`artifact_type` → dot.lowercase + snake_case 段） | 与 [Q3]/[R6] 合并入 `07@v1.1` 或 `01@v1.1` | ✅ consumed · `01@v1.1 §4.4` + `02@v1.1 §2.1.2` |
| [Q7] | task-types-review §2 Q7 | 中 | 在 `07-extensibility.md §2` 为四个扩展点各补"合规性自验证 checklist v0.1"（断言形式，可被脚本机械化判定） | 与 [Q3] 合并入 `07@v1.1` | ✅ consumed · `07@v1.1 §2.6` |

**与 §1.1 的关系**：
- §1.1 是"词表违规"（scenario-wordlist 硬约束未达标），清理方向为**替换/迁移**；
- §1.2 是"kernel 描述缺口"（写 adapter 时无章可循），清理方向为**新增/澄清**；
- 两者在**阶段 3** 的 `02-artifact-model.md@v2` 提交点**合并一次性处理**，避免 kernel 文档在短期内被连续升 rev。

**详细建议**（R1–R7）请查阅 `adapters/frontend-migration/_review/adapter-charter-review.md §3`（R1-R4）与 `adapters/frontend-migration/_review/task-types-review.md §3`（R5-R7）。

**路径推荐**：task-types review §4 建议**路径 A**——将 7 条 kernel 缺口合并为**一次 kernel 小版本**（`01@v1.1` + `02@v1.1` + `07@v1.1`），完成后进入分支 2b 启动工作流 A。

**路径 A 执行结果**（2026-04-18 23:35）：
- ✅ `01-identity-model@v1.1` 已发布（新增 §3.4 adapter 自身资产 scope 约定 + §4.4 命名风格约定）
- ✅ `02-artifact-model@v1.1` 已发布（新增 §2.1.1 `artifact.*` 派生示范 + §2.1.2 artifact_type 命名风格 + §2.2 派生类型注册方式）
- ✅ `07-extensibility@v1.1` 已发布（新增 §2.5 扩展点占位声明建议格式 + §2.6 扩展点合规性自验证 checklist v0.1）
- ✅ §1.2 **7 条缺口中 6 条 consumed**（Q1/Q2/Q3/Q5/Q6/Q7），Q4 延期至阶段 3（与 §1.1 合并清理，原因：wordcheck v0.1 尚不支持行内豁免注释）
- ⏸ §1.1 六条 BAN 保留，按原计划在阶段 3 `02@v2` 升版时与 Q4 一并清理

---

### 1.3 M4 review 发现的 kernel 缺口（7 条 · v5 新增）

> **入库依据**：`urn:piao:artifact:kernel:m4_snapshot_draft_review@v1` §2（七条"找不到答案的问题"），由 M4 首版 draft 压测 kernel 契约时反证暴露。
>
> **登记 + 消费同轮**：本批七条在 @v5 升版当下即标 consumed（无"登记后等下一 rev 再消费"的中间态），因 M4 milestone 收官 commit 已落地全部证据。这与 @v3→@v4 把 Q1–Q7 一次性推进到 consumed 的范式一致（均属 path-A/path-B 合并后的统一结账）。

| 编号 | 来源 | 严重性 | kernel 改动点 | 路径 | 映射 R | 状态 / 证据 |
|------|-----|--------|-------------|-----|-------|-----------|
| [Q8] | m4-snapshot-draft-review §2 Q8 | 中 | `03 §3.3.1` 新增"原子写入契约"（多事件同 txn 语义 + `--check-orphan` 接口声明） | B | R12 | ✅ consumed · `03 draft §3.3.1`（原地修订，未升 rev；M1 review 周期内） |
| [Q9] | m4-snapshot-draft-review §2 Q9 | 中 | `03 §3.1/§3.2` stage 事件追加可选字段 `related_taskdag_urn`，并对接 `04 §3.3 scope_kind=taskdag` | B | R13 | ✅ consumed · `03 draft §3.1/§3.2`（原地修订）+ `04@v1.1 §2.2` 绑定规则（scope_kind=taskdag 时必填且等于 scope_ref） |
| [Q10] | m4-snapshot-draft-review §2 Q10 | 低 | `04 §3.2 front-matter + §3.4` 显式 `artifact_type: snapshot` + 允许 `snapshot.<subtype>` 前缀 | A | R8 | ✅ consumed · `04@v1 (draft 内原地消化)` |
| [Q11] | m4-snapshot-draft-review §2 Q11 | 中 | `04 §3.2.1` 新增 `content_sha256` 规范化规则（canonical YAML 五步 + 字典序） | A | R9 | ✅ consumed · `04@v1 §3.2.1`（新增小节） |
| [Q12] | m4-snapshot-draft-review §2 Q12 | 低 | `01 §7.2` 存储位置表的 `snapshot` 行按 `scope_kind` 五类细分（unit/stage/taskdag/adapter/kernel） | B | R14 | ✅ consumed · `01@v1.2 §7.2`（@v1.1 → @v1.2 升版） |
| [Q13] | m4-snapshot-draft-review §2 Q13 | 中 | `04 §3.2.2` 声明 snapshot 不写 `depends_on`；`02 §5.3.1` lineage 查询器特化（snapshot 时以 `frozen_artifacts` 为等价替身） | A + B | R10 + R15 | ✅ consumed · `04@v1 §3.2.2`（路径 A 新增小节）+ `02@v1.2 §5.3.1`（路径 B 新增小节，strong 强度） |
| [Q14] | m4-snapshot-draft-review §2 Q14 | 中 | `04 §2.2` event_id 预留契约；`02 §4.3.1` 显式点名 snapshot 复用 §4.3 预留流程 | A + B | R11 + R16 | ✅ consumed · `04@v1 §2.2`（路径 A 补段）+ `02@v1.2 §4.3.1`（路径 B 新增小节） |

**与 §1.2 的关系**：
- §1.2（v2-v4 登记）的七条来自 **adapter 侧** review 反馈——由首个 adapter 在 charter / task-types 文档起草时的"写不动"触发
- §1.3（v5 登记）的七条来自 **kernel 侧** review 反馈——由 M4 首版 draft 在压测 kernel 已有契约时的"缺锚点"触发
- 两批都不是"词表违规"（§1.1 那是第三类），**而是 kernel 契约层的描述缺口**；清理方向均为**新增/澄清**
- §1.3 的七条在 M4 milestone 收官 commit 中**一次性全部 consumed**（不留遗留）

**详细建议 R8–R16**：
- R8–R11 → 路径 A → 消化于 `04@v1 (draft)` 内部（见 `m4-snapshot-draft-review §5`）
- R12–R16 → 路径 B → 消化于 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1`（见 `m4-snapshot-draft-review §6`）
- 跨篇一致性维护（Step 3 反向对接）→ `04@v1 → @v1.1 (draft)` 六处锚点微调（见 `04 §10 rev_history` v1.1 draft 行）
- Step 4 收官 → `04@v1.1 published` + `m4_final_decisions@v1`（见 `m4-snapshot-draft-review §7`）

**路径执行总结**（2026-04-19 02:10）：

```
Q8-Q14（7 条）
  ├─ 路径 A（R8/R9/R10/R11）：04 draft 内部原地消化（2026-04-19 01:00）
  ├─ 路径 B（R12/R13/R14/R15/R16）：m4_snapshot_kernel_alignment proposal（2026-04-19 01:45）
  ├─ Step 3 反向对接：04 @v1 draft → @v1.1 draft（2026-04-19 02:00）
  └─ Step 4 milestone 收官：04 @v1.1 draft → @v1.1 published + m4_final_decisions@v1（2026-04-19 02:10）
```

所有 7 条在本 rev 登记即闭环，**M4 milestone 正式关闭**。

---

### 1.4 M5 review 发现的 kernel 缺口（6 条 + 9 条修订落地矩阵 · v6 新增）

> **入库依据**：`urn:piao:artifact:kernel:m5_drift_draft_review@v1 §2`（六条"05 draft 压测 kernel 契约时的可完善空间"），由 M5 首版 draft（`05-drift-propagation.md @v1 draft`）压测 kernel 契约时反证暴露。
>
> **登记 + 消费同轮**：本批六条缺口（Q15-Q20）+ 九条修订（R17-R25）在 @v6 升版当下即标 consumed，对标 @v4→@v5 把 Q8-Q14 一次性推进到 consumed 的范式。由 `m5_final_decisions@v1` commit `b8f877f9` §1 决议 1-6 + §3 R17-R25 落地矩阵作为终态封冻证据。
>
> **特别说明**：M5 review 比 M4 review 多出"双通道分治"维度——kernel 锚点引用姿势问题（Q15/Q16/Q18）在 `m5-drift-draft-review §1.2` 中作为独立校验条目登记 · 但这三条 _非锚点虚构_ 级缺口，通过 R17/R18/R19 + R21/R22 五条修订双向闭合（路径 A 改 05 + 路径 B 升外篇），故合并登记于 Q15/Q16/Q18 条目下。

#### 1.4.1 Q15-Q20 六条 kernel 缺口

| 编号 | 来源 | 严重性 | kernel 改动点 | 路径 | 映射 R | 状态 / 证据 |
|------|-----|--------|-------------|-----|-------|-----------|
| [Q15] | m5-drift-draft-review §2 Q15 | 中 | `05 §2.5` drift 的 `content_sha256` "不参与字段清单" 改为正向白名单机制（列六字段 diff_base 两 URN + added + removed + sha_changed + unchanged_count） · `04 §3.2.1` 需补 canonical YAML 通用工具实施建议（含 key 正则 + pick_fields 范式 + SHA_WHITELIST 声明范式） | A + B | R17 + R21 | ✅ consumed · `05 @v1 (draft 内原地) §2.5` + `04 @v1.2 §3.2.3`（新增通用工具契约 · commit `c3b8fe82`） |
| [Q16] | m5-drift-draft-review §2 Q16 | 中 | `05 §6.2` `drift.detected` 事件的 `drifting_artifact_urn` 字段与 `subject` 同值 · 违反 `03 §3.1` 双轨原则 → 删除 `drifting_artifact_urn` 字段 · 保留 `evidence` 承载两张 snapshot URN | A | R18 | ✅ consumed · `05 @v1 (draft 内原地) §6.2`（删除 alias 字段 · 11 字段 schema 定稿） |
| [Q17] | m5-drift-draft-review §2 Q17 | 中 | drift artifact 的 `produced_by.event_id` 与 `drift.detected` 事件的 `event_id` 前缀规约冲突 · 引入双前缀分离（drift artifact `snap-published-*` · drift.detected `drift-detected-*`） | A | R19 | ✅ consumed · `05 @v1 (draft 内原地) §6.2 + §2.3 schema + §9 Q3 review-resolved` |
| [Q18] | m5-drift-draft-review §2 Q18 | 中 | `05 §3.2 T5` 同 txn 的"artifact.published(D) + drift.detected"写入语义 · `03 §3.3.1` 原子写入契约需泛化为"N 条 L1 事件同 txn 提交"通用契约（snapshot 三写 / drift 两写均为实例） | B | R22 | ✅ consumed · `03 draft §3.3.1`（原地修订 · 泛化为 N 条 L1 事件 · N≥1 · 无 type 约束 · commit `49608733`） |
| [Q19] | m5-drift-draft-review §2 Q19 | 低 | `05 §7.3` "drift 算法 kernel rev 升降" 作为 retracted 条件与 §7.1 "drift 不升 rev" 语义张力 → 默认不回溯作废 · 新 rev 显式声明 `retroactive_invalidation: true` 时才批量 retracted | A | R20 | ✅ consumed · `05 @v1 (draft 内原地) §7.1 脚注 + §7.3 条件 #2 重写` |
| [Q20] | m5-drift-draft-review §2 Q20 | 中 | `02 §5.3.1` lineage snapshot 特化扩展为**通用 lineage 特化注册表** · 首批注册 `kind=snapshot` + `kind=drift` 两条规则（drift 以 `diff_base` 两 URN 为等价替身） | B | R23 | ✅ consumed · `02 @v1.3 §5.3.1`（commit `f25dc403`） |

#### 1.4.2 R17-R25 九条修订落地矩阵

| 修订 | 源自 | 目标 | 落地 rev | 路径 | commit |
|-----|-----|------|---------|-----|-------|
| R17 | Q15 | `05 §2.5` 改为正向白名单六字段 | draft 内原地 | A | 阶段 β draft 起稿内（2026-04-19 14:10） |
| R18 | Q16 | `05 §6.2` 删除 `drifting_artifact_urn` 字段（消除 alias 冗余） | draft 内原地 | A | 阶段 β draft 起稿内（2026-04-19 14:10） |
| R19 | Q17 | `05 §6.2 + §2.3 + §9 Q3` 双前缀规约（`snap-published-*` / `drift-detected-*`） | draft 内原地 | A | 阶段 β draft 起稿内（2026-04-19 14:10） |
| R20 | Q19 | `05 §7.1 脚注 + §7.3` 默认不回溯作废 · `retroactive_invalidation: true` 才触发批量 retracted | draft 内原地 | A | 阶段 β draft 起稿内（2026-04-19 14:10） |
| R21 | Q15 + `m4-toolchain-review §2.5 T5`（合并） | `04 §3.2.3` canonical YAML 通用工具契约（三承诺：key 正则 + pick_fields 范式 + SHA_WHITELIST 声明范式） | @v1.1 → @v1.2 | B | `c3b8fe82` |
| R22 | Q18 | `03 §3.3.1` 泛化为 N 条 L1 事件同 txn（N≥1 · 无 type 约束） | draft 原地修订 | B | `49608733` |
| R23 | Q20 | `02 §5.3.1` 扩为通用 lineage 特化注册表（kind=snapshot + kind=drift 两条） | @v1.2 → @v1.3 | B | `f25dc403` |
| R24 | 05 §9 Q1 联动 | `04 §5.1` `sha_changed` 作为 `modified` 的 alias（双名兼容 · 新实施用 `sha_changed`） | 同 @v1.2 合并 | B | `c3b8fe82` |
| R25 | 05 §9 Q5 联动 | `02 §2.2.4` 派生类型注册补 `wordcheck_policy` 字段（七字段 schema 形式化 · 让 drift.propagation_record 等自动 exempt） | 同 @v1.3 合并 | B | `f25dc403` |

#### 1.4.3 与 §1.2/§1.3 的关系

| 登记批次 | rev 升降 | 来源方 | 触发机制 | 缺口性质 | 修订数量 |
|---------|---------|--------|---------|---------|---------|
| §1.2 | v2→v3→v4 | adapter 侧（charter + task-types review） | 首个 adapter 在 kernel 契约外写作时的"无章可循" | kernel **描述缺口** | Q1-Q7 · 七条 · 合并为 R1-R7 |
| §1.3 | v4→v5 | kernel 侧（m4-snapshot-draft-review） | M4 首版 draft 压测 kernel 已有契约时的"缺锚点" | kernel **契约层描述缺口** | Q8-Q14 · 七条 · 合并为 R8-R16（路径 A R8-R11 + 路径 B R12-R16） |
| §1.4 | v5→v6 | kernel 侧（m5-drift-draft-review） | M5 首版 draft 压测 kernel 契约时的"引用姿势可完善空间 + 新模型锚点反向需求" | kernel **跨篇一致性缺口** | Q15-Q20 · 六条 · 合并为 R17-R25（路径 A R17-R20 + 路径 B R21-R25） |

**共同点**：三批全为 kernel **描述/契约层缺口**（非词表违规 §1.1），清理方向均为**新增/澄清/规格化**

**差异点**：
- §1.2 来自外部 adapter 触发（"别人写不动"）· §1.3/§1.4 来自 kernel 自身 milestone 推进触发（"新 draft 发现上一批规格有 gap"）
- §1.4 首次引入"双通道分治"维度 · 把"4 条路径 A（draft 原地）+ 5 条路径 B（外篇升降）"作为同一批缺口的两种处置通道（§1.3 已是 A+B 混合，但 §1.4 通过 `m5-drift-kernel-alignment-proposal@v1` 显式 proposal 化打包，比 §1.3 的隐式处置更形式化）

#### 1.4.4 路径执行总结（2026-04-19 15:40）

```
Q15-Q20（6 条缺口 → R17-R25 九条修订）
  ├─ 路径 A（R17/R18/R19/R20）：05 @v1 draft 内部原地消化（2026-04-19 14:10）
  │     └─ 不升 rev · 按 01 §10.1 draft 可原地修订契约
  │
  ├─ 路径 B（R21/R22/R23/R24/R25）：m5_drift_kernel_alignment@v1 proposal 打包处置
  │     ├─ commit 78134de8 · proposal @v1 published
  │     ├─ S1 R22：03 §3.3.1 原地泛化（commit 49608733）
  │     ├─ S2 R21+R24：04 @v1.1 → @v1.2 published（commit c3b8fe82）
  │     ├─ S3 R23+R25：02 @v1.2 → @v1.3 published（commit f25dc403）
  │     └─ S5 反向对接：05 @v1 draft → @v1.1 draft 锚点同步（commit d6ee71ac）
  │
  ├─ Step S6+S7：m5-drift-draft-review §5 路径 A/B 消化记录追补 + 05 §9 Q1/Q5 "已 consumed" 注释补齐（commit c0991418）
  │
  ├─ 工具链验证：piao-drift-compute.sh MVP 首版（555 行 · 四场景冒烟全通 · commit bcc56229）
  │     └─ 反证 R1-R5 五硬约束未被实施反例证伪
  │
  └─ milestone 收官：
        ├─ _review/m5-drift-draft-review.md @v1 published（commit 596f2ad2）
        ├─ _review/m5-final-decisions.md @v1 published（commit b8f877f9）
        ├─ 05 @v1.1 draft → @v1.1 published（commit f224dcfa · 2026-04-19 15:40）
        ├─ m5_drift_kickoff @v1 status: published → superseded（本 commit 同批）
        └─ M1-debt-ledger @v5 → @v6（本 commit 同批 · 本文件）
```

所有 6 条缺口 + 9 条修订在本 rev 登记即闭环，**M5 drift milestone 正式关闭**。

---

### 1.5 M6 review 发现的 kernel 缺口（6 条 + 6 条消化路径矩阵 · v7 新增）

> **入库依据**：`urn:piao:artifact:kernel:m6_evolution_draft_review@v1 §2`（六条"06 @v1 draft 压测 kernel 契约时的可完善空间"），由 M6 首版 draft（`06-evolution-model.md @v1 draft`）压测 "M1–M5 五层既有封板契约 + M5 toolchain 扩展证据 TB'1–TB'5" 能否承载 evolution 决策层时反证暴露。
>
> **登记 + 消费同轮**：本批六条缺口（Q21-Q26）+ 六条消化路径（A1-A4 + B1-B2）在 @v7 升版当下即标 consumed，对标 @v5→@v6 把 Q15-Q20 + R17-R25 一次性推进到 consumed 的范式。由 `m6_final_decisions@v1 published`（2026-04-19 21:34）§1 决议 1-6 + §6 跨篇一致性矩阵作为终态封冻证据。
>
> **特别说明**：M6 review 相比 M5 review 缺口密度**显著下降**——六条全部为"增量完善 / 字面约束补齐"级别，**路径 B 仅 2 条**（M5 为 5 条），**路径 A 4 条**（M5 为 4 条）。原因：M6 站在 M1–M5 五层封板契约之上，可复用范式（双形态 / 双通道 / 三层订阅链 / C1–C4 继承 / 拒绝列表）密度高，新发明少，缺口自然少。这符合 kernel 层"越往后 milestone 越薄"的设计预期。

#### 1.5.1 Q21-Q26 六条 kernel 缺口

| 编号 | 来源 | 严重性 | kernel 改动点 | 路径 | 映射 | 状态 / 证据 |
|------|-----|--------|-------------|-----|------|-----------|
| [Q21] | m6-evolution-draft-review §2 Q21 | 中 | `03 §3.1` L1 事件枚举第 10 行 `evolution.scanned` 的 subject + 语义字段精化（从 M4 占位 `target_task_urn / extracted_memory_ids[]` 刷新为对齐 `06 §2.3/§5.3` 实锁 schema 的 `drift_event_urn / scope_urn / scanned_drifts[] / decision_log[]`）· `§3.1` 末段补"禁止扩展"注 + `§6.3` 连带精化 + `§10` rev_history 追述 | B | B1 | ✅ consumed · `03 @v1 draft §3.1` 原地精化（**不升 rev** · 10 类枚举总数不变 · commit `76bbfff5`）|
| [Q22] | m6-evolution-draft-review §2 Q22 | 低 | `02 §2.2.4` 派生类型注册表新增 `evolution.scan_result` 条目（七字段齐全 · `parent_type=evolution` · `wordcheck_policy=machine_generated` · `schema_version=1.0` · `owner=kernel:m6` · `stability=beta`）· "注释 3（v1.4 · B2）"补注 + 承诺段 v1.4 专项条目 + `§11` rev_history v1.4 行 | B | B2 | ✅ consumed · `02 @v1.3 → @v1.4 published`（commit `7a7bce04`）|
| [Q23] | m6-evolution-draft-review §2 Q23 | 低 | `06 §6.7` 锚点闭环声明末尾追加普适性声明段：§6.2 "L1 永远只读 3 字段" 契约为 06 M6 单边约束 · `03 §3.1` 尚未在 kernel 全局建立 L1 事件 body 字段数上限的统一 schema · 未来 M7+ 出现新 L1 事件需彼时重新评估 | A | A1 | ✅ consumed · `06 @v1 draft §6.7` 原地补段（不升 rev · +3 行 · commit `e6e18d5f`）|
| [Q24] | m6-evolution-draft-review §2 Q24 | 低 | `06 §2.3` artifact schema 的 `scanned_drifts[]` 字段必填性逐字段明示：`drift_urn / decision` 必填；`driver_event_id` **sha_only drift 时为 null**；其余补充字段可选 | A | A2 | ✅ consumed · `06 @v1 draft §2.3` 原地补列（不升 rev · +4 行 · commit `e6e18d5f`）|
| [Q25] | m6-evolution-draft-review §2 Q25 | 低 | `06 §5.2` orphan_check schema 后追加同值约束：`orphan_check.scanned_at == 顶层 produced_at` · 同一次扫描两字段不得分叉 · 客观性承诺（§3.3）在字段级的落实 | A | A3 | ✅ consumed · `06 @v1 draft §5.2` 原地补段（不升 rev · +5 行 · commit `e6e18d5f`）|
| [Q26] | m6-evolution-draft-review §2 Q26 | 低～中 | `06 §7.3` retracted 条件 #2 末尾脚注承继 `05 §7.3` "默认不回溯作废"范式：kernel rev 升版（扫描算法 v1 → v2）只对**未来扫描**生效 · 不触发对历史 published evolution.scan_result 的批量 retracted · 若需整体作废走独立 `evolution_retract_batch` proposal | A | A4 | ✅ consumed · `06 @v1 draft §7.3` 原地补脚注（不升 rev · +6 行 · commit `e6e18d5f`）|

#### 1.5.2 A1-A4 / B1-B2 六条消化路径矩阵

| 修订 | 源自 | 目标 | 落地 rev | 路径 | commit |
|-----|-----|------|---------|-----|-------|
| A1 | Q23 | `06 §6.7` 补普适性声明段（3 字段上限仅 M6 单边约束） | 06 @v1 draft 内原地（**不升 rev**）| A | `e6e18d5f` |
| A2 | Q24 | `06 §2.3` `scanned_drifts[]` 字段必填性列补齐（`driver_event_id` 允许 null）| 06 @v1 draft 内原地（**不升 rev**）| A | `e6e18d5f` |
| A3 | Q25 | `06 §5.2` `orphan_check.scanned_at == produced_at` 同值约束 | 06 @v1 draft 内原地（**不升 rev**）| A | `e6e18d5f` |
| A4 | Q26 | `06 §7.3` retracted 条件 #2 kernel rev 升版脚注 · 默认不回溯作废 | 06 @v1 draft 内原地（**不升 rev**）| A | `e6e18d5f` |
| B1 | Q21 | `03 §3.1` L1 事件枚举第 10 行 `evolution.scanned` subject + 语义字段精化（对齐 06 实锁 schema · 10 类总数不变）| 03 @v1 draft 原地精化（**不升 rev** · 按 01 §10.1 draft 可原地契约）| B | `76bbfff5` |
| B2 | Q22 | `02 §2.2.4` 派生注册表新增 `evolution.scan_result` 条目（七字段齐全）| @v1.3 → @v1.4 published | B | `7a7bce04` |

**路径 B 差异化策略说明**：B1 走 draft 原地精化（不升 rev）· B2 走 published 小升。原因：03 尚未 published · 按 01 §10.1 draft 契约可就地精化；02 已 @v1.3 published · 必须走 `@v1.3 → @v1.4` 小升才能增派生类型注册条目 · 对齐 `01 §10.1` published 不可变契约。本差异化策略与 M5 路径 B R22（03 原地）/ R25（02 小升）同构 · 系 kernel 层 rev 升降范式的**跨 milestone 稳定模式**。

#### 1.5.3 与 §1.2/§1.3/§1.4 的关系

| 登记批次 | rev 升降 | 来源方 | 触发机制 | 缺口性质 | 修订数量 | 路径 A / B 分布 |
|---------|---------|--------|---------|---------|---------|--------------|
| §1.2 | v2→v3→v4 | adapter 侧（charter + task-types review） | 首个 adapter 在 kernel 契约外写作时的"无章可循" | kernel **描述缺口** | Q1-Q7 · 七条 · 合并为 R1-R7 | 未显式分路径（隐式混合）|
| §1.3 | v4→v5 | kernel 侧（m4-snapshot-draft-review） | M4 首版 draft 压测 kernel 已有契约时的"缺锚点" | kernel **契约层描述缺口** | Q8-Q14 · 七条 · 合并为 R8-R16 | A 4 条 + B 5 条（隐式处置）|
| §1.4 | v5→v6 | kernel 侧（m5-drift-draft-review） | M5 首版 draft 压测 kernel 契约时的"引用姿势可完善空间 + 新模型锚点反向需求" | kernel **跨篇一致性缺口** | Q15-Q20 · 六条 · 合并为 R17-R25 | A 4 条 + B 5 条（首次 proposal 化打包 · `m5_drift_kernel_alignment@v1`）|
| §1.5 | v6→v7 | kernel 侧（m6-evolution-draft-review） | M6 首版 draft 压测 "M1–M5 五层封板契约 + M5 toolchain 扩展证据" 能否承载 evolution 决策层 | kernel **决策层接口缺口** | Q21-Q26 · 六条 · 分 A1-A4 + B1-B2 | A 4 条 + B 2 条（proposal 化打包 · `m6_evolution_kernel_alignment@v1`）|

**共同点**：四批全为 kernel **描述/契约层缺口**（非词表违规 §1.1）· 清理方向均为**新增/澄清/规格化**

**差异点**（§1.5 vs §1.4）：
- §1.4 路径 B 5 条（M5 范式首次 proposal 化打包 · `02/03/04` 三篇触达）· §1.5 路径 B 仅 2 条（**密度降低 60%** · 仅 `03/02` 两篇触达 · 不触达 `04/05`）
- §1.5 缺口总密度为 §1.4 的 **100%**（均为 6 条）· 但路径 B 密度为 §1.4 的 **40%**（2/5）· 路径 A 密度为 §1.4 的 **100%**（4/4）
- §1.5 首次引入 **"B1 走 draft 原地精化 / B2 走 published 小升" 的差异化 rev 策略**（M5 路径 B 统一走 published 小升或 draft 原地但未混合 · 本批首次按"目标篇当前 rev 状态"动态选择）
- §1.5 首次出现 **path A 全部单 commit 批量**（A1–A4 合并 `e6e18d5f` 一次 commit）· M5 路径 A 是分散在阶段 β draft 起稿内（2026-04-19 14:10 多次 commit）

**关键洞察**：M6 review 缺口密度仅为 M5 的 **~43%（6/14 若以 Q 编号计）** 或 **100%（6/6 若以 Q 条数计）**；路径 B 密度为 M5 的 **40%（2/5）**——两指标均显示"M1–M5 既有契约复用性"的红利。这与 `m6-evolution-draft-review §3.4` 与 M5 同场景对标表的"M6 缺口密度为 M5 的 43%"结论一致。

#### 1.5.4 路径执行总结（2026-04-19 21:34）

```
Q21-Q26（6 条缺口 → A1-A4 + B1-B2 六条消化路径）
  ├─ 路径 A（A1/A2/A3/A4）：06 @v1 draft 内部原地消化（2026-04-19 19:54）
  │     └─ 不升 rev · 按 01 §10.1 draft 可原地修订契约
  │     └─ 单 commit `e6e18d5f` 批量刷进（+18 行 · §2.3/§5.2/§6.7/§7.3 四处补齐）
  │
  ├─ 路径 B（B1/B2）：m6_evolution_kernel_alignment@v1 proposal 打包处置（2026-04-19 20:15–20:50）
  │     ├─ commit `1c106937` · proposal @v1 draft → published（S3）
  │     ├─ S0 · 预检（02 §2.2.4 注册区 `evolution.scan_result` 零冲突 · 2026-04-19 20:10 · 非 commit）
  │     ├─ S1 · B1：03 @v1 draft §3.1 原地精化（commit `76bbfff5` · 不升 rev）
  │     ├─ S2 · B2：02 @v1.3 → @v1.4 published（commit `7a7bce04`）
  │     └─ S4 · 反向对接：06 @v1 draft → @v1.1 draft 跟随升版（commit `44bf034b` · 8 处锚点同步 · schema 骨架不变）
  │
  ├─ S5+S6：m6-evolution-draft-review @v1 draft → @v1 published（2026-04-19 20:55 – 21:05）
  │     ├─ S5 · 追补 §5 路径 A/B 消化记录（四段式 review 第四段）
  │     └─ S6 · proposal.implemented 事件 + 三文档（03/02/06）wordcheck + IDE lint 全通过同 commit 批升
  │
  ├─ 工具链验证：piao-evolution-scan.sh MVP（待启动 · 预计 1-2 工作日 · ~200 行）
  │     └─ 对标 M5 piao-drift-compute.sh MVP 节奏 · 反证 R1-R5 五硬约束未被实施反例证伪
  │     └─ 06 @v1.1 draft → @v1.1 published 的门控 #2/#3 依赖此 MVP 反证
  │
  └─ M6 milestone 收官（2026-04-19 21:34）：
        ├─ _review/m6-evolution-kernel-alignment-proposal.md @v1 published（commit `1c106937`）
        ├─ _review/m6-evolution-draft-review.md @v1 published（S6 commit · 2026-04-19 21:05）
        ├─ _review/m6-final-decisions.md @v1 published（本 commit · 2026-04-19 21:34 · 对标 m5_final_decisions@v1 范式 · 决议 1-6 盖章 R1-R5 + 跨篇一致性 A1-A4/B1-B2 全 consumed · §8.6 决议 4/5 采保守组合 4-A 纯观测 + 5-A 终止于 scan_result）
        ├─ m6_evolution_kickoff @v1 status: published → superseded（本 commit 同批 · superseded_by 指向 m6_final_decisions@v1）
        └─ M1-debt-ledger @v6 → @v7（本 commit 同批 · 本文件）
```

所有 6 条缺口 + 6 条消化路径在本 rev 登记即闭环，**M6 evolution milestone 正式关闭**。

**M6 封板后的未决项**（不阻塞 milestone 封板 · 作为 M6 → M7 过渡期的工作项）：
- ⚠️ `06 @v1.1 draft → @v1.1 published`：依赖 `scripts/piao-evolution-scan.sh` MVP 产出至少 1 条真实 `evolution.scan_result` artifact（反证 R1–R5 未被实施反例证伪）+ 06 §8.2 门控 #2/#3 达成
- ⚠️ M7 extensibility milestone 起稿：待 06 published 后开 `m7_*_kickoff@v1` proposal（接力范式：post-m1-kickoff → m4_snapshot_kickoff → m5_drift_kickoff → m6_evolution_kickoff → m7_*_kickoff）

---

### 1.6 M6 遗留项收敛（2 条 · v8 新增 · Q27 consumed + Q28 continued）

> **入库依据**：M6 @v1.1 published 封版 22:40 时 06 §11 + §8.2 清单第 8 项字面留下 "**待发射** `artifact.published` L1 事件" 占位 · 属 M6 milestone 已封板但**工具链侧独立动作未完成**的显式遗留 · 在 2026-04-19 23:17 本次收敛行动中一次性补发 14 条 kernel spec 历史 published 事件到 journal · 并在补发过程中暴露出前缀字面规约冲突（`snap-published-*` vs `task-*`）作为 Q28 登记。
>
> **登记 + 消费分轮**：Q27 在本 v8 升版当下即标 consumed（补发已落盘 · journal 可验证）· Q28 标 continued-to-M7（前缀字面规约冲突需 kernel 层级决议 · 涉及 `01 §5` 事件域规约是否显式接纳 spec 专用前缀 / 或统一走 task 域 · 宜在 M7 extensibility milestone 起稿期间一并裁定）。

#### 1.6.1 Q27–Q28 两条遗留项

| 编号 | 来源 | 严重性 | kernel 缺口 / 行动 | 路径 | 状态 / 证据 |
|------|-----|--------|------------------|-----|-----------|
| [Q27] | `06 §11` @v1.1 published 封版字面 + `§8.2` 清单第 8 项 "⏳ 发射 artifact.published L1 事件" 占位 · 追溯发现 kernel spec **全部 7 份** 自 M1 定稿起 **无一条 `artifact.published` 事件** 落盘 · 违反 `01 §10` "artifact 状态变更必须通过 L1 事件宣告"契约 · kernel 在 journal 观测面整体不可见 | **高**（kernel 自身在事件本体空白 · 下游 evolution-scan / snapshot / drift 工具链查 kernel 时序均返回 unknown） | 补发 14 条历史 `artifact.published` 事件（01×3 + 02×5 + 04×2 + 05×1 + 06×1 + 07×2）· 全部标 `reconstructed: true` + `reconstructed_at` + `reconstructed_from` · 最终 rev 附真 `content_sha256`（01@v1.2 / 02@v1.4 / 04@v1.2 / 05@v1.1 / 06@v1.1 / 07@v1.1 六条）· 中间 rev `content_sha256: null` + `content_sha256_note: "historical_untraceable · 中间 rev 字节已被后续覆盖 · 仅 urn + published_at 可信"`（八条）· 落盘路径 `pipeline-output/piao/kernel-events/2026-04.jsonl`（不合并到 `mvp-smoke/events/2026-04.jsonl` · 因语义隔离：mvp-smoke 是 evolution-scan MVP 产出 · kernel-events 是 kernel spec 自身发布事件 · 前者 `producer_task_urn=agent:piao-evolution-scan` · 后者 `producer_task_urn=urn:piao:task:kernel:m{1–7}_*_publish`）· 03 仍为 draft 不纳入补发（首版从未 published） | **✅ consumed** · `pipeline-output/piao/kernel-events/2026-04.jsonl`（14 条 · 按 `published_at` UTC 升序 · 同秒按 urn 字典序 · 字段字母序对齐 `01 §5` event_id 规约 + `03 §3.2` L1 事件通用骨架）· `06 §11` + §8.2 字面已由 `2026-04-19 23:17` 追认事件 `event_id: task-260419144000-86e9a2` 闭合 · `_review/m6-debt-consumption.md @v1 published` 详述本次收敛路径 |
| [Q28] | Q27 补发过程暴露 · `06 §11` + `05 §2.3`/`§9 Q3` 原稿字面约定 spec published 事件 `event_id` 前缀为 `snap-published-*`（类比 M5 drift artifact 范式）· 但 `01 §5` 顶层事件域规约明列 `artifact.*` 事件归入 `task` 域（前缀 `task-*`）· 两处字面冲突 · 本次补发按 `01 §5` 顶层规约走 `task-*`（kernel 层顶层规约优先） | 中（仅字面冲突 · 不影响事件语义 · 但未来工具链按 `grep snap-published-*` 扫 kernel spec published 将查无此事 · 按 `grep task-*` 扫可正确命中 · 对齐 `01 §5` 表） | **选项 A**：追认 01 §5 为唯一真源 · 06 §11 / 05 §2.3 字面勘误为"本应按 `task-*` 规约 · 原文类比 M5 drift 修辞失准"（已在 06 §11 补注 · 05 §2.3 待处理）· **选项 B**：扩展 01 §5 事件域表 · 为 spec published 增设专用前缀 `snap-published-*` · 让 05 §2.3 / 06 §11 原文字面合法化 · 但需权衡"task 域下 artifact 子类是否必须统一前缀"与"grep 友好性分化"· **选项 C**：维持现状不裁定 · 仅要求发布工具侧同时索引两种前缀（向后兼容代价）· 选 A 对齐 kernel 层规约一致性原则 · 选 B 对齐"spec 自身作为特殊 artifact 类应享专用身份"原则 · 选 C 是工具侧救火 | ⏸ **continued-to-M7**（字面冲突已登记 · 实际裁定延期至 M7 extensibility milestone 起稿期间 · 届时可一并评估 `01 §5` 事件域表是否需要 M7 级扩展 · 与 `M7 kickoff proposal §4 必答问题` 合并处置 · 本次 Q27 补发按 `01 §5` 顶层规约走 `task-*` 仅作**权宜落盘**· 不构成对 Q28 的默认裁定） |

#### 1.6.2 通用契约：kernel spec rev 转换必须同步发射 `artifact.published`（CONV-01）

> **本次收敛在登记 Q27 的同时建立如下通用契约 · 适用于未来所有 kernel spec / adapter spec / 业务 artifact 的 rev 升降：**

| 契约编号 | 契约文字 | 适用范围 | 强制性 |
|---------|--------|---------|-------|
| **CONV-01** | 任何 `kind=spec` 或 `kind=artifact` 的资产在 **首版 published / 同 rev `draft→published` 转换 / 已 published 态下 `rev_N → rev_N+k` 小升或大升**三种场景下 · **必须**在同 txn（或承诺的独立但有界时间窗 · 默认 1 工作日内）发射 `artifact.published` L1 事件到对应 journal · 事件字段遵循 `01 §5` + `03 §3.2` 规约 · `subject` = 新 rev 的完整 URN · `content_sha256` = 新 rev 规范化后字节 sha256（遵循 `04 §3.2.1` + `04 §3.2.3` 规约）| kernel spec · adapter spec · 业务 artifact（snapshot / drift / evolution.scan_result / lineage 等派生类型同理） | **强制**（违约视为"状态变更在观测面不存在"· 下游工具查询时返回 unknown · 且资产本身视为"未正式发布"即便文件落盘）|
| **CONV-01-EX1** | 允许"独立事件写入步骤"延迟发射 · 但须在资产 front-matter `produced_by.event_id` 字段**预占**事件 id（遵循 `02 §4.3` + `04 §2.2` event_id 预留契约）· 预占字段值非 null 即视为承诺 · 超过有界时间窗未落盘视为违约 | 同 CONV-01 | 强制 |
| **CONV-01-EX2** | 资产为 `draft` 状态下的 **draft 内原地修订**（按 `01 §10.1` draft 允许原地契约）**不**发射 `artifact.published`（因为未转换到 published 态）· 内部修订仅记录 `last_modified_at` · 无 L1 事件义务 | 同 CONV-01 | 强制 |
| **CONV-01-EX3** | 资产为 `reconstructed=true` 的历史补发事件 · 其 `event_id` 时间戳段取**真实 published_at 的 UTC YYMMDDHHmmss**（而非追认时刻）· `emitted_at` 取追认时刻（UTC）· `published_at` 取真实 published 时刻（与 rev_history 表一致）· 三字段分工清晰 · 避免"追认事件伪装成实时事件"的证据污染 | 所有资产补发场景 | 强制 |

**首个实施案例**：本次 Q27 补发的 14 条事件 · 遵循 CONV-01 + CONV-01-EX3（reconstructed 分级标注 + 三时间字段分工）· 为所有未来资产补发建立**可复用范式**。

**未来触发点**（*v10 补注：Q28 已由 Q29 升级 + m7_prefix_taxonomy_decision@v1 裁定为选项 B'-1 · 以下三条触发点的 hypothetical 状态改为实际落地状态 · 原文保真*）：
- Q28 若裁定为选项 A，则 CONV-01 字面在 M7 封版时刷进 `01 §5` 作为**正式条款**（当前为 debt-ledger v8 §1.6.2 临时登记态）**· v10 实际裁定：采纳选项 B' 的升级版（Q29 B'-1）· 选项 A 淘汰 · CONV-01 由本 §1.6.2 主条款（位置不动）+ 新 CONV-01.1 子条款（见下方 v10 新增段）联合执行**
- 若裁定为选项 B，则 CONV-01 需对应扩展 · 支持 `artifact_type=spec.*` 的专用前缀声明 **· v10 实际裁定：采纳（Q29 B'-1 是本选项的精化版本）· CONV-01.1 建立 · 但具体机制不是"为 spec.* 加专用前缀"而是"kernel 封闭扩展 concern 维度"· 即 01 @v1.3 §5.1.1 二维表**
- Q28 continued-to-M7 期间 CONV-01 即作为**事实契约**执行 · `piao-evolution-scan.sh` / 未来工具 / agent 须按此执行 **· v10 实际落地：期间所有近实时发射事件（N1/N2/N3'/ledger v9 自指/M7 kickoff/decision v1/01 v1.3/本 ledger v10）均已按 CONV-01 主条款执行 · 共 8 次同 commit 发射 · 延迟 ≤95 min · 见 §1.8.3 压测表**

#### 1.6.2.1 CONV-01.1 前缀合法性子条款（*v10 新增 · 由 m7_prefix_taxonomy_decision@v1 建立*）

| ID | 字面 | 范围 | 强制性 |
|----|------|------|-------|
| **CONV-01.1** | 所有 L1 事件的 `event_id` 前缀段必须出现在 `01-identity-model @v1.3 §5 + §5.1.1 concern 预定义表` 中合法的 `{域, concern}` 组合内（单段式为"无 concern"的合法特殊情形）· 历史事件通过 `01 @v1.3 §5.3.1` 豁免条款兼容 · 不追溯回改 | 所有 L1 事件（kernel spec / adapter spec / 业务 artifact / journal 补发 / decision 等）| **强制**（违反视为工具侧产生"非法字面" · v0.2 阶段 `event_journal-append` 工具侧拒绝写入 · v0.1 阶段依赖人工 review + 本契约作为规约基线）|

**首个实施案例**：
- `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1` 自身发射的 `task-260419164500-17b2ca` 事件（task 三段式 · 无 concern · 合规）
- `urn:piao:spec:architecture:identity_model@v1.3` 升版事件 `task-260419165000-56845a`（task 三段式 · 合规）
- 本 ledger @v10 升版已发射的事件 `task-260419165500-0bc70e`（task 三段式 · 合规）

**CONV-01.1 与 CONV-01 分工**：

- **CONV-01（主）**：管"**什么时候**必须发射 `artifact.published`"（rev 转换三场景 + 三例外）
- **CONV-01.1（子）**：管"发射的事件 `event_id` **前缀字面**必须合法"（依赖 01 @v1.3 §5.1.1 二维表）

两者正交 · 不重叠。未来所有新事件必须同时满足 CONV-01 + CONV-01.1 + CONV-01-EX1/2/3。

**与 01 @v1.3 §5.3.1 分工**：

- **CONV-01.1（ledger 契约层）**：管**未来**事件的前缀合法性
- **01 @v1.3 §5.3.1（spec 规约层）**：管**历史**事件的字面兼容性

前者是规约性约束（应然）· 后者是历史事实兼容（实然）· 两者联合覆盖"所有前缀字面都有合法归属"的承诺。

#### 1.6.3 与 §1.2/§1.3/§1.4/§1.5 的关系

| 登记批次 | rev 升降 | 来源方 | 触发机制 | 缺口性质 | 修订数量 |
|---------|---------|--------|---------|---------|---------|
| §1.2 | v2→v3→v4 | adapter 侧 | adapter 写作卡点 | kernel 描述缺口 | Q1-Q7（7 条）|
| §1.3 | v4→v5 | kernel 侧（M4 draft） | kernel 新 draft 压测已有契约 | kernel 契约层描述缺口 | Q8-Q14（7 条）|
| §1.4 | v5→v6 | kernel 侧（M5 draft） | kernel 新 draft 引用姿势可完善 | kernel 跨篇一致性缺口 | Q15-Q20（6 条）+ R17-R25（9 条修订）|
| §1.5 | v6→v7 | kernel 侧（M6 draft） | kernel 新 draft 压测决策层接口 | kernel 决策层接口缺口 | Q21-Q26（6 条）+ A1-A4/B1-B2（6 条消化路径）|
| **§1.6** | **v7→v8** | **收敛侧（M6 milestone 已封板 · 补发遗留）** | **封板后工具链侧独立动作补齐 · journal 观测面裂缝暴露** | **kernel 自身在事件本体的可见性裂缝**（首次非 milestone 周期触发 · 首次建立 CONV-* 通用契约系列）| Q27-Q28（2 条）+ CONV-01（首条通用契约）|

**差异点**（§1.6 vs §1.2–§1.5 五批）：

- **首次非 milestone 周期触发**：前五批均在 milestone 封板时登记 + 消费 · §1.6 在 M6 封板**之后**的独立收敛行动中触发
- **首次建立 CONV-* 通用契约**：前五批均为"缺口→修订→落地"模式 · §1.6 首次从单点补发上升到"通用契约建立"（CONV-01）· 为所有未来资产的 rev 转换事件建立强制规范
- **首次使用 reconstructed 标志**：前五批均为实时 commit 触发即时事件 · §1.6 首次涉及追认历史事件 · 建立 reconstructed / reconstructed_at / reconstructed_from 三字段 + 三时间字段分工（emitted_at / published_at / reconstructed_at）范式
- **首次暴露"kernel 自身在事件本体空白"的系统级裂缝**：前五批关注 kernel 描述完整性 · §1.6 关注 kernel 在 journal 观测面的**存在性**—— 这是 piao 体系"事件即事实"本体论在 kernel 自指语义下的首次自洽性检验

#### 1.6.4 收敛执行总结（2026-04-19 23:17）

```
Q27-Q28（2 条遗留 · 1 条 consumed + 1 条 continued + 1 条通用契约 CONV-01）
  │
  ├─ 触发：06 @v1.1 published 封版（2026-04-19 22:40）时 §11 + §8.2 清单第 8 项字面"待发射"占位
  │
  ├─ 盘查：kernel 全部 7 份 spec 的 rev_history 表（01/02/04/05/06/07 各 rev · 03 仍 draft 不纳入）
  │     └─ 补发清单 14 条（01×3 + 02×5 + 04×2 + 05×1 + 06×1 + 07×2）
  │
  ├─ 构造：python3 可重现生成 · published_at CST→UTC 换算 · event_id 时间戳段取 UTC YYMMDDHHmmss · hash 段取 sha1(urn|published_at|rev) 前 6 位
  │     └─ 最终 rev 六条附真 content_sha256 · 中间 rev 八条 null + historical_untraceable 标注
  │
  ├─ 落盘：pipeline-output/piao/kernel-events/2026-04.jsonl（14 行 · 按 published_at UTC 升序 · 同秒按 urn 字典序 · JSON 字段字母序）
  │
  ├─ 06 §11 字面修订：
  │     ├─ §8.2 清单第 8 项从"⏳ 发射"改为"✅ 已发射 event_id task-260419144000-86e9a2"
  │     ├─ §11 本篇状态行从"待发射"改为"✅ 已发射 · reconstructed=true · 详见 _review/m6-debt-consumption.md"
  │     └─ 两处均补注前缀字面勘误（task-* 而非原稿 snap-published-*）· 引 Q28 续论
  │
  ├─ Q28 登记 continued-to-M7：
  │     └─ 三选项（A 追认 01 §5 / B 扩展 01 §5 / C 工具侧兼容）裁定延期至 M7 extensibility milestone 起稿
  │
  ├─ CONV-01 通用契约建立（§1.6.2）：
  │     └─ kernel spec / adapter spec / 业务 artifact rev 转换必须同步发射 artifact.published + 三例外
  │
  └─ M6-debt-consumption 报告（本批四 commit 之一）：
        ├─ _review/m6-debt-consumption.md @v1 published（收敛路径 + 14 条事件清单 + Q27/Q28 裁定记录 + CONV-01 首例）
        ├─ M1-debt-ledger @v7 → @v8（本文件 · §1.6 新增）
        ├─ pipeline-output/piao/kernel-events/2026-04.jsonl（14 条事件首版落盘）
        └─ 06-evolution-model.md §11 + §8.2 字面勘误（两处消除"待发射"占位 + 补注前缀字面勘误）
```

Q27 在本 rev 登记即闭环 · Q28 continued-to-M7 续论 · **M6 遗留项收敛完成**。

---

### 1.7 M6 扫尾续收敛（1 条 · v9 新增 · Q29 continued-to-M7）

> **入库依据**：v8 收敛完成后 · 在 CONV-01 EX1 指导下继续近实时发射三条 `artifact.published` 事件（N1/N2/N3'）· 落盘过程中发现 **Q28 的"前缀字面冲突"**远比 v8 登记时评估的严重 —— 不再是"两处字面冲突"（`01 §5` 的 `task-*` vs `06 §11` 的 `snap-published-*`）· 而是 **journal 落盘态事实已并存至少 4 种 event_id 前缀变体** · 三选项决议对象需升级为"分类系统缺口"而非"二元字面勘误"。
>
> **v9 定位**：Q29 作为 Q28 的升级版登记 · **不替换** Q28（§1.6 原文保真不动 · 保留 v8 收敛当下的真实证据语境）· 而是引 Q28 为历史前置 · 在 v9 新增一版包含 3 条落盘活证据的系统性描述 · 为 M7 的分类决议奠基。
>
> **登记 + 消费分轮**：Q29 登记即 continued-to-M7（本 rev 不触发新修订 · 仅登记证据升级）· 三条近实时发射事件（N1/N2/N3'）本身即 Q29 的活证据 · 无需附加 artifact。

#### 1.7.1 Q29 · event_id 前缀规约分化 meta 债

| 编号 | 来源 | 严重性 | kernel 缺口 / 行动 | 路径 | 状态 / 证据 |
|------|-----|--------|------------------|-----|-----------|
| [Q29] | Q28 v8 登记后 · 三批连续落盘事件暴露 **kernel 体系 journal 事实并存 ≥4 种 event_id 前缀变体** · 是 Q28"字面冲突"的本质升级（从"两处规约冲突"到"分类系统缺失"）· 四种变体具体为：① `task-*`（01 §5 顶层规约 · N1+N2 两条 + Q27 补发 14 条 · 共 16 条落盘）② `drift-triggered-*`（`piao-drift-compute.sh` MVP 产出 · mvp-smoke/events · 2 条）③ `evolution-scanned-*`（`piao-evolution-scan.sh` MVP 产出 · mvp-smoke/events · 2 条）④ `artifact-published-*`（smoke-report front-matter 预占 · N3' 保真补发 · 1 条） | **高**（从 Q28 的"中"升级 · 此前评估为字面冲突 · 现已事实形成分类系统缺口 · 工具链若按 `grep ^task-` 扫 kernel 可见事件将漏掉 5 条非 `task-*` 前缀事件 · 相当于 **23.8%** 事件在默认正则查询下不可见 · 基数 21 条 = 16 `task-*` + 2 `drift-triggered-*` + 2 `evolution-scanned-*` + 1 `artifact-published-*`）| **选项 A'**（原 Q28 选项 A 升级）：一律收敛到 `task-*` 域 · 要求 ② ③ ④ 三类变体在 M7 统一改名 · 代价是已落盘事件须追改 event_id 字面或加"alias"映射 · 且破坏 `piao-drift-compute.sh` / `piao-evolution-scan.sh` 与原 05 / 06 范式约定的对应性（它们是 spec 字面授权的域 · 改名等于否定 spec 字面权威） · **选项 B'**（原 Q28 选项 B 升级）：正式承认 event_id 前缀的"事件类型维度"· 扩展 `01 §5` 事件域表为二维：`event_domain × artifact_concern`（类似 ① task 域 / ② drift 域 / ③ evolution 域 / ④ 资产宣告域）· 每类前缀承担特定语义 · 工具链按"`domain` → `artifact_concern`"多维索引 · 这是与事实对齐的方案 · 但需要 M7 重新设计 `01 §5` 事件类型分类系统（预计 M7 决议 1-2 之一）· **选项 C'**（原 Q28 选项 C 升级）：保持现状 · 仅要求工具侧实现 prefix-agnostic 扫描（按 `event_type` 字段而非 `event_id` 前缀分流）· 该方案承认 event_id 前缀是"人类友好标识而非规约字段"· 所有工具侧查询依赖 `event_type` + `artifact_kind` + `producer_task_urn` 三元组 · **零 kernel 变更**但推翻了 `01 §5` 将 event_id 前缀作为"域分隔符"的原初设计意图 | ⏸ **continued-to-M7**（Q29 证据已备齐 · 三选项升级为 A'/B'/C' · 建议 M7 kickoff proposal §4 必答问题将其列为"决议 1 或 2"优先裁定项 · 理由：此条是 M7 extensibility 系统设计的**前置约束**· 不先裁定 Q29 · M7 的事件分类体系设计将缺少类型学基础） |

#### 1.7.2 Q29 活证据清单（3 条近实时发射事件）

| 事件 ID | 前缀变体 | 落盘 journal | 触发批次 | published_at | emitted_at | 证据说明 |
|--------|---------|------------|---------|-------------|-----------|---------|
| `task-260419151700-a9b94e` | ① `task-*` | `kernel-events/2026-04.jsonl` | N1 | 2026-04-19T15:17:00Z | 2026-04-19T15:55:00Z | consumption @v1 · reconstructed=false 首例 · 按 `01 §5` 顶层规约 |
| `task-260419151700-2121e1` | ① `task-*` | `kernel-events/2026-04.jsonl` | N2 | 2026-04-19T15:17:00Z | 2026-04-19T15:55:00Z | ledger @v8 · reconstructed=false · 自指发射（ledger 发射登记自己的事件）|
| `artifact-published-260419223000-rpt001` | ④ `artifact-published-*` | `kernel-events/2026-04.jsonl` | N3' | 2026-04-19T14:30:00Z | 2026-04-19T16:05:00Z | smoke-report @v1 · **保真前缀**（front-matter 预占 event_id 优先 · 不为统一性回改 sha256 触发循环回路）· 与前两条同 journal 但不同前缀 · 直接反证 `kernel-events/` journal 内部已事实并存至少两种前缀 |

**跨 journal 前缀分布**：

```
pipeline-output/piao/kernel-events/2026-04.jsonl（17 条 · M1 收敛主域）
  ├─ 16 条 task-*（Q27 补发 14 条 reconstructed=true + N1+N2 两条 reconstructed=false）
  └─  1 条 artifact-published-*（N3' smoke-report @v1 保真补发）

pipeline-output/piao/mvp-smoke/events/2026-04.jsonl（4 条 · MVP 冒烟域）
  ├─ 2 条 drift-triggered-*（piao-drift-compute.sh M5 MVP）
  └─ 2 条 evolution-scanned-*（piao-evolution-scan.sh M6 MVP）
```

#### 1.7.3 Q29 vs Q28 差异化对照

| 维度 | Q28（v8 登记态） | Q29（v9 升级态） |
|------|----------------|----------------|
| 缺口性质 | 字面冲突（两处规约分歧）| 分类系统缺失（事实 ≥4 种变体并存）|
| 严重性 | 中 | 高 |
| 证据数 | 0（仅规约文本对比）| 3 条活证据 + 5 条历史参照 |
| 选项对象 | 二元勘误（A/B/C 三选项 · 对象是"两处字面"）| 分类系统设计（A'/B'/C' 三选项 · 对象是"1+3 类前缀体系"）|
| M7 角色 | 可放到 M7 决议末位 | **应列为 M7 决议 1-2 优先裁定项**（前置约束）|
| 关闭条件 | 选项裁定 + 两处字面勘误 | 选项裁定 + `01 §5` 分类系统设计 + 全体 event_id 落盘前缀审计矩阵 |

**Q28 与 Q29 的关系**：Q28 保留为历史前置（§1.6.1 原文不动 · 保真 v8 收敛当下的评估语境）· Q29 是 Q28 的**真值升级**· 二者在 M7 一并裁定 · Q28 的选项 A/B/C 升级为 Q29 的选项 A'/B'/C'。

#### 1.7.4 与 §1.6 的关系（及对 CONV-01 的启示）

| 维度 | §1.6（v8）| §1.7（v9）|
|------|----------|----------|
| 触发节奏 | 封板后独立收敛 · 首次非 milestone 周期 | 收敛后扫尾续收敛 · **首次"收敛行动自身产出新缺口"**（meta 债发现链）|
| Q 编号 | Q27/Q28（同批 2 条）| Q29（独立 1 条 · 升级自 Q28）|
| 与 CONV-01 关系 | 建立 CONV-01 主条款 + EX1/EX2/EX3 三例外 | **压测 CONV-01 EX1**（N1+N2+N3' 三次近实时发射 · 全部 ≤38 分钟 · 远小于 EX1 承诺的 1 工作日 · 证实 EX1 在实际执行中可大幅压缩延迟窗）|
| 对 M7 kickoff 的影响 | Q28 作为 M7 必答 | Q29 升级为 M7 决议 1-2 优先 · 证据已预置 |

**CONV-01 压测成果**（v9 新增登记）：

- **N1**：consumption @v1 published @ 23:17 CST → artifact.published 发射 @ 23:55 CST · 延迟 **38 分钟**
- **N2**：ledger @v8 published @ 23:17 CST → artifact.published 发射 @ 23:55 CST · 延迟 **38 分钟**
- **N3'**：smoke-report @v1 published @ 22:30 CST（2026-04-19）→ artifact.published 发射 @ 00:05 CST（2026-04-20）· 延迟 **95 分钟**
- 三次发射全部 ≤ **2 小时** · 证实 CONV-01 EX1 的"1 工作日（8h）"承诺窗在实际执行中仅占用了 **≤25%**
- **启示**：M7 可考虑在 CONV-01 EX1 中加严承诺窗 · 例如"1 工作日"改为"2 小时内" · 但需权衡"自动化工具缺位时的 agent 负担"

#### 1.7.5 收敛执行总结（2026-04-20 00:10）

```
Q29（1 条新登记 · continued-to-M7 · 升级自 Q28）
  │
  ├─ 触发：N1+N2+N3' 三次近实时发射过程中落盘证据暴露
  │     ├─ N1+N2 commit 216d6c1d（2026-04-19 23:55 发射 · kernel-events 14→16 行）
  │     └─ N3' commit <v9 升版同批>（2026-04-20 00:05 发射 · kernel-events 16→17 行 · 保真 artifact-published-* 前缀）
  │
  ├─ 发现：kernel 体系 journal 已事实并存 4 种 event_id 前缀变体（共 21 条活事件）
  │     ├─ task-*（16 条 · 主流 · 01 §5 顶层规约）
  │     ├─ drift-triggered-*（2 条 · 05 spec 字面授权域）
  │     ├─ evolution-scanned-*（2 条 · 06 spec 字面授权域）
  │     └─ artifact-published-*（1 条 · smoke-report front-matter 预占）
  │
  ├─ 升级：Q28 三选项（A/B/C 字面勘误层面）→ Q29 三选项（A'/B'/C' 分类系统层面）
  │     └─ 严重性 中 → 高 · M7 角色 末位 → 优先裁定项
  │
  ├─ 压测：CONV-01 EX1 在 N1/N2/N3' 三次发射中延迟 ≤95 分钟 · 远小于承诺 8 小时
  │     └─ M7 可考虑加严承诺窗
  │
  └─ 本次 v9 升版产物（单 commit 批）：
        ├─ M1-debt-ledger @v8 → @v9（本文件 · §1.7 新增 + §1.6 原文保真）
        └─ pipeline-output/piao/kernel-events/2026-04.jsonl（已在 commit 216d6c1d + N3' 批次追加 · 共 17 行）
```

Q29 登记即 continued-to-M7 · **M6 扫尾续收敛完成 · M7 kickoff 具备前置条件**。

---

### 1.8 M7 工作流 P 阶段 γ₁ 收官（1 条裁定 · v10 新增 · Q29 consumed-via-m7-decision）

> **入库依据**：v9 登记 Q29 continued-to-M7 后 · M7 `m7_closeout_kickoff@v1 published`（2026-04-20 00:30）启动工作流 P · 阶段 γ₁ 于 00:45 由 `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1 published` 完成裁定 —— 选定 **选项 B'-1（严格二维扩展）** · 01 @v1.2 → @v1.3 于 00:50 published 落地决议 · 本 ledger @v10 承接记录。
>
> **v10 定位**：Q29 状态从 ⏸ `continued-to-M7` 转为 ✅ `consumed-via-m7-decision` · **不替换** §1.7 原文（§1.7 保真作为 v9 登记当下的真实证据语境）· 而是 §1.8 记载裁定结果 + 落地指令清单 + CONV-01.1 契约建立 + 压测汇总。
>
> **本 rev 扫尾要点**：
> - Q29 由 m7_prefix_taxonomy_decision @v1 裁定 B'-1（§1.8.1 摘要）
> - CONV-01.1 子条款建立（§1.6.2.1 · 前缀合法性约束）
> - Q28 续论三条 hypothetical 触发点落地状态标注（§1.6.2 补注）
> - 01 @v1.3 §5.1.1 concern 二维表 + §5.3.1 历史兼容条款（决议文本详见 m7_prefix_taxonomy_decision @v1 §3.2）
> - CONV-01 EX1 第三阶段压测 7 次同 commit 发射均延迟=0（§1.8.3）

#### 1.8.1 Q29 裁定摘要（consumed-via-m7-decision）

| 项目 | 原 v9 登记值 | v10 裁定后值 | 依据 |
|------|-------------|-------------|------|
| Q29 状态 | ⏸ continued-to-M7 | ✅ **consumed-via-m7-decision** | `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1` published |
| 选项 A' / B' / C' | 三选项并列待裁 | **选定 B' 子路径 B'-1**（严格二维扩展）· A'/C' 淘汰 | decision @v1 §2 三条硬证据 3/3 打分 |
| 已落盘 5 条非 `task-*` 事件处置 | 待定 | **不改 · 由 01 @v1.3 §5.3.1 历史兼容条款追认** | decision @v1 §2.1 第 4 点 |
| 05 / 06 published spec 字面 | 待定（v10 前未动）| **不改** · `drift-triggered-*` / `evolution-scanned-*` 在新 01 §5 下合法 | decision @v1 §4 升版矩阵 |
| 07 @v1.1 published | 待定（可能升版）| **不升版**（kernel 内部扩展 · 不破坏边界 2）| decision @v1 §4 + §7 Q-X1 预答 |
| 升版范围 | 预期 01 @v1.3 必升 · 其他待定 | **仅 01 @v1.3 + ledger @v10 + decision @v1** | decision @v1 §3.1 L1-L11 指令矩阵 |
| CONV-01 契约范围 | 主条款 + 3 例外 | **扩展为主条款 + CONV-01.1 + 3 例外** | 本 ledger §1.6.2.1 v10 新增 |

**Q29 关闭条件对账**（来自 m7 kickoff §2.2 + decision @v1 §5）：

- [x] `_review/m7-prefix-taxonomy-decision.md @v1 published` · §1 三选项对比矩阵齐全 · §2.2 三条硬证据支撑
- [x] CONV-01 扩展裁定明确（CONV-01.1 子条款建立 · 见 §1.6.2.1）
- [x] 对已落盘 5 条非 `task-*` 事件的处置路径明确（不改 · §5.3.1 追认）
- [x] 01 §5 表升级草稿已在 decision @v1 §3.2 产出 · 并在 01 @v1.3 正式落地
- [x] decision @v1 自身 `artifact.published` L1 事件已同 txn 发射（`task-260419164500-17b2ca` · kernel-events 第 20 行）
- [x] 01 @v1.3 升版事件已发射（`task-260419165000-56845a` · kernel-events 第 21 行）
- [x] 本 ledger @v10 升版事件已同 commit 发射（`task-260419165500-0bc70e` · kernel-events 第 22 行）

**8/8 全通过 · Q29 正式标记 consumed-via-m7-decision。**

#### 1.8.2 B'-1 落地清单

| # | 动作 | 目标资产 | 状态 | 落地 commit |
|---|------|---------|------|------------|
| L1 | 01 §5 扩展为二维分类（段数约定 + 示例新增）| `01-identity-model @v1.2 → @v1.3` | ✅ 已 published | `2ea5a49e`（批次 2）|
| L2 | 01 §5.1.1 新增 concern 预定义表 | 同上 | ✅ 已 published | 同上 |
| L3 | 01 §5.3.1 新增历史兼容条款 | 同上 | ✅ 已 published | 同上 |
| L4 | M1-debt-ledger §1.7.1 Q29 标注 consumed | `@v9 → @v10` | ✅ 本批次（§1.8.1 表 + 本清单）| 本 commit（批次 3）|
| L5 | CONV-01 扩展为 CONV-01.1 | ledger §1.6.2.1（v10 新增）| ✅ 本批次 | 本 commit |
| L6 | 03 §3.2 L1 事件骨架可选加 `concern` 字段 | `03-event-model @v1 draft` | ⏸ 推迟到 03 published 时决定 | - |
| L7 | 07 @v1.1 published | - | ✅ 不动 | - |
| L8 | 05 @v1.1 + 06 @v1.1 published | - | ✅ 不动 | - |
| L9 | 已落盘 5 条非 `task-*` 事件 | - | ✅ 不改（§5.3.1 豁免）| - |
| L10 | `piao-drift-compute.sh` / `piao-evolution-scan.sh` | - | ✅ 不改（字面仍合法）| - |
| L11 | 本决议自身 artifact.published 事件 | `kernel-events/2026-04.jsonl` | ✅ 已发射 | `862774bb`（批次 1）|

**B'-1 落地 commit 批次**（3 commit 共计）：

- **批次 1**（commit `862774bb`）· 2026-04-20 00:45：m7-prefix-taxonomy-decision @v1 published + 自指事件（延迟=0）
- **批次 2**（commit `2ea5a49e`）· 2026-04-20 00:50：01 @v1.2 → @v1.3 published + 升版事件（延迟=0）
- **批次 3**（本 commit）· 2026-04-20 00:55：M1-debt-ledger @v9 → @v10 published + 本 ledger 升版事件（延迟=0）

#### 1.8.3 CONV-01 EX1 第三阶段压测汇总（延迟表持续更新）

> v9 §1.7.4 已记录 N1/N2/N3' 三次压测 · v10 继续累积 M7 阶段 4 次 · 合计 7 次同 commit 发射实操数据 + 1 次异步（N3' 95min）· 共 8 次。

| 批次 | published_at | emitted_at | 延迟 | 场景 | 所属 rev |
|------|-------------|-----------|------|------|---------|
| N1 · consumption@v1 | 2026-04-19T15:17:00Z | 2026-04-19T15:55:00Z | 38 min | `CONV-01 EX1` 首次 · reconstructed=false 首例 | v8→v9 |
| N2 · ledger@v8 自指 | 2026-04-19T15:17:00Z | 2026-04-19T15:55:00Z | 38 min | 自指发射 · 与 N1 同 commit | v8→v9 |
| N3' · smoke-report@v1 | 2026-04-19T14:30:00Z | 2026-04-19T16:05:00Z | 95 min | 保真前缀补发 · 异步单独 commit | v9 新增 |
| ledger v9 自指 | 2026-04-19T16:10:00Z | 2026-04-19T16:12:00Z | 2 min | v9 升版同批发射 · 首次验证同 commit 同 txn 方案 | v9 收尾 |
| M7 kickoff @v1 | 2026-04-19T16:30:00Z | 2026-04-19T16:30:00Z | **0 min** | 同 commit 发射路径 · 首次做到"延迟=0" | v9→M7 |
| decision @v1 | 2026-04-19T16:45:00Z | 2026-04-19T16:45:00Z | **0 min** | 阶段 γ₁ 核心产出 | v9→v10 |
| 01 @v1.3 升版 | 2026-04-19T16:50:00Z | 2026-04-19T16:50:00Z | **0 min** | decision 落地批次 2 | v9→v10 |
| ledger @v10 升版 | 2026-04-19T16:55:00Z | 2026-04-19T16:55:00Z | **0 min** | decision 落地批次 3 · 本 rev · event_id `task-260419165500-0bc70e` | v9→v10 |

**统计**（共 8 次）：

| 延迟区间 | 次数 | 占比 |
|---------|------|------|
| 0 min（同 commit 同 txn）| **4 次** | **50%** |
| ≤10 min | **1 次** | 12.5% |
| 10-60 min | 2 次 | 25% |
| 60-120 min | 1 次 | 12.5% |
| >8h（CONV-01 EX1 承诺窗）| **0 次** | 0% |

**结论**（为 v0.1 Closeout 阶段 γ₃ 提供数据）：

1. 8 次发射全部 ≤ **1 工作日**（CONV-01 EX1 承诺窗 8h = 480 min）· 最大延迟 95 min 远低于承诺
2. 同 commit 同 txn 方案（延迟=0）在 M7 阶段已成为 **常规模式**（4/8 = 50%）· 建议 v0.1 final-decisions 将 CONV-01 EX1 承诺窗从"1 工作日"加严到"2 小时"
3. 工具侧（未来 `event_journal-append` 带 txn 保证）可把 CONV-01 EX1 承诺窗进一步加严到"毫秒级"· v0.2 milestone 可追
4. CONV-01 EX1 在 M7 阶段未出现违约 · 契约**压测通过**

#### 1.8.4 收敛执行总结（2026-04-20 00:55）

```
Q29（1 条 ⏸ → ✅ · 裁定 B'-1）
  │
  ├─ 触发：m7_closeout_kickoff @v1（2026-04-20 00:30）启动工作流 P 阶段 γ₁
  │
  ├─ 裁定：m7_prefix_taxonomy_decision @v1 @ 00:45 published
  │     ├─ 选定 B' 子路径 B'-1（严格二维扩展）· A'/C' 淘汰
  │     ├─ 三条硬证据支撑（事实对齐 / spec 权威 / 07 封闭性）
  │     ├─ self-review 签收 8/8
  │     └─ event_id: task-260419164500-17b2ca · kernel-events 20 行
  │
  ├─ 落地批次 2：01 @v1.2 → @v1.3 published @ 00:50
  │     ├─ §5 扩展四段式（{域}[-{concern}]-{时间戳}-{hash}）
  │     ├─ §5.1.1 concern 预定义表（kernel 封闭 · 7 对初始组合）
  │     ├─ §5.3.1 历史兼容条款（2 条 evolution-scanned-* + 1 条 artifact-published-* 豁免）
  │     └─ event_id: task-260419165000-56845a · kernel-events 21 行
  │
  ├─ 落地批次 3（本 rev）：M1-debt-ledger @v9 → @v10 published @ 00:55
  │     ├─ §1.7 原文保真不动
  │     ├─ §1.7.1 Q29 状态转 consumed-via-m7-decision（§1.8.1 裁定摘要）
  │     ├─ §1.6.2 "未来触发点"三条 hypothetical 标注 v10 实际裁定结果
  │     ├─ §1.6.2.1 CONV-01.1 子条款建立
  │     ├─ §1.8 新增本章节（B'-1 落地清单 + 压测汇总）
  │     └─ event_id: task-260419165500-0bc70e · kernel-events 22 行（已发射）
  │
  ├─ 压测：CONV-01 EX1 在 M7 阶段 4 次同 commit 发射延迟=0（§1.8.3）· 累计 8 次发射无违约
  │     └─ 建议 v0.1 final-decisions 将 EX1 承诺窗加严到"2 小时"
  │
  └─ 本次 v10 升版产物（单 commit 批）：
        ├─ M1-debt-ledger @v9 → @v10（本文件）
        └─ pipeline-output/piao/kernel-events/2026-04.jsonl（追加 1 行 · 22 行）
```

Q29 由 continued-to-M7（v9）→ consumed-via-m7-decision（v10）· **M7 工作流 P 阶段 γ₁ 正式收官** · 阶段 γ₂（工作流 X）入口条件已满足 · **Q-X1/Q-X2/Q-X4 三问已由本次决议间接预答**（见 m7 kickoff §7）· 阶段 γ₂ 负担从 5 问减至 2 问（Q-X3/Q-X5）。

---


## 2. 启发式改进记录（扫描器本身的演进）

M1 收尾过程中，`kernel-wordcheck.sh` 的豁免启发式迭代了一版：

| 版本 | 反引号豁免逻辑 | 问题 |
|------|--------------|------|
| v0.1 初版 | 命中词**恰好**被反引号包裹（如 `\`kotlin\``） | 无法豁免形如 `\`kotlin-coding-standards.md\`` 的 inline code —— 反引号之间不是裸词 |
| v0.1 修订版 | 用 awk 把命中行内所有成对反引号内容**剥离**后，判断命中词是否仍出现；若不再出现 → 全部 mention，豁免 | 正确处理 inline code 内的任意位置命中 |

**版本标记**：本账本**引用的基线结果**来自修订版启发式的扫描。

---

## 3. 关闭条件

本账本在满足以下所有条件后可发 `evolution_source.consumed` 事件归档：

- [ ] §1.1 六条违规清零（阶段 3 `02-artifact-model.md@v2` 处理）
- [x] §1.2 **七条** kernel 缺口中 **6 条（Q1/Q2/Q3/Q5/Q6/Q7）已 consumed**，各自落位到 kernel 三文档 @v1.1 对应章节（见 §1.2 表格"状态"列）
- [ ] §1.2 Q4（`00-overview.md:93` 的 `viewmodel` WARN）延期至阶段 3，与 §1.1 合并清理
- [x] §1.3 **七条** kernel 缺口全部 consumed（Q8-Q14，M4 milestone 收官时一次性登记 + 消费；见 §1.3 表格）
- [x] §1.4 **六条** kernel 缺口全部 consumed（Q15-Q20，M5 drift milestone 收官时一次性登记 + 消费 · 对应 R17-R25 九条修订落地矩阵；见 §1.4 表格 · v6 新增）
- [x] §1.5 **六条** kernel 缺口全部 consumed（Q21-Q26，M6 evolution milestone 收官时一次性登记 + 消费 · 对应 A1-A4/B1-B2 六条消化路径矩阵；见 §1.5 表格 · v7 新增）
- [x] §1.6 **Q27 consumed**（kernel spec published 事件 journal 可见性债 · 14 条历史 rev 一次性补发落盘 · 见 §1.6 表格 + `pipeline-output/piao/kernel-events/2026-04.jsonl` · v8 新增）· Q28 continued-to-M7（前缀字面规约冲突 · 延期至 M7 裁定）· **CONV-01 首条通用契约已建立**（§1.6.2）
- [x] §1.7 **Q29 登记**（event_id 前缀分类系统缺失 meta 债 · Q28 升级为 Q29 · 3 条活证据落盘 · 见 §1.7.2 表格 · v9 新增）· continued-to-M7（建议列 M7 决议 1-2 优先裁定项）· **CONV-01 EX1 已压测**（三次发射延迟 ≤95 分钟 · 远小于承诺 8 小时）
- [x] **§1.8 Q29 consumed-via-m7-decision**（M7 工作流 P 阶段 γ₁ 收官 · m7_prefix_taxonomy_decision @v1 裁定选项 B'-1 严格二维扩展 · 01 @v1.2 → @v1.3 published 落地 · CONV-01.1 子条款建立 · 见 §1.8.1 裁定摘要 + §1.8.2 L1-L11 落地清单 · v10 新增）· **CONV-01 EX1 第三阶段压测完成**（M7 阶段 4 次同 commit 发射延迟=0 · 累计 8 次发射无违约 · 见 §1.8.3）
- [ ] `./scripts/kernel-wordcheck.sh --ci` 在 `docs/piao-pipeline/kernel/` 下返回退出码 0（阶段 3 目标）
- [ ] M2 迭代产出 `docs/piao-pipeline/adapters/<adapter_name>/` 且本账本提到的业务示例已迁移过去
- [ ] 本账本 front-matter 的 `status` 从 `published` 变更为 `consumed`，并在 `urn:piao:snapshot:kernel:m2_final_decisions@v1` 中引用

> **当前进度**：`§1.2 consumed 6/7` + `§1.3 consumed 7/7` + `§1.4 consumed 6/6（含 R17-R25 九条修订）` + `§1.5 consumed 6/6（含 A1-A4/B1-B2 六条消化路径）` + `§1.6 consumed 1/2（Q27 ✅ · Q28 升级为 Q29）+ CONV-01 已建立` + `§1.7 registered 1/1（Q29 continued-to-M7）+ CONV-01 EX1 已压测` + `§1.8 consumed-via-m7-decision 1/1（Q29 裁定 B'-1）+ CONV-01.1 已建立 + EX1 第三阶段压测完成` + `§1.1 consumed 0/6`。账本**尚未**全部关闭，但 **M6 evolution milestone 闭环 + M6 遗留项收敛 + M6 扫尾续收敛 + M7 工作流 P 阶段 γ₁ 全部完成**——kernel 契约层对 evolution 决策层的描述能力已完整 · kernel 自身在 journal 观测面的可见性已补齐 · Q29 前缀分类系统已由 B'-1 落地（01 @v1.3 §5.1.1 二维表 · CONV-01.1 前缀合法性约束）· 阶段 γ₂（工作流 X · 07 Extensibility 宪章压测）入口条件已满足 · **Q-X1/Q-X2/Q-X4 三问已由本次决议间接预答**· 阶段 γ₂ 负担从 5 问减至 2 问。

---

**本账本状态**：published · rev v10（2026-04-20 00:55）
**上游锚点**：`urn:piao:snapshot:kernel:m1_final_decisions@v1` · 决议 4；`urn:piao:snapshot:kernel:m4_final_decisions@v1` · 决议 5；`urn:piao:snapshot:kernel:m5_final_decisions@v1` · 决议 1-6 + §3 R17-R25 落地矩阵；`urn:piao:snapshot:kernel:m6_final_decisions@v1` · 决议 1-6 + §6 跨篇一致性 A1-A4/B1-B2 矩阵；`urn:piao:artifact:kernel:m6_debt_consumption@v1` · Q27 补发 14 条历史事件 + Q28 前缀冲突登记 + CONV-01 通用契约；`urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1` · Q29 裁定 B'-1（严格二维扩展）+ L1-L11 落地指令矩阵；`urn:piao:spec:architecture:identity_model@v1.3` · §5 二维分类 + §5.1.1 concern 预定义表 + §5.3.1 历史兼容条款（B'-1 落地证据）；`urn:piao:journal:kernel:kernel_events@2026-04`（22 行活证据 · 其中 21 条 `task-*` + 1 条 `artifact-published-*`）· `urn:piao:journal:kernel:mvp_smoke_events@2026-04`（4 行活证据 · 2 条 `drift-triggered-*` + 2 条 `evolution-scanned-*`）· 两侧 journal 并列为 Q29 升级依据 + B'-1 裁定事实基线
**演进触发**：
- rev v1→v2：`urn:piao:artifact:adapter/frontend_migration:charter_review@v1` §2 产出 4 条 kernel 缺口（Q1-Q4）
- rev v2→v3：`urn:piao:artifact:adapter/frontend_migration:task_types_review@v1` §2 产出 3 条 kernel 缺口（Q5-Q7）
- rev v3→v4：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` 路径 A 执行完成，§1.2 Q1/Q2/Q3/Q5/Q6/Q7 六条 consumed
- rev v4→v5：`urn:piao:snapshot:kernel:m4_final_decisions@v1` M4 milestone 收官，§1.3 新增 Q8-Q14 七条 kernel 缺口登记并全部 consumed（证据矩阵见 §1.3 表格）
- rev v5→v6：`urn:piao:snapshot:kernel:m5_final_decisions@v1` M5 drift milestone 收官，§1.4 新增 Q15-Q20 六条 kernel 缺口 + R17-R25 九条修订落地矩阵，全部 consumed（证据矩阵见 §1.4 表格 · 路径 A 四条 draft 内原地 + 路径 B 五条外篇升降 · 工具链侧 `piao-drift-compute.sh` MVP 反证 R1-R5 未被证伪）
- rev v6→v7：`urn:piao:snapshot:kernel:m6_final_decisions@v1` M6 evolution milestone 收官，§1.5 新增 Q21-Q26 六条 kernel 缺口 + A1-A4/B1-B2 六条消化路径矩阵，全部 consumed（证据矩阵见 §1.5 表格 · 路径 A 四条 06 @v1 draft 内原地 · commit `e6e18d5f` · 路径 B 两条差异化 rev 策略 · B1 走 03 @v1 draft 原地精化 commit `76bbfff5` · B2 走 02 @v1.3 → @v1.4 published commit `7a7bce04` · 06 跟随升版 @v1 draft → @v1.1 draft commit `44bf034b` · 工具链侧 `piao-evolution-scan.sh` MVP 待启动反证 R1-R5 未被证伪）
- rev v7→v8：`urn:piao:artifact:kernel:m6_debt_consumption@v1` M6 遗留项收敛，§1.6 新增 Q27（kernel spec published 事件 journal 可见性债 · 14 条历史 rev 补发落盘 `pipeline-output/piao/kernel-events/2026-04.jsonl` · reconstructed=true + 最终 rev 真 sha256 / 中间 rev historical_untraceable 分级标注 · 06 §11 + §8.2 字面从"待发射"改为"已发射 event_id task-260419144000-86e9a2"）· Q28 登记 continued-to-M7（前缀字面规约冲突 snap-published-* vs task-* · 三选项裁定延期至 M7 extensibility milestone 起稿）· **CONV-01 首条通用契约建立**（§1.6.2 · kernel spec / adapter spec / 业务 artifact rev 转换必须同步发射 artifact.published · 三例外 EX1/EX2/EX3）· **首次非 milestone 周期触发 · 首次建立 CONV-* 通用契约系列 · 首次使用 reconstructed 标志 · 首次暴露 kernel 自身事件本体可见性裂缝**
- rev v8→v9：`urn:piao:journal:kernel:kernel_events@2026-04`（落盘至 17 行）+ `urn:piao:journal:kernel:mvp_smoke_events@2026-04`（4 行）两侧 journal 事实并存 M6 扫尾续收敛 · §1.7 新增 Q29（event_id 前缀分类系统缺失 meta 债 · Q28 升级）· N1+N2 近实时发射 consumption@v1 + ledger@v8（commit `216d6c1d` · 2 行追加 · reconstructed=false 首次）· N3' 保真补发 smoke-report@v1（前缀 artifact-published-* 保真于 front-matter 预占 · 1 行追加）· Q29 证据升级为 3 条活事件 + 5 条历史参照 · 选项 A'/B'/C' 升级自 Q28 A/B/C（从字面勘误到分类系统层面）· **CONV-01 EX1 已压测**（N1/N2/N3' 三次发射延迟 ≤95 分钟 · 远小于承诺 8 小时 · M7 可考虑加严承诺窗）· **首次"收敛行动自身产出新缺口"**（meta 债发现链）
- rev v9→v10：`urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1` M7 工作流 P 阶段 γ₁ 收官 · Q29 裁定选项 **B'-1（严格二维扩展）** · A'/C' 淘汰 · `urn:piao:spec:architecture:identity_model@v1.3` published 落地决议（§5 扩展为四段式可选 {域}[-{concern}]-{时间戳}-{hash} · §5.1.1 concern 预定义表 7 对初始组合 · §5.3.1 历史兼容条款豁免已落盘 5 条非 task-* 事件）· §1.8 新增 v10 收尾章节（§1.8.1 Q29 裁定摘要 8/8 关闭条件对账 + §1.8.2 L1-L11 落地清单 + §1.8.3 CONV-01 EX1 第三阶段压测汇总 · M7 阶段 4 次同 commit 发射延迟=0 / 累计 8 次发射无违约 · 建议 v0.1 final-decisions 将 EX1 承诺窗从"1 工作日"加严到"2 小时"）· §1.6.2 Q28"未来触发点"三条 hypothetical 标注 v10 实际裁定状态（选项 A 淘汰 / 选项 B 采纳升级版 B'-1 / 期间所有近实时发射按 CONV-01 主条款执行）· §1.6.2.1 新增 CONV-01.1 子条款（前缀合法性约束 · 由 01 @v1.3 §5.1.1 兜底 · 强制 · 与 CONV-01 主条款正交分工 · 与 01 @v1.3 §5.3.1 管未来/管历史分工）· **首次 kernel 内部 milestone 决议推进到"kickoff → decision → spec → ledger"同日四批次同 commit 同 txn 链式落地** · 三批次延迟全部=0 · 展示 "CONV-01 EX1 承诺窗加严到毫秒级" 的工具链可行性
**下游触发**：
- ✅ kernel 三文档小升（`01@v1.1` + `02@v1.1` + `07@v1.1`）已发布（2026-04-18 23:35）
- ✅ M4 路径 B 升降（`01@v1.2` + `02@v1.2`）已发布（2026-04-19 01:45）
- ✅ M4 milestone 收官（`04@v1.1 published` + `m4_final_decisions@v1`）已发布（2026-04-19 02:10）
- ✅ M5 路径 B 升降（`04@v1.2` + `02@v1.3` + `03 draft 原地`）已发布（2026-04-19 14:45 前完成 · commits `c3b8fe82` / `f25dc403` / `49608733`）
- ✅ M5 milestone 收官（`05@v1.1 published` + `m5-drift-draft-review@v1 published` + `m5_drift_kernel_alignment@v1 published` + `m5_final_decisions@v1 published`）已发布（2026-04-19 15:40 · commits `596f2ad2` / `78134de8` / `b8f877f9` / `f224dcfa`）
- ✅ M6 路径 A 消化（`06@v1 draft` §2.3/§5.2/§6.7/§7.3 四处原地补齐 · A1-A4 单 commit 批量）已发布（2026-04-19 19:54 · commit `e6e18d5f`）
- ✅ M6 路径 B 升降（`03 @v1 draft 原地精化` + `02@v1.3 → @v1.4 published` + `06 @v1 draft → @v1.1 draft 跟随升版`）已发布（2026-04-19 20:15–20:50 · commits `76bbfff5` / `7a7bce04` / `1c106937` / `44bf034b`）
- ✅ M6 milestone 收官（`m6-evolution-draft-review@v1 published` + `m6-evolution-kernel-alignment-proposal@v1 published+implemented` + `m6_final_decisions@v1 published` + `m6_evolution_kickoff@v1 superseded`）已发布（2026-04-19 21:05–21:34 · S5/S6/本 commit 批量固化）
- ✅ **M6 遗留项收敛**（Q27 补发 14 条历史事件 + 06 §11 字面勘误 + Q28 登记 + CONV-01 通用契约）已发布（2026-04-19 23:17 · v8 升版 · 四 commit 批）
- ✅ **M6 扫尾续收敛**（N1+N2 近实时发射 consumption@v1/ledger@v8 + N3' 保真补发 smoke-report@v1 + Q29 登记升级自 Q28 + CONV-01 EX1 压测）已发布（2026-04-20 00:10 · 本次 v9 升版 · 2 commit 批：216d6c1d + 本 commit）
- ✅ **M7 工作流 P 阶段 γ₁ 收官**（m7-closeout-kickoff @v1 启动 + m7-prefix-taxonomy-decision @v1 裁定 B'-1 + 01 @v1.2 → @v1.3 published 落地 + 本 ledger @v9 → @v10 published + CONV-01.1 子条款建立 + CONV-01 EX1 第三阶段压测）已发布（2026-04-20 00:30–00:55 · v10 升版 · 4 commit 链：kickoff / 批次 1 `862774bb` / 批次 2 `2ea5a49e` / 批次 3 本 commit）
- ⏳ **M7 工作流 X 阶段 γ₂**（07 Extensibility 宪章压测 · Q-X1/Q-X2/Q-X4 已由 decision @v1 间接预答 · 需形式化产出 `_review/m7-extensibility-charter-review.md @v1` + Q-X3/Q-X5 正式答复）
- ⏳ **M7 工作流 C 阶段 γ₃**（v0.1 Closeout · `_review/v0_1-final-decisions.md @v1 published` 封版 + ARCHITECTURE_SNAPSHOT 同步 + 四代 kickoff 接力链闭合）
- ⏳ 阶段 3 `02-artifact-model.md@v2` published（合并处理 §1.1 的 6 条 BAN + §1.2 Q4）
- ✅ `06@v1.1 draft → @v1.1 published` 已达成（2026-04-19 22:40 · 详见 `_review/m6-mvp-smoke-report @v1 published`）· artifact.published 事件已补发（2026-04-19 23:17 · event_id `task-260419144000-86e9a2` · 详见 §1.6 Q27）· smoke-report @v1 自身 artifact.published 事件已补发（2026-04-20 00:05 · event_id `artifact-published-260419223000-rpt001` · 详见 §1.7 Q29）
**关闭候选**：`urn:piao:snapshot:kernel:m2_final_decisions@v1`（阶段 3 收尾时的 milestone 快照）· `urn:piao:snapshot:kernel:v0_1_final_decisions@v1`（M7 阶段 γ₃ 收尾时 kernel 层 v0.1 封版快照 · 本账本作为其上游锚点之一）
