---
id: finalization-template
version: 1.0.0
scope: generic
category: archive
description: 里程碑封版终态文档生成器。六段式终态文档 + γ 门禁 self-review 模板。适用于任何需要封版/阶段性收尾/正式交付决议的场景（里程碑 closeout、版本发布、阶段交付、正式 review 报告等）。触发词：封版、finalization、final-decisions、里程碑收尾、封版决议、closeout、封版文档
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Finalization Template · 里程碑封版终态文档

## 概述

本 skill 是演进式研发中**阶段性收尾**的可复用范式。

**核心问题**：阶段性收尾（里程碑封版、版本发布、正式交付）常陷入两种极端：
- **太随意**：一行 commit message 就封版，事后找不到决策依据
- **太仪式化**：上百页文档没人看，封完就过时

折中方案：**六段式终态文档 + γ self-review 8 项门禁**。

> 📖 本 skill 的历史源头是 2026-04 某演进型 pipeline 的 v0.1 封版过程；
> 作为通用能力从该项目抽取出来，后续任何需要"阶段性收尾决议"的场景都可用。

---

## 什么时候用本 skill

### ✅ 适用
- 里程碑封版（MN → MN+1 边界）
- 版本正式发布（v0.1 → v0.2、v1.0.0 → v1.1.0 等）
- 阶段性交付（季度收口、半年总结）
- 多方决议需留痕（团队对齐后的正式决议）

### ❌ 不适用
- 单个需求的交付 → 用 pl archive 命令或栈级 `migration-doc-generator`（若存在）
- 纯技术债沉淀 → 用项目的 debt-ledger / issue tracker
- 代码层面的 review → 用栈级 code-review skill
- 日常 bugfix / minor → git commit message 即可

---

## 核心模板：六段式终态文档

```markdown
# <project-or-subsystem> <version> 封版决议（final-decisions）

- **artifact_kind**: artifact
- **artifact_type**: final_decisions
- **artifact_urn**: urn:<project>:artifact:<scope>:<version>_final_decisions@v1
- **status**: published
- **rev**: v1
- **supersedes**: urn:<project>:artifact:<scope>:<last_kickoff>@v1   # kickoff → final 闭合
- **upstream_anchor**: [上游依赖 artifact URN 列表（证据链）]
- **milestone**: MN （阶段 · 工作流 · 版本 closeout）
- **scope_hash**: <scope-descriptor>

---

## §0 覆盖范围与非覆盖范围（scope）

### §0.1 覆盖范围（本次封版所含）
列出具体封住了哪些对象（URN + rev + sha256 三元组在 §2）

### §0.2 非覆盖范围（刻意排除）
显式列出哪些对象 defer-to-下一版本，理由写清楚。
**关键**：非覆盖范围是必写的，否则边界模糊、事后扩大解释。

---

## §1 启动-收尾接力链闭合

显式记录本版的 kickoff → final-decisions 接力链：
- §1.1 接力链总览（ASCII 图）
- §1.2 范式演进说明（本代与上一代的方法论差异）
- §1.3 链路闭合事件（journal 里对应的事件 URN）

关联规则：`PIAO-001-KICKOFF`（见 `assets/pl/rules/piao-pipeline-discipline.md`）

---

## §2 封版对象清单（URN + rev + sha256 三元组）

**这是本文档的"单一事实源"**——任何事后争议以此为准。

| # | artifact_urn | rev | content_sha256 | 来源 commit |
|---|---|---|---|---|
| 1 | urn:... | v1.4 | sha256:... | commit-id |
| 2 | urn:... | v1 | sha256:... | commit-id |

关联规则：`PIAO-001-SHA256`

---

## §3 关键决议记录

按 **"问题 → 方案 → 理由 → 影响"** 四段式记录本版的所有重要决策。

每条决议：
- **问题 QN**：一句话描述
- **方案**：最终选择
- **理由**：为什么这样选
- **影响**：对未来版本的约束或开放点

---

## §4 发现项登记（discoveries）

封版过程中发现但**有意不修**的问题（遗留项）。

每条 discovery 必须包含：
| 字段 | 示例 |
|---|---|
| `id` | `DISC-V01-001` |
| `content` | 具体问题 |
| `defer_to` | 下一版本 / 具体里程碑 |
| `trigger_condition` | 什么时候必须重新审视（可观察锚点） |
| `compensation_path` | 在触发前如何补偿 |
| `impact` | 当前影响面 |

关联规则：`PIAO-001-DEFERRED`

---

## §5 下一版本入口清单（next-version-entry）

列出下一版本要做的事、触发条件、入口点。
**不实施、只清单**——为下一代 kickoff 准备素材。

---

## §6 Self-Review 签收（γ 门禁）

封版自检清单。通过全部门禁才允许 `status: published`。

### γ 门禁 · 8 项自检

| # | 检查项 | 预期 | 本次结果 |
|---|---|---|---|
| 1 | §0 范围表完整（含非覆盖） | 是 | ✅ / ❌ |
| 2 | §1 kickoff→final 接力链显式 | 是 | ✅ / ❌ |
| 3 | §2 三元组全部登记且 sha256 与落盘态一致 | 是 | ✅ / ❌ |
| 4 | §3 决议可追溯到事件 journal | 是 | ✅ / ❌ |
| 5 | §4 发现项全部带 trigger_condition | 是 | ✅ / ❌ |
| 6 | §5 下一版本入口列表不空 | 是 | ✅ / ❌ |
| 7 | 文档本身 URN + sha256 可计算 | 是 | ✅ / ❌ |
| 8 | 无"以后/有空/尽快"等禁用词 | 是 | ✅ / ❌ |

**通过条件**：8/8 全绿才允许 status 从 draft → published。

关联规则：`PIAO-001` 全部三条纪律 + `ACC-001` 验收门禁
```

