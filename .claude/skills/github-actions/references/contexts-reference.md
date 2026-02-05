# GitHub Actions Contexts Reference

Comprehensive guide to all context objects available in GitHub Actions workflows, including their properties, availability, and practical usage.

## Understanding Contexts

Contexts are a way to access information about workflow runs, runner environments, jobs, and steps. They provide structured data you can use in expressions throughout your workflow.

**Context Syntax**:
- Property dereference: `github.sha`
- Index syntax: `github['sha']`

**Key Differences from Environment Variables**:
- Contexts available throughout workflow (even before runner assignment)
- Environment variables only exist on the runner
- Use contexts for conditionals, job routing, and initial processing
- Use environment variables within step execution

## Available Contexts Summary

| Context | Scope | Primary Use |
|---------|-------|-------------|
| `github` | Global | Workflow run and event information |
| `env` | Step-level | Environment variables set in workflow |
| `vars` | Global | Configuration variables from repository/org |
| `job` | Job-level | Current job information |
| `jobs` | Workflow-level | Reusable workflow job outputs |
| `steps` | Job-level | Previous step outputs and results |
| `runner` | Job-level | Runner environment information |
| `secrets` | Global | Secret values |
| `strategy` | Job-level | Matrix strategy information |
| `matrix` | Job-level | Current matrix combination values |
| `needs` | Job-level | Dependent job outputs and results |
| `inputs` | Global | Workflow/action inputs |

## github Context

Contains information about the workflow run and the event that triggered it.

### Key Properties

**Workflow Information**:
```yaml
github.workflow          # Workflow name
github.workflow_ref      # Workflow file reference
github.workflow_sha      # Workflow file SHA
github.run_id           # Unique run ID
github.run_number       # Run number for this workflow
github.run_attempt      # Attempt number for this run
```

**Repository Information**:
```yaml
github.repository        # 'owner/repo'
github.repository_id     # Numeric repository ID
github.repository_owner  # Repository owner username
github.repository_owner_id  # Owner's numeric ID
github.repositoryUrl     # Git URL
```

**Event Information**:
```yaml
github.event_name       # Event that triggered workflow
github.event            # Full event webhook payload
github.event_path       # Path to event payload file
```

**Branch and Ref Information**:
```yaml
github.ref              # Full ref (refs/heads/main)
github.ref_name         # Short ref name (main)
github.ref_type         # 'branch' or 'tag'
github.ref_protected    # true if protected branch
github.sha              # Commit SHA
```

**Pull Request Specific**:
```yaml
github.head_ref         # PR source branch
github.base_ref         # PR target branch
```

**User Information**:
```yaml
github.actor            # User who triggered workflow
github.actor_id         # Actor's numeric ID
github.triggering_actor # User who triggered re-run
```

**Authentication and APIs**:
```yaml
github.token            # GITHUB_TOKEN for authentication
github.server_url       # GitHub server URL
github.api_url          # API URL
github.graphql_url      # GraphQL API URL
```

**File System Paths**:
```yaml
github.workspace        # Workspace directory path
github.env              # Path to environment file
github.path             # Path to PATH file
```

**Action Information**:
```yaml
github.action           # Action name or step ID
github.action_path      # Path to action
github.action_ref       # Action version/ref
github.action_repository # Action repository
github.action_status    # Composite action status
```

**Miscellaneous**:
```yaml
github.job              # Current job ID
github.retention_days   # Artifact retention days
github.secret_source    # Source of secrets
```

### Practical Examples

**Check Event Type**:
```yaml
jobs:
  build:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Push event"
```

**Branch-Specific Logic**:
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying from main branch"
```

**Access PR Information**:
```yaml
jobs:
  pr-info:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "PR from ${{ github.head_ref }} to ${{ github.base_ref }}"
          echo "PR number: ${{ github.event.pull_request.number }}"
```

**Use Event Payload**:
```yaml
jobs:
  comment:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Issue title: ${{ github.event.issue.title }}"
          echo "Comment body: ${{ github.event.comment.body }}"
```

**Conditional on Actor**:
```yaml
jobs:
  admin-only:
    if: github.actor == 'admin-user'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Admin task"
```

### Security Warning

Never log or expose the `github` context in public repositories as it may contain sensitive information. Use `toJSON()` carefully:

```yaml
# Safe for debugging in private repos
- name: Dump context
  env:
    GITHUB_CONTEXT: ${{ toJSON(github) }}
  run: echo "$GITHUB_CONTEXT"
