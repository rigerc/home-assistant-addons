#!/bin/bash
#
# Interactive script to launch AI assistant (Zai or Claude) with optional resume
# Refactored to follow Google Shell Style Guide template structure
#
# Usage: start2.sh [OPTIONS]
#   -h              Show this help message and exit
#   -V              Show version and exit
#   -v              Verbose mode (enables INFO and DEBUG logs)
#   -d              Debug mode (enables bash tracing with set -x)
#   -n              Dry run (show what would be done without doing it)
#   --upd-fail      Simulate update failure (testing, requires debug mode)
#   --upd-success   Simulate update success (testing, requires debug mode)

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME
readonly VERSION="1.0.0"

# Log levels
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default configuration
readonly DEFAULT_LOG_LEVEL="${LOG_LEVEL_INFO}"

# Random spinner styles for gum spin
readonly -a SPINNER_STYLES=("line" "dot" "minidot" "jump" "pulse" "points" "globe" "moon" "monkey" "meter" "hamburger")
readonly GUM_SPINNER="${SPINNER_STYLES[$RANDOM % ${#SPINNER_STYLES[@]}]}"

# Default flag values
readonly DEFAULT_DEBUG_MODE='false'
readonly DEFAULT_UPD_FAIL='false'
readonly DEFAULT_UPD_SUCCESS='false'
readonly DEFAULT_DRY_RUN='false'

# Temporary directory for cleanup
TEMP_DIR=''

# Global log level for cleanup handler (set in main)
CURRENT_LOG_LEVEL=''

#######################################
# Logging functions with levels
# Arguments:
#   Log level (1-4)
#   Current log level threshold
#   Log message
# Outputs:
#   Formatted log message to stderr
#######################################
log() {
  local level="$1"
  local current_level="$2"
  shift 2
  local message="$*"

  if (( level <= current_level )); then
    local level_name
    local color_code=''
    local reset_code=''

    # Add colors if outputting to terminal
    if [[ -t 2 ]]; then
      reset_code='\033[0m'
      case "${level}" in
        "${LOG_LEVEL_ERROR}") level_name="ERROR"; color_code='\033[0;31m' ;;
        "${LOG_LEVEL_WARN}")  level_name="WARN "; color_code='\033[1;33m' ;;
        "${LOG_LEVEL_INFO}")  level_name="INFO "; color_code='\033[0;32m' ;;
        "${LOG_LEVEL_DEBUG}") level_name="DEBUG"; color_code='\033[0;36m' ;;
      esac
    else
      case "${level}" in
        "${LOG_LEVEL_ERROR}") level_name="ERROR" ;;
        "${LOG_LEVEL_WARN}")  level_name="WARN " ;;
        "${LOG_LEVEL_INFO}")  level_name="INFO " ;;
        "${LOG_LEVEL_DEBUG}") level_name="DEBUG" ;;
      esac
    fi

    printf '%b[%s] [%s] %s%b\n' "${color_code}" "$(date +'%Y-%m-%d %H:%M:%S')" "${level_name}" "${message}" "${reset_code}" >&2
  fi
}

#######################################
# Display usage information
#######################################
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Interactive AI assistant launcher with update checking and session management.

OPTIONS:
  -h              Show this help message and exit
  -V              Show version and exit
  -v              Verbose mode (enables INFO and DEBUG logs)
  -d              Debug mode (enables bash tracing with set -x)
  -n              Dry run (show what would be done without doing it)
  --upd-fail      Simulate update failure (testing, requires debug mode)
  --upd-success   Simulate update success (testing, requires debug mode)

EXAMPLES:
  # Basic usage - launch interactive menu
  ${SCRIPT_NAME}

  # Debug mode with verbose logging
  ${SCRIPT_NAME} -d

  # Verbose mode
  ${SCRIPT_NAME} -v

  # Simulate update success (for testing)
  ${SCRIPT_NAME} -d --upd-success

EXIT CODES:
  0   Success
  1   General error
  2   Invalid arguments
  3   Prerequisite check failed

REQUIREMENTS:
  - gum: https://github.com/charmbracelet/gum
  - claude: https://claude.ai/download
  - kairo: https://github.com/dkmnx/kairo (optional, for zAI)
  - claudeup: https://github.com/claudeup/claudeup (optional, for plugin updates)

