#!/bin/sh

SCRIPT_NAME=$(basename -s '.sh' "${0}")
CONFIG_DIR="/config"

log() {
  printf "%s %-20s %s\n" "$(date -Is)" "[${SCRIPT_NAME}]" "${*}"
}

# Check if config directory exists
if [ ! -d "${CONFIG_DIR}" ]; then
  echo "ERROR: Config directory '${CONFIG_DIR}' does not exist!"
  exit 1
fi

TSD_ARG_STATEDIR="--statedir=${CONFIG_DIR}/.tailscaled_state"
TSD_ARG_TUN="--tun=userspace-networking"
TSD_LOG='/var/log/tailscaled'

log "Starting tailscaled..."
tailscaled ${TSD_ARG_STATEDIR} ${TSD_ARG_TUN} >> ${TSD_LOG} 2>&1 &
TSD_PID=${!}

log "Starting tailscale..."
tailscale up
EXIT_STATUS=${?}

if [ "${EXIT_STATUS}" -eq 0 ]; then
  log "Connecting to Tailscale successful!"
else
  log "ERROR: Connecting to Tailscale not successful!"
  if [ -f "${TSD_LOG}" ]; then
    log "Please check the logs:"
    log "======================="
    tail -20 "${TSD_LOG}"
    log "======================="
  fi
  kill ${TSD_PID} 2>/dev/null || true
  exit 1
fi
