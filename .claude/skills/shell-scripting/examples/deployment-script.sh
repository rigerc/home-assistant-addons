#!/bin/bash
#
# Application deployment script with rollback capability.
# Demonstrates advanced patterns: locking, validation, retry logic.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly APP_DIR="/opt/myapp"
readonly RELEASES_DIR="${APP_DIR}/releases"
readonly CURRENT_LINK="${APP_DIR}/current"
readonly SHARED_DIR="${APP_DIR}/shared"
readonly LOCK_FILE="/var/lock/deploy.lock"
readonly MAX_RELEASES=5

# Global variables
RELEASE_DIR=''
ROLLBACK_REQUIRED='false'

#######################################
# Print colored output if terminal supports it
# Arguments:
#   Color code
#   Message
#######################################
print_color() {
  local color="$1"
  shift
  if [[ -t 1 ]]; then
    echo -e "\033[${color}m$*\033[0m"
  else
    echo "$*"
  fi
}

log_info()    { print_color "0;32" "INFO: $*"; }
log_warn()    { print_color "1;33" "WARN: $*" >&2; }
log_error()   { print_color "0;31" "ERROR: $*" >&2; }
log_success() { print_color "1;32" "SUCCESS: $*"; }

#######################################
# Acquire deployment lock to prevent concurrent deployments
# Returns:
#   0 on success, 1 if lock already held
#######################################
acquire_lock() {
  local lock_fd=200

  eval "exec ${lock_fd}>${LOCK_FILE}"

  if ! flock -n "${lock_fd}"; then
    log_error "Another deployment is already in progress"
    return 1
  fi

  log_info "Deployment lock acquired"
  return 0
}

#######################################
# Cleanup function called on exit
#######################################
cleanup() {
  local exit_code=$?

  if [[ "${ROLLBACK_REQUIRED}" == 'true' ]]; then
    log_warn "Deployment failed, performing rollback..."
    perform_rollback
  fi

  if [[ -f "${LOCK_FILE}" ]]; then
    rm -f "${LOCK_FILE}"
    log_info "Deployment lock released"
  fi

  if (( exit_code == 0 )); then
    log_success "Deployment completed successfully"
  else
    log_error "Deployment failed with exit code: ${exit_code}"
  fi

  exit "${exit_code}"
}

trap cleanup EXIT

#######################################
# Retry a command with exponential backoff
# Arguments:
#   Command and arguments to retry
# Returns:
#   0 if command succeeds, 1 if all retries fail
#######################################
retry() {
  local max_attempts=3
  local delay=2
  local attempt=1

  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi

    log_warn "Attempt ${attempt}/${max_attempts} failed. Retrying in ${delay}s..."
    sleep "${delay}"
    (( delay *= 2 ))
    (( attempt++ ))
  done

  log_error "Command failed after ${max_attempts} attempts: $*"
  return 1
}

#######################################
# Validate deployment environment
# Returns:
#   0 if valid, 1 otherwise
#######################################
validate_environment() {
  log_info "Validating deployment environment..."

  local -a required_dirs=("${APP_DIR}" "${RELEASES_DIR}" "${SHARED_DIR}")
  local dir

  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "${dir}" ]]; then
      log_error "Required directory missing: ${dir}"
      return 1
    fi
  done

  local -a required_commands=(git rsync systemctl)
  local cmd
  local missing=()

  for cmd in "${required_commands[@]}"; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log_error "Missing required commands: ${missing[*]}"
    return 1
  fi

  log_success "Environment validation passed"
  return 0
}

#######################################
# Create new release directory
# Sets RELEASE_DIR global variable
# Returns:
#   0 on success, 1 on error
#######################################
create_release() {
  local timestamp
  timestamp="$(date +'%Y%m%d%H%M%S')"

  RELEASE_DIR="${RELEASES_DIR}/${timestamp}"

  log_info "Creating release directory: ${RELEASE_DIR}"

  if ! mkdir -p "${RELEASE_DIR}"; then
    log_error "Failed to create release directory"
    return 1
  fi

  return 0
}

#######################################
# Deploy application code to release directory
# Globals:
#   RELEASE_DIR
# Arguments:
#   Git repository URL
#   Git branch/tag
# Returns:
#   0 on success, 1 on error
#######################################
deploy_code() {
  local repo_url="$1"
  local git_ref="$2"

  log_info "Deploying code from ${repo_url} (${git_ref})..."

  if ! retry git clone --depth 1 --branch "${git_ref}" "${repo_url}" "${RELEASE_DIR}"; then
    log_error "Failed to clone repository"
    return 1
  fi

  # Remove .git directory to save space
  rm -rf "${RELEASE_DIR}/.git"

  log_success "Code deployed successfully"
  return 0
}

#######################################
# Link shared resources to release directory
# Globals:
#   RELEASE_DIR
#   SHARED_DIR
# Returns:
#   0 on success, 1 on error
#######################################
link_shared_resources() {
  log_info "Linking shared resources..."

  local -a shared_items=("config" "uploads" "logs")
  local item

  for item in "${shared_items[@]}"; do
    local shared_path="${SHARED_DIR}/${item}"
    local release_path="${RELEASE_DIR}/${item}"

    if [[ -e "${shared_path}" ]]; then
      if ! ln -sfn "${shared_path}" "${release_path}"; then
        log_error "Failed to link shared item: ${item}"
        return 1
      fi
    fi
  done

  log_success "Shared resources linked"
  return 0
}

