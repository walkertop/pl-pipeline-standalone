#!/usr/bin/env bash
# =============================================================================
# pipeline-orchestrator.sh — Agentic Workflow 全流程编排器
# =============================================================================
#
# 基于 .state.md 蓝图驱动 Pipeline 各阶段的调度和门控。
# 对脚本阶段自动执行，对 Agent 阶段暂停等待人工/AI 介入。
# 所有事件写入统一的 Event Journal (pipeline-output/trace/{page}.events.jsonl)。
#
# 用法:
#   ./scripts/pipeline-orchestrator.sh --page order_detail
#   ./scripts/pipeline-orchestrator.sh --page order_detail --from VERIFY
#   ./scripts/pipeline-orchestrator.sh --page order_detail --only VERIFY
#   ./scripts/pipeline-orchestrator.sh --page order_detail --status
#   ./scripts/pipeline-orchestrator.sh --page order_detail --diff
#
# 阶段定义:
#   SPEC       → agent:migration-analyzer   (需求标准化 + 依赖分析)
#   PLAN       → agent:migration-analyzer   (TaskDAG + Contract)
#   IMPLEMENT  → agent:migration-coder      (代码实现)
#   VERIFY     → script:migration-verify    (静态检查 + 编译 + 运行时)
#   OBSERVE    → agent:migration-guardian   (运行时观测 + 自动修复)
#   ARCHIVE    → agent:knowledge-archiver   (知识沉淀)
#
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/trace-emit.sh"

# ---- 颜色 -------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ---- 阶段定义 ----------------------------------------------------------------

# 有序阶段列表（空格分隔字符串，兼容 bash 3.x）
ORDERED_STAGES="SPEC PLAN IMPLEMENT VERIFY OBSERVE ARCHIVE"

# 阶段 → 序号（用函数查表替代 declare -A）
stage_order() {
  case "$1" in
    SPEC) echo 0 ;; PLAN) echo 1 ;; IMPLEMENT) echo 2 ;;
    VERIFY) echo 3 ;; OBSERVE) echo 4 ;; ARCHIVE) echo 5 ;;
    *) echo 99 ;;
  esac
}

# 阶段 → 执行器
stage_actor() {
  case "$1" in
    SPEC)      echo "agent:migration-analyzer" ;;
    PLAN)      echo "agent:migration-analyzer" ;;
    IMPLEMENT) echo "agent:migration-coder" ;;
    VERIFY)    echo "script:migration-verify" ;;
    OBSERVE)   echo "agent:migration-guardian" ;;
    ARCHIVE)   echo "agent:knowledge-archiver" ;;
    *)         echo "unknown" ;;
  esac
}

# 阶段 → 门控表达式（人类可读描述）
stage_gate() {
  case "$1" in
    SPEC)      echo "" ;;
    PLAN)      echo "spec.complete AND blocking_questions == 0" ;;
    IMPLEMENT) echo "dag.tasks_defined AND component_reuse.analyzed" ;;
    VERIFY)    echo "tasks.all_done" ;;
    OBSERVE)   echo "verify.lint.pass AND verify.compile.pass" ;;
    ARCHIVE)   echo "no_p0_issues AND knowledge_captured" ;;
    *)         echo "" ;;
  esac
}

# 阶段 → emoji
stage_emoji() {
  case "$1" in
    SPEC) echo "📝" ;; PLAN) echo "🗂" ;; IMPLEMENT) echo "💻" ;;
    VERIFY) echo "🔍" ;; OBSERVE) echo "📡" ;; ARCHIVE) echo "📦" ;;
    *) echo "❓" ;;
  esac
}

# ---- .state.md 解析函数 ------------------------------------------------------

# 读取 .state.md 中的字段值
# 用法: state_read <state_file> <field_name>
state_read() {
  local file="$1" field="$2"
  grep "^- ${field}:" "$file" 2>/dev/null | sed "s/^- ${field}: *//" | tr -d '"'
}

# 读取 Task Progress 中的任务统计
state_task_stats() {
  local file="$1"
  local total done_count
  # 排除表头行 "| Task ID"，只统计 "| T-" 开头的任务行
  total=$(grep -c '| T-' "$file" 2>/dev/null) || total=0
  done_count=$(grep -c '✅ DONE' "$file" 2>/dev/null) || done_count=0
  echo "${done_count}/${total}"
}

