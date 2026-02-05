# Creating GitHub CLI Extensions

Create custom commands for GitHub CLI by building extensions. Extensions add new functionality to `gh` and can be shared with the community.

## Understanding Extensions

GitHub CLI extensions are:
- **Local installations** - Scoped to the current user, not machine-wide
- **Named repositories** - Must start with `gh-` prefix
- **Executable files** - Either scripts or precompiled binaries
- **Command shortcuts** - Run as `gh EXTENSION-NAME` (without `gh-` prefix)

### Extension Types

1. **Interpreted Extensions** - Scripts (bash, Python, Node.js, etc.)
2. **Precompiled Extensions** - Compiled binaries (Go, Rust, C++, etc.)

## Interpreted Extensions

### Directory Structure

```
gh-EXTENSION-NAME/
├── gh-EXTENSION-NAME    # Executable script (same name as directory)
├── README.md            # Documentation
└── LICENSE              # License file
```

### Creating with the Wizard

Use the interactive extension creator:

```bash
gh extension create EXTENSION-NAME
```

Follow the prompts to:
1. Choose extension type (interpreted or precompiled)
2. Select language for precompiled extensions
3. Generate starter code and scaffolding
4. Initialize git repository
5. Optionally publish to GitHub

### Creating Manually

#### Step 1: Create Directory

```bash
mkdir gh-EXTENSION-NAME
cd gh-EXTENSION-NAME
```

Replace `EXTENSION-NAME` with your extension name, e.g., `gh-whoami`.

#### Step 2: Create Executable Script

Create a file with the same name as the directory:

```bash
# gh-EXTENSION-NAME
#!/usr/bin/env bash
set -e

# Your extension logic here
echo "Hello from my extension!"
```

#### Step 3: Make Executable

On Unix/Linux/macOS:

```bash
chmod +x gh-EXTENSION-NAME
```

On Windows (Git Bash):

```bash
git init -b main
git add gh-EXTENSION-NAME
git update-index --chmod=+x gh-EXTENSION-NAME
```

#### Step 4: Example Extension Script

```bash
#!/usr/bin/env bash
set -e

# Fetch and display current user info
exec gh api user --jq '"You are @\(.login) (\(.name))"'
```

#### Step 5: Install Locally

```bash
gh extension install .
```

#### Step 6: Test

```bash
gh EXTENSION-NAME
```

For `gh-whoami`, run `gh whoami`.

### Argument Handling

All arguments after `gh EXTENSION-NAME` pass to the script:

```bash
#!/usr/bin/env bash
set -e

verbose=""
name_arg=""

while [ $# -gt 0 ]; do
  case "$1" in
    --verbose)
      verbose=1
      ;;
    --name)
      name_arg="$2"
      shift
      ;;
    -h|--help)
      echo "Usage: gh EXTENSION-NAME [options]"
      echo ""
      echo "Options:"
      echo "  --verbose    Enable verbose output"
      echo "  --name NAME  Set name"
      echo "  -h, --help   Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# Your logic using $verbose and $name_arg
```

### Non-Interactive Mode

Avoid prompts in scripts by providing explicit arguments:

```bash
# Instead of interactive prompt
gh issue create --title "Title" --body "Description"

# Fetch data without prompts
gh issue list --limit 100 --json number,title
```

### JSON Data Processing

Use `--json` flag for structured output:

```bash
# Get specific fields
gh pr list --json number,title,state,mergeStateStatus

# Filter with jq
gh pr list --json title --jq '.[].title'

# Complex queries
gh issue list --json number,labels --jq '.[] | select(.labels[].name == "bug") | .number'
```

### Direct API Access

Use `gh api` when no core command exists:

```bash
# Get user info
gh api user

# Custom endpoint
gh api /repos/OWNER/REPO/issues --method POST -f title='Bug'

# With headers
gh api /user/starred/OWNER/REPO --method PUT
```

## Precompiled Extensions

### Directory Structure

```
gh-EXTENSION-NAME/
├── main.go              # Source code
├── go.mod               # Go module definition
├── script/
│   └── build.sh         # Build script
├── .github/
│   └── workflows/
│       └── release.yml  # Release workflow
├── README.md
└── LICENSE
```

### Creating Go Extension with Wizard

```bash
gh extension create --precompiled=go EXTENSION-NAME
```

This generates:
- Go scaffolding with `go-gh` library
- Starter code
- GitHub Actions workflow for releases

### Creating Go Extension Manually

#### Step 1: Create Directory

```bash
mkdir gh-EXTENSION-NAME
cd gh-EXTENSION-NAME
```

#### Step 2: Initialize Go Module

```bash
go mod init github.com/YOUR-USERNAME/gh-EXTENSION-NAME
```

#### Step 3: Write Source Code

```go
package main

import (
    "github.com/cli/go-gh"
    "fmt"
    "os"
)

func main() {
    // Execute gh command
    args := []string{"api", "user", "--jq", `"You are @\(.login) (\(.name))"`}
    stdOut, _, err := gh.Exec(args...)
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }
    fmt.Print(stdOut.String())
}
```

#### Step 4: Install Dependencies

```bash
go get github.com/cli/go-gh
go mod tidy
```

#### Step 5: Build

```bash
go build
```

