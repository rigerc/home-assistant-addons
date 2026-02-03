#!/usr/bin/with-contenv bashio
# ==============================================================================
# Initialize and setup the environment
# Runs during container initialization, before services start
# ==============================================================================

bashio::log.info "Running initialization tasks..."

# Create required directories
mkdir -p /data/config
mkdir -p /data/logs
mkdir -p /share/example-addon

# Set proper permissions
chown -R nobody:nogroup /data/logs

# Generate configuration file from add-on options
MESSAGE=$(bashio::config 'message')
PORT=$(bashio::config 'port')

bashio::log.info "Generating application configuration..."
cat > /data/config/app.conf <<EOF
# Generated configuration
message="${MESSAGE}"
port=${PORT}
log_path=/data/logs/app.log
EOF

# Run database migrations or other setup tasks
# bashio::log.info "Running database migrations..."
# /app/migrate.sh || bashio::exit.nok "Migration failed"

# Validate configuration
if ! bashio::config.has_value 'message'; then
    bashio::exit.nok "Configuration error: 'message' is required"
fi

bashio::log.info "Initialization complete"