EOF
}

#######################################
# Show version information
#######################################
version() {
  echo "${SCRIPT_NAME} version ${VERSION}"
}

#######################################
# Cleanup temporary resources
# Called automatically on script exit
# Uses global CURRENT_LOG_LEVEL for logging
#######################################
cleanup() {
  local exit_code=$?
  local log_level="${CURRENT_LOG_LEVEL:-${DEFAULT_LOG_LEVEL}}"

  set +e  # Don't exit on error during cleanup

  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Cleaning up temporary directory: ${TEMP_DIR}"
    rm -rf "${TEMP_DIR}"
  fi

  if (( exit_code == 0 )); then
    log "${LOG_LEVEL_INFO}" "${log_level}" "Script completed successfully"
  else
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Script failed with exit code: ${exit_code}"
  fi
}

#######################################
# Parse command-line arguments
# Arguments:
#   All script arguments
# Outputs:
#   Prints parsed config as key=value pairs
# Returns:
#   0 on success, exits on error
#######################################
parse_arguments() {
  local log_level="${DEFAULT_LOG_LEVEL}"
  local debug_mode="${DEFAULT_DEBUG_MODE}"
  local dry_run="${DEFAULT_DRY_RUN}"
  local upd_fail="${DEFAULT_UPD_FAIL}"
  local upd_success="${DEFAULT_UPD_SUCCESS}"
  local opt

  while getopts 'hVvdn' opt; do
    case "${opt}" in
      h)
        usage
        exit 0
        ;;
      V)
        version
        exit 0
        ;;
      v)
        log_level="${LOG_LEVEL_DEBUG}"
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Verbose mode enabled"
        ;;
      d)
        debug_mode='true'
        log_level="${LOG_LEVEL_DEBUG}"
        set -x  # Enable bash tracing
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Debug mode enabled (bash tracing active)"
        ;;
      n)
        dry_run='true'
        log "${LOG_LEVEL_INFO}" "${log_level}" "Dry run mode enabled"
        ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
  done

  shift $((OPTIND - 1))

  # Parse long options manually
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --upd-fail)
        upd_fail='true'
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Update failure simulation enabled"
        shift
        ;;
      --upd-success)
        upd_success='true'
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Update success simulation enabled"
        shift
        ;;
      *)
        log "${LOG_LEVEL_ERROR}" "${log_level}" "Unknown argument: $1"
        usage >&2
        exit 2
        ;;
    esac
  done

  # Validate that upd-fail and upd-success require debug mode
  if [[ "${upd_fail}" == 'true' ]] || [[ "${upd_success}" == 'true' ]]; then
    if [[ "${debug_mode}" != 'true' ]]; then
      log "${LOG_LEVEL_ERROR}" "${log_level}" "--upd-fail and --upd-success require debug mode (-d)"
      usage >&2
      exit 2
    fi
  fi

  # Output configuration (parsed by caller)
  echo "log_level=${log_level}"
  echo "debug_mode=${debug_mode}"
  echo "dry_run=${dry_run}"
  echo "upd_fail=${upd_fail}"
  echo "upd_success=${upd_success}"
}

#######################################
# Validate script prerequisites
# Arguments:
#   Log level
# Returns:
#   0 on success, 1 on error
#######################################
validate_prerequisites() {
  local log_level="$1"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Validating prerequisites"

  local cmd
  local missing=()

  # Check required commands
  for cmd in gum claude; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Missing required commands: ${missing[*]}"
    if [[ " ${missing[*]} " =~ " gum " ]]; then
      log "${LOG_LEVEL_ERROR}" "${log_level}" "Install gum from: https://github.com/charmbracelet/gum"
    fi
    if [[ " ${missing[*]} " =~ " claude " ]]; then
      log "${LOG_LEVEL_ERROR}" "${log_level}" "Install claude from: https://claude.ai/download"
    fi
    return 1
  fi

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "gum found: $(command -v gum)"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "claude found: $(command -v claude)"

  # Check optional commands (warn only)
  if ! command -v kairo &>/dev/null; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "kairo not found - zAI option will not work"
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Install kairo from: https://github.com/dkmnx/kairo"
  else
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "kairo found: $(command -v kairo)"
  fi

  if ! command -v claudeup &>/dev/null; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "claudeup not found - plugin updates will not work"
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Install claudeup from: https://github.com/claudeup/claudeup"
  else
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "claudeup found: $(command -v claudeup)"
  fi

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "All prerequisites validated"
  return 0
}

