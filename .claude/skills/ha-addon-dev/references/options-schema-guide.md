# Add-on Options and Schema Guide

Advanced patterns for defining user-configurable options with validation in Home Assistant add-ons.

## Overview

The `options` field defines default values, while `schema` enforces validation rules. Together they create a powerful configuration system that guides users and prevents invalid configurations.

## Basic Patterns

### Required vs Optional Fields

**Required field (has default value):**
```yaml
options:
  port: 8080
schema:
  port: "int(1024,65535)"
```
User must provide a value (default is 8080).

**Truly optional field (no default):**
```yaml
options: {}
schema:
  api_key: "str?"
```
User may leave empty. Add `?` suffix to type.

**Mandatory field (no default, not optional):**
```yaml
options:
  database_url: null
schema:
  database_url: str
```
User must provide value before add-on can start.

## Validation Types

### String Validation

**Basic string:**
```yaml
schema:
  name: str
```

**String with length constraints:**
```yaml
schema:
  username: "str(3,20)"      # 3-20 characters
  description: "str(,500)"    # Max 500 characters
  code: "str(6,)"             # Min 6 characters
```

**String with regex pattern:**
```yaml
schema:
  api_key: "match(^[A-Z0-9]{32}$)"  # 32 uppercase alphanumeric
  version: "match(^\\d+\\.\\d+\\.\\d+$)"  # Semantic version
```

**String enumeration:**
```yaml
schema:
  log_level: "list(debug|info|warning|error)"
```

### Integer Validation

**Basic integer:**
```yaml
schema:
  count: int
```

**Integer with range:**
```yaml
schema:
  port: "int(1024,65535)"     # Between 1024-65535
  workers: "int(1,)"          # Minimum 1
  max_size: "int(,1000)"      # Maximum 1000
```

### Float Validation

**Basic float:**
```yaml
schema:
  rate: float
```

**Float with range:**
```yaml
schema:
  temperature: "float(-20,50)"
  percentage: "float(0.0,100.0)"
```

### Boolean Validation

**Simple boolean:**
```yaml
schema:
  enabled: bool
  ssl: bool
```

### Specialized Types

**Email:**
```yaml
schema:
  admin_email: email
```

**URL:**
```yaml
schema:
  webhook_url: url
```

**Password (masked in UI):**
```yaml
schema:
  api_key: password
  db_password: password
```

**Port number:**
```yaml
schema:
  listen_port: port
```

**Device path:**
```yaml
schema:
  serial_device: device
  usb_device: "device(subsystem=usb)"
  tty_device: "device(subsystem=tty)"
```

## Complex Structures

### Nested Objects

**Configuration:**
```yaml
options:
  database:
    host: "localhost"
    port: 5432
    username: "admin"
    password: null
schema:
  database:
    host: str
    port: "int(1024,65535)"
    username: str
    password: password
```

**Access in run.sh:**
```bash
DB_HOST=$(bashio::config 'database.host')
DB_PORT=$(bashio::config 'database.port')
DB_USER=$(bashio::config 'database.username')
DB_PASS=$(bashio::config 'database.password')
```

### Lists (Arrays)

**Simple list:**
```yaml
options:
  allowed_ips:
    - "192.168.1.100"
    - "192.168.1.101"
schema:
  allowed_ips:
    - "match(^\\d+\\.\\d+\\.\\d+\\.\\d+$)"
```

**List of objects:**
```yaml
options:
  users:
    - username: "admin"
      password: "changeme"
      role: "administrator"
    - username: "guest"
      password: "guest123"
      role: "viewer"
schema:
  users:
    - username: str
      password: password
      role: "list(administrator|editor|viewer)"
```

**Access in run.sh:**
```bash
# Get number of users
USER_COUNT=$(bashio::config 'users | length')

# Iterate over users
for i in $(seq 0 $((USER_COUNT - 1))); do
  USERNAME=$(bashio::config "users[$i].username")
  PASSWORD=$(bashio::config "users[$i].password")
  ROLE=$(bashio::config "users[$i].role")
  echo "User: $USERNAME, Role: $ROLE"
done
```

