# Oneshot Initialization Service Example

Demonstrates using oneshot services for initialization tasks before starting main services.

## Use Case

Run database migrations and prepare the application environment before starting the web server.

## Structure

```
db-init/                  # Initialize database (oneshot)
├── type
├── up
└── dependencies.d/base

app-migrations/           # Run migrations (oneshot)
├── type
├── up
└── dependencies.d/
    ├── base
    └── db-init

app/                      # Main web server (longrun)
├── type
├── run
└── dependencies.d/
    ├── base
    └── app-migrations
```

## Dependency Flow

```
base → db-init → app-migrations → app
```

## Installation

```dockerfile
FROM python:3.11-slim
ARG S6_OVERLAY_VERSION=3.2.2.0

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x6_64.tar.xz

# Copy initialization scripts
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Copy service definitions
COPY db-init/ /etc/s6-overlay/s6-rc.d/db-init/
COPY app-migrations/ /etc/s6-overlay/s6-rc.d/app-migrations/
COPY app/ /etc/s6-overlay/s6-rc.d/app/

# Make run scripts executable
RUN chmod +x /etc/s6-overlay/s6-rc.d/app/run

# Add to user bundle
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/db-init \
    /etc/s6-overlay/s6-rc.d/user/contents.d/app-migrations \
    /etc/s6-overlay/s6-rc.d/user/contents.d/app

ENTRYPOINT ["/init"]
```

## Execution Order

Container startup:
1. `db-init` runs once, initializes database
2. `app-migrations` runs once, applies schema changes
3. `app` starts and runs continuously

Container shutdown:
1. `app` stops
2. `app-migrations` down script (if exists)
3. `db-init` down script (if exists)

## Testing

```bash
docker build -t app-init-example .
docker run app-init-example

# Expected output:
# s6-rc: info: service db-init: starting
# s6-rc: info: service db-init successfully started
# s6-rc: info: service app-migrations: starting
# s6-rc: info: service app-migrations successfully started
# s6-rc: info: service app: starting
# s6-rc: info: service app successfully started
```

## Advanced: Rollback with Down Scripts

Add `down` scripts to oneshots for cleanup during shutdown:

**app-migrations/down:**
```bash
#!/bin/sh
echo "Rolling back last migration if needed..."
cd /app
python manage.py db downgrade
```

Make executable:
```bash
chmod +x /etc/s6-overlay/s6-rc.d/app-migrations/down
```

## Notes

- Oneshots without dependencies run in **parallel**
- Use dependencies to enforce order
- Oneshots with errors fail container startup (if `S6_BEHAVIOUR_IF_STAGE2_FAILS=2`)
- Down scripts run during shutdown in reverse dependency order
