ARG BUILD_FROM
FROM ${BUILD_FROM}

# Build arguments
ARG BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_DATE

# Labels (applied at build time)
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.dev="true" \
  org.opencontainers.image.title="Home Assistant Add-on: Cleanuparr" \
  org.opencontainers.image.description="Automated cleanup for Sonarr, Radarr, Lidarr, Readarr, and Whisparr downloads" \
  org.opencontainers.image.version="${BUILD_VERSION}" \
  org.opencontainers.image.created="${BUILD_DATE}" \
  org.opencontainers.image.source="https://github.com/Cleanuparr/Cleanuparr" \
  org.opencontainers.image.licenses="Apache-2.0"

# =============================================================================
# Install Runtime Dependencies
# =============================================================================
RUN echo "════════════════════════════════════════════════════════════════" && \
    echo "  Home Assistant Add-on: Cleanuparr" && \
    echo "  Version: ${BUILD_VERSION}" && \
    echo "  Architecture: ${BUILD_ARCH}" && \
    echo "════════════════════════════════════════════════════════════════" && \
    echo "" && \
    echo "[1/4] Installing runtime dependencies..." && \
    echo "→ Updating Alpine package index..." && \
    apk update && \
    echo "→ Installing packages: curl, unzip, ca-certificates..." && \
    apk add --no-cache curl unzip ca-certificates && \
    echo "→ Updating CA certificates..." && \
    update-ca-certificates && \
    echo "✓ Runtime dependencies installed successfully" && \
    echo ""

# =============================================================================
# Download and Install Cleanuparr Binary
# =============================================================================
RUN \
    echo "[2/4] Downloading and installing Cleanuparr binary..." && \
    echo "→ Detecting architecture (BUILD_ARCH=${BUILD_ARCH})..." && \
    if [ "${BUILD_ARCH}" = "aarch64" ]; then \
        BINARY_ARCH="arm64" && echo "  Mapped: aarch64 → arm64"; \
    elif [ "${BUILD_ARCH}" = "amd64" ]; then \
        BINARY_ARCH="amd64" && echo "  Mapped: amd64 → amd64"; \
    else \
        echo "  ✗ Unsupported architecture: ${BUILD_ARCH}" && exit 1; \
    fi && \
    echo "→ BINARY_ARCH=${BINARY_ARCH}" && \
    DOWNLOAD_URL="https://github.com/Cleanuparr/Cleanuparr/releases/download/v${BUILD_VERSION}/Cleanuparr-${BUILD_VERSION}-linux-${BINARY_ARCH}.zip" && \
    echo "→ Downloading Cleanuparr v${BUILD_VERSION} for ${BINARY_ARCH}..." && \
    echo "  URL: ${DOWNLOAD_URL}" && \
    echo "→ Downloading..." && \
    curl -fSL "${DOWNLOAD_URL}" -o /tmp/cleanuparr.zip && \
    echo "✓ Download complete ($(stat -c%s /tmp/cleanuparr.zip) bytes)" && \
    echo "" && \
    echo "→ Listing archive contents..." && \
    unzip -l /tmp/cleanuparr.zip && \
    echo "" && \
    echo "→ Extracting archive..." && \
    unzip -q /tmp/cleanuparr.zip -d /tmp/ && \
    echo "✓ Archive extracted" && \
    echo "" && \
    echo "→ Listing extracted files..." && \
    ls -la /tmp/ && \
    echo "" && \
    echo "→ Finding Cleanuparr binary..." && \
    find /tmp -name "Cleanuparr" -type f && \
    echo "" && \
    echo "→ Installing binary to /usr/bin/cleanuparr..." && \
    EXTRACTED_DIR="$(find /tmp -type d -name "Cleanuparr-*" | head -1)" && \
    echo "  Found directory: ${EXTRACTED_DIR}" && \
    ls -la "${EXTRACTED_DIR}/" && \
    mv "${EXTRACTED_DIR}/Cleanuparr" /usr/bin/cleanuparr && \
    chmod +x /usr/bin/cleanuparr && \
    echo "✓ Binary installed and made executable" && \
    echo "" && \
    echo "→ Cleaning up temporary files..." && \
    rm -rf /tmp/cleanuparr.zip /tmp/Cleanuparr-* && \
    echo "✓ Cleanup complete" && \
    echo "" && \
    echo "→ Verifying installation..." && \
    if [ -x /usr/bin/cleanuparr ]; then \
        echo "✓ Cleanuparr binary exists and is executable" && \
        /usr/bin/cleanuparr --version; \
    else \
        echo "✗ ERROR: Cleanuparr binary not found or not executable!" && exit 1; \
    fi && \
    echo ""