This creates an executable named `gh-EXTENSION-NAME`.

#### Step 6: Install Locally

```bash
gh extension install .
```

#### Step 7: Test

```bash
gh EXTENSION-NAME
```

### Binary Naming Convention

For cross-platform releases, binaries must follow this naming pattern:

```
gh-EXTENSION-NAME-OS-ARCHITECTURE[EXTENSION]
```

**OS values:** `linux`, `windows`, `darwin` (macOS)

**Architecture values:** `amd64`, `386`, `arm64`, `arm`

**Examples:**
- `gh-whoami-linux-amd64`
- `gh-whoami-windows-amd64.exe` (Windows requires `.exe`)
- `gh-whoami-darwin-arm64`

### Building for Multiple Platforms

```bash
# Linux AMD64
GOOS=linux GOARCH=amd64 go build -o gh-EXTENSION-NAME-linux-amd64

# Linux ARM64
GOOS=linux GOARCH=arm64 go build -o gh-EXTENSION-NAME-linux-arm64

# macOS AMD64 (Intel)
GOOS=darwin GOARCH=amd64 go build -o gh-EXTENSION-NAME-darwin-amd64

# macOS ARM64 (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -o gh-EXTENSION-NAME-darwin-arm64

# Windows AMD64
GOOS=windows GOARCH=amd64 go build -o gh-EXTENSION-NAME-windows-amd64.exe
```

### Creating Releases

#### Step 1: Tag Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

#### Step 2: Build All Platforms

```bash
# Build all platforms
GOOS=linux GOARCH=amd64 go build -o gh-EXTENSION-NAME-linux-amd64
GOOS=linux GOARCH=arm64 go build -o gh-EXTENSION-NAME-linux-arm64
GOOS=darwin GOARCH=amd64 go build -o gh-EXTENSION-NAME-darwin-amd64
GOOS=darwin GOARCH=arm64 go build -o gh-EXTENSION-NAME-darwin-arm64
GOOS=windows GOARCH=amd64 go build -o gh-EXTENSION-NAME-windows-amd64.exe
```

#### Step 3: Create Release with Binaries

```bash
gh release create v1.0.0 ./*amd64* ./*arm64*
```

### Automating Releases

Use the `gh-extension-precompile` GitHub Action for automatic cross-platform builds:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cli/gh-extension-precompile@v1
        with:
          build: |
            go build -o ${{ github.event.repository.name }}
```

### Non-Go Precompiled Extensions

For other languages (Rust, C++, etc.):

```bash
gh extension create --precompiled=other EXTENSION-NAME
```

Create `script/build.sh` to compile your extension:

```bash
#!/bin/bash
# Build script for your language
cargo build --release
cp target/release/gh-EXTENSION-NAME .
```

## Publishing Extensions

### Create Repository

```bash
git init -b main
git add .
git commit -m "Initial commit"
gh repo create gh-EXTENSION-NAME --source=. --public --push
```

### Add Topic for Discoverability

```bash
# Via CLI
gh repo edit --add-topic=gh-extension

# Or via web interface
# Visit repo Settings → Topics and add "gh-extension"
```

Your extension will appear at https://github.com/topics/gh-extension

### README Best Practices

Include in your README:

```markdown
# gh-extension-name

Description of what your extension does.

## Installation

\`\`\`bash
gh extension install OWNER/gh-EXTENSION-NAME
\`\`\`

## Usage

\`\`\`bash
gh EXTENSION-NAME [arguments]
\`\`\`

## Examples

\`\`\`bash
# Example 1
gh EXTENSION-NAME --option value

# Example 2
gh EXTENSION-NAME positional-arg
\`\`\`
```

## Tips for Extension Development

### Error Handling

```bash
#!/usr/bin/env bash
set -e  # Exit on error

# Or handle gracefully
if ! gh api user &>/dev/null; then
  echo "Error: Not authenticated"
  exit 1
fi
```

### Help Text

```bash
#!/usr/bin/env bash

show_help() {
  cat << EOF
Usage: gh EXTENSION-NAME [options]

Description of what the extension does.

Options:
  -h, --help     Show this help message
  -v, --version  Show version information
  --verbose      Enable verbose output

Examples:
  gh EXTENSION-NAME --option value
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done
```

### Using go-gh Library

The `go-gh` library provides Go bindings for GitHub CLI functionality:

```go
import (
    "github.com/cli/go-gh"
    "github.com/cli/go-gh/pkg/api"
)

// Execute gh commands
stdOut, _, _ := gh.Exec("api", "user")

// Make API requests
client, _ := gh.RESTClient(nil)
client.Request("GET", "user", &result)
```

### Version Information

```bash
VERSION="1.0.0"

case "$1" in
  -v|--version)
    echo "gh-EXTENSION-NAME $VERSION"
    exit 0
    ;;
esac
```

## Finding Extension Examples

Browse community extensions for inspiration:

- Visit https://github.com/topics/gh-extension
- Search for `gh-extension` topic on GitHub
- Review popular extensions' source code

## Extension Repository Requirements

- Repository name must start with `gh-`
- Root directory must have an executable file with the same name
- For precompiled: attach binaries to releases with correct naming
- For interpreted: make the script executable
- Add `gh-extension` topic for discoverability
