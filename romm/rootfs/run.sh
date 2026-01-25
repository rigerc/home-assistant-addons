#!/usr/bin/bashio

bashio::log.info "Starting Romm add-on..."

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

# Get ingress port
ROMM_PORT=$(bashio::addon.ingress_port)
if [ -z "$ROMM_PORT" ]; then
    ROMM_PORT=8095
fi

# Export database configuration
export DB_HOST="$(bashio::config 'database.host')"
export DB_PORT="$(bashio::config 'database.port')"
export DB_NAME="$(bashio::config 'database.name')"
export DB_USER="$(bashio::config 'database.user')"
export DB_PASSWD="$(bashio::config 'database.password')"

# Export auth configuration
export ROMM_AUTH_SECRET_KEY="$(bashio::config 'auth_secret_key')"

# Export metadata provider credentials (optional)
if bashio::config.has_value 'metadata_providers.screenscraper_user'; then
    export SCREENSCRAPER_USER="$(bashio::config 'metadata_providers.screenscraper_user')"
fi
if bashio::config.has_value 'metadata_providers.screenscraper_password'; then
    export SCREENSCRAPER_PASSWORD="$(bashio::config 'metadata_providers.screenscraper_password')"
fi
if bashio::config.has_value 'metadata_providers.retroachievements_api_key'; then
    export RETROACHIEVEMENTS_API_KEY="$(bashio::config 'metadata_providers.retroachievements_api_key')"
fi
if bashio::config.has_value 'metadata_providers.steamgriddb_api_key'; then
    export STEAMGRIDDB_API_KEY="$(bashio::config 'metadata_providers.steamgriddb_api_key')"
fi
if bashio::config.has_value 'metadata_providers.igdb_client_id'; then
    export IGDB_CLIENT_ID="$(bashio::config 'metadata_providers.igdb_client_id')"
fi
if bashio::config.has_value 'metadata_providers.igdb_client_secret'; then
    export IGDB_CLIENT_SECRET="$(bashio::config 'metadata_providers.igdb_client_secret')"
fi
if bashio::config.has_value 'metadata_providers.mobygames_api_key'; then
    export MOBYGAMES_API_KEY="$(bashio::config 'metadata_providers.mobygames_api_key')"
fi

# Export provider flags
export HASHEOUS_API_ENABLED="$(bashio::config 'metadata_providers.hasheous_enabled')"
export PLAYMATCH_API_ENABLED="$(bashio::config 'metadata_providers.playmatch_enabled')"
export LAUNCHBOX_API_ENABLED="$(bashio::config 'metadata_providers.launchbox_enabled')"

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

# Export volume paths
export ROMM_RESOURCES_PATH="/data/romm_resources"
export REDIS_DATA_PATH="/data/redis_data"
export ROMM_LIBRARY_PATH="$LIBRARY_PATH"
export ROMM_ASSETS_PATH="/data/romm_assets"

# Optional: config.yml path (if user provides one)
if [ -f "/config/romm/config.yml" ]; then
    export ROMM_CONFIG_PATH="/config/romm/config.yml"
fi

# Handle custom environment variables
ENV_VARS=$(bashio::config 'env_vars | join(" ")')

bashio::log.info "Configuration complete"
bashio::log.info "Port: ${ROMM_PORT}"
bashio::log.info "Database: ${DB_HOST}:${DB_PORT}/${DB_NAME}"
bashio::log.info "Library: ${ROMM_LIBRARY_PATH}"

# Start Romm
cd /romm || exit 1

if [ -n "$ENV_VARS" ]; then
    bashio::log.info "Applying custom environment variables"
    # shellcheck disable=SC2086
    exec env $ENV_VARS gunicorn main:app --bind "0.0.0.0:${ROMM_PORT}" --worker-class uvicorn.workers.UvicornWorker
else
    exec gunicorn main:app --bind "0.0.0.0:${ROMM_PORT}" --worker-class uvicorn.workers.UvicornWorker
fi
