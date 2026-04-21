#!/usr/bin/env bash
# =============================================================================
# adapter-python-fastapi lint.sh
# =============================================================================
# 最快的门禁：ruff check + ruff format --check。适合 pre-commit hook。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ FastAPI lint @ $PROJECT_ROOT"

RUNNER="python3 -m"
if command -v uv >/dev/null 2>&1; then
  RUNNER="uv run"
fi

$RUNNER ruff check .
$RUNNER ruff format --check .

echo "✅ lint passed"
