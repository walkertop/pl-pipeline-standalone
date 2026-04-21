# kernel · 02 Artifact Model

> 系统生产的"**东西**"叫什么、长什么样、怎么验真、怎么追溯。
> Artifact 是 piao-pipeline 的**基本物质**，事件是它的"运动"，快照是它的"静态截面"，演化是它的"进化压力"。

---

## 0. 定位

**Artifact** = piao-pipeline 产出的**可被其他环节引用的持久化实体**。

它的三大要求：
1. **有身份**：每个 artifact 都有 URN（见 `01-identity-model.md`）
2. **有契约**：每个 artifact 类型有明确 schema，不是 "markdown 想写啥写啥"
3. **有出身**：每个 artifact 必须可溯源回生产它的事件

**非 artifact 的东西**：
- 聊天上下文 / Agent 思考过程 → 只有"痕迹"，不是 artifact
- 命令行临时输出 → 除非被落盘为 log 文件
- IDE 编辑器未保存的草稿 → 不算

**口号**：**"落盘 + 有 URN + 可被引用 = artifact；三缺一不是。"**

---

## 1. Artifact 的五要素契约

任何 artifact 都必须能回答这五个问题：

| 要素 | 回答 | 强制 |
|------|------|------|
| **Identity** | 我是谁？（URN） | ✅ |
| **Shape** | 我长什么样？（schema / 模板） | ✅ |
| **Provenance** | 我是谁做的？什么事件产出的？ | ✅ |
| **Integrity** | 内容是否被篡改？（sha256） | ✅ |
| **Lineage** | 我依赖哪些 artifact？被哪些 artifact 依赖？ | ⚠️ 尽量 |

### 1.1 强制字段（所有 artifact 的 front-matter 必须包含）

不论底层格式是 markdown / yaml / json / kotlin，任何 artifact 文件**开头都必须有一段可机器解析的"头信息"**。

markdown 的约定：

```yaml
---
urn: urn:piao:artifact:prop_confirm:structured_spec@v1
artifact_type: spec.structured
schema_version: 1.0
created_at: 2026-04-18T13:57:00+08:00
created_by_event: task-260418055700-a3f2b1    # event_id（短格式，见 M1 §5）
content_sha256: ""                            # 由工具写入/校验
depends_on:
  - urn:piao:unit:prop_confirm
produced_by:
  actor: agent:migration-analyzer
  task_urn: urn:piao:task:prop_confirm/dag:t_03
  event_id: task-260418055700-a3f2b1          # 与 created_by_event 一致（双轨）
---
```

json 的约定：同样五要素放在顶层字段 `__artifact__` 下。

**校验失败 = artifact 不被承认。**

---

## 2. Artifact 种类（kernel 定义的基础类型）

kernel 层只定义**通用类型**，具体 artifact 子类型由 adapter 在此基础上细化。

| 类型（artifact_type） | 用途 | 默认格式 | 版本化 |
|------|------|------|------|
| `spec` | 需求/契约类文档 | markdown | ✅ |
| `plan` | 计划/TaskDAG | markdown | ✅ |
| `code` | 源代码产物 | 任意 | ✅（随 commit 实质性升版） |
| `config` | 配置文件 | yaml/json/toml | ✅ |
| `report` | 阶段性报告（verify / observe） | markdown / html | ✅ |
| `log` | 结构化日志产物（非事件 journal） | jsonl | ❌（append-only） |
| `snapshot` | 快照文件 | json | ✅ |
| `proposal` | 演化提案 | markdown | ✅ |
| `rule` / `skill` | 规则 / 技能资产 | markdown | ✅ |
| `asset` | 静态资源（图片 / 截图 / apk） | binary | ✅ |

**派生子类型**可在 kernel 类型上细化，但需在 `artifact_type` 字段中**以 `.` 分层**：

```
artifact_type: spec                  # kernel 认的
artifact_type: spec.structured       # 细化（kuikly 迁移场景）
artifact_type: spec.api_contract     # 细化
```

### 2.1 kind 与 artifact_type 的映射关系

URN 中的 `kind` 段（见 M1 §2）和 front-matter 中的 `artifact_type` 字段**不是同一个东西，但必须一致**：

| URN kind | 合法的 artifact_type |
|----------|-------------------|
| `artifact` | 本表所有类型（`spec`, `plan`, `code`, `config`, `log`, `report`, `asset`, ... 及其派生）<br>**也允许以 `artifact.` 为前缀的派生**（如 `artifact.build_output`，见 §2.1.1） |
| `rule` | `rule` 或 `rule.<subtype>`（如 `rule.lint`） |
| `skill` | `skill` 或 `skill.<subtype>` |
| `proposal` | `proposal` 或 `proposal.<subtype>` |
| `snapshot` | `snapshot` 或 `snapshot.<subtype>` |

简言之：**artifact_type 必须等于 kind，或派生自 kind（带 `.` 前缀）**。`scripts/artifact-validate.sh` 强制这个一致性。

#### 2.1.1 `artifact.*` 派生示范（v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 4（R5 / Q5）
> **触发背景**：adapter 撰写"构建产物 / 资产包"类 task 的 `emits` 字段时发现 §2 的基础类型 `spec / plan / code / config / report / log / snapshot / asset` 均不贴切，需要一个通用的"构建过程输出物"派生前缀。

**规则**：`artifact_type` 允许以 kind 名 `artifact` 直接作为 dot 前缀，表达"此产物是通用的 `artifact` 基础类下的一个派生，不归属于某个特定的 kernel 基础类型"。

**合法示例**（建议由 adapter 按需采用，不强制）：

