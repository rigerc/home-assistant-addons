ARG BUILD_FROM
FROM ghcr.io/plexguide/huntarr:9.1.1 as huntarr-source

FROM ${BUILD_FROM}

# Install Python and runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set Python environment
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv

# Create and activate virtual environment
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy Huntarr application from upstream image
COPY --from=huntarr-source /app /app

# Install Python dependencies from requirements.txt if it exists
RUN if [ -f /app/requirements.txt ]; then \
        pip install --no-cache-dir -r /app/requirements.txt; \
    fi

# Copy S6-overlay configuration (v2 legacy format)
COPY rootfs /

# Set permissions
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:9705/health || exit 1