#######################################
# Get the current claude version
# Returns:
#   Version string (e.g., "2.1.19") or empty if not found
#######################################
get_claude_version() {
  local version
  version="$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")"
  echo "${version}"
}

#######################################
# Check for claude updates and display status
# Arguments:
#   Log level
#   Update fail simulation flag
#   Update success simulation flag
#######################################
check_claude_update() {
  local log_level="$1"
  local upd_fail="$2"
  local upd_success="$3"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Checking for claude updates..."

  if [[ "${upd_fail}" == "true" ]]; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "UPD_FAIL enabled - simulating update failure"
  fi
  if [[ "${upd_success}" == "true" ]]; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "UPD_SUCCESS enabled - simulating update success"
  fi

  local old_version
  local new_version
  local output
  local exit_code
  local update_available=false

  # Get old version before update
  old_version="$(get_claude_version)"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Old version: ${old_version}"

  # Simulate update success if UPD_SUCCESS is enabled with debug
  if [[ "${upd_success}" == "true" ]]; then
    local simulated_new_version
    # Parse version and increment patch number
    local major minor patch
    IFS='.' read -r major minor patch <<< "${old_version:-0.0.0}"
    simulated_new_version="${major}.${minor}.$((patch + 1))"
    gum style --foreground 212 "✓ Claude updated: v${old_version} → v${simulated_new_version} (simulated)"
    gum style --foreground 240 "Changelog: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md"
    return
  fi

  # Create temp file for exit code
  local exit_code_file="${TEMP_DIR}/claude_update_exit"

  # Run update with spinner and capture output
  output="$(gum spin --spinner "${GUM_SPINNER}" --show-error --title "Checking for updates..." -- bash -c "claude update 2>&1; echo \$? > '${exit_code_file}'")"
  exit_code="$(cat "${exit_code_file}" 2>/dev/null || echo 0)"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Update exit code: ${exit_code}"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Update output: ${output}"

  # Check if update is available
  if [[ "${output}" =~ "Claude is managed by Homebrew" ]] && [[ ! "${output}" =~ "up to date" ]]; then
    update_available=true
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Update available detected"
  fi

  # Simulate failure if UPD_FAIL is enabled
  if [[ "${upd_fail}" == "true" ]]; then
    update_available=true
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "UPD_FAIL: forcing update available state"
  fi

  # Handle update scenarios
  if [[ "${update_available}" == "true" ]]; then
    # Update available, try brew upgrade
    gum style --foreground 212 "Update available (v${old_version}), upgrading..."
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Running brew upgrade claude-code..."

    local brew_output
    local brew_exit_code_file="${TEMP_DIR}/brew_upgrade_exit"
    brew_output="$(gum spin --spinner "${GUM_SPINNER}" --show-error --title "Upgrading via Homebrew..." -- bash -c "brew upgrade claude-code 2>&1; echo \$? > '${brew_exit_code_file}'")"
    local brew_exit
    brew_exit="$(cat "${brew_exit_code_file}" 2>/dev/null || echo 0)"

    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Brew exit code: ${brew_exit}"
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Brew output: ${brew_output}"

    # Get new version after upgrade attempt
    new_version="$(get_claude_version)"
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "New version: ${new_version}"

    if (( brew_exit == 0 )); then
      if [[ "${brew_output}" =~ "Already installed" ]] || [[ "${brew_output}" =~ "No upgrade" ]]; then
        gum style --foreground 240 "Claude is already up to date (v${old_version})"
      elif [[ "${new_version}" != "${old_version}" ]] && [[ -n "${new_version}" ]]; then
        gum style --foreground 212 "✓ Claude updated: v${old_version} → v${new_version}"
        gum style --foreground 240 "Changelog: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md"
      else
        gum style --foreground 240 "Claude remains at v${old_version}"
      fi
    else
      log "${LOG_LEVEL_ERROR}" "${log_level}" "Failed to upgrade via Homebrew (v${old_version})"
    fi
  elif [[ "${output}" =~ "up to date" ]]; then
    gum style --foreground 240 "✓ Claude is up to date (v${old_version})"
  elif [[ -n "${old_version}" ]]; then
    gum style --foreground 240 "✓ Claude is up to date (v${old_version})"
  else
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Could not determine update status from output"
  fi
}

