# piao-pipeline

> 一套 **"状态即事实、演化即一等公民"** 的 AI 辅助研发流水线架构。
>
> 解决一个具体问题：**当 Agent 的任何一步出错，整条流水线能感知、定位、传播、修复，并把教训沉淀回系统本身。**

---

## 📌 阅读本文档的定位说明（独立仓版本）

本目录 `assets/piao/docs/` 是 piao-pipeline kernel v0.1 封版文档的**完整历史快照**，
由宿主 `KuiklyPolyCity/docs/piao-pipeline/` 于 2026-04-21 整体迁移而来。

文档内部可能出现的相对路径（如 `scripts/piao-*.sh`、`pipeline-output/piao/kernel-events/*.jsonl`）
在历史上下文中指向**当时宿主项目的布局**；在 pl-pipeline 独立仓中，实际路径已变为：

| 文档中出现的路径 | 独立仓实际位置 |
|---|---|
| `scripts/piao-*.sh` | `scripts/piao-*.sh`（一致） |
| `scripts/kernel-wordcheck.sh` | `scripts/piao-kernel-wordcheck.sh`（已改名） |
| `pipeline-output/piao/kernel-events/` | `${PL_OUTPUT}/piao/kernel-events/`（运行时由用户宿主项目产出） |
| `docs/piao-pipeline/kernel/*.md` | `${PL_ASSETS}/piao/docs/kernel/*.md`（即本目录） |

⚠️ **按 piao §4.1 第 1 条"事件不可变"契约，历史文档中的路径叙述不改写**；
   仅在此处集中记录路径映射，供阅读时参照。

---

## 当前状态

**kernel 层 v0.1 已封版**（2026-04-19）· adapter 层 v0.2 入口就位，待首个业务需求触发。

| 层 | 状态 | 终态单一事实源 |
|---|---|---|
| **kernel 七维** | ✅ 封版 | [`kernel/_review/v0_1-final-decisions.md @v1`](kernel/_review/v0_1-final-decisions.md) |
| **M1 债账本** | ✅ @v10（10 轮演进） | [`kernel/_review/M1-debt-ledger.md`](kernel/_review/M1-debt-ledger.md) |
| **adapter 层** | 🚧 待触发 | 候选：`prop_confirm` 业务单元迁移 |

> 单一事实源规则：**任何时候对"v0.1 封版到底封了什么"产生疑问，以 `v0_1-final-decisions.md §2` 的 URN+rev+sha256 三元组为准。** 其余所有文档皆为该表的展开叙事。

---

## 入口选择（按你的目标和时间）

| 你的目标 | 走哪条路 | 时间 |
|---|---|---|
| **快速判断能否用 / 和别人介绍它** | 读 [`00-overview.md`](00-overview.md) | 5 分钟 |
| **深入参与讨论 / Code Review** | `00-overview` → [`v0_1-final-decisions`](kernel/_review/v0_1-final-decisions.md) | 30 分钟 |
| **真正接手推进 v0.2** | 按 [`GUIDED-TOUR.md`](GUIDED-TOUR.md) 走完 6 章 | 半天 |
| **做扩展 / 接 adapter** | [`kernel/07-extensibility.md`](kernel/07-extensibility.md) → `v0_1-final-decisions §5` | 2 小时 |
| **做对标研究** | [`competitive/`](competitive/) 目录 | 视对标项而定 |

---

## 目录结构

```
docs/piao-pipeline/
├── README.md                     ← 你在这里（入口导航）
├── 00-overview.md                ← 核心门面（一页纸心智模型）
├── GUIDED-TOUR.md                ← 新人导读（半天版）
├── kernel/                       ← 七大模型正文 + 封版决议
│   ├── 01-identity-model.md         ← URN 身份（@v1.3）
│   ├── 02-artifact-model.md         ← 工件契约（@v1.4）
│   ├── 03-layered-architecture.md   ← 分层 + 事件（@v1 draft · v0.2 候选升版）
│   ├── 04-version-snapshot.md       ← 版本快照（@v1.2）
│   ├── 05-drift-propagation.md      ← 漂移传播（@v1.1）
│   ├── 06-evolution-model.md        ← 演化与 lazy-load（@v1.1）
│   ├── 07-extensibility.md          ← 扩展性（@v1.1）
│   ├── scenario-wordlist.md         ← kernel 场景禁用词表
│   └── _review/                     ← 25 份里程碑演进史（M1→M7）
│       └── v0_1-final-decisions.md  ← ⭐ v0.1 终态单一事实源
├── adapters/                     ← adapter 层（v0.2 填充）
└── competitive/                  ← 对标研究
```

事件流位于仓库另一处：`pipeline-output/piao/kernel-events/*.jsonl`（append-only JSONL，v0.1 封版态 26 条，合规率 100%）。

---

## 设计底线（不可违背的六条 · 摘自 `00-overview §4`）

1. **事件不可变**：写入后只能追加勘误事件，不能改历史
2. **身份全局唯一**：所有 artifact / task / event 都是 URN
3. **变更必有原因**：强制经 evolution 事件记录
4. **kernel 不知道场景**：禁用场景词（`scripts/kernel-wordcheck.sh` 自动检查）
5. **Lazy > Greedy**：记忆系统默认只加载索引
6. **Artifact-centric**：围绕产出而非 task 组织

---

## 最后一行永远是同一句话

> 这个系统的价值不在每个模块多先进，而在它们**共用一套契约**。契约破了，系统就是普通脚手架。
