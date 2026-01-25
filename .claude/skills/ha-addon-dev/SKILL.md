---
name: ha-addon-dev
description: This skill should be used when the user asks to "create a Home Assistant add-on", "make an HA add-on", "build a Home Assistant addon", "develop a Supervisor add-on", or wants to create, configure, test, or publish add-ons for Home Assistant.
version: 0.1.0
---

# Home Assistant Add-on Development

Create, configure, test, and publish Home Assistant add-ons following official standards and best practices.

## Purpose

Guide developers through the complete lifecycle of Home Assistant add-on development, from initial project structure to publishing in repositories. Covers configuration, Docker containerization, security, networking, API integration, and deployment strategies.

## When to Use This Skill

Use this skill when:
- Creating a new Home Assistant add-on from scratch
- Converting Docker Compose configurations to Home Assistant add-ons
- Configuring add-on options, networking, or permissions
- Integrating add-ons with Home Assistant Core or Supervisor APIs
- Testing add-ons locally or in development environments
- Publishing add-ons to repositories or container registries
- Implementing add-on security, AppArmor profiles, or Ingress
- Setting up inter-add-on communication or service discovery
- Troubleshooting add-on configuration or deployment issues

## Core Workflow

### Alternative Start: Converting from Docker Compose

If starting from an existing Docker Compose file, use the conversion workflow:

1. **Analyze the Compose file** - Identify services, ports, volumes, environment variables
2. **Run conversion script** - `scripts/compose-to-addon.sh docker-compose.yml output-dir/`
3. **Review generated files** - Check `CONVERSION_NOTES.md` for manual steps
4. **Map Compose elements** - Convert services, networks, volumes to add-on equivalents
5. **Test thoroughly** - Docker Compose and add-ons have different runtime contexts

Consult **`references/docker-compose-conversion.md`** for comprehensive conversion guide with examples for:
- Single service to add-on conversion
- Multi-service handling (separate add-ons vs S6-Overlay)
- Volume mapping strategies
- Network communication patterns
- Environment variable conversion to options
- Common conversion issues and solutions

After conversion, continue with standard workflow starting at Step 2.

### Step 1: Project Structure Setup

Create the basic add-on directory structure with required files.

**Minimum required files:**
- `config.yaml` - Add-on configuration and metadata
- `Dockerfile` - Container image definition
- `run.sh` - Startup script (entry point)

**Recommended additional files:**
- `README.md` - Brief introduction shown in add-on store
- `DOCS.md` - Detailed documentation shown in add-on info
- `CHANGELOG.md` - Version history and release notes
- `icon.png` - Square icon (128x128px recommended)
- `logo.png` - Logo for visual representation (~250x100px)
- `build.yaml` - Extended build configuration (if needed)
- `apparmor.txt` - Custom AppArmor security profile (recommended)
- `translations/en.yaml` - Configuration option translations

**Example structure:**
```
my_addon/
├── config.yaml
├── Dockerfile
├── run.sh
├── README.md
├── DOCS.md
├── CHANGELOG.md
├── icon.png
├── logo.png
├── apparmor.txt
├── build.yaml
└── translations/
    └── en.yaml
```

### Step 2: Configure Add-on Metadata

Define add-on configuration in `config.yaml` with required and optional settings.

**Required fields:**
- `name` - Display name of the add-on
- `version` - Semantic version (must match image tag if using pre-built images)
- `slug` - Unique URI-friendly identifier within repository
- `description` - Brief description of functionality
- `arch` - Supported architectures: `armhf`, `armv7`, `aarch64`, `amd64`, `i386`

**Common optional fields:**
- `url` - Homepage or documentation URL
- `startup` - When to start: `initialize`, `system`, `services`, `application`, `once`
- `boot` - Boot behavior: `auto`, `manual`, `manual_only`
- `ports` - Network port mappings: `"container-port/tcp": host-port`
- `map` - Directory mappings: `homeassistant_config`, `addon_config`, `ssl`, `share`, etc.
- `options` - Default configuration values
- `schema` - Configuration validation rules
- `ingress` - Enable web UI integration: `true/false`
- `hassio_api` - Enable Supervisor API access: `true/false`
- `homeassistant_api` - Enable Home Assistant API access: `true/false`

Consult **`references/configuration-reference.md`** for comprehensive field documentation.

