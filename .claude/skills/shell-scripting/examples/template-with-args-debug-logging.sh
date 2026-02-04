#!/bin/bash
#
# Comprehensive script template demonstrating:
# - Argument parsing with getopts
# - Debug mode with -x tracing
# - Multi-level logging
# - Error handling and cleanup
#
# This template is suitable for production scripts requiring robust
# argument handling, debugging capabilities, and structured logging.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly VERSION="1.0.0"

# Log levels
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default configuration
readonly DEFAULT_LOG_LEVEL="${LOG_LEVEL_INFO}"
readonly DEFAULT_OUTPUT_DIR="/tmp/output"
readonly DEFAULT_TIMEOUT=30

# Temporary directory for cleanup
TEMP_DIR=''

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
Usage: ${SCRIPT_NAME} [OPTIONS] INPUT_FILE

Process INPUT_FILE with configurable options, logging, and debugging.

OPTIONS:
  -h              Show this help message and exit
  -V              Show version and exit
  -v              Verbose mode (enables INFO and DEBUG logs)
  -d              Debug mode (enables bash tracing with set -x)
  -n              Dry run (show what would be done without doing it)
  -o DIR          Output directory (default: ${DEFAULT_OUTPUT_DIR})
  -t SECONDS      Timeout in seconds (default: ${DEFAULT_TIMEOUT})
  -l LEVEL        Log level: error(1), warn(2), info(3), debug(4)
                  (default: info)

EXAMPLES:
  # Basic usage
  ${SCRIPT_NAME} input.txt

  # Verbose mode with custom output directory
  ${SCRIPT_NAME} -v -o /custom/output input.txt

  # Debug mode with bash tracing enabled
  ${SCRIPT_NAME} -d input.txt

  # Dry run to see what would happen
  ${SCRIPT_NAME} -n input.txt

  # Set log level to debug and custom timeout
  ${SCRIPT_NAME} -l 4 -t 60 input.txt

