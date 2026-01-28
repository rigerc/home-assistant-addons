# Dockerfile Patterns for Wrapped Docker Images

This reference provides comprehensive Dockerfile patterns for wrapping existing Docker images as Home Assistant add-ons.

## BUILD_VERSION Automation

Home Assistant automatically passes the `version` field from config.yaml as `BUILD_VERSION` to your Dockerfile during build.

**Key Points:**
- ✅ Version only needs to be defined in config.yaml
- ✅ No need to define BUILD_VERSION in build.yaml args
- ✅ Dockerfile always uses the version from config.yaml
- ✅ Single source of truth for version management

**Example flow:**

```yaml
# config.yaml
version: "3.6.4"
```

```dockerfile
# Dockerfile - BUILD_VERSION automatically available
ARG BUILD_VERSION
FROM grafana/loki:${BUILD_VERSION}
```

Result: `FROM grafana/loki:3.6.4`

## Pattern 1: Single Binary Extraction

**Use when:** Application provides a single binary with minimal dependencies.

**Advantages:**
- Smallest final image size
- Simple to maintain
- Clear separation of concerns
- Easy to update upstream version

**Example: Grafana Loki**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Extract from upstream
FROM grafana/loki:${BUILD_VERSION} AS loki-source

# Stage 2: Build on HA base
FROM ${BUILD_FROM}

# Copy binary only
COPY --from=loki-source /usr/bin/loki /usr/bin/loki

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate

# Create application user
RUN adduser -D -H -u 999 -g loki loki

# Copy S6-overlay configuration
COPY rootfs /

WORKDIR /data

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
```

**Finding binaries in upstream image:**

```bash
# Run container and explore
docker run --rm -it grafana/loki:3.6.4 sh

# Locate binary
which loki
# Output: /usr/bin/loki

# Check if it's statically linked
ldd /usr/bin/loki
# If "not a dynamic executable" → static binary (easy)
# If shows libraries → need to copy dependencies
```

## Pattern 2: Binary with Shared Libraries

**Use when:** Binary depends on shared libraries not in HA base image.

**Challenge:** Must identify and copy all required .so files.

**Solution:**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy binary
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Copy shared libraries
COPY --from=app-source /usr/lib/libmyapp.so* /usr/lib/
COPY --from=app-source /usr/lib/libspecial.so* /usr/lib/

# Install system library dependencies
RUN apk add --no-cache \
    libstdc++ \
    libgcc

COPY rootfs /
WORKDIR /data
```

**Identify required libraries:**

```bash
# Check dependencies
docker run --rm -it myapp/official:latest sh -c "ldd /usr/bin/myapp"

# Output shows required .so files:
# libmyapp.so.1 => /usr/lib/libmyapp.so.1
# libstdc++.so.6 => /usr/lib/libstdc++.so.6
# libc.musl-x86_64.so.1 => /lib/libc.musl-x86_64.so.1

# Copy custom libraries, install standard ones via apk
```

## Pattern 3: Complete Directory Extraction

**Use when:** Application requires multiple files (configs, plugins, static assets).

**Example: Application with plugins**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy entire application directory
COPY --from=app-source /usr/local/myapp/ /usr/local/myapp/

# Copy binaries
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp
COPY --from=app-source /usr/bin/myapp-admin /usr/bin/myapp-admin

# Copy default configuration
COPY --from=app-source /etc/myapp/ /etc/myapp/

# Install dependencies
RUN apk add --no-cache ca-certificates

COPY rootfs /
WORKDIR /data
```

**Determine what to copy:**

```bash
# List all files in upstream image
docker run --rm myapp/official:latest find / -type f | grep -v /proc | grep -v /sys

