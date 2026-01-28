ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Extract from upstream Cleanuparr image
# BUILD_VERSION comes automatically from config.yaml 'version' property
FROM ghcr.io/cleanuparr/cleanuparr:2.5.1 AS app-source

# Stage 2: Build on Home Assistant base
FROM ${BUILD_FROM}

# Copy Cleanuparr binary with executable permissions
COPY --from=app-source /app/Cleanuparr /usr/bin/cleanuparr
RUN chmod +x /usr/bin/cleanuparr

# Copy dependency libraries (.NET self-contained app)
COPY --from=app-source /app/libMono.Unix.so /usr/lib/libMono.Unix.so
COPY --from=app-source /app/libe_sqlite3.so /usr/lib/libe_sqlite3.so

# Copy web UI assets (wwwroot directory)
COPY --from=app-source /app/wwwroot /app/wwwroot

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    gomplate \
    bash \
    icu-libs \
    libstdc++ \
    tzdata

# Create application user and directory
RUN addgroup -g 1000 appgroup && \
    adduser -u 1000 -G appgroup -D -h /config -s /sbin/nologin appuser && \
    mkdir -p /config && \
    chown -R appuser:appgroup /config

# Copy S6-overlay configuration (v2 legacy format)
COPY rootfs /

# Set permissions for S6 v2 scripts (same pattern as romm)
RUN find /etc/services.d -type f -name "run" -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

WORKDIR /

# Environment variables
ENV DOTNET_USE_POLLING_FILE_WATCHER=true \
    HTTP_PORTS=11011 \
    PUID=1000 \
    PGID=1000 \
    UMASK=022

# Labels
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