EXIT CODES:
  0   Success
  1   General error
  2   Invalid arguments
  3   File not found or not readable

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
# Arguments:
#   Log level for cleanup messages
#######################################
cleanup() {
  local exit_code=$?
  local log_level="${1:-${DEFAULT_LOG_LEVEL}}"

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
  local output_dir="${DEFAULT_OUTPUT_DIR}"
  local timeout="${DEFAULT_TIMEOUT}"
  local verbose='false'
  local debug_mode='false'
  local dry_run='false'
  local input_file=''
  local opt

  while getopts 'hVvdno:t:l:' opt; do
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
        verbose='true'
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
      o)
        output_dir="${OPTARG}"
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Output directory set to: ${output_dir}"
        ;;
      t)
        if ! [[ "${OPTARG}" =~ ^[0-9]+$ ]]; then
          log "${LOG_LEVEL_ERROR}" "${log_level}" "Invalid timeout value: ${OPTARG}"
          usage >&2
          exit 2
        fi
        timeout="${OPTARG}"
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Timeout set to: ${timeout} seconds"
        ;;
      l)
        if ! [[ "${OPTARG}" =~ ^[1-4]$ ]]; then
          log "${LOG_LEVEL_ERROR}" "${log_level}" "Invalid log level: ${OPTARG} (must be 1-4)"
          usage >&2
          exit 2
        fi
        log_level="${OPTARG}"
        log "${LOG_LEVEL_DEBUG}" "${log_level}" "Log level set to: ${log_level}"
        ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
  done

  shift $((OPTIND - 1))

  # Check for required positional argument
  if (( $# == 0 )); then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Missing required INPUT_FILE argument"
    usage >&2
    exit 2
  fi

  input_file="$1"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Input file: ${input_file}"

  # Output configuration (parsed by caller)
  echo "log_level=${log_level}"
  echo "output_dir=${output_dir}"
  echo "timeout=${timeout}"
  echo "verbose=${verbose}"
  echo "debug_mode=${debug_mode}"
  echo "dry_run=${dry_run}"
  echo "input_file=${input_file}"
}

#######################################
# Validate script prerequisites
# Arguments:
#   Log level
#   Input file path
# Returns:
#   0 on success, 1 on error
#######################################
validate_prerequisites() {
  local log_level="$1"
  local input_file="$2"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Validating prerequisites"

  # Check required commands
  local cmd
  local missing=()

  for cmd in awk sed grep; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Missing required commands: ${missing[*]}"
    return 1
  fi

  # Validate input file
  if [[ ! -f "${input_file}" ]]; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Input file not found: ${input_file}"
    return 3
  fi

  if [[ ! -r "${input_file}" ]]; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Input file not readable: ${input_file}"
    return 3
  fi

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "All prerequisites validated"
  return 0
}

#######################################
# Setup required directories and resources
# Arguments:
#   Log level
#   Output directory
#   Dry run flag (true/false)
# Returns:
#   0 on success, 1 on error
#######################################
setup_environment() {
  local log_level="$1"
  local output_dir="$2"
  local dry_run="$3"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Setting up environment"

  # Create output directory
  if [[ ! -d "${output_dir}" ]]; then
    if [[ "${dry_run}" == 'true' ]]; then
      log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would create output directory: ${output_dir}"
    else
      log "${LOG_LEVEL_INFO}" "${log_level}" "Creating output directory: ${output_dir}"
      if ! mkdir -p "${output_dir}"; then
        log "${LOG_LEVEL_ERROR}" "${log_level}" "Failed to create output directory: ${output_dir}"
        return 1
      fi
    fi
  fi

  # Create temporary directory
  if [[ "${dry_run}" == 'true' ]]; then
    log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would create temporary directory"
    TEMP_DIR="/tmp/dry-run-temp"
  else
    TEMP_DIR="$(mktemp -d)"
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Created temporary directory: ${TEMP_DIR}"
  fi

  return 0
}

#######################################
# Process the input file
# Arguments:
#   Log level
#   Input file path
#   Output directory
#   Timeout seconds
#   Dry run flag (true/false)
# Returns:
#   0 on success, 1 on error
#######################################
process_file() {
  local log_level="$1"
  local input_file="$2"
  local output_dir="$3"
  local timeout="$4"
  local dry_run="$5"
  local output_file="${output_dir}/output.txt"

  log "${LOG_LEVEL_INFO}" "${log_level}" "Processing file: ${input_file}"

  local line_count
  line_count="$(wc -l < "${input_file}")"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "File contains ${line_count} lines"

  if [[ "${dry_run}" == 'true' ]]; then
    log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would process ${line_count} lines"
    log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would write output to: ${output_file}"
    return 0
  fi

  # Simulate processing with timeout
  local temp_output="${TEMP_DIR}/temp_output.txt"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Processing with timeout: ${timeout}s"
  if ! timeout "${timeout}" tr '[:lower:]' '[:upper:]' < "${input_file}" > "${temp_output}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Processing failed or timed out"
    return 1
  fi

  # Move to final output location
  if ! mv "${temp_output}" "${output_file}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Failed to write output file: ${output_file}"
    return 1
  fi

  log "${LOG_LEVEL_INFO}" "${log_level}" "Output written to: ${output_file}"
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

  log "${LOG_LEVEL_INFO}" "${log_level}" "Starting ${SCRIPT_NAME} v${VERSION}"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Script directory: ${SCRIPT_DIR}"

  # Parse command-line arguments
  local config
  config="$(parse_arguments "$@")"

  # Extract configuration values
  local output_dir timeout verbose debug_mode dry_run input_file
  while IFS='=' read -r key value; do
    case "${key}" in
      log_level) log_level="${value}" ;;
      output_dir) output_dir="${value}" ;;
      timeout) timeout="${value}" ;;
      verbose) verbose="${value}" ;;
      debug_mode) debug_mode="${value}" ;;
      dry_run) dry_run="${value}" ;;
      input_file) input_file="${value}" ;;
    esac
  done <<< "${config}"

  # Register cleanup with current log level
  trap "cleanup ${log_level}" EXIT

  # Validate prerequisites
  if ! validate_prerequisites "${log_level}" "${input_file}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Prerequisite validation failed"
    exit 1
  fi

  # Setup environment
  if ! setup_environment "${log_level}" "${output_dir}" "${dry_run}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Environment setup failed"
    exit 1
  fi

  # Process the file
  if ! process_file "${log_level}" "${input_file}" "${output_dir}" "${timeout}" "${dry_run}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "File processing failed"
    exit 1
  fi

  log "${LOG_LEVEL_INFO}" "${log_level}" "All operations completed successfully"
  return 0
}

main "$@"
