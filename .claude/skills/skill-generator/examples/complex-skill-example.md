# Example: Complex Skill for Database Migrations

This example shows a comprehensive skill with all resource types.

## Directory Structure

```
database-migrations/
├── SKILL.md
├── references/
│   ├── patterns.md
│   ├── sql-best-practices.md
│   └── troubleshooting.md
├── examples/
│   ├── create-table.sql
│   ├── add-column.sql
│   └── migration-config.json
└── scripts/
    ├── generate-migration.sh
    ├── validate-migration.sh
    └── rollback.sh
```

## SKILL.md Content

```yaml
---
name: database-migrations
description: This skill should be used when the user asks to "create a migration", "run migrations", "rollback database changes", "generate migration file", or mentions database schema updates. Provides systematic database migration management.
version: 0.1.0
---

# Database Migrations

This skill provides comprehensive database migration management including creation, validation, execution, and rollback.

## Purpose

Manage database schema changes safely and systematically through versioned migration files. Ensure database changes are tracked, reversible, and applied consistently across environments.

## When to Use This Skill

Use this skill when:
- Creating new database migration files
- Running pending migrations
- Rolling back database changes
- Validating migration syntax
- Managing schema versioning

## Core Workflow

### Step 1: Determine Action Type

Identify what the user wants to do:
- **Create migration** - Generate new migration file
- **Run migrations** - Apply pending migrations
- **Rollback** - Revert last migration
- **Validate** - Check migration syntax

### Step 2: Execute Appropriate Workflow

#### Creating Migrations

Use the generation script:

\`\`\`bash
./scripts/generate-migration.sh "description_of_change"
\`\`\`

This creates a timestamped migration file in `migrations/` directory.

Edit the generated file with SQL:
- **up** section - Apply changes
- **down** section - Revert changes

Consult `references/patterns.md` for common migration patterns.

#### Running Migrations

Validate before running:

\`\`\`bash
./scripts/validate-migration.sh migrations/latest.sql
\`\`\`

Then apply:

\`\`\`bash
# Apply all pending
psql -d database_name -f migrations/pending.sql

# Apply specific migration
psql -d database_name -f migrations/20260124_add_users.sql
\`\`\`

#### Rolling Back

Use the rollback script:

\`\`\`bash
./scripts/rollback.sh
\`\`\`

This runs the most recent migration's down section.

### Step 3: Verify Results

After any migration operation:
- Check database schema matches expectations
- Verify data integrity maintained
- Test application still functions
- Document any issues

## Migration File Structure

Standard format:

\`\`\`sql
-- Migration: description_here
-- Created: YYYY-MM-DD HH:MM:SS

-- UP
BEGIN;

-- SQL statements to apply changes

COMMIT;

-- DOWN
BEGIN;

-- SQL statements to revert changes

ROLLBACK;
\`\`\`

## Additional Resources

### Reference Files

For detailed guidance, consult:
- **`references/patterns.md`** - Common migration patterns (CREATE, ALTER, DROP, etc.)
- **`references/sql-best-practices.md`** - SQL syntax best practices and safety checks
- **`references/troubleshooting.md`** - Common issues and solutions

### Example Files

Working examples in `examples/`:
- **`examples/create-table.sql`** - Creating new tables
- **`examples/add-column.sql`** - Adding columns safely
- **`examples/migration-config.json`** - Configuration template

### Scripts

Utility scripts in `scripts/`:
- **`scripts/generate-migration.sh`** - Create new migration file with timestamp
- **`scripts/validate-migration.sh`** - Validate SQL syntax before running
- **`scripts/rollback.sh`** - Safely rollback last migration

## Best Practices

- Always write both up and down sections
- Test rollback before running migration
- Use transactions for atomic changes
- Validate syntax before applying
- Back up database before major changes
- Document migration purpose clearly
- Version migrations with timestamps
```

## references/patterns.md Content

