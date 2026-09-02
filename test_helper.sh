#!/bin/bash
# Helper functions for SFTP testing in CI pipeline

# Export test configuration variables
export SFTP_TEST_PORT="2222"
export SFTP_TEST_CONTAINER_NAME="backtail-test"
export SFTP_TEST_KEY_NAME="test_key"
export SFTP_TEST_KEY_PATH="/tmp/test_key"
export SFTP_TEST_CONFIG_DIR="/tmp/test-config"
export SFTP_TEST_BACKUP_DIR="/tmp/test-backup"

# Setup test environment
# Args: $1 = key_type (optional, defaults to ed25519)
setup_sftp_test() {
  local key_type="${1:-ed25519}"
  
  # Always use the default key name
  local key_name="${SFTP_TEST_DEFAULT_KEY_NAME}"
  
  # Update the key path variable for the current test
  export SFTP_TEST_KEY_PATH="/tmp/${key_name}"
  
  # Create test environment
  mkdir -p "$SFTP_TEST_CONFIG_DIR" "$SFTP_TEST_BACKUP_DIR" "$SFTP_TEST_BACKUP_DIR/.ssh"
  
  # Generate SSH key pair for testing
  ssh-keygen -t "$key_type" -f "/tmp/${key_name}" -N "" -q
  
  # Setup authorized_keys
  cp "/tmp/${key_name}.pub" "$SFTP_TEST_BACKUP_DIR/.ssh/authorized_keys"
  
  # Start container in background (Tailscale disabled for testing)
  docker run -d --name "$SFTP_TEST_CONTAINER_NAME" \
    -p "${SFTP_TEST_PORT}:22" \
    -v "$SFTP_TEST_CONFIG_DIR:/config" \
    -v "$SFTP_TEST_BACKUP_DIR:/data/backtail" \
    -e PUID="$(id -u)" -e PGID="$(id -g)" \
    -e TAILSCALE_ENABLED=false \
    backtail:test
  
  # Wait for SSH to be ready
  for i in $(seq 1 30); do
    if docker exec "$SFTP_TEST_CONTAINER_NAME" pgrep sshd >/dev/null; then
      echo "SSH is ready"
      break
    fi
    echo "Waiting for SSH... ($i/30)"
    sleep 2
  done
}

# Teardown test environment
# Args: $1 = additional_files (optional)
teardown_sftp_test() {
  local additional_files="$1"
  
  # Stop and remove container
  docker stop "$SFTP_TEST_CONTAINER_NAME"
  docker rm "$SFTP_TEST_CONTAINER_NAME"
  
  # Remove test files (always use default key name)
  rm -rf "$SFTP_TEST_BACKUP_DIR" "$SFTP_TEST_CONFIG_DIR" "/tmp/${SFTP_TEST_DEFAULT_KEY_NAME}" "/tmp/${SFTP_TEST_DEFAULT_KEY_NAME}.pub"
  
  # Remove additional files if specified
  if [ -n "$additional_files" ]; then
    rm -rf $additional_files
  fi
}

# Auto-call setup when script is sourced (can be overridden by calling setup_sftp_test again with custom parameters)
setup_sftp_test
