#!/usr/bin/env bash
# tests/cli/test-pl-detect.sh — pl detect / pl new --here 默认 detect 行为
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../_lib/runner.sh
source "$REPO_ROOT/tests/_lib/runner.sh"

export PL_HOME="$REPO_ROOT"
export PATH="$REPO_ROOT/bin:$PATH"

# 创建一个临时 fixture（裸目录 + 简单 frontend skeleton）
FIX="$(mktemp -d -t pl-detect-test-XXXXXX)"
trap 'rm -rf "$FIX"' EXIT

mkdir -p "$FIX/empty-project"
mkdir -p "$FIX/with-fastapi/api"
cat > "$FIX/with-fastapi/api/pyproject.toml" <<'PY'
[project]
name = "myapi"
dependencies = ["fastapi>=0.100"]
PY

mkdir -p "$FIX/with-frontend-skeleton/apps/web"
mkdir -p "$FIX/with-frontend-skeleton/packages/ui"

mkdir -p "$FIX/with-openapi/contracts/openapi/v1"
echo "openapi: 3.0.0" > "$FIX/with-openapi/contracts/openapi/v1/openapi.yaml"

# 已接入 pl 的 fixture
mkdir -p "$FIX/already-pl/pl/changes/foo"
echo "version: pl@v1.1" > "$FIX/already-pl/pl/config.yaml"

# ---------------------------------------------------------------------------
tc_suite "pl detect — 基础元命令"
# ---------------------------------------------------------------------------
tc_case "pl detect --help 退出 0"
tc_assert_pass "pl detect --help" pl detect --help

tc_case "pl scan 是 detect 的别名"
tc_assert_pass "pl scan --help" pl scan --help

tc_case "pl detect 在空目录上不崩"
tc_assert_pass "pl detect on empty" pl detect "$FIX/empty-project"

tc_case "pl detect 在不存在目录上 exit 2"
tc_assert_exit 2 "pl detect bad-dir" pl detect "$FIX/does-not-exist"

# ---------------------------------------------------------------------------
tc_suite "pl detect — 检测识别准确性"
# ---------------------------------------------------------------------------
tc_case "FastAPI 项目识别为 high confidence"
tc_assert_contains "FastAPI" "pl detect with-fastapi" pl detect "$FIX/with-fastapi"

tc_case "FastAPI 项目建议装 adapter-python-fastapi"
tc_assert_contains "adapter-python-fastapi" "pl detect with-fastapi" pl detect "$FIX/with-fastapi"

tc_case "Frontend 骨架（apps+packages 但无 package.json）识别"
tc_assert_contains "monorepo 骨架" "pl detect with-frontend-skeleton" pl detect "$FIX/with-frontend-skeleton"

tc_case "OpenAPI 文件被识别为 CDC 锚点"
tc_assert_contains "CDC 锚点" "pl detect with-openapi" pl detect "$FIX/with-openapi"

tc_case "已接入 pl 的项目识别"
tc_assert_contains "已接入 pl-pipeline" "pl detect already-pl" pl detect "$FIX/already-pl"

# ---------------------------------------------------------------------------
tc_suite "pl detect --json"
# ---------------------------------------------------------------------------
tc_case "JSON 输出是 valid JSON"
JSON_OUT=$(pl detect "$FIX/with-fastapi" --json 2>&1)
if echo "$JSON_OUT" | python3 -c "import json,sys; json.load(sys.stdin)" >/dev/null 2>&1; then
  tc_ok
else
  tc_fail "invalid JSON: $JSON_OUT"
fi

tc_case "JSON 包含 detections 数组"
tc_assert_contains '"detections"' "json detections key" pl detect "$FIX/with-fastapi" --json

tc_case "JSON detection 包含 module/stack/confidence/evidence/suggestion 字段"
JSON_OUT=$(pl detect "$FIX/with-fastapi" --json 2>&1)
if echo "$JSON_OUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ds = d['detections']
assert len(ds) > 0
assert all(k in ds[0] for k in ['module','stack','confidence','evidence','suggestion_id','suggestion'])
" >/dev/null 2>&1; then
  tc_ok
else
  tc_fail "missing fields"
fi

# ---------------------------------------------------------------------------
tc_suite "pl detect — bash 3.2 兼容"
# ---------------------------------------------------------------------------
tc_case "stdout 不应含 'unbound variable'"
tc_assert_not_contains "unbound variable" "pl detect on fixture" pl detect "$FIX/with-fastapi"

tc_case "stdout 不应含 'declare: invalid option'"
tc_assert_not_contains "declare: invalid" "pl detect on fixture" pl detect "$FIX/with-fastapi"

tc_case "在 demo-monorepo-trio 上跑通"
tc_assert_pass "pl detect demo" pl detect "$REPO_ROOT/examples/demo-monorepo-trio"

# ---------------------------------------------------------------------------
tc_suite "pl new --here 无 --stack：应跑 detect 而非装文件"
# ---------------------------------------------------------------------------
mkdir -p "$FIX/dryrun-target/api"
cat > "$FIX/dryrun-target/api/pyproject.toml" <<'PY'
[project]
name = "x"
dependencies = ["fastapi"]
PY

tc_case "pl new --here 无 --stack 不应创建 pl/config.yaml"
( cd "$FIX/dryrun-target" && pl new myproj --here ) >/dev/null 2>&1 || true
if [[ -f "$FIX/dryrun-target/pl/config.yaml" ]]; then
  tc_fail "pl/config.yaml was created (should be dry-run)"
else
  tc_ok
fi

tc_case "pl new --here 无 --stack 输出包含 detect 建议"
OUT=$(cd "$FIX/dryrun-target" && pl new myproj --here 2>&1)
if [[ "$OUT" == *"FastAPI"* && "$OUT" == *"--stack"* ]]; then
  tc_ok
else
  tc_fail "expected detect output + stack hint, got: $OUT"
fi

tc_case "pl new --here --stack bare 仍然装文件（不破现有行为）"
mkdir -p "$FIX/explicit-bare"
( cd "$FIX/explicit-bare" && pl new myproj --here --stack bare --no-init --no-git ) >/dev/null 2>&1 || true
if [[ -f "$FIX/explicit-bare/pl/config.yaml" ]]; then
  tc_ok
else
  tc_fail "pl/config.yaml not created with explicit --stack bare"
fi

# ---------------------------------------------------------------------------
tc_suite "pl help 暴露 detect"
# ---------------------------------------------------------------------------
tc_case "pl help 提到 detect"
tc_assert_contains "detect" "pl help" pl help

tc_summary
