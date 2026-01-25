# Complete Configuration Reference

Comprehensive documentation for all `config.yaml` configuration options in Home Assistant add-ons.

## Required Configuration Options

### name
**Type:** string
**Description:** The display name of the add-on shown in the UI.

**Example:**
```yaml
name: "My Awesome Add-on"
```

### version
**Type:** string
**Description:** Semantic version of the add-on. If using pre-built images (`image` option), this must match the Docker image tag.

**Example:**
```yaml
version: "1.2.3"
```

### slug
**Type:** string
**Description:** Unique identifier within the repository scope. Must be URI-friendly (lowercase, hyphens, no spaces). Used for internal DNS naming.

**Example:**
```yaml
slug: "my_awesome_addon"
```

### description
**Type:** string
**Description:** Brief description of add-on functionality, shown in the add-on store.

**Example:**
```yaml
description: >-
  "Provides awesome functionality for your Home Assistant instance"
```

### arch
**Type:** list
**Description:** List of supported CPU architectures.

**Valid values:**
- `armhf` - ARM 32-bit hard float
- `armv7` - ARM v7 32-bit
- `aarch64` - ARM 64-bit
- `amd64` - x86-64 (standard desktop/server)
- `i386` - x86 32-bit

**Example:**
```yaml
arch:
  - aarch64
  - amd64
  - armv7
```

## Optional Configuration Options

### machine
**Type:** list
**Default:** All machine types supported
**Description:** Restrict add-on to specific machine types. Use `!` prefix to negate.

**Example:**
```yaml
machine:
  - odroid-n2
  - raspberrypi4-64
  - "!generic-x86-64"
```

### url
**Type:** url
**Description:** Homepage or documentation URL for the add-on.

**Example:**
```yaml
url: "https://github.com/user/my-addon"
```

### startup
**Type:** string
**Default:** `application`
**Description:** When the add-on should start in boot sequence.

**Valid values:**
- `initialize` - Start during Home Assistant setup
- `system` - For databases and non-dependent services
- `services` - Start before Home Assistant
- `application` - Start after Home Assistant
- `once` - Run once, not as daemon

**Example:**
```yaml
startup: services
```

### webui
**Type:** string
**Description:** URL template for add-on web interface. Use placeholders for dynamic values.

**Placeholders:**
- `[HOST]` - Add-on hostname
- `[PORT:internal]` - Port number (internal port, replaced with effective port)
- `[PROTO:option_name]` - Protocol (http/https based on boolean option)

**Example:**
```yaml
webui: "http://[HOST]:[PORT:8080]/dashboard"
```

**With protocol binding:**
```yaml
webui: "[PROTO:ssl]://[HOST]:[PORT:8080]/admin"
```

### boot
**Type:** string
**Default:** `auto`
**Description:** Boot behavior control.

**Valid values:**
- `auto` - System controls auto-start
- `manual` - Only manual start, user can change
- `manual_only` - Manual only, user cannot change

**Example:**
```yaml
boot: auto
```

### ports
**Type:** dict
**Description:** Network port mappings from container to host.

**Format:** `"container-port/protocol": host-port`

Set host port to `null` to disable mapping.

**Example:**
```yaml
ports:
  8080/tcp: 8080
  8443/tcp: 8443
  53/udp: 53
  9999/tcp: null  # Disabled
```

### ports_description
**Type:** dict
**Description:** Human-readable descriptions for ports. Alternatively use translation files.

**Example:**
```yaml
ports_description:
  8080/tcp: "Web interface (not used for Ingress)"
  8443/tcp: "HTTPS interface"
```

### host_network
**Type:** bool
**Default:** `false`
**Description:** Run add-on on host network namespace.

**Security impact:** -1 point

**Example:**
```yaml
host_network: true
```

### host_ipc
**Type:** bool
**Default:** `false`
**Description:** Share IPC namespace with host.

**Example:**
```yaml
host_ipc: true
```

### host_dbus
**Type:** bool
**Default:** `false`
**Description:** Map host D-Bus service into add-on.

**Example:**
```yaml
host_dbus: true
```

### host_pid
**Type:** bool
**Default:** `false`
**Description:** Run on host PID namespace. Only works for unprotected add-ons.

**Warning:** Does not work with S6 Overlay. If needed, disable S6 by overriding `/init` or use alternate base image.

**Security impact:** -2 points

**Example:**
```yaml
host_pid: true
```

### host_uts
**Type:** bool
**Default:** `false`
**Description:** Use host UTS namespace.

**Security impact:** -1 point when combined with `privileged: SYS_ADMIN`

