# Advanced Service Management with s6-overlay

This guide covers advanced patterns for managing multiple services in Home Assistant add-ons using s6-overlay, based on the [romm](../../romm/) add-on implementation.

## What is s6-overlay?

s6-overlay is a process supervision and initialization system that provides:
- Multiple service management (run several processes in one container)
- Dependency-based startup ordering
- Graceful shutdown with signal handling
- Automatic service restart on failure
- Environment variable propagation

## Architecture

### Directory Structure

```
rootfs/etc/
├── cont-init.d/          # Initialization scripts (run once at startup)
│   ├── 01-setup.sh       # Must start with 2-digit prefix for order
│   ├── 02-migrations.sh  # Executed in numerical order
│   └── 99-finalize.sh    # Last initialization script
├── services.d/           # Long-running services
│   ├── nginx/            # Service name
│   │   ├── dependencies  # Services this depends on (one per line)
│   │   ├── run           # Startup script (executable, required)
│   │   └── finish        # Shutdown handler (optional)
│   ├── app/              # Main application
│   ├── worker/           # Background job processor
│   └── scheduler/        # Scheduled task runner
└── s6-overlay/           # s6-rc service database
    └── s6-rc.d/
        ├── user/         # Enabled services (symlinks)
        └── init/         # Initialization service
```

### Execution Flow

1. **Container Start**
   - s6-overlay initializes
   - Runs scripts in `cont-init.d/` in numerical order
   - Environment variables exported here are available to all services

2. **Service Startup**
   - s6-rc reads service definitions from `services.d/`
   - Resolves dependencies
   - Starts services in dependency order
   - Monitors service health

3. **Service Monitoring**
   - Each service runs under supervision
   - Failed services are automatically restarted
   - Logs are collected per service

4. **Container Shutdown**
   - SIGTERM received
   - Services stopped in reverse dependency order
   - Each service's `finish` script runs (if exists)
   - Graceful shutdown timeout (default: 30 seconds)

## Initialization Scripts

### Basic Template

```bash
#!/usr/bin/with-contenv bashio
# 01-setup.sh

bashio::log.info "Setting up configuration..."

# Validate required configuration
if ! bashio::config.has_value 'required_field'; then
    bashio::exit.nok "required_field is required!"
fi

# Create directories
mkdir -p /data/config
mkdir -p /data/cache

# Export environment variables for services
export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

export_env APP_PORT "$(bashio::addon.port '8080/tcp')"
export_env APP_LOG_LEVEL "$(bashio::config 'log_level')"

bashio::log.info "Setup complete"
```

### Advanced Template (romm pattern)

```bash
#!/usr/bin/with-contenv bashio
# 01-romm-setup.sh

bashio::log.info "Setting up Romm configuration..."

# Validate required configuration
if ! bashio::config.has_value 'database.host'; then
    bashio::exit.nok "Database host is required!"
fi

if ! bashio::config.has_value 'database.password'; then
    bashio::exit.nok "Database password is required!"
fi

# Create required directories with proper ownership
bashio::log.info "Creating data directories..."
mkdir -p /data/romm_resources
mkdir -p /data/redis_data
mkdir -p /data/romm_assets
mkdir -p /romm

# Get library path from config
LIBRARY_PATH="$(bashio::config 'library_path')"
if [ ! -d "$LIBRARY_PATH" ]; then
    bashio::log.warning "Library path ${LIBRARY_PATH} does not exist. Creating..."
    mkdir -p "$LIBRARY_PATH"
fi

# Create symlinks for application to access our data directories
# Application expects paths under /romm/* but we store data in HA-specific locations
bashio::log.info "Creating symlinks for data paths..."

# Remove old symlinks if they exist
for target_name in library resources assets; do
    symlink_path="/romm/${target_name}"
    if [ -L "$symlink_path" ]; then
        rm "$symlink_path"
    elif [ -e "$symlink_path" ]; then
        bashio::log.warning "${symlink_path} exists but is not a symlink, removing..."
        rm -rf "$symlink_path"
    fi
done

# Create fresh symlinks
ln -s "$LIBRARY_PATH" /romm/library
ln -s /data/romm_resources /romm/resources
ln -s /data/romm_assets /romm/assets

# Export environment variables for all services
export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

# Export database configuration
export_env DB_HOST "$(bashio::config 'database.host')"
export_env DB_PORT "$(bashio::config 'database.port')"
export_env DB_NAME "$(bashio::config 'database.name')"
export_env DB_USER "$(bashio::config 'database.user')"
export_env DB_PASSWD "$(bashio::config 'database.password')"

# Export optional configuration
if bashio::config.has_value 'metadata_providers.screenscraper_user'; then
    export_env SCREENSCRAPER_USER "$(bashio::config 'metadata_providers.screenscraper_user')"
fi

# Export nginx configuration
export_env ROMM_PORT "$(bashio::addon.port '5999/tcp')"
export_env ROMM_BASE_PATH "/romm"

bashio::log.info "Setup complete"
```

