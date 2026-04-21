#!/usr/bin/env bash
# =============================================================================
# adapter-nextjs-web verify.sh
# =============================================================================
# 快速验证：typecheck + lint + unit test（不跑 next build）。
# 对应 pl-core VERIFY 阶段的 B 门禁最小集。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ Next.js verify @ $PROJECT_ROOT"

fail=0

run() {
  local label="$1"; shift
  echo ""
  echo "━━━ $label ━━━"
  if "$@"; then
    echo "✅ $label"
  else
    echo "❌ $label"
    fail=1
  fi
}

run "typecheck" npx tsc --noEmit
run "lint"      npx next lint
if npm test --help >/dev/null 2>&1; then
  run "unit test" npm test -- --ci --passWithNoTests
else
  echo "ℹ no test script defined, skipping"
fi

echo ""
if [[ $fail -eq 0 ]]; then
  echo "✅ verify passed"
  exit 0
else
  echo "❌ verify failed"
  exit 1
fi
