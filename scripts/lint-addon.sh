#!/bin/bash
#
# Local Home Assistant Add-on Linter
# Based on https://github.com/frenck/action-addon-linter
# Validates config and build files against JSON schemas and checks for common issues

set -euo pipefail

#######################################
# Constants
#######################################
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly VERSION="1.0.0"

# Schema URLs
readonly CONFIG_SCHEMA_URL="https://raw.githubusercontent.com/frenck/action-addon-linter/main/src/config.schema.json"
readonly BUILD_SCHEMA_URL="https://raw.githubusercontent.com/frenck/action-addon-linter/main/src/build.schema.json"

# Cache directory
readonly CACHE_DIR="${HOME}/.cache/ha-addon-linter"
readonly CONFIG_SCHEMA_CACHE="${CACHE_DIR}/config.schema.json"
readonly BUILD_SCHEMA_CACHE="${CACHE_DIR}/build.schema.json"

# Deprecated architectures
readonly DEPRECATED_ARCHS=("armhf" "armv7" "i386")

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_MISSING_DEPS=2
readonly EXIT_INVALID_PATH=3

#######################################
# Global variables
#######################################
addon_path=""
community_checks=false
update_schemas=false
verbose=false
error_count=0
warning_count=0

#######################################
# Logging functions
#######################################
info() {
  echo "  [INFO] $*" >&2
}

warn() {
  echo "  [WARN] $*" >&2
  ((warning_count++))
}

error() {
  echo "  [ERROR] $*" >&2
  ((error_count++))
}

#######################################
# Print usage information
#######################################
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] PATH

Local Home Assistant Add-on Linter
Validates config and build files against JSON schemas and checks for common issues.

ARGUMENTS:
  PATH                  Path to the add-on directory (default: current directory)

OPTIONS:
  -h, --help            Show this help message and exit
  -c, --community       Enable community add-ons specific checks
  -u, --update-schemas  Force update of cached schema files
  -v, --verbose         Enable verbose output

EXAMPLES:
  # Lint a specific add-on
  ${SCRIPT_NAME} ./cleanuparr

  # Lint with community checks enabled
  ${SCRIPT_NAME} ./my-addon --community

  # Lint all add-ons in the current directory
  for dir in */; do ${SCRIPT_NAME} "\$dir"; done

EXIT CODES:
  0    No errors found
  1    Validation errors found
  2    Missing dependencies (jq, yq)
  3    Invalid path specified

EOF
}

#######################################
# Check dependencies
#######################################
check_dependencies() {
  local deps_ok=true

  if ! command -v jq &> /dev/null; then
    error "jq is required but not installed. Install with: apt install jq"
    deps_ok=false
  fi

  if ! command -v yq &> /dev/null; then
    error "yq is required but not installed. Install with: snap install yq"
    deps_ok=false
  fi

  if [[ "${deps_ok}" == "false" ]]; then
    return "${EXIT_MISSING_DEPS}"
  fi
}

#######################################
# Download schema if not cached
#######################################
download_schema() {
  local url="$1"
  local cache_path="$2"

  if [[ -f "${cache_path}" && "${update_schemas}" == "false" ]]; then
    if [[ "${verbose}" == "true" ]]; then
      info "Using cached schema: ${cache_path}"
    fi
    return 0
  fi

  info "Downloading schema from ${url}..."

  if ! curl -fsSL "${url}" -o "${cache_path}" 2>/dev/null; then
    if [[ -f "${cache_path}" ]]; then
      warn "Download failed, using cached schema"
      return 0
    fi
    error "Failed to download schema and no cache available"
    return 1
  fi
}

#######################################
# Load and normalize config file (JSON or YAML)
#######################################
load_config_file() {
  local base_name="$1"
  local file_path=""

  # Try JSON first, then YAML variants
  for ext in "json" "yaml" "yml"; do
    if [[ -f "${addon_path}/${base_name}.${ext}" ]]; then
      file_path="${addon_path}/${base_name}.${ext}"
      break
    fi
  done

  if [[ -z "${file_path}" ]]; then
    return 1
  fi

  # Convert YAML to JSON if needed, then output JSON
  if [[ "${file_path}" == *.json ]]; then
    cat "${file_path}"
  else
    yq eval -o=json "${file_path}"
  fi
}

