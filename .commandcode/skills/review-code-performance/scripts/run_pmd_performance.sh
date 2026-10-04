#!/usr/bin/env bash
# run_pmd_performance.sh — scan Java sources with PMD (free, BSD-style license),
# Java performance category only.
#
# Default order: container image (self-contained, no manual install), then local binary.
# Set PERF_PREFER_LOCAL=1 to prefer a locally installed `pmd` instead.
#
# Usage: bash run_pmd_performance.sh [PROJECT_DIR]
# Evidence output: <PROJECT_DIR>/.perf-reports/pmd-report.xml
# Prints one terminal status line: STATUS: OK | SKIP | FAIL
#   SKIP = PMD unavailable, or no Java sources found — NOT a review failure.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=container_engine.sh
. "$SCRIPT_DIR/container_engine.sh"

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir: $1)"; exit 1; }
REPORT_DIR="${PERF_REPORT_DIR:-$PROJECT_DIR/.perf-reports}"
REPORT="$REPORT_DIR/pmd-report.xml"
mkdir -p "$REPORT_DIR"

# PMD 7 built-in performance ruleset (verified path: category/java/performance.xml).
RULESET="category/java/performance.xml"

# Collect Java source roots (fall back to whole tree minus node_modules/build dirs).
SRC_DIRS=()
while IFS= read -r d; do SRC_DIRS+=("$d"); done < <(
  find "$PROJECT_DIR" -type d \( -path "*/src/main/java" -o -path "*/src/java" \) \
    -not -path "*/node_modules/*" -not -path "*/build/tmp/*" 2>/dev/null
)
if [ ${#SRC_DIRS[@]} -eq 0 ]; then
  if find "$PROJECT_DIR" -name "*.java" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
    SRC_DIRS=("$PROJECT_DIR")
  else
    echo "[pmd] no Java sources under $PROJECT_DIR"
    echo "STATUS: SKIP"
    exit 0
  fi
fi
printf '[pmd] scanning: %s\n' "${SRC_DIRS[@]}"

ARG=(-d)
for d in "${SRC_DIRS[@]}"; do ARG+=("$d"); done
DARG=()
for d in "${SRC_DIRS[@]}"; do DARG+=(-d "/src${d#"$PROJECT_DIR"}"); done

run_local() {
  echo "[pmd] using local binary: $(command -v pmd)" >&2
  pmd check "${ARG[@]}" -R "$RULESET" -f xml
}

run_container() {
  echo "[pmd] using $CONTAINER_ENGINE image pmd/pmd" >&2
  $CONTAINER_ENGINE run --rm -v "$PROJECT_DIR:/src" pmd/pmd pmd check "${DARG[@]}" -R "$RULESET" -f xml
}

if [ "${PERF_PREFER_LOCAL:-0}" = "1" ]; then
  STRATEGIES="local container"
else
  STRATEGIES="container local"
fi

for s in $STRATEGIES; do
  case "$s" in
    local)
      command -v pmd >/dev/null 2>&1 || continue
      run_local > "$REPORT" 2>"$REPORT_DIR/pmd-stderr.log"
      ;;
    container)
      [ "${CONTAINER_ENGINE_AVAILABLE:-0}" = "1" ] || continue
      run_container > "$REPORT" 2>"$REPORT_DIR/pmd-stderr.log"
      ;;
  esac
  # PMD writes the XML report even when violations are found, so judge by the report,
  # not the exit code (PMD exits non-zero on findings).
  if [ -s "$REPORT" ]; then
    echo "STATUS: OK report=$REPORT"; exit 0
  fi
done

echo "[pmd] no local 'pmd' binary and no usable Docker/Podman engine."
echo "[pmd] install (free): brew install pmd  |  or download from https://github.com/pmd/pmd/releases"
echo "STATUS: SKIP"
exit 0