#######################################
# Build and execute the selected command
# Arguments:
#   Command base (kairo zai or claude)
#   Resume flag (true for resume, false otherwise)
#   Custom arguments (optional, empty string if none)
#   Log level
#   Dry run flag
#######################################
execute_command() {
  local cmd_base="$1"
  local should_resume="$2"
  local custom_args="${3:-}"
  local log_level="$4"
  local dry_run="$5"
  local final_cmd

  if [[ "${should_resume}" == "true" ]]; then
    if [[ "${cmd_base}" == "kairo zai" ]]; then
      if [[ -n "${custom_args}" ]]; then
        final_cmd="${cmd_base} -- -r ${custom_args}"
      else
        final_cmd="${cmd_base} -- -r"
      fi
    else
      if [[ -n "${custom_args}" ]]; then
        final_cmd="${cmd_base} -r ${custom_args}"
      else
        final_cmd="${cmd_base} -r"
      fi
    fi
  else
    if [[ "${cmd_base}" == "kairo zai" ]]; then
      if [[ -n "${custom_args}" ]]; then
        final_cmd="${cmd_base} -- ${custom_args}"
      else
        final_cmd="${cmd_base}"
      fi
    else
      if [[ -n "${custom_args}" ]]; then
        final_cmd="${cmd_base} ${custom_args}"
      else
        final_cmd="${cmd_base}"
      fi
    fi
  fi

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Executing: ${final_cmd}"

  if [[ "${dry_run}" == 'true' ]]; then
    log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would execute: ${final_cmd}"
    return 0
  fi

  exec ${final_cmd}
}