# Identify application-specific paths:
# - /usr/bin/myapp* → binaries
# - /etc/myapp/ → config files
# - /usr/local/myapp/ → application files
# - /usr/share/myapp/ → static assets
```

## Pattern 4: Multi-Service Applications

**Use when:** Application requires multiple services (app + database, app + cache).

**Example: Web App + Redis**

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG REDIS_VERSION=8.4-alpine

# Stage 1: Application
FROM myapp/server:${BUILD_VERSION} AS app-source

# Stage 2: Redis
FROM redis:${REDIS_VERSION} AS redis-source

# Stage 3: Combine
FROM ${BUILD_FROM}

# Copy application
COPY --from=app-source /usr/local/bin/myapp /usr/bin/myapp
COPY --from=app-source /usr/local/lib/myapp/ /usr/lib/myapp/

# Copy Redis
COPY --from=redis-source /usr/local/bin/redis-server /usr/bin/redis-server
COPY --from=redis-source /usr/local/bin/redis-cli /usr/bin/redis-cli

# Install dependencies for both
RUN apk add --no-cache \
    ca-certificates \
    libssl3 \
    libcrypto3

# Copy S6 services (includes services for both app and redis)
COPY rootfs /

WORKDIR /data
```

**S6 service structure for multi-service:**

```
rootfs/etc/s6-overlay/s6-rc.d/
├── redis/
│   ├── type: longrun
│   ├── run
│   └── dependencies.d/base
├── myapp/
│   ├── type: longrun
│   ├── run
│   └── dependencies.d/
│       ├── base
│       └── redis
└── user/contents.d/
    ├── redis
    └── myapp
```

## Pattern 5: LinuxServer.io Images

**Challenge:** LinuxServer.io images have their own init system (s6-overlay v2).

**Recommended: Extract Binary Only**

```dockerfile
ARG BUILD_FROM
FROM linuxserver/plex:latest AS plex-source

FROM ${BUILD_FROM}

# Extract just the application, not their init
COPY --from=plex-source /usr/lib/plexmediaserver/ /usr/lib/plexmediaserver/

# Install dependencies (check what Plex needs)
RUN apk add --no-cache \
    libstdc++ \
    gcompat \
    ca-certificates

# Use HA's S6-overlay, not LinuxServer's
COPY rootfs /

WORKDIR /data
```

**Replicate their environment setup:**

```bash
# In your run script
#!/command/with-contenv bashio

# LinuxServer.io sets these
export PUID=0
export PGID=0
export TZ=$(bashio::config 'timezone')

# Create expected directories
mkdir -p /config /transcode

# Run application directly
exec /usr/lib/plexmediaserver/Plex\ Media\ Server
```

**Not Recommended: Layer S6 on top**

```dockerfile
# Don't do this - causes init system conflicts
FROM linuxserver/plex:latest

# Trying to add another S6-overlay layer
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
```

## Pattern 6: Architecture-Specific Builds

**Use when:** Upstream image has different binaries for different architectures.

**Strategy 1: Platform-Aware FROM**

Docker automatically selects the right architecture:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Docker automatically pulls the right arch
FROM grafana/loki:${BUILD_VERSION} AS loki-source

FROM ${BUILD_FROM}

# Binary location is the same across architectures
COPY --from=loki-source /usr/bin/loki /usr/bin/loki

COPY rootfs /
```

**Strategy 2: Conditional Logic**

When architectures require different handling:

```dockerfile
ARG BUILD_FROM
ARG BUILD_ARCH
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy binary
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Architecture-specific dependencies
RUN if [ "${BUILD_ARCH}" = "aarch64" ]; then \
      apk add --no-cache libatomic; \
    fi

COPY rootfs /
```

**Strategy 3: Different Source Tags**

When upstream uses different tags per architecture:

```dockerfile
ARG BUILD_FROM
ARG BUILD_ARCH
ARG BUILD_VERSION

# Map HA arch to upstream arch tags
FROM --platform=linux/${BUILD_ARCH} \
  myapp/official:${BUILD_VERSION}-${BUILD_ARCH} AS app-source

FROM ${BUILD_FROM}

COPY --from=app-source /usr/bin/myapp /usr/bin/myapp
COPY rootfs /
```

## Pattern 7: Additional Tools Integration

**Use when:** Application needs templating, monitoring, or helper tools.

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

FROM myapp/official:${BUILD_VERSION} AS app-source

FROM ${BUILD_FROM}

# Copy application
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Install add-on tools
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    yq \
    gomplate \
    ca-certificates \
    tzdata

# Create directories
RUN mkdir -p /data/myapp /var/log/myapp

COPY rootfs /
WORKDIR /data
```

