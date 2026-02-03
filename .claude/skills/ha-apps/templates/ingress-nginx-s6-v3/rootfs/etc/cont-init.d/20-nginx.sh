#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configure nginx for ingress and direct access
# s6-overlay v3: Runs during stage 2, before services start
# ==============================================================================

set -e

bashio::log.info "Configuring nginx..."

#################
# INGRESS SETUP #
#################

declare ingress_interface
declare ingress_port

# Get ingress configuration from Home Assistant
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)

# Update ingress configuration with actual values
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf

bashio::log.info "Ingress configured on ${ingress_interface}:${ingress_port}"

#####################
# DIRECT PORT SETUP #
#####################

declare port
declare certfile
declare keyfile

# Check if direct port is mapped
port=$(bashio::addon.port 80)

if bashio::var.has_value "${port}"; then
    bashio::log.info "Direct port 8080 is mapped"

    # Enable direct access configuration
    if bashio::config.true 'ssl'; then
        bashio::config.require.ssl

        certfile=$(bashio::config 'certfile')
        keyfile=$(bashio::config 'keyfile')

        bashio::log.info "SSL enabled for direct access"
        mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
        sed -i "s/%%certfile%%/${certfile}/g" /etc/nginx/servers/direct.conf
        sed -i "s/%%keyfile%%/${keyfile}/g" /etc/nginx/servers/direct.conf
    else
        bashio::log.info "SSL disabled for direct access"
        mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf
    fi
else
    bashio::log.info "Direct port 8080 is not mapped"
fi

bashio::log.info "Nginx configuration complete"
