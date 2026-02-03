ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Copy application from upstream image (pinned to specific digest)
FROM ghcr.io/dictionarry-hub/profilarr@sha256:9e6b08cb4210f1df1e5db05bce6d745118a44b7393a6fc84aa3c6792b2d93d1d AS app-source

# Stage 2: Build on Home Assistant base
FROM ${BUILD_FROM}

# Copy application from upstream (skip entrypoint.sh - we use s6-overlay instead)
COPY --from=app-source /app /app

# Install runtime dependencies (Debian - minimal set from upstream)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    bash \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create config directory structure
RUN mkdir -p /config/data /config/logs /config/backups /config/databases && \
    chmod 755 /config

# Copy s6-overlay configuration (v2 format)
COPY rootfs /

# Set permissions for s6 v2 scripts
RUN find /etc/services.d -type f -name "run" -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "finish" -exec chmod +x {} \; && \
    find /etc/cont-init.d -type f -exec chmod +x {} \;

WORKDIR /app

# Environment variables (defaults from upstream)
ENV PORT=6868 \
    HOST=0.0.0.0 \
    TZ=UTC

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:6868/ || exit 1

# Labels
ARG BUILD_ARCH
LABEL \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="Profilarr V2" \
  org.opencontainers.image.description="Next-generation profile manager for Radarr and Sonarr" \
  org.opencontainers.image.source="https://github.com/Dictionarry-Hub/profilarr" \
  org.opencontainers.image.licenses="AGPL-3.0"
