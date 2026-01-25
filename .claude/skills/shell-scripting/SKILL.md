---
name: shell-scripting
description: This skill should be used when the user asks to "write a bash script", "create a shell script", "write a deployment script", "help with shell scripting", "review this bash script", "fix shell script style", or mentions bash, shell, or scripting tasks. Provides comprehensive guidance based on the Google Shell Style Guide.
version: 0.1.0
---

# Shell Scripting Skill

Write production-ready shell scripts following the Google Shell Style Guide. This skill provides guidance on Bash scripting best practices, common patterns, error handling, and code organization.

## When to Use This Skill

Use this skill when:
- Writing new Bash scripts for automation, deployment, or utilities
- Reviewing existing shell scripts for style and correctness
- Fixing shell script issues or improving code quality
- Need guidance on shell scripting patterns and best practices
- Converting ad-hoc commands into reusable scripts

## Core Principles

### Use Bash, Not POSIX Shell

- All scripts must start with `#!/bin/bash`
- Use bash-specific features freely (arrays, `[[`, etc.)
- No need for POSIX compatibility unless explicitly required

### When Shell is Appropriate

Shell is suitable for:
- Small utilities and wrapper scripts
- Calling other utilities with minimal data manipulation
- Scripts under 100 lines
- Simple automation tasks

**Avoid shell for:**
- Scripts over 100 lines (consider Python, Go, etc.)
- Complex data structures or algorithms
- Performance-critical code
- Non-straightforward control flow

### Start Scripts Safely

Begin every script with:

```bash
#!/bin/bash
set -euo pipefail
```

- `-e`: Exit on error
- `-u`: Exit on undefined variable
- `-o pipefail`: Exit if any command in pipeline fails

## Script Structure

### Basic Template

```bash
#!/bin/bash
#
# Brief description of script purpose

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Error handling
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

# Main function for scripts with other functions
main() {
  # Script logic here
  echo "Hello, World!"
}

main "$@"
```

### File Organization

1. Shebang and file header comment
2. `set` options
3. Constants (readonly, UPPER_CASE)
4. Functions (with proper comments)
5. `main` function (if script has other functions)
6. Call to `main "$@"` at end

## Formatting Standards

### Indentation

- Use 2 spaces (no tabs)
- Exception: Here-documents with `<<-` may use tabs

### Line Length

- Maximum 80 characters
- Use here-documents or embedded newlines for long strings
- Factor long paths/URLs into variables

### Control Flow

```bash
# Put ; then and ; do on same line
if [[ condition ]]; then
  action
else
  alternative
fi

for item in "${items[@]}"; do
  process_item "${item}"
done

while [[ condition ]]; do
  action
done
```

### Case Statements

```bash
case "${var}" in
  pattern1)
    action1
    ;;
  pattern2)
    action2
    ;;
  *)
    default_action
    ;;
esac
```

### Pipelines

```bash
# Single line if it fits
command1 | command2

# Multi-line with \ continuation
command1 \
  | command2 \
  | command3 \
  | command4
```

## Naming Conventions

### Functions

- Lower-case with underscores: `process_file()`
- Use `::` for package names: `mylib::process_file()`
- Opening brace on same line as function name

### Variables

- Lower-case with underscores: `my_var`
- Loop variables match what they iterate: `for file in "${files[@]}"`

### Constants

- UPPER_CASE with underscores: `MAX_RETRIES`
- Declare with `readonly`
- Put at top of file after `set` options

### Local Variables

Always use `local` for function variables:

```bash
my_func() {
  local arg="$1"

  # Separate declaration and assignment for command substitution
  local result
  result="$(some_command)"
  (( $? == 0 )) || return 1
}
```

## Quoting and Variable Expansion

### Always Quote Variables

```bash
# Correct
echo "${var}"
if [[ "${my_var}" == "value" ]]; then

# Incorrect
echo $var
if [[ $my_var == "value" ]]; then
```

### Variable Expansion Style

- Prefer `"${var}"` over `"$var"`
- Don't brace single-char specials: `$1`, `$?`, `$#`
- Always use `"$@"` for argument arrays (not `$*`)

### Arrays

Use arrays for lists:

```bash
# Declare
declare -a files
files=("file1.txt" "file2.txt")

# Append
files+=("file3.txt")

# Iterate
for file in "${files[@]}"; do
  echo "${file}"
done

# Don't use strings for lists
# BAD: files="file1.txt file2.txt"
```

## Testing and Conditionals

### Use [[ ]] Not [ ]

```bash
# Correct
if [[ "${var}" == "value" ]]; then
if [[ -f "${file}" ]]; then
if [[ "${name}" =~ ^[a-z]+$ ]]; then

# Incorrect
if [ "${var}" = "value" ]; then
if test -f "${file}"; then
```

### String Tests

```bash
# Empty/non-empty (preferred)
if [[ -z "${var}" ]]; then  # empty
if [[ -n "${var}" ]]; then  # non-empty

# Equality
if [[ "${var}" == "value" ]]; then

# Pattern matching
if [[ "${file}" == *.txt ]]; then

# Regex
if [[ "${email}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}$ ]]; then
```

### Numeric Comparisons

```bash
# Use (( )) for arithmetic
if (( count > 10 )); then
if (( i >= 0 && i < max )); then

# Or use -lt, -gt, etc.
if [[ "${count}" -gt 10 ]]; then
```

## Error Handling

### Check Return Values

```bash
# Direct check
if ! mv "${src}" "${dst}"; then
  err "Move failed"
  exit 1
fi

# Check $?
command_name
if (( $? != 0 )); then
  err "Command failed"
  exit 1
fi
```

### Pipeline Status

