---
name: ha-addons
description: This skill should be used when the user asks to "create a Home Assistant add-on", "wrap a Docker image for HA", "create an HA addon", "scaffold an add-on", "convert docker-compose to add-on", "analyze for add-on creation", or mentions Home Assistant add-ons, Supervisor add-ons, or wrapping applications for Home Assistant.
version: 1.0.0
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - AskUserQuestion
---

# Home Assistant Add-on Development

Create Home Assistant add-ons using a structured 7-phase workflow with discovery tools, scaffold templates, and best practices for this repository. Do not explore the current codebase unless asked to do so.

## Purpose

Guide the creation of Home Assistant add-ons from existing Docker images, GitHub repositories, or from scratch. Follow a consistent workflow that ensures proper configuration, s6-overlay service management, and Home Assistant integration.

## When to Use This Skill

Use this skill when:
- Creating a new Home Assistant add-on
- Wrapping an existing Docker image or application for Home Assistant
- Converting a docker-compose setup to an add-on
- Analyzing an application to understand add-on requirements
- Troubleshooting add-on configuration or service issues

## Quick Start Decision Tree

**Choose the path:**

1. **Wrapping an existing application?**
   - Has GitHub repo or Docker image → Start with [Discovery Phase](#phase-1-discovery--analysis)
   - No public image/repo → Skip to [Setup Phase](#phase-2-setup--scaffolding)

2. **Creating a new application from scratch?**
   - Skip to [Setup Phase](#phase-2-setup--scaffolding)

3. **Modifying an existing add-on?**
   - Skip to [Implementation Phase](#phase-4-implementation)

## Workflow Overview

```
Phase 1: Discovery & Analysis  (if wrapping existing app)
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

## Required Information

Before starting, gather:
- **Add-on name**: Human-readable name (e.g., "My Application")
- **Add-on slug**: Directory name, lowercase with underscores (e.g., `my_application`)
- **Target directory**: Where to create the add-on (defaults to `./{slug}`)

If wrapping an existing application:
- **Source**: GitHub URL or Docker image name

**Note:** Additional files (Dockerfile, docker-compose.yaml, config examples) will be requested after discovery phase if needed for complete add-on configuration.

## Phase 1: Discovery & Analysis

### When to Use Discovery

Run discovery when wrapping an existing application to extract:
- Architecture support (amd64, aarch64, armv7)
- Base OS (Alpine, Debian)
- Exposed ports
- Environment variables
- Volumes
- Package dependencies
- Startup commands

### Running Discovery

Before proceeding, check if docker is available with the command `docker -v`.

If so:

Execute the discovery script:

```bash
# Analyze GitHub repository
.claude/skills/ha-addons/scripts/discover.sh https://github.com/user/repo

# Analyze Docker image
.claude/skills/ha-addons/scripts/discover.sh linuxserver/plex:latest
.claude/skills/ha-addons/scripts/discover.sh ghcr.io/user/image:tag
```

### Interpreting Discovery Output

Inspect `.claude/skills/ha-addons/scaffold/` for valid add-on structure.

**Architecture Support** → Use in `config.yaml` → `arch:`
**Base OS** → Choose appropriate Home Assistant base image
**Exposed Ports** → Configure `ports:` or `ingress:`
**Environment Variables** → Map to `options:` and `schema:`
**Volumes** → Map to `map:` directory entries
**Startup Command** → Use in service run script

### Post-Discovery: Gather Additional Information

**CRITICAL:** After running discovery, use the AskUserQuestion tool to gather missing information.

**Use AskUserQuestion to ask:**

Present the discovery findings and gather clarifications in a single AskUserQuestion call with multiple questions:

**Question 1: Verify Discovery Results**
- Header: "Verification"
- Question: "I analyzed [source] and found [summary of key findings]. Is this the correct application and version for the add-on?"
- Options: ["Yes, proceed", "No, different version needed", "Need to modify findings"]

**Question 2: Additional Files Available**
- Header: "Files"
- Question: "Which additional files can you provide to ensure accurate configuration?"
- Multi-select: true
- Options:
  - "Application Dockerfile" - Custom or modified Dockerfile with exact dependencies
  - "docker-compose.yaml file" - Complete environment and service configuration
  - "Configuration examples" - Example config files (.env, settings.yaml, etc.)
  - "None available" - Use discovered information only

**Question 3: Network Access Method**
- Header: "Access"
- Question: "How should users access this application?"
- Options:
  - "Ingress only (embedded in HA UI)" - Seamless HA integration, single sign-on
  - "Direct port access only" - Independent access, works with external tools
  - "Both ingress and ports" - Maximum flexibility

**Question 4: Configuration Scope**
- Header: "Config Options"
- Question: "Which configuration options should be user-configurable in Home Assistant?"
- Multi-select: true
- Options:
  - "Port number" - Allow users to change the port
  - "Log level" - Control logging verbosity
  - "All environment variables" - Expose all discovered env vars
  - "Essential options only" - Only critical settings

After receiving responses, if files were indicated as available, prompt the user to share them:
```
Please share the files you indicated:
- [List files they selected]

You can paste the file contents or provide file paths.
```

### Document Findings

After gathering additional information, create a comprehensive checklist:

```markdown
## Add-on Requirements (from discovery + clarifications)

### Basic Info
- [ ] Application: [name and version]
- [ ] Source: [GitHub URL or Docker image]

### Technical Details
- [ ] Architecture: amd64, aarch64
- [ ] Base OS: Alpine Linux
- [ ] Ports: 8080/tcp (web UI)
- [ ] Volumes: /config, /data
- [ ] Dependencies: python3, curl
- [ ] Startup: python /app/server.py

### User Configuration
- [ ] Expose port option (default: 8080)
- [ ] Expose log_level option
- [ ] Network mode: ingress + ports
- [ ] Optional: SSL support

### Additional Files Needed
- [x] Dockerfile (provided/discovered)
- [ ] docker-compose.yaml (requested)
- [ ] Configuration examples (requested)
```

## Phase 2: Setup & Scaffolding

### Copy Scaffold Template

It's MANDATORY to use 'cp' to copy the scaffold and use it as a base for the add-on.

```bash
# Copy scaffold to new add-on directory
cp -r .claude/skills/ha-addons/scaffold/ {slug}
cd {slug}
```

### Scaffold Structure

```
{slug}/
├── config.yaml              # Add-on configuration
├── Dockerfile               # Container build instructions
├── DOCS.md                  # User-facing documentation (manual)
├── README.md                # Auto-generated, do not edit
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
    │       └── app/
    │           ├── run       # Service run script
    │           └── finish    # Service finish script
    └── usr/bin/             # Application binaries
```

## Phase 3: Configuration

### Update config.yaml

Key sections to configure:

**Basic Metadata:**
```yaml
name: "My Application"
version: "1.0.0"
slug: "my_application"
description: "Description of what the add-on does"
arch:
  - amd64
  - aarch64
```

**Network Configuration - Choose ONE:**

```yaml
# Option A: Ingress only (embedded in HA UI)
ingress: true
ingress_port: 8099

# Option B: Ports only (direct network access)
ports:
  8080/tcp: 8080

# Option C: Both
ingress: true
ingress_port: 8099
ports:
  8080/tcp: 8080
```

**Volume Mapping:**
```yaml
map:
  - type: addon_config
    path: /config          # If app expects /config
  - type: media
    read_only: false       # For media access
  - type: share
    read_only: false
```

**Options and Schema:**
```yaml
options:
  log_level: info
  port: 8080

schema:
  log_level: list(trace|debug|info|warning|error)
  port: port
```

### Update Translations

Edit `translations/en.yaml` to match options:
```yaml
configuration:
  log_level:
    name: Log Level
    description: Set the logging verbosity
  port:
    name: Port
    description: Port number for the web interface
```

### Update build.yaml

```yaml
build_from:
  aarch64: ghcr.io/home-assistant/aarch64-base:3.23
  amd64: ghcr.io/home-assistant/amd64-base:3.23
```

## Phase 4: Implementation

### Update Dockerfile

```dockerfile
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install dependencies (from discovery)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash

# Copy application
COPY app/ /app/

# Copy rootfs (s6-overlay scripts)
COPY rootfs /
```

### Write Initialization Script

Edit `rootfs/etc/cont-init.d/01-setup.sh`:

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Running initialization..."

# Get configuration
PORT="$(bashio::config 'port')"
LOG_LEVEL="$(bashio::config 'log_level')"

# Create directories
mkdir -p /data/config
mkdir -p /data/logs

# Generate config file
cat > /data/config/app.conf <<EOF
port = ${PORT}
log_level = ${LOG_LEVEL}
EOF

bashio::log.info "Initialization complete"
```

### Write Service Run Script

Edit `rootfs/etc/services.d/app/run`:

```bash
#!/usr/bin/with-contenv bashio

exec 2>&1

bashio::log.info "Starting application..."

PORT="$(bashio::config 'port')"

# MUST use exec and run in foreground
exec /app/myapp --port "${PORT}" --foreground
```

## Phase 5: Testing

### Validate Add-on Structure

**MANDATORY:** Before building, validate the add-on structure using the linter:

```bash
# Validate the add-on configuration
.claude/skills/ha-addons/scripts/lint-addon.sh {slug}

# For community add-ons (requires version: "dev" and build.yaml)
.claude/skills/ha-addons/scripts/lint-addon.sh {slug} --community
```

The linter validates:
- Required fields in config.yaml and build.yaml
- Schema compliance with Home Assistant standards
- Deprecated architectures (armhf, armv7, i386)
- Deprecated configurations (auto_uart, codenotary, watchdog, squash)
- Configuration conflicts (ingress vs webui, full_access vs device options)
- Default values that can be removed
- Map folder conflicts (config vs homeassistant_config vs addon_config)

**Fix all errors before proceeding.** Warnings are informational but should be addressed when possible.

**Dependencies:** The linter requires `jq` and `yq`:
```bash
# Check if dependencies are installed
jq --version && yq --version

# Install if missing (Debian/Ubuntu)
apt install jq && snap install yq
```

### Build Locally

After validation passes:

```bash
docker build -t local/my-addon .
```

### Test Run

```bash
mkdir -p test-data
cat > test-data/options.json <<EOF
{
  "log_level": "debug",
  "port": 8080
}
EOF

docker run --rm -it \
  -v $(pwd)/test-data:/data \
  -p 8080:8080 \
  local/my-addon
```

### Verify

- Check logs for errors
- Test web interface (if applicable)
- Verify configuration changes work
- Re-run linter if configuration was modified

## Phase 6: Documentation

**DOCS.md** (manual, shown in HA UI):
- Configuration option descriptions
- Usage instructions
- Known issues and limitations

**CHANGELOG.md** (manual):
- Version history with dates
- Added/Changed/Fixed sections

**README.md** (auto-generated):
- Do not edit manually - generated from config.yaml and DOCS.md
- Updated automatically during build process

## Phase 7: Deployment

For this repository, add-ons are deployed via GitHub Actions when pushed to main. Copy .claude/skills/ha-addons/references/release-drafter-template.yml to .github/ and rename it release-drafter-{slug}.yml and edit the file to use the add-on slug.

## Additional Resources

### Reference Files

Detailed documentation in `references/`:
- **`references/discovery-clarifications.md`** - Complete guide for post-discovery questions and gathering additional files
- **`references/bashio-guide.md`** - Complete Bashio function reference
- **`references/config-reference.md`** - config.yaml options and schema types
- **`references/s6-overlay-guide.md`** - s6-overlay service management
- **`references/dockerfile-patterns.md`** - Dockerfile best practices

### Scripts

Utility scripts in `scripts/`:
- **`scripts/discover.sh`** - Analyze GitHub repos or Docker images

### Scaffold Files

Template files in `scaffold/`:
- Complete add-on template ready to customize

## Common Patterns

### SSL Configuration
```bash
if bashio::config.true 'ssl'; then
    bashio::config.require.ssl
    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"
fi
```

### Service Discovery (MQTT)
```bash
if bashio::services.available 'mqtt'; then
    MQTT_HOST="$(bashio::services mqtt 'host')"
    MQTT_PORT="$(bashio::services mqtt 'port')"
fi
```

### Wait for Dependencies
```bash
if bashio::config.has_value 'db_host'; then
    bashio::net.wait_for "${DB_PORT}" "${DB_HOST}" 120
fi
```

## Troubleshooting

**Add-on won't start:**
1. Check logs in Home Assistant UI
2. Verify all required options are set
3. Check file permissions in rootfs

**Service crashes immediately:**
1. Ensure `exec` is used in run script
2. Verify app runs in foreground mode
3. Check for missing dependencies

**Ingress not working:**
1. Verify `ingress: true` in config.yaml
2. Check app listens on `ingress_port`
3. Verify app binds to localhost
