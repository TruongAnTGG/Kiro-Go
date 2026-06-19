#!/usr/bin/env bash
set -euo pipefail

APP_NAME="kiro-go"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DATA_DIR="${DATA_DIR:-data}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"

usage() {
  cat <<USAGE
Usage: ./run.sh [command]

Commands:
  deploy    Create data dir, build image, start service (default)
  up        Start service without rebuilding
  down      Stop and remove service containers
  restart   Restart service
  logs      Follow service logs
  status    Show service status
  build     Build service image
  help      Show this help

Env:
  ADMIN_PASSWORD=...   Optional admin password override
  DATA_DIR=data        Data directory on host
  COMPOSE_FILE=...     Compose file path
USAGE
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$COMPOSE_FILE" "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f "$COMPOSE_FILE" "$@"
  else
    echo "Missing Docker Compose. Install Docker Desktop or docker compose plugin." >&2
    exit 1
  fi
}

ensure_ready() {
  need_cmd docker
  [ -f "$COMPOSE_FILE" ] || {
    echo "Compose file not found: $COMPOSE_FILE" >&2
    exit 1
  }
  mkdir -p "$DATA_DIR"
}

deploy() {
  ensure_ready
  echo "Deploying $APP_NAME..."
  if [ -n "$ADMIN_PASSWORD" ]; then
    ADMIN_PASSWORD="$ADMIN_PASSWORD" compose up -d --build
  else
    compose up -d --build
  fi
  echo "Done. Open: http://localhost:8080/admin"
  compose ps
}

cmd="${1:-deploy}"
case "$cmd" in
  deploy) deploy ;;
  up) ensure_ready; compose up -d ;;
  down) ensure_ready; compose down ;;
  restart) ensure_ready; compose restart ;;
  logs) ensure_ready; compose logs -f --tail=100 ;;
  status) ensure_ready; compose ps ;;
  build) ensure_ready; compose build ;;
  help|-h|--help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
esac