### Step 3: Create Dockerfile

Build container image using Home Assistant base images with automatic architecture substitution.

**Standard template:**
```dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install required packages
RUN \
  apk add --no-cache \
    python3 \
    nginx

# Copy startup script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
```

**Available build arguments:**
- `BUILD_FROM` - Base image (automatically substituted)
- `BUILD_VERSION` - Add-on version from config.yaml
- `BUILD_ARCH` - Current architecture being built

**Base images:**
Home Assistant provides official base images with bashio pre-installed. Use `FROM $BUILD_FROM` for automatic architecture selection.

### Step 4: Write Startup Script

Create `run.sh` using bashio for configuration parsing and logging.

**Template:**
```bash
#!/usr/bin/with-contenv bashio

# Parse configuration
CONFIG_PATH=/data/options.json
TARGET="$(bashio::config 'target')"

bashio::log.info "Starting service with target: ${TARGET}"

# Your service logic here
exec your_service_command
```

**Key paths:**
- `/data` - Persistent storage volume
- `/data/options.json` - User configuration options
- Environment variable `SUPERVISOR_TOKEN` - API authentication token

Use bashio functions for configuration parsing, logging, and API communication.

### Step 5: Define Options Schema

Configure user-adjustable settings with validation rules in `config.yaml`.

**Example:**
```yaml
options:
  target: "default"
  port: 8080
  ssl: false
  credentials:
    username: "admin"
    password: null
schema:
  target: str
  port: "int(1024,65535)"
  ssl: bool
  credentials:
    username: str
    password: password
```

**Validation types:**
- `str`, `str(min,max)` - String with optional length constraints
- `int`, `int(min,max)` - Integer with optional range
- `float`, `float(min,max)` - Float with optional range
- `bool` - Boolean
- `email`, `url`, `password`, `port` - Specialized formats
- `match(REGEX)` - Custom regex pattern
- `list(val1|val2)` - Enumeration
- `device`, `device(subsystem=TYPE)` - Device filtering

**Optional values:** Add `?` suffix (e.g., `str?`) and omit from `options` to make truly optional.

See **`references/options-schema-guide.md`** for advanced schema patterns.

### Step 6: Implement API Integration

Integrate with Home Assistant Core and Supervisor APIs for enhanced functionality.

**Home Assistant Core API:**
1. Set `homeassistant_api: true` in config.yaml
2. Use `http://supervisor/core/api/` as base URL
3. Authenticate with `Authorization: Bearer ${SUPERVISOR_TOKEN}` header

**Example:**
```bash
curl -X GET \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  -H "Content-Type: application/json" \
  http://supervisor/core/api/states
```

**Supervisor API:**
1. Set `hassio_api: true` in config.yaml
2. Set `hassio_role` appropriately: `default`, `homeassistant`, `backup`, `manager`, `admin`
3. Use `http://supervisor/` as base URL
4. Authenticate with `Authorization: Bearer ${SUPERVISOR_TOKEN}` header

**WebSocket API:**
Use `ws://supervisor/core/websocket` with `SUPERVISOR_TOKEN` as password.

Consult **`references/api-integration.md`** for detailed API documentation and examples.

### Step 7: Configure Networking

Set up network communication between add-ons and Home Assistant.

**Internal DNS naming:**
Add-ons use the format: `{REPO}_{SLUG}` (replace `_` with `-` for valid hostnames)
- Local add-ons: `local_{slug}`
- Repository add-ons: `{hashed_repo}_{slug}`
- Home Assistant: `homeassistant`
- Supervisor: `supervisor`

**Port mapping:**
```yaml
ports:
  8080/tcp: 8080
  8443/tcp: null  # Disabled
```

**Host network mode:**
Set `host_network: true` to run on host network (reduces security rating).

**Services API:**
Discover shared services (MQTT, MySQL) without user configuration:
```bash
MQTT_HOST=$(bashio::services mqtt "host")
MQTT_USER=$(bashio::services mqtt "username")
MQTT_PASSWORD=$(bashio::services mqtt "password")
```

Supported services: `mqtt`, `mysql`

See **`references/networking-guide.md`** for inter-add-on communication patterns.

### Step 8: Implement Security Best Practices

Maximize add-on security rating (scale 1-6, base rating is 5).

