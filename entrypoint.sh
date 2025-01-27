#!/bin/sh

BACKUPS_DIR="/backups"

if [ -z "${SFTP_USER}" ] || [ -z "${SFTP_PASS}" ]; then
  echo "Error: SFTP_USER and SFTP_PASS must be set as environment variables."
  exit 1
fi

if [ ! -f /config/ssh_host_rsa_key ]; then
  echo "Generating SSH host keys..."
  ssh-keygen -A
  cp /etc/ssh/ssh_host_* /config/
else
  echo "Using existing SSH host keys..."
  cp /config/ssh_host_* /etc/ssh/
fi

sudo adduser -D -h "${BACKUPS_DIR}" "${SFTP_USER}"

echo "${SFTP_USER}:${SFTP_PASS}" | chpasswd

/usr/sbin/sshd -D

echo "Setting up tailscale..."
exec /tailscale.sh
