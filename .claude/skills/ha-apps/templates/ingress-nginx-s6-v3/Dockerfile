ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install runtime dependencies
RUN apk add --no-cache \
    nginx \
    curl \
    bash

# Copy application binary
COPY rootfs/usr/local/bin/myapp /usr/local/bin/myapp

# Copy rootfs structure (includes s6-overlay scripts and nginx config)
COPY rootfs /

# Make scripts executable
RUN chmod +x /etc/cont-init.d/*.sh \
    && chmod +x /etc/services.d/*/run \
    && chmod +x /etc/services.d/*/finish \
    && chmod +x /usr/local/bin/myapp

# Create required directories
RUN mkdir -p /data/config \
    && mkdir -p /data/logs \
    && mkdir -p /var/lib/nginx/tmp \
    && mkdir -p /run/nginx

# Set proper ownership
RUN chown -R nobody:nogroup /data \
    && chown -R nginx:nginx /var/lib/nginx \
    && chown -R nginx:nginx /run/nginx

# Health check - uses nginx /health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8099/health || exit 1
