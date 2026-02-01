ARG BUILD_FROM
ARG BUILD_VERSION

# Stage 1: Copy application from upstream image
FROM santiagosayshey/profilarr:v1.1.3 AS app-source

# Stage 2: Build on Home Assistant base
FROM ${BUILD_FROM}

# Copy application from upstream (skip entrypoint.sh - we use s6-overlay instead)
COPY --from=app-source /app /app

# Install runtime dependencies (Debian)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    ca-certificates \
    bash \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir --break-system-packages \
    Flask==2.0.1 \
    Flask-CORS==3.0.10 \
    PyYAML==5.4.1 \
    requests==2.26.0 \
    Werkzeug==2.0.1 \
    GitPython==3.1.24 \
    regex==2023.10.3 \
    APScheduler==3.10.4 \
    gunicorn==21.2.0 \
    aiohttp==3.8.5 \
    asyncio==3.4.3

# Create data directory
RUN mkdir -p /data && chmod 755 /data

# Copy S6-overlay configuration (v2 legacy format)
COPY rootfs /

# Set permissions for S6 v2 scripts
RUN find /etc/services.d -type f -name "run" -exec chmod +x {} \; && \
    find /etc/services.d -type f -name "finish" -exec chmod +x {} \; && \
    find /etc/cont-init.d -type f -exec chmod +x {} \;

WORKDIR /app

# Environment variables
ENV PORT=6868 \
    HOST=0.0.0.0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:6868/health || exit 1

# Labels
ARG BUILD_ARCH
LABEL \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}"