**Example:**
```yaml
host_uts: true
```

### devices
**Type:** list
**Description:** Device paths to map into add-on container.

**Format:** Path on host

**Example:**
```yaml
devices:
  - /dev/ttyUSB0
  - /dev/ttyACM0
  - /dev/sda1
```

### homeassistant
**Type:** string
**Description:** Minimum required Home Assistant Core version.

**Format:** Version string

**Example:**
```yaml
homeassistant: "2023.6.0"
```

### hassio_role
**Type:** string
**Default:** `default`
**Description:** Role-based access level for Supervisor API.

**Valid values:**
- `default` - Access to all `info` calls
- `homeassistant` - Access to all Home Assistant API endpoints
- `backup` - Access to all backup API endpoints
- `manager` - Extended rights for CLI add-ons
- `admin` - Full API access, can disable protection mode

**Security impact:**
- `manager`: -1 point
- `admin`: -2 points

**Example:**
```yaml
hassio_role: manager
```

### hassio_api
**Type:** bool
**Default:** `false`
**Description:** Enable access to Supervisor REST API at `http://supervisor`.

**Example:**
```yaml
hassio_api: true
```

**Note:** Some endpoints are always accessible without this flag:
- `/core/api`
- `/core/api/stream`
- `/core/websocket`
- `/addons/self/*`
- `/services*`
- `/discovery*`
- `/info`

### homeassistant_api
**Type:** bool
**Default:** `false`
**Description:** Enable access to Home Assistant REST API proxy at `http://supervisor/core/api`.

**Example:**
```yaml
homeassistant_api: true
```

### docker_api
**Type:** bool
**Default:** `false`
**Description:** Allow read-only access to Docker API. Only works for unprotected add-ons.

**Security impact:** Security set to 1 (overrides all adjustments)

**Example:**
```yaml
docker_api: true
```

### privileged
**Type:** list
**Description:** Hardware/system privilege capabilities.

**Valid values:**
- `BPF` - BPF operations
- `CHECKPOINT_RESTORE` - Checkpoint/restore
- `DAC_READ_SEARCH` - Bypass file read permission checks
- `IPC_LOCK` - Lock memory
- `NET_ADMIN` - Network administration
- `NET_RAW` - Use RAW and PACKET sockets
- `PERFMON` - Performance monitoring
- `SYS_ADMIN` - System administration
- `SYS_MODULE` - Load kernel modules
- `SYS_NICE` - Process priority management
- `SYS_PTRACE` - Trace processes
- `SYS_RAWIO` - Raw I/O operations
- `SYS_RESOURCE` - Resource limits
- `SYS_TIME` - System time modification

**Security impact:** -1 point if using `NET_ADMIN`, `SYS_ADMIN`, `SYS_RAWIO`, `SYS_PTRACE`, `SYS_MODULE`, or `DAC_READ_SEARCH`

**Example:**
```yaml
privileged:
  - NET_ADMIN
  - SYS_RAWIO
```

### full_access
**Type:** bool
**Default:** `false`
**Description:** Full hardware access (equivalent to Docker privileged mode). Only works for unprotected add-ons.

**Warning:** Do not combine with `devices`, `uart`, `usb`, or `gpio`.

**Security impact:** Security set to 1 (overrides all adjustments)

**Example:**
```yaml
full_access: true
```

### apparmor
**Type:** bool or string
**Default:** `true`
**Description:** AppArmor support control. Can be boolean or custom profile name.

**Values:**
- `true` - Use default AppArmor profile
- `false` - Disable AppArmor
- `"profile_name"` - Use custom profile (from `apparmor.txt`)

**Security impact:**
- `false`: -1 point
- custom profile: +1 point (applied after installation)

**Example:**
```yaml
apparmor: "my_addon_profile"
```

### map
**Type:** list
**Description:** Home Assistant directories to bind mount into container.

**Valid types:**
- `homeassistant_config` - Home Assistant configuration
- `addon_config` - Add-on-specific config folder
- `ssl` - SSL certificates
- `addons` - Add-ons directory
- `backup` - Backup directory
- `share` - Shared storage
- `media` - Media directory
- `all_addon_configs` - All add-on configs
- `data` - Always mapped and writable

**Properties:**
- `type` - Directory type (required)
- `read_only` - Boolean, defaults to true
- `path` - Custom mount path (optional, must be non-empty, unique, not root)

**Example:**
```yaml
map:
  - type: share
    read_only: false
  - type: ssl
  - type: homeassistant_config
    read_only: false
    path: /custom/config/path
```

