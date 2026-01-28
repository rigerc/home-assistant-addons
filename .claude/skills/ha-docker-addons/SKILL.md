---
name: ha-docker-addons
description: This skill should be used when the user asks to "create a new add-on for [application]", "wrap [docker image] as a Home Assistant add-on", "build an add-on from existing Docker image", "set up Docker wrapper add-on", or mentions wrapping Docker images, multi-stage Dockerfiles, or S6-overlay integration for Home Assistant.
version: 0.1.0
---

# Home Assistant Docker Add-on Wrapper

## Purpose

This skill guides the creation of Home Assistant add-ons that wrap existing Docker images. Use this approach when official, well-maintained Docker images exist (like Grafana Loki, Prometheus, or LinuxServer.io images) and you want to integrate them into Home Assistant with proper configuration, S6-overlay supervision, and add-on options.

## When to Use This Skill

**Use this approach when:**
- Official, well-maintained upstream Docker image exists
- Application has complex build requirements
- Upstream provides multi-architecture support
- You want to track upstream versions easily
- Image is production-tested and stable

**Build from scratch instead when:**
- Upstream image has security issues or poor maintenance
- Significant customization is required
- Base image conflicts with Home Assistant base images
- Image is bloated with unnecessary services

## Core Workflow

### Step 1: Analyze the Upstream Image

Before starting, understand what the upstream image provides and requires.

**Inspect the Docker image:**

Use the `scripts/analyze-image.sh` helper to automate inspection and generate a summary report.

```bash
# Pull the upstream image
docker pull grafana/loki:3.6.4

# Inspect environment variables and configuration
docker inspect grafana/loki:3.6.4 | jq '.[0].Config'

# Check exposed ports
docker inspect grafana/loki:3.6.4 | jq '.[0].Config.ExposedPorts'

# Check volumes
docker inspect grafana/loki:3.6.4 | jq '.[0].Config.Volumes'
```

**Run the image interactively to explore:**

```bash
# Start interactive shell
docker run --rm -it grafana/loki:3.6.4 sh

# Inside container, locate binaries
which loki
ls -la /usr/bin/loki

# Check dependencies
ldd /usr/bin/loki

# Review default configuration
cat /etc/loki/loki.yaml
```

Use the `scripts/analyze-image.sh` helper to automate inspection and generate a summary report.

**Document findings:**
- Binary locations (e.g., `/usr/bin/loki`)
- Required shared libraries
- Configuration file locations and formats
- Port requirements
- Volume/data directory needs
- User/permission requirements
- Environment variable support

### Step 2: Create Add-on Directory Structure

Set up the standard Home Assistant add-on structure with proper organization for wrapped images.

**Create the base structure:**

```bash
mkdir -p my-addon/{rootfs/etc/s6-overlay/s6-rc.d,rootfs/defaults,translations}
cd my-addon
```

Use `scripts/scaffold-addon.sh [addon-name] [upstream-image]` to generate the complete structure automatically.

**Required files:**
- `config.yaml` - Add-on configuration and options
- `build.yaml` - Build configuration and base images
- `Dockerfile` - Multi-stage build extracting from upstream
- `CHANGELOG.md` - Version history
- `DOCS.md` - User documentation
- `README.md` - Repository introduction
- `apparmor.txt` - AppArmor security profile

**Optional but recommended:**
- `icon.png` - Add-on icon (256x256)
- `logo.png` - Add-on logo (1024x1024)
- `translations/en.yaml` - Option labels
- `.github/workflows/builder.yaml` - Automated builds

### Step 3: Write the Multi-Stage Dockerfile

Create a Dockerfile that extracts binaries from the upstream image while building on Home Assistant base images.

**Critical: BUILD_VERSION is automatically passed from config.yaml**

Home Assistant automatically passes the `version` field from config.yaml as `BUILD_VERSION` to your Dockerfile. This means:
- ✅ Version defined only in config.yaml (single source of truth)
- ✅ No need to define BUILD_VERSION in build.yaml args
- ✅ Dockerfile automatically uses config.yaml version
- ✅ Add-on version matches upstream version

**Pattern 1: Single Binary Extraction (Recommended)**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Extract from upstream image
# BUILD_VERSION comes automatically from config.yaml 'version' property
FROM grafana/loki:${BUILD_VERSION} AS app-source

# Stage 2: Build on Home Assistant base
FROM ${BUILD_FROM}

