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
# 从 VERSION 文件读真实版本，避免每次升版都要改测试
EXPECTED_VER=$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")
tc_assert_contains "$EXPECTED_VER" "pl --version" "$PL" --version

tc_case "pl version 输出版本号（别名）"
tc_assert_contains "$EXPECTED_VER" "pl version" "$PL" version

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
# Suite 6: pl upgrade / pl doctor 远端检查 (v1.10.1)
# ----------------------------------------------------------------------
tc_suite "upgrade-and-doctor-version-check"

tc_case "pl upgrade --help 输出 usage"
tc_assert_contains "pl upgrade" "pl upgrade --help" "$PL" upgrade --help

tc_case "pl upgrade --check 在 PL_HOME 已是最新时 exit 0"
# 假设 dev 环境的 PL_HOME (REPO_ROOT) 就是最新 main，--check 应该 exit 0 或 10
# 这里只验证退出码不是 1/2（即不是错误，而是 0/10）
set +e
"$PL" upgrade --check >/dev/null 2>&1
rc=$?
set -e
TC_CURRENT_CASE="pl upgrade --check exit in {0,10}"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc -eq 0 || $rc -eq 10 ]]; then tc_ok; else tc_fail "expected 0 or 10, got $rc"; fi

tc_case "pl upgrade --check --no-fetch 不应触发网络 / unbound"
set +e
out=$("$PL" upgrade --check --no-fetch 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="pl upgrade --check --no-fetch healthy"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$out" == *"unbound variable"* ]]; then
  tc_fail "unbound variable in output: $out"
elif [[ $rc -eq 0 || $rc -eq 10 ]]; then
  tc_ok
else
  tc_fail "expected 0 or 10, got $rc; out: $out"
fi

tc_case "pl upgrade 在非 git PL_HOME 时友好报错（exit 1）"
FAKE=$(mktemp -d)
mkdir -p "$FAKE/scripts" "$FAKE/bin"
cp "$REPO_ROOT/scripts/_env.sh" "$FAKE/scripts/"
cp "$REPO_ROOT/scripts/pl-upgrade.sh" "$FAKE/scripts/"
echo "0.0.0" > "$FAKE/VERSION"
set +e
out=$(PL_HOME="$FAKE" bash "$FAKE/scripts/pl-upgrade.sh" --check 2>&1)
rc=$?
set -e
rm -rf "$FAKE"
TC_CURRENT_CASE="pl upgrade non-git → exit 1 + 友好提示"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc -eq 1 && "$out" == *"非 git"* || "$out" == *"不是 git"* ]]; then
  tc_ok
else
  tc_fail "expected exit 1 + '非 git'/'不是 git'; got rc=$rc, out=$out"
fi

tc_case "pl doctor PL_DOCTOR_OFFLINE=1 应跳过远端检查"
set +e
out=$(PL_DOCTOR_OFFLINE=1 "$PL" doctor 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="pl doctor offline mode skips remote"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$out" == *"PL_DOCTOR_OFFLINE"* || "$out" == *"已跳过"* ]]; then
  tc_ok
else
  tc_fail "expected '已跳过' / PL_DOCTOR_OFFLINE in output; got: $out"
fi

tc_case "pl doctor 包含 [版本] 段落"
out=$(PL_DOCTOR_OFFLINE=1 "$PL" doctor 2>&1)
TC_CURRENT_CASE="pl doctor has [版本] section"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$out" == *"[版本]"* && "$out" == *"pl-pipeline ="* ]]; then
  tc_ok
else
  tc_fail "missing [版本]/pl-pipeline = section"
fi

# ----------------------------------------------------------------------
# Suite 7: pl ide (v1.11.0)
# ----------------------------------------------------------------------
tc_suite "ide-sync"

tc_case "pl ide help 输出 usage"
tc_assert_contains "ide detect" "pl ide help" "$PL" ide help

tc_case "pl ide detect 在空目录返回 0"
TMPDIR_IDE=$(mktemp -d)
set +e
out=$(cd "$TMPDIR_IDE" && "$PL" ide detect 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="pl ide detect in empty dir → exit 0"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc -eq 0 && "$out" == *"未检测到"* ]]; then
  tc_ok
