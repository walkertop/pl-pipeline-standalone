#!/usr/bin/env bash
# =============================================================================
# adapter-python-fastapi build.sh
# =============================================================================
# 构建 = 同步依赖 + 编译字节码 + 校验 OpenAPI 可导出。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ FastAPI build @ $PROJECT_ROOT"

if [[ ! -f pyproject.toml ]]; then
  echo "✗ pyproject.toml not found"
  exit 1
fi

# 1) 依赖同步
echo "• Step 1/3 — uv sync"
if command -v uv >/dev/null 2>&1; then
  uv sync --frozen || uv sync
else
  echo "ℹ uv not installed; falling back to pip install -e ."
  python3 -m pip install -e .
fi

# 2) 字节码编译
echo "• Step 2/3 — compileall"
if command -v uv >/dev/null 2>&1; then
  uv run python -m compileall -q app
else
  python3 -m compileall -q app
fi

# 3) OpenAPI 可导出
echo "• Step 3/3 — OpenAPI export check"
if command -v uv >/dev/null 2>&1; then
  uv run python -c "from app.main import app; import json; json.dumps(app.openapi())"
else
  python3 -c "from app.main import app; import json; json.dumps(app.openapi())"
fi

echo "✅ Build succeeded"
