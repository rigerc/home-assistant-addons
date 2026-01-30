# Add-on Discovery Tool

The `discover.sh` script analyzes GitHub repositories or Docker images to extract information useful for creating Home Assistant add-ons.

## Features

### GitHub Repository Analysis

When analyzing a GitHub repository, the script:

1. **Fetches Repository Metadata**
   - Description, stars, primary language, license
   - Uses GitHub API (no authentication required)

2. **Clones Repository**
   - Shallow clone (depth=1) for faster analysis
   - Fallback to archive download if git unavailable

3. **Analyzes Dockerfiles**
   - Base images and OS detection (Alpine, Debian, etc.)
   - Exposed ports and volumes
   - Environment variables
   - Package installations (apk, apt, pip, npm)
   - Entrypoint and CMD
   - Architecture support detection

4. **Checks Docker Compose Files**
   - Service definitions
   - Port mappings
   - Volume mounts
   - Network configuration

5. **Extracts Documentation**
   - README.md analysis
   - Port references
   - Configuration sections

6. **Scans Configuration Files**
   - Config file patterns (*.conf, *.yaml, *.json, etc.)
   - Environment files (.env)

### Docker Image Analysis

When analyzing a Docker image, the script:

1. **Pulls Image Metadata**
   - Architecture (amd64, arm64, etc.)
   - Operating system
   - Image size

2. **Inspects Image Configuration**
   - Exposed ports
   - Environment variables
   - Volumes
   - Entrypoint and CMD
   - Working directory
   - Default user
   - Labels

3. **Checks Multi-Architecture Support**
   - Queries manifest list
   - Lists all available platforms
   - Identifies architecture variants

## Usage

```bash
# Analyze a GitHub repository
./discover.sh https://github.com/linuxserver/plex
./discover.sh github.com/user/repo

# Analyze a Docker image
./discover.sh linuxserver/plex:latest
./discover.sh ghcr.io/home-assistant/amd64-base:latest
./discover.sh docker.io/library/nginx:alpine
```

## Requirements

### Required Dependencies

- **curl** - HTTP requests to GitHub API and downloading archives
- **jq** - JSON parsing for API responses and Docker metadata

### Optional Dependencies

- **git** - Clone repositories (fallback to archive download if unavailable)
- **docker** - Required for Docker image inspection
  - Must have Docker daemon running
  - Must have permissions to pull images

## Error Handling

The script includes comprehensive error handling:

### Dependency Checks
```bash
✗ Missing required dependencies: jq
  Please install them and try again
```

### Docker Availability
```bash
⚠ docker not found - Docker image inspection will be unavailable
```

### Docker Daemon
```bash
✗ Docker daemon is not running
  Please start Docker and try again
```

### Network Errors
```bash
✗ Failed to fetch repository metadata
✗ Failed to clone repository
✗ Failed to pull image
```

## Output Format

The script outputs structured information in sections:

### Repository Analysis Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GitHub Repository: user/repo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Description:  A cool application
Stars:        1234
Language:     Python
License:      MIT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dockerfile Analysis: Dockerfile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Base Images:
  - alpine:3.18
    OS: Alpine Linux

Exposed Ports:
  - 8080

Volumes:
  - /config
  - /data

Environment Variables:
  - TZ=UTC
  - PORT=8080

Package Installations:
  Alpine (apk): python3 py3-pip bash curl
  Python (pip): flask gunicorn

Entrypoint:
  ENTRYPOINT ["/init"]

CMD:
  CMD ["python", "app.py"]

Architecture Support:
  ✓ Multi-architecture support detected (BuildKit TARGETARCH)
  Supports: likely amd64, aarch64, armv7, etc.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recommendations for Home Assistant Add-on
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Configuration (config.yaml):
  - Set appropriate arch: (amd64, aarch64, armv7, armhf, i386)
  - Define ports and ports_description based on exposed ports
  - Consider using ingress: true for web interfaces
  - Add map: entries for volumes (share, config, etc.)
  ...
