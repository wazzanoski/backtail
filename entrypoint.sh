#!/bin/sh
set -e
 
# Apply UMASK from environment
if [ -n "${UMASK}" ]; then
  umask "${UMASK}"
fi
 
# Trap signals for graceful shutdown
trap 'kill $(jobs -p)' EXIT TERM INT
 
/run_tailscale.sh && /run_sftp.sh