**Increase security (+):**
- Implement Ingress (`ingress: true`) - **+2 points**
- Use auth API (`auth_api: true`) - **+1 point**
- Create custom AppArmor profile - **+1 point**
- Sign with CodeNotary - **+1 point**

**Decrease security (-):**
- Disable AppArmor - **-1 point**
- Use dangerous privileges - **-1 point**
- Use `hassio_role: manager` - **-1 point**
- Use host network - **-1 point**
- Use `hassio_role: admin` - **-2 points**
- Enable `full_access` or `docker_api` - **Security set to 1**

**AppArmor profile template:**
Create `apparmor.txt` with add-on slug substituted:
```txt
#include <tunables/global>

profile ADDON_SLUG flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Capabilities
  file,
  signal (send) set=(kill,term,int,hup,cont),

  # S6-Overlay
  /init ix,
  /bin/** ix,
  /usr/bin/** ix,

  # Access to data
  /data/** rw,
}
```

Consult **`references/security-guide.md`** for comprehensive security implementation.

### Step 9: Implement Ingress (Web UI)

Enable seamless web interface integration within Home Assistant UI.

**Requirements:**
1. Set `ingress: true` in config.yaml
2. Server listens on port 8099 (or set `ingress_port`)
3. Accept connections only from `172.30.32.2`
4. No authentication required (handled by Home Assistant)

**Nginx example:**
```nginx
server {
    listen 8099;
    allow  172.30.32.2;
    deny   all;
}
```

**Headers available:**
- `X-Ingress-Path` - Base URL path for the add-on
- `X-Remote-User-Id` - Authenticated user ID
- `X-Remote-User-Name` - Username
- `X-Remote-User-Display-Name` - Display name

See **`examples/ingress-nginx.conf`** and **`examples/ingress-addon/`** for complete examples.

### Step 10: Local Testing

Test add-ons using VS Code devcontainer or remote development.

**Recommended: VS Code devcontainer**
1. Copy devcontainer configuration files to repository
2. Open in VS Code and reopen in container
3. Run task "Start Home Assistant"
4. Access at `http://localhost:7123/`
5. Add-ons appear automatically in Local Add-ons repository

**Alternative: Remote development**
1. Install Samba or SSH add-on on Home Assistant device
2. Copy add-on to `/addons` directory
3. Comment out `image:` line in config.yaml to force local build
4. Refresh add-on store

**Local Docker build:**
```bash
docker run \
  --rm --privileged \
  -v /path/to/addon:/data \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/home-assistant/amd64-builder \
  -t /data --all --test \
  -i my-test-addon-{arch} -d local
```

Check **`references/testing-guide.md`** for comprehensive testing strategies.

### Step 11: Create Repository

Package add-on(s) in a repository for distribution.

**Repository structure:**
```
my-repository/
├── repository.yaml
└── my_addon/
    ├── config.yaml
    ├── Dockerfile
    └── run.sh
```

**repository.yaml:**
```yaml
name: "My Add-on Repository"
url: "https://github.com/user/my-addons"
maintainer: "Your Name <email@example.com>"
```

**Installation URL for users:**
```
https://github.com/user/my-addons
```

Generate a my.home-assistant.io link for one-click installation.

See **`references/repository-guide.md`** for repository management.

### Step 12: Publishing Strategy

Choose between pre-built containers (recommended) or local builds.

**Pre-built containers (recommended):**
- Build images for all architectures
- Push to container registry (Docker Hub, GHCR)
- Set `image` field in config.yaml: `ghcr.io/user/{arch}-addon-name`
- Fast installation, no build failures, better UX

**Local builds:**
- Users build on their devices
- No `image` field in config.yaml
- Slower, higher failure risk, SD card wear
- Acceptable for experimental/testing phase

**Build with official builder:**
```bash
docker run --rm --privileged \
  -v ~/.docker/config.json:/root/.docker/config.json:ro \
  ghcr.io/home-assistant/amd64-builder \
  --all -t addon-folder \
  -r https://github.com/user/addons \
  -b branchname
```

Consult **`references/publishing-guide.md`** for complete publishing workflows.

## Additional Resources

### Reference Files

