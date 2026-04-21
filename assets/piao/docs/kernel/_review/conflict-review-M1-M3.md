---
urn: urn:piao:report:review:conflict_m1_m3@v2
kind: report
rev: v2
status: resolved
supersedes: urn:piao:report:review:conflict_m1_m3@v1
produced_by: urn:piao:task:m3b:conflict_scan_resolve
produced_at: 2026-04-18T19:25:00+08:00
---

# kernel · M1–M3 第一性冲突扫描报告（v2 · 已解决）

> 2026-04-18 扫描 + 决策 + 修复落盘。v1 是 scan 报告，v2 标记所有 P0/P1 项已解决，附最终方案摘要。

---

## 0. 本次决策总览

用户反馈："M1 的事件 id 格式其实是我更倾向的风格，之前选 M3 格式是因为被伪二选一了" + "保持通用性但减少概念成本（减少 adapter 相关抽象）"。

**最终决策**：

| 议题 | 最终方案 |
|------|---------|
| **URN schema** | 删除 realm 段 → `urn:piao:<kind>:<scope>:<name>[@<rev>]` |
| **事件 id 格式** | `{域}-{UTC的YYMMDDHHmmss}-{6位hash}`，域 7 选 1（`pipe/tdag/task/trace/evo/drift/gate`） |
| **C-02 subject 字段** | C 双轨：所有 L1/L2 事件强制 `subject`，语义字段（`artifact_urn` 等）作为别名 |
| **C-03 producer_event** | C 两个都存：`producer_event_id` + `producer_task_urn` 双字段，互相校验 |
| **C-04/C-05 artifact 生命周期** | 对齐 M3 L1 10 类枚举，删除 `archived` 状态。artifact 三路径：`draft→published`/`superseded`/`retracted` |
| **C-06 `event` kind** | 删除 |
| **C-07 published 判定** | M3 §6.1 加脚注说明依赖 M4 原子性，不改严 |
| **kind 枚举梳理** | 分 "核心 kind" / "扩展 kind"：`page` / `evolution_source` 降为扩展 kind（不删，保留以免破坏现有项目） |
| **未来扩展** | M1 加 §11 "未来扩展"节，记录多领域/多仓/多租户的升级路径 |

---

## 1. 落盘修改清单

### M1 `01-identity-model.md`
- §1.1 URN schema：删 realm 段，表格同步；加"关于 realm"说明
- §2 kind 枚举：拆分为 "核心 kind" / "扩展 kind"；删 `event` kind；`page` 降为扩展 kind；注释说明 `page` 与 `unit` 关系
- §3 整节重写：从 "realm 规则" → "命名空间隔离（无 realm 版）"，通过 scope 和路径上下文表达 kernel/adapter 边界
- §5 event_id：重写为 M1 风格（UTC + 6 位 hash + 7 选 1 域），加 §5.1 格式选型理由、§5.2 碰撞处理、§5.3 subject 双轨契约
- §6 校验器：第 3/4 条改为基于 scope / 调用方路径上下文
- §7 存储布局：manifest 示例 URN 删 realm；默认存储约定"adapter"措辞中性化
- §8.2/§8.3 反模式：跨 adapter 相关条目调整，反例增加"不再支持 realm 段"
- §9 迁移路径：所有示例 URN 删 realm
- §11（新增）未来扩展节

### M2 `02-artifact-model.md`
- §1.1 front-matter 示例：URN 删 realm、event id 改 UTC 格式、`produced_by` 简化
- §2 artifact 类型：加 §2.1 kind↔artifact_type 映射说明
- §3.1/§3.2 URN 示例删 realm
- §4 provenance 整节重写：三元组 → 四元组（双字段 `producer_event_id` + `producer_task_urn`）；§4.3 明确自动填充路径；§4.4 去掉 `stage.entered` 的不合理链接
- §5 lineage 示例 URN 删 realm；§5.3 触发事件改为 `artifact.superseded`
- §6 生命周期整节重写：对齐 M3 L1 10 类，删除 `archived` 状态，改为三路径（published/superseded/retracted）
- §7 Kuikly 锚点表 URN 删 realm；标题改为"业务场景锚点"
- §8.2 反模式同步新事件名
- §9 校验器：补 `kind_artifact_type_consistent` / `producer_dual_track_consistent` / `manifest_consistent` 三项
- §10 微调"kuikly adapter 下" → "以 Kuikly 迁移业务场景为例"

