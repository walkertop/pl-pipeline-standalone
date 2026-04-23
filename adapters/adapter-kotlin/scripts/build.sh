#!/usr/bin/env bash
# =============================================================================
# adapter-kotlin build.sh
# =============================================================================
# 构建 Kotlin 项目的完整产物（compile + test + package）。
# 被注入为宿主项目的 scripts/adapter-kotlin-build.sh
#
# 约束：必须在宿主项目根目录执行，项目需包含 gradlew。
# 环境变量：
#   KOTLIN_BUILD_TASK=build    默认 gradle 任务，可覆盖为 assemble / jar 等
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "▶ Kotlin build @ $PROJECT_ROOT"

if [[ ! -f gradlew ]]; then
  echo "✗ gradlew not found. Kotlin projects without gradle wrapper are not supported by this adapter."
  echo "  Please run: gradle wrapper"
  exit 1
fi

TASK="${KOTLIN_BUILD_TASK:-build}"

# 1) compile check（快，先跑）
echo "• Step 1/3 — compile check"
./gradlew compileKotlin --quiet

# 2) test
echo "• Step 2/3 — test"
./gradlew test --continue

# 3) build
echo "• Step 3/3 — ./gradlew $TASK"
./gradlew "$TASK" --continue

echo "✅ Build succeeded"