**Common additional tools:**
- `gomplate` - Template rendering (Go-based)
- `tempio` - Template rendering (Python-based, HA standard)
- `jq` - JSON processing
- `yq` - YAML processing
- `curl` - API calls and health checks
- `bash` - Advanced scripting
- `tzdata` - Timezone support

## User and Permission Handling

**Challenge:** Upstream image runs as specific user/UID, HA base runs as root.

**Solution: Create Matching User**

```dockerfile
ARG BUILD_FROM
FROM myapp/official:latest AS app-source

FROM ${BUILD_FROM}

# Check upstream user first (docker inspect or explore container)
# Suppose upstream uses uid=999, gid=999, name=myapp

# Create matching user in final image
RUN addgroup -g 999 myapp && \
    adduser -D -H -u 999 -G myapp -s /sbin/nologin myapp

# Copy application
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# Set ownership
RUN chown -R myapp:myapp /data/myapp

COPY rootfs /
```

**Run script with user:**

```bash
#!/command/with-contenv bashio

exec 2>&1

bashio::log.info "Starting myapp as user myapp"

# Ensure ownership
chown -R myapp:myapp /data/myapp

# Run as myapp user
exec s6-setuidgid myapp /usr/bin/myapp
```

## Best Practices

### 1. Preserve Executable Permissions

```dockerfile
# Permissions are preserved in COPY
COPY --from=app-source /usr/bin/myapp /usr/bin/myapp

# But verify and set explicitly if needed
RUN chmod +x /usr/bin/myapp
```

### 2. Minimal Dependencies

```dockerfile
# Install only what's needed
RUN apk add --no-cache \
    ca-certificates  # HTTPS support
    # Don't install: build tools, dev packages, docs
```

### 3. Layer Optimization

```dockerfile
# Combine RUN commands to reduce layers
RUN apk add --no-cache ca-certificates && \
    adduser -D -H myapp && \
    mkdir -p /data/myapp

# Instead of:
# RUN apk add --no-cache ca-certificates
# RUN adduser -D -H myapp
# RUN mkdir -p /data/myapp
```

### 4. Verify Extraction

```dockerfile
# After copying binary, test it
RUN /usr/bin/myapp --version || \
    (echo "Binary not working" && exit 1)
```

### 5. Document Source

```dockerfile
# Add labels to track upstream
LABEL \
  io.hass.upstream.image="grafana/loki" \
  io.hass.upstream.version="${BUILD_VERSION}" \
  io.hass.upstream.url="https://github.com/grafana/loki"
```

## Troubleshooting

### Binary Not Found

```dockerfile
# Symptom: /usr/bin/myapp: not found

# Check architecture match
RUN file /usr/bin/myapp
# Should show correct arch (x86-64, aarch64, etc.)

# Check if it's a script needing interpreter
RUN head -n 1 /usr/bin/myapp
# If #!/bin/bash, ensure bash is installed
```

### Missing Libraries

```dockerfile
# Symptom: error while loading shared libraries

# Identify missing libraries
RUN ldd /usr/bin/myapp
# Shows: libfoo.so.1 => not found

# Solution 1: Copy from source
COPY --from=app-source /usr/lib/libfoo.so* /usr/lib/

# Solution 2: Install from apk
RUN apk add --no-cache libfoo
```

### Permission Denied

```dockerfile
# Symptom: Permission denied when running binary

# Fix permissions
RUN chmod +x /usr/bin/myapp

# Or set ownership
RUN chown root:root /usr/bin/myapp && \
    chmod 755 /usr/bin/myapp
```

### Architecture Mismatch

```dockerfile
# Symptom: exec format error

# Check binary architecture
RUN file /usr/bin/myapp

# Ensure source stage uses correct arch
FROM --platform=linux/${BUILD_ARCH} \
  myapp/official:${BUILD_VERSION} AS app-source
```

## Complete Example: Prometheus

Full example wrapping Prometheus:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Extract from upstream
FROM prom/prometheus:v${BUILD_VERSION} AS prom-source

