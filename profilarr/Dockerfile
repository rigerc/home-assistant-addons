ARG BUILD_FROM
FROM santiagosayshey/profilarr:latest AS profilarr-base
FROM ${BUILD_FROM} AS final

# Install runtime dependencies
# - bash: For shell scripts
# - curl: For health checks
# - nginx: For reverse proxy (ingress)
RUN apk add --no-cache \
    bash \
    curl \
    nginx

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

WORKDIR /profilarr
EXPOSE 6099
