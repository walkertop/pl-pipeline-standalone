#!/usr/bin/env bash
# =============================================================================
# pl-agent-run.sh — Agent Execution Loop MVP
# =============================================================================
#
# 用法:
#   pl-agent-run.sh --change <id> --cmd <command> [--task <id>]
#   pl-agent-run.sh --change <id> --cmd <command> --verify-gate D \
#     --repair-cmd <command> --max-retries 1 [--json]
#
# 职责：
#   1. 执行一个 agent/executor 命令
#   2. 可选调用 pl-runner gate 验证
#   3. gate 失败时生成 repair context，并在预算内执行 repair 命令
#   4. 将 agent/gate/repair 全部写入同一条 trace
#
# 退出码:
#   0 = 最终命令或 gate 通过
#   1 = 命令或 gate 阻塞，且无法修复
#   2 = 参数错误
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
# shellcheck source=./trace-emit.sh
source "$(dirname "${BASH_SOURCE[0]}")/trace-emit.sh"
set +e
set -uo pipefail

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=; GREEN=; YELLOW=; BLUE=; BOLD=; DIM=; NC=
fi

log_info()  { echo "${BLUE}ℹ${NC} $*"; }
log_ok()    { echo "${GREEN}✅${NC} $*"; }
log_warn()  { echo "${YELLOW}⚠${NC}  $*"; }
log_error() { echo "${RED}✗${NC}  $*" >&2; }

CHANGE=""
TASK_ID="manual"
EXECUTOR="local"
CMD=""
VERIFY_GATE=""
REPAIR_CMD=""
MAX_RETRIES=0
JSON_OUT=false

usage() {
  sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-2}"
}

require_value() {
  local opt="$1"
  local val="${2:-}"
  [[ -n "$val" ]] || { log_error "Missing value for $opt"; usage; }
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change)      require_value "$1" "${2:-}"; CHANGE="$2"; shift 2 ;;
    --task)        require_value "$1" "${2:-}"; TASK_ID="$2"; shift 2 ;;
    --executor)    require_value "$1" "${2:-}"; EXECUTOR="$2"; shift 2 ;;
    --cmd)         require_value "$1" "${2:-}"; CMD="$2"; shift 2 ;;
    --verify-gate) require_value "$1" "${2:-}"; VERIFY_GATE="$2"; shift 2 ;;
    --repair-cmd)  require_value "$1" "${2:-}"; REPAIR_CMD="$2"; shift 2 ;;
    --max-retries) require_value "$1" "${2:-}"; MAX_RETRIES="$2"; shift 2 ;;
    --json)        JSON_OUT=true; shift ;;
    -h|--help)     usage 0 ;;
    *)             log_error "Unknown option: $1"; usage ;;
  esac
done

[[ -n "$CHANGE" ]] || { log_error "Missing --change <id>"; usage; }
[[ -n "$CMD" ]] || { log_error "Missing --cmd <command>"; usage; }
if ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
  log_error "--max-retries must be a non-negative integer"
  exit 2
fi

RUN_ID="$(date +%Y%m%d_%H%M%S)_$$"
RUN_DIR="$PL_OUTPUT/agent-runs/$CHANGE/$RUN_ID"
mkdir -p "$RUN_DIR"

RUN_CMD_LOG=""
GATE_LOG=""
REPAIR_CONTEXT=""
LAST_GATE_RESULT=""
LAST_CMD_RC=0
LAST_GATE_RC=0

