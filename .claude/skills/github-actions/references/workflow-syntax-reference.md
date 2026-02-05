# Workflow Syntax Reference

Comprehensive reference for GitHub Actions workflow YAML syntax. Use this reference when creating or modifying workflow files.

## File Location and Naming

Store workflow files in `.github/workflows` directory. Use `.yml` or `.yaml` extension.

## Top-Level Keys

### `name`

Optional name for the workflow. GitHub displays this in the Actions tab.

```yaml
name: CI Build and Test
```

### `run-name`

Custom name for workflow runs. Can include expressions referencing `github` and `inputs` contexts.

```yaml
run-name: Deploy to ${{ inputs.deploy_target }} by @${{ github.actor }}
```

### `on`

**Required.** Events that trigger the workflow.

#### Single Event

```yaml
on: push
```

#### Multiple Events

```yaml
on: [push, pull_request]
```

#### Event with Configuration

```yaml
on:
  push:
    branches:
      - main
      - 'releases/**'
```

### `on.<event_name>.types`

Specify activity types for events. Only runs when specific activity types occur.

```yaml
on:
  issues:
    types: [opened, labeled]
```

### `on.push.<branches|tags>`

Filter push events by branch or tag patterns.

```yaml
on:
  push:
    branches:
      - main
      - 'releases/**'
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
```

### `on.push.<branches-ignore|tags-ignore>`

Exclude branches or tags from push events.

```yaml
on:
  push:
    branches-ignore:
      - 'docs/**'
```

### `on.<push|pull_request>.<paths|paths-ignore>`

Run workflows based on changed files.

```yaml
on:
  push:
    paths:
      - '**.js'
      - '!docs/**'
```

### `on.schedule`

Run workflows on a schedule using POSIX cron syntax.

```yaml
on:
  schedule:
    - cron: '30 5,17 * * *'  # 5:30 AM and 5:30 PM daily
```

### `on.workflow_dispatch`

Enable manual workflow triggering.

```yaml
on:
  workflow_dispatch:
    inputs:
      logLevel:
        description: 'Log level'
        required: true
        default: 'warning'
        type: choice
        options:
          - info
          - warning
          - debug
```

### `on.workflow_call`

Define inputs and outputs for reusable workflows.

```yaml
on:
  workflow_call:
    inputs:
      username:
        required: true
        type: string
    secrets:
      token:
        required: true
    outputs:
      result:
        description: "Processing result"
        value: ${{ jobs.process.outputs.result }}
```

## Permissions

Control GITHUB_TOKEN permissions for workflow or specific jobs.

```yaml
permissions:
  contents: read
  pull-requests: write
```

Available permission scopes: `actions`, `checks`, `contents`, `deployments`, `discussions`, `id-token`, `issues`, `packages`, `pages`, `pull-requests`, `repository-projects`, `security-events`, `statuses`.

Values: `read`, `write`, `none`.

## Environment Variables

### `env`

Set environment variables for all jobs or specific jobs/steps.

#### Workflow Level

```yaml
env:
  SERVER: production
  PORT: 8080
```

#### Job Level

```yaml
jobs:
  build:
    env:
      NODE_ENV: production
```

#### Step Level

```yaml
steps:
  - name: Build
    env:
      API_KEY: ${{ secrets.API_KEY }}
    run: npm run build
```

## Defaults

Set default shell and working directory.

```yaml
defaults:
  run:
    shell: bash
    working-directory: ./scripts
```

## Concurrency

Prevent concurrent workflow runs or jobs.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## Jobs

### `jobs.<job_id>`

Define jobs with unique identifiers.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

### `jobs.<job_id>.name`

Display name for the job.

```yaml
jobs:
  build:
    name: Build and Test Application
```

### `jobs.<job_id>.needs`

Define job dependencies.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
  test:
    needs: build
    runs-on: ubuntu-latest
  deploy:
    needs: [build, test]
    runs-on: ubuntu-latest
```

### `jobs.<job_id>.if`

Conditional job execution.

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
```

### `jobs.<job_id>.runs-on`

Specify runner type.

#### GitHub-Hosted Runners

```yaml
runs-on: ubuntu-latest
```

Available: `ubuntu-latest`, `ubuntu-22.04`, `ubuntu-20.04`, `windows-latest`, `windows-2022`, `windows-2019`, `macos-latest`, `macos-13`, `macos-12`.

#### Self-Hosted Runners