### environment
**Type:** dict
**Description:** Environment variables for add-on.

**Example:**
```yaml
environment:
  LOG_LEVEL: "info"
  MAX_WORKERS: "4"
```

### audio
**Type:** bool
**Default:** `false`
**Description:** Enable internal audio system (PulseAudio).

**Note:** Install `alsa-plugins-pulse` (Alpine) or `libasound2-plugins` (Debian/Ubuntu) if application doesn't support PulseAudio natively.

**Example:**
```yaml
audio: true
```

### video
**Type:** bool
**Default:** `false`
**Description:** Enable video system, maps available video devices.

**Example:**
```yaml
video: true
```

### gpio
**Type:** bool
**Default:** `false`
**Description:** Map `/sys/class/gpio` for GPIO access.

**Note:** May need `/dev/mem` and `SYS_RAWIO` for some libraries. With AppArmor, provide custom profile or disable AppArmor.

**Example:**
```yaml
gpio: true
```

### usb
**Type:** bool
**Default:** `false`
**Description:** Map raw USB access (`/dev/bus/usb`) with plug-and-play support.

**Example:**
```yaml
usb: true
```

### uart
**Type:** bool
**Default:** `false`
**Description:** Auto-map all UART/serial devices.

**Example:**
```yaml
uart: true
```

### udev
**Type:** bool
**Default:** `false`
**Description:** Mount host udev database read-only.

**Example:**
```yaml
udev: true
```

### devicetree
**Type:** bool
**Default:** `false`
**Description:** Map `/device-tree` into add-on.

**Example:**
```yaml
devicetree: true
```

### kernel_modules
**Type:** bool
**Default:** `false`
**Description:** Map host kernel modules and config (read-only), grants `SYS_MODULE`.

**Security impact:** -1 point

**Example:**
```yaml
kernel_modules: true
```

### stdin
**Type:** bool
**Default:** `false`
**Description:** Enable STDIN access via Home Assistant API (`hassio.addon_stdin` action).

**Example:**
```yaml
stdin: true
```

### legacy
**Type:** bool
**Default:** `false`
**Description:** Enable legacy mode for images without `hass.io` labels.

**Example:**
```yaml
legacy: true
```

### options
**Type:** dict
**Description:** Default values for user-configurable options. Set to `null` or use schema to make mandatory.

**Example:**
```yaml
options:
  port: 8080
  ssl: false
  name: "default"
```

### schema
**Type:** dict or bool
**Description:** Validation schema for options. Set to `false` to disable schema validation.

**Example:**
```yaml
schema:
  port: "int(1024,65535)"
  ssl: bool
  name: str
```

### image
**Type:** string
**Description:** Pre-built container image location. Use `{arch}` placeholder for architecture.

**Example:**
```yaml
image: "ghcr.io/user/{arch}-addon-myapp"
```

**Note:** `version` must match image tag when using this option.

### codenotary
**Type:** string
**Description:** Email address for Codenotary CAS image verification.

**Security impact:** +1 point

**Example:**
```yaml
codenotary: "developer@example.com"
```

### timeout
**Type:** integer
**Default:** 10
**Description:** Seconds to wait for Docker daemon before killing container.

**Example:**
```yaml
timeout: 30
```

### tmpfs
**Type:** bool
**Default:** `false`
**Description:** Use tmpfs (memory filesystem) for `/tmp`.

**Example:**
```yaml
tmpfs: true
```

### discovery
**Type:** list
**Description:** Services provided for Home Assistant discovery.

**Example:**
```yaml
discovery:
  - mqtt
```

### services
**Type:** list
**Description:** Service dependencies and provisions.

**Format:** `service:function`

**Functions:**
- `provide` - This add-on provides the service
- `want` - This add-on can use the service
- `need` - This add-on requires the service

**Example:**
```yaml
services:
  - mqtt:want
  - mysql:need
```

### auth_api
**Type:** bool
**Default:** `false`
**Description:** Access to Home Assistant user backend for authentication.

**Security impact:** +1 point (overridden by ingress)

**Example:**
```yaml
auth_api: true
```

### ingress
**Type:** bool
**Default:** `false`
**Description:** Enable Ingress feature for web UI integration.

**Security impact:** +2 points (overrides auth_api)

**Example:**
```yaml
ingress: true
```

### ingress_port
**Type:** integer
**Default:** 8099
**Description:** Port for Ingress connections. Use `0` for host network to read port via API.

**Example:**
```yaml
ingress_port: 8099
```

