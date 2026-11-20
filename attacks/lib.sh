#!/bin/bash
# Safety guard shared by every scenario. Refuses to run against anything
# outside the isolated lab network (172.30.0.0/24), so these scripts can
# only ever touch the lab's own victim container.
set -euo pipefail
TARGET="${TARGET:-victim}"
TARGET_IP="$(getent hosts "$TARGET" | awk '{print $1; exit}')"
case "$TARGET_IP" in
  172.30.0.*) ;;
  *) echo "[!] $TARGET resolves to '${TARGET_IP:-nothing}', not the lab network 172.30.0.0/24. Refusing to run."; exit 1 ;;
esac
step() { echo; echo "==> $*"; }
