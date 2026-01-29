ARG BUILD_FROM
ARG BUILD_VERSION
ARG BASE_IMAGE=ghcr.io/cleanuparr/cleanuparr:2.5.1

# Stage 1: Extract from upstream Cleanuparr image
# BUILD_VERSION comes automatically from config.yaml 'version' property
FROM ${BASE_IMAGE} AS app-source

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

# Install runtime dependencies (Debian)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    bash \
    tzdata \
    curl \
    python3 \
    python3-venv \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Create Python virtual environment and install Apprise
ENV VIRTUAL_ENV=/opt/apprise-venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip install --no-cache-dir apprise==1.9.6

# Install gomplate for configuration templating (architecture-aware)
ARG BUILD_ARCH
RUN GOMPLATE_ARCH=$([ "${BUILD_ARCH}" = "amd64" ] && echo "amd64" || echo "arm64") && \
    curl -o /usr/local/bin/gomplate -sSL "https://github.com/hairyhenderson/gomplate/releases/download/v3.11.5/gomplate_linux-${GOMPLATE_ARCH}" && \
    chmod +x /usr/local/bin/gomplate

# Create application directories
RUN mkdir -p /config /data && \
    chmod 755 /config /data

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

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:${HTTP_PORTS}/health || exit 1

# Labels
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
