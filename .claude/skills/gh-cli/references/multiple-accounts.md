# Using Multiple Accounts with GitHub CLI

Manage authentication across multiple GitHub accounts and platforms with GitHub CLI.

## Authentication Scenarios

Two distinct scenarios exist for multiple accounts:

1. **Same platform, multiple accounts** - Multiple accounts on GitHub.com or a single GitHub Enterprise instance
2. **Different platforms** - Accounts across GitHub.com and GitHub Enterprise Server

## Same Platform, Multiple Accounts

### Authentication

Authenticate with each account on the same platform:

```bash
# First account
gh auth login

# Second account
gh auth login
```

Follow the prompts for each authentication. GitHub CLI stores credentials for all authenticated accounts.

### Switching Accounts

Toggle between accounts on the same platform:

```bash
gh auth switch
```

An interactive menu displays available accounts. Select the desired account to switch.

### Viewing Active Account

Check the currently active account:

```bash
gh auth status
```

This displays the authenticated user for the current context.

## Different Platforms

### Authentication for Each Platform

Authenticate separately for each GitHub platform:

```bash
# Authenticate to GitHub.com
gh auth login --hostname github.com

# Authenticate to GitHub Enterprise Server
gh auth login --hostname github.enterprise.com
```

### Automatic Platform Detection

GitHub CLI automatically detects the correct platform when operating within a repository context:

```bash
cd ~/work/enterprise-repo
gh issue list        # Automatically uses GitHub Enterprise

cd ~/personal/project
gh issue list        # Automatically uses GitHub.com
```

This automatic detection works because the repository's remote URL indicates the hostname.

### Manual Platform Specification

When outside repository context, specify the platform explicitly:

#### Using GH_HOST Environment Variable

Set the default target hostname:

```bash
# Temporarily set for one command
GH_HOST=github.enterprise.com gh repo list

# Set for session
export GH_HOST=github.enterprise.com
gh repo list    # Uses GitHub Enterprise

# Reset to default
unset GH_HOST
```

#### Using --hostname Flag

Some commands support the `--hostname` flag:

```bash
gh api --hostname github.enterprise.com /user/repos
gh repo list --hostname github.enterprise.com
```

#### Using Full URLs

Pass full repository URLs to specify the platform:

```bash
gh pr view https://github.enterprise.com/OWNER/REPO/pr/42
gh issue view https://github.com/OWNER/REPO/issues/7
gh repo clone https://github.enterprise.com/OWNER/REPO
```

## Authentication Requirements

**Important:** Authenticate to all platforms you need to use, even for public repositories.

GitHub CLI requires authentication for:
- All operations, including public repository reads
- Any command that contacts GitHub servers
- Both read and write operations

Example: Viewing a public repository requires authentication to that platform:

```bash
# This fails if only authenticated to Enterprise
gh repo view octocat/hello-world

# Authenticate to GitHub.com first
gh auth login --hostname github.com
gh repo view octocat/hello-world  # Now works
```

## Platform-Specific Operations

### Repository Operations

```bash
# Clone from specific platform
gh repo clone --repo https://github.enterprise.com/OWNER/REPO

# View repository with full URL
gh repo view https://github.com/OWNER/REPO
```

### API Operations

```bash
# GitHub.com API
gh api /user

# Enterprise API with hostname
gh api --hostname github.enterprise.com /user

# Full URL specification
gh api https://github.enterprise.com/api/v3/user
```

### Search Operations

```bash
# Search on GitHub.com
gh search repos --language python

# Search on Enterprise
GH_HOST=github.enterprise.com gh search repos --language go
```

## Enterprise Server Considerations

### Self-Hosted Instances

For self-hosted GitHub Enterprise Server:

```bash
gh auth login --hostname github.example.com
```

Ensure the hostname matches your Enterprise Server URL.

### API Version Endpoints

Enterprise Server API endpoints typically include `/api/v3`:

