# Ingress + Nginx + s6-overlay v3 Template

Home Assistant add-on template with ingress, nginx reverse proxy, and proper s6-overlay v3 lifecycle management.

## Template Structure

```
ingress-nginx-s6-v3/
├── config.yaml              # Add-on configuration
├── Dockerfile               # Container build instructions
├── DOCS.md                  # User-facing documentation
├── translations/
│   └── en.yaml              # UI translations
└── rootfs/                  # Files copied to container
    ├── etc/
    │   ├── cont-init.d/     # Initialization scripts (oneshot)
    │   │   ├── 10-banner.sh
    │   │   ├── 20-nginx.sh  # Configure nginx
    │   │   └── 30-app.sh    # Configure app
    │   ├── nginx/
    │   │   ├── nginx.conf
    │   │   ├── includes/
    │   │   │   ├── proxy_params.conf
    │   │   │   ├── resolver.conf
    │   │   │   └── server_params.conf
    │   │   └── servers/
    │   │       ├── ingress.conf
    │   │       └── direct.disabled
    │   └── services.d/      # Supervised services (longruns)
    │       ├── nginx/
    │       │   ├── run
    │       │   └── finish
    │       └── app/
    │           ├── run
    │           └── finish
    └── usr/
        └── local/
            └── bin/
                └── myapp    # Application binary
```

## s6-overlay v3 Lifecycle

### Stage 1: System Setup
- Black magic handled by s6-overlay
- /run preparation
- Basic initialization

### Stage 2: Service Initialization
1. **cont-init.d scripts run sequentially** (10-*, 20-*, 30-*)
   - Create directories
   - Generate configuration files
   - Setup nginx
   - Validate configuration
2. **services.d services start in parallel**
   - nginx service starts
   - app service starts
   - Both are supervised

### Stage 3: Shutdown
1. Services receive TERM signal
2. Grace period for cleanup
3. KILL signal if needed
4. Container exits

## Key Files

### config.yaml

Defines ingress configuration:
```yaml
ingress: true
ingress_port: 8099
ports:
  8080/tcp: 8080
```

### nginx.conf

Main nginx configuration that:
- Runs in foreground (required by s6)
- Logs to stdout/stderr
- Includes server configs

### nginx/servers/ingress.conf

Ingress configuration with:
- Listen on ingress interface/port
- Proxy to backend application
- WebSocket support
- Security headers

### services.d/nginx/run

Starts nginx in foreground:
```bash
#!/usr/bin/with-contenv bashio
exec 2>&1
exec nginx
```

### services.d/nginx/finish

Handles nginx failures - halts container on crash.

### services.d/app/run

Starts your application in foreground.

### services.d/app/finish

Handles app failures - halts container on crash.

## Usage

1. Copy template to new add-on directory
2. Rename `myapp` to your application name
3. Update config.yaml with your settings
4. Modify nginx configuration for your application
5. Update application run script
6. Build and test

## Differences from s6-overlay v2

- **No /etc/fix-attrs.d**: Use static permissions in Dockerfile or cont-init.d
- **No /etc/cont-finish.d**: Use finish scripts in services.d/
- **Service dependencies**: Use s6-rc format in /etc/s6-overlay/s6-rc.d/ (advanced)
- **Improved logging**: Better integration with container logs
- **Faster startup**: Parallel service initialization where possible

## Common Patterns

See individual files for detailed examples and comments.
