# CI/CD Integration for Commitlint

Complete guide for integrating commitlint into various CI/CD platforms.

## General Principles

### Fetch Depth

Most CI systems perform shallow clones by default (typically 1-20 commits). Commitlint needs git history to validate commit ranges, so configure full clones:

- **GitHub Actions:** `fetch-depth: 0`
- **GitLab CI:** `GIT_DEPTH: 0`
- **CircleCI:** `checkout` with no depth limitation
- **Azure Pipelines:** `fetchDepth: 0`

### Push vs Pull Request

Different validation strategies:

**Push events:** Validate the last commit only
```bash
npx commitlint --last
```

**Pull request events:** Validate all commits in the PR
```bash
npx commitlint --from $BASE_SHA --to $HEAD_SHA
```

### Configuration File

Ensure commitlint configuration is committed to the repository:
- `commitlint.config.js` (or other supported formats)
- Install commitlint dependencies in CI
- Optionally cache `node_modules` for faster builds

## GitHub Actions

### Complete Workflow Example

```yaml
name: Lint Commit Messages

on: [push, pull_request]

permissions:
  contents: read

jobs:
  commitlint:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Fetch all history for commit range validation

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: lts/*
          cache: npm  # Cache npm dependencies

      - name: Install commitlint
        run: npm install -D @commitlint/cli @commitlint/config-conventional

      - name: Print versions
        run: |
          git --version
          node --version
          npm --version
          npx commitlint --version

      - name: Validate current commit (push)
        if: github.event_name == 'push'
        run: npx commitlint --last --verbose

      - name: Validate PR commits
        if: github.event_name == 'pull_request'
        run: |
          npx commitlint \
            --from ${{ github.event.pull_request.base.sha }} \
            --to ${{ github.event.pull_request.head.sha }} \
            --verbose
```

### Minimal Workflow

```yaml
name: Commitlint

on: [push, pull_request]

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
      - run: npm install -D @commitlint/cli @commitlint/config-conventional
      - run: npx commitlint --from HEAD~1 --to HEAD --verbose
        if: github.event_name == 'push'
      - run: npx commitlint --from ${{ github.event.pull_request.base.sha }} --to ${{ github.event.pull_request.head.sha }} --verbose
        if: github.event_name == 'pull_request'
```

### Using Pre-commit Dependencies

If commitlint is already in `package.json`:

```yaml
name: Commitlint

on: [push, pull_request]

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          cache: npm
      - run: npm ci  # Install from package-lock.json
      - run: npx commitlint --last --verbose
        if: github.event_name == 'push'
      - run: npx commitlint --from ${{ github.event.pull_request.base.sha }} --to ${{ github.event.pull_request.head.sha }} --verbose
        if: github.event_name == 'pull_request'
```

### Matrix Strategy

Test against multiple Node versions:

```yaml
name: Commitlint

on: [push, pull_request]

jobs:
  commitlint:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [18, 20, 22]

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm install -D @commitlint/cli @commitlint/config-conventional
      - run: npx commitlint --last --verbose
```

### Using Commitlint Action

There's a community action available:

```yaml
name: Commitlint

on: [push, pull_request]

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: wagoid/commitlint-github-action@v5
```

## GitLab CI

### Basic Configuration

```yaml
lint:commit:
  image: node:alpine
  variables:
    GIT_DEPTH: 0  # Fetch all history
  before_script:
    - apk add --no-cache git
    - npm install --save-dev @commitlint/config-conventional @commitlint/cli
  script:
    - npx commitlint --from ${CI_MERGE_REQUEST_DIFF_BASE_SHA} --to ${CI_COMMIT_SHA}
  only:
    - merge_requests
```

### Using Pre-built Container

```yaml
stages: ["lint", "build", "test"]

lint:commit:
  image:
    name: commitlint/commitlint:latest
    entrypoint: [""]
  stage: lint
  variables:
    GIT_DEPTH: 0
  script:
    - commitlint --from ${CI_MERGE_REQUEST_DIFF_BASE_SHA} --to ${CI_COMMIT_SHA}
  only:
    - merge_requests
```

### With Dependency Caching

```yaml
lint:commit:
  image: node:lts
  variables:
    GIT_DEPTH: 0
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
  before_script:
    - npm ci
  script:
    - npx commitlint --from ${CI_MERGE_REQUEST_DIFF_BASE_SHA} --to ${CI_COMMIT_SHA}
  only:
    - merge_requests
```

### For Monorepos with Nx

```yaml
lint:commit:
  image:
    name: commitlint/commitlint:latest
    entrypoint: [""]
  stage: lint
  variables:
    GIT_DEPTH: 0
  before_script:
    # Install Nx if extending @commitlint/config-nx-scopes
    - npm i -g nx@$(node -pe "require('./package.json').devDependencies.nx")
  script:
    - commitlint --from ${CI_MERGE_REQUEST_DIFF_BASE_SHA} --to ${CI_COMMIT_SHA}
  only:
    - merge_requests
```

## CircleCI

### Basic Configuration

