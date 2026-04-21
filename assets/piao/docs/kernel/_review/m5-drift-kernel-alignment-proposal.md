---
urn: urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1
artifact_type: proposal.kernel_minor_upgrade
kind: proposal
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-19T14:20:00+08:00
last_modified_at: 2026-04-19T14:22:00+08:00
created_by_event: manual-m5-drift-align-260419
content_sha256: ""
depends_on:
  - urn: urn:piao:artifact:kernel:m5_drift_draft_review@v1
    strength: strong
  - urn: urn:piao:spec:architecture:drift_propagation@v1
    strength: strong
  - urn: urn:piao:spec:architecture:version_snapshot@v1.1
    strength: strong
  - urn: urn:piao:spec:architecture:artifact_model@v1.2
    strength: strong
  - urn: urn:piao:spec:architecture:layered_architecture@v1
    strength: strong
  - urn: urn:piao:spec:architecture:identity_model@v1.2
    strength: strong
  - urn: urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1
    strength: weak
  - urn: urn:piao:artifact:kernel:m4_toolchain_review@v1
    strength: weak
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:kernel:m5_drift_kernel_alignment_planning
  event_id: manual-m5-drift-align-260419
wordcheck_exempt: true
---

# Kernel Alignment Proposal · M5 Drift 落地触发

> 本 proposal 是 **`m5-drift-draft-review.md @v1 §3.2 路径 B`** 的执行文档，沿用 **`m4-snapshot-kernel-alignment-proposal.md @v1`** 的格式与动作表范式（range/节号/动作三列矩阵 + 执行顺序 + 风险表 + DoD + 下游触发 + scope-out）。
>
> **输入**：review §3.2 的 5 条路径 B 修订（R21–R25）+ 已 consumed 的路径 A 四条（R17–R20 · 05 draft 原地落地 · 见 `05 §8.1 rev_history` 的 "v1（原地追述 · 路径 A 消化）· 2026-04-19 14:10" 条目）。
>
> **输出**：
> - 一份 `published` kernel 文档升小版：`04-version-snapshot.md @v1.1 → @v1.2`（R21 + R24 合并）
> - 一份 `published` kernel 文档升小版：`02-artifact-model.md @v1.2 → @v1.3`（R23 + R25 合并）
> - 一份 `draft` kernel 文档原地修订（不升 rev）：`03-layered-architecture.md`（R22）
> - 一份 `draft` kernel 文档跟随升小版：`05-drift-propagation.md @v1 (draft) → @v1.1 (draft)`（反映 R21/R23 带来的 §2.5 / §10 锚点注释从"待外篇对接"改为"已反向对接" · 对齐 M4 Step 3 范式）
>
> **完成后**：M5 drift 层的 kernel 缺口全部闭环；`05-drift-propagation.md` 即可从 `@v1.1 draft → @v1.1 published`（走 §8.2 门控 #2/#3/#4 · 依赖 Step 5 的 `piao-drift-compute.sh` MVP 产出真实 drift artifact 做反证）。

---

## 1. 为什么是小升（04/02 升版 · 03 原地 · 05 跟随升版）

按 `01-identity-model.md §4.2` rev 创建规则 + `01 §10.1` draft 契约综合判定，R21–R25 的处置分四类：

### 1.1 rev 升降矩阵

| 目标文档 | 当前 rev | 当前 status | 本次处置 | rev 升降 |
|---------|--------|-----------|---------|---------|
| `04-version-snapshot.md` | **@v1.1** | **published** | R21（§3.2.1 补 canonical YAML 工具实施建议）+ R24（§5.1 补 `sha_changed` alias） | **@v1.1 → @v1.2** |
| `02-artifact-model.md` | **@v1.2** | **published** | R23（§5.3.1 扩为通用特化注册表 + drift 首批注册）+ R25（§2.2 派生类型注册补 `wordcheck_policy` 字段） | **@v1.2 → @v1.3** |
| `03-layered-architecture.md` | **@v1** | **draft** | R22（§3.3.1 原子写入契约泛化为 N 事件同 txn） | **不升 rev**（按 `01 §10.1` draft 可原地修订 · 沿用 M4 `m4_snapshot_kernel_alignment` proposal 对 03 的处置范式） |
| `05-drift-propagation.md` | **@v1** | **draft** | Step 3 跟随升版：反映 04/02 反向对接后的锚点注释状态（从"待 02/04 反向对接"改为"已反向对接"） | **@v1 → @v1.1**（draft 内小升 · 非 published 升版） |

### 1.2 为什么不算大升

按 `01 §4.2`：

