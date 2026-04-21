---
urn: urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1
artifact_type: proposal.kernel_minor_upgrade
kind: proposal
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-18T23:15:00+08:00
created_by_event: manual-m2-kernel-upgrade-260418
content_sha256: ""
depends_on:
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v3
  - urn:piao:artifact:adapter/frontend_migration:charter_review@v1
  - urn:piao:artifact:adapter/frontend_migration:task_types_review@v1
  - urn:piao:artifact:kernel:identity_model@v1
  - urn:piao:artifact:kernel:artifact_model@v1
  - urn:piao:artifact:kernel:extensibility@v1
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:kernel:m2_minor_upgrade_planning
  event_id: manual-m2-kernel-upgrade-260418
wordcheck_exempt: true
---

# Kernel 小升 Proposal · 阶段 2 路径 A 收敛

> 本 proposal 是 **`post-m1-kickoff.md §2.3` 分支 2a 路径 A** 的执行文档。
> 输入：M1-debt-ledger §1.2 的 7 条 kernel 缺口（Q1-Q7）+ 两份 adapter review 的 7 条修订建议（R1-R7）。
> 输出：三份 kernel 文档的 `@v1.1` 小升动作清单，以及执行顺序、风险点、回退预案。
> 完成后：M1-debt-ledger §1.2 的 Q1-Q7 可全部 consumed；阶段 2 收敛，进入分支 2b 启动工作流 A（M4 Snapshot Model）。

---

## 1. 为什么是小升（`@v1.1`）而不是大升（`@v2`）

按 `01-identity-model.md §4.2` rev 创建规则：

| 操作 | 是否升 rev |
|------|------|
| 修错别字、修措辞 | ❌ 不升 |
| **补充示例、补充说明** | **✅ 升次版 `v1.1`** |
| 字段重命名、类型变更、枚举增删 | ✅ 升主版 `v2` |
| 删除某个字段 | ✅ 升主版 `v2` |

R1-R7 **全部落在"补充示例 / 补充说明"这一格**：

| 建议 | 变更类型 | 为什么不算大升 |
|------|---------|-------------|
| R1（新增 §3.4 adapter scope 约定） | 新增小节 | `01 §3` 原有三小节未动；§3.4 明文化此前隐含的约定 |
| R2（派生注册方式小节） | 补充说明 | `02 §2` 派生规则未变；只补"注册流程"描述 |
| R3（M1-debt-ledger §1.2） | ledger 自身升版 | 不触达 kernel 主文档 rev |
| R4（占位声明建议格式） | 补充模板 | `07 §2` 四扩展点 schema 未动；末尾加建议模板 |
| R5（`artifact.*` 派生示范） | 补充示例 | `02 §2.1` 映射规则未变；补一行 kind-as-prefix 示范 |
| R6（命名风格建议） | 补充说明 | 非强制约定；不进校验器 |
| R7（扩展点合规性自验证 checklist） | 补充工具 | kernel 硬约束未变；只提供可断言的检验套件 |

**零 schema 变更、零字段删除、零语义反转** → 小升足矣。

**实施影响**：所有现有 adapter（目前仅 `frontend-migration`）**不需要改动**任何现有 front-matter；新增 adapter 将受益于三份升版后的 kernel 文档。

---

## 2. 三文档升版矩阵（R → 文档 → 节号 → 动作）

| # | 来源 | 建议 | 目标文档 | 目标节 | 动作 |
|---|------|-----|---------|-------|------|
| 1 | Q1 / R1 | adapter 自身资产 scope 约定 | `01-identity-model.md` | 新增 §3.4 | 新增一节，~40 行 |
| 2 | Q6 / R6（前半） | task `type` 命名风格 → snake_case | `01-identity-model.md` | §4 末尾或新增 §4.4 | 追加一段非强制约定 |
| 3 | Q2 / R2 | adapter 自用派生 vs 跨 adapter 共用派生的注册路径 | `02-artifact-model.md` | §2 末尾新增 §2.2 | 新增子节，~25 行 |
| 4 | Q5 / R5 | `artifact.*` 派生示范 | `02-artifact-model.md` | §2.1 映射表 + §2 末尾派生示例 | 表格增行；补一段 kind-as-prefix 合法性说明 |
| 5 | Q6 / R6（后半） | artifact `artifact_type` 命名风格 → dot.lowercase + snake_case 段 | `02-artifact-model.md` | §2.1 末尾 | 追加一段非强制约定 |
| 6 | Q3 / R4 | 扩展点占位声明建议格式 | `07-extensibility.md` | §2 末尾新增 §2.5 | 新增一节，四扩展点共用 ~30 行 |
| 7 | Q7 / R7 | 扩展点合规性自验证 checklist | `07-extensibility.md` | §2 末尾新增 §2.6 | 新增一节，四扩展点各一小节 ~60 行 |
| 8 | Q4 | `00-overview.md:93` 的 `viewmodel` WARN 修正 | `00-overview.md`（§3 处理策略见下） | L93 | 文字替换；并入此次小升 |