## Validation Depth Limit

Maximum nesting depth is 2 levels:

**Valid:**
```yaml
options:
  database:
    connection:
      host: "localhost"
schema:
  database:
    connection:
      host: str
```

**Invalid (too deep):**
```yaml
options:
  level1:
    level2:
      level3:
        level4: "value"
```

## Optional Values Deep Dive

### Making Nested Fields Optional

**Entire object optional:**
```yaml
options: {}
schema:
  smtp:
    host: str
    port: int
    username: "str?"
    password: "password?"
```

If `smtp` not provided, entire section omitted.
If provided, `username` and `password` can be empty.

**Check in run.sh:**
```bash
if bashio::config.has_value 'smtp'; then
  SMTP_HOST=$(bashio::config 'smtp.host')
  if bashio::config.has_value 'smtp.username'; then
    SMTP_USER=$(bashio::config 'smtp.username')
  fi
fi
```

## Complete Examples

### Example 1: Web Server Configuration

```yaml
options:
  server:
    port: 8080
    ssl: false
    host: "0.0.0.0"
  authentication:
    enabled: true
    method: "basic"
  logging:
    level: "info"
    file: "/data/server.log"
schema:
  server:
    port: "int(1024,65535)"
    ssl: bool
    host: str
  authentication:
    enabled: bool
    method: "list(basic|digest|oauth)"
  logging:
    level: "list(debug|info|warning|error)"
    file: str
```

### Example 2: Database Service

```yaml
options:
  databases:
    - name: "primary"
      host: "db.local"
      port: 5432
      ssl: true
  backup:
    enabled: false
    schedule: "0 2 * * *"
    retention: 7
schema:
  databases:
    - name: str
      host: str
      port: "int(1024,65535)"
      ssl: bool
  backup:
    enabled: bool
    schedule: "match(^[\\d\\s\\*\\/]+$)"  # Cron pattern
    retention: "int(1,365)"
```

### Example 3: IoT Device Configuration

```yaml
options:
  devices:
    - id: "sensor1"
      type: "temperature"
      device: "/dev/ttyUSB0"
      interval: 60
  mqtt:
    enabled: false
schema:
  devices:
    - id: str
      type: "list(temperature|humidity|pressure|motion)"
      device: "device(subsystem=tty)"
      interval: "int(1,3600)"
  mqtt:
    enabled: bool
    host: "str?"
    port: "int?"
    username: "str?"
    password: "password?"
```

## Translations

Provide user-friendly names and descriptions for configuration options.

**translations/en.yaml:**
```yaml
configuration:
  server:
    name: Server Configuration
    description: Web server settings
    fields:
      port:
        name: Port
        description: TCP port for the web server
      ssl:
        name: Enable SSL
        description: Use HTTPS instead of HTTP
  logging:
    name: Logging Configuration
    description: Configure logging behavior
    fields:
      level:
        name: Log Level
        description: Minimum severity level to log
```

## Common Patterns

### Pattern: API Key with Optional Custom URL

```yaml
options:
  api_key: null
  api_url: "https://api.example.com"
schema:
  api_key: password
  api_url: url
```

### Pattern: Feature Flags

```yaml
options:
  features:
    experimental: false
    debug_mode: false
    telemetry: true
schema:
  features:
    experimental: bool
    debug_mode: bool
    telemetry: bool
```

### Pattern: Multiple Service Endpoints

```yaml
options:
  services:
    - name: "primary"
      url: "https://service1.com"
      timeout: 30
    - name: "backup"
      url: "https://service2.com"
      timeout: 60
schema:
  services:
    - name: str
      url: url
      timeout: "int(1,300)"
```

### Pattern: Conditional Configuration

```yaml
options:
  ssl:
    enabled: false
    cert_file: ""
    key_file: ""
schema:
  ssl:
    enabled: bool
    cert_file: "str?"
    key_file: "str?"
```