run_executor_command() {
  local kind="$1"
  local attempt="$2"
  local command="$3"
  local log_file="$RUN_DIR/attempt-${attempt}-${kind}.log"
  local start_ts end_ts duration rc

  RUN_CMD_LOG="$log_file"
  start_ts=$(date +%s)

  log_info "agent $kind attempt=$attempt executor=$EXECUTOR"
  echo "  ${DIM}\$ $command${NC}"

  trace_emit "agent.run.start" "$(jq -nc \
    --arg run_id "$RUN_ID" --arg executor "$EXECUTOR" --arg task "$TASK_ID" \
    --arg kind "$kind" --arg cmd "$command" --argjson attempt "$attempt" \
    '{run_id:$run_id,executor:$executor,task_id:$task,kind:$kind,attempt:$attempt,cmd:$cmd}')"

  (
    cd "$PL_PROJECT" || exit 1
    export PL_CHANGE="$CHANGE"
    export PL_TASK_ID="$TASK_ID"
    export PL_RUN_ID="$RUN_ID"
    export PL_RUN_DIR="$RUN_DIR"
    export PL_AGENT_EXECUTOR="$EXECUTOR"
    export PL_AGENT_ATTEMPT="$attempt"
    if [[ -n "$REPAIR_CONTEXT" ]]; then
      export PL_REPAIR_CONTEXT="$REPAIR_CONTEXT"
    fi
    bash -c "$command"
  ) > "$log_file" 2>&1
  rc=$?
  end_ts=$(date +%s)
  duration=$((end_ts - start_ts))
  LAST_CMD_RC=$rc

  trace_emit "agent.run.result" "$(jq -nc \
    --arg run_id "$RUN_ID" --arg executor "$EXECUTOR" --arg task "$TASK_ID" \
    --arg kind "$kind" --arg log "$log_file" --argjson attempt "$attempt" \
    --argjson exit_code "$rc" --argjson duration "$duration" \
    '{run_id:$run_id,executor:$executor,task_id:$task,kind:$kind,attempt:$attempt,exit_code:$exit_code,duration_sec:$duration,log:$log}')"

  if [[ "$kind" == "repair" ]]; then
    trace_emit "agent.repair.result" "$(jq -nc \
      --arg run_id "$RUN_ID" --arg context "$REPAIR_CONTEXT" --arg log "$log_file" \
      --argjson attempt "$attempt" --argjson exit_code "$rc" \
      '{run_id:$run_id,attempt:$attempt,exit_code:$exit_code,context:$context,log:$log}')"
  fi

  if [[ $rc -eq 0 ]]; then
    log_ok "agent $kind command passed"
  else
    log_warn "agent $kind command exited $rc (log: $log_file)"
  fi
  return "$rc"
}

run_verify_gate() {
  local attempt="$1"
  local log_file="$RUN_DIR/attempt-${attempt}-gate-${VERIFY_GATE}.log"
  local gate_json result rc

  GATE_LOG="$log_file"
  log_info "verify gate $VERIFY_GATE attempt=$attempt"
  trace_emit "agent.gate.start" "$(jq -nc \
    --arg run_id "$RUN_ID" --arg gate "$VERIFY_GATE" --argjson attempt "$attempt" \
    '{run_id:$run_id,gate:$gate,attempt:$attempt}')"

  (
    cd "$PL_PROJECT" || exit 1
    PL_HOME="$PL_HOME" PL_PROJECT="$PL_PROJECT" \
      bash "$PL_HOME/scripts/pl-runner.sh" --change "$CHANGE" --gate "$VERIFY_GATE" --json
  ) > "$log_file" 2>&1
  rc=$?

  gate_json=$(grep -E '^\{' "$log_file" | tail -1)
  if [[ -n "$gate_json" ]] && echo "$gate_json" | jq empty >/dev/null 2>&1; then
    result=$(echo "$gate_json" | jq -r '.result // "unknown"')
  elif [[ $rc -eq 0 ]]; then
    result="passed"
  else
    result="blocked"
  fi

  LAST_GATE_RC=$rc
  LAST_GATE_RESULT="$result"
  trace_emit "agent.gate.result" "$(jq -nc \
    --arg run_id "$RUN_ID" --arg gate "$VERIFY_GATE" --arg result "$result" \
    --arg log "$log_file" --argjson attempt "$attempt" --argjson exit_code "$rc" \
    '{run_id:$run_id,gate:$gate,attempt:$attempt,result:$result,exit_code:$exit_code,log:$log}')"

  if [[ $rc -eq 0 ]]; then
    log_ok "gate $VERIFY_GATE passed"
  else
    log_warn "gate $VERIFY_GATE blocked (log: $log_file)"
  fi
  return "$rc"
}

