#!/bin/sh
set -e
 
# Check if config directory exists
if [ ! -d "${CONFIG_DIR}" ]; then
  echo "ERROR: Config directory '${CONFIG_DIR}' does not exist!"
  exit 1
fi
 
# Apply UMASK from environment
if [ -n "${UMASK}" ]; then
  umask "${UMASK}"
fi
 
# Trap signals for graceful shutdown
trap 'kill $(jobs -p)' EXIT TERM INT
 
/run_tailscale.sh && /run_sftp.sh
