#!/usr/bin/env bash
# =============================================================================
# pl-state-init.sh — 创建 change 时生成完整 .state.md + 初始 trace 事件
# =============================================================================
#
# 解决的问题：
#   手动走阶段时观测层被完全绕过（无 .state.md 骨架、无 trace 事件）。
#   本脚本确保 change 从第一秒起就有完整的观测数据。
#
# 用法：
#   pl-state-init.sh <change-id> [--name "变更名"] [--domain "业务域"] [--complexity low|medium|high]
#
# 产出：
#   1. pl/changes/<change-id>/.state.md   ← 完整骨架（10 章节）
#   2. pipeline-output/trace/<change-id>.events.jsonl ← workflow.start 初始事件
#
# 前置：
#   - $PL_HOME 已设置（或脚本自探测）
#   - 当前目录是项目根
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PL_HOME="${PL_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# ── 参数解析 ──────────────────────────────────────────────────
CHANGE_ID=""
CHANGE_NAME=""
DOMAIN="通用"
COMPLEXITY="🟡中"

usage() {
  echo "Usage: pl-state-init.sh <change-id> [options]"
  echo "  --name <name>           变更中文名"
  echo "  --domain <domain>       业务域"
  echo "  --complexity <l|m|h>    复杂度 (low/medium/high)"
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)       CHANGE_NAME="$2"; shift 2 ;;
    --domain)     DOMAIN="$2"; shift 2 ;;
    --complexity)
      case "$2" in
        low|l)    COMPLEXITY="🟢低" ;;
        medium|m) COMPLEXITY="🟡中" ;;
        high|h)   COMPLEXITY="🔴高" ;;
        *)        COMPLEXITY="$2" ;;
      esac
      shift 2 ;;
    --help|-h)    usage ;;
    -*)           echo "unknown option: $1"; usage ;;
    *)            CHANGE_ID="$1"; shift ;;
  esac
done

[[ -z "$CHANGE_ID" ]] && { echo "❌ change-id is required"; usage; }
[[ -z "$CHANGE_NAME" ]] && CHANGE_NAME="$CHANGE_ID"

PROJECT_ROOT="$PWD"
CHANGE_DIR="$PROJECT_ROOT/pl/changes/$CHANGE_ID"
STATE_FILE="$CHANGE_DIR/.state.md"
TRACE_DIR="$PROJECT_ROOT/pipeline-output/trace"
TRACE_FILE="$TRACE_DIR/${CHANGE_ID}.events.jsonl"

NOW=$(date '+%Y-%m-%d %H:%M')

# ── 检查 ──────────────────────────────────────────────────────
if [[ ! -d "$PROJECT_ROOT/pl" ]]; then
  echo "❌ pl/ 目录不存在，请先初始化 pl-pipeline"
  exit 1
fi

if [[ -f "$STATE_FILE" ]]; then
  echo "⚠️  $STATE_FILE 已存在，跳过（使用 --force 覆盖）"
  exit 0
fi

# ── 生成 .state.md ────────────────────────────────────────────
mkdir -p "$CHANGE_DIR"

cat > "$STATE_FILE" << EOF
# ${CHANGE_ID}.state.md
<!-- 生成时间: $NOW -->
<!-- 最后更新: $NOW by pl-state-init.sh -->
<!-- pl_version: pl@v1.1 -->

## Pipeline State
- stage: SPEC
- gate_status: IN_PROGRESS
- blocked_reason: ""
- last_transition: "→ SPEC at $NOW"
- next_gate: A0

## Change Meta
- change_id: $CHANGE_ID
- change_name: $CHANGE_NAME
- business_domain: $DOMAIN
- complexity: $COMPLEXITY
- spec_ref: pl/changes/$CHANGE_ID/spec.md
- plan_ref: pl/changes/$CHANGE_ID/plan.md
- taskdag_ref: pl/changes/$CHANGE_ID/taskdag.md
- api_ref: N/A
- testmatrix_ref: N/A
- deps_ref: N/A

## Artifacts（产物清单）

### 页面入口
- page_entry: \`<待填>\`

### 数据层
- models: N/A
- modules: N/A
- data_store: N/A
- viewmodels: N/A

### 组件层
- new_components: []
- reused_components: []

### Mock & 测试
- mock_files: N/A
- trace_contract: N/A

## Component Reuse（组件复用分析）

| 组件 | 来源层 | 复用方式 | 状态 |
|------|--------|---------|------|

- reuse_rate: 0/0 = N/A
- candidates_for_promotion: []

## Self-Check Results（自检结果）

| 层 | 状态 | 详情 |
|----|------|------|
| 静态检查 (lint) | ⬜ PENDING | — |
| 编译 (compile) | ⬜ PENDING | — |
| 构建 (build) | ⬜ PENDING | — |
| 网络层 (network) | ⬜ PENDING | — |
| 解析层 (parse) | ⬜ PENDING | — |
| 渲染层 (render) | ⬜ PENDING | — |
| 埋点 (tracking) | ⬜ PENDING | — |

## Task Progress（任务进度，同步自 taskdag.md）

| Task ID | 任务名 | 依赖 | 状态 | 完成时间 |
|---------|--------|------|------|---------|

- total_tasks: 0
- done_tasks: 0
- blocked_tasks: 0

## Open Questions（待确认项）

| ID | 问题 | 等级 | 状态 | 结论 |
|----|------|------|------|------|

## History（变更历史）

| 时间 | 操作者 | 阶段变更 | 说明 |
|------|--------|---------|------|
| $NOW | pl-state-init.sh | → SPEC | 创建 change，初始化 .state.md |
EOF

echo "✅ 已生成 $STATE_FILE"

# ── 生成初始 trace 事件 ───────────────────────────────────────
mkdir -p "$TRACE_DIR"

# 直接用 jq 写入 workflow.start 事件（不依赖 source trace-emit.sh 避免 shell 兼容问题）
jq -cn \
  --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg tid "${CHANGE_ID}_$(date +%Y%m%d_%H%M%S)" \
  --arg phase "SPEC" \
  --arg actor "pl-state-init.sh" \
  --arg event "workflow.start" \
  --arg cid "$CHANGE_ID" \
  --arg name "$CHANGE_NAME" \
  '{ts:$ts, trace_id:$tid, phase:$phase, actor:$actor, event:$event, data:{change_id:$cid, name:$name}}' \
  >> "$TRACE_FILE"

jq -cn \
  --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg tid "${CHANGE_ID}_$(date +%Y%m%d_%H%M%S)" \
  --arg phase "SPEC" \
  --arg actor "pl-state-init.sh" \
  --arg event "phase.start" \
  '{ts:$ts, trace_id:$tid, phase:$phase, actor:$actor, event:$event, data:{phase_name:"SPEC"}}' \
  >> "$TRACE_FILE"

echo "✅ 已写入初始 trace: $TRACE_FILE (2 events)"

# ── 总结 ──────────────────────────────────────────────────────
echo ""
echo "📋 Change '$CHANGE_ID' 已初始化:"
echo "   .state.md  → $STATE_FILE"
echo "   trace      → $TRACE_FILE"
echo ""
echo "下一步："
echo "   1. 写 spec:  pl/changes/$CHANGE_ID/spec.md"
echo "   2. 推进阶段: pl-phase.sh $CHANGE_ID advance PLAN"
echo "   3. 查看状态: pl-status.sh --project ."