```

## env Context

Contains environment variables set at workflow, job, or step level.

### Scope and Availability

Variables are available based on where they're defined:
- Workflow-level: Available in all jobs and steps
- Job-level: Available in all steps in that job
- Step-level: Available only in that step

### Practical Examples

**Access Environment Variables**:
```yaml
env:
  BUILD_ENV: production
  VERSION: 1.0.0

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      NODE_ENV: production
    steps:
      - run: echo "Build env: ${{ env.BUILD_ENV }}"
      - run: echo "Node env: ${{ env.NODE_ENV }}"
      - run: echo "Version: ${{ env.VERSION }}"
        env:
          VERSION: 2.0.0  # Overrides workflow-level
```

**Dynamic Environment Variables**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "BUILD_ID=$RANDOM" >> $GITHUB_ENV

      - run: echo "Build ID: ${{ env.BUILD_ID }}"
```

**Conditional Based on Environment**:
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying"
        if: env.BUILD_ENV == 'production'
```

### Important Notes

- Cannot use `env` in `id` or `uses` keys
- Use runner's environment variable syntax (`$VAR`) in run scripts
- Environment variables are string values only
- Case-sensitive on Linux/macOS, case-insensitive on Windows

## vars Context

Contains configuration variables set at repository, organization, or environment levels.

### Usage Examples

**Access Configuration Variables**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "API URL: ${{ vars.API_URL }}"
      - run: echo "Environment: ${{ vars.ENVIRONMENT }}"
```

**Use in Job Configuration**:
```yaml
jobs:
  deploy:
    runs-on: ${{ vars.RUNNER_LABEL }}
    environment: ${{ vars.DEPLOY_ENVIRONMENT }}
    steps:
      - run: echo "Deploying to ${{ vars.DEPLOY_TARGET }}"
```

**With Environment-Specific Variables**:
```yaml
jobs:
  deploy:
    environment: production
    runs-on: ubuntu-latest
    steps:
      # Environment-level vars take precedence
      - run: echo "DB URL: ${{ vars.DATABASE_URL }}"
```

### Variable Precedence

1. Environment-level variables (highest)
2. Repository-level variables
3. Organization-level variables (lowest)

### Important Notes

- Variables available after environment is declared
- Cannot contain sensitive data (use secrets instead)
- Can be used in workflow, job, and step contexts
- Useful for non-sensitive configuration

## job Context

Contains information about the currently running job.

### Key Properties

```yaml
job.status              # 'success', 'failure', 'cancelled'
job.check_run_id        # Check run ID (GitHub.com only)
job.container.id        # Container ID
job.container.network   # Container network ID
job.services.<id>.id    # Service container ID
job.services.<id>.network    # Service network ID
job.services.<id>.ports      # Exposed ports
```

### Practical Examples

**Access Service Container Ports**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres
        ports:
          - 5432
    steps:
      - run: |
          echo "Postgres port: ${{ job.services.postgres.ports[5432] }}"
          pg_isready -h localhost -p ${{ job.services.postgres.ports[5432] }}
```

**Check Job Status**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: make build

      - name: Cleanup on failure
        if: job.status == 'failure'
        run: make cleanup
```

**Use Container Network**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: node:16
    services:
      redis:
        image: redis
    steps:
      - run: |
          echo "Network: ${{ job.container.network }}"
          # Services accessible on container network
