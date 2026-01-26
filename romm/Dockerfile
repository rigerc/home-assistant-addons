ARG BUILD_FROM
FROM rommapp/romm:latest AS romm-base
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
# - zlib: Compression library (needed by Python)
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
# We only need the static HTML files, not nginx itself
COPY --from=romm-base /var/www/html /var/www/html

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
EXPOSE 8099
