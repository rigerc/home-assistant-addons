# Debugging and Troubleshooting Guide

## Overview

Debugging GitHub Actions workflows requires systematic investigation of logs, configurations, and execution environments. This guide provides techniques and strategies to identify and resolve common workflow issues.

## Enabling Debug Logging

### Step Debug Logging

Enable detailed step-level logging to see additional debug output for each workflow step.

Create a repository secret named `ACTIONS_STEP_DEBUG` with value `true`:

```bash
# Using GitHub CLI
gh secret set ACTIONS_STEP_DEBUG --body "true"
```

Or via web interface:
1. Navigate to repository Settings
2. Select Secrets and variables > Actions
3. Click New repository secret
4. Name: `ACTIONS_STEP_DEBUG`
5. Value: `true`

Step debug logging reveals:
- Environment variables available to steps
- Step execution context
- Internal step processing details

### Runner Debug Logging

Enable detailed runner-level logging to diagnose runner infrastructure issues.

Create a repository secret named `ACTIONS_RUNNER_DEBUG` with value `true`:

```bash
gh secret set ACTIONS_RUNNER_DEBUG --body "true"
```

Runner debug logging shows:
- Runner job assignment process
- File download operations
- Runner preparation steps
- Job cleanup operations

### Viewing Debug Logs

After enabling debug logging, re-run the workflow. Debug output appears in log viewer:

1. Navigate to Actions tab
2. Select the workflow run
3. Expand job and step logs
4. Debug entries appear with "[debug]" prefix

Example debug output:

```
##[debug]Evaluating condition for step: 'Build application'
##[debug]Evaluating: success()
##[debug]Evaluating success:
##[debug]=> true
##[debug]Result: true
```

### Disabling Debug Logging

Remove or set debug secrets to `false` when debugging completes to reduce log verbosity and improve performance.

## Using Workflow Commands

### Debug Messages

Print debug messages visible only when step debug logging is enabled:

```yaml
steps:
  - name: Debug workflow state
    run: |
      echo "::debug::Current branch: ${{ github.ref }}"
      echo "::debug::Commit SHA: ${{ github.sha }}"
      echo "::debug::Actor: ${{ github.actor }}"
```

### Notice Messages

Create highlighted notice annotations in workflow logs:

```yaml
steps:
  - name: Deployment notice
    run: echo "::notice::Deploying to production environment"

  - name: Notice with file location
    run: echo "::notice file=config.yml,line=10::Configuration loaded successfully"
```

### Warning Messages

Generate warning annotations that appear in the workflow summary:

```yaml
steps:
  - name: Deprecation warning
    run: |
      echo "::warning::Using deprecated API version 1.0"
      echo "::warning file=app.js,line=45::Consider updating to v2.0 API"
```

### Error Messages

Create error annotations and mark issues in logs:

```yaml
steps:
  - name: Validate configuration
    run: |
      if [[ ! -f config.yml ]]; then
        echo "::error file=config.yml::Configuration file not found"
        exit 1
      fi
```

### Grouping Log Output

Organize log output into collapsible groups:

```yaml
steps:
  - name: Installation process
    run: |
      echo "::group::Installing dependencies"
      npm install
      echo "::endgroup::"

      echo "::group::Running build"
      npm run build
      echo "::endgroup::"
```

Groups appear as expandable sections in the log viewer.

### Masking Sensitive Data

Prevent sensitive values from appearing in logs:

```yaml
steps:
  - name: Handle API key
    run: |
      API_KEY=$(generate-api-key)
      echo "::add-mask::$API_KEY"
      echo "Generated key: $API_KEY"  # Appears as "Generated key: ***"
```

Always mask secrets before using them in commands or logging.

## Common Workflow Errors

### Syntax Errors

**Error:** "Workflow file is not valid"

**Causes:**
- Invalid YAML syntax
- Incorrect indentation
- Missing required fields
- Invalid workflow syntax

**Solutions:**

Validate YAML syntax:

```bash
# Using yamllint
yamllint .github/workflows/workflow.yml

# Using yq
yq eval .github/workflows/workflow.yml
```

Check common syntax issues:

```yaml
# Bad: Incorrect indentation
jobs:
build:
  runs-on: ubuntu-latest

# Good: Correct indentation
jobs:
  build:
    runs-on: ubuntu-latest
```

```yaml
# Bad: Missing required field
jobs:
  test:
    steps:
      - run: npm test

# Good: Includes required runs-on
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test
```

Verify expressions use correct syntax:

```yaml
# Bad: Single curly braces
run: echo ${ github.ref }

# Good: Double curly braces
run: echo ${{ github.ref }}
```

