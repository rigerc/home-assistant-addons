#!/bin/sh
#
# Generate s6-rc service template
# Usage: ./generate-service-template.sh <service-name> <type> [--with-logging]
#

set -e

SERVICE_NAME="$1"
SERVICE_TYPE="$2"
WITH_LOGGING="$3"

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_TYPE" ]; then
    echo "Usage: $0 <service-name> <type> [--with-logging]"
    echo
    echo "Arguments:"
    echo "  service-name    Name of the service (e.g., myapp)"
    echo "  type            Service type: longrun or oneshot"
    echo "  --with-logging  (Optional) Add logging pipeline for longrun services"
    echo
    echo "Examples:"
    echo "  $0 myapp longrun"
    echo "  $0 myapp longrun --with-logging"
    echo "  $0 db-init oneshot"
    exit 1
fi

case "$SERVICE_TYPE" in
    longrun|oneshot)
        ;;
    *)
        echo "Error: type must be 'longrun' or 'oneshot'"
        exit 1
        ;;
esac

SERVICE_DIR="/etc/s6-overlay/s6-rc.d/$SERVICE_NAME"

if [ -d "$SERVICE_DIR" ]; then
    echo "Error: Service already exists: $SERVICE_DIR"
    exit 1
fi

echo "Creating $SERVICE_TYPE service: $SERVICE_NAME"
echo

# Create main service directory
mkdir -p "$SERVICE_DIR/dependencies.d"
touch "$SERVICE_DIR/dependencies.d/base"

# Create type file
echo "$SERVICE_TYPE" > "$SERVICE_DIR/type"

# Create appropriate script files
if [ "$SERVICE_TYPE" = "longrun" ]; then
    cat > "$SERVICE_DIR/run" << 'EOF'
#!/bin/sh
# Redirect stderr to stdout for logging
exec 2>&1

# TODO: Replace with your actual service command
# Run your service in foreground mode (no daemon mode)
exec echo "Replace this with your service command"
EOF
    chmod +x "$SERVICE_DIR/run"

    echo "✓ Created run script: $SERVICE_DIR/run"
    echo "  TODO: Edit this file with your actual service command"

elif [ "$SERVICE_TYPE" = "oneshot" ]; then
    cat > "$SERVICE_DIR/up" << 'EOF'
#!/bin/sh
set -e
# TODO: Add your initialization commands here
echo "Running initialization for SERVICE_NAME"
EOF
    chmod +x "$SERVICE_DIR/up"

    echo "✓ Created up script: $SERVICE_DIR/up"
    echo "  TODO: Edit this file with your initialization commands"
fi

# Add logging if requested (only for longrun)
if [ "$SERVICE_TYPE" = "longrun" ] && [ "$WITH_LOGGING" = "--with-logging" ]; then
    LOG_PREPARE="${SERVICE_NAME}-log-prepare"
    LOG_SERVICE="${SERVICE_NAME}-log"
    PIPELINE_NAME="${SERVICE_NAME}-pipeline"

    echo
    echo "Setting up logging pipeline..."

    # Create log preparation oneshot
    mkdir -p "/etc/s6-overlay/s6-rc.d/$LOG_PREPARE/dependencies.d"
    touch "/etc/s6-overlay/s6-rc.d/$LOG_PREPARE/dependencies.d/base"
    echo "oneshot" > "/etc/s6-overlay/s6-rc.d/$LOG_PREPARE/type"

    cat > "/etc/s6-overlay/s6-rc.d/$LOG_PREPARE/up" << EOF
if { mkdir -p /var/log/$SERVICE_NAME }
if { chown nobody:nogroup /var/log/$SERVICE_NAME }
chmod 02755 /var/log/$SERVICE_NAME
EOF

    echo "✓ Created log preparation: $LOG_PREPARE"

    # Create logger service
    mkdir -p "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/dependencies.d"
    touch "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/dependencies.d/$LOG_PREPARE"
    echo "longrun" > "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/type"

    cat > "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/run" << EOF
#!/bin/sh
exec logutil-service /var/log/$SERVICE_NAME
EOF
    chmod +x "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/run"

    echo "$SERVICE_NAME" > "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/consumer-for"
    echo "$PIPELINE_NAME" > "/etc/s6-overlay/s6-rc.d/$LOG_SERVICE/pipeline-name"

    echo "✓ Created logger service: $LOG_SERVICE"

    # Link main service to logger
    echo "$LOG_SERVICE" > "$SERVICE_DIR/producer-for"

    echo "✓ Linked $SERVICE_NAME → $LOG_SERVICE"
    echo
    echo "Logging will be written to: /var/log/$SERVICE_NAME/"
fi

# Add to user bundle
if [ "$SERVICE_TYPE" = "longrun" ] && [ "$WITH_LOGGING" = "--with-logging" ]; then
    # Add pipeline to bundle, not individual service
    touch "/etc/s6-overlay/s6-rc.d/user/contents.d/$PIPELINE_NAME"
    echo "✓ Added to user bundle: $PIPELINE_NAME"
else
    touch "/etc/s6-overlay/s6-rc.d/user/contents.d/$SERVICE_NAME"
    echo "✓ Added to user bundle: $SERVICE_NAME"
fi

echo
echo "===================="
echo "Service created successfully!"
echo
echo "Next steps:"
echo "  1. Edit the service script(s) with your commands"
if [ "$SERVICE_TYPE" = "longrun" ]; then
    echo "  2. Ensure your service runs in foreground mode"
fi
echo "  3. Add dependencies if needed:"
echo "     touch $SERVICE_DIR/dependencies.d/other-service"
echo "  4. Test with: s6-rc -u change $SERVICE_NAME"
echo "  5. Rebuild your Docker image"
echo

# Print file structure
echo "Created files:"
if [ "$WITH_LOGGING" = "--with-logging" ]; then
    find "/etc/s6-overlay/s6-rc.d" -path "*$SERVICE_NAME*" -o -path "*$LOG_PREPARE*" -o -path "*$LOG_SERVICE*"
else
    find "/etc/s6-overlay/s6-rc.d/$SERVICE_NAME" -type f
fi
