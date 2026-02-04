#!/bin/bash
#
# ShellCheck wrapper with recommended settings for Google Shell Style Guide.
# Runs shellcheck with style-guide-compliant options.

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

#######################################
# Print usage information
#######################################
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] FILE...

Run ShellCheck with Google Shell Style Guide recommended settings.

Options:
  -h          Show this help message
  -s SHELL    Specify shell dialect (default: bash)
  -e CODES    Exclude specific error codes (comma-separated)
  -f FORMAT   Output format (default: tty)

Formats:
  tty         Terminal output with colors
  gcc         GCC-style output
  json        JSON output
  checkstyle  Checkstyle XML output

Examples:
  ${SCRIPT_NAME} myscript.sh
  ${SCRIPT_NAME} -f gcc *.sh
  ${SCRIPT_NAME} -e SC2086,SC2181 script.sh

EOF
}

#######################################
# Check if shellcheck is installed
# Returns:
#   0 if installed, 1 otherwise
#######################################
check_shellcheck() {
  if ! command -v shellcheck &>/dev/null; then
    echo "ERROR: shellcheck is not installed" >&2
    echo "Install with: sudo apt-get install shellcheck" >&2
    echo "Or visit: https://www.shellcheck.net/" >&2
    return 1
  fi
  return 0
}

#######################################
# Main function
# Arguments:
#   Command line arguments
# Returns:
#   Exit code from shellcheck
#######################################
main() {
  local shell='bash'
  local exclude_codes=''
  local output_format='tty'
  local -a files=()

  # Parse command-line options
  while getopts 'hs:e:f:' flag; do
    case "${flag}" in
      h) usage; exit 0 ;;
      s) shell="${OPTARG}" ;;
      e) exclude_codes="${OPTARG}" ;;
      f) output_format="${OPTARG}" ;;
      *) usage >&2; exit 1 ;;
    esac
  done

  shift $((OPTIND - 1))

  # Remaining arguments are files
  files=("$@")

  if (( ${#files[@]} == 0 )); then
    echo "ERROR: No files specified" >&2
    usage >&2
    exit 1
  fi

  # Check if shellcheck is available
  if ! check_shellcheck; then
    exit 1
  fi

  # Build shellcheck command
  local -a shellcheck_args=(
    --shell="${shell}"
    --format="${output_format}"
    --severity=style
    --color=auto
  )

  # Add exclusions if specified
  if [[ -n "${exclude_codes}" ]]; then
    shellcheck_args+=(--exclude="${exclude_codes}")
  fi

  # Common exclusions for Google Shell Style Guide compatibility:
  # SC2034 - Unused variables (sometimes intentional for documentation)
  # SC2086 - Double quote to prevent globbing (we use arrays)
  # SC2155 - Declare and assign separately (style preference)
  #
  # Uncomment to enable these exclusions:
  # shellcheck_args+=(--exclude=SC2034,SC2086,SC2155)

  # Add files
  shellcheck_args+=("${files[@]}")

  # Run shellcheck
  shellcheck "${shellcheck_args[@]}"
  local exit_code=$?

  if (( exit_code == 0 )); then
    echo "✓ All checks passed!" >&2
  fi

  return "${exit_code}"
}

main "$@"
