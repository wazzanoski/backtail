#!/bin/sh

# Setup logging
SCRIPT_NAME=$(basename -s '.sh' "${0}")
export SCRIPT_NAME
. ./logger.sh

# Manage SSH host key
manage_host_key() {
  # Generate SSH host key if it doesn't exist
  if [ ! -f "${CONFIG_DIR}/${HOST_KEY_FILE}" ]; then
    log INFO "Generating SSH host key ..."
    su -s /bin/sh "${USER}" -c "ssh-keygen -t ed25519 -f '${CONFIG_DIR}/${HOST_KEY_FILE}' -N ''"
  fi
  # Copy to SSH config
  log INFO "Copying SSH host key to /etc/ssh ..."
  cp "${CONFIG_DIR}/${HOST_KEY_FILE}" '/etc/ssh'
  log INFO "Setting permissions on SSH host key ..."
  chown root:root "/etc/ssh/${HOST_KEY_FILE}"
  chmod 400 "/etc/ssh/${HOST_KEY_FILE}"
}

# Manage SSH banner
manage_banner() {
  if [ ! -f "${CONFIG_DIR}/${BANNER_FILE}" ]; then
    log INFO "Setting default banner ..."
    su -s /bin/sh "${USER}" -c "cp '/etc/ssh/${BANNER_FILE}' '${CONFIG_DIR}/'"
  fi
}

# Manage SSH config
manager_config() {
  log INFO "Setting permissions on sshd_config ..."
  chown root:root "/etc/ssh/sshd_config.d/*.conf"
  chmod 400 "/etc/ssh/sshd_config.d/*.conf"
}

manage_host_key
manage_banner
manager_config

log INFO "Starting sshd ..."
/usr/sbin/sshd -D -e -f "/etc/ssh/sshd_config.d/${SSHD_CONFIG_FILE}"
