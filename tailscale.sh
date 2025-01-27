#!/bin/bash

echo "Starting tailscaled${TSD_MSG}"
eval tailscaled -statedir=${TSD_STATE_DIR} ${TSD_PARAMS}&

echo "Starting tailscale"
eval tailscale up ${TS_AUTH}${TS_PARAMS}
EXIT_STATUS="$?"

if [ "${EXIT_STATUS}" == "0" ]; then
  echo "Connecting to Tailscale successful!"
  if [ ! -f ${TSD_STATE_DIR}/.initialized ]; then
    echo "Please don't remove this file!" > ${TSD_STATE_DIR}/.initialized
  fi
else
  echo "ERROR: Connecting to Tailscale not successful!"
  if [ -f /var/log/tailscaled ]; then
    echo "Please check the logs:"
    tail -20 /var/log/tailscaled
    echo "======================="
  fi
  error_handler
fi