# Build on HA base
FROM ${BUILD_FROM}

# Copy Prometheus binaries
COPY --from=prom-source /bin/prometheus /usr/bin/prometheus
COPY --from=prom-source /bin/promtool /usr/bin/promtool

# Copy console templates
COPY --from=prom-source /usr/share/prometheus/console_libraries/ /usr/share/prometheus/console_libraries/
COPY --from=prom-source /usr/share/prometheus/consoles/ /usr/share/prometheus/consoles/

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate \
    bash

# Create prometheus user
RUN addgroup -g 65534 prometheus && \
    adduser -D -H -u 65534 -G prometheus -s /sbin/nologin prometheus

# Create data directories
RUN mkdir -p /data/prometheus && \
    chown -R prometheus:prometheus /data/prometheus

# Copy S6-overlay configuration
COPY rootfs /

WORKDIR /data

# Labels
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.upstream.image="prom/prometheus" \
  io.hass.upstream.url="https://github.com/prometheus/prometheus"
```

This provides a solid foundation for wrapping any Docker image as a Home Assistant add-on.

## Dockerfile Debugging Techniques

Debugging Dockerfile builds requires visibility into the build process. Use these patterns to track build progress, diagnose issues, and validate extraction results.

### Debug Logging Pattern

Add structured debug logging to track build progress:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH

# Stage 1: Extract from upstream
FROM grafana/loki:${BUILD_VERSION} AS app-source

# Stage 2: Build on HA base
FROM ${BUILD_FROM}

# Log build start
RUN echo "[BUILD] ========================================" && \
    echo "[BUILD] Starting build at $(date -u +'%Y-%m-%dT%H:%M:%SZ')" && \
    echo "[BUILD] Version: ${BUILD_VERSION}" && \
    echo "[BUILD] Architecture: ${BUILD_ARCH}" && \
    echo "[BUILD] Base image: ${BUILD_FROM}" && \
    echo "[BUILD] ========================================"

# Install dependencies with logging
RUN echo "[BUILD] Installing runtime dependencies..." && \
    apk add --no-cache \
    ca-certificates \
    gomplate && \
    echo "[BUILD] Dependencies installed successfully" && \
    apk info | sort

# Log binary copy operation
RUN echo "[BUILD] Copying application binary..." && \
    echo "[BUILD] Source: grafana/loki:${BUILD_VERSION}"

COPY --from=app-source /usr/bin/loki /usr/bin/loki

# Verify binary with detailed output
RUN echo "[BUILD] Verifying binary..." && \
    echo "[BUILD] File info:" && \
    ls -lh /usr/bin/loki && \
    echo "[BUILD] File type:" && \
    file /usr/bin/loki && \
    echo "[BUILD] Binary version:" && \
    /usr/bin/loki --version && \
    echo "[BUILD] ========================================"

# User creation with logging
RUN echo "[BUILD] Creating application user..." && \
    adduser -D -H -u 999 -g loki loki && \
    echo "[BUILD] User 'loki' created (UID: 999)" && \
    id loki

# Copy S6-overlay with file count
RUN echo "[BUILD] Copying S6-overlay configuration..." && \
    find /etc/s6-overlay -type f 2>/dev/null | wc -l | xargs -I {} echo "[BUILD] {} S6 service files found"

COPY rootfs /

WORKDIR /data

# Final build summary
RUN echo "[BUILD] ========================================" && \
    echo "[BUILD] Build completed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')" && \
    echo "[BUILD] Version: ${BUILD_VERSION}" && \
    echo "[BUILD] Architecture: ${BUILD_ARCH}" && \
    echo "[BUILD] Disk usage:" && \
    df -h | grep -E '^/dev/' && \
    echo "[BUILD] ========================================"
```

### Conditional Debug Logging

Enable verbose debugging only when needed using build arguments:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG DEBUG_BUILD=false

# Conditional debug function definition
RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[DEBUG] Build environment:"; \
      env | grep -E '^(BUILD_|DEBUG_)' | sort; \
    fi

