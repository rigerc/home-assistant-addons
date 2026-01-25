#!/usr/bin/with-contenv bashio

bashio::log.info "Setting up Romm configuration..."

# Validate required configuration
if ! bashio::config.has_value 'database.host'; then
    bashio::exit.nok "Database host is required!"
fi

if ! bashio::config.has_value 'database.password'; then
    bashio::exit.nok "Database password is required!"
fi

if ! bashio::config.has_value 'auth_secret_key'; then
    bashio::exit.nok "Auth secret key is required! Generate with: openssl rand -hex 32"
fi

# Create required directories
bashio::log.info "Creating data directories..."
mkdir -p /data/romm_resources
mkdir -p /data/redis_data
mkdir -p /data/romm_assets

# Get library path from config
LIBRARY_PATH="$(bashio::config 'library_path')"
if [ ! -d "$LIBRARY_PATH" ]; then
    bashio::log.warning "Library path ${LIBRARY_PATH} does not exist. Creating..."
    mkdir -p "$LIBRARY_PATH"
fi

bashio::log.info "Romm initialization complete"
