---
urn: urn:piao:artifact:kernel:m6_debt_consumption@v1
kind: artifact
artifact_type: review.debt_consumption
rev: v1
status: published
produced_by: agent:kernel-events-backfill
produced_at: 2026-04-19T23:17:00+08:00
upstream:
  - urn:piao:spec:architecture:evolution_model@v1.1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v7
  - urn:piao:snapshot:kernel:m6_final_decisions@v1
  - urn:piao:artifact:kernel:m6_mvp_smoke_report@v1
  - urn:piao:spec:architecture:identity_model@v1.2
  - urn:piao:spec:architecture:layered_architecture@v1
downstream:
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v8
wordcheck_exempt: true
---

# M6 遗留项收敛报告 · Q27 补发 14 条历史事件 + Q28 前缀字面冲突登记 + CONV-01 通用契约建立

> **触发**：`06 @v1.1 published` 封版（2026-04-19 22:40）时 §11 + §8.2 清单第 8 项字面"**待发射** `artifact.published` L1 事件"占位 · 属 M6 milestone 已封板但工具链侧独立动作未完成的显式遗留
>
> **收敛时刻**：2026-04-19 23:17 CST（15:17 UTC）· 独立于 M6 milestone 封板后的收敛行动
>
> **范围**：D = 完整补发历史 + 建立通用契约 + 升 ledger v8（用户当前会话决议）
>
> **定位**：`artifact:review.debt_consumption` —— kernel 层首个"非 milestone 周期触发"的收敛报告 · 首次建立 CONV-* 通用契约系列 · 首次使用 `reconstructed=true` 追认机制 · 为未来所有资产的 rev 转换事件补发/追认建立可复用范式

---

## 1. 问题定义

### 1.1 显式遗留字面

`06-evolution-model.md @v1.1 published`（2026-04-19 22:40 封版）遗留两处"待发射"字面：

**位置 1**：§8.2 升版动作清单第 8 项

```markdown
8. ⏳ 发射 `artifact.published` L1 事件（kind=spec · event_id 前缀 `snap-published-<YYMMDDHHmmss>-<rand6>`
   · 由独立事件写入步骤执行 · 对标 `05 @v1.1 published` 范式 · 不在本 commit 内原子完成 · 属工具链侧独立动作）
```

**位置 2**：§11 本篇状态行末尾括号内

```markdown
· **待发射** `artifact.published` L1 事件（kind=spec · event_id 前缀 `snap-published-*`
  · 独立事件写入步骤 · 不在本 commit 内原子完成）
```

两处均明确承诺"将发射事件"· 但未在本 commit 内落盘。

### 1.2 追溯发现的系统级裂缝

本次收敛盘查时发现：**kernel 全部 7 份 spec 自 M1 定稿起 无一条 `artifact.published` 事件** 落盘到任何 journal。这违反 `01 §10` "artifact 状态变更必须通过 L1 事件宣告"契约——kernel 在 journal 观测面**整体不可见**。

**影响面**：
- `piao-evolution-scan.sh` 扫 `artifact.published` 识别漂移时 · kernel 作为一大类 artifact 完全不出现在查询结果中
- 未来 `piao-snap.sh` / drift-propagation / 任何需要从 journal 重建 artifact 时间线的工具 · 在 kernel 边界都会断裂
- 任何"查某 kernel spec 在 YYYY-MM-DD 的状态"的用例都会返回 unknown

---

## 2. 补发清单（14 条 · 按 published_at 时序）

> 按 `01 §10.1` 契约 · 只有 `published` 态才发射 `artifact.published` · draft 内部升版不发。03 仍为 draft（首版未 published）· 不纳入补发。

