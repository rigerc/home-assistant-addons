#!/bin/sh
#
# Validate s6-rc service definition
# Usage: ./validate-service.sh /etc/s6-overlay/s6-rc.d/myservice
#

set -e

SERVICE_DIR="$1"

if [ -z "$SERVICE_DIR" ]; then
    echo "Usage: $0 <service-directory>"
    echo "Example: $0 /etc/s6-overlay/s6-rc.d/myapp"
    exit 1
fi

if [ ! -d "$SERVICE_DIR" ]; then
    echo "Error: Directory does not exist: $SERVICE_DIR"
    exit 1
fi

SERVICE_NAME=$(basename "$SERVICE_DIR")
ERRORS=0
WARNINGS=0

echo "Validating service: $SERVICE_NAME"
echo "===================="
echo

# Check 'type' file exists
if [ ! -f "$SERVICE_DIR/type" ]; then
    echo "ERROR: Missing 'type' file"
    ERRORS=$((ERRORS + 1))
else
    SERVICE_TYPE=$(cat "$SERVICE_DIR/type")
    echo "Service type: $SERVICE_TYPE"

    # Validate type value
    case "$SERVICE_TYPE" in
        longrun|oneshot|bundle)
            ;;
        *)
            echo "ERROR: Invalid type '$SERVICE_TYPE' (must be: longrun, oneshot, or bundle)"
            ERRORS=$((ERRORS + 1))
            ;;
    esac
fi

echo

# Type-specific validation
if [ "$SERVICE_TYPE" = "longrun" ]; then
    # Longrun must have 'run' script
    if [ ! -f "$SERVICE_DIR/run" ]; then
        echo "ERROR: Longrun service missing 'run' script"
        ERRORS=$((ERRORS + 1))
    else
        if [ ! -x "$SERVICE_DIR/run" ]; then
            echo "WARNING: 'run' script is not executable"
            WARNINGS=$((WARNINGS + 1))
        else
            echo "✓ 'run' script exists and is executable"
        fi
    fi

    # Check for producer-for (logging)
    if [ -f "$SERVICE_DIR/producer-for" ]; then
        PRODUCER_FOR=$(cat "$SERVICE_DIR/producer-for")
        echo "✓ Produces for: $PRODUCER_FOR"

        # Check if consumer exists
        CONSUMER_DIR="/etc/s6-overlay/s6-rc.d/$PRODUCER_FOR"
        if [ ! -d "$CONSUMER_DIR" ]; then
            echo "WARNING: Consumer service '$PRODUCER_FOR' does not exist"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    # Check for consumer-for (logging)
    if [ -f "$SERVICE_DIR/consumer-for" ]; then
        CONSUMER_FOR=$(cat "$SERVICE_DIR/consumer-for")
        echo "✓ Consumes from: $CONSUMER_FOR"

        if [ -f "$SERVICE_DIR/pipeline-name" ]; then
            PIPELINE_NAME=$(cat "$SERVICE_DIR/pipeline-name")
            echo "✓ Pipeline name: $PIPELINE_NAME"
        else
            echo "WARNING: consumer-for defined but no pipeline-name"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

elif [ "$SERVICE_TYPE" = "oneshot" ]; then
    # Oneshot must have 'up' file
    if [ ! -f "$SERVICE_DIR/up" ]; then
        echo "ERROR: Oneshot service missing 'up' file"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ 'up' file exists"

        # Check if up is executable or command line
        if [ -x "$SERVICE_DIR/up" ]; then
            echo "  'up' is an executable script"
        else
            # Check if it's a path to an executable
            UP_CONTENT=$(head -n 1 "$SERVICE_DIR/up")
            if [ -f "$UP_CONTENT" ] && [ -x "$UP_CONTENT" ]; then
                echo "  'up' references: $UP_CONTENT"
            else
                echo "  'up' is a command line"
            fi
        fi
    fi

    # Check for 'down' (optional)
    if [ -f "$SERVICE_DIR/down" ]; then
        echo "✓ 'down' file exists (finalization)"
    fi
fi

echo

# Check dependencies
if [ -d "$SERVICE_DIR/dependencies.d" ]; then
    DEP_COUNT=$(find "$SERVICE_DIR/dependencies.d" -type f | wc -l)
    if [ "$DEP_COUNT" -eq 0 ]; then
        echo "WARNING: dependencies.d/ exists but is empty"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "Dependencies ($DEP_COUNT):"
        for dep_file in "$SERVICE_DIR/dependencies.d"/*; do
            if [ -f "$dep_file" ]; then
                dep_name=$(basename "$dep_file")
                echo "  - $dep_name"

                # Check if dependency exists
                if [ "$dep_name" != "base" ]; then
                    DEP_DIR="/etc/s6-overlay/s6-rc.d/$dep_name"
                    if [ ! -d "$DEP_DIR" ]; then
                        echo "    WARNING: Dependency '$dep_name' does not exist"
                        WARNINGS=$((WARNINGS + 1))
                    fi
                fi
            fi
        done
    fi
else
    echo "WARNING: No dependencies.d/ directory"
    echo "  Consider adding: dependencies.d/base"
    WARNINGS=$((WARNINGS + 1))
fi

echo

# Check if service is in a bundle
BUNDLE_COUNT=0
for bundle_dir in /etc/s6-overlay/s6-rc.d/*/contents.d; do
    if [ -d "$bundle_dir" ]; then
        if [ -f "$bundle_dir/$SERVICE_NAME" ]; then
            bundle_name=$(basename "$(dirname "$bundle_dir")")
            echo "✓ Service is in bundle: $bundle_name"
            BUNDLE_COUNT=$((BUNDLE_COUNT + 1))
        fi
    fi
done

# Check for pipeline in bundle (if this is a consumer)
if [ -f "$SERVICE_DIR/pipeline-name" ]; then
    PIPELINE_NAME=$(cat "$SERVICE_DIR/pipeline-name")
    PIPELINE_IN_BUNDLE=0
    for bundle_dir in /etc/s6-overlay/s6-rc.d/*/contents.d; do
        if [ -d "$bundle_dir" ]; then
            if [ -f "$bundle_dir/$PIPELINE_NAME" ]; then
                bundle_name=$(basename "$(dirname "$bundle_dir")")
                echo "✓ Pipeline '$PIPELINE_NAME' is in bundle: $bundle_name"
                PIPELINE_IN_BUNDLE=1
            fi
        fi
    done

    if [ $PIPELINE_IN_BUNDLE -eq 0 ]; then
        echo "ERROR: Pipeline '$PIPELINE_NAME' is not in any bundle"
        echo "  Run: touch /etc/s6-overlay/s6-rc.d/user/contents.d/$PIPELINE_NAME"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ $BUNDLE_COUNT -eq 0 ] && [ ! -f "$SERVICE_DIR/pipeline-name" ]; then
    echo "WARNING: Service is not in any bundle (will not start automatically)"
    echo "  Run: touch /etc/s6-overlay/s6-rc.d/user/contents.d/$SERVICE_NAME"
    WARNINGS=$((WARNINGS + 1))
fi

echo
echo "===================="
echo "Validation complete:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"
echo

if [ $ERRORS -gt 0 ]; then
    echo "Service has errors and may not work correctly"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "Service has warnings but should work"
    exit 0
else
    echo "Service looks good!"
    exit 0
fi
