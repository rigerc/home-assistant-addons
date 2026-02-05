# Creating Docker Container Actions

Build custom Docker container actions for GitHub Actions workflows. Docker actions package your code with dependencies and environment in a consistent, isolated container that runs on Linux runners.

## When to Use Docker Actions

Choose Docker actions when you need:

- Specific system dependencies or tools
- Consistent execution environment
- Non-JavaScript runtime (Python, Ruby, Go, etc.)
- Complex software stack
- Guaranteed reproducibility

Avoid Docker actions if you need:

- Fast execution (Docker has startup overhead)
- Windows or macOS runner support
- Minimal resource usage
- Simple Node.js operations (use JavaScript actions instead)

## Prerequisites

Install Docker on your development machine:

```bash
# macOS
brew install docker

# Ubuntu/Debian
sudo apt-get install docker.io

# Verify installation
docker --version
```

Create a new repository for your action:

```bash
mkdir hello-world-docker-action
cd hello-world-docker-action
git init
```

## Creating a Dockerfile

The Dockerfile defines your container environment and dependencies.

### Basic Dockerfile

Create `Dockerfile`:

```dockerfile
# Container image that runs your code
FROM alpine:3.10

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]
```

### Choosing a Base Image

Select appropriate base images for your needs:

**Alpine Linux** - Minimal size, fast builds:
```dockerfile
FROM alpine:3.19
```

**Ubuntu** - More tools available:
```dockerfile
FROM ubuntu:22.04
```

**Language-specific images**:
```dockerfile
FROM python:3.11-slim
FROM node:20-alpine
FROM golang:1.21-alpine
FROM ruby:3.2-slim
```

**Scratch** - Minimal for compiled binaries:
```dockerfile
FROM scratch
COPY myapp /
ENTRYPOINT ["/myapp"]
```

### Installing Dependencies

Add package installations to your Dockerfile:

```dockerfile
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

For Alpine:

```dockerfile
FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

### Multi-stage Builds

Reduce image size with multi-stage builds:

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Runtime stage
FROM alpine:3.19
COPY --from=builder /app/myapp /usr/local/bin/myapp
ENTRYPOINT ["myapp"]
```

## Action Metadata

Create `action.yml` to define your action interface:

```yaml
name: Hello World
description: Greet someone and record the time

inputs:
  who-to-greet:
    description: Who to greet
    required: true
    default: World

outputs:
  time:
    description: The time we greeted you

runs:
  using: docker
  image: Dockerfile
  args:
    - ${{ inputs.who-to-greet }}
```

### Metadata Components

**runs.using**: Set to `docker` for container actions

**runs.image**: Specify container image
- `Dockerfile` - Build from Dockerfile in repository
- `docker://ubuntu:22.04` - Use pre-built image from registry
- `docker://ghcr.io/owner/image:tag` - Use custom registry image

**runs.args**: Pass arguments to container entrypoint
- Use `${{ inputs.input-name }}` to pass inputs
- Arguments are passed as command-line arguments

**runs.env**: Set environment variables in container
```yaml
runs:
  using: docker
  image: Dockerfile
  env:
    API_URL: https://api.example.com
    LOG_LEVEL: ${{ inputs.log-level }}
```

**runs.entrypoint**: Override Dockerfile ENTRYPOINT
```yaml
runs:
  using: docker
  image: Dockerfile
  entrypoint: /custom-entrypoint.sh
```

## Writing the Entrypoint Script

The entrypoint script contains your action logic.

### Basic Shell Script

Create `entrypoint.sh`:

```bash
#!/bin/sh -l

echo "Hello $1"
time=$(date)
echo "time=$time" >> $GITHUB_OUTPUT
```

Key points:
- `#!/bin/sh -l` - Login shell to load environment
- `$1` - First argument (from `args` in action.yml)
- `$GITHUB_OUTPUT` - File for setting outputs

### Make Script Executable

```bash
chmod +x entrypoint.sh
git add entrypoint.sh
git update-index --chmod=+x entrypoint.sh
```

Verify permissions:

```bash
git ls-files --stage entrypoint.sh
# Should show: 100755 ... entrypoint.sh
```

## Handling Inputs and Outputs

### Reading Inputs

Inputs are passed as arguments or environment variables:

**Via Arguments**:
```yaml
# action.yml
runs:
  using: docker
  image: Dockerfile
  args:
    - ${{ inputs.username }}
    - ${{ inputs.password }}
```

```bash
# entrypoint.sh
#!/bin/bash

USERNAME=$1
PASSWORD=$2

echo "Username: $USERNAME"
```

**Via Environment Variables**:
```yaml
# action.yml
runs:
  using: docker
  image: Dockerfile
  env:
    INPUT_USERNAME: ${{ inputs.username }}
    INPUT_PASSWORD: ${{ inputs.password }}
```

