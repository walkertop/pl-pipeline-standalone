---
urn: urn:piao:evolution_source:kernel:m1_exit_check@v1
kind: evolution_source
rev: v1
status: published
produced_by: m1-review-2026-04-18
supersedes: null
wordcheck_exempt: true
upstream: urn:piao:snapshot:kernel:m1_final_decisions@v1
---

# M1 Exit Check · 入口清单实际状态

> 本文档是 **M1 final-decisions §4 的入口清单**（4 项 checkbox）在 M1 收尾时的**实际状态登记**。
>
> 为什么单独一份文档：`M1-final-decisions.md` 是 `snapshot`，按 `01-identity-model.md §14` 的契约**一经产出不再修改**。入口清单的"实际勾选状态"属于**动态事实**，不应污染 snapshot；故独立为 `evolution_source` 记账。
>
> 读这份文档的人应当先读 `M1-final-decisions.md` 再读本表。

---

## 0. 对应关系

| M1-final-decisions §4 条目 | 本文档对应段 |
|---------------------------|-------------|
| 条目 1（kernel-wordcheck.sh 骨架） | §1 |
| 条目 2（00-overview §1 章节索引对齐） | §2 |
| 条目 3（03-layered-architecture kind 枚举变更史） | §3 |
| 条目 4（adapters/ 骨架） | §4 |

---

## 1. 条目 1 — `scripts/kernel-wordcheck.sh` 骨架就绪

**状态**：✅ **已完成**

**交付物**：
- 路径：`scripts/kernel-wordcheck.sh`
- 参数：`--ci`、`--file FILE`、`--list`、`--help`（详见脚本 `--help` 输出）
- 词表来源：`docs/piao-pipeline/kernel/scenario-wordlist.md`（21 条 BAN + 4 条 WARN）
- 启发式豁免：4 重（URN/路径、元讨论关键词、反引号 inline code 区域、词表行 `/` 分隔）+ 文件级 `wordcheck_exempt: true` front-matter（v0.2 实现，见本 Ledger §5）

**当前扫描基线**：`./scripts/kernel-wordcheck.sh --ci` → 6 条 BAN 全部登记在 `M1-debt-ledger.md §1.1`

**后续路径**：
- v0.2：git pre-commit hook + inline escape（见 `M1-final-decisions.md §1 决议 4`）

---

## 2. 条目 2 — `00-overview.md §1 核心公式` 章节索引对齐

**状态**：✅ **已完成**

**修订要点**：
- 从 6 维扩为 7 维（补齐 `Extensibility`）
- 章节映射更正：`03-event-model.md` → `03-layered-architecture.md`
- 每行补"状态"列（M1/M2/M3 定稿 vs 规划中）
- §1 表格下方补脚注解释"章节 03 的命名变化"（层级模型与事件模型合并于同一篇）

**对齐结果**：

| §1 条目 | 实际 kernel 文件 | 一致 |
|---------|-----------------|------|
| Identity | `01-identity-model.md` | ✅ |
| Artifact | `02-artifact-model.md` | ✅ |
| Layering × Event | `03-layered-architecture.md` | ✅ |
| Snapshot | `04-version-snapshot.md`（规划） | ✅（位规划状态） |
| Drift | `05-drift-propagation.md`（规划） | ✅（位规划状态） |
| Evolution | `06-evolution-layer.md`（规划） | ✅（位规划状态） |
| Extensibility | `07-extensibility.md` | ✅ |

**无遗漏**：7 个 kernel 文档/规划文档在 00-overview 里都能一一检索到。

---

## 3. 条目 3 — `03-layered-architecture.md` kind 枚举变更史段落

**状态**：✅ **已完成**（本 Ledger 产出时同步补齐）

**已落位**：
- `01-identity-model.md §2.4` — kind 枚举变更史表（append-only；记录 `page` / `event` kind 删除）
- `03-layered-architecture.md §8.3` — 追加了交叉引用段，明确声明"分层模型不引入独立 kind 枚举，以 01 为单一真源"，并补注 kind 删除对分层的影响（`page` 合并后所有 `unit.*` 事件 subject 统一；`event` kind 删除不影响分层）

**豁免等级**：无。

---

## 4. 条目 4 — `docs/piao-pipeline/adapters/<adapter_name>/` 骨架

**状态**：🚧 **未启动**（有意推迟到 M2）

**推迟理由**：
1. M1 范围已明确为 **kernel 身份与边界收敛**（四项决议全部落于 kernel 层）；
2. adapter 骨架涉及**把现有业务示例从 `02-artifact-model.md §7` / §10.1 迁出**（详见 `M1-debt-ledger.md §1.1`），这部分是 M2 第一批输入；
3. 先启动 adapter 骨架会反过来干扰 kernel 的通用化清理节奏。

**M2 入口先决**：
- 本条与 `M1-debt-ledger.md §3 关闭条件` 第 3 项是**同一件事**，M2 启动时一起做；
- 届时产出物：`docs/piao-pipeline/adapters/<adapter_name>/README.md` + 从 02 迁入的业务示例段落。

---

## 5. 总评

| 条目 | 状态 | 去向 |
|------|------|------|
| 1 | ✅ 已完成 | v0.2 hook + escape 持续演进 |
| 2 | ✅ 已完成 | 后续随 kernel 文档增量同步 |
| 3 | ✅ 已完成 | 01 §2.4 + 03 §8.3 交叉引用已落位 |
| 4 | 🚧 未启动 | M2 第一批输入（与 `M1-debt-ledger.md §3` 合并） |

**M1 可否宣布收尾**：**可以**。条目 1/2/3 已全部完成；条目 4 作为 M2 入口任务有明确锚点，不阻塞 M1 定稿。

---

## 6. 关闭条件

本 Ledger 在满足以下所有条件后可发 `evolution_source.consumed`：

- [x] F3 完成（`03-layered-architecture.md §8.3` 增加对 `01 §2.4` 的交叉引用段）
- [ ] M2 启动时 adapter 骨架首个文档产出
- [ ] 本 Ledger 的 `status` 从 `published` → `consumed`，在 `M2-final-decisions@v1` 中引用

---

**本 Ledger 状态**：published
**上游锚点**：`urn:piao:snapshot:kernel:m1_final_decisions@v1` · §4
**并列账本**：`urn:piao:evolution_source:kernel:m1_debt_ledger@v1`