### Database Migration Template

```bash
#!/usr/bin/with-contenv bashio
# 02-migrations.sh

bashio::log.info "Running database migrations..."

# Start temporary service for migrations
# This pattern is useful when you need a service (like database) for migrations

cd /app || exit 1

# Run migrations
python manage.py migrate --noinput

# Run startup tasks
python manage.py startup_tasks

bashio::log.info "Migrations complete"
```

## Service Scripts

### Basic Service

```bash
#!/usr/bin/with-contenv bashio
# myapp/run

bashio::log.info "Starting my application..."

cd /app || exit 1

# Use exec to replace the script with the application
# This ensures signals are properly handled
exec python app.py
```

### Service with Dependencies

**File: `myapp/dependencies`**
```
nginx
valkey
```

Services listed will start before this service.

### Nginx Service with Template Processing

```bash
#!/usr/bin/with-contenv bashio
# nginx/run

bashio::log.info "Starting nginx..."

# Process templates with envsubst
mkdir -p /etc/nginx
for template in /etc/nginx/templates/*.template; do
    if [ -f "$template" ]; then
        config="${template%.template}"
        bashio::log.info "Processing ${template}..."
        envsubst < "${template}" > "${config}"
    fi
done

# Remove default config if exists
rm -f /etc/nginx/conf.d/default.conf

# Start nginx (exec replaces the script)
exec nginx -g 'daemon off;'
```

### Background Worker Service

```bash
#!/usr/bin/with-contenv bashio
# worker/run

bashio::log.info "Starting background worker..."

cd /app || exit 1

# Start worker process
exec python worker.py \
    --log-level="${WORKER_LOG_LEVEL:-info}" \
    --concurrency="${WORKER_CONCURRENCY:-2}"
```

### Scheduler Service

```bash
#!/usr/bin/with-contenv bashio
# scheduler/run

bashio::log.info "Starting scheduler..."

cd /app || exit 1

# Start scheduler
exec python scheduler.py \
    --interval="${SCHEDULER_INTERVAL:-60}"
```

### Service with Finish Handler

**File: `myapp/finish`**
```bash
#!/usr/bin/with-contenv bashio
# myapp/finish

bashio::log.info "Shutting down my application..."

# Perform cleanup tasks
# - Close database connections
# - Flush caches
# - Save state

bashio::log.info "Shutdown complete"
```

## Multi-Service Example

Based on the romm add-on, here's a complete multi-service setup:

### Service Structure

```
services.d/
├── nginx/           # Reverse proxy (starts first)
├── valkey/          # Redis/Cache (no dependencies)
├── romm-main/       # Main FastAPI application
│   ├── dependencies: valkey
├── rq-worker/       # Background job processor
│   ├── dependencies: valkey, romm-main
├── rq-scheduler/    # Scheduled task runner
│   ├── dependencies: valkey, romm-main
└── watcher/         # File watcher for library changes
    ├── dependencies: romm-main
```

### Dependency Chain

```
nginx ─┐
valkey ─┼─> romm-main ─┬─> rq-worker
                       ├─> rq-scheduler
                       └─> watcher
```

### Main Application Service

```bash
#!/usr/bin/with-contenv bashio
# romm-main/run

bashio::log.info "Starting Romm web server..."

cd /backend || bashio::exit.nok "Failed to change to /backend directory"

# Use gunicorn for production WSGI server
exec gunicorn main:app \
    --bind "unix:/tmp/gunicorn.sock" \
    --worker-class uvicorn_worker.UvicornWorker \
    --workers 1 \
    --timeout 300 \
    --keep-alive 2 \
    --max-requests 1000 \
    --max-requests-jitter 100 \
    --worker-connections 1000 \
    --error-logfile - \
    --pid /tmp/gunicorn.pid
```

