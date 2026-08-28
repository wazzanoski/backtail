#!/bin/sh

# Health check script for backtail container
# Verifies SSHD process, port listening, configuration, host key, user/group config, and Tailscale processes/status (if enabled)
# Returns 0 if healthy, 1 if unhealthy

# Check if SSHD is running
check_sshd_running() {
  STATUS=1
  if pgrep sshd >/dev/null 2>&1; then
    STATUS=0
  fi
  echo "sshd_running:${STATUS}"
  return ${STATUS}
}

# Check if SSH port is listening
check_ssh_port_listening() {
  STATUS=1
  # Use /proc/net/tcp to check if port 22 (hex 0016) is in LISTEN state (hex 0A)
  if awk '$4 == "0A" && $2 ~ /:0016$/ {found=1} END {exit !found}' /proc/net/tcp 2>/dev/null; then
    STATUS=0
  fi
  echo "ssh_port_listening:${STATUS}"
  return ${STATUS}
}

# Check SSHD configuration validity
check_sshd_config_valid() {
  STATUS=1
  if sshd -t 2>/dev/null; then
    STATUS=0
  fi
  echo "sshd_config_valid:${STATUS}"
  return ${STATUS}
}

# Check SSH host key exists
check_ssh_host_key_exists() {
  host_key="/etc/ssh/ssh_host_ed25519_key"
  STATUS=1
  if [ -f "${host_key}" ]; then
    STATUS=0
  fi
  echo "ssh_host_key_exists:${STATUS}"
  return ${STATUS}
}

# Check Tailscale running (if enabled)
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

# Check Tailscale connection status (if enabled)
check_tailscale_status() {
  # Only check if Tailscale is enabled
  if [ "${TAILSCALE_ENABLED}" != "true" ]; then
    echo "tailscale_status:skipped"
    return 0
  fi

  STATUS=1
  # Check if tailscale command is available and connected
  if command -v tailscale >/dev/null 2>&1; then
    # Check if tailscale is connected (various possible status indicators)
    if tailscale status 2>/dev/null | grep -qE "(Logged in|Connected|Running)"; then
      STATUS=0
    fi
  fi
  echo "tailscale_status:${STATUS}"
  return ${STATUS}
}

# Check user/group configuration
check_user_group_config() {
  STATUS=0
  
  # Check if backtail user exists
  if ! id "${USER}" >/dev/null 2>&1; then
    STATUS=1
  fi

  # Check if backtail group exists
  if ! getent group "${USER}" >/dev/null 2>&1; then
    STATUS=1
  fi

  echo "user_group_config:${STATUS}"
  return ${STATUS}
}

# Main health check function
main() {
  healthcheck_failed_checks=0

  # Check SSHD is running
  if ! check_sshd_running; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check SSH port is listening
  if ! check_ssh_port_listening; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check SSHD configuration
  if ! check_sshd_config_valid; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check SSH host key
  if ! check_ssh_host_key_exists; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check user/group configuration
  if ! check_user_group_config; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check Tailscale running (if enabled)
  if ! check_tailscale_running; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check Tailscale status (if enabled)
  if ! check_tailscale_status; then
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
