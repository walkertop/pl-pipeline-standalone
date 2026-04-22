# Evidence: v1.3 observe 层全生命周期演示

2026-04-22 Day 2 下午产出。验证 v1.3 新增的 **pl-observe 纯观察者架构**
能端到端地抓到"LLM 编码的全链路状态"。

## 文件

- `demo-nextjs-todo-observe.jsonl` — 对 demo-nextjs-todo 跑完整三阶段的 trace

## 事件统计（52 events）

```
  29 artifact.created    ← 首次扫描建 baseline
   2 artifact.modified   ← 两次 stage 变化触发
   8 asset.promoted      ← 4 rule + 4 skill（新增到 .codebuddy/）
  11 plan.task.added     ← taskdag 里 T01~T11
   2 state.transition    ← SPEC→PLAN, PLAN→IMPLEMENT
```

## 验证场景

### 场景 1 · 首次进入项目（建 baseline）
```bash
PL_PROJECT=$PWD/examples/demo-nextjs-todo \
bash scripts/pl-observe.sh --change add-todo-list --phase SPEC
```
**产出**：29 条 artifact.created + 规则推断 19 条业务事件。

### 场景 2 · SPEC → PLAN（人/agent 改 .state.md 的 stage）
```bash
sed -i.bak 's/^- stage: SPEC$/- stage: PLAN/' .state.md
bash scripts/pl-observe.sh --change add-todo-list --phase PLAN
```
**产出**：
- 1 条 artifact.modified
- 1 条 **state.transition**（from_stage:SPEC → to_stage:PLAN）

### 场景 3 · PLAN → IMPLEMENT
同上，再推断出 1 条 state.transition。

## 重要设计验证

### ✅ 规则是事后应用（重放友好）
`observe-apply-rules.py` 读 events.jsonl 里的 artifact.* 事件做语义升级。
这意味着**改规则后可以重放历史 git commit** 再生成一次 events（MCP 做不到的）。

### ✅ 零依赖
无 fswatch / inotify / PyYAML，纯 Python stdlib。macOS 默认就能跑。

### ✅ 内容寻址缓存
`pipeline-output/observe/content-cache/<sha256>.txt` 存文件历史版本。
只对 ≤ 256KB 文本文件缓存，自动跳过二进制。

### ✅ 幂等
重复跑 `pl-observe.sh` 不会重复产事件（按 `trace_id + path + event + sig` 去重）。

## 规则命中示例

### Rule: taskdag-row-added
```jsonl
{"event":"plan.task.added",
 "data":{"task_id":"T04",
         "task_name":"Server Action `createTodo` + Zod 校验",
         "source_path":"pl/changes/add-todo-list/taskdag.md",
         "inferred_by":"taskdag-row-added"}}
```

### Rule: state-stage-transition
```jsonl
{"event":"state.transition",
 "data":{"from_stage":"SPEC", "to_stage":"PLAN",
         "source_path":"pl/changes/add-todo-list/.state.md",
         "inferred_by":"state-stage-transition"}}
```

### Rule: rule-asset-promoted
```jsonl
{"event":"asset.promoted",
 "data":{"kind":"rule",
         "target_path":".codebuddy/rules/nextjs-revalidate-for-non-fetch.md",
         "inferred_by":"rule-asset-promoted"}}
```

## 和 v1.2 evidence 的对比

v1.2 的 trace 只覆盖 IMPLEMENT / SMOKE / OBSERVE 三阶段共 8 events。
v1.3 的 trace **覆盖 SPEC 到 ARCHIVE 全生命周期** —— 本次 demo 里用模拟演示
了 SPEC→PLAN→IMPLEMENT 部分，52 events 密度是 v1.2 的 6 倍。

下一步（Day 3）：把这些事件画成可视化面板。
