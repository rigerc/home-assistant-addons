# config.yaml Reference

Complete reference for Home Assistant add-on configuration options.

## Basic Metadata

```yaml
name: "My Add-on"              # Human-readable name
version: "1.0.0"               # Semantic version
slug: "my_addon"               # Directory name, lowercase with underscores
description: "Short description"
url: "https://github.com/user/repo"  # Documentation URL
```

## Architecture Support

```yaml
arch:
  - amd64      # 64-bit x86 (most common)
  - aarch64    # 64-bit ARM (Raspberry Pi 4)
  - armv7      # 32-bit ARM (Raspberry Pi 3)
  - armhf      # 32-bit ARM hard-float
  - i386       # 32-bit x86
```

## Image Configuration

```yaml
# GitHub Container Registry (recommended)
image: "ghcr.io/{arch}/username-addon-name"

# Docker Hub
image: "docker.io/{arch}/username-addon-name"
```

The `{arch}` placeholder is replaced with the target architecture.

## Network Configuration

### Ingress (Embedded in HA UI)

```yaml
ingress: true
ingress_port: 8099              # Internal port for ingress
ingress_stream: false           # Enable for WebSocket/streaming
panel_icon: "mdi:puzzle"        # Sidebar icon
panel_title: "My Add-on"        # Sidebar title (optional)
panel_admin: false              # Require admin access
```

### Direct Ports

```yaml
ports:
  8080/tcp: 8080                # host:container
  8443/tcp: null                # Disabled by default
  1883/tcp: 1883

ports_description:
  8080/tcp: "Web interface"
  8443/tcp: "SSL web interface"
  1883/tcp: "MQTT broker"
```

### Network Modes

```yaml
host_network: false             # Use host network directly
host_pid: false                 # Share host PID namespace
host_uts: false                 # Share host UTS namespace
```

## Directory Mapping

```yaml
map:
  # Simple form (read-only by default)
  - share
  - ssl
  - media

  # Extended form with options
  - type: addon_config
    path: /config               # Custom mount path
    read_only: false            # Allow writes

  - type: media
    read_only: false

  - type: share
    path: /shared
    read_only: false
```

### Available Directory Types

| Type | Default Path | Default Access | Description |
|------|-------------|----------------|-------------|
| `data` | `/data` | read-write | Always mounted, persistent storage |
| `addon_config` | `/addon_config` | read-write | Add-on's configuration |
| `homeassistant_config` | `/homeassistant_config` | read-only | HA configuration directory |
| `ssl` | `/ssl` | read-only | SSL certificates |
| `share` | `/share` | read-only | Shared data between add-ons |
| `media` | `/media` | read-only | Media files |
| `backup` | `/backup` | read-only | HA backups |
| `addons` | `/addons` | read-only | All add-ons directory |
| `all_addon_configs` | `/all_addon_configs` | read-only | All add-on configs |

## Options and Schema

### Defining Options

```yaml
options:
  log_level: info
  port: 8080
  ssl: false
  certfile: fullchain.pem
  keyfile: privkey.pem
  items:
    - name: "Item 1"
      value: 100
```

### Schema Types

```yaml
schema:
  # Basic types
  string_option: str              # Required string
  optional_str: str?              # Optional string
  boolean_opt: bool               # true/false
  integer_opt: int                # Integer
  float_opt: float                # Floating point
  email_opt: email                # Email validation
  url_opt: url                    # URL validation
  port_opt: port                  # Port 1-65535
  password: password              # Hidden in UI

  # With constraints
  ranged_int: int(1,100)          # Integer 1-100
  ranged_float: float(0.0,1.0)    # Float 0.0-1.0
  device_path: device             # /dev/* path

  # Choices
  level: list(trace|debug|info|warning|error)

  # Lists
  string_list: [str]              # List of strings
  int_list: [int]                 # List of integers

  # Nested objects
  items:
    - name: str
      value: int

  # Match pattern
  pattern: match(^[a-z]+$)        # Regex validation
```

### Optional vs Required

```yaml
schema:
  required_field: str             # Must have value
  optional_field: str?            # Can be empty/null
  optional_list: [str?]           # List with optional items
```

## API Access

```yaml
homeassistant_api: true           # Access HA REST API
hassio_api: true                  # Access Supervisor API
hassio_role: default              # API permission level

# Roles: default, homeassistant, backup, manager, admin
```

## Hardware Access

```yaml
# USB devices
usb: true                         # USB device detection
uart: true                        # UART/serial access
gpio: true                        # GPIO pins

# Specific devices
devices:
  - /dev/ttyUSB0
  - /dev/ttyACM0
  - /dev/video0

# Audio
audio: true
audio_input: true
audio_output: true

# Video
video: true
```

## Privileges

```yaml
privileged:
  - SYS_ADMIN                     # Full admin (use sparingly)
  - NET_ADMIN                     # Network administration
  - SYS_RAWIO                     # Raw I/O
  - SYS_PTRACE                    # Process tracing
  - DAC_READ_SEARCH               # Bypass file permissions

# Run as full root (avoid if possible)
full_access: true

# AppArmor profile
apparmor: true                    # Use default profile
# apparmor: false                 # Disable AppArmor
```

## Startup Configuration

```yaml
startup: application              # When to start in boot sequence
# Options: initialize, system, services, application, once

boot: auto                        # Start on boot
# Options: auto, manual

init: false                       # Use custom init system

# Watchdog - restart on failure
watchdog: true                    # Enable watchdog
timeout: 10                       # Timeout in seconds
```

## Resource Limits

```yaml
# Memory limits
memory: 1024                      # Memory limit in MB

# Temporary filesystem
tmpfs: true                       # Mount /tmp as tmpfs
tmpfs_size: 1g                    # tmpfs size

# Kernel modules
kernel_modules: true              # Allow loading kernel modules
```

## Discovery

```yaml
# Service discovery
discovery:
  - mqtt
  - mysql

# mDNS/Avahi
mdns:
  - _myservice._tcp.local
```

## Labels and Build

```yaml
# Build labels
labels:
  io.hass.name: "My Add-on"
  io.hass.description: "Description"
  io.hass.version: "1.0.0"
  io.hass.type: "addon"
  io.hass.arch: "amd64"
```

## Complete Example

```yaml
name: "My Application"
version: "1.0.0"
slug: "my_application"
description: "A complete Home Assistant add-on"
url: "https://github.com/user/my-addon"
arch:
  - amd64
  - aarch64
image: "ghcr.io/{arch}/user-my-application"

# Startup
startup: application
boot: manual

# Network
ingress: true
ingress_port: 8099
panel_icon: "mdi:application"

# Or use ports
# ports:
#   8080/tcp: 8080

# Directories
map:
  - type: addon_config
    path: /config
  - type: media
    read_only: false
  - ssl

# API access
homeassistant_api: true
hassio_api: true
hassio_role: default

# Options
options:
  log_level: info
  port: 8080
  ssl: false
  certfile: fullchain.pem
  keyfile: privkey.pem

schema:
  log_level: list(trace|debug|info|warning|error)
  port: port
  ssl: bool
  certfile: str?
  keyfile: str?

# Watchdog
watchdog: true

# Labels
labels:
  io.hass.name: "My Application"
  io.hass.type: "addon"
```
