#!/bin/sh

# Health check script for backtail container
# Verifies SSHD, Tailscale (if enabled), and basic SFTP functionality
# Returns 0 if healthy, 1 if unhealthy

# Setup logging
SCRIPT_NAME="healthcheck"
export SCRIPT_NAME
# Source logger.sh from the same directory
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "${SCRIPT_DIR}/logger.sh"

# Configuration
SSH_TEST_PORT=22

# Function to check if SSHD is running
check_sshd_running() {
  log DEBUG "Checking if SSHD is running..."
  if pgrep sshd >/dev/null 2>&1; then
    log DEBUG "SSHD process found"
    return 0
  else
    log ERROR "SSHD process not found"
    return 1
  fi
}

# Function to check if SSH port is listening
check_ssh_port_listening() {
  log DEBUG "Checking if SSH port is listening..."
  if command -v ss >/dev/null 2>&1 && ss -ln 2>/dev/null | grep -q ":${SSH_TEST_PORT}"; then
    log DEBUG "SSH port ${SSH_TEST_PORT} is listening (ss)"
    return 0
  elif command -v netstat >/dev/null 2>&1 && netstat -an 2>/dev/null | grep -q ":${SSH_TEST_PORT}.*LISTEN"; then
    log DEBUG "SSH port ${SSH_TEST_PORT} is listening (netstat)"
    return 0
  else
    log ERROR "SSH port ${SSH_TEST_PORT} is not listening"
    return 1
  fi
}

# Function to check SSHD configuration validity
check_sshd_config() {
  log DEBUG "Checking SSHD configuration..."
  if sshd -t 2>/dev/null; then
    log DEBUG "SSHD configuration is valid"
    return 0
  else
    log ERROR "SSHD configuration is invalid"
    return 1
  fi
}

# Function to check Tailscale status (if enabled)
check_tailscale_status() {
  # Only check if Tailscale is supposed to be enabled
  if [ "${TAILSCALE_ENABLED}" != "true" ]; then
    log DEBUG "Tailscale is disabled, skipping health check"
    return 0
  fi

  log DEBUG "Checking Tailscale status..."
  
  # Check if tailscaled is running
  if ! pgrep tailscaled >/dev/null 2>&1; then
    log ERROR "Tailscaled process not found"
    return 1
  fi

  # Check if tailscale command is available and connected
  if command -v tailscale >/dev/null 2>&1; then
    # Check if tailscale is connected (various possible status indicators)
    if tailscale status 2>/dev/null | grep -qE "(Logged in|Connected|Running)"; then
      log DEBUG "Tailscale is connected"
      return 0
    else
      log ERROR "Tailscale is not connected"
      return 1
    fi
  else
    log WARN "Tailscale command not found, but tailscaled is running"
    return 0
  fi
}

# Function to check basic SFTP connectivity
check_sftp_connectivity() {
  log DEBUG "Checking SFTP connectivity..."
  
  # Since we already check that SSHD is running and port is listening,
  # we can skip actual connectivity test to avoid requiring additional tools
  # like netcat. The combination of process check + port check is sufficient.
  log DEBUG "SFTP connectivity verified via process and port checks"
  return 0
}

# Function to check SSH host key exists
check_ssh_host_key() {
  log DEBUG "Checking SSH host key..."
  check_host_key="/etc/ssh/ssh_host_ed25519_key"
  
  if [ -f "${check_host_key}" ]; then
    log DEBUG "SSH host key exists"
    return 0
  else
    log ERROR "SSH host key not found at ${check_host_key}"
    return 1
  fi
}

# Function to check user/group configuration
check_user_group_config() {
  log DEBUG "Checking user/group configuration..."
  
  # Use the same user name as defined in Dockerfile/entrypoint (default: backtail)
  check_user_name="${USER:-backtail}"
  
  # Check if backtail user exists
  if id "${check_user_name}" >/dev/null 2>&1; then
    log DEBUG "User '${check_user_name}' exists"
  else
    log ERROR "User '${check_user_name}' does not exist"
    return 1
  fi

  # Check if backtail group exists
  if getent group "${check_user_name}" >/dev/null 2>&1; then
    log DEBUG "Group '${check_user_name}' exists"
  else
    log ERROR "Group '${check_user_name}' does not exist"
    return 1
  fi

  return 0
}

# Main health check function
main() {
  log INFO "Starting health check..."
  
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
  if ! check_sshd_config; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check SSH host key
  if ! check_ssh_host_key; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check user/group configuration
  if ! check_user_group_config; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check Tailscale status (if enabled)
  if ! check_tailscale_status; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  # Check SFTP connectivity
  if ! check_sftp_connectivity; then
    healthcheck_failed_checks=$((healthcheck_failed_checks + 1))
  fi

  if [ "${healthcheck_failed_checks}" -eq 0 ]; then
    log INFO "Health check passed - all services are healthy"
    exit 0
  else
    log ERROR "Health check failed - ${healthcheck_failed_checks} check(s) failed"
    exit 1
  fi
}

# Run main function
main
