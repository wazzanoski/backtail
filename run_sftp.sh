#!/bin/sh

SCRIPT_NAME=`basename -s '.sh' ${0}`
CONFIG_DIR="/config"

log() {
  printf "%s %-20s %s\n" "`date -Is`" "[${SCRIPT_NAME}]" "${*}"
}

#ssh host key
if [ ! -f "${CONFIG_DIR}/ssh_host_ed25519_key" ]; then
  log "Generating SSH host key..."
  ssh-keygen -t ed25519 -f "${CONFIG_DIR}/ssh_host_ed25519_key" -N ""
fi
cp "${CONFIG_DIR}/ssh_host_ed25519_key" '/etc/ssh/'

#banner
if [ ! -f "${CONFIG_DIR}/banner.txt" ]; then
  log "Setting default banner..."
  cp '/etc/ssh/banner.txt' "${CONFIG_DIR}/" 
fi

log "Starting sshd..."
/usr/sbin/sshd -D -e
