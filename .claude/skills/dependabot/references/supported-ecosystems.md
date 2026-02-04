# Supported Package Ecosystems

Reference for all package managers and ecosystems supported by Dependabot.

## Quick Reference

| Ecosystem | Value for `package-ecosystem` | Typical Directory | Manifest Files |
|-----------|------------------------------|-------------------|----------------|
| Bundler (Ruby) | `bundler` | `/` | `Gemfile`, `Gemfile.lock` |
| Cargo (Rust) | `cargo` | `/` | `Cargo.toml`, `Cargo.lock` |
| Composer (PHP) | `composer` | `/` | `composer.json`, `composer.lock` |
| Docker | `docker` | `/` | `Dockerfile` |
| Elm | `elm` | `/` | `elm.json` |
| Git submodules | `gitsubmodule` | `/` | `.gitmodules` |
| GitHub Actions | `github-actions` | `/` | `.github/workflows/*.yml` |
| Go modules | `gomod` | `/` | `go.mod`, `go.sum` |
| Gradle | `gradle` | `/` | `build.gradle`, `build.gradle.kts` |
| Maven | `maven` | `/` | `pom.xml` |
| Mix (Elixir) | `mix` | `/` | `mix.exs`, `mix.lock` |
| npm | `npm` | `/` | `package.json`, `package-lock.json` |
| NuGet | `nuget` | `/` | `*.csproj`, `*.vbproj`, `*.fsproj` |
| pip (Python) | `pip` | `/` | `requirements.txt`, `Pipfile` |
| Poetry (Python) | `pip` | `/` | `pyproject.toml`, `poetry.lock` |
| Pub (Dart) | `pub` | `/` | `pubspec.yaml` |
| Swift | `swift` | `/` | `Package.swift` |
| Terraform | `terraform` | `/` | `*.tf` |
| Yarn | `npm` | `/` | `package.json`, `yarn.lock` |

## Ecosystem Details

### Bundler (Ruby)

```yaml
- package-ecosystem: "bundler"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `Gemfile`, `Gemfile.lock`

**Features:**
- Updates direct and indirect dependencies
- Supports private gem servers via registries
- Can execute code during updates (requires `insecure-external-code-execution: allow`)

**Common configuration:**
```yaml
- package-ecosystem: "bundler"
  directory: "/"
  schedule:
    interval: "weekly"
  insecure-external-code-execution: "allow"
  versioning-strategy: "increase"
```

### Cargo (Rust)

```yaml
- package-ecosystem: "cargo"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `Cargo.toml`, `Cargo.lock`

**Features:**
- Updates workspace dependencies
- Supports git dependencies
- Lockfile-only updates by default

**Monorepo support:**
```yaml
# Workspace root
- package-ecosystem: "cargo"
  directory: "/"
  schedule:
    interval: "weekly"

# Individual crate
- package-ecosystem: "cargo"
  directory: "/crates/my-crate"
  schedule:
    interval: "weekly"
```

### Composer (PHP)

```yaml
- package-ecosystem: "composer"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `composer.json`, `composer.lock`

**Features:**
- Updates direct and indirect dependencies
- Supports private package repositories
- Distinguishes between `require` and `require-dev`

**Dependency types:**
```yaml
# Production only
- package-ecosystem: "composer"
  directory: "/"
  schedule:
    interval: "weekly"
  allow:
    - dependency-type: "production"

# Development only
- package-ecosystem: "composer"
  directory: "/"
  schedule:
    interval: "monthly"
  allow:
    - dependency-type: "development"
```

### Docker

```yaml
- package-ecosystem: "docker"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `Dockerfile`, `docker-compose.yml`, `docker-compose.yaml`

**Features:**
- Updates `FROM` statements in Dockerfiles
- Updates image tags in docker-compose files
- Supports private registries

**Tag format:**
- For tags like `account.dkr.ecr.region.amazonaws.com/base/foo/bar/image:tag`
- Use `base/foo/bar/image` as dependency name

**Private registry:**
```yaml
registries:
  ecr-docker:
    type: docker-registry
    url: 123456789.dkr.ecr.us-west-2.amazonaws.com
    username: ${{secrets.AWS_ACCESS_KEY_ID}}
    password: ${{secrets.AWS_SECRET_ACCESS_KEY}}

updates:
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - ecr-docker
```

### GitHub Actions

