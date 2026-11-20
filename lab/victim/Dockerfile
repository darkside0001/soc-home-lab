# Deliberately weak Ubuntu server for the lab. Never expose it outside the lab network.
FROM ubuntu:22.04
ARG WAZUH_VERSION=4.12.0
ARG INSTALL_AGENT=true
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server sudo rsyslog cron curl gnupg ca-certificates procps \
    && rm -rf /var/lib/apt/lists/*

# Wazuh agent from the official repository
RUN if [ "$INSTALL_AGENT" = "true" ]; then \
      curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg && \
      echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list && \
      apt-get update && WAZUH_MANAGER=wazuh.manager apt-get install -y "wazuh-agent=${WAZUH_VERSION}-1" && \
      rm -rf /var/lib/apt/lists/* ; \
    fi
COPY agent-extra.conf /tmp/agent-extra.conf
RUN if [ -d /var/ossec/etc ]; then cat /tmp/agent-extra.conf >> /var/ossec/etc/ossec.conf; fi

# Lab accounts. The weak passwords are the point of the exercise.
#   alice  - normal user, weak password, sudo allowed ONLY for /usr/bin/find (GTFOBins misconfig)
#   bob    - normal user, no sudo
#   labadmin - administrator, strong password, key login in real life
RUN useradd -m -s /bin/bash alice && echo 'alice:sunshine1' | chpasswd && \
    useradd -m -s /bin/bash bob && echo 'bob:Bob-Lab-2026!' | chpasswd && \
    useradd -m -s /bin/bash -G sudo labadmin && echo 'labadmin:L4b-Adm1n-Strong-Pass!' | chpasswd && \
    echo 'alice ALL=(root) NOPASSWD: /usr/bin/find' > /etc/sudoers.d/alice && chmod 440 /etc/sudoers.d/alice && \
    mkdir -p /run/sshd && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/; s/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
