# Dependabot Configuration Options Reference

Complete reference for all configuration options available in `dependabot.yml`.

## File Structure

The `dependabot.yml` file must be located at `.github/dependabot.yml` in the repository.

### Required Keys

Every `dependabot.yml` file must include:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
```

**Required fields:**
- `version`: Always `2` (current configuration syntax version)
- `updates`: Array of update configurations
- `package-ecosystem`: Package manager to monitor (see ecosystem reference)
- `directory`: Location of manifest files
- `schedule.interval`: Update frequency (`daily`, `weekly`, or `monthly`)

## Common Configuration Options

### `allow` / `ignore`

Control which dependencies Dependabot updates.

**Default behavior:**
- Version updates: All explicitly defined dependencies
- Security updates: All dependencies with vulnerabilities

**Allow specific dependencies:**

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      - dependency-name: "react*"
      - dependency-name: "@types/*"
      - dependency-type: "production"
```

**Ignore dependencies or versions:**

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    ignore:
      - dependency-name: "eslint"
        versions: ["5.x", "6.x"]
      - dependency-name: "typescript"
        update-types: ["version-update:semver-major"]
```

**Dependency types:**
- `direct`: Explicitly defined dependencies
- `indirect`: Sub-dependencies (transitive dependencies)
- `all`: All dependencies including transitive
- `production`: Production dependencies only
- `development`: Development dependencies only

**Update types for ignore:**
- `version-update:semver-major`: Major version updates
- `version-update:semver-minor`: Minor version updates
- `version-update:semver-patch`: Patch version updates

### `assignees` and `reviewers`

Assign team members to pull requests.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    assignees:
      - "octocat"
    reviewers:
      - "my-org/security-team"
      - "octocat"
```

**Requirements:**
- Assignees must have write access
- Reviewers can have read access
- Team reviewers use `org-name/team-name` format
- Maximum 10 assignees and 10 reviewers combined

### `commit-message`

Customize commit messages for Dependabot PRs.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "npm"
      prefix-development: "npm dev"
      include: "scope"
```

**Options:**
- `prefix`: Prefix for all commits (e.g., "npm: ")
- `prefix-development`: Prefix for development dependencies
- `include`: Set to `"scope"` to include scope in conventional commits

**Example output:**
```
npm: update react to 18.2.0
npm dev: update eslint to 8.0.0 (scope)
```

### `labels`

Apply custom labels to pull requests.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "npm"
```

**Default labels:**
- Version updates: `dependencies` + ecosystem label
- Security updates: `security`

Labels are created automatically if they don't exist.

### `milestone`

Add pull requests to a milestone.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    milestone: 4
```

Use the milestone number (visible in milestone URL).

### `open-pull-requests-limit`

Control maximum open PRs per ecosystem.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

**Default:** 5
**Range:** 0-10 (0 disables version updates but keeps security updates)

### `pull-request-branch-name.separator`

Customize branch name separator.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    pull-request-branch-name:
      separator: "-"
```

**Options:** `/` or `-`
**Default:** `/`

**Branch name format:** `dependabot/npm/react-18.2.0`

### `rebase-strategy`

Control when Dependabot rebases PRs.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    rebase-strategy: "disabled"
```

**Options:**
- `auto`: Rebase when changes detected (default)
- `disabled`: Never rebase automatically

Use `@dependabot rebase` comment to manually trigger.

### `schedule`

Configure when Dependabot checks for updates.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "05:00"
      timezone: "America/Los_Angeles"
```

**Required:**
- `interval`: `daily`, `weekly`, or `monthly`

**Optional:**
- `day`: Day of week for `weekly` (monday-sunday)
- `time`: Time in HH:MM format (24-hour)
- `timezone`: IANA timezone name

**Examples:**
```yaml
# Daily at 5 AM UTC
schedule:
  interval: "daily"
  time: "05:00"

# Weekly on Monday
schedule:
  interval: "weekly"
  day: "monday"

# Monthly on the 1st
schedule:
  interval: "monthly"
```

### `target-branch`

Update dependencies on a non-default branch.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    target-branch: "develop"
```

**Note:** Security updates ignore this and target the default branch.

### `versioning-strategy`

Control version requirement updates in manifest files.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    versioning-strategy: "increase"
```

**Options:**
- `auto`: Default behavior (varies by ecosystem)
- `increase`: Always increase version requirement
- `increase-if-necessary`: Only update if current range doesn't include new version
- `lockfile-only`: Update lockfile only, never touch manifest
- `widen`: Widen range to include both old and new versions

**Ecosystem defaults:**

| Ecosystem | Default Strategy |
|-----------|-----------------|
| npm, yarn | lockfile-only |
| bundler, composer, pip | increase |
| cargo, gomod | lockfile-only |
| maven, gradle | increase |

