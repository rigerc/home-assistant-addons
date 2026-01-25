# Jobs and Matrix Strategy

Detailed configuration for jobs, runners, and matrix builds.

## Runner Types

### GitHub-Hosted Runners

```yaml
# Linux
runs-on: ubuntu-latest      # Ubuntu 22.04
runs-on: ubuntu-22.04
runs-on: ubuntu-20.04

# macOS
runs-on: macos-latest       # macOS 14
runs-on: macos-14
runs-on: macos-13

# Windows
runs-on: windows-latest     # Windows 2022
runs-on: windows-2022
```

### Self-Hosted Runners

```yaml
runs-on: self-hosted
runs-on: [self-hosted, linux, x64]
runs-on: [self-hosted, macOS, arm64]
```

### Runner Groups

```yaml
runs-on:
  group: my-runner-group
  labels: [ubuntu-22.04]
```

## Matrix Strategy

### Basic Matrix

```yaml
strategy:
  matrix:
    node-version: [16, 18, 20]
steps:
  - uses: actions/setup-node@v4
    with:
      node-version: ${{ matrix.node-version }}
```

### Multi-Dimensional Matrix

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    node-version: [18, 20]
```

This creates 6 jobs (3 OS × 2 versions).

### Include/Exclude

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    version: [10, 12, 14]
    include:
      # Add extra config for specific combos
      - os: ubuntu-latest
        version: 14
        extra: ubuntu-14
    exclude:
      # Remove specific combos
      - os: ubuntu-latest
        version: 10
```

### Limit Parallel Jobs

```yaml
strategy:
  max-parallel: 2  # Only 2 jobs run at once
  matrix:
    version: [10, 12, 14, 16]
```

**Limits:**
- Maximum 256 total combinations per matrix
- Maximum 20 dimensions
- Maximum 50 items per dimension

## Job Dependencies

### Sequential Jobs

```yaml
jobs:
  job1:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job 1"

  job2:
    needs: job1  # Wait for job1
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job 2"

  job3:
    needs: [job1, job2]  # Wait for both
    runs-on: ubuntu-latest
    steps:
      - run: echo "Job 3"
```

### Passing Data Between Jobs

```yaml
jobs:
  job1:
    runs-on: ubuntu-latest
    outputs:
      result: ${{ steps.build.outputs.status }}
    steps:
      - id: build
        run: echo "status=success" >> $GITHUB_OUTPUT

  job2:
    needs: job1
    runs-on: ubuntu-latest
    steps:
      - run: echo "${{ needs.job1.outputs.result }}"
```

## Concurrency

### Workflow-Level Concurrency

Cancel in-progress runs when new commits are pushed:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

### Job-Level Concurrency

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    concurrency:
      group: deploy-group
      cancel-in-progress: true
    steps:
      - run: ./deploy.sh
```

**Behavior:**
- Only one running + one pending per group
- Group names are case-insensitive
- Existing pending jobs are canceled when new ones queue

## Permissions

Set minimum required permissions:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      pull-requests: write
```

### Default Permission Levels

```yaml
permissions: read-all      # Read everything
permissions: write-all     # Write everything (not recommended)
permissions: {}            # No permissions
```

## Environments

Use environments for deployment protection:

```yaml
jobs:
  deploy-production:
    environment:
      name: production
      url: https://prod.example.com
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

**Environment features:**
- Require reviewers for approval
- Set wait timer before deployment
- Restrict deployment branches
- Environment-specific secrets

## Continue on Error

Allow workflow to continue after step failure:

```yaml
steps:
  - name: Optional check
    id: optional
    continue-on-error: true
    run: might-fail.sh

  - name: Check result
    if: steps.optional.outcome == 'failure'
    run: echo "Optional check failed"
```

## Timeout

Set maximum job runtime:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - run: npm test
```

**Default timeouts:**
- Public repos: 35 days
- Private repos: 7 days