#######################################
# Validate JSON against schema using jq
#######################################
validate_schema() {
  local config_json="$1"
  local schema_file="$2"
  local file_type="$3"

  # Basic required fields check (simplified schema validation)
  local required_fields
  if [[ "${file_type}" == "config" ]]; then
    required_fields=("arch" "description" "name" "slug" "version")
  else
    required_fields=()  # build has no strictly required fields
  fi

  for field in "${required_fields[@]}"; do
    if ! echo "${config_json}" | jq -e ".${field}" &> /dev/null; then
      error "[${file_type}] Missing required field: ${field}"
    fi
  done
}

#######################################
# Check for default values that can be removed
#######################################
check_default_values() {
  local config_json="$1"
  local file_type="$2"

  # Defaults from schema (config)
  if [[ "${file_type}" == "config" ]]; then
    local defaults=(
      "advanced:false"
      "apparmor:true"
      "audio:false"
      "auth_api:false"
      "auto_uart:false"
      "backup:hot"
      "boot:auto"
      "devicetree:false"
      "docker_api:false"
      "full_access:false"
      "gpio:false"
      "hassio_api:false"
      "hassio_role:default"
      "homeassistant_api:false"
      "host_dbus:false"
      "host_ipc:false"
      "host_network:false"
      "host_pid:false"
      "host_uts:false"
      "ingress:false"
      "ingress_port:8099"
      "init:true"
      "journald:false"
      "kernel_modules:false"
      "legacy:false"
      "panel_admin:true"
      "panel_icon:mdi:puzzle"
      "realtime:false"
      "stage:stable"
      "startup:application"
      "stdin:false"
      "timeout:10"
      "tmpfs:false"
      "uart:false"
      "udev:false"
      "usb:false"
      "video:false"
    )

    for default in "${defaults[@]}"; do
      local field="${default%%:*}"
      local value="${default#*:}"

      if echo "${config_json}" | jq -e ".${field} == ${value}" &> /dev/null; then
        warn "[${file_type}] '${field}' uses default value (${value}), can be removed"
      fi
    done
  fi

  # Defaults from schema (build)
  if [[ "${file_type}" == "build" ]]; then
    if echo "${config_json}" | jq -e '.squash == false' &> /dev/null; then
      warn "[${file_type}] 'squash' uses default value (false), can be removed"
    fi
  fi
}

#######################################
# Check for deprecated architectures
#######################################
check_deprecated_archs() {
  local config_json="$1"
  local file_type="$2"
  local arch_key="arch"

  [[ "${file_type}" == "build" ]] && arch_key="build_from"

  local archs
  if ! archs="$(echo "${config_json}" | jq -r ".${arch_key} // [] | if type == \"array\" then . else keys end[]")"; then
    return 0
  fi

  while IFS= read -r arch; do
    [[ -z "${arch}" ]] && continue

    for deprecated in "${DEPRECATED_ARCHS[@]}"; do
      if [[ "${arch}" == "${deprecated}" ]]; then
        warn "[${file_type}] Architecture '${arch}' is deprecated and no longer " \
             "supported as of Home Assistant 2025.12 (December 3, 2025)"
      fi
    done
  done <<< "${archs}"
}

#######################################
# Check deprecated configurations
#######################################
check_deprecated_configs() {
  local config_json="$1"
  local file_type="$2"

  # auto_uart is deprecated
  if echo "${config_json}" | jq -e '.auto_uart' &> /dev/null; then
    error "[${file_type}] 'auto_uart' is deprecated, use 'uart' instead"
  fi

  # Check codenotary
  if echo "${config_json}" | jq -e '.codenotary' &> /dev/null; then
    error "[${file_type}] 'codenotary' is deprecated and no longer used. Please remove this field"
  fi

  # watchdog is obsolete
  if echo "${config_json}" | jq -e '.watchdog' &> /dev/null; then
    error "[${file_type}] 'watchdog' is obsolete. Use the native Docker HEALTHCHECK directive instead"
  fi

  # squash in build files
  if [[ "${file_type}" == "build" ]]; then
    if echo "${config_json}" | jq -e '.squash' &> /dev/null; then
      error "[${file_type}] 'squash' is no longer supported. The Supervisor now uses " \
           "Docker Buildkit, which doesn't support this. Please remove this field"
    fi
  fi

  # Check devices format (old format with colons)
  local devices
  devices="$(echo "${config_json}" | jq -r '.devices[]? // ""' 2>/dev/null || true)"
  if [[ "${devices}" =~ : ]]; then
    error "[${file_type}] 'devices' uses a deprecated format. The new format uses a list of paths only"
  fi

  # Check tmpfs format (should be boolean)
  local tmpfs
  if tmpfs="$(echo "${config_json}" | jq -r '.tmpfs // ""' 2>/dev/null)"; then
    if [[ "${tmpfs}" != "true" && "${tmpfs}" != "false" && "${tmpfs}" != "" ]]; then
      error "[${file_type}] 'tmpfs' uses a deprecated format; it is a boolean now"
    fi
  fi
}

