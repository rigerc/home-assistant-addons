# Action Metadata Syntax Reference

Complete reference for creating custom GitHub Actions using action.yml metadata files.

## Understanding Action Types

GitHub Actions supports three types of custom actions:

1. **JavaScript Actions** - Run on the runner using Node.js
2. **Docker Container Actions** - Run in a Docker container
3. **Composite Actions** - Combine multiple workflow steps

Each type uses the same metadata file structure but with different configuration in the `runs` section.

## Metadata File Basics

**File Name**: `action.yml` or `action.yaml`

**Location**: Root of your action repository

**Format**: YAML syntax

**Important**: Changing metadata filename between releases hides previous versions from GitHub Marketplace.

## Top-Level Metadata Fields

### name (Required)

The display name of your action shown in the Actions tab.

```yaml
name: 'Build and Deploy'
```

**Best Practices**:
- Keep it concise and descriptive
- Use title case
- Clearly indicate what the action does
- Avoid redundant words like "Action" or "GitHub Action"

### description (Required)

Short description of what the action does.

```yaml
description: 'Build Docker images and deploy to Kubernetes cluster'
```

**Best Practices**:
- One sentence summary
- Focus on value, not implementation
- Maximum ~125 characters for best display
- Explain what it does, not how

### author (Optional)

Name of the action's author or organization.

```yaml
author: 'Acme Corporation'
```

## Inputs

Define input parameters the action accepts.

### Basic Input Syntax

```yaml
inputs:
  input_id:
    description: 'Description of what this input does'
    required: true|false
    default: 'default value'
    deprecationMessage: 'This input is deprecated, use X instead'
```

### Input Properties

**inputs.<input_id>**

Unique identifier for the input. Must:
- Start with letter or `_`
- Contain only alphanumeric, `-`, or `_`
- Be unique within inputs object

**inputs.<input_id>.description** (Required)

Human-readable description of the input parameter.

**inputs.<input_id>.required** (Optional)

Boolean indicating if the input is required.

```yaml
inputs:
  api_key:
    description: 'API key for authentication'
    required: true
```

**Note**: Actions won't automatically fail if required inputs are missing. Validate in your action code.

**inputs.<input_id>.default** (Optional)

Default value used when input not specified.

```yaml
inputs:
  environment:
    description: 'Deployment environment'
    required: false
    default: 'staging'
```

**inputs.<input_id>.deprecationMessage** (Optional)

Warning message logged when input is used.

```yaml
inputs:
  old_api_key:
    description: 'Legacy API key'
    deprecationMessage: 'old_api_key is deprecated. Use api_key instead.'
```

### Complete Input Example

```yaml
inputs:
  docker_image:
    description: 'Docker image name to build'
    required: true

  docker_tag:
    description: 'Tag for the Docker image'
    required: false
    default: 'latest'

  build_args:
    description: 'Build arguments as JSON string'
    required: false
    default: '{}'

  dockerfile_path:
    description: 'Path to Dockerfile'
    required: false
    default: './Dockerfile'

  push:
    description: 'Push image to registry after build'
    required: false
    default: 'true'
```

### Accessing Inputs

**In JavaScript/Docker Actions**:

Inputs become environment variables with the format `INPUT_<VARIABLE_NAME>`:

```javascript
// Input: docker-image becomes INPUT_DOCKER-IMAGE
const dockerImage = process.env.INPUT_DOCKER_IMAGE;
```

**In Composite Actions**:

Use the `inputs` context:

```yaml
steps:
  - run: echo "Building ${{ inputs.docker_image }}:${{ inputs.docker_tag }}"
```

**In Docker Actions with args**:

Pass inputs via args:

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.docker_image }}
    - ${{ inputs.docker_tag }}
```

## Outputs

Define output parameters the action produces.

### Outputs for JavaScript and Docker Actions

```yaml
outputs:
  output_id:
    description: 'Description of this output'