| # | spec | rev | published_at (CST) | published_at (UTC) | event_id | content_sha256 忠实度 |
|---|------|-----|---------------------|---------------------|----------|-------------------|
| 1 | `01 identity_model` | v1 | 2026-04-18 ~18:00 | 2026-04-18 10:00 | `task-260418100000-bcfcd6` | null · historical_untraceable |
| 2 | `01 identity_model` | v1.1 | 2026-04-18 23:35 | 2026-04-18 15:35 | `task-260418153500-ed4f1c` | null · historical_untraceable |
| 3 | `01 identity_model` | v1.2 | 2026-04-19 01:45 | 2026-04-18 17:45 | `task-260418174500-b7da1a` | `4c9b54da0d217ac7...`（final rev · 真 sha）|
| 4 | `02 artifact_model` | v1 | 2026-04-18 ~18:00 | 2026-04-18 10:00 | `task-260418100000-159b7d` | null · historical_untraceable |
| 5 | `02 artifact_model` | v1.1 | 2026-04-18 23:35 | 2026-04-18 15:35 | `task-260418153500-b9fede` | null · historical_untraceable |
| 6 | `02 artifact_model` | v1.2 | 2026-04-19 01:45 | 2026-04-18 17:45 | `task-260418174500-bab9e6` | null · historical_untraceable |
| 7 | `02 artifact_model` | v1.3 | 2026-04-19 14:45 | 2026-04-19 06:45 | `task-260419064500-f5236b` | null · historical_untraceable |
| 8 | `02 artifact_model` | v1.4 | 2026-04-19 20:45 | 2026-04-19 12:45 | `task-260419124500-f51faf` | `ce0fb477c5148f18...`（final rev · 真 sha）|
| 9 | `04 version_snapshot` | v1.1 | 2026-04-19 02:10 | 2026-04-18 18:10 | `task-260418181000-b1bee9` | null · historical_untraceable |
| 10 | `04 version_snapshot` | v1.2 | 2026-04-19 14:35 | 2026-04-19 06:35 | `task-260419063500-1db60b` | `664050203f6a75f1...`（final rev · 真 sha）|
| 11 | `05 drift_propagation` | v1.1 | 2026-04-19 15:40 | 2026-04-19 07:40 | `task-260419074000-97c822` | `f591b2970bd99155...`（final rev · 真 sha）|
| 12 | `06 evolution_model` | v1.1 | 2026-04-19 22:40 | 2026-04-19 14:40 | `task-260419144000-86e9a2` | `c4830bb55fb453fe...`（final rev · 真 sha）|
| 13 | `07 extensibility` | v1 | 2026-04-18 ~18:00 | 2026-04-18 10:00 | `task-260418100000-1bf277` | null · historical_untraceable |
| 14 | `07 extensibility` | v1.1 | 2026-04-18 23:35 | 2026-04-18 15:35 | `task-260418153500-8f1f67` | `2f2f4947c937332f...`（final rev · 真 sha）|

**分布统计**：01 × 3 · 02 × 5 · 04 × 2 · 05 × 1 · 06 × 1 · 07 × 2 · 合计 14 条

**sha256 忠实度分级**：
- **Final rev 六条附真 sha256**（01@v1.2 / 02@v1.4 / 04@v1.2 / 05@v1.1 / 06@v1.1 / 07@v1.1）· 源自 `shasum -a 256` 当前字节
- **中间 rev 八条 `content_sha256: null`** · 附 `content_sha256_note: "historical_untraceable · 中间 rev 字节已被后续覆盖 · 仅 urn + published_at 可信"`

---

## 3. 事件落盘路径与 journal 分离策略

### 3.1 落盘路径

```
pipeline-output/piao/kernel-events/2026-04.jsonl  (14 行)
```

**字段结构**（字母序 · 对齐现有 `mvp-smoke/events/2026-04.jsonl` 格式 + 扩展 reconstructed 元数据）：

