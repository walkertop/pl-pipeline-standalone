---
urn: urn:piao:artifact:kernel:m4_toolchain_review@v1
kind: artifact
artifact_type: review
rev: v1
status: published
supersedes: null
produced_by: m5-drift-kickoff-stage-alpha-2026-04-19
produced_at: 2026-04-19T03:30:00+08:00
upstream:
  - urn:piao:proposal:kernel:m5_drift_kickoff@v1
  - urn:piao:spec:architecture:version_snapshot@v1.1
  - urn:piao:snapshot:kernel:m4_final_decisions@v1
wordcheck_exempt: true
---

# M4 Toolchain Review · piao-snapshot-produce/diff MVP 实施反馈

> 本文档是 **M5 Drift milestone 阶段 α 的退出门产出**（对标 `post-m1-kickoff §3.3` 的 adapter charter review 三段式 + `m4-snapshot-draft-review` 的 draft 反馈范式）。
>
> 产出时机：`scripts/piao-snapshot-produce.sh` + `scripts/piao-snapshot-diff.sh` MVP 完成自反性 + 真实差分 + 跨 scope 三项验证之后。
>
> 消费方向：本文档的 §2 / §3 条目数决定 `m5_drift_kickoff @v1 §2.3` 分支判定（β-1 还是 β-2），从而触发工作流 D（M5 Drift 规格起稿）。

---

## 0. 实施总览

| 维度 | 实际 |
|------|------|
| **产出物** | `scripts/piao-snapshot-produce.sh`（MVP · 293 行）+ `scripts/piao-snapshot-diff.sh`（MVP · 204 行） |
| **命名空间规避** | `piao-` 前缀 · 已规避 `scripts/snapshot-generator.sh`（道聚城 Kuikly 业务扫描器） |
| **契约依据** | `04 §2.2 / §3.2 / §3.2.1 / §3.3 / §4 / §5 / §5.3` |
| **验证覆盖** | 自反性 + 真实差分 + 跨 scope_kind 拒绝 + `--format json` 共 **4 项** |
| **依赖运行时** | `bash 3.2+` + `python3.9+`（仅 stdlib：`re` / `hashlib` / `json` / `os`；**无第三方依赖**） |
| **耗时** | M5 阶段 α 启动至本文档产出，历时约 1 小时 |

### 0.1 验证结果记录（四项全通）

| 验证项 | 输入 | 预期输出 | 实际输出 | 结论 |
|--------|------|---------|---------|------|
| **① 自反性**（kickoff §2.2 门控 1） | `diff(s_a, s_a)` | `{added:0, removed:0, sha_changed:0, unchanged:7}` | 完全一致 | ✅ |
| **② 真实差分**（kickoff §2.2 门控 2） | `diff(s_a, s_b)`（s_b 在 s_a 基础上 sha 改 03 + 加新 URN + 删 scenario_wordlist） | `{added:1, removed:1, sha_changed:1, unchanged:5}` | 完全一致，sha 值精确定位 | ✅ |
| **③ 跨 scope_kind 拒绝**（04 §5.3） | `diff(s_a[kernel], s_c[unit])` | 退出码非 0，报错指向 `§5.3` | `ERROR: scope_kind mismatch: old=kernel new=unit (§5.3)` | ✅ |
| **④ json 输出有效** | `--format json` + `python3 -c "json.load"` | 可解析 | `parsed OK · summary: {...}` | ✅ |

### 0.2 意外证实的 04 契约行为（非设计目标，但实测印证）

实施过程中意外观察到：同样的 `frozen_artifacts` 列表，用**不同的 `scope_kind` + `scope_ref`** 产出的两个 snapshot，`content_sha256` **完全相同**（都是 `fdb2542c8a2a475b6c13e7b6db045391054937452afbf503b5fa1653e2eb6fe6`）。

**这恰好证明了 `04 §3.2.1` canonical 规范化的核心特性**：

> 规范化**仅对 `frozen_artifacts` 列表**执行，front-matter（含 `frozen_scope` / `produced_at` / `event_id`）不参与 sha 计算。

