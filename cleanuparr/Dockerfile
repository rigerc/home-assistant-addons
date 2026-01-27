ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install runtime dependencies
RUN apk add --no-cache \
    curl

# Copy root filesystem (s6-overlay service scripts)
COPY rootfs /

# Set permissions for service scripts
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Cleanuparr is a single binary application
# It will be downloaded in the run script based on architecture