| 建议 | 变更类型 | 为什么不算大升 |
|-----|---------|-------------|
| R21（04 §3.2.3 补通用工具实施建议） | **新增小节** | 04 既有 §3.2.1 五必填 key / canonical 五步规范化未动；§3.2.3 是工具链实施层的**下钻说明**（key 正则 + 正向白名单 pick 规则），契约语义不变。同时合并 `m4-toolchain-review §2.5 T5` 的 key 正则建议，消除路径 A 遗留债 |
| R22（03 §3.3.1 泛化多事件同 txn 为 N 条） | **语义扩展但不破坏现状** | 03 §3.3.1 原列举的"snapshot 三写"场景仍为合法子集（N=3 · 含 stage 事件）；扩展后 drift 的 N=2 场景（无 stage 事件）也合法。调用方若按旧版实现仅支持 N=3 仍可正常产出 snapshot · 仅在 drift 场景下需更新（向上兼容） |
| R23（02 §5.3.1 扩为通用特化注册表） | **新增特化条目** | 02 §5.3.1 snapshot 特化规则保留不变；扩表追加 `kind=drift` 条目。lineage_query 函数签名不变 · 仅在 kind 分支添加 drift 条件 · 对已有 snapshot 查询零影响 |
| R24（04 §5.1 补 `sha_changed` alias） | **向下兼容双名** | 04 §5.1 `modified` 字段保留 · 新增 `sha_changed` 为 alias；新实施代码优先用 `sha_changed`，旧消费方仍读 `modified` 可用。schema 键数 +1 但不改字段类型 |
| R25（02 §2.2 派生类型注册补 `wordcheck_policy` 字段） | **新增可选字段** | 02 §2.2 派生类型注册 schema 现有六字段不动；新增 `wordcheck_policy: machine_generated \| content_safe_default`（可选）· 未填的派生类型按原语义（`content_safe_default`）处理。drift.propagation_record 通过本字段声明 `machine_generated` 自动 exempt |

**零 schema 删减、零字段类型变更、零语义反转** → 小升（02/04）与 draft 原地修订（03）+ draft 内小升（05）足矣。

### 1.3 对下游的影响

- **现有 adapter**（目前仅 `frontend-migration`）：**不需要任何改动**。R21/R24 新增字段均为可选或 alias · R22 是向上兼容扩展 · R23/R25 均为读端行为补齐（adapter 不直接生成 drift artifact）。
- **04/02 已 published 的历史 snapshot / artifact**：**不需要迁移**。R21 不影响已存 snapshot 的 content_sha256 计算（既有 snapshot 的 sha 在本次升版前已按 04 @v1.1 算法计算完毕 · 本次升版不触发重算 · 与 `04 §7.1` "published snapshot 不可变" 硬约束对齐）· R24 的 `sha_changed` alias 仅影响未来新产出的 snapshot_diff。
- **05-drift-propagation.md（draft @v1）**：本 proposal 完成后，05 **跟随升版**到 `@v1.1 (draft)` 以反映锚点注释更新（§2.5 末尾的 R23 对接 + §10 前置契约表中 §3.2.3 / §5.3.1 新位置 / §5.1 `sha_changed` 双名的引用更新）。详见 §7 下游触发。

---

## 2. 五文档动作矩阵（R → 文档 → 节号 → 动作）

| # | 来源 | 建议 | 目标文档 | 目标节 | 动作 |
|---|------|-----|---------|-------|------|
| 1 | Q15 + `m4-toolchain-review §2.5 T5`（合并）/ R21 | canonical YAML 通用工具实施建议 | `04-version-snapshot.md`（@v1.1 → @v1.2） | 新增 §3.2.3（紧跟 §3.2.1 canonical 五步之后、§3.3 scope_kind 之前） | 补子节：key 正则 `^[a-z_][a-z_0-9]*$` + 正向白名单 `pick_fields` 伪码 + `SHA_WHITELIST` 声明范式 + 供 05 §2.5 复用的锚点备注 |
| 2 | 05 §9 Q1 联动 / R24 | `sha_changed` 作为 `modified` 的 alias | `04-version-snapshot.md`（@v1.1 → @v1.2） | §5.1 snapshot_diff 算子字段表 | `modified` 行下追加注释："v1.2 起新实施优先使用 `sha_changed` · `modified` 保留为向下兼容 alias · 两字段值必须同语义" |
| 3 | Q18 / R22 | 多事件同 txn 语义泛化为 N 条 | `03-layered-architecture.md`（draft） | §3.3.1 原子写入契约 | 将原列举式契约改写为通用契约："`event-journal-append` 支持 N 条 L1 事件同 txn 提交（N ≥ 1）· 事件间无固定 type 约束 · 当前已知场景含 snapshot 三写（N=3）+ drift 两写（N=2）· 未来新场景不需改 03" |
| 4 | Q20 / R23 | lineage 特化注册表化 | `02-artifact-model.md`（@v1.2 → @v1.3） | §5.3.1 snapshot 特化 → 改写为"lineage 特化注册表" | 将 §5.3.1 从"snapshot 一次性特化规则"改为"派生 kind 的 `depends_on` 等价替身规则表"· 首批注册两条：`kind=snapshot` → `frozen_artifacts`（原有）· `kind=drift` → `diff_base.old_snapshot_urn` + `diff_base.new_snapshot_urn`（新增） |
| 5 | 05 §9 Q5 联动 / R25 | 派生类型注册补 wordcheck_policy | `02-artifact-model.md`（@v1.2 → @v1.3） | §2.2 派生类型的注册方式 | schema 新增可选字段 `wordcheck_policy`（枚举 `machine_generated \| content_safe_default` · 默认 `content_safe_default`）· 补注释："`machine_generated` 声明 artifact 由确定性算法产出 · 其 body 自动继承 `wordcheck_exempt: true` · 用于 drift.propagation_record / snapshot.diff 等机器产物类型" |

