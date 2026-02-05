---
name: gh-cli
description: This skill should be used when the user asks to "use gh cli", "run gh command", "work with GitHub CLI", "create a gh extension", or mentions "gh", "GitHub CLI", "gh extension", or GitHub command-line operations.
version: 0.1.0
---

# GitHub CLI (gh) Skill

## Purpose

GitHub CLI (`gh`) brings GitHub to the terminal. Work with issues, pull requests, checks, releases, and more without leaving the command line. This skill provides comprehensive guidance for using GitHub CLI effectively and extending it with custom commands.

## When to Use This Skill

Use this skill when:
- Interacting with GitHub repositories, issues, or pull requests from the command line
- Creating, viewing, or managing GitHub resources without a browser
- Automating GitHub workflows with scripts
- Creating custom GitHub CLI extensions
- Managing authentication across multiple GitHub accounts
- Fetching GitHub data programmatically via the API

## Core Workflow

### Step 1: Authentication

Before using GitHub CLI, authenticate with your GitHub account:

```bash
gh auth login
```

Follow the prompts to choose GitHub.com or GitHub Enterprise, authenticate via browser or token, and configure credentials.

For multiple accounts on the same platform, authenticate with each account and use `gh auth switch` to toggle between them. For accounts across different platforms (e.g., personal GitHub.com and work Enterprise Server), authenticate separately—GitHub CLI automatically detects the correct platform when operating within a repository context.

### Step 2: Essential Commands

#### Repository Operations

View repository information:

```bash
gh repo view OWNER/REPO
gh repo view OWNER/REPO --web  # Open in browser
```

Clone a repository:

```bash
gh repo clone OWNER/REPO
```

Create a new repository:

```bash
gh repo create
```

List repositories:

```bash
gh repo list
```

#### Issue Management

List issues:

```bash
gh issue list --repo OWNER/REPO
gh issue list --assignee "@me"      # Your assigned issues
gh issue list --author monalisa     # By specific author
```

Create an issue:

```bash
gh issue create --title "Title" --body "Description"
```

View issue details:

```bash
gh issue view ISSUE-NUMBER
```

#### Pull Request Operations

List pull requests:

```bash
gh pr list --repo OWNER/REPO
gh pr list --author "@me"                    # Your PRs
gh pr list --label bug                       # By label
gh search prs --review-requested=@me         # Awaiting your review
```

Create a pull request:

```bash
gh pr create
```

Create a draft PR:

```bash
gh pr create --draft
```

View PR details:

```bash
gh pr view PR-NUMBER
```

Check out a PR locally:

```bash
gh pr checkout PR-NUMBER
```

#### Codespaces Management

Create a codespace:

```bash
gh codespace create
```

List codespaces:

```bash
gh codespace list
```

Open a codespace in VS Code for the Web:

```bash
gh codespace code -w
```

The shortcut `cs` can substitute for `codespace` in all commands.

#### Status Viewing

View your current GitHub activity across repositories:

```bash
gh status
```

### Step 3: Configuration

Customize GitHub CLI behavior:

```bash
gh config set editor "code -w"     # Set default editor
gh config set git_protocol ssh     # Prefer SSH over HTTPS
```

Create aliases for frequently used commands:

```bash
gh alias set prd "pr create --draft"  # Then run: gh prd
gh alias set ils "issue list --assignee @me"
```

View all aliases:

```bash
gh alias list
```

### Step 4: Programmatic Usage

For scripting and automation, use non-interactive modes:

#### Explicit Arguments

Always provide required values explicitly to avoid prompts:

```bash
gh issue create --title "My Title" --body "Issue description"
```

#### JSON Output

Fetch structured data with `--json`:

```bash
gh pr list --json number,title,mergeStateStatus
gh issue view 123 --json title,state,labels
```

Filter JSON output with `--jq`:

```bash
gh api user --jq '.login'
gh pr list --jq '.[].title'
```

#### API Access

Use `gh api` for direct GitHub REST API access:

```bash
gh api user
gh api repos/octocat/hello-world
gh api /user/repos --jq '.[].name'
```

### Step 5: Getting Help

Access built-in help:

```bash
gh                          # Top-level commands
gh COMMAND --help           # Command-specific help
gh COMMAND SUBCOMMAND --help  # Subcommand help
```

For complete documentation, visit the online manual at https://cli.github.com/manual/gh

## GitHub CLI Extensions

Extensions add custom commands to GitHub CLI. Discover extensions at https://github.com/topics/gh-extension.

### Installing Extensions

Install from a repository:

```bash
gh extension install OWNER/REPO
gh extension install https://github.com/OWNER/gh-REPO
```

Install from current directory (for development):

```bash
gh extension install .
```

### Managing Extensions

List installed extensions:

```bash
gh extension list
```

Update an extension:

```bash
gh extension upgrade EXTENSION-NAME
```

Update all extensions:

```bash
gh extension upgrade --all
```

Remove an extension:

```bash
gh extension remove EXTENSION-NAME
```

### Running Extensions

Execute extensions like built-in commands:

```bash
gh EXTENSION-NAME
```

The extension name is the repository name minus the `gh-` prefix. For `octocat/gh-whoami`, run `gh whoami`.

## Multiple Account Management

### Same Platform, Multiple Accounts

Authenticate with multiple accounts on the same platform:

```bash
gh auth login  # First account
gh auth login  # Second account
```

Switch between accounts:

```bash
gh auth switch
```

### Multiple Platforms

Authenticate separately for each platform. GitHub CLI automatically detects the correct platform when operating within a repository directory. For commands without repository context:

```bash
GH_HOST=github.enterprise.com gh repo list
gh api --hostname github.enterprise.com /user/repos
gh pr view https://github.enterprise.com/OWNER/REPO/pr/1
```

## Additional Resources

### Reference Files

For detailed information, consult:

- **`references/quickstart.md`** - Essential commands for getting started quickly
- **`references/extension-creation.md`** - Comprehensive guide to creating GitHub CLI extensions
- **`references/multiple-accounts.md`** - Managing authentication across accounts and platforms
- **`references/command-reference.md`** - Complete command structure and help system

### Online Resources

- [GitHub CLI Manual](https://cli.github.com/manual/gh) - Complete command reference
- [GitHub CLI Extensions](https://github.com/topics/gh-extension) - Discover community extensions
- [CLI Repository](https://github.com/cli/cli) - Source code and issue tracking
