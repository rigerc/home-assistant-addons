ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install runtime dependencies
# Common packages:
# - bash: Shell scripting
# - python3/py3-pip: Python support
# - nodejs/npm: Node.js support
# - nginx: Web server
# - curl/wget: Download tools
# - git: Version control
# - tzdata: Timezone data
RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip

# Copy application files (if any)
# COPY app /app

# Copy root filesystem (s6-overlay service scripts)
COPY rootfs /

# Set permissions for service scripts
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Set working directory (if applicable)
# WORKDIR /app

# Expose ports
EXPOSE 8080