```yaml
- package-ecosystem: "github-actions"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `.github/workflows/*.yml`, `.github/workflows/*.yaml`

**Features:**
- Updates action versions in `uses:` statements
- Updates reusable workflow versions
- Supports both tag and SHA references

**Example:**
```yaml
# Updates actions like:
# uses: actions/checkout@v3
# uses: actions/setup-node@v3.5.0
# uses: my-org/my-action@abc123

- package-ecosystem: "github-actions"
  directory: "/"
  schedule:
    interval: "weekly"
  labels:
    - "dependencies"
    - "github-actions"
```

### Go modules (gomod)

```yaml
- package-ecosystem: "gomod"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `go.mod`, `go.sum`

**Features:**
- Updates direct and indirect dependencies
- Supports private module registries
- Lockfile-only updates by default

**Vendor support:**
```yaml
- package-ecosystem: "gomod"
  directory: "/"
  schedule:
    interval: "weekly"
  vendor: true  # Run `go mod vendor` after updates
```

### Gradle

```yaml
- package-ecosystem: "gradle"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts`

**Features:**
- Updates dependencies in Gradle and Kotlin DSL files
- Supports version catalogs (`libs.versions.toml`)
- Supports private Maven repositories

**Dependency format:**
- Use `groupId:artifactId` format
- Example: `org.springframework.boot:spring-boot-starter-web`

**Version catalog:**
```yaml
# Updates dependencies in gradle/libs.versions.toml
- package-ecosystem: "gradle"
  directory: "/"
  schedule:
    interval: "weekly"
```

### Maven

```yaml
- package-ecosystem: "maven"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `pom.xml`

**Features:**
- Updates dependencies and plugins
- Supports multi-module projects
- Supports private Maven repositories

**Multi-module:**
```yaml
# Parent POM
- package-ecosystem: "maven"
  directory: "/"
  schedule:
    interval: "weekly"

# Module
- package-ecosystem: "maven"
  directory: "/module-name"
  schedule:
    interval: "weekly"
```

### Mix (Elixir)

```yaml
- package-ecosystem: "mix"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `mix.exs`, `mix.lock`

**Features:**
- Updates Hex packages
- Updates git dependencies
- Can execute code during updates (requires configuration)

**Configuration:**
```yaml
- package-ecosystem: "mix"
  directory: "/"
  schedule:
    interval: "weekly"
  insecure-external-code-execution: "allow"
```

### npm (includes Yarn)

```yaml
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `package.json`, `package-lock.json`, `yarn.lock`, `npm-shrinkwrap.json`

**Features:**
- Automatically detects npm, Yarn, or pnpm
- Updates both dependencies and devDependencies
- Lockfile-only updates by default
- Supports workspaces

**Workspace configuration:**
```yaml
# Root workspace
- package-ecosystem: "npm"
  directory: "/"
  schedule:
    interval: "weekly"

# Workspace package
- package-ecosystem: "npm"
  directory: "/packages/frontend"
  schedule:
    interval: "weekly"
```

**Private registry:**
```yaml
registries:
  npm-github:
    type: npm-registry
    url: https://npm.pkg.github.com
    token: ${{secrets.NPM_TOKEN}}

updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - npm-github
```

### NuGet (.NET)

```yaml
- package-ecosystem: "nuget"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `*.csproj`, `*.vbproj`, `*.fsproj`, `packages.config`

**Features:**
- Updates PackageReference dependencies
- Supports private NuGet feeds
- Updates multiple project files

**Private feed:**
```yaml
registries:
  nuget-contoso:
    type: nuget-feed
    url: https://nuget.contoso.com/feed/v3/index.json
    token: ${{secrets.NUGET_TOKEN}}

updates:
  - package-ecosystem: "nuget"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - nuget-contoso
```

### pip (Python)

```yaml
- package-ecosystem: "pip"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:**
- `requirements.txt`
- `requirements/*.txt`
- `Pipfile`, `Pipfile.lock`
- `pyproject.toml`, `poetry.lock`
- `setup.py` (reads `install_requires`)

**Features:**
- Supports pip, Pipenv, and Poetry
- Updates direct and indirect dependencies
- Supports private package indexes

**Poetry:**
```yaml
- package-ecosystem: "pip"
  directory: "/"
  schedule:
    interval: "weekly"
  # Automatically detects Poetry from poetry.lock
```

**Private index:**
```yaml
registries:
  python-azure:
    type: python-index
    url: https://pkgs.dev.azure.com/organization/project/_packaging/feed/pypi/simple
    username: ${{secrets.AZURE_USERNAME}}
    password: ${{secrets.AZURE_PASSWORD}}

updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - python-azure
```

### Pub (Dart/Flutter)

```yaml
- package-ecosystem: "pub"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `pubspec.yaml`, `pubspec.lock`

**Features:**
- Updates Flutter and Dart packages
- Supports dependency and dev_dependency
- Updates from pub.dev

### Terraform

```yaml
- package-ecosystem: "terraform"
  directory: "/"
  schedule:
    interval: "weekly"
```

**Manifest files:** `*.tf` files

**Features:**
- Updates Terraform modules
- Updates provider versions
- Supports public and private registries

**Configuration:**
```yaml
- package-ecosystem: "terraform"
  directory: "/"
  schedule:
    interval: "weekly"
  labels:
    - "terraform"
    - "infrastructure"
```

**Private registry:**
```yaml
registries:
  terraform-private:
    type: terraform-registry
    url: https://terraform.example.com
    token: ${{secrets.TERRAFORM_TOKEN}}

updates:
  - package-ecosystem: "terraform"
    directory: "/"
    schedule:
      interval: "weekly"
    registries:
      - terraform-private
```

## Common Patterns by Ecosystem

### Monorepo - npm workspaces

```yaml
updates:
  # Root package.json
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"

  # Frontend workspace
  - package-ecosystem: "npm"
    directory: "/apps/frontend"
    schedule:
      interval: "weekly"

  # Backend workspace
  - package-ecosystem: "npm"
    directory: "/apps/backend"
    schedule:
      interval: "weekly"
```

### Monorepo - Cargo workspace

```yaml
updates:
  # Workspace root
  - package-ecosystem: "cargo"
    directory: "/"
    schedule:
      interval: "weekly"

  # Individual crates (if needed)
  - package-ecosystem: "cargo"
    directory: "/crates/core"
    schedule:
      interval: "weekly"
```

### Full Stack Project

```yaml
updates:
  # Frontend dependencies
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"

  # Backend dependencies
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"

  # Infrastructure
  - package-ecosystem: "terraform"
    directory: "/infrastructure"
    schedule:
      interval: "monthly"

  # CI/CD
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Container-based Project

```yaml
updates:
  # Application dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"

  # Docker images
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  # GitHub Actions workflows
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Ecosystem-Specific Notes

### npm / Yarn

- **Lockfile-only by default**: Dependabot updates lockfiles without changing version ranges in `package.json`
- **Workspace support**: Automatically detects and handles npm/Yarn workspaces
- **Version strategy**: Use `versioning-strategy: increase` to update `package.json` ranges

### pip / Poetry

- **Multiple file support**: Checks `requirements.txt`, `requirements/*.txt`, `Pipfile`, `pyproject.toml`
- **Poetry detection**: Automatically uses Poetry if `poetry.lock` exists
- **Version pinning**: Updates `==` pinned versions and `>=` constraints

### Docker

- **Tag formats**: Use full repository path for dependency names
- **Digest pinning**: Updates both tags and digest pins
- **Multi-stage builds**: Updates all `FROM` statements

### GitHub Actions

- **Version formats**: Updates `@v1`, `@v1.2.3`, and SHA references
- **Security**: Consider using SHA references for security-critical workflows
- **Composite actions**: Updates both regular actions and composite actions

### Gradle / Maven

- **Dependency format**: Use `groupId:artifactId` for allow/ignore rules
- **Version catalogs**: Gradle version catalogs are fully supported
- **Property versions**: Updates version defined in properties

### Go modules

- **Indirect dependencies**: Use `allow: [{dependency-type: "indirect"}]` to update transitive deps
- **Vendor directory**: Set `vendor: true` to run `go mod vendor` after updates
- **Replace directives**: Respects `replace` directives in `go.mod`

## Version Strategy by Ecosystem

Default `versioning-strategy` for each ecosystem:

| Ecosystem | Default Strategy |
|-----------|-----------------|
| bundler | increase |
| cargo | lockfile-only |
| composer | increase |
| docker | increase |
| gomod | lockfile-only |
| gradle | increase |
| maven | increase |
| mix | increase |
| npm | lockfile-only |
| nuget | increase |
| pip | increase |
| pub | increase |
| terraform | increase |

Override with `versioning-strategy` option in configuration.
