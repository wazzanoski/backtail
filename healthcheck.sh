#!/bin/sh

# Health check script for backtail container.
# Verifies user/group definition, SSHD process, port listening, configuration, host key, and Tailscale processes/status (if enabled).
# Returns 0 if all healthy, 1 if any unhealthy.

# Check if user exists.
check_user_exists() {
  STATUS=0
  if ! id "${USER}" >/dev/null 2>&1; then
    STATUS=1
  fi
  echo "user_exists:${STATUS}"
  return ${STATUS}
}

# Check if group exists.
check_group_exists() {
  STATUS=0
  if ! getent group "${USER}" >/dev/null 2>&1; then
    STATUS=1
  fi
  echo "group_exists:${STATUS}"
  return ${STATUS}
}

# Check if user id matches.
check_user_id_matches() {
  STATUS=0
  if [ $(id -u "${USER}") = "${PUID}" ]; then
    STATUS=1
  fi
  echo "user_id_matches:${STATUS}"
  return ${STATUS}
}

# Check if group id matches.
check_group_id_matches() {
  STATUS=0
  if [ $(id -g "${USER}") = "${PGID}" ]; then
    STATUS=1
  fi
  echo "group_id_matches:${STATUS}"
  return ${STATUS}
}

# Check if SSH host key exists.
check_ssh_host_key_exists() {
  host_key="/etc/ssh/ssh_host_ed25519_key"
  STATUS=1
  if [ -f "${host_key}" ]; then
    STATUS=0
  fi
  echo "ssh_host_key_exists:${STATUS}"
  return ${STATUS}
}

# Check if SSHD is running.
check_sshd_running() {
  STATUS=1
  if pgrep sshd >/dev/null 2>&1; then
    STATUS=0
  fi
  echo "sshd_running:${STATUS}"
  return ${STATUS}
}

# Check if SSHD configuration is valid.
check_sshd_config_valid() {
  STATUS=1
  if sshd -t 2>/dev/null; then
    STATUS=0
  fi
  echo "sshd_config_valid:${STATUS}"
  return ${STATUS}
}

# Check if SFTP port is listening.
check_sftp_port_listening() {
  STATUS=1
  # Use /proc/net/tcp to check if port 22 (hex 0016) is in LISTEN state (hex 0A)
  if awk '$4 == "0A" && $2 ~ /:0016$/ {found=1} END {exit !found}' /proc/net/tcp 2>/dev/null; then
    STATUS=0
  fi
  echo "sftp_port_listening:${STATUS}"
  return ${STATUS}
}

# Check if Tailscale is running (if enabled).
check_tailscale_running() {
  # Only check if Tailscale is enabled
  if [ "${TAILSCALE_ENABLED}" != "true" ]; then
    echo "tailscale_running:skipped"
    return 0
  fi

  STATUS=1
  # Check if tailscaled is running
  if pgrep tailscaled >/dev/null 2>&1; then
    STATUS=0
  fi
  echo "tailscale_running:${STATUS}"
  return ${STATUS}
}

# Check if Tailscale connected (if enabled).
check_tailscale_connected() {
  # Only check if Tailscale is enabled
  if [ "${TAILSCALE_ENABLED}" != "true" ]; then
    echo "tailscale_connected:skipped"
    return 0
  fi

  STATUS=1
  # Check if tailscale command is available and connected
  if command -v tailscale >/dev/null 2>&1; then
    # Check if tailscale is connected
    if [ $(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null) = "Running" ]; then
      STATUS=0
    fi
  fi
  echo "tailscale_connected:${STATUS}"
  return ${STATUS}
}

# Main health check function.
main() {
  healthcheck_failed_checks=0

  if ! check_user_exists; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi
  if ! check_group_exists; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi
  if ! check_user_id_matches; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi
  if ! check_group_id_matches; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi
  if ! check_ssh_host_key_exists; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi
  if ! check_sshd_running; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi
  if ! check_sshd_config_valid; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  if ! check_sftp_port_listening; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  if ! check_tailscale_running; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  if ! check_tailscale_connected; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  STATUS=0
  if [ "${healthcheck_failed_checks}" -ne 0 ]; then
    STATUS=1
  fi
  echo "healthcheck_result:${STATUS}"
  exit ${STATUS}
}

# Run main function
main
