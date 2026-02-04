# Shell Script Template Usage Guide

This guide explains how to use the comprehensive shell script template (`examples/template-with-args-debug-logging.sh`) to create production-ready shell scripts with argument parsing, debugging, and logging.

## Template Overview

The template provides a complete foundation for production shell scripts with:

- **Argument parsing**: Full `getopts` implementation supporting flags, options, and positional arguments
- **Debug mode**: Bash tracing with `set -x` enabled via `-d` flag
- **Multi-level logging**: ERROR (1), WARN (2), INFO (3), DEBUG (4) with colored terminal output
- **Dry run mode**: Preview operations with `-n` flag without executing them
- **Error handling**: Comprehensive validation and error reporting
- **Automatic cleanup**: Cleanup handlers for temporary resources
- **Functional design**: Minimal global variables, configuration passed as arguments

## When to Use This Template

Use this template for:

- **Production scripts**: Scripts deployed to production environments
- **Complex automation**: Multi-step workflows requiring debugging
- **Scripts requiring logging**: When detailed operation logs are needed
- **Scripts with multiple options**: Scripts accepting various command-line arguments
- **Team collaboration**: Scripts maintained by multiple developers
- **Scripts needing testing**: When dry-run capability aids development

For simpler scripts (under 100 lines, few arguments), consider `examples/basic-script.sh` instead.

## Using the Template

### Step 1: Copy the Template

```bash
cp examples/template-with-args-debug-logging.sh my-script.sh
chmod +x my-script.sh
```

### Step 2: Update Script Metadata

Edit the header and constants:

```bash
#!/bin/bash
#
# Brief description of what your script does.
# Include key functionality and usage scenarios.

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly VERSION="1.0.0"  # Update version

# Update default configuration for your script
readonly DEFAULT_LOG_LEVEL="${LOG_LEVEL_INFO}"
readonly DEFAULT_OUTPUT_DIR="/tmp/output"  # Change as needed
readonly DEFAULT_TIMEOUT=30  # Change as needed
```

### Step 3: Customize Argument Parsing

Modify the `parse_arguments()` function to support your script's options.

**Add new options:**

```bash
# Add to getopts string
while getopts 'hVvdno:t:l:f:m:' opt; do  # Added f: and m:
  case "${opt}" in
    # ... existing cases ...
    f)
      format="${OPTARG}"
      log "${LOG_LEVEL_DEBUG}" "${log_level}" "Format set to: ${format}"
      ;;
    m)
      if ! [[ "${OPTARG}" =~ ^(json|xml|csv)$ ]]; then
        log "${LOG_LEVEL_ERROR}" "${log_level}" "Invalid mode: ${OPTARG}"
        usage >&2
        exit 2
      fi
      mode="${OPTARG}"
      log "${LOG_LEVEL_DEBUG}" "${log_level}" "Mode set to: ${mode}"
      ;;
    # ... rest of cases ...
  esac
done
```

**Update configuration output:**

```bash
# Output configuration (at end of parse_arguments)
echo "log_level=${log_level}"
echo "output_dir=${output_dir}"
echo "timeout=${timeout}"
echo "format=${format}"      # Add new options
echo "mode=${mode}"          # Add new options
echo "input_file=${input_file}"
```

**Update usage text:**

```bash
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] INPUT_FILE

Brief description of your script.

OPTIONS:
  -h              Show this help message and exit
  -V              Show version and exit
  -v              Verbose mode (enables INFO and DEBUG logs)
  -d              Debug mode (enables bash tracing with set -x)
  -n              Dry run (show what would be done)
  -o DIR          Output directory (default: ${DEFAULT_OUTPUT_DIR})
  -t SECONDS      Timeout in seconds (default: ${DEFAULT_TIMEOUT})
  -l LEVEL        Log level: error(1), warn(2), info(3), debug(4)
  -f FORMAT       Output format                    # Add your options
  -m MODE         Processing mode (json|xml|csv)    # Add your options

EXAMPLES:
  # Add relevant examples for your script
  ${SCRIPT_NAME} input.txt
  ${SCRIPT_NAME} -v -f json input.txt
  ${SCRIPT_NAME} -n -m xml input.txt

EXIT CODES:
  0   Success
  1   General error
  2   Invalid arguments
  3   File not found or not readable
  # Add script-specific exit codes

EOF
}
```

### Step 4: Extract Configuration in Main

Update the `main()` function to extract your new configuration values:

```bash
main() {
  local log_level="${DEFAULT_LOG_LEVEL}"

  log "${LOG_LEVEL_INFO}" "${log_level}" "Starting ${SCRIPT_NAME} v${VERSION}"

  # Parse command-line arguments
  local config
  config="$(parse_arguments "$@")"

  # Extract configuration values
  local output_dir timeout verbose debug_mode dry_run input_file
  local format mode  # Add your new variables

  while IFS='=' read -r key value; do
    case "${key}" in
      log_level) log_level="${value}" ;;
      output_dir) output_dir="${value}" ;;
      timeout) timeout="${value}" ;;
      format) format="${value}" ;;      # Add new options
      mode) mode="${value}" ;;          # Add new options
      input_file) input_file="${value}" ;;
    esac
  done <<< "${config}"

  # ... rest of main function
}
```

### Step 5: Implement Your Script Logic

Replace the `process_file()` function with your actual processing logic:

```bash
#######################################
# Process the input file
# Arguments:
#   Log level
#   Input file path
#   Output directory
#   Timeout seconds
#   Dry run flag (true/false)
#   ... add your custom arguments
# Returns:
#   0 on success, 1 on error
#######################################
process_file() {
  local log_level="$1"
  local input_file="$2"
  local output_dir="$3"
  local timeout="$4"
  local dry_run="$5"
  # Extract additional arguments as needed

  log "${LOG_LEVEL_INFO}" "${log_level}" "Processing file: ${input_file}"

  # Add your validation
  local line_count
  line_count="$(wc -l < "${input_file}")"
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "File contains ${line_count} lines"

  if [[ "${dry_run}" == 'true' ]]; then
    log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would process ${line_count} lines"
    # Show what would happen
    return 0
  fi

  # Implement your actual processing logic here
  # Use temporary files from ${TEMP_DIR}
  local temp_output="${TEMP_DIR}/temp_output.txt"

  # Example: process with timeout
  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Processing with timeout: ${timeout}s"
  if ! timeout "${timeout}" your_command < "${input_file}" > "${temp_output}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Processing failed or timed out"
    return 1
  fi

  # Move to final output location
  local output_file="${output_dir}/output.txt"
  if ! mv "${temp_output}" "${output_file}"; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Failed to write output file: ${output_file}"
    return 1
  fi

  log "${LOG_LEVEL_INFO}" "${log_level}" "Output written to: ${output_file}"
  return 0
}
```

### Step 6: Update Prerequisites

Modify `validate_prerequisites()` to check for your script's requirements:

```bash
validate_prerequisites() {
  local log_level="$1"
  local input_file="$2"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Validating prerequisites"

  # Check required commands
  local cmd
  local missing=()

  # Update this list for your script's dependencies
  for cmd in jq curl python3; do  # Changed from awk, sed, grep
    if ! command -v "${cmd}" &>/dev/null; then
      missing+=("${cmd}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Missing required commands: ${missing[*]}"
    return 1
  fi

  # Add custom validation
  if [[ -n "${CONFIG_FILE:-}" && ! -f "${CONFIG_FILE}" ]]; then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Config file not found: ${CONFIG_FILE}"
    return 1
  fi

  # Standard input file validation
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
```

### Step 7: Test Your Script

```bash
# Test help
./my-script.sh -h

# Test with verbose logging
./my-script.sh -v input.txt

# Test dry run mode
./my-script.sh -n input.txt

# Test debug mode (bash tracing)
./my-script.sh -d input.txt

# Test error handling
./my-script.sh nonexistent.txt  # Should show error

# Test custom options
./my-script.sh -o /tmp/custom -t 60 input.txt
```

## Template Features Explained

### Logging System

The template uses a functional logging approach without global log level variables:

```bash
# Log levels are passed as arguments
log "${LOG_LEVEL_INFO}" "${log_level}" "Message"

# Where:
# - First argument: Message level (ERROR, WARN, INFO, DEBUG)
# - Second argument: Current log level threshold
# - Remaining arguments: Message text

# Color output automatically disabled when not writing to terminal
```

**Benefits:**
- No global log level variable
- Functions receive log level as parameter
- Thread-safe (if using background jobs)
- Easy to test different log levels

**Usage in your functions:**

```bash
my_function() {
  local log_level="$1"  # Receive log level as parameter

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Starting operation"

  # Do work...

  if (( error )); then
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Operation failed"
    return 1
  fi

  log "${LOG_LEVEL_INFO}" "${log_level}" "Operation completed"
  return 0
}
```

### Debug Mode

The `-d` flag enables bash tracing (`set -x`), showing each command as it executes:

```bash
# Without -d
$ ./my-script.sh input.txt
[2026-01-24 10:00:00] [INFO ] Processing file: input.txt

# With -d (shows every command)
$ ./my-script.sh -d input.txt
++ log 4 4 'Debug mode enabled (bash tracing active)'
++ local level=4
++ local current_level=4
++ shift 2
[2026-01-24 10:00:00] [DEBUG] Debug mode enabled (bash tracing active)
```

**Use debug mode to:**
- Troubleshoot script execution flow
- See exact commands being run
- Verify variable expansions
- Diagnose pipeline issues

### Dry Run Mode

The `-n` flag previews operations without executing them:

```bash
if [[ "${dry_run}" == 'true' ]]; then
  log "${LOG_LEVEL_INFO}" "${log_level}" "[DRY RUN] Would execute: command"
  return 0
fi

# Actually execute
command
```

**Use dry run to:**
- Test script logic safely
- Preview file operations
- Verify configuration before execution
- Document script behavior

### Cleanup Handler

The template uses `trap` to ensure cleanup runs on exit:

```bash
# Register cleanup with current log level
trap "cleanup ${log_level}" EXIT

cleanup() {
  local exit_code=$?
  local log_level="${1:-${DEFAULT_LOG_LEVEL}}"

  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    log "${LOG_LEVEL_DEBUG}" "${log_level}" "Cleaning up: ${TEMP_DIR}"
    rm -rf "${TEMP_DIR}"
  fi

  if (( exit_code == 0 )); then
    log "${LOG_LEVEL_INFO}" "${log_level}" "Script completed successfully"
  else
    log "${LOG_LEVEL_ERROR}" "${log_level}" "Script failed with exit code: ${exit_code}"
  fi
}
```

**Benefits:**
- Temporary files always cleaned up
- Final status logged on every exit
- Exit code preserved
- Log level context maintained

### Configuration Passing Pattern

The template avoids global variables by using a key=value output pattern:

```bash
# parse_arguments outputs configuration
parse_arguments() {
  # ... parse options ...

  # Output as key=value pairs
  echo "log_level=${log_level}"
  echo "output_dir=${output_dir}"
  echo "input_file=${input_file}"
}

# main() extracts configuration
main() {
  local config
  config="$(parse_arguments "$@")"

  local log_level output_dir input_file
  while IFS='=' read -r key value; do
    case "${key}" in
      log_level) log_level="${value}" ;;
      output_dir) output_dir="${value}" ;;
      input_file) input_file="${value}" ;;
    esac
  done <<< "${config}"

  # Pass to functions as needed
  process_file "${log_level}" "${input_file}" "${output_dir}"
}
```

**Benefits:**
- No global configuration variables
- Clear data flow
- Functions receive only what they need
- Easy to test functions in isolation

## Common Customizations

### Adding Boolean Flags

```bash
# In parse_arguments()
local compress='false'

while getopts 'hVvdnc' opt; do  # Added 'c'
  case "${opt}" in
    # ... existing cases ...
    c)
      compress='true'
      log "${LOG_LEVEL_DEBUG}" "${log_level}" "Compression enabled"
      ;;
  esac
done

# Output configuration
echo "compress=${compress}"
```

### Adding Optional Arguments

```bash
# In parse_arguments()
local config_file=''

while getopts 'hVvdnc:' opt; do  # c: requires argument
  case "${opt}" in
    c)
      config_file="${OPTARG}"
      if [[ ! -f "${config_file}" ]]; then
        log "${LOG_LEVEL_ERROR}" "${log_level}" "Config file not found: ${config_file}"
        exit 2
      fi
      log "${LOG_LEVEL_DEBUG}" "${log_level}" "Using config: ${config_file}"
      ;;
  esac
done

echo "config_file=${config_file}"
```

### Adding Multiple Positional Arguments

```bash
# After getopts processing
shift $((OPTIND - 1))

if (( $# < 2 )); then
  log "${LOG_LEVEL_ERROR}" "${log_level}" "Missing required arguments: INPUT_FILE OUTPUT_FILE"
  usage >&2
  exit 2
fi

readonly INPUT_FILE="$1"
readonly OUTPUT_FILE="$2"

echo "input_file=${INPUT_FILE}"
echo "output_file=${OUTPUT_FILE}"
```

### Adding Additional Functions

```bash
#######################################
# Your custom function
# Arguments:
#   Log level
#   Custom arguments...
# Returns:
#   0 on success, 1 on error
#######################################
my_custom_function() {
  local log_level="$1"
  local arg1="$2"

  log "${LOG_LEVEL_DEBUG}" "${log_level}" "Custom function called with: ${arg1}"

  # Your logic here

  return 0
}

# Call from main or other functions
if ! my_custom_function "${log_level}" "${value}"; then
  log "${LOG_LEVEL_ERROR}" "${log_level}" "Custom function failed"
  exit 1
fi
```