#######################################
# Check for plugin updates using claudeup
# Arguments:
#   Log level
#######################################
check_plugin_updates() {
  local log_level="$1"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Checking for plugin updates..."

  # Check if claudeup is installed
  if ! command -v claudeup &>/dev/null; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "claudeup is not installed. Please install it from: https://github.com/claudeup/claudeup"
    return 1
  fi

  local output
  local exit_code
  local exit_code_file="${TEMP_DIR}/claudeup_exit"

  # Run claudeup outdated with spinner
  output="$(gum spin --spinner "${GUM_SPINNER}" --show-error --title "Checking for plugin updates..." -- bash -c "claudeup outdated 2>&1; echo \$? > '${exit_code_file}'")"
  exit_code="$(cat "${exit_code_file}" 2>/dev/null || echo 0)"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "claudeup outdated exit code: ${exit_code}"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "claudeup outdated output: ${output}"

  if (( exit_code != 0 )); then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Failed to check for plugin updates"
    return 1
  fi

  # Parse output to count updates available
  # Outdated items have format: "name hash → hash" (may have ⚠ prefix)
  # Warnings have format: "⚠ message" (no → arrow)
  local -a outdated_lines
  local -a warning_lines
  readarray -t outdated_lines < <(grep -E '\s+[0-9a-f]+\s+→\s+[0-9a-f]+' <<< "${output}" || true)
  readarray -t warning_lines < <(grep -E '^\s+⚠' <<< "${output}" | grep -vE '→' || true)

  local outdated_count="${#outdated_lines[@]}"
  local warning_count="${#warning_lines[@]}"

  # Count marketplace updates by extracting section between headers
  local marketplace_section
  local -a marketplace_outdated
  marketplace_section="$(sed -n '/Marketplaces/,/Plugins/p' <<< "${output}")"
  readarray -t marketplace_outdated < <(grep -E '\s+[0-9a-f]+\s+→\s+[0-9a-f]+' <<< "${marketplace_section}" || true)
  local marketplace_updates="${#marketplace_outdated[@]}"

  # Count plugin updates from Plugins section to end
  local plugins_section
  local -a plugin_outdated
  plugins_section="$(sed -n '/Plugins/,$p' <<< "${output}")"
  readarray -t plugin_outdated < <(grep -E '\s+[0-9a-f]+\s+→\s+[0-9a-f]+' <<< "${plugins_section}" || true)
  local plugin_updates="${#plugin_outdated[@]}"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Outdated items: ${outdated_count}, Warnings: ${warning_count}, Marketplaces: ${marketplace_updates}, Plugins: ${plugin_updates}"

  # If no updates and no warnings, everything is up to date
  if (( outdated_count == 0 )) && (( warning_count == 0 )); then
    gum style --foreground 240 "✓ All plugins are up to date"
    return 0
  fi

  # If no updates but there are warnings
  if (( outdated_count == 0 )) && (( warning_count > 0 )); then
    gum style --foreground 240 "✓ All plugins are up to date"
    echo ""
    gum style --foreground "214" "⚠ ${warning_count} marketplace(s) could not be checked:"
    printf '  %s\n' "${warning_lines[@]}" | sed 's/^  ⚠ /  /'
    return 0
  fi

  # Updates available - show summary
  echo ""
  gum style --foreground 212 "Plugin updates available:"

  # Show breakdown
  if (( marketplace_updates > 0 )); then
    gum style --foreground 212 "  • ${marketplace_updates} marketplace(s) need updating"
  fi
  if (( plugin_updates > 0 )); then
    gum style --foreground 212 "  • ${plugin_updates} plugin(s) need updating"
  fi

  # Show warnings if any
  if (( warning_count > 0 )); then
    gum style --foreground "214" "  • ${warning_count} marketplace(s) could not be checked"
  fi

  echo ""

  # Show detailed list of outdated items
  for line in "${outdated_lines[@]}"; do
    # Parse the line format: "  [⚠] name old_hash → new_hash"
    # First strip the ⚠ prefix if present
    local clean_line="${line//⚠/}"
    clean_line="${clean_line#"${clean_line%%[![:space:]]*}"}"  # Trim leading whitespace

    if [[ "${clean_line}" =~ ^([^[:space:]]+)[[:space:]]+([0-9a-f]+)[[:space:]]+→[[:space:]]+([0-9a-f]+) ]]; then
      local name="${BASH_REMATCH[1]}"
      local old_hash="${BASH_REMATCH[2]}"
      local new_hash="${BASH_REMATCH[3]}"
      gum style --foreground 240 "  • ${name}: ${old_hash:0:7} → ${new_hash:0:7}"
    else
      echo "  ${line}"
    fi
  done

  # Show warnings
  if (( warning_count > 0 )); then
    echo ""
    gum style --foreground "214" "Warnings:"
    printf '  %s\n' "${warning_lines[@]}" | sed 's/^  ⚠ /  • /'
  fi

  echo ""

  # Ask if user wants to update
  if gum confirm "Run 'claudeup upgrade' to update?"; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Running claudeup upgrade..."

    local upgrade_output
    local upgrade_exit
    local upgrade_exit_file="${TEMP_DIR}/claudeup_upgrade_exit"

    # Show spinner during upgrade
    upgrade_output="$(gum spin --spinner "${GUM_SPINNER}" --show-error --title "Upgrading plugins..." -- bash -c "claudeup upgrade 2>&1; echo \$? > '${upgrade_exit_file}'")"
    upgrade_exit="$(cat "${upgrade_exit_file}" 2>/dev/null || echo 0)"

    log "${LOG_LEVEL_DEBUG}" "${log_level}" "claudeup upgrade exit code: ${upgrade_exit}"
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "claudeup upgrade output: ${upgrade_output}"

    if (( upgrade_exit == 0 )); then
      # Parse successful updates
      local -a updated_lines
      readarray -t updated_lines < <(grep -E '^✓ .*Updated' <<< "${upgrade_output}" || true)
      local updated_count="${#updated_lines[@]}"

      echo ""
      gum style --foreground 212 "✓ Plugin updates completed"

      if (( updated_count > 0 )); then
        gum style --foreground 240 "  • ${updated_count} marketplace(s) updated"
      fi

      # Show what was updated
      local -a all_success_lines
      readarray -t all_success_lines < <(grep '^✓' <<< "${upgrade_output}" || true)
      printf '  %s\n' "${all_success_lines[@]}"
    else
      log "${LOG_LEVEL_ERROR}" "${log_level}" "Failed to update plugins"
      echo "${upgrade_output}" >&2
      return 1
    fi
  else
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "User declined plugin updates"
  fi

  return 0
}

