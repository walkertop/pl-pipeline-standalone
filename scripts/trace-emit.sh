#!/usr/bin/env bash
# =============================================================================
# trace-emit.sh — Pipeline Trace 事件写入库
# =============================================================================
#
# 统一的事件写入接口。所有脚本通过 source 本文件后获得 trace_emit 系列函数，
# 将可观测事件追加写入 pipeline-output/trace/{page_id}.events.jsonl (JSON Lines 格式)。
#
# 用法:
#   source "$(dirname "$0")/trace-emit.sh"
#   trace_init "order_detail" "VERIFY" "script:migration-verify"
#   trace_emit "check.run" '{"checker":"lint","status":"pass"}'
#
# Event 类型枚举:
#   phase.start / phase.end   — Pipeline 阶段开始/结束
#   gate.eval                 — 门控评估
#   task.start / task.end     — TaskDAG 中某个 Task 开始/结束
#   artifact.create / update  — 产物创建/更新
#   check.run                 — 检查项执行结果
#   runtime.log               — 运行时日志 (MigrationLogger 产出)
#   error                     — 错误事件
#   hook.trigger              — Hook 触发 (预留)
#   workflow.start / end      — 工作流整体开始/结束
#
# =============================================================================

# 防止重复 source
[[ -n "${_TRACE_EMIT_LOADED:-}" ]] && return 0
_TRACE_EMIT_LOADED=1

# ---- 目录和路径 ---------------------------------------------------------------

TRACE_PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TRACE_DIR="${TRACE_DIR:-$TRACE_PROJECT_ROOT/build/trace}"
mkdir -p "$TRACE_DIR"

# ---- 全局 Trace 上下文 --------------------------------------------------------

TRACE_ID=""
TRACE_PAGE=""
TRACE_PHASE=""
TRACE_ACTOR=""

# ---- 核心函数 -----------------------------------------------------------------

# trace_init: 初始化 trace 上下文
# 用法: trace_init <page_id> [phase] [actor]
trace_init() {
  TRACE_PAGE="${1:?trace_init requires page_id}"
  TRACE_ID="${TRACE_PAGE}_$(date +%Y%m%d_%H%M%S)"
  TRACE_PHASE="${2:-}"
  TRACE_ACTOR="${3:-}"
  export TRACE_ID TRACE_PAGE TRACE_PHASE TRACE_ACTOR
}

# trace_emit: 写入一条事件到 JSONL
# 用法: trace_emit <event_type> [json_data]
# 事件会追加写入 pipeline-output/trace/{TRACE_PAGE}.events.jsonl
trace_emit() {
  local event_type="${1:?trace_emit requires event_type}"
  local data="${2:-"{}"}"

  # 如果 data 为空或空白，默认为空对象
  [[ -z "${data// /}" ]] && data='{"_":"_"}'

  # 验证 data 是合法 JSON，如果不是则包装为 message
  if ! echo "$data" | jq empty 2>/dev/null; then
    data=$(jq -cn --arg m "$data" '{message:$m}')
  fi

  local ts
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

  local target_file="${TRACE_DIR}/${TRACE_PAGE}.events.jsonl"

  # 使用 jq -n 构建完整 JSON，通过 input 读取 data 避免 --argjson 的 shell 问题
  echo "$data" | jq -cn \
    --arg ts "$ts" \
    --arg tid "$TRACE_ID" \
    --arg phase "$TRACE_PHASE" \
    --arg actor "$TRACE_ACTOR" \
    --arg event "$event_type" \
    '{ts:$ts, trace_id:$tid, phase:$phase, actor:$actor, event:$event, data: input}' \
    >> "$target_file"
}

# ---- 便捷函数 -----------------------------------------------------------------

# 内部辅助：安全构建合并 JSON（处理空对象 {} 的 shell glob 问题）
_jq_merge() {
  # 用法: _jq_merge '{"key":"val"}' '{"extra":"data"}'
  # 将两个 JSON 对象合并
  local base="$1"
  local extra="$2"
  if [[ "$extra" == "{}" || -z "$extra" ]]; then
    echo "$base"
  else
    echo "$base $extra" | jq -cs '.[0] + .[1]'
  fi
}

