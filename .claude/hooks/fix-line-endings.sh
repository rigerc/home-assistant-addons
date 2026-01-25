#!/bin/bash
#
# Check for Windows line endings (CRLF) in a file and convert to Unix format (LF).

set -euo pipefail

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
# Check if file has CRLF line endings
# Arguments:
#   File path
# Returns:
#   0 if CRLF found, 1 if not
#######################################
has_crlf() {
  local file="$1"

  # Use file command to detect CRLF
  if file "${file}" | grep -q "CRLF"; then
    return 0
  fi

  # Alternative: check for carriage return with grep
  if grep -q $'\r' "${file}" 2>/dev/null; then
    return 0
  fi

  return 1
}

#######################################
# Convert CRLF to LF in a file
# Arguments:
#   File path
# Returns:
#   0 on success, 1 on error
#######################################
fix_line_endings() {
  local file="$1"

  if [[ ! -f "${file}" ]]; then
    err "File not found: ${file}"
    return 1
  fi

  if [[ ! -w "${file}" ]]; then
    err "Cannot write to file: ${file}"
    return 1
  fi

  # Create temp file
  local temp_file
  temp_file="$(mktemp)"

  # Remove carriage returns
  tr -d '\r' < "${file}" > "${temp_file}"

  # Replace original
  mv "${temp_file}" "${file}"

  return 0
}

#######################################
# Display usage information
#######################################
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] FILE

Check for Windows line endings (CRLF) in a file and fix them.

Options:
  -h          Show this help message
  -c          Check only (don't modify file)
  -v          Verbose output

Arguments:
  FILE        Path to file to check/fix

Exit codes:
  0           No CRLF found (or successfully fixed)
  1           Error occurred
  2           CRLF found (in check-only mode)

Examples:
  ${SCRIPT_NAME} script.sh
  ${SCRIPT_NAME} -c myfile.txt
  ${SCRIPT_NAME} -v data.csv
EOF
}

#######################################
# Main function
# Arguments:
#   Command line arguments
# Returns:
#   0 on success, 1 on error, 2 if CRLF found (check-only)
#######################################
main() {
  local check_only='false'
  local verbose='false'

  while getopts 'hcv' flag; do
    case "${flag}" in
      h) usage; exit 0 ;;
      c) check_only='true' ;;
      v) verbose='true' ;;
      *) usage >&2; exit 1 ;;
    esac
  done

  shift $((OPTIND - 1))

  if (( $# == 0 )); then
    err "Missing required FILE argument"
    usage >&2
    exit 1
  fi

  local file="$1"

  if [[ ! -f "${file}" ]]; then
    err "File not found: ${file}"
    exit 1
  fi

  if [[ ! -r "${file}" ]]; then
    err "Cannot read file: ${file}"
    exit 1
  fi

  if [[ "${verbose}" == 'true' ]]; then
    echo "Checking file: ${file}"
  fi

  if has_crlf "${file}"; then
    echo "CRLF line endings found in: ${file}"

    if [[ "${check_only}" == 'true' ]]; then
      exit 2
    fi

    if ! fix_line_endings "${file}"; then
      err "Failed to fix line endings"
      exit 1
    fi

    echo "Fixed: ${file}"
  else
    if [[ "${verbose}" == 'true' ]]; then
      echo "No CRLF line endings found"
    fi
  fi

  exit 0
}

main "$@"