### M3 `03-layered-architecture.md`
- front-matter URN 删 realm
- §1 四层模型：Adapter 层注释中性化，加"关于 Adapter 这个层名"说明
- §2.3 L1/L2 关联：修正 `parent_task_urn` 的指向描述
- §3.1 L1 事件表：新增 subject 列，所有类型的 subject 指向明确；加双轨原则说明
- §3.2 L1 骨架：加 `subject` 为第 6 个强制字段
- §4 事件 id 规则整节重写：对齐 M1 §5（UTC + 6 位 hash + 7 选 1 域），删除 ULID 对比（那是针对 base36 版本的论证）
- §5.1 L2 骨架：event_id 格式同步，加 `subject` 强制字段（通常等于 parent_task_urn）
- §6 归档规则：标题加"L2 事件归档"术语消歧；§6.1 条件 2 加原子性脚注
- §8.1 决策清单：决策 5 改为新格式，新增决策 6（subject 强制）；其他 adapter 字样中性化为"业务层"
- §8.3 前置契约：引用对齐 M1/M2 的新节号

### Review 报告
- v1 → v2：加本总览；保留原冲突诊断供溯源

---

## 2. 未在本次扫描范围内，但可能需要同步

以下文件在 M1-M3 外围，暂未动。用户如需同步更新请告知：

- `docs/piao-pipeline/kernel/07-extensibility.md`：§2 里还有"realm 下的 scope 组织方式"、§4 顶层目录示例 "kernel/" 描述 "realm=kernel 的所有内容都在这" — 与新 URN schema 不符
- `docs/piao-pipeline/kernel/scenario-wordlist.md`：多处引用 `adapter.kuikly` 作为 URN 示例

**建议**：这两份文档与 M1-M3 改动同步刷一次（用户决策后再动）。

---

## 3. 下面是原 v1 扫描报告（保留供溯源）

原扫描的 11 条冲突诊断保留在下方。所有 P0/P1 项已在上文 §0 / §1 标记决策和修复落盘；P2 项在 v1 阶段已自动修复。

---

## 4. v1 · 执行摘要

**扫出 11 条**，分布：

| 严重度 | 条目数 | 处置 |
|--------|-------|------|
| **P0**（契约破坏，必须改） | **3** | ✅ v2 已决策并修复 |
| **P1**（语义模糊，建议改） | 4 | ✅ v2 已决策并修复 |
| **P2**（措辞优化，可选） | 4 | ✅ v1 阶段已自动修复 |

**结论**：M1–M3 的**顶层分层哲学一致**（身份 / artifact / 事件分层三个维度干净），但在**事件层**有 3 条硬冲突——这是预期之中的风险区，因为事件是 M1（只提了 event_id）和 M3（事件模型主场）**两次交叉定义**的地方，对齐未完成。

---

## 5. v1 · P0 冲突详情（已解决）

---

### **C-01 · 事件 id 格式两篇互斥**

| 维度 | M1 §5 定义 | M3 §4.1 定义 |
|------|-----------|-------------|
| 格式 | `{域}-{YYMMDDHHmmss}-{6位hash}` | `<domain>-<timestamp>-<hash8>` |
| 时间戳 | 本地时区，`YYMMDDHHmmss`（12 位十进制，人肉可读） | UTC 毫秒，base36（紧凑不可读） |
| hash 位数 | 6 位 hex | 8 位 hex |
| domain 取值 | 7 选 1 固定枚举（`pipe/tdag/task/trace/evo/drift/gate`） | 对应 URN realm 段（`kernel` / `adapter.<name>`，开放） |
| 示例 | `task-260418135700-a3f2b1` | `kernel-lygqjn80-a3f2c919` |

**诊断**：这是对**同一实体的两个不相容定义**。工具链按哪一个实现都会和另一篇对不上。

**根因**：M1 的 event id 设计在"事件按 pipeline 阶段分域"的思路下做的（`pipe/task/trace/evo/drift`）；M3 的 event id 设计在"事件按 realm 分域"的思路下做的（`kernel/adapter.kuikly`）。**两个维度的正交性没有对齐**。

**建议选项**：

