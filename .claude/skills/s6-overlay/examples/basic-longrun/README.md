# Basic Longrun Service Example

Simple nginx web server as an s6-rc longrun service.

## Structure

```
nginx/
├── type           - Service type (longrun)
├── run            - Main service script
└── dependencies.d/
    └── base       - Depends on base system
```

## Files

### type

```
longrun
```

### run

```bash
#!/bin/sh
# Redirect stderr to stdout for logging
exec 2>&1

# Ensure nginx runs in foreground mode
exec nginx -g "daemon off;"
```

### dependencies.d/base

Empty file - ensures base system is ready before starting nginx.

## Installation

Copy to your Dockerfile build:

```dockerfile
FROM nginx:latest
ARG S6_OVERLAY_VERSION=3.2.2.0

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Copy service definition
COPY nginx/ /etc/s6-overlay/s6-rc.d/nginx/

# Make run script executable
RUN chmod +x /etc/s6-overlay/s6-rc.d/nginx/run

# Add to user bundle
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/nginx

# Set entrypoint
ENTRYPOINT ["/init"]
```

## Testing

Build and run:

```bash
docker build -t nginx-s6 .
docker run -p 8080:80 nginx-s6
curl http://localhost:8080
```

## Notes

- Service runs as root - for production, use `s6-setuidgid nginx`
- Logs go to container stdout/stderr (visible in `docker logs`)
- Container exits when nginx exits
