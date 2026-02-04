#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# Romm add-on initialization script

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
mkdir -p /romm

# Get library path from config
LIBRARY_PATH="$(bashio::config 'library_path')"
if [ ! -d "$LIBRARY_PATH" ]; then
    bashio::log.warning "Library path ${LIBRARY_PATH} does not exist. Creating..."
    mkdir -p "$LIBRARY_PATH"
fi

# Create symlinks for ROMM to access our data directories
# ROMM backend expects paths under /romm/* but we store data in HA-specific locations
bashio::log.info "Creating symlinks for ROMM data paths..."

# Remove old symlinks if they exist and point to wrong location
for target_name in library resources assets; do
    symlink_path="/romm/${target_name}"
    if [ -L "$symlink_path" ]; then
        rm "$symlink_path"
    elif [ -e "$symlink_path" ]; then
        bashio::log.warning "${symlink_path} exists but is not a symlink, removing..."
        rm -rf "$symlink_path"
    fi
done

# Create fresh symlinks
ln -s "$LIBRARY_PATH" /romm/library
ln -s /data/romm_resources /romm/resources
ln -s /data/romm_assets /romm/assets

bashio::log.info "Symlinks created: /romm/library -> ${LIBRARY_PATH}"

# Fix frontend symlinks (similar to official ROMM entrypoint.sh)
# Frontend needs symlinks in /var/www/html/assets/romm/ pointing to ROMM_BASE_PATH
bashio::log.info "Verifying frontend asset symlinks..."
mkdir -p /var/www/html/assets/romm

for subfolder in assets resources; do
    frontend_symlink="/var/www/html/assets/romm/${subfolder}"
    expected_target="/romm/${subfolder}"

    if [ -L "$frontend_symlink" ]; then
        current_target=$(readlink "$frontend_symlink")
        if [ "$current_target" != "$expected_target" ]; then
            bashio::log.info "Updating frontend symlink: ${frontend_symlink} -> ${expected_target}"
            rm "$frontend_symlink"
            ln -s "$expected_target" "$frontend_symlink"
        fi
    else
        if [ -e "$frontend_symlink" ]; then
            bashio::log.warning "${frontend_symlink} exists but is not a symlink, removing..."
            rm -rf "$frontend_symlink"
        fi
        bashio::log.info "Creating frontend symlink: ${frontend_symlink} -> ${expected_target}"
        ln -s "$expected_target" "$frontend_symlink"
    fi
done

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

# Export Redis connection URL
export_env REDIS_URL "redis://127.0.0.1:6379/0"

# Export scheduled tasks configuration
export_env ENABLE_SCHEDULED_RESCAN "$(bashio::config 'scheduled_tasks.enable_rescan')"
export_env ENABLE_SCHEDULED_UPDATE_SWITCH_TITLEDB "$(bashio::config 'scheduled_tasks.enable_switch_titledb')"
export_env ENABLE_SCHEDULED_UPDATE_LAUNCHBOX_METADATA "$(bashio::config 'scheduled_tasks.enable_launchbox_metadata')"
export_env ENABLE_SCHEDULED_CONVERT_IMAGES_TO_WEBP "$(bashio::config 'scheduled_tasks.enable_image_conversion')"
export_env ENABLE_SCHEDULED_RETROACHIEVEMENTS_PROGRESS_SYNC "$(bashio::config 'scheduled_tasks.enable_retroachievements_sync')"

# Export file watcher configuration (always enabled)
export_env ENABLE_RESCAN_ON_FILESYSTEM_CHANGE "true"

# Export nginx configuration
# Get the actual mapped port from config.yaml (not user-configurable)
export_env ROMM_PORT "$(bashio::addon.port '5999/tcp')"
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
