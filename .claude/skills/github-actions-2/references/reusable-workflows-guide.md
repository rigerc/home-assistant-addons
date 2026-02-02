# Reusable Workflows Guide

## Overview

Reusable workflows eliminate duplication by allowing you to call complete workflows from within other workflows. Store workflow logic once and reuse it across multiple repositories and workflows, reducing maintenance overhead and ensuring consistency.

## Creating Reusable Workflows

### Basic Structure

Create reusable workflows as YAML files in the `.github/workflows` directory. Subdirectories within `workflows` are not supported.

Define a workflow as reusable by including `workflow_call` in the `on` trigger:

```yaml
on:
  workflow_call:
```

This simple trigger makes the workflow callable from other workflows.

### Complete Example

```yaml
name: Reusable workflow example

on:
  workflow_call:
    inputs:
      config-path:
        required: true
        type: string
      deploy-target:
        required: false
        type: string
        default: 'staging'
    secrets:
      token:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure deployment
        run: echo "Deploying to ${{ inputs.deploy-target }}"

      - name: Deploy application
        uses: actions/deploy@v1
        with:
          repo-token: ${{ secrets.token }}
          configuration-path: ${{ inputs.config-path }}
```

## Defining Inputs and Secrets

### Input Parameters

Define inputs that callers must or can provide. Inputs support multiple data types and validation.

```yaml
on:
  workflow_call:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        type: string

      dry-run:
        description: 'Run deployment in dry-run mode'
        required: false
        type: boolean
        default: false

      timeout:
        description: 'Deployment timeout in minutes'
        required: false
        type: number
        default: 30
```

Supported input types:
- `string` - Text values
- `boolean` - True/false values
- `number` - Numeric values

Always provide descriptions to document parameter purposes.

### Secret Parameters

Define secrets that callers must pass. Secrets are encrypted and never logged.

```yaml
on:
  workflow_call:
    secrets:
      deploy-token:
        description: 'Token for deployment authentication'
        required: true

      api-key:
        description: 'API key for external service'
        required: false
```

Mark secrets as required when the workflow cannot function without them.

### Using Inherited Secrets

Workflows can inherit all secrets from the caller without explicit definition:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Access inherited secret
        run: echo "Using token"
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

When the caller uses `secrets: inherit`, all secrets become available even if not defined in `on.workflow_call.secrets`.

### Referencing Inputs and Secrets

Access inputs and secrets using context expressions:

```yaml
jobs:
  process:
    runs-on: ubuntu-latest
    steps:
      - name: Use input
        run: echo "Environment is ${{ inputs.environment }}"

      - name: Use secret
        env:
          API_TOKEN: ${{ secrets.deploy-token }}
        run: ./deploy.sh
```

### Environment Secret Limitation

Environment secrets cannot be passed through `on.workflow_call`. The workflow must define environments at the job level to access environment secrets:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy
        env:
          # This uses the environment secret, not a passed secret
          SECRET: ${{ secrets.PRODUCTION_SECRET }}
        run: ./deploy.sh
```

## Calling Reusable Workflows

### Reference Syntax

Call reusable workflows using one of these reference formats:

```yaml
# Same repository
uses: ./.github/workflows/reusable-workflow.yml

# Different repository (with version tag)
uses: octo-org/repo-name/.github/workflows/workflow.yml@v1

# Different repository (with branch)
uses: octo-org/repo-name/.github/workflows/workflow.yml@main

# Different repository (with commit SHA)
uses: octo-org/repo-name/.github/workflows/workflow.yml@1234567890abcdef
```

Use commit SHAs for maximum security and reproducibility.

### Calling Example

```yaml
name: Call a reusable workflow

on:
  pull_request:
    branches:
      - main

jobs:
  call-simple-workflow:
    uses: octo-org/shared-workflows/.github/workflows/build.yml@v1

  call-workflow-with-data:
    permissions:
      contents: read
      pull-requests: write
    uses: octo-org/shared-workflows/.github/workflows/deploy.yml@main
    with:
      environment: staging
      dry-run: false
    secrets:
      deploy-token: ${{ secrets.DEPLOY_TOKEN }}