| 派生 artifact_type | 语义 | 典型产出方 |
|-------------------|------|----------|
| `artifact.build_output` | 构建产物（泛指）；具体格式由 adapter 在 front-matter 补充 | build task |
| `artifact.asset_bundle` | 被打包的资产集合（多文件聚合的二进制或归档包） | bundle task |
| `artifact.intermediate` | 流水线中间产物（非最终交付，可能被后续 task 消费后作废） | 中间计算 task |

**对比：何时用 `artifact.*` 而不是既有基础类型**：

| 情境 | 选型 |
|------|-----|
| 产物是源代码/DSL 脚本 | 用 `code` 或 `code.<subtype>` |
| 产物是配置文件 | 用 `config` 或 `config.<subtype>` |
| 产物是报告/文档 | 用 `report` 或 `report.<subtype>` |
| **产物是构建输出且不易归入上列** | **用 `artifact.build_output` 或 `artifact.<subtype>`** |
| 产物是二进制资源（图片/音频/字体） | 用 `asset` 或 `asset.<subtype>` |

**命名合法性**（与 `01 §4.4` 命名风格约定一致）：dot 后的段用 snake_case（如 `artifact.build_output` ✅；`artifact.BuildOutput` ❌）。

**升 kernel 的时机**：若同一 `artifact.*` 派生被**两个或以上 adapter 使用**，按 §2.2 的规则触发 kernel 升版，将该派生正式登记为本表的 kernel 级基础类型子行（可能不再需要 `artifact.` 前缀）。

#### 2.1.2 artifact_type 命名风格（v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 5（R6 后半 / Q6）
> **性质**：**约定优于强制**——与 `01 §4.4` 对偶，此处专门约束 `artifact_type` 字段。

推荐风格：**dot.lowercase + 各段 snake_case**。

| 好 | 坏 |
|----|-----|
| `spec.structured` | `Spec.Structured` |
| `code.page_ui` | `code.PageUI` |
| `report.trace_run` | `report.traceRun` |
| `artifact.build_output` | `artifact.buildOutput` |

**为什么不与 `01 §4.4` 的 `snake_case` 完全一致**：
- task `type` 是**单段标识符**（snake_case 即足）
- `artifact_type` 需要表达"基础类型 → 派生"的**两级关系**（dot 作为显式层级分隔符，各段内部仍 snake_case）

**校验器关系**：`artifact-validate.sh` **不会**把"风格违规"作为 hard error（它只强制 §2.1 的 kind 前缀一致性）；本约定只是 lint 级建议，由 adapter 自律遵守。

### 2.2 派生类型的注册方式（v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 3（R2 / Q2）
> **触发背景**：adapter 撰写 `artifact_type: spec.charter` / `report.review` 等派生时发现 kernel 未明确"派生是 adapter 自用即可，还是必须向 kernel 登记"。

#### 2.2.1 两类注册路径

**路径 A · adapter 自用派生**（默认，99% 的情况）：
- adapter 在自己的文档中使用派生名（如 `spec.charter` / `report.review` / `code.page_ui`）
- **无需向 kernel 登记**
- **必须满足**：
  1. 派生名在本 adapter 目录内**唯一**（防止本 adapter 内同名歧义）
  2. 派生名的语义**不与现有 kernel 基础类型冲突**（如不得用 `spec.log`——`log` 已是另一个基础类型）
  3. 遵循 §2.1.2 的命名风格（dot.lowercase + snake_case）

**路径 B · 跨 adapter 共用派生**（罕见但重要）：
- 当某派生名被**两个或以上 adapter 同名同义地使用** → 触发"升 kernel"流程
- 流程：
  1. 在一次 kernel 升 rev 中（次版或主版均可），将该派生正式登记进 `§2` 的类型表或 `§7` 业务场景锚点表
  2. 在 `01-identity-model.md §2.4 kind 枚举变更史`（或本文件将来的"派生登记变更史"）留痕一行
  3. 两个 adapter 各自下次升版时，将原"自用"派生的引用改为"kernel 正式派生"引用（语义无变化，但 provenance 改变）

#### 2.2.2 冲突检测（何时必须"升 kernel"）

满足**以下任一条件**即触发路径 B：

- [ ] 同一派生名在多 adapter 语义**完全一致**（同义）
- [ ] 同一派生名在多 adapter 语义**不一致**（歧义，**必须**升 kernel 消除歧义）
- [ ] adapter 实现发现需要某派生的**跨 adapter 共享字段**（工具层面需要一致解析）

**检测工具**（v0.2 做，非本次小升范围）：`scripts/artifact-type-audit.sh` 扫描所有 `adapters/*/` 下 artifact_type 派生名的交集，产出候选"升 kernel"清单。

#### 2.2.3 adapter 新建派生的实践建议

- **不需要**在 adapter 的 `00-charter.md` 里穷举所有派生；随 adapter 各份文档按需出现即可
- **需要**在 adapter 的**某一处**（通常是 charter § 5 承诺段或 task-types 等最接近派生源的文档）登记一次"本 adapter 自用派生清单"，便于 audit 工具扫描
- **不允许**跳过本节 §2.1 的映射一致性检查（kind / artifact_type 必须配对合法）

#### 2.2.4 派生类型注册 schema（v1.3 新增）

> **新增来源**：`urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 §4.5`（R25）
> **触发背景**：路径 B 之前 · 派生登记无统一 schema · 路径 A 走 §2.2.1 的自然语言描述即可；但 M5 引入 `drift.propagation_record` 等**机器产物派生类型**后 · 需要一个可机读的 schema 让 `kernel-wordcheck.sh` 等工具自动识别派生属性（典型：是否跳过 wordcheck / 是否受 `SHA_WHITELIST` 约束）。