```bash
command1 | command2 | command3
if (( PIPESTATUS[0] != 0 || PIPESTATUS[1] != 0 || PIPESTATUS[2] != 0 )); then
  err "Pipeline failed"
fi

# Or save immediately
tar -cf - ./* | ( cd "${dir}" && tar -xf - )
return_codes=( "${PIPESTATUS[@]}" )
if (( return_codes[0] != 0 )); then
  handle_tar_error
fi
```

### Cleanup on Exit

```bash
TEMP_DIR=''

cleanup() {
  if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
    rm -rf "${TEMP_DIR}"
  fi
}

trap cleanup EXIT
```

## Function Comments

Document non-obvious functions:

```bash
#######################################
# Backup database to compressed file
# Globals:
#   DB_NAME
#   BACKUP_DIR
# Arguments:
#   None
# Returns:
#   0 on success, 1 on error
#######################################
backup_database() {
  # Implementation
}
```

## Common Patterns

### Command Substitution

Use `$()` not backticks:

```bash
# Correct
result="$(command)"
nested="$(command1 "$(command2)")"

# Incorrect
result=`command`
```

### Process Substitution

Avoid subshell variable issues:

```bash
# BAD: count won't persist
count=0
cat file.txt | while read -r line; do
  (( count++ ))
done

# GOOD: Use process substitution
count=0
while read -r line; do
  (( count++ ))
done < <(cat file.txt)

# ALSO GOOD: Use readarray
readarray -t lines < file.txt
count="${#lines[@]}"
```

### Arithmetic

```bash
# Use (( )) or $(( ))
(( i += 1 ))
result="$(( a + b ))"

# Within (( )), no ${} needed
(( total = count * price ))

# Avoid expr, let, $[ ]
```

### Wildcards

Use explicit paths to avoid `-` prefix issues:

```bash
# Correct
for file in ./*; do
  rm "${file}"
done

# Incorrect (breaks if file starts with -)
for file in *; do
  rm "${file}"
done
```

## ShellCheck Integration

Run ShellCheck on all scripts:

```bash
# Using the provided wrapper
./scripts/shellcheck-wrapper.sh myscript.sh

# Or directly
shellcheck myscript.sh
```

Address all ShellCheck warnings unless there's a documented reason to ignore them.

## Additional Resources

### Reference Files

Detailed documentation in `references/`:
- **`references/template-usage.md`** - Complete guide for using the comprehensive script template
- **`references/style-guide.md`** - Complete Google Shell Style Guide
- **`references/common-patterns.md`** - Common patterns, recipes, and anti-patterns

### Example Scripts

Working examples in `examples/`:
- **`examples/basic-script.sh`** - Basic template with core conventions
- **`examples/template-with-args-debug-logging.sh`** - Comprehensive template with argument parsing, debug mode, and multi-level logging
- **`examples/backup-script.sh`** - Production backup script with logging and cleanup
- **`examples/deployment-script.sh`** - Advanced deployment with rollback capability

### Utility Scripts

Tools in `scripts/`:
- **`scripts/shellcheck-wrapper.sh`** - ShellCheck with style-guide settings

## Anti-Patterns to Avoid

**Don't:**
- Use `eval` (security risk, unpredictable)
- Parse `ls` output (use arrays/find instead)
- Use backticks (use `$()` instead)
- Use `[ ]` for tests (use `[[ ]]` instead)
- Use `cd` without checking result
- Iterate with `for file in $(ls)` (breaks on spaces)
- Mix functions and executable code (group functions together)
- Skip error checking on critical commands

## Implementation Workflow

To create a new shell script:

1. **Copy the comprehensive template**: `cp examples/template-with-args-debug-logging.sh my-script.sh`
   - This template provides argument parsing, debug mode, multi-level logging, and dry run capability
   - Use `examples/basic-script.sh` only if explicitly requested or for very simple scripts (under 50 lines)
2. **Make it executable**: `chmod +x my-script.sh`
3. **Customize the script**:
   - Update script metadata (description, version, defaults)
   - Modify argument parsing to support required options
   - Implement processing logic in function bodies
   - Update prerequisites validation for dependencies
   - Customize usage text and examples
4. **Follow core principles**:
   - Include `set -euo pipefail`
   - Define constants as uppercase readonly variables
   - Write functions with proper documentation
   - Check return values, handle errors
   - Use `trap cleanup EXIT` for temp files
   - Quote all variable expansions
   - Use arrays for lists
5. **Test thoroughly**:
   - Run ShellCheck: `shellcheck my-script.sh`
   - Test with `-h` (help), `-v` (verbose), `-d` (debug), `-n` (dry run)
   - Test error conditions (missing files, invalid arguments)
   - Verify cleanup runs on all exit paths

For detailed template usage, see **`references/template-usage.md`**

## Quick Checklist

Before finalizing a script:

- [ ] Starts with `#!/bin/bash` and `set -euo pipefail`
- [ ] All functions have proper comments (if non-obvious)
- [ ] Variables properly quoted: `"${var}"`
- [ ] Arrays used for lists, not strings
- [ ] `[[ ]]` used for tests, not `[ ]`
- [ ] Return values checked for critical commands
- [ ] Cleanup handler with `trap EXIT` (if needed)
- [ ] `main "$@"` at end (if script has functions)
- [ ] Constants in UPPER_CASE with readonly
- [ ] Local variables declared with `local`
- [ ] ShellCheck passes with no warnings
- [ ] Script is under 100 lines (or consider refactoring)

## Getting Help

For detailed style rules, patterns, and examples, consult the reference files and examples included with this skill. The Google Shell Style Guide is comprehensive and covers edge cases not included in this overview.

When in doubt about a pattern or convention, check:
1. This SKILL.md for common scenarios
2. `references/common-patterns.md` for specific recipes
3. `references/style-guide.md` for detailed rules
4. Example scripts for working implementations
