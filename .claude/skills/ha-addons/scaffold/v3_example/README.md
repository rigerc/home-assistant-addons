# s6-overlay v3 Example

This directory contains example s6-overlay v3 service definitions using the s6-rc format.

## What is s6-overlay v3?

s6-overlay v3 is the latest version of the s6-overlay init system, using the s6-rc service manager format. It provides more features and better service dependency management than v2.

## Directory Structure

```
v3_example/
└── s6-overlay/
    ├── s6-rc.d/              # Service definitions
    │   ├── example-init/     # Oneshot initialization service
    │   │   ├── type          # Service type: "oneshot"
    │   │   ├── up            # Command/script to run
    │   │   └── dependencies.d/
    │   │       └── base      # Depends on base system
    │   ├── example-service/  # Longrun supervised service
    │   │   ├── type          # Service type: "longrun"
    │   │   ├── run           # Service run script
    │   │   ├── finish        # Service finish script
    │   │   └── dependencies.d/
    │   │       ├── base
    │   │       └── example-init
    │   ├── user/             # User bundle (auto-start services)
    │   │   └── contents.d/
    │   │       ├── example-init
    │   │       └── example-service
    │   └── README.md
    └── scripts/
        └── example-init.sh   # Initialization script
```

## Using in Your Add-on

### Option 1: Copy to rootfs (recommended for new add-ons)

```bash
# Copy the s6-overlay directory to your rootfs
cp -r v3_example/s6-overlay rootfs/etc/
```

Your Dockerfile should copy rootfs:
```dockerfile
COPY rootfs /
```

### Option 2: Keep using v2 (services.d/)

The main scaffold uses s6-overlay v2 format (`rootfs/etc/services.d/`), which is still widely used and fully supported. Use v2 if:
- You're familiar with the v2 format
- Migrating from existing add-ons
- You don't need complex service dependencies

## Key Differences: v2 vs v3

| Feature | v2 (services.d) | v3 (s6-rc.d) |
|---------|----------------|--------------|
| Service location | `/etc/services.d/` | `/etc/s6-overlay/s6-rc.d/` |
| Init scripts | `/etc/cont-init.d/` | oneshot services with `type` and `up` |
| Service types | Only longruns | longruns + oneshots |
| Dependencies | Manual (wait in scripts) | Declarative (`dependencies.d/`) |
| Service definition | `run` + `finish` | `type`, `run`/`up`, `finish`, dependencies |
| Complexity | Simple | More structured |

## When to Use v3

Use s6-overlay v3 when you need:
- Complex service dependency chains
- Oneshot initialization services that are part of the dependency graph
- Better service lifecycle management
- Modern s6-rc features

## When to Use v2

Use s6-overlay v2 when:
- You have simple service requirements
- You're maintaining existing add-ons
- You prefer the simpler cont-init.d + services.d pattern

## Service Startup Order (v3 Example)

1. System initialization (automatic)
2. `base` service ready
3. `example-init` oneshot runs (depends on base)
4. `example-service` longrun starts (depends on base + example-init)

## Examples Included

### example-init (Oneshot)
- Creates directories
- Generates configuration
- Validates settings
- Runs before main service

### example-service (Longrun)
- Main application service
- Supervised and auto-restarted
- Depends on initialization completing
- Proper crash handling

## Testing

To test v3 services in your add-on:

1. Copy s6-overlay directory to rootfs:
   ```bash
   cp -r v3_example/s6-overlay rootfs/etc/
   ```

2. Build and run your add-on

3. Check service status inside container:
   ```bash
   s6-rc -a list
   s6-svstat /run/service/example-service
   ```

## Migration from v2 to v3

To migrate existing v2 services:

1. **Initialization scripts** (`cont-init.d/`) → oneshot services
   - Create `service-name-init/` directory
   - Add `type` file with "oneshot"
   - Add `up` file pointing to your script
   - Add to `user/contents.d/`

2. **Longrun services** (`services.d/`) → longrun services
   - Move to `s6-rc.d/service-name/`
   - Add `type` file with "longrun"
   - Keep `run` and `finish` scripts
   - Add `dependencies.d/` for dependencies
   - Add to `user/contents.d/`

## References

- [s6-overlay v3 Documentation](https://github.com/just-containers/s6-overlay)
- [s6-rc Service Manager](https://skarnet.org/software/s6-rc/)
- Main scaffold uses v2 in `rootfs/etc/services.d/`
