#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Initialize and setup Profilarr environment
# Runs during container initialization, before services start
# ==============================================================================

bashio::log.info "Setting up Profilarr..."

# Get configuration
AUTH_MODE="$(bashio::config 'auth_mode')"
LOG_LEVEL="$(bashio::config 'log_level')"

# Profilarr expects /config directory (mapped from addon_config)
# Ensure config directory and subdirectories exist with proper permissions
if [ -d "/config" ]; then
    bashio::log.info "Config directory exists at /config"
    # Create subdirectories that Profilarr needs
    mkdir -p /config/log /config/db
    chmod -R 755 /config
    bashio::log.info "Created Profilarr subdirectories in /config"
else
    bashio::log.warning "/config directory not found, creating it"
    mkdir -p /config/log /config/db
    chmod -R 755 /config
fi

# Export environment variables for service
# Note: Profilarr doesn't use these, but keeping for compatibility
echo "export PORT=6868" >> /var/run/s6/container_environment/PORT
echo "export HOST=127.0.0.1" >> /var/run/s6/container_environment/HOST
echo "export AUTH=${AUTH_MODE}" >> /var/run/s6/container_environment/AUTH

# Optional Git user configuration
if bashio::config.has_value 'git_user_name'; then
    GIT_USER_NAME="$(bashio::config 'git_user_name')"
    echo "export GIT_USER_NAME=${GIT_USER_NAME}" >> /var/run/s6/container_environment/GIT_USER_NAME
    bashio::log.info "Git user name: ${GIT_USER_NAME}"
fi

if bashio::config.has_value 'git_user_email'; then
    GIT_USER_EMAIL="$(bashio::config 'git_user_email')"
    echo "export GIT_USER_EMAIL=${GIT_USER_EMAIL}" >> /var/run/s6/container_environment/GIT_USER_EMAIL
    bashio::log.info "Git user email: ${GIT_USER_EMAIL}"
fi

# Set timezone from Home Assistant
if bashio::config.exists 'timezone'; then
    TIMEZONE="$(bashio::config 'timezone')"
    echo "export TZ=${TIMEZONE}" >> /var/run/s6/container_environment/TZ
    bashio::log.info "Timezone set to: ${TIMEZONE}"
fi

bashio::log.info "Authentication mode: ${AUTH_MODE}"
bashio::log.info "Log level: ${LOG_LEVEL}"
bashio::log.info "Profilarr setup complete"