**五文档升版总体积**：~90–110 行新增（纯补充 + 少量改写 · 不删不改现有契约语义）。与 `m4_snapshot_kernel_alignment` 的 80–100 行同量级，符合"第二轮对齐同模式 proposal"体量预期。

---

## 3. 执行顺序与依赖

**关键观察**：五条修订中 R21/R24 改 04；R23/R25 改 02；R22 改 03。四文档之间的依赖：

- **R21（04 §3.2.3）← 05 §2.5**：05 路径 A R17 已落地正向白名单六字段 · 本次 R21 在 04 侧提供通用工具契约供 05 复用锚点
- **R22（03 §3.3.1）← 05 §3.2 T5**：05 已声明 drift 两写场景 · 本次 R22 在 03 侧把契约泛化，消除"05 假设 03 已支持 N 事件同 txn 但 03 原文只列举三写"的隐性偏差
- **R23（02 §5.3.1）← 05 §2.5 末尾"等价替身规则"**：05 路径 A R17 补述中已点名"02 侧反向对接归入 R23"· 本次在 02 侧注册 drift 特化
- **R24（04 §5.1）← 05 §2.4 + §9 Q1**：05 body 已用 `sha_changed` · 本次在 04 侧补 alias · 05 §10 锚点引用从"04 §5.1 modified" 改为"04 §5.1 modified/sha_changed 双名"
- **R25（02 §2.2）← 05 front-matter `wordcheck_exempt: true` + §9 Q5**：05 已在 header 中声明 exempt · 本次在 02 侧正式注册 `wordcheck_policy` 字段让该声明有根据

推荐执行顺序（基于依赖最小化 + 先 draft 原地后 published 小升 + 最后 05 跟随）：

```
(S0) 预检 · key 正则兼容性扫描（S1 前置 · 护栏）
       │   执行：grep -oE "^[A-Za-z_][A-Za-z_0-9]*:" docs/piao-pipeline/kernel/0{1,2,3,4,5}-*.md | awk -F: '{print $2}' | sort -u
       │   验收：所有 key 必须匹配 ^[a-z_][a-z_0-9]*$（R21 承诺 1 的正则）
       │   失败处置：若存在不匹配 key → 暂停 S2 · 在 m4-toolchain-review 补一条正则放宽债 · 待裁决后再恢复（与 m4 T5 同模式）
       │   预期：kernel front-matter 全部 snake_case · 预检通过
       │
       ▼
(S1) 03-layered-architecture.md（draft 原地修订，不升 rev）
       │   动作 3（§3.3.1 多事件同 txn 泛化为 N 条）
       │
       ▼
(S2) 04-version-snapshot.md @v1.1 → @v1.2
       │   动作 1（新增 §3.2.3 canonical 通用实施建议）
       │   动作 2（§5.1 补 sha_changed alias）
       │
       ▼
(S3) 02-artifact-model.md @v1.2 → @v1.3
       │   动作 4（§5.3.1 扩为通用特化注册表）
       │   动作 5（§2.2 派生类型补 wordcheck_policy）
       │
       ▼
(S4) 两份 published 文档 rev_history 追加 v1.2 / v1.3 一行 · 03 draft 的 rev_history（若有；或参考 05 §8.1 / M4 范式）追加"draft 阶段原地修订 · 路径 B"一行
       │
       ▼
(S5) 05-drift-propagation.md @v1 (draft) → @v1.1 (draft) 跟随升版
       │   §2.5 末尾"等价替身规则"注释从"R23 待处理"改为"R23 已落地 · 对接 02 §5.3.1 的 kind=drift 注册条目"
       │   §10 前置契约表：04 §5.1 引用改为双名 · 新增 04 §3.2.3 条目 · 02 §5.3.1 引用更新为"通用特化注册表 · drift 条目"
       │   §8.1 rev_history 追加 v1.1 一行（triggered_by = 本 proposal）
       │   §9 开放问题 Q1/Q5 的"04 侧 / 02 侧落地归 R24/R25"注释改为"已 consumed · 见 `m5_drift_kernel_alignment@v1` S2/S3"
       │
       ▼
(S6) review 文档追加 §5/§6 路径 B 完成记录（与 §3.2 表对齐 · R21–R25 逐条 consumed 表 · 对标 `m4-snapshot-draft-review @v1 §6` 范式）
       │
       ▼
(S7) 全量 wordcheck + IDE lint + commit
```