### Permission Errors

**Error:** "Resource not accessible by integration"

**Causes:**
- Insufficient GITHUB_TOKEN permissions
- Missing workflow permissions declaration
- Organization or repository policy restrictions

**Solutions:**

Grant required permissions:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: read
    steps:
      - uses: actions/checkout@v4
```

Check default permissions in repository settings:
1. Settings > Actions > General
2. Workflow permissions section
3. Adjust default GITHUB_TOKEN permissions

Common permission requirements:

| Operation | Required Permission |
|-----------|-------------------|
| Push commits | `contents: write` |
| Create pull request | `pull-requests: write` |
| Add comments | `issues: write` or `pull-requests: write` |
| Create releases | `contents: write` |
| Read packages | `packages: read` |
| Deploy to environment | `deployments: write` |

### Secret Access Issues

**Error:** "Secret not found" or secret evaluates to empty string

**Causes:**
- Secret not defined at repository/organization/environment level
- Incorrect secret name reference
- Secret not accessible from fork
- Environment secret not available in workflow_call

**Solutions:**

Verify secret exists:

```bash
# List repository secrets
gh secret list

# Set new secret
gh secret set SECRET_NAME
```

Check secret name matches exactly:

```yaml
# Case-sensitive
steps:
  - env:
      TOKEN: ${{ secrets.API_TOKEN }}  # Must match exact name
    run: ./script.sh
```

Handle missing secrets:

```yaml
steps:
  - name: Check secret availability
    env:
      SECRET: ${{ secrets.OPTIONAL_SECRET }}
    run: |
      if [ -z "$SECRET" ]; then
        echo "Secret not set, using default"
      fi
```

Fork behavior:
- Forks do not inherit secrets from parent repository
- Pull requests from forks cannot access secrets
- Use `pull_request_target` carefully with fork PRs

### Timeout Errors

**Error:** "The job running on runner has exceeded the maximum execution time"

**Causes:**
- Job exceeds default 360-minute limit
- Infinite loops or hanging processes
- Network timeouts
- Resource exhaustion

**Solutions:**

Set appropriate timeouts:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Job-level timeout
    steps:
      - name: Long running task
        timeout-minutes: 15  # Step-level timeout
        run: ./long-task.sh
```

Add progress indicators:

```yaml
steps:
  - name: Long build
    run: |
      echo "::group::Build process"
      for i in {1..10}; do
        echo "Step $i of 10"
        ./build-stage-$i.sh
      done
      echo "::endgroup::"
```

Debug hanging processes:

```yaml
steps:
  - name: Test with timeout
    timeout-minutes: 5
    continue-on-error: true
    id: tests
    run: npm test

  - name: Handle timeout
    if: steps.tests.outcome == 'failure'
    run: |
      echo "Tests timed out or failed"
      # Collect diagnostics
      ps aux
      df -h
```

### Runner Availability Issues

**Error:** "No runner available" or "Waiting for runner"

**Causes:**
- All runners busy
- Runner label mismatch
- Self-hosted runner offline
- GitHub-hosted runner capacity limits

**Solutions:**

Verify runner labels:

```yaml
# Check available labels
jobs:
  build:
    runs-on: ubuntu-latest  # Must match available runners
```

For self-hosted runners:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, production]
    steps:
      - run: echo "Running on self-hosted runner"
```

Check runner status:
- Self-hosted: Settings > Actions > Runners
- View runner status and labels
- Restart offline runners

Add fallback strategies:

```yaml
jobs:
  build:
    strategy:
      matrix:
        runner: [ubuntu-latest, ubuntu-20.04]
    runs-on: ${{ matrix.runner }}
```

## Debugging Techniques

### Step Output Inspection

Examine step outputs to verify data flow:

```yaml
steps:
  - name: Generate version
    id: version
    run: echo "number=1.2.3" >> $GITHUB_OUTPUT

  - name: Verify output
    run: |
      echo "Version is: ${{ steps.version.outputs.number }}"
      if [ -z "${{ steps.version.outputs.number }}" ]; then
        echo "::error::Version output is empty"
        exit 1
      fi
```

### Context Inspection

Use `toJSON()` to examine available context data:

```yaml
steps:
  - name: Dump GitHub context
    run: echo '${{ toJSON(github) }}'

  - name: Dump runner context
    run: echo '${{ toJSON(runner) }}'

  - name: Dump job context
    run: echo '${{ toJSON(job) }}'