```

**Set Outputs in Code**:

```javascript
// JavaScript action
const core = require('@actions/core');
core.setOutput('image-digest', digestValue);
```

```bash
# Docker/composite action
echo "image-digest=sha256:abc123..." >> $GITHUB_OUTPUT
```

**Example**:

```yaml
outputs:
  image_digest:
    description: 'SHA256 digest of the built image'

  image_size:
    description: 'Size of the built image in bytes'

  build_time:
    description: 'Time taken to build in seconds'
```

### Outputs for Composite Actions

Composite actions must map outputs from steps.

```yaml
outputs:
  random_number:
    description: 'A random number'
    value: ${{ steps.generate.outputs.random_id }}

runs:
  using: 'composite'
  steps:
    - id: generate
      run: echo "random_id=$RANDOM" >> $GITHUB_OUTPUT
      shell: bash
```

**Complete Example**:

```yaml
outputs:
  version:
    description: 'Application version'
    value: ${{ steps.version.outputs.version }}

  commit_hash:
    description: 'Git commit hash'
    value: ${{ steps.git_info.outputs.hash }}

runs:
  using: 'composite'
  steps:
    - id: version
      run: echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT
      shell: bash

    - id: git_info
      run: echo "hash=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
      shell: bash
```

## Runs Configuration for JavaScript Actions

Configure Node.js-based actions.

### Basic Structure

```yaml
runs:
  using: 'node20'  # or 'node24'
  main: 'dist/index.js'
  pre: 'dist/setup.js'      # Optional
  pre-if: runner.os == 'linux'  # Optional
  post: 'dist/cleanup.js'    # Optional
  post-if: always()          # Optional
```

### runs.using (Required)

Specifies Node.js runtime version.

**Options**:
- `node20` - Node.js v20
- `node24` - Node.js v24

```yaml
runs:
  using: 'node24'
```

**Best Practice**: Use latest stable Node.js version.

### runs.main (Required)

Entry point file for your action code.

```yaml
runs:
  using: 'node24'
  main: 'dist/index.js'
```

**Best Practices**:
- Compile TypeScript to JavaScript
- Bundle dependencies (using ncc or similar)
- Minimize file size
- Place in `dist/` directory

### runs.pre (Optional)

Script to run before main action.

```yaml
runs:
  using: 'node24'
  main: 'index.js'
  pre: 'setup.js'
```

**Use Cases**:
- Install dependencies
- Set up environment
- Download required files
- Validate prerequisites

**Important**: Not supported for local actions (actions in the same repository).

### runs.pre-if (Optional)

Condition for running pre script.

```yaml
runs:
  using: 'node24'
  main: 'index.js'
  pre: 'setup.js'
  pre-if: runner.os == 'linux'
```

**Default**: `always()` - runs unconditionally

**Common Conditions**:
```yaml
pre-if: runner.os == 'linux'
pre-if: inputs.setup == 'true'
pre-if: env.SKIP_SETUP != 'true'
```

**Note**: `step` context unavailable (no steps run yet).

### runs.post (Optional)

Cleanup script to run after main action completes.

```yaml
runs:
  using: 'node24'
  main: 'index.js'
  post: 'cleanup.js'
```

**Use Cases**:
- Clean up temporary files
- Stop background processes
- Upload logs
- Send telemetry

### runs.post-if (Optional)

Condition for running post script.

```yaml
runs:
  using: 'node24'
  main: 'index.js'
  post: 'cleanup.js'
  post-if: always()  # Run even if main fails
```

**Common Patterns**:
```yaml
post-if: always()                    # Always run
post-if: success()                   # Only on success
post-if: failure()                   # Only on failure
post-if: cancelled()                 # Only if cancelled
post-if: job.status == 'success'     # Check job status
```

### Complete JavaScript Action Example

```yaml
name: 'Setup Environment'
description: 'Set up build environment with caching'
author: 'DevOps Team'

inputs:
  node_version:
    description: 'Node.js version to install'
    required: false
    default: '20'

  cache_dependencies:
    description: 'Enable dependency caching'
    required: false
    default: 'true'

