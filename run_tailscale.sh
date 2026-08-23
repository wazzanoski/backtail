#!/bin/sh

SCRIPT_NAME=$(basename -s '.sh' "${0}")

# Source common functions
. /logger.sh

TSD_ARG_STATEDIR="--statedir=${CONFIG_DIR}/.tailscaled_state"
TSD_ARG_TUN="--tun=userspace-networking"
TSD_LOG='/var/log/tailscaled'

log INFO "Starting tailscaled in the background ..."
tailscaled ${TSD_ARG_STATEDIR} ${TSD_ARG_TUN} >> ${TSD_LOG} 2>&1 &
TSD_PID=${!}

log INFO "Starting tailscale..."
tailscale up
EXIT_STATUS=${?}

if [ "${EXIT_STATUS}" -eq 0 ]; then
  log INFO "Connecting to Tailscale successful!"
else
  log ERROR "Connecting to Tailscale not successful!"
  if [ -f "${TSD_LOG}" ]; then
    log INFO "Please check the logs:"
    log INFO "======================="
    tail -20 "${TSD_LOG}"
    log INFO "======================="
  fi
  kill ${TSD_PID} 2>/dev/null || true
  exit 1
fi

log INFO "Tailscale is running in the background with PID ${TSD_PID}"