| 方案 | 说明 | 代价 |
|------|------|------|
| **A · 采用 M3 格式，M1 §5 对齐** | domain = URN realm，时间戳 UTC-base36，hash 8 位 | 时间戳不人肉可读，但最近上下文里你倾向"语义清晰 > 可读性"，且 domain=realm 更天然融入身份体系 |
| **B · 采用 M1 格式，M3 §4.1 对齐** | domain = 7 种固定前缀，时间戳 `YYMMDDHHmmss`，hash 6 位 | 人肉可读，但 domain 7 选 1 和 L1/L2 的 event_type 枚举（10+ 类）有重叠却不等价，long-term 会混乱 |
| **C · 混合方案** | domain 用 realm（对齐身份），时间戳用 `YYMMDDHHmmss`（可读），hash 6 位 | 折衷但需要定义得更细 |

**我的倾向**：**A**。理由是 domain 和 URN realm 同源的设计更简洁；时间戳不可读可以靠工具解码。但你上次定 event id 格式时说的是 M3 的 `<domain>-<timestamp>-<hash8>`，**M1 的 `{域}-{YYMMDDHHmmss}-{6位hash}` 看起来是你更早之前写的 M1 里的遗物**——确认一下：是不是我落 M1 的时候这一段是沿袭旧设计没拍板，后来你拍板的是 M3 那版？

**等你回答**：选 A / B / C / 还有别的？

---

### **C-02 · L1 事件的 subject 字段存在性不一致**

| 位置 | 说法 |
|------|------|
| **M1 §5** | "事件 body 里必须有 `subject` 字段（subject: urn:...），使事件可被 URN 索引" |
| **M1 §8.1** | "所有事件 body 的 `subject` 字段必须是合法 URN" |
| **M3 §3.2** | L1 骨架 5 字段：`event_id / event_type / event_layer / emitted_at / emitted_by`，**没有 subject** |
| **M3 §3.1** | L1 事件示例字段：`artifact_urn` / `task_urn` / `producer_task_urn` / `target_task_urn`……每类 L1 按 event_type 各自命名 |
| **M3 §5.1** | L2 骨架 6 字段，也**没有 subject** |

**诊断**：
- **M1**：事件统一用 `subject` 字段表达"这条事件讲的是谁"
- **M3**：事件按类型各自用 `artifact_urn` / `task_urn` 等具体字段，**每类 L1 表达"主语"的字段名都不一样**

两种设计哲学：
- **M1 风格（统一 subject）**：好处是索引简单（所有事件一个字段查），坏处是 `artifact.published` 的 subject 是 artifact，`task.finished` 的 subject 是 task，语义要靠 event_type 复合推断
- **M3 风格（按类型命名）**：好处是字段名自带语义（一眼看出是 artifact 事件还是 task 事件），坏处是**没有统一入口做"按 URN 反查所有相关事件"**（要 union 多个字段）

**建议选项**：

| 方案 | 说明 |
|------|------|
| **A · 采用 M1 风格** | 所有 L1 事件强制有 `subject`；具体字段（`artifact_urn` 等）作为 subject 的别名或补充 |
| **B · 采用 M3 风格** | 删掉 M1 §5/§8.1 的 subject 强制；每类事件按自己的语义字段命名；**额外要求 kernel 提供"URN → event 反查索引"**覆盖"多入口"问题 |
| **C · 双轨** | 骨架要求 `subject`（统一索引），同时**允许**按类型的别名字段（`artifact_urn` = subject 的副本）；冗余但工具体验最好 |

**我的倾向**：**C 双轨**——`subject` 做统一索引入口，`artifact_urn` / `task_urn` 是同一 URN 的**别名字段**（工具校验一致性）。这样 M1 的 subject 契约保留，M3 的字段表仍可读。

**等你回答**：A / B / C？

---

### **C-03 · producer_event 到底指向什么**

**冲突点有三处**：

| 位置 | 说法 |
|------|------|
| **M2 §1.1 front-matter** | `created_by_event: task-260418135700-a3f2b1`（event id 字符串） |
| **M2 §4.1 三元组** | `producer_event: task-260418135700-a3f2b1`（event id） |
| **M2 §4.3** | "producer_event 必须是当前 actor 刚刚写入的最新事件……自动把最近一次同 actor 的 `task.finished` / `stage.entered` 事件填入" |
| **M2 §4.4** | "producer_event 永远指向 **L1 层事件的 URN**" — 这里又说是 **URN**，不是 event id |
| **M3 §3.1** | `artifact.published` 字段是 `producer_task_urn`（指向 **task URN**，不是 event id） |

