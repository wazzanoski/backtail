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

log DEBUG "PUID='${PUID}'"
# Validate PUID is numeric
case "${PUID}" in ''|*[!0-9]*) log ERROR "PUID ('${PUID}') must be a numeric value" && exit 1 ;; esac
# Validate PUID is either 99 or >= 1000 (system user range)
if [ "${PUID}" -ne 99 ] && [ "${PUID}" -lt 1000 ]; then
  log ERROR "PUID ('${PUID}') must be either 99 or >=1000"
  exit 1
fi

log DEBUG "PGID='${PGID}'"
# Validate PGID is numeric
case "${PGID}" in ''|*[!0-9]*) log ERROR "PGID ('${PGID}') must be a numeric value" && exit 1 ;; esac
# Validate PGID is either 100 or >= 1000 (system user range)
if [ "${PGID}" -ne 100 ] && [ "${PGID}" -lt 1000 ]; then
  log ERROR "PGID ('${PGID}') must be either 100 or >=1000"
  exit 1
fi

log DEBUG "USER=${USER}"
# Create USER (if doesn't exist)
# -S              Create a system user
# -D              Don't assign a password
# -H              Don't create home directory
if ! id -u "${USER}" >/dev/null 2>&1; then
  adduser -S -D -H "${USER}"
  log INFO "Created user '${USER}'"
else
  log INFO "User '${USER}' already exists"
fi

# Ensure group exists (adduser should create it, but verify)
if ! getent group "${USER}" >/dev/null 2>&1; then
  addgroup "${USER}"
  log INFO "Created group '${USER}'"
fi

# Modify group with specified GID
groupmod -o -g "${PGID}" "${USER}"
log INFO "Set group '${USER}' GID to ${PGID}"

# Modify user with specified UID and GID
usermod -o -u "${PUID}" -g "${PGID}" "${USER}"
log INFO "Set user '${USER}' UID to ${PUID} and GID to ${PGID}"

# Because the account was created without a password
# the account is initially locked.
# https://unix.stackexchange.com/questions/193066/how-to-unlock-account-for-public-key-ssh-authorization-but-not-for-password-aut
# Unlock the account and set an invalid password hash:
echo "${USER}:*" | chpasswd

log DEBUG "UMASK='${UMASK}'"
# Apply UMASK
if [ -n "${UMASK}" ]; then
  # Validate UMASK is a valid octal value (000-777)
  case "${UMASK}" in
    [0-7][0-7][0-7])
      umask "${UMASK}"
      log INFO "Set UMASK to ${UMASK}"
      ;;
    *)
      log ERROR "UMASK '${UMASK}' must be a valid octal value (000-777)"
      exit 1
      ;;
  esac
fi
 
# Trap signals for graceful shutdown
trap 'kill $(jobs -p)' EXIT TERM INT
 
/run_tailscale.sh && /run_sftp.sh
