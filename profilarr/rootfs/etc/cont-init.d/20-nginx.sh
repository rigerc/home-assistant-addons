#!/usr/bin/with-contenv bashio
# ==============================================================================
# Configure nginx for ingress
# Runs during container initialization, before services start
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
bashio::log.info "Nginx will proxy requests to Profilarr on 127.0.0.1:6868"
bashio::log.info "Nginx configuration complete"
