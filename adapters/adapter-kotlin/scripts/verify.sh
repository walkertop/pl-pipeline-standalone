#!/usr/bin/env bash
# =============================================================================
# adapter-kotlin verify.sh
# =============================================================================
# 快速验证：compile + test（不跑完整 build），对应 pl-core VERIFY 阶段 B 门禁。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ Kotlin verify @ $PROJECT_ROOT"

fail=0
run() {
  local label="$1"; shift
  echo "• $label"
  if ! "$@"; then
    echo "  ✗ $label FAILED"
    fail=1
  fi
}

run "compile (compileKotlin)" ./gradlew compileKotlin --quiet
run "test" ./gradlew test --continue

if [[ $fail -ne 0 ]]; then
  echo "✗ Verify failed"
  exit 1
fi

echo "✅ Verify passed"
