#!/usr/bin/env bash
set -euo pipefail

{
  printf 'args:'
  for arg in "$@"; do
    printf ' [%s]' "$arg"
  done
  printf '\n'
  printf 'stdin:\n'
  cat
} > codex-invocation.log

mkdir -p app
printf 'codex fake ok\n' > app/codex-result.txt
printf '{"event":"fake-codex","tokens":{"input":11,"output":7}}\n'