# trace_phase_start: 标记阶段开始
# 用法: trace_phase_start <phase_name> [actor]
trace_phase_start() {
  TRACE_PHASE="${1:?trace_phase_start requires phase_name}"
  TRACE_ACTOR="${2:-orchestrator}"
  trace_emit "phase.start" '{"phase_name":"'"$TRACE_PHASE"'"}'
}

# trace_phase_end: 标记阶段结束
# 用法: trace_phase_end <status> [extra_json]
# status: pass | fail | warn | blocked | skip | awaiting_agent
trace_phase_end() {
  local status="${1:?trace_phase_end requires status}"
  local extra="${2:-}"
  local base
  base=$(jq -cn --arg s "$status" '{status:$s}')
  trace_emit "phase.end" "$(_jq_merge "$base" "$extra")"
}

# trace_gate: 记录门控评估
# 用法: trace_gate <gate_name> <expression> <result>
trace_gate() {
  local gate_name="${1:?}"
  local expr="${2:?}"
  local result="${3:?}"
  trace_emit "gate.eval" "$(jq -cn \
    --arg g "$gate_name" \
    --arg e "$expr" \
    --arg r "$result" \
    '{gate:$g, expr:$e, result:$r}')"
}

# trace_task: 记录任务状态变更
# 用法: trace_task <start|end> <task_id> [extra_json]
trace_task() {
  local action="${1:?}"  # start | end
  local task_id="${2:?}"
  local extra="${3:-}"
  local base
  base=$(jq -cn --arg t "$task_id" '{task_id:$t}')
  trace_emit "task.${action}" "$(_jq_merge "$base" "$extra")"
}

# trace_artifact: 记录产物创建/更新
# 用法: trace_artifact <create|update> <path> [extra_json]
trace_artifact() {
  local action="${1:?}"
  local artifact_path="${2:?}"
  local extra="${3:-}"
  local base
  base=$(jq -cn --arg p "$artifact_path" '{path:$p}')
  trace_emit "artifact.${action}" "$(_jq_merge "$base" "$extra")"
}

# trace_check: 记录检查项结果
# 用法: trace_check <checker_name> <status> [extra_json]
trace_check() {
  local checker="${1:?}"
  local status="${2:?}"
  local extra="${3:-}"
  local base
  base=$(jq -cn --arg c "$checker" --arg s "$status" '{checker:$c, status:$s}')
  trace_emit "check.run" "$(_jq_merge "$base" "$extra")"
}

# trace_error: 记录错误
# 用法: trace_error <message> [extra_json]
trace_error() {
  local message="${1:?}"
  local extra="${2:-}"
  local base
  base=$(jq -cn --arg m "$message" '{message:$m}')
  trace_emit "error" "$(_jq_merge "$base" "$extra")"
}

# trace_runtime_log: 记录运行时日志 (MigrationLogger bridge)
# 用法: trace_runtime_log <domain> <level> <message>
trace_runtime_log() {
  local domain="${1:?}"
  local level="${2:?}"
  local msg="${3:?}"
  trace_emit "runtime.log" "$(jq -cn \
    --arg d "$domain" \
    --arg l "$level" \
    --arg m "$msg" \
    '{domain:$d, level:$l, msg:$m}')"
}

# ---- 工具函数 -----------------------------------------------------------------

# trace_file: 返回当前 trace 的事件文件路径
trace_file() {
  echo "${TRACE_DIR}/${TRACE_PAGE}.events.jsonl"
}

# trace_count: 统计当前 trace 的事件数量
trace_count() {
  local f
  f=$(trace_file)
  [[ -f "$f" ]] && wc -l < "$f" | tr -d ' ' || echo "0"
}

# trace_tail: 输出最近 N 条事件 (默认 5)
trace_tail() {
  local n="${1:-5}"
  local f
  f=$(trace_file)
  [[ -f "$f" ]] && tail -n "$n" "$f" | jq -c '.' || echo "No events"
}

# trace_summary: 输出当前 trace 的摘要
trace_summary() {
  local f
  f=$(trace_file)
  if [[ ! -f "$f" ]]; then
    echo "No trace events found"
    return
  fi
  echo "Trace: $TRACE_ID"
  echo "Page:  $TRACE_PAGE"
  echo "File:  $f"
  echo "Events: $(trace_count)"
  echo ""
  echo "Phase summary:"
  jq -r 'select(.event == "phase.end") | "  \(.phase): \(.data.status)"' "$f" 2>/dev/null || echo "  (no phase completions)"
}