```

### Passing Data

Use `with` to pass inputs:

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy.yml@main
    with:
      target: production
      timeout: 60
```

Use `secrets` to pass individual secrets:

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy.yml@main
    secrets:
      api-token: ${{ secrets.API_TOKEN }}
      deploy-key: ${{ secrets.DEPLOY_KEY }}
```

Use `secrets: inherit` to pass all secrets:

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy.yml@main
    secrets: inherit
```

### Setting Permissions

Set permissions for the called workflow's GITHUB_TOKEN:

```yaml
jobs:
  deploy:
    permissions:
      contents: read
      deployments: write
    uses: ./.github/workflows/deploy.yml@main
```

The called workflow operates with these permissions, not the permissions defined in the reusable workflow file.

## Using Matrix Strategy

Combine matrix strategies with reusable workflows to run the same workflow with different configurations:

```yaml
jobs:
  deploy-multiple-environments:
    strategy:
      matrix:
        target: [dev, staging, production]
        region: [us-east, eu-west]
    uses: ./.github/workflows/deploy.yml@main
    with:
      environment: ${{ matrix.target }}
      region: ${{ matrix.region }}
```

This creates six jobs (3 targets × 2 regions), each calling the reusable workflow with different parameters.

### Matrix with Exclusions

```yaml
jobs:
  deploy:
    strategy:
      matrix:
        target: [dev, staging, production]
        include:
          - target: dev
            branch: develop
          - target: staging
            branch: release
          - target: production
            branch: main
    uses: ./.github/workflows/deploy.yml@main
    with:
      environment: ${{ matrix.target }}
      branch: ${{ matrix.branch }}
```

## Workflow Outputs

### Defining Outputs

Reusable workflows can return data to callers through outputs. Map job outputs to workflow outputs:

```yaml
name: Reusable workflow with outputs

on:
  workflow_call:
    outputs:
      build-version:
        description: "Version number of the build"
        value: ${{ jobs.build.outputs.version }}

      artifact-url:
        description: "URL to the build artifact"
        value: ${{ jobs.build.outputs.url }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.number }}
      url: ${{ steps.upload.outputs.artifact-url }}

    steps:
      - id: version
        run: echo "number=1.2.3" >> $GITHUB_OUTPUT

      - id: upload
        run: echo "artifact-url=https://example.com/artifact" >> $GITHUB_OUTPUT
```

Outputs follow this mapping chain:
1. Step outputs set via `$GITHUB_OUTPUT`
2. Job outputs map step outputs
3. Workflow outputs map job outputs

### Using Outputs

Access outputs from called workflows in subsequent jobs:

```yaml
jobs:
  build:
    uses: ./.github/workflows/build.yml@main

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy build
        run: |
          echo "Version: ${{ needs.build.outputs.build-version }}"
          echo "Artifact: ${{ needs.build.outputs.artifact-url }}"
```

### Matrix and Outputs

When using matrix strategy with outputs, the output contains the value from the last successful workflow run:

```yaml
jobs:
  build-matrix:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    uses: ./.github/workflows/build.yml@main

  deploy:
    needs: build-matrix
    runs-on: ubuntu-latest
    steps:
      # This gets the output from whichever matrix job completed last
      - run: echo "${{ needs.build-matrix.outputs.build-version }}"
```

## Nesting Reusable Workflows

### Nesting Depth

Chain reusable workflows up to these depths:
- GitHub.com: 10 levels (caller + 9 nested workflows)
- GitHub Enterprise Server: 4 levels (caller + 3 nested workflows)

```
caller.yml
  → level-1.yml
    → level-2.yml
      → level-3.yml
```

Circular references are not permitted.

### Nested Example

```yaml
# level-1.yml
name: First level workflow

on:
  workflow_call:
    inputs:
      message:
        required: true
        type: string

jobs:
  call-next-level:
    uses: octo-org/workflows/.github/workflows/level-2.yml@main
    with:
      message: ${{ inputs.message }}
```

### Access and Permissions

