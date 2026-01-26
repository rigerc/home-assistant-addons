#!/usr/bin/with-contenv bashio

bashio::log.info "Setting up Profilarr configuration..."

# Create data directories
bashio::log.info "Creating data directories..."
mkdir -p /data/config
mkdir -p /data/logs
mkdir -p /data/db

# Get addon config path
ADDON_CONFIG="$(bashio::addon.config_path)"

# Create symlink for config directory
if [ ! -L /config ]; then
    ln -sf "$ADDON_CONFIG" /config
fi

# Ensure config directory exists
mkdir -p "$ADDON_CONFIG"

# Helper function to export environment variables for s6 services
export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Export log level
export_env LOG_LEVEL "$(bashio::config 'log_level')"

# Export timezone
export_env TZ "$(bashio::config 'tz')"

# Export Git configuration
export_env GIT_USER_NAME "$(bashio::config 'git_user_name')"
export_env GIT_USER_EMAIL "$(bashio::config 'git_user_email')"

# Export ingress port for nginx
export_env PROFILARR_PORT "$(bashio::addon.ingress_port)"

# Export Flask configuration
export_env FLASK_ENV production
export_env FLASK_APP /profilarr/app/main.py

# Set Python environment
export_env PYTHONUNBUFFERED 1
export_env PYTHONDONTWRITEBYTECODE 1
export_env PYTHONPATH /profilarr

bashio::log.info "Profilarr initialization complete"