**回滚点**：S1 / S2 / S3 / S5 每一步都是**独立可 commit 的 git 节点**；若发现 S2 的某处补充不够可直接打补丁（仍在 `@v1.2` 同一 rev 内 · 因 04 在小升窗口内允许微调，参考 `m2`/`m4-snap-align` 的同模式回滚逻辑）。**S0 预检失败不构成本 proposal 失败**——预检是护栏 · 失败时仅暂停执行并补债回退，proposal 正文保持不变。

---

## 4. 文档级精确修订锚点

### 4.1 R22 · 03 §3.3.1 泛化多事件同 txn 为 N 条（draft 原地）

**落点**：`03 §3.3.1 原子写入契约`（M4 路径 B 新增）。

**现状**：03 §3.3.1 当前（由 `m4_snapshot_kernel_alignment@v1` 落地）的"多事件同 txn"场景写为"snapshot 产出的三写（artifact.published(snapshot) + stage.exited/entered + artifact.published(其他 artifact)）"。

**修订动作**：

- 将现有"三写"的列举表述改为**通用契约**：

  ```
  承诺 1（v1 draft 修订 · 2026-04-19 · 本 proposal S1）：
  event-journal-append 工具提供"N 条 L1 事件同 txn"语义（N ≥ 1），对调用方呈现为原子。
  事件间无固定 type 约束——当前已知场景：
    - N=3 · snapshot 产出：artifact.published(snapshot) + stage.exited/entered + artifact.published(其他 artifact)
    - N=2 · drift 产出：artifact.published(drift) + drift.detected（由 05-drift-propagation §3.2 T5 触发）
  未来新增场景（如 M6 evolution 可能引入的 N≥4 组合）不需要修改 03；列举仅为当前已知实例，不构成 type 白名单约束。
  ```

- **承诺 2**（失败回滚 + 孤儿标记）保留不变
- **接口 1**（`artifact-validate.sh --check-orphan`）保留不变
- **kernel 不承诺的部分**保留不变

**副作用**：05 §3.2 T5 的两写场景从"隐性依赖 03 §3.3.1 允许扩展"变为"显式 N=2 实例"· 路径 B 完成 · 05 §3.2 可在 Step 5（跟随升版）时把 T5 脚注指向本次 03 修订。

### 4.2 R21 · 04 §3.2.3 新增"canonical YAML 工具实施建议"（@v1.1 → @v1.2）

**落点**：紧跟 `04 §3.2.1 canonical YAML 五步规范化` 之后、`§3.3 scope_kind 五类封板` 之前，插入新小节 **§3.2.3**（编号按 04 当前结构顺延）。

**内容大纲**（约 30 行）：

- **合并来源**：本节**同时落地** Q15/R21（drift content_sha256 实施）+ `m4-toolchain-review §2.5 T5`（snapshot front-matter key 正则）两条路径 A 遗留债
- **动机引述**：从"04 snapshot + 05 drift 两套 canonical YAML 实施路径应统一"的工具链自洽性反推 kernel 承诺层
- **承诺 1 · key 正则**：canonical YAML 参与规范化的 front-matter key 必须匹配正则 `^[a-z_][a-z_0-9]*$`（小写开头 + 下划线/数字/小写字母）· 其它 key 一律视为"非规范化 key"不参与 content_sha256
- **承诺 2 · 正向白名单 `pick_fields`**：工具实施模式为 `canonical_yaml( pick_fields(front_matter, KEY_ORDER) )`· `KEY_ORDER` 为文档指定的正向字段清单（非反向排除清单）· fail-safe 默认
- **承诺 3 · `SHA_WHITELIST` 声明范式**：供复用本工具链的派生 artifact（snapshot / drift / M6 evolution 的未来产物）声明各自的白名单字段清单 · 与 `02 §2.2` 派生类型注册的 schema 对接
- **可复用锚点**：点名 05 §2.5 正是本小节的首个复用案例 · 未来 M6 evolution 的 content_sha256 也应沿用本小节
- **kernel 不承诺的部分**：具体哈希算法实现（sha256 库版本）· canonical YAML 工具的语言绑定（bash/python/kotlin）· 这些留工具链层决定

