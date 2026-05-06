#!/usr/bin/env bash
set -euo pipefail

cat > app/calc.py <<'PY'
def add(a, b):
    return a - b
PY
