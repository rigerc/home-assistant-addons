# Home Assistant Add-on Scaffold

This is a complete scaffold/template for creating Home Assistant add-ons with both s6-overlay v2 and v3 examples.

## Structure

```
scaffold/
├── config.yaml              # Add-on configuration
├── Dockerfile               # Container build instructions
├── run.sh                   # Standalone run script (optional)
├── DOCS.md                  # User-facing documentation
├── README.md                # Repository readme
├── CHANGELOG.md             # Version history
├── translations/            # UI translations
│   └── en.yaml              # English translations
├── rootfs/                  # s6-overlay v2 format (RECOMMENDED)
│   ├── README.md            # s6-overlay v2 documentation
│   ├── etc/
│   │   ├── cont-init.d/     # Initialization scripts (v2)
│   │   │   ├── 00-banner.sh
│   │   │   └── 01-setup.sh
│   │   └── services.d/      # Supervised services (v2)
│   │       └── example-app/
│   │           ├── run
│   │           └── finish
│   └── usr/bin/
│       └── example-app      # Example application
└── v3_example/              # s6-overlay v3 format (REFERENCE)
    ├── README.md            # v3 migration guide
    └── s6-overlay/
        ├── s6-rc.d/         # Service definitions (v3)
        │   ├── example-init/      # Oneshot service
        │   │   ├── type           # "oneshot"
        │   │   ├── up             # Initialization script
        │   │   └── dependencies.d/
        │   ├── example-service/   # Longrun service
        │   │   ├── type           # "longrun"
        │   │   ├── run            # Service run script
        │   │   ├── finish         # Finish script
        │   │   └── dependencies.d/
        │   └── user/              # User bundle
        │       └── contents.d/
        └── scripts/
            └── example-init.sh
```

## Quick Start

### Option 1: Discovery Mode (Recommended for existing apps)

Use the discovery script to analyze an existing GitHub repo or Docker image:

```bash
# Analyze a GitHub repository
./discover.sh https://github.com/user/repo

# Analyze a Docker image
./discover.sh linuxserver/plex:latest
./discover.sh ghcr.io/user/image:tag
```

The script will extract:
- Architecture support
- Base OS (Alpine/Debian)
- Exposed ports
- Environment variables
- Volumes
- Package installations
- Dockerfile analysis
- Recommended configuration

Use the output to guide your add-on configuration.

### Option 2: Manual Setup

1. **Copy the scaffold** to your add-on name:
   ```bash
   cp -r docs/scaffold my-addon
   cd my-addon
   ```

2. **Update config.yaml**:
   - Change `name`, `slug`, `description`
   - Update `image` path
   - Modify `options` and `schema` for your needs
   - Choose ports vs ingress (see comments)

3. **Choose s6-overlay version**:
   - **Use v2** (rootfs/etc/services.d/) - RECOMMENDED for most add-ons
   - **Use v3** (v3_example/) - Only if you need complex dependencies

4. **Implement your logic**:
   - Update `rootfs/etc/services.d/example-app/run` with your app
   - Modify `rootfs/etc/cont-init.d/01-setup.sh` for initialization
   - Update translations in `translations/en.yaml`

5. **Build and test** locally

## Discovery Tool

The `discover.sh` script helps you create add-ons from existing applications by analyzing:

**GitHub Repositories:**
- Dockerfile(s) in the repository
- Docker Compose files
- Base images and OS detection
- Package installations (apk, apt, pip, npm)
- Exposed ports and volumes
- Environment variables
- Architecture support
- Configuration files

**Docker Images:**
- Image architecture (amd64, arm64, etc.)
- Operating system
- Exposed ports
- Environment variables
- Volumes
- Entrypoint and CMD
- Multi-architecture manifest
- Image size and metadata

**Requirements:**
- `curl` (required)
- `jq` (required)
- `git` (optional - for cloning repos)
- `docker` (required for Docker image inspection)

**Error Handling:**
- Checks for missing dependencies
- Validates Docker daemon is running
- Handles failed network requests
- Provides clear error messages
- Graceful fallback for missing tools