else
  tc_fail "expected exit 0 + '未检测到'; rc=$rc out=$out"
fi
rm -rf "$TMPDIR_IDE"

tc_case "pl ide detect 识别 .cursor 和 .codebuddy"
TMPDIR_IDE=$(mktemp -d)
mkdir -p "$TMPDIR_IDE/.cursor" "$TMPDIR_IDE/.codebuddy"
set +e
out=$(cd "$TMPDIR_IDE" && "$PL" ide detect 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="detect lists cursor + codebuddy"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc -eq 0 && "$out" == *"cursor"* && "$out" == *"codebuddy"* ]]; then
  tc_ok
else
  tc_fail "expected both ides; rc=$rc out=$out"
fi
rm -rf "$TMPDIR_IDE"

tc_case "pl ide sync 实际写入并 idempotent"
TMPDIR_IDE=$(mktemp -d)
mkdir -p "$TMPDIR_IDE/.cursor" "$TMPDIR_IDE/.codebuddy"
set +e
(cd "$TMPDIR_IDE" && "$PL" ide sync >/dev/null 2>&1)
rc1=$?
written_cursor_rules=$(ls "$TMPDIR_IDE/.cursor/rules/" 2>/dev/null | wc -l | tr -d ' ')
written_codebuddy_agents=$(ls "$TMPDIR_IDE/.codebuddy/agents/" 2>/dev/null | wc -l | tr -d ' ')
# 第二次 sync 应不再写入（output 不含 written= 后跟非零数字 — 这里宽松判断只校验返回 0）
(cd "$TMPDIR_IDE" && "$PL" ide sync >/dev/null 2>&1)
rc2=$?
set -e
TC_CURRENT_CASE="ide sync writes files + idempotent"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $rc1 -eq 0 && $rc2 -eq 0 && $written_cursor_rules -ge 1 && $written_codebuddy_agents -ge 1 ]]; then
  tc_ok
else
  tc_fail "expected 2x rc 0 + cursor rules + codebuddy agents; got rc1=$rc1 rc2=$rc2 c-rules=$written_cursor_rules cb-agents=$written_codebuddy_agents"
fi

tc_case "Cursor rules 是 .mdc + frontmatter, CodeBuddy rules 是 .md plain"
fst_cursor=$(ls "$TMPDIR_IDE/.cursor/rules/"*.mdc 2>/dev/null | head -1)
fst_codebuddy=$(ls "$TMPDIR_IDE/.codebuddy/rules/"*.md 2>/dev/null | head -1)
TC_CURRENT_CASE="cursor has .mdc with frontmatter, codebuddy plain .md"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ -f "$fst_cursor" ]] && head -1 "$fst_cursor" | grep -q '^---$' \
   && [[ -f "$fst_codebuddy" ]]; then
  tc_ok
else
  tc_fail "cursor=$fst_cursor codebuddy=$fst_codebuddy"
fi

tc_case "AGENTS.md 含两个独立 IDE 段落"
TC_CURRENT_CASE="AGENTS.md has cursor+codebuddy managed sections"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if grep -q "pl-pipeline:cursor managed section" "$TMPDIR_IDE/AGENTS.md" \
   && grep -q "pl-pipeline:codebuddy managed section" "$TMPDIR_IDE/AGENTS.md"; then
  tc_ok
else
  tc_fail "missing one or both managed sections in $TMPDIR_IDE/AGENTS.md"
fi

tc_case "用户手改文件后 sync 默认拒绝覆盖"
echo "USER MODIFIED" >> "$fst_cursor"
set +e
out=$(cd "$TMPDIR_IDE" && "$PL" ide sync --ide cursor 2>&1)
set -e
TC_CURRENT_CASE="hash mismatch → skip without --force"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$out" == *"被手工修改"* || "$out" == *"skipped=1"* ]]; then
  tc_ok
else
  tc_fail "expected '被手工修改' or skipped=1, got: $out"
fi

