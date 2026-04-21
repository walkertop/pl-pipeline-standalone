#!/usr/bin/env bash
# =============================================================================
# should-build.sh — 变更感知自动构建触发器
# =============================================================================
#
# 遵循规则: BUILD-001 (构建验证协议)
#
# 功能:
#   分析当前 git 工作区的变更，根据多维启发式规则判断是否应触发构建。
#   Agent 在 coding 过程中周期性调用此脚本，实现"变更积累到一定程度自动 build"。
#
# 用法:
#   ./scripts/should-build.sh              # 检查是否需要 build (退出码: 0=需要, 1=不需要)
#   ./scripts/should-build.sh --json       # 输出 JSON 格式详情
#   ./scripts/should-build.sh --verbose    # 详细输出每条规则的评估结果
#   ./scripts/should-build.sh --mark       # 标记当前时间为"最近一次 build"
#   ./scripts/should-build.sh --status     # 查看距上次 build 的变更统计
#   ./scripts/should-build.sh --reset      # 重置所有标记
#
# 退出码:
#   0 = 建议立即构建
#   1 = 暂不需要构建
#   2 = 参数错误
#
# 环境变量覆盖（可在 .env 或 export 中设置）:
#   SHOULD_BUILD_LINES=100       # 变更行数阈值
#   SHOULD_BUILD_FILES=5         # 变更文件数阈值
#   SHOULD_BUILD_PAGES=2         # 跨页面数阈值
#   SHOULD_BUILD_NEW_FILES=3     # 新文件数阈值
#   SHOULD_BUILD_MINUTES=30      # 时间兜底阈值（分钟）
#
# =============================================================================

set -euo pipefail

# ---- 颜色定义 ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ---- 配置 -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_MARKER="$PROJECT_ROOT/.codebuddy/.last-build-check"
BUILD_SNAPSHOT="$PROJECT_ROOT/.codebuddy/.last-build-snapshot"

# 阈值（可通过环境变量覆盖）
THRESHOLD_LINES="${SHOULD_BUILD_LINES:-100}"
THRESHOLD_FILES="${SHOULD_BUILD_FILES:-5}"
THRESHOLD_PAGES="${SHOULD_BUILD_PAGES:-2}"
THRESHOLD_NEW_FILES="${SHOULD_BUILD_NEW_FILES:-3}"
THRESHOLD_MINUTES="${SHOULD_BUILD_MINUTES:-30}"

# ---- 参数解析 ----------------------------------------------------------------
MODE="check"
VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --mark)    MODE="mark"; shift ;;
    --status)  MODE="status"; shift ;;
    --reset)   MODE="reset"; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --json)    JSON_OUTPUT=true; shift ;;
    -h|--help)
      head -30 "$0" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *)
      echo "未知参数: $1" >&2
      exit 2 ;;
  esac
done

cd "$PROJECT_ROOT"

# ---- 工具函数 ----------------------------------------------------------------
log_verbose() {
  $VERBOSE && echo -e "$*" || true
}

ensure_marker_dir() {
  mkdir -p "$(dirname "$BUILD_MARKER")"
}

# ---- 模式: 标记最近一次 build -----------------------------------------------
if [[ "$MODE" == "mark" ]]; then
  ensure_marker_dir
  date +%s > "$BUILD_MARKER"
  # 保存当前 git diff 快照（用于下次对比增量）
  git diff --stat -- '*.kt' > "$BUILD_SNAPSHOT" 2>/dev/null || true
  echo -e "${GREEN}✅${NC} 已标记当前时间为最近一次构建检查"
  exit 0
fi

# ---- 模式: 重置标记 ---------------------------------------------------------
if [[ "$MODE" == "reset" ]]; then
  rm -f "$BUILD_MARKER" "$BUILD_SNAPSHOT"
  echo -e "${GREEN}✅${NC} 已重置构建标记"
  exit 0
fi

# ---- 收集变更数据 -----------------------------------------------------------

