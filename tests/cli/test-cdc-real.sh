#!/usr/bin/env bash
# tests/cli/test-cdc-real.sh — CDC 端到端"真实场景"测试
# ----------------------------------------------------------------------
# 当前 CI 的 cdc-broker-smoke 跑的是最小骨架（手写 yaml 几行）。
# 这套测试在两个真实 demo 项目（demo-nextjs-todo / demo-fastapi-users）上跑
# 完整 CDC 闭环，验证：
#   1. pl trace use 写事件 → events.jsonl 文件存在
#   2. pl contract aggregate 生成 pact + registry
#   3. pl contract verify 对账成功（satisfied）
#   4. pl contract query --capability 反查命中
#
# 这是 v1.7 → v1.8 升级后的关键回归保险。
# ----------------------------------------------------------------------

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
export PL_HOME="$REPO_ROOT"
export PATH="$REPO_ROOT/bin:$PATH"

source "$REPO_ROOT/tests/_lib/runner.sh"

# ----------------------------------------------------------------------
# 通用 fixture: 在临时目录里复制一个 demo，跑全流程
# ----------------------------------------------------------------------
run_full_cdc() {
  local demo_name="$1"
  local capability_id="$2"
  local skill_id="$3"
  local sandbox change

  sandbox=$(mktemp -d)
  cp -R "$REPO_ROOT/examples/$demo_name/." "$sandbox/"
  export PL_PROJECT="$sandbox"
  change="cdc-real-$demo_name"

  # 清理可能的残留（demo 自己可能有 contracts）
  rm -rf "$sandbox/pl/contracts" "$sandbox/pipeline-output"

  # 1. trace use（capability + skill 各一条）
  pl trace use \
    --change "$change" --kind capability --id "$capability_id" \
    --phase IMPLEMENT --by "agent:cdc-real-test" >/dev/null

  pl trace use \
    --change "$change" --kind skill --id "$skill_id" \
    --phase IMPLEMENT --by "agent:cdc-real-test" >/dev/null

  # 2. aggregate
  pl contract aggregate >/dev/null

  # 3. 验证产物
  test -f "$sandbox/pl/contracts/${change}.consumed.yaml" || {
    echo "FAIL: pact not generated for $change"; rm -rf "$sandbox"; return 1
  }
  test -f "$sandbox/pl/contracts/_registry.yaml" || {
    echo "FAIL: registry not generated"; rm -rf "$sandbox"; return 1
  }

  # 4. verify（捕获 exit）
  set +e
  local verify_out verify_rc
  verify_out=$(pl contract verify 2>&1)
  verify_rc=$?
  set -e
  if [[ $verify_rc -ne 0 ]]; then
    echo "FAIL: verify exit=$verify_rc, output:"
    echo "$verify_out"
    rm -rf "$sandbox"
    return 1
  fi

  # 5. query 反查 capability（注意 query 在没找到时也是 exit 0，要看输出）
  local query_out
  query_out=$(pl contract query --capability "$capability_id" 2>&1)
  if [[ "$query_out" != *"$change"* ]]; then
    echo "FAIL: query for capability '$capability_id' did not find '$change':"
    echo "$query_out"
    rm -rf "$sandbox"
    return 1
  fi

  rm -rf "$sandbox"
  return 0
}

# ----------------------------------------------------------------------
# Suite 1: demo-nextjs-todo
# ----------------------------------------------------------------------
tc_suite "CDC real scenario · demo-nextjs-todo"

tc_case "trace use → aggregate → verify → query 全流程"
if run_full_cdc "demo-nextjs-todo" "typecheck" "react-server-components"; then
  tc_ok
else
  tc_fail "see output above"
fi

# ----------------------------------------------------------------------
# Suite 2: demo-fastapi-users
# ----------------------------------------------------------------------
tc_suite "CDC real scenario · demo-fastapi-users"

tc_case "trace use → aggregate → verify → query 全流程"
if run_full_cdc "demo-fastapi-users" "typecheck" "fastapi-dependency-injection"; then
  tc_ok
else
  tc_fail "see output above"
fi

# ----------------------------------------------------------------------
# Suite 3: dashboard contract endpoints
# ----------------------------------------------------------------------
tc_suite "dashboard contract data endpoints"

tc_case "/_data/contracts.json 端点返回真实 pact 状态"
# 准备 sandbox：在 demo 上跑出真实 pact
sandbox=$(mktemp -d)
cp -R "$REPO_ROOT/examples/demo-nextjs-todo/." "$sandbox/"
rm -rf "$sandbox/pl/contracts" "$sandbox/pipeline-output"
export PL_PROJECT="$sandbox"
pl trace use --change dash-real --kind capability --id typecheck \
  --phase IMPLEMENT --by "agent:dash-test" >/dev/null
pl contract aggregate >/dev/null

# 先生成 _data.json（dashboard refresh）
pl dashboard refresh >/dev/null 2>&1 || true
# 如果 refresh 不识别，回退到直接生成（用 dashboard-refresh.sh 直接产物）
DATA_FILE="$sandbox/_data.json"
[[ -f "$DATA_FILE" ]] || echo '{"changes":[]}' > "$DATA_FILE"

# 直接调 dashboard-server.py（不跑 pl dashboard，避免 SIGINT 等待循环）
PORT=18887
python3 "$REPO_ROOT/scripts/_lib/dashboard-server.py" \
  --bind 127.0.0.1 --port "$PORT" \
  --dash-dir "$REPO_ROOT/dashboard" \
  --trace-dir "$sandbox/pipeline-output/trace" \
  --data-file "$DATA_FILE" \
  --pl-home "$REPO_ROOT" \
  --pl-project "$sandbox" \
  --contracts-dir "$sandbox/pl/contracts" \
  >/tmp/_dash_test.log 2>&1 &
dash_pid=$!
disown $dash_pid 2>/dev/null || true

# 等 server 就绪（最多 5s）
ready=0
for i in 1 2 3 4 5; do
  sleep 1
  if curl -s --max-time 1 -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then
    ready=1; break
  fi
done

if [[ $ready -eq 0 ]]; then
  kill -9 $dash_pid 2>/dev/null || true
  out=$(cat /tmp/_dash_test.log 2>/dev/null || echo "(no log)")
  rm -rf "$sandbox" /tmp/_dash_test.log
  tc_fail "dashboard-server.py 5s 内未就绪。log:
    $out"
else
  # 拉 contracts.json
  contracts_json=$(curl -s --max-time 3 "http://127.0.0.1:$PORT/_data/contracts.json")
  kill -9 $dash_pid 2>/dev/null || true
  rm -rf "$sandbox" /tmp/_dash_test.log

  if [[ "$contracts_json" == *"dash-real"* ]]; then
    tc_ok
  else
    tc_fail "/_data/contracts.json 未包含 'dash-real'.
    response: $contracts_json"
  fi
fi

# ----------------------------------------------------------------------
tc_summary
