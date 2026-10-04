#!/usr/bin/env bash
# run_eslint_performance.sh — lint JS/TS/React with ESLint (free, MIT) via the CLI and
# emit machine-readable JSON evidence.
#
# Decision: the ESLint MCP server (mcp__ESLint__lint-files) is the primary channel when
# configured. This CLI script remains as a deterministic, headless/CI-friendly fallback that
# writes a report file; it is used only when the MCP server is not available.
#
# The react-hooks diagnostics come from the project's own ESLint config, which already
# includes eslint-plugin-react-hooks in most React projects. If no config/local install is
# present, this script SKIPs and Biome (run_biome_performance.sh) covers JS/TS instead.
#
# Usage: bash run_eslint_performance.sh [PROJECT_DIR]
# Evidence output: <PROJECT_DIR>/.perf-reports/eslint-report.json
# Prints one terminal status line: STATUS: OK | SKIP | FAIL
#   SKIP = no JS/TS project, or no ESLint config/install — NOT a review failure.
set -u

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir: $1)"; exit 1; }
REPORT_DIR="${PERF_REPORT_DIR:-$PROJECT_DIR/.perf-reports}"
REPORT="$REPORT_DIR/eslint-report.json"
mkdir -p "$REPORT_DIR"

js_files() {  # $1 = dir
  find "$1" -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) \
    -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null | grep -q .
}

if [ ! -f "$PROJECT_DIR/package.json" ] && ! js_files "$PROJECT_DIR"; then
  echo "[eslint] no JS/TS project detected under $PROJECT_DIR"
  echo "STATUS: SKIP"
  exit 0
fi

# Pick the first known source root that actually contains JS/TS files; else the project root.
SCAN_ROOT="$PROJECT_DIR"
for cand in frontend/src src app frontend client; do
  if [ -d "$PROJECT_DIR/$cand" ] && js_files "$PROJECT_DIR/$cand"; then
    SCAN_ROOT="$PROJECT_DIR/$cand"; break
  fi
done
echo "[eslint] scanning: $SCAN_ROOT"

# ESLint needs a config. Accept flat, legacy, or package.json "eslintConfig".
HAS_CONFIG=0
if ls "$PROJECT_DIR"/eslint.config.* "$PROJECT_DIR"/.eslintrc* >/dev/null 2>&1; then
  HAS_CONFIG=1
elif [ -f "$PROJECT_DIR/package.json" ] && grep -q '"eslintConfig"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  HAS_CONFIG=1
fi

ESLINT_BIN=""
if [ -x "$PROJECT_DIR/node_modules/.bin/eslint" ]; then
  ESLINT_BIN="$PROJECT_DIR/node_modules/.bin/eslint"
elif command -v eslint >/dev/null 2>&1; then
  ESLINT_BIN="$(command -v eslint)"
fi

if [ -z "$ESLINT_BIN" ]; then
  if ! command -v npx >/dev/null 2>&1; then
    echo "[eslint] no 'eslint' and no 'npx'."
    echo "[eslint] install: npm i -D eslint eslint-plugin-react-hooks (see INSTALL.md)"
    echo "STATUS: SKIP"
    exit 0
  fi
  if [ "$HAS_CONFIG" = "0" ]; then
    echo "[eslint] no ESLint config and no local install; skipping (Biome covers JS/TS)."
    echo "[eslint] to add react-hooks rules: npm i -D eslint eslint-plugin-react-hooks (see INSTALL.md)"
    echo "STATUS: SKIP"
    exit 0
  fi
  echo "[eslint] no local 'eslint'; using npx with the project config."
  (cd "$PROJECT_DIR" && npx --yes eslint --format json --output-file "$REPORT" "$SCAN_ROOT" \
    > "$REPORT_DIR/eslint-stdout.log" 2> "$REPORT_DIR/eslint-stderr.log") || true
else
  echo "[eslint] using: $ESLINT_BIN"
  (cd "$PROJECT_DIR" && "$ESLINT_BIN" --format json --output-file "$REPORT" "$SCAN_ROOT" \
    > "$REPORT_DIR/eslint-stdout.log" 2> "$REPORT_DIR/eslint-stderr.log") || true
fi

if [ ! -s "$REPORT" ]; then
  echo "[eslint] produced no report (no matching files or ESLint errored); see eslint-stderr.log"
  echo "STATUS: FAIL"
  exit 1
fi

count=$(jq -r '[.[] | (.messages | length)] | add // 0' "$REPORT" 2>/dev/null || echo "?")
files=$(jq -r 'length' "$REPORT" 2>/dev/null || echo "?")

if [ "$count" = "?" ]; then
  echo "[eslint] report exists but is not parseable JSON; leaving raw report at $REPORT"
  echo "STATUS: OK report=$REPORT"; exit 0
fi

echo "[eslint] $count issue(s) across $files file(s)."
echo "STATUS: OK report=$REPORT"
exit 0
