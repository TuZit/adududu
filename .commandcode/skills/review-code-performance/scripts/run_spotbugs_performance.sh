#!/usr/bin/env bash
# run_spotbugs_performance.sh — run SpotBugs (free, open source) on compiled Java
# bytecode, PERFORMANCE bug category only.
#
# Usage: bash run_spotbugs_performance.sh [PROJECT_DIR]
# Requires compiled .class files or a jar (SpotBugs analyzes bytecode, not sources).
# Evidence output: <PROJECT_DIR>/.perf-reports/spotbugs-report.xml
# Prints one terminal status line: STATUS: OK | SKIP | FAIL
#   SKIP = SpotBugs unavailable or nothing compiled to analyze — NOT a review failure.
set -u

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir: $1)"; exit 1; }
REPORT_DIR="${PERF_REPORT_DIR:-$PROJECT_DIR/.perf-reports}"
REPORT="$REPORT_DIR/spotbugs-report.xml"
mkdir -p "$REPORT_DIR"

# Prefer the Maven/Gradle SpotBugs plugin output (already produced by the build).
# The plugin XML contains all bug categories; the review pass filters to PERFORMANCE.
PLUGIN_XML=""
for candidate in "$PROJECT_DIR/target/spotbugsXml.xml" \
                "$PROJECT_DIR/build/reports/spotbugs/main.xml"; do
  [ -f "$candidate" ] && PLUGIN_XML="$candidate" && break
done
if [ -n "$PLUGIN_XML" ]; then
  cp "$PLUGIN_XML" "$REPORT"
  echo "[spotbugs] using build plugin output: $PLUGIN_XML"
  echo "[spotbugs] note: plugin XML includes all bug categories; review pass filters to PERFORMANCE."
  echo "STATUS: OK report=$REPORT"; exit 0
fi

# Find compiled output (Maven or Gradle layout).
TARGETS=()
while IFS= read -r d; do TARGETS+=("$d"); done < <(
  find "$PROJECT_DIR" -type d \( -path "*/target/classes" -o -path "*/build/classes/java/main" \) \
    -not -path "*/node_modules/*" 2>/dev/null | head -20
)
JAR=$(find "$PROJECT_DIR" -maxdepth 3 \( -path "*/target/*.jar" -o -path "*/build/libs/*.jar" \) \
      -not -name "*-sources.jar" -not -name "*-javadoc.jar" 2>/dev/null | head -1)

if [ ${#TARGETS[@]} -eq 0 ] && [ -z "$JAR" ]; then
  echo "[spotbugs] no compiled classes/jar found — build the project first (mvn -DskipTests package / gradle classes)."
  echo "STATUS: SKIP"
  exit 0
fi
[ -n "$JAR" ] && TARGETS+=("$JAR")
printf '[spotbugs] analyzing: %s\n' "${TARGETS[@]}"

# SpotBugs CLI options verified against official docs (spotbugs.readthedocs.io/en/stable/running.html):
#   -textui, -xml:withMessages, -output FILE, -bugCategories PERFORMANCE
run_textui() {  # $1 = command prefix (e.g. "spotbugs" or "java -jar /path/spotbugs.jar")
  $1 -textui -xml:withMessages -bugCategories PERFORMANCE -output "$REPORT" "${TARGETS[@]}"
}

if command -v spotbugs >/dev/null 2>&1; then
  echo "[spotbugs] using local binary: $(command -v spotbugs)"
  if run_textui spotbugs; then echo "STATUS: OK report=$REPORT"; exit 0; fi
elif [ -n "${SPOTBUGS_HOME:-}" ] && [ -f "$SPOTBUGS_HOME/lib/spotbugs.jar" ] && command -v java >/dev/null 2>&1; then
  echo "[spotbugs] using SPOTBUGS_HOME jar"
  if run_textui "java -jar $SPOTBUGS_HOME/lib/spotbugs.jar"; then echo "STATUS: OK report=$REPORT"; exit 0; fi
elif [ -n "${SPOTBUGS_JAR:-}" ] && [ -f "$SPOTBUGS_JAR" ] && command -v java >/dev/null 2>&1; then
  echo "[spotbugs] using SPOTBUGS_JAR"
  if run_textui "java -jar $SPOTBUGS_JAR"; then echo "STATUS: OK report=$REPORT"; exit 0; fi
else
  echo "[spotbugs] no 'spotbugs' binary and no SPOTBUGS_HOME/SPOTBUGS_JAR set."
  echo "[spotbugs] install (free): brew install spotbugs  |  or download from https://github.com/spotbugs/spotbugs/releases"
  echo "[spotbugs] or use the Maven/Gradle SpotBugs plugin in the project build."
  echo "STATUS: SKIP"
  exit 0
fi

echo "STATUS: FAIL (spotbugs exited non-zero; SpotBugs uses exit codes 1-3 for found bugs — check report)"
exit 1