**三文档升版总体积**：~150-180 行新增（纯补充，不删不改现有内容的语义）。

---

## 3. 执行顺序与依赖

**关键观察**：三文档之间有**弱依赖**——`02 §2.1` 的映射表被 `07 §2.6` 的自验证断言引用；`01 §3.4` 的 scope 约定被 `07 §2.5` 的占位模板引用。

推荐执行顺序（基于依赖最小化）：

```
(S1) 01-identity-model.md @v1.1   ← 先落 §3.4 scope 约定（R1 高优先级）
       │   动作 1 + 动作 2
       │
       ▼
(S2) 02-artifact-model.md @v1.1   ← 建立派生类型的完整说明面
       │   动作 3 + 动作 4 + 动作 5
       │
       ▼
(S3) 07-extensibility.md @v1.1    ← 消费 01/02 的新增内容（占位模板 + 自验证）
       │   动作 6 + 动作 7
       │
       ▼
(S4) 00-overview.md 局部修正      ← 动作 8（§3 策略）
       │
       ▼
(S5) M1-debt-ledger @v4           ← Q1-Q7 → consumed（§1.2 逐条勾选）
       │
       ▼
(S6) 全量 wordcheck + commit
```

**回滚点**：S1 / S2 / S3 每一步都是**独立可 commit 的 git 节点**；若 S3 发现 S2 的某处补充不够可直接打补丁（仍在 `@v1.1` 同一 rev 内，因 draft→published 的单向约束见 `01 §10.1`——kernel 文档在 M1 review 期间处 draft 状态的先例允许在小升窗口内微调，然后一次 publish）。

---

## 4. 动作 8（`00-overview.md:93` WARN）的特殊处理策略

这条是 M1 定稿时 §1.1 登记遗漏的违规（Q4），**严格说属于 §1.1 而非 §1.2**，但由于 `02-artifact-model.md@v2` 阶段 3 清理还没到，先行处理的策略如下：

| 候选策略 | 评价 |
|---------|-----|
| A. 立即改为 `<placeholder>` | 保证 wordcheck 零 WARN；但 `00-overview.md` 升 rev 会扰动整个 kernel 体系 |
| **B. 在 `00-overview.md` 对应行追加 scenario-wordlist 豁免注释（`<!-- kernel-wordcheck-allow: viewmodel @reason=post-m1-ledger-q4 -->`）** | 不升 rev；wordcheck 工具支持豁免注释（见 `scripts/kernel-wordcheck.sh`）；阶段 3 `02@v2` 合并清理时再彻底消除 |
| C. 拖到阶段 3 统一处理 | 保持低扰动，但 wordcheck --ci 期间会持续 WARN |

**推荐策略 B**——低扰动 + 显式记录豁免原因。

**实施验证**：S4 完成后 `./scripts/kernel-wordcheck.sh --ci` 在 `docs/piao-pipeline/kernel/` 下应 **WARN 数下降 ≥1**（其他 BAN 保留至阶段 3）。

> 注：若当前 `kernel-wordcheck.sh` 未支持行内豁免注释语法，则动作 8 降级为策略 C（拖到阶段 3），不阻塞 S1-S3 + S5。

---

## 5. 风险与不确定性