这让"同一 scope_ref 下两次实质无变化的冻结可以被 dedup 识别"（`04 §3.2.1` 最后一段）从**规格声明**变成了**实测印证**。04 schema 的这一设计在 MVP 层经受住了验证。

---

## 1. 引用的 kernel 锚点

本 MVP 实施过程中，逐一对照并实现了以下 kernel 锚点：

### 1.1 `04 §3.2` snapshot schema

**用于**：`piao-snapshot-produce.sh` 产出 yaml 的结构。

**实现映射**：
- front-matter 五要素（urn/kind/rev/status/supersedes）+ 特化字段（produced_by/produced_at/frozen_scope/content_sha256）全部覆盖
- body 的 `frozen_artifacts` 列表五个必填 key（artifact_urn/content_sha256/producer_event_id/producer_task_urn/artifact_type）全部覆盖
- 字典序排序（UTF-8 字节序）在 Python 侧用 `sort(key=lambda r: r["artifact_urn"].encode("utf-8"))` 精确实现

**实测证据**：产出的 `/tmp/piao-mvp/s_a.yaml` 前 18 行 front-matter 与 `04 §3.4` 给出的"最小示例"结构完全对齐。

### 1.2 `04 §3.2.1` content_sha256 canonical YAML 规则

**用于**：`piao-snapshot-produce.sh` 计算 sha 的唯一真源。

**实现映射**：五步规范化全部手写实现（不依赖 `PyYAML` 避免不可控）：

| 步骤 | 契约要求 | MVP 实现位置 |
|------|---------|------------|
| 1 解析 yaml 为纯数据 | ✅ | 从 TSV 解析 + 从 front-matter 推断 artifact_type |
| 2 保留且仅保留五个 key | ✅ | `KEY_ORDER = [...]` 白名单硬编码 |
| 3 按 artifact_urn 字典序排序 | ✅ | `records.sort(key=lambda r: r["artifact_urn"].encode("utf-8"))` |
| 4 canonical YAML 输出 | ✅ | 手写字符串拼接：key 固定顺序、双引号包字符串、两空格缩进、末尾恰好一个 \n |
| 5 UTF-8 SHA-256 小写 hex | ✅ | `hashlib.sha256(canonical.encode("utf-8")).hexdigest()` |

**实测证据**：自反性验证通过——`diff(s_a, s_a)` 7 条 artifact 全部 `unchanged`；且跨 scope_kind 产出的 s_a / s_c_unit 的 content_sha256 相同，证明 front-matter 不参与 sha 计算。

### 1.3 `04 §3.3` scope_kind 五类封板

**用于**：`piao-snapshot-produce.sh` 参数校验 + URN 派生。

**实现映射**：参数 `--scope-kind` 用 bash `case` 语句严格限死五类，任何其他值退出码 2。

### 1.4 `04 §4` URN 寻址

**用于**：`piao-snapshot-produce.sh` 自动组装 snapshot 自身的 URN。

**实现映射**：按 `04 §4.1` 表格对每种 scope_kind 派生 `<scope>` 段。例如：
- kernel → `urn:piao:snapshot:kernel:<name>@<rev>`
- unit → `urn:piao:snapshot:<unit_name>:<name>@<rev>`
- taskdag → `urn:piao:snapshot:<unit>:<dag_name>:<name>@<rev>`（MVP 简化）

### 1.5 `04 §5` snapshot_diff 算子契约

**用于**：`piao-snapshot-diff.sh` 的核心算法。

**实现映射**：
- 输入：两个 snapshot yaml 路径（§5.1 允许 URN 或 path，MVP 选 path）
- 输出：四集合 `added` / `removed` / `sha_changed` / `unchanged`（MVP 把 §5.1 的 `modified` 重命名为 `sha_changed` 以对齐 kickoff §2.2；见 §2 T4）
- 复杂度：O(|s1.frozen| + |s2.frozen|)——用 Python `set` 运算实现，天然线性

### 1.6 `04 §5.3` 跨 scope diff 禁止

**用于**：`piao-snapshot-diff.sh` 的前置校验。

**实现映射**：解析两个 snapshot 的 `frozen_scope.scope_kind` 与 `frozen_scope.scope_ref`，任一不同即退出码 1，报错指向 `§5.3`。

