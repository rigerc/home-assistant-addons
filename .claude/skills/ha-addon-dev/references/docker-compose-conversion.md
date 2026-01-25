# Converting Docker Compose to Home Assistant Add-ons

Complete guide for transforming Docker Compose configurations into Home Assistant add-ons.

## Overview

Docker Compose files define containerized applications with services, networks, volumes, and environment variables. Home Assistant add-ons use similar concepts but with a different structure optimized for the Supervisor ecosystem.

## Conversion Strategy

### Step 1: Analyze Docker Compose Structure

Identify key elements to convert:
- Service definitions → Add-on configuration
- Image specifications → Dockerfile or image reference
- Environment variables → Options and environment
- Volumes → Map configuration
- Ports → Ports configuration
- Networks → Internal DNS naming
- Depends_on → Services configuration

### Step 2: Map Compose Service to Add-on

**Docker Compose service:**
```yaml
services:
  myapp:
    image: myapp:latest
    ports:
      - "8080:80"
    environment:
      - LOG_LEVEL=info
      - DATABASE_URL=postgres://...
    volumes:
      - ./config:/config
      - ./data:/data
    restart: unless-stopped
```

**Home Assistant add-on equivalents:**

**config.yaml:**
```yaml
name: "MyApp"
version: "1.0.0"
slug: "myapp"
description: "MyApp add-on"
arch:
  - amd64
  - aarch64
  - armv7
startup: application
boot: auto
ports:
  80/tcp: 8080
map:
  - type: addon_config
    read_only: false
    path: /config
  - type: share
    read_only: false
environment:
  LOG_LEVEL: "info"
options:
  database_url: ""
schema:
  database_url: str
```

**Dockerfile:**
```dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install dependencies if needed
RUN apk add --no-cache ...

# Copy original image content or rebuild
# Option 1: Use multi-stage build from original
FROM myapp:latest as source
FROM $BUILD_FROM
COPY --from=source /app /app

# Option 2: Install application
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
```

**run.sh:**
```bash
#!/usr/bin/with-contenv bashio

# Get configuration
DATABASE_URL=$(bashio::config 'database_url')

# Export environment
export DATABASE_URL

# Start application
exec /app/start
```

## Field Mapping Reference

### Image

**Docker Compose:**
```yaml
services:
  myapp:
    image: nginx:alpine
```

**Add-on options:**

**Option 1: Use existing image (easiest)**
```yaml
# config.yaml
image: "nginx:{arch}"  # If multi-arch available
```

**Option 2: Build from base**
```dockerfile
# Dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install nginx
RUN apk add --no-cache nginx

CMD [ "nginx" ]
```

**Option 3: Multi-stage from original**
```dockerfile
# Dockerfile
FROM nginx:alpine as source

ARG BUILD_FROM
FROM $BUILD_FROM

# Copy from original image
COPY --from=source /usr/sbin/nginx /usr/sbin/
COPY --from=source /etc/nginx /etc/nginx

CMD [ "nginx" ]
```

### Build Context

**Docker Compose:**
```yaml
services:
  myapp:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        - VERSION=1.0
```

**Add-on:**
```dockerfile
# Dockerfile at add-on root
ARG BUILD_FROM
ARG BUILD_VERSION
FROM $BUILD_FROM

# Use BUILD_VERSION build arg (from config.yaml version)
ARG BUILD_VERSION
ENV APP_VERSION=${BUILD_VERSION}

# Copy application code
COPY app/ /app/

CMD [ "/app/start.sh" ]
```

### Environment Variables

**Docker Compose:**
```yaml
services:
  myapp:
    environment:
      LOG_LEVEL: info
      API_KEY: ${API_KEY}
      DEBUG: "true"
```

**Add-on:**

**Static environment (config.yaml):**
```yaml
environment:
  LOG_LEVEL: "info"
  DEBUG: "true"
```

**User-configurable (options):**
```yaml
options:
  api_key: ""
  log_level: "info"
schema:
  api_key: password
  log_level: "list(debug|info|warning|error)"
```

