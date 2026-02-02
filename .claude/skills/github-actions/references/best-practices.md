# GitHub Actions Best Practices

Security, performance, and maintainability patterns.

## Security

**Pin action versions to specific releases:**
```yaml
- uses: actions/checkout@v4         # ✅ Specific version
- uses: actions/checkout@main        # ❌ Mutable branch
```

**Limit GitHub token permissions:**
```yaml
permissions:
  contents: read
  pull-requests: write
```

**Protect secrets - never log them:**
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}
```

**Be careful with pull_request_target** - runs with write permissions.

## Performance

**Cache dependencies:**
```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'npm'
```

**Cancel outdated runs:**
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

**Parallelize jobs** - jobs run in parallel by default unless `needs:` is specified.

## Maintainability

**Use descriptive names:**
```yaml
- name: Install dependencies
  run: npm ci
```

**Extract reusable workflows** for shared patterns across repos.

**Document non-obvious logic** with YAML comments.

See full documentation in this file for comprehensive best practices including conditional execution, artifacts, testing, monitoring, and resource limits.
