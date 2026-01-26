#!/usr/bin/with-contenv bashio

# Start Valkey in background for migrations
bashio::log.info "Starting Valkey for database migrations..."

# Ensure redis data directory exists and has correct permissions
mkdir -p /data/redis_data
chmod 755 /data/redis_data

# Start Valkey with error output
if ! valkey-server --dir /data/redis_data --daemonize yes --loglevel warning --pidfile /tmp/valkey-init.pid 2>&1 | tee /tmp/valkey-error.log; then
    bashio::log.error "Failed to start Valkey. Error log:"
    cat /tmp/valkey-error.log
    bashio::exit.nok "Valkey startup failed"
fi

# Wait for Valkey to be ready
bashio::log.info "Waiting for Valkey to be ready..."
for i in {1..30}; do
    # Try to connect to Valkey using Python (which we know is available)
    if python3 -c "import socket; s=socket.socket(); s.settimeout(1); s.connect(('127.0.0.1', 6379)); s.send(b'PING\r\n'); assert b'PONG' in s.recv(1024); s.close()" 2>/dev/null; then
        bashio::log.info "Valkey is ready after ${i} seconds"
        break
    fi

    if [ $i -eq 5 ]; then
        bashio::log.info "Still waiting for Valkey... (${i}s)"
    fi

    if [ $i -eq 30 ]; then
        bashio::log.error "Valkey failed to respond after 30 seconds"
        bashio::log.error "Checking if process is running:"
        ps aux | grep valkey || true
        bashio::log.error "Checking port 6379:"
        netstat -tlnp | grep 6379 || true
        bashio::log.error "Testing Python connection:"
        python3 -c "import socket; s=socket.socket(); s.settimeout(1); s.connect(('127.0.0.1', 6379)); s.send(b'PING\r\n'); print('Response:', s.recv(1024)); s.close()" || true
        bashio::exit.nok "Valkey failed to start after 30 seconds"
    fi
    sleep 1
done

bashio::log.info "Running database migrations..."
cd /backend || bashio::exit.nok "Failed to change to /backend directory"

if ! alembic upgrade head; then
    bashio::exit.nok "Database migrations failed"
fi

bashio::log.info "Running startup tasks..."
if ! python startup.py; then
    bashio::exit.nok "Startup tasks failed"
fi

bashio::log.info "Startup complete"