### 4.3 R24 · 04 §5.1 补 `sha_changed` 作为 `modified` 的 alias（@v1.1 → @v1.2）

**落点**：`04 §5.1 snapshot_diff 算子契约` 的字段表中 `modified` 行。

**修订动作**：

- 保留 `modified` 字段类型 / 语义 / 必填性不变
- 字段表下方追加一段：

  ```
  v1.2 新增（本 proposal S2 R24）：
  - snapshot_diff 输出新增 sha_changed 字段作为 modified 的 alias（两字段值必须同语义）
  - 新实施的 04 消费方（含 05-drift-propagation §2.4 对偶表 / M6 evolution）应优先使用 sha_changed；modified 保留为向下兼容 alias
  - 工具输出层面：snapshot_diff 脚本的 JSON 输出可同时写入 modified 和 sha_changed 两字段（值相同），消费方任选读一个即可
  - 向下兼容承诺：v1.2 起至少保留两个小版本周期（v1.2 + v1.3）同时输出双名；v1.4 起允许工具只输出 sha_changed（但 04 字段表仍保留 modified 文档条目供查阅）
  ```

### 4.4 R23 · 02 §5.3.1 扩为通用 lineage 特化注册表（@v1.2 → @v1.3）

**落点**：`02 §5.3.1 snapshot 特化`（M4 路径 B 新增）。

**修订动作**：

- 将 §5.3.1 标题改为 "**lineage 特化注册表**（v1.2 首设 · v1.3 扩为通用注册表）"
- 现有"snapshot 特化"条目保留不变（作为表中首条）
- 新增通用表格结构：

  ```
  ### 5.3.1 lineage 特化注册表（v1.3）

  当 lineage_query 的目标 URN 的 kind 落在下表时，查询器应用对应的特化规则：

  | kind | depends_on 等价替身 | 特化规则来源 | 强度 |
  |------|-------------------|------------|-----|
  | `snapshot` | body.frozen_artifacts[*].artifact_urn | 04-version-snapshot.md §3.2.2（v1.2 首设） | strong（一律） |
  | `drift` | body.diff_base.old_snapshot_urn + body.diff_base.new_snapshot_urn | 05-drift-propagation.md §2.5（v1.3 新增） | strong（一律） |

  注册表规则：
  - 特化条目由"派生 kind 的 kernel 文档"反向注册（02 自身不主动列举）· 未来 M6 evolution 若引入新 kind 且有 depends_on 等价替身需求，走同样路径在本表追加条目
  - 所有特化条目的 depends_on 解析路径在 kind 分支内实施，不走默认的 front-matter.depends_on 解析
  - 工具实现方：lineage-query.sh 需在 URN kind 分支中匹配本表，命中时按本表规则解析；未命中时回落到默认路径
  ```

**副作用**：05 §2.5 末尾的"等价替身规则"（R17 补述中已标记"R23 → 本 proposal 处理"）从"路径 A 单边声明"变为"02 侧已反向对接" · 跨篇契约闭环。

### 4.5 R25 · 02 §2.2 派生类型注册补 `wordcheck_policy` 字段（@v1.2 → @v1.3）

**落点**：`02 §2.2 派生类型的注册方式`（v1.1 新增）的 schema 字段表。

**修订动作**：

- 现有六字段（`artifact_type` / `parent_type` / `description` / `schema_version` / `owner` / `stability`）保留不变
- schema 追加第 7 字段：

  ```
  | wordcheck_policy | enum?: machine_generated / content_safe_default | 可选（默认 content_safe_default）· 声明本派生类型的 body 是否自动继承 wordcheck_exempt：
  - machine_generated：本派生类型的 body 由确定性算法产出（无自然语言 / 无人工撰写），自动视为 wordcheck_exempt: true。典型：drift.propagation_record / snapshot.diff / evolution 未来的机器产物
  - content_safe_default：本派生类型的 body 可能含自然语言（人工撰写 / 半自动撰写），走默认的 kernel-wordcheck.sh 扫描流程。典型：proposal / decision_log / review
  ```

- 表格下方补一段语义说明：

  ```
  wordcheck_policy 的声明由派生类型注册方在 02 §2.2 表中明示；未显式声明的派生类型按 content_safe_default 处理（兜底安全）。
  一旦声明 machine_generated，所有符合该 artifact_type 的实体 front-matter 无需再单独写 wordcheck_exempt: true，kernel-wordcheck.sh 自动跳过扫描。
  工具实施方：kernel-wordcheck.sh 加载 02 §2.2 派生注册表 → 构建 machine_generated 类型的 exempt 缓存 → 扫描时先查缓存再决定是否跳过。
  ```