派生类型（无论路径 A adapter 自用 · 还是路径 B 升 kernel 登记）的注册 schema 采用下列七字段结构：

| 字段 | 类型 | 必填 | 语义 | 示例 |
|------|-----|------|-----|------|
| `artifact_type` | string | ✅ | 派生类型名 · 遵循 §2.1.2 命名风格（dot.lowercase + snake_case） | `drift.propagation_record` / `snapshot.diff` |
| `parent_type` | string | ✅ | 派生所基的 kernel 基础类型（§2.1 映射表中的合法值） | `drift` / `snapshot` |
| `description` | string | ✅ | 一句话语义描述（20–80 字 · 中文） | "drift 计算引擎产出的传播记录" |
| `schema_version` | string | ✅ | 本派生类型当前支持的 schema 版本号（遵循 semver · 形如 `1.0`） | `1.0` |
| `owner` | string | ✅ | 派生类型的 owner 签名（adapter 名 / kernel milestone 名 / human 名 任选一种） | `kernel:m5` / `adapter:frontend-migration` |
| `stability` | enum | ✅ | 稳定性等级：`experimental` / `beta` / `stable` / `deprecated`（四级 · 枚举封板） | `beta` |
| `wordcheck_policy` | enum? | ⭕ | v1.3 新增 · 可选（默认 `content_safe_default`） · 声明本派生类型的 body 是否自动继承 `wordcheck_exempt: true`：<br/>· `machine_generated`：本派生类型的 body 由确定性算法产出（无自然语言 / 无人工撰写）· 自动视为 `wordcheck_exempt: true`。典型：`drift.propagation_record` / `snapshot.diff` / 未来 evolution 的机器产物<br/>· `content_safe_default`：本派生类型的 body 可能含自然语言（人工撰写 / 半自动撰写）· 走默认的 `kernel-wordcheck.sh` 扫描流程。典型：`proposal` / `decision_log` / `review` | `machine_generated` |

**`wordcheck_policy` 的语义细则**（v1.3 新增）：

- 声明由派生类型注册方在本 §2.2.4 schema 的 adapter / kernel 配套文档中明示；未显式声明的派生类型按 `content_safe_default` 处理（**兜底安全**——默认走扫描 · 不会因为遗漏声明而跳过 wordcheck 导致违禁词泄露）
- 一旦声明 `machine_generated` · 所有符合该 `artifact_type` 的实体 front-matter **无需**再单独写 `wordcheck_exempt: true`· `kernel-wordcheck.sh` 自动跳过扫描（实体仍可显式写 `wordcheck_exempt: true` · 行为幂等 · 与注册声明不冲突）
- 工具实施方：`kernel-wordcheck.sh` 在启动时加载本 §2.2.4 派生注册表 → 构建 `machine_generated` 类型的 exempt 缓存 → 扫描时先查缓存再决定是否跳过（默认为扫描 · 命中 exempt 才跳过）
- **与 `04 §3.2.3 SHA_WHITELIST` 的关系**：两者共享同一 schema 宿主（本 §2.2.4）· `SHA_WHITELIST` 作为 schema 的**可选扩展字段**登记 · `wordcheck_policy` 作为 schema 的**可选枚举字段**登记 · 两者正交（某派生类型可同时声明两者 · 如 `drift.propagation_record` 既 `machine_generated` 又有六字段 `SHA_WHITELIST`）

**注册 schema 的 YAML 表达范式**（供 adapter / kernel 文档复用）：

```yaml
# 登记示例（放在 adapter 的 charter 或 kernel 派生登记表）
artifact_type: drift.propagation_record
parent_type: drift
description: "drift 计算引擎产出的传播记录 · 由 scripts/piao-drift-compute.sh 产出"
schema_version: 1.0
owner: kernel:m5
stability: beta
wordcheck_policy: machine_generated            # v1.3 新增 · 机器产物自动 exempt
sha_whitelist:                                 # v1.2 起 · 04 §3.2.3 承诺 3
  - diff_base
  - propagated_drifts
  - content_sha256
  - producer_event_id
  - producer_task_urn
  - artifact_type
```

**登记示例 2 · `evolution.scan_result`**（v1.4 新增 · 由 `m6_evolution_kernel_alignment@v1` S2 B2 落地 · 2026-04-19）：

```yaml
# evolution 扫描器产出的观测基础层 artifact 注册条目
artifact_type: evolution.scan_result
parent_type: evolution
description: "evolution 扫描器产出的观测基础层 artifact · 由 scripts/piao-evolution-scan.sh 产出 · body schema 由 06-evolution-model.md §2.3 定义"
schema_version: 1.0
owner: kernel:m6
stability: beta
wordcheck_policy: machine_generated            # v1.4 新增 · 对齐 drift.propagation_record 模式
```

**注释 3**（v1.4 · 本次 S2 B2）：

- `evolution.scan_result` 的 `wordcheck_policy=machine_generated` 依据：
  - body schema（见 `06-evolution-model.md §2.3`）由 `scripts/piao-evolution-scan.sh` 按确定性算法产出 · 无自然语言 / 无人工撰写
  - `scanned_drifts[]` / `decision_log[]` / `orphan_check?` 均为 YAML 结构化字段 · 与 `drift.propagation_record` 同模式
  - `kernel-wordcheck.sh` 的 `machine_generated` 分支已在 M5 期间实施 · 本条目仅**复用既有分支**识别新派生类型 · 零工具链改动 · 零 adapter 改动
