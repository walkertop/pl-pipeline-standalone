#!/usr/bin/env bash
# =============================================================================
# adapter-kotlin lint.sh
# =============================================================================
# 静态检查：detekt + ktlint（若存在）。适合 Git pre-commit hook。
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ Kotlin lint @ $PROJECT_ROOT"

# detekt（若项目配置了该插件）
if ./gradlew tasks --all 2>/dev/null | grep -qE '^\s*detekt\s'; then
  echo "• detekt"
  ./gradlew detekt --continue
else
  echo "ℹ detekt task not found (add io.gitlab.arturbosch.detekt plugin to enable)"
fi

# ktlint（若项目配置了该插件）
if ./gradlew tasks --all 2>/dev/null | grep -qE '^\s*ktlintCheck\s'; then
  echo "• ktlintCheck"
  ./gradlew ktlintCheck --continue
else
  echo "ℹ ktlintCheck task not found (add org.jlleitschuh.gradle.ktlint plugin to enable)"
fi

echo "✅ Lint passed (or no lint tasks configured)"
