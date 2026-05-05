#!/usr/bin/env bash
# tests/cli/test-pl-agent.sh — pl agent execution loop tests

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
PL="$REPO_ROOT/bin/pl"

# shellcheck source=tests/_lib/runner.sh
source "$REPO_ROOT/tests/_lib/runner.sh"

export PL_HOME="$REPO_ROOT"
unset PL_PROJECT 2>/dev/null || true

tc_suite "agent-execution-loop"

tc_case "pl agent run executes, repairs a failed gate, and records trace"
TMPDIR_AGENT=$(mktemp -d)
mkdir -p "$TMPDIR_AGENT/app" "$TMPDIR_AGENT/tests" "$TMPDIR_AGENT/scripts" "$TMPDIR_AGENT/pl/changes/agent-loop-demo"

cat > "$TMPDIR_AGENT/pl/config.yaml" <<'YML'
version: pl@v1.1
namespace: demo-agent-loop
checks:
  - id: unit_tests
    label: "Python unit tests"
    cmd: "python3 -m unittest discover -s tests"
    cwd: "."
    required: true
gates:
  D:
    from: IMPLEMENT
    to: VERIFY
    eval: all_checks.pass
    on_failure: block
    checks: [unit_tests]
YML

touch "$TMPDIR_AGENT/app/__init__.py"
cat > "$TMPDIR_AGENT/app/calc.py" <<'PY'
def add(a, b):
    return a + b
PY
cat > "$TMPDIR_AGENT/tests/test_calc.py" <<'PY'
import unittest

from app.calc import add


class CalcTest(unittest.TestCase):
    def test_adds_two_numbers(self):
        self.assertEqual(add(2, 3), 5)
        self.assertEqual(add(-1, 1), 0)


if __name__ == "__main__":
    unittest.main()
PY
cat > "$TMPDIR_AGENT/scripts/write_bad_impl.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cat > app/calc.py <<'PY'
def add(a, b):
    return a - b
PY
SH
cat > "$TMPDIR_AGENT/scripts/repair_impl.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${PL_REPAIR_CONTEXT:-}" || ! -f "$PL_REPAIR_CONTEXT" ]]; then
  echo "missing PL_REPAIR_CONTEXT" >&2
  exit 1
fi
grep -q "Gate output" "$PL_REPAIR_CONTEXT"
cat > app/calc.py <<'PY'
def add(a, b):
    return a + b
PY
SH
chmod +x "$TMPDIR_AGENT/scripts/write_bad_impl.sh" "$TMPDIR_AGENT/scripts/repair_impl.sh"

set +e
out=$(cd "$TMPDIR_AGENT" && PL_PROJECT="$TMPDIR_AGENT" PL_HOME="$REPO_ROOT" "$PL" agent run \
  --change agent-loop-demo \
  --task T03 \
  --executor local \
  --cmd "./scripts/write_bad_impl.sh" \
  --verify-gate D \
  --repair-cmd "./scripts/repair_impl.sh" \
  --max-retries 1 2>&1)
rc=$?
set -e

trace_file="$TMPDIR_AGENT/pipeline-output/trace/agent-loop-demo.events.jsonl"
context_file=""
context_dir="$TMPDIR_AGENT/pipeline-output/agent-runs/agent-loop-demo"
if [[ -d "$context_dir" ]]; then
  context_file=$(find "$context_dir" -name 'repair-context-attempt-0.md' -print 2>/dev/null | head -1)
fi

if [[ $rc -eq 0 ]] \
   && [[ -f "$trace_file" ]] \
   && [[ -f "$context_file" ]] \
   && grep -q '"event":"agent.run.start"' "$trace_file" \
   && grep -q '"event":"agent.repair.context"' "$trace_file" \
   && grep -q '"event":"agent.run.complete"' "$trace_file" \
   && grep -q "return a + b" "$TMPDIR_AGENT/app/calc.py" \
   && (cd "$TMPDIR_AGENT" && python3 -m unittest discover -s tests >/dev/null 2>&1); then
  tc_ok