- 与 `drift.propagation_record` 的共性：两者都是 kernel 观测基础层的确定性产物 · 共同构成 piao-pipeline 的"L2 之外 + L1 之上"机器产物层
- `sha_whitelist` 暂未登记：`piao-evolution-scan.sh` MVP 未实施 · 哈希白名单字段清单将由首次 MVP 产出反证后补登（对标 `drift.propagation_record` v1.2 → v1.3 的节奏 · 六字段 `SHA_WHITELIST` 由 04 §3.2.3 在 M5 驱动阶段补登）· 不阻塞本次 v1.4 小升

**"现有七字段保留不变"承诺**（v1.4 兼容性保证）：

- v1.3 之前（即 v1.2 及更早）无正式 schema 表 · 派生登记走 §2.2.1 的自然语言描述路径
- v1.3 首次引入正式 schema 表（本 §2.2.4）· **前六字段**（`artifact_type` / `parent_type` / `description` / `schema_version` / `owner` / `stability`）是对既有隐式语义的形式化 · 不引入新承诺 · 已有 adapter 派生若未登记可继续沿用（按 `content_safe_default` + `stability=beta` 默认值处理）
- **第 7 字段** `wordcheck_policy` 是 v1.3 本次新增的可选字段 · 仅影响未显式声明的派生按默认 `content_safe_default` 处理（与 v1.2 语义完全兼容 · 无反转）
- adapter 若需启用 `machine_generated`（如 drift.propagation_record）· 在下次 adapter 升版时登记即可 · v1.2 时期已产出的派生实体不受影响
- **v1.4 本次**（`m6_evolution_kernel_alignment@v1` S2 B2 · 2026-04-19）：**仅新增一条 `evolution.scan_result` 注册条目** · 沿用 v1.3 已有的七字段 schema 字面不动 · 未新增字段 · 未修改字段类型 · 未反转任何枚举值 · 既有 `drift.propagation_record` 注册条目字面保留不变 · 已产出 adapter 派生实体零冲击（与 v1.3 的兼容性承诺一致延伸）

---

## 3. 存储与内容寻址

### 3.1 双层定位

每个 artifact 有**两套坐标**：

| 坐标 | 用途 | 示例 |
|------|------|------|
| **URN**（逻辑） | 被引用，被事件记录，跨版本追踪 | `urn:piao:artifact:prop_confirm:structured_spec@v1` |
| **Path**（物理） | 磁盘定位，IDE 打开 | `openspec/changes/x/spec.md` |

两者通过 `identity-manifest.jsonl` 映射（见 `01-identity-model.md` §7）。

### 3.2 内容哈希 + URN = 真身份

**内容可能被编辑但 URN 不变**（只要未升 rev）。此时 `content_sha256` 会变。

规则：
- `content_sha256` 在每次 artifact 被"正式保存"时由工具写入
- 事件 `artifact.updated` 会记录新 sha
- **事件引用 artifact 时，可选带上 sha256 作为精确引用**（防止 URN 被后续 edit 偷偷改变语义）：

```json
{
  "subject": "urn:piao:...@v1",
  "subject_sha256": "abc123..."
}
```

### 3.3 为什么不做纯内容寻址（像 Git blob）

**做了，但只做到 sha256 级，不替代 URN。** 原因同 `01-identity-model.md` §1.2：纯 hash 身份不可读、不可语义化，和 piao-pipeline 强调"状态即事实"的可读性哲学不合。

---

## 4. Provenance（出身）

### 4.1 四元组（双字段记账）

每个 artifact 的 provenance 记四个字段——**event_id 和 task_urn 都存**，互相校验：

```
(producer_actor, producer_event_id, producer_task_urn, input_urns)
```

| 字段 | 语义 | 示例 |
|------|------|------|
| `producer_actor` | 谁写的 | `agent:migration-analyzer` |
| `producer_event_id` | 产出事件的 event_id（短格式） | `task-260418055700-a3f2b1` |
| `producer_task_urn` | 产出事件所归属的 task URN | `urn:piao:task:prop_confirm/dag:t_03` |
| `input_urns` | 依赖的上游 URN 列表 | 见下 |

举例：`prop_confirm` 的 structured_spec：
- producer_actor: `agent:migration-analyzer`
- producer_event_id: `task-260418055700-a3f2b1`
- producer_task_urn: `urn:piao:task:prop_confirm/dag:t_03`
- input_urns:
  - `urn:piao:unit:prop_confirm`
  - `urn:piao:artifact:prop_confirm:prd@v1`

### 4.2 为什么双字段冗余存

drift 和 evolution 两个子系统对 provenance 的访问路径不同：
- **drift** 主要按 task 维度聚类（"这个 task 产出的所有 artifact 都要重新评估"）→ 需要 `task_urn`
- **evolution** 主要按事件维度回放（"这条 artifact.published 事件的 body 是什么"）→ 需要 `event_id`

两个都存不仅让查询 O(1)，更重要的是**互相校验**：如果 `event_id` 指向的事件 body 里 `task_urn` 和 front-matter 的 `producer_task_urn` 不一致，说明 provenance 被篡改或写错。

### 4.3 Provenance 不可伪造

**规则**：`producer_event_id` 必须是**当前 actor 刚刚写入且尚未被更新的一条 L1 事件的 event_id**，且该事件的 `subject` 必须等于本 artifact 的 URN 或其归属 task 的 URN。

**工具自动填充路径**：
- 对 artifact 的"发布"操作：工具写一条 `artifact.published` L1 事件，然后把该事件的 event_id 和 task_urn 填入 front-matter
- 对 artifact 的"revised"操作：同理写 `artifact.superseded` 事件
- **人肉填写违规**，`scripts/artifact-validate.sh` 会校验 event_id 是否真实存在于 event journal

