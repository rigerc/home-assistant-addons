#!/usr/bin/with-contenv bashio
# =============================================================================
# Home Assistant Add-on: Your Add-on
# Runs during container initialization to set up the environment
# =============================================================================

bashio::log.info "Setting up Your Add-on configuration..."

# =============================================================================
# Configuration Validation
# =============================================================================

# Validate required configuration
# Uncomment and modify for your required fields
# if ! bashio::config.has_value 'required_field'; then
#     bashio::exit.nok "Required field 'required_field' is not set!"
# fi

# =============================================================================
# Directory Setup
# =============================================================================

# Create required directories with proper permissions
bashio::log.info "Creating data directories..."
mkdir -p /data/config
mkdir -p /data/cache

# =============================================================================
# Environment Variable Export
# =============================================================================
# Exported variables are available to all s6-overlay services
# They are stored in /var/run/s6/container_environment/

export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Get configuration values
LOG_LEVEL="$(bashio::config 'log_level')"

# Export common environment variables
export_env LOG_LEVEL "${LOG_LEVEL}"

# Get port mapping (for web services)
if bashio::var.has_value "$(bashio::addon.port 8080/tcp)"; then
    export_env APP_PORT "$(bashio::addon.port 8080/tcp)"
fi

# Export addon information
export_env ADDON_NAME "$(bashio::addon.name)"
export_env ADDON_IP "$(bashio::addon.ip_address)"

# Example: Export nested configuration
# if bashio::config.has_value 'database.host'; then
#     export_env DB_HOST "$(bashio::config 'database.host')"
#     export_env DB_PORT "$(bashio::config 'database.port')"
#     export_env DB_NAME "$(bashio::config 'database.name')"
#     export_env DB_USER "$(bashio::config 'database.user')"
#     export_env DB_PASSWORD "$(bashio::config 'database.password')"
# fi

# Example: Export optional configuration
# if bashio::config.has_value 'optional_api_key'; then
#     export_env API_KEY "$(bashio::config 'optional_api_key')"
# fi

# Example: Export boolean flags
# export_env ENABLE_FEATURE "$(bashio::config 'enable_feature')"

# =============================================================================
# Additional Setup
# =============================================================================

# Add any additional setup steps here
# Examples:
# - Create symlinks
# - Download dependencies
# - Run initialization scripts
# - Validate configuration files

bashio::log.info "Setup complete"
