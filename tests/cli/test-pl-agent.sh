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

tc_summary
