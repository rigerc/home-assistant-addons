#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Display banner on startup
# Runs during container initialization, before services start
# ==============================================================================

bashio::log.info "---"
bashio::log.info "Profilarr"
bashio::log.info "Initializing add-on..."
bashio::log.info "---"
