# Piao Scripts Dependency Analysis

> **Phase P1-1 产出** · 2026-04-21
>
> 目标：分析宿主 KuiklyPolyCity 中 piao-pipeline 相关 bash 脚本的依赖关系，
> 为 P1-2（迁移到独立仓）提供准确的迁移清单和改造清单。

---

## 一、结论速览

| 维度 | 结论 |
|---|---|
| **纳入迁移的脚本** | 5 个 (`piao-snapshot-produce` / `piao-snapshot-diff` / `piao-drift-compute` / `piao-evolution-scan` / `kernel-wordcheck`) |
| **排除迁移的脚本** | 2 个 (`snapshot-generator` / `state-generator`，Kuikly 业务耦合过深，留宿主) |
| **脚本间 source 依赖** | **0 条**（5 个脚本彼此独立，可分别改造分别提交） |
| **主要硬编码点** | ① 契约文档路径 `docs/piao-pipeline/kernel/*.md` ② 输出路径 `pipeline-output/piao/` ③ `kernel-wordcheck` 扫描目录 |
| **外部工具依赖** | `python3` (piao-snapshot-diff / piao-drift-compute / piao-evolution-scan)、`shasum`、`jq` |
| **估计改造工作量** | 5 个脚本 × 0.5-1 小时 ≈ 3-5 小时 |

---

## 二、7 个候选脚本梳理

宿主 `scripts/` 下与 piao-pipeline 相关的 bash 脚本共 7 个，迁移决策如下：

| # | 脚本 | 行数 | 迁移？ | 决策理由 |
|---|---|---|---|---|
| 1 | `piao-snapshot-produce.sh` | ~320 | ✅ 迁 | piao-kernel §04 契约实现，无业务耦合 |
| 2 | `piao-snapshot-diff.sh` | ~260 | ✅ 迁 | piao-kernel §04 §5 算子实现 |
| 3 | `piao-drift-compute.sh` | ~875 | ✅ 迁 | piao-kernel §05 drift 计算器 |
| 4 | `piao-evolution-scan.sh` | ~500 | ✅ 迁 | piao-kernel §06 evolution 扫描器 |
| 5 | `kernel-wordcheck.sh` | ~310 | ✅ 迁（改名为 `piao-kernel-wordcheck.sh`）| piao-kernel §07 场景词检查器 |
| 6 | `snapshot-generator.sh` | ~450 | ❌ **留宿主** | 生成 `ARCHITECTURE_SNAPSHOT.md`，硬编码扫描 `shared/src/commonMain/kotlin/com/tencent/kuiklypolycity/page`、已知组件名白名单等，Kuikly 业务特定 |
| 7 | `state-generator.sh` | ~717 | ❌ **留宿主** | 硬编码 Kuikly page 目录、openspec 模板、Layer 2/3 组件名白名单，业务耦合过深，v0.2 可泛化后再迁 |

> ⚠️ 上一轮方案里曾把 `snapshot-generator.sh` / `state-generator.sh` 列为"piao 家族"，经本次源码检查确认**它们是 Kuikly 业务脚本，名字带 snapshot 是巧合**，正式从迁移清单剔除。

---

## 三、5 个待迁脚本的依赖关系

### 3.1 脚本间依赖（source / exec / 共享状态）

```
piao-snapshot-produce.sh  ─── 产出 ──▶  snapshot@v1.yaml  ──┐
                                                             │
piao-snapshot-diff.sh     ─── 消费 2 个 snapshot ◀───────────┤
                                                             │
piao-drift-compute.sh     ─── 消费 2 个 snapshot ◀───────────┘
                          ─── 产出 ──▶  drift@v1.yaml + 2 个 L1 事件 ──┐
                                                                        │
piao-evolution-scan.sh    ─── 消费 drift event + drift artifact ◀──────┘
                          ─── 产出 ──▶  evolution.scan_result + 2 个 L1 事件

kernel-wordcheck.sh       ─── 扫描 markdown ──▶  报告（人工查看 / CI 退出码）
```

**关键观察**：
- 5 个脚本**没有任何 `source xxx.sh` 引用**（经 grep 验证）
- 它们通过 **yaml / jsonl 产物** 进行数据交互，不是代码耦合
- 这意味着可以**分别迁移、分别改造、分别提交**（每个脚本一个 commit）

### 3.2 对宿主外部世界的依赖

| 依赖类别 | 内容 | 处置 |
|---|---|---|
| **python3** | 4 个脚本内嵌 `python3 -` heredoc（yaml 解析、canonical 化、sha256、jsonl 原子写入）| 保持 python3，文档里声明为前置依赖 |
| **shasum** | `piao-snapshot-produce` / `piao-drift-compute` 算 content_sha256 | 所有 Unix/macOS/Linux 内置 |
| **契约文档路径** | 注释和报错消息里引用 `docs/piao-pipeline/kernel/*.md` | 迁移后改为 `$PL_ASSETS/piao/docs/kernel/*.md` |
| **输出目录** | 默认输出到 `pipeline-output/snapshots/` / `pipeline-output/drifts/` / `pipeline-output/piao/kernel-events/` | 迁移后统一改为 `$PL_OUTPUT/piao/{snapshots,drifts,kernel-events}/` |