```yaml
runs-on: [self-hosted, linux, x64]
```

#### Matrix

```yaml
runs-on: ${{ matrix.os }}
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
```

### `jobs.<job_id>.environment`

Specify deployment environment.

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://prod.example.com
```

### `jobs.<job_id>.outputs`

Define job outputs for use in dependent jobs.

```yaml
jobs:
  build:
    outputs:
      build_id: ${{ steps.build_step.outputs.build_id }}
    steps:
      - id: build_step
        run: echo "build_id=$RANDOM" >> $GITHUB_OUTPUT
```

### `jobs.<job_id>.timeout-minutes`

Maximum job execution time. Default: 360 minutes.

```yaml
jobs:
  build:
    timeout-minutes: 60
```

### `jobs.<job_id>.strategy`

Define matrix strategy for running job variations.

```yaml
jobs:
  test:
    strategy:
      matrix:
        node: [14, 16, 18]
        os: [ubuntu-latest, windows-latest]
      fail-fast: false
      max-parallel: 2
```

### `jobs.<job_id>.strategy.matrix`

Define matrix variables.

```yaml
strategy:
  matrix:
    version: [10, 12, 14]
    os: [ubuntu-latest, windows-latest]
    include:
      - os: ubuntu-latest
        version: 16
    exclude:
      - os: windows-latest
        version: 10
```

### `jobs.<job_id>.continue-on-error`

Allow workflow to pass when job fails.

```yaml
jobs:
  experimental:
    continue-on-error: true
```

### `jobs.<job_id>.container`

Run job in Docker container.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: node:16
      env:
        NODE_ENV: development
      ports:
        - 80
      volumes:
        - my_docker_volume:/volume_mount
      options: --cpus 1
```

### `jobs.<job_id>.services`

Add service containers.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

## Steps

### `jobs.<job_id>.steps`

Sequence of tasks in a job.

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v4
  - name: Run tests
    run: npm test
```

### `jobs.<job_id>.steps[*].id`

Unique identifier for referencing step outputs.

```yaml
steps:
  - id: build_step
    run: echo "result=success" >> $GITHUB_OUTPUT
  - run: echo ${{ steps.build_step.outputs.result }}
```

### `jobs.<job_id>.steps[*].if`

Conditional step execution.

```yaml
steps:
  - name: Deploy
    if: success() && github.ref == 'refs/heads/main'
    run: ./deploy.sh
```

### `jobs.<job_id>.steps[*].name`

Display name for the step.

```yaml
steps:
  - name: Install dependencies
    run: npm ci
```

### `jobs.<job_id>.steps[*].uses`

Specify action to run.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-node@v4
    with:
      node-version: '18'
```

#### Action Referencing Syntax

```yaml
# Public repository
uses: owner/repo@ref

# Specific commit SHA (recommended)
uses: actions/checkout@8f4b7f84864484a7bf31766abe9204da3cbe65b3

# Major version
uses: actions/checkout@v4

# Specific version
uses: actions/checkout@v4.1.0

# Branch
uses: actions/checkout@main

# Subdirectory
uses: owner/repo/path/to/action@ref

# Local action
uses: ./.github/actions/my-action

# Docker Hub
uses: docker://alpine:3.8

# Docker registry
uses: docker://ghcr.io/owner/image
```

### `jobs.<job_id>.steps[*].run`

Execute shell commands.

```yaml
steps:
  - name: Multi-line script
    run: |
      npm ci
      npm run build
      npm test
```

### `jobs.<job_id>.steps[*].shell`

Specify shell for run steps.

```yaml
steps:
  - name: Bash script
    shell: bash
    run: echo "Hello"
  - name: PowerShell script
    shell: pwsh
    run: Write-Output "Hello"
  - name: Python script
    shell: python
    run: |
      import sys
      print(sys.version)
```

Available shells: `bash`, `pwsh`, `python`, `sh`, `cmd`, `powershell`.

### `jobs.<job_id>.steps[*].with`

Input parameters for actions.

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      repository: owner/repo
      ref: main
      token: ${{ secrets.PAT }}
```

### `jobs.<job_id>.steps[*].with.args`

Arguments for Docker container actions.

```yaml
steps:
  - uses: docker://alpine:3.8
    with:
      args: /bin/sh -c "echo Hello"
```

### `jobs.<job_id>.steps[*].with.entrypoint`

Override Docker ENTRYPOINT.

```yaml
steps:
  - uses: docker://node:16
    with:
      entrypoint: /bin/bash