### 4.3.1 snapshot 产出的 event_id 预留（v1.2 新增）

snapshot 作为 artifact 的特殊子类（`kind=snapshot`），其产出过程涉及"先写 snapshot artifact、再写 stage 事件、最后写 `artifact.published`"的**三步原子操作**（完整契约见 `04-version-snapshot.md §2.2`）。第一步写入 snapshot 时，其 front-matter 的 `produced_by.event_id` 需指向**第三步才产生**的 `artifact.published` 事件 id——这是典型的"先有鸡后有蛋"场景。

**snapshot 产出走与普通 artifact 完全相同的预留流程**，不发明新机制：

1. 工具在进入原子操作前**先生成**候选 event_id（格式见 `03 §4.1` / `01 §5`）
2. 将该 id 预写入 snapshot front-matter 的 `produced_by.event_id`（原子操作的第一步）
3. 再按该预留 id 写入后续 L1 事件（第二、三步）
4. 若原子操作任一步失败（详见 `03 §3.3.1` 原子写入契约），整批 id 作废，snapshot 进入"孤儿"状态（由 `artifact-validate.sh --check-orphan` 扫出，补偿路径留 M5）

**本小节仅作显式点名**，避免调用方误以为 snapshot 需要特殊 provenance 处理——**snapshot 完全复用 §4.3 已有规则**，`producer_event_id` 必须存在于 event journal、subject 校验、人肉填写违规等约束一概同构。

### 4.4 Provenance 与事件分层

> **背景**：M2 对标研究（`competitive/02-agent-orchestration.md` jj vs `competitive/03-pipeline-systems.md` Dagster）发现，所有能长期运行的"可观测历史"系统都有一个共同模式——**事件分两层**：
>
> - **L1 · Artifact 事件**：artifact 的产出 / 变更 / 废止。**数量少、语义稳定、跨项目通用。**典型：`artifact.published`、`artifact.superseded`、`artifact.retracted`。这层事件是 drift 和 evolution 的输入。
> - **L2 · Execution 事件**：actor 在执行 task 过程中产生的细粒度事件。**数量多、语义可变、场景相关。**典型：`task.started`、`task.step_log`、`task.finished`、`verify.lint_failed`。这层事件是 trace 和 debug 的输入。

**`producer_event_id` 永远指向 L1 事件**——具体是 `artifact.published`（artifact 首次发布）或 `artifact.superseded`（artifact 升 rev 发布）。**不允许指向 `stage.entered` 或任何不产 artifact 的事件**。

**L2 事件序列的完整 schema 已在 M3（`03-layered-architecture.md`）定义**，以下三点与本节相关：
- L1 10 类事件枚举封板（见 M3 §3.1）、L2 采用"骨架 + payload 扩展"模式（见 M3 §5）；
- 两层之间的关联字段是 **L2 事件的 `parent_task_urn` → 对应的 L1 task 事件归属的 task URN**；
- L1 **永久保留**，L2 **可归档但禁止 compact**，归档的三条件全部是 L1 事件的客观存在性判定（见 M3 §6）。

**M2 承诺**：`producer_event_id` 永远是 L1 层的 `artifact.published` / `artifact.superseded` 事件 id，M3 对 L2 的任何调整都不会破坏这个契约。

---

## 5. Lineage（依赖图）

### 5.1 depends_on

每个 artifact 的 front-matter 里声明它依赖的上游 URN 列表。

**两类依赖：**

| 类型 | 语义 | 例 |
|------|------|------|
| `strong` | 强依赖——上游变更必须重新评估当前 artifact | `structured_spec` 强依赖 `prd/prop_confirm.png` |
| `weak` | 弱依赖——仅作参考，上游变更不强制触发 drift | `structured_spec` 弱依赖某个 `rule` |

声明方式：

```yaml
depends_on:
  - urn: urn:piao:artifact:prop_confirm:prd@v1
    strength: strong
  - urn: urn:piao:rule:kotlin_coding_standards@v1
    strength: weak
```

### 5.2 反向依赖（depended_by）

**不在 artifact 自身声明**，而是通过 manifest 和 event journal **反向索引**得到。避免"声明了但没更新"的维护债。

### 5.3 lineage 的 drift 应用

详见 `kernel/05-drift-propagation.md`。这里只保留接口：

- **查询**：`lineage_query(urn, direction=upstream|downstream, strength=strong|any)`
- **失效传播**：当上游发出 `artifact.superseded`（升 rev）或 `artifact.retracted`（作废），下游所有 strong 依赖者都被打上 `stale` 标记

### 5.3.1 lineage 特化注册表（v1.2 首设 snapshot 特化 · v1.3 扩为通用注册表）

> **升级路径**：v1.2 首版仅登记 `kind=snapshot` 特化（由 `m4_snapshot_kernel_alignment@v1 §4.5` 落地 · 对应 review R15）· v1.3 扩表登记 `kind=drift` 特化（由 `m5_drift_kernel_alignment@v1 §4.4` 落地 · 对应 review R23）· 本节结构化为"注册表"以支撑未来 M6 evolution 等新 kind 的无摩擦接入。

当 `lineage_query` 的目标 URN 的 `kind` 落在下表时，查询器**应用对应的特化规则**（而非走默认的 `front-matter.depends_on` 解析）：