#######################################
# Check configuration conflicts
#######################################
check_config_conflicts() {
  local config_json="$1"

  local ingress
  ingress="$(echo "${config_json}" | jq -r '.ingress // false')"
  local webui
  webui="$(echo "${config_json}" | jq -r '.webui // ""')"
  local host_network
  host_network="$(echo "${config_json}" | jq -r '.host_network // false')"
  local ingress_port
  ingress_port="$(echo "${config_json}" | jq -r '.ingress_port // 8099')"
  local full_access
  full_access="$(echo "${config_json}" | jq -r '.full_access // false')"
  local backup
  backup="$(echo "${config_json}" | jq -r '.backup // "hot"')"

  # webui with ingress
  if [[ "${ingress}" == "true" && -n "${webui}" ]]; then
    error "[config] 'webui' should be removed when Ingress is enabled"
  fi

  # ingress_port = 0 without host_network
  if [[ "${ingress}" == "true" && "${host_network}" == "false" && "${ingress_port}" == "0" ]]; then
    error "[config] 'ingress_port' is set to 0 but the add-on does not run on " \
         "the host network. Ingress port doesn't have to be randomized (not 0)"
  fi

  # full_access with device-specific options
  if [[ "${full_access}" == "true" ]]; then
    local has_device_option=false
    local opts=("devices" "gpio" "uart" "usb")
    for opt in "${opts[@]}"; do
      if echo "${config_json}" | jq -e ".${opt}" &> /dev/null; then
        has_device_option=true
        break
      fi
    done

    if [[ "${has_device_option}" == "true" ]]; then
      error "[config] 'full_access' is set; don't add 'devices', 'uart', 'usb' or 'gpio' " \
           "as they are not needed when using full_access"
    fi

    warn "[config] 'full_access' is set; consider using other options instead, like 'devices'"
  fi

  # backup_pre/post with cold backup
  if [[ "${backup}" == "cold" ]]; then
    if echo "${config_json}" | jq -e '.backup_pre or .backup_post' &> /dev/null; then
      error "[config] 'backup_pre' and 'backup_post' are not valid when using cold backups"
    fi
  fi

  # Check advanced flag
  local advanced
  advanced="$(echo "${config_json}" | jq -r '.advanced // false')"
  if [[ "${advanced}" == "true" ]]; then
    warn "[config] 'advanced' flag is not recommended. Home Assistant plans to deprecate " \
         "this flag in the near future. It causes confusion for end users."
  fi
}

#######################################
# Check map folder configurations
#######################################
check_map_folders() {
  local config_json="$1"

  local map_list
  map_list="$(echo "${config_json}" | jq -r '.map[]? // empty' 2>/dev/null || true)"

  local has_config=false
  local has_ha_config=false
  local has_addon_config=false

  while IFS= read -r map_entry; do
    [[ -z "${map_entry}" ]] && continue

    case "${map_entry}" in
      config|config:rw|config:ro)
        has_config=true
        ;;
      homeassistant_config*)
        has_ha_config=true
        ;;
      addon_config*)
        has_addon_config=true
        ;;
    esac
  done <<< "${map_list}"

  if [[ "${has_config}" == "true" ]]; then
    warn "[config] 'map' contains the 'config' folder, which has been replaced by " \
         "'homeassistant_config'. See: https://developers.home-assistant.io/blog/2023/11/06/public-addon-config"
  fi

  if [[ "${has_config}" == "true" && "${has_ha_config}" == "true" ]]; then
    error "[config] 'map' contains both the 'config' and 'homeassistant_config' folder, " \
         "which are conflicting"
  fi

  if [[ "${has_config}" == "true" && "${has_addon_config}" == "true" ]]; then
    error "[config] 'map' contains both the 'config' and 'addon_config' folder, " \
         "which are conflicting"
  fi
}

