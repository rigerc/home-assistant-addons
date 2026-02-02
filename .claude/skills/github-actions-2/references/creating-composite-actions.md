# Creating Composite Actions

Build reusable composite actions that combine multiple workflow steps into a single action. Composite actions allow you to package complex workflows into sharable, maintainable units without requiring Docker or JavaScript.

## When to Use Composite Actions

Choose composite actions when you need to:

- Combine multiple steps into a reusable unit
- Share common workflows across repositories
- Avoid duplicating step sequences
- Create simple actions without code compilation
- Use existing actions as building blocks

Choose alternative action types when you need:

- **JavaScript actions** - Complex logic, GitHub API interaction, cross-platform support
- **Docker actions** - Specific runtime environment, system dependencies
- **Reusable workflows** - Multiple jobs, matrix strategies, environment secrets

## Composite vs Reusable Workflows

**Composite Actions**:
- Run as single step within a job
- Share runner with other steps
- Cannot use different operating systems
- Simpler to pass inputs/outputs
- Better for step-level reuse

**Reusable Workflows**:
- Run as complete job(s)
- Can use different runners
- Support matrix strategies
- Use job-level secrets
- Better for job-level reuse

## Creating a Composite Action

### Project Setup

Create a new repository or subdirectory:

```bash
# Separate repository
mkdir hello-world-composite-action
cd hello-world-composite-action
git init

# Within existing repository
mkdir -p .github/actions/hello-world
cd .github/actions/hello-world
```

### Basic Structure

A composite action requires only `action.yml`:

```
hello-world-composite-action/
├── action.yml
└── scripts/
    └── goodbye.sh
```

## Action Metadata

Create `action.yml` defining your composite action:

```yaml
name: Hello World
description: Greet someone

inputs:
  who-to-greet:
    description: Who to greet
    required: true
    default: World

outputs:
  random-number:
    description: Random number
    value: ${{ steps.random-number-generator.outputs.random-number }}

runs:
  using: composite
  steps:
    - name: Set Greeting
      run: echo "Hello $INPUT_WHO_TO_GREET."
      shell: bash
      env:
        INPUT_WHO_TO_GREET: ${{ inputs.who-to-greet }}

    - name: Random Number Generator
      id: random-number-generator
      run: echo "random-number=$(echo $RANDOM)" >> $GITHUB_OUTPUT
      shell: bash

    - name: Run Script
      run: echo "Goodbye"
      shell: bash
```

### Metadata Requirements

**runs.using**: Must be `composite`

**runs.steps**: Array of steps to execute
- Each step must specify `shell`
- Steps run sequentially
- Can use `if` conditionals
- Can reference inputs via `${{ inputs.input-name }}`

**shell**: Required for all run steps
- `bash`, `pwsh`, `python`, `sh`
- Can use different shells for different steps

## Working with Inputs

### Defining Inputs

```yaml
inputs:
  environment:
    description: Deployment environment
    required: true

  version:
    description: Version to deploy
    required: false
    default: latest

  dry-run:
    description: Perform dry run
    required: false
    default: 'false'
```

### Using Inputs in Steps

**Direct reference**:
```yaml
steps:
  - run: echo "Deploying version ${{ inputs.version }}"
    shell: bash
```

**Via environment variables** (recommended):
```yaml
steps:
  - run: echo "Deploying version $VERSION"
    shell: bash
    env:
      VERSION: ${{ inputs.version }}
```

### Input Types

Inputs are always strings. Convert as needed:

```yaml
steps:
  - name: Process boolean
    run: |
      if [ "$DRY_RUN" = "true" ]; then
        echo "Dry run mode enabled"
      fi
    shell: bash
    env:
      DRY_RUN: ${{ inputs.dry-run }}
```

## Working with Outputs

### Defining Outputs

Outputs must reference step outputs:

```yaml
outputs:
  deployment-url:
    description: Deployed application URL
    value: ${{ steps.deploy.outputs.url }}

  status:
    description: Deployment status
    value: ${{ steps.deploy.outputs.status }}
```

### Setting Outputs in Steps

```yaml
steps:
  - name: Deploy
    id: deploy
    run: |
      echo "url=https://app.example.com" >> $GITHUB_OUTPUT
      echo "status=success" >> $GITHUB_OUTPUT
    shell: bash
```

### Multiline Outputs

```yaml
steps:
  - name: Generate Report
    id: report
    run: |
      echo "summary<<EOF" >> $GITHUB_OUTPUT
      echo "Line 1" >> $GITHUB_OUTPUT
      echo "Line 2" >> $GITHUB_OUTPUT
      echo "EOF" >> $GITHUB_OUTPUT
    shell: bash
```

## Using Other Actions

Composite actions can use other actions:

```yaml
runs:
  using: composite
  steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: 20

    - name: Install dependencies
      run: npm ci
      shell: bash

    - name: Run tests
      run: npm test
      shell: bash
```

## Working with Scripts

### External Scripts

Create `scripts/deploy.sh`:

```bash
#!/bin/bash
set -e

echo "Deploying to $1"
# Deployment logic here
```

