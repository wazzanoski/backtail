#!/bin/sh

# exit script if return code != 0
set -e

export CONFIG_DIR="/config"

# Source common functions
. /logger.sh

# Check if config directory exists
if [ ! -d "${CONFIG_DIR}" ]; then
  log ERROR "Config directory \'${CONFIG_DIR}\' does not exist!"
  exit 1
fi

# User/group creation at runtime for PUID/PGID support
# Validate PUID and PGID are numeric
case "${PUID}" in ''|*[!0-9]*) log ERROR "PUID \'${PUID}\' must be a numeric value" && exit 1 ;; esac
case "${PGID}" in ''|*[!0-9]*) log ERROR "PGID \'${PGID}\' must be a numeric value" && exit 1 ;; esac

# Create group with specified GID
addgroup -g "${PGID}" "${USER}" 2>/dev/null || true

# Create user with specified UID and GID
# -S              Create a system user
# -D              Don't assign a password
# -H              Don't create home directory
adduser -S -D -H -u "${PUID}" -G "${USER}" "${USER}"

# Because the account was created without a password
# the account is initially locked.
# https://unix.stackexchange.com/questions/193066/how-to-unlock-account-for-public-key-ssh-authorization-but-not-for-password-aut
# Unlock the account and set an invalid password hash:
echo "${USER}:*" | chpasswd

# Apply UMASK
if [ -n "${UMASK}" ]; then
  umask "${UMASK}"
fi
 
# Trap signals for graceful shutdown
trap 'kill $(jobs -p)' EXIT TERM INT
 
/run_tailscale.sh && /run_sftp.sh
