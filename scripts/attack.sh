#!/usr/bin/env bash
# Run one scenario (or all) from the attacker container against the lab victim.
set -euo pipefail
cd "$(dirname "$0")/.."
WHAT="${1:-all}"
case "$WHAT" in
  recon) S=01-recon ;; spray) S=02-ssh-spray ;; brute) S=03-ssh-bruteforce ;;
  privesc) S=04-privesc-sudo ;; persist) S=05-persistence ;; all) S=run-all ;;
  *) echo "usage: $0 {recon|spray|brute|privesc|persist|all}"; exit 1 ;;
esac
docker exec -e TARGET=victim soc-lab-attacker bash "/attacks/${S}.sh"