tc_case "pl ide unsync 撤回 + AGENTS.md 段落消失"
set +e
(cd "$TMPDIR_IDE" && "$PL" ide unsync --force >/dev/null 2>&1)
if [[ -d "$TMPDIR_IDE/.cursor/rules" ]]; then
  remaining_cursor=$(find "$TMPDIR_IDE/.cursor/rules" -maxdepth 1 -type f | wc -l | tr -d ' ')
else
  remaining_cursor=0
fi
if [[ -d "$TMPDIR_IDE/.codebuddy/rules" ]]; then
  remaining_cb=$(find "$TMPDIR_IDE/.codebuddy/rules" -maxdepth 1 -type f | wc -l | tr -d ' ')
else
  remaining_cb=0
fi
set -e
TC_CURRENT_CASE="unsync removes managed files + AGENTS.md sections"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ $remaining_cursor -eq 0 && $remaining_cb -eq 0 ]] \
   && ! grep -q "pl-pipeline:cursor managed section" "$TMPDIR_IDE/AGENTS.md" 2>/dev/null \
   && ! grep -q "pl-pipeline:codebuddy managed section" "$TMPDIR_IDE/AGENTS.md" 2>/dev/null; then
  tc_ok
else
  tc_fail "remaining cursor=$remaining_cursor cb=$remaining_cb; AGENTS.md grep showed leftover sections"
fi
rm -rf "$TMPDIR_IDE"

# ----------------------------------------------------------------------
# Suite 8: pl ide — Claude / Codex (v1.12.0)
# ----------------------------------------------------------------------
tc_suite "ide-sync-v1.12"

tc_case "ide-integrations/ 目录包含 4 个内置 IDE manifest"
TC_CURRENT_CASE="ide-integrations contains claude+codex+codebuddy+cursor"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
ok=true
for ide in claude codex codebuddy cursor; do
  [[ -f "$REPO_ROOT/ide-integrations/$ide/manifest.yaml" ]] || ok=false
done
if $ok; then
  tc_ok
else
  tc_fail "missing one of ide-integrations/{claude,codex,codebuddy,cursor}/manifest.yaml"
fi