```bash
gh api --hostname github.example.com /api/v3/user
```

GitHub CLI automatically handles API path prefixing for most operations.

## Common Workflows

### Personal and Work Accounts

Authenticate to both personal GitHub.com and work Enterprise:

```bash
# Personal account on GitHub.com
gh auth login

# Work account on Enterprise
gh auth login --hostname github.enterprise.com
```

### Multiple Personal Accounts

For multiple GitHub.com accounts:

```bash
# Primary account
gh auth login

# Secondary account
gh auth login

# Switch when needed
gh auth switch
```

### Organization-Specific Operations

```bash
# Work with organization on Enterprise
GH_HOST=github.enterprise.com gh repo list org-name

# Work with personal repositories on GitHub.com
gh repo list
```

## Troubleshooting

### Authentication Errors

If commands fail with authentication errors:

```bash
# Check current status
gh auth status

# Re-authenticate to the problematic platform
gh auth login --hostname HOSTNAME
```

### Wrong Account Being Used

If commands use the wrong account:

```bash
# Check active account
gh auth status

# Switch accounts (same platform)
gh auth switch

# Specify correct platform
GH_HOST=correct.host.com gh COMMAND
```

### Platform Not Detected

When automatic detection fails:

```bash
# Use full URL
gh COMMAND https://desired-host/OWNER/REPO

# Set environment variable
GH_HOST=desired-host gh COMMAND

# Use hostname flag
gh COMMAND --hostname desired-host
```

## Environment Variables

### GH_HOST

Default GitHub hostname for commands without repository context:

```bash
export GH_HOST=github.enterprise.com
```

### GH_TOKEN

Provide authentication token for specific commands:

```bash
GH_TOKEN=ghp_xxxxx gh api /user
```

### GH_ENTERPRISE_TOKEN (Deprecated)

Legacy variable. Use `GH_TOKEN` with `GH_HOST` instead.

## Best Practices

### Use Repository Context

Work inside cloned repositories when possible for automatic platform detection:

```bash
cd ~/projects/enterprise-project
gh pr list    # Automatically correct platform
```

### Shell Aliases for Platforms

Create aliases for different platforms:

```bash
# In ~/.bashrc or ~/.zshrc
alias ghe='GH_HOST=github.enterprise.com gh'
alias ghc='GH_HOST=github.com gh'

# Usage
ghe repo list    # Enterprise
ghc repo list    # GitHub.com
```

### Separate Git Configurations

Configure different Git credentials per platform:

```bash
# ~/.gitconfig
[includeIf "gitdir:~/work/"]
  path = ~/.gitconfig-work

# ~/.gitconfig-work
[user]
  email = work@example.com
```

## Security Considerations

### Token Storage

GitHub CLI stores OAuth tokens securely:
- macOS: Keychain
- Windows: Credential Manager
- Linux: Secret Service (gnome-keyring, etc.)

### Token Scopes

During authentication, grant only necessary scopes:
- `repo` - Full repository access
- `read:org` - Organization read access
- `admin:org` - Organization administration (rarely needed)

### Logout

Remove credentials when no longer needed:

```bash
# Remove all credentials for current host
gh auth logout

# Remove specific host
gh auth logout --hostname github.enterprise.com
```

## Advanced Configuration

### Configuration Files

GitHub CLI stores configuration in:
- Linux/macOS: `~/.config/gh/hosts.yml`
- Windows: `%APPDATA%\gh\hosts.yml`

View configuration file:

```bash
cat ~/.config/gh/hosts.yml
```

### Multiple Git Protocols

Configure different Git protocols per platform:

```bash
# GitHub.com with SSH
gh config set --host github.com git_protocol ssh

# Enterprise with HTTPS
gh config set --host github.enterprise.com git_protocol https
```

### Default Branch Configuration

Set default branch per platform:

```bash
gh config set --host github.com default_branch main
gh config set --host github.enterprise.com default_branch master
```
