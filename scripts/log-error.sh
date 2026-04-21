#!/bin/bash

# 错误快速记录工具
# 用法: ./scripts/log-error.sh CE-006 "文件名" "问题" "原因" "解决"

TYPE=$1
FILE=$2
PROBLEM=$3
REASON=$4
SOLUTION=$5
DATE=$(date +%Y-%m-%d)

if [ -z "$TYPE" ] || [ -z "$FILE" ] || [ -z "$PROBLEM" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 错误记录工具"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "用法:"
    echo "  ./scripts/log-error.sh [错误编号] [文件名] [问题] [原因] [解决]"
    echo ""
    echo "示例:"
    echo "  ./scripts/log-error.sh CE-006 \\"
    echo "      \"PropCard.kt\" \\"
    echo "      \"Unresolved reference\" \\"
    echo "      \"导入缺失\" \\"
    echo "      \"添加 import\""
    echo ""
    echo "错误类型:"
    echo "  CE - 编译错误"
    echo "  RE - 运行时错误"
    echo "  LE - 逻辑错误"
    echo "  IE - 集成错误"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

# 检查是否已存在
if grep -q "\\[$TYPE\\]" .errorlog 2>/dev/null; then
    echo "⚠️  错误 $TYPE 已存在，跳过记录"
    exit 0
fi

# 追加到 .errorlog
echo "" >> .errorlog
echo "#### [$TYPE] $FILE" >> .errorlog
echo '```' >> .errorlog
echo "问题: $PROBLEM" >> .errorlog
[ -n "$REASON" ] && echo "原因: $REASON" >> .errorlog
[ -n "$SOLUTION" ] && echo "解决: $SOLUTION" >> .errorlog
echo '```' >> .errorlog

echo ""
echo "✅ 错误已记录: $TYPE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tail -8 .errorlog