Make executable:

```bash
chmod +x scripts/deploy.sh
git add --chmod=+x scripts/deploy.sh
```

Reference in action:

```yaml
runs:
  using: composite
  steps:
    - name: Add scripts to PATH
      run: echo "${{ github.action_path }}/scripts" >> $GITHUB_PATH
      shell: bash

    - name: Deploy
      run: deploy.sh ${{ inputs.environment }}
      shell: bash
```

### Inline Scripts

Use multiline strings for longer scripts:

```yaml
steps:
  - name: Complex Logic
    run: |
      # Multi-line bash script
      for file in *.txt; do
        echo "Processing $file"
        # Process file
      done
    shell: bash
```

## Complete Working Example

### Build and Test Action

**action.yml**:
```yaml
name: Node.js Build and Test
description: Build and test Node.js application

inputs:
  node-version:
    description: Node.js version
    required: false
    default: '20'

  working-directory:
    description: Working directory
    required: false
    default: '.'

  run-tests:
    description: Run test suite
    required: false
    default: 'true'

outputs:
  build-status:
    description: Build status
    value: ${{ steps.build.outputs.status }}

  test-status:
    description: Test status
    value: ${{ steps.test.outputs.status }}

  coverage:
    description: Test coverage percentage
    value: ${{ steps.test.outputs.coverage }}

runs:
  using: composite
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: npm
        cache-dependency-path: ${{ inputs.working-directory }}/package-lock.json

    - name: Install dependencies
      run: npm ci
      shell: bash
      working-directory: ${{ inputs.working-directory }}

    - name: Build
      id: build
      run: |
        if npm run build; then
          echo "status=success" >> $GITHUB_OUTPUT
          echo "✅ Build succeeded"
        else
          echo "status=failed" >> $GITHUB_OUTPUT
          echo "❌ Build failed"
          exit 1
        fi
      shell: bash
      working-directory: ${{ inputs.working-directory }}

    - name: Run tests
      id: test
      if: inputs.run-tests == 'true'
      run: |
        if npm test -- --coverage; then
          echo "status=success" >> $GITHUB_OUTPUT

          # Extract coverage percentage
          COVERAGE=$(grep -oP '\d+(?=%)' coverage/coverage-summary.txt | head -1)
          echo "coverage=$COVERAGE" >> $GITHUB_OUTPUT

          echo "✅ Tests passed (${COVERAGE}% coverage)"
        else
          echo "status=failed" >> $GITHUB_OUTPUT
          echo "coverage=0" >> $GITHUB_OUTPUT
          echo "❌ Tests failed"
          exit 1
        fi
      shell: bash
      working-directory: ${{ inputs.working-directory }}

    - name: Upload coverage
      if: inputs.run-tests == 'true'
      uses: actions/upload-artifact@v4
      with:
        name: coverage-report
        path: ${{ inputs.working-directory }}/coverage
```

### Using the Action

**In external repository**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and test
        id: build
        uses: owner/node-build-test-action@v1
        with:
          node-version: '20'
          run-tests: true

      - name: Check results
        run: |
          echo "Build: ${{ steps.build.outputs.build-status }}"
          echo "Tests: ${{ steps.build.outputs.test-status }}"
          echo "Coverage: ${{ steps.build.outputs.coverage }}%"
```

**In same repository**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ./.github/actions/node-build-test
        with:
          node-version: '20'
```

## Advanced Patterns

### Conditional Steps

```yaml
runs:
  using: composite
  steps:
    - name: Development deploy
      if: inputs.environment == 'development'
      run: echo "Deploying to dev"
      shell: bash

    - name: Production deploy
      if: inputs.environment == 'production'
      run: echo "Deploying to prod"
      shell: bash
```

### Error Handling

```yaml
steps:
  - name: Deploy with error handling
    id: deploy
    run: |
      set +e  # Don't exit on error

      # Attempt deployment
      ./deploy.sh
      RESULT=$?

      if [ $RESULT -eq 0 ]; then
        echo "status=success" >> $GITHUB_OUTPUT
      else
        echo "status=failed" >> $GITHUB_OUTPUT
        echo "::error::Deployment failed with code $RESULT"
        exit $RESULT
      fi
    shell: bash
```

### Using Secrets

Pass secrets as inputs:

```yaml
# action.yml
inputs:
  api-token:
    description: API authentication token
    required: true

runs:
  using: composite
  steps:
    - name: Call API
      run: |
        curl -H "Authorization: Bearer $API_TOKEN" \
          https://api.example.com/deploy
      shell: bash
      env:
        API_TOKEN: ${{ inputs.api-token }}
```

Usage:
```yaml
- uses: owner/my-action@v1
  with:
    api-token: ${{ secrets.API_TOKEN }}
```

### Matrix-like Behavior

```yaml
runs:
  using: composite
  steps:
    - name: Test multiple versions
      run: |
        for version in 18 20 22; do
          echo "Testing Node.js $version"
          docker run --rm node:$version node --version
        done
      shell: bash
```

### Setting Environment Variables