For detailed information, consult:
- **`references/configuration-reference.md`** - Complete config.yaml field documentation
- **`references/options-schema-guide.md`** - Advanced schema patterns and validation
- **`references/api-integration.md`** - Home Assistant and Supervisor API details
- **`references/networking-guide.md`** - Inter-add-on communication patterns
- **`references/security-guide.md`** - Security implementation and AppArmor
- **`references/testing-guide.md`** - Testing strategies and debugging
- **`references/repository-guide.md`** - Repository management and distribution
- **`references/publishing-guide.md`** - Building and publishing workflows

### Example Files

Working examples in `examples/`:
- **`examples/basic-addon/`** - Minimal working add-on
- **`examples/ingress-addon/`** - Ingress-enabled web UI add-on
- **`examples/api-integration/`** - Home Assistant API usage
- **`examples/service-consumer/`** - MQTT/MySQL service usage

### Scripts

Utility scripts in `scripts/`:
- **`scripts/compose-to-addon.sh`** - Convert Docker Compose to add-on scaffold
- **`scripts/validate-config.sh`** - Validate config.yaml syntax
- **`scripts/create-addon.sh`** - Scaffold new add-on structure
- **`scripts/local-build.sh`** - Build add-on locally with all architectures

## Quick Reference

### Configuration Quick Start

```yaml
name: "My Add-on"
version: "1.0.0"
slug: "my_addon"
description: "Does something useful"
arch:
  - amd64
  - aarch64
  - armv7
url: "https://github.com/user/my-addon"
startup: application
boot: auto
ports:
  8080/tcp: 8080
map:
  - type: share
    read_only: false
options:
  port: 8080
schema:
  port: "int(1024,65535)"
```

### Essential Commands

**Parse configuration:**
```bash
VALUE="$(bashio::config 'key')"
```

**Logging:**
```bash
bashio::log.info "Message"
bashio::log.warning "Warning"
bashio::log.error "Error"
```

**API call:**
```bash
curl -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  http://supervisor/core/api/states
```

### Security Checklist

- [ ] Avoid `host_network: true`
- [ ] Create custom AppArmor profile
- [ ] Map directories as read-only when possible
- [ ] Use minimal `hassio_role`
- [ ] Implement Ingress for web UI
- [ ] Sign with CodeNotary
- [ ] Avoid privileged capabilities

### Testing Checklist

- [ ] Config.yaml is valid YAML
- [ ] All required fields present
- [ ] Schema matches options structure
- [ ] Dockerfile builds successfully
- [ ] Add-on starts without errors
- [ ] Configuration options work as expected
- [ ] API integrations function correctly
- [ ] Logs are readable and informative
- [ ] Security rating is acceptable

## Common Patterns

### Conditional Configuration

```bash
if bashio::config.has_value 'ssl'; then
  SSL_ENABLED=$(bashio::config 'ssl')
fi
```

### Service Discovery

```bash
if bashio::services.available 'mqtt'; then
  MQTT_HOST=$(bashio::services mqtt "host")
  # Use MQTT
fi
```

### Multi-Architecture Support

Use `{arch}` placeholder in image names:
```yaml
image: "ghcr.io/user/{arch}-my-addon"
```

### Breaking Version Management

```yaml
breaking_versions:
  - "2.0.0"
  - "3.0.0"
```

Force manual updates when crossing breaking versions.

## Best Practices

1. **Use bashio** for all configuration parsing and API access
2. **Implement Ingress** when providing web UI
3. **Create AppArmor profiles** for security
4. **Publish pre-built images** for production add-ons
5. **Document configuration options** in translations
6. **Keep changelog** for version tracking
7. **Test on multiple architectures** before release
8. **Follow semantic versioning** strictly
9. **Map directories read-only** when write access not needed
10. **Validate user input** thoroughly in schema

## Troubleshooting

**Add-on not showing in store:**
- Check Supervisor logs for validation errors
- Validate config.yaml YAML syntax
- Ensure all required fields present
- Clear browser cache (Ctrl+F5)

**Build failures:**
- Check Dockerfile syntax
- Verify base image availability
- Review build logs for missing dependencies

**API access denied:**
- Verify `hassio_api` or `homeassistant_api` set to true
- Check `hassio_role` is appropriate
- Confirm `SUPERVISOR_TOKEN` is being used correctly

**Networking issues:**
- Verify port mappings in config.yaml
- Check DNS naming format (replace `_` with `-`)
- Confirm service discovery configuration