**副作用**：05 front-matter 的 `wordcheck_exempt: true` 在 02 注册 drift.propagation_record 为 `machine_generated` 后变为"注册自动继承 · 显式声明可省略但保留不冲突"· 路径 B 完成 · 05 §9 Q5 的注释可从"02 侧落地归 R25"改为"已 consumed"。

### 4.6 Step 5 · 05 跟随升版 @v1 → @v1.1（draft 内小升）

**落点**：`05-drift-propagation.md` 多处锚点注释更新。

**修订动作**：

- **front-matter**：`rev: v1 → rev: v1.1`· `last_modified_at` 刷新为 S5 执行时刻
- **§2.5 末尾"等价替身规则"注释**：
  - 从 "本对偶规则的 02 侧反向对接归入 R23 → `m5_drift_kernel_alignment@v1` proposal"
  - 改为 "本对偶规则的 02 侧已反向对接 · 见 `02 §5.3.1 lineage 特化注册表 · kind=drift 条目`（`m5_drift_kernel_alignment@v1` S3 落地 · 2026-04-19 · v1.3）"
- **§10 前置契约表**：
  - `04 §5.1` 引用描述：从 "snapshot_diff 字段 `modified`" 改为 "snapshot_diff 字段 `modified/sha_changed` 双名（04 @v1.2 起）"
  - 新增一行：`04 §3.2.3` · canonical YAML 通用工具实施建议 · 提供 key 正则 + `pick_fields` 范式供 drift content_sha256 复用
  - `02 §5.3.1` 引用描述：从 "snapshot 特化查询规则" 改为 "lineage 特化注册表 · 含 `kind=drift` 条目（02 @v1.3 起）"
- **§8.1 rev_history** 追加一行：

  ```
  | v1.1 | 2026-04-19 <S5 时刻> | `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1` | 跟随 04/02 升版的锚点注释更新：§2.5 R23 对接完成记录 · §10 新增 04 §3.2.3 引用 + 04 §5.1 改双名 + 02 §5.3.1 改"注册表"措辞 · §9 Q1/Q5 改 consumed。draft 内小升（status 保持 draft）· 为 §8.2 门控 #2/#3/#4 的 Step 5 工具链验证留出窗口期 |
  ```

- **§9 Q1 裁定补注**：从"路径 B 归 R24"改为"R24 已于 `m5_drift_kernel_alignment@v1` S2 consumed（04 @v1.2 · 双名落地）"
- **§9 Q5 裁定补注**：从"路径 B 归 R25"改为"R25 已于 `m5_drift_kernel_alignment@v1` S3 consumed（02 @v1.3 · `wordcheck_policy` 字段落地）"

---

## 5. 风险与不确定性

| 风险 | 可能性 | 影响 | 缓解 |
|------|-------|-----|------|
| **R22 的 N 条同 txn 在 v0.1 JSONL 实现上做不到严格原子（N 越大回滚窗口越长）** | 中 | 中 | 沿用 m4 S1 同款缓解策略："v0.1 实现为顺序写 + 失败回滚 · 对调用方呈现为原子但 crash 时可能遗留孤儿 · `--check-orphan` 扫描兜底"· drift 的 N=2 比 snapshot 的 N=3 回滚窗口更短 · 风险更低 |
| **R23 的注册表在未来 kind 爆炸时可能演化为查找热点** | 低 | 低 | kernel 封板 kind（01 §2.1）· 派生 kind 严格受 02 §2.2 派生注册机制约束 · 注册表长期维持个位数条目 · 不构成真实查找压力 |
| **R24 的双名期若工具实施方不一致（A 只写 modified · B 只读 sha_changed）将导致 drift 与 snapshot_diff 对不齐** | 中 | 中 | 本 proposal §4.3 明确要求 snapshot_diff 工具**同时**写入两字段（值相同）· 消费方任选读一个即可 · 05 §2.4 对偶表 + `scripts/piao-drift-compute.sh` MVP 按 `sha_changed` 单名读即可与 snapshot_diff 对齐 |
| **R25 的 `machine_generated` 在 kernel-wordcheck 实施时可能需要重跑扫描缓存** | 低 | 低 | 配套 Step 5 的 `scripts/piao-drift-compute.sh` 产出 drift artifact 时会触发 kernel-wordcheck 的首次 `machine_generated` 分支测试 · 若发现 bug 可在 v0.1 工具层打补丁（kernel 契约不受影响） |
| **R21 的 key 正则 `^[a-z_][a-z_0-9]*$` 与现有 kernel 文档 front-matter 的实际 key 不匹配** | 低 | 高 | 由 §3 **S0 预检**（独立前置步骤）负责兜底：执行 `grep -oE "^[A-Za-z_][A-Za-z_0-9]*:" docs/piao-pipeline/kernel/0{1,2,3,4,5}-*.md` · 若发现不符合的 key（如驼峰命名 / 含连字符）· 先在 `m4-toolchain-review` 补一条债再决定正则放宽（与 m4 `T5` 同模式）· 预期**通过**：既有 kernel front-matter 全部采用 snake_case |
| **S5 跟随升版后 05 从 @v1 → @v1.1 仍保持 draft · 与 `01 §4.2` "升版需从 published 基线"有看似张力** | 低 | 低 | 按 `01 §10.1` draft 允许内部小升（M4 `04 @v1 draft → @v1.1 draft` 先例 · 已接受范式）· draft 状态下的 rev 小升**不**触发 `supersedes` · 仅用于锚点校验期的版本标识 |
| **升版后四文档互相引用的锚点失效** | 低 | 高 | 引用均为节号（如 `§5.3.1` / `§3.2.3`）· 小升仅新增不删旧 · 锚点稳定（与 `m2` / `m4_snap_align` proposal 同风险模式） |