```json
{
  "artifact_kind": "spec",
  "artifact_type": "spec.architecture",
  "artifact_urn": "urn:piao:spec:architecture:evolution_model@v1.1",
  "content_sha256": "c4830bb55fb453fe81dfeffdf4f359f6a16b630169a6f8da4709ce4f790b02cb",
  "content_sha256_note": "final rev · byte-traceable · 当前 docs/piao-pipeline/kernel/06-evolution-model.md shasum",
  "emitted_at": "2026-04-19T15:17:00Z",
  "emitted_by": "agent:kernel-events-backfill",
  "event_id": "task-260419144000-86e9a2",
  "event_layer": "L1",
  "event_type": "artifact.published",
  "producer_task_urn": "urn:piao:task:kernel:m6_evolution_model_publish",
  "published_at": "2026-04-19T14:40:00Z",
  "reconstructed": true,
  "reconstructed_at": "2026-04-19T15:17:00Z",
  "reconstructed_from": "rev_history 自述 · M6 遗留项 Q27 补发 · kernel spec rev 转换 artifact.published 事件追认 · 见 _review/m6-debt-consumption.md",
  "subject": "urn:piao:spec:architecture:evolution_model@v1.1"
}
```

### 3.2 为什么不合并到 `mvp-smoke/events/2026-04.jsonl`

**语义隔离**：

| 维度 | `mvp-smoke/events/2026-04.jsonl` | `kernel-events/2026-04.jsonl` |
|------|----------------------------------|-------------------------------|
| 产出方 | `agent:piao-evolution-scan`（evolution-scan MVP 脚本）| `agent:kernel-events-backfill`（本次 M6 遗留收敛追认）|
| `producer_task_urn` | `urn:piao:task:manual:piao_evolution_scan` | `urn:piao:task:kernel:m{1–7}_*_publish` |
| 事件类型 | `artifact.published`（drift-triggered-* 前缀）+ `evolution.scanned` | `artifact.published`（task-* 前缀）|
| 订阅者 | 下游 evolution 消费工具 | 下游 kernel spec 时间线重建工具 + evolution 扫 kernel 自身变迁 |
| `reconstructed` 标志 | 不适用（实时产出）| `true`（追认补发）|

**合并落盘会导致**：① 订阅者按 `producer_task_urn` 过滤时无法区分 ② reconstructed 实时混合 ③ 未来 kernel spec 新发布（实时）与本次补发（追认）混在同一个文件语义不清。

### 3.3 事件 ID 时间戳的忠实性（三时间字段分工）

| 字段 | 取值 | 语义 |
|------|------|------|
| `event_id` 时间戳段 | 真实 `published_at` 的 UTC `YYMMDDHHmmss` | grep 友好 · 支持"按时间范围查 event" · 反映事件的**业务时刻**|
| `emitted_at` | 2026-04-19T15:17:00Z（追认落盘时刻 UTC）| 反映事件的**物理写入时刻**· 用于 append-only 可信度追溯 |
| `published_at` | 真实 published 时刻 UTC · 来自 rev_history 表 | 反映资产的**状态转换时刻**· 被 `event_id` 时间戳段镜像 |
| `reconstructed_at` | 等于 `emitted_at`（追认时刻）| 明示本条事件是追认 · 而非实时 |

**三字段分工**避免"追认事件伪装成实时事件"的证据污染 · 任何下游工具可通过 `reconstructed=true || emitted_at != published_at` 识别追认事件。

### 3.4 `event_id` 的 hash 段可重现算法

```python
h_input = f"{urn}|{published_at_utc}|{rev}".encode("utf-8")
hex6 = hashlib.sha1(h_input).hexdigest()[:6]
event_id = f"task-{YYMMDDHHmmss}-{hex6}"
```

**特性**：
- 确定性（相同输入 → 相同 event_id）· 未来若需重建 journal 可 byte-identical
- 域前缀 `task-` 按 `01 §5` 顶层规约（`artifact.*` 归入 task 域）
- 输入三元组 `urn|published_at|rev` 保证同 urn 跨 rev 不撞 · 同 rev 跨 published_at 不撞 · 足以保证 6-hex 防撞（2^24 空间）

---

## 4. Q28 · event_id 前缀字面规约冲突（continued-to-M7）

### 4.1 冲突字面

