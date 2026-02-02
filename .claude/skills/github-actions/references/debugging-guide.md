# GitHub Actions Debugging Guide

Troubleshooting workflows and common issues.

## Enable Debug Logging

Add repository secret `ACTIONS_STEP_DEBUG=true` for verbose logs.

## Common Errors

**Syntax errors** - Validate YAML with online tools.

**Permission denied** - Add `permissions:` block.

**Secret not found** - Check Settings → Secrets, verify exact name.

**Workflow not triggering** - Check file location (`.github/workflows/`), syntax, and event triggers.

**Cache not restoring** - Verify cache key matches, check 7-day expiration.

## Debugging Techniques

```yaml
# Inspect environment
- run: env | sort

# Debug contexts
- run: echo '${{ toJSON(github) }}'

# Upload files for inspection
- uses: actions/upload-artifact@v4
  if: always()
  with:
    path: logs/**
```

## Expression Debugging

```yaml
# Full ref path required
if: github.ref == 'refs/heads/main'  # ✅
if: github.ref == 'main'              # ❌
```

## Local Testing

Use [act](https://github.com/nektos/act) to run workflows locally:
```bash
act push
act pull_request
```

See full documentation in this file for complete debugging guide including timeout issues, rate limiting, matrix builds, and the Workflow Run API.
