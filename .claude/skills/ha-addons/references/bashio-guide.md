# Bashio Guide for Home Assistant Add-ons

Bashio is a bash function library specifically designed for Home Assistant add-ons. It provides a comprehensive set of commonly used operations to reduce code duplication across add-ons and simplify interactions with the Home Assistant Supervisor API.

## Table of Contents

- [Getting Started](#getting-started)
- [Configuration Management](#configuration-management)
- [Logging](#logging)
- [API Integration](#api-integration)
- [Service Discovery](#service-discovery)
- [Add-on Management](#add-on-management)
- [Home Assistant Core](#home-assistant-core)
- [File System Operations](#file-system-operations)
- [Network Operations](#network-operations)
- [Variable & String Utilities](#variable--string-utilities)
- [Caching](#caching)
- [Exit Handling](#exit-handling)
- [Common Patterns](#common-patterns)
- [Environment Variables](#environment-variables)

---

## Getting Started

### Including Bashio in Your Add-on

Use the `bashio` shebang to automatically load the library:

```bash
#!/usr/bin/with-contenv bashio

# Your add-on code here
bashio::log.info "Starting my add-on..."
```

Alternatively, source it manually:

```bash
#!/usr/bin/with-contenv bashio
# shellcheck source=/dev/null
source /usr/lib/bashio/bashio

bashio::log.info "Starting my add-on..."
```

### What Bashio Provides

Bashio includes these main modules:

- **config.sh** - Configuration option parsing and validation
- **log.sh** - Structured logging with levels
- **api.sh** - Supervisor API communication
- **services.sh** - Service discovery (MQTT, MySQL, etc.)
- **addons.sh** - Add-on information and management
- **core.sh** - Home Assistant Core control
- **fs.sh** - File system checks
- **net.sh** - Network utilities
- **var.sh** - Variable and JSON utilities
- **string.sh** - String manipulation
- **cache.sh** - In-memory caching
- **exit.sh** - Clean exit handling

---

## Configuration Management

### Reading Configuration Values

Configuration is stored in `/data/options.json`. Bashio provides convenient functions to read it.

```bash
# Get a configuration value
VALUE="$(bashio::config 'my_option')"

# Get with default value if not set
PORT="$(bashio::config 'port' '8080')"

# Get boolean
if bashio::config.true 'enabled'; then
    bashio::log.info "Feature is enabled"
fi

# Get nested values
API_KEY="$(bashio::config 'credentials.api_key')"
```

### Configuration Validation

```bash
# Check if option exists
if bashio::config.exists 'optional_feature'; then
    bashio::log.info "Optional feature is configured"
fi

# Check if option has a value
if bashio::config.has_value 'required_field'; then
    bashio::log.info "Required field is set"
fi

# Check if option is empty
if bashio::config.is_empty 'optional_field'; then
    bashio::log.warning "Optional field is empty"
fi

# Check specific value
if bashio::config.equals 'log_level' 'debug'; then
    bashio::log.level debug
fi
```

### Requiring Configuration

```bash
# Require a value (exits with error if not set)
bashio::config.require 'api_key'

# Require with custom reason
bashio::config.require 'database_path' \
    "The add-on needs a database to store data"

# Suggest (warning only)
bashio::config.suggest 'backup_location'

# Suggest enabling
bashio::config.suggest.true 'ssl'

# Suggest disabling
bashio::config.suggest.false 'debug_mode'
```

### Credential Helpers

```bash
# Require username
bashio::config.require.username 'user'

# Suggest username
bashio::config.suggest.username 'username'

# Require password
bashio::config.require.password 'pass'

# Suggest password
bashio::config.suggest.password 'password'

# Require safe password (checks HaveIBeenPwned)
bashio::config.require.safe_password 'admin_password'

# Suggest safe password
bashio::config.suggest.safe_password 'user_password'
```

### SSL Certificate Validation

```bash
# Require SSL certificates when SSL is enabled
bashio::config.require.ssl 'ssl_enabled' 'cert_file' 'key_file'

# This checks:
# - If 'ssl_enabled' is true
# - 'cert_file' and 'key_file' are set
# - The certificate files exist in /ssl/
```

---

## Logging

Bashio provides structured logging with multiple levels and colored output.

### Log Levels

```bash
# Trace - Very verbose debugging
bashio::log.trace "Detailed execution path"

# Debug - Debugging information
bashio::log.debug "Variable value: ${VALUE}"

# Info - General information (default level, green)
bashio::log.info "Service started successfully"

# Notice - Normal but significant condition (cyan)
bashio::log.notice "Configuration reloaded"

# Warning - Warning messages (yellow)
bashio::log.warning "Using default configuration"

# Error - Error conditions (magenta)
bashio::log.error "Failed to connect to service"

# Fatal - Critical conditions (red)
bashio::log.fatal "Cannot continue without configuration"
```

### Setting Log Level

```bash
# Change log level at runtime
bashio::log.level debug    # Show debug and above
bashio::log.level info     # Show info and above (default)
bashio::log.level warning  # Show only warnings and errors
bashio::log.level error    # Show only errors
bashio::log.level off      # Disable all logging
```

### Colored Output

```bash
# Direct colored output (no timestamp/level prefix)
bashio::log.red "Error message"
bashio::log.green "Success message"
bashio::log.yellow "Warning message"
bashio::log.blue "Info message"
bashio::log.magenta "Debug message"
bashio::log.cyan "Notice message"

# Plain output
bashio::log "Plain message"
```

### Log Format Customization

Bashio logs use these customizable variables:

- `LOG_LEVEL` - Minimum level to display
- `LOG_FORMAT` - Log message format
- `LOG_TIMESTAMP` - Timestamp format

---

## API Integration

Bashio handles all Supervisor API communication with authentication.

### Supervisor API Calls

```bash
# GET request (returns JSON data)
INFO="$(bashio::api.supervisor GET '/supervisor/info')"

# POST request with JSON data
bashio::api.supervisor POST '/addons/self/restart'

# POST with data payload
bashio::api.supervisor POST '/core/options' \
    "$(bashio::var.json 'log_level' 'debug')"

# GET raw response (not JSON)
LOGS="$(bashio::api.supervisor GET '/addons/self/logs' true)"

# With jq filter
VERSION="$(bashio::api.supervisor GET '/supervisor/info' false '.version')"
```

### Home Assistant Core API

When `homeassistant_api: true` is set in config.yaml:

```bash
# Get all states
STATES="$(curl -s -X GET \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    http://supervisor/core/api/states)"

# Call service
curl -s -X POST \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"entity_id": "light.living_room"}' \
    http://supervisor/core/api/services/light/turn_on
```

### WebSocket API

```bash
# Connect to Home Assistant WebSocket
websocat \
    --header "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    ws://supervisor/core/websocket
```

---

## Service Discovery

Discover shared services without user configuration.

### Checking Service Availability

```bash
# Check if MQTT service is available
if bashio::services.available 'mqtt'; then
    bashio::log.info "MQTT service is available"
fi

# Check if MySQL service is available
if bashio::services.available 'mysql'; then
    bashio::log.info "MySQL service is available"
fi
```

### Getting Service Configuration

```bash
# Get all MQTT service configuration
MQTT_CONFIG="$(bashio::services 'mqtt')"

# Get specific MQTT values
MQTT_HOST="$(bashio::services mqtt 'host')"
MQTT_PORT="$(bashio::services mqtt 'port')"
MQTT_USER="$(bashio::services mqtt 'username')"
MQTT_PASSWORD="$(bashio::services mqtt 'password')"

# Use in application
mosquitto_client \
    -h "${MQTT_HOST}" \
    -p "${MQTT_PORT}" \
    -u "${MQTT_USER}" \
    -P "${MQTT_PASSWORD}"
```

### Publishing Services

Make your add-on discoverable by others:

```bash
# Publish MQTT broker service
bashio::services.publish 'mqtt' \
    "$(bashio::var.json \
        host '127.0.0.1' \
        port '^1883' \
        username 'mqtt_user' \
        password 'mqtt_pass' \
        protocol '^4')"

# Delete published service
bashio::services.delete 'mqtt'
```

---

## Add-on Management

### Getting Add-on Information

```bash
# Get add-on name
NAME="$(bashio::addon.name)"

# Get current version
VERSION="$(bashio::addon.version)"

# Get latest available version
LATEST="$(bashio::addon.version_latest)"

# Check for updates
if bashio::addon.update_available; then
    bashio::log.info "Update available!"
fi

# Get add-on description
DESCRIPTION="$(bashio::addon.description)"

# Get add-on hostname
HOSTNAME="$(bashio::addon.hostname)"
```

### Networking

```bash
# Get DNS names for this add-on
DNS_NAMES="$(bashio::addon.dns)"

# Get IP address on HA network
IP_ADDRESS="$(bashio::addon.ip_address)"

# Get mapped port
MAPPED_PORT="$(bashio::addon.port 8080)"

# Check if using host network
if bashio::addon.host_network; then
    bashio::log.info "Running on host network"
fi

# Get all network info
NETWORK_INFO="$(bashio::addon.network)"
```

### Ingress

```bash
# Check if ingress is enabled
if bashio::addon.ingress; then
    bashio::log.info "Ingress is available"

    # Get ingress port
    INGRESS_PORT="$(bashio::addon.ingress_port)"

    # Get ingress URL
    INGRESS_URL="$(bashio::addon.ingress_url)"

    # Get ingress entry path
    INGRESS_ENTRY="$(bashio::addon.ingress_entry)"
fi
```

### Capabilities

```bash
# Check API access
if bashio::addon.homeassistant_api; then
    bashio::log.info "Has Home Assistant API access"
fi

if bashio::addon.hassio_api; then
    bashio::log.info "Has Supervisor API access"
fi

# Check privileges
if bashio::addon.privileged | grep -q 'SYS_ADMIN'; then
    bashio::log.info "Has SYS_ADMIN privilege"
fi

# Check hardware access
if bashio::addon.usb; then
    bashio::log.info "Has USB access"
fi

if bashio::addon.uart; then
    bashio::log.info "Has UART access"
fi

if bashio::addon.gpio; then
    bashio::log.info "Has GPIO access"
fi
```

### Options Management

```bash
# Get current options
OPTIONS="$(bashio::addon.options)"

# Get specific option
LOG_LEVEL="$(bashio::addon.options | jq -r '.log_level')"

# Set an option
bashio::addon.option 'log_level' 'debug'

# Remove an option
bashio::addon.option 'old_option'

# Set auto-update
bashio::addon.auto_update 'self' true

# Set watchdog
bashio::addon.watchdog 'self' true
```

### Add-on Control

```bash
# Restart this add-on
bashio::addon.restart 'self'

# Stop this add-on
bashio::addon.stop 'self'

# Start this add-on
bashio::addon.start 'self'

# Get logs
LOGS="$(bashio::addon.logs 'self')"

# Get documentation
DOCS="$(bashio::addon.documentation 'self')"

# Get changelog
CHANGELOG="$(bashio::addon.changelog 'self')"
```

### Protection Mode

```bash
# Require protection mode (exits if not enabled)
bashio::require.protected

# Require unprotected mode (exits if protected)
bashio::require.unprotected

# Check protection status
if bashio::addon.protected; then
    bashio::log.info "Running in protected mode"
fi
```

---

## Home Assistant Core

### Core Information

```bash
# Get Home Assistant version
HA_VERSION="$(bashio::core.version)"

# Get latest version
HA_LATEST="$(bashio::core.version_latest)"

# Check for updates
if bashio::core.update_available; then
    bashio::log.info "Home Assistant update available"
fi

# Get architecture
ARCH="$(bashio::core.arch)"

# Get machine type
MACHINE="$(bashio::core.machine)"

# Check if custom version
if bashio::core.custom; then
    bashio::log.info "Running custom Home Assistant version"
fi
```

### Core Control

```bash
# Start Home Assistant
bashio::core.start

# Stop Home Assistant
bashio::core.stop

# Restart Home Assistant
bashio::core.restart

# Update Home Assistant
bashio::core.update

# Update to specific version
bashio::core.update "2024.1.0"

# Rebuild Home Assistant
bashio::core.rebuild

# Check configuration
bashio::core.check

# Get logs
LOGS="$(bashio::core.logs)"
```

### Core Options

```bash
# Get/set image
IMAGE="$(bashio::core.image)"
bashio::core.image "homeassistant/home-assistant:latest"

# Get/set port
PORT="$(bashio::core.port)"

# Check if SSL enabled
if bashio::core.ssl; then
    bashio::log.info "Home Assistant is using SSL"
fi

# Get/set watchdog
if bashio::core.watchdog; then
    bashio::log.info "Watchdog is enabled"
fi
bashio::core.watchdog false
```

### Core Statistics

```bash
# CPU usage
CPU_PERCENT="$(bashio::core.cpu_percent)"

# Memory usage
MEMORY_USAGE="$(bashio::core.memory_usage)"
MEMORY_LIMIT="$(bashio::core.memory_limit)"
MEMORY_PERCENT="$(bashio::core.memory_percent)"

# Network statistics
NETWORK_TX="$(bashio::core.network_tx)"
NETWORK_RX="$(bashio::core.network_rx)"

# Disk I/O
BLK_READ="$(bashio::core.blk_read)"
BLK_WRITE="$(bashio::core.blk_write)"
```

---

## File System Operations

### Existence Checks

```bash
# Check if directory exists
if bashio::fs.directory_exists '/data/config'; then
    bashio::log.info "Config directory exists"
fi

# Check if file exists
if bashio::fs.file_exists '/data/options.json'; then
    bashio::log.info "Options file exists"
fi

# Check if device exists
if bashio::fs.device_exists '/dev/ttyUSB0'; then
    bashio::log.info "USB device found"
fi

# Check if socket exists
if bashio::fs.socket_exists '/var/run/docker.sock'; then
    bashio::log.info "Docker socket found"
fi
```

### Standard Paths

Home Assistant add-ons use these standard paths:

| Path | Description |
|------|-------------|
| `/data` | Persistent storage for add-on data |
| `/config` | Home Assistant configuration (if mapped) |
| `/share` | Home Assistant share folder (if mapped) |
| `/ssl` | SSL certificates (if mapped) |
| `/backup` | Home Assistant backups (if mapped) |
| `/media` | Home Assistant media (if mapped) |
| `/tmp` | Temporary files |

---

## Network Operations

### Wait for Services

```bash
# Wait for port to be available (default: localhost, 60s timeout)
bashio::net.wait_for 8080

# Wait for specific host
bashio::net.wait_for 3306 database.local 120

# Wait for database before starting
bashio::net.wait_for 5432 postgres
bashio::log.info "Database is ready, starting application"
```

### DNS Resolution

```bash
# Get DNS server
DNS_HOST="$(bashio::dns.host)"

# Get DNS servers
DNS_SERVERS="$(bashio::dns.servers)"

# Get local DNS servers
DNS_LOCALS="$(bashio::dns.locals)"

# DNS operations
bashio::dns.update
bashio::dns.restart
bashio::dns.reset
```

---

## Variable & String Utilities

### Variable Checks

```bash
# Check if true
if bashio::var.true "${ENABLED}"; then
    bashio::log.info "Is enabled"
fi

# Check if false
if bashio::var.false "${DISABLED}"; then
    bashio::log.info "Is disabled"
fi

# Check if has value
if bashio::var.has_value "${VARIABLE}"; then
    bashio::log.info "Has value: ${VARIABLE}"
fi

# Check if empty
if bashio::var.is_empty "${VARIABLE}"; then
    bashio::log.info "Is empty"
fi

# Check equality
if bashio::var.equals "${VALUE}" "expected"; then
    bashio::log.info "Values match"
fi
```

### JSON Creation

```bash
# Create JSON object (prefix non-strings with ^)
JSON="$(bashio::var.json \
    name 'My Add-on' \
    port '^8080' \
    enabled '^true' \
    items '["one","two"]')"

# Result: {"name":"My Add-on","port":8080,"enabled":true,"items":["one","two"]}
```

### String Manipulation

```bash
# Convert to lowercase
LOWER="$(bashio::string.lower 'HELLO WORLD')"  # "hello world"

# Convert to uppercase
UPPER="$(bashio::string.upper 'hello world')"  # "HELLO WORLD"

# Replace substring
RESULT="$(bashio::string.replace 'hello world' 'world' 'there')"  # "hello there"

# Get length
LENGTH="$(bashio::string.length 'hello')"  # 5

# Get substring
SUB="$(bashio::string.substring 'hello world' 6)"     # "world"
SUB="$(bashio::string.substring 'hello world' 0 5)"   # "hello"
```

---

## Caching

Bashio provides file-based caching to reduce API calls.

### Cache Operations

```bash
# Check if cache exists
if bashio::cache.exists 'my_key'; then
    bashio::log.info "Cached data found"
fi

# Get cached value
VALUE="$(bashio::cache.get 'my_key')"

# Set cache
bashio::cache.set 'my_key' 'cached value'

# Flush specific cache
bashio::cache.flush 'my_key'

# Flush all caches
bashio::cache.flush_all
```

### Using Cache with API Functions

Many bashio functions support automatic caching:

```bash
# First call fetches from API and caches
INFO="$(bashio::addon.info)"

# Subsequent calls use cache (if within same script)
INFO2="$(bashio::addon.info)"

# Use custom cache key with filter
VERSION="$(bashio::core 'custom.version.key' '.version')"
```

---

## Exit Handling

Clean exit functions for add-on termination.

### Exit Functions

```bash
# Exit with success
bashio::exit.ok

# Exit with error and message
bashio::exit.nok "Something went wrong"

# Exit if condition is false
bashio::exit.die_if_false "${CONDITION}" "Condition was false"

# Exit if condition is true
bashio::exit.die_if_true "${ERROR}" "Error occurred"

# Exit if value is empty
bashio::exit.die_if_empty "${REQUIRED_VAR}" "Variable is empty"
```

---

## Common Patterns

### Pattern 1: Basic Add-on Startup

```bash
#!/usr/bin/with-contenv bashio

# Require configuration
bashio::config.require 'api_key'

# Get configuration
API_KEY="$(bashio::config 'api_key')"
LOG_LEVEL="$(bashio::config 'log_level' 'info')"

# Set log level
bashio::log.level "${LOG_LEVEL}"

# Log startup
bashio::log.info "Starting add-on..."
bashio::log.debug "API key: ${API_KEY}"

# Run service
exec my-service --api-key "${API_KEY}"
```

### Pattern 2: Service Discovery

```bash
#!/usr/bin/with-contenv bashio

# Try to use MQTT service
if bashio::services.available 'mqtt'; then
    bashio::log.info "Using shared MQTT service"
    MQTT_HOST="$(bashio::services mqtt 'host')"
    MQTT_PORT="$(bashio::services mqtt 'port')"
    MQTT_USER="$(bashio::services mqtt 'username')"
    MQTT_PASSWORD="$(bashio::services mqtt 'password')"
else
    # Fallback to configuration
    bashio::log.info "Using configured MQTT"
    bashio::config.require 'mqtt_host'
    MQTT_HOST="$(bashio::config 'mqtt_host')"
    MQTT_PORT="$(bashio::config 'mqtt_port' '1883')"
    MQTT_USER="$(bashio::config 'mqtt_user')"
    MQTT_PASSWORD="$(bashio::config 'mqtt_password')"
fi

# Start service with MQTT configuration
exec my-app \
    --mqtt-host "${MQTT_HOST}" \
    --mqtt-port "${MQTT_PORT}" \
    --mqtt-user "${MQTT_USER}" \
    --mqtt-password "${MQTT_PASSWORD}"
```

### Pattern 3: SSL Configuration

```bash
#!/usr/bin/with-contenv bashio

# Check SSL option
if bashio::config.true 'ssl'; then
    bashio::log.info "SSL is enabled"

    # Validate certificates
    bashio::config.require.ssl

    # Get certificate paths
    CERTFILE="/ssl/$(bashio::config 'certfile')"
    KEYFILE="/ssl/$(bashio::config 'keyfile')"

    # Start with SSL
    exec my-server \
        --cert "${CERTFILE}" \
        --key "${KEYFILE}"
else
    bashio::log.info "Starting without SSL"
    exec my-server
fi
```

### Pattern 4: Wait for Dependencies

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting add-on..."

# Wait for database if configured
if bashio::config.has_value 'db_host'; then
    DB_HOST="$(bashio::config 'db_host')"
    DB_PORT="$(bashio::config 'db_port' '5432')"

    bashio::log.info "Waiting for database at ${DB_HOST}:${DB_PORT}"
    bashio::net.wait_for "${DB_PORT}" "${DB_HOST}"
fi

# Start application
exec my-app
```

### Pattern 5: Conditional Features

```bash
#!/usr/bin/with-contenv bashio

# Build command line arguments
ARGS=()

# Add debug mode if enabled
if bashio::config.true 'debug'; then
    bashio::log.level debug
    bashio::log.warning "Debug mode is enabled"
    ARGS+=(--debug)
fi

# Add verbose logging
if bashio::config.true 'verbose'; then
    ARGS+=(--verbose)
fi

# Suggest options if not set
bashio::config.suggest.true 'metrics' "Enable metrics for better monitoring"
bashio::config.suggest.false 'legacy_mode' "Legacy mode will be removed in future"

# Log configuration summary
bashio::log.info "Starting with arguments: ${ARGS[*]}"

# Start service
exec my-service "${ARGS[@]}"
```

### Pattern 6: Publishing a Service

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting service..."

# Start service in background
my-service --port 1883 &
SERVICE_PID=$!

# Publish service for other add-ons
bashio::services.publish 'mqtt' \
    "$(bashio::var.json \
        host '127.0.0.1' \
        port '^1883' \
        username 'user' \
        password '^pass' \
        protocol '^5')"

bashio::log.info "Service published, waiting for process..."

# Wait for service
wait "${SERVICE_PID}"

# Cleanup on exit
bashio::services.delete 'mqtt'
```

### Pattern 7: Home Assistant API Integration

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Home Assistant integration..."

# Get Home Assistant info
HA_VERSION="$(bashio::core.version)"
bashio::log.info "Home Assistant version: ${HA_VERSION}"

# Call Home Assistant API
STATES="$(curl -s -X GET \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Content-Type: application/json" \
    http://supervisor/core/api/states)"

# Process states
echo "${STATES}" | jq -r '.[] | select(.entity_id | startswith("sensor.")) | .entity_id'

# Start add-on
exec my-integration
```

---

## Environment Variables

Bashio respects these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SUPERVISOR_TOKEN` | (auto) | Supervisor API authentication token |
| `SUPERVISOR_API` | `http://supervisor` | Supervisor API endpoint |
| `LOG_LEVEL` | `info` | Minimum log level to display |
| `LOG_FORMAT` | `{TIMESTAMP} {LEVEL}: {MESSAGE}` | Log message format |
| `LOG_TIMESTAMP` | `%Y-%m-%d %H:%M:%S` | Timestamp format |
| `CACHE_DIR` | `/tmp/bashio/cache` | Cache storage directory |
| `HIBP_ENDPOINT` | (official) | Have I Been Pwned API endpoint |

---

## Best Practices

1. **Always use bashio for config parsing** - Don't manually read `/data/options.json`

2. **Log at appropriate levels** - Use `debug` for diagnostics, `info` for normal operation, `warning` for issues, `error` for failures

3. **Require critical configuration** - Use `bashio::config.require` for required values

4. **Suggest optional configuration** - Use `bashio::config.suggest` for recommended values

5. **Use service discovery** - Check for available services before requiring manual configuration

6. **Cache API results** - Many bashio functions cache automatically, use cache keys when calling repeatedly

7. **Clean exit** - Use `bashio::exit.nok` with clear error messages

8. **Validate SSL certificates** - Use `bashio::config.require.ssl` when SSL is enabled

9. **Use var.json for API payloads** - Ensures proper JSON formatting

10. **Check privilege/protection mode** - Verify `bashio::require.protected` or `bashio::require.unprotected` when needed

---

## Troubleshooting

### Debug Script Issues

Enable trace logging:

```bash
#!/usr/bin/with-contenv bashio

bashio::log.level trace
bashio::log.trace "Script execution started"
```

### Check Configuration

```bash
# Log all configuration
bashio::log.info "Configuration: $(bashio::addon.options)"

# Check specific values
bashio::log.debug "Port: $(bashio::config 'port')"
```

### API Debugging

```bash
# Enable debug logging to see API calls
bashio::log.level debug

# Check API connectivity
bashio::api.supervisor GET '/supervisor/info'
```

### Common Issues

**"Permission denied" errors:**
- Check if `hassio_api` is enabled in config.yaml
- Verify `hassio_role` is appropriate

**"Service not found" errors:**
- Service may not be available in your setup
- Use `bashio::services.available` before accessing

**"Configuration option missing" errors:**
- User hasn't set required options
- Use `bashio::config.suggest` for helpful messages
