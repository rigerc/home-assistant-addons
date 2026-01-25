#!/bin/bash
# Convert Docker Compose file to Home Assistant add-on structure
# Usage: ./compose-to-addon.sh docker-compose.yml output-directory

set -e

COMPOSE_FILE="$1"
OUTPUT_DIR="$2"

if [ -z "$COMPOSE_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <docker-compose.yml> <output-directory>"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: Compose file not found: $COMPOSE_FILE"
    exit 1
fi

echo "Converting $COMPOSE_FILE to Home Assistant add-on..."
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Parse compose file and extract first service name
# This is a basic implementation - manual review always required
SERVICE_NAME=$(grep -A 1 "^services:" "$COMPOSE_FILE" | grep -v "^services:" | grep -v "^--" | head -n 1 | sed 's/://g' | xargs)

if [ -z "$SERVICE_NAME" ]; then
    SERVICE_NAME="myapp"
fi

echo "Detected service name: $SERVICE_NAME"

# Generate config.yaml
cat > "$OUTPUT_DIR/config.yaml" << EOF
name: "${SERVICE_NAME^} Add-on"
version: "1.0.0"
slug: "${SERVICE_NAME}"
description: "Converted from Docker Compose"
arch:
  - amd64
  - aarch64
  - armv7
startup: application
boot: auto

# TODO: Review and configure ports
# Extract from: docker-compose.yml ports section
ports: {}

# TODO: Review and configure volume mappings
# Extract from: docker-compose.yml volumes section
map: []

# TODO: Review and configure environment variables
# Convert from: docker-compose.yml environment section
environment: {}

# TODO: Configure user options
# Move sensitive/configurable environment vars here
options: {}
schema: {}

# TODO: Review these settings
# hassio_api: false
# homeassistant_api: false
# ingress: false
EOF

echo "✓ Created config.yaml"

# Generate Dockerfile
cat > "$OUTPUT_DIR/Dockerfile" << EOF
ARG BUILD_FROM
FROM \$BUILD_FROM

# TODO: Install required dependencies
# Review docker-compose.yml service definition
RUN apk add --no-cache \\
    bash

# TODO: Copy application files
# COPY app/ /app/

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
EOF

echo "✓ Created Dockerfile"

# Generate run.sh
cat > "$OUTPUT_DIR/run.sh" << 'EOF'
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting add-on..."

# TODO: Parse configuration options
# Example:
# VALUE=$(bashio::config 'option_name')

# TODO: Set environment variables
# Example:
# export MY_VAR="${VALUE}"

# TODO: Start your application
# Example:
# exec /app/start.sh

bashio::log.info "Add-on started successfully"
EOF

chmod +x "$OUTPUT_DIR/run.sh"
echo "✓ Created run.sh"

# Generate README.md
cat > "$OUTPUT_DIR/README.md" << EOF
# ${SERVICE_NAME^} Add-on

Converted from Docker Compose configuration.

## Installation

Add this repository to your Home Assistant instance:

1. Go to Supervisor → Add-on Store
2. Add repository URL
3. Install "${SERVICE_NAME^} Add-on"

## Configuration

TODO: Document configuration options

## Support

TODO: Add support information
EOF

echo "✓ Created README.md"

# Generate DOCS.md
cat > "$OUTPUT_DIR/DOCS.md" << EOF
# ${SERVICE_NAME^} Add-on Documentation

## About

This add-on was converted from a Docker Compose configuration.

## Configuration

### Options

TODO: Document each configuration option

\`\`\`yaml
option_name: value
\`\`\`

## Usage

TODO: Describe how to use the add-on

## Support

TODO: Add support channels
EOF

echo "✓ Created DOCS.md"

# Create conversion notes
cat > "$OUTPUT_DIR/CONVERSION_NOTES.md" << EOF
# Docker Compose to Add-on Conversion Notes

## Original Compose File

Source: $COMPOSE_FILE

## Manual Steps Required

1. **Review config.yaml:**
   - [ ] Configure ports from Compose ports section
   - [ ] Map volumes to Home Assistant directories
   - [ ] Convert environment variables to options/environment
   - [ ] Set appropriate startup and boot values
   - [ ] Configure API access if needed
   - [ ] Enable Ingress if web UI present

2. **Review Dockerfile:**
   - [ ] Identify base image from Compose
   - [ ] Install required dependencies
   - [ ] Copy application files
   - [ ] Set up multi-stage build if needed

3. **Review run.sh:**
   - [ ] Parse configuration options
   - [ ] Set environment variables
   - [ ] Start application correctly
   - [ ] Add health checks if appropriate

4. **Multi-Service Handling:**
   - [ ] Decide: separate add-ons or single with S6-Overlay?
   - [ ] Configure service dependencies if using separate
   - [ ] Set up S6 services if embedding multiple processes

5. **Security:**
   - [ ] Create AppArmor profile (recommended)
   - [ ] Review required permissions
   - [ ] Enable Ingress instead of exposed ports (if web UI)
   - [ ] Move sensitive config to options with password type

6. **Testing:**
   - [ ] Test locally with Home Assistant
   - [ ] Verify all ports accessible
   - [ ] Confirm data persistence
   - [ ] Check logs for errors

## Detected Configuration

Service name: $SERVICE_NAME

TODO: Add detected ports, volumes, environment variables

## Reference

See: references/docker-compose-conversion.md for complete guide
EOF

echo "✓ Created CONVERSION_NOTES.md"

echo ""
echo "=========================================="
echo "Conversion scaffold complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review CONVERSION_NOTES.md for checklist"
echo "2. Analyze original Docker Compose file"
echo "3. Update config.yaml with ports, volumes, environment"
echo "4. Update Dockerfile with dependencies and build steps"
echo "5. Update run.sh with startup logic"
echo "6. Test locally before deployment"
echo ""
echo "Reference: .claude/skills/ha-addon-dev/references/docker-compose-conversion.md"
echo ""
