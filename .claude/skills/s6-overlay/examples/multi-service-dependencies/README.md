# Multi-Service Dependencies Example

Complete multi-service application demonstrating complex dependency chains with s6-rc.

## Architecture

```
PostgreSQL database
Redis cache
Application initialization (migrations)
Application worker (background jobs)
Application web server
Nginx reverse proxy
```

## Dependency Graph

```
base → postgres-init → postgres
base → redis
base + postgres + redis → app-migrations
app-migrations → app-worker
app-migrations → app-web
app-web → nginx
```

## Startup Sequence

1. **Parallel:** `postgres-init` and `redis` start together
2. `postgres` starts after `postgres-init` completes
3. `app-migrations` starts after `postgres` and `redis` are both ready
4. **Parallel:** `app-worker` and `app-web` start after migrations complete
5. `nginx` starts after `app-web` is ready

## Structure

See the complete file structure in this directory. Key points:

- Each service has explicit dependencies declared
- Independent services (postgres, redis) start in parallel
- Critical path ensures app only starts after infrastructure is ready
- Nginx waits for app-web to avoid connection refused errors

## Installation

```dockerfile
FROM ubuntu:22.04
ARG S6_OVERLAY_VERSION=3.2.2.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    postgresql \
    redis-server \
    nginx \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Copy all service definitions
COPY services/ /etc/s6-overlay/s6-rc.d/

# Make all run scripts executable
RUN find /etc/s6-overlay/s6-rc.d -name run -type f -exec chmod +x {} +

# Add all services to user bundle
RUN for service in postgres redis app-migrations app-worker-pipeline app-web-pipeline nginx; do \
      touch /etc/s6-overlay/s6-rc.d/user/contents.d/$service; \
    done

EXPOSE 80
ENTRYPOINT ["/init"]
```

## Testing

```bash
docker build -t multi-service-app .
docker run -p 80:80 multi-service-app

# Watch services start in order
docker logs -f <container-id>
```

Expected startup log:
```
s6-rc: info: service postgres-init: starting
s6-rc: info: service redis: starting
s6-rc: info: service postgres-init successfully started
s6-rc: info: service redis successfully started
s6-rc: info: service postgres: starting
s6-rc: info: service postgres successfully started
s6-rc: info: service app-migrations: starting
s6-rc: info: service app-migrations successfully started
s6-rc: info: service app-worker: starting
s6-rc: info: service app-web: starting
s6-rc: info: service app-worker successfully started
s6-rc: info: service app-web successfully started
s6-rc: info: service nginx: starting
s6-rc: info: service nginx successfully started
```

## Notes

- Parallel startup significantly faster than sequential
- Dependencies ensure correct order without manual delays
- Services automatically restarted by s6 if they crash
- Shutdown happens in reverse dependency order
