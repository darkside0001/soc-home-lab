#!/bin/bash
# T1046 Network Service Discovery: port scan + SSH banner grabbing.
# Expected detections: Wazuh 5706, lab rule 100500.
source "$(dirname "$0")/lib.sh"
step "Port scan of $TARGET ($TARGET_IP)"
nmap -Pn -sT -sV --top-ports 100 "$TARGET_IP"
step "Open and drop connections to sshd (no handshake)"
for i in $(seq 1 6); do nc -w 1 "$TARGET_IP" 22 </dev/null >/dev/null || true; done