write_repair_context() {
  local attempt="$1"
  local command_log="$2"
  local gate_log="$3"
  local next_command="$4"
  local context_file="$RUN_DIR/repair-context-attempt-${attempt}.md"

  {
    printf '# PL Agent Repair Context\n\n'
    printf -- '- change: `%s`\n' "$CHANGE"
    printf -- '- task: `%s`\n' "$TASK_ID"
    printf -- '- executor: `%s`\n' "$EXECUTOR"
    printf -- '- run_id: `%s`\n' "$RUN_ID"
    printf -- '- failed_attempt: `%s`\n' "$attempt"
    printf -- '- next_attempt_command: `%s`\n\n' "$next_command"

    printf '## Agent command output\n\n```text\n'
    if [[ -f "$command_log" ]]; then
      sed -n '1,180p' "$command_log"
    else
      printf 'missing command log: %s\n' "$command_log"
    fi
    printf '\n```\n\n'

    printf '## Gate output\n\n```text\n'
    if [[ -f "$gate_log" ]]; then
      sed -n '1,220p' "$gate_log"
    else
      printf 'missing gate log: %s\n' "$gate_log"
    fi
    printf '\n```\n'
  } > "$context_file"

  REPAIR_CONTEXT="$context_file"
  trace_artifact create "$context_file" "$(jq -nc \
    --arg run_id "$RUN_ID" --arg kind "repair_context" --arg gate "$VERIFY_GATE" \
    --argjson attempt "$attempt" \
    '{run_id:$run_id,kind:$kind,gate:$gate,failed_attempt:$attempt}')"
  trace_emit "agent.repair.context" "$(jq -nc \
    --arg run_id "$RUN_ID" --arg path "$context_file" --arg gate "$VERIFY_GATE" \
    --argjson attempt "$attempt" \
    '{run_id:$run_id,path:$path,gate:$gate,failed_attempt:$attempt}')"

  log_info "repair context: $context_file"
}

trace_init "$CHANGE" "IMPLEMENT" "agent:$EXECUTOR"
trace_task start "$TASK_ID" "$(jq -nc \
  --arg run_id "$RUN_ID" --arg executor "$EXECUTOR" \
  '{run_id:$run_id,executor:$executor,loop:"agent_execution"}')"

echo "${BOLD}━━━ Agent Execution Loop ━━━${NC}"
echo "  change:   $CHANGE"
echo "  task:     $TASK_ID"
echo "  executor: $EXECUTOR"
echo "  run_dir:  $RUN_DIR"
if [[ -n "$VERIFY_GATE" ]]; then
  echo "  gate:     $VERIFY_GATE"
fi
echo ""

STATUS="blocked"
ATTEMPT=0
KIND="implement"
COMMAND="$CMD"

while :; do
  run_executor_command "$KIND" "$ATTEMPT" "$COMMAND"
  cmd_rc=$?

  if [[ -n "$VERIFY_GATE" ]]; then
    run_verify_gate "$ATTEMPT"
    gate_rc=$?
    if [[ $gate_rc -eq 0 ]]; then
      STATUS="passed"
      break
    fi
  else
    if [[ $cmd_rc -eq 0 ]]; then
      STATUS="passed"
    fi
    break
  fi

  if [[ -z "$REPAIR_CMD" ]]; then
    log_warn "no --repair-cmd provided; stopping after blocked gate"
    break
  fi
  if [[ "$ATTEMPT" -ge "$MAX_RETRIES" ]]; then
    log_warn "repair budget exhausted: attempt=$ATTEMPT max_retries=$MAX_RETRIES"
    break
  fi

  write_repair_context "$ATTEMPT" "$RUN_CMD_LOG" "$GATE_LOG" "$REPAIR_CMD"
  ATTEMPT=$((ATTEMPT + 1))
  KIND="repair"
  COMMAND="$REPAIR_CMD"
done

trace_emit "agent.run.complete" "$(jq -nc \
  --arg run_id "$RUN_ID" --arg status "$STATUS" --arg gate "$VERIFY_GATE" \
  --arg gate_result "$LAST_GATE_RESULT" --arg run_dir "$RUN_DIR" \
  --argjson attempts "$((ATTEMPT + 1))" --argjson command_exit "$LAST_CMD_RC" --argjson gate_exit "$LAST_GATE_RC" \
  '{run_id:$run_id,status:$status,attempts:$attempts,command_exit_code:$command_exit,gate_exit_code:$gate_exit,run_dir:$run_dir}
   + (if $gate != "" then {gate:$gate,gate_result:$gate_result} else {} end)')"

trace_task end "$TASK_ID" "$(jq -nc --arg status "$STATUS" --arg run_id "$RUN_ID" '{status:$status,run_id:$run_id}')"

echo ""
echo "${BOLD}━━━ Summary ━━━${NC}"
echo "  status: $STATUS"
echo "  run:    $RUN_DIR"
echo "  trace:  $PL_OUTPUT/trace/$CHANGE.events.jsonl"

if $JSON_OUT; then
  jq -nc --arg status "$STATUS" --arg run_id "$RUN_ID" --arg run_dir "$RUN_DIR" \
    --arg trace "$PL_OUTPUT/trace/$CHANGE.events.jsonl" \
    '{status:$status,run_id:$run_id,run_dir:$run_dir,trace:$trace}'
fi

if [[ "$STATUS" == "passed" ]]; then
  exit 0
fi
exit 1
