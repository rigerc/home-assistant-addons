# s6-overlay v2 Directory Structure

This directory contains the s6-overlay v2 service definitions and initialization scripts for the Home Assistant add-on.

## Directory Structure

```
rootfs/
├── etc/
│   ├── cont-init.d/          # Initialization scripts (run before services)
│   │   ├── 00-banner.sh      # Display startup banner
│   │   └── 01-setup.sh       # Setup environment and configuration
│   └── services.d/           # Supervised services (longruns)
│       └── example-app/
│           ├── run           # Service run script (starts the service)
│           └── finish        # Service finish script (handles crashes)
└── usr/
    └── bin/
        └── example-app       # Example application binary/script
```

## How It Works

### Startup Sequence

1. **Container Initialization** (s6-overlay stage 1)
   - Basic system setup
   - Environment preparation

2. **Initialization Scripts** (s6-overlay stage 2 - cont-init.d/)
   - Scripts run in alphanumeric order (00-*, 01-*, 02-*, ...)
   - Used for one-time setup tasks:
     - Create directories
     - Generate configuration files
     - Run database migrations
     - Validate configuration
   - If any script exits with non-zero code, container stops

3. **Services Start** (s6-overlay stage 2 - services.d/)
   - All services start in parallel
   - Each service runs its `run` script
   - Services are supervised and auto-restart on failure

4. **Container Running**
   - Services continue running under s6 supervision
   - Logs are collected and displayed

### Service Files

#### `run` Script
- **Purpose**: Start and run the service
- **Requirements**:
  - Must be executable (`chmod +x`)
  - Must run process in foreground (not daemon mode)
  - Should redirect stderr to stdout: `exec 2>&1`
  - Should use `exec` to replace shell with the process
- **Example**:
  ```bash
  #!/usr/bin/with-contenv bashio
  exec 2>&1
  bashio::log.info "Starting service..."
  exec /usr/bin/myapp --foreground
  ```

#### `finish` Script
- **Purpose**: Handle service exit/crash
- **Arguments**: Receives exit code as `${1}`
  - `0` = Normal exit
  - `256` = Killed by signal
  - Other = Abnormal exit
- **Behavior Options**:
  - Do nothing: s6 automatically restarts the service
  - Halt container: `exec /run/s6/basedir/bin/halt`
- **Example**:
  ```bash
  #!/usr/bin/with-contenv bashio
  declare APP_EXIT_CODE=${1}
  if [[ "${APP_EXIT_CODE}" -ne 0 ]] && [[ "${APP_EXIT_CODE}" -ne 256 ]]; then
      bashio::log.error "Service crashed - halting container"
      echo "${APP_EXIT_CODE}" > /run/s6-linux-init-container-results/exitcode
      exec /run/s6/basedir/bin/halt
  fi
  ```

### Initialization Scripts (cont-init.d/)

- Run once during container startup, before services
- Execute in alphanumeric order (00-*, 01-*, 02-*)
- Use for setup tasks:
  - Create directories
  - Generate config files
  - Run migrations
  - Validate settings
- Exit with non-zero to stop container

**Example**:
```bash
#!/usr/bin/with-contenv bashio
bashio::log.info "Setting up environment..."
mkdir -p /data/config
if ! bashio::config.has_value 'required_setting'; then
    bashio::exit.nok "Missing required configuration"
fi
```

## Using bashio

All scripts should use `#!/usr/bin/with-contenv bashio` to:
- Load Home Assistant environment variables
- Access bashio helper functions

**Common bashio functions**:
```bash
# Get config value
MESSAGE=$(bashio::config 'message')

# Check if config exists
if bashio::config.has_value 'optional_field'; then
    VALUE=$(bashio::config 'optional_field')
fi

# Iterate over array
for item in $(bashio::config 'items|keys'); do
    NAME=$(bashio::config "items[${item}].name")
done

# Logging
bashio::log.info "Information message"
bashio::log.warning "Warning message"
bashio::log.error "Error message"

# Exit with error
bashio::exit.nok "Fatal error message"

# Get add-on port (for ingress)
PORT=$(bashio::addon.port '8080')
```

## Dockerfile Integration

Add to your Dockerfile:

```dockerfile
# Copy rootfs structure
COPY rootfs /

# Make scripts executable (if not already done)
RUN chmod +x /etc/cont-init.d/*.sh && \
    chmod +x /etc/services.d/*/run && \
    chmod +x /etc/services.d/*/finish
```

**Note**: Home Assistant base images already include s6-overlay, so you don't need to install it.

## Common Patterns

### Multiple Services

Create multiple service directories:

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

### Service Dependencies

If services need specific startup order, use initialization scripts:

```bash
# In cont-init.d/02-wait-for-database.sh
#!/usr/bin/with-contenv bashio
until pg_isready -h database; do
    sleep 1
done
```

### Oneshot Services

For tasks that run once and exit, use cont-init.d/ scripts, not services.d/:

```bash
# cont-init.d/03-migrate-database.sh
#!/usr/bin/with-contenv bashio
bashio::log.info "Running migrations..."
/app/migrate || bashio::exit.nok "Migration failed"
```

## Debugging

Inside a running container:

```bash
# Check service status
s6-svstat /var/run/s6/services/*

# View service logs
cat /var/run/s6/services/example-app/log/current

# Manually stop a service
s6-svc -d /var/run/s6/services/example-app

# Manually start a service
s6-svc -u /var/run/s6/services/example-app

# Restart a service
s6-svc -r /var/run/s6/services/example-app
```

## References

- [s6-overlay v2 Documentation](https://github.com/just-containers/s6-overlay/tree/v2.2.0.3)
- [Home Assistant Add-on Documentation](https://developers.home-assistant.io/docs/add-ons)
- [bashio Documentation](https://github.com/hassio-addons/bashio)