# Copy only the application binary
COPY --from=app-source /usr/bin/loki /usr/bin/loki

# Install minimal runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate

# Create application user if needed
RUN adduser -D -H -u 999 -g loki loki

# Copy S6-overlay configuration
COPY rootfs /

WORKDIR /data

# Labels
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
```

**Pattern 2: Multi-Service (Application + Database)**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG REDIS_VERSION=7.2-alpine

# Extract application (BUILD_VERSION from config.yaml)
FROM myapp/server:${BUILD_VERSION} AS app-source

# Extract Redis (fixed version)
FROM redis:${REDIS_VERSION} AS redis-source

# Combine on HA base
FROM ${BUILD_FROM}

# Copy application
COPY --from=app-source /usr/local/bin/myapp /usr/bin/myapp

# Copy Redis
COPY --from=redis-source /usr/local/bin/redis-server /usr/bin/redis-server
COPY --from=redis-source /usr/local/bin/redis-cli /usr/bin/redis-cli

# Install dependencies
RUN apk add --no-cache ca-certificates

# Copy S6 services for both
COPY rootfs /

WORKDIR /data
```

See `references/dockerfile-patterns.md` for additional patterns including LinuxServer.io image handling, architecture-specific builds, and binary extraction best practices.

### Step 4: Configure config.yaml

Create the add-on configuration that maps upstream options to Home Assistant add-on settings.

**Essential fields:**

```yaml
name: "Grafana Loki"
version: "3.6.4"  # docker:grafana/loki
slug: "grafana-loki"
description: "Log aggregation system"
url: "https://github.com/grafana/loki"

arch:
  - aarch64
  - amd64

init: false
startup: services
boot: auto

# Port configuration - use 'port' property, not in options
port: 3100
ports:
  3100/tcp: 3100    # HTTP API
  9095/tcp: null    # GRPC (optional, disabled by default)

ports_description:
  3100/tcp: "Loki HTTP API and query interface"
  9095/tcp: "GRPC endpoint for distributed mode"

# Volume mappings
map:
  - type: addon_config
    read_only: false
  - type: share
    read_only: false

# Add-on options (NOT including port)
options:
  log_level: "info"
  retention_period: "744h"
  grpc_port: 9095

schema:
  log_level: list(debug|info|warn|error)
  retention_period: str
  grpc_port: port

# Web UI
webui: "http://[HOST]:[PORT:3100]"
ingress: false

# Security
apparmor: true

# Image reference
image: "ghcr.io/username/{arch}-addon-loki"
```

**Critical: Port Configuration**
- Use config's `port` property for the main port, NOT in options
- Access main port in scripts via `bashio::addon.port 3100`
- Additional ports can go in options if needed

**Important: Version Comment for Renovate**
- Add a `# docker:image/name` comment next to the version for automatic dependency updates
- Format: `version: "3.6.4"  # docker:grafana/loki`
- The Renovate bot parses this comment to track upstream Docker image updates
- Replace `grafana/loki` with your actual upstream image name
- This enables automated PRs when new versions are released

**Map upstream settings to options:**

| Upstream Setting | Type | Add-on Option | Notes |
|-----------------|------|---------------|-------|
| `LOG_LEVEL` | env | `log_level` | Map to list |
| `HTTP_PORT` | env | config `port` | Use port property |
| `RETENTION` | config | `retention_period` | String format |
| `DATA_DIR` | path | hardcoded | Always `/data` |

### Step 5: Configure build.yaml

Define base images and build metadata.

```yaml
build_from:
  aarch64: "ghcr.io/home-assistant/aarch64-base:3.23"
  amd64: "ghcr.io/home-assistant/amd64-base:3.23"

args:
  # Optional: Document source image
  LOKI_SOURCE_IMAGE: "grafana/loki"

  # Build metadata
  BUILD_DATE: "2024-01-15"
  GOMPLATE_VERSION: "3.11.5"

labels:
  org.opencontainers.image.title: "Home Assistant Add-on: Grafana Loki"
  org.opencontainers.image.description: "Grafana Loki log aggregation"
  org.opencontainers.image.source: "https://github.com/username/addon-repo"

  # Track upstream
  io.hass.upstream.image: "grafana/loki"
  io.hass.upstream.url: "https://github.com/grafana/loki"
```

