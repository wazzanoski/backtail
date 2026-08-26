#!/bin/sh

# exit script if return code != 0
set -e

# Setup logging
SCRIPT_NAME=$(basename -s '.sh' "${0}")
export SCRIPT_NAME
. ./logger.sh

# Function to manage group
manage_group() {
  log DEBUG "PGID='${PGID}'"
  # Validate PGID is numeric
  case "${PGID}" in ''|*[!0-9]*) log ERROR "PGID ('${PGID}') must be a numeric value" && exit 1 ;; esac
  # Validate PGID is either 100 or >= 1000 (system user range)
  if [ "${PGID}" -ne 100 ] && [ "${PGID}" -lt 1000 ]; then
    log ERROR "PGID ('${PGID}') must be either 100 or >=1000"
    exit 1
  fi
  
  # Get group id of "${USER}" if it exists
  BACKTAIL_GID=""
  if getent group "${USER}" >/dev/null 2>&1; then
    BACKTAIL_GID=$(getent group "${USER}" | cut -d: -f3)
    log DEBUG "Group '${USER}' exists with GID ${BACKTAIL_GID}"
  fi

  # Check if a group already exists for PGID
  PGID_GROUP=""
  if getent group "${PGID}" >/dev/null 2>&1; then
    PGID_GROUP=$(getent group "${PGID}" | cut -d: -f1)
    log DEBUG "Group with GID ${PGID} exists: '${PGID_GROUP}'"
  fi

  # Handle group management based on conditions
  if [ -n "${PGID_GROUP}" ]; then
    # A group with PGID already exists
    if [ "${PGID_GROUP}" = "${USER}" ]; then
      # Group with PGID is already named ${USER} - do nothing
      log INFO "Group '${USER}' already exists with GID ${PGID}"
    else
      # Group with PGID exists but is not ${USER} - delete it
      delgroup "${PGID_GROUP}"
      log INFO "Deleted group '${PGID_GROUP}' with GID ${PGID}"
      # Now create ${USER} with PGID
      addgroup -g "${PGID}" "${USER}"
      log INFO "Created group '${USER}' with GID ${PGID}"
    fi
  else
    # No group exists with PGID
    if [ -n "${BACKTAIL_GID}" ]; then
      # ${USER} group exists but with wrong GID - modify it
      groupmod -o -g "${PGID}" "${USER}"
      log INFO "Modified group '${USER}' GID from ${BACKTAIL_GID} to ${PGID}"
    else
      # ${USER} group doesn't exist - create it with PGID
      addgroup -g "${PGID}" "${USER}"
      log INFO "Created group '${USER}' with GID ${PGID}"
    fi
  fi
}

