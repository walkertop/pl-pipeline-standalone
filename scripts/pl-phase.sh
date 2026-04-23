#!/usr/bin/env bash
# =============================================================================
# pl-phase.sh — 手动推进阶段 + 自动写 trace 事件 + 自动更新 .state.md
# =============================================================================
#
# 解决的问题：
#   手动走阶段时如果不经过 orchestrator，观测层就被绕过。
#   本脚本让"手动走阶段"也能产出完整的 trace 事件和 .state.md 更新。
#
# 用法：
#   pl-phase.sh <change-id> start <PHASE>          # 标记阶段开始
#   pl-phase.sh <change-id> end <PHASE> <RESULT>   # 标记阶段结束 (pass|fail|warn|skip)
#   pl-phase.sh <change-id> gate <GATE> <RESULT>   # 标记门禁评估
#   pl-phase.sh <change-id> task <start|end> <TASK_ID> [result]  # 标记任务
#   pl-phase.sh <change-id> check <CHECKER> <RESULT> [detail]    # 标记检查项
#   pl-phase.sh <change-id> artifact <create|update> <PATH>      # 标记产物
#   pl-phase.sh <change-id> done                   # 标记 workflow 结束
#   pl-phase.sh <change-id> status                 # 查看 trace 摘要
#
# 每条命令都会：
#   1. 写入 pipeline-output/trace/<change-id>.events.jsonl
#   2. 更新 pl/changes/<change-id>/.state.md 的 History 节
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PL_HOME="${PL_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# ── 参数 ──────────────────────────────────────────────────────
CHANGE_ID="${1:?Usage: pl-phase.sh <change-id> <command> ...}"
ACTION="${2:?Usage: pl-phase.sh <change-id> <command> ...}"
shift 2

PROJECT_ROOT="$PWD"
CHANGE_DIR="$PROJECT_ROOT/pl/changes/$CHANGE_ID"
STATE_FILE="$CHANGE_DIR/.state.md"
TRACE_DIR="$PROJECT_ROOT/pipeline-output/trace"
TRACE_FILE="$TRACE_DIR/${CHANGE_ID}.events.jsonl"
NOW=$(date '+%Y-%m-%d %H:%M')
NOW_UTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
TRACE_TID="${CHANGE_ID}_$(date +%Y%m%d_%H%M%S)"

# ── 前置检查 ──────────────────────────────────────────────────
if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ $STATE_FILE 不存在。请先运行: pl-state-init.sh $CHANGE_ID"
  exit 1
fi

mkdir -p "$TRACE_DIR"

# ── trace 写入函数（不 source trace-emit.sh，避免 shell 兼容问题）──
_trace_write() {
  local event="$1"
  local phase="$2"
  local data="$3"
  echo "$data" | jq -cn \
    --arg ts "$NOW_UTC" \
    --arg tid "$TRACE_TID" \
    --arg phase "$phase" \
    --arg actor "pl-phase.sh" \
    --arg event "$event" \
    '{ts:$ts, trace_id:$tid, phase:$phase, actor:$actor, event:$event, data:input}' \
    >> "$TRACE_FILE"
}

# ── .state.md History 追加 ────────────────────────────────────
_append_history() {
  local msg="$1"
  # 在 History 表格的最后一行（即 `|` 开头的最后一行之后）追加
  if grep -q "^## History" "$STATE_FILE"; then
    echo "| $NOW | pl-phase.sh | $msg |" >> "$STATE_FILE"
  fi
}

# ── .state.md 更新 stage 字段 ─────────────────────────────────
_update_stage() {
  local new_stage="$1"
  local old_stage
  old_stage=$(grep '^\- stage:' "$STATE_FILE" | head -1 | sed 's/- stage: //')
  sed -i '' "s/^- stage: .*$/- stage: $new_stage/" "$STATE_FILE"
  sed -i '' "s/^- last_transition: .*$/- last_transition: \"$old_stage → $new_stage at $NOW\"/" "$STATE_FILE"
  sed -i '' "s/^<!-- 最后更新: .*$/<!-- 最后更新: $NOW by pl-phase.sh -->/" "$STATE_FILE"
}

