---
name: ha-apps
description: Creates Home Assistant add-ons from existing Docker images with ingress support. Use when user asks to "wrap a Docker app for HA", "create HA add-on from Docker image", "analyze Docker image for add-on", "make ingress add-on", or wants to convert existing containerized applications into Home Assistant add-ons with web UI integration.
---

# Home Assistant Add-on Creator (from Docker Images)

Specialized skill for creating Home Assistant add-ons from existing Docker images with automatic ingress (embedded web UI) support.

## What This Skill Does

This skill helps you:
1. **Analyze Docker images** - Use the discovery script to extract configuration from existing Docker images
2. **Scaffold add-on structure** - Generate complete add-on directory with all required files
3. **Configure ingress** - Set up nginx reverse proxy for embedded Home Assistant web UI
4. **Apply best practices** - Follow Home Assistant add-on standards with s6-overlay v3 process supervision

## When to Use This Skill

Use this skill when:
- Converting an existing Docker application to a Home Assistant add-on
- Creating an add-on with a web interface that should appear in the Home Assistant sidebar
- Wrapping third-party containerized services for Home Assistant
- Building add-ons that need ingress (embedded UI) support
- Analyzing a Docker image to understand its structure for add-on creation

## Quick Start Workflow

### 1. Discover Docker Image Configuration

First, analyze the target Docker image to understand its structure:

```bash
# Run the discovery script
bash .claude/skills/ha-apps/scripts/discover.sh <docker-image>

# Examples:
bash .claude/skills/ha-apps/scripts/discover.sh linuxserver/plex:latest
bash .claude/skills/ha-apps/scripts/discover.sh ghcr.io/user/myapp:v1.0
bash .claude/skills/ha-apps/scripts/discover.sh https://github.com/user/repo
```

The discovery script will output:
- Base image and OS information
- Exposed ports
- Environment variables
- Volume mounts
- Entrypoint and CMD
- Package installations
- Architecture support

### 2. Create Add-on Directory Structure

Use the scaffold template as a starting point:

```bash
# Copy scaffold to your add-on directory
cp -r .claude/skills/ha-apps/scaffold/ /path/to/addons/myapp/

# Or for ingress-enabled add-on:
cp -r .claude/skills/ha-apps/templates/ingress-nginx-s6-v3/ /path/to/addons/myapp/
```

### 3. Configure the Add-on

Edit the key configuration files based on discovery output:

#### config.yaml
```yaml
name: "My Application"
version: "1.0.0"
slug: "my_application"
description: "My application wrapped for Home Assistant"
arch:
  - amd64
  - aarch64

# Enable ingress for embedded web UI
ingress: true
ingress_port: 8099
panel_icon: "mdi:application"

# Map discovered ports (if not using ingress)
# ports:
#   8080/tcp: 8080

# Map discovered volumes
map:
  - type: addon_config
    path: /config
  - ssl
  - share

# API access
homeassistant_api: true
hassio_api: true

# Options from discovery
options:
  port: 8080
  ssl: false

schema:
  port: port
  ssl: bool
```

#### Dockerfile

For **ingress-enabled** add-ons (using the ingress-nginx-s6-v3 template):

```dockerfile
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install s6-overlay v3
ARG S6_OVERLAY_VERSION="3.2.2.0"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Install nginx for ingress
RUN apk add --no-cache nginx

# Install your application
RUN apk add --no-cache \
    python3 \
    your-app-dependencies

# Copy rootfs (includes nginx config and s6 services)
COPY rootfs /

# Set up entrypoint
ENTRYPOINT ["/init"]
```

For **basic** add-ons (using the scaffold template):

```dockerfile
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install your application and dependencies
RUN apk add --no-cache \
    bash \
    your-app-dependencies

# Copy rootfs structure
COPY rootfs /

# Standard entrypoint for HA add-ons
CMD ["/run.sh"]
```

## Directory Structure

### Ingress-Enabled Add-on (templates/ingress-nginx-s6-v3/)

