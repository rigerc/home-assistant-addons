# Longrun Service with Logging Example

Complete example of a web application with full logging pipeline using s6-rc.

## Structure

```
app-log-prepare/          # Log directory setup (oneshot)
├── type
├── up
└── dependencies.d/base

app/                      # Main application (longrun)
├── type
├── run
├── producer-for
└── dependencies.d/base

app-log/                  # Logger service (longrun)
├── type
├── run
├── consumer-for
├── pipeline-name
└── dependencies.d/app-log-prepare
```

## Flow

1. `app-log-prepare` runs once to create `/var/log/app` with correct permissions
2. `app` and `app-log` start as a pipeline
3. Everything `app` writes to stdout/stderr goes to `app-log`
4. `app-log` uses `logutil-service` to write to `/var/log/app/current`
5. Logs automatically rotate when reaching size limit

## Installation

```dockerfile
FROM python:3.11-slim
ARG S6_OVERLAY_VERSION=3.2.2.0

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Copy application
COPY app.py /app/

# Copy service definitions
COPY app-log-prepare/ /etc/s6-overlay/s6-rc.d/app-log-prepare/
COPY app/ /etc/s6-overlay/s6-rc.d/app/
COPY app-log/ /etc/s6-overlay/s6-rc.d/app-log/

# Make scripts executable
RUN chmod +x /etc/s6-overlay/s6-rc.d/app/run \
    /etc/s6-overlay/s6-rc.d/app-log/run

# Add to user bundle (use pipeline name, not individual services)
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/app-pipeline

ENTRYPOINT ["/init"]
```

## Testing

```bash
docker build -t app-with-logging .
docker run --name myapp app-with-logging

# In another terminal:
# Check logs are being written
docker exec myapp tail -f /var/log/app/current

# Check log rotation
docker exec myapp ls -lh /var/log/app/
```

## Log Output

Logs in `/var/log/app/`:
```
current          - Current log file
@4000000065a1b2c31234abcd.s - Rotated log (timestamped)
@4000000065a1b3d41234abce.s - Older rotated log
```

Each line prefixed with timestamp:
```
2024-01-15_10:30:45.123456789 Starting application...
2024-01-15_10:30:45.234567890 Listening on :8000
```

## Customization

### Change log rotation size

Modify `S6_LOGGING_SCRIPT` (default rotates at 1MB):

```dockerfile
ENV S6_LOGGING_SCRIPT="n20 s5000000 T"  # Rotate at 5MB
```

### Change number of archived logs

```dockerfile
ENV S6_LOGGING_SCRIPT="n50 s1000000 T"  # Keep 50 archived files
```

### Remove timestamps

```dockerfile
ENV S6_LOGGING_SCRIPT="n20 s1000000"  # No T flag
```

## Notes

- Logger runs as `nobody:nogroup` for security
- Logs automatically rotate, no logrotate needed
- Old logs automatically deleted when limit reached
- Log directory must be writable by `nobody` user