# Function to manage user
manage_user() {
  log DEBUG "PUID='${PUID}'"
  # Validate PUID is numeric
  case "${PUID}" in ''|*[!0-9]*) log ERROR "PUID ('${PUID}') must be a numeric value" && exit 1 ;; esac
  # Validate PUID is either 99 or >= 1000 (system user range)
  if [ "${PUID}" -ne 99 ] && [ "${PUID}" -lt 1000 ]; then
    log ERROR "PUID ('${PUID}') must be either 99 or >=1000"
    exit 1
  fi

  log DEBUG "USER=${USER}"
  # Get user id of "${USER}" if it exists
  BACKTAIL_UID=""
  if id -u "${USER}" >/dev/null 2>&1; then
    BACKTAIL_UID=$(id -u "${USER}")
    BACKTAIL_CURRENT_GID=$(id -g "${USER}")
    log DEBUG "User '${USER}' exists with UID ${BACKTAIL_UID} and GID ${BACKTAIL_CURRENT_GID}"
  fi

  # Check if a user already exists for PUID
  PUID_USER=""
  if getent passwd "${PUID}" >/dev/null 2>&1; then
    PUID_USER=$(getent passwd "${PUID}" | cut -d: -f1)
    log DEBUG "User with UID ${PUID} exists: '${PUID_USER}'"
  fi

  # Handle user management based on conditions
  if [ -n "${PUID_USER}" ]; then
    # A user with PUID already exists
    if [ "${PUID_USER}" = "${USER}" ]; then
      # User with PUID is already named ${USER} - check group
      if [ "${BACKTAIL_CURRENT_GID}" != "${PGID}" ]; then
        # ${USER} exists but wrong group - modify it
        usermod -g "${USER}" "${USER}"
        log INFO "Modified user '${USER}' group from ${BACKTAIL_CURRENT_GID} to ${PGID}"
      else
        log INFO "User '${USER}' already exists with UID ${PUID} and GID ${PGID}"
      fi
    else
      # User with PUID exists but is not backtail - delete it
      deluser "${PUID_USER}"
      log INFO "Deleted user '${PUID_USER}' with UID ${PUID}"
      # Now create ${USER} with PUID and PGID
      # -S              Create a system user
      # -D              Don't assign a password
      # -h              Set home directory
      adduser -S -D -h "/data/${USER}" -u "${PUID}" -G "${USER}" "${USER}"
      log INFO "Created user '${USER}' with UID ${PUID} and GID ${PGID}"
    fi
  else
    # No user exists with PUID
    if [ -n "${BACKTAIL_UID}" ]; then
      # ${USER} user exists but with wrong UID - modify it
      usermod -o -u "${PUID}" "${USER}"
      log INFO "Modified user '${USER}' UID from ${BACKTAIL_UID} to ${PUID}"
      # Also check and fix group if needed
      if [ "${BACKTAIL_CURRENT_GID}" != "${PGID}" ]; then
        usermod -g "${USER}" "${USER}"
        log INFO "Modified user '${USER}' group from ${BACKTAIL_CURRENT_GID} to ${PGID}"
      fi
    else
      # ${USER} user doesn't exist - create it with PUID and PGID
      # -S              Create a system user
      # -D              Don't assign a password
      # -h              Set home directory
      adduser -S -D -h "/data/${USER}" -u "${PUID}" -G "${USER}" "${USER}"
      log INFO "Created user '${USER}' with UID ${PUID} and GID ${PGID}"
    fi
  fi

  # Because the account was created without a password
  # the account is initially locked.
  # https://unix.stackexchange.com/questions/193066/how-to-unlock-account-for-public-key-ssh-authorization-but-not-for-password-aut
  # Unlock the account and set an invalid password hash:
  echo "${USER}:*" | chpasswd
}

# Function to manage umask
manage_umask() {
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
}

update_permissions() {
  set +e
	chown -R "${PUID}":"${PGID}" "${1}"
#	exit_code_chown=$?
	
	# Calculate directory permissions based on UMASK
	# UMASK is the complement of permissions (777 - UMASK = permissions)
	# Manual calculation for POSIX compatibility
	case "${UMASK}" in
		000) dir_perms="777"; file_perms="666" ;;
		002) dir_perms="775"; file_perms="664" ;;
		022) dir_perms="755"; file_perms="644" ;;
		077) dir_perms="700"; file_perms="600" ;;
		111) dir_perms="666"; file_perms="555" ;;
		*) dir_perms="755"; file_perms="644" ;; # Default to safe permissions
	esac
	
	log DEBUG "dir_perms=${dir_perms}"
	log DEBUG "file_perms=${file_perms}"
	
	# Apply directory permissions to directories
	find "${1}" -type d -exec chmod "${dir_perms}" {} \;
	
	# Apply file permissions to files
	find "${1}" -type f -exec chmod "${file_perms}" {} \;
	
#	exit_code_chmod=$?
	set -e
}

# Manage group
manage_group

# Manage user
manage_user

# Manage umask
manage_umask

update_permissions "${CONFIG_DIR}"
update_permissions "${BACKUP_DIR}"

# Check if dry run mode is enabled
if [ "${DRY_RUN}" = "true" ]; then
  log INFO "Dry run mode enabled - skipping service startup"
  log INFO "Configuration validation completed successfully"
  exit 0
fi

# Trap signals for graceful shutdown
trap 'kill $(jobs -p)' EXIT TERM INT

# Start services based on configuration
if [ "${TAILSCALE_ENABLED}" = "true" ]; then
  /run_tailscale.sh
else
  log INFO "Tailscale disabled - starting SSH only"
fi
/run_sftp.sh