**run.sh:**
```bash
#!/usr/bin/with-contenv bashio

API_KEY=$(bashio::config 'api_key')
LOG_LEVEL=$(bashio::config 'log_level')

export API_KEY
export LOG_LEVEL

exec /app/start
```

### Volumes

**Docker Compose:**
```yaml
services:
  myapp:
    volumes:
      - ./config:/config
      - ./data:/data:rw
      - /etc/localtime:/etc/localtime:ro
      - myvolume:/var/lib/app
```

**Add-on mapping:**

| Compose Volume | Add-on Mapping | Path |
|---|---|---|
| `./config:/config` | `addon_config` | `/config` |
| `./data:/data` | Auto-mapped | `/data` |
| `/etc/localtime` | Handled by base image | - |
| Named volumes | `share` or `addon_config` | Custom path |

**config.yaml:**
```yaml
map:
  - type: addon_config
    read_only: false
    path: /config
  - type: share
    read_only: false
```

**Notes:**
- `/data` is always available and writable (no need to specify)
- Use `addon_config` for add-on-specific files users may edit
- Use `share` for files shared across add-ons
- Time zone is handled automatically by base images

### Ports

**Docker Compose:**
```yaml
services:
  myapp:
    ports:
      - "8080:80"
      - "8443:443"
      - "127.0.0.1:9000:9000"
```

**Add-on:**
```yaml
ports:
  80/tcp: 8080
  443/tcp: 8443
  9000/tcp: 9000
ports_description:
  80/tcp: "Web interface"
  443/tcp: "HTTPS interface"
  9000/tcp: "Admin interface (localhost only recommended)"
```

**Notes:**
- Add-on ports cannot bind to specific host IPs
- For localhost-only access, document in DOCS.md to use firewall
- Consider using Ingress instead of exposed ports

### Depends On

**Docker Compose:**
```yaml
services:
  app:
    depends_on:
      - db
      - redis
  db:
    image: postgres
  redis:
    image: redis
```

**Add-on:**

**Option 1: Multiple add-ons**
Create separate add-ons and use service dependencies:

**App add-on config.yaml:**
```yaml
services:
  - mysql:need
```

**Option 2: Single add-on with multiple processes**
Use S6-Overlay or supervisord to manage multiple processes:

**Dockerfile:**
```dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache postgresql redis

COPY rootfs /
```

**rootfs/etc/services.d/postgres/run:**
```bash
#!/usr/bin/with-contenv bashio
exec postgres -D /data/postgres
```

**rootfs/etc/services.d/redis/run:**
```bash
#!/usr/bin/with-contenv bashio
exec redis-server
```

### Networks

**Docker Compose:**
```yaml
services:
  app:
    networks:
      - frontend
      - backend
  nginx:
    networks:
      - frontend
networks:
  frontend:
  backend:
```

**Add-on:**

Home Assistant add-ons use internal DNS for communication. All add-ons can communicate using DNS names:

**Format:** `{REPO}_{SLUG}` (replace `_` with `-` for valid hostname)

**Example communication:**
```bash
# From one add-on to another
curl http://local-myapp:8080/api

# To Home Assistant
curl http://homeassistant:8123/api/states
```

**config.yaml:**
```yaml
# No explicit network configuration needed
# All add-ons are on the same internal network by default
```

### Restart Policy

**Docker Compose:**
```yaml
services:
  myapp:
    restart: unless-stopped
```

**Add-on:**
```yaml
# Controlled by Supervisor, not configurable per add-on
# Use startup and boot options instead
startup: application
boot: auto
```

### Healthcheck

**Docker Compose:**
```yaml
services:
  myapp:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Add-on:**
```yaml
watchdog: "http://[HOST]:[PORT:80]/health"
```

### Labels

**Docker Compose:**
```yaml
services:
  myapp:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.local`)"
```

**Add-on:**

Labels are not directly supported. Use add-on configuration for similar functionality:

```yaml
# config.yaml
ingress: true
panel_icon: "mdi:application"
panel_title: "MyApp"
```