**Example Output:**
```
./discover.sh https://github.com/user/app
  ✓ Dockerfile found
  ✓ Base Image: alpine:3.18
  ✓ OS: Alpine Linux
  ✓ Packages: python3, bash, curl
  ✓ Ports: 8080/tcp
  ✓ Volumes: /data, /config
  ✓ Architecture: amd64, aarch64

Recommendations:
  - Set arch: [amd64, aarch64]
  - Add ports: 8080/tcp
  - Map volumes: /data -> /data
  ...
```

## Configuration Features

The scaffold demonstrates:
- ✅ Image hosting on GHCR
- ✅ Both ports and ingress (with guidance comments)
- ✅ Architecture support (amd64, aarch64 only)
- ✅ Example options with validation
- ✅ Nested configuration (items array)
- ✅ Translations for all options
- ✅ Service management (manual boot)
- ✅ Directory mapping (share, addon_config)

## s6-overlay: Which Version?

### Use v2 (rootfs/etc/services.d/) if:
- ✅ First time creating an add-on
- ✅ Simple service setup (1-3 services)
- ✅ Familiar with cont-init.d pattern
- ✅ Don't need complex dependencies
- **This is the default and recommended for most use cases**

### Use v3 (v3_example/) if:
- ⚠️ Need complex service dependency chains
- ⚠️ Want declarative dependency management
- ⚠️ Using advanced s6-rc features
- ⚠️ Migrating from another s6-rc setup

## Files Explained

### Required Files
- `config.yaml` - Add-on metadata and configuration schema
- `Dockerfile` - How to build the container
- `README.md` - Repository documentation

### Optional Files
- `DOCS.md` - Shown in Home Assistant UI
- `CHANGELOG.md` - Version history
- `run.sh` - Standalone script (alternative to s6-overlay)
- `build.yaml` - Custom build configuration
- `translations/` - Multi-language support
- `rootfs/` - Files copied to container root

### Development Files
- `addon_info.json` - Used by build automation
- `build-debian.yaml` - Debian-based build config

## Configuration Patterns

### Ports vs Ingress

```yaml
# Option 1: Ingress only (embedded in HA UI)
ingress: true
ingress_port: 8099
# Remove 'ports' section

# Option 2: Ports only (direct network access)
ports:
  8080/tcp: 8080
# Remove 'ingress' section

# Option 3: Both (ingress for UI + ports for API)
ingress: true
ingress_port: 8099
ports:
  8080/tcp: 8080
```

See comments in `config.yaml` for detailed guidance.

### Options and Schema

```yaml
options:
  my_option: "default value"

schema:
  my_option: str                    # Required string
  optional: "str?"                  # Optional string
  port: "int(1024,65535)"          # Integer with range
  level: list(debug|info|warning)  # Enum/choice
```

## Customization Checklist

- [ ] Update `name`, `slug`, `description` in config.yaml
- [ ] Change `image` path to your repository
- [ ] Set `url` to your add-on's documentation/repo
- [ ] Define your `options` and `schema`
- [ ] Update translations in `translations/en.yaml`
- [ ] Implement service in `rootfs/etc/services.d/*/run`
- [ ] Add initialization in `rootfs/etc/cont-init.d/`
- [ ] Update `DOCS.md` with usage instructions
- [ ] Update `README.md` with add-on description
- [ ] Choose ports vs ingress configuration
- [ ] Test locally before publishing

## Building

```bash
# Local build
docker build -t my-addon .

# Run locally
docker run --rm -v $(pwd)/data:/data my-addon
```

## Publishing

1. Push to GitHub repository
2. Add repository to Home Assistant add-on store
3. Users can install from the store

## References

- [Add-on Configuration Docs](../ha-addons/configuration.md)
- [Add-on Tutorial](../ha-addons/tutorial.md)
- [s6-overlay v2 Docs](rootfs/README.md)
- [s6-overlay v3 Examples](v3_example/README.md)
- [Home Assistant Developer Docs](https://developers.home-assistant.io/docs/add-ons)