# 读取 Self-Check Results 中特定层的状态
state_check_status() {
  local file="$1" layer="$2"
  grep "| ${layer}" "$file" 2>/dev/null | grep -oE '(✅ PASS|❌ FAIL|⏭️ SKIP|⚠️ WARN)' | head -1 || echo "UNKNOWN"
}

# 读取 Open Questions 数量（排除"暂无"行）
state_open_questions() {
  local file="$1"
  local count
  count=$(grep -c '| Q' "$file" 2>/dev/null) || count=0
  echo "$count"
}

# ---- 门控评估 ----------------------------------------------------------------

# evaluate_gate: 评估指定阶段的门控条件
# 返回: passed | blocked | warn
evaluate_gate() {
  local state_file="$1"
  local stage="$2"

  local gate_expr
  gate_expr=$(stage_gate "$stage")
  [[ -z "$gate_expr" ]] && echo "passed" && return 0

  case "$stage" in
    PLAN)
      # 门控: spec 完成 + 无阻塞问题
      local current
      current=$(state_read "$state_file" "stage")
      local oq
      oq=$(state_open_questions "$state_file")
      local spec_ref
      spec_ref=$(state_read "$state_file" "spec_ref")

      if [[ "$spec_ref" == "N/A" || -z "$spec_ref" ]]; then
        echo "blocked"; return
      fi
      if [[ "$oq" -gt 0 ]]; then
        echo "warn"; return  # 有待确认项，警告但不阻塞
      fi
      echo "passed"
      ;;

    IMPLEMENT)
      # 门控: TaskDAG 定义 + 组件复用分析完成
      local dag_ref
      dag_ref=$(state_read "$state_file" "dag_ref")
      local reuse_rate
      reuse_rate=$(grep 'reuse_rate:' "$state_file" 2>/dev/null | head -1)

      if [[ "$dag_ref" == "N/A" || -z "$dag_ref" ]]; then
        echo "blocked"; return
      fi
      echo "passed"
      ;;

    VERIFY)
      # 门控: 所有任务完成
      local stats
      stats=$(state_task_stats "$state_file")
      local done_count total_count
      done_count=$(echo "$stats" | cut -d/ -f1)
      total_count=$(echo "$stats" | cut -d/ -f2)

      if [[ "$total_count" -eq 0 ]]; then
        echo "blocked"; return
      fi
      if [[ "$done_count" -lt "$total_count" ]]; then
        echo "blocked"; return
      fi
      echo "passed"
      ;;

    OBSERVE)
      # 门控: lint 和 compile 通过
      local lint_st compile_st
      lint_st=$(state_check_status "$state_file" "静态检查")
      compile_st=$(state_check_status "$state_file" "编译")

      if [[ "$lint_st" == *"FAIL"* || "$compile_st" == *"FAIL"* ]]; then
        echo "blocked"; return
      fi
      if [[ "$lint_st" == *"SKIP"* || "$compile_st" == *"SKIP"* ]]; then
        echo "warn"; return
      fi
      echo "passed"
      ;;

    ARCHIVE)
      # 门控: 无 P0 问题
      echo "passed"
      ;;

    *)
      echo "passed"
      ;;
  esac
}

# ---- .state.md diff → trace events 推导 ------------------------------------

# 给编排器调度 Agent 前后使用，从 .state.md 变更推导事件
# 用法: state_diff_emit <page_id> <before_snapshot> <after_file>
state_diff_emit() {
  local page_id="$1"
  local before_snap="$2"
  local after_file="$3"

  # 比较 stage 变化
  local before_stage after_stage
  before_stage=$(echo "$before_snap" | grep '^- stage:' | sed 's/- stage: //' | tr -d ' "')
  after_stage=$(state_read "$after_file" "stage")

  if [[ "$before_stage" != "$after_stage" ]]; then
    trace_emit "phase.end" "$(jq -cn \
      --arg phase "$before_stage" \
      --arg status "pass" \
      '{phase:$phase, status:$status, reason:"stage transition detected"}')"
    trace_emit "phase.start" "$(jq -cn \
      --arg phase "$after_stage" \
      '{phase:$phase}')"
  fi

  # 比较 Task Progress 变化
  local before_done after_done
  before_done=$(echo "$before_snap" | grep -c '✅ DONE') || before_done=0
  after_done=$(grep -c '✅ DONE' "$after_file") || after_done=0

  if [[ "$after_done" -gt "$before_done" ]]; then
    local new_tasks=$((after_done - before_done))
    trace_emit "task.end" "$(jq -cn \
      --argjson count "$new_tasks" \
      '{batch_completed:$count, source:"state.md diff"}')"
  fi

  # 比较 Self-Check 变化
  local before_checks after_checks
  before_checks=$(echo "$before_snap" | grep -c '✅ PASS') || before_checks=0
  after_checks=$(grep -c '✅ PASS' "$after_file") || after_checks=0

  if [[ "$after_checks" -gt "$before_checks" ]]; then
    trace_emit "check.run" "$(jq -cn \
      --argjson new_passes "$((after_checks - before_checks))" \
      '{checker:"state.md self-check", status:"pass", new_passes:$new_passes}')"
  fi

  # 检查新增的 Artifacts
  local before_files after_files
  before_files=$(echo "$before_snap" | grep -c '\.kt') || before_files=0
  after_files=$(grep -c '\.kt' "$after_file") || after_files=0

  if [[ "$after_files" -gt "$before_files" ]]; then
    trace_emit "artifact.create" "$(jq -cn \
      --argjson count "$((after_files - before_files))" \
      '{new_files:$count, source:"state.md diff"}')"
  fi
}