### Resource Limits

**Docker Compose:**
```yaml
services:
  myapp:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          memory: 256M
```

**Add-on:**

Resource limits are not directly configurable in add-on config. Use ulimits for file descriptors and similar:

```yaml
ulimits:
  nofile: 4096
  nproc: 512
```

For memory/CPU limits, users can configure via Supervisor API or UI.

## Complete Conversion Example

### Original Docker Compose

```yaml
version: '3.8'

services:
  web:
    build: ./web
    ports:
      - "8080:80"
    environment:
      - DATABASE_URL=postgresql://db:5432/mydb
      - REDIS_URL=redis://redis:6379
      - API_KEY=${API_KEY}
    volumes:
      - ./config:/config:ro
      - ./data:/data
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:14-alpine
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Converted Add-on

**Strategy:** Create separate add-ons or use embedded services.

**Option 1: Main add-on with service dependencies (recommended)**

**config.yaml:**
```yaml
name: "MyWeb Application"
version: "1.0.0"
slug: "myweb"
description: "Web application with database"
arch:
  - amd64
  - aarch64
  - armv7
url: "https://github.com/user/myweb-addon"
startup: application
boot: auto
ports:
  80/tcp: 8080
map:
  - type: addon_config
    read_only: true
    path: /config
  - type: share
    read_only: false
services:
  - mysql:want  # Or create PostgreSQL add-on
options:
  api_key: ""
  db_password: ""
  use_redis: false
schema:
  api_key: password
  db_password: password
  use_redis: bool
```

**Dockerfile:**
```dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    redis

# Copy application
COPY web/ /app/
COPY run.sh /
RUN chmod a+x /run.sh

WORKDIR /app
RUN pip3 install -r requirements.txt

CMD [ "/run.sh" ]
```

**run.sh:**
```bash
#!/usr/bin/with-contenv bashio

# Get configuration
API_KEY=$(bashio::config 'api_key')
DB_PASSWORD=$(bashio::config 'db_password')
USE_REDIS=$(bashio::config 'use_redis')

# Set environment
export API_KEY
export DATABASE_URL="postgresql://user:${DB_PASSWORD}@postgres-addon:5432/mydb"

if bashio::var.true "${USE_REDIS}"; then
    # Start redis in background if enabled
    redis-server --daemonize yes
    export REDIS_URL="redis://localhost:6379"
fi

# Start web application
exec python3 /app/main.py
```

**Option 2: All-in-one add-on with S6-Overlay**

**config.yaml:**
```yaml
name: "MyWeb Application (All-in-One)"
version: "1.0.0"
slug: "myweb_allinone"
description: "Web application with embedded database and cache"
arch:
  - amd64
  - aarch64
  - armv7
init: false  # Using S6-Overlay
ports:
  80/tcp: 8080
map:
  - type: addon_config
    read_only: true
    path: /config
options:
  api_key: ""
  db_password: ""
schema:
  api_key: password
  db_password: password
```

**Dockerfile:**
```dockerfile
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install all services
RUN apk add --no-cache \
    python3 \
    py3-pip \
    postgresql14 \
    redis

# S6-Overlay services
COPY rootfs /

# Application
COPY web/ /app/
WORKDIR /app
RUN pip3 install -r requirements.txt
```

**rootfs/etc/services.d/postgres/run:**
```bash
#!/usr/bin/with-contenv bashio

# Initialize if needed
if [ ! -d /data/postgres ]; then
    bashio::log.info "Initializing PostgreSQL..."
    mkdir -p /data/postgres
    chown postgres:postgres /data/postgres
    su-exec postgres initdb -D /data/postgres
fi

bashio::log.info "Starting PostgreSQL..."
exec su-exec postgres postgres -D /data/postgres
```

**rootfs/etc/services.d/redis/run:**
```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Redis..."
exec redis-server \
    --dir /data/redis \
    --save 60 1
```

**rootfs/etc/services.d/web/run:**
```bash
#!/usr/bin/with-contenv bashio

# Wait for services
sleep 5