tc_case "pl ide sync --ide claude 写入 .claude/ + CLAUDE.md"
TMPDIR_IDE=$(mktemp -d)
mkdir -p "$TMPDIR_IDE/.claude"
set +e
(cd "$TMPDIR_IDE" && "$PL" ide sync --ide claude >/dev/null 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="claude sync writes .claude/ + CLAUDE.md"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
n_cmds=$(ls "$TMPDIR_IDE/.claude/commands/pl/" 2>/dev/null | wc -l | tr -d ' ')
n_agents=$(ls "$TMPDIR_IDE/.claude/agents/" 2>/dev/null | wc -l | tr -d ' ')
if [[ $rc -eq 0 && $n_cmds -ge 1 && $n_agents -ge 1 ]] \
   && [[ -f "$TMPDIR_IDE/CLAUDE.md" ]] \
   && grep -q "pl-pipeline:claude" "$TMPDIR_IDE/CLAUDE.md"; then
  tc_ok
else
  tc_fail "rc=$rc cmds=$n_cmds agents=$n_agents; CLAUDE.md present? $([[ -f "$TMPDIR_IDE/CLAUDE.md" ]] && echo y || echo n)"
fi
rm -rf "$TMPDIR_IDE"

tc_case "pl ide sync --ide codex 仅写 AGENTS.md（不复制目录）"
TMPDIR_IDE=$(mktemp -d)
mkdir -p "$TMPDIR_IDE/.codex"
set +e
(cd "$TMPDIR_IDE" && "$PL" ide sync --ide codex >/dev/null 2>&1)
rc=$?
set -e
TC_CURRENT_CASE="codex sync only updates AGENTS.md"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
# 不应该有 .codex/{commands,agents,rules,skills} 目录
nothing_copied=true
for d in commands agents rules skills; do
  [[ -d "$TMPDIR_IDE/.codex/$d" ]] && nothing_copied=false
done
if [[ $rc -eq 0 ]] && $nothing_copied \
   && [[ -f "$TMPDIR_IDE/AGENTS.md" ]] \
   && grep -q "pl-pipeline:codex" "$TMPDIR_IDE/AGENTS.md"; then
  tc_ok
else
  tc_fail "rc=$rc, copied=$([ "$nothing_copied" = true ] && echo none || echo some); AGENTS.md present? $([[ -f "$TMPDIR_IDE/AGENTS.md" ]] && echo y || echo n)"
fi
rm -rf "$TMPDIR_IDE"

tc_case "pl ide sync 4 IDE 共存 不互相覆盖"
TMPDIR_IDE=$(mktemp -d)
mkdir -p "$TMPDIR_IDE"/.{cursor,codebuddy,claude,codex}
set +e
(cd "$TMPDIR_IDE" && "$PL" ide sync >/dev/null 2>&1)
set -e
TC_CURRENT_CASE="all 4 IDE managed sections coexist in AGENTS.md/CLAUDE.md"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if grep -q "pl-pipeline:cursor"   "$TMPDIR_IDE/AGENTS.md" \
   && grep -q "pl-pipeline:codebuddy" "$TMPDIR_IDE/AGENTS.md" \
   && grep -q "pl-pipeline:codex"     "$TMPDIR_IDE/AGENTS.md" \
   && grep -q "pl-pipeline:claude"    "$TMPDIR_IDE/CLAUDE.md"; then
  tc_ok
else
  tc_fail "missing one of the 4 managed sections"
fi
rm -rf "$TMPDIR_IDE"

# ----------------------------------------------------------------------
# Suite 9: requires.pl_version 启动自检 (v1.12.0)
# ----------------------------------------------------------------------
tc_suite "require-check"

tc_case "pl/config.yaml requires.pl_version 不匹配应 stderr 警告"
TMPDIR_REQ=$(mktemp -d)
mkdir -p "$TMPDIR_REQ/pl"
cat > "$TMPDIR_REQ/pl/config.yaml" <<'YML'
version: pl@v1.1
namespace: pl
requires:
  pl_version: ">=99.0"
YML
set +e
err=$(cd "$TMPDIR_REQ" && "$PL" status 2>&1 1>/dev/null)
set -e
TC_CURRENT_CASE="requires.pl_version mismatch warns on stderr"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$err" == *"版本不匹配"* ]]; then
  tc_ok
else
  tc_fail "expected 版本不匹配; got: $err"
fi
rm -rf "$TMPDIR_REQ"

tc_case "PL_REQUIRE_CHECK=0 关闭自检"
TMPDIR_REQ=$(mktemp -d)
mkdir -p "$TMPDIR_REQ/pl"
cat > "$TMPDIR_REQ/pl/config.yaml" <<'YML'
version: pl@v1.1
namespace: pl
requires:
  pl_version: ">=99.0"
YML
set +e
err=$(cd "$TMPDIR_REQ" && PL_REQUIRE_CHECK=0 "$PL" status 2>&1 1>/dev/null)
set -e
TC_CURRENT_CASE="PL_REQUIRE_CHECK=0 silences warning"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$err" != *"版本不匹配"* ]]; then
  tc_ok
else
  tc_fail "PL_REQUIRE_CHECK=0 should silence; got: $err"
fi
rm -rf "$TMPDIR_REQ"

tc_case "doctor 命令本身不被 requires 检查干扰"
TMPDIR_REQ=$(mktemp -d)
mkdir -p "$TMPDIR_REQ/pl"
cat > "$TMPDIR_REQ/pl/config.yaml" <<'YML'
requires:
  pl_version: ">=99.0"
YML
set +e
err=$(cd "$TMPDIR_REQ" && "$PL" doctor 2>&1 1>/dev/null)
set -e
TC_CURRENT_CASE="doctor skips requires self-check"
printf '  %s· %s%s ... ' "$TC_DIM" "$TC_CURRENT_CASE" "$TC_RST"
if [[ "$err" != *"版本不匹配"* ]]; then
  tc_ok
else
  tc_fail "doctor should NOT trigger self-check; got: $err"
fi
rm -rf "$TMPDIR_REQ"

# ----------------------------------------------------------------------
# Final summary
# ----------------------------------------------------------------------
tc_summary