| 风险 | 可能性 | 影响 | 缓解 |
|------|-------|-----|------|
| **R7 的 checklist 过度工程化**（adapter 发现 checklist 不实用） | 中 | 中 | 首版定义为 v0.1，标注"随 adapter 反馈迭代"；保留后续 `07@v1.2` 补丁空间 |
| **R5 的 `artifact.*` 派生示范与阶段 3 `02@v2` 的 artifact_type 重构冲突** | 低 | 中 | 本次只加示例行，不引入新 schema；阶段 3 若大改 schema 可一并重写示例 |
| **R1 scope 约定与现有 `frontend-migration` charter front-matter 冲突** | 低 | 低 | 实测 charter scope 已写为 `adapter/frontend_migration` + unit 名两套路径，与 R1 原文一致 |
| S4（`00-overview.md` 豁免注释）的工具支持缺失 | 中 | 低 | 降级到策略 C（见 §4） |
| **升版后 kernel 文档互相引用的锚点失效** | 低 | 高 | 引用均为节号（如 `§3.4`）；小升仅新增不删旧，锚点稳定 |

---

## 6. 完成条件（Definition of Done）

本 proposal 在以下所有条件全部满足后发 `proposal.implemented` 事件并归档：

- [ ] S1 落地：`01-identity-model.md @v1.1` published（含 §3.4 + §4 命名风格补充）
- [ ] S2 落地：`02-artifact-model.md @v1.1` published（含 §2 派生注册 + §2.1 `artifact.*` 示范 + §2.1 命名风格补充）
- [ ] S3 落地：`07-extensibility.md @v1.1` published（含 §2.5 占位模板 + §2.6 自验证 checklist）
- [ ] S4 落地：`00-overview.md:93` 按策略 B 加豁免注释（或退化到策略 C 并在 §1.2 Q4 标注延期）
- [ ] S5 落地：`M1-debt-ledger @v4` published，§1.2 Q1-Q7 全部勾选 consumed（或显式标注仍在阶段 3 处理的条目）
- [ ] `./scripts/kernel-wordcheck.sh --ci` 在 `docs/piao-pipeline/kernel/` 下返回 exit 0（BAN 违规数不增加；WARN 数按策略 B 预期下降 ≥1）
- [ ] `./scripts/kernel-wordcheck.sh --file` 对三份升版后的 kernel 主文档逐一 exit 0
- [ ] 每份升版文档的 front-matter 含 `rev_history` 段追加一条 v1→v1.1 条目，指向本 proposal URN 作为 `triggered_by`

---

## 7. 完成后的下游触发

- `M1-debt-ledger @v4`：Q1-Q7 → consumed；若仅剩 §1.1 未清理（等待阶段 3）则 ledger 自身维持 published，等阶段 3 收尾
- `adapters/README.md`：阶段 2 路径 A 完结标记 + 启动分支 2b 的说明
- `post-m1-kickoff.md`：补一条"阶段 2 路径 A 完结"快照引用
- **分支 2b 启动**：工作流 A（M4 Snapshot Model）解冻；kernel 健壮度已通过两份 adapter 文档 + 一次小升的三角验证

---

## 8. 不做的事（scope out）

本 proposal **明确不包含**以下内容，避免范围蔓延：

| 不做的事 | 理由 |
|---------|-----|
| 新增任何扩展点 | 违反 `07 §4` 四问；当前两个扩展点压测尚未完成 |
| 修改 kernel 基础枚举（kind / event_type / Stage） | 小升不允许（`07 §1 边界 2`） |
| 重构 `02-artifact-model.md` 的五要素契约 | 需要大升 `@v2`，合并阶段 3 §1.1 清理时处理 |
| 引入 `piao-kernel/` 代码目录（见 `07 §9.2`） | 仍是 v0.2 目标 |
| 多 adapter 共用派生的"升 kernel"仪式 | R2 仅做流程声明，不做完整流程实现（留 M4 之后） |
| `scenario-wordlist.md` 词表的扩充 | 需要与 `02@v2` 清理统一 |

---

**本 proposal 状态**：published · rev v1（2026-04-18 23:15）
**上游锚点**：
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v3`
- `urn:piao:artifact:adapter/frontend_migration:charter_review@v1`
- `urn:piao:artifact:adapter/frontend_migration:task_types_review@v1`
**下游候选**：
- `01-identity-model.md @v1.1` · `02-artifact-model.md @v1.1` · `07-extensibility.md @v1.1`
- `M1-debt-ledger @v4`（Q1-Q7 consumed）
- `adapters/README.md` 更新
**关闭候选**：`urn:piao:snapshot:kernel:m2_minor_upgrade_complete@v1`（阶段 2 完结快照，与分支 2b 启动同步产出）
