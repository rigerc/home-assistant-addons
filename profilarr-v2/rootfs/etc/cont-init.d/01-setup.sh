#!/usr/bin/with-contenv bashio
# ==============================================================================
# Initialize and setup Profilarr V2 environment
# Runs during container initialization, before services start
# ==============================================================================

bashio::log.info "Setting up Profilarr V2..."

# Get configuration
LOG_LEVEL="$(bashio::config 'log_level')"
PUID="$(bashio::config 'puid' '1000')"
PGID="$(bashio::config 'pgid' '1000')"
UMASK="$(bashio::config 'umask' '022')"

# Export environment variables for Profilarr
echo "export PORT=6868" >> /var/run/s6/container_environment/PORT
echo "export HOST=0.0.0.0" >> /var/run/s6/container_environment/HOST
echo "export PUID=${PUID}" >> /var/run/s6/container_environment/PUID
echo "export PGID=${PGID}" >> /var/run/s6/container_environment/PGID
echo "export UMASK=${UMASK}" >> /var/run/s6/container_environment/UMASK

# Set timezone from Home Assistant
if bashio::config.exists 'timezone'; then
    TIMEZONE="$(bashio::config 'timezone')"
    echo "export TZ=${TIMEZONE}" >> /var/run/s6/container_environment/TZ
    bashio::log.info "Timezone set to: ${TIMEZONE}"
fi

# Create config subdirectories if they don't exist
mkdir -p /config/data /config/logs /config/backups /config/databases

# Set proper ownership for config directories
# Note: In HA add-ons, we run as root but the app manages its own permissions via PUID/PGID
chown -R root:root /config
chmod -R 755 /config

bashio::log.info "Configuration:"
bashio::log.info "  - Log level: ${LOG_LEVEL}"
bashio::log.info "  - PUID: ${PUID}"
bashio::log.info "  - PGID: ${PGID}"
bashio::log.info "  - UMASK: ${UMASK}"
bashio::log.info "Profilarr V2 setup complete"
