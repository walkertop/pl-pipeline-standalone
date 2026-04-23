#!/usr/bin/env bash
# =============================================================================
# trace-emit.sh — Pipeline Trace 事件写入库
# =============================================================================
#
# 统一的事件写入接口。所有脚本通过 source 本文件后获得 trace_emit 系列函数，
# 将可观测事件追加写入 $PL_OUTPUT/trace/{page_id}.events.jsonl (JSON Lines)。
#
# 前置：调用方必须先 source _env.sh（会导出 $PL_OUTPUT）
#
# 用法:
#   source "$(dirname "$0")/_env.sh"
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
#   adapter.use               — Consumer→Adapter 能力消费证据（v1.6+，观测用）
#   error                     — 错误事件
#   hook.trigger              — Hook 触发 (预留)
#   workflow.start / end      — 工作流整体开始/结束
#
# =============================================================================

# 防止重复 source
[[ -n "${_TRACE_EMIT_LOADED:-}" ]] && return 0
_TRACE_EMIT_LOADED=1

# ---- 目录和路径 ---------------------------------------------------------------
# 优先级：$TRACE_DIR 显式覆盖 > $PL_OUTPUT/trace (_env.sh 提供) > 自探测兜底
# 兜底路径仅在 _env.sh 未被 source 时使用（保持向后兼容）

if [[ -n "${TRACE_DIR:-}" ]]; then
  : # 调用方显式指定，优先使用
elif [[ -n "${PL_OUTPUT:-}" ]]; then
  TRACE_DIR="$PL_OUTPUT/trace"
else
  # 兜底：_env.sh 未 source 时取脚本父目录的 pipeline-output/trace
  _trace_fallback_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  TRACE_DIR="$_trace_fallback_root/pipeline-output/trace"
  unset _trace_fallback_root
fi
mkdir -p "$TRACE_DIR"

# ---- 全局 Trace 上下文 --------------------------------------------------------

TRACE_ID=""
TRACE_PAGE=""        # 等同于 change_id（不再单独造 session_id 字段，trace_id 已含 change_id）
TRACE_PHASE=""
TRACE_ACTOR=""

# ---- Span 栈（v1.6.1+，结构化 WHERE） ---------------------------------------
# 用 bash 数组作为运行时 span 栈：每次 phase/gate/task 开始就 push，结束就 pop。
# 中间发出的所有 point 事件（check.run / artifact.* / adapter.use 等）会
# 自动从栈顶继承 parent_span_id。这样 jsonl 自包含、事后可拼成因果树。
# 注意：用 plain 赋值（不用 declare -g）以兼容 macOS 自带的 bash 3.2。
_SPAN_STACK=()

_span_new_id() {
  # 生成短 span id：sp_<纳秒后段>_<rand>
  local ns
  if date +%N 2>/dev/null | grep -qE '^[0-9]+$'; then
    ns=$(date +%N 2>/dev/null | tail -c 7)
  else
    ns=$(printf '%06d' "$RANDOM")
  fi
  echo "sp_${ns}_$(printf '%04x' $RANDOM)"
}

_span_push() {
  _SPAN_STACK+=("$1")
}

