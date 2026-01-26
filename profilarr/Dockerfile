ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install runtime dependencies
# - git: For Git version control operations
# - nodejs npm: For frontend build
# - bash: For shell scripts
# - curl: For health checks
RUN apk add --no-cache \
    git \
    nodejs \
    npm \
    bash \
    curl

# Set working directory
WORKDIR /profilarr

# Copy backend application
COPY backend/app /profilarr/app
COPY backend/requirements.txt /profilarr/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r /profilarr/requirements.txt

# Copy frontend files for build
COPY frontend/package.json frontend/package-lock.json frontend/vite.config.js /profilarr/frontend/
COPY frontend/src /profilarr/frontend/src
COPY frontend/index.html /profilarr/frontend/
COPY frontend/tailwind.config.js /profilarr/frontend/ 2>/dev/null || true
COPY frontend/postcss.config.js /profilarr/frontend/ 2>/dev/null || true

# Build frontend
RUN cd /profilarr/frontend && \
    npm install && \
    npm run build && \
    mkdir -p /profilarr/app/static && \
    cp -r dist/* /profilarr/app/static/

# Copy rootfs (s6 service scripts)
COPY rootfs /

# Set permissions for service scripts
RUN chmod a+x /etc/cont-init.d/*.sh \
    && find /etc/services.d -type f -name "run" -exec chmod +x {} \; \
    && find /etc/services.d -type f -name "finish" -exec chmod +x {} \;

# Set environment for Python
ENV PYTHONPATH=/profilarr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /profilarr