| kind | `depends_on` 等价替身（读取路径） | 强度判定 | 特化规则来源 | 首设 rev |
|------|---------------------------------|---------|-------------|---------|
| `snapshot` | `body.frozen_artifacts[*].artifact_urn` | **一律 `strong`**（冻结即强绑定 · `artifact_type` 不参与强度判定） | `04-version-snapshot.md §3.2.2`（规约：snapshot 不写 `depends_on` · 避免与 `frozen_artifacts` 冗余） | **v1.2** |
| `drift` | `body.diff_base.old_snapshot_urn` + `body.diff_base.new_snapshot_urn` | **一律 `strong`**（drift 对基准 snapshot 对的依赖是本体意义的 · 不存在弱依赖形态） | `05-drift-propagation.md §2.5`（drift 的 `depends_on` 等价替身规则 · 指向本节登记） | **v1.3** |

**注册表规则**（v1.3 起生效）：

1. **反向注册原则**：特化条目由**派生 kind 的 kernel 文档**反向注册到本表——02 自身**不**主动列举所有可能的 kind。未来任何新 kind（如 M6 evolution 可能引入的 `evolution.gap_report` 等）若有 `depends_on` 等价替身需求 · 走同样路径：在派生文档中声明 body 的等价替身字段 · 再在本表追加一行。
2. **特化执行位置**：所有登记的 kind 的 `depends_on` 解析在 `lineage_query` 的 kind 分支内实施 · **不走**默认的 front-matter.depends_on 解析；未命中本表的 kind 回落到默认路径（`§5.1` 直接读 front-matter.depends_on）。
3. **强度一致性**：截至 v1.3，所有登记条目的强度均为 `strong`（"等价替身"语义本身排除了弱依赖的可能）· 未来若某 kind 需要弱等价替身规则 · 需配发 proposal 明确新增"强度判定"列的细分条件（本表暂无此需求）。
4. **跨表一致性验证**：`lineage-query.sh`（M5 drift 层工具链）在启动时应读取本表（或本表的机器可读副本 · 见 §2.2 派生注册表的一致性承诺）· 构建 kind 分支 cache · 避免每次查询重新解析本文档。

**原 snapshot 特化条款**（v1.2 首版原文保留 · 现作为注册表中 `kind=snapshot` 行的详细说明）：

- snapshot 的 front-matter **不含** `depends_on` 字段（见 `04-version-snapshot.md §3.2.2` 规约：snapshot 不写 `depends_on`，避免与 `frozen_artifacts` 冗余引发不一致）
- 查询器读取 snapshot body 中的 `frozen_artifacts` 列表，将其中每一条 `artifact_urn` 视为该 snapshot 的**等价 strong `depends_on`**
- `frozen_artifacts` 条目中的 `artifact_type` 不参与 lineage 强度判定（即 snapshot 对被冻结 artifact 的依赖**一律视为 `strong`**，对应"冻结即强绑定"的语义）

**新增 drift 特化条款**（v1.3 新增 · 由 `05-drift-propagation.md §2.5` 反向对接）：

- drift 的 front-matter 可含 `depends_on` 字段（与 snapshot 不同 · drift 允许声明弱依赖如上游 snapshot proposal 等）· 但其**核心 lineage**（对基准 snapshot 对的依赖）通过 body 的 `diff_base` 表达
- 查询器读取 drift body 中的 `diff_base.old_snapshot_urn` 和 `diff_base.new_snapshot_urn`，将二者视为该 drift 的**等价 strong `depends_on`**
- 与 snapshot 的区别：snapshot 是**全集冻结**（`frozen_artifacts` 列表可任意长）· drift 是**对点比较**（`diff_base` 固定两条 · 永远是 `old_snapshot_urn` + `new_snapshot_urn`）
- 工具实施方：`lineage-query.sh` 在 `kind=drift` 分支下读取本规则；`artifact-validate.sh` 在校验 drift 时**应要求** body 的 `diff_base` 字段必填两个 snapshot URN（发现缺失报 ERROR · 不可忽略）

**工具实施方**：`lineage-query.sh`（M5 drift 层工具链）应在 URN kind 分支中特化 snapshot / drift 的 `depends_on` 解析路径，不走默认的 front-matter 解析。`artifact-validate.sh` 在校验 snapshot 时**应拒绝** front-matter 出现 `depends_on`（发现则 WARN 并忽略，按 `04 §3.2.2` 契约）。

**与 §5.1 `depends_on` 定义的关系**：本特化注册表不改变 §5.1 的"两类依赖（strong/weak）"定义，仅在登记的 kind 场景下补一条"如何找到 depends_on"的**等价替身读取规则**——调用方看到的 lineage 结果与普通 artifact 完全同构，不需要为 snapshot / drift 场景分叉消费逻辑。

---

## 6. Artifact 生命周期

```
  ┌────────┐   emit(artifact.published)     ┌──────────┐
  │ draft  │ ──────────────────────────▶   │ published│
  └────────┘  （工具写 L1 事件 + 收录 manifest） │   @v1   │
                                             └────┬─────┘
                                                  │ 升 rev 发布
                                                  │   emit(artifact.superseded) + 新 URN
                                                  ▼
                                             ┌──────────┐
                                             │ published│
                                             │   @v2   │
                                             └────┬─────┘
                                                  │ 作废（罕见）
                                                  │   emit(artifact.retracted)
                                                  ▼
                                             ┌──────────┐
                                             │ retracted│
                                             └──────────┘
```

**三条路径，对应 L1 三类 artifact 事件**（见 M3 §3.1）：

| 转换 | L1 事件 | 语义 |
|------|---------|------|
| `draft → published@v1` | `artifact.published` | artifact 首次正式发布（从 draft 转为 published） |
| `published@vN → published@vN+1` | `artifact.superseded` | 升 rev 发布新版本，旧 URN 被覆盖但仍可解析 |
| `published → retracted` | `artifact.retracted` | 作废（极罕见，如发现严重错误或违规） |

