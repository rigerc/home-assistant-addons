# s6-overlay v3 Service Definitions

This directory contains s6-rc service definitions for s6-overlay v3.

## Service Structure

```
s6-rc.d/
├── example-init/           # Oneshot initialization service
│   ├── type                # Contains: oneshot
│   ├── up                  # Script to run for initialization
│   └── dependencies.d/
│       └── base            # Depends on base (system ready)
├── example-service/        # Longrun supervised service
│   ├── type                # Contains: longrun
│   ├── run                 # Service run script (foreground)
│   ├── finish              # Service finish script (handle crashes)
│   └── dependencies.d/
│       ├── base            # Depends on base
│       └── example-init    # Depends on initialization
└── user/                   # User bundle (services to start)
    └── contents.d/
        ├── example-init    # Include init service
        └── example-service # Include main service
```

## Service Types

### Oneshot Services
- Run once and exit (initialization, setup tasks)
- Files required:
  - `type` - contains "oneshot"
  - `up` - command or script to execute
- Optional:
  - `down` - rollback/cleanup script
  - `dependencies.d/` - service dependencies

### Longrun Services
- Continuously running services (daemons)
- Files required:
  - `type` - contains "longrun"
  - `run` - executable script (must run in foreground)
- Optional:
  - `finish` - script to run when service exits
  - `dependencies.d/` - service dependencies

## Dependencies

Dependencies control startup order. Create empty files in `dependencies.d/`:

```bash
# Make example-service depend on base
touch dependencies.d/base

# Make example-service depend on example-init
touch dependencies.d/example-init
```

**Common dependencies:**
- `base` - System is ready (always recommended)
- Custom services - Other services that must start first

## User Bundle

Services must be added to the `user` bundle to start automatically:

```bash
# Add service to user bundle
touch user/contents.d/example-service
```

## Example: Oneshot Service

Create initialization service that runs once:

```bash
# Create service directory
mkdir -p example-init/dependencies.d

# Set type
echo "oneshot" > example-init/type

# Create up script (inline command or script path)
echo "/etc/s6-overlay/scripts/init.sh" > example-init/up

# Add dependency on base
touch example-init/dependencies.d/base

# Add to user bundle
touch user/contents.d/example-init
```

## Example: Longrun Service

Create supervised service:

```bash
# Create service directory
mkdir -p myapp/dependencies.d

# Set type
echo "longrun" > myapp/type

# Create run script
cat > myapp/run <<'EOF'
#!/command/with-contenv bashio
exec 2>&1
bashio::log.info "Starting myapp..."
exec /usr/bin/myapp --foreground
EOF
chmod +x myapp/run

# Add dependencies
touch myapp/dependencies.d/base
touch myapp/dependencies.d/example-init

# Add to user bundle
touch user/contents.d/myapp
```

## Startup Order

With the example configuration:
1. `base` - System initialization
2. `example-init` - Oneshot initialization (depends on base)
3. `example-service` - Main service (depends on base and example-init)

## References

- [s6-overlay v3 Documentation](https://github.com/just-containers/s6-overlay)
- [s6-rc Documentation](https://skarnet.org/software/s6-rc/)