outputs:
  cache_hit:
    description: 'Whether cache was hit'

  node_version:
    description: 'Installed Node.js version'

runs:
  using: 'node24'
  main: 'dist/index.js'
  pre: 'dist/setup.js'
  pre-if: inputs.cache_dependencies == 'true'
  post: 'dist/cleanup.js'
  post-if: always()
```

## Runs Configuration for Composite Actions

Combine multiple steps into a single action.

### Basic Structure

```yaml
runs:
  using: 'composite'
  steps:
    - run: echo "Step 1"
      shell: bash

    - uses: actions/checkout@v4

    - run: npm install
      shell: bash
```

### runs.using (Required)

Must be set to `'composite'`.

```yaml
runs:
  using: 'composite'
```

### runs.steps (Required)

Array of steps to execute.

Each step can be:
- `run` step - Execute commands
- `uses` step - Call another action

### Step Properties

**runs.steps[*].run**

Command to execute.

```yaml
steps:
  - run: echo "Hello World"
    shell: bash

  - run: |
      echo "Multi-line"
      echo "commands"
    shell: bash

  - run: ${{ github.action_path }}/scripts/build.sh
    shell: bash
```

**Use action path**:
```yaml
- run: ${{ github.action_path }}/script.sh
  shell: bash

# Or with environment variable
- run: $GITHUB_ACTION_PATH/script.sh
  shell: bash
```

**runs.steps[*].shell** (Required for run steps)

Shell to use for execution.

**Options**:
- `bash`
- `sh`
- `pwsh` (PowerShell Core)
- `powershell` (Windows PowerShell)
- `cmd`
- `python`

```yaml
steps:
  - run: echo "Bash script"
    shell: bash

  - run: Write-Host "PowerShell"
    shell: pwsh

  - run: print("Python script")
    shell: python
```

**runs.steps[*].uses**

Action to run as part of this step.

```yaml
steps:
  # Use specific version
  - uses: actions/checkout@v4

  # Use specific commit
  - uses: actions/setup-node@b39b52d1213e96004bfcb1c61a8a6fa8ab84f3e8

  # Use major version
  - uses: actions/cache@v3

  # Use branch
  - uses: actions/upload-artifact@main

  # Use local action
  - uses: ./.github/actions/custom-action

  # Use Docker image
  - uses: docker://alpine:3.8
```

**Versioning Best Practices**:
- **Commit SHA**: Most secure, never changes
- **Major version tag**: Get updates, maintain compatibility
- **Specific version**: Lock to exact version
- **Branch**: Convenient but can break

**runs.steps[*].with**

Input parameters for the action.

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
      ref: main

  - uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'
```

**runs.steps[*].name** (Optional)

Display name for the step.

```yaml
steps:
  - name: Install dependencies
    run: npm install
    shell: bash

  - name: Run tests
    run: npm test
    shell: bash
```

**runs.steps[*].id** (Optional)

Unique identifier to reference step in contexts.

```yaml
steps:
  - id: build
    run: |
      echo "version=1.0.0" >> $GITHUB_OUTPUT
      echo "hash=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
    shell: bash

  - run: echo "Version: ${{ steps.build.outputs.version }}"
    shell: bash
```

**runs.steps[*].env** (Optional)

Environment variables for the step.

```yaml
steps:
  - run: echo "API URL: $API_URL"
    shell: bash
    env:
      API_URL: https://api.example.com
      API_KEY: ${{ inputs.api_key }}
```

**Important**: Use `echo "name=value" >> $GITHUB_ENV` to modify workflow environment.

**runs.steps[*].working-directory** (Optional)

Working directory for the command.

```yaml
steps:
  - run: npm install
    shell: bash
    working-directory: ./frontend

  - run: npm test
    shell: bash
    working-directory: ./frontend
```

**runs.steps[*].if** (Optional)

Conditional execution of step.

