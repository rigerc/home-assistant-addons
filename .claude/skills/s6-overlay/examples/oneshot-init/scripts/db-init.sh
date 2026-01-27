#!/bin/sh
set -e

echo "Initializing database..."

# Create database directory if needed
mkdir -p /var/lib/app/db

# Initialize database schema (example)
if [ ! -f /var/lib/app/db/database.db ]; then
    echo "Creating database schema..."
    sqlite3 /var/lib/app/db/database.db <<EOF
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    title TEXT,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
EOF
    echo "Database schema created successfully"
else
    echo "Database already exists, skipping initialization"
fi

echo "Database initialization complete"