```bash
# entrypoint.sh
#!/bin/bash

echo "Username: $INPUT_USERNAME"
```

Note: GitHub automatically creates `INPUT_*` environment variables for all inputs in uppercase with hyphens replaced by underscores.

### Setting Outputs

Write outputs to `$GITHUB_OUTPUT`:

```bash
# Set single output
echo "result=success" >> $GITHUB_OUTPUT

# Set multiple outputs
echo "version=1.2.3" >> $GITHUB_OUTPUT
echo "status=deployed" >> $GITHUB_OUTPUT

# Set multiline output
echo "report<<EOF" >> $GITHUB_OUTPUT
echo "Line 1" >> $GITHUB_OUTPUT
echo "Line 2" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT
```

### Exit Codes

Return appropriate exit codes:

```bash
# Success
exit 0

# Failure
echo "Error: Something went wrong"
exit 1

# Custom exit code
exit 78
```

## Complete Working Example

### Python Action

**Dockerfile**:
```dockerfile
FROM python:3.11-slim

# Install dependencies
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Copy action code
COPY entrypoint.py /entrypoint.py

# Set entrypoint
ENTRYPOINT ["python", "/entrypoint.py"]
```

**requirements.txt**:
```
requests==2.31.0
PyGithub==2.1.1
```

**action.yml**:
```yaml
name: Python Issue Labeler
description: Automatically label issues based on content

inputs:
  github-token:
    description: GitHub token for API access
    required: true
  label-mapping:
    description: JSON mapping of keywords to labels
    required: true
    default: '{"bug": "bug", "feature": "enhancement"}'

outputs:
  labels-added:
    description: Labels that were added

runs:
  using: docker
  image: Dockerfile
  env:
    INPUT_GITHUB_TOKEN: ${{ inputs.github-token }}
    INPUT_LABEL_MAPPING: ${{ inputs.label-mapping }}
```

**entrypoint.py**:
```python
#!/usr/bin/env python3
import os
import sys
import json
from github import Github

def main():
    try:
        # Get inputs from environment
        token = os.environ.get("INPUT_GITHUB_TOKEN")
        label_mapping = json.loads(os.environ.get("INPUT_LABEL_MAPPING", "{}"))

        # Get GitHub context
        repository = os.environ.get("GITHUB_REPOSITORY")
        event_path = os.environ.get("GITHUB_EVENT_PATH")

        # Read event data
        with open(event_path, 'r') as f:
            event = json.load(f)

        # Get issue details
        if 'issue' not in event:
            print("No issue found in event")
            return

        issue_number = event['issue']['number']
        issue_body = event['issue']['body'] or ""
        issue_title = event['issue']['title'] or ""

        # Initialize GitHub client
        g = Github(token)
        repo = g.get_repo(repository)
        issue = repo.get_issue(issue_number)

        # Find matching labels
        labels_to_add = []
        content = f"{issue_title} {issue_body}".lower()

        for keyword, label in label_mapping.items():
            if keyword.lower() in content:
                labels_to_add.append(label)

        # Add labels
        if labels_to_add:
            issue.add_to_labels(*labels_to_add)
            print(f"Added labels: {', '.join(labels_to_add)}")

            # Set output
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write(f"labels-added={','.join(labels_to_add)}\n")
        else:
            print("No matching labels found")
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write("labels-added=\n")

    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

## Working with Files and Workspace

### Accessing Workspace

GitHub Actions automatically mounts the workspace:

- Runner workspace: `$GITHUB_WORKSPACE`
- Container path: `/github/workspace`

Files in this directory are accessible to all steps.

**Write files from container**:
```bash
#!/bin/bash

# Write to workspace
echo "Build output" > /github/workspace/output.txt

# These files persist after container exits
ls -la /github/workspace
```

**Use files in subsequent steps**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build with container
        uses: ./my-action

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: ${{ github.workspace }}/output.txt
```

### Reading Repository Files

```bash
#!/bin/bash

# Repository is checked out to /github/workspace
if [ -f "/github/workspace/package.json" ]; then
  VERSION=$(jq -r .version /github/workspace/package.json)
  echo "version=$VERSION" >> $GITHUB_OUTPUT
fi
```

### Environment Files

Use GitHub environment files for step communication:

```bash
# Set environment variable
echo "DEPLOY_URL=https://example.com" >> $GITHUB_ENV

# Set output
echo "status=success" >> $GITHUB_OUTPUT

# Add to PATH
echo "/custom/bin" >> $GITHUB_PATH

# Set step summary
echo "## Deployment Complete" >> $GITHUB_STEP_SUMMARY
echo "Deployed to production" >> $GITHUB_STEP_SUMMARY
```

## Testing Your Action

### Local Testing

Test container locally before pushing:

```bash
# Build image
docker build -t my-action .

# Run container
docker run --rm \
  -e INPUT_WHO_TO_GREET="GitHub" \
  -e GITHUB_OUTPUT=/tmp/output.txt \
  my-action

# Test with workspace mount
docker run --rm \
  -v $(pwd):/github/workspace \
  -e GITHUB_WORKSPACE=/github/workspace \
  my-action
```

### Test Workflow

Create `.github/workflows/test.yml`:

```yaml
on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test action
        uses: ./
        with:
          who-to-greet: World
```

## Optimization Techniques

### Minimize Image Size

**Use Alpine base**:
```dockerfile
FROM alpine:3.19
RUN apk add --no-cache python3 py3-pip
```

**Remove build dependencies**:
```dockerfile
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
  && pip install mypackage \
  && apk del .build-deps
```

**Clean up package cache**:
```dockerfile
RUN apt-get update \
  && apt-get install -y package \
  && rm -rf /var/lib/apt/lists/*
```

**Use multi-stage builds**:
```dockerfile
FROM golang:alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o app

FROM alpine:3.19
COPY --from=builder /app/app /usr/local/bin/
ENTRYPOINT ["app"]
```

### Cache Dependencies

**Layer optimization**:
```dockerfile
# Copy dependency files first
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy source code last (changes more frequently)
COPY . .
```

**Use BuildKit cache**:
```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.11

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

### Pre-built Images

Use pre-built images from container registry:

```yaml
# action.yml
runs:
  using: docker
  image: docker://ghcr.io/owner/my-action:v1
```

Build and push images:
```bash
docker build -t ghcr.io/owner/my-action:v1 .
docker push ghcr.io/owner/my-action:v1
```

## Advanced Patterns

### Conditional Logic

```bash
#!/bin/bash

ENVIRONMENT=$INPUT_ENVIRONMENT

if [ "$ENVIRONMENT" = "production" ]; then
  echo "::warning::Deploying to production"

  # Require approval
  if [ "$INPUT_APPROVED" != "true" ]; then
    echo "::error::Production requires approval"
    exit 1
  fi
fi

echo "Deploying to $ENVIRONMENT"
```

### Error Handling

```bash
#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Trap errors
trap 'echo "::error::Script failed at line $LINENO"; exit 1' ERR

# Your logic here
echo "Processing..."
```

### Logging

```bash
#!/bin/bash

# Info message
echo "::notice::Deployment started"

# Warning
echo "::warning file=app.py,line=10::Deprecated function"

# Error
echo "::error::Build failed"

# Debug (visible with debug logging)
echo "::debug::Variable value: $VAR"

# Grouping
echo "::group::Running tests"
npm test
echo "::endgroup::"
```

### Working with JSON

```bash
#!/bin/bash

# Parse JSON input
CONFIG=$(echo "$INPUT_CONFIG" | jq -r '.environment')

# Create JSON output
RESULT=$(jq -n \
  --arg status "success" \
  --arg time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{status: $status, timestamp: $time}')

echo "result=$RESULT" >> $GITHUB_OUTPUT
```

## Publishing Your Action

### Create README

```markdown
# Issue Labeler Action

Automatically label issues based on content.

## Usage

```yaml
- uses: owner/issue-labeler@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    label-mapping: |
      {
        "bug": "bug",
        "feature": "enhancement"
      }
```

## Inputs

### `github-token`

**Required** GitHub token for API access.

### `label-mapping`

**Required** JSON mapping of keywords to labels.

## Outputs

### `labels-added`

Comma-separated list of labels added.
```

### Version and Release

```bash
git add Dockerfile action.yml entrypoint.sh README.md
git commit -m "Initial release"
git tag -a -m "Release v1" v1
git push --follow-tags
```

## Best Practices

### Security

- Use specific image versions, not `latest`
- Scan images for vulnerabilities
- Minimize installed packages
- Run as non-root user when possible
- Never log secrets

### Performance

- Use smallest base image possible
- Optimize Dockerfile layer caching
- Remove unnecessary files
- Consider pre-built images for faster startup

### Reliability

- Handle all error cases
- Set appropriate exit codes
- Validate inputs
- Add timeout handling
- Test with various inputs

### Maintainability

- Document Dockerfile steps
- Use clear variable names
- Keep scripts simple
- Version pin dependencies
- Update base images regularly

## Troubleshooting

### Build Failures

Check Docker build locally:
```bash
docker build --no-cache -t test .
```

### Permission Errors

Ensure scripts are executable:
```bash
git ls-files --stage entrypoint.sh
```

### Missing Outputs

Verify output file path:
```bash
echo "Output: $GITHUB_OUTPUT"
echo "result=value" >> $GITHUB_OUTPUT
```

### Container Not Found

Ensure Dockerfile is committed:
```bash
git ls-files | grep Dockerfile
```
