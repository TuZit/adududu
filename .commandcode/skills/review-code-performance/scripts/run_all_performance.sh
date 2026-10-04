#!/usr/bin/env bash
# run_all_performance.sh — run every available free performance static analyzer and
# consolidate the evidence into a fresh per-run report folder.
#
# Usage:
#   bash run_all_performance.sh [PROJECT_DIR] [--tools pmd,spotbugs,semgrep,sonarqube,biome,eslint]
#
# Default tools: pmd,spotbugs,semgrep,biome,eslint (sonarqube needs a server + token).
# Output folder: <PROJECT_DIR>/.perf-reports/<run_id>/  (also symlinked as .../latest)
#   report.md          report skeleton for the agent to fill (assets/report-template.md)
#   findings.json      machine-readable findings for the agent to fill
#   meta.json          run metadata (project, git ref, rule count, gate choice)
#   summary.txt/.json   tool status table
#   <tool>-report.*    raw evidence from each analyzer
# This orchestrator always exits 0: a missing tool or a failing tool is evidence, not a
# reason to abort the review.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=container_engine.sh
. "$SCRIPT_DIR/container_engine.sh"
PROJECT_DIR="$(pwd)"
TOOLS="pmd,spotbugs,semgrep,biome,eslint"

while [ $# -gt 0 ]; do
  case "$1" in
    --tools) TOOLS="${2:-}"; shift 2 ;;
    --help|-h)
      sed -n '2,16p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) PROJECT_DIR="$1"; shift ;;
  esac
done

PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir)"; exit 1; }

# Create a fresh per-run report folder and route all tool evidence into it.
RUN_DIR="$(bash "$SCRIPT_DIR/perf_report.sh" init "$PROJECT_DIR")" \
  || { echo "STATUS: FAIL (could not create run folder)"; exit 1; }
export PERF_REPORT_DIR="$RUN_DIR"
REPORT_DIR="$RUN_DIR"
SUMMARY_TXT="$REPORT_DIR/summary.txt"
SUMMARY_JSON="$REPORT_DIR/summary.json"

declare -a NAMES=() STATUSES=() DETAILS=()

run_one() {
  local name="$1" script="$2"
  if [ ! -f "$SCRIPT_DIR/$script" ]; then
    NAMES+=("$name"); STATUSES+=("SKIP"); DETAILS+=("script not found")
    return
  fi
  echo "──────── $name ────────"
  local out status detail
  out="$(bash "$SCRIPT_DIR/$script" "$PROJECT_DIR" 2>&1)"
  echo "$out"
  status="$(printf '%s\n' "$out" | grep -Eo 'STATUS: (OK|SKIP|FAIL)' | tail -1 | awk '{print $2}')"
  detail="$(printf '%s\n' "$out" | grep -E '^STATUS:' | tail -1)"
  [ -z "$status" ] && status="FAIL"
  NAMES+=("$name"); STATUSES+=("$status"); DETAILS+=("${detail:-no status line}")
}

IFS=',' read -r -a WANTED <<< "$TOOLS"
for tool in "${WANTED[@]}"; do
  tool="$(printf '%s' "$tool" | tr -d '[:space:]')"
  case "$tool" in
    pmd)      run_one "pmd"      "run_pmd_performance.sh" ;;
    spotbugs) run_one "spotbugs" "run_spotbugs_performance.sh" ;;
    semgrep)  run_one "semgrep"  "run_semgrep_performance.sh" ;;
    sonarqube)run_one "sonarqube" "run_sonarqube_performance.sh" ;;
    biome)    run_one "biome"    "run_biome_performance.sh" ;;
    eslint)   run_one "eslint"   "run_eslint_performance.sh" ;;
    "" ) ;;
    *) echo "── unknown tool: $tool (ignored)" ;;
  esac
done

{
  echo "Performance static-tool summary — $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Project: $PROJECT_DIR"
  echo "Container engine: ${CONTAINER_ENGINE:-none}"
  echo
  printf '%-12s %-6s %s\n' "TOOL" "STATUS" "DETAIL"
  for i in "${!NAMES[@]}"; do
    printf '%-12s %-6s %s\n' "${NAMES[$i]}" "${STATUSES[$i]}" "${DETAILS[$i]}"
  done
} | tee "$SUMMARY_TXT"

{
  echo "{"
  echo "  \"project\": \"$PROJECT_DIR\","
  echo "  \"generated_at\": \"$(date '+%Y-%m-%dT%H:%M:%S')\","
  echo "  \"tools\": ["
  for i in "${!NAMES[@]}"; do
    sep=","; [ "$i" -eq $(( ${#NAMES[@]} - 1 )) ] && sep=""
    detail="${DETAILS[$i]//\"/\\\"}"
    echo "    {\"name\": \"${NAMES[$i]}\", \"status\": \"${STATUSES[$i]}\", \"detail\": \"$detail\"}$sep"
  done
  echo "  ]"
  echo "}"
} > "$SUMMARY_JSON"

echo
echo "Report folder: $RUN_DIR"
echo "Next (agent review pass): fill $RUN_DIR/report.md and $RUN_DIR/findings.json"
echo "STATUS: OK report_dir=$RUN_DIR summary=$SUMMARY_TXT"
exit 0
