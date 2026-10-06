#!/usr/bin/env bash
# perf_scope.sh — deterministic review scope + per-file rule resolution.
#
# This is the "engineering" half of the skill: it decides WHAT to review and WHICH
# rules apply to each file, before any LLM reasoning. It mirrors the idea behind
# open-code-review's `delegate preview` + `delegate rule`: hard constraints on the
# review process so large changesets cannot quietly drop files.
#
# Usage:
#   bash perf_scope.sh [preview] [PROJECT_DIR] [--from REF --to REF] [--commit HASH]
#                      [--exclude 'pat1,pat2'] [--format json|text] [--new]
#
# Outputs:
#   stdout : scope JSON (--format json, default) or a text table (--format text)
#   stderr : RUN_DIR=<path> for the current run
#   <run_dir>/scope.json     the same scope JSON
#   <run_dir>/coverage.json  coverage ledger skeleton (every reviewable file = "pending")
#
# Rules:
#   - Default excludes: build output, vendored, generated, lockfiles, snapshots.
#   - Non Java/JS/React files are excluded as out of scope.
#   - Deleted files are excluded (no new code to review).
#   - Files are never dropped silently: everything is either reviewable or excluded with a reason.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$SKILL_DIR/references/performance-rule-list.md"
PATH_RULES="$SKILL_DIR/references/perf-path-rules.json"

usage() {
  sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Optional `preview` subcommand (kept for symmetry with `ocr delegate preview`).
if [ $# -gt 0 ]; then
  case "$1" in
    preview) shift ;;
    --help|-h) usage; exit 0 ;;
  esac
fi

PROJECT_DIR="$(pwd)"
FROM=""; TO=""; COMMIT=""; FORMAT="json"; NEW_RUN=0; EXCLUDES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="${2:-}"; shift 2 ;;
    --to) TO="${2:-}"; shift 2 ;;
    -c|--commit) COMMIT="${2:-}"; shift 2 ;;
    --exclude) EXCLUDES="${2:-}"; shift 2 ;;
    -f|--format) FORMAT="${2:-}"; shift 2 ;;
    --new) NEW_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) PROJECT_DIR="$1"; shift ;;
  esac
done

PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "perf_scope: bad project dir" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "perf_scope: git is required" >&2; exit 1; }
git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || { echo "perf_scope: not a git repository: $PROJECT_DIR" >&2; exit 1; }

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# ---- glob translation: '**/' -> '*', '**' -> '*' (bash `case` '*' also spans '/') ----
translate_glob() {
  local p="$1"
  p="${p//\*\*\//*}"
  p="${p//\*\*/*}"
  printf '%s' "$p"
}
glob_match() { case "$2" in $1) return 0 ;; esac; return 1; }

# ---- git: determine mode and collect changed files as "STATUS<TAB>PATH[<TAB>PATH]" ----
MODE="workspace"; MERGE_BASE=""
tmp="$(mktemp "${TMPDIR:-/tmp}/perf_scope.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

if [ -n "$COMMIT" ]; then
  MODE="commit"
  git -C "$PROJECT_DIR" show --name-status --format= "$COMMIT" > "$tmp" 2>/dev/null \
    || { echo "perf_scope: cannot read commit $COMMIT" >&2; exit 1; }
elif [ -n "$FROM" ] && [ -n "$TO" ]; then
  MODE="range"
  MERGE_BASE="$(git -C "$PROJECT_DIR" merge-base "$FROM" "$TO" 2>/dev/null || echo "$FROM")"
  git -C "$PROJECT_DIR" diff --name-status "$MERGE_BASE..$TO" > "$tmp" 2>/dev/null \
    || { echo "perf_scope: cannot diff $MERGE_BASE..$TO" >&2; exit 1; }
else
  MODE="workspace"
  { git -C "$PROJECT_DIR" diff --name-status HEAD 2>/dev/null || true
    git -C "$PROJECT_DIR" ls-files --others --exclude-standard 2>/dev/null | sed 's/^/A\t/'
  } > "$tmp"
fi

# ---- Spring/JPA detection (drives PERF-SPRING attachment) ----
IS_SPRING=0
while IFS= read -r f; do
  if grep -qiE 'spring|hibernate|jakarta\.persistence|javax\.persistence' "$f" 2>/dev/null; then
    IS_SPRING=1; break
  fi
done < <(find "$PROJECT_DIR" -maxdepth 3 \( -name pom.xml -o -name build.gradle -o -name build.gradle.kts \) \
           -not -path '*/node_modules/*' 2>/dev/null)