```markdown
# Database Migration Patterns

Detailed patterns for common migration operations.

## Creating Tables

### Basic Table

\`\`\`sql
-- UP
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DOWN
DROP TABLE IF EXISTS users;
\`\`\`

### Table with Foreign Keys

\`\`\`sql
-- UP
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_posts_user_id ON posts(user_id);

-- DOWN
DROP INDEX IF EXISTS idx_posts_user_id;
DROP TABLE IF EXISTS posts;
\`\`\`

## Altering Tables

### Adding Columns

\`\`\`sql
-- UP
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- DOWN
ALTER TABLE users DROP COLUMN phone;
\`\`\`

### Adding Non-Nullable Columns

\`\`\`sql
-- UP
-- Add as nullable first
ALTER TABLE users ADD COLUMN status VARCHAR(20);

-- Set default value for existing rows
UPDATE users SET status = 'active' WHERE status IS NULL;

-- Make non-nullable
ALTER TABLE users ALTER COLUMN status SET NOT NULL;

-- DOWN
ALTER TABLE users DROP COLUMN status;
\`\`\`

### Renaming Columns

\`\`\`sql
-- UP
ALTER TABLE users RENAME COLUMN email TO email_address;

-- DOWN
ALTER TABLE users RENAME COLUMN email_address TO email;
\`\`\`

## Modifying Data

### Updating Values

\`\`\`sql
-- UP
UPDATE users SET status = 'verified' WHERE email_verified = true;

-- DOWN
UPDATE users SET status = NULL WHERE status = 'verified';
\`\`\`

### Migrating Data Between Tables

\`\`\`sql
-- UP
INSERT INTO new_table (field1, field2)
SELECT old_field1, old_field2 FROM old_table;

-- DOWN
DELETE FROM new_table WHERE migrated_at IS NOT NULL;
\`\`\`

## Indexes

### Creating Indexes

\`\`\`sql
-- UP
CREATE INDEX idx_users_email ON users(email);

-- DOWN
DROP INDEX IF EXISTS idx_users_email;
\`\`\`

### Unique Indexes

\`\`\`sql
-- UP
CREATE UNIQUE INDEX idx_users_username ON users(username);

-- DOWN
DROP INDEX IF EXISTS idx_users_username;
\`\`\`

## Advanced Patterns

[... 2000+ more words of detailed patterns ...]
```

## scripts/generate-migration.sh

```bash
#!/bin/bash
# Generate new migration file with timestamp

if [ -z "$1" ]; then
    echo "Usage: $0 <migration_description>"
    echo "Example: $0 add_users_table"
    exit 1
fi

DESCRIPTION=$1
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="migrations/${TIMESTAMP}_${DESCRIPTION}.sql"

mkdir -p migrations

cat > "$FILENAME" << EOF
-- Migration: ${DESCRIPTION}
-- Created: $(date '+%Y-%m-%d %H:%M:%S')

-- UP
BEGIN;

-- TODO: Add SQL statements to apply changes

COMMIT;

-- DOWN
BEGIN;

-- TODO: Add SQL statements to revert changes

ROLLBACK;
EOF

echo "Created migration: $FILENAME"
echo "Edit the file to add your SQL statements"
```

## examples/create-table.sql

```sql
-- Migration: create_users_table
-- Created: 2026-01-24 10:30:00

-- UP
BEGIN;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

COMMIT;

-- DOWN
BEGIN;

DROP INDEX IF EXISTS idx_users_username;
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;

ROLLBACK;
```

## Why This Works

**Strong triggers:**
- "create a migration"
- "run migrations"
- "rollback database changes"
- "generate migration file"
- "database schema updates"

**Progressive disclosure:**
- SKILL.md: 1,200 words (core workflow)
- references/patterns.md: 2,500+ words (detailed patterns)
- references/sql-best-practices.md: 1,800 words (safety checks)
- references/troubleshooting.md: 1,200 words (issue resolution)

**Complete resources:**
- Working scripts (generate, validate, rollback)
- Real migration examples
- Comprehensive pattern library

**Imperative form throughout:**
- "Use the generation script"
- "Validate before running"
- "Check database schema"

**Proper length:**
- SKILL.md: 1,200 words (lean core)
- Total with references: 6,700+ words (comprehensive)
