#!/usr/bin/env bash
# perf_report.sh — manage the per-run performance report folder.
#
# Every review run gets its own folder under <PROJECT_DIR>/.perf-reports/<run_id>/:
#
#   .perf-reports/
#   ├── latest -> 2026-10-04_22-30-07        (symlink to the newest run)
#   └── 2026-10-04_22-30-07/
#       ├── report.md          human-readable report (from assets/report-template.md)
#       ├── findings.json      machine-readable findings (agent-filled)
#       ├── meta.json          run metadata (project, git ref, rules version, gate choice)
#       ├── summary.txt/.json  tool status table (run_all_performance.sh)
#       └── <tool>-report.*    raw evidence from each analyzer
#
# Usage:
#   bash perf_report.sh init   [PROJECT_DIR]   # create a run folder; prints its path
#   bash perf_report.sh latest [PROJECT_DIR]   # print the newest run folder path
#   bash perf_report.sh --help
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/report-template.md"
REGISTRY="$SKILL_DIR/references/performance-rule-list.md"

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

resolved() {  # $1 = project dir (default pwd)
  (cd "${1:-$(pwd)}" 2>/dev/null && pwd) || { echo "perf_report: bad project dir: ${1:-}" >&2; exit 1; }
}

cmd_init() {
  local project root run_id run_dir git_ref rule_count now
  project="$(resolved "${1:-}")" || exit 1
  root="$project/.perf-reports"
  run_id="$(date '+%Y-%m-%d_%H-%M-%S')"
  run_dir="$root/$run_id"
  now="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  git_ref="$(git -C "$project" rev-parse --short HEAD 2>/dev/null || echo "n/a")"
  rule_count="$(grep -cE '^\| \[[x~ ]\] \| PERF-' "$REGISTRY" 2>/dev/null || echo 0)"

  mkdir -p "$run_dir"
  if [ -f "$TEMPLATE" ]; then
    sed -e "s|{{PROJECT_DIR}}|$project|g" \
        -e "s|{{RUN_ID}}|$run_id|g" \
        -e "s|{{GENERATED_AT}}|$now|g" \
        -e "s|{{GIT_REF}}|$git_ref|g" \
        -e "s|{{RULE_COUNT}}|$rule_count|g" \
        -e "s|{{GATE_CHOICE}}|use-existing|g" \
        -e "s|{{TOOLS_SUMMARY}}|pending|g" \
        -e "s|{{VERDICT}}|Review in progress|g" \
        "$TEMPLATE" > "$run_dir/report.md"
  fi

  cat > "$run_dir/meta.json" <<EOF
{
  "run_id": "$run_id",
  "generated_at": "$now",
  "project": "$project",
  "git_ref": "$git_ref",
  "rule_registry": "references/performance-rule-list.md",
  "rule_count": $rule_count,
  "gate_choice": "use-existing",
  "skill_version": "2.2"
}
EOF

  cat > "$run_dir/findings.json" <<'EOF'
{
  "summary": { "critical": 0, "high": 0, "medium": 0, "low": 0 },
  "findings": [],
  "excluded_non_perf": [],
  "tools": []
}
EOF

  ln -sfn "$run_id" "$root/latest" 2>/dev/null || true
  echo "$run_dir"
}

cmd_latest() {
  local project root
  project="$(resolved "${1:-}")" || exit 1
  root="$project/.perf-reports"
  if [ -L "$root/latest" ]; then
    echo "$root/$(readlink "$root/latest")"
  else
    local newest
    newest="$(ls -1d "$root"/*/ 2>/dev/null | sort | tail -1)"
    [ -n "$newest" ] && echo "${newest%/}" || { echo "perf_report: no run folder under $root" >&2; exit 1; }
  fi
}

case "${1:-}" in
  init)   shift; cmd_init "$@" ;;
  latest) shift; cmd_latest "$@" ;;
  --help|-h|"") usage ;;
  *) echo "perf_report: unknown subcommand: $1" >&2; usage; exit 1 ;;
esac