```

## jobs Context

Available only in reusable workflows for accessing outputs from called workflow jobs.

### Practical Examples

**Define Reusable Workflow Outputs**:
```yaml
# reusable.yml
on:
  workflow_call:
    outputs:
      image_tag:
        description: "Built image tag"
        value: ${{ jobs.build.outputs.tag }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      tag: ${{ steps.build.outputs.tag }}
    steps:
      - id: build
        run: echo "tag=v1.0.0" >> $GITHUB_OUTPUT
```

**Use Reusable Workflow Outputs**:
```yaml
jobs:
  call-reusable:
    uses: ./.github/workflows/reusable.yml

  deploy:
    needs: call-reusable
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ needs.call-reusable.outputs.image_tag }}"
```

**Access Job Results**:
```yaml
# reusable.yml
on:
  workflow_call:
    outputs:
      all_passed:
        value: ${{ jobs.test.result == 'success' && jobs.lint.result == 'success' }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint
```

## steps Context

Contains information about steps that have already run in the current job.

### Key Properties

```yaml
steps.<step_id>.outputs.<name>  # Step output value
steps.<step_id>.outcome          # 'success', 'failure', 'cancelled', 'skipped'
steps.<step_id>.conclusion       # Final result after continue-on-error
```

### Practical Examples

**Use Step Outputs**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - id: build_info
        run: |
          echo "version=1.0.0" >> $GITHUB_OUTPUT
          echo "hash=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT

      - run: |
          echo "Version: ${{ steps.build_info.outputs.version }}"
          echo "Hash: ${{ steps.build_info.outputs.hash }}"
```

**Conditional Based on Previous Step**:
```yaml
steps:
  - id: tests
    run: npm test
    continue-on-error: true

  - name: Notify on failure
    if: steps.tests.outcome == 'failure'
    run: echo "Tests failed but continuing"

  - name: Check conclusion
    if: steps.tests.conclusion == 'success'
    run: echo "Tests passed"
```

**Chain Step Outputs**:
```yaml
steps:
  - id: checkout
    uses: actions/checkout@v4

  - id: build
    if: steps.checkout.conclusion == 'success'
    run: npm run build

  - id: test
    if: steps.build.conclusion == 'success'
    run: npm test
```

**Multi-Output Step**:
```yaml
steps:
  - id: matrix_prep
    run: |
      echo "node_versions=[14, 16, 18]" >> $GITHUB_OUTPUT
      echo "os_list=[ubuntu-latest, windows-latest]" >> $GITHUB_OUTPUT

  - run: echo "${{ steps.matrix_prep.outputs.node_versions }}"
```

## runner Context

Contains information about the runner executing the current job.

### Key Properties

```yaml
runner.name             # Runner name
runner.os               # 'Linux', 'Windows', 'macOS'
runner.arch             # 'X64', 'ARM', 'ARM64'
runner.temp             # Temporary directory path
runner.tool_cache       # Tool cache directory path
runner.debug            # '1' if debug logging enabled
runner.environment      # Runner environment type
```

### Practical Examples

**OS-Specific Steps**:
```yaml
jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - run: echo "Building on ${{ runner.os }}"

      - name: Linux-specific
        if: runner.os == 'Linux'
        run: apt-get update

      - name: Windows-specific
        if: runner.os == 'Windows'
        run: choco install tool

      - name: macOS-specific
        if: runner.os == 'macOS'
        run: brew install tool
```

**Use Temporary Directory**:
```yaml
steps:
  - run: |
      mkdir ${{ runner.temp }}/build
      echo "Build logs" > ${{ runner.temp }}/build/output.log

  - uses: actions/upload-artifact@v4
    with:
      name: logs
      path: ${{ runner.temp }}/build
```

**Architecture-Specific Build**:
```yaml
steps:
  - run: |
      if [[ "${{ runner.arch }}" == "ARM64" ]]; then
        make build-arm64
      else
        make build-x64
      fi
```

**Debug Mode Check**:
```yaml
steps:
  - run: |
      if [[ "${{ runner.debug }}" == "1" ]]; then
        set -x  # Enable verbose output
      fi
      ./build.sh
```

## secrets Context

Contains secret values available to the workflow run.

### Key Properties

```yaml
secrets.GITHUB_TOKEN    # Automatic token
secrets.<secret_name>   # Named secret value
```

### Practical Examples

**Use in Authentication**:
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.PAT_TOKEN }}

      - run: |
          echo "Deploying with credentials"
        env:
          API_KEY: ${{ secrets.API_KEY }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

**Pass to Actions**:
```yaml
steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-1
```

**Conditional on Secret Availability**:
```yaml
jobs:
  deploy:
    if: secrets.DEPLOY_KEY != ''
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying"
```

### Important Security Notes

- Never log secrets or use them in echo commands
- Secrets are automatically redacted in logs
- Cannot use secrets in composite actions directly
- Pass secrets as inputs to composite actions
- Secrets not available in fork PRs (security measure)

## strategy Context

Contains information about the matrix execution strategy.

### Key Properties

```yaml
strategy.fail-fast      # true if fail-fast enabled
strategy.job-index      # Zero-based job index in matrix
strategy.job-total      # Total number of jobs in matrix
strategy.max-parallel   # Max parallel jobs
```

### Practical Examples

**Unique Artifact Names**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [14, 16, 18]
    steps:
      - run: npm run build

      - uses: actions/upload-artifact@v4
        with:
          name: build-${{ strategy.job-index }}
          path: dist/
```

**Conditional Logic in Matrix**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - run: |
          echo "Running shard ${{ strategy.job-index }} of ${{ strategy.job-total }}"
          npm test -- --shard=${{ strategy.job-index }}/${{ strategy.job-total }}
```

**Index-Based Configuration**:
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    steps:
      - run: |
          # Use job-index for unique ports, IDs, etc.
          PORT=$((3000 + ${{ strategy.job-index }}))
          echo "Deploying on port $PORT"
```

## matrix Context

Contains the matrix properties for the current job.

### Practical Examples

**Access Matrix Values**:
```yaml
jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        node: [14, 16, 18]
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}

      - run: |
          echo "Building on ${{ matrix.os }} with Node ${{ matrix.node }}"