**重要：**
- **draft 不发事件**：draft 状态的 artifact 修改由 git diff 自治，不进 event journal（见 M1 §10.1 的 published/draft 契约）
- **published 禁止原地改**：任何修改都必走升 rev → `artifact.superseded`（见 M1 §10.1）
- **没有 "archived" 状态**：artifact 不被"归档"——过期的 artifact 要么被 `artifact.superseded` 取代，要么被 `artifact.retracted` 作废。"archive" 一词在 piao-pipeline 中**仅用于 L2 事件归档**（见 M3 §6），与 artifact 无关

---

## 7. 业务场景锚点：Kuikly 迁移举例

> 这是**业务场景层**的举例，在 kernel 文档里锚定是为了让本章不悬空。其他业务场景会有自己的 artifact 类型细化清单，但都遵循 kernel 契约。

| artifact_type（细化） | 常见 URN | 谁产出 |
|------|------|------|
| `spec.structured` | `urn:piao:artifact:<unit>:structured_spec@vN` | migration-analyzer |
| `spec.api_contract` | `urn:piao:artifact:<unit>:api_contract@vN` | migration-analyzer |
| `plan.taskdag` | `urn:piao:artifact:<unit>:taskdag@vN` | migration-analyzer |
| `code.page_ui` | `urn:piao:artifact:<unit>:page_ui@vN` | migration-coder |
| `code.viewmodel` | `urn:piao:artifact:<unit>:viewmodels@vN` | migration-coder |
| `config.state_md` | `urn:piao:artifact:<unit>:state@vN` | orchestrator |
| `report.verify` | `urn:piao:artifact:<unit>:verify_report@vN` | migration-verify |
| `report.trace` | `urn:piao:artifact:<unit>:trace_report@vN` | trace-report |
| `asset.screenshot` | `urn:piao:artifact:<unit>:screenshot/<name>@vN` | auto-ui-test |

---

## 8. 约束与反模式

### 8.1 强制

- 任何文件要成为 artifact，**必须**有 URN front-matter
- 任何事件引用 artifact 时，**必须**使用完整 URN（含 rev）
- `content_sha256` 必须由工具写入，不得手填

### 8.2 禁止

| 反模式 | 为什么禁 |
|------|------|
| "暗搓搓"地覆盖 published artifact 文件而不发 `artifact.superseded` 事件 | 破坏可追溯性，drift 失灵 |
| 同一 URN 指向不同物理文件 | manifest 冲突，任何引用都不可信 |
| 用 `artifact_type: custom_xxx` 绕过 kernel 分类 | 破坏分类学，派生类型必须带 `.` 前缀于 kernel 类型 |
| artifact 之间循环依赖 | lineage 无法拓扑，drift 会死循环 |
| published artifact 原地修改（包括"只修错别字"） | 违反 M1 §10.1，**任何**修改必须走 rev 升降 |

---

## 9. 校验器（与 identity 校验联动）

kernel 必须提供 artifact-level 校验：

```
validate_artifact(path: str) → Report {
  urn_valid: bool,                           # URN 格式合法（委托 M1 §6）
  front_matter_complete: bool,               # 五要素齐全
  kind_artifact_type_consistent: bool,       # §2.1 映射一致
  content_sha256_match: bool,                # sha 与文件内容一致
  lineage_resolvable: bool,                  # depends_on 的 URN 都能在 manifest 中找到
  producer_event_exists: bool,               # producer_event_id 在 event journal 中存在
  producer_dual_track_consistent: bool,      # event_id 指向的事件 subject / task_urn 与 front-matter 一致
  manifest_consistent: bool,                 # manifest 条目的 urn / sha256 / event_id 与 front-matter 一致
  errors: [str]
}
```

**实施**：
- 脚本 `scripts/artifact-validate.sh <path>`
- Git pre-commit 强制：任何被标记为 artifact 的文件 commit 前必须通过校验
- 违规 commit 被拒

---

## 10. 已决事项与开放问题

### 10.1 已决（M1 review，2026-04-18）

1. **code artifact 粒度 = 目录级** ✅
   - **一个目录 = 一个 code artifact**，目录内所有文件共享同一个 URN 和 rev。
   - 典型单位（以 Kuikly 迁移业务场景为例）：
     - 一个 Kuikly 页面的根目录（如 `shared/.../page/customize_lucky_draw_machine/`）
     - 一个 feature 模块的根目录（如 `shared/.../feature/xxx/`）
     - 一个公共工具模块（如 `shared/.../util/`）
   - 粒度标记：在目录下放一个 `.artifact.yaml` sidecar（见 §1/§6），sidecar 位置即定义 artifact 边界。
   - rev 升降的触发规则：
     - **模块内部文件重构 / 重命名 / 新增文件** → **不升 rev**（artifact 的"形状"没变）
     - **对外 API（public 接口 / Route 入口 / 导出符号）变更** → **必升 rev**
     - **spec 或 acceptance 变更导致的实现改动** → **必升 rev**，且 `produced_by` 指向该 spec/acceptance 的演化事件
   - 理由：
     - Kotlin 代码在重构时文件拆合非常频繁（ViewModel 拆分、Card 化），文件级粒度会导致 rev 通胀，manifest 噪声巨大；
     - 目录级粒度天然对齐 Kuikly 项目的"page / feature / module"概念，与 `.state.md` 的 `page_id` 语义一致；
     - 对 drift 检查足够：drift 关心的是"契约是否漂移"，目录级的 sha256 聚合（对目录做 `git ls-files -z | sort -z | xargs -0 sha256sum | sha256sum`）能稳定感知内容变化。