# Debug build arguments
RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[DEBUG] BUILD_FROM=${BUILD_FROM}"; \
      echo "[DEBUG] BUILD_VERSION=${BUILD_VERSION}"; \
      echo "[DEBUG] BUILD_ARCH=${BUILD_ARCH}"; \
      echo "[DEBUG] DEBUG_BUILD=${DEBUG_BUILD}"; \
    fi

# Conditional file listing
COPY --from=app-source /usr/bin/loki /usr/bin/loki

RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[DEBUG] Listing upstream image binaries:"; \
      ls -lhR /usr/bin/ | grep -E '(loki|:)' || true; \
      echo "[DEBUG] Binary details:"; \
      file /usr/bin/loki; \
      ldd /usr/bin/loki 2>&1 || true; \
    fi

# Conditional dependency inspection
RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[DEBUG] Installed packages:"; \
      apk info -vv | sort; \
      echo "[DEBUG] Available disk space:"; \
      df -h; \
      echo "[DEBUG] Inode usage:"; \
      df -i; \
    fi

# Conditional network debugging
RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      apk add --no-cache curl && \
      echo "[DEBUG] Testing connectivity:"; \
      curl -v --connect-timeout 5 https://google.com 2>&1 | head -20 && \
      apk del curl; \
    fi
```

**Enable debug builds:**

```bash
# Enable for single build
docker build \
  --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:latest" \
  --build-arg BUILD_VERSION="3.6.4" \
  --build-arg BUILD_ARCH="amd64" \
  --build-arg DEBUG_BUILD=true \
  -t addon:debug \
  .

# Enable globally in build.yaml
args:
  DEBUG_BUILD: "true"
```

### Build Stage Debugging

Debug specific stages individually:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION

# Upstream image inspection stage
FROM grafana/loki:${BUILD_VERSION} AS app-source

# Add debug information to source stage
RUN echo "[SOURCE] Upstream image info:" && \
    echo "[SOURCE] Image: grafana/loki:${BUILD_VERSION}" && \
    echo "[SOURCE] OS:" && \
    cat /etc/os-release 2>/dev/null | head -3 && \
    echo "[SOURCE] Installed packages:" && \
    apk info -vv 2>/dev/null | sort | head -20

# Build final image
FROM ${BUILD_FROM}

# Copy with verification
COPY --from=app-source /usr/bin/loki /usr/bin/loki

RUN echo "[BUILD] Verifying extracted binary:" && \
    echo "[BUILD] Size: $(du -h /usr/bin/loki | cut -f1)" && \
    echo "[BUILD] SHA256: $(sha256sum /usr/bin/loki | cut -d' ' -f1)"
```

**Inspect intermediate stage:**

```bash
# Build only the source stage
docker build \
  --target app-source \
  --build-arg BUILD_VERSION="3.6.4" \
  -t upstream:inspect \
  .

# Explore the upstream image
docker run --rm -it upstream:inspect sh

# Inside container
which loki
ldd /usr/bin/loki
ls -la /usr/bin/
```

### Common Debug Targets

**Variable Expansion Debugging:**

```dockerfile
# Debug variable expansion
RUN echo "BUILD_VERSION is: ${BUILD_VERSION}"
RUN echo "BUILD_ARCH is: ${BUILD_ARCH}"
RUN echo "BUILD_FROM is: ${BUILD_FROM}"

# List all build arguments
RUN printenv | grep '^BUILD_' | sort

# Check if variables are set
RUN if [ -z "${BUILD_VERSION}" ]; then \
      echo "ERROR: BUILD_VERSION is not set!"; \
      exit 1; \
    fi
```

**File Operation Debugging:**

```dockerfile
# List directory contents
RUN ls -lh /usr/bin/
RUN find /usr -name '*loki*' -type f 2>/dev/null

# Verify file type
RUN file /usr/bin/loki

# Check binary dependencies
RUN ldd /usr/bin/loki

# Verify executable permissions
RUN ls -la /usr/bin/loki
RUN test -x /usr/bin/loki || (echo "Not executable!" && exit 1)
```

**Network Debugging:**