```

### Environment Verification

Check environment state:

```yaml
steps:
  - name: Environment diagnostics
    run: |
      echo "::group::Environment variables"
      env | sort
      echo "::endgroup::"

      echo "::group::File system"
      pwd
      ls -la
      df -h
      echo "::endgroup::"

      echo "::group::Network"
      curl -I https://github.com
      echo "::endgroup::"
```

### Conditional Debugging

Add debug steps that run only when needed:

```yaml
steps:
  - name: Conditional debug
    if: runner.debug == '1'
    run: |
      echo "Debug mode enabled"
      echo "Event: ${{ github.event_name }}"
      echo "Ref: ${{ github.ref }}"
      printenv | grep GITHUB_
```

### Interactive Debugging with tmate

Debug workflows interactively by connecting to runner via SSH:

```yaml
steps:
  - name: Setup tmate session
    if: failure()  # Only on failure
    uses: mxschmitt/action-tmate@v3
    timeout-minutes: 30
```

After this step runs, the workflow pauses and provides SSH connection details in the logs. Connect and investigate the runner environment directly.

**Warning:** Do not use tmate in production workflows or with sensitive data. It grants shell access to the runner.

### Artifact Collection

Collect diagnostic artifacts:

```yaml
steps:
  - name: Run tests
    continue-on-error: true
    run: npm test

  - name: Collect logs
    if: always()
    run: |
      mkdir -p debug-logs
      cp -r logs/ debug-logs/
      cp -r test-results/ debug-logs/
      env > debug-logs/environment.txt

  - name: Upload debug artifacts
    if: always()
    uses: actions/upload-artifact@v4
    with:
      name: debug-logs
      path: debug-logs/
      retention-days: 7
```

## Action-Specific Errors

### Checkout Issues

**Error:** "Failed to checkout repository"

**Solutions:**

```yaml
steps:
  # Ensure sufficient token permissions
  - uses: actions/checkout@v4
    with:
      token: ${{ secrets.GITHUB_TOKEN }}
      fetch-depth: 0  # Full history if needed

  # For submodules
  - uses: actions/checkout@v4
    with:
      submodules: recursive
      token: ${{ secrets.GITHUB_TOKEN }}

  # For private repositories
  - uses: actions/checkout@v4
    with:
      token: ${{ secrets.PAT_TOKEN }}  # Personal access token
```

### Cache Issues

**Error:** "Failed to restore cache" or "Failed to save cache"

**Solutions:**

```yaml
steps:
  - name: Cache with fallback
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-npm-

  - name: Verify cache
    run: |
      if [ -d ~/.npm ]; then
        echo "Cache restored successfully"
        du -sh ~/.npm
      else
        echo "No cache, will install from scratch"
      fi
```

Check cache limits:
- Maximum 10 GB total cache size per repository
- Least recently used caches evicted when limit exceeded
- Caches expire after 7 days of no access

### Setup Action Issues

**Error:** Setup action fails (setup-node, setup-python, etc.)

**Solutions:**

```yaml
steps:
  # Specify exact version
  - uses: actions/setup-node@v4
    with:
      node-version: '20.10.0'

  # Use version file
  - uses: actions/setup-node@v4
    with:
      node-version-file: '.nvmrc'

  # With caching
  - uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'

  # Verify installation
  - name: Verify Node.js
    run: |
      node --version
      npm --version
```

## Troubleshooting Decision Trees

### Workflow Not Triggering

```
Workflow not running?
  ├─ Check workflow trigger events
  │   ├─ Verify event matches (push, pull_request, etc.)
  │   ├─ Check branch/path filters
  │   └─ Confirm workflow file in .github/workflows/
  │
  ├─ Check workflow enabled
  │   ├─ Actions tab > Workflows
  │   └─ Enable if disabled
  │
  └─ Verify syntax is valid
      └─ GitHub shows syntax errors in UI
```

### Step Failing

```
Step fails?
  ├─ Check exit code
  │   └─ Non-zero exit code causes failure
  │
  ├─ Review step logs
  │   ├─ Enable debug logging
  │   └─ Check error messages
  │
  ├─ Verify environment
  │   ├─ Check runner OS
  │   ├─ Verify dependencies installed
  │   └─ Confirm files exist
  │
  └─ Test command locally
      └─ Run same command in similar environment
```

### Permission Issues

```
Permission denied?
  ├─ Check GITHUB_TOKEN permissions
  │   ├─ Add permissions block
  │   └─ Grant specific scopes
  │
  ├─ Verify repository settings
  │   ├─ Workflow permissions
  │   └─ Organization policies
  │
  └─ Confirm user/token has access
      └─ For cross-repository operations