### ingress_entry
**Type:** string
**Default:** `/`
**Description:** Entry point path for Ingress.

**Example:**
```yaml
ingress_entry: "/admin"
```

### ingress_stream
**Type:** bool
**Default:** `false`
**Description:** Enable streaming mode for Ingress requests.

**Example:**
```yaml
ingress_stream: true
```

### panel_icon
**Type:** string
**Default:** `mdi:puzzle`
**Description:** Material Design Icon for panel menu.

**Example:**
```yaml
panel_icon: "mdi:home-assistant"
```

### panel_title
**Type:** string
**Description:** Panel menu title (defaults to add-on name).

**Example:**
```yaml
panel_title: "My Custom Panel"
```

### panel_admin
**Type:** bool
**Default:** `true`
**Description:** Restrict panel menu to admin users only.

**Example:**
```yaml
panel_admin: false
```

### backup
**Type:** string
**Default:** `hot`
**Description:** Backup mode for add-on.

**Values:**
- `hot` - Backup while running, use pre/post commands
- `cold` - Stop add-on before backup (pre/post ignored)

**Example:**
```yaml
backup: cold
```

### backup_pre
**Type:** string
**Description:** Command to run before backup.

**Example:**
```yaml
backup_pre: "/usr/bin/mysqldump > /backup/dump.sql"
```

### backup_post
**Type:** string
**Description:** Command to run after backup.

**Example:**
```yaml
backup_post: "/usr/bin/cleanup.sh"
```

### backup_exclude
**Type:** list
**Description:** Files/paths to exclude from backups (glob patterns supported).

**Example:**
```yaml
backup_exclude:
  - "*.tmp"
  - "/data/cache/**"
```

### advanced
**Type:** bool
**Default:** `false`
**Description:** Require "Advanced" mode to be visible in store.

**Example:**
```yaml
advanced: true
```

### stage
**Type:** string
**Default:** `stable`
**Description:** Development stage flag.

**Values:**
- `stable` - Production ready
- `experimental` - Experimental features
- `deprecated` - Deprecated, may be removed

**Note:** `experimental` and `deprecated` require advanced mode to show in store.

**Example:**
```yaml
stage: experimental
```

### init
**Type:** bool
**Default:** `true`
**Description:** Enable Docker default init system.

**Note:** Set to `false` for images with own init (like S6-Overlay v3).

**Example:**
```yaml
init: false
```

### watchdog
**Type:** string
**Description:** Health monitoring URL with same placeholder support as `webui`.

**TCP monitoring:**
```yaml
watchdog: "tcp://[HOST]:[PORT:80]"
```

**HTTP monitoring:**
```yaml
watchdog: "http://[HOST]:[PORT:8080]/health"
```

### realtime
**Type:** bool
**Default:** `false`
**Description:** Grant host schedule access and `SYS_NICE` for priority control.

**Example:**
```yaml
realtime: true
```

### journald
**Type:** bool
**Default:** `false`
**Description:** Map host system journal read-only (`/var/log/journal` or `/run/log/journal`).

**Example:**
```yaml
journald: true
```

### breaking_versions
**Type:** list
**Description:** Versions requiring manual update (even with auto-update enabled).

**Example:**
```yaml
breaking_versions:
  - "2.0.0"
  - "3.0.0"
```

### ulimits
**Type:** dict
**Description:** Resource limits (ulimits) for container.

**Format:** Plain integer or dict with `soft` and `hard` keys.

**Example:**
```yaml
ulimits:
  nofile: 524288
  nproc:
    soft: 1024
    hard: 2048
```

## Build Configuration (build.yaml)

Extended build options for multi-architecture or custom base images.

### build_from
**Type:** dict
**Description:** Custom base images per architecture.

**Example:**
```yaml
build_from:
  aarch64: "mycustom/base-aarch64:latest"
  amd64: "mycustom/base-amd64:latest"
```

### args
**Type:** dict
**Description:** Additional Docker build arguments.

**Example:**
```yaml
args:
  MY_BUILD_ARG: "value"
  VERSION: "1.2.3"
```

### labels
**Type:** dict
**Description:** Additional Docker labels.

**Example:**
```yaml
labels:
  maintainer: "user@example.com"
  org.label-schema.version: "1.0"
```

### codenotary
**Type:** dict
**Description:** Codenotary CAS configuration for signing.

**Properties:**
- `signer` - Owner signer email
- `base_image` - Verify base image (use `notary@home-assistant.io` for official images)

**Example:**
```yaml
codenotary:
  signer: "developer@example.com"
  base_image: "notary@home-assistant.io"
```
