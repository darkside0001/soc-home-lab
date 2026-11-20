#!/usr/bin/env bash
# Start a throwaway wazuh-manager with the lab rules and replay tests/cases.json
# through wazuh-logtest. Used by CI and runnable locally (needs only Docker).
set -euo pipefail
cd "$(dirname "$0")/.."
WAZUH_VERSION="${WAZUH_VERSION:-4.12.0}"
NAME=soc-lab-ruletest

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" \
  -v "$PWD/rules/local_rules.xml:/wazuh-config-mount/etc/rules/local_rules.xml:ro" \
  -v "$PWD/tests:/tests:ro" \
  "wazuh/wazuh-manager:${WAZUH_VERSION}" >/dev/null
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT

echo "Waiting for wazuh-analysisd (logtest socket)..."
for _ in $(seq 1 90); do
  if docker exec "$NAME" test -S /var/ossec/queue/sockets/logtest 2>/dev/null; then break; fi
  sleep 2
done
docker exec "$NAME" test -S /var/ossec/queue/sockets/logtest || {
  echo "logtest socket did not appear"; docker logs "$NAME" | tail -50
  docker exec "$NAME" tail -50 /var/ossec/logs/ossec.log || true; exit 1; }

# Fail on ruleset load errors (bad XML, unknown options)
if docker exec "$NAME" grep -E "ERROR|CRITICAL" /var/ossec/logs/ossec.log | grep -iE "rule|xml|local_rules"; then
  echo "Ruleset errors found"; exit 1
fi

docker exec "$NAME" /var/ossec/framework/python/bin/python3 /tests/run_logtest.py \
  /tests/cases.json /tmp/sample-alerts.json
docker cp "$NAME:/tmp/sample-alerts.json" "${ALERTS_OUT:-/tmp/sample-alerts.json}" >/dev/null