# ---- 状态展示 ----------------------------------------------------------------

show_status() {
  local state_file="$1"
  local page_id="$2"

  local current_stage
  current_stage=$(state_read "$state_file" "stage")
  local gate_status
  gate_status=$(state_read "$state_file" "gate_status")
  local task_stats
  task_stats=$(state_task_stats "$state_file")

  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}📊 Pipeline Status: ${page_id}${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}当前阶段:${NC}  ${current_stage}"
  echo -e "  ${BOLD}门控状态:${NC}  ${gate_status}"
  echo -e "  ${BOLD}任务进度:${NC}  ${task_stats}"
  echo ""

  # Pipeline 进度条
  echo -e "  ${DIM}Pipeline:${NC}"
  echo -n "  "
  for stage in $ORDERED_STAGES; do
    local s_idx
    s_idx=$(stage_order "$stage")
    local c_idx
    c_idx=$(stage_order "$current_stage")
    local emoji
    emoji=$(stage_emoji "$stage")

    if [[ $s_idx -lt $c_idx ]]; then
      echo -ne "${GREEN}${emoji} ${stage}${NC} → "
    elif [[ $s_idx -eq $c_idx ]]; then
      echo -ne "${BLUE}${BOLD}${emoji} [${stage}]${NC} → "
    else
      echo -ne "${DIM}${emoji} ${stage}${NC} → "
    fi
  done
  echo ""
  echo ""

  # 门控评估预览
  echo -e "  ${DIM}门控评估:${NC}"
  for stage in $ORDERED_STAGES; do
    local gate_expr
    gate_expr=$(stage_gate "$stage")
    [[ -z "$gate_expr" ]] && continue
    local gate_result
    gate_result=$(evaluate_gate "$state_file" "$stage")
    local gate_icon="⬜"
    case "$gate_result" in
      passed)  gate_icon="${GREEN}✅${NC}" ;;
      blocked) gate_icon="${RED}🚫${NC}" ;;
      warn)    gate_icon="${YELLOW}⚠️${NC}" ;;
    esac
    echo -e "    ${gate_icon} ${stage}: ${DIM}${gate_expr}${NC}"
  done
  echo ""

  # Trace 事件统计
  local trace_file="$TRACE_DIR/${page_id}.events.jsonl"
  if [[ -f "$trace_file" ]]; then
    local event_count
    event_count=$(wc -l < "$trace_file" | tr -d ' ')
    local last_event
    last_event=$(tail -1 "$trace_file" | jq -r '.event + " (" + .phase + ")"' 2>/dev/null || echo "N/A")
    echo -e "  ${DIM}Trace Events:${NC} ${event_count} events"
    echo -e "  ${DIM}Last Event:${NC}   ${last_event}"
    echo ""
  fi
}

# ---- 主逻辑 -----------------------------------------------------------------