# 1. 变更行数（unstaged + staged）
CHANGED_LINES_ADD=$(git diff --numstat -- '*.kt' 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
CHANGED_LINES_DEL=$(git diff --numstat -- '*.kt' 2>/dev/null | awk '{sum+=$2} END{print sum+0}')
STAGED_LINES_ADD=$(git diff --cached --numstat -- '*.kt' 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
STAGED_LINES_DEL=$(git diff --cached --numstat -- '*.kt' 2>/dev/null | awk '{sum+=$2} END{print sum+0}')
TOTAL_LINES=$(( CHANGED_LINES_ADD + CHANGED_LINES_DEL + STAGED_LINES_ADD + STAGED_LINES_DEL ))

# 2. 变更的 .kt 文件数
CHANGED_KT_FILES=$(
  {
    git diff --name-only -- '*.kt' 2>/dev/null
    git diff --cached --name-only -- '*.kt' 2>/dev/null
  } | sort -u | wc -l | tr -d ' '
)

# 3. 变更涉及的 page/ 目录数
CHANGED_PAGES=$(
  {
    git diff --name-only -- '*.kt' 2>/dev/null
    git diff --cached --name-only -- '*.kt' 2>/dev/null
  } | grep '/page/' | sed 's|.*/page/\([^/]*\)/.*|\1|' | sort -u | wc -l | tr -d ' '
)

# 4. 关键架构文件被改动
CRITICAL_PATTERNS="Module\.kt|DataStore\.kt|ViewModel\.kt|ViewModels\.kt|DataManager\.kt|PageEntry\.kt"
CRITICAL_FILES_CHANGED=$(
  {
    git diff --name-only -- '*.kt' 2>/dev/null
    git diff --cached --name-only -- '*.kt' 2>/dev/null
  } | grep -cE "$CRITICAL_PATTERNS" || echo 0
)

# 5. 新创建的 .kt 文件数（untracked）
NEW_KT_FILES=$(git ls-files --others --exclude-standard -- '*.kt' 2>/dev/null | wc -l | tr -d ' ')

# 6. 距离上次 build 的分钟数
if [[ -f "$BUILD_MARKER" ]]; then
  LAST_BUILD_TS=$(cat "$BUILD_MARKER")
  NOW_TS=$(date +%s)
  MINUTES_SINCE_BUILD=$(( (NOW_TS - LAST_BUILD_TS) / 60 ))
else
  MINUTES_SINCE_BUILD=999  # 从未 build 过
fi

# ---- 模式: 状态查看 ---------------------------------------------------------
if [[ "$MODE" == "status" ]]; then
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo -e "${BOLD}📊 构建触发状态${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════${NC}"
  echo ""
  echo -e "  变更行数:       ${BOLD}${TOTAL_LINES}${NC} 行 (阈值: ${THRESHOLD_LINES})"
  echo -e "  变更文件:       ${BOLD}${CHANGED_KT_FILES}${NC} 个 .kt 文件 (阈值: ${THRESHOLD_FILES})"
  echo -e "  跨页面改动:     ${BOLD}${CHANGED_PAGES}${NC} 个页面 (阈值: ${THRESHOLD_PAGES})"
  echo -e "  关键文件改动:   ${BOLD}${CRITICAL_FILES_CHANGED}${NC} 个"
  echo -e "  新建文件:       ${BOLD}${NEW_KT_FILES}${NC} 个 (阈值: ${THRESHOLD_NEW_FILES})"
  echo -e "  距上次构建:     ${BOLD}${MINUTES_SINCE_BUILD}${NC} 分钟 (阈值: ${THRESHOLD_MINUTES})"
  echo ""

  if [[ -f "$BUILD_MARKER" ]]; then
    echo -e "  上次构建时间:   $(date -r "$BUILD_MARKER" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$(cat "$BUILD_MARKER")" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo '未知')"
  else
    echo -e "  上次构建时间:   ${DIM}从未标记${NC}"
  fi
  echo ""
  exit 0
fi

# ---- 模式: 检查是否应该构建 -------------------------------------------------

# 评估每条规则
TRIGGERS=()
SHOULD_BUILD=false

# 规则 1: 变更行数
if [[ $TOTAL_LINES -ge $THRESHOLD_LINES ]]; then
  TRIGGERS+=("LINES: ${TOTAL_LINES} 行变更 (≥${THRESHOLD_LINES})")
  SHOULD_BUILD=true
fi
log_verbose "  规则1 [行数]:     ${TOTAL_LINES}/${THRESHOLD_LINES} $(${SHOULD_BUILD} && echo '🔴 触发' || echo '🟢 通过')"

# 规则 2: 变更文件数
FILE_TRIGGER=false
if [[ $CHANGED_KT_FILES -ge $THRESHOLD_FILES ]]; then
  TRIGGERS+=("FILES: ${CHANGED_KT_FILES} 个文件变更 (≥${THRESHOLD_FILES})")
  SHOULD_BUILD=true
  FILE_TRIGGER=true
fi
log_verbose "  规则2 [文件数]:   ${CHANGED_KT_FILES}/${THRESHOLD_FILES} $(${FILE_TRIGGER} && echo '🔴 触发' || echo '🟢 通过')"

# 规则 3: 跨页面改动
PAGE_TRIGGER=false
if [[ $CHANGED_PAGES -ge $THRESHOLD_PAGES ]]; then
  TRIGGERS+=("PAGES: ${CHANGED_PAGES} 个页面有改动 (≥${THRESHOLD_PAGES})")
  SHOULD_BUILD=true
  PAGE_TRIGGER=true
fi
log_verbose "  规则3 [跨页面]:   ${CHANGED_PAGES}/${THRESHOLD_PAGES} $(${PAGE_TRIGGER} && echo '🔴 触发' || echo '🟢 通过')"

# 规则 4: 关键架构文件改动
CRITICAL_TRIGGER=false
if [[ $CRITICAL_FILES_CHANGED -gt 0 ]]; then
  TRIGGERS+=("CRITICAL: ${CRITICAL_FILES_CHANGED} 个核心架构文件被修改")
  SHOULD_BUILD=true
  CRITICAL_TRIGGER=true
fi
log_verbose "  规则4 [关键文件]: ${CRITICAL_FILES_CHANGED} $(${CRITICAL_TRIGGER} && echo '🔴 触发' || echo '🟢 通过')"

# 规则 5: 新文件创建
NEWFILE_TRIGGER=false
if [[ $NEW_KT_FILES -ge $THRESHOLD_NEW_FILES ]]; then
  TRIGGERS+=("NEW_FILES: ${NEW_KT_FILES} 个新建文件 (≥${THRESHOLD_NEW_FILES})")
  SHOULD_BUILD=true
  NEWFILE_TRIGGER=true
fi
log_verbose "  规则5 [新文件]:   ${NEW_KT_FILES}/${THRESHOLD_NEW_FILES} $(${NEWFILE_TRIGGER} && echo '🔴 触发' || echo '🟢 通过')"

# 规则 6: 时间兜底（只在有改动时触发）
TIME_TRIGGER=false
HAS_ANY_CHANGES=$(( TOTAL_LINES + NEW_KT_FILES ))
if [[ $MINUTES_SINCE_BUILD -ge $THRESHOLD_MINUTES ]] && [[ $HAS_ANY_CHANGES -gt 0 ]]; then
  TRIGGERS+=("TIME: 距上次构建 ${MINUTES_SINCE_BUILD} 分钟 (≥${THRESHOLD_MINUTES}) 且有未验证改动")
  SHOULD_BUILD=true
  TIME_TRIGGER=true
fi
log_verbose "  规则6 [时间]:     ${MINUTES_SINCE_BUILD}min/${THRESHOLD_MINUTES}min $(${TIME_TRIGGER} && echo '🔴 触发' || echo '🟢 通过')"

# ---- JSON 输出 ---------------------------------------------------------------
if $JSON_OUTPUT; then
  TRIGGERS_JSON="[]"
  if [[ ${#TRIGGERS[@]} -gt 0 ]]; then
    TRIGGERS_JSON=$(printf '%s\n' "${TRIGGERS[@]}" | jq -R . | jq -s .)
  fi

  jq -n \
    --argjson shouldBuild "$($SHOULD_BUILD && echo true || echo false)" \
    --argjson totalLines "$TOTAL_LINES" \
    --argjson changedFiles "$CHANGED_KT_FILES" \
    --argjson changedPages "$CHANGED_PAGES" \
    --argjson criticalFiles "$CRITICAL_FILES_CHANGED" \
    --argjson newFiles "$NEW_KT_FILES" \
    --argjson minutesSinceBuild "$MINUTES_SINCE_BUILD" \
    --argjson triggers "$TRIGGERS_JSON" \
    '{
      shouldBuild: $shouldBuild,
      metrics: {
        totalLines: $totalLines,
        changedFiles: $changedFiles,
        changedPages: $changedPages,
        criticalFiles: $criticalFiles,
        newFiles: $newFiles,
        minutesSinceBuild: $minutesSinceBuild
      },
      triggers: $triggers
    }'
  $SHOULD_BUILD && exit 0 || exit 1
fi

# ---- 人类可读输出 ------------------------------------------------------------
if $SHOULD_BUILD; then
  echo -e "${YELLOW}⚠️  建议立即构建${NC}"
  echo ""
  echo -e "触发原因:"
  for t in "${TRIGGERS[@]}"; do
    echo -e "  ${RED}▸${NC} $t"
  done
  echo ""
  echo -e "${DIM}运行: ./gradlew :kuikly-dynamic-apk-builder:packSplitApkRelease${NC}"
  echo -e "${DIM}完成后: ./scripts/should-build.sh --mark${NC}"
  exit 0
else
  if [[ $HAS_ANY_CHANGES -eq 0 ]]; then
    echo -e "${GREEN}✅ 暂无 .kt 文件变更，无需构建${NC}"
  else
    echo -e "${GREEN}✅ 变更量未达阈值，暂不需要构建${NC}"
    echo -e "${DIM}   (${TOTAL_LINES} 行 / ${CHANGED_KT_FILES} 文件 / ${CHANGED_PAGES} 页面)${NC}"
  fi
  exit 1
fi
