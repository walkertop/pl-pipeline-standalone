---
name: "PL: Status"
description: "查看所有 change 的 Pipeline 状态面板（或单个 change 详情）"
argument-hint: "[change-id]"
---

展示 pipeline 状态面板：

- **省略参数**：所有活跃 change 的总览
- **给 change-id**：单个 change 的详细状态（stage / gate / artifacts / task progress / open questions / self-check）

---

## 步骤

### 场景 A：全局面板（无参数）

#### A1. 优先调用编排器脚本（若存在）

```bash
if [ -x scripts/pl-orchestrator.sh ]; then
  ./scripts/pl-orchestrator.sh --status-all
  exit 0
fi
```

脚本缺失时走手动路径。

#### A2. 手动扫描 `pl/changes/*`

```bash
for dir in pl/changes/*/; do
  [ -f "$dir/.state.md" ] || continue
  # 解析 stage / gate / created_at / task-progress
done
```

输出格式：

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    PL Pipeline Status — All Changes                        │
├──────────────────────────────┬─────────┬──────────────┬────────┬──────────┤
│ Change                       │ Stage   │ Gate         │ Tasks  │ Updated  │
├──────────────────────────────┼─────────┼──────────────┼────────┼──────────┤
│ prop-confirm-migration       │ PLAN    │ B1-pending   │  0/16  │ 2d ago   │
│ refactor-prop-detail         │ IMPL    │ C-inprogress │  4/12  │ 3h ago   │
│ migrate-order-detail-page    │ VERIFY  │ E-pending    │ 18/18  │ 1h ago   │
│ weex-legacy-cleanup          │ ARCH.   │ G-passed     │  -     │ 1w ago   │
└──────────────────────────────┴─────────┴──────────────┴────────┴──────────┘

Active:   3     Archived: 1     Blocked: 0
Total Tasks: 22 done / 46 planned (48%)

💡 Tip: /pl:status <change-id> 查看详情
```

#### A3. 若存在 dashboard

附加一行：

```
Dashboard: pipeline-output/dashboard/index.html
执行 ./scripts/pl-dashboard-gen.sh 刷新。
```

---

### 场景 B：单 change 详情

`$ARGUMENTS = <change-id>` 时：

#### B1. 读 `.state.md` 全文

#### B2. 读 taskdag.md 做对齐统计

- 任务总数 / done / pending / blocked
- 按 Tier 分组

#### B3. 读 Self-Check Results 节（若存在）

#### B4. 读 Open Questions 节

输出：

```
## Change: <id>

**Stage:** <X> (entered <Xh ago>)
**Gate:** <Y> (<pending|passed|failed>)
**Version:** pl@v1.0
**Created:** <ISO>
**Updated:** <ISO>

### Artifacts
- [x] spec.md          (156 lines)
- [x] plan.md          (243 lines)
- [x] taskdag.md       (16 tasks, 14.0 person-days)
- [x] api.md           (7 endpoints)
- [x] testmatrix.md    (32 cases)
- [ ] deps.md          (missing)
- [x] .state.md

### Task Progress (4/16)
```
Tier 0:  [████████░░]  T01 ✓  T02 ✓  T03 ✓  T03b ✓
Tier 1:  [░░░░░░░░░░]  T04    T05    T05b   T06    T07
Tier 2:  [░░░░░░░░░░]  T08    T09
Tier 3:  [░░░░░░░░░░]  T10    T11    T11b
Tier 4:  [░░░░░░░░░░]  T12
Tier 5:  [░░░░░░░░░░]  T13
```

### Open Questions (2)
1. cfm JB2 支付是否保留 → 已解 (Plan v2.1 §B6)
2. RedCard V1/V2 版本判断删除后回归风险 → BLOCKING

### Self-Check Results
(not yet run — 执行 /pl:verify 生成)

### Next Actions
→ Resolve 1 BLOCKING question
→ Then /pl:implement 继续 T04
```

---

## Guardrails

- **只读**：本命令不修改任何文件
- **不调用** subagent / skill（纯展示）
- 若 `.state.md` 不存在或损坏 → 提醒用户用 `./scripts/pl-state-generator.sh --change <id>` 重建
- 若是 openspec 遗产 change（`openspec/changes/<id>`）而非 `pl/changes/<id>`：
  - 提醒 `scripts/pl-migrate-legacy.sh --change <id>` 迁移
  - 仍尽力解析老格式展示（`StructuredSpec.md` / `TaskDAG.md` 等）
- Task Progress 进度条用 ASCII 显示，不依赖终端颜色
- 单 change 详情不得超过 150 行（超出则折叠长段）
