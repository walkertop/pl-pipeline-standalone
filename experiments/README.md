# experiments/

> 这里放**未列入 ROADMAP、未承诺维护**的实验性代码。
> 主仓的 ROADMAP / 文档 / `bin/pl` 不会引用这些目录。

## 现状

| 目录 | 描述 | 状态 |
|------|------|------|
| `cli-nodejs/` | Node.js 实现的 `pl` CLI（v0.1.0，2026-04-23 起） | 🟡 实验中，**不推荐用户使用** |

## 为什么有这个目录？

主仓的 [ROADMAP.md](../ROADMAP.md) 明确写：

> **v0.2 不做的事**：❌ 不重写脚本为 TypeScript；CLI 是脚本的薄 wrapper

主线 CLI 路线是 `bin/pl`（bash 实现，v1.8.0+），它**完全满足**这条原则。
任何重写为 Node.js / Python / Go 的尝试只能放在 `experiments/`，并满足下面三条约束：

1. **不进入 `install.sh` / `pl new` / `bin/pl` 任何路径**
2. **不打 `pl-vX.Y.Z` 风格的 release tag**（避免 install.sh 的 latest-stable
   选择器把用户切到实验分支，详见 v1.10.0 之后的 install.sh 过滤逻辑）
3. **必须有自己的 README 说明"为什么实验、什么时候考虑提升、什么时候考虑删除"**

## 立项 → 提升 → 删除

实验性目录的三种归宿：

- **提升为正式分支**：必须先在 ROADMAP / `docs/milestones/` 立项 RFC，得到
  方向背书后才能搬出 `experiments/`，并且**主线代码必须先决定是替换还是并存**。
- **保持实验**：每隔 30 天 review 一次，没人维护 / 没人用就考虑删除。
- **删除**：删 commit + 删相关 tag。

---

## 历史教训：`pl-v2.0.0-alpha` 引发的安装链路事故

2026-04-23 起，根目录 `cli/` 用 Node.js 平行实现了一套 `pl` 命令，并在
2026-04-24 打了 `pl-v2.0.0-alpha` tag。这个 tag 挂在一个**没有 `bin/pl`**
的提交上（`fca3bb7`，只有 `cli/lib/*.js`），导致：

```
curl -fsSL https://.../install.sh | bash
  → 选 "latest stable tag"
  → git ls-remote --sort=-v:refname → pl-v2.0.0-alpha 排在 pl-v1.10.0 前
  → checkout 后报 "bin/pl 不可执行"
```

**修复链路**：
- `install.sh` 显式过滤 `-(alpha|beta|rc|pre|dev)` 后缀（commit `5a0297f`）
- `cli/` → `experiments/cli-nodejs/`（本次提交）
- `pl-v2.0.0-alpha` tag 从远端删除
- 后续若要继续这条 Node.js 路线，必须先发 RFC：
  `docs/milestones/v2.0-cli-rewrite-rfc.md`

教训写进 `assets/pl/agents/pipeline-master.md` 第 348+ 行的 "release/tag 纪律"
和 "distribution/install 纪律" 两节。
