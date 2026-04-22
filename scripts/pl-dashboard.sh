#!/usr/bin/env bash
# =============================================================================
# pl-dashboard.sh — 启动 pl-pipeline 可视化面板
# =============================================================================
#
# 职责：
#   1. 扫描 $PL_PROJECT/pipeline-output/trace/ 下所有 events.jsonl
#   2. 生成 dashboard/_data.json 索引
#   3. 起 python http server 提供静态文件
#   4. 可选自动打开浏览器
#
# 用法：
#   $ pl-dashboard.sh                  # 默认端口 8889
#   $ pl-dashboard.sh --port 9000 --open
#   $ pl-dashboard.sh --project /path/to/another-project --no-server
#
# 设计：
#   - 零构建：纯静态 HTML + CSS + vanilla JS
#   - Dashboard 源码住独立仓（$PL_HOME/dashboard/）
#   - 生成的 _data.json 同时指向宿主项目的 events.jsonl（可能在外部路径）
# =============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PL_HOME="${PL_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# ─── 参数 ────────────────────────────────────────────────────────────────────
PROJECT="${PL_PROJECT:-$PWD}"
PORT=8889
OPEN=0
NO_SERVER=0

usage() {
  sed -n '1,25p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)   PROJECT="$2"; shift 2 ;;
    --port)      PORT="$2"; shift 2 ;;
    --open)      OPEN=1; shift ;;
    --no-server) NO_SERVER=1; shift ;;
    --help|-h)   usage ;;
    *)           echo "unknown arg: $1"; usage ;;
  esac
done

PROJECT="$(cd "$PROJECT" && pwd)"
DASH_DIR="$PL_HOME/dashboard"
DATA_FILE="$DASH_DIR/_data.json"
TRACE_DIR="$PROJECT/pipeline-output/trace"

# ─── 日志颜色 ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; NC='\033[0m'

# ─── 生成 _data.json ─────────────────────────────────────────────────────────
generate_index() {
  mkdir -p "$DASH_DIR"

  if [[ ! -d "$TRACE_DIR" ]]; then
    printf "${YELLOW}⚠${NC} trace dir not found: %s\n" "$TRACE_DIR"
    printf "%s\n" '{"project":"'"$PROJECT"'","changes":[]}' > "$DATA_FILE"
    return
  fi

  python3 - "$TRACE_DIR" "$PROJECT" > "$DATA_FILE" <<'PYEOF'
import sys, os, json, glob

trace_dir = sys.argv[1]
project = sys.argv[2]

changes = []
for path in sorted(glob.glob(os.path.join(trace_dir, "*.events.jsonl"))):
    name = os.path.basename(path)
    change_id = name.replace(".events.jsonl", "")
    # dashboard 在 $PL_HOME/dashboard/，trace 在 $PROJECT/pipeline-output/trace/
    # 浏览器访问 dashboard/index.html，需要 fetch 绝对或相对路径
    # 最简单：用 file:// 绝对路径（python http server 不支持跨出 cwd）
    # 解决方案：symlink 或用软连接
    changes.append({
        "id": change_id,
        "trace_path": f"trace/{name}",  # 相对 dashboard/ 根
    })

print(json.dumps({
    "project": project,
    "trace_dir": trace_dir,
    "changes": changes,
}, indent=2, ensure_ascii=False))
PYEOF

  printf "${GREEN}✓${NC} generated index: %s (%d change(s))\n" "$DATA_FILE" \
    "$(python3 -c "import json; print(len(json.load(open('$DATA_FILE'))['changes']))")"
}

# ─── 链接 trace 目录到 dashboard 下，让 http server 可访问 ────────────────
link_trace_dir() {
  local link="$DASH_DIR/trace"
  # 删除旧 symlink
  if [[ -L "$link" ]] || [[ -e "$link" ]]; then
    rm -rf "$link"
  fi
  if [[ -d "$TRACE_DIR" ]]; then
    ln -s "$TRACE_DIR" "$link"
    printf "${BLUE}ℹ${NC} linked %s -> %s\n" "$link" "$TRACE_DIR"
  fi
}

# ─── 启动 server ─────────────────────────────────────────────────────────────
start_server() {
  cd "$DASH_DIR"
  local url="http://localhost:$PORT"
  printf "${GREEN}✓${NC} starting dashboard at %s\n" "$url"
  printf "${BLUE}ℹ${NC} serving from: %s\n" "$DASH_DIR"
  printf "${BLUE}ℹ${NC} project:      %s\n" "$PROJECT"
  printf "  (Ctrl+C to stop)\n\n"

  if [[ $OPEN -eq 1 ]]; then
    if command -v open >/dev/null 2>&1; then
      (sleep 1 && open "$url") &
    elif command -v xdg-open >/dev/null 2>&1; then
      (sleep 1 && xdg-open "$url") &
    fi
  fi

  exec python3 -m http.server "$PORT" --bind 127.0.0.1
}

# ─── main ────────────────────────────────────────────────────────────────────
generate_index
link_trace_dir

if [[ $NO_SERVER -eq 1 ]]; then
  printf "${GREEN}✓${NC} --no-server set, exiting after index generation\n"
  exit 0
fi

start_server
