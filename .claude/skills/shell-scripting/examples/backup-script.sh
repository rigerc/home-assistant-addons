#!/bin/bash
#
# Database backup script with proper error handling, logging, and cleanup.
# Demonstrates production-ready shell scripting patterns.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly BACKUP_DIR="/var/backups/database"
readonly LOG_FILE="/var/log/backup.log"
readonly MAX_BACKUPS=7
readonly DB_NAME="production_db"
readonly DB_USER="backup_user"

# Global variables
TEMP_DIR=''

#######################################
# Log message with timestamp
# Arguments:
#   Log message
#######################################
log() {
  local message="$*"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ${message}" | tee -a "${LOG_FILE}"
}

#######################################
# Log error message to stderr and log file
# Arguments:
#   Error message
#######################################
err() {
  local message="$*"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: ${message}" | tee -a "${LOG_FILE}" >&2
}

#######################################
# Cleanup temporary files
# Called on script exit
#######################################
cleanup() {
  local exit_code=$?

  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    log "Cleaning up temporary directory: ${TEMP_DIR}"
    rm -rf "${TEMP_DIR}"
  fi

  if (( exit_code != 0 )); then
    err "Script exited with error code: ${exit_code}"
  fi

  exit "${exit_code}"
}

# Register cleanup function to run on exit
trap cleanup EXIT

#######################################
# Check if required commands are available
# Returns:
#   0 if all commands available, 1 otherwise
#######################################
check_prerequisites() {
  local cmd
  local missing=()

  for cmd in pg_dump gzip date; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    err "Missing required commands: ${missing[*]}"
    return 1
  fi

  return 0
}

#######################################
# Ensure backup directory exists with correct permissions
# Returns:
#   0 on success, 1 on error
#######################################
setup_backup_dir() {
  if [[ ! -d "${BACKUP_DIR}" ]]; then
    log "Creating backup directory: ${BACKUP_DIR}"
    if ! mkdir -p "${BACKUP_DIR}"; then
      err "Failed to create backup directory"
      return 1
    fi
  fi

  if [[ ! -w "${BACKUP_DIR}" ]]; then
    err "Backup directory is not writable: ${BACKUP_DIR}"
    return 1
  fi

  return 0
}

#######################################
# Create temporary directory for backup staging
# Sets TEMP_DIR global variable
# Returns:
#   0 on success, 1 on error
#######################################
setup_temp_dir() {
  TEMP_DIR="$(mktemp -d)"
  if [[ ! -d "${TEMP_DIR}" ]]; then
    err "Failed to create temporary directory"
    return 1
  fi

  log "Created temporary directory: ${TEMP_DIR}"
  return 0
}

#######################################
# Perform database backup
# Globals:
#   DB_NAME
#   DB_USER
#   TEMP_DIR
# Returns:
#   0 on success, 1 on error
#######################################
backup_database() {
  local timestamp
  timestamp="$(date +'%Y%m%d_%H%M%S')"

  local backup_file="${TEMP_DIR}/${DB_NAME}_${timestamp}.sql"
  local compressed_file="${BACKUP_DIR}/${DB_NAME}_${timestamp}.sql.gz"

  log "Starting backup of database: ${DB_NAME}"

  # Perform database dump
  if ! pg_dump -U "${DB_USER}" "${DB_NAME}" > "${backup_file}"; then
    err "Database dump failed"
    return 1
  fi

  local backup_size
  backup_size="$(du -h "${backup_file}" | cut -f1)"
  log "Backup created: ${backup_file} (${backup_size})"

  # Compress backup
  log "Compressing backup..."
  if ! gzip -c "${backup_file}" > "${compressed_file}"; then
    err "Compression failed"
    return 1
  fi

  local compressed_size
  compressed_size="$(du -h "${compressed_file}" | cut -f1)"
  log "Compressed backup: ${compressed_file} (${compressed_size})"

  # Verify compressed file
  if ! gzip -t "${compressed_file}"; then
    err "Compressed file verification failed"
    return 1
  fi

  log "Backup completed successfully"
  return 0
}

#######################################
# Remove old backups keeping only MAX_BACKUPS newest
# Globals:
#   BACKUP_DIR
#   MAX_BACKUPS
# Returns:
#   0 on success, 1 on error
#######################################
cleanup_old_backups() {
  log "Cleaning up old backups (keeping ${MAX_BACKUPS} most recent)"

  local -a old_backups
  readarray -t old_backups < <(
    find "${BACKUP_DIR}" -name "${DB_NAME}_*.sql.gz" -type f \
      | sort -r \
      | tail -n +$((MAX_BACKUPS + 1))
  )

  if (( ${#old_backups[@]} == 0 )); then
    log "No old backups to remove"
    return 0
  fi

  local backup
  for backup in "${old_backups[@]}"; do
    log "Removing old backup: ${backup}"
    if ! rm "${backup}"; then
      err "Failed to remove old backup: ${backup}"
      return 1
    fi
  done

  log "Removed ${#old_backups[@]} old backup(s)"
  return 0
}

#######################################
# Main function
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  log "========== Backup started =========="

  # Check prerequisites
  if ! check_prerequisites; then
    err "Prerequisite check failed"
    exit 1
  fi

  # Setup directories
  if ! setup_backup_dir; then
    err "Failed to setup backup directory"
    exit 1
  fi

  if ! setup_temp_dir; then
    err "Failed to setup temporary directory"
    exit 1
  fi

  # Perform backup
  if ! backup_database; then
    err "Backup failed"
    exit 1
  fi

  # Cleanup old backups
  if ! cleanup_old_backups; then
    err "Failed to cleanup old backups"
    exit 1
  fi

  log "========== Backup completed successfully =========="
  return 0
}

main "$@"