#######################################
# Run health check on deployment
# Arguments:
#   URL to check
# Returns:
#   0 if healthy, 1 otherwise
#######################################
health_check() {
  local url="$1"

  log_info "Running health check: ${url}"

  local max_attempts=10
  local attempt=1

  while (( attempt <= max_attempts )); do
    if curl -f -s -o /dev/null "${url}"; then
      log_success "Health check passed"
      return 0
    fi

    log_info "Health check attempt ${attempt}/${max_attempts} failed, retrying..."
    sleep 2
    (( attempt++ ))
  done

  log_error "Health check failed after ${max_attempts} attempts"
  return 1
}

#######################################
# Activate the release by updating the current symlink
# Globals:
#   RELEASE_DIR
#   CURRENT_LINK
# Returns:
#   0 on success, 1 on error
#######################################
activate_release() {
  log_info "Activating release..."

  ROLLBACK_REQUIRED='true'

  # Create temporary symlink
  local temp_link="${CURRENT_LINK}.tmp"
  if ! ln -sfn "${RELEASE_DIR}" "${temp_link}"; then
    log_error "Failed to create temporary symlink"
    return 1
  fi

  # Atomically replace current symlink
  if ! mv -Tf "${temp_link}" "${CURRENT_LINK}"; then
    log_error "Failed to activate release"
    rm -f "${temp_link}"
    return 1
  fi

  log_success "Release activated: ${RELEASE_DIR}"
  return 0
}

#######################################
# Restart application service
# Arguments:
#   Service name
# Returns:
#   0 on success, 1 on error
#######################################
restart_service() {
  local service="$1"

  log_info "Restarting service: ${service}"

  if ! systemctl restart "${service}"; then
    log_error "Failed to restart service"
    return 1
  fi

  # Wait for service to be active
  local max_wait=30
  local waited=0

  while (( waited < max_wait )); do
    if systemctl is-active --quiet "${service}"; then
      log_success "Service restarted successfully"
      return 0
    fi
    sleep 1
    (( waited++ ))
  done

  log_error "Service did not become active within ${max_wait} seconds"
  return 1
}

#######################################
# Rollback to previous release
# Returns:
#   0 on success, 1 on error
#######################################
perform_rollback() {
  if [[ ! -L "${CURRENT_LINK}" ]]; then
    log_error "No current release to rollback from"
    return 1
  fi

  local current
  current="$(readlink "${CURRENT_LINK}")"

  local -a releases
  readarray -t releases < <(
    find "${RELEASES_DIR}" -maxdepth 1 -type d \
      | sort -r \
      | grep -v "^${RELEASES_DIR}$"
  )

  local previous_release=''
  local release

  for release in "${releases[@]}"; do
    if [[ "${release}" != "${current}" ]]; then
      previous_release="${release}"
      break
    fi
  done

  if [[ -z "${previous_release}" ]]; then
    log_error "No previous release available for rollback"
    return 1
  fi

  log_info "Rolling back to: ${previous_release}"

  if ! ln -sfn "${previous_release}" "${CURRENT_LINK}"; then
    log_error "Rollback failed"
    return 1
  fi

  log_success "Rollback completed"
  ROLLBACK_REQUIRED='false'
  return 0
}

#######################################
# Cleanup old releases keeping only MAX_RELEASES
# Returns:
#   0 on success, 1 on error
#######################################
cleanup_old_releases() {
  log_info "Cleaning up old releases (keeping ${MAX_RELEASES})..."

  local -a old_releases
  readarray -t old_releases < <(
    find "${RELEASES_DIR}" -maxdepth 1 -type d \
      | sort -r \
      | tail -n +$((MAX_RELEASES + 1)) \
      | grep -v "^${RELEASES_DIR}$"
  )

  if (( ${#old_releases[@]} == 0 )); then
    log_info "No old releases to remove"
    return 0
  fi

  local release
  for release in "${old_releases[@]}"; do
    log_info "Removing old release: ${release}"
    if ! rm -rf "${release}"; then
      log_warn "Failed to remove old release: ${release}"
    fi
  done

  log_success "Cleaned up ${#old_releases[@]} old release(s)"
  return 0
}

#######################################
# Main deployment function
# Arguments:
#   Git repository URL
#   Git branch/tag
#   Service name
#   Health check URL
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  if (( $# != 4 )); then
    log_error "Usage: ${SCRIPT_NAME} <repo_url> <git_ref> <service> <health_url>"
    exit 1
  fi

  local repo_url="$1"
  local git_ref="$2"
  local service="$3"
  local health_url="$4"

  log_info "========== Starting deployment =========="
  log_info "Repository: ${repo_url}"
  log_info "Reference: ${git_ref}"
  log_info "Service: ${service}"

  # Acquire deployment lock
  if ! acquire_lock; then
    exit 1
  fi

  # Validate environment
  if ! validate_environment; then
    exit 1
  fi

  # Create and deploy release
  if ! create_release; then
    exit 1
  fi

  if ! deploy_code "${repo_url}" "${git_ref}"; then
    exit 1
  fi

  if ! link_shared_resources; then
    exit 1
  fi

  # Activate release
  if ! activate_release; then
    exit 1
  fi

  # Restart service
  if ! restart_service "${service}"; then
    exit 1
  fi

  # Health check
  if ! health_check "${health_url}"; then
    exit 1
  fi

  # Cleanup old releases
  cleanup_old_releases

  # Deployment successful, disable rollback
  ROLLBACK_REQUIRED='false'

  log_success "========== Deployment completed successfully =========="
  return 0
}

main "$@"
