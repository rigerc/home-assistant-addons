# Triggers and Events

Complete guide to configuring workflow triggers.

## Push Event

Triggers when commits are pushed to branches or tags.

```yaml
on: push
```

### Filter by Branches

```yaml
on:
  push:
    branches:
      - main
      - 'releases/**'    # Glob pattern
      - '!releases/**-tmp' # Exclude pattern
```

### Filter by Tags

```yaml
on:
  push:
    tags:
      - 'v*.*.*'         # Semantic versioning
```

### Filter by Paths

Only run when specific files change:

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
      - '**.js'
    paths-ignore:
      - 'docs/**'
      - '**.md'
```

## Pull Request Event

Triggers on pull request activity.

```yaml
on: pull_request
```

### Activity Types

```yaml
on:
  pull_request:
    types: [opened, reopened, synchronize]
```

All available types: `opened`, `closed`, `reopened`, `synchronize`, `assigned`, `unassigned`, `labeled`, `unlabeled`, `edited`, `ready_for_review`, `locked`, `unlocked`, `review_requested`, `review_request_removed`, `converted_to_draft`, `auto_merge_enabled`, `auto_merge_disabled`.

### Filtering

```yaml
on:
  pull_request:
    branches: [main]
    paths: ['src/**']
```

## Workflow Dispatch (Manual)

Manually trigger workflows from GitHub UI or CLI.

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [staging, production]
      debug:
        description: 'Enable debug mode'
        required: false
        type: boolean
        default: false
```

### Trigger via CLI

```bash
gh workflow run deploy.yml -f environment=production -f debug=true
```

## Schedule Event

Trigger workflows at scheduled times using cron syntax.

```yaml
on:
  schedule:
    - cron: '30 5 * * 1,3'  # 05:30 UTC on Mon/Wed
    - cron: '0 0 * * *'     # Daily at midnight
```

### Cron Syntax

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6)
│ │ │ │ │
* * * * *
```

| Operator | Description | Example |
|----------|-------------|----------|
| `*` | Any value | `15 * * * *` (at minute 15) |
| `,` | List | `2,10 4,5 * * *` |
| `-` | Range | `30 4-6 * * *` |
| `/` | Step | `*/15 * * * *` (every 15 min) |

**Important:** Non-standard syntax like `@daily` is NOT supported. Minimum interval is 5 minutes.

## Other Events

```yaml
# Release
on:
  release:
    types: [created, published]

# Issue/PR comment
on:
  issue_comment:
    types: [created]

# Workflow call (reusable)
on:
  workflow_call:
    inputs:
      config:
        required: true
        type: string
```

## Context Variables

Different events provide different context:

| Event | `GITHUB_SHA` | `GITHUB_REF` |
|-------|--------------|--------------|
| `push` | Commit pushed | Branch/tag ref |
| `pull_request` | Last merge commit | PR merge branch |
| `schedule` | Last commit on default | Default branch |

For PR head commit: `github.event.pull_request.head.sha`
