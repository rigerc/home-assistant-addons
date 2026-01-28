ARG BUILD_FROM
ARG BUILD_VERSION
FROM rommapp/romm:4.6.0 AS romm-base
FROM ${BUILD_FROM} AS final


# Copy Python runtime from Romm image (ensures compatibility with venv)
# This ensures we use the same Python version as the virtual environment
COPY --from=romm-base /usr/local/bin/python* /usr/local/bin/
COPY --from=romm-base /usr/local/lib/libpython* /usr/local/lib/
COPY --from=romm-base /usr/local/lib/python3.13 /usr/local/lib/python3.13

# Install runtime dependencies
# - bash: Already in HA base, but ensure it's present
# - mariadb-connector-c: MySQL/MariaDB client library
# - libpq: PostgreSQL client library
# - p7zip: 7zip archive support
# - tzdata: Timezone data
# - valkey: Redis-compatible in-memory data store (for background jobs)
# - pcre2: PCRE library for nginx regex support
# - zlib: Compression library (needed by Python and nginx)
# Python runtime dependencies:
# - libffi: Foreign Function Interface library (needed by Python ctypes)
# - libgcc: GCC runtime library (needed by Python)
# - readline: Command line editing (needed by Python)
# - sqlite-libs: SQLite database (needed by Python sqlite3 module)
# - ncurses-libs: Terminal handling (needed by Python)
# - libbz2: bzip2 compression (needed by Python)
# - xz-libs: LZMA compression (needed by Python)
RUN apk add --no-cache \
    bash \
    mariadb-connector-c \
    libpq \
    p7zip \
    tzdata \
    libmagic \
    valkey \
    pcre2 \
    gettext \
    zlib \
    libffi \
    libgcc \
    readline \
    sqlite-libs \
    ncurses-libs \
    libbz2 \
    xz-libs

# Copy Python virtual environment from Romm image
COPY --from=romm-base /src/.venv /src/.venv

# Copy backend application code
COPY --from=romm-base /backend /backend

# Copy RAHasher binary for RetroAchievements support
COPY --from=romm-base /usr/bin/RAHasher /usr/bin/RAHasher

# Copy nginx and frontend files from base image
COPY --from=romm-base /var/www/html /var/www/html
COPY --from=romm-base /etc/nginx /tmp/nginx-etc
COPY --from=romm-base /usr/lib/nginx /usr/lib/nginx
COPY --from=romm-base /usr/sbin/nginx /usr/sbin/nginx

# Move nginx config to final location and create required directories
RUN mkdir -p /run/nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /etc/nginx && \
    cp -r /tmp/nginx-etc/* /etc/nginx/ && \
    rm -rf /tmp/nginx-etc && \
    # Create nginx user/group only if they don't exist
    if ! id nginx >/dev/null 2>&1; then \
        addgroup -S nginx && \
        adduser -S -D -H -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx; \
    fi

# Create romm directory structure
RUN mkdir -p /romm /redis-data && \
    chmod 755 /romm /redis-data

# Copy rootfs (s6 service scripts)
COPY rootfs /

# Set permissions
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Set environment for Python
ENV PATH="/src/.venv/bin:${PATH}"
ENV PYTHONPATH=/backend
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /romm
EXPOSE 5999