main() {
  local page_id=""
  local from_stage=""
  local only_stage=""
  local show_status_only=false
  local show_diff=false
  local dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --page)   page_id="$2"; shift 2 ;;
      --from)   from_stage="$2"; shift 2 ;;
      --only)   only_stage="$2"; shift 2 ;;
      --status) show_status_only=true; shift ;;
      --diff)   show_diff=true; shift ;;
      --dry-run) dry_run=true; shift ;;
      -h|--help)
        echo "用法: ./scripts/pipeline-orchestrator.sh --page <page_id> [选项]"
        echo ""
        echo "选项:"
        echo "  --page NAME     指定页面 (必须)"
        echo "  --from STAGE    从指定阶段开始 (SPEC|PLAN|IMPLEMENT|VERIFY|OBSERVE|ARCHIVE)"
        echo "  --only STAGE    仅执行指定阶段"
        echo "  --status        仅显示当前状态"
        echo "  --diff          显示 .state.md 与 trace 的差异"
        echo "  --dry-run       模拟执行，不实际运行"
        echo ""
        echo "示例:"
        echo "  ./scripts/pipeline-orchestrator.sh --page order_detail"
        echo "  ./scripts/pipeline-orchestrator.sh --page order_detail --status"
        echo "  ./scripts/pipeline-orchestrator.sh --page order_detail --from VERIFY"
        echo "  ./scripts/pipeline-orchestrator.sh --page order_detail --only VERIFY --dry-run"
        exit 0 ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
  done

  [[ -z "$page_id" ]] && { echo -e "${RED}Error: --page required${NC}"; exit 1; }

  # 查找 .state.md
  local state_file
  state_file=$(find "$PROJECT_ROOT/openspec" -name "${page_id}.state.md" 2>/dev/null | head -1)
  [[ -z "$state_file" ]] && { echo -e "${RED}Error: ${page_id}.state.md not found in openspec/${NC}"; exit 1; }

  # 初始化 trace
  trace_init "$page_id"

  # --status 模式
  if $show_status_only; then
    show_status "$state_file" "$page_id"
    return 0
  fi

  # --diff 模式
  if $show_diff; then
    local trace_file="$TRACE_DIR/${page_id}.events.jsonl"
    if [[ -f "$trace_file" ]]; then
      echo -e "${BOLD}State.md vs Trace Events:${NC}"
      echo ""
      trace_summary
    else
      echo "No trace events found."
    fi
    return 0
  fi

  # ---- 编排模式 ----
  local current_stage
  current_stage=$(state_read "$state_file" "stage")

  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}🚀 Pipeline Orchestrator${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  📄 Page:    ${page_id}"
  echo -e "  📍 Stage:   ${current_stage}"
  echo -e "  📁 State:   ${state_file}"
  echo ""

  # 确定执行范围
  local stages_to_run=""
  if [[ -n "$only_stage" ]]; then
    stages_to_run="$only_stage"
  else
    local start_stage="${from_stage:-$current_stage}"
    local start_idx
    start_idx=$(stage_order "$start_stage")
    for stage in $ORDERED_STAGES; do
      local s_idx
      s_idx=$(stage_order "$stage")
      if [[ $s_idx -ge $start_idx ]]; then
        stages_to_run="$stages_to_run $stage"
      fi
    done
    stages_to_run=$(echo "$stages_to_run" | sed 's/^ //')
  fi

  echo -e "  🎯 Stages:  ${stages_to_run}"
  echo ""

  # 发射 workflow.start
  trace_emit "workflow.start" "$(jq -cn \
    --arg page "$page_id" \
    --arg stages "$stages_to_run" \
    --arg current "$current_stage" \
    '{page:$page, stages:$stages, current_stage:$current}')"

  # 保存 state 快照（用于 diff 推导）
  local state_snapshot
  state_snapshot=$(cat "$state_file")

  # 逐阶段执行
  for stage in $stages_to_run; do
    local emoji
    emoji=$(stage_emoji "$stage")
    echo -e "${CYAN}━━━ ${emoji} Phase: ${stage} ━━━${NC}"

    local actor
    actor=$(stage_actor "$stage")
    trace_phase_start "$stage" "${actor:-orchestrator}"

    # 门控检查
    local gate_expr
    gate_expr=$(stage_gate "$stage")
    if [[ -n "$gate_expr" ]]; then
      local gate_result
      gate_result=$(evaluate_gate "$state_file" "$stage")
      trace_gate "$stage" "$gate_expr" "$gate_result"

      case "$gate_result" in
        blocked)
          echo -e "  ${RED}🚫 门控未通过:${NC} ${DIM}${gate_expr}${NC}"
          trace_phase_end "blocked" "$(jq -cn --arg r "gate not passed: $gate_expr" '{reason:$r}')"
          echo ""
          break
          ;;
        warn)
          echo -e "  ${YELLOW}⚠️  门控警告:${NC} ${DIM}${gate_expr}${NC}"
          echo -e "  ${DIM}继续执行...${NC}"
          ;;
        passed)
          echo -e "  ${GREEN}✅ 门控通过${NC}"
          ;;
      esac
    else
      echo -e "  ${DIM}(无门控)${NC}"
    fi

    # Dry-run 模式
    if $dry_run; then
      echo -e "  ${MAGENTA}[DRY-RUN]${NC} 跳过执行"
      trace_phase_end "dry_run" '{}'
      echo ""
      continue
    fi

    # 执行阶段
    case "$actor" in
      agent:*)
        local agent_name="${actor#agent:}"
        echo -e "  ${MAGENTA}🤖 需要 Agent 介入:${NC} ${BOLD}${agent_name}${NC}"
        echo ""
        echo -e "  ${DIM}请在 CodeBuddy 中执行对应 Agent 任务。${NC}"
        echo -e "  ${DIM}Agent 完成后，编排器会从 .state.md 变更推导事件。${NC}"
        echo ""

        # 提示信息
        case "$agent_name" in
          migration-analyzer)
            echo -e "  💡 ${DIM}使用 migration-analyzer Agent 完成需求标准化 / 依赖分析 / TaskDAG 拆分${NC}" ;;
          migration-coder)
            echo -e "  💡 ${DIM}使用 migration-coder Agent 按 TaskDAG 逐任务编码${NC}" ;;
          migration-guardian)
            echo -e "  💡 ${DIM}使用 migration-guardian Agent 分析运行时日志，检测断链，自动修复${NC}" ;;
          knowledge-archiver)
            echo -e "  💡 ${DIM}使用 knowledge-archiver Agent 沉淀迁移经验，更新 Rules & Skills${NC}" ;;
        esac
        echo ""

        trace_phase_end "awaiting_agent" "$(jq -cn --arg a "$agent_name" '{agent:$a}')"

        # Agent 阶段：暂停编排，等待下次运行
        echo -e "  ${BLUE}⏸  编排暂停。Agent 完成后重新运行编排器继续。${NC}"
        echo ""
        break
        ;;

      script:*)
        local script_name="${actor#script:}"
        echo -e "  ${BLUE}🔧 执行脚本:${NC} ${script_name}"
        echo ""

        case "$script_name" in
          migration-verify)
            local verify_args="--page $page_id"
            echo -e "  ${DIM}→ ./scripts/migration-verify.sh ${verify_args}${NC}"
            echo ""

            if "$SCRIPT_DIR/migration-verify.sh" $verify_args; then
              trace_phase_end "pass" '{}'
              echo -e "  ${GREEN}✅ VERIFY 阶段完成${NC}"
            else
              trace_phase_end "fail" '{}'
              echo -e "  ${RED}❌ VERIFY 阶段失败${NC}"
              echo ""
              break
            fi
            ;;

          runtime-observer)
            echo -e "  ${YELLOW}⏳ 运行时观测（开发中）${NC}"
            trace_phase_end "skip" '{"reason":"not implemented yet"}'
            ;;

          *)
            echo -e "  ${YELLOW}⚠️  未知脚本: ${script_name}${NC}"
            trace_phase_end "skip" "$(jq -cn --arg s "$script_name" '{reason:"unknown script", script:$s}')"
            ;;
        esac
        ;;
    esac

    echo ""

    # 阶段执行后，diff state.md 推导事件
    local current_state
    current_state=$(cat "$state_file")
    if [[ "$current_state" != "$state_snapshot" ]]; then
      state_diff_emit "$page_id" "$state_snapshot" "$state_file"
      state_snapshot="$current_state"
    fi
  done

  # 发射 workflow.end
  trace_emit "workflow.end" "$(jq -cn \
    --arg page "$page_id" \
    --arg stages "$stages_to_run" \
    '{page:$page, planned_stages:$stages}')"

  # 打印 trace 摘要
  echo -e "${CYAN}━━━ 📊 Trace Summary ━━━${NC}"
  echo ""
  trace_summary
  echo ""

  # 提示生成报告
  local trace_file="$TRACE_DIR/${page_id}.events.jsonl"
  if [[ -f "$trace_file" ]]; then
    echo -e "  ${DIM}查看 HTML 报告:${NC}"
    echo -e "    ${BOLD}./scripts/trace-report.sh --page ${page_id} --open${NC}"
    echo ""
  fi
}

main "$@"
