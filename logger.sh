#!/bin/sh

# Common logging function with level support
# Usage: log LEVEL "message"
# Levels: DEBUG, INFO, WARN, ERROR
log() {
  LEVEL="${1}"
  shift
  MESSAGE="${*}"
  
  case "${LEVEL}" in
    DEBUG) printf "%s %-20s [DEBUG] %s\n" "$(date -Is)" "[${SCRIPT_NAME}]" "${MESSAGE}" ;;
    INFO)  printf "%s %-20s [INFO]  %s\n" "$(date -Is)" "[${SCRIPT_NAME}]" "${MESSAGE}" ;;
    WARN)  printf "%s %-20s [WARN]  %s\n" "$(date -Is)" "[${SCRIPT_NAME}]" "${MESSAGE}" ;;
    ERROR) printf "%s %-20s [ERROR] %s\n" "$(date -Is)" "[${SCRIPT_NAME}]" "${MESSAGE}" ;;
    *)     printf "%s %-20s [INFO]  %s\n" "$(date -Is)" "[${SCRIPT_NAME}]" "${MESSAGE}" ;;
  esac
}
