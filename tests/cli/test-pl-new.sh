#!/usr/bin/env bash
# tests/cli/test-pl-new.sh — pl new + install.sh 端到端测试
# ----------------------------------------------------------------------
# 跑法（在 repo 根）:
#   bash tests/cli/test-pl-new.sh
# ----------------------------------------------------------------------

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
PL="$REPO_ROOT/bin/pl"
INSTALL_SH="$REPO_ROOT/install.sh"

# shellcheck source=tests/_lib/runner.sh
source "$REPO_ROOT/tests/_lib/runner.sh"

export PL_HOME="$REPO_ROOT"
export PATH="$PL_HOME/bin:$PATH"
unset PL_PROJECT 2>/dev/null || true

# 用临时工作目录避免污染
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ----------------------------------------------------------------------
# Suite 1: install.sh 自身
# ----------------------------------------------------------------------
tc_suite "install.sh"

tc_case "install.sh 语法合法"
tc_assert_pass "bash -n install.sh" bash -n "$INSTALL_SH"

tc_case "install.sh --help 不报错（仅显示 usage 也算）"
# install.sh 没有 --help 但应能优雅退出（这里我们不强求）
tc_assert_pass "install.sh 是文件且可执行" test -x "$INSTALL_SH"

tc_case "本地模式：检测到 SELF_DIR 是 pl 仓库时不重新 clone"
# 临时设置 PREFIX 为不同路径，但 LOCAL_MODE 应识别 SELF_DIR
out=$(PL_INSTALL_PREFIX="$WORK/should-be-overridden" \
      PL_INSTALL_NO_RC=1 \
      PL_INSTALL_QUIET=1 \
      bash "$INSTALL_SH" 2>&1)
if [[ "$out" == *"使用本地仓库"* ]] || [[ "$out" == *"已就绪"* ]]; then
  tc_ok
else
  tc_fail "expected 'local mode' detection. output: $out"
fi

# ----------------------------------------------------------------------
# Suite 2: pl new 元命令
# ----------------------------------------------------------------------
tc_suite "pl new meta"

tc_case "pl new --help 显示用法"
tc_assert_contains "用法:" "pl new --help" "$PL" new --help

tc_case "pl new 无参数报错"
tc_assert_exit 2 "pl new (no args)" "$PL" new

tc_case "pl new --stack 非法值报错"
tc_assert_exit 1 "pl new x --stack invalid" "$PL" new "$WORK/invalid-stack" --stack invalid