| 位置 | 字面约定 | 与 01 §5 顶层规约关系 |
|------|---------|----------------------|
| `05 §2.3` schema 示例 | `event_id: snap-published-<YYMMDDHHmmss>-<rand6>` · 注释 "drift artifact 的 produced_by.event_id" | 冲突 · 01 §5 表 `artifact.*` 归 task 域 |
| `05 §9 Q3` review 裁定 | "drift artifact 的 `produced_by.event_id` 前缀 = `snap-published-*`" | 同上冲突 |
| `06 §11` 本篇状态行（已勘误）| 原 "event_id 前缀 `snap-published-*`" · 类比 M5 drift artifact 范式 | 冲突 · 已由本次 Q27 补发按 task-* 落盘并补注勘误 |
| `06 §8.2` 第 8 项（已勘误）| 原 "event_id 前缀 `snap-published-<YYMMDDHHmmss>-<rand6>`" | 同上 |
| `01 §5` 顶层规约 | `artifact.*` 归入 `task` 域（前缀 `task-*`）| **真源** |

### 4.2 三选项裁定（延期至 M7）

**选项 A**：追认 `01 §5` 为唯一真源 · `05 §2.3` / `05 §9 Q3` / `06 §11` / `06 §8.2` 字面勘误为"本应按 `task-*` 规约 · 原文类比 M5 drift 修辞失准"
- 优势：kernel 层规约一致性最高 · 一处真源 · 下游工具按 `task-*` grep 就能命中所有 `artifact.published`（含 spec / snapshot / drift / evolution.scan_result 等所有派生）
- 代价：05 是 published @v1.1 · 勘误需独立补注块（不改文字 · 按 01 §10.1 append-only 契约）· 或等待下一次 05 rev 升版时刷进

**选项 B**：扩展 `01 §5` 事件域表 · 为 spec published 增设专用前缀 `snap-published-*`（或类似）· 让 05 §2.3 / 06 §11 原文字面合法化
- 优势：spec 自身作为特殊 artifact 类享有独立身份 · 对齐 `04 §3.2 snapshot` 特化模式
- 代价：需权衡 "`task` 域下 artifact 子类是否必须统一前缀" vs "grep 友好性分化"· 涉及 01 rev 升版（01 是 kernel 最底层 · 升 rev 代价高）

**选项 C**：维持现状不裁定 · 仅要求发布工具侧同时索引两种前缀（向后兼容代价）
- 优势：无即时成本
- 代价：工具侧救火 · 每个新工具都要处理双前缀 · 违反"kernel 层决定 · 工具层执行"范式

### 4.3 本次 Q27 落盘的权宜决策

**本次按选项 A 临时执行**（`task-*` 前缀）· 不构成对 Q28 的默认裁定 · 仅在 `06 §11` 补注说明前缀字面勘误的原因 · 并留 Q28 给 M7 裁定。

**M7 起稿时**（预计 06 @v1.1 published 达成 + M7 kickoff proposal 启动后）须一次性完成：
- Q28 三选项裁定
- 若选 A：05 @v1.1 补勘误追述块 + 06 @v1.1 已含勘误（本次完成）
- 若选 B：01 rev 升版（v1.2 → v1.3）+ 05 / 06 原文字面无需改
- 若选 C：无 kernel 层变更 · 但需在 M7 toolchain 规约中强制工具双前缀索引

---

## 5. CONV-01 · 首条通用契约（§1.6.2）

### 5.1 契约原文

