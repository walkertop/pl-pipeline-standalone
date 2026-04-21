#!/usr/bin/env bash
# =============================================================================
# adapter-nextjs-web build.sh
# =============================================================================
# 构建 Next.js 项目的生产产物。
# 被注入为宿主项目的 scripts/adapter-nextjs-web-build.sh
#
# 约束：必须在宿主项目根目录执行。
# 环境变量：
#   NEXT_BUILD_ANALYZE=1   启用 bundle analyzer
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# pl-core 注入后位于 scripts/ 下，宿主根为上一级
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ Next.js build @ $PROJECT_ROOT"

if [[ ! -f package.json ]]; then
  echo "✗ package.json not found"
  exit 1
fi

# 1) type check（快，先跑）
echo "• Step 1/3 — typecheck"
npx tsc --noEmit

# 2) lint
echo "• Step 2/3 — lint"
npx next lint

# 3) build
echo "• Step 3/3 — next build"
if [[ "${NEXT_BUILD_ANALYZE:-0}" == "1" ]]; then
  ANALYZE=true npm run build
else
  npm run build
fi

echo "✅ Build succeeded"
