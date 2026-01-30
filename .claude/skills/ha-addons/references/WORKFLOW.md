# Home Assistant Add-on Creation Workflow

Complete step-by-step workflow for creating Home Assistant add-ons using the scaffold template and discovery tools.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start Decision Tree](#quick-start-decision-tree)
- [Workflow Overview](#workflow-overview)
- [Phase 1: Discovery & Analysis](#phase-1-discovery--analysis)
- [Phase 2: Setup & Scaffolding](#phase-2-setup--scaffolding)
- [Phase 3: Configuration](#phase-3-configuration)
- [Phase 4: Implementation](#phase-4-implementation)
- [Phase 5: Testing](#phase-5-testing)
- [Phase 6: Documentation](#phase-6-documentation)
- [Phase 7: Deployment](#phase-7-deployment)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)
- [Reference Documentation](#reference-documentation)

---

## Prerequisites

### Required Tools

- **bash** - Shell scripting
- **docker** - Container building and testing
- **curl** - HTTP requests (for discovery)
- **jq** - JSON parsing (for discovery)
- **git** - Version control (optional for discovery)

### Optional Tools

- **gh** - GitHub CLI (for creating repositories)
- **docker-compose** - Multi-container testing

### Knowledge Requirements

- Basic Docker concepts (images, containers, volumes)
- YAML syntax (for configuration files)
- Shell scripting basics (for service scripts)
- Home Assistant concepts (add-ons, Supervisor, Ingress)

---

## Quick Start Decision Tree

**Choose your path:**

1. **Wrapping an existing application?**
   - ✅ Use [Discovery Mode](#option-1-discovery-mode-recommended) → Go to Phase 1
   - ✅ Application has a GitHub repo or Docker image → Use discovery script
   - ⚠️ No public Docker image/repo → Use [Manual Mode](#option-2-manual-mode)

2. **Creating a new application from scratch?**
   - ✅ Use [Manual Mode](#option-2-manual-mode) → Go to Phase 2

3. **Modifying an existing add-on?**
   - ✅ Skip to [Phase 4: Implementation](#phase-4-implementation)

---

## Workflow Overview

```
Phase 1: Discovery & Analysis
  ↓
Phase 2: Setup & Scaffolding
  ↓
Phase 3: Configuration
  ↓
Phase 4: Implementation
  ↓
Phase 5: Testing
  ↓
Phase 6: Documentation
  ↓
Phase 7: Deployment
```

**Estimated time:**
- Simple wrapper add-on: 1-2 hours
- Medium complexity add-on: 4-8 hours
- Complex add-on with custom code: 1-2 days

---

## Phase 1: Discovery & Analysis

### When to Use Discovery

Use the discovery script when:
- Wrapping an existing application (Plex, Radarr, etc.)
- Application has a GitHub repository
- Application has a Docker image on Docker Hub/GHCR
- You want to understand requirements before building

### Running Discovery

#### Option A: Analyze GitHub Repository

```bash
cd docs/workflow/scripts
./discover.sh https://github.com/user/repo
```

**Example:**
```bash
./discover.sh https://github.com/linuxserver/docker-plex
```

#### Option B: Analyze Docker Image

```bash
./discover.sh linuxserver/plex:latest
./discover.sh ghcr.io/user/image:tag
```

### Understanding Discovery Output

The discovery script extracts:

**1. Architecture Support**
```
Architecture Support:
  ✓ Multi-architecture support detected
  Supports: amd64, aarch64, armv7
```
→ Use these values in `config.yaml` → `arch:`

**2. Base Operating System**
```
Base Images:
  - alpine:3.18
    OS: Alpine Linux
```
→ Choose appropriate Home Assistant base image

**3. Exposed Ports**
```
Exposed Ports:
  - 8080/tcp
  - 9090/tcp
```
→ Configure in `config.yaml` → `ports:` or `ingress:`

**4. Environment Variables**
```
Environment Variables:
  - TZ=UTC
  - PORT=8080
  - LOG_LEVEL=info
```
→ Map to add-on options in `config.yaml` → `options:`

**5. Volumes**
```
Volumes:
  - /config
  - /data
  - /media
```
→ Map to HA directories in `config.yaml` → `map:`

**How to map discovered volumes:**
- `/config` → Use `addon_config` (or with custom `path: /config`)
- `/data` → Already available at `/data` (no mapping needed)
- `/media` → Use `media` directory type
- `/share` → Use `share` directory type
- App config files → Consider `addon_config` with custom path

**6. Package Dependencies**
```
Package Installations:
  Alpine (apk): python3 py3-pip bash curl
  Python (pip): flask gunicorn requests
```
→ Install in Dockerfile

**7. Startup Command**
```
Entrypoint:
  ENTRYPOINT ["/init"]

CMD:
  CMD ["python", "app.py"]
```
→ Use in service run script

### Document Your Findings

Create a checklist from discovery output:

```markdown
## Add-on Requirements (from discovery)

- [ ] Architecture: amd64, aarch64, armv7
- [ ] Base OS: Alpine Linux
- [ ] Ports: 8080/tcp (web UI), 9090/tcp (API)
- [ ] Volumes: /config, /data
- [ ] Dependencies: python3, py3-pip, curl
- [ ] Environment: TZ, LOG_LEVEL
- [ ] Startup: python /app/server.py
```

---

## Phase 2: Setup & Scaffolding

### Option 1: Discovery Mode (Recommended)

**If you completed Phase 1:**

1. **Copy scaffold to your add-on directory:**

```bash
# From repository root
cp -r docs/workflow/scaffold/ my-addon
cd my-addon
```

2. **Review discovery output and scaffold:**

```bash
# Keep discovery output open for reference
cat ../discovery-output.txt  # if you saved it

# Review scaffold structure
tree
```

### Option 2: Manual Mode

**If you skipped Phase 1:**

1. **Copy scaffold:**

```bash
cp -r docs/workflow/scaffold/ my-addon
cd my-addon
```

2. **Review scaffold structure:**

```
my-addon/
├── config.yaml              # Add-on configuration
├── Dockerfile               # Container build instructions
├── DOCS.md                  # User-facing documentation
├── README.md                # Repository readme
├── CHANGELOG.md             # Version history
├── build.yaml               # Multi-arch build config
├── translations/
│   └── en.yaml              # UI translations
└── rootfs/                  # Files copied to container
    ├── etc/
    │   ├── cont-init.d/     # Initialization scripts
    │   │   ├── 00-banner.sh
    │   │   └── 01-setup.sh
    │   └── services.d/      # Supervised services
    │       └── example-app/
    │           ├── run       # Service run script
    │           └── finish    # Service finish script
    └── usr/bin/
        └── example-app       # Example application
```

### Initialize Git Repository

```bash
cd my-addon
git init
git add .
git commit -m "Initial commit from scaffold"
```

---

## Phase 3: Configuration

### Step 1: Update config.yaml

Open `config.yaml` and update with your discovery findings:

#### Basic Metadata

```yaml
name: My Application
version: "1.0.0"
slug: my-application
description: Description of what the add-on does

# GitHub repository
url: https://github.com/yourusername/ha-addon-myapp

# Your architecture (from discovery)
arch:
  - amd64
  - aarch64
  - armv7  # Only if supported
```

#### Image Configuration

```yaml
# GitHub Container Registry recommended
image: ghcr.io/{arch}/yourusername-my-application
```

**Architecture placeholders:**
- `{arch}` - Replaced with: amd64, aarch64, armv7, armhf, i386

#### Network Configuration

**Choose ONE of these approaches:**

**Option A: Ingress Only (Embedded in HA UI)**
```yaml
ingress: true
ingress_port: 8099

# Remove or comment out 'ports' section
```
→ Use when: App has a web UI that should be embedded in Home Assistant

**Option B: Ports Only (Direct Network Access)**
```yaml
ports:
  8080/tcp: 8080
  9090/tcp: 9090

# Remove or comment out 'ingress' section
```
→ Use when: App needs direct network access, no web UI, or API-only

**Option C: Both (Ingress + Ports)**
```yaml
ingress: true
ingress_port: 8099
ports:
  8080/tcp: 8080
  9090/tcp: 9090
ports_description:
  8080/tcp: Web interface
  9090/tcp: API endpoint
```
→ Use when: App has both a web UI AND needs direct port access

#### Volume Mapping

Map Home Assistant directories into your container:

**Basic examples:**

```yaml
map:
  - addon_config           # Maps to /addon_config (read-write by default for addon's own config)
  - share                  # Maps to /share (read-only by default)
  - ssl                    # Maps to /ssl (read-only by default)
  - media                  # Maps to /media (read-only by default)
  - backup                 # Maps to /backup (read-only by default)
```

**With read-write access:**

```yaml
map:
  - type: share
    read_only: false       # Allow writes to /share
  - type: media
    read_only: false       # Allow writes to /media
```

**With custom paths:**

```yaml
map:
  - type: addon_config
    path: /config          # Maps addon_config to /config instead of /addon_config
  - type: share
    path: /shared
    read_only: false
  - type: homeassistant_config
    path: /homeassistant   # Access HA configuration.yaml directory
```

**Available directory types:**

| Type | Default Path | Default Access | Description |
|------|-------------|----------------|-------------|
| `data` | `/data` | read-write | Always mounted, persistent add-on data |
| `addon_config` | `/addon_config` | read-write | Add-on's configuration directory |
| `homeassistant_config` | `/homeassistant_config` | read-only | Home Assistant configuration directory |
| `ssl` | `/ssl` | read-only | SSL certificates directory |
| `share` | `/share` | read-only | Shared data between add-ons |
| `media` | `/media` | read-only | Media directory |
| `backup` | `/backup` | read-only | Backup directory |
| `addons` | `/addons` | read-only | All add-ons directory |
| `all_addon_configs` | `/all_addon_configs` | read-only | All add-on configs |

**Common patterns:**

**Media management apps (Plex, Jellyfin):**
```yaml
map:
  - type: media
    read_only: false
  - type: share
    read_only: false
```

**Apps needing SSL certificates:**
```yaml
map:
  - ssl                    # Read-only access to /ssl
```

**Apps needing HA config access:**
```yaml
map:
  - homeassistant_config   # Access to configuration.yaml, etc.
```

**Apps with custom config location:**
```yaml
map:
  - type: addon_config
    path: /config          # Application expects config at /config
```

**Important notes:**
- The `/data` directory is **always mounted** as read-write (path can be customized)
- By default, all mapped directories are **read-only** except `addon_config`
- Use `read_only: false` to allow writes
- Custom paths must be unique and not be root (`/`)
- Custom paths must not be empty

**When to use which directory type:**

| Use Case | Directory Type | Example |
|----------|---------------|---------|
| Store add-on persistent data | `data` (automatic) | Database files, logs |
| Add-on needs own config dir | `addon_config` | App expects `/config` |
| Access HA configuration | `homeassistant_config` | Read HA secrets, config |
| Share data with other add-ons | `share` | Common datasets |
| Manage media files | `media` | Plex, Jellyfin libraries |
| Access SSL certificates | `ssl` | HTTPS configuration |
| Access HA backups | `backup` | Backup management tools |

**Example: Application expects `/config` for configuration:**

```yaml
# App discovered with: VOLUME /config
map:
  - type: addon_config
    path: /config        # Maps addon_config to /config instead of /addon_config
```

**Example: Media server needing write access:**

```yaml
# Plex/Jellyfin type application
map:
  - type: media
    read_only: false
  - type: share
    path: /downloads     # Custom path for downloads
    read_only: false
```

**Example: Backup management tool:**

```yaml
# Needs to read HA backups and write to share
map:
  - backup               # Read-only access to backups
  - type: share
    path: /archive       # Write backup archives here
    read_only: false
```

#### Add-on Options

Define user-configurable options (from discovery):

```yaml
options:
  log_level: info
  port: 8080
  ssl: false
  certfile: fullchain.pem
  keyfile: privkey.pem

schema:
  log_level: list(trace|debug|info|notice|warning|error|fatal)
  port: port
  ssl: bool
  certfile: str?
  keyfile: str?
```

**Schema types:**
- `str` - Required string
- `str?` - Optional string
- `bool` - Boolean true/false
- `int` - Integer
- `int(min,max)` - Integer with range
- `port` - Port number (1-65535)
- `list(a|b|c)` - Choice from list

#### Capabilities

Configure what the add-on can access:

```yaml
# API access
homeassistant_api: true   # Access HA REST API
hassio_api: true          # Access Supervisor API
hassio_role: default      # Permissions: default, homeassistant, manager, admin

# Hardware access
devices:
  - /dev/ttyUSB0          # USB devices
uart: true                # UART/serial access
usb: true                 # USB device detection
gpio: true                # GPIO pins (on supported hardware)

# Privileges (use sparingly)
privileged:
  - SYS_ADMIN             # Only if absolutely required

# Startup
boot: auto                # auto, manual
startup: application      # before, after services
```

### Real-World Examples

**Example 1: Simple web application (dashboard)**

```yaml
name: My Dashboard
slug: my-dashboard
arch: [amd64, aarch64]
image: ghcr.io/{arch}/my-dashboard

# Ingress only - embedded in HA UI
ingress: true
ingress_port: 8099

# No additional directories needed, uses /data for storage
# map: []  # Optional, can be omitted if only using /data

options:
  theme: dark
  refresh_interval: 30

schema:
  theme: list(light|dark)
  refresh_interval: int(5,300)
```

**Example 2: Media server (Plex/Jellyfin)**

```yaml
name: Media Server
slug: media-server
arch: [amd64, aarch64]

# Both ingress and ports
ingress: true
ingress_port: 8096
ports:
  8096/tcp: 8096
  1900/udp: 1900

# Needs media access with write permissions
map:
  - type: media
    read_only: false
  - type: share
    path: /downloads
    read_only: false
  - type: addon_config
    path: /config

options:
  transcode_quality: high

schema:
  transcode_quality: list(low|medium|high|ultra)
```

**Example 3: Configuration management tool**

```yaml
name: Config Manager
slug: config-manager
arch: [amd64, aarch64]

ingress: true
ingress_port: 3000

# Needs access to HA configuration
map:
  - homeassistant_config
  - type: backup
  - ssl

homeassistant_api: true  # Access HA API for validation

options:
  auto_backup: true

schema:
  auto_backup: bool
```

**Example 4: File sync/backup service**

```yaml
name: Cloud Sync
slug: cloud-sync
arch: [amd64, aarch64]

# No web UI, background service
startup: services
boot: auto

# Needs access to multiple directories
map:
  - type: backup
  - type: share
    read_only: false
  - type: addon_config
    path: /config
  - type: media
    read_only: false

options:
  sync_interval: 3600
  exclude_patterns: []

schema:
  sync_interval: int(300,86400)
  exclude_patterns: [str]
```

**Example 5: Database service**

```yaml
name: PostgreSQL
slug: postgres
arch: [amd64, aarch64]

ports:
  5432/tcp: 5432

# Only needs persistent storage in /data
# No map needed, uses /data by default

options:
  max_connections: 100
  shared_buffers: "256MB"

schema:
  max_connections: int(10,1000)
  shared_buffers: str
```

### Step 2: Update Translations

Edit `translations/en.yaml` to match your options:

```yaml
configuration:
  log_level:
    name: Log Level
    description: Set the logging verbosity
  port:
    name: Port
    description: Port number for the web interface
  ssl:
    name: Enable SSL
    description: Enable SSL/TLS encryption
```

### Step 3: Update Build Configuration

Edit `build.yaml` for multi-architecture builds:

```yaml
build_from:
  aarch64: ghcr.io/home-assistant/aarch64-base-python:3.11
  amd64: ghcr.io/home-assistant/amd64-base-python:3.11
  armv7: ghcr.io/home-assistant/armv7-base-python:3.11
```

**Choose base image:**
- `base` - Minimal Alpine base (~10MB)
- `base-python:3.11` - Python 3.11 on Alpine (~50MB)
- `base-debian` - Debian base (~100MB)
- `base-ubuntu` - Ubuntu base (~100MB)

**Or use Debian/Ubuntu variant** (edit `build-debian.yaml`):
```yaml
build_from:
  amd64: ghcr.io/home-assistant/amd64-base-debian:bookworm
```

---

## Phase 4: Implementation

### Step 1: Update Dockerfile

Edit `Dockerfile` based on discovery findings:

```dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install runtime dependencies (from discovery)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    curl \
    nginx

# Copy application files
WORKDIR /app
COPY app/ /app/

# Install Python dependencies (if applicable)
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy rootfs (s6-overlay scripts)
COPY rootfs /

# Labels
LABEL \
    io.hass.name="My Application" \
    io.hass.description="Description" \
    io.hass.version="1.0.0" \
    io.hass.type="addon"
```

**Debian/Alpine considerations:**

**Alpine (default):**
```dockerfile
RUN apk add --no-cache package-name
```

**Debian/Ubuntu:**
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    package-name \
    && rm -rf /var/lib/apt/lists/*
```

### Step 2: Write Initialization Scripts

Edit `rootfs/etc/cont-init.d/01-setup.sh`:

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting initialization..."

# Validate required configuration
bashio::config.require 'port'

# Get configuration values
PORT="$(bashio::config 'port')"
LOG_LEVEL="$(bashio::config 'log_level')"

bashio::log.info "Port: ${PORT}"
bashio::log.info "Log Level: ${LOG_LEVEL}"

# Create necessary directories in /data (always available, writable)
mkdir -p /data/config
mkdir -p /data/logs

# Note: If you mapped addon_config with custom path:
# mkdir -p /config  # If using: map: [{ type: addon_config, path: /config }]

# Set permissions
chown -R abc:abc /data

# Generate configuration file
cat > /data/config/app.conf <<EOF
port = ${PORT}
log_level = ${LOG_LEVEL}
data_dir = /data
EOF

# SSL configuration (if enabled)
if bashio::config.true 'ssl'; then
    bashio::log.info "SSL is enabled"
    bashio::config.require.ssl

    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"

    echo "ssl_cert = ${CERTFILE}" >> /data/config/app.conf
    echo "ssl_key = ${KEYFILE}" >> /data/config/app.conf
fi

# Service discovery (e.g., MQTT)
if bashio::services.available 'mqtt'; then
    bashio::log.info "MQTT service detected"
    MQTT_HOST="$(bashio::services mqtt 'host')"
    MQTT_PORT="$(bashio::services mqtt 'port')"

    echo "mqtt_host = ${MQTT_HOST}" >> /data/config/app.conf
    echo "mqtt_port = ${MQTT_PORT}" >> /data/config/app.conf
fi

bashio::log.info "Initialization complete"
```

**See:** [reference/BASHIO-GUIDE.md](reference/BASHIO-GUIDE.md) for all Bashio functions

### Step 3: Write Service Run Script

Edit `rootfs/etc/services.d/example-app/run`:

**For Alpine (s6-overlay v2):**

```bash
#!/usr/bin/with-contenv bashio

# Set log level
bashio::log.level "$(bashio::config 'log_level' 'info')"

bashio::log.info "Starting application..."

# Get configuration
PORT="$(bashio::config 'port')"
CONFIG_FILE="/data/config/app.conf"

# Wait for dependencies (if needed)
if bashio::config.has_value 'db_host'; then
    DB_HOST="$(bashio::config 'db_host')"
    DB_PORT="$(bashio::config 'db_port' '5432')"

    bashio::log.info "Waiting for database..."
    bashio::net.wait_for "${DB_PORT}" "${DB_HOST}" 120
fi

# Start the application
bashio::log.info "Starting on port ${PORT}..."

# Run as non-root user (if applicable)
exec s6-setuidgid abc \
    python3 /app/server.py \
        --config "${CONFIG_FILE}" \
        --port "${PORT}"
```

**For applications with their own entrypoint:**

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting application with entrypoint..."

# Export configuration as environment variables
export PORT="$(bashio::config 'port')"
export LOG_LEVEL="$(bashio::config 'log_level')"
export DATA_DIR="/data"

# Run original entrypoint
exec /app/entrypoint.sh
```

### Step 4: Write Finish Script (Optional)

Edit `rootfs/etc/services.d/example-app/finish`:

```bash
#!/bin/sh
# Finish script runs when service exits

# $1 = exit code (256 if killed by signal)
# $2 = signal number (if killed by signal)

if test "$1" -eq 0; then
    echo "Service exited cleanly"
elif test "$1" -eq 256; then
    echo "Service killed by signal ${2}"
    echo "$((128 + ${2}))" > /run/s6-linux-init-container-results/exitcode
else
    echo "Service exited with code ${1}"
    echo "${1}" > /run/s6-linux-init-container-results/exitcode
fi
```

### Step 5: Ingress Configuration (If Using Ingress)

If using `ingress: true`, configure your application:

**Option A: Application supports base path**

Configure app to run at ingress path:
```bash
INGRESS_PORT="$(bashio::addon.ingress_port)"
INGRESS_PATH="$(bashio::addon.ingress_entry)"

# Start app with base path
exec myapp --port "${INGRESS_PORT}" --base-path "${INGRESS_PATH}"
```

**Option B: Use NGINX proxy**

Create `rootfs/etc/nginx/nginx.conf`:
```nginx
server {
    listen {{ .ingress_port }};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Ingress-Path $http_x_ingress_path;
    }
}
```

---

## Phase 5: Testing

### Step 1: Build Locally

```bash
# Build for your architecture
docker build -t local/my-addon .

# Check image size
docker images local/my-addon
```

**Troubleshooting build errors:**
- Check Dockerfile syntax
- Verify all COPY sources exist
- Check base image availability
- Review build logs carefully

### Step 2: Test Run

```bash
# Create test data directory
mkdir -p test-data

# Create test options.json
cat > test-data/options.json <<EOF
{
  "log_level": "debug",
  "port": 8080,
  "ssl": false
}
EOF

# Run container
docker run --rm -it \
  -v $(pwd)/test-data:/data \
  -p 8080:8080 \
  local/my-addon
```

### Step 3: Verify Functionality

**Check logs:**
```bash
docker logs <container-id>
```

**Expected log output:**
```
[00:00:00] INFO: Starting initialization...
[00:00:01] INFO: Port: 8080
[00:00:01] INFO: Log Level: debug
[00:00:02] INFO: Initialization complete
[00:00:03] INFO: Starting application...
```

**Test the application:**
```bash
# Test web interface
curl http://localhost:8080

# Test API endpoints
curl http://localhost:8080/api/status
```

### Step 4: Test Configuration Changes

**Test different options:**

```bash
# Test with SSL enabled
cat > test-data/options.json <<EOF
{
  "log_level": "info",
  "port": 8443,
  "ssl": true,
  "certfile": "fullchain.pem",
  "keyfile": "privkey.pem"
}
EOF

docker restart <container-id>
```

**Test error conditions:**
```bash
# Test missing required config
cat > test-data/options.json <<EOF
{}
EOF

# Should exit with error message
docker restart <container-id>
```

### Step 5: Test in Home Assistant (Local Add-on)

**1. Copy add-on to Home Assistant:**

```bash
# SSH to Home Assistant
ssh root@homeassistant.local

# Create local add-ons directory
mkdir -p /addons/my-addon

# Copy files (from your development machine)
scp -r my-addon/* root@homeassistant.local:/addons/my-addon/
```

**2. Reload add-on store:**
- Go to **Settings** → **Add-ons** → ⋮ (menu) → **Check for updates**
- Your add-on should appear under "Local add-ons"

**3. Install and test:**
- Click on your add-on
- Click **Install**
- Configure options
- Click **Start**
- Check logs

---

## Phase 6: Documentation

### Step 1: Update README.md

```markdown
# Home Assistant Add-on: My Application

Description of what the add-on does.

## About

This add-on wraps [Application Name](https://example.com) for Home Assistant.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install "My Application"
3. Configure the add-on
4. Start the add-on

## Configuration

```yaml
log_level: info
port: 8080
ssl: false
```

### Option: `log_level`

Set logging verbosity.

### Option: `port`

Port number for the web interface.

## Support

- [GitHub Issues](https://github.com/user/repo/issues)
- [Home Assistant Community](https://community.home-assistant.io/)
```

### Step 2: Update DOCS.md

```markdown
# Configuration

## Option: `log_level`

The `log_level` option controls the verbosity of log output.

**Values:**
- `trace` - Very verbose
- `debug` - Debug information
- `info` - Normal (default)
- `warning` - Warnings only
- `error` - Errors only

## Option: `port`

Port number for the web interface (1-65535).

**Default:** `8080`

## Option: `ssl`

Enable SSL/TLS encryption.

**When enabled, you must also configure:**
- `certfile` - Certificate file in `/ssl/`
- `keyfile` - Private key file in `/ssl/`

## Example Configuration

```yaml
log_level: info
port: 8080
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
```

## Known Issues

List any known issues or limitations.

## Support

For issues and questions, please use:
- [GitHub Issues](https://github.com/user/repo/issues)
```

### Step 3: Update CHANGELOG.md

```markdown
# Changelog

## [1.0.0] - 2024-01-30

### Added
- Initial release
- Support for amd64, aarch64, armv7
- Configuration options for port and logging
- SSL support
- Ingress support

### Changed
- N/A

### Fixed
- N/A
```

---

## Phase 7: Deployment

### Option A: GitHub Repository Method

#### Step 1: Create Repository

```bash
# Initialize git (if not done)
git init
git add .
git commit -m "Initial release v1.0.0"

# Create GitHub repository (using gh CLI)
gh repo create ha-addon-myapp --public

# Push to GitHub
git branch -M main
git remote add origin https://github.com/username/ha-addon-myapp.git
git push -u origin main
```

#### Step 2: Create repository.json

Create `repository.json` in repository root:

```json
{
  "name": "My Add-ons Repository",
  "url": "https://github.com/username/ha-addons",
  "maintainer": "Your Name <your.email@example.com>"
}
```

#### Step 3: Setup GitHub Actions for Building

Create `.github/workflows/builder.yml`:

```yaml
name: Builder

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    name: Build ${{ matrix.arch }}
    strategy:
      matrix:
        arch: [amd64, aarch64, armv7]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build addon
        uses: home-assistant/builder@master
        with:
          args: |
            --${{ matrix.arch }} \
            --target my-addon \
            --docker-hub ghcr.io/${{ github.repository_owner }}
```

#### Step 4: Add Repository to Home Assistant

**Users will:**
1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click ⋮ (menu) → **Repositories**
3. Add: `https://github.com/username/ha-addon-myapp`
4. Find and install your add-on

### Option B: Manual Distribution

#### Build for All Architectures

```bash
# Build for amd64
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest \
  -t ghcr.io/username/amd64-my-addon:1.0.0 .

# Build for aarch64
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest \
  -t ghcr.io/username/aarch64-my-addon:1.0.0 .

# Build for armv7
docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/armv7-base:latest \
  -t ghcr.io/username/armv7-my-addon:1.0.0 .
```

#### Push Images

```bash
# Login to registry
docker login ghcr.io

# Push all architectures
docker push ghcr.io/username/amd64-my-addon:1.0.0
docker push ghcr.io/username/aarch64-my-addon:1.0.0
docker push ghcr.io/username/armv7-my-addon:1.0.0
```

---

## Advanced Topics

### Using s6-overlay v3

For complex dependency chains, use s6-overlay v3 format.

**See:** [scaffold/v3_example/README.md](scaffold/v3_example/README.md)

**Example structure:**
```
rootfs/
└── s6-overlay/
    └── s6-rc.d/
        ├── myapp-init/          # Oneshot initialization
        │   ├── type             # "oneshot"
        │   ├── up               # Init script
        │   └── dependencies.d/
        │       └── base         # Depends on base
        ├── myapp/               # Longrun service
        │   ├── type             # "longrun"
        │   ├── run              # Service script
        │   └── dependencies.d/
        │       └── myapp-init   # Depends on init
        └── user/
            └── contents.d/
                └── myapp        # Add to user bundle
```

### Publishing Services for Discovery

Make your add-on discoverable:

```bash
#!/usr/bin/with-contenv bashio

# Start MQTT broker
mosquitto -c /data/mosquitto.conf &

# Publish service
bashio::services.publish 'mqtt' \
    "$(bashio::var.json \
        host '127.0.0.1' \
        port '^1883' \
        username 'mqtt' \
        password 'secret' \
        protocol '^5')"

# Wait for process
wait
```

### Multi-Stage Builds

Reduce image size:

```dockerfile
# Build stage
FROM python:3.11-alpine AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# Runtime stage
ARG BUILD_FROM
FROM $BUILD_FROM
COPY --from=builder /install /usr/local
COPY app/ /app/
```

### Custom Base Images

For special requirements:

```dockerfile
FROM alpine:3.18

# Install s6-overlay manually
ARG S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Install Home Assistant add-on requirements
RUN apk add --no-cache bash jq curl

ENTRYPOINT ["/init"]
```

---

## Troubleshooting

### Build Issues

**Error: `COPY failed: no source files`**
- Check that source paths exist
- Verify paths are relative to Dockerfile location

**Error: `failed to solve with frontend dockerfile.v0`**
- Check Dockerfile syntax
- Verify all instructions are valid

**Error: `manifest for ghcr.io/home-assistant/... not found`**
- Check base image name
- Verify architecture is supported

### Runtime Issues

**Add-on won't start**
1. Check logs in Home Assistant UI
2. Look for errors in initialization scripts
3. Verify all required options are set
4. Check file permissions in rootfs

**Configuration not working**
1. Verify `options.json` syntax
2. Check schema in `config.yaml`
3. Test with `bashio::config` functions
4. Enable debug logging

**Service crashes immediately**
1. Check service run script has execute permissions
2. Verify `exec` is used in run script
3. Check for missing dependencies
4. Review application logs

**Ingress not working**
1. Verify `ingress: true` in config.yaml
2. Check application listens on ingress_port
3. Verify application runs on localhost
4. Check NGINX proxy configuration

### Permission Issues

**Error: `Permission denied`**
- Check file ownership in container
- Use `chown` in init script
- Verify service runs as correct user

**Error: `Operation not permitted`**
- Check if privileged access is needed
- Add required capabilities in config.yaml
- Review Docker security settings

### Common Mistakes

1. **Forgetting `exec` in run script**
   ```bash
   # Wrong - creates zombie processes
   python app.py

   # Correct - replaces shell process
   exec python app.py
   ```

2. **Not using bashio for config**
   ```bash
   # Wrong - doesn't validate
   PORT=$(jq -r '.port' /data/options.json)

   # Correct - validates and provides defaults
   PORT="$(bashio::config 'port' '8080')"
   ```

3. **Hardcoding paths**
   ```bash
   # Wrong - not portable
   INGRESS_PORT=8099

   # Correct - dynamic
   INGRESS_PORT="$(bashio::addon.ingress_port)"
   ```

---

## Reference Documentation

### Internal References

- [Discovery Script Documentation](scripts/DISCOVERY.md)
- [Scaffold Documentation](scaffold/SCAFFOLD_README.md)
- [s6-overlay v2 Guide](reference/s6-overlay.md)
- [Bashio Function Reference](reference/BASHIO-GUIDE.md)
- [Dockerfile Reference](reference/dockerfile-ref.md)

### External References

- [Home Assistant Add-on Documentation](https://developers.home-assistant.io/docs/add-ons)
- [Add-on Configuration Reference](https://developers.home-assistant.io/docs/add-ons/configuration)
- [s6-overlay Official Documentation](https://github.com/just-containers/s6-overlay)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions for Add-ons](https://github.com/home-assistant/builder)

---

## Quick Reference Cheat Sheet

### Essential Bashio Functions

```bash
# Configuration
bashio::config 'option_name'                    # Get value
bashio::config.require 'option_name'            # Require value
bashio::config.true 'bool_option'               # Check if true
bashio::config.has_value 'option_name'          # Has value?

# Logging
bashio::log.info "message"                      # Info log
bashio::log.warning "message"                   # Warning
bashio::log.error "message"                     # Error
bashio::log.debug "message"                     # Debug

# Add-on Info
bashio::addon.ingress_port                      # Get ingress port
bashio::addon.ingress_entry                     # Get ingress path

# Services
bashio::services.available 'mqtt'               # Check if available
bashio::services mqtt 'host'                    # Get service config

# Network
bashio::net.wait_for 8080                       # Wait for port
```

### Common config.yaml Patterns

```yaml
# Basic add-on
name: My Add-on
version: "1.0.0"
slug: my-addon
description: Short description
arch: [amd64, aarch64]
image: ghcr.io/{arch}/my-addon

# With ingress
ingress: true
ingress_port: 8099

# With ports
ports:
  8080/tcp: 8080

# With options
options:
  port: 8080
schema:
  port: port
```

### Service Run Script Template

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting..."

PORT="$(bashio::config 'port')"

exec s6-setuidgid abc \
    /app/myapp --port "${PORT}"
```

---

**Next Steps:**
- Start with [Phase 1: Discovery](#phase-1-discovery--analysis) for existing apps
- Jump to [Phase 2: Setup](#phase-2-setup--scaffolding) for new apps
- Review [Reference Documentation](#reference-documentation) for details