```dockerfile
# Test connectivity during build
RUN apk add --no-cache curl && \
    echo "Testing network connectivity..." && \
    curl -I https://github.com && \
    curl -I https://registry-1.docker.io && \
    apk del curl

# Debug upstream image pull
RUN echo "Attempting to pull upstream image..." && \
    docker pull grafana/loki:${BUILD_VERSION} || \
    (echo "Failed to pull grafana/loki:${BUILD_VERSION}" && exit 1)
```

**Disk Space Debugging:**

```dockerfile
# Check disk space
RUN df -h

# Find large files
RUN du -sh /* 2>/dev/null | sort -hr | head -10

# Check inode usage
RUN df -i

# Analyze layer sizes (after each major operation)
RUN echo "Size after COPY:" && du -sh /usr
RUN echo "Size after APK install:" && du -sh /lib
```

**Permission Debugging:**

```dockerfile
# Check current user
RUN whoami
RUN id

# List file permissions
RUN ls -la /usr/bin/loki
RUN ls -la /data/

# Check if binary is executable
RUN test -x /usr/bin/loki && echo "Executable" || echo "Not executable"

# Fix permissions
RUN chmod +x /usr/bin/loki
RUN chown root:root /usr/bin/loki
```

### Error Trapping

Add error trapping to catch build failures:

```dockerfile
# Trap errors with detailed output
RUN set -e && \
    echo "[BUILD] Installing dependencies..." && \
    if ! apk add --no-cache ca-certificates; then \
      echo "[ERROR] Failed to install dependencies"; \
      echo "[ERROR] Available repositories:"; \
      cat /etc/apk/repositories; \
      echo "[ERROR] Network status:"; \
      ping -c 2 8.8.8.8 || true; \
      exit 1; \
    fi && \
    echo "[BUILD] Dependencies installed successfully"

# Validate binary after copy
COPY --from=app-source /usr/bin/loki /usr/bin/loki

RUN echo "[BUILD] Validating binary..." && \
    if [ ! -f /usr/bin/loki ]; then \
      echo "[ERROR] Binary not found after copy"; \
      exit 1; \
    fi && \
    if [ ! -x /usr/bin/loki ]; then \
      echo "[ERROR] Binary is not executable"; \
      ls -la /usr/bin/loki; \
      exit 1; \
    fi && \
    VERSION=$(/usr/bin/loki --version 2>&1) && \
    echo "[BUILD] Binary version: ${VERSION}" && \
    echo "[BUILD] Binary validated successfully"
```

### Build Annotations

Add build metadata for tracking:

```dockerfile
# Capture build information
ARG BUILD_DATE
ARG VCS_REF

RUN echo "[BUILD] Build metadata:" && \
    echo "  Date: ${BUILD_DATE:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}" && \
    echo "  VCS Ref: ${VCS_REF:-unknown}" && \
    echo "  Host: ${HOSTNAME:-unknown}"

# Store build info in image
RUN echo "BUILD_VERSION=${BUILD_VERSION}" > /etc/build-info && \
    echo "BUILD_ARCH=${BUILD_ARCH}" >> /etc/build-info && \
    echo "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> /etc/build-info && \
    cat /etc/build-info

# Labels for debugging
LABEL \
  io.hass.build.date="${BUILD_DATE}" \
  io.hass.build.ref="${VCS_REF}" \
  io.hass.build.debug="${DEBUG_BUILD}"
```

### Debugging Strategies

**Strategy 1: Build Log Analysis**

```bash
# Build with full output
docker build --no-cache --progress=plain -t addon:debug .

# Save build log
docker build --no-cache --progress=plain -t addon:debug . 2>&1 | tee build.log

# Search for errors
grep -i error build.log
grep -i failed build.log
```

**Strategy 2: Interactive Build**

```bash
# Stop at specific stage
docker build --target app-source -t upstream:debug .

# Run and explore
docker run --rm -it upstream:debug sh

# Verify what you need to extract
```

**Strategy 3: Layer Inspection**

```bash
# Build image
docker build -t addon:test .

# Inspect layers
docker history addon:test

# Inspect specific layer
docker inspect addon:test | jq '.[0].RootFS.Layers'

# Run shell in built image
docker run --rm -it addon:test sh
```

**Strategy 4: BuildKit Debugging**