**Important:** BUILD_VERSION is automatically passed from config.yaml's `version` field. Do not define it in args.

### Step 6: Set Up S6-Overlay Services

Create S6-RC service definitions to manage the application lifecycle.

**Basic service structure:**

```
rootfs/etc/s6-overlay/s6-rc.d/
├── init-config/              # Configuration generation (oneshot)
│   ├── type
│   ├── up
│   └── dependencies.d/base
├── loki/                     # Main application (longrun)
│   ├── type
│   ├── run
│   ├── finish
│   └── dependencies.d/
│       ├── base
│       └── init-config
└── user/contents.d/
    └── loki
```

**File: `rootfs/etc/s6-overlay/s6-rc.d/loki/type`**
```
longrun
```

**File: `rootfs/etc/s6-overlay/s6-rc.d/loki/run`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Starting Grafana Loki..."

# Get configuration from add-on options
LOG_LEVEL=$(bashio::config 'log_level')
CONFIG_FILE="/data/loki-config.yaml"

# Get port from config property (not options)
HTTP_PORT=$(bashio::addon.port 3100)

# Verify config exists
if [ ! -f "${CONFIG_FILE}" ]; then
  bashio::log.error "Configuration file not found: ${CONFIG_FILE}"
  exit 1
fi

bashio::log.info "Using log level: ${LOG_LEVEL}"
bashio::log.info "Using HTTP port: ${HTTP_PORT}"

# Run application
exec /usr/bin/loki \
  -config.file="${CONFIG_FILE}" \
  -log.level="${LOG_LEVEL}"
```

**File: `rootfs/etc/s6-overlay/s6-rc.d/loki/finish`**
```bash
#!/bin/sh

if [ "$1" -eq 256 ]; then
  exit_code=$((128 + $2))
else
  exit_code="$1"
fi

echo "${exit_code}" > /run/s6-linux-init-container-results/exitcode

if [ "${exit_code}" -ne 0 ]; then
  echo "[ERROR] Loki exited with code ${exit_code}" >&2
fi
```

**Dependencies:**
- Create empty file: `rootfs/etc/s6-overlay/s6-rc.d/loki/dependencies.d/base`
- Create empty file: `rootfs/etc/s6-overlay/s6-rc.d/loki/dependencies.d/init-config`
- Create empty file: `rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/loki`

See `references/s6-overlay-guide.md` for advanced patterns including multi-service coordination, health checks, logging configurations, and init scripts.

### Step 7: Create Configuration Templates

Generate application configuration files from add-on options using gomplate.

**File: `rootfs/etc/s6-overlay/s6-rc.d/init-config/type`**
```
oneshot
```

**File: `rootfs/etc/s6-overlay/s6-rc.d/init-config/up`**
```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Generating Loki configuration..."

# Set environment for gomplate
export LOKI_HTTP_PORT=$(bashio::addon.port 3100)
export LOKI_GRPC_PORT=$(bashio::config 'grpc_port')
export LOKI_LOG_LEVEL=$(bashio::config 'log_level')
export LOKI_RETENTION=$(bashio::config 'retention_period')

# Generate configuration from template
gomplate \
  -f /defaults/loki-config.yaml.gotmpl \
  -o /data/loki-config.yaml

if [ $? -ne 0 ]; then
  bashio::log.error "Failed to generate configuration"
  exit 1
fi

bashio::log.info "Configuration generated: /data/loki-config.yaml"
```

**File: `rootfs/defaults/loki-config.yaml.gotmpl`**
```yaml
auth_enabled: false

server:
  http_listen_port: {{ getenv "LOKI_HTTP_PORT" "3100" }}
  grpc_listen_port: {{ getenv "LOKI_GRPC_PORT" "9095" }}
  log_level: {{ getenv "LOKI_LOG_LEVEL" "info" }}

common:
  path_prefix: /data/loki
  storage:
    filesystem:
      chunks_directory: /data/loki/chunks
      rules_directory: /data/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: {{ getenv "LOKI_RETENTION" "744h" }}
```

**Dependencies:**
- Create empty file: `rootfs/etc/s6-overlay/s6-rc.d/init-config/dependencies.d/base`

See `references/configuration-mapping.md` for comprehensive templating patterns, environment variable mapping, secret handling, and configuration validation techniques.

### Step 8: Create AppArmor Profile

Develop a security profile through iteration and testing.

**Start with base profile:**

```txt
#include <tunables/global>

