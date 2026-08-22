#!/bin/sh

# exit script if return code != 0
set -e

SCRIPT_NAME=$(basename -s '.sh' "${0}")
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

# Validate PUID is either 99 or >= 1000 (system user range)
if [ "${PUID}" -ne 99 ] && [ "${PUID}" -lt 1000 ]; then
  log ERROR "PUID must be either 99 or >= 1000"
  exit 1
fi

# Validate PGID is either 100 or >= 1000 (system user range)
if [ "${PGID}" -ne 100 ] && [ "${PGID}" -lt 1000 ]; then
  log ERROR "PGID must be either 100 or >= 1000"
  exit 1
fi

# Create USER
# -S              Create a system user
# -D              Don't assign a password
# -H              Don't create home directory
adduser -S -D -H "${USER}"

# Modify group with specified GID
groupmod -o -g "${PGID}" "${USER}" 2>/dev/null

# Modify user with specified UID and GID
usermod -o -u "${PUID}" -g "${PGID}" "${USER}" 2>/dev/null

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