| 契约编号 | 契约文字 | 适用范围 | 强制性 |
|---------|--------|---------|-------|
| **CONV-01** | 任何 `kind=spec` 或 `kind=artifact` 的资产在 **首版 published / 同 rev `draft→published` 转换 / 已 published 态下 `rev_N → rev_N+k` 小升或大升**三种场景下 · **必须**在同 txn（或承诺的独立但有界时间窗 · 默认 1 工作日内）发射 `artifact.published` L1 事件到对应 journal · 事件字段遵循 `01 §5` + `03 §3.2` 规约 · `subject` = 新 rev 的完整 URN · `content_sha256` = 新 rev 规范化后字节 sha256 | kernel spec · adapter spec · 业务 artifact（snapshot / drift / evolution.scan_result / lineage 等派生类型同理）| **强制** |
| **CONV-01-EX1** | 允许"独立事件写入步骤"延迟发射 · 但须在资产 front-matter `produced_by.event_id` 字段**预占**事件 id · 预占非 null 即视为承诺 · 超过有界时间窗未落盘视为违约 | 同 CONV-01 | 强制 |
| **CONV-01-EX2** | `draft` 状态下的 **draft 内原地修订**（按 `01 §10.1` draft 允许原地契约）**不**发射 `artifact.published`（因为未转换到 published 态）· 仅记录 `last_modified_at` · 无 L1 事件义务 | 同 CONV-01 | 强制 |
| **CONV-01-EX3** | 资产为 `reconstructed=true` 的历史补发事件 · `event_id` 时间戳段取**真实 published_at 的 UTC YYMMDDHHmmss**（非追认时刻）· `emitted_at` 取追认时刻（UTC）· `published_at` 取真实 published 时刻（与 rev_history 表一致）· 三字段分工 避免证据污染 | 所有资产补发场景 | 强制 |

### 5.2 首个实施案例

**本次 Q27 补发 14 条事件**即 CONV-01 + CONV-01-EX3 的首个实施案例：
- CONV-01 本体：kernel 7 份 spec 的历史 rev 转换 · 全部补发 `artifact.published`
- CONV-01-EX3：14 条事件均 `reconstructed=true` · 三时间字段分工清晰

### 5.3 未来触发点

- Q28 若裁定为选项 A：CONV-01 字面在 M7 封版时刷进 `01 §5` 作为**正式条款**（当前为 debt-ledger v8 §1.6.2 临时登记态）
- Q28 若裁定为选项 B：CONV-01 需对应扩展 · 支持 `artifact_type=spec.*` 专用前缀声明
- Q28 continued-to-M7 期间 · CONV-01 即作为**事实契约**执行 · `piao-evolution-scan.sh` / 未来工具 / agent 须按此执行

### 5.4 对 piao 体系的本体论意义

本次 Q27 补发**首次在实践层验证**：piao 体系"事件即事实"本体论 · 在 **kernel 自指语义下** 的自洽性——kernel 层自己也要纳入事件本体 · 不能留观测面空白 · 否则下游任何时序推理都会在 kernel 边界断裂。

CONV-01 的建立 · 将"kernel 自身要发事件"从**隐式惯例**提升为**显式契约**· 为所有未来资产（包括 adapter / 业务 artifact）的 rev 转换事件发射义务建立强制规范。

---

## 6. 收敛产出清单（本次 commit 四批）

| 产出 | 路径 | 内容 | commit 归属 |
|------|------|------|-----------|
| 事件 journal | `pipeline-output/piao/kernel-events/2026-04.jsonl` | 14 条 `artifact.published` 事件 · `reconstructed=true` · 字段字母序 · 按 `published_at` UTC 升序 | Commit 1（events）|
| 06 spec 勘误 | `docs/piao-pipeline/kernel/06-evolution-model.md` | §8.2 清单第 8 项 + §11 本篇状态行两处字面修订（"待发射" → "✅ 已发射 event_id task-260419144000-86e9a2"）· 补注前缀字面勘误（task-* 而非 snap-published-*）· 引 Q28 续论 | Commit 2（kernel-spec-lines）|
| ledger 升版 | `docs/piao-pipeline/kernel/_review/M1-debt-ledger.md` | v7 → v8 · front-matter rev_history 追加 v8 行 · §1.6 新增（Q27/Q28/CONV-01 三小节）· §3 关闭条件追加 §1.6 行 · 末尾状态区全面刷新 | Commit 3（ledger）|
| 收敛报告 | `docs/piao-pipeline/kernel/_review/m6-debt-consumption.md` | 本文档 · @v1 published · 收敛路径 + 补发清单 + Q28 三选项 + CONV-01 首例 | Commit 4（report）|

---

## 7. 与 M5 `final-decisions` 范式的对照

