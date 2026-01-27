ARG BUILD_FROM
FROM ${BUILD_FROM}

# Build arguments
ARG CLEANUPARR_VERSION
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_VERSION

# Labels (applied at build time)
LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  io.hass.dev="true" \
  org.opencontainers.image.title="Home Assistant Add-on: Cleanuparr" \
  org.opencontainers.image.description="Automated cleanup for Sonarr, Radarr, Lidarr, Readarr, and Whisparr downloads" \
  org.opencontainers.image.version="${CLEANUPARR_VERSION}" \
  org.opencontainers.image.created="${BUILD_DATE}" \
  org.opencontainers.image.source="https://github.com/Cleanuparr/Cleanuparr" \
  org.opencontainers.image.licenses="Apache-2.0"

# Install runtime dependencies
# - curl: For downloading the Cleanuparr binary
# - unzip: For extracting the downloaded archive
# - ca-certificates: For SSL/TLS connections
RUN \
  apk update && \
  apk add --no-cache \
    curl \
    unzip \
    ca-certificates && \
  update-ca-certificates

# Download and install Cleanuparr binary
# The Cleanuparr project provides pre-built binaries for multiple architectures
RUN \
  set -ex && \
  # Map Docker TARGETARCH to Cleanuparr's architecture naming
  case "${BUILD_ARCH}" in \
    aarch64) \
      BINARY_ARCH="arm64" \
      ;; \
    amd64) \
      BINARY_ARCH="amd64" \
      ;; \
    armv7) \
      BINARY_ARCH="arm" \
      ;; \
    *) \
      echo "Unsupported architecture: ${BUILD_ARCH}" && exit 1 \
      ;; \
  esac && \
  # Download the Cleanuparr binary from GitHub releases
  DOWNLOAD_URL="https://github.com/Cleanuparr/Cleanuparr/releases/download/v${CLEANUPARR_VERSION}/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}.zip" && \
  echo "Downloading Cleanuparr v${CLEANUPARR_VERSION} for ${BINARY_ARCH} from ${DOWNLOAD_URL}..." && \
  curl -fsSL "${DOWNLOAD_URL}" -o /tmp/cleanuparr.zip && \
  # Extract the downloaded archive
  unzip -q /tmp/cleanuparr.zip -d /tmp/ && \
  # Move the binary to /usr/bin
  mv "/tmp/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}/Cleanuparr" /usr/bin/cleanuparr && \
  # Make the binary executable
  chmod +x /usr/bin/cleanuparr && \
  # Clean up temporary files
  rm -rf /tmp/cleanuparr.zip "/tmp/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}" && \
  # Verify the binary was installed
  echo "Cleanuparr binary installed successfully:" && \
  /usr/bin/cleanuparr --version || echo "Warning: Unable to run Cleanuparr --version"

# Copy root filesystem overlay
# This includes S6-Overlay service scripts and initialization scripts
COPY rootfs /

# Set permissions for service scripts
# Ensure all scripts are executable
RUN \
  chmod a+x /etc/cont-init.d/*.sh 2>/dev/null || true && \
  find /etc/services.d -type f -name "run" -exec chmod +x {} \; 2>/dev/null || true && \
  find /etc/services.d -type f -name "finish" -exec chmod +x {} \; 2>/dev/null || true && \
  chmod a+x /etc/s6-overlay/s6-rc.d/*/up 2>/dev/null || true && \
  chmod a+x /etc/s6-overlay/s6-rc.d/*/run 2>/dev/null || true

# Set the working directory
# The application will run from here
WORKDIR /config

# Default environment variables
# These can be overridden at runtime
ENV \
  CLEANUPARR_CONFIG_DIR="/config/cleanuparr" \
  CLEANUPARR_LOG_LEVEL="info" \
  PORT="11011"

# Health check
# Verify the service is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:11011/health || exit 1

# Note: No CMD or ENTRYPOINT here
# Home Assistant's base images include S6-Overlay which will:
# 1. Run initialization scripts in /etc/cont-init.d/
# 2. Start services in /etc/services.d/ and S6-RC services
# 3. The cleanuparr service script will run the Cleanuparr binary
