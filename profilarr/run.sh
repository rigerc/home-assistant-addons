#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "Starting Profilarr..."

# Get addon config path
ADDON_CONFIG="$(bashio::addon.config_path)"

# Create and setup directories
mkdir -p /data/config /data/logs /data/db "$ADDON_CONFIG"

# Create symlink for config directory
if [ ! -L /config ]; then
    ln -sf "$ADDON_CONFIG" /config
fi

# Get configuration values
LOG_LEVEL="$(bashio::config 'log_level')"
TZ="$(bashio::config 'tz')"
PROFILARR_PORT="6099"

# Export environment variables
export PYTHONPATH=/profilarr
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export FLASK_ENV=production
export FLASK_APP=/profilarr/app/main.py
export LOG_LEVEL
export TZ
export PROFILARR_PORT

# Process nginx template with environment variables
bashio::log.info "Configuring nginx..."
envsubst < /etc/nginx/templates/profilarr.conf.template > /etc/nginx/conf.d/profilarr.conf

bashio::log.info "Starting nginx on port ${PROFILARR_PORT}..."
# Start nginx in background
nginx &

bashio::log.info "Starting Gunicorn on port 6868..."
# Start gunicorn in background (nginx proxies to it)
cd /profilarr
exec /usr/bin/gunicorn "app.main:create_app()" \
    --bind "0.0.0.0:6868" \
    --workers 2 \
    --threads 4 \
    --timeout 600 \
    --keep-alive 2 \
    --worker-class sync \
    --access-logfile - \
    --error-logfile - \
    --log-level "$LOG_LEVEL"