```yaml
steps:
  - run: npm test
    shell: bash
    if: runner.os == 'Linux'

  - run: echo "On main branch"
    shell: bash
    if: github.ref == 'refs/heads/main'

  - uses: actions/upload-artifact@v4
    if: failure()
    with:
      name: logs
      path: logs/
```

**Common Conditionals**:
```yaml
if: success()                                # Previous step succeeded
if: failure()                                # Previous step failed
if: always()                                 # Always run
if: cancelled()                              # Workflow cancelled
if: runner.os == 'Linux'                     # OS check
if: github.event_name == 'push'              # Event check
if: inputs.deploy == 'true'                  # Input check
if: env.BUILD_ENV == 'production'            # Environment check
if: steps.build.outputs.status == 'success'  # Step output check
```

**runs.steps[*].continue-on-error** (Optional)

Prevent action failure when step fails.

```yaml
steps:
  - run: npm run lint
    shell: bash
    continue-on-error: true

  - run: npm test
    shell: bash
```

### Complete Composite Action Example

```yaml
name: 'Build and Test'
description: 'Build application and run tests with caching'
author: 'Engineering Team'

inputs:
  node_version:
    description: 'Node.js version'
    required: false
    default: '20'

  working_directory:
    description: 'Working directory'
    required: false
    default: '.'

  run_tests:
    description: 'Run test suite'
    required: false
    default: 'true'

outputs:
  build_status:
    description: 'Build status'
    value: ${{ steps.build.outputs.status }}

  test_coverage:
    description: 'Test coverage percentage'
    value: ${{ steps.test.outputs.coverage }}

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node_version }}
        cache: 'npm'
        cache-dependency-path: ${{ inputs.working_directory }}/package-lock.json

    - name: Install dependencies
      run: npm ci
      shell: bash
      working-directory: ${{ inputs.working_directory }}

    - name: Build application
      id: build
      run: |
        npm run build
        echo "status=success" >> $GITHUB_OUTPUT
      shell: bash
      working-directory: ${{ inputs.working_directory }}

    - name: Run tests
      id: test
      if: inputs.run_tests == 'true'
      run: |
        npm test -- --coverage
        COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
        echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT
      shell: bash
      working-directory: ${{ inputs.working_directory }}

    - name: Upload coverage
      if: inputs.run_tests == 'true' && always()
      uses: actions/upload-artifact@v4
      with:
        name: coverage-report
        path: ${{ inputs.working_directory }}/coverage
```

## Runs Configuration for Docker Actions

Configure containerized actions.

### Basic Structure

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.arg1 }}
    - ${{ inputs.arg2 }}
  env:
    ENV_VAR: value
  entrypoint: 'entrypoint.sh'
  pre-entrypoint: 'setup.sh'
  post-entrypoint: 'cleanup.sh'
```

### runs.using (Required)

Must be set to `'docker'`.

```yaml
runs:
  using: 'docker'
```

### runs.image (Required)

Specify the Docker image to use.

**Options**:

**1. Local Dockerfile**:
```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
```

**2. Public Docker Hub image**:
```yaml
runs:
  using: 'docker'
  image: 'docker://alpine:3.18'
```

**3. Public registry image**:
```yaml
runs:
  using: 'docker'
  image: 'docker://gcr.io/cloud-builders/gradle:latest'
```

**Best Practices**:
- Use specific tags, not `latest`
- Pin to exact versions for reproducibility
- Keep images small for faster execution
- Use multi-stage builds to minimize size

### runs.env (Optional)

Environment variables for the container.

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  env:
    API_URL: https://api.example.com
    LOG_LEVEL: debug
    FEATURE_FLAG: ${{ inputs.feature_flag }}
```

### runs.entrypoint (Optional)

Override the Docker ENTRYPOINT.

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  entrypoint: '/app/entrypoint.sh'
```

**When to use**:
- Dockerfile doesn't specify ENTRYPOINT
- Need to override existing ENTRYPOINT
- Want different behavior than image default

### runs.pre-entrypoint (Optional)

Script to run before main entrypoint.

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  pre-entrypoint: '/app/setup.sh'
  entrypoint: '/app/main.sh'
```

