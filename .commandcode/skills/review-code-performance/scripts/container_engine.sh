#!/usr/bin/env bash
# container_engine.sh — detect a usable container runtime.
#
# Source this file from a tool script:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   . "$SCRIPT_DIR/container_engine.sh"
#
# Sets:
#   CONTAINER_ENGINE            "docker" | "podman" | ""   (empty = none usable)
#   CONTAINER_ENGINE_AVAILABLE  1 | 0
#   CONTAINER_COMPOSE           e.g. "docker compose", "docker-compose", "podman compose", "podman-compose", or ""
#
# Preference: Docker first, then Podman. An engine counts as usable only when its
# CLI exists AND `info` succeeds (daemon / podman machine reachable).
# This file is safe to source; it must not be executed standalone for side effects.

_container_engine_usable() {  # $1 = engine binary
  command -v "$1" >/dev/null 2>&1 || return 1
  "$1" info >/dev/null 2>&1
}

_detect_compose() {  # $1 = engine binary
  if "$1" compose version >/dev/null 2>&1; then
    echo "$1 compose"
  elif command -v "$1-compose" >/dev/null 2>&1; then
    echo "$1-compose"
  else
    echo ""
  fi
}

CONTAINER_ENGINE=""
CONTAINER_ENGINE_AVAILABLE=0
CONTAINER_COMPOSE=""

if _container_engine_usable docker; then
  CONTAINER_ENGINE="docker"
elif _container_engine_usable podman; then
  CONTAINER_ENGINE="podman"
fi

if [ -n "$CONTAINER_ENGINE" ]; then
  CONTAINER_ENGINE_AVAILABLE=1
  CONTAINER_COMPOSE="$(_detect_compose "$CONTAINER_ENGINE")"
fi

export CONTAINER_ENGINE CONTAINER_ENGINE_AVAILABLE CONTAINER_COMPOSE
