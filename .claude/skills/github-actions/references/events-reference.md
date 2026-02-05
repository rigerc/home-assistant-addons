# GitHub Actions Events Reference

Comprehensive guide to all events that trigger GitHub Actions workflows, their activity types, use cases, and practical examples.

## Understanding Workflow Events

Workflow triggers are events that cause a workflow to run. Events can be:

- **Repository events**: Activities that happen in your repository (push, pull request, issues)
- **Scheduled events**: Time-based triggers using cron syntax
- **Manual events**: Manually triggered workflows (workflow_dispatch)
- **External events**: Events from outside GitHub (repository_dispatch)
- **Workflow events**: Workflows triggering other workflows (workflow_run, workflow_call)

Not all webhook events trigger workflows. Many events support multiple activity types that let you control exactly when workflows run.

## Core Code Events

### push

Triggers when you push commits or tags to a repository.

**Activity Types**: None
**GITHUB_SHA**: Tip commit pushed to the ref
**GITHUB_REF**: Updated ref

**Basic Usage**:
```yaml
on: push
```

**Filter by Branches**:
```yaml
on:
  push:
    branches:
      - 'main'
      - 'releases/**'
```

**Filter by Tags**:
```yaml
on:
  push:
    tags:
      - 'v1.**'
```

**Filter by Files**:
```yaml
on:
  push:
    paths:
      - '**.js'
      - 'src/**'
```

**Common Use Cases**:
- Run CI tests on every commit
- Deploy to production when pushing to main
- Build and publish when pushing version tags
- Validate code quality on all branches

**Important Notes**:
- Events won't be created if more than 5,000 branches are pushed at once
- Events won't be created for tags when more than three tags are pushed at once
- The "pushed by" field shows the pusher, not the author or committer

### pull_request

Triggers when activity occurs on a pull request.

**Activity Types**:
- `opened` - Pull request opened
- `reopened` - Pull request reopened
- `closed` - Pull request closed
- `synchronize` - Head branch updated
- `assigned` / `unassigned` - Assignee changed
- `labeled` / `unlabeled` - Label changed
- `edited` - Title or body edited
- `ready_for_review` - Converted from draft
- `review_requested` / `review_request_removed` - Reviewer changed
- `auto_merge_enabled` / `auto_merge_disabled` - Auto-merge toggled
- `converted_to_draft` - Converted to draft
- `locked` / `unlocked` - Conversation locked/unlocked
- `milestoned` / `demilestoned` - Milestone changed
- `enqueued` / `dequeued` - Merge queue status changed

**GITHUB_SHA**: Last merge commit on PR merge branch
**GITHUB_REF**: PR merge branch `refs/pull/PULL_REQUEST_NUMBER/merge`

**Default Triggers** (opened, synchronize, reopened):
```yaml
on: pull_request
```

**Specific Activity Types**:
```yaml
on:
  pull_request:
    types: [opened, reopened, review_requested]
```

**Target Specific Branches**:
```yaml
on:
  pull_request:
    branches:
      - 'main'
      - 'releases/**'
```

**Filter by Changed Files**:
```yaml
on:
  pull_request:
    paths:
      - '**.js'
      - 'src/**'
```

**Check Head Branch in Job**:
```yaml
on: pull_request
jobs:
  build:
    if: startsWith(github.head_ref, 'feature/')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building feature branch"
```

**Detect Merged PRs**:
```yaml
on:
  pull_request:
    types: [closed]

jobs:
  cleanup:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - run: echo "PR was merged"
```

**Common Use Cases**:
- Run tests on every PR update
- Require checks before merge
- Auto-label PRs based on files changed
- Deploy preview environments
- Run security scans on PR code

**Important Notes**:
- Workflows won't run if PR has merge conflicts
- Webhook payload is empty for merged PRs from forks
- For PRs from forks, consider using `pull_request_target` for write access (with caution)

### pull_request_target

Similar to `pull_request` but runs in the context of the base repository.

**Activity Types**: Same as `pull_request`
**GITHUB_SHA**: Last commit on default branch
**GITHUB_REF**: Default branch (not merge branch)

**Usage**:
```yaml
on:
  pull_request_target:
    types: [opened, synchronize]
```

**Common Use Cases**:
- Comment on PRs from forks (needs write access)
- Label PRs from external contributors
- Add PRs to project boards
- Run workflows that need secrets (carefully)

**Security Warning**:
- Runs with write token and access to secrets
- Can be dangerous if checking out PR code
- Never run untrusted code from PR in this context
- Use only for actions that don't execute PR code

## Pull Request Review Events

### pull_request_review

Triggers when a pull request review is submitted, edited, or dismissed.

**Activity Types**:
- `submitted` - Review submitted
- `edited` - Review edited
- `dismissed` - Review dismissed

