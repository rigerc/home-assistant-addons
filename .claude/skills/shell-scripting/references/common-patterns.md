# Common Shell Script Patterns

This reference provides common patterns and recipes for shell scripting following the Google Shell Style Guide.

## Script Template

Basic structure for a well-formed shell script:

```bash
#!/bin/bash
#
# Brief description of what this script does.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/var/log/myscript.log"

# Error handling function
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Main function description
# Globals:
#   SCRIPT_DIR
#   LOG_FILE
# Arguments:
#   Command line arguments
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  local arg
  for arg in "$@"; do
    echo "Processing: ${arg}"
  done
}

main "$@"
```

## Common Patterns

### Safe Set Options

Always start scripts with these set options for safety:

```bash
set -euo pipefail
# -e: Exit on error
# -u: Exit on undefined variable
# -o pipefail: Exit on pipe failure
```

### Finding Script Directory

Reliably determine where the script is located:

```bash
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
```

### Error Messages to STDERR

All error messages should go to STDERR:

```bash
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

if ! do_something; then
  err "Unable to do_something"
  exit 1
fi
```

### Checking Prerequisites

Check for required commands at script start:

```bash
check_prerequisites() {
  local cmd
  local missing=()

  for cmd in jq curl git; do
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    err "Missing required commands: ${missing[*]}"
    exit 1
  fi
}
```

### Command-line Argument Parsing

Using getopts for option parsing:

```bash
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] FILE

Options:
  -h          Show this help message
  -v          Verbose output
  -o FILE     Output file
  -n NUM      Number of retries
EOF
}

parse_args() {
  local verbose='false'
  local output_file=''
  local num_retries=3

  while getopts 'hvo:n:' flag; do
    case "${flag}" in
      h) usage; exit 0 ;;
      v) verbose='true' ;;
      o) output_file="${OPTARG}" ;;
      n) num_retries="${OPTARG}" ;;
      *) usage >&2; exit 1 ;;
    esac
  done

  shift $((OPTIND - 1))

  if (( $# == 0 )); then
    err "Missing required FILE argument"
    usage >&2
    exit 1
  fi

  # Export parsed values for use in other functions
  readonly VERBOSE="${verbose}"
  readonly OUTPUT_FILE="${output_file}"
  readonly NUM_RETRIES="${num_retries}"
  readonly INPUT_FILE="$1"
}
```

### Temporary Files and Cleanup

Safe temporary file handling with cleanup:

```bash
# Global variable for temp dir
TEMP_DIR=''

cleanup() {
  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi
}

# Register cleanup to run on exit
trap cleanup EXIT

setup_temp_dir() {
  TEMP_DIR="$(mktemp -d)"
  readonly TEMP_DIR
}
```

### Retry Logic

Retry a command with exponential backoff:

```bash
#######################################
# Retry a command with exponential backoff
# Arguments:
#   Command and arguments to retry
# Returns:
#   0 if command succeeds, 1 if all retries fail
#######################################
retry() {
  local max_attempts=5
  local delay=1
  local attempt=1

  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi

    err "Attempt ${attempt}/${max_attempts} failed. Retrying in ${delay}s..."
    sleep "${delay}"
    (( delay *= 2 ))
    (( attempt++ ))
  done

  err "Command failed after ${max_attempts} attempts: $*"
  return 1
}

# Usage:
retry curl -f https://example.com/api
```

### Safe File Processing

Process files safely with proper error handling:

```bash
process_files() {
  local file
  local -a files=()

  # Use process substitution to avoid subshell
  while IFS= read -r -d '' file; do
    files+=("${file}")
  done < <(find /path/to/dir -name "*.txt" -print0)

  if (( ${#files[@]} == 0 )); then
    err "No files found"
    return 1
  fi

  for file in "${files[@]}"; do
    if [[ ! -r "${file}" ]]; then
      err "Cannot read file: ${file}"
      continue
    fi

    process_single_file "${file}"
  done
}
```

### Reading Configuration Files

Parse simple key=value config files:

