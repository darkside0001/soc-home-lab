#!/bin/bash
# Full attack chain in order (recon -> spray -> brute force -> privesc -> persistence).
set -e
cd "$(dirname "$0")"
for s in 01-recon 02-ssh-spray 03-ssh-bruteforce 04-privesc-sudo 05-persistence; do
  echo; echo "############ $s ############"
  bash "./$s.sh"
done
