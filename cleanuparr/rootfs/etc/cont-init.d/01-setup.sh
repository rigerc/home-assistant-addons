#!/usr/bin/with-contenv bashio
# =============================================================================
# Home Assistant Add-on: Cleanuparr
# Runs during container initialization to set up the environment
# =============================================================================

bashio::log.info "Setting up Cleanuparr..."

# =============================================================================
# Directory Setup
# =============================================================================

bashio::log.info "Creating data directories..."
mkdir -p /config/cleanuparr
mkdir -p /data/cleanuparr/logs

# Create symlinks for Cleanuparr to use /config directory
ln -sf /data/cleanuparr /config/cleanuparr

# =============================================================================
# Download Cleanuparr binary
# =============================================================================

bashio::log.info "Downloading Cleanuparr binary..."

# Determine architecture
ARCH=$(uname -m)
case "${ARCH}" in
    aarch64)
        BINARY_ARCH="arm64"
        ;;
    armv7l)
        BINARY_ARCH="arm"
        ;;
    x86_64)
        BINARY_ARCH="x64"
        ;;
    *)
        bashio::exit.nok "Unsupported architecture: ${ARCH}"
        ;;
esac

# Download Cleanuparr
CLEANUPARR_VERSION="${CLEANUPARR_VERSION:-2.5.1}"
DOWNLOAD_URL="https://github.com/Cleanuparr/Cleanuparr/releases/download/v${CLEANUPARR_VERSION}/Cleanuparr-${CLEANUPARR_VERSION}-linux-${BINARY_ARCH}.zip"
bashio::log.info "Downloading Cleanuparr v${CLEANUPARR_VERSION} for ${BINARY_ARCH}..."
if ! curl -fsSL "${DOWNLOAD_URL}" -o /tmp/cleanuparr.zip; then
    bashio::exit.nok "Failed to download Cleanuparr binary"
fi

# Extract binary
zip -xzf /tmp/cleanuparr.zip -C /tmp/
mv /tmp/Cleanuparr /usr/bin/cleanuparr
chmod +x /usr/bin/cleanuparr

# Cleanup
rm -f /tmp/cleanuparr.zip

bashio::log.info "Cleanuparr v${CLEANUPARR_VERSION} installed successfully"

# =============================================================================
# Environment Variable Export
# =============================================================================

export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Get configuration values
LOG_LEVEL="$(bashio::config 'log_level')"
PORT="$(bashio::addon.port 11011/tcp)"

# Export environment variables for Cleanuparr
export_env LOG_LEVEL "${LOG_LEVEL}"
export_env PORT "${PORT}"

# Set default timezone
export_env TZ "$(bashio::info.timezone)"

# Set PUID and PGID (Home Assistant add-on runs as root by default)
export_env PUID "0"
export_env PGID "0"

# Export addon information
export_env ADDON_NAME "$(bashio::addon.name)"
export_env ADDON_IP "$(bashio::addon.ip_address)"

bashio::log.info "Setup complete"