**Check for Approvals**:
```yaml
on:
  pull_request_review:
    types: [submitted]

jobs:
  approved:
    if: github.event.review.state == 'approved'
    runs-on: ubuntu-latest
    steps:
      - run: echo "PR was approved!"
```

**Common Use Cases**:
- Auto-merge when approved
- Notify team of reviews
- Track review metrics
- Trigger deployment on approval

### pull_request_review_comment

Triggers when a comment on a PR diff is created, edited, or deleted.

**Activity Types**:
- `created`
- `edited`
- `deleted`

**Usage**:
```yaml
on:
  pull_request_review_comment:
    types: [created]
```

**Common Use Cases**:
- Respond to specific code feedback
- Trigger actions based on comment commands
- Track code review discussions

## Issue Events

### issues

Triggers when an issue is created or modified.

**Activity Types**:
- `opened` / `reopened` / `closed` - Lifecycle changes
- `assigned` / `unassigned` - Assignee changed
- `labeled` / `unlabeled` - Labels changed
- `edited` / `deleted` - Content changed
- `transferred` - Issue transferred
- `pinned` / `unpinned` - Pin status changed
- `locked` / `unlocked` - Lock status changed
- `milestoned` / `demilestoned` - Milestone changed
- `typed` / `untyped` - Issue type changed

**Usage**:
```yaml
on:
  issues:
    types: [opened, labeled]
```

**Auto-Respond to New Issues**:
```yaml
on:
  issues:
    types: [opened]

jobs:
  welcome:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Thanks for opening this issue!'
            })
```

**Common Use Cases**:
- Auto-label issues
- Add to project boards
- Notify teams
- Validate issue format
- Create linked branches

### issue_comment

Triggers when a comment on an issue or PR is created, edited, or deleted.

**Activity Types**:
- `created`
- `edited`
- `deleted`

**Distinguish Issues vs PRs**:
```yaml
on: issue_comment

jobs:
  pr_comment:
    if: github.event.issue.pull_request
    runs-on: ubuntu-latest
    steps:
      - run: echo "Comment on PR"

  issue_comment:
    if: '!github.event.issue.pull_request'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Comment on issue"
```

**Common Use Cases**:
- Bot commands (e.g., "/deploy", "/retest")
- Auto-respond to questions
- Trigger workflows from comments
- Moderate discussions

## Release Events

### release

Triggers when a release is published, unpublished, created, edited, deleted, or prereleased.

**Activity Types**:
- `published` - Release published (not draft)
- `unpublished` - Published release unpublished
- `created` - Draft created
- `edited` - Release edited
- `deleted` - Release deleted
- `prereleased` - Prerelease published
- `released` - Release or prerelease published

**Usage**:
```yaml
on:
  release:
    types: [published]
```

**Build and Upload Assets**:
```yaml
on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make build
      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ./build/app.zip
          asset_name: app.zip
          asset_content_type: application/zip
```

**Common Use Cases**:
- Build and publish binaries
- Deploy to production
- Create distribution packages
- Update changelog
- Notify users of new releases

**Important Notes**:
- `created`, `edited`, `deleted` don't trigger for draft releases
- `prereleased` doesn't trigger for drafts promoted to prerelease
- Use `published` to catch both releases and prereleases

## Discussion Events

### discussion

Triggers when a discussion is created or modified.

**Activity Types**:
- `created` / `edited` / `deleted`
- `transferred` / `pinned` / `unpinned`
- `labeled` / `unlabeled`
- `locked` / `unlocked`
- `category_changed`
- `answered` / `unanswered`

**Usage**:
```yaml
on:
  discussion:
    types: [created, answered]
```

### discussion_comment

Triggers when a discussion comment is created, edited, or deleted.

**Activity Types**:
- `created`
- `edited`
- `deleted`

**Common Use Cases**:
- Auto-respond to questions
- Categorize discussions
- Award badges for helpful answers

## Scheduled Events

### schedule

Triggers workflows at scheduled times using cron syntax.

**Usage**:
```yaml
on:
  schedule:
    # Run at 4:15 and 5:15 UTC daily
    - cron: '15 4,5 * * *'
```

**Multiple Schedules**:
```yaml
on:
  schedule:
    - cron: '0 0 * * *'    # Daily at midnight
    - cron: '0 12 * * 1'   # Weekly on Monday at noon
```

**Common Patterns**:
```yaml
# Every 15 minutes
- cron: '*/15 * * * *'

# Hourly
- cron: '0 * * * *'

# Daily at 2:30 AM
- cron: '30 2 * * *'

# Weekly on Sunday at midnight
- cron: '0 0 * * 0'

# Monthly on the 1st at midnight
- cron: '0 0 1 * *'

# Weekdays at 9 AM
- cron: '0 9 * * 1-5'
```

**Common Use Cases**:
- Nightly builds
- Periodic cleanup tasks
- Data synchronization
- Report generation
- Dependency updates
- Security scans

