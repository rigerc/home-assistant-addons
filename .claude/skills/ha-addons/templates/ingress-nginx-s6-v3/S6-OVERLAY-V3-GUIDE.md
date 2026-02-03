# s6-overlay v3 Guide for Home Assistant Add-ons

Complete guide for using s6-overlay v3 in Home Assistant add-ons with nginx and ingress.

## Table of Contents

- [Overview](#overview)
- [Lifecycle Stages](#lifecycle-stages)
- [Directory Structure](#directory-structure)
- [Initialization Scripts (cont-init.d)](#initialization-scripts-cont-initd)
- [Service Scripts (services.d)](#service-scripts-servicesd)
- [Nginx Integration](#nginx-integration)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

---

## Overview

s6-overlay v3 is a process supervision and init system for containers. Home Assistant base images include s6-overlay v3, so you don't need to install it.

### Key Concepts

- **Oneshot tasks**: Scripts that run once during startup (cont-init.d)
- **Longrun services**: Supervised processes that run continuously (services.d)
- **Foreground mode**: All services must run in foreground (not daemon)
- **Signal handling**: Proper SIGTERM/SIGINT handling for graceful shutdown

### s6-overlay v3 vs v2 Changes

| Feature | v2 | v3 |
|---------|----|----|
| init system | `/init` | `/init` (same) |
| cont-init.d | Same | Same |
| services.d | Same | Same |
| fix-attrs.d | Available | **Deprecated** - use static permissions |
| cont-finish.d | Available | **Removed** - use service finish scripts |
| Service dependencies | Manual | s6-rc available (advanced) |

---

## Lifecycle Stages

### Stage 1: System Setup

Handled automatically by s6-overlay:
- Sets up /run directory
- Prepares environment
- No user intervention needed

### Stage 2: Service Initialization

```
1. Run cont-init.d scripts sequentially (00-*, 10-*, 20-*, ...)
   ↓
2. Start all services.d services in parallel
   ↓
3. Container is now running
```

### Stage 3: Shutdown

```
1. Receive SIGTERM (docker stop)
   ↓
2. Send SIGTERM to all services
   ↓
3. Wait S6_SERVICES_GRACETIME (default: 3000ms)
   ↓
4. Send SIGKILL to remaining processes
   ↓
5. Run finish scripts if defined
   ↓
6. Container exits
```

---

## Directory Structure

```
rootfs/
├── etc/
│   ├── cont-init.d/          # Initialization scripts (oneshot)
│   │   ├── 10-banner.sh      # Display startup message
│   │   ├── 20-nginx.sh       # Configure nginx
│   │   └── 30-app.sh         # Configure application
│   │
│   └── services.d/           # Supervised services (longruns)
│       ├── nginx/
│       │   ├── run           # Start nginx
│       │   └── finish        # Handle nginx exit
│       └── app/
│           ├── run           # Start application
│           └── finish        # Handle app exit
│
└── usr/
    └── local/
        └── bin/
            └── myapp         # Application binary
```

---

## Initialization Scripts (cont-init.d)

Scripts in `/etc/cont-init.d/` run once during container startup, before any services start.

### Execution Order

Scripts run in alphanumeric order:
1. `00-*` - Early initialization
2. `10-*` - Configuration setup
3. `20-*` - Service-specific setup
4. `30-*` - Late initialization

### Script Requirements

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e  # Exit on error (stops container startup)

# Your initialization code here
```

### Best Practices

1. **Use `set -e`** to stop container on error
2. **Use bashio functions** for configuration
3. **Log all actions** with bashio::log
4. **Validate configuration** before continuing
5. **Create directories** with proper permissions

### Example: Basic Setup

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

bashio::log.info "Running initialization..."

# Create directories
mkdir -p /data/config
mkdir -p /data/logs

# Set ownership (use static permissions, not fix-attrs.d)
chown -R nobody:nogroup /data/logs

# Load configuration
LOG_LEVEL=$(bashio::config 'log_level')

# Generate config file
cat > /data/config/app.conf <<EOF
log_level=${LOG_LEVEL}
data_path=/data
EOF

bashio::log.info "Initialization complete"
```

### Example: Service Dependencies

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

# Wait for database before continuing
DB_HOST=$(bashio::config 'db_host')
DB_PORT=$(bashio::config 'db_port' '5432')

bashio::log.info "Waiting for database at ${DB_HOST}:${DB_PORT}"
bashio::net.wait_for "${DB_PORT}" "${DB_HOST}" 120

bashio::log.info "Database is ready"
```

### Example: Conditional Configuration

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

bashio::log.info "Configuring nginx..."

# Check if direct port is mapped
port=$(bashio::addon.port 8080)

if bashio::var.has_value "${port}"; then
    bashio::log.info "Direct port is mapped"

    # Check if SSL is enabled
    if bashio::config.true 'ssl'; then
        bashio::config.require.ssl
        bashio::log.info "SSL enabled"
        mv /etc/nginx/servers/direct-ssl.disabled /etc/nginx/servers/direct.conf
    else
        bashio::log.info "SSL disabled"
        mv /etc/nginx/servers/direct.disabled /etc/nginx/servers/direct.conf
    fi
fi

bashio::log.info "Nginx configuration complete"
```

---

## Service Scripts (services.d)

Each service directory in `/etc/services.d/` contains a supervised long-running process.

### Directory Structure

```
services.d/
└── myservice/
    ├── run       # Required: Starts the service
    └── finish    # Optional: Handles service exit
```

### run Script

**Purpose**: Start the service in foreground mode

**Requirements**:
- Must be executable (`chmod +x`)
- Must redirect stderr to stdout: `exec 2>&1`
- Must use `exec` to replace shell with service
- Service must run in foreground (not daemon)

**Template**:

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

# Redirect stderr to stdout
exec 2>&1

bashio::log.info "Starting service..."

# Load configuration
LOG_LEVEL=$(bashio::config 'log_level')

# Export environment variables
export LOG_LEVEL="${LOG_LEVEL}"

# Wait for dependencies (if needed)
# bashio::net.wait_for 5432 database 120

# Execute service in foreground
exec /usr/local/bin/myservice --foreground
```

**Important Notes**:

1. Always use `exec` - it replaces the shell with your service
2. Service must run in foreground - no daemon mode
3. Use `--foreground` or `--no-daemon` flag if available
4. Don't background with `&` - supervision won't work

### finish Script

**Purpose**: Handle service exit/crash

**Arguments**:
- `$1` = Exit code
  - `0` = Normal shutdown
  - `256` = Killed by signal
  - Other = Crash/error

**Template**:

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

declare SERVICE_EXIT_CODE=${1}

bashio::log.info "Service exited with code ${SERVICE_EXIT_CODE}"

if [[ "${SERVICE_EXIT_CODE}" -ne 0 ]] && [[ "${SERVICE_EXIT_CODE}" -ne 256 ]]; then
    # Service crashed - halt container
    bashio::log.error "Service crashed! Halting container."

    echo "${SERVICE_EXIT_CODE}" > /run/s6-linux-init-container-results/exitcode
    exec /run/s6/basedir/bin/halt
fi

# Normal exit - s6 will restart service
bashio::log.info "Service will restart automatically"
```

**Behavior**:

| Exit Code | Action | Result |
|-----------|--------|--------|
| 0 | Do nothing | Container stops normally |
| 256 | Do nothing | Container stops normally |
| Other | Halt container | Container stops with error |

---

## Nginx Integration

### nginx.conf Configuration

Key settings for s6-overlay compatibility:

```nginx
# Run in foreground (REQUIRED)
daemon off;

# Log to stdout/stderr
error_log /proc/1/fd/1 error;
access_log /proc/1/fd/1;

# User
user root;

# Pid location
pid /var/run/nginx.pid;
```

### Service Startup

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e
exec 2>&1

bashio::log.info "Starting nginx..."

# Wait for backend
bashio::net.wait_for 8080 localhost 300

# Test configuration
nginx -t || bashio::exit.nok "Nginx config test failed"

# Execute in foreground
exec nginx
```

### Graceful Shutdown

The finish script handles nginx exit:

```bash
#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

set -e

declare NGINX_EXIT_CODE=${1}

if [[ "${NGINX_EXIT_CODE}" -ne 0 ]] && [[ "${NGINX_EXIT_CODE}" -ne 256 ]]; then
    bashio::log.error "Nginx crashed! Halting container."
    echo "${NGINX_EXIT_CODE}" > /run/s6-linux-init-container-results/exitcode
    exec /run/s6/basedir/bin/halt
fi
```

---

## Best Practices

### 1. Always Use `exec`

```bash
# GOOD
exec /usr/bin/myapp --foreground

# BAD - shell stays as parent
/usr/bin/myapp --foreground
```

### 2. Always Run in Foreground

```bash
# GOOD - foreground mode
exec /usr/bin/myapp --foreground
exec /usr/bin/myapp --no-daemon

# BAD - daemon mode
exec /usr/bin/myapp --daemon
exec /usr/bin/myapp -d
```

### 3. Use `set -e` in Initialization

```bash
#!/usr/bin/with-contenv bashio
set -e  # Stops container on error
```

### 4. Log Everything

```bash
bashio::log.trace "Detailed diagnostic info"
bashio::log.debug "Debug information"
bashio::log.info "General information"
bashio::log.notice "Normal but significant"
bashio::log.warning "Warning message"
bashio::log.error "Error message"
bashio::log.fatal "Fatal error - exiting"
```

### 5. Validate Configuration

```bash
# Require critical configuration
bashio::config.require 'api_key'

# Validate SSL certificates
bashio::config.require.ssl

# Check optional values
if bashio::config.has_value 'optional_field'; then
    VALUE=$(bashio::config 'optional_field')
fi
```

### 6. Use Static Permissions

Don't use `/etc/fix-attrs.d/` (deprecated). Set permissions in:

- Dockerfile (build time)
- cont-init.d scripts (runtime)

```bash
# In Dockerfile
RUN chown -R nobody:nogroup /data

# In cont-init.d
chown -R nobody:nogroup /data/logs
```

---

## Common Patterns

### Pattern 1: Multiple Services

```
services.d/
├── app/
│   ├── run
│   └── finish
├── worker/
│   ├── run
│   └── finish
└── scheduler/
    ├── run
    └── finish
```

All services start in parallel and are supervised independently.

### Pattern 2: Service Dependencies

Use initialization script to wait for dependencies:

```bash
#!/usr/bin/with-contenv bashio
# In cont-init.d/20-wait-for-db.sh

bashio::log.info "Waiting for database..."
bashio::net.wait_for 5432 database 120

# Or use a simple loop
until pg_isready -h database; do
    sleep 1
done
```

### Pattern 3: Configuration Generation

```bash
#!/usr/bin/with-contenv bashio
# In cont-init.d/30-generate-config.sh

DB_HOST=$(bashio::config 'db_host')
DB_PORT=$(bashio::config 'db_port')
DB_USER=$(bashio::config 'db_user')
DB_PASS=$(bashio::config 'db_pass')

cat > /data/config/database.conf <<EOF
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASS}
EOF

chmod 600 /data/config/database.conf
```

### Pattern 4: Conditional Service Start

```bash
#!/usr/bin/with-contenv bashio
# In service run script

if bashio::config.true 'enable_worker'; then
    bashio::log.info "Starting worker..."
    exec /usr/bin/myapp worker
else
    bashio::log.info "Worker disabled, exiting"
    exit 0
fi
```

### Pattern 5: Health Checks

In nginx server config:

```nginx
location /health {
    access_log off;
    return 200 "healthy\n";
    add_header Content-Type text/plain;
}
```

---

## Troubleshooting

### Service Won't Start

1. Check script is executable:
   ```bash
   chmod +x /etc/services.d/myapp/run
   ```

2. Check for foreground mode:
   ```bash
   # Ensure no --daemon or -d flag
   exec /usr/bin/myapp --foreground
   ```

3. Check for proper `exec`:
   ```bash
   # Shell must be replaced
   exec /usr/bin/myapp
   ```

### Container Restarts Loops

1. Check finish script behavior:
   ```bash
   # Should halt on crash, not on normal exit
   if [[ "${EXIT_CODE}" -ne 0 ]] && [[ "${EXIT_CODE}" -ne 256 ]]; then
       exec /run/s6/basedir/bin/halt
   fi
   ```

2. Check logs in Home Assistant UI

3. Test configuration:
   ```bash
   docker run --rm -it local/myaddon sh
   ```

### Nginx Issues

1. Test configuration:
   ```bash
   nginx -t
   ```

2. Check for conflicting ports:
   ```bash
   netstat -tulpn | grep :8080
   ```

3. Verify backend is running:
   ```bash
   curl http://127.0.0.1:8080
   ```

### Debugging Scripts

Enable debug output:

```bash
#!/usr/bin/with-contenv bashio
set -x  # Enable debug output
set -e

bashio::log.info "Debug: Variable = ${VARIABLE}"
```

Check service status inside container:

```bash
s6-svstat /var/run/s6/services/*
cat /var/run/s6/services/*/log/current
```

### Common Errors

**"Permission denied"**:
- Make scripts executable
- Check file ownership

**"Port already in use"**:
- Change application port
- Check for conflicting services

**"Connection refused"**:
- Backend service not started
- Wrong port in nginx config
- Service not ready yet

---

## Reference Files

See template files for complete examples:
- `rootfs/etc/cont-init.d/*.sh` - Initialization scripts
- `rootfs/etc/services.d/*/run` - Service run scripts
- `rootfs/etc/services.d/*/finish` - Service finish scripts
- `rootfs/etc/nginx/nginx.conf` - Nginx configuration

## Additional Resources

- [s6-overlay Documentation](https://github.com/just-containers/s6-overlay)
- [Home Assistant Add-on Documentation](https://developers.home-assistant.io/docs/add-ons)
- [bashio Reference](../../bashio-guide.md)
- [config.yaml Reference](../references/config-reference.md)