_span_pop() {
  local n=${#_SPAN_STACK[@]}
  if (( n > 1 )); then
    unset '_SPAN_STACK[n-1]'
    # 重建数组以确保索引连续；用 :- 防 set -u 在空数组情况下报错
    _SPAN_STACK=("${_SPAN_STACK[@]:-}")
  elif (( n == 1 )); then
    _SPAN_STACK=()
  fi
}

_span_top() {
  local n=${#_SPAN_STACK[@]}
  if (( n > 0 )); then
    echo "${_SPAN_STACK[n-1]}"
  else
    echo ""
  fi
}

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
# 用法: trace_emit <event_type> [json_data] [span_id]
#   span_id 仅 span 开/关事件需要传（由 trace_phase_start / trace_gate_start 等辅助函数管理）
#   point 事件不传 span_id，自动从栈顶继承为 parent_span_id
# 事件会追加写入 pipeline-output/trace/{TRACE_PAGE}.events.jsonl
trace_emit() {
  local event_type="${1:?trace_emit requires event_type}"
  local data="${2:-"{}"}"
  local explicit_span_id="${3:-}"

  # 如果 data 为空或空白，默认为空对象
  [[ -z "${data// /}" ]] && data='{"_":"_"}'

  # 验证 data 是合法 JSON，如果不是则包装为 message
  if ! echo "$data" | jq empty 2>/dev/null; then
    data=$(jq -cn --arg m "$data" '{message:$m}')
  fi

  local ts
  ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

  local target_file="${TRACE_DIR}/${TRACE_PAGE}.events.jsonl"

  # 自动 span 上下文：
  # - 显式 span_id（开/关事件）作为本事件的 span_id
  # - parent_span_id 永远来自栈顶（注意：开 span 事件传入的是"自己刚生成的 id"，
  #   而 _span_push 是由调用方在 trace_emit 之前完成的，因此栈顶就是该事件的 span_id 本身。
  #   为避免 self-parent，开 span 时 parent 取栈顶下一层；其余情况 parent 取栈顶）
  local span_id="$explicit_span_id"
  local parent_span_id=""
  local stack_n=${#_SPAN_STACK[@]}
  if [[ -n "$explicit_span_id" ]]; then
    # 调用方在 emit 前已 push，自身 = 栈顶；parent = 栈顶下一层（若存在）
    if (( stack_n >= 2 )); then
      parent_span_id="${_SPAN_STACK[stack_n-2]}"
    fi
  else
    if (( stack_n >= 1 )); then
      parent_span_id="${_SPAN_STACK[stack_n-1]}"
    fi
  fi

  # 使用 jq -n 构建完整 JSON，通过 input 读取 data 避免 --argjson 的 shell 问题
  # change_id 是 schema v1.3 早就要求的字段（之前漏发），这里补上
  echo "$data" | jq -cn \
    --arg ts "$ts" \
    --arg cid "$TRACE_PAGE" \
    --arg tid "$TRACE_ID" \
    --arg phase "$TRACE_PHASE" \
    --arg actor "$TRACE_ACTOR" \
    --arg event "$event_type" \
    --arg span "$span_id" \
    --arg parent "$parent_span_id" \
    '{ts:$ts, change_id:$cid, trace_id:$tid, phase:$phase, actor:$actor, event:$event}
     + (if $span   != "" then {span_id:$span}        else {} end)
     + (if $parent != "" then {parent_span_id:$parent} else {} end)
     + {data: input}' \
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

# trace_phase_start: 标记阶段开始（自动 push span）
# 用法: trace_phase_start <phase_name> [actor]
trace_phase_start() {
  TRACE_PHASE="${1:?trace_phase_start requires phase_name}"
  TRACE_ACTOR="${2:-orchestrator}"
  local sid; sid=$(_span_new_id)
  _span_push "$sid"
  trace_emit "phase.start" '{"phase_name":"'"$TRACE_PHASE"'"}' "$sid"
}

# trace_phase_end: 标记阶段结束（自动 pop span）
# 用法: trace_phase_end <status> [extra_json]
# status: pass | fail | warn | blocked | skip | awaiting_agent
trace_phase_end() {
  local status="${1:?trace_phase_end requires status}"
  local extra="${2:-}"
  local base
  base=$(jq -cn --arg s "$status" '{status:$s}')
  local sid; sid=$(_span_top)
  trace_emit "phase.end" "$(_jq_merge "$base" "$extra")" "$sid"
  _span_pop
}

# trace_gate: 记录门控评估（point 事件，不开 span）
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

# trace_gate_start: 开 gate span（v1.6.1+）
# 用法: trace_gate_start <gate_id> [extra_json]
trace_gate_start() {
  local gate="${1:?}"
  local extra="${2:-}"
  local base; base=$(jq -cn --arg g "$gate" '{gate:$g}')
  local sid; sid=$(_span_new_id)
  _span_push "$sid"
  trace_emit "gate.start" "$(_jq_merge "$base" "$extra")" "$sid"
}

# trace_gate_end: 关 gate span（v1.6.1+）
# 用法: trace_gate_end <gate_id> <result> [extra_json]
trace_gate_end() {
  local gate="${1:?}"
  local result="${2:?}"
  local extra="${3:-}"
  local base; base=$(jq -cn --arg g "$gate" --arg r "$result" '{gate:$g, result:$r}')
  local sid; sid=$(_span_top)
  trace_emit "gate.eval" "$(_jq_merge "$base" "$extra")" "$sid"
  _span_pop
}

# trace_task: 记录任务状态变更（start 自动 push、end 自动 pop span）
# 用法: trace_task <start|end> <task_id> [extra_json]
trace_task() {
  local action="${1:?}"  # start | end
  local task_id="${2:?}"
  local extra="${3:-}"
  local base
  base=$(jq -cn --arg t "$task_id" '{task_id:$t}')
  if [[ "$action" == "start" ]]; then
    local sid; sid=$(_span_new_id)
    _span_push "$sid"
    trace_emit "task.start" "$(_jq_merge "$base" "$extra")" "$sid"
  else
    local sid; sid=$(_span_top)
    trace_emit "task.end" "$(_jq_merge "$base" "$extra")" "$sid"
    _span_pop
  fi
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

# trace_adapter_use: 记录一次 Consumer→Adapter 能力消费事件（v1.6+，观测用）
#
# 语义：当前 change（consumer）实际使用了某个 adapter（provider）提供的资产。
# 这是 Consumer-Driven Contract 的"事实账本"基础——只观测、不阻塞。
# 后续可由 broker 脚本聚合 pipeline-output/trace/*.events.jsonl 生成 consumer pact。
#
# 用法: trace_adapter_use <asset_kind> <asset_id> [extra_json]
#   asset_kind: build_command | skill | rule | template | agent | capability
#   asset_id:   adapter 资产标识（如 "compile_check" / "react-server-components"）
#   extra:      可选附加 JSON（如 {"cmd":"npx tsc","via_env":"PL_BUILD_CHECK_CMD"}）
#
# 自动从宿主 $PL_PROJECT/.pl-adapter.yaml 读 adapter id 与 version（带进程内缓存）。
trace_adapter_use() {
  local kind="${1:?trace_adapter_use requires asset_kind}"
  local id="${2:?trace_adapter_use requires asset_id}"
  local extra="${3:-}"

  local adapter_id="${_PL_ADAPTER_ID_CACHE:-}"
  local adapter_ver="${_PL_ADAPTER_VER_CACHE:-}"
  if [[ -z "$adapter_id" && -n "${PL_PROJECT:-}" && -f "$PL_PROJECT/.pl-adapter.yaml" ]]; then
    # 解析 adapter.id / adapter.version（minimal YAML，不依赖 PyYAML）
    adapter_id=$(awk '
      /^[[:space:]]*adapter:[[:space:]]*$/ { in_adapter=1; next }
      in_adapter && /^[^[:space:]]/ { in_adapter=0 }
      in_adapter && /^[[:space:]]+id:/ {
        sub(/^[[:space:]]+id:[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        print; exit
      }
    ' "$PL_PROJECT/.pl-adapter.yaml" 2>/dev/null)
    adapter_ver=$(awk '
      /^[[:space:]]*adapter:[[:space:]]*$/ { in_adapter=1; next }
      in_adapter && /^[^[:space:]]/ { in_adapter=0 }
      in_adapter && /^[[:space:]]+version:/ {
        sub(/^[[:space:]]+version:[[:space:]]*/, "")
        gsub(/^"|"$/, "")
        print; exit
      }
    ' "$PL_PROJECT/.pl-adapter.yaml" 2>/dev/null)
    export _PL_ADAPTER_ID_CACHE="${adapter_id:-unknown}"
    export _PL_ADAPTER_VER_CACHE="${adapter_ver:-unknown}"
    adapter_id="$_PL_ADAPTER_ID_CACHE"
    adapter_ver="$_PL_ADAPTER_VER_CACHE"
  fi

  local base
  base=$(jq -cn \
    --arg adapter "${adapter_id:-unknown}" \
    --arg version "${adapter_ver:-unknown}" \
    --arg kind "$kind" \
    --arg id "$id" \
    '{adapter:$adapter, adapter_version:$version, asset_kind:$kind, asset_id:$id}')
  trace_emit "adapter.use" "$(_jq_merge "$base" "$extra")"
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
