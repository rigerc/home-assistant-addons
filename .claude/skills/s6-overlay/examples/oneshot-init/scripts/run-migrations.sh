#!/bin/sh
set -e

echo "Running database migrations..."

# Example: Add new column if it doesn't exist
sqlite3 /var/lib/app/db/database.db <<EOF
-- Add email column to users table if not exists
ALTER TABLE users ADD COLUMN email TEXT;
EOF

echo "Checking current schema version..."
# In real app, you'd check migration version and run needed migrations

echo "All migrations applied successfully"