| 维度 | M5 `_review/m5-final-decisions.md @v1 published` | M6 遗留收敛 `_review/m6-debt-consumption.md @v1 published` |
|------|---------------------------------------------------|------------------------------------------------------------|
| 触发时机 | milestone 封板同批 | milestone 封板**之后**的独立收敛行动（首次）|
| 产出类型 | `kind=snapshot`（封板快照）| `kind=artifact` · `artifact_type=review.debt_consumption`（收敛报告）|
| 范围 | milestone 级决议矩阵 | milestone 遗留单点（但揭示系统级裂缝）|
| ledger 升版 | 随 milestone 封板升 v6（§1.4 新增）| 独立升 v8（§1.6 新增）· 首次非 milestone 周期升版 |
| 建立的契约 | R17-R25 落地矩阵（点对点修订）| CONV-01（首条通用契约）· 点对面规范 |
| 诚实标记 | N/A（实时产出）| `reconstructed=true` + 三时间字段分工（首次）|

**范式意义**：本文件为未来所有"milestone 封板后发现的遗留收敛"建立**可复用 artifact 类**`artifact_type=review.debt_consumption`（未来 M7+ 若有类似场景可直接复用本模板）。

---

## 8. 关联锚点

**上游**：
- `urn:piao:spec:architecture:evolution_model@v1.1 published`（06 §11 + §8.2 遗留字面的来源）
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v7 superseded`（本次升版的前序态）
- `urn:piao:snapshot:kernel:m6_final_decisions@v1 published`（M6 milestone 封板）
- `urn:piao:artifact:kernel:m6_mvp_smoke_report@v1 published`（M6 MVP 反证 · 本次未动其字面）
- `urn:piao:spec:architecture:identity_model@v1.2 published`（§5 event_id 规约真源）
- `urn:piao:spec:architecture:layered_architecture@v1 draft`（§3.2 L1 事件通用骨架）

**下游**：
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v8 published`（本文件的直接下游 · Q27 consumed + Q28 continued + CONV-01 登记）

**触发的事件**：
- 14 条 `artifact.published`（`reconstructed=true`）· 落盘 `pipeline-output/piao/kernel-events/2026-04.jsonl`
- 自身的 `artifact.published`（本文件 @v1 published · event_id 按 CONV-01 契约应同批发射 · 预留给后续 journal append 步骤）

---

## 9. 后续动作

### 9.1 即时（本次 commit 批内完成）

- [x] 14 条事件落盘 `pipeline-output/piao/kernel-events/2026-04.jsonl`
- [x] `06-evolution-model.md` §8.2 + §11 两处字面勘误完成
- [x] `M1-debt-ledger.md` v7 → v8 升版完成（§1.6 新增）
- [x] 本报告 @v1 published 起稿完成

### 9.2 短期（M7 kickoff proposal 启动前）

- [ ] Q28 三选项评估材料准备（含 grep 兼容性成本估算 + 01 rev 升版代价估算）
- [ ] 发射本报告自身的 `artifact.published` 事件（按 CONV-01 EX1 预留 event_id · 1 工作日内落盘）

### 9.3 M7 期间

- [ ] Q28 最终裁定（A/B/C 三选一）· 结果同批刷进 05 @v1.1 补追述块（如选 A）或 01 rev 升版（如选 B）
- [ ] CONV-01 字面晋升为 kernel 正式条款（按 Q28 裁定结果刷进 `01 §5` 或独立成章）
- [ ] 05 / 06 字面一致性校验（若选 A 则 05 补追述块 · 06 已完成）

### 9.4 M7+ 长期

- [ ] 本 `artifact_type=review.debt_consumption` 模板复用（未来 milestone 封板后遗留收敛统一走此范式）
- [ ] CONV-* 契约系列扩展（CONV-02 / 03 / ... 按未来需要）

---

**本报告状态**：published · @v1（2026-04-19 23:17 CST / 15:17 UTC）
**最后修改**：2026-04-19T23:17:00+08:00
**wordcheck**：`wordcheck_exempt: true`（本报告含大量 kernel 规约引用 · 属机器产物性质 · 按 `02 §2.2.4 wordcheck_policy=machine_generated` 豁免）
