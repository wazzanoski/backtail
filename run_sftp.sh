#!/bin/sh

# Setup logging
SCRIPT_NAME=$(basename -s '.sh' "${0}")
export SCRIPT_NAME
. ./logger.sh

HOST_KEY_FILE="ssh_host_ed25519_key"

#ssh host key
if [ ! -f "${CONFIG_DIR}/${HOST_KEY_FILE}" ]; then
  log INFO "Generating SSH host key..."
  su -s /bin/sh "${USER}" -c "ssh-keygen -t ed25519 -f '${CONFIG_DIR}/${HOST_KEY_FILE}' -N ''"
fi
cp "${CONFIG_DIR}/${HOST_KEY_FILE}" '/etc/ssh/'
chmod 600 "/etc/ssh/${HOST_KEY_FILE}"

#banner
if [ ! -f "${CONFIG_DIR}/banner.txt" ]; then
  log INFO "Setting default banner..."
  su -s /bin/sh "${USER}" -c "cp '/etc/ssh/banner.txt' '${CONFIG_DIR}/'"
fi

log INFO "Starting sshd..."
/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config.d/sftp_jail.conf