---

## 6. 完成条件（Definition of Done）

本 proposal 在以下所有条件全部满足后发 `proposal.implemented` 事件并归档：

- [ ] **S0 预检通过**：key 正则兼容性扫描显示 kernel front-matter 全部匹配 `^[a-z_][a-z_0-9]*$`（若不通过需补债回退 · 见 §3 执行顺序图 S0）
- [ ] **S1 落地**：`03-layered-architecture.md` draft 原地修订（§3.3.1 泛化为 N 事件同 txn），不升 rev（按 `01 §10.1` draft 契约）
- [ ] **S2 落地**：`04-version-snapshot.md @v1.1 → @v1.2` published（含 §3.2.3 canonical 通用实施建议 + §5.1 `sha_changed` alias），rev_history 追加一行
- [ ] **S3 落地**：`02-artifact-model.md @v1.2 → @v1.3` published（含 §5.3.1 注册表改写 + §2.2 `wordcheck_policy` 字段），rev_history 追加一行
- [ ] **S4 落地**：03 draft 的 rev_history（若有）追加一行"v1（原地追述 · 路径 B 消化）"· 参考 05 §8.1 或 M4 范式
- [ ] **S5 落地**：`05-drift-propagation.md @v1 (draft) → @v1.1 (draft)`（§2.5 / §10 / §8.1 rev_history / §9 Q1 Q5 四处锚点注释同步更新），status 保持 draft 不变
- [ ] **S6 落地**：`m5-drift-draft-review.md` 追加 §5 路径 B 完成记录（与 §3.2 R21–R25 表对齐 · 逐条 consumed 表 · 对标 `m4-snapshot-draft-review @v1 §6` 范式）
- [ ] `./scripts/kernel-wordcheck.sh --ci`（如有）或等价命令在 `docs/piao-pipeline/kernel/` 下返回 exit 0（BAN 违规数不增加；WARN 数不增加）
- [ ] IDE lint 对四份修订后文档各自 0 错误
- [ ] `05 §10` 前置契约表中声明的新增锚点（`04 §3.2.3` / `02 §5.3.1` 注册表条目）在源文档内可找到
- [ ] Step 5（Step 2 路径 B 完成后的工具链实施）准备就绪：`scripts/piao-drift-compute.sh` 的接口契约已由 04 @v1.2 / 02 @v1.3 / 05 @v1.1 锚定

---

## 7. 完成后的下游触发

- **`05-drift-propagation.md @v1.1 (draft) → @v1.1 (published)`**（**路径 B 后的下一步**）：
  - 走 §8.2 门控 #2/#3/#4：`scripts/piao-drift-compute.sh` 产出至少一条真实 drift artifact · R1–R5 五条硬约束未被反例证伪 · `m5-final-decisions.md` 产出
  - 预计路径：Step 5 的 `piao-drift-compute.sh` MVP 实施（对标 M4 阶段 α 的 `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh`） + 产出端到端 drift artifact + final-decisions 快照封冻
  - 05 published 后 `m5_drift_kickoff@v1` 工作流 D 完结 · `m5_drift_kickoff@v1` 可标 `superseded`（与 `post-m1-kickoff @v1` 当前状态对称）
- **`M1-debt-ledger @v6 → @v7`**（如适用）：review §3.2 的 R21–R25 五条 consumed 登记
- **`m5-drift-draft-review.md` 状态更新**：§4.3 Step 2/3/4 推进 · §5 路径 B 消化记录追加
- **下一 milestone**：M6 Evolution 模型起稿（05 published + `m5-final-decisions` 封冻后 · 对标 M5 起稿节奏 · 由 `m6_evolution_kickoff@v1` proposal 启动）

---

## 8. 不做的事（scope out）

本 proposal **明确不包含**以下内容，避免范围蔓延（严格对齐 `m4_snapshot_kernel_alignment §8` 的 scope out 范式）：

