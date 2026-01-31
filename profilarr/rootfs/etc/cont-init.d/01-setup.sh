#!/usr/bin/with-contenv bashio
# ==============================================================================
# Initialize and setup Profilarr environment
# Runs during container initialization, before services start
# ==============================================================================

bashio::log.info "Setting up Profilarr..."

# Get configuration
AUTH_MODE="$(bashio::config 'auth_mode')"
LOG_LEVEL="$(bashio::config 'log_level')"

# Create data directory
mkdir -p /data/config

# Export environment variables for service
echo "export PORT=6868" >> /var/run/s6/container_environment/PORT
echo "export HOST=0.0.0.0" >> /var/run/s6/container_environment/HOST
echo "export APP_BASE_PATH=/data" >> /var/run/s6/container_environment/APP_BASE_PATH
echo "export AUTH=${AUTH_MODE}" >> /var/run/s6/container_environment/AUTH

# Set timezone from Home Assistant
if bashio::config.exists 'timezone'; then
    TIMEZONE="$(bashio::config 'timezone')"
    echo "export TZ=${TIMEZONE}" >> /var/run/s6/container_environment/TZ
    bashio::log.info "Timezone set to: ${TIMEZONE}"
fi

bashio::log.info "Authentication mode: ${AUTH_MODE}"
bashio::log.info "Log level: ${LOG_LEVEL}"
bashio::log.info "Profilarr setup complete"