All workflows in the chain must be accessible to the original caller. Permissions can only be maintained or reduced, never elevated:

```yaml
# Caller sets read permissions
permissions:
  contents: read

# Level 1 can maintain or reduce, not increase
permissions:
  contents: read
  # Cannot add: issues: write

# Level 2 must further maintain or reduce
permissions:
  contents: read
```

## Passing Secrets Through Nested Workflows

### Direct Passing

Explicitly pass named secrets to directly called workflows:

```yaml
# workflow-A.yml
jobs:
  call-B:
    uses: ./.github/workflows/workflow-B.yml@main
    secrets:
      api-token: ${{ secrets.API_TOKEN }}
```

### Inherit All Secrets

Pass all secrets automatically:

```yaml
# workflow-A.yml
jobs:
  call-B:
    uses: ./.github/workflows/workflow-B.yml@main
    secrets: inherit
```

### Nested Secret Passing

Secrets only pass to directly called workflows. In chain A → B → C:
- A passes secrets to B
- B must explicitly pass secrets to C
- C does not automatically receive A's secrets

```yaml
# workflow-A.yml
jobs:
  call-B:
    uses: ./.github/workflows/B.yml@main
    secrets: inherit  # Pass all to B

# workflow-B.yml
jobs:
  call-C:
    uses: ./.github/workflows/C.yml@main
    secrets:
      # Must explicitly pass to C
      token: ${{ secrets.API_TOKEN }}
```

## Monitoring Workflow Usage

### Audit Log Integration

GitHub Enterprise Cloud provides audit log access to monitor reusable workflow usage:

```bash
# Query audit logs via REST API
curl -H "Authorization: token TOKEN" \
  https://api.github.com/orgs/ORG/audit-log
```

### Audit Log Fields

The `prepared_workflow_job` event captures:

- `repo` - Organization/repository where workflow job runs
- `@timestamp` - Unix epoch timestamp of job start
- `job_name` - Name of the executed job
- `calling_workflow_refs` - Array of caller workflow paths (reverse order)
- `calling_workflow_shas` - Array of caller workflow SHAs
- `job_workflow_ref` - Reference to the called workflow

Example audit data for chain A → B → C:

```json
{
  "job_workflow_ref": "octo-org/repo/.github/workflows/C.yml@ref",
  "calling_workflow_refs": [
    "octo-org/repo/.github/workflows/B.yml",
    "octo-org/repo/.github/workflows/A.yml"
  ]
}
```

## Reusable Workflows vs Composite Actions

### When to Use Reusable Workflows

Choose reusable workflows when you need:

- Complete workflow orchestration with multiple jobs
- Different runner types for different tasks
- Matrix strategies across jobs
- Conditional job execution
- Environment deployments with protection rules

Example use case:

```yaml
# Reusable workflow for multi-stage deployment
on:
  workflow_call:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  test:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - run: npm test

  deploy:
    runs-on: ubuntu-latest
    needs: test
    environment: production
    steps:
      - run: ./deploy.sh
```

### When to Use Composite Actions

Choose composite actions when you need:

- Reusable sequence of steps within a single job
- Parameterized action with inputs and outputs
- Sharing across multiple workflows easily
- No need for multiple runners or job orchestration

Example use case:

```yaml
# Composite action for setup steps
name: Setup Node.js project
description: Install dependencies and cache
runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
    - run: npm ci
      shell: bash
    - uses: actions/cache@v3
```

### Comparison Table

| Feature | Reusable Workflows | Composite Actions |
|---------|-------------------|-------------------|
| Multiple jobs | Yes | No (single job steps) |
| Different runners | Yes | No (inherits job runner) |
| Matrix strategy | Yes (at job level) | No |
| Environments | Yes | No |
| Secrets | Explicit passing required | Inherit from job |
| Nested calls | Up to 10 levels | Unlimited |
| Location | `.github/workflows/` | Any repository location |
| Reference | Repository + path | Marketplace or repository |

## Best Practices

### Version Management

Always reference reusable workflows with specific versions:

