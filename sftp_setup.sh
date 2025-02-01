#!/bin/sh

APP_NAME=`basename -s '.sh' ${0}`
USER_NAME="backtail"
CONFIG_DIR="/config"

log() {
  printf "%s %-20s %s\n" "`date -Is`" "[${APP_NAME}]" "${*}"
}

log "Begin."

if [ ! -f "${CONFIG_DIR}/ssh_host_ed25519_key" ]; then
  log "Generating SSH host key..."
  ssh-keygen -A
  cp '/etc/ssh/ssh_host_ed25519_key' "${CONFIG_DIR}"
else
  log "Using existing SSH host key..."
  cp "${CONFIG_DIR}/ssh_host_ed25519_key" '/etc/ssh/'
fi

log "Setting up sftp user..."
#-S              Create a system user
#-D              Don't assign a password
#-H              Don't create home directory
adduser -S -D -H "${USER_NAME}"
#Because the account was created without a password
#the account is initially locked.
#https://unix.stackexchange.com/questions/193066/how-to-unlock-account-for-public-key-ssh-authorization-but-not-for-password-aut
#Unlock the account and set an invalid password hash:
echo "${USER_NAME}:*" | chpasswd

log "Starting sshd..."
/usr/sbin/sshd -D -e

log "Done."