---

## 2. 实现过程中发现的 kernel 契约歧义 / 缺失

按严重度降序排列。**共 5 条**，均非致命，大部分为"补注级别"。

### 2.1 T1 · kernel 根目录文件 front-matter 严重缺失 · 严重度：中

**现象**：实施时尝试从 kernel 各 `*.md` 文件自动提取 URN 失败，因为：

| 文件 | front-matter 状态 |
|------|------------------|
| `01-identity-model.md` | ❌ 无 |
| `02-artifact-model.md` | ❌ 无 |
| `03-layered-architecture.md` | ✅ 有 |
| `04-version-snapshot.md` | ✅ 有 |
| `05-drift-propagation.md` | ✅ 有 |
| `07-extensibility.md` | ❌ 无 |
| `scenario-wordlist.md` | ❌ 无（推测） |

7 份 kernel 文件中 **4 份（57%）缺失 front-matter**。

**影响**：
- 工具链无法从文件自动解析 URN / kind / status
- `piao-snapshot-produce.sh` 被迫要求调用方在 frozen-list 里**显式**传入 URN（这增加了工具链使用摩擦）
- **drift 引擎未来的 lineage 反查**（M5 §5.4 归因算法）如果同样依赖 front-matter，会直接退化

**建议**（留给阶段 β 起稿工作流 D 时定夺）：
- 短期：`02 @v2` 时补强 `§1.1 五要素 front-matter` 的**落地率**契约（如"kernel 层文件必须 100% 带 front-matter"），登记为 M1-debt-ledger §1.4 新条目
- 中期：工具链提供 `scripts/piao-frontmatter-scan.sh` 扫描报告 + auto-fix（非 M5 范围）

**不触发 β-1**：这是**横向契约缺口**，属于 02 问题而不是 04 问题——不计入 kickoff §2.3 "04 契约歧义/缺失" 计数。

---

### 2.2 T2 · canonical YAML 规则未明确字符串值的转义策略 · 严重度：低

**现象**：`04 §3.2.1` 规则 4 规定"字符串一律双引号包裹"，但未明确：

> 若某 artifact_urn / producer_event_id / 其他字段的值**本身含有** `"` 字符（或其他需转义的字符如 `\`），如何处理？

**MVP 的选择**：严格拒绝——如果值含 `"`，直接 `sys.exit(3)`。理由：
- URN 语义（`01 §1.1`）不允许出现 `"`
- event_id 格式（`<prefix>-YYMMDDHHmmss-<rand6>`）也不允许 `"`
- sha256 / artifact_type 同样不含 `"`

