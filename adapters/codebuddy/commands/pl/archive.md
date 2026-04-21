---
name: "PL: Archive"
description: "归档已验收的 change，沉淀知识到 Skills/Rules/架构快照（pl-pipeline v1）"
argument-hint: "[change-id]"
---

把 `stage=OBSERVE, gate=G-ready` 的 change 归档到 `pl/archive/YYYY-MM-DD-<id>/`，并完成资产沉淀 6 项检查：Skills / Rules / error-log / ARCHITECTURE_SNAPSHOT / TestMatrix / piao kernel-events。

---

## 输入

`$ARGUMENTS` = change-id；省略时列出所有 `stage ∈ {OBSERVE, VERIFY}` 的 change，用 AskUserQuestion 让用户选（**不要猜**）。

---

## 步骤

### 1. 评估 G 门禁

G 判据（`pl/config.yaml`）：

- [ ] **稳定运行 N 天**（默认 3 天，从 verify.passed 起算；.state.md 检查 `verified_at`）
- [ ] **组件目录已更新**（`ARCHITECTURE_SNAPSHOT.md` 中该 change 涉及的组件已登记）
- [ ] **知识沉淀完成**（见第 3 步 6 项检查）

若 G 未通过：

- 列出未通过项
- 用 AskUserQuestion：`补齐后归档` / `强制归档（带 warning）` / `取消`
- 强制归档时所有产物 header 打 `⚠ Archived with warnings`

### 2. Spec 完整性复核

对比 `pl/changes/<id>/spec.md` 的 Feature List 和实际实现：

- 每项 Feature 是否被至少 1 个 task 覆盖？
- TestMatrix 是否覆盖所有 P0 用例？

有遗漏时提醒用户确认是否归档。

### 3. 资产沉淀 6 项检查（核心飞轮）

#### 3.1 Skills 升级检查

扫描本 change 的编码经验，判断是否要沉淀：

- 某组件复用率 > 50% → 建议新增 / 扩展对应 skill
- 出现新的 Kuikly DSL 模式 → 扩展 `.codebuddy/skills/kuikly-ui-framework/`
- 某迁移 SOP 被重复使用 3 次以上 → 抽为新 skill

用 AskUserQuestion 让用户确认是否写入。

#### 3.2 Rules 升级检查

查是否出现了新的**强制约束**（命名 / 结构 / 禁止用法）：

- 若有，写入对应 rule（如 `.codebuddy/rules/migration-rules.md`）并标注"来自 change <id> YYYY-MM-DD"

#### 3.3 error-log 更新

扫描本次 VERIFY / OBSERVE 阶段的错误修复案例，将可复用的「错误→诊断→修复」三元组写入 `.codebuddy/rules/error-log.md`（若不存在则新建）。

#### 3.4 ARCHITECTURE_SNAPSHOT 更新

- 把新增的页面 / ViewModel / Component / Service 登记到 `ARCHITECTURE_SNAPSHOT.md`
- 更新 `ARCHITECTURE_SNAPSHOT.md.stats`（行数 / 文件数）

#### 3.5 TestMatrix 归档

把 `pl/changes/<id>/testmatrix.md` 合入项目主测试矩阵（`docs/migration/test-matrix.md` 或等价位置），打上标签 `#<change-id>`。

#### 3.6 piao kernel-events 发送

按 PIAO-001-SHA256 纪律，**现场**对核心产物算 sha256 并发事件：

```bash
./scripts/pl-trace-emit.sh \
  --change <id> --stage ARCHIVE --event artifact.registered \
  --emit-piao \
  --urn-prefix "urn:piao:artifact:pl:<id>" \
  --sha256-scan "pl/changes/<id>/*.md"
```

写入 `docs/piao-pipeline/kernel-events/YYYY-MM.jsonl`。

### 4. 物理归档

```bash
mkdir -p pl/archive
TARGET="pl/archive/$(date +%Y-%m-%d)-<id>"

# 检查目标是否已存在
if [ -d "$TARGET" ]; then
  echo "Archive target already exists: $TARGET"
  # 用 AskUserQuestion 选：重命名 / 覆盖 / 取消
fi

mv pl/changes/<id> "$TARGET"
```

### 5. 更新 `.state.md`

在归档目录内：

```markdown
- **stage**: ARCHIVED
- **gate**: G-passed
- **archived_at**: <ISO>
- **archive_location**: pl/archive/YYYY-MM-DD-<id>/

## Final Self-Check Summary
- Skills updated:   <N>
- Rules updated:    <M>
- error-log added:  <K>
- ARCHITECTURE_SNAPSHOT: updated
- TestMatrix merged: yes
- piao event emitted: yes (sha256=<...>)
```

### 6. 输出摘要

```
## Archive Complete

**Change:** <id>
**Stage:** OBSERVE → ARCHIVED
**Archived to:** pl/archive/YYYY-MM-DD-<id>/

**Knowledge Harvest:**
- Skills:            +1 (kuikly-xxx-xxx extended)
- Rules:             +2 (migration-rules.md, kotlin-serialization-rules.md)
- error-log:         +3 entries
- ARCHITECTURE_SNAPSHOT: +5 components, +3 services
- TestMatrix:        27 cases merged

**piao Event:**
- urn: urn:piao:artifact:pl:<id>/spec.md@v1.0
- sha256: <hash>
- event_file: docs/piao-pipeline/kernel-events/2026-04.jsonl

**Next Cycle:**
→ 下一次迁移启动 `/pl:proposal`，将自动复用本次沉淀的 Skills/Rules
```

---

## Guardrails

- **不允许**跳过资产沉淀 6 项检查（这是飞轮核心）
- **必须现场算 sha256**（PIAO-001-SHA256 纪律）
- **不允许**归档带 BLOCKING Open Questions 的 change（必须先 resolve 或转成 deferred）
- 若 G 门禁未通过而强制归档，必须在 .state.md 和 piao 事件中打 `warnings` 标签
- **不要**直接删除原目录，用 `mv` 到 archive
- 对 openspec 遗产 change（`openspec/changes/<id>/` 而非 `pl/changes/<id>/`）：先提醒用户走 `scripts/pl-migrate-legacy.sh --change <id>` 迁移路径再归档
- 归档后 change-id 不可复用（防误覆盖）

---

## 与 `.codebuddy/commands/openspec/archive.md` 的差异

- 本命令**不依赖** `openspec` CLI
- 额外做 6 项资产沉淀（原 archive 只 mv）
- 额外发 piao kernel-event
- 门禁由 `pl/config.yaml` 驱动
