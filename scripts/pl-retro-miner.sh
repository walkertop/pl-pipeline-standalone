#!/usr/bin/env bash
# =============================================================================
# pl-retro-miner.sh — 离线 trace 挖掘
# =============================================================================
#
# 职责：
#   从多个项目的 events.jsonl 中挖掘 pattern，产出候选规则 markdown 供人审批。
#
# 用法：
#   pl-retro-miner.sh --sources path1.jsonl path2.jsonl ...
#   pl-retro-miner.sh --sources ./pipeline-output/trace/ --out /tmp/retro-out
#   pl-retro-miner.sh --sources ./example1 ./example2 --kinds frequency,cooccurrence
#
# 四类挖掘：
#   frequency       事件频次排行（Pattern 1）
#   cooccurrence    事件共现分析（Pattern 2）
#   anti-pattern    反模式（gate blocked 前因）（Pattern 3）
#   outliers        异常点（耗时/频次）（Pattern 4）
#
# 输出：
#   <out>/frequency.md
#   <out>/cooccurrence.md
#   <out>/anti-patterns.md
#   <out>/outliers.md
#   <out>/summary.md
#
# 设计：
#   - 纯离线批处理，不改 trace 数据
#   - 纯统计，不调用 LLM
#   - 输出 markdown 给人读；绝不自动入库 rule
# =============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PL_HOME="${PL_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# ─── 默认参数 ────────────────────────────────────────────────────────────────
SOURCES=()
OUT_DIR="./pipeline-output/retro-candidates/$(date +%Y%m%d)"
KINDS="frequency,cooccurrence,anti-pattern,outliers"
VERBOSE=0

usage() {
  sed -n '1,35p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sources)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        SOURCES+=("$1")
        shift
      done
      ;;
    --out)       OUT_DIR="$2"; shift 2 ;;
    --kinds)     KINDS="$2"; shift 2 ;;
    --verbose|-v) VERBOSE=1; shift ;;
    --help|-h)   usage ;;
    *)           echo "unknown arg: $1"; usage ;;
  esac
done

[[ ${#SOURCES[@]} -eq 0 ]] && { echo "error: --sources required"; usage; }

mkdir -p "$OUT_DIR"

# ─── 颜色 ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; NC='\033[0m'

# ─── 1. 加载事件 ─────────────────────────────────────────────────────────────
printf "${BLUE}ℹ${NC} loading events from %d source(s)\n" "${#SOURCES[@]}"
TMP_EVENTS="$(mktemp -t pl-retro-events.XXXXXX.json)"
trap 'rm -f "$TMP_EVENTS"' EXIT

LOAD_ARGS=(
  "$SCRIPT_DIR/_lib/mine-load.py"
  --sources "${SOURCES[@]}"
  --out     "$TMP_EVENTS"
)
[[ $VERBOSE -eq 1 ]] && LOAD_ARGS+=(--verbose)
python3 "${LOAD_ARGS[@]}"

EVENT_COUNT=$(python3 -c "import json; print(len(json.load(open('$TMP_EVENTS'))))")
printf "${GREEN}✓${NC} loaded %s events\n" "$EVENT_COUNT"

# ─── 2. 逐 kind 挖掘 ─────────────────────────────────────────────────────────
IFS=',' read -ra KIND_LIST <<< "$KINDS"

for k in "${KIND_LIST[@]}"; do
  case "$k" in
    frequency)
      printf "\n${BLUE}ℹ${NC} mining frequency patterns...\n"
      python3 "$SCRIPT_DIR/_lib/mine-frequency.py" --events "$TMP_EVENTS" --out "$OUT_DIR/frequency.md"
      ;;
    cooccurrence)
      printf "\n${BLUE}ℹ${NC} mining co-occurrence patterns...\n"
      python3 "$SCRIPT_DIR/_lib/mine-cooccurrence.py" --events "$TMP_EVENTS" --out "$OUT_DIR/co-occurrence.md"
      ;;
    anti-pattern)
      printf "\n${BLUE}ℹ${NC} mining anti-patterns...\n"
      python3 "$SCRIPT_DIR/_lib/mine-anti-pattern.py" --events "$TMP_EVENTS" --out "$OUT_DIR/anti-patterns.md"
      ;;
    outliers)
      printf "\n${BLUE}ℹ${NC} mining outliers...\n"
      python3 "$SCRIPT_DIR/_lib/mine-outliers.py" --events "$TMP_EVENTS" --out "$OUT_DIR/outliers.md"
      ;;
    *)
      printf "${YELLOW}⚠${NC} unknown kind: %s\n" "$k"
      ;;
  esac
done

# ─── 3. 生成 summary ─────────────────────────────────────────────────────────
cat > "$OUT_DIR/summary.md" <<EOF
# Retro-miner Summary

- date: $(date +%Y-%m-%d)
- sources: ${#SOURCES[@]} file(s)/dir(s)
- events scanned: $EVENT_COUNT
- kinds mined: $KINDS

## Reports

$(ls "$OUT_DIR" | grep -v summary.md | sed 's/^/- /')

---

**下一步**：人 review 各报告，把**高置信度 + 频次充足**的 pattern 整理成正式
规则，写入 \`.codebuddy/rules/\` 或 \`assets/pl/observe-rules.yaml\`。

**提醒**：本报告只是**候选**，retro-miner 绝不自动入库规则。
EOF

printf "\n${GREEN}✓${NC} retro-miner done. reports at: %s\n" "$OUT_DIR"
ls "$OUT_DIR" | sed "s|^|  $OUT_DIR/|"