```yaml
version: 2.1

executors:
  node-executor:
    docker:
      - image: cimg/node:current
    working_directory: ~/project

jobs:
  setup:
    executor: node-executor
    steps:
      - checkout
      - restore_cache:
          key: lock-{{ checksum "package-lock.json" }}
      - run:
          name: Install dependencies
          command: npm install
      - save_cache:
          key: lock-{{ checksum "package-lock.json" }}
          paths:
            - node_modules
      - persist_to_workspace:
          root: ~/project
          paths:
            - node_modules

  lint_commit_message:
    executor: node-executor
    steps:
      - checkout
      - attach_workspace:
          at: ~/project
      - run:
          name: Define commit message variable
          command: |
            echo 'export COMMIT_MESSAGE=$(git log -1 --pretty=format:"%s")' >> $BASH_ENV
            source $BASH_ENV
      - run:
          name: Lint commit message
          command: echo "$COMMIT_MESSAGE" | npx commitlint

workflows:
  version: 2.1
  commit:
    jobs:
      - setup
      - lint_commit_message:
          requires:
            - setup
```

### Simplified Configuration

```yaml
version: 2.1

jobs:
  commitlint:
    docker:
      - image: cimg/node:lts
    steps:
      - checkout
      - run: npm install -D @commitlint/cli @commitlint/config-conventional
      - run: npx commitlint --from HEAD~1 --to HEAD --verbose

workflows:
  main:
    jobs:
      - commitlint
```

## Azure Pipelines

### Complete Configuration

```yaml
trigger:
  - main
  - develop

pr:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
  - checkout: self
    fetchDepth: 0  # Fetch all history

  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'
      checkLatest: true
    displayName: 'Install Node.js'

  - script: |
      git --version
      node --version
      npm --version
      npx commitlint --version
    displayName: 'Print versions'

  - script: |
      npm install -D @commitlint/cli @commitlint/config-conventional
    displayName: 'Install commitlint'

  - script: npx commitlint --last --verbose
    condition: ne(variables['Build.Reason'], 'PullRequest')
    displayName: 'Validate current commit (push)'

  - script: |
      echo "Accessing Azure DevOps API..."

      response=$(curl -s -X GET \
        -H "Cache-Control: no-cache" \
        -H "Authorization: Bearer $(System.AccessToken)" \
        "$(System.TeamFoundationCollectionUri)$(System.TeamProject)/_apis/git/repositories/$(Build.Repository.Name)/pullRequests/$(System.PullRequest.PullRequestId)/commits?api-version=6.0")

      numberOfCommits=$(echo "$response" | jq -r '.count')
      echo "$numberOfCommits commits to check"

      npx commitlint \
        --from $(System.PullRequest.SourceCommitId)~${numberOfCommits} \
        --to $(System.PullRequest.SourceCommitId) \
        --verbose
    condition: eq(variables['Build.Reason'], 'PullRequest')
    displayName: 'Validate PR commits'
```

### Minimal Configuration

```yaml
trigger:
  - main

steps:
  - checkout: self
    fetchDepth: 0
  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'
  - script: npm install -D @commitlint/cli @commitlint/config-conventional
  - script: npx commitlint --last --verbose
```

## Travis CI

### Using Travis-specific CLI

```yaml
language: node_js
node_js:
  - lts/*

install:
  - npm install --save-dev @commitlint/travis-cli @commitlint/config-conventional

script:
  - commitlint-travis
```

### Standard Configuration

```yaml
language: node_js
node_js:
  - lts/*

install:
  - npm install -D @commitlint/cli @commitlint/config-conventional

script:
  - npx commitlint --from HEAD~1 --to HEAD --verbose
```

## Bitbucket Pipelines

### PR Validation

```yaml
image: node:18

pipelines:
  pull-requests:
    '**':
      - step:
          name: Lint commit messages
          script:
            - npm install --save-dev @commitlint/config-conventional @commitlint/cli
            - npx commitlint --from $BITBUCKET_COMMIT~$(git rev-list --count $BITBUCKET_BRANCH ^origin/$BITBUCKET_PR_DESTINATION_BRANCH) --to $BITBUCKET_COMMIT --verbose
```

### With Custom Clone Depth

```yaml
image: node:18

clone:
  depth: full  # Fetch all history

pipelines:
  pull-requests:
    '**':
      - step:
          name: Lint commits
          caches:
            - node
          script:
            - npm ci
            - npx commitlint --from $BITBUCKET_COMMIT~$(git rev-list --count $BITBUCKET_BRANCH ^origin/$BITBUCKET_PR_DESTINATION_BRANCH) --to $BITBUCKET_COMMIT --verbose
```

## Jenkins (Declarative Pipeline)

### Jenkinsfile