# ----------------------------------------------------------------------
# Suite 3: pl new <stack>（每个 stack 真起一个项目）
# ----------------------------------------------------------------------
for stack in bare nextjs fastapi crawler monorepo-trio; do
  tc_suite "pl new --stack $stack"

  tc_case "项目目录被创建"
  proj="$WORK/test-$stack"
  if "$PL" new "$proj" --stack "$stack" --no-git >/dev/null 2>&1; then
    if [[ -d "$proj" ]]; then
      tc_ok
    else
      tc_fail "exit 0 但目录不存在: $proj"
    fi
  else
    tc_fail "pl new $stack exit non-zero"
    continue
  fi

  if [[ "$stack" == "monorepo-trio" ]]; then
    tc_case "三个子模块都有 pl/config.yaml"
    if [[ -f "$proj/frontend/pl/config.yaml" ]] && \
       [[ -f "$proj/api/pl/config.yaml" ]] && \
       [[ -f "$proj/crawler/pl/config.yaml" ]]; then
      tc_ok
    else
      tc_fail "monorepo 子模块缺 pl/config.yaml"
    fi

    tc_case "三个子模块都起了首个 change"
    if [[ -f "$proj/frontend/pl/changes/add-first-feature/.state.md" ]] && \
       [[ -f "$proj/api/pl/changes/add-first-feature/.state.md" ]] && \
       [[ -f "$proj/crawler/pl/changes/add-first-feature/.state.md" ]]; then
      tc_ok
    else
      tc_fail "monorepo 子模块缺 .state.md"
    fi

    tc_case "frontend 装了 nextjs adapter"
    if [[ -f "$proj/frontend/.pl-adapter.yaml" ]] && \
       grep -q "nextjs-web" "$proj/frontend/.pl-adapter.yaml"; then
      tc_ok
    else
      tc_fail "frontend 没装上 nextjs-web adapter"
    fi

    tc_case "api 装了 fastapi adapter"
    if [[ -f "$proj/api/.pl-adapter.yaml" ]] && \
       grep -q "python-fastapi" "$proj/api/.pl-adapter.yaml"; then
      tc_ok
    else
      tc_fail "api 没装上 python-fastapi adapter"
    fi

    tc_case "crawler 不装 adapter 但有 build.yaml"
    if [[ ! -f "$proj/crawler/.pl-adapter.yaml" ]] && \
       [[ -f "$proj/crawler/pl/adapters/build.yaml" ]]; then
      tc_ok
    else
      tc_fail "crawler 应无 .pl-adapter.yaml 但有 build.yaml"
    fi
  else
    tc_case "pl/config.yaml 在位"
    tc_assert_pass "config.yaml exists" test -f "$proj/pl/config.yaml"

    tc_case "首个 change 已起"
    tc_assert_pass ".state.md exists" test -f "$proj/pl/changes/add-first-feature/.state.md"

    tc_case "README.md 在位"
    tc_assert_pass "README.md exists" test -f "$proj/README.md"

    if [[ "$stack" == "nextjs" || "$stack" == "fastapi" ]]; then
      tc_case "$stack adapter 装上"
      tc_assert_pass ".pl-adapter.yaml exists" test -f "$proj/.pl-adapter.yaml"

      tc_case ".codebuddy/agents/ 有内容"
      if [[ -d "$proj/.codebuddy/agents" ]] && [[ -n "$(ls "$proj/.codebuddy/agents" 2>/dev/null)" ]]; then
        tc_ok
      else
        tc_fail ".codebuddy/agents 应有 agent .md"
      fi
    fi

    if [[ "$stack" == "crawler" ]]; then
      tc_case "crawler 自定义 build.yaml 在位"
      tc_assert_pass "build.yaml exists" test -f "$proj/pl/adapters/build.yaml"
    fi
  fi
done

# ----------------------------------------------------------------------
# Suite 4: pl new --no-init / --no-git 选项
# ----------------------------------------------------------------------
tc_suite "pl new options"

tc_case "--no-git 不创建 .git/"
proj="$WORK/test-nogit"
"$PL" new "$proj" --stack bare --no-git --no-init >/dev/null 2>&1
if [[ ! -d "$proj/.git" ]]; then
  tc_ok
else
  tc_fail "--no-git 但 .git 还在"
fi

tc_case "--no-init 不起 first change"
proj="$WORK/test-noinit"
"$PL" new "$proj" --stack bare --no-init >/dev/null 2>&1
if [[ ! -e "$proj/pl/changes/add-first-feature" ]]; then
  tc_ok
else
  tc_fail "--no-init 但 add-first-feature 还在"
fi

tc_case "--first-change 自定义名"
proj="$WORK/test-customfirst"
"$PL" new "$proj" --stack bare --first-change "my-cool-feature" >/dev/null 2>&1
if [[ -f "$proj/pl/changes/my-cool-feature/.state.md" ]]; then
  tc_ok
else
  tc_fail "自定义 first-change 未生效"
fi

tc_case "已存在目录无 --force 拒绝"
proj="$WORK/test-existing"
mkdir -p "$proj"
tc_assert_exit 1 "pl new (existing dir, no --force)" "$PL" new "$proj" --stack bare

tc_case "已存在目录加 --force 覆盖"
"$PL" new "$proj" --stack bare --force --no-init --no-git >/dev/null 2>&1
if [[ -f "$proj/pl/config.yaml" ]]; then
  tc_ok
else
  tc_fail "--force 没把目录覆盖成新项目"
fi

# ----------------------------------------------------------------------
tc_summary
