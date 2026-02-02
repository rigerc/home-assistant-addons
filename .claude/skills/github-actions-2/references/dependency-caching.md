# Dependency Caching Guide

## Overview

Dependency caching dramatically reduces workflow execution time by storing and reusing downloaded packages and compiled artifacts. This guide covers effective caching strategies for all major package managers and build systems.

## Cache Action Basics

### How Caching Works

The cache action follows this sequence:

1. Calculate cache key from your specified inputs
2. Search for exact key match
3. If no exact match, search for partial key matches
4. If no match, search through restore-keys
5. Restore matched cache to specified path
6. If job completes successfully, save new cache with your key

### Cache Key Matching

**Exact Match (Cache Hit)**
- Cache key exactly matches an existing cache
- Cached files restored to specified path
- No new cache created

**Partial Match (Cache Miss)**
- No exact match found
- Searches for keys with matching prefixes
- Most recent partial match restored
- New cache created with exact key upon job success

### Cache Action Parameters

#### Required Parameters

**key** - Unique identifier for the cache:

```yaml
key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

- Maximum length: 512 characters
- Can include contexts, functions, literals
- Should change when dependencies change
- Typically includes OS and content hash

**path** - Files or directories to cache:

```yaml
# Single path
path: ~/.npm

# Multiple paths
path: |
  ~/.npm
  ~/.cache

# Glob patterns supported
path: |
  **/node_modules
  !**/node_modules/exclude-this
```

Supports:
- Single files or directories
- Multiple paths on separate lines
- Glob patterns
- Absolute or relative paths (relative to workspace)

#### Optional Parameters

**restore-keys** - Fallback cache keys:

```yaml
restore-keys: |
  ${{ runner.os }}-npm-
  ${{ runner.os }}-
```

Searches restore-keys sequentially if no exact match found. Each key can match by prefix.

**enableCrossOsArchive** - Cross-platform caching:

```yaml
enableCrossOsArchive: true
```

Allows Windows runners to restore caches from Linux/macOS and vice versa. Defaults to `false`.

### Cache Action Outputs

**cache-hit** - Boolean indicating exact match:

```yaml
steps:
  - uses: actions/cache@v3
    id: npm-cache
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}

  - name: Install if cache miss
    if: steps.npm-cache.outputs.cache-hit != 'true'
    run: npm ci
```

Use this output to skip installation steps when cache hits.

## Cache Key Strategies

### Content-Based Keys

Generate keys from file contents using `hashFiles()`:

```yaml
# NPM - based on package-lock.json
key: npm-${{ hashFiles('**/package-lock.json') }}

# Python - based on requirements.txt
key: pip-${{ hashFiles('**/requirements.txt') }}

# Go - based on go.sum
key: go-${{ hashFiles('**/go.sum') }}
```

Cache automatically updates when dependency files change.

### Multi-Factor Keys

Include multiple factors for precise cache invalidation:

```yaml
key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('**/package.json') }}
```

Cache updates when:
- Operating system changes
- Package lock changes
- Package.json changes (version updates, script changes)

### Versioned Keys

Include version identifiers for manual cache invalidation:

```yaml
env:
  CACHE_VERSION: v1

steps:
  - uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ env.CACHE_VERSION }}-${{ hashFiles('**/package-lock.json') }}
```

Increment `CACHE_VERSION` to force cache refresh across all workflows.

### Branch-Specific Keys

Create separate caches per branch:

```yaml
key: ${{ runner.os }}-${{ github.ref }}-npm-${{ hashFiles('**/package-lock.json') }}
```

Useful when different branches have significantly different dependencies.

### Restore Key Hierarchy

Design fallback strategy from specific to general:

```yaml
key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
restore-keys: |
  ${{ runner.os }}-npm-
  ${{ runner.os }}-
```

Search order:
1. Exact match: `linux-npm-abc123`
2. Partial match: `linux-npm-*` (most recent)
3. Broader match: `linux-*` (most recent)

## Package Manager Caching

### NPM

#### Using setup-node with Built-in Caching

Simplest approach using setup-node:

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-node@v4
    with:
      node-version: 20
      cache: 'npm'

  - run: npm ci
  - run: npm test
```

Setup-node automatically:
- Detects package-lock.json
- Generates appropriate cache key
- Caches `~/.npm` directory

