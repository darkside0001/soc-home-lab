#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LAB_ROOT="$PWD"
WAZUH_DOCKER_DIR="${WAZUH_DOCKER_DIR:-$PWD/.wazuh-docker}"
docker compose -f "$WAZUH_DOCKER_DIR/single-node/docker-compose.yml" \
               -f "$LAB_ROOT/lab/docker-compose.lab.yml" down -v
