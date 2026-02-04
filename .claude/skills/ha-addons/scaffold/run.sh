#!/usr/bin/with-contenv bashio

# Parse configuration
LOG_LEVEL=$(bashio::config 'log_level')
MESSAGE=$(bashio::config 'message')
ENABLE_FEATURE=$(bashio::config 'enable_feature')
PORT=$(bashio::config 'port')

# Set log level
bashio::log.level "${LOG_LEVEL}"

bashio::log.info "Starting Example Add-on"
bashio::log.info "Message: ${MESSAGE}"
bashio::log.info "Feature enabled: ${ENABLE_FEATURE}"
bashio::log.info "Port: ${PORT}"

# Parse items array (example)
if bashio::config.has_value 'items'; then
    bashio::log.info "Processing items configuration..."
    for item in $(bashio::config 'items|keys'); do
        ITEM_NAME=$(bashio::config "items[${item}].name")
        ITEM_VALUE=$(bashio::config "items[${item}].value")
        bashio::log.info "  - ${ITEM_NAME}: ${ITEM_VALUE}"
    done
fi

# Your add-on logic goes here

bashio::log.info "Add-on started successfully"

# Keep the container running
while true; do
    sleep 3600
done