```

### `jobs.<job_id>.steps[*].env`

Environment variables for specific step.

```yaml
steps:
  - name: Build
    env:
      API_KEY: ${{ secrets.API_KEY }}
      DEBUG: true
    run: npm run build
```

### `jobs.<job_id>.steps[*].continue-on-error`

Allow step failure without failing job.

```yaml
steps:
  - name: Experimental feature
    continue-on-error: true
    run: ./experimental.sh
```

### `jobs.<job_id>.steps[*].timeout-minutes`

Maximum step execution time. Default: 360 minutes.

```yaml
steps:
  - name: Long running test
    timeout-minutes: 30
    run: npm test
```

### `jobs.<job_id>.steps[*].working-directory`

Working directory for run commands.

```yaml
steps:
  - name: Build frontend
    working-directory: ./frontend
    run: npm run build
```

## Reusable Workflows

### `jobs.<job_id>.uses`

Call reusable workflow.

```yaml
jobs:
  deploy:
    uses: owner/repo/.github/workflows/deploy.yml@main
    with:
      environment: production
    secrets:
      token: ${{ secrets.DEPLOY_TOKEN }}
```

### `jobs.<job_id>.with`

Pass inputs to reusable workflow.

```yaml
jobs:
  call-workflow:
    uses: ./. github/workflows/reusable.yml
    with:
      config-path: ./config.yml
      debug: true
```

### `jobs.<job_id>.secrets`

Pass secrets to reusable workflow.

```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
    secrets:
      token: ${{ secrets.API_TOKEN }}
```

Or inherit all secrets:

```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable.yml
    secrets: inherit
```

## Filter Patterns

### Branch and Tag Patterns

```yaml
# Match specific branch
branches: [main]

# Wildcard matching
branches: ['releases/**']

# Multiple patterns
branches:
  - main
  - 'releases/**'
  - 'feature/*'

# Exclude patterns
branches-ignore:
  - 'docs/**'
```

### Path Patterns

```yaml
# Match JavaScript files
paths: ['**.js']

# Match specific directory
paths: ['src/**']

# Exclude paths
paths-ignore: ['docs/**', '**.md']

# Complex patterns
paths:
  - 'src/**/*.ts'
  - '!src/**/*.test.ts'
```

### Pattern Matching Rules

- `*` matches zero or more characters (not `/`)
- `**` matches zero or more characters (including `/`)
- `?` matches zero or one character
- `+` matches one or more characters
- `[]` matches character ranges
- `!` negates pattern (must be first character)

### Examples

```yaml
# Semantic versioning tags
tags: ['v[0-9]+.[0-9]+.[0-9]+']

# Feature branches
branches: ['feature/**', 'bugfix/**']

# TypeScript files excluding tests
paths:
  - '**.ts'
  - '!**.test.ts'
  - '!**/__tests__/**'
```

## Complete Workflow Example

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
    paths-ignore: ['docs/**', '**.md']
  pull_request:
    branches: [main]
  workflow_dispatch:

env:
  NODE_VERSION: '18'

defaults:
  run:
    shell: bash

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  pull-requests: write

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [16, 18, 20]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.node }}
          path: coverage/

  build:
    name: Build Application
    needs: test
    runs-on: ubuntu-latest
    outputs:
      build-id: ${{ steps.build.outputs.id }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
      - run: npm ci
      - id: build
        run: |
          npm run build
          echo "id=$(date +%s)" >> $GITHUB_OUTPUT
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  deploy:
    name: Deploy to Production
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
      - name: Deploy
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
        run: ./scripts/deploy.sh
```

## Best Practices

### Use Specific Action Versions

```yaml
# Good: Use commit SHA or version tag
uses: actions/checkout@8f4b7f84864484a7bf31766abe9204da3cbe65b3
uses: actions/checkout@v4

# Avoid: Using branch names
uses: actions/checkout@main
```

### Cache Dependencies

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '18'
    cache: 'npm'
```

### Use Matrix for Multiple Configurations

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    node: [16, 18, 20]
```

### Set Appropriate Timeouts

```yaml
jobs:
  test:
    timeout-minutes: 30
    steps:
      - name: Integration tests
        timeout-minutes: 10
        run: npm run test:integration
```

### Use Concurrency Controls

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

### Minimize Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
```

### Use Environment Variables

```yaml
env:
  NODE_VERSION: '18'

jobs:
  build:
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
```
