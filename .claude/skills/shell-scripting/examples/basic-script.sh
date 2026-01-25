#!/bin/bash
#
# Basic script template demonstrating Google Shell Style Guide conventions.
# This shows proper structure, error handling, and common patterns.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

#######################################
# Print error message to stderr
# Arguments:
#   Error message
#######################################
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Display usage information
#######################################
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] FILE

Process a file with various options.

Options:
  -h          Show this help message
  -v          Verbose output
  -o FILE     Output file (default: stdout)

Examples:
  ${SCRIPT_NAME} input.txt
  ${SCRIPT_NAME} -v -o output.txt input.txt
EOF
}

#######################################
# Process a single file
# Arguments:
#   Input file path
#   Output file path (optional)
# Returns:
#   0 on success, 1 on error
#######################################
process_file() {
  local input_file="$1"
  local output_file="${2:-}"

  if [[ ! -f "${input_file}" ]]; then
    err "Input file not found: ${input_file}"
    return 1
  fi

  if [[ ! -r "${input_file}" ]]; then
    err "Cannot read input file: ${input_file}"
    return 1
  fi

  local line_count
  line_count="$(wc -l < "${input_file}")"

  echo "Processing ${input_file} (${line_count} lines)"

  # Process the file
  local processed_content
  processed_content="$(tr '[:lower:]' '[:upper:]' < "${input_file}")"

  # Output to file or stdout
  if [[ -n "${output_file}" ]]; then
    echo "${processed_content}" > "${output_file}"
    echo "Output written to: ${output_file}"
  else
    echo "${processed_content}"
  fi

  return 0
}

#######################################
# Main function
# Arguments:
#   Command line arguments
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  local verbose='false'
  local output_file=''

  # Parse command-line options
  while getopts 'hvo:' flag; do
    case "${flag}" in
      h) usage; exit 0 ;;
      v) verbose='true' ;;
      o) output_file="${OPTARG}" ;;
      *) usage >&2; exit 1 ;;
    esac
  done

  shift $((OPTIND - 1))

  # Check for required arguments
  if (( $# == 0 )); then
    err "Missing required FILE argument"
    usage >&2
    exit 1
  fi

  local input_file="$1"

  if [[ "${verbose}" == 'true' ]]; then
    echo "Verbose mode enabled"
    echo "Input file: ${input_file}"
    if [[ -n "${output_file}" ]]; then
      echo "Output file: ${output_file}"
    fi
  fi

  # Process the file
  if ! process_file "${input_file}" "${output_file}"; then
    err "Failed to process file"
    exit 1
  fi

  return 0
}

main "$@"