**Important Notes**:
- Scheduled workflows run on default branch only
- Delays may occur during high load
- Disabled after 60 days of no repository activity (public repos)
- Non-standard syntax (`@daily`, etc.) not supported
- Use [crontab.guru](https://crontab.guru/) to validate syntax

## Manual Trigger Events

### workflow_dispatch

Enables manual workflow triggering from the GitHub UI, API, or CLI.

**Basic Usage**:
```yaml
on: workflow_dispatch
```

**With Inputs**:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        type: choice
        options:
          - development
          - staging
          - production
      logLevel:
        description: 'Log level'
        required: false
        default: 'info'
        type: choice
        options:
          - debug
          - info
          - warning
          - error
      tags:
        description: 'Run with tags'
        required: false
        type: boolean

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
      - run: echo "Log level: ${{ inputs.logLevel }}"
      - run: echo "Tags: ${{ inputs.tags }}"
```

**Input Types**:
- `string` - Text input
- `boolean` - Checkbox
- `choice` - Dropdown menu
- `environment` - Environment selector

**Trigger via CLI**:
```bash
gh workflow run deploy.yml \
  -f environment=production \
  -f logLevel=info \
  -f tags=true
```

**Common Use Cases**:
- Manual deployments
- On-demand testing
- Administrative tasks
- Emergency hotfixes
- Data migrations

## Repository Events

### create

Triggers when a branch or tag is created.

**Usage**:
```yaml
on: create
```

**Common Use Cases**:
- Set up branch protection
- Initialize new features
- Notify team of new branches

**Important Notes**:
- Event not created for more than 3 tags at once

### delete

Triggers when a branch or tag is deleted.

**Usage**:
```yaml
on: delete
```

**Common Use Cases**:
- Clean up associated resources
- Close related issues
- Archive artifacts

### fork

Triggers when someone forks the repository.

**Usage**:
```yaml
on: fork
```

**Common Use Cases**:
- Track repository popularity
- Welcome new contributors
- Send analytics

### watch

Triggers when someone stars the repository.

**Activity Types**: `started`

**Usage**:
```yaml
on:
  watch:
    types: [started]
```

**Common Use Cases**:
- Thank users for starring
- Track repository growth
- Send notifications

### public

Triggers when a private repository becomes public.

**Usage**:
```yaml
on: public
```

**Common Use Cases**:
- Update documentation
- Enable public integrations
- Notify team

## Workflow Orchestration Events

### workflow_run

Triggers when another workflow completes or is requested.

**Activity Types**:
- `completed`
- `requested`
- `in_progress`

**Usage**:
```yaml
on:
  workflow_run:
    workflows: [Build]
    types: [completed]
```

**Check Workflow Result**:
```yaml
on:
  workflow_run:
    workflows: [Tests]
    types: [completed]

jobs:
  on_success:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Tests passed"

  on_failure:
    if: github.event.workflow_run.conclusion == 'failure'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Tests failed"
```

**Filter by Branch**:
```yaml
on:
  workflow_run:
    workflows: [Deploy]
    types: [completed]
    branches: [main, staging]
```

**Access Triggering Workflow Artifacts**:
```yaml
on:
  workflow_run:
    workflows: [Build]
    types: [completed]

jobs:
  use_artifacts:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const artifacts = await github.rest.actions.listWorkflowRunArtifacts({
              owner: context.repo.owner,
              repo: context.repo.repo,
              run_id: context.payload.workflow_run.id
            });
            console.log(artifacts);
```

**Common Use Cases**:
- Deploy after successful build
- Run security scans after tests
- Publish artifacts from forks safely
- Chain dependent workflows

**Important Notes**:
- Can't chain more than 3 levels deep
- Runs with write token even if previous workflow didn't
- Security risk: validate workflow_run conclusion carefully

### workflow_call

Marks a workflow as reusable, callable from other workflows.

**Usage in Reusable Workflow**:
```yaml
on:
  workflow_call:
    inputs:
      config-path:
        required: true
        type: string
    secrets:
      token:
        required: true
    outputs:
      result:
        description: "Build result"
        value: ${{ jobs.build.outputs.result }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      result: ${{ steps.build.outputs.result }}
    steps:
      - id: build
        run: echo "result=success" >> $GITHUB_OUTPUT
```

**Call from Another Workflow**:
```yaml
jobs:
  call-reusable:
    uses: ./.github/workflows/reusable.yml
    with:
      config-path: .github/config.yml
    secrets:
      token: ${{ secrets.TOKEN }}
```

**Common Use Cases**:
- Share workflows across repositories
- Standardize CI/CD processes
- Reduce code duplication
- Enforce organizational policies

## External Trigger Events

### repository_dispatch

Triggers workflows from external events via the GitHub API.

**Usage**:
```yaml
on:
  repository_dispatch:
    types: [deploy, test]
```

**Trigger via API**:
```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{
    "event_type": "deploy",
    "client_payload": {
      "environment": "production",
      "version": "1.0.0"
    }
  }'
```

**Access Payload**:
```yaml
on:
  repository_dispatch:
    types: [deploy]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Environment: ${{ github.event.client_payload.environment }}"
          echo "Version: ${{ github.event.client_payload.version }}"
```

**Common Use Cases**:
- Trigger from external CI/CD
- Integrate with webhooks
- Respond to custom events
- Cross-repository automation

**Important Notes**:
- event_type limited to 100 characters
- client_payload max 10 top-level properties
- Max 65,535 characters total in payload

## Deployment Events

### deployment

Triggers when a deployment is created.

**Usage**:
```yaml
on: deployment
```

### deployment_status

Triggers when deployment status changes.

**Usage**:
```yaml
on: deployment_status
```

**Common Use Cases**:
- Track deployment progress
- Update status badges
- Notify teams
- Trigger rollback

## Check and Status Events

### check_run

Triggers on check run events.

**Activity Types**:
- `created`
- `rerequested`
- `completed`
- `requested_action`

**Usage**:
```yaml
on:
  check_run:
    types: [rerequested]
```

### check_suite

Triggers when check suite completes.

**Activity Types**: `completed`

**Usage**:
```yaml
on:
  check_suite:
    types: [completed]
```

### status

Triggers when commit status changes.

**Usage**:
```yaml
on: status

jobs:
  on_error:
    if: github.event.state == 'error' || github.event.state == 'failure'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Status check failed"
```

## Branch Protection Events

### branch_protection_rule

Triggers when branch protection rules change.

**Activity Types**:
- `created`
- `edited`
- `deleted`

**Usage**:
```yaml
on:
  branch_protection_rule:
    types: [created, edited]
```

**Common Use Cases**:
- Audit protection changes
- Sync settings across branches
- Notify security team

## Label and Milestone Events

### label

Triggers when repository labels change.

**Activity Types**:
- `created`
- `edited`
- `deleted`

**Usage**:
```yaml
on:
  label:
    types: [created]
```

### milestone

Triggers when milestones change.

**Activity Types**:
- `created`
- `closed`
- `opened`
- `edited`
- `deleted`

**Usage**:
```yaml
on:
  milestone:
    types: [created, closed]
```

## Wiki and Pages Events

### gollum

Triggers when wiki pages are created or updated.

**Usage**:
```yaml
on: gollum
```

**Common Use Cases**:
- Validate wiki changes
- Update documentation index
- Sync to external docs

### page_build

Triggers when GitHub Pages builds.

**Usage**:
```yaml
on: page_build
```

**Common Use Cases**:
- Verify Pages deployment
- Update CDN cache
- Notify of publish

## Package Events

### registry_package

Triggers when packages are published or updated.

**Activity Types**:
- `published`
- `updated`

**Usage**:
```yaml
on:
  registry_package:
    types: [published]
```

**Filter Multi-arch Images**:
```yaml
jobs:
  deploy:
    if: github.event.registry_package.package_version.container_metadata.tag.name != ''
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying tagged image"
```

## Merge Queue Events

### merge_group

Triggers when a PR is added to merge queue.

**Activity Types**: `checks_requested`

**Usage**:
```yaml
on:
  pull_request:
    branches: [main]
  merge_group:
    types: [checks_requested]
```

**Common Use Cases**:
- Run required checks before merge
- Validate merge queue entries
- Test merged state

## Event Context and Variables

Every event provides context through:

- `github.event` - Full webhook payload
- `github.event_name` - Event name
- `github.sha` - Commit SHA
- `github.ref` - Git ref
- `github.actor` - User who triggered event

**Access Event Data**:
```yaml
steps:
  - run: |
      echo "Event: ${{ github.event_name }}"
      echo "Actor: ${{ github.actor }}"
      echo "SHA: ${{ github.sha }}"
      echo "Ref: ${{ github.ref }}"
```

## Combining Events

Trigger on multiple events:

```yaml
on: [push, pull_request, workflow_dispatch]
```

Different configurations per event:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 0 * * *'
```

## Best Practices

1. **Use specific activity types** to avoid unnecessary workflow runs
2. **Filter by branches/paths** to run only when relevant files change
3. **Combine events carefully** to avoid duplicate runs
4. **Use pull_request_target cautiously** - security risk with fork PRs
5. **Test scheduled workflows** - they may have delays or skip runs
6. **Validate manual inputs** in workflow_dispatch workflows
7. **Check event conclusions** before chaining workflows with workflow_run
8. **Use repository_dispatch** for external integrations sparingly
9. **Document custom event_types** for repository_dispatch
10. **Monitor workflow runs** to optimize trigger configurations
