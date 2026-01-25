# Secrets and Security

Managing secrets and securing GitHub Actions workflows.

## Secret Types

| Type | Scope | Syntax |
|------|-------|--------|
| Repository secrets | Single repository | `secrets.NAME` |
| Environment secrets | Environment | `secrets.NAME` |
| Organization secrets | All repos in org | `secrets.NAME` |
| Configuration variables | Non-sensitive data | `vars.NAME` |

## Repository Secrets

### Creating Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add name and value

### Using Secrets

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.MY_SECRET }}
        run: |
          curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

## Environment Secrets

### Environment-Specific Secrets

```yaml
jobs:
  deploy-production:
    environment: production
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.PRODUCTION_API_KEY }}
        run: deploy.sh
```

### Environment Protection

Configure in repository Settings → Environments:

- **Required reviewers**: Require approval
- **Wait timer**: Delay deployment
- **Deployment branches**: Restrict which branches

## Secrets in Reusable Workflows

### Passing Secrets Explicitly

```yaml
# Caller
jobs:
  call-workflow:
    uses: ./.github/workflows/deploy.yml
    secrets:
      api-key: ${{ secrets.MY_API_KEY }}

# Reusable workflow
on:
  workflow_call:
    secrets:
      api-key:
        required: true
```

### Inheriting All Secrets

```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/deploy.yml
    secrets: inherit  # Pass all accessible secrets
```

## Secret Masking

GitHub Actions automatically masks secrets in logs.

### Manual Masking

Mask dynamically generated values:

```yaml
steps:
  - name: Generate secret
    run: |
      SECRET=$(openssl rand -hex 32)
      echo "::add-mask::$SECRET"
      echo "Secret is $SECRET"  # Now masked
```

### Masking Multi-Line Secrets

```yaml
steps:
  - name: Mask multi-line
    run: |
      SECRET="line1
      line2
      line3"
      while IFS= read -r line; do
        echo "::add-mask::$line"
      done <<< "$SECRET"
```

## GITHUB_TOKEN

Each workflow has a `GITHUB_TOKEN` with scoped permissions.

### Setting Permissions

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      issues: write
    steps:
      - run: gh issue create --title "Test"
```

### Permission Scopes

| Scope | Description |
|-------|-------------|
| `contents` | Repository contents |
| `issues` | Issues |
| `pull-requests` | Pull requests |
| `packages` | Packages |
| `deployments` | Deployments |
| `actions` | Actions |
| `checks` | Checks |

## Third-Party Authentication

### Using OIDC

OpenID Connect avoids storing long-lived credentials:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions
          aws-region: us-east-1

      - name: Deploy
        run: aws s3 sync ./dist s3://my-bucket
```

### Azure Service Principal

```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Google Cloud

```yaml
- uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_CREDENTIALS }}

- uses: google-github-actions/setup-gcloud@v2
```

## Security Best Practices

### ✅ Do

```yaml
# Use secrets for sensitive data
env:
  API_KEY: ${{ secrets.API_KEY }}

# Mask before use
- run: |
    echo "::add-mask::${{ secrets.API_KEY }}"
    curl -H "Authorization: Bearer ${{ secrets.API_KEY }}" https://api.example.com

# Use environment-specific secrets
environment: production

# Minimize permissions
permissions:
  contents: read
```

### ❌ Don't

```yaml
# Never echo secrets
- run: echo "${{ secrets.MY_SECRET }}"

# Never put secrets in workflows
# ❌ api-key: sk-1234567890

# Never commit .env with secrets

# Never log secret values
- run: echo "Key: $API_KEY"  # Will be in logs
```

## Security Checklist

- [ ] Use secrets for all sensitive data
- [ ] Never log secret values
- [ ] Mask dynamically generated secrets
- [ ] Use environment-specific secrets
- [ ] Minimize `GITHUB_TOKEN` permissions
- [ ] Use OIDC for third-party auth
- [ ] Enable secret scanning
- [ ] Review workflow permissions
- [ ] Use environment protection rules
- [ ] Rotate secrets regularly
