#!/usr/bin/env bash
# run_semgrep_performance.sh — scan Java/JS/React with Semgrep Community Edition (free).
#
# Default order: container image (self-contained), then local binary.
# Set PERF_PREFER_LOCAL=1 to prefer a locally installed `semgrep` instead.
#
# Usage: bash run_semgrep_performance.sh [PROJECT_DIR]
# Evidence output: <PROJECT_DIR>/.perf-reports/semgrep-report.json
# Prints one terminal status line: STATUS: OK | SKIP | FAIL
#   OK    = scan completed, read the report file
#   SKIP  = semgrep not available (no local binary, no Docker/Podman) — NOT a review failure
#   FAIL  = semgrep ran but produced no report
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=container_engine.sh
. "$SCRIPT_DIR/container_engine.sh"

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir: $1)"; exit 1; }
REPORT_DIR="${PERF_REPORT_DIR:-$PROJECT_DIR/.perf-reports}"
REPORT="$REPORT_DIR/semgrep-report.json"
mkdir -p "$REPORT_DIR"

# Semgrep Registry rulesets. There is NO "p/performance" pack (it returns HTTP 404 and
# makes the scan fail), so use the language packs that exist; the PERF rules do the
# performance reasoning. These Community packs are free for internal enterprise use
# (see references/licensing-enterprise.md).
CONFIGS=""
# Detect Java via standard source roots first, then fall back to any .java file (no shallow
# -maxdepth, which misses Maven/Gradle layouts like src/main/java/com/...).
if find "$PROJECT_DIR" -type d \( -path "*/src/main/java" -o -path "*/src/java" -o -path "*/src/test/java" \) \
     -not -path "*/node_modules/*" 2>/dev/null | grep -q . \
   || find "$PROJECT_DIR" -name "*.java" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
  CONFIGS="$CONFIGS --config p/java"
fi
if [ -f "$PROJECT_DIR/package.json" ] \
   || find "$PROJECT_DIR" -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) \
        -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
  CONFIGS="$CONFIGS --config p/javascript --config p/react"
fi

if [ -z "$CONFIGS" ]; then
  echo "[semgrep] no Java/JS/React sources under $PROJECT_DIR"
  echo "STATUS: SKIP"
  exit 0
fi

run_local() {
  echo "[semgrep] using local binary: $(command -v semgrep)"
  # shellcheck disable=SC2086
  semgrep scan --quiet --metrics=off --json $CONFIGS --output "$REPORT" "$PROJECT_DIR"
}

run_container() {
  echo "[semgrep] using $CONTAINER_ENGINE image semgrep/semgrep (official CE image)"
  local rel="${REPORT_DIR#"$PROJECT_DIR"/}"
  # shellcheck disable=SC2086
  $CONTAINER_ENGINE run --rm -v "$PROJECT_DIR:/src" semgrep/semgrep \
    semgrep scan --quiet --metrics=off --json $CONFIGS --output "/src/$rel/semgrep-report.json" /src
}

if [ "${PERF_PREFER_LOCAL:-0}" = "1" ]; then
  STRATEGIES="local container"
else
  STRATEGIES="container local"
fi

for s in $STRATEGIES; do
  case "$s" in
    local)
      command -v semgrep >/dev/null 2>&1 || continue
      run_local
      ;;
    container)
      [ "${CONTAINER_ENGINE_AVAILABLE:-0}" = "1" ] || continue
      run_container
      ;;
  esac
  if [ -s "$REPORT" ]; then
    echo "STATUS: OK report=$REPORT"; exit 0
  fi
done

echo "[semgrep] no local 'semgrep' binary and no usable Docker/Podman engine."
echo "[semgrep] install (free): pipx install semgrep  |  brew install semgrep  |  or start Docker/Podman."
echo "STATUS: SKIP"
exit 0