```bash
# Enable BuildKit debug
DOCKER_BUILDKIT=1 docker build \
  --debug \
  --progress=plain \
  -t addon:debug \
  .

# Check BuildKit logs
journalctl -u docker -f
```

### Debug Checklist

Use this checklist when debugging Dockerfile builds:

- [ ] Verify BUILD_VERSION is passed correctly
- [ ] Check architecture match between stages
- [ ] Confirm binary exists in upstream image
- [ ] Verify binary dependencies are available
- [ ] Check executable permissions
- [ ] Validate file ownership
- [ ] Confirm network connectivity (if pulling)
- [ ] Check disk space availability
- [ ] Verify S6-overlay files are copied
- [ ] Test binary execution in final image

### Example: Full Debug Dockerfile

Complete example with comprehensive debugging:

```dockerfile
ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG DEBUG_BUILD=false

# Stage 1: Extract from upstream with debug
FROM grafana/loki:${BUILD_VERSION} AS app-source

RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[SOURCE DEBUG] Upstream image inspection:"; \
      echo "[SOURCE DEBUG] OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME)"; \
      echo "[SOURCE DEBUG] Loki binary:"; \
      ls -lh /usr/bin/loki; \
      file /usr/bin/loki; \
      /usr/bin/loki --version; \
    fi

# Stage 2: Final image
FROM ${BUILD_FROM}

# Environment info
RUN echo "[BUILD] ========================================" && \
    echo "[BUILD] Build Information:" && \
    echo "[BUILD] Version: ${BUILD_VERSION}" && \
    echo "[BUILD] Architecture: ${BUILD_ARCH}" && \
    echo "[BUILD] Base: ${BUILD_FROM}" && \
    echo "[BUILD] Debug: ${DEBUG_BUILD}" && \
    echo "[BUILD] ========================================"

# Install dependencies
RUN echo "[BUILD] Installing dependencies..." && \
    apk add --no-cache ca-certificates gomplate && \
    if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[BUILD DEBUG] Installed packages:"; \
      apk info -vv | sort; \
    fi && \
    echo "[BUILD] Dependencies installed"

# Copy binary
COPY --from=app-source /usr/bin/loki /usr/bin/loki

# Verify with detailed output
RUN echo "[BUILD] Verifying binary..." && \
    if [ ! -f /usr/bin/loki ]; then \
      echo "[ERROR] Binary not found!"; exit 1; \
    fi && \
    echo "[BUILD] File info: $(ls -lh /usr/bin/loki | awk '{print $5, $9}')" && \
    echo "[BUILD] File type: $(file /usr/bin/loki | cut -d: -f2-)" && \
    VERSION=$(/usr/bin/loki --version 2>&1) && \
    echo "[BUILD] Version: ${VERSION}" && \
    if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[BUILD DEBUG] Binary dependencies:"; \
      ldd /usr/bin/loki 2>&1 || true; \
      echo "[BUILD DEBUG] Disk usage:"; \
      df -h | grep -E '^/dev/|Filesystem'; \
    fi && \
    echo "[BUILD] Binary verified"

# Create user
RUN echo "[BUILD] Creating user..." && \
    adduser -D -H -u 999 -g loki loki && \
    echo "[BUILD] User created: $(id loki)"

# Copy S6 config
COPY rootfs /

RUN if [ "${DEBUG_BUILD}" = "true" ]; then \
      echo "[BUILD DEBUG] S6 services:"; \
      find /etc/s6-overlay -type f -name 'run' -exec echo "{}" \; -exec head -5 {} \;; \
    fi

WORKDIR /data

# Build summary
RUN echo "[BUILD] ========================================" && \
    echo "[BUILD] Build Complete:" && \
    echo "[BUILD] Version: ${BUILD_VERSION}" && \
    echo "[BUILD] Architecture: ${BUILD_ARCH}" && \
    echo "[BUILD] Size: $(du -sh / | cut -f1)" && \
    echo "[BUILD] ========================================"

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.build.debug="${DEBUG_BUILD}"
```

This comprehensive debugging approach ensures build issues are caught early and can be diagnosed efficiently.
