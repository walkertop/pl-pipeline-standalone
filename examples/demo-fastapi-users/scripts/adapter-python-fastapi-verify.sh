#!/usr/bin/env bash
# =============================================================================
# adapter-python-fastapi verify.sh
# =============================================================================
# VERIFY 阶段最小集：ruff + mypy + pytest。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ FastAPI verify @ $PROJECT_ROOT"

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

RUNNER="python3"
if command -v uv >/dev/null 2>&1; then
  RUNNER="uv run"
fi

run "ruff"   $RUNNER ruff check .
run "mypy"   $RUNNER mypy app
run "pytest" $RUNNER pytest -q --cov=app --cov-report=term --cov-fail-under=0

echo ""
if [[ $fail -eq 0 ]]; then
  echo "✅ verify passed"
  exit 0
else
  echo "❌ verify failed"
  exit 1
fi