if [ "$IS_SPRING" = "0" ]; then
  if grep -rIl -m1 -E '@SpringBootApplication|@EnableJpaRepositories|@Entity|@Repository|org\.springframework|jakarta\.persistence|javax\.persistence' \
       --include='*.java' --exclude-dir=node_modules --exclude-dir=target --exclude-dir=build \
       "$PROJECT_DIR" 2>/dev/null | head -1 | grep -q .; then
    IS_SPRING=1
  fi
fi

# ---- rule resolution: prefixes -> concrete PERF IDs from the registry ----
ALL_RULES="$(grep -Eo 'PERF-[A-Z0-9-]+' "$REGISTRY" 2>/dev/null | sort -u)"
ALWAYS_PREFIXES=""
if [ -f "$PATH_RULES" ]; then
  ALWAYS_PREFIXES="$(sed -n 's/.*"always"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$PATH_RULES" | tr -d ' "' | tr ',' ' ')"
fi

resolve_rule_ids() {  # $1 = path -> newline-separated PERF IDs
  local path="$1" line pat grps when prefixes=""
  if [ -f "$PATH_RULES" ]; then
    while IFS= read -r line; do
      case "$line" in
        *'"path"'*'"groups"'*) ;;
        *) continue ;;
      esac
      pat="$(printf '%s' "$line" | sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
      grps="$(printf '%s' "$line" | sed -n 's/.*"groups"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | tr -d ' "' | tr ',' ' ')"
      when="$(printf '%s' "$line" | sed -n 's/.*"when"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
      [ -z "$pat" ] && continue
      glob_match "$(translate_glob "$pat")" "$path" || continue
      case "$when" in
        spring) [ "$IS_SPRING" = "1" ] || continue ;;
      esac
      [ -n "$grps" ] && prefixes="$prefixes $grps"
    done < "$PATH_RULES"
  fi
  prefixes="$prefixes $ALWAYS_PREFIXES"
  local pfx
  for pfx in $prefixes; do
    printf '%s\n' "$ALL_RULES" | grep -E "^${pfx}-" || true
  done | sort -u
}

# ---- exclusion rules ----
USER_EXCLUDES=""
if [ -n "$EXCLUDES" ]; then USER_EXCLUDES="$(printf '%s' "$EXCLUDES" | tr ',' ' ')"; fi
if [ -f "$PROJECT_DIR/.perf-excludes" ]; then
  USER_EXCLUDES="$USER_EXCLUDES $(grep -v '^[[:space:]]*#' "$PROJECT_DIR/.perf-excludes" 2>/dev/null | tr '\n' ' ')"
fi