**Validation in run.sh:**
```bash
SSL_ENABLED=$(bashio::config 'ssl.enabled')

if bashio::var.true "${SSL_ENABLED}"; then
  # Validate SSL files exist
  if ! bashio::config.has_value 'ssl.cert_file'; then
    bashio::exit.nok "SSL enabled but cert_file not specified"
  fi

  CERT_FILE=$(bashio::config 'ssl.cert_file')
  if [ ! -f "$CERT_FILE" ]; then
    bashio::exit.nok "Certificate file not found: $CERT_FILE"
  fi
fi
```

## Validation Best Practices

1. **Use specific types** - Don't use `str` when `email`, `url`, or `password` is more appropriate
2. **Set reasonable ranges** - Always constrain integers and floats to prevent abuse
3. **Provide defaults** - Most options should have sensible defaults
4. **Use enumerations** - Limit choices with `list()` when possible
5. **Validate relationships** - Check interdependent options in run.sh
6. **Document constraints** - Use translations to explain validation rules
7. **Fail early** - Validate configuration before starting services
8. **Test edge cases** - Try empty values, boundary values, invalid patterns

## Advanced Validation in run.sh

Schema validates syntax, but run.sh should validate semantics:

```bash
#!/usr/bin/with-contenv bashio

# Schema ensures port is 1024-65535
PORT=$(bashio::config 'port')

# But we need to check if port is actually available
if netstat -tuln | grep -q ":${PORT} "; then
  bashio::exit.nok "Port ${PORT} is already in use"
fi

# Schema ensures URL format
WEBHOOK_URL=$(bashio::config 'webhook_url')

# But we should verify it's reachable
if ! curl -f -s -o /dev/null "${WEBHOOK_URL}"; then
  bashio::log.warning "Webhook URL may not be reachable: ${WEBHOOK_URL}"
fi

# Schema ensures list of valid device types
DEVICE_TYPE=$(bashio::config 'device.type')

# But we should check appropriate device exists
if [ "${DEVICE_TYPE}" = "serial" ]; then
  DEVICE_PATH=$(bashio::config 'device.path')
  if [ ! -c "${DEVICE_PATH}" ]; then
    bashio::exit.nok "Serial device not found: ${DEVICE_PATH}"
  fi
fi
```

## Handling Configuration Updates

Configuration changes during add-on runtime:

```bash
#!/usr/bin/with-contenv bashio

# In continuous loop
while true; do
  # Get current config
  CURRENT_PORT=$(bashio::config 'port')

  # Wait for changes
  bashio::config.wait

  # Config changed, reload
  NEW_PORT=$(bashio::config 'port')

  if [ "${NEW_PORT}" != "${CURRENT_PORT}" ]; then
    bashio::log.info "Port changed from ${CURRENT_PORT} to ${NEW_PORT}, restarting..."
    # Restart service
  fi
done
```

## Migration Between Versions

Handle configuration schema changes:

```bash
#!/usr/bin/with-contenv bashio

# Check if old option exists and migrate
if bashio::config.exists 'old_option_name'; then
  OLD_VALUE=$(bashio::config 'old_option_name')
  bashio::log.warning "Migrating old_option_name to new_option_name"

  # Update via API
  bashio::addon.option 'new_option_name' "${OLD_VALUE}"
  bashio::addon.option 'old_option_name'  # Delete old option
fi
```

See `configuration-reference.md` note about removing deprecated options.

## Debugging Schema Issues

**Common errors:**

1. **"Option does not exist in schema"**
   - User has old configuration with removed option
   - Delete using `bashio::addon.option 'key'`

2. **"Invalid value for schema"**
   - Value doesn't match validation rule
   - Check regex patterns, ranges, enumerations

3. **"Schema depth exceeded"**
   - Nested more than 2 levels deep
   - Flatten structure

4. **"Required option missing"**
   - Option in schema but not in options (with no default)
   - Add to options or make optional with `?`

Check Supervisor logs for detailed validation errors.
