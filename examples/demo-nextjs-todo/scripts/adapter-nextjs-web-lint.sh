#!/usr/bin/env bash
# =============================================================================
# adapter-nextjs-web lint.sh
# =============================================================================
# 只跑 lint + format check，最快的"门禁"。适合 Git pre-commit hook。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ Next.js lint @ $PROJECT_ROOT"

npx next lint

if npx --no prettier --version >/dev/null 2>&1; then
  echo "• prettier check"
  npx prettier --check "**/*.{ts,tsx,js,jsx,json,md}" || {
    echo "ℹ prettier 有未格式化的文件，运行: npx prettier --write ."
    exit 1
  }
fi

echo "✅ lint passed"
