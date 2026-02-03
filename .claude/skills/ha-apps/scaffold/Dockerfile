ARG BUILD_FROM
ARG BUILD_VERSION

# Base image if multi-stage build
# FROM repo/dockerimage:tag as app-source

# Copy run script if native
# COPY run.sh /
# RUN chmod a+x /run.sh

# If multi-stage build, copy from app-source:
# COPY --from=app-source

# Only if native:
# CMD [ "/run.sh" ]

# apk if alpine, apt-get if debian, etc.

# Multi-stage uses s6-overlay v2

# Copy S6-overlay configuration (v2 legacy format)
# COPY rootfs /

# Set permissions
# RUN chmod a+x /etc/cont-init.d/*.sh \
#    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
#    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Health check
# Uses internal docker port from config.yaml
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:11011/health || exit 1