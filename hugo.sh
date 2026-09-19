#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

docker_up() {
  docker info >/dev/null 2>&1
}

ensure_orbstack() {
  docker_up && return 0
  open -ga OrbStack
  for _ in $(seq 1 60); do
    docker_up && return 0
    sleep 1
  done
  return 1
}

start() {
  ensure_orbstack
  docker compose up -d
}

stop() {
  docker_up && docker compose down || true
}

restart() {
  stop
  start
}

clean() {
  docker_up && docker compose down -v --remove-orphans || true
  rm -rf "$ROOT_DIR/public" "$ROOT_DIR/resources" "$ROOT_DIR/.hugo_build.lock"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  clean) clean ;;
  *) exit 1 ;;
esac
