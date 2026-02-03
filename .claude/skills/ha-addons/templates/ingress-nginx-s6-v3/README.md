# Ingress + Nginx + s6-overlay v3 Template

Home Assistant add-on template with ingress, nginx reverse proxy, and proper s6-overlay v3 lifecycle management.

## Template Structure

```
ingress-nginx-s6-v3/
├── config.yaml              # Add-on configuration
├── Dockerfile               # Container build instructions (includes HEALTHCHECK)
├── build.yaml               # Multi-arch build configuration
├── DOCS.md                  # User-facing documentation
├── translations/
│   └── en.yaml              # UI translations
└── rootfs/                  # Files copied to container
    ├── etc/
    │   ├── cont-init.d/     # Initialization scripts (oneshot)
    │   │   ├── 10-banner.sh
    │   │   ├── 20-nginx.sh  # Configure nginx with dynamic ingress_port/interface
    │   │   └── 30-app.sh    # Configure application
    │   ├── nginx/
    │   │   ├── nginx.conf
    │   │   ├── includes/
    │   │   │   ├── proxy_params.conf
    │   │   │   ├── resolver.conf
    │   │   │   ├── server_params.conf
    │   │   │   └── mime.types
    │   │   └── servers/
    │   │       ├── ingress.conf       # Ingress proxy (dynamic port/interface)
    │   │       ├── direct.disabled     # Direct port (non-SSL)
    │   │       └── direct-ssl.disabled # Direct port (SSL)
    │   └── services.d/      # Supervised services (longruns)
    │       ├── nginx/
    │       │   ├── run              # Start nginx (waits for app backend)
    │       │   └── finish           # Handle nginx exit
    │       └── app/
    │           ├── run              # Start app (sets BASE_URL for ingress)
    │           └── finish           # Handle app exit
    └── usr/
        └── local/
            └── bin/
                └── myapp            # Application binary
```

## Key Features

### Ingress Configuration

- **ingress_port (8099)**: Port nginx listens on for ingress traffic from Home Assistant
- **backend_port (8080)**: Internal port the application listens on
- **Dynamic configuration**: `%%interface%%` and `%%port%%` replaced at runtime by `20-nginx.sh`

### Health Check

Uses Docker's native `HEALTHCHECK` directive:
- Checks nginx `/health` endpoint every 30 seconds
- 30 second startup grace period
- 3 retries before marking unhealthy

### BASE_URL for Ingress

When ingress is enabled, `BASE_URL` environment variable is set via `bashio::addon.ingress_entry`:
- Allows application to generate correct URLs for links, redirects, and API calls
- Automatically handles Home Assistant's ingress routing path
- Example: `/api/hassio_ingress/XXXXXXX/...`

### s6-overlay v3 Lifecycle

#### Stage 1: System Setup
- Black magic handled by s6-overlay
- /run preparation
- Basic initialization

#### Stage 2: Service Initialization
1. **cont-init.d scripts run sequentially** (10-*, 20-*, 30-*)
   - Create directories
   - Generate configuration files
   - **Setup nginx with dynamic ingress configuration**
   - Validate configuration
2. **services.d services start in parallel**
   - nginx service starts (after waiting for app backend)
   - app service starts (with BASE_URL set)
   - Both are supervised

#### Stage 3: Shutdown
1. Services receive TERM signal
2. Grace period for cleanup
3. KILL signal if needed
4. Container exits

## Port Architecture

```
Home Assistant UI
       │
       ▼
┌─────────────────────────────────────────────┐
│  Ingress (ingress_port: 8099)               │
│  ┌─────────────────────────────────────┐   │
│  │  nginx (%%interface%%:%%port%%)     │   │
│  │  Listens on dynamic ingress port    │   │
│  └──────────────────┬──────────────────┘   │
│                     │                       │
│                     ▼                       │
│  ┌─────────────────────────────────────┐   │
│  │  Backend Application (8080)         │   │
│  │  App listens on fixed internal port │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘

Optional Direct Access:
┌─────────────────────────────────────────────┐
│  Port 8080/tcp                              │
│  ┌─────────────────────────────────────┐   │
│  │  nginx (listen 8080)                │   │
│  │  Proxy to Backend (8080)            │   │
│  └──────────────────┬──────────────────┘   │
│                     │                       │
│                     ▼                       │
│  ┌─────────────────────────────────────┐   │
│  │  Backend Application (8080)         │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Configuration Options

### config.yaml

```yaml
ingress: true              # Enable ingress (embedded in HA UI)
ingress_port: 8099         # Port nginx listens on for ingress
startup: services          # Start as service (not application)

# Optional direct access
ports:
  8080/tcp: 8080          # Direct port access
```

### Dynamic Variable Replacement

In `20-nginx.sh`:
```bash
ingress_port=$(bashio::addon.ingress_port)  # Gets actual port from HA
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
```

In `ingress.conf`:
```nginx
listen %%interface%%:%%port%% default_server;
```

## Usage

1. Copy template to new add-on directory
2. Update `slug` in config.yaml to your add-on name
3. Update `ingress_port` if you need a different internal port
4. Change backend port (8080) if your app uses a different port
5. Modify nginx configuration for your application's needs
6. Update application run script with your actual command
7. Build and test

## Customization Checklist

- [ ] Update `slug` in config.yaml (e.g., `my_application` → `your_addon`)
- [ ] Update `ingress_port` if different from 8099
- [ ] Change backend port from 8080 if your app uses different port
- [ ] Update `panel_icon` and `panel_title` for HA sidebar
- [ ] Modify application command in `services.d/app/run`
- [ ] Update HEALTHCHECK port in Dockerfile if changing ingress_port
- [ ] Add your application binary or install instructions in Dockerfile

## Differences from s6-overlay v2

- **No watchdog**: Use Docker's `HEALTHCHECK` directive instead
- **No /etc/fix-attrs.d**: Use static permissions in Dockerfile or cont-init.d
- **No /etc/cont-finish.d**: Use finish scripts in services.d/
- **Dynamic ingress configuration**: Port/interface replaced at runtime
- **BASE_URL support**: Application gets ingress path for correct URL generation
- **Improved logging**: Better integration with container logs
- **Faster startup**: Parallel service initialization where possible

## Common Patterns

See individual files for detailed examples and comments.