else
  tc_fail "expected repaired implementation + trace; rc=$rc context=$context_file output:
    $out"
fi

rm -rf "$TMPDIR_AGENT"

tc_case "pl agent run can choose repair command from config policy"
TMPDIR_POLICY=$(mktemp -d)
mkdir -p "$TMPDIR_POLICY/app" "$TMPDIR_POLICY/tests" "$TMPDIR_POLICY/scripts" "$TMPDIR_POLICY/pl/changes/agent-loop-policy"

cat > "$TMPDIR_POLICY/pl/config.yaml" <<'YML'
version: pl@v1.1
namespace: demo-agent-policy
agent:
  repair:
    max_retries: 1
    strategy:
      test_failure: "./scripts/repair_from_policy.sh"
      default: "./scripts/repair_default.sh"
checks:
  - id: unit_tests
    label: "Python unit tests"
    cmd: "python3 -m unittest discover -s tests"
    cwd: "."
    required: true
gates:
  D:
    from: IMPLEMENT
    to: VERIFY
    eval: all_checks.pass
    on_failure: block
    checks: [unit_tests]
YML

touch "$TMPDIR_POLICY/app/__init__.py"
cat > "$TMPDIR_POLICY/app/calc.py" <<'PY'
def add(a, b):
    return a + b
PY
cat > "$TMPDIR_POLICY/tests/test_calc.py" <<'PY'
import unittest

from app.calc import add


class CalcPolicyTest(unittest.TestCase):
    def test_adds_two_numbers(self):
        self.assertEqual(add(2, 3), 5)


if __name__ == "__main__":
    unittest.main()
PY
cat > "$TMPDIR_POLICY/scripts/write_bad_impl.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cat > app/calc.py <<'PY'
def add(a, b):
    return a - b
PY
SH
cat > "$TMPDIR_POLICY/scripts/repair_from_policy.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
test "${PL_FAILURE_KIND:-}" = "test_failure"
grep -q "failure_kind: \`test_failure\`" "$PL_REPAIR_CONTEXT"
cat > app/calc.py <<'PY'
def add(a, b):
    return a + b
PY
SH
cat > "$TMPDIR_POLICY/scripts/repair_default.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo "default repair should not be used" >&2
exit 1
SH
chmod +x "$TMPDIR_POLICY/scripts/write_bad_impl.sh" "$TMPDIR_POLICY/scripts/repair_from_policy.sh" "$TMPDIR_POLICY/scripts/repair_default.sh"

set +e
out=$(cd "$TMPDIR_POLICY" && PL_PROJECT="$TMPDIR_POLICY" PL_HOME="$REPO_ROOT" "$PL" agent run \
  --change agent-loop-policy \
  --task T04 \
  --executor local \
  --cmd "./scripts/write_bad_impl.sh" \
  --verify-gate D 2>&1)
rc=$?
set -e

policy_trace="$TMPDIR_POLICY/pipeline-output/trace/agent-loop-policy.events.jsonl"
policy_context=""
policy_context_dir="$TMPDIR_POLICY/pipeline-output/agent-runs/agent-loop-policy"
if [[ -d "$policy_context_dir" ]]; then
  policy_context=$(find "$policy_context_dir" -name 'repair-context-attempt-0.md' -print 2>/dev/null | head -1)
fi

if [[ $rc -eq 0 ]] \
   && [[ -f "$policy_trace" ]] \
   && [[ -f "$policy_context" ]] \
   && grep -q '"failure_kind":"test_failure"' "$policy_trace" \
   && grep -q '"repair_source":"policy:test_failure"' "$policy_trace" \
   && grep -q "return a + b" "$TMPDIR_POLICY/app/calc.py"; then
  tc_ok
