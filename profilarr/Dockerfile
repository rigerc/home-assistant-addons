ARG BUILD_FROM
FROM santiagosayshey/profilarr:latest AS profilarr-base
FROM ${BUILD_FROM} AS final

# Install runtime dependencies
# - git: For Git version control operations (already in base image)
# - bash: For shell scripts
# - curl: For health checks
RUN apk add --no-cache \
    bash \
    curl

# Copy application files from official Profilarr image
COPY --from=profilarr-base /app /profilarr

# Copy Python virtual environment and binaries from base image
COPY --from=profilarr-base /usr/local/bin /usr/local/bin
COPY --from=profilarr-base /usr/local/lib /usr/local/lib

# Copy rootfs (s6 service scripts)
COPY rootfs /

# Set permissions for service scripts and ensure /init is executable
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \; \
    && if [ -f /init ]; then chmod +x /init; fi

# Set environment for Python
ENV PYTHONPATH=/profilarr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=/profilarr/main.py

WORKDIR /profilarr
EXPOSE 6099

# Start s6-overlay
CMD ["/init"]