```
myapp/
├── config.yaml                          # Add-on configuration
├── Dockerfile                           # Container build instructions
├── build.yaml                           # Multi-arch build config
├── DOCS.md                              # Add-on documentation
├── README.md                            # GitHub README
├── rootfs/
│   ├── etc/
│   │   ├── cont-init.d/                # Init scripts (run once at startup)
│   │   │   ├── 10-banner.sh           # Show startup banner
│   │   │   ├── 20-nginx.sh            # Configure nginx
│   │   │   └── 30-app.sh              # Configure your app
│   │   ├── services.d/                 # S6 service definitions
│   │   │   ├── app/
│   │   │   │   ├── run                # Run your application
│   │   │   │   └── finish             # Handle app exit
│   │   │   └── nginx/
│   │   │       ├── run                # Run nginx
│   │   │       └── finish             # Handle nginx exit
│   │   └── nginx/
│   │       ├── nginx.conf             # Main nginx config
│   │       ├── servers/
│   │       │   └── ingress.conf       # Ingress proxy config
│   │       └── includes/              # Reusable nginx configs
│   └── usr/local/bin/
│       └── myapp                      # Your application binary
└── translations/
    └── en.yaml                         # UI translations
```

### Basic Add-on (scaffold/)

```
myapp/
├── config.yaml                          # Add-on configuration
├── Dockerfile                           # Container build instructions
├── build.yaml                           # Multi-arch build config
├── DOCS.md                              # Add-on documentation
├── README.md                            # GitHub README
├── run.sh                               # Main startup script
├── rootfs/
│   ├── etc/
│   │   ├── cont-init.d/                # Init scripts
│   │   │   ├── 00-banner.sh
│   │   │   └── 01-setup.sh
│   │   └── services.d/                 # S6 services (optional)
│   │       └── example-app/
│   │           ├── run
│   │           └── finish
│   └── usr/bin/
│       └── example-app                 # Your application
└── translations/
    └── en.yaml
```

## Key Components Explained

### S6-Overlay v3 Process Supervision

S6-overlay provides proper init system for containers:

**Init stages:**
1. **cont-init.d/** - One-time initialization scripts (numbered 00-99)
2. **services.d/** - Long-running supervised services
3. **cont-finish.d/** - Cleanup scripts on shutdown

**Service structure** (`services.d/myapp/`):
- `run` - Script to start your service (must run in foreground)
- `finish` - Optional cleanup when service exits

Example service run script:
```bash
#!/command/execlineb -P
with-contenv
s6-setuidgid abc
/usr/local/bin/myapp --config /config/myapp.conf
```

See `@references/s6-overlay.md` for detailed documentation.

### Bashio Helper Functions

Bashio provides convenient bash functions for Home Assistant add-ons:

```bash
#!/usr/bin/env bashio

# Logging
bashio::log.info "Starting application..."
bashio::log.warning "Port already in use"
bashio::log.error "Failed to start"

# Read add-on options
PORT=$(bashio::config 'port')
SSL=$(bashio::config 'ssl')

# Check if option exists
if bashio::config.has_value 'ssl_cert'; then
    CERT=$(bashio::config 'ssl_cert')
fi

# API calls
bashio::api.supervisor GET /info
bashio::services.publish "mqtt" \
    "host=core-mosquitto" \
    "port=1883"
```

See `@references/bashio-reference.md` for complete API reference.

### Ingress Configuration

**What is ingress?**
Ingress allows your add-on's web UI to be embedded directly in Home Assistant, accessible via the sidebar without exposing ports.

**How it works:**
1. Your app runs on internal port (e.g., 8080)
2. Nginx proxies from ingress port (8099) to your app
3. Home Assistant routes `/api/hassio_ingress/<addon>/` to your nginx
4. Users access via Home Assistant UI sidebar

**Nginx ingress configuration** (`rootfs/etc/nginx/servers/ingress.conf`):

```nginx
server {
    listen 8099 default_server;

    location / {
        allow 172.30.32.2;
        deny all;

        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Init script to configure nginx** (`rootfs/etc/cont-init.d/20-nginx.sh`):

```bash
#!/usr/bin/env bashio

bashio::log.info "Configuring nginx..."

# Get ingress configuration
INGRESS_PORT=$(bashio::addon.ingress_port)
bashio::log.info "Ingress will be available on port ${INGRESS_PORT}"

# Update nginx config
sed -i "s/listen 8099/listen ${INGRESS_PORT}/g" /etc/nginx/servers/ingress.conf
```

### Build Configuration

**build.yaml** - Multi-architecture builds:

```yaml
build_from:
  amd64: "ghcr.io/home-assistant/amd64-base:3.19"
  aarch64: "ghcr.io/home-assistant/aarch64-base:3.19"

args:
  S6_OVERLAY_VERSION: "3.2.2.0"
```

Home Assistant base images come with:
- Proper init system
- bashio pre-installed
- Common utilities
- Multi-arch support

### Configuration Schema

Define user-configurable options in `config.yaml`:

```yaml
options:
  port: 8080
  log_level: info
  ssl: false
  certfile: fullchain.pem
  keyfile: privkey.pem

schema:
  port: port                              # Port number (1-65535)
  log_level: list(trace|debug|info|warning|error)
  ssl: bool
  certfile: str?                          # Optional string
  keyfile: str?
```

Access in scripts:
```bash
PORT=$(bashio::config 'port')
LOG_LEVEL=$(bashio::config 'log_level')
```

See `@references/config-reference.md` for all schema types.

## Common Patterns

### Pattern 1: Simple Web Application

For apps with a single web interface:

1. Use ingress template
2. Configure nginx to proxy to your app's port
3. Set `ingress: true` in config.yaml
4. Add init script to start your app

### Pattern 2: Service with Optional Web UI

For apps that can run headless or with UI:

1. Use basic scaffold
2. Make ingress conditional:
```yaml
# config.yaml
options:
  enable_ui: true

schema:
  enable_ui: bool
```

3. In init script:
```bash
if bashio::config.true 'enable_ui'; then
    # Enable nginx
    bashio::log.info "Enabling web UI"
fi
```

### Pattern 3: Multi-Service Application

For apps with multiple components:

1. Create multiple service directories in `services.d/`
2. Use dependencies in s6-rc format (see v3_example/)
3. Each service gets its own run/finish scripts

```
services.d/
├── database/
│   ├── run
│   └── finish
├── backend/
│   ├── run
│   └── finish
└── frontend/
    ├── run
    └── finish
```

## Discovery Script Details

The discovery script (`scripts/discover.sh`) analyzes:

**For Docker images:**
```bash
bash discover.sh linuxserver/plex:latest
```
- Pulls image and inspects metadata
- Extracts environment variables, volumes, ports
- Analyzes Docker history for package installations
- Detects base OS and architecture

**For GitHub repositories:**
```bash
bash discover.sh https://github.com/user/repo
```
- Clones repository
- Finds and analyzes Dockerfile
- Extracts docker-compose configuration
- Searches for documentation

**Output includes:**
- Architecture support recommendations
- Port mappings for config.yaml
- Volume mapping suggestions
- Base image information
- Package dependencies to install
- Environment variables to expose as options

## Testing Your Add-on

### Local Testing

1. Build the add-on:
```bash
docker build -t local/myapp .
```

2. Run with Home Assistant:
```bash
docker run --rm \
  -v /path/to/config:/config \
  -v /path/to/data:/data \
  -p 8099:8099 \
  local/myapp
```

3. Check logs:
```bash
docker logs -f <container-id>
```

### Development in Home Assistant

1. Add local add-on repository:
   - Go to Supervisor → Add-on Store → ⋮ → Repositories
   - Add your repository path

2. Install and test:
   - Install add-on from local repository
   - Configure options
   - Start add-on
   - Check logs in Supervisor → Add-on → Log tab

### Common Issues

**Add-on won't start:**
- Check Dockerfile builds successfully
- Verify ENTRYPOINT or CMD is correct
- Check service run scripts are executable
- Review logs for error messages

**Ingress not working:**
- Verify `ingress: true` in config.yaml
- Check nginx is listening on correct port
- Ensure your app accepts connections from 127.0.0.1
- Check nginx logs in add-on logs

**Options not being read:**
- Verify schema matches options structure
- Check bashio::config calls use correct keys
- Ensure default values are valid

## Advanced Topics

### Custom S6 Services (v3 format)

The `v3_example/` directory shows s6-rc service format:

```
s6-overlay/s6-rc.d/
├── myapp/                    # Service definition
│   ├── type                  # "longrun" or "oneshot"
│   ├── run                   # Start script
│   ├── finish                # Exit handler
│   └── dependencies.d/       # Service dependencies
│       └── base              # Wait for base services
└── user/
    └── contents.d/
        └── myapp             # Register service
```

### Environment Variables

Expose configuration as environment variables:

```bash
#!/usr/bin/env bashio

# Read options
export APP_PORT=$(bashio::config 'port')
export APP_LOG_LEVEL=$(bashio::config 'log_level')
export APP_DATA_DIR="/data"

# Start app with environment
exec /usr/local/bin/myapp
```

### Volume Permissions

Handle volume ownership in init script:

```bash
#!/usr/bin/env bashio

# Ensure directories exist with correct permissions
mkdir -p /data/app
chown -R abc:abc /data/app

# Or use bashio helpers
bashio::fs.directory_exists "/config/app" || mkdir -p "/config/app"
```

### Multi-Architecture Support

Build for multiple architectures:

```yaml
# build.yaml
build_from:
  amd64: "ghcr.io/home-assistant/amd64-base:3.19"
  aarch64: "ghcr.io/home-assistant/aarch64-base:3.19"
  armv7: "ghcr.io/home-assistant/armv7-base:3.19"
```

Use build arguments for arch-specific downloads:

```dockerfile
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
    amd64) ARCH=x86_64 ;; \
    aarch64) ARCH=aarch64 ;; \
    armv7) ARCH=armv7 ;; \
    esac && \
    wget https://example.com/app-${ARCH}.tar.gz
```

## Reference Documentation

This skill includes comprehensive reference documentation:

- **bashio-reference.md** - Complete bashio API reference with examples
- **s6-overlay.md** - Official s6-overlay v3 documentation
- **dockerfile-ref.md** - Dockerfile instruction reference
- **config-reference.md** - Complete config.yaml schema reference

## Example: Creating a Plex Add-on

Let's walk through creating a Plex Media Server add-on:

### 1. Discover Plex Image

```bash
bash scripts/discover.sh linuxserver/plex:latest
```

Output shows:
- Base: Ubuntu
- Ports: 32400/tcp, 1900/udp, etc.
- Volumes: /config, /movies, /tv
- Environment: PUID, PGID, TZ

### 2. Create Add-on Structure

```bash
cp -r templates/ingress-nginx-s6-v3/ ~/addons/plex/
cd ~/addons/plex/
```

### 3. Configure config.yaml

```yaml
name: "Plex Media Server"
version: "1.0.0"
slug: "plex"
description: "Plex Media Server for Home Assistant"
arch:
  - amd64
  - aarch64

ingress: true
ingress_port: 8099
panel_icon: "mdi:plex"

map:
  - type: addon_config
    path: /config
  - type: media
    path: /media
    read_only: false

options:
  claim_token: ""

schema:
  claim_token: str?
```

### 4. Update Dockerfile

```dockerfile
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install s6-overlay
ARG S6_OVERLAY_VERSION="3.2.2.0"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Install nginx and dependencies
RUN apk add --no-cache nginx curl

# Install Plex
RUN curl -o /tmp/plexmediaserver.tar.gz \
    https://downloads.plex.tv/plex-media-server-new/1.32.0.6100/linux/PlexMediaServer-1.32.0.6100-x86_64.tar.gz && \
    tar -xzf /tmp/plexmediaserver.tar.gz -C /opt

COPY rootfs /

ENTRYPOINT ["/init"]
```

### 5. Configure Nginx (rootfs/etc/nginx/servers/ingress.conf)

```nginx
server {
    listen 8099;

    location / {
        allow 172.30.32.2;
        deny all;

        proxy_pass http://127.0.0.1:32400;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
    }
}
```

### 6. Create Plex Service (rootfs/etc/services.d/plex/run)

```bash
#!/command/execlineb -P
with-contenv
s6-setuidgid abc
/opt/plexmediaserver/Plex\ Media\ Server
```

### 7. Add Init Script (rootfs/etc/cont-init.d/30-plex.sh)

```bash
#!/usr/bin/env bashio

bashio::log.info "Configuring Plex Media Server..."

# Get claim token if provided
if bashio::config.has_value 'claim_token'; then
    CLAIM_TOKEN=$(bashio::config 'claim_token')
    bashio::log.info "Using claim token for Plex setup"
    export PLEX_CLAIM="${CLAIM_TOKEN}"
fi

# Set Plex preferences
export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/config"
```

### 8. Test

```bash
# Build
docker build -t local/plex .

# Run
docker run --rm \
  -v $(pwd)/test-config:/config \
  -v $(pwd)/test-media:/media \
  -p 8099:8099 \
  local/plex
```

### 9. Access via Home Assistant

After installing in HA:
- Add-on appears in sidebar with Plex icon
- Click to access Plex web interface
- All traffic proxied through Home Assistant ingress
- No need to expose port 32400

## Tips and Best Practices

1. **Always use ingress** for web UIs - Better user experience and security
2. **Use bashio helpers** - Cleaner code and better error handling
3. **Follow s6 best practices** - Proper process supervision and init
4. **Test multi-arch** - Build and test on both amd64 and aarch64
5. **Document options** - Clear descriptions in DOCS.md
6. **Version properly** - Semantic versioning (1.0.0, 1.1.0, 2.0.0)
7. **Include translations** - At minimum English in translations/en.yaml
8. **Handle secrets safely** - Use options schema with password type
9. **Log appropriately** - Use bashio logging for consistency
10. **Clean up temp files** - Remove downloads in Dockerfile

## Resources

- [Home Assistant Add-on Documentation](https://developers.home-assistant.io/docs/add-ons)
- [S6-Overlay Documentation](https://github.com/just-containers/s6-overlay)
- [Bashio GitHub](https://github.com/hassio-addons/bashio)
- [Home Assistant Base Images](https://github.com/home-assistant/docker-base)
- [Add-on Example Repository](https://github.com/home-assistant/addons-example)

## Troubleshooting

### Add-on won't install
- Check config.yaml syntax is valid YAML
- Verify all required fields are present
- Check image exists and is accessible

### Ingress shows 502 error
- Ensure your app is listening on 127.0.0.1 or 0.0.0.0
- Check nginx is running: `ps aux | grep nginx`
- Verify proxy_pass port matches your app's port

### Options not applying
- Check schema matches options structure exactly
- Use `bashio::config 'key'` not environment variables
- Verify default values in options are valid

### Service won't start
- Make run script executable: `chmod +x run`
- Check script has proper shebang
- Ensure service runs in foreground (no & or daemon mode)
- Check dependencies in dependencies.d/ exist

### Logs show permission errors
- Use s6-setuidgid in service run scripts
- Set correct ownership in init scripts
- Check volume permissions on host

## Next Steps

After creating your add-on:

1. **Test thoroughly** - Install in Home Assistant and test all features
2. **Write documentation** - Complete DOCS.md with all options and usage
3. **Create repository** - Set up GitHub repository for add-on
4. **Configure CI/CD** - Use GitHub Actions for automated builds
5. **Publish** - Share with community via add-on repository
6. **Maintain** - Keep dependencies updated and respond to issues

## Summary

This skill provides everything needed to create professional Home Assistant add-ons from Docker images:

- **Discovery script** to analyze existing images
- **Scaffold templates** for quick setup
- **Ingress template** for embedded web UIs
- **Reference docs** for all HA add-on technologies
- **Examples and patterns** for common scenarios

Use the discovery script to understand your target application, choose the appropriate template (basic or ingress), customize the configuration, and test thoroughly before publishing.
