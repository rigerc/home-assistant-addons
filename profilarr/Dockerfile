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

# Copy nginx configuration
COPY rootfs/etc/nginx /etc/nginx

# Copy startup script
COPY run.sh /
RUN chmod a+x /run.sh

# Set environment for Python
ENV PYTHONPATH=/profilarr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=/profilarr/main.py

WORKDIR /profilarr
EXPOSE 6099

# Start the add-on
CMD ["/run.sh"]
