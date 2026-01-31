ARG BUILD_FROM
FROM ghcr.io/plexguide/huntarr:9.1.1 as huntarr-source

FROM ${BUILD_FROM}

# Install Python and runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set Python environment
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1

# Copy Huntarr application from upstream image
COPY --from=huntarr-source /app /app

# Copy S6-overlay configuration (v2 legacy format)
COPY rootfs /

# Set permissions
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:9705/health || exit 1