```bash
#######################################
# Load configuration from a file
# Arguments:
#   Path to config file
# Returns:
#   0 on success, 1 on error
#######################################
load_config() {
  local config_file="$1"

  if [[ ! -f "${config_file}" ]]; then
    err "Config file not found: ${config_file}"
    return 1
  fi

  # Source the config file safely
  # shellcheck source=/dev/null
  if ! source "${config_file}"; then
    err "Failed to load config: ${config_file}"
    return 1
  fi

  # Validate required variables
  if [[ -z "${DB_HOST:-}" || -z "${DB_NAME:-}" ]]; then
    err "Missing required config variables"
    return 1
  fi
}
```

### Locking for Single Instance

Ensure only one instance of script runs:

```bash
readonly LOCK_FILE="/var/lock/myscript.lock"

acquire_lock() {
  local lock_fd=200

  eval "exec ${lock_fd}>${LOCK_FILE}"

  if ! flock -n "${lock_fd}"; then
    err "Another instance is already running"
    exit 1
  fi
}

# Call at script start
acquire_lock
```

### Logging

Implement simple logging:

```bash
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default log level
LOG_LEVEL="${LOG_LEVEL_INFO}"

log() {
  local level="$1"
  shift
  local message="$*"

  if (( level <= LOG_LEVEL )); then
    local level_name
    case "${level}" in
      "${LOG_LEVEL_ERROR}") level_name="ERROR" ;;
      "${LOG_LEVEL_WARN}")  level_name="WARN"  ;;
      "${LOG_LEVEL_INFO}")  level_name="INFO"  ;;
      "${LOG_LEVEL_DEBUG}") level_name="DEBUG" ;;
    esac

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level_name}] ${message}" >&2
  fi
}

log_error() { log "${LOG_LEVEL_ERROR}" "$@"; }
log_warn()  { log "${LOG_LEVEL_WARN}"  "$@"; }
log_info()  { log "${LOG_LEVEL_INFO}"  "$@"; }
log_debug() { log "${LOG_LEVEL_DEBUG}" "$@"; }
```

### Checking User Permissions

Verify script runs as correct user:

```bash
check_not_root() {
  if (( EUID == 0 )); then
    err "This script should not be run as root"
    exit 1
  fi
}

check_is_root() {
  if (( EUID != 0 )); then
    err "This script must be run as root"
    exit 1
  fi
}
```

### String Manipulation

Common string operations using bash built-ins:

```bash
# Remove prefix
string="prefix-value"
echo "${string#prefix-}"  # Output: value

# Remove suffix
string="value.txt"
echo "${string%.txt}"  # Output: value

# Replace first occurrence
string="foo bar foo"
echo "${string/foo/baz}"  # Output: baz bar foo

# Replace all occurrences
echo "${string//foo/baz}"  # Output: baz bar baz

# Uppercase/lowercase
string="Hello World"
echo "${string^^}"  # Output: HELLO WORLD
echo "${string,,}"  # Output: hello world

# Substring extraction
string="Hello World"
echo "${string:0:5}"  # Output: Hello
```

### Array Operations

Working with arrays:

```bash
# Declare and populate array
declare -a files
files=("file1.txt" "file2.txt" "file3.txt")

# Append to array
files+=("file4.txt")

# Iterate over array
for file in "${files[@]}"; do
  echo "Processing: ${file}"
done

# Array length
echo "Number of files: ${#files[@]}"

# Check if element exists
if [[ " ${files[*]} " =~ " file2.txt " ]]; then
  echo "file2.txt is in the array"
fi

# Slice array
echo "${files[@]:1:2}"  # Elements 1 and 2
```

### Associative Arrays (bash 4+)

Using hash maps:

```bash
declare -A config
config[host]="localhost"
config[port]="5432"
config[database]="mydb"

# Access values
echo "Host: ${config[host]}"

# Iterate over keys
for key in "${!config[@]}"; do
  echo "${key}: ${config[${key}]}"
done

# Check if key exists
if [[ -v config[host] ]]; then
  echo "host is configured"
fi
```

### Process Substitution

Avoid subshell issues with pipes:

```bash
# BAD: Variables modified in while loop won't persist
count=0
cat file.txt | while read -r line; do
  (( count++ ))
done
echo "${count}"  # Will be 0!

# GOOD: Use process substitution
count=0
while read -r line; do
  (( count++ ))
done < <(cat file.txt)
echo "${count}"  # Correct count

# ALSO GOOD: Use readarray
readarray -t lines < file.txt
count="${#lines[@]}"
```