**Important**:
- Runs in a new container with same base image
- State not shared with main container
- Use workspace, HOME, or STATE_ variables to share data

### runs.post-entrypoint (Optional)

Cleanup script after main entrypoint.

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  entrypoint: '/app/main.sh'
  post-entrypoint: '/app/cleanup.sh'
```

**Use Cases**:
- Remove temporary files
- Upload logs
- Send metrics
- Clean up resources

### runs.args (Optional)

Arguments passed to container ENTRYPOINT.

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  args:
    - ${{ inputs.source_dir }}
    - ${{ inputs.output_dir }}
    - '--verbose'
```

**Important**:
- Replaces CMD instruction in Dockerfile
- Passed to ENTRYPOINT at container startup
- For variable substitution, ensure shell execution

**Guidelines (ordered by preference)**:
1. Don't use CMD if using `args`
2. Use ENTRYPOINT and args together
3. Make ENTRYPOINT a script that handles args
4. Document expected argument format

**Variable Substitution**:

```yaml
runs:
  using: 'docker'
  image: 'Dockerfile'
  entrypoint: 'sh -c'  # Enable shell
  args:
    - |
      echo "Input: ${{ inputs.message }}"
      /app/main.sh "$INPUT_MESSAGE"
```

### Complete Docker Action Example

```yaml
name: 'Docker Build and Push'
description: 'Build Docker image and push to registry'
author: 'DevOps Team'

inputs:
  image_name:
    description: 'Docker image name'
    required: true

  image_tag:
    description: 'Docker image tag'
    required: false
    default: 'latest'

  registry:
    description: 'Docker registry URL'
    required: false
    default: 'docker.io'

  dockerfile:
    description: 'Path to Dockerfile'
    required: false
    default: './Dockerfile'

outputs:
  image_digest:
    description: 'SHA256 digest of pushed image'

  image_url:
    description: 'Full image URL with tag'

runs:
  using: 'docker'
  image: 'Dockerfile'
  env:
    DOCKER_REGISTRY: ${{ inputs.registry }}
    BUILDKIT_PROGRESS: plain
  args:
    - ${{ inputs.image_name }}
    - ${{ inputs.image_tag }}
    - ${{ inputs.dockerfile }}
```

**Corresponding Dockerfile**:

```dockerfile
FROM docker:24-cli

RUN apk add --no-cache bash jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

## Branding

Customize action appearance in GitHub Marketplace.

### Basic Structure

```yaml
branding:
  icon: 'award'
  color: 'green'
```

### branding.icon

Feather icon name (v4.28.0).

**Popular Icons**:
- `activity`, `alert-circle`, `archive`
- `award`, `check-circle`, `code`
- `database`, `deploy`, `download`
- `file`, `git-branch`, `git-commit`
- `package`, `play`, `rocket`
- `server`, `settings`, `shield`
- `terminal`, `upload`, `zap`

**Find icons**: [Feather Icons](https://feathericons.com/)

### branding.color

Background color for the badge.

**Options**:
- `white`
- `black`
- `gray-dark`
- `yellow`
- `orange`
- `red`
- `purple`
- `blue`
- `green`

### Branding Examples

```yaml
# CI/CD action
branding:
  icon: 'play-circle'
  color: 'blue'

# Deployment action
branding:
  icon: 'upload-cloud'
  color: 'green'

# Security action
branding:
  icon: 'shield'
  color: 'red'

# Notification action
branding:
  icon: 'bell'
  color: 'yellow'

# Testing action
branding:
  icon: 'check-circle'
  color: 'green'
```

## Complete Action Examples

### JavaScript Action

```yaml
name: 'Semantic Release'
description: 'Automate version management and package publishing'
author: 'Release Team'

inputs:
  github_token:
    description: 'GitHub token for creating releases'
    required: true

  npm_token:
    description: 'NPM token for publishing packages'
    required: false

  dry_run:
    description: 'Run in dry-run mode'
    required: false
    default: 'false'

