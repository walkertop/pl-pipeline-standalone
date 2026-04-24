#!/usr/bin/env bash
# tests/cli/test-pl.sh — bin/pl CLI dispatcher 单元测试
# ----------------------------------------------------------------------
# 跑法（在 repo 根）:
#   bash tests/cli/test-pl.sh
# 退出码:
#   0 = 全绿
#   1 = 有 failed case（最后会列出名字）
# ----------------------------------------------------------------------

set -uo pipefail

# 定位 repo root（无论从哪儿跑）
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
PL="$REPO_ROOT/bin/pl"

# shellcheck source=tests/_lib/runner.sh
source "$REPO_ROOT/tests/_lib/runner.sh"

# 防止用户当前 shell 的 PL_HOME 干扰
export PL_HOME="$REPO_ROOT"
unset PL_PROJECT 2>/dev/null || true

# ----------------------------------------------------------------------
# Suite 1: meta-commands
# ----------------------------------------------------------------------
tc_suite "meta-commands"

tc_case "pl --version 输出版本号"
tc_assert_contains "1.8" "pl --version" "$PL" --version

tc_case "pl version 输出版本号（别名）"
tc_assert_contains "1.8" "pl version" "$PL" version

tc_case "pl env 输出 PL_HOME"
tc_assert_contains "PL_HOME" "pl env" "$PL" env

tc_case "pl help 输出 usage"
tc_assert_contains "用法:" "pl help" "$PL" help

tc_case "pl --help 输出 usage（别名）"
tc_assert_contains "用法:" "pl --help" "$PL" --help

tc_case "pl 无参 等价于 help"
tc_assert_contains "用法:" "pl (no args)" "$PL"

tc_case "pl doctor 跑过（不一定全绿，但应 exit 0）"
tc_assert_pass "pl doctor" "$PL" doctor

# ----------------------------------------------------------------------
# Suite 2: 错误处理 + bash 3.2 兼容
# ----------------------------------------------------------------------
tc_suite "error-handling"

tc_case "pl bogus 应 exit 2"
tc_assert_exit 2 "pl bogus" "$PL" bogus

tc_case "pl bogus 报错信息含未知子命令"
tc_assert_contains "未知" "pl bogus error msg" "$PL" bogus

tc_case "pl bogus 不应触发 unbound variable（bash 3.2 兼容）"
tc_assert_not_contains "unbound variable" "pl bogus" "$PL" bogus

tc_case "pl contract（缺 verb）应 exit 2"
tc_assert_exit 2 "pl contract" "$PL" contract

tc_case "pl contract 报错信息含 'aggregate|verify|query'"
tc_assert_contains "aggregate|verify|query" "pl contract" "$PL" contract

tc_case "pl contract bogus 应 exit 2"
tc_assert_exit 2 "pl contract bogus" "$PL" contract bogus

tc_case "pl contract bogus 不应触发 unbound variable"
tc_assert_not_contains "unbound variable" "pl contract bogus" "$PL" contract bogus

tc_case "pl trace（缺 verb）应 exit 2"
tc_assert_exit 2 "pl trace" "$PL" trace

tc_case "pl adapter（缺 verb）应 exit 2"
tc_assert_exit 2 "pl adapter" "$PL" adapter

tc_case "pl piao（缺 verb）应 exit 2"
tc_assert_exit 2 "pl piao" "$PL" piao

# ----------------------------------------------------------------------
# Suite 3: namespace verbs 路由（不真跑，只验证能找到底层脚本）
# ----------------------------------------------------------------------
tc_suite "namespace-routing"

# 这里用 --help 探测：每个底层脚本都至少能 -h 出 usage（或直接 exit 但不报 unbound）
# trace use 不接受 --help，所以专门用 --change 缺值测试

tc_case "pl contract verify --help 不报 unbound variable"
tc_assert_not_contains "unbound variable" "pl contract verify --help" "$PL" contract verify --help

tc_case "pl contract aggregate --help 不报 unbound variable"
tc_assert_not_contains "unbound variable" "pl contract aggregate --help" "$PL" contract aggregate --help

tc_case "pl contract query --help 不报 unbound variable"
tc_assert_not_contains "unbound variable" "pl contract query --help" "$PL" contract query --help

tc_case "pl adapter validate（缺参）应非 0 退出"
set +e
"$PL" adapter validate >/dev/null 2>&1
rc=$?
set -e
TC_CURRENT_CASE="pl adapter validate (no args) exits non-zero"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc -ne 0 ]]; then tc_ok; else tc_fail "expected non-zero, got 0"; fi

tc_case "pl status --self-check 在 repo 根能跑（不应报 unbound variable）"
# 在临时 PL_PROJECT 下跑（避免依赖项目状态）
PROJ=$(mktemp -d)
mkdir -p "$PROJ/pl/changes"
out=$(PL_PROJECT="$PROJ" "$PL" status --self-check 2>&1) || true
rm -rf "$PROJ"
TC_CURRENT_CASE="pl status --self-check no unbound"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$out" == *"unbound variable"* ]]; then
  tc_fail "output contained 'unbound variable':
    $out"
else
  tc_ok
fi

# ----------------------------------------------------------------------
# Suite 4: 顶层 1:1 映射
# ----------------------------------------------------------------------
tc_suite "top-level-mappings"

# 验证一些直接映射的命令能找到底层脚本（用 --help / 缺参方式探测，不副作用）
for cmd in run smoke phase orchestrator status; do
  tc_case "pl $cmd 不报 'command not found' 类错误（路由可达）"
  out=$("$PL" "$cmd" --help 2>&1 || true)
  TC_CURRENT_CASE="pl $cmd routing"
  if [[ "$out" == *"未知子命令"* ]] || [[ "$out" == *"command not found"* ]] || [[ "$out" == *"未找到 verb"* ]]; then
    tc_fail "routing failed for 'pl $cmd':
    $out"
  else
    tc_ok
  fi
done

# ----------------------------------------------------------------------
# Suite 5: argv 透传
# ----------------------------------------------------------------------
tc_suite "argv-passthrough"

tc_case "pl trace use 缺必需参数时底层脚本能识别（透传完整）"
# trace-adapter-use.sh 缺 --change 时应非 0
set +e
"$PL" trace use 2>&1 >/dev/null
rc=$?
set -e
TC_CURRENT_CASE="pl trace use (no args) exits non-zero (passthrough works)"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc -ne 0 ]]; then tc_ok; else tc_fail "expected non-zero, got 0"; fi

tc_case "pl run --change foo --gate D（缺配置）应非 0 但不应报 unbound"
set +e
out=$("$PL" run --change foo --gate D 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="pl run argv passthrough"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$out" == *"unbound variable"* ]]; then
  tc_fail "passthrough triggered unbound variable:
    $out"
else
  tc_ok
fi

# ----------------------------------------------------------------------
# Final summary
# ----------------------------------------------------------------------
tc_summary