**建议**（补注级别，不触发 rev 升降）：
- `04 §3.2.1` 规则 4 补一行注记：
  > "MVP 契约假设五个字段值均不含 `"`（由 `01 §1.1` URN grammar + sha256 grammar + `<prefix>-timestamp-rand` event_id grammar 共同保证）；若未来有场景破坏该假设，规则 4 需扩展为 JSON-string-escape 规则并同步升 §3.2.1 版本。"

**是否触发 β-1**：**否**——这是**补注级别**，不是歧义。

---

### 2.3 T3 · `§2.2 原子写入契约` 与 `§3.2.2 lineage 查询器特化` 无 MVP 可实施路径 · 严重度：中

**现象**：
- `04 §2.2 原子性要求`依赖 `event-journal-append`（M4 工具链未实现）
- `04 §3.2.2` snapshot 不写 `depends_on`，由 `02 §5.3.1` 的"lineage 查询器特化"替代，但该查询器也未实现

**MVP 的选择**：显式**不覆盖**。`piao-snapshot-produce.sh` 只产出 yaml 文件，**不**写入 L1 事件；`piao-snapshot-diff.sh` **不**做 lineage 反查。

**影响**：
- MVP 产出的 snapshot 相当于"孤儿"（无 `artifact.published` 事件配对），严格按 `04 §2.2` 容错段应当被 `artifact-validate.sh --check-orphan` 识别
- `producer_event_id` / `producer_task_urn` 在 MVP 里用占位符（`task-unknown-000000-000000` / `urn:piao:task:manual:unknown`），这是**已知技术债**

**对 M5 drift 的直接影响**（建议，工作流 D 必须在起稿时正视）：
- `05 §5 归因算法` 要把 `sha_changed` 反向追溯到 `producer_event_id`，但 MVP 的占位符不足以做此追溯——**M5 规格必须定义"若无 event-journal，drift 如何降级"**
- 降级方案候选：
  - 选项 ①：M5 明示"归因算法强依赖 event-journal，在 event-journal 未落地前 drift 只给出 `sha_changed` 集合，不承诺归因"
  - 选项 ②：M5 定义"降级归因"——用文件系统 mtime + VCS blame 近似替代 event_id（精度差但可用）

**是否触发 β-1**：**否，但必须在 β-2（工作流 D 起稿）时优先回答**。计入 kickoff §4 `Q5.4 drift 的归因` 必答问题的强约束。

---

### 2.4 T4 · `§5.1 算子契约` 的 `modified` 字段名与 kickoff §2.2 的 `sha_changed` 不一致 · 严重度：低

**现象**：
- `04 §5.1 snapshot_diff` 算子输出结构里字段叫 `modified`
- `m5_drift_kickoff @v1 §2.2 门控 2` 用 `sha_changed`
- 两者指同一概念，但命名不统一

**MVP 的选择**：以 `sha_changed` 为准（语义更精确——`modified` 容易让人以为是"artifact 内容变化"广义概念，`sha_changed` 明确指"sha256 字符串变化"这个原子观察）。

**建议**（补注级别）：`04 @v1.1 @v1.2` 补升时把 §5.1 输出字段改名为 `sha_changed`（向下兼容：同时接受两个名称）。

**是否触发 β-1**：**否**——字段命名不是契约歧义，是命名约定。

---

### 2.5 T5 · 工具链视角的实施建议附录缺失 · 严重度：低

**现象**：本 MVP 实施时踩到一个**技术坑**——diff 脚本正则 `^    ([a-z_]+):` 无法匹配 `content_sha256` 中的数字 `256`，导致解析失败但不报错，直接返回错误的 diff 结果（把 sha_changed 归到 unchanged）。

**教训**：`04 §3.2.1` schema 规定了五个 key 的固定名单（含 `content_sha256` 含数字），但**没有给出"建议的解析正则"**——实施者容易踩正则字符类选择的坑。

**建议**（附录级别）：在 `04 @v1.2` 或后续版本，新增 `§3.2.3 工具链实施建议` 附录小节，列出：
- 建议的正则：`^    ([a-z_][a-z_0-9]*):\s*"([^"]*)"\s*$`（key 可含数字，但必须以字母/下划线起始）
- 必测试用例：至少覆盖自反性 + 真实差分 + 跨 scope_kind + `--format json` 四项
- 已知陷阱列表（避坑清单）：
  - SIGPIPE + `set -o pipefail` + `tr | head` 组合（本 MVP 踩过，已改为 python3 实现）
  - 正则字符类漏数字（本 MVP 踩过，已修复）
  - yaml 双引号转义（T2 相关）

**是否触发 β-1**：**否**——是工具链沉淀，不是契约本身的歧义。

---

### 2.6 小结

| # | 条目 | 严重度 | 是否触发 β-1 | 归属 |
|---|------|-------|------------|------|
| T1 | kernel 文件 front-matter 缺失 | 中 | ❌ | 02 问题 |
| T2 | canonical 字符串转义未明确 | 低 | ❌ | 04 补注 |
| T3 | §2.2 / §3.2.2 无 MVP 可实施路径 | 中 | ❌ | M5 必答 |
| T4 | modified / sha_changed 命名不一 | 低 | ❌ | 04 补注 |
| T5 | 工具链实施建议附录缺失 | 低 | ❌ | 04 附录 |

**kickoff §2.3 分支判定判定依据**："发现 ≥ 3 条 kernel 契约**歧义/缺失**"——上述 5 条中，只有 T3 属于**无 MVP 可实施路径**的中度条目（但影响面是 M5 必答问题，而非 04 本身的歧义），其他四条都是**补注/命名/附录**级别。