excluded_reason() {  # $1 = path -> reason (empty = not excluded by defaults)
  local p="$1"
  case "$p" in
    *node_modules/*|node_modules/*) echo "vendored (node_modules)"; return ;;
    */dist/*|dist/*) echo "build output (dist)"; return ;;
    */build/*|build/*) echo "build output (build)"; return ;;
    */target/*|target/*) echo "build output (target)"; return ;;
    */out/*|out/*) echo "build output (out)"; return ;;
    */vendor/*|vendor/*) echo "vendored"; return ;;
    */third_party/*|third_party/*) echo "vendored (third_party)"; return ;;
    */generated/*|generated/*|*/gen/*) echo "generated code"; return ;;
    */.git/*) echo "git internals"; return ;;
    */.perf-reports/*|.perf-reports/*) echo "perf run artifacts"; return ;;
    *.min.js|*.min.css|*.map) echo "generated/minified"; return ;;
    *.lock|package-lock.json|yarn.lock|pnpm-lock.yaml|go.sum) echo "lockfile"; return ;;
    */__snapshots__/*|*.snap) echo "snapshot"; return ;;
  esac
  echo ""
}

lang_of() {
  case "$1" in
    *.java) echo java ;;
    *.js|*.jsx) echo javascript ;;
    *.ts|*.tsx) echo typescript ;;
    *) echo "" ;;
  esac
}

# ---- classify every changed file ----
declare -a R_JSON=() C_JSON=() E_JSON=()
TOTAL_CHANGED=0
while IFS=$'\t' read -r st p1 p2; do
  [ -z "${st:-}" ] && continue
  case "$st" in
    R*|C*) path="$p2"; status="${st:0:1}" ;;
    *)     path="$p1"; status="$st" ;;
  esac
  [ -z "${path:-}" ] && continue
  TOTAL_CHANGED=$((TOTAL_CHANGED + 1))

  if [ "$status" = "D" ]; then
    E_JSON+=("  {\"path\": \"$(json_escape "$path")\", \"reason\": \"deleted (no new code)\"}")
    continue
  fi

  reason="$(excluded_reason "$path")"
  if [ -z "$reason" ] && [ -n "$USER_EXCLUDES" ]; then
    for up in $USER_EXCLUDES; do
      if glob_match "$(translate_glob "$up")" "$path"; then reason="excluded by pattern: $up"; break; fi
    done
  fi
  if [ -z "$reason" ]; then
    lang="$(lang_of "$path")"
    [ -z "$lang" ] && reason="out of scope (non Java/JS/React)"
  fi
  if [ -n "$reason" ]; then
    E_JSON+=("  {\"path\": \"$(json_escape "$path")\", \"reason\": \"$(json_escape "$reason")\"}")
    continue
  fi

  ids="$(resolve_rule_ids "$path")"
  rc="$(printf '%s\n' "$ids" | grep -c . || true)"
  rules_json="$(printf '%s\n' "$ids" | awk 'NF{printf "%s\"%s\"", (n++?",":""), $0}')"
  R_JSON+=("  {\"path\": \"$(json_escape "$path")\", \"status\": \"$status\", \"language\": \"$lang\", \"rule_count\": $rc, \"rule_ids\": [$rules_json]}")
  C_JSON+=("    {\"path\": \"$(json_escape "$path")\", \"status\": \"pending\", \"reason\": \"\", \"findings\": 0}")
done < "$tmp"

join() { local first=1 e; for e in "$@"; do [ $first -eq 1 ] || printf ',\n'; printf '%s' "$e"; first=0; done; }
rv=""; [ ${#R_JSON[@]} -gt 0 ] && rv="$(join "${R_JSON[@]}")"
ev=""; [ ${#E_JSON[@]} -gt 0 ] && ev="$(join "${E_JSON[@]}")"
cv=""; [ ${#C_JSON[@]} -gt 0 ] && cv="$(join "${C_JSON[@]}")"

RCOUNT=${#R_JSON[@]}
ECOUNT=${#E_JSON[@]}
NOW="$(date '+%Y-%m-%dT%H:%M:%S%z')"

JSON="$(cat <<EOF
{
  "mode": "$MODE",
  "project": "$(json_escape "$PROJECT_DIR")",
  "from": "$(json_escape "$FROM")",
  "to": "$(json_escape "$TO")",
  "commit": "$(json_escape "$COMMIT")",
  "merge_base": "$(json_escape "$MERGE_BASE")",
  "spring_detected": $IS_SPRING,
  "generated_at": "$NOW",
  "total_changed": $TOTAL_CHANGED,
  "reviewable_count": $RCOUNT,
  "excluded_count": $ECOUNT,
  "reviewable_files": [
$rv
  ],
  "excluded_files": [
$ev
  ]
}
EOF
)"

# ---- run folder: reuse PERF_RUN_DIR when set, else create a fresh one ----
if [ "$NEW_RUN" = "1" ]; then
  RUN_DIR="$(PERF_RUN_DIR="" bash "$SCRIPT_DIR/perf_report.sh" init --new "$PROJECT_DIR")"
else
  RUN_DIR="$(bash "$SCRIPT_DIR/perf_report.sh" init "$PROJECT_DIR")"
fi
[ -d "$RUN_DIR" ] || { echo "perf_scope: could not create run folder" >&2; exit 1; }

printf '%s\n' "$JSON" > "$RUN_DIR/scope.json"
cat > "$RUN_DIR/coverage.json" <<EOF
{
  "run_id": "$(basename "$RUN_DIR")",
  "total_files": $RCOUNT,
  "reviewed_files": 0,
  "skipped_files": 0,
  "pending_files": $RCOUNT,
  "coverage_rate": 0,
  "files": [
$cv
  ]
}
EOF

echo "RUN_DIR=$RUN_DIR" >&2

if [ "$FORMAT" = "text" ]; then
  echo "Scope ($MODE) — project: $PROJECT_DIR"
  echo "Spring/JPA detected: $IS_SPRING"
  echo "Changed: $TOTAL_CHANGED  |  reviewable: $RCOUNT  |  excluded: $ECOUNT"
  echo
  printf '%-50s %-4s %-10s %s\n' "REVIEWABLE" "ST" "LANG" "RULES"
  printf '%s\n' "$rv" | sed -n 's/.*"path": "\([^"]*\)".*"status": "\([^"]*\)".*"language": "\([^"]*\)".*"rule_count": \([0-9]*\).*/\1 \2 \3 \4/p' \
    | while read -r p s l c; do printf '%-50s %-4s %-10s %s\n' "$p" "$s" "$l" "$c"; done
  echo
  echo "Run folder: $RUN_DIR"
else
  printf '%s\n' "$JSON"
fi
exit 0
