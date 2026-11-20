#!/usr/bin/env bash
# Bring up the whole lab: clone the official Wazuh single-node stack, then layer
# the lab overlay (victim + attacker + local rules) on top.
set -euo pipefail
cd "$(dirname "$0")/.."
export LAB_ROOT="$PWD"
export WAZUH_VERSION="${WAZUH_VERSION:-4.12.0}"
WAZUH_DOCKER_DIR="${WAZUH_DOCKER_DIR:-$PWD/.wazuh-docker}"

if [ ! -d "$WAZUH_DOCKER_DIR" ]; then
  echo "==> Cloning wazuh-docker v${WAZUH_VERSION}"
  git clone --depth 1 -b "v${WAZUH_VERSION}" https://github.com/wazuh/wazuh-docker.git "$WAZUH_DOCKER_DIR"
fi

# The indexer needs a high vm.max_map_count; warn if the host is too low.
if [ "$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)" -lt 262144 ]; then
  echo "[!] vm.max_map_count is low. Run:  sudo sysctl -w vm.max_map_count=262144"
fi

COMPOSE="$WAZUH_DOCKER_DIR/single-node/docker-compose.yml"

echo "==> Generating indexer certificates"
docker compose -f "$WAZUH_DOCKER_DIR/single-node/generate-indexer-certs.yml" run --rm generator

echo "==> Starting Wazuh + lab"
docker compose -f "$COMPOSE" -f "$LAB_ROOT/lab/docker-compose.lab.yml" up -d --build

cat <<MSG

Lab is starting. Give it 2-3 minutes, then:
  - Dashboard:  https://localhost  (admin / SecretPassword)
  - Run attacks:  scripts/attack.sh all
  - Tear down:    scripts/teardown.sh
MSG