```yaml
# Good: Pinned to version tag
uses: org/repo/.github/workflows/deploy.yml@v1.2.3

# Better: Pinned to commit SHA (most secure)
uses: org/repo/.github/workflows/deploy.yml@abc123def456

# Avoid: Using branch names (can change unexpectedly)
uses: org/repo/.github/workflows/deploy.yml@main
```

### Input Validation

Validate inputs within the reusable workflow:

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate environment
        run: |
          if [[ ! "${{ inputs.environment }}" =~ ^(dev|staging|prod)$ ]]; then
            echo "Invalid environment: ${{ inputs.environment }}"
            exit 1
          fi
```

### Secret Handling

Never log or expose secrets:

```yaml
# Bad: Secret might appear in logs
- run: echo "Token is ${{ secrets.API_TOKEN }}"

# Good: Use secret in environment variable
- env:
    API_TOKEN: ${{ secrets.API_TOKEN }}
  run: ./script.sh  # Script uses $API_TOKEN
```

### Documentation

Document reusable workflows clearly:

```yaml
name: Deploy Application

# Purpose: Deploy application to specified environment
# Inputs:
#   - environment: Target environment (dev/staging/prod)
#   - version: Version to deploy
# Secrets:
#   - deploy-token: Authentication token for deployment
# Outputs:
#   - deployment-url: URL of deployed application

on:
  workflow_call:
    inputs:
      environment:
        description: 'Target environment (dev/staging/prod)'
        required: true
        type: string
```

### Error Handling

Include error handling and status reporting:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        id: deploy
        continue-on-error: true
        run: ./deploy.sh

      - name: Report failure
        if: steps.deploy.outcome == 'failure'
        run: |
          echo "Deployment failed"
          # Send notification
          exit 1
```

### Testing Reusable Workflows

Test reusable workflows in isolation:

```yaml
# test-workflow.yml
name: Test reusable workflow

on:
  workflow_dispatch:
    inputs:
      test-scenario:
        required: true
        type: string

jobs:
  test:
    uses: ./.github/workflows/reusable.yml@main
    with:
      environment: test
    secrets: inherit
```

## Access Control

### Repository Visibility

Reusable workflows follow repository visibility:
- Public repositories: Anyone can call workflows
- Private repositories: Only workflows in same repository or organization (with access)
- Internal repositories: Available within enterprise

### Organization Settings

Configure organization-wide policies for reusable workflows:
1. Navigate to organization settings
2. Select Actions > General
3. Configure "Access" policies for workflows

### Self-Hosted Runner Groups

Restrict reusable workflows to specific self-hosted runner groups:

```yaml
jobs:
  secure-deploy:
    runs-on: [self-hosted, production]
    steps:
      - run: ./deploy.sh
```

Configure runner groups to only execute specific reusable workflows, ensuring controlled deployment environments.

## Troubleshooting

### Common Issues

**Workflow not found**
- Verify the repository path is correct
- Check the workflow file exists in `.github/workflows/`
- Ensure the reference (tag/branch/SHA) exists
- Confirm caller has access to the repository

**Input validation failures**
- Check input types match (string, boolean, number)
- Verify required inputs are provided
- Ensure input names match exactly (case-sensitive)

**Secret not available**
- Confirm secret is defined at repository/org level
- Check secret name matches exactly
- Verify `secrets:` block passes the secret
- Remember environment secrets cannot be passed

**Permission denied**
- Set appropriate permissions in caller job
- Check organization policies allow workflow access
- Verify repository visibility and access settings

### Debug Logging

Enable detailed logging:

```yaml
jobs:
  debug-call:
    uses: ./.github/workflows/reusable.yml@main
    with:
      debug: true
    secrets: inherit
```

Add debug output in reusable workflow:

```yaml
jobs:
  job:
    runs-on: ubuntu-latest
    steps:
      - name: Debug inputs
        run: |
          echo "Input environment: ${{ inputs.environment }}"
          echo "Runner OS: ${{ runner.os }}"
```

Enable GitHub Actions debug logging by setting repository secrets:
- `ACTIONS_STEP_DEBUG` = `true`
- `ACTIONS_RUNNER_DEBUG` = `true`
