# Release Types Reference

Supported languages, package managers, and their configuration.

## Release Types

| Type | Description | Files Updated |
|------|-------------|---------------|
| `dart` | Dart packages | `pubspec.yaml`, `CHANGELOG.md` |
| `elixir` | Elixir packages | `mix.exs`, `CHANGELOG.md` |
| `go` | Go modules | `CHANGELOG.md` |
| `helm` | Helm charts | `Chart.yaml`, `CHANGELOG.md` |
| `java` | Java projects | `CHANGELOG.md` (use extra-files for pom.xml) |
| `krm-blueprint` | KRM blueprints | KRM files, `CHANGELOG.md` |
| `maven` | Maven projects | `pom.xml`, `CHANGELOG.md` |
| `node` | Node.js packages | `package.json`, `package-lock.json`, `CHANGELOG.md` |
| `expo` | Expo React Native | `package.json`, `app.json`, `CHANGELOG.md` |
| `ocaml` | OCaml packages | `opam`, `esy` files, `CHANGELOG.md` |
| `php` | PHP packages | `composer.json`, `CHANGELOG.md` |
| `python` | Python packages | `setup.py`, `setup.cfg`, `pyproject.toml`, `__init__.py`, `CHANGELOG.md` |
| `ruby` | Ruby gems | `version.rb`, `CHANGELOG.md` |
| `rust` | Rust crates | `Cargo.toml`, `Cargo.lock`, `CHANGELOG.md` |
| `sfdx` | Salesforce DX | `sfdx-project.json`, `CHANGELOG.md` |
| `simple` | Simple versioning | `version.txt`, `CHANGELOG.md` |
| `terraform-module` | Terraform modules | `README.md`, `CHANGELOG.md` |

## Node.js (node)

### Files Updated

- `package.json` - version field
- `package-lock.json` - if exists
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "node"
    }
  }
}
```

### Node Workspace Plugin

For monorepos with npm/yarn workspaces:

```json
{
  "plugins": ["node-workspace"]
}
```

Automatically updates inter-package dependencies.

### Custom Extra Files

```json
{
  "extra-files": [
    {
      "type": "json",
      "path": "app.json",
      "jsonpath": "$.version"
    }
  ]
}
```

## Python (python)

### Files Updated

- `setup.py` - version argument
- `setup.cfg` - version field
- `pyproject.toml` - project.version
- `<package>/__init__.py` - `__version__` variable
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    "path/to/package": {
      "release-type": "python",
      "package-name": "my-package"
    }
  }
}
```

The `package-name` is required for Python packages.

### Custom Init File

```json
{
  "extra-files": [
    {
      "type": "generic",
      "path": "src/mypackage/__init__.py"
    }
  ]
}
```

Annotate with:
```python
__version__ = "1.0.0"  # x-release-please-version
```

## Rust (rust)

### Files Updated

- `Cargo.toml` - package.version
- `Cargo.lock` - updated automatically
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    "path/to/crate": {
      "release-type": "rust"
    }
  }
}
```

### Cargo Workspace Plugin

For Cargo workspaces:

```json
{
  "plugins": ["cargo-workspace"]
}
```

Builds dependency graph and updates all dependents.

### Workspace Config

```json
{
  "plugins": [
    {
      "type": "cargo-workspace",
      "merge": false
    }
  ]
}
```

Set `merge: false` when combining with linked-versions plugin.

## Java/Maven (java, maven)

### Java Strategy

General-purpose, updates no files by default. Use `extra-files`:

```json
{
  "packages": {
    ".": {
      "release-type": "java",
      "extra-files": [
        {
          "type": "xml",
          "path": "pom.xml",
          "xpath": "//project/version"
        }
      ]
    }
  }
}
```

### Maven Strategy

Updates all `pom.xml` files recursively:

```json
{
  "packages": {
    ".": {
      "release-type": "maven"
    }
  }
}
```

Updates `/project/version` or `/project/parent/version`.

### SNAPSHOT Versions

Java/Maven strategies create snapshot PRs after releases:

- Creates separate PR with SNAPSHOT version
- Labeled with `autorelease: snapshot`
- Updates all affected files but doesn't create release

### Maven Workspace Plugin

```json
{
  "plugins": ["maven-workspace"]
}
```

Builds dependency graph of all `pom.xml` files.

## Go (go)

### Files Updated

- `CHANGELOG.md` - changelog entries only

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "go"
    }
  }
}
```

### Version in Go

Go uses git tags for versioning. Update version via extra-files:

```json
{
  "extra-files": [
    {
      "type": "generic",
      "path": "version.go"
    }
  ]
}
```

Annotate:
```go
const Version = "1.0.0" // x-release-please-version
```

## Ruby (ruby)

### Files Updated

- `version.rb` - VERSION constant
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "ruby",
      "version-file": "lib/mygem/version.rb"
    }
  }
}
```

### Version File Format

```ruby
# lib/mygem/version.rb
module MyGem
  VERSION = "1.0.0"
end
```

## PHP (php)

### Files Updated

- `composer.json` - version field
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "php"
    }
  }
}
```

## Dart (dart)

### Files Updated

- `pubspec.yaml` - version field
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "dart"
    }
  }
}
```

## Elixir (elixir)

### Files Updated

- `mix.exs` - @version attribute
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "elixir"
    }
  }
}
```

## Helm (helm)

### Files Updated

- `Chart.yaml` - version field
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    "charts/mychart": {
      "release-type": "helm"
    }
  }
}
```

## Terraform Module (terraform-module)

### Files Updated

- `README.md` - version in documentation
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    "modules/mymodule": {
      "release-type": "terraform-module"
    }
  }
}
```

### Version Format

Version is typically documented in README:

```markdown
# Terraform Module

Version: 1.0.0  # x-release-please-version
```

## Simple (simple)

### Files Updated

- `version.txt` - version string
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "simple"
    }
  }
}
```

### Version File Format

```
1.0.0
```

## Expo (expo)

### Files Updated

- `package.json` - version field
- `app.json` or `app.config.js` - expo.version
- `CHANGELOG.md` - changelog entries

### Configuration

```json
{
  "packages": {
    ".": {
      "release-type": "expo"
    }
  }
}
```

## Custom Release Types

To add a new release type, implement:

1. A `Strategy` class that determines which files to update
2. `Updater` classes that update file contents
3. Register the new type

See [contributing guidelines](https://github.com/googleapis/release-please/blob/main/.github/CONTRIBUTING.md) for details.

## Choosing a Release Type

Consider the project type:

- **Node.js library**: Use `node`
- **Python package**: Use `python`
- **Rust crate**: Use `rust`
- **Java project**: Use `maven` or `java`
- **Go module**: Use `go` with extra-files for version
- **Simple app**: Use `simple`
- **Helm chart**: Use `helm`
- **Terraform module**: Use `terraform-module`

For projects not listed, use `simple` with `extra-files` configuration.

## Package Name Requirements

Some release types require explicit `package-name`:

- `python` - Required
- `simple` - Optional
- `node` - Auto-detected from package.json
- `rust` - Auto-detected from Cargo.toml

Other types may have package name auto-detection.
