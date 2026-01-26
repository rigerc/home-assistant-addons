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

# Create required directories with proper ownership
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

# Helper function to export environment variables for s6 services
export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Export database configuration
export_env DB_HOST "$(bashio::config 'database.host')"
export_env DB_PORT "$(bashio::config 'database.port')"
export_env DB_NAME "$(bashio::config 'database.name')"
export_env DB_USER "$(bashio::config 'database.user')"
export_env DB_PASSWD "$(bashio::config 'database.password')"

# Export auth configuration
export_env ROMM_AUTH_SECRET_KEY "$(bashio::config 'auth_secret_key')"

# Export metadata provider credentials (optional)
if bashio::config.has_value 'metadata_providers.screenscraper_user'; then
    export_env SCREENSCRAPER_USER "$(bashio::config 'metadata_providers.screenscraper_user')"
fi
if bashio::config.has_value 'metadata_providers.screenscraper_password'; then
    export_env SCREENSCRAPER_PASSWORD "$(bashio::config 'metadata_providers.screenscraper_password')"
fi
if bashio::config.has_value 'metadata_providers.retroachievements_api_key'; then
    export_env RETROACHIEVEMENTS_API_KEY "$(bashio::config 'metadata_providers.retroachievements_api_key')"
fi
if bashio::config.has_value 'metadata_providers.steamgriddb_api_key'; then
    export_env STEAMGRIDDB_API_KEY "$(bashio::config 'metadata_providers.steamgriddb_api_key')"
fi
if bashio::config.has_value 'metadata_providers.igdb_client_id'; then
    export_env IGDB_CLIENT_ID "$(bashio::config 'metadata_providers.igdb_client_id')"
fi
if bashio::config.has_value 'metadata_providers.igdb_client_secret'; then
    export_env IGDB_CLIENT_SECRET "$(bashio::config 'metadata_providers.igdb_client_secret')"
fi
if bashio::config.has_value 'metadata_providers.mobygames_api_key'; then
    export_env MOBYGAMES_API_KEY "$(bashio::config 'metadata_providers.mobygames_api_key')"
fi

# Export provider flags
export_env HASHEOUS_API_ENABLED "$(bashio::config 'metadata_providers.hasheous_enabled')"
export_env PLAYMATCH_API_ENABLED "$(bashio::config 'metadata_providers.playmatch_enabled')"
export_env LAUNCHBOX_API_ENABLED "$(bashio::config 'metadata_providers.launchbox_enabled')"

# Export volume paths
export_env ROMM_RESOURCES_PATH "/data/romm_resources"
export_env REDIS_DATA_PATH "/data/redis_data"
export_env ROMM_LIBRARY_PATH "$(bashio::config 'library_path')"
export_env ROMM_ASSETS_PATH "/data/romm_assets"

# Export scheduled tasks configuration
export_env ENABLE_SCHEDULED_RESCAN "$(bashio::config 'scheduled_tasks.enable_rescan')"
export_env ENABLE_SCHEDULED_UPDATE_SWITCH_TITLEDB "$(bashio::config 'scheduled_tasks.enable_switch_titledb')"
export_env ENABLE_SCHEDULED_UPDATE_LAUNCHBOX_METADATA "$(bashio::config 'scheduled_tasks.enable_launchbox_metadata')"
export_env ENABLE_SCHEDULED_CONVERT_IMAGES_TO_WEBP "$(bashio::config 'scheduled_tasks.enable_image_conversion')"
export_env ENABLE_SCHEDULED_RETROACHIEVEMENTS_PROGRESS_SYNC "$(bashio::config 'scheduled_tasks.enable_retroachievements_sync')"

# Export file watcher configuration
export_env ENABLE_RESCAN_ON_FILESYSTEM_CHANGE "$(bashio::config 'enable_file_watcher')"

# Export nginx configuration
export_env ROMM_PORT "$(bashio::addon.ingress_port)"
export_env ROMM_BASE_PATH "/romm"

# Optional: config.yml path
if [ -f "/config/romm/config.yml" ]; then
    export_env ROMM_CONFIG_PATH "/config/romm/config.yml"
fi

# Set Python environment
export_env PYTHONUNBUFFERED 1
export_env PYTHONDONTWRITEBYTECODE 1
export_env PYTHONPATH /backend

# Disable OpenTelemetry (not needed for HA add-on)
export_env OTEL_SDK_DISABLED true

bashio::log.info "Romm initialization complete"