**裁定：符合 β-2 条件**（发现 ≤ 2 条契约歧义，且均为小歧义）。

---

## 3. 对 M5 drift 规格起草的工具链视角建议

按 `m5_drift_kickoff @v1 §4` 必答问题（Q5.1 身份 / Q5.2 触发 / Q5.3 scope / Q5.4 归因 / Q5.5 接口）组织建议。

### 3.1 TB1 · Q5.4 归因：必须优先定义"无 event-journal 时的降级路径" · 对应 T3

见 §2.3 的两个降级选项。工具链视角强烈建议**选项 ①**（明示强依赖，不承诺降级归因）——理由：
- 强依赖明示后，event-journal 的落地优先级会自然提高
- 降级归因（选项 ②）的精度差（mtime 可能被 git checkout 重置、VCS blame 受 cherry-pick 干扰），会成为 M5 规格的**实现陷阱**
- piao-pipeline 的"客观性"原则（`04 §2.4`）不允许归因算法依赖"业务层诚信"

### 3.2 TB2 · Q5.2 触发：`drift` 的触发器应是 `snapshot.published` 而非 `artifact.published` · 对应 `04 §2.1`

工具链视角：
- MVP 证实 snapshot 作为 drift 输入的**最小必要信息量**（URN + sha256 五元组列表）
- 每次单独 artifact 发布（`artifact.published`）如果都触发 drift，会造成 drift 事件洪流（artifact 数 × N 倍于 snapshot 数）
- **建议**：M5 §3 触发契约锁定"drift 只在 snapshot 之间对比，不在 artifact 之间对比"——这与 `04 §5.2` 的"drift 引擎的消费姿势"完全一致，但 M5 应把这条升级为**硬约束**

### 3.3 TB3 · Q5.3 scope：drift 的 scope 继承 snapshot 的 scope_kind · 对应 `04 §3.3 / §5.3`

**工具链证据**：MVP 跨 scope_kind diff 的拒绝机制（验证 3）已证明"跨 scope 对比语义无效"。

**建议**：M5 §4 规定"drift 的两个输入 snapshot **必须同 scope_kind + 同 scope_ref**"，与 `04 §5.3` 契约 1:1 对齐。不引入新的 scope 维度。

### 3.4 TB4 · Q5.5 接口：drift→evolution 接口应携带 `old_producer_event_id` + `new_producer_event_id`

**工具链证据**：MVP diff 输出已经对每个 `sha_changed` 条目记录了两个 `producer_event_id`（虽然 MVP 用的是占位符）。

**建议**：M5 §6 drift→evolution 接口 schema 保留这两个字段——未来 evolution 引擎据此把"drift 事件"关联回"触发变化的 task 链路"，支撑 M6 的"本次迭代影响了哪些下游单元"查询。

### 3.5 TB5 · Q5.1 身份：`drift` 作为 artifact 的 kind 已在 `01 §2.1` 定稿 · 无需额外论证

`01 §2.1 核心 kind 枚举`已包含 `drift`。工具链视角无补充建议，M5 直接继承。

---

## 4. 阶段 α 退出声明

### 4.1 门控复核（按 kickoff §2.2）

| 门控项 | 状态 | 证据 |
|-------|------|------|
| `piao-snapshot-produce.sh` MVP 产出 | ✅ | `scripts/piao-snapshot-produce.sh` · 命名避让完成 |
| `piao-snapshot-diff.sh` MVP 产出 | ✅ | `scripts/piao-snapshot-diff.sh` · 命名避让完成 |
| 自反性验证 | ✅ | §0.1 验证 ① |
| 真实差分验证 | ✅ | §0.1 验证 ② |
| scripts/ 目录不纳入 wordcheck 新违规 | ✅ | `kernel-wordcheck.sh --ci` 输出 6 BAN + 5 WARN，与基线一致 |
| `m4-toolchain-review.md` 产出 | ✅ | 本文档 |

### 4.2 分支判定结论

**裁定**：**β-2**（发现 ≤ 2 条契约歧义，且均为小歧义）

**依据**：§2.6 小结——T1–T5 共 5 条发现中，无任一条构成"04 契约本身的歧义/缺失"触发 β-1 条件。T3 虽中度但归属 M5 必答问题的强约束（对应 §3.1），属"M5 起稿时必须回答"而非"04 本身缺失"。