---

## 工作流：三步法

### Step 1 · 封版前准备（draft 态）

1. **确认 kickoff 存在**：本代必须有对应的 `MN-kickoff@v1` artifact，记录了本代的 scope 和
   paradigm_innovation。如无 → **先补 kickoff 再谈封版**（违反 `PIAO-001-KICKOFF`）。
2. **冻结范围**：确定 §0.1 覆盖范围清单。对每个边界模糊的对象做裁决——要么纳入、要么显式 defer。
   **不允许"模糊带过"**。
3. **收集证据**：对每个纳入对象，收集 URN + rev + content_sha256，**先落盘再算 sha**
   （违反 `PIAO-001-SHA256` 会留下时序陷阱）。

### Step 2 · 起草 final-decisions（六段式）

按上述模板逐段填写。关键纪律：
- §2 清单必须在 git commit 之后回填 commit-id（否则字段循环依赖）
- §4 发现项的 `trigger_condition` 字段由配套 validator 检查
- §6 self-review 必须**逐项**检查，不允许"整体通过"

### Step 3 · γ 门禁 self-review

完成 §6 自检清单：
- 8 项任一未通过 → 回到 Step 2 修复
- 8/8 通过 → 将 status 从 `draft` 改为 `published`
- 在事件 journal 写入一条 `artifact.published` 事件（**先改文档、再算 sha、再写事件**）

---

## 配套资产

### 检查脚本（推荐实现）

```bash
# scripts/validate-finalization.sh <final-decisions.md>
# 按 γ 门禁 8 项自动检查：
# - 解析 §0/§1/§2/§4/§5/§6 段落
# - 对 §2 三元组：重算 sha256 并比对
# - 对 §4 发现项：检测禁用词、必填字段
# - 输出 PASS/FAIL 报告
```

（本 skill 暂不内置脚本。**在实际用到第二次时再实现**——避免 over-engineering。）

### 模板文件路径建议

可将本 skill 的"核心模板"段落复制到：
- `docs/<project>/_review/templates/final-decisions-template.md`
- 每次封版时从模板拷贝一份、填充内容

---

## 使用示例

### 示例 1 · 子系统的 v0.2 封版

- 输入：v0.2 期间的演进事件 + 对应的 `v0_2-kickoff@v1`
- 输出：`docs/<subsystem>/_review/v0_2-final-decisions.md`
- 关键差异：`scope_hash` 从 `core-only` 变为 `core+extension`

### 示例 2 · 跨季度阶段性收口

- 输入：本季度交付的 N 个需求 + issue tracker ID 列表
- 输出：`docs/closeouts/<YYYY-QN>-finalization.md`
- 关键差异：§2 清单变为"本季度交付 change 的 commit-id + sha256"

### 示例 3 · 技术栈迁移收口

- 输入：legacy → modern 迁移完成的 N 个模块
- 输出：`docs/migration/_review/<migration-name>-finalization.md`
- 关键差异：§4 发现项偏重"遗留的兼容性边界"

---

## 与其他 skill/rule 的边界

| 工具 | 职责 | 与本 skill 关系 |
|---|---|---|
| `spec-normalizer` | 需求标准化 | **上游**：定义"做什么"，本 skill 定义"做完了" |
| 栈级 `migration-doc-generator` | 单需求迁移文档 | **并列**：它做单次，本 skill 做阶段性 |
| `piao-pipeline-discipline` rule | 演进三纪律 | **规范**：本 skill 是规则的模板化 |
| pl `archive` 命令 | 归档单个 change | **并列**：它做 change 级，本 skill 做版本级 |

---

## 反模式（不要这样做）

### ❌ 反模式 1：把 final-decisions 写成 CHANGELOG
CHANGELOG 是"做了什么"，final-decisions 是 **"决议了什么 + 留白了什么 + 下次从哪开始"**。
只写做了什么的是缺角文档，必然导致事后回溯困难。

### ❌ 反模式 2：§6 self-review 整体打勾
必须逐项检查。整体"通过"等于没查。

### ❌ 反模式 3：把 §4 发现项写成"TODO 列表"
TODO 没有 trigger_condition，会被永久遗忘。发现项必须带"什么时候重新审视"。

### ❌ 反模式 4：跳过 kickoff 直接封版
违反 `PIAO-001-KICKOFF`。封版必须与 kickoff 成对——否则边界模糊。

### ❌ 反模式 5：§0.2 非覆盖范围省略
"刻意不做"必须显式记录。省略非覆盖范围等于给事后任意扩大解释留了口子。

---

## 附：真实案例参考

本 skill 的所有设计都基于以下真实案例：

> **案例**：某演进型 pipeline v0.1 封版（2026-04）
> - **规模**：290 行文档 · 六段式齐备 · γ₃ 8/8 通过
> - **关键收获**：§0.2 非覆盖范围和 §4 trigger_condition 是最容易省略、但事后回溯价值最高的两节

脱敏的真实例子（六段式骨架 + 内容）见 `examples/`（可选，本版暂不内置）。

---

## 相关文档

- [`piao-pipeline-discipline.md`](../../rules/piao-pipeline-discipline.md) — 演进三纪律
- [`acceptance-criteria.md`](../../rules/acceptance-criteria.md) — 验收门禁规范
- [`working-with-fuzzy-intent.md`](../../../../docs/guides/working-with-fuzzy-intent.md) — 辩证方法论

## 版本

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0.0 | 2026-04-23 | 首版 · 从源项目脱敏迁入独立仓（见 frontmatter.migrated_from） |