### 3.3 宿主项目无关证据

```bash
# 在宿主项目运行：
grep -Ei "KuiklyPolyCity|daojuROOT|shared/src|kuiklypolycity|openspec" \
  scripts/piao-*.sh scripts/kernel-wordcheck.sh
# → 0 命中（已验证）
```

这证实了这 5 个脚本是**真正场景无关**的 piao-kernel 工具，符合 piao-pipeline
"kernel 不知道场景"的设计底线（见 `docs/piao-pipeline/00-overview.md §4` 第 4 条）。

---

## 四、改造清单（P1-2 的精确工作项）

对每个脚本统一执行以下 6 步改造：

### R1. 头三行改造
```diff
  #!/usr/bin/env bash
+ source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
  set -euo pipefail
- SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
- PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
```
（PROJECT_ROOT 不再手动算，用 `$PL_PROJECT`）

### R2. 输出路径泛化
```diff
- OUTPUT_DEFAULT="pipeline-output/piao/snapshots"
+ OUTPUT_DEFAULT="${PL_OUTPUT}/piao/snapshots"
```

### R3. 契约文档路径泛化（kernel-wordcheck 专项）
```diff
- SCAN_DIRS=("docs/piao-pipeline/kernel" ...)
+ SCAN_DIRS=("${PL_PIAO_DOCS:-${PL_ASSETS}/piao/docs}/kernel" ...)
```
（用户若想扫描自己项目的其他 md，可设 `PL_PIAO_DOCS=...` 覆盖）

### R4. 报错消息里的文档路径泛化
```diff
- echo "请阅读 docs/piao-pipeline/kernel/scenario-wordlist.md"
+ echo "请阅读 \${PL_ASSETS}/piao/docs/kernel/scenario-wordlist.md"
```

### R5. 改名（仅 kernel-wordcheck）
```
scripts/kernel-wordcheck.sh  ──▶  scripts/piao-kernel-wordcheck.sh
```
统一 `piao-*` 命名空间（CONTRIBUTING §一.脚本命名规则）。

### R6. 测试
每个脚本迁移后执行：
```bash
# 语法检查
bash -n scripts/piao-xxx.sh

# --help / --list 等无副作用参数能跑
bash scripts/piao-xxx.sh --help

# 在宿主目录下能产出与迁移前一致的结果
PL_PROJECT=/path/to/KuiklyPolyCity bash scripts/piao-xxx.sh [原参数]
```

---

## 五、迁移顺序（P1-2 子任务拆分）

按依赖深度和改造复杂度，建议顺序：

| 顺序 | 脚本 | 复杂度 | 单独 commit |
|---|---|---|---|
| 1 | `piao-kernel-wordcheck.sh` | 🟢 低 | `feat(piao): migrate kernel-wordcheck and rename to piao-kernel-wordcheck` |
| 2 | `piao-snapshot-produce.sh` | 🟡 中 | `feat(piao): migrate piao-snapshot-produce with _env.sh wiring` |
| 3 | `piao-snapshot-diff.sh` | 🟡 中 | `feat(piao): migrate piao-snapshot-diff with _env.sh wiring` |
| 4 | `piao-drift-compute.sh` | 🔴 高（875 行）| `feat(piao): migrate piao-drift-compute with _env.sh wiring` |
| 5 | `piao-evolution-scan.sh` | 🔴 高（500 行）| `feat(piao): migrate piao-evolution-scan with _env.sh wiring` |

每完成一个立即 commit，便于回滚定位。

---

## 六、与 docs 迁移的耦合关系

本次 `piao-*.sh` 脚本注释中引用的 `docs/piao-pipeline/kernel/*.md`
将在 **P1-3** 全量搬到 `assets/piao/docs/kernel/*.md`。迁移顺序：

```
P1-2（本任务）── 脚本迁移，注释里相对路径先用 $PL_ASSETS/piao/docs/ 占位
     │
P1-3 ── docs 迁移，路径真正生效
     │
P1-4 ── 提炼 schema（纯增量，不影响脚本）
     │
P1-5 ── THREE_LAYERS.md 解释三层关系
```

---

## 七、不迁移脚本的处置

`snapshot-generator.sh` 和 `state-generator.sh` 留宿主后，未来如需泛化：

| 方案 | 说明 |
|---|---|
| **方案 A（推荐 v0.2）** | 重写为 **`adapter-weex-to-kuikly`（社区 adapter）** 里的 `scripts/build-architecture-snapshot.sh` |
| **方案 B** | 如需在 adapter-sdk 中提供"snapshot 脚手架"通用能力，可在独立仓 `assets/adapter-sdk/template/scripts/snapshot-skeleton.sh.hbs` 提供骨架 |
| **方案 C** | 完全不做，这两个脚本就永远是 KuiklyPolyCity 的私产 |

此决策推迟到 v0.2，不影响本次 MVP。

---

## 八、P1-1 验收

- [x] 明确 7 个候选脚本的迁移决策
- [x] 证实 5 个待迁脚本彼此无 source 依赖
- [x] 列出 6 项改造清单（R1-R6）
- [x] 给出 P1-2 的 5 个子 commit 建议顺序
- [x] 明确 2 个排除脚本的未来处置方案

**P1-1 完成**。进入 P1-2。
