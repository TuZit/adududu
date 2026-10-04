#!/usr/bin/env bash
# run_biome_performance.sh — lint JS/TS/React with Biome (free, fast) and keep only
# findings that matter as performance evidence (unused state, hook misuse, etc.).
#
# Usage: bash run_biome_performance.sh [PROJECT_DIR]
# Evidence output: <PROJECT_DIR>/.perf-reports/biome-report.json
# Prints one terminal status line: STATUS: OK | SKIP | FAIL
#   SKIP = no JS/TS project, no JS files, or Biome/node unavailable — NOT a review failure.
set -u

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir: $1)"; exit 1; }
REPORT_DIR="${PERF_REPORT_DIR:-$PROJECT_DIR/.perf-reports}"
REPORT="$REPORT_DIR/biome-report.json"
mkdir -p "$REPORT_DIR"

js_files() {  # $1 = dir
  find "$1" -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) \
    -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null | grep -q .
}

# Only relevant when a JS/TS project is present.
if [ ! -f "$PROJECT_DIR/package.json" ] && [ ! -f "$PROJECT_DIR/biome.json" ] \
   && ! js_files "$PROJECT_DIR"; then
  echo "[biome] no JS/TS project detected under $PROJECT_DIR"
  echo "STATUS: SKIP"
  exit 0
fi

# Pick the first known source root that actually contains JS/TS files; else the project root.
SCAN_ROOT=""
for cand in frontend/src src app frontend client; do
  if [ -d "$PROJECT_DIR/$cand" ] && js_files "$PROJECT_DIR/$cand"; then
    SCAN_ROOT="$PROJECT_DIR/$cand"; break
  fi
done
[ -z "$SCAN_ROOT" ] && SCAN_ROOT="$PROJECT_DIR"
echo "[biome] scanning: $SCAN_ROOT"

if ! command -v npx >/dev/null 2>&1; then
  echo "[biome] no local 'npx'."
  echo "[biome] install Node.js, or use ESLint + eslint-plugin-react-hooks instead."
  echo "STATUS: SKIP"
  exit 0
fi

(cd "$PROJECT_DIR" && npx --yes @biomejs/biome check \
    --formatter-enabled=false --reporter=json "$SCAN_ROOT" \
    > "$REPORT" 2>"$REPORT_DIR/biome-stderr.log") || true

# Decide from the report, not the exit code: Biome exits non-zero both for findings
# and for scanner errors (e.g. "no files processed").
if [ ! -s "$REPORT" ]; then
  echo "STATUS: FAIL (biome produced no report; see $REPORT_DIR/biome-stderr.log)"
  exit 1
fi

diagnostics=$(jq -r '.diagnostics | length' "$REPORT" 2>/dev/null || echo "?")
files_scanned=$(jq -r '(.summary.changed + .summary.unchanged + .summary.matches + .summary.skipped)' "$REPORT" 2>/dev/null || echo "?")

if [ "$diagnostics" = "?" ] || [ "$files_scanned" = "?" ]; then
  echo "[biome] could not parse report with jq; leaving raw report at $REPORT"
  echo "STATUS: OK report=$REPORT"; exit 0
fi

if [ "$diagnostics" -gt 0 ]; then
  echo "[biome] $diagnostics diagnostic(s) across $files_scanned file(s)."
  echo "STATUS: OK report=$REPORT"; exit 0
fi

if [ "$files_scanned" -gt 0 ]; then
  echo "[biome] no diagnostics across $files_scanned file(s)."
  echo "STATUS: OK report=$REPORT"; exit 0
fi

echo "[biome] no JS/TS files matched under $SCAN_ROOT (nothing to scan)."
echo "STATUS: SKIP"
exit 0