# =============================================================================
# Copy Root Filesystem Overlay
# =============================================================================
COPY rootfs /

RUN \
    echo "[3/4] Copying root filesystem overlay..." && \
    echo "✓ Root filesystem copied" && \
    echo "  Contents:" && \
    find /etc/cont-init.d -type f 2>/dev/null | sed 's/^/    /' || echo "    (no cont-init.d scripts)" && \
    find /etc/services.d -type f 2>/dev/null | sed 's/^/    /' || echo "    (no services.d scripts)" && \
    echo ""

# =============================================================================
# Set Permissions for Service Scripts
# =============================================================================
RUN \
    echo "→ Setting executable permissions on service scripts..." && \
    echo "  Processing /etc/cont-init.d/..." && \
    chmod a+x /etc/cont-init.d/*.sh 2>/dev/null || echo "    (no scripts found)" && \
    echo "  Processing /etc/services.d/ run scripts..." && \
    find /etc/services.d -type f -name "run" -exec chmod +x {} \; 2>/dev/null || echo "    (no run scripts found)" && \
    echo "  Processing /etc/services.d/ finish scripts..." && \
    find /etc/services.d -type f -name "finish" -exec chmod +x {} \; 2>/dev/null || echo "    (no finish scripts found)" && \
    echo "  Processing /etc/s6-overlay/s6-rc.d/ up scripts..." && \
    chmod a+x /etc/s6-overlay/s6-rc.d/*/up 2>/dev/null || echo "    (no up scripts found)" && \
    echo "  Processing /etc/s6-overlay/s6-rc.d/ run scripts..." && \
    chmod a+x /etc/s6-overlay/s6-rc.d/*/run 2>/dev/null || echo "    (no run scripts found)" && \
    echo "✓ Permissions set" && \
    echo ""

# =============================================================================
# Set Working Directory and Environment
# =============================================================================
RUN \
    echo "[4/4] Configuring environment..." && \
    echo "✓ Working directory: /config" && \
    echo "✓ Environment variables configured:" && \
    echo "    CLEANUPARR_CONFIG_DIR=/config/cleanuparr" && \
    echo "    CLEANUPARR_LOG_LEVEL=info" && \
    echo "    PORT=11011" && \
    echo ""

# Set the working directory
WORKDIR /config

# Default environment variables
ENV \
    CLEANUPARR_CONFIG_DIR="/config/cleanuparr" \
    CLEANUPARR_LOG_LEVEL="info" \
    PORT="11011"

# =============================================================================
# Health Check Configuration
# =============================================================================
RUN \
    echo "→ Configuring health check..." && \
    echo "✓ Health check configured (http://localhost:11011/health)" && \
    echo "" && \
    echo "════════════════════════════════════════════════════════════════" && \
    echo "  ✓ Build Complete!" && \
    echo "════════════════════════════════════════════════════════════════" && \
    echo "" && \
    echo "  Cleanuparr Add-on Ready!" && \
    echo "  Version: ${BUILD_VERSION}" && \
    echo "  Architecture: ${BUILD_ARCH}" && \
    echo "" && \
    echo "  Next Steps:" && \
    echo "  1. Configure your *arr applications" && \
    echo "  2. Configure your download clients" && \
    echo "  3. Set up cleaning rules" && \
    echo "  4. Start cleaning!" && \
    echo "" && \
    echo "════════════════════════════════════════════════════════════════"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:11011/health || exit 1

# Note: No CMD or ENTRYPOINT here
# Home Assistant's base images include S6-Overlay which will:
# 1. Run initialization scripts in /etc/cont-init.d/
# 2. Start services in /etc/services.d/ and S6-RC services
# 3. The cleanuparr service script will run the Cleanuparr binary