```yaml
steps:
  - name: Set environment
    run: |
      echo "DEPLOY_ENV=${{ inputs.environment }}" >> $GITHUB_ENV
      echo "TIMESTAMP=$(date -u +%Y%m%d%H%M%S)" >> $GITHUB_ENV
    shell: bash

  - name: Use environment
    run: |
      echo "Environment: $DEPLOY_ENV"
      echo "Timestamp: $TIMESTAMP"
    shell: bash
```

### Working Directory

```yaml
steps:
  - name: Build in subdirectory
    run: npm run build
    shell: bash
    working-directory: ${{ inputs.working-directory }}
```

## Shell Options

### Available Shells

**bash** - Default for Linux/macOS:
```yaml
- run: echo "Hello"
  shell: bash
```

**pwsh** - PowerShell Core (cross-platform):
```yaml
- run: Write-Output "Hello"
  shell: pwsh
```

**python** - Python scripts:
```yaml
- run: print("Hello")
  shell: python
```

**sh** - POSIX shell:
```yaml
- run: echo "Hello"
  shell: sh
```

### Custom Shell Configuration

```yaml
- run: |
    set -e  # Exit on error
    set -u  # Exit on undefined variable
    set -o pipefail  # Exit on pipe failure

    # Your script
  shell: bash
```

## Limitations

### Cannot Use

- `strategy.matrix` - Use reusable workflows instead
- `runs-on` - Inherits from calling workflow
- `needs` - No job dependencies
- `environment` - Cannot set deployment environment
- `if` at action level - Use at step level

### Workarounds

**Different operating systems**:
Use conditional steps:
```yaml
steps:
  - name: Linux steps
    if: runner.os == 'Linux'
    run: echo "Linux"
    shell: bash

  - name: Windows steps
    if: runner.os == 'Windows'
    run: echo "Windows"
    shell: pwsh
```

**Job-level features**:
Use reusable workflows instead of composite actions.

## Testing Your Action

### Local Testing

Create test workflow `.github/workflows/test.yml`:

```yaml
on:
  push:
    branches:
      - main
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test action
        id: test
        uses: ./
        with:
          who-to-greet: GitHub

      - name: Verify outputs
        run: |
          echo "Output: ${{ steps.test.outputs.random-number }}"

          # Validate output
          if [ -z "${{ steps.test.outputs.random-number }}" ]; then
            echo "Error: No random number generated"
            exit 1
          fi
```

### Test Different Inputs

```yaml
jobs:
  test-matrix:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, staging, production]
        version: ['1.0', '2.0']

    steps:
      - uses: actions/checkout@v4

      - uses: ./
        with:
          environment: ${{ matrix.environment }}
          version: ${{ matrix.version }}
```

## Best Practices

### Design

- Keep actions focused on single responsibility
- Provide sensible defaults
- Make inputs optional when possible
- Document all inputs and outputs
- Use descriptive step names

### Performance

- Minimize number of steps
- Cache dependencies when possible
- Avoid unnecessary checkouts
- Use specific action versions

### Reliability

- Validate inputs early
- Handle errors gracefully
- Set appropriate exit codes
- Use `set -e` in bash scripts
- Test with various inputs

### Maintainability

- Use clear, descriptive names
- Add comments for complex logic
- Keep scripts simple
- Extract reusable scripts to files
- Version pin dependencies

### Security

- Never log secrets
- Validate input formats
- Use least-privilege tokens
- Escape variables properly
- Review dependencies regularly

## Publishing Your Action

### Create README

```markdown
# Node.js Build and Test Action

Build and test Node.js applications with caching and coverage reporting.

## Usage

```yaml
- uses: owner/node-build-test-action@v1
  with:
    node-version: '20'
    run-tests: true
```

## Inputs

### `node-version`

**Optional** Node.js version to use. Default: `20`.

### `working-directory`

**Optional** Working directory. Default: `.`.

### `run-tests`

**Optional** Run test suite. Default: `true`.

## Outputs

### `build-status`

Build status: `success` or `failed`.

### `test-status`

Test status: `success` or `failed`.

### `coverage`

Test coverage percentage.

## Example

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: owner/node-build-test-action@v1
        id: build
        with:
          node-version: '20'

      - run: echo "Coverage: ${{ steps.build.outputs.coverage }}%"
```
```

### Version and Release

```bash
git add action.yml README.md
git commit -m "Initial release"
git tag -a -m "Release v1" v1
git push --follow-tags
```

## Troubleshooting

### Action Not Found

Ensure:
- `action.yml` exists in repository root or action directory
- Repository is public or access is configured
- Path is correct when using local action

### Missing Outputs

Check:
- Step has `id` defined
- Output references correct step ID
- Step actually runs (check `if` conditions)
- Output is written to `$GITHUB_OUTPUT`

### Shell Errors

Verify:
- Every `run` step has `shell` specified
- Shell is available on runner OS
- Scripts have correct line endings
- Scripts are executable (if using files)

### Input Not Available

Confirm:
- Input is defined in `action.yml`
- Input name matches (case-sensitive)
- Using `${{ inputs.name }}` syntax
- Input is passed from workflow
