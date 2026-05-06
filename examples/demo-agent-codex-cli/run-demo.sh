#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
FAKE_BIN="$HERE/.tmp-bin"

rm -rf "$FAKE_BIN"
mkdir -p "$FAKE_BIN"
ln -s "$HERE/scripts/fake-codex.sh" "$FAKE_BIN/codex"

export PL_HOME="${PL_HOME:-$REPO_ROOT}"
export PL_PROJECT="$HERE"
export PATH="$FAKE_BIN:$PATH"

"$PL_HOME/bin/pl" agent run \
  --change codex-cli-demo \
  --task T02 \
  --executor codex-cli \
  --model codex-fake-model \
  --prompt-path prompts/implement.md \
  --output-artifact app/codex-result.txt \
  --json

grep -Fq 'args: [exec]' "$HERE/codex-invocation.log"
grep -Fq '[--cd]' "$HERE/codex-invocation.log"
grep -Fq '[--sandbox] [workspace-write]' "$HERE/codex-invocation.log"
grep -Fq '[--ask-for-approval] [never]' "$HERE/codex-invocation.log"
grep -Fq '[-m] [codex-fake-model]' "$HERE/codex-invocation.log"
grep -Fq 'Create `app/codex-result.txt`' "$HERE/codex-invocation.log"
grep -q 'codex fake ok' "$HERE/app/codex-result.txt"

TRACE_FILE="$HERE/pipeline-output/trace/codex-cli-demo.events.jsonl"
grep -q '"executor":"codex-cli"' "$TRACE_FILE"
grep -q '"provider":"openai"' "$TRACE_FILE"
grep -Fq '"tool_calls":["codex.exec"]' "$TRACE_FILE"
grep -Fq '"output_artifacts":["app/codex-result.txt"]' "$TRACE_FILE"

printf '\nCodex CLI Demo OK\n'
printf 'Trace: %s\n' "$TRACE_FILE"