#### Manual NPM Caching

For advanced control:

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Cache npm dependencies
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-npm-

  - uses: actions/setup-node@v4
    with:
      node-version: 20

  - run: npm ci
```

#### Caching node_modules

Cache installed packages directly:

```yaml
steps:
  - uses: actions/cache@v3
    id: cache-node-modules
    with:
      path: node_modules
      key: ${{ runner.os }}-node-modules-${{ hashFiles('**/package-lock.json') }}

  - name: Install dependencies
    if: steps.cache-node-modules.outputs.cache-hit != 'true'
    run: npm ci
```

Faster than caching `~/.npm` but larger cache size.

### Yarn

#### Yarn v1

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-node@v4
    with:
      node-version: 20
      cache: 'yarn'

  - run: yarn install --frozen-lockfile
```

Manual caching:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.cache/yarn
      key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
      restore-keys: |
        ${{ runner.os }}-yarn-

  - run: yarn install --frozen-lockfile
```

#### Yarn v2+ (Berry)

```yaml
steps:
  - uses: actions/setup-node@v4
    with:
      node-version: 20
      cache: 'yarn'

  - name: Cache Yarn packages
    uses: actions/cache@v3
    with:
      path: .yarn/cache
      key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}

  - run: yarn install --immutable
```

### pnpm

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: pnpm/action-setup@v2
    with:
      version: 8

  - uses: actions/setup-node@v4
    with:
      node-version: 20
      cache: 'pnpm'

  - run: pnpm install --frozen-lockfile
```

Manual caching:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.pnpm-store
      key: ${{ runner.os }}-pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
      restore-keys: |
        ${{ runner.os }}-pnpm-

  - run: pnpm install --frozen-lockfile
```

### Python (pip)

#### Using setup-python with Built-in Caching

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-python@v5
    with:
      python-version: '3.11'
      cache: 'pip'

  - run: pip install -r requirements.txt
```

#### Manual pip Caching

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.cache/pip
      key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
      restore-keys: |
        ${{ runner.os }}-pip-

  - run: pip install -r requirements.txt
```

#### Multiple Requirements Files

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.cache/pip
      key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt') }}
      restore-keys: |
        ${{ runner.os }}-pip-
```

### Python (pipenv)

```yaml
steps:
  - uses: actions/setup-python@v5
    with:
      python-version: '3.11'
      cache: 'pipenv'

  - run: pipenv install
```

Manual caching:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.cache/pipenv
      key: ${{ runner.os }}-pipenv-${{ hashFiles('**/Pipfile.lock') }}

  - run: pipenv install
```

### Python (Poetry)

```yaml
steps:
  - uses: actions/setup-python@v5
    with:
      python-version: '3.11'
      cache: 'poetry'

  - run: poetry install
```

Manual caching:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.cache/pypoetry
      key: ${{ runner.os }}-poetry-${{ hashFiles('**/poetry.lock') }}

  - run: poetry install
```

### Java (Maven)

#### Using setup-java with Built-in Caching

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-java@v4
    with:
      java-version: '17'
      distribution: 'temurin'
      cache: 'maven'

  - run: mvn package
```

#### Manual Maven Caching

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.m2/repository
      key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
      restore-keys: |
        ${{ runner.os }}-maven-

  - run: mvn package
```

### Java (Gradle)

#### Using setup-java with Built-in Caching

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-java@v4
    with:
      java-version: '17'
      distribution: 'temurin'
      cache: 'gradle'

  - run: ./gradlew build
```

#### Manual Gradle Caching

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: |
        ~/.gradle/caches
        ~/.gradle/wrapper
      key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
      restore-keys: |
        ${{ runner.os }}-gradle-

  - run: ./gradlew build
```

### Ruby (Bundler)

#### Using setup-ruby with Built-in Caching

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: ruby/setup-ruby@v1
    with:
      ruby-version: '3.2'
      bundler-cache: true

  - run: bundle exec rake
```

#### Manual Bundler Caching

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: vendor/bundle
      key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
      restore-keys: |
        ${{ runner.os }}-gems-

  - run: |
      bundle config path vendor/bundle
      bundle install --jobs 4 --retry 3
```

### Go

#### Using setup-go with Built-in Caching

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-go@v5
    with:
      go-version: '1.21'
      cache: true

  - run: go build
