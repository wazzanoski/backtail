#!/bin/sh

APP_NAME=`basename -s '.sh' ${0}`

echo "[${APP_NAME}] Begin."

BACKUPS_DIR="/backups"
CONFIG_DIR="/config"

if [ -z "${SFTP_USER}" ] || [ -z "${SFTP_PASS}" ]; then
  echo "[${APP_NAME}] Error: SFTP_USER and SFTP_PASS must be set as environment variables."
  exit 1
fi

if [ ! -f /config/ssh_host_rsa_key ]; then
  echo "[${APP_NAME}] Generating SSH host keys..."
  ssh-keygen -A
  cp /etc/ssh/ssh_host_* "${CONFIG_DIR}"
else
  echo "[${APP_NAME}] Using existing SSH host keys..."
  cp /config/ssh_host_* /etc/ssh/
fi

echo "[${APP_NAME}] Setting up ftp user..."
adduser -D -h "${BACKUPS_DIR}" "${SFTP_USER}"
echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd

echo "[${APP_NAME}] Starting sshd..."
/usr/sbin/sshd -D

echo "[${APP_NAME}] Done."
