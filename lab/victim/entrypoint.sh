#!/bin/bash
# Start logging first so every event from sshd/sudo/useradd reaches auth.log
set -e
touch /var/log/auth.log /var/log/syslog
rsyslogd
service cron start >/dev/null
/usr/sbin/sshd

if [ -x /var/ossec/bin/wazuh-control ]; then
  sed -i "s#<address>.*</address>#<address>${WAZUH_MANAGER:-wazuh.manager}</address>#" /var/ossec/etc/ossec.conf
  # Register with the manager (retry until it is up), then start the agent
  for i in $(seq 1 30); do
    /var/ossec/bin/agent-auth -m "${WAZUH_MANAGER:-wazuh.manager}" -A "${WAZUH_AGENT_NAME:-victim}" && break
    echo "manager not ready, retry $i/30"; sleep 10
  done
  /var/ossec/bin/wazuh-control start
else
  echo "Wazuh agent not installed (INSTALL_AGENT=false): logs stay local"
fi

echo "victim ready"
exec tail -F /var/log/auth.log