```

### Variable/Secret Issues

```
Variable not available?
  ├─ Check variable/secret exists
  │   ├─ Repository/environment/org level
  │   └─ Correct name (case-sensitive)
  │
  ├─ Verify scope
  │   ├─ Environment secrets require environment
  │   └─ Org secrets require access policy
  │
  └─ Check syntax
      └─ Use ${{ secrets.NAME }} or ${{ vars.NAME }}
```

## Advanced Debugging

### Using Job Summaries

Create detailed debug summaries:

```yaml
steps:
  - name: Generate debug summary
    run: |
      echo "## Debug Information" >> $GITHUB_STEP_SUMMARY
      echo "" >> $GITHUB_STEP_SUMMARY
      echo "**Workflow:** ${{ github.workflow }}" >> $GITHUB_STEP_SUMMARY
      echo "**Run ID:** ${{ github.run_id }}" >> $GITHUB_STEP_SUMMARY
      echo "**Actor:** ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
      echo "" >> $GITHUB_STEP_SUMMARY
      echo "### Environment" >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
      env | grep GITHUB_ >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
```

### Comparing Workflow Runs

Compare successful and failed runs:

1. Navigate to Actions tab
2. Open failed workflow run
3. Find corresponding successful run
4. Compare:
   - Trigger events and inputs
   - Environment variables
   - Dependency versions
   - Runner environments

### Testing with workflow_dispatch

Create test workflows for debugging:

```yaml
name: Debug Workflow

on:
  workflow_dispatch:
    inputs:
      debug-level:
        description: 'Debug verbosity'
        required: true
        type: choice
        options:
          - minimal
          - verbose
          - full

jobs:
  debug:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Minimal debug
        if: inputs.debug-level != 'minimal'
        run: |
          echo "Basic debug output"

      - name: Verbose debug
        if: inputs.debug-level == 'verbose' || inputs.debug-level == 'full'
        run: |
          echo "::group::Environment"
          env
          echo "::endgroup::"

      - name: Full debug
        if: inputs.debug-level == 'full'
        run: |
          echo '${{ toJSON(github) }}'
          echo '${{ toJSON(runner) }}'
```

### Log Retention

Workflow logs retain for 90 days. Download important logs:

```bash
# Using GitHub CLI
gh run download RUN_ID

# Or view logs
gh run view RUN_ID --log
```

## Performance Debugging

### Identifying Slow Steps

Add timing information:

```yaml
steps:
  - name: Timed operation
    run: |
      start_time=$(date +%s)
      ./long-running-command.sh
      end_time=$(date +%s)
      duration=$((end_time - start_time))
      echo "::notice::Operation took ${duration} seconds"
```

### Profiling Workflows

Profile resource usage:

```yaml
steps:
  - name: Profile resources
    run: |
      echo "::group::System resources before"
      free -h
      df -h
      echo "::endgroup::"

      ./resource-intensive-task.sh

      echo "::group::System resources after"
      free -h
      df -h
      echo "::endgroup::"
```

## Common Pitfalls

### Expression Evaluation

Understand when expressions evaluate:

```yaml
# Bad: Expression in string, not evaluated
run: echo "Ref is ${{ github.ref }}"

# Good: Expression outside quotes
run: echo "Ref is ${{ github.ref }}"

# Context matters
env:
  # Evaluated once at workflow start
  STATIC_REF: ${{ github.ref }}
steps:
  - run: echo $STATIC_REF  # Uses evaluated value
```

### Context Availability

Some contexts only available in specific locations:

```yaml
# Job context not available in job-level conditionals
jobs:
  test:
    if: job.status == 'success'  # WRONG - job context not available here

  deploy:
    needs: test
    if: needs.test.result == 'success'  # CORRECT
```

### String vs Boolean

Handle boolean values correctly:

```yaml
# Bad: String comparison
if: github.event.pull_request.draft == 'false'

# Good: Boolean comparison
if: github.event.pull_request.draft == false

# Or check truthiness
if: "!github.event.pull_request.draft"
```

## Getting Help

### Community Resources

- GitHub Community Forum: discuss.github.com
- Stack Overflow: Tag `github-actions`
- GitHub Actions documentation
- Action repository issues

### Creating Reproducible Examples

When seeking help, provide:

```yaml
# Minimal reproducible workflow
name: Issue Reproduction

on: push

jobs:
  reproduce:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Demonstrate issue
        run: |
          # Minimal code showing the problem
          echo "This step demonstrates the issue"
```

Include:
- Workflow YAML
- Error messages
- Expected vs actual behavior
- Workflow run URL
- Relevant logs