outputs:
  new_release_published:
    description: 'Whether a new release was published'

  new_release_version:
    description: 'Version of the new release'

  new_release_git_tag:
    description: 'Git tag of the new release'

runs:
  using: 'node24'
  main: 'dist/index.js'

branding:
  icon: 'package'
  color: 'blue'
```

### Composite Action

```yaml
name: 'Deploy to AWS'
description: 'Deploy application to AWS with full setup'
author: 'Cloud Team'

inputs:
  aws_region:
    description: 'AWS region'
    required: true

  environment:
    description: 'Deployment environment'
    required: true

  app_version:
    description: 'Application version to deploy'
    required: true

outputs:
  deployment_url:
    description: 'URL of deployed application'
    value: ${{ steps.deploy.outputs.url }}

  deployment_id:
    description: 'Deployment ID'
    value: ${{ steps.deploy.outputs.id }}

runs:
  using: 'composite'
  steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-region: ${{ inputs.aws_region }}
        role-to-assume: arn:aws:iam::123456789012:role/GitHubActions

    - name: Login to ECR
      uses: aws-actions/amazon-ecr-login@v2

    - name: Deploy to ECS
      id: deploy
      run: |
        aws ecs update-service \
          --cluster production \
          --service app-service \
          --force-new-deployment

        URL="https://${{ inputs.environment }}.example.com"
        echo "url=$URL" >> $GITHUB_OUTPUT
        echo "id=$(uuidgen)" >> $GITHUB_OUTPUT
      shell: bash

branding:
  icon: 'upload-cloud'
  color: 'orange'
```

### Docker Action

```yaml
name: 'Security Scanner'
description: 'Scan code for security vulnerabilities'
author: 'Security Team'

inputs:
  scan_path:
    description: 'Path to scan'
    required: false
    default: '.'

  fail_on_severity:
    description: 'Fail on severity level (low, medium, high, critical)'
    required: false
    default: 'high'

  output_format:
    description: 'Output format (json, sarif, table)'
    required: false
    default: 'sarif'

outputs:
  vulnerabilities_found:
    description: 'Number of vulnerabilities found'

  report_path:
    description: 'Path to generated report'

runs:
  using: 'docker'
  image: 'Dockerfile'
  env:
    SCANNER_CONFIG: /config/scanner.yml
  args:
    - scan
    - ${{ inputs.scan_path }}
    - --severity=${{ inputs.fail_on_severity }}
    - --format=${{ inputs.output_format }}

branding:
  icon: 'shield'
  color: 'red'
```

## Best Practices

1. **Choose the right action type**:
   - JavaScript: Fast, cross-platform, good for API interactions
   - Docker: Complex dependencies, specific environment needs
   - Composite: Combine existing actions, workflow reuse

2. **Design good inputs**:
   - Make required inputs truly required
   - Provide sensible defaults
   - Use descriptive names
   - Validate inputs in action code

3. **Provide useful outputs**:
   - Output key results
   - Enable action chaining
   - Use descriptive output names

4. **Handle errors gracefully**:
   - Provide clear error messages
   - Validate prerequisites
   - Clean up on failure

5. **Document thoroughly**:
   - Clear README with usage examples
   - Document all inputs and outputs
   - Provide troubleshooting guide

6. **Version properly**:
   - Use semantic versioning
   - Maintain major version tags
   - Document breaking changes

7. **Test extensively**:
   - Test on multiple platforms
   - Test with different inputs
   - Test error scenarios
   - Automate testing

8. **Keep actions focused**:
   - Single responsibility
   - Composable
   - Reusable

9. **Optimize performance**:
   - Minimize Docker image size
   - Bundle JavaScript dependencies
   - Cache where appropriate
   - Use efficient algorithms

10. **Security considerations**:
    - Validate all inputs
    - Don't log secrets
    - Use minimal permissions
    - Keep dependencies updated
