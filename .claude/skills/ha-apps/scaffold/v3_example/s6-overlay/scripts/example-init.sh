#!/command/with-contenv bashio
# ==============================================================================
# Example initialization script (oneshot service)
# This runs once during startup, before longrun services
# ==============================================================================

bashio::log.info "Running example initialization..."

# Create required directories
mkdir -p /data/config
mkdir -p /data/logs

# Generate configuration
MESSAGE=$(bashio::config 'message')
PORT=$(bashio::config 'port')

bashio::log.info "Generating configuration file..."
cat > /data/config/app.conf <<EOF
message="${MESSAGE}"
port=${PORT}
EOF

# Validate configuration
if ! bashio::config.has_value 'message'; then
    bashio::exit.nok "Configuration error: 'message' is required"
fi

bashio::log.info "Initialization complete"