### Worker Service

```bash
#!/usr/bin/with-contenv bashio
# rq-worker/run

bashio::log.info "Starting RQ worker..."

cd /backend || bashio::exit.nok "Failed to change to /backend directory"

# Start Redis Queue worker
exec python -m rq worker \
    --url "${REDIS_URL}" \
    --log-level="${WORKER_LOG_LEVEL:-info}"
```

## Environment Variables

### Exporting Variables

Variables exported in `cont-init.d` scripts are available to all services:

```bash
# In 01-setup.sh
export_env() {
    local name="$1"
    local value="$2"
    export "$name=$value"
    printf "%s" "$value" > "/var/run/s6/container_environment/$name"
}

export_env DATABASE_URL "postgresql://user:pass@host/db"
```

### Using Variables in Services

```bash
# In any service run script
echo "Database URL: ${DATABASE_URL}"
exec myapp --db="${DATABASE_URL}"
```

### Variable Scoping

- Exported variables persist across all services
- Service-specific variables can be set in the service's `run` script
- Variables are not persisted across container restarts

## Nginx Configuration

### Template File

**File: `rootfs/etc/nginx/templates/default.conf.template`**

```nginx
server {
    listen ${APP_PORT};
    server_name _;

    root /var/www/html;
    index index.html;

    # Client body size limit for uploads
    client_max_body_size 500M;
    client_body_timeout 300s;

    # Frontend static files
    location / {
        alias /var/www/html/;
        try_files $uri $uri/ /index.html;

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API endpoints - proxy to application
    location /api/ {
        proxy_pass http://unix:/tmp/app.sock:/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://unix:/tmp/app.sock:/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    # Static media files
    location /resources/ {
        alias /data/resources/;
        expires 1y;
        add_header Cache-Control "public";
    }

    # Health check
    location /health {
        proxy_pass http://unix:/tmp/app.sock:/health;
        access_log off;
    }
}
```

### Main Nginx Config

**File: `rootfs/etc/nginx.conf`**

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;

    # Include site configs
    include /etc/nginx/conf.d/*.conf;
}
```

## Signal Handling

### Proper Signal Handling

Use `exec` to replace the script with your application:

```bash
#!/usr/bin/with-contenv bashio

# Good - signals handled correctly
exec python app.py

# Bad - signals not handled, creates extra process
python app.py
```

### Graceful Shutdown

Implement graceful shutdown in your application:

```python
import signal
import sys

def signal_handler(sig, frame):
    print("Shutting down gracefully...")
    # Cleanup tasks
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)
```

## Troubleshooting

### Service Not Starting

1. Check the `run` script is executable:
   ```bash
   chmod +x rootfs/etc/services.d/myapp/run
   ```

2. Verify dependencies are correct:
   ```
   cat rootfs/etc/services.d/myapp/dependencies
   ```

3. Check logs in Home Assistant Supervisor

### Environment Variables Not Available

1. Verify export in `cont-init.d`:
   ```bash
   export_env MY_VAR "value"
   ```

2. Check variable file:
   ```bash
   cat /var/run/s6/container_environment/MY_VAR
   ```

### Dependencies Not Resolved

1. Ensure dependency services exist:
   ```bash
   ls rootfs/etc/services.d/
   ```

2. Check dependency file format (one per line, no trailing spaces)

## Best Practices

1. **Use numerical prefixes** for `cont-init.d` scripts to control execution order
2. **Always use `exec`** to run your application for proper signal handling
3. **Export environment variables** in `cont-init.d`, not in service scripts
4. **Create symlinks** to map application paths to Home Assistant paths
5. **Use `finish` scripts** for cleanup tasks
6. **Log messages** at service start for debugging
7. **Validate configuration** before starting services
8. **Handle signals** properly for graceful shutdown
9. **Use templates** for configuration files with variable substitution
10. **Monitor service health** through logs

## References

- [s6-overlay Documentation](https://github.com/just-containers/s6-overlay)
- [s6-rc Documentation](https://github.com/just-containers/s6-rc)
- [bashio Documentation](https://github.com/hassio-addons/bashio)
- [romm Add-on](../../romm/) - Full working example
