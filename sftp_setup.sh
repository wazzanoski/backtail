#!/bin/sh

APP_NAME=`basename -s '.sh' ${0}`
BACKUPS_DIR="/backups"
CONFIG_DIR="/config"

log() {
  MSG="${1}"
  echo "[${APP_NAME}] ${MSG}"
}

log "Begin."

if [ -z "${SFTP_USER}" ] || [ -z "${SFTP_PASS}" ]; then
  log "Error: SFTP_USER and SFTP_PASS must be set as environment variables."
  exit 1
fi

if [ ! -f /config/ssh_host_rsa_key ]; then
  log "Generating SSH host keys..."
  ssh-keygen -A
  cp /etc/ssh/ssh_host_* "${CONFIG_DIR}"
else
  log "Using existing SSH host keys..."
  cp /config/ssh_host_* /etc/ssh/
fi

log "Setting up ftp user..."
#Don't assign a password
#Deny shell access
adduser -D -h "${BACKUPS_DIR}" -s '/sbin/nologin' "${SFTP_USER}"
echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd

log "Starting sshd..."
/usr/sbin/sshd -D -e

log "Done."