**诊断**：这条冲突**跨三篇**：
1. **M2 内部打架**：§4.1 说 producer_event 是 event id，§4.4 说是 L1 事件的 URN。**事件身份是 event id，不是 URN**（M1 §5 明确说事件不用 URN），所以 §4.4 的"L1 事件的 URN"措辞错了，应该是 "L1 事件的 event_id"。
2. **M2 vs M3 语义不同**：M2 把 artifact 的 producer 字段指向 event，M3 把 artifact 的 producer 指向 task URN。**同一件事两种记账方式**。
3. **M2 §4.3 的 `stage.entered`**：M3 有 `stage.entered` L1 事件，但它不产 artifact。把它列为 artifact 的 producer_event 语义违和。

**建议选项**：

| 方案 | 说明 |
|------|------|
| **A · 只存 task URN（M3 风格）** | artifact 的 provenance 只记 `producer_task_urn`，不记 event_id；想查事件时从 task URN 二跳查 `task.finished` 事件 | 链路多一跳，但和 M3 的 L1 枚举一致 |
| **B · 只存 event id（M2 §4.1 风格）** | artifact 的 provenance 只记 event_id；想查 task 从 event 里的 `task_urn` 字段二跳 | M3 §3.1 的 L1 字段表要调，改成记 event 而非 task |
| **C · 两个都存** | front-matter 同时存 `producer_event_id` 和 `producer_task_urn`，可以互相校验 | 冗余但鲁棒；轻微增加写入负担 |

**并修正 M2 §4.3 的"stage.entered"**：artifact 的 producer 只能是 `task.finished` 或 `artifact.published`，不能是 `stage.entered`（后者不产出 artifact）。

**我的倾向**：**C**。provenance 是整个 drift / evolution 的锚，多存一份交叉校验值得。

**等你回答**：A / B / C？并且确认去掉 M2 §4.3 的 "stage.entered"。

---

## 2. P1 冲突详情（建议改）

> v1 记录保留；所有条目已在 v2 §0 决策，按 §1 落盘修复。

---

### **C-04 · artifact 生命周期事件名 vs L1 10 类枚举对不上**

| M2 §6 生命周期图 | M3 §3.1 L1 枚举 | 状态 |
|------------------|-----------------|------|
| `artifact.created` | ❌ 不存在 | M3 最接近的是 `artifact.published`，但语义偏 "从 draft 转为收录"，和 created 不等价 |
| `artifact.updated` | ❌ 不存在 | M3 封板 10 类里没有；见 C-05 |
| `artifact.revised` | `artifact.superseded`？ | 命名不一致，M2 强调"产生新 rev"，M3 强调"旧 rev 被覆盖"，同一事件两种称呼 |
| `artifact.archived` | ❌ 不存在 | M3 只定义了 L2 事件归档，没定义 artifact 归档事件 |

**建议处置**（不等你决策，先写进报告，你选）：

- 统一以 **M3 为准**（L1 10 类封板是你刚拍板的），M2 §6 图改成：
  - `artifact.created` → `artifact.published`（去掉 draft → live 这个事件；draft 状态**不产事件**，publish 才产）
  - `artifact.updated` → **删除此路径**（见 C-05，published 后禁止 updated）
  - `artifact.revised` → `artifact.superseded`
  - `artifact.archived` → 要么**新增 L1 事件**（但这违反 "10 类封板"），要么**删掉 archived 状态**（改成"artifact 不 archive，过期的 artifact 靠 `artifact.superseded` + 查 manifest 得到"）

**我的倾向**：删掉 `artifact.archived`。artifact 没有真正的 "archived" 状态——只有"被更新的 rev 取代"或"被作废"两种情况，分别对应 `artifact.superseded` / `artifact.retracted`。M2 §6 的 `archived` 是从 Git 概念借来的，在 piao-pipeline 里多余。

**等你决策**：同意这个统一方案？

---

### **C-05 · `artifact.updated` 路径与 M1 §10.1 "published 禁改" 冲突**

- **M1 §10.1**：published artifact 禁止原地修改
- **M2 §6 图**：`live → live (sha 变，URN 不变) + emit(artifact.updated)`

**诊断**：M2 §6 的图是 **M1 §10.1 拍板之前**画的，当时允许"小修不升 rev"。现在 M1 §10.1 已封板禁止，M2 §6 必须同步。

**建议处置**：
- 删掉 `live → live (sha 变)` 这条路径
- draft 阶段的修改**不产事件**（不落入 journal，靠 git diff 自治）
- published 后任何修改**必走 rev 升降** → `artifact.superseded`

**这条和 C-04 是同一次修改**，合并处理。

