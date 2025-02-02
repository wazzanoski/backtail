#!/bin/sh

SCRIPT_NAME=`basename -s '.sh' ${0}`
CONFIG_DIR="/config"
TSD_ARG_STATEDIR="--statedir=${CONFIG_DIR}/.tailscaled_state"
TSD_ARG_TUN="--tun=userspace-networking"
TSD_LOG='/var/log/tailscaled'

error_handler() {
  echo
  log "======================="
  exit 1
}

log() {
  printf "%s %-20s %s\n" "`date -Is`" "[${SCRIPT_NAME}]" "${*}"
}

log "======================="

log "Starting tailscaled..."
log "tailscaled ${TSD_ARG_STATEDIR} ${TSD_ARG_TUN} >> ${TSD_LOG} 2>&1 &"
eval tailscaled ${TSD_ARG_STATEDIR} ${TSD_ARG_TUN} >> ${TSD_LOG} 2>&1 &

log "Starting tailscale..."
log "tailscale up"
eval tailscale up
EXIT_STATUS="$?"

if [ "${EXIT_STATUS}" == "0" ]; then
  log "Connecting to Tailscale successful!"
else
  log "ERROR: Connecting to Tailscale not successful!"
  if [ -f "${TSD_LOG}" ]; then
    log "Please check the logs:"
    tail -20 "${TSD_LOG}"
    log "======================="
  fi
  error_handler
fi
