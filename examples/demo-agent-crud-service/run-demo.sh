#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"

export PL_HOME="${PL_HOME:-$REPO_ROOT}"
export PL_PROJECT="$HERE"

"$PL_HOME/bin/pl" agent run \
  --change crud-service-demo \
  --task T04 \
  --executor local \
  --cmd "./scripts/write_bad_impl.sh" \
  --verify-gate D

(cd "$HERE" && python3 -m unittest discover -s tests)

TRACE_FILE="$HERE/pipeline-output/trace/crud-service-demo.events.jsonl"
grep -q '"failure_kind":"test_failure"' "$TRACE_FILE"
grep -q '"repair_source":"policy:test_failure"' "$TRACE_FILE"
grep -q '"event":"agent.run.complete"' "$TRACE_FILE"

printf '\nCRUD Demo OK\n'
printf 'Trace: %s\n' "$TRACE_FILE"