else
  tc_fail "expected config policy repair to run; rc=$rc context=$policy_context output:
    $out"
fi

rm -rf "$TMPDIR_POLICY"

tc_case "pl agent run records agent trace metadata"
TMPDIR_TRACE=$(mktemp -d)
mkdir -p "$TMPDIR_TRACE/scripts" "$TMPDIR_TRACE/prompts" "$TMPDIR_TRACE/specs" "$TMPDIR_TRACE/app" "$TMPDIR_TRACE/pl/changes/agent-trace-demo"

cat > "$TMPDIR_TRACE/pl/config.yaml" <<'YML'
version: pl@v1.1
namespace: demo-agent-trace
YML

cat > "$TMPDIR_TRACE/prompts/implement.md" <<'MD'
Implement the trace demo.
MD
cat > "$TMPDIR_TRACE/specs/spec.md" <<'MD'
# Trace Demo Spec
MD
cat > "$TMPDIR_TRACE/scripts/write_output.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cat > app/result.txt <<'TXT'
trace metadata ok
TXT
SH
chmod +x "$TMPDIR_TRACE/scripts/write_output.sh"

set +e
out=$(cd "$TMPDIR_TRACE" && PL_PROJECT="$TMPDIR_TRACE" PL_HOME="$REPO_ROOT" "$PL" agent run \
  --change agent-trace-demo \
  --task T01 \
  --executor local \
  --provider openai \
  --model codex-local-test \
  --prompt-path prompts/implement.md \
  --input-artifact specs/spec.md \
  --output-artifact app/result.txt \
  --tool-call shell \
  --tokens-input 123 \
  --tokens-output 45 \
  --cmd "./scripts/write_output.sh" \
  --json 2>&1)
rc=$?
set -e

trace_meta="$TMPDIR_TRACE/pipeline-output/trace/agent-trace-demo.events.jsonl"
if [[ $rc -eq 0 ]] \
   && [[ -f "$trace_meta" ]] \
   && grep -q '"provider":"openai"' "$trace_meta" \
   && grep -q '"model":"codex-local-test"' "$trace_meta" \
   && grep -q '"prompt_path":"prompts/implement.md"' "$trace_meta" \
   && grep -Fq '"input_artifacts":["specs/spec.md"]' "$trace_meta" \
   && grep -Fq '"output_artifacts":["app/result.txt"]' "$trace_meta" \
   && grep -Fq '"tool_calls":["shell"]' "$trace_meta" \
   && grep -Fq '"tokens":{"input":123,"output":45,"total":168}' "$trace_meta" \
   && grep -q '"status":"passed"' "$trace_meta"; then
  tc_ok
else
  tc_fail "expected agent trace metadata in trace; rc=$rc output:
    $out"
fi

rm -rf "$TMPDIR_TRACE"

tc_case "pl agent run can invoke codex-cli executor from prompt"
TMPDIR_CODEX=$(mktemp -d)
mkdir -p "$TMPDIR_CODEX/bin" "$TMPDIR_CODEX/prompts" "$TMPDIR_CODEX/app" "$TMPDIR_CODEX/pl/changes/codex-exec-demo"

cat > "$TMPDIR_CODEX/pl/config.yaml" <<'YML'
version: pl@v1.1
namespace: demo-codex-cli
YML

cat > "$TMPDIR_CODEX/prompts/implement.md" <<'MD'
Create app/codex-result.txt with the text codex fake ok.
MD
cat > "$TMPDIR_CODEX/bin/codex" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'args:'
  for arg in "$@"; do printf ' [%s]' "$arg"; done
  printf '\n'
  printf 'stdin:\n'
  cat
} > codex-invocation.log

mkdir -p app
printf 'codex fake ok\n' > app/codex-result.txt
printf '{"event":"fake-codex","tokens":{"input":11,"output":7}}\n'
SH
chmod +x "$TMPDIR_CODEX/bin/codex"

