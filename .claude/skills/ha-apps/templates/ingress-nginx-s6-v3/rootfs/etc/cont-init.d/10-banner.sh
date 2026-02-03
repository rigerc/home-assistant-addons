#!/usr/bin/with-contenv bashio
# ==============================================================================
# Display banner on startup
# s6-overlay v3: Runs during stage 2, before services start
# ==============================================================================

bashio::log.info "---"
bashio::log.info "My Application Add-on"
bashio::log.info "Version: $(bashio::addon.version)"
bashio::log.info "Initializing..."
bashio::log.info "---"
