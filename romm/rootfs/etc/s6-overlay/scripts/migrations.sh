#!/usr/bin/with-contenv bashio

bashio::log.info "Running database migrations..."

cd /backend || bashio::exit.nok "Failed to change to /backend directory"

# Run alembic migrations
if ! alembic upgrade head; then
    bashio::exit.nok "Database migrations failed"
fi

bashio::log.info "Running startup tasks..."
if ! python startup.py; then
    bashio::exit.nok "Startup tasks failed"
fi

bashio::log.info "Migrations complete - exiting"
# Exit cleanly - s6 will mark service as "up" but not restart it
exit 0