## Advanced Configuration

### `groups`

Group related dependencies into single PRs.

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      react-ecosystem:
        patterns:
          - "react*"
          - "@types/react*"
      dev-dependencies:
        dependency-type: "development"
        update-types:
          - "minor"
          - "patch"
```

**Group options:**
- `patterns`: Array of dependency name patterns
- `dependency-type`: Filter by dependency type
- `update-types`: Filter by update type (major, minor, patch)
- `exclude-patterns`: Exclude specific patterns from group

### `insecure-external-code-execution`

Allow or deny code execution during updates.

```yaml
updates:
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
    insecure-external-code-execution: "allow"
```

**Options:**
- `allow`: Execute code during updates (required for some ecosystems)
- `deny`: Never execute external code (default, more secure)

**Required for:**
- Bundler (runs Ruby code in gemspecs)
- Mix (runs Elixir code)

### `registries`

Configure access to private package registries.

```yaml
version: 2
registries:
  npm-github:
    type: npm-registry
    url: https://npm.pkg.github.com
    token: ${{secrets.DEPENDABOT_NPM_TOKEN}}

  docker-private:
    type: docker-registry
    url: registry.example.com
    username: octocat
    password: ${{secrets.DOCKER_PASSWORD}}

updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - npm-github

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - docker-private
```

**Registry types:**
- `composer-repository`
- `docker-registry`
- `git`
- `hex-organization`
- `hex-repository`
- `maven-repository`
- `npm-registry`
- `nuget-feed`
- `python-index`
- `rubygems-server`
- `terraform-registry`

**Authentication:**
- Use `${{secrets.SECRET_NAME}}` to reference encrypted secrets
- Configure secrets in repository settings

## Multiple Ecosystems

Monitor multiple package managers in a single repository.

```yaml
version: 2
updates:
  # Frontend dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "frontend"

  # Backend dependencies
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "backend"

  # Docker images
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
      - "docker"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "ci"
```

## Best Practices

### Security Configuration

```yaml
updates:
  # Aggressive security updates
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    open-pull-requests-limit: 10
    labels:
      - "security"
      - "priority-high"
```

### Monorepo Configuration

```yaml
updates:
  # Root workspace
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"

  # Frontend package
  - package-ecosystem: "npm"
    directory: "/packages/frontend"
    schedule:
      interval: "weekly"

  # Backend package
  - package-ecosystem: "npm"
    directory: "/packages/backend"
    schedule:
      interval: "weekly"
```

### Grouped Updates

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      # Major updates separately
      major-updates:
        update-types:
          - "major"

      # Minor and patch together
      minor-and-patch:
        update-types:
          - "minor"
          - "patch"
```

### Selective Updates

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    # Only update specific dependencies
    allow:
      - dependency-name: "react"
      - dependency-name: "react-dom"
    # Ignore major version bumps for others
    ignore:
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]
```

## Common Patterns

### Pattern: Production-Only Updates

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      - dependency-type: "production"
```

### Pattern: Separate Dev and Prod

```yaml
updates:
  # Production dependencies - weekly
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      - dependency-type: "production"
    labels:
      - "dependencies"
      - "production"

  # Development dependencies - monthly
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "monthly"
    allow:
      - dependency-type: "development"
    labels:
      - "dependencies"
      - "development"
```

### Pattern: Scoped Packages

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      # Only update our organization's packages
      - dependency-name: "@myorg/*"
```

### Pattern: Exclude Pre-releases

```yaml
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    ignore:
      # Ignore all pre-release versions
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]
        versions: [">= 0.a", "< 1"]
```

## Troubleshooting

### Configuration Not Working

1. Verify file location is `.github/dependabot.yml`
2. Validate YAML syntax (no tabs, proper indentation)
3. Check required fields are present
4. Ensure package ecosystem is supported
5. Verify directory path matches manifest location

### No Pull Requests Created

**Possible causes:**
- `open-pull-requests-limit` reached
- All dependencies already up to date
- Dependencies ignored via `ignore` configuration
- Dependency not matched by `allow` configuration
- Schedule hasn't run yet

**Check:**
- View Dependabot logs in Security tab
- Verify schedule configuration
- Check ignore/allow rules

### Too Many Pull Requests

**Solutions:**
- Reduce `open-pull-requests-limit`
- Use `groups` to combine related updates
- Increase `schedule.interval` to weekly or monthly
- Add specific dependencies to `ignore`

### Authentication Failures

**Solutions:**
- Verify secrets are configured correctly
- Check registry URLs are correct
- Ensure tokens have required permissions
- Use `${{secrets.NAME}}` syntax for secrets
