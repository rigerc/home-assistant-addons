ARG BUILD_FROM
ARG BUILD_VERSION
FROM santiagosayshey/profilarr:v1.1.3 AS profilarr-base
FROM ${BUILD_FROM} AS final

# Install runtime dependencies (Debian)
# - bash: For shell scripts
# - curl: For health checks
# - nginx: For reverse proxy (ingress)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Copy application files from official Profilarr image
COPY --from=profilarr-base /app /profilarr

# Copy Python virtual environment and binaries from base image
COPY --from=profilarr-base /usr/local/bin /usr/local/bin
COPY --from=profilarr-base /usr/local/lib /usr/local/lib

# Copy s6-overlay service configuration
COPY rootfs/ /

# Make s6 scripts executable
RUN chmod +x /etc/cont-init.d/* /etc/services.d/*/run /etc/services.d/*/finish 2>/dev/null || true

# Set environment for Python
ENV PYTHONPATH=/profilarr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=/profilarr/main.py

EXPOSE 6099