# ── 命令分发 ──────────────────────────────────────────────────
case "$ACTION" in
  start)
    PHASE="${1:?Usage: pl-phase.sh <id> start <PHASE>}"
    _update_stage "$PHASE"
    _trace_write "phase.start" "$PHASE" "{\"phase_name\":\"$PHASE\"}"
    _append_history "→ $PHASE | 阶段开始"
    echo "✅ $CHANGE_ID: phase $PHASE started (trace + state updated)"
    ;;

  end)
    PHASE="${1:?Usage: pl-phase.sh <id> end <PHASE> <RESULT>}"
    RESULT="${2:?Usage: pl-phase.sh <id> end <PHASE> <pass|fail|warn|skip>}"
    _trace_write "phase.end" "$PHASE" "{\"status\":\"$RESULT\"}"
    if [[ "$RESULT" == "pass" ]]; then
      sed -i '' "s/^- gate_status: .*$/- gate_status: PASSED/" "$STATE_FILE"
    elif [[ "$RESULT" == "fail" ]]; then
      sed -i '' "s/^- gate_status: .*$/- gate_status: BLOCKED/" "$STATE_FILE"
    fi
    _append_history "$PHASE end | 结果: $RESULT"
    echo "✅ $CHANGE_ID: phase $PHASE ended ($RESULT)"
    ;;

  gate)
    GATE="${1:?Usage: pl-phase.sh <id> gate <GATE> <RESULT>}"
    RESULT="${2:?Usage: pl-phase.sh <id> gate <GATE> <pass|fail>}"
    # 读取当前 phase
    CURRENT_PHASE=$(grep '^\- stage:' "$STATE_FILE" | head -1 | sed 's/- stage: //')
    _trace_write "gate.eval" "$CURRENT_PHASE" "{\"gate\":\"$GATE\",\"result\":\"$RESULT\"}"
    _append_history "gate $GATE | 结果: $RESULT"
    echo "✅ $CHANGE_ID: gate $GATE → $RESULT"
    ;;

  task)
    TASK_ACTION="${1:?Usage: pl-phase.sh <id> task <start|end> <TASK_ID>}"
    TASK_ID="${2:?}"
    TASK_RESULT="${3:-pass}"
    CURRENT_PHASE=$(grep '^\- stage:' "$STATE_FILE" | head -1 | sed 's/- stage: //')
    _trace_write "task.${TASK_ACTION}" "$CURRENT_PHASE" "{\"task_id\":\"$TASK_ID\",\"result\":\"$TASK_RESULT\"}"
    if [[ "$TASK_ACTION" == "end" ]]; then
      # 更新 Task Progress 里的状态
      sed -i '' "s/| $TASK_ID |.*|.*| ⬜ TODO |/| $TASK_ID | | | ✅ DONE | $NOW |/" "$STATE_FILE" 2>/dev/null || true
      _append_history "— | $TASK_ID $TASK_ACTION ($TASK_RESULT)"
    else
      _append_history "— | $TASK_ID $TASK_ACTION"
    fi
    echo "✅ $CHANGE_ID: task $TASK_ID $TASK_ACTION"
    ;;

  check)
    CHECKER="${1:?Usage: pl-phase.sh <id> check <CHECKER> <RESULT>}"
    RESULT="${2:?}"
    DETAIL="${3:-}"
    CURRENT_PHASE=$(grep '^\- stage:' "$STATE_FILE" | head -1 | sed 's/- stage: //')
    local_data="{\"checker\":\"$CHECKER\",\"status\":\"$RESULT\"}"
    [[ -n "$DETAIL" ]] && local_data="{\"checker\":\"$CHECKER\",\"status\":\"$RESULT\",\"detail\":\"$DETAIL\"}"
    _trace_write "check.run" "$CURRENT_PHASE" "$local_data"
    _append_history "— | check $CHECKER → $RESULT"
    echo "✅ $CHANGE_ID: check $CHECKER → $RESULT"
    ;;

  artifact)
    ART_ACTION="${1:?Usage: pl-phase.sh <id> artifact <create|update> <PATH>}"
    ART_PATH="${2:?}"
    CURRENT_PHASE=$(grep '^\- stage:' "$STATE_FILE" | head -1 | sed 's/- stage: //')
    _trace_write "artifact.${ART_ACTION}" "$CURRENT_PHASE" "{\"path\":\"$ART_PATH\"}"
    echo "✅ $CHANGE_ID: artifact $ART_ACTION $ART_PATH"
    ;;

  done)
    _trace_write "workflow.end" "ARCHIVE" "{\"change_id\":\"$CHANGE_ID\",\"status\":\"completed\"}"
    _update_stage "ARCHIVE"
    sed -i '' "s/^- gate_status: .*$/- gate_status: PASSED/" "$STATE_FILE"
    sed -i '' "s/^- next_gate: .*$/- next_gate: none/" "$STATE_FILE"
    _append_history "→ ARCHIVE | workflow 完成"
    echo "✅ $CHANGE_ID: workflow completed"
    ;;

  status)
    echo "📊 Trace summary for $CHANGE_ID:"
    if [[ -f "$TRACE_FILE" ]]; then
      echo "   Events: $(wc -l < "$TRACE_FILE" | tr -d ' ')"
      echo "   File:   $TRACE_FILE"
      echo ""
      echo "   Phase results:"
      jq -r 'select(.event == "phase.end") | "     \(.phase): \(.data.status)"' "$TRACE_FILE" 2>/dev/null || echo "     (no phase completions)"
      echo ""
      echo "   Gate results:"
      jq -r 'select(.event == "gate.eval") | "     \(.data.gate): \(.data.result)"' "$TRACE_FILE" 2>/dev/null || echo "     (no gates)"
    else
      echo "   ❌ No trace file found"
    fi
    echo ""
    echo "📄 State: $(grep '^\- stage:' "$STATE_FILE" | head -1)"
    ;;

  *)
    echo "❌ Unknown action: $ACTION"
    echo "Available: start, end, gate, task, check, artifact, done, status"
    exit 1
    ;;
esac
