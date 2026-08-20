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

#ssh host key
if [ ! -f "${CONFIG_DIR}/ssh_host_ed25519_key" ]; then
  log "Generating SSH host key..."
  ssh-keygen -t ed25519 -f "${CONFIG_DIR}/ssh_host_ed25519_key" -N ""
fi
cp "${CONFIG_DIR}/ssh_host_ed25519_key" '/etc/ssh/'
chmod 600 '/etc/ssh/ssh_host_ed25519_key'

#banner
if [ ! -f "${CONFIG_DIR}/banner.txt" ]; then
  log "Setting default banner..."
  cp '/etc/ssh/banner.txt' "${CONFIG_DIR}/" 
fi

log "Starting sshd..."
/usr/sbin/sshd -D -e