```groovy
pipeline {
    agent any

    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm install -D @commitlint/cli @commitlint/config-conventional'
            }
        }

        stage('Lint Commits') {
            steps {
                script {
                    if (env.CHANGE_ID) {
                        // Pull request
                        sh """
                            npx commitlint \
                                --from origin/${env.CHANGE_TARGET} \
                                --to HEAD \
                                --verbose
                        """
                    } else {
                        // Push
                        sh 'npx commitlint --last --verbose'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

## Jenkins X (Tekton)

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: pullrequest
spec:
  pipelineSpec:
    tasks:
      - name: conventional-commits
        taskSpec:
          steps:
            - name: lint-commit-messages
              image: commitlint/commitlint
              script: |
                #!/usr/bin/env sh
                . .jx/variables.sh
                commitlint \
                  --extends '@commitlint/config-conventional' \
                  --from $PR_BASE_SHA \
                  --to $PR_HEAD_SHA
  serviceAccountName: tekton-bot
  timeout: 15m
```

## Drone CI

```yaml
kind: pipeline
name: default

steps:
  - name: commitlint
    image: node:lts
    commands:
      - npm install -D @commitlint/cli @commitlint/config-conventional
      - npx commitlint --from HEAD~1 --to HEAD --verbose
```

## Buildkite

```yaml
steps:
  - label: "Lint commits"
    command: |
      npm install -D @commitlint/cli @commitlint/config-conventional
      npx commitlint --last --verbose
    plugins:
      - docker#v3.8.0:
          image: node:lts
```

## Codemagic

```yaml
workflows:
  commitlint:
    name: Lint commit message
    scripts:
      - name: Install commitlint
        script: npm install -D @commitlint/cli @commitlint/config-conventional
      - name: Lint commits
        script: npx commitlint --from=HEAD~1
```

## Pre-commit Framework

Not CI, but useful for local + CI enforcement:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/alessandrojcm/commitlint-pre-commit-hook
    rev: v9.5.0
    hooks:
      - id: commitlint
        stages: [commit-msg]
        additional_dependencies: ['@commitlint/config-conventional']
```

## Docker Container Approach

Use the official commitlint Docker image:

```bash
docker run --rm -v $(pwd):/app \
  commitlint/commitlint:latest \
  --from HEAD~1 --to HEAD --verbose
```

In CI:

```yaml
# Generic Docker-based CI
steps:
  - name: Lint commits
    image: commitlint/commitlint:latest
    commands:
      - commitlint --from HEAD~1 --to HEAD --verbose
```

## Best Practices for CI

### 1. Fail Fast

Place commitlint as an early step in the pipeline to fail quickly:

```yaml
jobs:
  - lint  # Run first
  - build
  - test
  - deploy
```

### 2. Cache Dependencies

```yaml
# GitHub Actions
- uses: actions/setup-node@v4
  with:
    cache: npm

# GitLab CI
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/
```

### 3. Use Verbose Output

Always use `--verbose` in CI for better debugging:

```bash
npx commitlint --last --verbose
```

### 4. Check Configuration

Add a step to validate configuration before linting:

```bash
npx commitlint --print-config
```

### 5. Conditional Execution

Skip commitlint for:
- Automated commits (bots, release automation)
- Merge commits (if using default ignores)
- Specific branches (e.g., `dependabot/*`)

```yaml
# GitHub Actions
- name: Lint commits
  if: github.actor != 'dependabot[bot]'
  run: npx commitlint --last --verbose
```

### 6. Informative Error Messages

Configure custom help URL:

```javascript
// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  helpUrl: 'https://github.com/yourorg/yourrepo/blob/main/CONTRIBUTING.md#commit-messages'
};
```

### 7. Handle Merge Commits

Default ignores handle merge commits, but ensure they're enabled:

```javascript
export default {
  extends: ['@commitlint/config-conventional'],
  defaultIgnores: true  // Keep merge commit ignores
};
```

## Troubleshooting CI Integration

### Issue: Shallow Clone Errors

**Error:** `fatal: needed a single revision`

**Fix:** Set fetch-depth to 0 or full:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

### Issue: Missing Commits in PR

**Error:** Cannot validate commit range

**Fix:** Ensure base and head SHAs are correct:

```bash
# Debug: Print commit range
git log --oneline ${BASE_SHA}..${HEAD_SHA}
```

### Issue: Configuration Not Found

**Error:** `Please add rules to your commitlint.config.js`

**Fix:** Ensure config file is committed and in the right location:

```bash
ls -la commitlint.config.js
```

### Issue: Node Version Incompatibility

**Error:** Module format errors

**Fix:** Use LTS Node version:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: lts/*
```

### Issue: Permission Errors

**Error:** Cannot read git history

**Fix:** Ensure proper permissions:

```yaml
permissions:
  contents: read
```

## Performance Optimization

### Parallel Execution

Run commitlint in parallel with other lint jobs:

```yaml
jobs:
  lint:
    strategy:
      matrix:
        task: [commitlint, eslint, prettier]
    steps:
      - run: npm run ${{ matrix.task }}
```

### Skip on Draft PRs

```yaml
- name: Lint commits
  if: github.event.pull_request.draft == false
  run: npx commitlint --last --verbose
```

### Use Cached Dependencies

```yaml
- run: npm ci  # Faster than npm install
```
