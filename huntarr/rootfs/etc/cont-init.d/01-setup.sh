#!/usr/bin/with-contenv bashio
# ==============================================================================
# Initialize and setup Huntarr environment
# Runs during container initialization, before services start
# ==============================================================================

bashio::log.info "Running Huntarr initialization..."

# Create config directory if it doesn't exist
# Create config directory if it doesn't exist
if [ ! -d "/config" ]; then
    bashio::exit.fatal "Configuration directory '/config' not found. Please ensure it is mounted correctly."
fi

# Set proper permissions for config directory
chown -R root:root /config

# Get log level from add-on options
LOG_LEVEL=$(bashio::config 'log_level')
bashio::log.info "Log level set to: ${LOG_LEVEL}"

# Set timezone environment variable
export TZ="$(bashio::config 'timezone' 'UTC')"
bashio::log.info "Timezone set to: ${TZ}"

bashio::log.info "Huntarr initialization complete"