```

#### Manual Go Caching

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: |
        ~/go/pkg/mod
        ~/.cache/go-build
      key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
      restore-keys: |
        ${{ runner.os }}-go-

  - run: go build
```

### Rust (Cargo)

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Cache cargo registry
    uses: actions/cache@v3
    with:
      path: ~/.cargo/registry
      key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}

  - name: Cache cargo index
    uses: actions/cache@v3
    with:
      path: ~/.cargo/git
      key: ${{ runner.os }}-cargo-git-${{ hashFiles('**/Cargo.lock') }}

  - name: Cache cargo build
    uses: actions/cache@v3
    with:
      path: target
      key: ${{ runner.os }}-cargo-build-${{ hashFiles('**/Cargo.lock') }}

  - run: cargo build --release
```

### PHP (Composer)

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Get Composer cache directory
    id: composer-cache
    run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT

  - uses: actions/cache@v3
    with:
      path: ${{ steps.composer-cache.outputs.dir }}
      key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
      restore-keys: |
        ${{ runner.os }}-composer-

  - run: composer install --prefer-dist
```

### .NET (NuGet)

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: actions/setup-dotnet@v4
    with:
      dotnet-version: '8.0.x'
      cache: true
      cache-dependency-path: '**/packages.lock.json'

  - run: dotnet restore
  - run: dotnet build
```

Manual caching:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: ~/.nuget/packages
      key: ${{ runner.os }}-nuget-${{ hashFiles('**/packages.lock.json') }}
      restore-keys: |
        ${{ runner.os }}-nuget-

  - run: dotnet restore
```

## Build Output Caching

### Compiled Artifacts

Cache build outputs to skip recompilation:

```yaml
steps:
  - uses: actions/cache@v3
    id: cache-build
    with:
      path: dist/
      key: build-${{ runner.os }}-${{ hashFiles('src/**') }}

  - name: Build application
    if: steps.cache-build.outputs.cache-hit != 'true'
    run: npm run build
```

### Docker Layers

Cache Docker build layers:

```yaml
steps:
  - uses: actions/checkout@v4

  - uses: docker/setup-buildx-action@v3

  - uses: actions/cache@v3
    with:
      path: /tmp/.buildx-cache
      key: ${{ runner.os }}-buildx-${{ github.sha }}
      restore-keys: |
        ${{ runner.os }}-buildx-

  - uses: docker/build-push-action@v5
    with:
      context: .
      cache-from: type=local,src=/tmp/.buildx-cache
      cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max

  - name: Move cache
    run: |
      rm -rf /tmp/.buildx-cache
      mv /tmp/.buildx-cache-new /tmp/.buildx-cache
```

### Test Results

Cache test results for incremental testing:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: .jest-cache
      key: jest-${{ runner.os }}-${{ hashFiles('**/jest.config.js') }}

  - run: npm test -- --cacheDirectory=.jest-cache
```

## Cache Management

### Cache Limits and Eviction

**Storage Limits:**
- Default: 10 GB per repository
- Configurable up to 10 TB for user repositories
- No limit on number of caches

**Eviction Policy:**
- Caches not accessed for 7 days are deleted
- When limit exceeded, least recently used caches deleted
- Upload limit: 200 uploads per minute per repository

### Monitoring Cache Usage

View cache usage in repository:
1. Actions tab
2. Management section
3. Caches

Shows:
- Cache keys
- Creation time
- Last accessed
- Size
- Branch

### Cache Invalidation

#### Automatic Invalidation

Caches automatically invalidate when:
- Cache key changes (dependency files updated)
- 7 days pass without access
- Cache limit exceeded and evicted

#### Manual Invalidation

Force cache refresh by changing cache key:

```yaml
# Increment version in cache key
env:
  CACHE_VERSION: v2  # Changed from v1

