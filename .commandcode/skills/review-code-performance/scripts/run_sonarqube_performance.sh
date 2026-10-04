#!/usr/bin/env bash
# run_sonarqube_performance.sh — scan with SonarQube Community Build (free, LGPL-3.0) and
# export performance-relevant issues as JSON. Auto-starts the server via Docker/Podman
# compose when it is not already running, so you do not have to start it by hand.
#
# Usage: bash run_sonarqube_performance.sh [PROJECT_DIR]
# Needs: SONAR_TOKEN (see below), plus sonar-scanner (local) or a container engine.
# Evidence outputs:
#   <PROJECT_DIR>/.perf-reports/sonar-scan.log          scanner output
#   <PROJECT_DIR>/.perf-reports/sonar-perf-issues.json  performance issues (best effort)
# Prints one terminal status line: STATUS: OK | SKIP | FAIL
#   SKIP = no token, no scanner, or server cannot be started — NOT a review failure.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=container_engine.sh
. "$SCRIPT_DIR/container_engine.sh"

PROJECT_DIR="${1:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || { echo "STATUS: FAIL (bad project dir: $1)"; exit 1; }
REPORT_DIR="${PERF_REPORT_DIR:-$PROJECT_DIR/.perf-reports}"
mkdir -p "$REPORT_DIR"
HOST="${SONAR_HOST_URL:-http://localhost:9000}"
KEY="${SONAR_PROJECT_KEY:-$(basename "$PROJECT_DIR")}"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

server_up() {
  curl -sf -m 5 "$HOST/api/system/status" >/dev/null 2>&1 \
    || curl -sf -m 5 "$HOST/api/server/status" >/dev/null 2>&1
}

compose_cmd() {
  if [ -n "${CONTAINER_COMPOSE:-}" ]; then
    echo "$CONTAINER_COMPOSE"
  elif [ "${CONTAINER_ENGINE_AVAILABLE:-0}" = "1" ]; then
    echo "$CONTAINER_ENGINE compose"
  else
    echo ""
  fi
}

start_server() {
  local compose
  compose="$(compose_cmd)"
  if [ -z "$compose" ]; then
    echo "[sonar] no usable container engine/compose to auto-start the server."
    echo "[sonar] start it manually, or install Docker/Podman (see INSTALL.md)."
    return 1
  fi
  echo "[sonar] server not reachable; auto-starting: $compose -f scripts/docker-compose.yml up -d"
  # shellcheck disable=SC2086
  $compose -f "$COMPOSE_FILE" up -d || return 1
  echo "[sonar] waiting for SonarQube to become ready (first boot ~1 min)..."
  local i
  for i in $(seq 1 60); do
    server_up && { echo "[sonar] server ready at $HOST"; return 0; }
    sleep 2
  done
  echo "[sonar] server did not become ready in time; check: $compose -f scripts/docker-compose.yml logs"
  return 1
}

if ! server_up; then
  start_server || { echo "STATUS: SKIP"; exit 0; }
fi

if [ -z "${SONAR_TOKEN:-}" ]; then
  echo "[sonar] SONAR_TOKEN is not set. Community Build requires a token:"
  echo "[sonar] $HOST -> My Account -> Security -> Generate Tokens (type: Global Analysis)."
  echo "[sonar] then: SONAR_TOKEN=<token> bash run_sonarqube_performance.sh $PROJECT_DIR"
  echo "STATUS: SKIP"
  exit 0
fi

SCAN_LOG="$REPORT_DIR/sonar-scan.log"
run_scanner() {
  if command -v sonar-scanner >/dev/null 2>&1; then
    echo "[sonar] using local sonar-scanner"
    (cd "$PROJECT_DIR" && sonar-scanner \
      -Dsonar.projectKey="$KEY" -Dsonar.projectBaseDir="$PROJECT_DIR" \
      -Dsonar.host.url="$HOST" 2>&1) | tee "$SCAN_LOG"
  elif [ "${CONTAINER_ENGINE_AVAILABLE:-0}" = "1" ]; then
    echo "[sonar] using $CONTAINER_ENGINE image sonarsource/sonar-scanner-cli"
    # shellcheck disable=SC2086
    $CONTAINER_ENGINE run --rm --network host \
      -e SONAR_HOST_URL="$HOST" -e SONAR_TOKEN="$SONAR_TOKEN" \
      -v "$PROJECT_DIR:/usr/src" sonarsource/sonar-scanner-cli \
      -Dsonar.projectKey="$KEY" -Dsonar.projectBaseDir=/usr/src 2>&1 | tee "$SCAN_LOG"
  else
    echo "[sonar] no sonar-scanner binary and no usable Docker/Podman engine."
    echo "[sonar] install: brew install sonar-scanner"
    echo "STATUS: SKIP"
    exit 0
  fi
}

if ! run_scanner; then
  echo "STATUS: FAIL (scanner exited non-zero; see $SCAN_LOG)"
  exit 1
fi

# Best effort: export issues flagged with PERFORMANCE impact. Different server
# versions use different API fields; try modern impact query, then legacy tag query.
ISSUES="$REPORT_DIR/sonar-perf-issues.json"
if curl -sf -m 30 -u "$SONAR_TOKEN:" \
     "$HOST/api/issues/search?componentKeys=$KEY&impactSoftwareQualities=PERFORMANCE&ps=500" > "$ISSUES" 2>/dev/null \
   || curl -sf -m 30 -u "$SONAR_TOKEN:" \
     "$HOST/api/issues/search?componentKeys=$KEY&additionalTags=performance&ps=500" > "$ISSUES" 2>/dev/null; then
  echo "[sonar] performance issues exported to $ISSUES"
else
  rm -f "$ISSUES"
  echo "[sonar] scan done, but issue export API was unavailable (check scan log + server UI; results still valid evidence)."
fi
echo "STATUS: OK scan_log=$SCAN_LOG issues=${ISSUES:-n/a}"
exit 0