```

### Docker Image Analysis Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker Image: linuxserver/plex:latest
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Architecture:
  amd64

Operating System:
  linux

Exposed Ports:
  - 32400/tcp
  - 3005/tcp
  - 8324/tcp

Environment Variables:
  - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  - PLEX_DOWNLOAD=auto
  - VERSION=docker

Volumes:
  - /config
  - /transcode

Entrypoint:
  /init

Working Directory:
  /

User:
  abc

Image Size:
  512 MB

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Multi-Architecture Support
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Multi-architecture image detected

Available Platforms:
  - linux/amd64
  - linux/arm64
  - linux/arm/v7
```

## Using Discovery Results

After running the discovery script, use the extracted information to configure your add-on:

### 1. Update config.yaml

```yaml
# Set architectures based on discovery
arch:
  - amd64
  - aarch64

# Add discovered ports
ports:
  8080/tcp: 8080
ports_description:
  8080/tcp: Web interface

# Map discovered volumes
map:
  - config:rw
  - share:rw
```

### 2. Update Dockerfile

```dockerfile
# Use discovered base image or Home Assistant base
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base-python:3.11

# Install discovered packages
RUN apk add --no-cache python3 py3-pip bash curl

# Copy discovered configuration paths
COPY rootfs /
```

### 3. Configure Services

Use discovered entrypoint and CMD in your service definition:

```bash
# rootfs/etc/services.d/app/run
#!/usr/bin/with-contenv bashio
exec python /app/main.py
```

### 4. Add Environment Variables

Map discovered environment variables to add-on options:

```yaml
# config.yaml
options:
  tz: "UTC"
  port: 8080

schema:
  tz: str
  port: "int(1024,65535)"
```

## Limitations

### GitHub Repositories

- Only analyzes files in the repository root and subdirectories
- Cannot execute build scripts or complex build logic
- Architecture detection is heuristic-based
- Some Dockerfiles with advanced features may not be fully parsed

### Docker Images

- Requires Docker to be installed and running
- Pulls entire image (can be large)
- Cannot inspect layers for detailed package information
- Private images require authentication (not supported)

## Tips

1. **Start with Discovery**: Always run discovery before creating an add-on to understand the application's requirements

2. **Verify Information**: Discovery output is a starting point - verify ports, volumes, and dependencies

3. **Check Documentation**: Review the application's README for additional configuration options not in the Dockerfile

4. **Test Locally**: After configuring your add-on, test it locally before publishing

5. **Compare with Similar Add-ons**: Look at existing Home Assistant add-ons for similar applications for patterns and best practices

## Troubleshooting

### "Failed to fetch repository metadata"
- Check internet connection
- Verify GitHub URL is correct
- Check if repository is public (private repos not supported)

### "Docker daemon is not running"
- Start Docker: `sudo systemctl start docker`
- Check Docker status: `docker info`

### "Failed to pull image"
- Verify image name is correct
- Check internet connection
- For private images, authenticate: `docker login`

### "No Dockerfile found"
- Some repositories don't include Dockerfiles
- Check if the application uses a different build method
- Look for Containerfile or other build definitions

## Examples

### Example 1: LinuxServer Plex

```bash
./discover.sh https://github.com/linuxserver/docker-plex

# Output shows:
# - Alpine base
# - Multiple ports (32400, 3005, etc.)
# - /config and /transcode volumes
# - s6-overlay usage
# - Multi-arch support

# Use this to configure:
# - arch: [amd64, aarch64, armv7]
# - ports for Plex server
# - map: share and config directories
```

### Example 2: Docker Hub Image

```bash
./discover.sh nginx:alpine

# Output shows:
# - Alpine Linux
# - Port 80/tcp
# - /var/cache/nginx volume
# - nginx entrypoint

# Use this to configure:
# - Alpine-based Dockerfile
# - Port 80 mapping
# - Nginx configuration setup
```

## See Also

- [Scaffold README](SCAFFOLD_README.md) - Complete scaffold documentation
- [s6-overlay v2 Guide](rootfs/README.md) - Service management
- [Home Assistant Add-on Docs](https://developers.home-assistant.io/docs/add-ons)
