---
urn: urn:piao:rule:scenario_wordlist@v1
kind: rule
rev: v1
status: draft
produced_by: m1-review-2026-04-18
supersedes: null
---

# Kernel 场景词白名单（v0.1）

> 本文档是 `07-extensibility.md §9.1` 的 v0.1 交付物。
> 它规定了**哪些词不许出现在 kernel 层文档/代码里**。
> v0.1 仅作**写作自查清单**，v0.2 起会接入 `scripts/kernel-wordcheck.sh` 并 git hook 拦截。

---

## 1. 适用范围

### 1.1 受管控目录（命中即检查）

- `docs/piao-pipeline/00-overview.md`
- `docs/piao-pipeline/kernel/**`
- 未来的 `piao-kernel/**` 代码目录（若引入）

### 1.2 豁免目录（不检查）

- `docs/piao-pipeline/adapters/**`
- `docs/piao-pipeline/competitive/**`（对标研究本身就在谈其他产品）
- `docs/piao-pipeline/reference/**`（参考资料可原样引用）
- `openspec/**`、`.codebuddy/**`、`scripts/**`、各语言源码目录

---

## 2. 强禁用词（kernel 文档出现即违规）

这些词代表"场景实现"而非"原理契约"。任何一个出现在受管控目录的 markdown 文档里，都应该被改写成 kernel 通用表述。

| 禁用词 | 推荐改写 |
|--------|---------|
| `kuikly` | `adapter.<name>` / `某个 adapter` |
| `weex` | `legacy source` / `migration source adapter` |
| `vue` | `source framework` |
| `compose` | `UI DSL` / `declarative UI runtime` |
| `kotlin` | `host language` / `adapter implementation language` |
| `swift` / `objective-c` | `host language` |
| `android` / `ios` | `target platform` |
| `gradle` / `cocoapods` | `build tool` |
| `detekt` / `ktlint` / `swiftlint` | `static analyzer` |
| `tapd` | `task tracker` |
| `logcat` / `xcode console` | `runtime log source` |
| `adb` | `device bridge` |

**例外条款**：
- `07-extensibility.md §2` 的"已识别扩展点清单"允许列举 adapter 名字作为**已识别的扩展点**，不算违规。
- 文档引用 URN 时出现 `adapters/kuikly/...` 路径或 `adapter.kuikly:` 前缀是**路径/标识字符串**，不是场景词——允许。（URN 身份段本身不含 `kuikly` 字样：URN schema 见 `01-identity-model.md §1.1`）

## 3. 受限使用词（必须处于示例段落或 adapter 上下文）

这些词在 kernel 里可以作为"某 adapter 的专有概念"被引用，但必须显式归属：

| 受限词 | 允许形式 |
|-------|---------|
| `page` / `page_id` | **强禁用**——M1 review 已将 `page` kind 合并到 `unit`，kernel 文档统一用 `unit` / `unit_id`。仅在"迁移路径"或"历史追述"段落引用业务侧字段名时允许出现 |
| `card` | 仅作 adapter 的 task 类型示例 |
| `viewmodel` | 仅作 adapter 的 task 类型示例 |
| `migration` | 仅作 adapter 的 Task 类型示例（kernel 层应说 "rewrite task" 或 "transform task"） |
| `lint` | 允许（通用概念），但不得附加具体 linter 名字 |
| `logger` | 允许（通用概念），但不得附加具体日志组件名 |

## 4. kernel 允许的通用词（正向清单，供参考）

写 kernel 文档时**应该**使用的通用词：

- identity / URN / scope / rev / unit
- artifact / spec / acceptance / rule / task / taskdag / trace_event / snapshot / evolution_source / evolution_proposal
- kernel / adapter / extension_point
- provenance / lineage / integrity / shape
- event / emitter / consumer / journal / subject
- drift / re-evaluation / promotion
- quality_gate / acceptance_criteria / metric

## 5. 自查流程（v0.1 人工版）

写完一篇 kernel 文档后，建议搜一遍：

```bash
# macOS / Linux
cd docs/piao-pipeline/kernel
grep -nE -i '(kuikly|weex|vue|compose|kotlin|swift|android|ios|gradle|detekt|tapd|logcat|\bpage\b|page_id)' ./*.md
```

出现时对照本表改写。**允许的例外**（URN 字符串、§3 扩展点列举、示例代码块中的语言提示）要手工判断。

## 6. v0.2 升级路径

v0.2 将：

1. 把本词表转成 `scripts/kernel-wordcheck.sh` 的输入（jsonc 格式，明确"禁用 / 受限 / 豁免"）。
2. 在 git pre-commit hook 中对命中文件调用该脚本。
3. 违规 commit 被拒，返回行号 + 命中词 + 推荐改写。
4. 增加 "inline escape" 机制：允许用 `<!-- kernel-wordcheck: allow -->` 显式豁免某段落（用于引用/对比举例）。

---

**维护提醒**：
- 新增 adapter 立项时（`07-extensibility.md §7` 的第一个触发条件），需要把该 adapter 的场景词追加到 §2。
- 本文档修订时升 rev（从 v1 → v2），且 `scripts/kernel-wordcheck.sh`（v0.2 起）必须同步更新其嵌入的词表 hash。
