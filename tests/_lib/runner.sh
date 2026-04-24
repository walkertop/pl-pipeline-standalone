#!/usr/bin/env bash
# tests/_lib/runner.sh — 极简 shell 测试 runner
# ----------------------------------------------------------------------
# 不引入 bats 等外部依赖（pl-pipeline 的内核约束：只用 bash + python3 stdlib）
# 用法见 tests/cli/test-pl.sh
# ----------------------------------------------------------------------
set -uo pipefail

# 颜色（CI 不带 TTY 时降级）
if [[ -t 1 ]]; then
  TC_RED=$'\033[31m'; TC_GREEN=$'\033[32m'; TC_YELLOW=$'\033[33m'
  TC_DIM=$'\033[2m'; TC_BOLD=$'\033[1m'; TC_RST=$'\033[0m'
else
  TC_RED=""; TC_GREEN=""; TC_YELLOW=""; TC_DIM=""; TC_BOLD=""; TC_RST=""
fi

# 全局计数
TC_PASS=0
TC_FAIL=0
TC_SKIP=0
TC_FAIL_NAMES=()
TC_SUITE_NAME=""

# 当前 case context
TC_CURRENT_CASE=""

# 注册 case
tc_case() {
  TC_CURRENT_CASE="$1"
  printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
}

# 通过当前 case
tc_ok() {
  TC_PASS=$((TC_PASS + 1))
  printf '%sOK%s\n' "$TC_GREEN" "$TC_RST"
}

# 失败当前 case
tc_fail() {
  local why="${1:-(no detail)}"
  TC_FAIL=$((TC_FAIL + 1))
  TC_FAIL_NAMES+=("$TC_CURRENT_CASE")
  printf '%sFAIL%s\n    %s%s%s\n' "$TC_RED" "$TC_RST" "$TC_DIM" "$why" "$TC_RST"
}

# 跳过
tc_skip() {
  local why="${1:-}"
  TC_SKIP=$((TC_SKIP + 1))
  printf '%sSKIP%s %s\n' "$TC_YELLOW" "$TC_RST" "$why"
}

# 断言：命令应该 exit 0
tc_assert_pass() {
  local cmd_desc="$1"; shift
  local out
  if out="$("$@" 2>&1)"; then
    tc_ok
  else
    tc_fail "expected pass, got rc=$?: ${cmd_desc}
    output: ${out}"
  fi
}

# 断言：命令应该以特定 exit code 退出
tc_assert_exit() {
  local expected_rc="$1"; shift
  local cmd_desc="$1"; shift
  local out rc
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if [[ $rc -eq $expected_rc ]]; then
    tc_ok
  else
    tc_fail "expected rc=$expected_rc, got rc=$rc: ${cmd_desc}
    output: ${out}"
  fi
}

# 断言：输出包含 substring
tc_assert_contains() {
  local needle="$1"; shift
  local cmd_desc="$1"; shift
  local out
  set +e
  out="$("$@" 2>&1)"
  set -e
  if [[ "$out" == *"$needle"* ]]; then
    tc_ok
  else
    tc_fail "expected output to contain '${needle}': ${cmd_desc}
    actual output: ${out}"
  fi
}

# 断言：输出 NOT 包含某字符串（用于"不应有 unbound variable 这类"）
tc_assert_not_contains() {
  local forbidden="$1"; shift
  local cmd_desc="$1"; shift
  local out
  set +e
  out="$("$@" 2>&1)"
  set -e
  if [[ "$out" == *"$forbidden"* ]]; then
    tc_fail "output unexpectedly contained '${forbidden}': ${cmd_desc}
    output: ${out}"
  else
    tc_ok
  fi
}

# Suite 入口
tc_suite() {
  TC_SUITE_NAME="$1"
  printf '\n%s━━━ Suite: %s ━━━%s\n' "$TC_BOLD" "$TC_SUITE_NAME" "$TC_RST"
}

# Suite 结束总结
tc_summary() {
  echo ""
  printf '%s━━━ Summary ━━━%s\n' "$TC_BOLD" "$TC_RST"
  printf '  pass: %s%d%s\n' "$TC_GREEN" "$TC_PASS" "$TC_RST"
  if [[ $TC_FAIL -gt 0 ]]; then
    printf '  fail: %s%d%s\n' "$TC_RED" "$TC_FAIL" "$TC_RST"
    printf '%sFailed cases:%s\n' "$TC_RED" "$TC_RST"
    for n in "${TC_FAIL_NAMES[@]}"; do
      printf '    - %s\n' "$n"
    done
  else
    printf '  fail: 0\n'
  fi
  if [[ $TC_SKIP -gt 0 ]]; then
    printf '  skip: %s%d%s\n' "$TC_YELLOW" "$TC_SKIP" "$TC_RST"
  fi
  echo ""
  if [[ $TC_FAIL -eq 0 ]]; then
    printf '%s✅ all tests passed%s\n' "$TC_GREEN" "$TC_RST"
    return 0
  else
    printf '%s❌ %d test(s) failed%s\n' "$TC_RED" "$TC_FAIL" "$TC_RST"
    return 1
  fi
}
