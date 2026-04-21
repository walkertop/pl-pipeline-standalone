#!/bin/bash
#
# Pipeline Visualizer - KMV 日志可视化诊断工具（Shell 包装器）
#
# 使用方式：
#   # 从文件输入
#   ./scripts/pipeline-visualizer.sh --file /path/to/logcat.txt
#
#   # 从 stdin 管道（如直接粘贴日志）
#   pbpaste | ./scripts/pipeline-visualizer.sh
#
#   # 从 ADB logcat 实时捕获
#   ./scripts/pipeline-visualizer.sh --live --duration 30
#
#   # 自动打开报告
#   ./scripts/pipeline-visualizer.sh --file log.txt --open
#

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 检查是否有 --live 参数
if echo "$@" | grep -q -- '--live'; then
    DURATION=30
    PAGE_FILTER=""
    REMAINING_ARGS=""
    
    # 解析 live 专属参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --live) shift ;;
            --duration) DURATION="$2"; shift 2 ;;
            --page) PAGE_FILTER="$2"; shift 2 ;;
            *) REMAINING_ARGS="$REMAINING_ARGS $1"; shift ;;
        esac
    done
    
    if ! command -v adb &>/dev/null; then
        echo "❌ adb not found. Please install Android SDK platform-tools."
        exit 1
    fi
    
    TMPLOG=$(mktemp)
    trap "rm -f '$TMPLOG'" EXIT
    
    echo "🔴 Live capture from ADB logcat (${DURATION}s)..."
    timeout "$DURATION" adb logcat -v time 2>/dev/null | grep -E '\[KMV:' > "$TMPLOG" || true
    LINE_COUNT=$(wc -l < "$TMPLOG" | tr -d ' ')
    echo "✅ Captured $LINE_COUNT KMV log lines"
    
    if [[ "$LINE_COUNT" -eq 0 ]]; then
        echo "⚠️  No KMV logs captured. Make sure the app is running and producing KMV logs."
        exit 1
    fi
    
    # shellcheck disable=SC2086
    exec node "$SCRIPT_DIR/pipeline-visualizer.js" --file "$TMPLOG" $REMAINING_ARGS
else
    # 直接透传所有参数给 Node 脚本
    exec node "$SCRIPT_DIR/pipeline-visualizer.js" "$@"
fi