---

### **C-06 · M1 `event` kind 的历史残留**

- M1 §2 kind 枚举中 `event` 注释："用 event_id 即可引用，此 kind 仅用于归档引用"
- M3 通篇未使用 `urn:piao:...:event:...` 形式

**诊断**：这个 kind 是 M1 预留的，但 M3 没有任何场景需要它。事件身份是 event_id（短格式），归档后也是通过 event_id 查。`urn:...:event:...` 这个 URN 构造出来不服务任何查询。

**建议处置**：
- 从 M1 §2 kind 枚举中**删除 `event`**
- 或保留但在注释里改为 "预留，v1 期间不使用；如 M5 归档系统需要时再启用"

**我的倾向**：删掉。不用的 kind 留着只会让校验器误放行错误 URN。

---

### **C-07 · published 判定在两篇里严格度不同**

- **M1 §10.1**：published = manifest 收录 **AND** `artifact.published` L1 事件已写入（**双条件 AND**）
- **M3 §6.1 条件 2**："产物已固化 = 所有 artifact 都已 `artifact.published`"（**只查事件**）

**诊断**：严格来说，**M3 的归档器会在 "事件写了但 manifest 没写" 的 bug 场景下误放行**。虽然这种场景不该发生（`event-journal-append` 工具应原子性保证两者同时写），但契约层面 M3 的条件比 M1 弱。

**建议处置**：
- 在 M3 §6.1 注一句："`artifact.published` 事件存在即可，因为 `event-journal-append` 工具保证事件写入和 manifest 更新的原子性（见 M4 工具链）"
- 或改严为双条件 AND，但这会让 M3 的"三条件全 L1 客观可查"的干净度下降

**我的倾向**：保留 M3 §6.1 现状，加脚注说明"依赖 M4 的原子性保证"。

---

## 3. P2 自动修复项

以下已由本次扫描**直接改掉**（或标记为无冲突），不需要决策：

### **C-08 · kind=rule vs artifact_type=rule 映射关系不明**（P2）

**处置**：在 M2 §2 表格下方加一行说明：
> **kind 与 artifact_type 的映射**：URN 中的 `kind` 段（如 `rule` / `skill`）对应 M1 §2 枚举；front-matter 里的 `artifact_type` 字段必须与 URN 的 kind 段**严格一致**或**派生自**（例：kind=`artifact`，artifact_type 可以是 `spec.structured`；kind=`rule`，artifact_type 必须是 `rule` 或 `rule.<subtype>`）。

（下一步我会落盘这个修改。）

### **C-09 · manifest vs front-matter 一致性校验缺失**（P2）

**处置**：在 M2 §9 校验器伪码中补一条：
- `manifest_front_matter_consistency: bool` — 校验 manifest 里的 `urn/content_sha256/event_id` 与 artifact 文件自身 front-matter 一致。

（下一步落盘。）

### **C-10 · L1/L2 术语（Artifact 事件 / Execution 事件）**（P2 · 确认无冲突）

**结论**：M2 §4.4 和 M3 §2.2 术语一致，仅做确认，无改动。

### **C-11 · archive 术语混用（artifact 归档 vs L2 事件归档）**（P2）

**处置**：在 M3 §6 标题旁加括号 "（L2 事件归档；区别于 artifact 层面的 `superseded`/`retracted`）"，消歧。

（下一步落盘。）

---

## 4. 等待决策清单（v1 遗留，已在 v2 §0 全部回答）

> ⚠️ 此节为 v1 快照。以下问题均已决策，答案见 v2 §0 决策总览。保留仅供溯源。

恳请按以下顺序回答，我按决策批量修复：

1. **C-01 事件 id 格式**：A / B / C / 其他？
2. **C-02 subject 字段**：A / B / C？
3. **C-03 producer_event 指向**：A / B / C？并确认去掉 "stage.entered" 作为 artifact 的 producer？
4. **C-04 + C-05 artifact 生命周期事件统一**：同意我列的统一方案（对齐 M3，删 archived 状态）？
5. **C-06 `event` kind**：删 / 改注释保留？
6. **C-07 published 判定**：加脚注说明 vs 改严双条件？

---

**本报告状态**：v2 · resolved。v1 所有 P0/P1/P2 项已决策并落盘修复；v1 原始内容保留供溯源。

**后续**：如需对 `07-extensibility.md` / `scenario-wordlist.md` 做同步更新，等用户决策后另起一轮。
