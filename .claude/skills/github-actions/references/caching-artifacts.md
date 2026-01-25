# Caching and Artifacts

Optimize workflows with caching and share data between jobs.

## Caching Dependencies

### Basic Cache

```yaml
steps:
  - name: Cache node modules
    uses: actions/cache@v4
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      restore-keys: |
        ${{ runner.os }}-node-
```

### Cache Parameters

| Parameter | Description |
|-----------|-------------|
| `path` | Path(s) to cache (required) |
| `key` | Unique cache key (required) |
| `restore-keys` | Fallback keys for partial match |
| `enableCrossOsArchive` | Allow cross-OS restore |

### Language-Specific Caching

#### Node.js (npm)

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

#### Node.js (yarn)

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.yarn/cache
      ~/.yarn/unplugged
    key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
```

#### Node.js (pnpm)

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.pnpm-store
    key: ${{ runner.os }}-pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
```

#### Python (pip)

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

#### Go

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/go-build
      ~/go/pkg/mod
    key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
```

#### Rust (cargo)

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/registry
      ~/.cargo/git
      target
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
```

#### Java (Gradle)

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*') }}
```

#### Java (Maven)

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
```

### Cache Hit Output

```yaml
- name: Cache dependencies
  id: cache
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

- name: Install dependencies
  if: steps.cache.outputs.cache-hit != 'true'
  run: npm ci
```

### Multiple Cache Paths

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      ~/.cache/solargraph
      .next/cache
    key: ${{ runner.os }}-multi-${{ hashFiles('**/package-lock.json') }}
```

## Artifacts

### Upload Artifacts

```yaml
- name: Upload build
  uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 30
    compression-level: 9
```

### Download Artifacts

```yaml
# Download specific artifact
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./dist

# Download all artifacts
- uses: actions/download-artifact@v4
  with:
    path: ./artifacts
```

### Share Between Jobs

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: ./dist
      - run: ./deploy.sh
```

### Multiple Paths and Patterns

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: project-files
    path: |
      dist/
      docs/
      **/*.md
```

## Cache vs Artifacts

| Feature | Cache | Artifacts |
|---------|-------|-----------|
| Purpose | Speed up workflows | Share data between jobs |
| Lifetime | 7 days with activity | Up to 90 days |
| Scope | Repository | Workflow run |
| Key required | Yes | No |

## Best Practices

1. **Version cache keys**: `v1-${{ runner.os }}-node-`
2. **Hash lockfiles**: `${{ hashFiles('**/package-lock.json') }}`
3. **Use restore-keys**: Provide fallback keys
4. **Cache before install**: Set up cache before running `npm ci`
5. **Set retention**: Use appropriate `retention-days` for artifacts

## Cache Size Limits

| Plan | Cache size |
|------|------------|
| Free | 10 GB |
| Pro | 10 GB |
| Enterprise | 10 GB per repository |