2. **二进制 artifact（如 apk / png）使用 sidecar 承载 front-matter** ✅
   - 同目录下加 `<name>.artifact.yaml`，包含 URN / rev / content_sha256 / provenance / lineage。

### 10.2 仍然开放

1. **是否引入 content-addressed storage**（如 Git LFS 或类 IPFS 层）？倾向：**v0.1 不做**，sha256 足够，生态复杂化不值。

---

**本篇结论**：artifact 是 piao-pipeline 的"物质"。
- 没有 URN 的文件不是 artifact；
- 没有 provenance 的文件不是 artifact；
- 不能被 drift/evolution 消费的 artifact，是漏写了 front-matter 的 artifact。

下一篇（`07-extensibility.md`）会明确说明：哪些 artifact_type 是 kernel 封死的、哪些可以在业务场景层扩展。

---

## 11. rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1 | M1 阶段定稿（2026-04-18） | `urn:piao:snapshot:kernel:m1_final_decisions@v1` | 首版定稿；§10.1 确立目录级 code artifact 粒度 + 二进制 sidecar 约定 |
| **v1.1** | **2026-04-18 23:25** | `urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` | 新增 §2.1.1 `artifact.*` 派生示范（R5）；新增 §2.1.2 artifact_type 命名风格（R6 后半）；新增 §2.2 派生类型的注册方式（R2）。**纯补充性小升**，schema 不变，五要素契约不变，现有 artifact 不受影响 |
| **v1.2** | **2026-04-19 01:30** | `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` | 新增 §4.3.1 snapshot 产出的 event_id 预留段（R16，源自 M4 review Q14），显式点名 snapshot 复用 §4.3 既有预留流程；新增 §5.3.1 snapshot 特化查询段（R15，源自 M4 review Q13），明确 `lineage_query` 遇 `kind=snapshot` 时以 `frozen_artifacts` 作为 `depends_on` 等价替身（strong 强度）。**纯补充性小升**，§4.3 / §5.3 既有规则与函数签名不变，是路径 B 对 `04-version-snapshot.md §3.2.2 / §2.2` 前置锚点的反向对接 |
| **v1.3** | **2026-04-19 14:40** | `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 §4.4 / §4.5` · M5 路径 B 落地 | **小升 @v1.2 → @v1.3**（纯补充 · 零 schema 删减 · 零字段类型变更 · 零语义反转）：①§5.3.1 从"snapshot 一次性特化"改写为"lineage 特化注册表"（R23 · v1.2 的 snapshot 条目保留不变作为首条 · v1.3 扩表追加 `kind=drift` 条目：`body.diff_base.old_snapshot_urn` + `body.diff_base.new_snapshot_urn` 作为 strong 等价替身 · 反向注册原则 + 强度一致性 + 跨表一致性验证）· `lineage_query` 函数签名不变 · 仅在 kind 分支添加 drift 条件；②新增 §2.2.4 "派生类型注册 schema"（R25 · 七字段结构：artifact_type / parent_type / description / schema_version / owner / stability + 第 7 字段 `wordcheck_policy` 枚举 `machine_generated / content_safe_default` 默认后者兜底安全 · 与 `04 §3.2.3 SHA_WHITELIST` 正交 · 共享同一 schema 宿主）· v1.2 之前无正式 schema 表 · 本次首次形式化 · 前六字段是既有隐式语义的形式化 · 未登记 adapter 派生按默认值处理 · v1.2 时期已产出派生实体不受影响。**对 v1.2 已产出 snapshot / artifact 零冲击**（§5.3.1 的 snapshot 特化规则字面保留）。本次 published 对应 L1 事件两连：`artifact.published(spec:architecture:artifact_model@v1.3)` + `stage.transited(stage=m5_path_b_step3)`（按 `03 §3.3.1` N=2 原子契约） |
| **v1.4** | **2026-04-19 20:45** | `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 §4.2` · M6 路径 B · S2 B2 落地 | **小升 @v1.3 → @v1.4**（纯追加 · 零 schema 删减 · 零字段类型变更 · 零语义反转）：§2.2.4 派生类型注册表**新增一个 YAML 登记示例块 · `evolution.scan_result`**（七字段齐全：`artifact_type=evolution.scan_result` / `parent_type=evolution` / `description` 指向 `scripts/piao-evolution-scan.sh` 产出 · body schema 锚定 `06-evolution-model.md §2.3` / `schema_version=1.0` / `owner=kernel:m6` / `stability=beta` / `wordcheck_policy=machine_generated`）· 表格下方**补注"注释 3"段**（说明 `wordcheck_policy=machine_generated` 的三条依据：确定性算法产出 + YAML 结构化字段同 drift.propagation_record · 与 drift.propagation_record 的共性 · `sha_whitelist` 暂未登记原因 MVP 未实施）· §2.2.4 表下 **"现有六字段保留不变" 承诺段标题改为"现有七字段保留不变"**（v1.3 表中第 7 字段 `wordcheck_policy` 已作为正式字段入册 · 本次只是沿用已有 7 字段注册一条新派生类型 · 非 schema 字段扩展）。`kernel-wordcheck.sh` 的 `machine_generated` 分支已在 M5 期间实施完毕 · 本次**零工具链改动 · 零 adapter 改动**。**对 v1.3 已产出 artifact 零冲击**（既有 `drift.propagation_record` 登记示例字面保留 · 既有 7 字段 schema 字面保留）。本次 published 对应 L1 事件两连：`artifact.published(spec:architecture:artifact_model@v1.4)` + `stage.transited(stage=m6_path_b_s2)`（按 `03 §3.3.1` N=2 原子契约） |
