#!/usr/bin/env bash
# =============================================================================
# pl-observe.sh — 文件系统观察器（fs watcher 层）
# =============================================================================
#
# 职责：
#   调用 _lib/observe-fs.py 扫描项目文件变化，产出 artifact.* 事件到统一
#   trace 流。不侵入任何 agent / LLM / IDE。
#
# 用法：
#   $ pl-observe.sh --change add-todo-list
#   $ pl-observe.sh --change add-todo-list --phase PLAN
#   $ pl-observe.sh --change add-todo-list --loop --interval 2
#   $ pl-observe.sh --change add-todo-list --watch "app/**" ".codebuddy/**"
#
# 模式：
#   默认 --once 扫一次退出（适合嵌入 pl-runner / CI）
#   --loop 循环扫描（daemon 化，开发时保持后台）
#
# 输出：
#   $PL_PROJECT/pipeline-output/trace/<change>.events.jsonl
#   $PL_PROJECT/pipeline-output/observe/snapshot.json
# =============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PL_HOME="${PL_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# ─── 参数解析 ────────────────────────────────────────────────────────────────
CHANGE=""
PHASE="IMPLEMENT"
MODE="once"
INTERVAL=2
TRACE_ID=""
WATCH_GLOBS=()
VERBOSE=0

usage() {
  sed -n '1,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change)   CHANGE="$2"; shift 2 ;;
    --phase)    PHASE="$2"; shift 2 ;;
    --trace-id) TRACE_ID="$2"; shift 2 ;;
    --once)     MODE="once"; shift ;;
    --loop)     MODE="loop"; shift ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --watch)    shift; while [[ $# -gt 0 && "$1" != --* ]]; do WATCH_GLOBS+=("$1"); shift; done ;;
    --verbose|-v) VERBOSE=1; shift ;;
    --help|-h)  usage ;;
    *)          echo "unknown arg: $1"; usage ;;
  esac
done

[[ -z "$CHANGE" ]] && { echo "error: --change required"; usage; }

PL_PROJECT="${PL_PROJECT:-$PWD}"

# ─── 组装 python 命令 ────────────────────────────────────────────────────────
PY_ARGS=(
  "$SCRIPT_DIR/_lib/observe-fs.py"
  --project "$PL_PROJECT"
  --change  "$CHANGE"
  --phase   "$PHASE"
)
[[ -n "$TRACE_ID" ]] && PY_ARGS+=(--trace-id "$TRACE_ID")
[[ "$MODE" == "loop" ]] && PY_ARGS+=(--loop --interval "$INTERVAL")
[[ $VERBOSE -eq 1 ]] && PY_ARGS+=(--verbose)

for g in "${WATCH_GLOBS[@]}"; do
  PY_ARGS+=(--watch-glob "$g")
done

# ─── 日志（绿色图标） ────────────────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

if [[ "$MODE" == "loop" ]]; then
  printf "${BLUE}ℹ${NC} observing %s (loop, interval=%ss)  change=%s  phase=%s\n" \
    "$PL_PROJECT" "$INTERVAL" "$CHANGE" "$PHASE"
else
  printf "${BLUE}ℹ${NC} scanning %s  change=%s  phase=%s\n" "$PL_PROJECT" "$CHANGE" "$PHASE"
fi

exec python3 "${PY_ARGS[@]}"