### Safe Remote Command Execution

Execute commands on remote hosts safely:

```bash
#######################################
# Execute command on remote host via SSH
# Arguments:
#   Host
#   Command to execute
# Returns:
#   Exit code from remote command
#######################################
remote_exec() {
  local host="$1"
  shift
  local cmd="$*"

  ssh -o StrictHostKeyChecking=yes \
      -o ConnectTimeout=10 \
      "${host}" \
      "${cmd}"
}
```

### Parallel Execution

Run commands in parallel with limits:

```bash
#######################################
# Run function in parallel with max concurrent jobs
# Globals:
#   MAX_PARALLEL_JOBS
# Arguments:
#   Array of items to process
#######################################
parallel_process() {
  local -a items=("$@")
  local max_jobs="${MAX_PARALLEL_JOBS:-4}"
  local item

  for item in "${items[@]}"; do
    # Wait if we have too many background jobs
    while (( $(jobs -r | wc -l) >= max_jobs )); do
      sleep 0.1
    done

    process_item "${item}" &
  done

  # Wait for all background jobs to complete
  wait
}
```

### Input Validation

Validate user input:

```bash
validate_number() {
  local input="$1"

  if ! [[ "${input}" =~ ^[0-9]+$ ]]; then
    err "Invalid number: ${input}"
    return 1
  fi
}

validate_email() {
  local email="$1"

  if ! [[ "${email}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
    err "Invalid email: ${email}"
    return 1
  fi
}

validate_path() {
  local path="$1"

  if [[ ! -e "${path}" ]]; then
    err "Path does not exist: ${path}"
    return 1
  fi
}
```

### Colors in Output

Add colored output for better readability:

```bash
# Check if output is to a terminal
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly NC='\033[0m'  # No Color
else
  readonly RED=''
  readonly GREEN=''
  readonly YELLOW=''
  readonly NC=''
fi

print_error() {
  echo -e "${RED}ERROR: $*${NC}" >&2
}

print_success() {
  echo -e "${GREEN}SUCCESS: $*${NC}"
}

print_warning() {
  echo -e "${YELLOW}WARNING: $*${NC}" >&2
}
```

### Progress Indication

Show progress for long-running operations:

```bash
#######################################
# Show progress bar
# Arguments:
#   Current count
#   Total count
#######################################
show_progress() {
  local current="$1"
  local total="$2"
  local width=50

  local percent=$(( current * 100 / total ))
  local filled=$(( width * current / total ))
  local empty=$(( width - filled ))

  printf '\r['
  printf '%*s' "${filled}" '' | tr ' ' '#'
  printf '%*s' "${empty}" ''
  printf '] %3d%%' "${percent}"
}

# Usage:
total=100
for i in $(seq 1 "${total}"); do
  show_progress "${i}" "${total}"
  sleep 0.1
done
echo  # New line after progress bar
```

## Anti-Patterns to Avoid

### Don't Use `eval`

```bash
# BAD: eval is dangerous and hard to predict
eval $(get_config)

# GOOD: Use read or source
source <(get_config)
```

### Don't Use `cd` Without Error Handling

```bash
# BAD: If cd fails, following commands run in wrong directory
cd /some/path
rm -rf ./*

# GOOD: Check cd result or use subshell
cd /some/path || exit 1
rm -rf ./*

# ALSO GOOD: Use subshell
(cd /some/path && rm -rf ./*)
```

### Don't Use Backticks

```bash
# BAD: Backticks are hard to nest
output=`command1 \`command2\``

# GOOD: Use $() syntax
output="$(command1 "$(command2)")"
```

### Don't Use `[ ]` for Tests

```bash
# BAD: Old test syntax, prone to errors
if [ "$var" = "value" ]; then

# GOOD: Use [[ ]] for tests
if [[ "${var}" == "value" ]]; then
```

### Don't Use `ls` for Iteration

```bash
# BAD: Breaks on filenames with spaces
for file in $(ls *.txt); do

# GOOD: Use globbing
for file in *.txt; do
```

### Don't Parse `ls` Output

```bash
# BAD: ls output is for humans, not scripts
files=$(ls -l | awk '{print $9}')

# GOOD: Use find or globbing
readarray -t files < <(find . -maxdepth 1 -name "*.txt")
```
