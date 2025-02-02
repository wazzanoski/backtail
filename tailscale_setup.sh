#!/bin/sh
#Most of this script has been copied from here:
#https://github.com/ich777/docker-steamcmd-server/blob/master/tailscale.sh

SCRIPT_NAME=`basename -s '.sh' ${0}`
CONFIG_DIR="/config"

log() {
  printf "%s %-20s %s\n" "`date -Is`" "[${SCRIPT_NAME}]" "${*}"
}

error_handler() {
  echo
  echo "======================="
  exit 1
}

echo "======================="
log "Begin."

unset TSD_PARAMS
unset TS_PARAMS

if [ -z "${TAILSCALE_STAT_DIR}" ]; then
  TAILSCALE_STATE_DIR="${CONFIG_DIR}/.tailscale_state"
fi
TSD_STATE_DIR=${TAILSCALE_STATE_DIR}
log "Settings Tailscale state dir to: ${TSD_STATE_DIR}"

if [ ! -d ${TS_STATE_DIR} ]; then
  mkdir -p ${TS_STATE_DIR}
fi

TSD_PARAMS="${TSD_PARAMS}-tun=userspace-networking "  

if [ "${TAILSCALE_LOG}" != "false" ]; then
  TSD_PARAMS="${TSD_PARAMS}>>/var/log/tailscaled 2>&1 "
  TSD_MSG=" with log file /var/log/tailscaled"
else
  TSD_PARAMS="${TSD_PARAMS}>/dev/null 2>&1 "
fi

if [ ! -z "${TAILSCALED_PARAMS}" ]; then
  TSD_PARAMS="${TAILSCALED_PARAMS} ${TSD_PARAMS}"
fi

if [ ! -z "${TAILSCALE_PARAMS}" ]; then
  TS_PARAMS="${TAILSCALE_PARAMS}${TS_PARAMS}"
fi

log "Starting tailscaled${TSD_MSG}"
eval tailscaled -statedir=${TSD_STATE_DIR} ${TSD_PARAMS}&

log "Starting tailscale"
eval tailscale up ${TS_AUTH}${TS_PARAMS}
EXIT_STATUS="$?"

if [ "${EXIT_STATUS}" == "0" ]; then
  log "Connecting to Tailscale successful!"
  if [ ! -f ${TSD_STATE_DIR}/.initialized ]; then
    echo "Please don't remove this file!" > ${TSD_STATE_DIR}/.initialized
  fi
else
  log "ERROR: Connecting to Tailscale not successful!"
  if [ -f /var/log/tailscaled ]; then
    log "Please check the logs:"
    tail -20 /var/log/tailscaled
    echo "======================="
  fi
  error_handler
fi

log "Done."