steps:
  - uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ env.CACHE_VERSION }}-${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

Or delete caches manually via UI or API:

```bash
# Using GitHub CLI
gh api \
  --method DELETE \
  -H "Accept: application/vnd.github+json" \
  /repos/OWNER/REPO/actions/caches/CACHE_ID
```

### Cache Access Restrictions

**Branch Scoping:**
- Workflow on branch can access:
  - Caches created in current branch
  - Caches from default branch (main)
  - Caches from base branch (for PRs)

**Pull Request Behavior:**
- PR workflows create caches scoped to merge ref
- Limited to PR re-runs only
- Cannot be accessed by base branch
- Prevents cache pollution from fork PRs

**Cross-Repository:**
- Caches are repository-scoped
- Cannot share caches between repositories

## Advanced Caching Patterns

### Conditional Caching

Cache only when beneficial:

```yaml
steps:
  - name: Cache dependencies
    if: github.event_name != 'schedule'  # Skip for scheduled runs
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

### Multi-Stage Caching

Separate caches for different stages:

```yaml
jobs:
  build:
    steps:
      # Cache dependencies
      - uses: actions/cache@v3
        with:
          path: ~/.npm
          key: deps-${{ hashFiles('**/package-lock.json') }}

      - run: npm ci

      # Cache build output
      - uses: actions/cache@v3
        with:
          path: dist/
          key: build-${{ github.sha }}

      - run: npm run build

  test:
    needs: build
    steps:
      # Restore build output
      - uses: actions/cache@v3
        with:
          path: dist/
          key: build-${{ github.sha }}

      - run: npm test
```

### Composite Caching

Cache multiple related items together:

```yaml
steps:
  - uses: actions/cache@v3
    with:
      path: |
        ~/.npm
        ~/.cache
        node_modules
        dist
      key: composite-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('src/**') }}
```

### Fallback Caching

Implement fallback strategies:

```yaml
steps:
  - name: Restore production cache
    id: prod-cache
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: prod-${{ hashFiles('**/package-lock.json') }}

  - name: Restore development cache
    if: steps.prod-cache.outputs.cache-hit != 'true'
    uses: actions/cache@v3
    with:
      path: ~/.npm
      key: dev-${{ hashFiles('**/package-lock.json') }}

  - name: Install from scratch
    if: steps.prod-cache.outputs.cache-hit != 'true'
    run: npm ci
```

## Troubleshooting

### Cache Not Restoring

**Check cache key:**
- Verify key syntax is valid
- Ensure `hashFiles()` pattern matches files
- Check if cache exists in repository

**Verify paths:**
- Confirm paths exist after dependency installation
- Check for typos in path configuration
- Verify glob patterns match intended files

**Review restore-keys:**
- Ensure restore-keys have valid prefixes
- Check ordering (most specific to general)

### Cache Too Large

**Optimize cached content:**
```yaml
# Bad: Caching entire home directory
path: ~/

# Good: Specific cache directories
path: |
  ~/.npm
  ~/.cache
```

**Exclude unnecessary files:**
```yaml
path: |
  node_modules
  !node_modules/.cache
```

**Use compression:**
- Cache action automatically compresses
- Exclude pre-compressed files (images, videos)

### Cache Thrashing

Occurs when caches are created and deleted rapidly.

**Solutions:**

Increase cache size (if available):
1. Repository Settings > Actions
2. Configure cache settings
3. Increase storage limit

Reduce cache creation:
```yaml
# Only cache on main branch
- uses: actions/cache@v3
  if: github.ref == 'refs/heads/main'
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

### Slow Cache Operations

**Reduce cache size:**
- Cache only essential directories
- Exclude large unnecessary files
- Use more specific paths

**Optimize cache keys:**
- Avoid overly specific keys that rarely hit
- Balance between hit rate and precision

**Consider parallel caching:**
```yaml
# Separate caches for faster parallel operations
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: npm-${{ hashFiles('package-lock.json') }}

- uses: actions/cache@v3
  with:
    path: dist/
    key: build-${{ github.sha }}
```

## Best Practices Summary

1. **Use setup-* actions when available** - Built-in caching is optimized and maintained

2. **Include OS in cache key** - Prevents cross-platform cache conflicts

3. **Hash dependency files** - Automatic cache invalidation on dependency changes

4. **Provide restore-keys** - Improves cache hit rate with fallbacks

5. **Cache appropriate paths** - Cache directories, not arbitrary file trees

6. **Monitor cache size** - Stay under limits to avoid eviction

7. **Version cache keys** - Enable manual cache invalidation when needed

8. **Test cache effectiveness** - Measure time savings vs cache overhead

9. **Document cache strategy** - Explain cache keys and restore-keys logic

10. **Clean up old caches** - Remove unused caches to free space