| 不做的事 | 理由 |
|---------|-----|
| 新增任何 L1 事件类型 | 违反 `03 §3.1` 封板；R22 仅泛化"N 条同 txn"承诺，不触达 10 类事件枚举 |
| 新增任何 kind | 违反 `01 §2.1` 封板；R23 注册的 `kind=drift` 特化是读端 lineage 规则，drift kind 本身早在 01 封板时即存在 |
| 重构 `02 §2.2` 派生注册机制 | R25 仅追加可选字段 `wordcheck_policy`，schema 其它六字段不动 |
| 修改 `04 §3.2.1` 五必填 key / canonical 五步 | R21 新增的 §3.2.3 是下钻实施建议，不动 §3.2.1 既有 schema |
| 修改 `04 §5.1` `modified` 字段类型或必填性 | R24 仅追加 alias `sha_changed`，向下兼容 |
| 修改 lineage_query 函数签名 | R23 仅在 §5.3.1 注册表内扩条目，函数签名不变 |
| `scripts/` 下的工具实现（含 `piao-drift-compute.sh` / `kernel-wordcheck.sh` 的 `machine_generated` 分支） | 本 proposal 只承诺契约；工具实施留 M5 Step 5 / `m4-toolchain-review` 后续补债条目 |
| 05 draft → published 门控 #2/#3/#4 | Step 5 的工具链实施 + final-decisions 产出负责 · 本 proposal 仅完成门控 #1 之后的"契约侧路径 B 闭环" |
| M6 Evolution 模型起稿 | 下一 milestone 职责 · 由 `m6_evolution_kickoff@v1` proposal 启动 |
| 历史 drift artifact 迁移 | 当前尚无 published drift artifact（05 仍 draft · 工具链未实施） · 无迁移问题 |

---

**本 proposal 状态**：published · rev v1（created 2026-04-19 14:20 · last_modified 2026-04-19 14:22）

**Self-review 签收**（2026-04-19 14:22）：
- 结构完备性 · 对标 `m4_snapshot_kernel_alignment@v1`：§1 rev 升降矩阵 ✅ · §1.2 为什么不算大升 ✅ · §1.3 下游影响 ✅ · §2 动作矩阵 ✅ · §3 执行顺序（含 S0 预检）✅ · §4 修订锚点（§4.1–§4.6 六节）✅ · §5 风险表（7 行）✅ · §6 DoD（10 项含 S0）✅ · §7 下游触发 ✅ · §8 scope-out（9 行）✅
- 锚点准确性 · 对 05 路径 A 已 consumed 的 R17/R19 引用（§10 锚点注释更新 · §8.1 rev_history 14:10 时刻）· 对 M4 遗留债的合并（`m4-toolchain-review §2.5 T5` 并入 R21）· 对 01 §10.1 draft 契约的遵守（05 跟随升版保持 draft · 03 原地不升 rev）· 全部正确
- 体量合理性 · 新增 ~100 行散布 4 文档 · 与 M4 的 80–100 行同量级
- 风险闭环 · S0 预检护栏显式化（§3 新增独立前置步 + §5 风险表行文对齐 + §6 DoD 勾选项）· 消除原 draft 中 "风险描述说要做但执行顺序未列" 的隐患
- 签收结论：**符合 kernel proposal 格式范式 · 具备进入执行阶段的条件 · 自此升 published**

**上游锚点**：
- `urn:piao:artifact:kernel:m5_drift_draft_review@v1 §3.2`（R21–R25 来源）
- `urn:piao:spec:architecture:drift_propagation@v1 (draft @ 路径 A 消化后 · 2026-04-19 14:10)`（05 前置锚点已声明）
- `urn:piao:spec:architecture:version_snapshot@v1.1`（升版目标 · 至 @v1.2）
- `urn:piao:spec:architecture:artifact_model@v1.2`（升版目标 · 至 @v1.3）
- `urn:piao:spec:architecture:layered_architecture@v1 (draft)`（原地修订目标）

**下游候选**：
- `03-layered-architecture.md`（draft 原地修订 · 不升 rev）
- `04-version-snapshot.md @v1.1 → @v1.2`
- `02-artifact-model.md @v1.2 → @v1.3`
- `05-drift-propagation.md @v1 (draft) → @v1.1 (draft)`（跟随升版 · Step 5 前置）
- `m5-drift-draft-review.md @v1`（§5 追加路径 B 完成记录）
- `m5-final-decisions.md @v1`（待 05 published 后产出 · M5 milestone 收官）

**关闭候选**：`urn:piao:snapshot:kernel:m5_drift_kernel_alignment_complete@v1`（路径 B 完成快照 · 与 05 升 @v1.1 同步产出）