profile loki-addon flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # S6-Overlay
  /init ix,
  /bin/** ix,
  /usr/bin/** ix,
  /command/** ix,
  /run/s6/** rw,
  /etc/s6-overlay/** rwix,

  # Application binary
  /usr/bin/loki rix,

  # Data directories
  /data/** rw,
  /share/** rw,

  # Network
  network inet stream,
  network inet6 stream,

  # System files
  /etc/passwd r,
  /etc/group r,
  /etc/hosts r,
  /etc/resolv.conf r,
  /etc/ssl/** r,
}
```

**Test and refine:**
1. Enable complain mode: Add `complain` to flags
2. Start add-on and exercise all features
3. Check audit logs: `journalctl _TRANSPORT=audit | grep -i apparmor`
4. Add required permissions
5. Remove complain flag when stable

### Step 9: Test Locally

Validate the add-on works before publishing.

**Method 1: Docker build and run**

```bash
# Build image
docker build \
  --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:latest" \
  --build-arg BUILD_ARCH="amd64" \
  -t local/loki-addon:test \
  .

# Create test data
mkdir -p /tmp/addon-test-data
cat > /tmp/addon-test-data/options.json <<EOF
{
  "log_level": "debug",
  "retention_period": "744h",
  "grpc_port": 9095
}
EOF

# Run container
docker run --rm -it \
  -v /tmp/addon-test-data:/data \
  -p 3100:3100 \
  local/loki-addon:test
```

**Method 2: VS Code devcontainer** (recommended for full HA integration)

Create `.devcontainer/devcontainer.json` and use "Reopen in Container" to get full Home Assistant environment for testing.

**Validation checklist:**
- [ ] Add-on starts successfully
- [ ] Configuration generates correctly
- [ ] Application binary executes
- [ ] Ports are accessible
- [ ] Logs appear in add-on logs
- [ ] Data persists in /data
- [ ] Options can be changed and take effect

See `references/troubleshooting.md` for common issues, debugging techniques, and solutions to permission problems, network issues, and configuration errors.

## Additional Resources

### Reference Files

Consult these files for detailed information:

- **`references/dockerfile-patterns.md`** - Complete multi-stage Dockerfile patterns, architecture handling, LinuxServer.io images, binary extraction best practices
- **`references/s6-overlay-guide.md`** - Comprehensive S6-RC service setup, init patterns, multi-service coordination, logging strategies, health checks
- **`references/configuration-mapping.md`** - Configuration templating with gomplate, environment variable mapping, port/volume configuration, secret handling
- **`references/troubleshooting.md`** - Common issues and solutions, debugging techniques, permission problems, network debugging, validation strategies

### Example Files

Complete working examples in `examples/`:

- **`examples/loki-addon/`** - Full Grafana Loki add-on implementation with Dockerfile, config files, S6 services, and templates
- **`examples/simple-wrapper/`** - Minimal single-binary wrapper pattern
- **`examples/multi-service/`** - Application + database multi-service pattern

### Scripts

Utility scripts in `scripts/`:

- **`scripts/analyze-image.sh`** - Inspect upstream Docker images and generate analysis report
- **`scripts/scaffold-addon.sh`** - Create complete add-on directory structure automatically
- **`scripts/validate-config.sh`** - Validate config.yaml and build.yaml syntax and structure

## Quick Reference

**Essential bashio commands:**
```bash
# Get add-on option
$(bashio::config 'option_name')

# Get main port from config (not options)
$(bashio::addon.port 3100)

# Check if option exists
bashio::config.has_value 'option_name'

# Logging
bashio::log.info "Message"
bashio::log.error "Error message"
```

**BUILD_VERSION behavior:**
- Automatically passed from config.yaml `version` field
- No need to define in build.yaml args
- Always available in Dockerfile as `${BUILD_VERSION}`
- Keeps add-on version in sync with upstream

**Port configuration pattern:**
```yaml
# config.yaml
port: 3100  # Main port (at root level)
options:
  other_port: 9095  # Additional ports in options
```

```bash
# Access in scripts
MAIN_PORT=$(bashio::addon.port 3100)  # From config property
OTHER_PORT=$(bashio::config 'other_port')  # From options
```

**Service dependency pattern:**
```
base → init-config → application
```

All oneshot services (init-*) must complete before longrun services start.
