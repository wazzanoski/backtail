#!/bin/sh

APP_NAME=`basename -s '.sh' ${0}`
BACKUPS_DIR="/backups"
CONFIG_DIR="/config"
USER_NAME="backtail"

log() {
  MSG="${1}"
  echo "[${APP_NAME}] ${MSG}"
}

log "Begin."

if [ ! -f /config/ssh_host_rsa_key ]; then
  log "Generating SSH host keys..."
  ssh-keygen -A
  cp /etc/ssh/ssh_host_* "${CONFIG_DIR}"
else
  log "Using existing SSH host keys..."
  cp /config/ssh_host_* /etc/ssh/
fi

log "Setting up sftp user..."
#-h DIR          Home directory
#-S              Create a system user
#-D              Don't assign a password
#-H              Don't create home directory
adduser -h "${BACKUPS_DIR}" -S -D -H "${USER_NAME}"
#echo "${USER_NAME}:${USER_NAME}" | chpasswd

log "Starting sshd..."
/usr/sbin/sshd -D -e

log "Done."
