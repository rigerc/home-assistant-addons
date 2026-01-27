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
LOG_LEVEL="$(bashio::config 'log_level')"
export LOG_LEVEL
printf "%s" "$LOG_LEVEL" > "/var/run/s6/container_environment/LOG_LEVEL"

# Export timezone
TZ="$(bashio::config 'tz')"
export TZ
printf "%s" "$TZ" > "/var/run/s6/container_environment/TZ"

# Export ingress port for nginx
PROFILARR_PORT="6099"
export PROFILARR_PORT
printf "%s" "$PROFILARR_PORT" > "/var/run/s6/container_environment/PROFILARR_PORT"

# Export Flask configuration
export FLASK_ENV=production
printf "%s" "production" > "/var/run/s6/container_environment/FLASK_ENV"

export FLASK_APP=/profilarr/app/main.py
printf "%s" "/profilarr/app/main.py" > "/var/run/s6/container_environment/FLASK_APP"

# Set Python environment
export_env PYTHONUNBUFFERED 1
export_env PYTHONDONTWRITEBYTECODE 1
export_env PYTHONPATH /profilarr

bashio::log.info "Profilarr initialization complete"