# Get configuration
API_KEY=$(bashio::config 'api_key')
DB_PASSWORD=$(bashio::config 'db_password')

export API_KEY
export DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@localhost:5432/mydb"
export REDIS_URL="redis://localhost:6379"

bashio::log.info "Starting web application..."
exec python3 /app/main.py
```

## Common Conversion Patterns

### Pattern 1: Web App with Database

**Compose:** Separate web and db services
**Add-on:** Use service dependencies or embed database

**Recommendation:** Separate add-ons for cleaner architecture

### Pattern 2: Multi-Process Application

**Compose:** Multiple service containers
**Add-on:** S6-Overlay with multiple service definitions

**Recommendation:** Use S6-Overlay for tightly coupled processes

### Pattern 3: Reverse Proxy + App

**Compose:** Nginx + Application
**Add-on:** Embedded nginx or use Ingress

**Recommendation:** Use Ingress for web UIs, embed nginx only if needed

### Pattern 4: Background Worker + Queue

**Compose:** Worker + Redis/RabbitMQ
**Add-on:** S6-Overlay or separate add-ons

**Recommendation:** Single add-on with S6 if tightly coupled

## Validation Checklist

After conversion, verify:

- [ ] All required ports exposed correctly
- [ ] Configuration options match environment variables
- [ ] Volume mappings preserve data between restarts
- [ ] Service dependencies declared if using external add-ons
- [ ] Network communication works (test DNS names)
- [ ] Startup order correct for multi-process add-ons
- [ ] Resource usage acceptable (check logs)
- [ ] Security rating acceptable (aim for 5+)
- [ ] Documentation updated for Home Assistant context

## Common Issues

### Issue: Host port binding

**Compose:**
```yaml
ports:
  - "127.0.0.1:8080:80"
```

**Problem:** Add-ons cannot bind to specific host IPs.

**Solution:** Use standard port mapping and document firewall rules:
```yaml
ports:
  80/tcp: 8080
```

### Issue: Named volumes

**Compose:**
```yaml
volumes:
  - mydata:/data
```

**Problem:** No direct equivalent for named volumes.

**Solution:** Use `/data` directory or `share` mapping:
```yaml
map:
  - type: share
    read_only: false
```

### Issue: Environment variable substitution

**Compose:**
```yaml
environment:
  - API_KEY=${API_KEY}
```

**Problem:** Shell variable substitution not available in config.yaml.

**Solution:** Use options and parse in run.sh:
```yaml
options:
  api_key: ""
schema:
  api_key: password
```

### Issue: External networks

**Compose:**
```yaml
networks:
  external_net:
    external: true
```

**Problem:** No external network concept.

**Solution:** Use internal DNS or expose via ports.

## Tools and Automation

### Conversion Script

See `scripts/compose-to-addon.sh` for automated conversion assistance.

**Usage:**
```bash
./scripts/compose-to-addon.sh docker-compose.yml output-addon/
```

Generates:
- Skeleton `config.yaml`
- Basic `Dockerfile`
- Template `run.sh`
- Service definitions if multi-process

**Note:** Manual review and adjustment always required.

## Best Practices

1. **Prefer service dependencies** over embedding multiple processes
2. **Use Ingress** instead of exposed ports for web UIs
3. **Keep configuration simple** - convert complex environment to options
4. **Document changes** from original Compose in DOCS.md
5. **Test thoroughly** - Compose and add-ons have different runtime environments
6. **Consider security** - Don't blindly enable full_access or privileged
7. **Use appropriate startup** - Match original restart policy intent
8. **Validate architecture support** - Not all images available for all archs

## Advanced: Compose Override Pattern

For development, maintain both Compose and add-on:

**docker-compose.yml** (development):
```yaml
version: '3.8'
services:
  myapp:
    build: .
    ports:
      - "8080:80"
    environment:
      - DEBUG=true
```

**Add-on** (production):
- Use same Dockerfile
- Convert environment to options
- Add Home Assistant integrations

This allows local development with Compose, deployment as add-on.