set +e
out=$(cd "$TMPDIR_CODEX" && PATH="$TMPDIR_CODEX/bin:$PATH" PL_PROJECT="$TMPDIR_CODEX" PL_HOME="$REPO_ROOT" "$PL" agent run \
  --change codex-exec-demo \
  --task T02 \
  --executor codex-cli \
  --model codex-fake-model \
  --prompt-path prompts/implement.md \
  --output-artifact app/codex-result.txt \
  --json 2>&1)
rc=$?
set -e

codex_trace="$TMPDIR_CODEX/pipeline-output/trace/codex-exec-demo.events.jsonl"
codex_log="$TMPDIR_CODEX/codex-invocation.log"
if [[ $rc -eq 0 ]] \
   && [[ -f "$codex_log" ]] \
   && grep -Fq 'args: [exec]' "$codex_log" \
   && grep -Fq '[--cd]' "$codex_log" \
   && grep -Fq '[--sandbox] [workspace-write]' "$codex_log" \
   && grep -Fq '[--ask-for-approval] [never]' "$codex_log" \
   && grep -Fq '[-m] [codex-fake-model]' "$codex_log" \
   && grep -Fq '[-]' "$codex_log" \
   && grep -Fq 'Create app/codex-result.txt' "$codex_log" \
   && grep -q 'codex fake ok' "$TMPDIR_CODEX/app/codex-result.txt" \
   && [[ -f "$codex_trace" ]] \
   && grep -q '"executor":"codex-cli"' "$codex_trace" \
   && grep -q '"provider":"openai"' "$codex_trace" \
   && grep -q '"model":"codex-fake-model"' "$codex_trace" \
   && grep -Fq '"tool_calls":["codex.exec"]' "$codex_trace" \
   && grep -Fq '"output_artifacts":["app/codex-result.txt"]' "$codex_trace"; then
  tc_ok
else
  tc_fail "expected codex-cli executor invocation + trace; rc=$rc output:
    $out"
fi

rm -rf "$TMPDIR_CODEX"

tc_case "demo-agent-codex-cli runs fake codex executor"
set +e
out=$(PL_HOME="$REPO_ROOT" bash "$REPO_ROOT/examples/demo-agent-codex-cli/run-demo.sh" 2>&1)
rc=$?
set -e

codex_demo_trace="$REPO_ROOT/examples/demo-agent-codex-cli/pipeline-output/trace/codex-cli-demo.events.jsonl"
if [[ $rc -eq 0 ]] \
   && [[ -f "$codex_demo_trace" ]] \
   && grep -q '"executor":"codex-cli"' "$codex_demo_trace" \
   && grep -q '"provider":"openai"' "$codex_demo_trace" \
   && grep -Fq '"tool_calls":["codex.exec"]' "$codex_demo_trace" \
   && grep -q '"status":"passed"' "$codex_demo_trace"; then
  tc_ok
else
  tc_fail "expected fake codex-cli demo to pass; rc=$rc output:
    $out"
fi

tc_case "demo-agent-crud-service runs a real CRUD repair loop"
set +e
out=$(PL_HOME="$REPO_ROOT" bash "$REPO_ROOT/examples/demo-agent-crud-service/run-demo.sh" 2>&1)
rc=$?
set -e

crud_trace="$REPO_ROOT/examples/demo-agent-crud-service/pipeline-output/trace/crud-service-demo.events.jsonl"
if [[ $rc -eq 0 ]] \
   && [[ -f "$crud_trace" ]] \
   && grep -q '"failure_kind":"test_failure"' "$crud_trace" \
   && grep -q '"repair_source":"policy:test_failure"' "$crud_trace" \
   && grep -q '"event":"agent.run.complete"' "$crud_trace"; then
  tc_ok
else
  tc_fail "expected CRUD demo to pass through policy repair loop; rc=$rc output:
    $out"
fi

tc_summary