```

**Custom Matrix Properties**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - environment: dev
            api_url: https://dev.api.com
            debug: true
          - environment: prod
            api_url: https://api.com
            debug: false
    steps:
      - run: |
          echo "Testing ${{ matrix.environment }}"
          echo "API: ${{ matrix.api_url }}"
        env:
          DEBUG: ${{ matrix.debug }}
```

**Dynamic Configuration**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        config:
          - { name: "Debug", flags: "-g -O0" }
          - { name: "Release", flags: "-O3" }
    steps:
      - run: |
          make build \
            NAME="${{ matrix.config.name }}" \
            FLAGS="${{ matrix.config.flags }}"
```

## needs Context

Contains outputs and results from dependent jobs.

### Key Properties

```yaml
needs.<job_id>.result           # 'success', 'failure', 'cancelled', 'skipped'
needs.<job_id>.outputs.<name>   # Job output value
```

### Practical Examples

**Use Job Outputs**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
      artifact_id: ${{ steps.upload.outputs.artifact-id }}
    steps:
      - id: version
        run: echo "version=1.0.0" >> $GITHUB_OUTPUT
      - id: upload
        uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Deploying version: ${{ needs.build.outputs.version }}"
          echo "Artifact: ${{ needs.build.outputs.artifact_id }}"
```

**Conditional on Job Result**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: test
    if: needs.test.result == 'success'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Tests passed, deploying"

  notify:
    needs: test
    if: needs.test.result == 'failure'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Tests failed, sending notification"
```

**Multiple Dependencies**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      build_id: ${{ steps.build.outputs.id }}
    steps:
      - id: build
        run: echo "id=$RANDOM" >> $GITHUB_OUTPUT

  test:
    runs-on: ubuntu-latest
    outputs:
      coverage: ${{ steps.test.outputs.coverage }}
    steps:
      - id: test
        run: echo "coverage=85" >> $GITHUB_OUTPUT

  deploy:
    needs: [build, test]
    if: needs.test.outputs.coverage > 80
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Build: ${{ needs.build.outputs.build_id }}"
          echo "Coverage: ${{ needs.test.outputs.coverage }}%"
```

## inputs Context

Contains input values for reusable workflows or manually triggered workflows.

### Practical Examples

**Reusable Workflow with Inputs**:
```yaml
# reusable.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      deploy_version:
        required: true
        type: string
      dry_run:
        required: false
        type: boolean
        default: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Environment: ${{ inputs.environment }}"
          echo "Version: ${{ inputs.deploy_version }}"
          echo "Dry run: ${{ inputs.dry_run }}"
```

**Manual Workflow with Inputs**:
```yaml
on:
  workflow_dispatch:
    inputs:
      log_level:
        type: choice
        options: [debug, info, warning, error]
        default: info
      tags:
        type: boolean
        default: false

jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - run: |
          ./script.sh \
            --log-level=${{ inputs.log_level }} \
            ${{ inputs.tags && '--with-tags' || '' }}
```

**Use in Conditionals**:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    if: inputs.environment == 'production'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to production"
```

## Context Availability

Different contexts available at different workflow points:

**Workflow Level** (`on:`, `env:`, `concurrency:`):
- `github`
- `inputs`
- `vars`

**Job Level** (`jobs.<job_id>.*`):
- `github`
- `needs`
- `strategy`
- `matrix`
- `inputs`
- `vars`
- `secrets` (in specific keys)

**Step Level** (`jobs.<job_id>.steps[*].*`):
- All contexts including:
  - `job`
  - `steps`
  - `runner`
  - `env`

## Best Practices

1. **Use appropriate context for the task** - Don't overuse `github.event` when simpler context exists
2. **Check context availability** - Verify context is available in your workflow location
3. **Validate inputs** - Always check inputs from manual triggers or reusable workflows
4. **Secure secrets** - Never log or expose secrets context
5. **Use typed inputs** - Leverage choice, boolean types in workflow_dispatch
6. **Access nested properties carefully** - Event payloads vary by event type
7. **Prefer contexts over environment variables** for conditionals and routing
8. **Document matrix properties** - Make custom matrix properties self-documenting
9. **Use needs for job orchestration** - Better than duplicating logic across jobs
10. **Test context expressions** - Verify expressions work as expected before relying on them
