#!/bin/sh

# Setup logging
SCRIPT_NAME=$(basename -s '.sh' "${0}")
export SCRIPT_NAME
. /logger.sh

#ssh host key
if [ ! -f "${CONFIG_DIR}/ssh_host_ed25519_key" ]; then
  log INFO "Generating SSH host key..."
  ssh-keygen -t ed25519 -f "${CONFIG_DIR}/ssh_host_ed25519_key" -N ""
fi
cp "${CONFIG_DIR}/ssh_host_ed25519_key" '/etc/ssh/'
chmod 600 '/etc/ssh/ssh_host_ed25519_key'

#banner
if [ ! -f "${CONFIG_DIR}/banner.txt" ]; then
  log INFO "Setting default banner..."
  cp '/etc/ssh/banner.txt' "${CONFIG_DIR}/" 
fi

log INFO "Starting sshd..."
/usr/sbin/sshd -D -e
