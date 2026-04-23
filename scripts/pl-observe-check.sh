#!/usr/bin/env bash
# =============================================================================
# pl-observe-check.sh — 观测完整性检查（pl-core VERIFY 阶段必跑）
# =============================================================================
#
# 检查每个活跃 change 是否有：
#   1. 完整的 .state.md（非空、有 Pipeline State 章节）
#   2. 对应的 trace 事件文件（非空）
#   3. trace 中包含 workflow.start 事件
#
# 用法：
#   pl-observe-check.sh                     # 检查所有 change
#   pl-observe-check.sh <change-id>         # 检查单个 change
#   pl-observe-check.sh --strict            # 严格模式（warn 变 error）
#
# 退出码：
#   0 = 全部通过
#   1 = 有 error
#   2 = 有 warn（非严格模式下仍 exit 0）
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$PWD"
STRICT=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)   STRICT=1; shift ;;
    --help|-h)  sed -n '1,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          TARGET="$1"; shift ;;
  esac
done

RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; NC='\033[0m'

errors=0
warns=0

check_change() {
  local cid="$1"
  local change_dir="$PROJECT_ROOT/pl/changes/$cid"
  local state_file="$change_dir/.state.md"
  local trace_file="$PROJECT_ROOT/pipeline-output/trace/${cid}.events.jsonl"

  echo "━━━ $cid ━━━"

  # Check 1: .state.md 存在且有内容
  if [[ ! -f "$state_file" ]]; then
    echo -e "  ${RED}✗${NC} .state.md 不存在"
    echo "    修复: pl-state-init.sh $cid"
    ((errors++))
  elif [[ ! -s "$state_file" ]]; then
    echo -e "  ${RED}✗${NC} .state.md 为空"
    ((errors++))
  else
    # Check 1b: 有 Pipeline State 章节
    if grep -q "^## Pipeline State" "$state_file"; then
      echo -e "  ${GREEN}✓${NC} .state.md 完整（有 Pipeline State 章节）"
    else
      echo -e "  ${YELLOW}⚠${NC} .state.md 存在但缺少 'Pipeline State' 章节（可能是简陋版）"
      echo "    修复: 用 pl-state-init.sh 重新生成，或按模板补全"
      ((warns++))
    fi

    # Check 1c: 有 History 章节
    if ! grep -q "^## History" "$state_file"; then
      echo -e "  ${YELLOW}⚠${NC} .state.md 缺少 History 章节（无法追溯阶段变更）"
      ((warns++))
    fi

    # Check 1d: 有 Self-Check 章节
    if ! grep -q "^## Self-Check" "$state_file"; then
      echo -e "  ${YELLOW}⚠${NC} .state.md 缺少 Self-Check Results 章节"
      ((warns++))
    fi
  fi

  # Check 2: trace 文件存在且非空
  if [[ ! -f "$trace_file" ]]; then
    echo -e "  ${RED}✗${NC} trace 文件不存在: $trace_file"
    echo "    修复: pl-phase.sh $cid start SPEC（或用 pl-state-init.sh 重新初始化）"
    ((errors++))
  elif [[ ! -s "$trace_file" ]]; then
    echo -e "  ${RED}✗${NC} trace 文件为空"
    ((errors++))
  else
    local event_count
    event_count=$(wc -l < "$trace_file" | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} trace 文件存在（$event_count 条事件）"

    # Check 3: 有 workflow.start 事件
    if jq -e 'select(.event == "workflow.start")' "$trace_file" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} trace 包含 workflow.start"
    else
      echo -e "  ${YELLOW}⚠${NC} trace 缺少 workflow.start 事件"
      ((warns++))
    fi

    # Check 3b: 有 phase.start 事件
    local phases
    phases=$(jq -r 'select(.event == "phase.start") | .data.phase_name' "$trace_file" 2>/dev/null | sort -u | tr '\n' ', ')
    if [[ -n "$phases" ]]; then
      echo -e "  ${GREEN}✓${NC} trace 包含阶段: ${phases%, }"
    else
      echo -e "  ${YELLOW}⚠${NC} trace 无任何 phase.start 事件"
      ((warns++))
    fi
  fi

  echo ""
}

# ── 执行检查 ──────────────────────────────────────────────────
if [[ -n "$TARGET" ]]; then
  check_change "$TARGET"
else
  for change_dir in "$PROJECT_ROOT"/pl/changes/*/; do
    [[ -d "$change_dir" ]] || continue
    cid=$(basename "$change_dir")
    check_change "$cid"
  done
fi

# ── 结果汇总 ──────────────────────────────────────────────────
echo "━━━ 汇总 ━━━"
if [[ $errors -gt 0 ]]; then
  echo -e "${RED}✗ $errors error(s), $warns warning(s)${NC}"
  echo ""
  echo "观测数据不完整会导致 Dashboard 无法展示、retro-miner 无法挖掘。"
  echo "请修复后再继续推进流水线。"
  exit 1
elif [[ $warns -gt 0 ]]; then
  if [[ $STRICT -eq 1 ]]; then
    echo -e "${RED}✗ $warns warning(s) in strict mode${NC}"
    exit 1
  else
    echo -e "${YELLOW}⚠ $warns warning(s)${NC}"
    exit 0
  fi
else
  echo -e "${GREEN}✓ 观测完整性检查全部通过${NC}"
  exit 0
fi