#######################################
# Main function
# Arguments:
#   All script arguments
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  local log_level="${DEFAULT_LOG_LEVEL}"

  # Parse command-line arguments
  local config
  config="$(parse_arguments "$@")"

  # Extract configuration values
  local debug_mode="${DEFAULT_DEBUG_MODE}"
  local dry_run="${DEFAULT_DRY_RUN}"
  local upd_fail="${DEFAULT_UPD_FAIL}"
  local upd_success="${DEFAULT_UPD_SUCCESS}"
  while IFS='=' read -r key value; do
    case "${key}" in
      log_level) log_level="${value}" ;;
      debug_mode) debug_mode="${value}" ;;
      dry_run) dry_run="${value}" ;;
      upd_fail) upd_fail="${value}" ;;
      upd_success) upd_success="${value}" ;;
    esac
  done <<< "${config}"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Starting ${SCRIPT_NAME} v${VERSION}"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Script directory: ${SCRIPT_DIR}"

  # Set global log level for cleanup handler
  CURRENT_LOG_LEVEL="${log_level}"

  # Create temp directory
  TEMP_DIR="$(mktemp -d)"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Created temporary directory: ${TEMP_DIR}"

  # Register cleanup (uses single quotes to defer expansion)
  trap 'cleanup' EXIT

  # Validate prerequisites
  if ! validate_prerequisites "${log_level}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Prerequisite validation failed"
    exit 1
  fi

  # Check for claude updates
  check_claude_update "${log_level}" "${upd_fail}" "${upd_success}"

  # Select AI assistant
  local assistant
  assistant="$(gum choose --header "Choose AI Assistant" "🤖 zAI" "🧠 Claude" "🔄 Check for plugin updates")" || exit 0
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Selected assistant: ${assistant}"

  # Handle plugin updates check
  if [[ "${assistant}" == "🔄 Check for plugin updates" ]]; then
    check_plugin_updates "${log_level}"
    # After plugin updates, return to assistant selection
    if gum confirm "Launch an assistant?"; then
      assistant="$(gum choose --header "Choose AI Assistant" "🤖 zAI" "🧠 Claude")" || exit 0
      log "${LOG_LEVEL_DEBUG}" "${log_level}" "Selected assistant: ${assistant}"
    else
      return 0
    fi
  fi

  # Check if kairo is available when zAI is selected
  if [[ "${assistant}" == "🤖 zAI" ]] && ! command -v kairo &>/dev/null; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "kairo is not installed. Please install it from: https://github.com/dkmnx/kairo"
    exit 1
  fi

  # Select action
  local action
  action="$(gum choose --header "Choose Action" "✨ New Session" "▶️ Resume")" || exit 0
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Selected action: ${action}"

  local should_resume="false"
  if [[ "${action}" == "▶️ Resume" ]]; then
    should_resume="true"
  fi

  # Ask for custom arguments after action selection
  local custom_args
  custom_args="$(gum input --placeholder "Enter additional arguments (leave empty for none)" --value "")" || exit 0
  if [[ -n "${custom_args}" ]]; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Custom args: ${custom_args}"
  fi

  # Execute based on selection
  case "${assistant}" in
    "🤖 zAI")
      execute_command "kairo zai" "${should_resume}" "${custom_args}" "${log_level}" "${dry_run}"
      ;;
    "🧠 Claude")
      execute_command "claude" "${should_resume}" "${custom_args}" "${log_level}" "${dry_run}"
      ;;
  esac

  return 0
}

# Handle help and version before main (can't exit from subshell in parse_arguments)
for arg in "$@"; do
  case "${arg}" in
    -h|--help)
      usage
      exit 0
      ;;
    -V|--version)
      version
      exit 0
      ;;
  esac
done

main "$@"