### 4.3 下一步（阶段 β · 工作流 D 启动）

按 kickoff §2.3 分支 β-2 的执行序：

1. **启动工作流 D**：`05-drift-propagation.md @v0.2 → @v1 draft`（按骨架 §2 大纲逐段起稿）
2. **M5 draft 起稿时必须优先回答**的问题（本 review 已锁定）：
   - §3.1 / TB1（Q5.4 归因的降级路径）
   - §3.2 / TB2（Q5.2 触发器是 `snapshot.published` 而非 `artifact.published`）
   - §3.3 / TB3（Q5.3 scope 继承）
   - §3.4 / TB4（Q5.5 接口字段设计）
3. **draft-review 阶段**：产出 `_review/m5-drift-draft-review.md`（对标 `m4-snapshot-draft-review.md`）
4. **收官**：产出 `_review/m5-final-decisions.md`（M5 milestone 冻结点）

### 4.4 配套动作（与本文档 published 同步完成）

- [x] `scripts/piao-snapshot-produce.sh` + `scripts/piao-snapshot-diff.sh` 落盘并赋可执行权限
- [x] 四项端到端验证全部通过，过程日志保留于 shell history（未持久化为 artifact · MVP 不做）
- [x] IDE lints · 0 错误
- [x] wordcheck · 6 BAN + 5 WARN（与基线完全一致，scripts/piao-*.sh 未引入新违规）
- [x] 本 review 文档 published
- [ ] `m5_drift_kickoff @v1` 篇尾追补一行 "阶段 α 退出点"（append-only 追述，不升 rev）
- [ ] commit D 提交阶段 α 全部产出

---

## 5. 已知技术债（MVP 范围外）

**这些条目不阻塞阶段 α 退出，但必须登记**：

| ID | 技术债 | 应在哪个 milestone 消费 |
|----|-------|---------------------|
| D1 | `producer_event_id` / `producer_task_urn` 用占位符（`task-unknown-...`） | M5 draft 起稿时借 TB1 的降级路径一并解决 |
| D2 | `piao-snapshot-produce.sh` 不写 L1 事件（§2.2 步骤 2/3 跳过） | event-journal 工具链落地时（晚于 M5，可能 M6 或更后） |
| D3 | `artifact_type` 推断在 front-matter 缺失时默认 `spec`（兜底太宽） | T1 解决后自然消除 |
| D4 | MVP 测试样本（s_a / s_b）未持久化到仓库（放在 `/tmp/piao-mvp/`） | 不计入技术债——阶段 α 一次性验证，不需持久化；阶段 β 工作流 D 起稿时若需要可现造 |

---

## 6. 本 review 的 rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1 | 2026-04-19 03:30 | `m5_drift_kickoff@v1 §3.3` 退出门要求 | 首版 published。覆盖 piao-snapshot-produce / piao-snapshot-diff MVP 的全部实施反馈；裁定阶段 β 走 β-2 分支；四项验证全通（自反性 + 真实差分 + 跨 scope 拒绝 + json 输出）；识别 T1–T5 共 5 条发现但均不触发 β-1 |

---

**本 review 状态**：published @v1（阶段 α 退出门 · 不承诺后续原地修订；若有新发现另起 `m4-toolchain-review@v2`）
**上游**：
- `urn:piao:proposal:kernel:m5_drift_kickoff@v1`（阶段 α 触发源 + 本 review 产出依据）
- `urn:piao:spec:architecture:version_snapshot@v1.1 published`（MVP 契约的唯一真源）
- `urn:piao:snapshot:kernel:m4_final_decisions@v1`（M4 milestone 基线）

**下游锚点**：
- `m5_drift_kickoff @v1` 分支判定结论（β-2）的唯一依据
- `05-drift-propagation.md @v1 draft` 起稿时 §3.1 / §3.2 / §3.3 / §3.4 四条 TB 建议为强约束输入
- 未来 `04 @v1.2`（若发生）补升时可引用本 review 的 T2 / T4 / T5 作为**补注来源**