## Testing Your Script

### Unit Testing Functions

Functions can be tested in isolation because they don't rely on globals:

```bash
# test_my_script.sh
source ./my-script.sh

# Test with different log levels
result=$(process_file "${LOG_LEVEL_DEBUG}" "test.txt" "/tmp" "30" "true")
echo "Dry run result: $?"

# Test error handling
result=$(validate_prerequisites "${LOG_LEVEL_INFO}" "nonexistent.txt")
echo "Expected error: $?"
```

### Integration Testing

```bash
#!/bin/bash
# integration_test.sh

set -euo pipefail

# Setup
echo "test data" > /tmp/test_input.txt

# Test normal execution
./my-script.sh /tmp/test_input.txt
if (( $? != 0 )); then
  echo "FAIL: Normal execution failed"
  exit 1
fi

# Test dry run
./my-script.sh -n /tmp/test_input.txt
if (( $? != 0 )); then
  echo "FAIL: Dry run failed"
  exit 1
fi

# Test error handling
./my-script.sh /tmp/nonexistent.txt 2>&1 | grep -q "not found"
if (( $? != 0 )); then
  echo "FAIL: Error handling failed"
  exit 1
fi

echo "All tests passed"
```

## Best Practices

### Do:
- Keep default values in readonly constants
- Pass log level to all functions that log
- Use dry run for destructive operations
- Validate all input early
- Use descriptive variable names
- Add function documentation
- Test with various argument combinations
- Use ShellCheck for validation

### Don't:
- Add unnecessary global variables
- Skip error checking
- Hardcode values that could be arguments
- Mix configuration and processing logic
- Forget to update usage text when adding options
- Skip cleanup handler registration
- Assume commands exist without checking

## Troubleshooting

### Common Issues

**Issue:** Script fails with "unbound variable" error

**Solution:** Check that all variables are initialized before use. The template uses `set -u` which treats unset variables as errors.

```bash
# Wrong
echo "${MY_VAR}"  # Fails if MY_VAR not set

# Right
echo "${MY_VAR:-default}"  # Uses default if not set
local my_var="${MY_VAR:-}"  # Initialize to empty string
```

**Issue:** Log messages not appearing

**Solution:** Check log level threshold. Messages only appear if their level is <= current log level.

```bash
# DEBUG messages won't show at INFO level (3)
log "${LOG_LEVEL_DEBUG}" "3" "Hidden message"

# Use -v or -l 4 to see DEBUG messages
./my-script.sh -v input.txt
./my-script.sh -l 4 input.txt
```

**Issue:** Cleanup not running

**Solution:** Ensure trap is registered after log_level is available:

```bash
main() {
  # ... parse arguments first ...

  # Register cleanup AFTER log_level is set
  trap "cleanup ${log_level}" EXIT
}
```

## Advanced Usage

### Using with Cron

When running from cron, redirect output appropriately:

```bash
# crontab entry
0 2 * * * /path/to/my-script.sh -l 3 input.txt >> /var/log/my-script.log 2>&1
```

### Background Execution

For long-running scripts:

```bash
# Start in background with logging
nohup ./my-script.sh -v input.txt > output.log 2>&1 &

# Get process ID
SCRIPT_PID=$!

# Monitor progress
tail -f output.log
```

### Integration with Other Tools

```bash
# Use with find
find /data -name "*.txt" -exec ./my-script.sh {} \;

# Use in pipeline
cat files.txt | while read -r file; do
  ./my-script.sh "${file}" || echo "Failed: ${file}"
done

# Use with parallel
parallel ./my-script.sh ::: file1.txt file2.txt file3.txt
```

## Summary

The comprehensive template provides a solid foundation for production shell scripts. Key features:

1. **Flexible argument parsing** - Supports flags, options, positional arguments
2. **Multi-level logging** - ERROR, WARN, INFO, DEBUG with colors
3. **Debug mode** - Bash tracing for troubleshooting
4. **Dry run mode** - Safe operation preview
5. **Automatic cleanup** - Resource cleanup on any exit
6. **Functional design** - Minimal globals, clear data flow
7. **Error handling** - Comprehensive validation and reporting

Customize by:
1. Updating metadata and defaults
2. Adding/modifying argument parsing
3. Implementing your processing logic
4. Updating prerequisites validation
5. Testing thoroughly

The template is designed to scale from simple scripts to complex production automation while maintaining clarity and maintainability.
