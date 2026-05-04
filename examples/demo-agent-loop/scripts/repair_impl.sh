#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PL_REPAIR_CONTEXT:-}" || ! -f "$PL_REPAIR_CONTEXT" ]]; then
  echo "missing PL_REPAIR_CONTEXT" >&2
  exit 1
fi

grep -E "Gate output|FAILED|AssertionError" "$PL_REPAIR_CONTEXT" >/dev/null

cat > app/calc.py <<'PY'
def add(a, b):
    return a + b
PY