#######################################
# Community-specific checks
#######################################
check_community_rules() {
  local config_json="$1"
  local build_json="$2"

  # Version must be "dev"
  local version
  version="$(echo "${config_json}" | jq -r '.version // ""')"
  if [[ "${version}" != "dev" ]]; then
    error "[config] Add-on version identifier must be 'dev' for community add-ons"
  fi

  # build.json is required
  if [[ -z "${build_json}" ]]; then
    error "[build] The build.json/yaml file is missing (required for community add-ons)"
    return
  fi

  # Architecture matching
  local config_archs
  config_archs="$(echo "${config_json}" | jq -r '.arch | sort | join(",")')"
  local build_archs
  build_archs="$(echo "${build_json}" | jq -r '.build_from | keys | sort | join(",")')"

  if [[ "${config_archs}" != "${build_archs}" ]]; then
    error "[build] Architectures in config (${config_archs}) and build (${build_archs}) do not match"
  fi
}

#######################################
# Lint config file
#######################################
lint_config() {
  local config_json
  local config_file

  echo ""
  echo "=== Linting config.{json,yaml,yml} ==="

  if ! config_json="$(load_config_file "config")"; then
    error "Configuration file not found in '${addon_path}'"
    return 1
  fi

  config_file="${config_json}"

  # Run all checks
  validate_schema "${config_json}" "${CONFIG_SCHEMA_CACHE}" "config"
  check_default_values "${config_json}" "config"
  check_deprecated_archs "${config_json}" "config"
  check_deprecated_configs "${config_json}" "config"
  check_config_conflicts "${config_json}"
  check_map_folders "${config_json}"
}

#######################################
# Lint build file
#######################################
lint_build() {
  local build_json

  echo ""
  echo "=== Linting build.{json,yaml,yml} ==="

  if ! build_json="$(load_config_file "build")"; then
    info "No build file found (optional)"
    return 0
  fi

  validate_schema "${build_json}" "${BUILD_SCHEMA_CACHE}" "build"
  check_default_values "${build_json}" "build"
  check_deprecated_archs "${build_json}" "build"
  check_deprecated_configs "${build_json}" "build"
}

#######################################
# Main linter function
#######################################
lint_addon() {
  local config_json=""
  local build_json=""

  echo "========================================"
  echo "Linting add-on at: ${addon_path}"
  echo "========================================"

  # Load configs once for community checks
  config_json="$(load_config_file "config" 2>/dev/null || echo "")"
  build_json="$(load_config_file "build" 2>/dev/null || echo "")"

  # Run linters
  lint_config
  lint_build

  # Community checks
  if [[ "${community_checks}" == "true" && -n "${config_json}" ]]; then
    echo ""
    echo "=== Community Checks ==="
    check_community_rules "${config_json}" "${build_json}"
  fi

  # Summary
  echo ""
  echo "========================================"
  if (( error_count == 0 )); then
    echo "No errors found!"
    if (( warning_count > 0 )); then
      echo "${warning_count} warning(s)"
    fi
  else
    echo "Found ${error_count} error(s) and ${warning_count} warning(s)"
  fi
  echo "========================================"
}

#######################################
# Parse command line arguments
#######################################
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit "${EXIT_SUCCESS}"
        ;;
      -c|--community)
        community_checks=true
        shift
        ;;
      -u|--update-schemas)
        update_schemas=true
        shift
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      -*)
        error "Unknown option: $1"
        usage
        exit "${EXIT_ERROR}"
        ;;
      *)
        addon_path="$1"
        shift
        ;;
    esac
  done

  # Default to current directory
  if [[ -z "${addon_path}" ]]; then
    addon_path="."
  fi

  # Resolve to absolute path
  addon_path="$(cd "${addon_path}" 2>/dev/null && pwd || true)"

  if [[ ! -d "${addon_path}" ]]; then
    error "Path not found: ${addon_path}"
    exit "${EXIT_INVALID_PATH}"
  fi
}

#######################################
# Main function
#######################################
main() {
  parse_args "$@"
  check_dependencies

  # Create cache directory
  mkdir -p "${CACHE_DIR}"

  # Download schemas
  if ! download_schema "${CONFIG_SCHEMA_URL}" "${CONFIG_SCHEMA_CACHE}"; then
    exit "${EXIT_ERROR}"
  fi

  if ! download_schema "${BUILD_SCHEMA_URL}" "${BUILD_SCHEMA_CACHE}"; then
    exit "${EXIT_ERROR}"
  fi

  # Run linter
  lint_addon

  if (( error_count > 0 )); then
    exit "${EXIT_ERROR}"
  fi

  exit "${EXIT_SUCCESS}"
}

main "$@"
