#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

export PL_HOME="$REPO_ROOT"
export PL_PROJECT="$HERE"

"$REPO_ROOT/bin/pl" agent run \
  --change agent-loop-demo \
  --task T03 \
  --executor local \
  --cmd "./scripts/write_bad_impl.sh" \
  --verify-gate D \
  --repair-cmd "./scripts/repair_impl.sh" \
  --max-retries 1

(cd "$HERE" && python3 -m unittest discover -s tests)

TRACE_FILE="$HERE/pipeline-output/trace/agent-loop-demo.events.jsonl"
grep -q '"event":"agent.run.start"' "$TRACE_FILE"
grep -q '"event":"agent.repair.context"' "$TRACE_FILE"
grep -q '"event":"agent.run.complete"' "$TRACE_FILE"

printf '\nDemo OK\n'
printf 'Trace: %s\n' "$TRACE_FILE"
