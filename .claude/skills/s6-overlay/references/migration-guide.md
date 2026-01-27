# Migration Guide: Legacy to s6-rc Format

Complete guide for migrating from s6-overlay v2 legacy formats (`/etc/services.d`, `/etc/cont-init.d`, `/etc/cont-finish.d`) to the modern s6-rc format in s6-overlay v3.

## Why Migrate to s6-rc?

**Advantages of s6-rc format:**

1. **Proper dependency management** - Services start in correct order based on declared dependencies
2. **Parallel initialization** - Independent oneshots run concurrently, faster startup
3. **Better organization** - Service definitions grouped in logical directories
4. **Atomic operations** - Service graphs compiled once, consistent state
5. **Cleaner shutdown** - Services stopped in reverse dependency order
6. **More features** - Readiness notifications, bundles, pipelines

**Legacy format limitations:**

- `/etc/cont-init.d` scripts run sequentially, no parallelism
- `/etc/services.d` services start without dependency awareness
- No built-in way to ensure service readiness before starting dependents
- Harder to maintain complex multi-service setups

## Migration Overview

**Three main conversions:**

1. `/etc/cont-init.d` scripts → s6-rc oneshot services
2. `/etc/services.d` longruns → s6-rc longrun services
3. `/etc/cont-finish.d` scripts → s6-rc oneshot down scripts

**Migration strategy:**

- Start with simple services first
- Test each migration step
- Both formats can coexist during transition
- Legacy services still work in v3 (but start last)

## Migration Step-by-Step

### Step 1: Inventory Current Services

List all legacy services and scripts:

```bash
# List initialization scripts
ls -la /etc/cont-init.d/

# List services
ls -la /etc/services.d/

# List finalization scripts
ls -la /etc/cont-finish.d/
```

Document what each does and dependencies between them.

### Step 2: Identify Dependencies

Determine the startup order requirements:

**Questions to answer:**
- Which init scripts must run before others?
- Which services depend on which init scripts?
- Which services depend on other services?
- What can run in parallel?

**Example analysis:**
```
01-setup-directories -> Creates /var/lib/app, /var/log/app
02-database-init -> Initializes database (depends on 01)
03-run-migrations -> Runs migrations (depends on 02)

Services:
- postgres -> Needs 02-database-init
- app-worker -> Needs 03-run-migrations, postgres
- app-web -> Needs 03-run-migrations, postgres
- nginx -> Needs app-web
```

### Step 3: Create s6-rc Directory Structure

Create base directory for s6-rc services:

```bash
mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d
```

### Step 4: Migrate Initialization Scripts

Convert `/etc/cont-init.d` scripts to s6-rc oneshots.

#### Legacy Format

`/etc/cont-init.d/01-setup-app`:
```bash
#!/usr/bin/with-contenv bash
set -e
echo "Setting up application..."
mkdir -p /var/lib/app /var/log/app
chown app:app /var/lib/app /var/log/app
chmod 0755 /var/lib/app /var/log/app
```

#### s6-rc Format (Method 1: Inline Script)

**When script is simple enough:**

`/etc/s6-overlay/s6-rc.d/setup-app/type`:
```
oneshot
```

`/etc/s6-overlay/s6-rc.d/setup-app/dependencies.d/base`:
```
(empty file)
```

`/etc/s6-overlay/s6-rc.d/setup-app/up`:
```
if { echo "Setting up application..." }
if { mkdir -p /var/lib/app /var/log/app }
if { chown app:app /var/lib/app /var/log/app }
chmod 0755 /var/lib/app /var/log/app
```

`/etc/s6-overlay/s6-rc.d/user/contents.d/setup-app`:
```
(empty file)
```

#### s6-rc Format (Method 2: External Script)

**When script is complex:**

`/etc/s6-overlay/s6-rc.d/setup-app/type`:
```
oneshot
```

`/etc/s6-overlay/s6-rc.d/setup-app/dependencies.d/base`:
```
(empty file)
```

`/etc/s6-overlay/s6-rc.d/setup-app/up`:
```
/etc/s6-overlay/scripts/setup-app.sh
```

`/etc/s6-overlay/scripts/setup-app.sh`:
```bash
#!/usr/bin/with-contenv bash
set -e
echo "Setting up application..."
mkdir -p /var/lib/app /var/log/app
chown app:app /var/lib/app /var/log/app
chmod 0755 /var/lib/app /var/log/app
```

Make executable:
```bash
chmod +x /etc/s6-overlay/scripts/setup-app.sh
```

`/etc/s6-overlay/s6-rc.d/user/contents.d/setup-app`:
```
(empty file)
```

#### Migration Checklist for Init Scripts

For each `/etc/cont-init.d/XX-name` script:

- [ ] Create `/etc/s6-overlay/s6-rc.d/name/` directory
- [ ] Create `type` file containing "oneshot"
- [ ] Create `up` file (inline or pointing to script)
- [ ] Make `up` executable if it's a script: `chmod +x`
- [ ] Create `dependencies.d/base` (always)
- [ ] Add dependencies on other oneshots if needed
- [ ] Add to user bundle: `touch user/contents.d/name`
- [ ] Test the service independently
- [ ] Remove or comment out legacy script

### Step 5: Migrate Longrun Services

Convert `/etc/services.d` services to s6-rc longruns.

#### Legacy Format

`/etc/services.d/app/run`:
```bash
#!/usr/bin/with-contenv bash
exec 2>&1
cd /app
exec s6-setuidgid app gunicorn --bind 0.0.0.0:8000 wsgi:app
```

`/etc/services.d/app/finish`:
```bash
#!/command/execlineb -S1
if { eltest ${1} -ne 0 -a ${1} -ne 256 }
/run/s6/basedir/bin/halt
```

#### s6-rc Format

`/etc/s6-overlay/s6-rc.d/app/type`:
```
longrun
```

`/etc/s6-overlay/s6-rc.d/app/dependencies.d/base`:
```
(empty file)
```

`/etc/s6-overlay/s6-rc.d/app/run`:
```bash
#!/usr/bin/with-contenv bash
exec 2>&1
cd /app
exec s6-setuidgid app gunicorn --bind 0.0.0.0:8000 wsgi:app
```

`/etc/s6-overlay/s6-rc.d/app/finish`:
```bash
#!/bin/sh
if test "$1" -ne 0 -a "$1" -ne 256 ; then
  echo "$1" > /run/s6-linux-init-container-results/exitcode
  /run/s6/basedir/bin/halt
fi
```

`/etc/s6-overlay/s6-rc.d/user/contents.d/app`:
```
(empty file)
```

Make scripts executable:
```bash
chmod +x /etc/s6-overlay/s6-rc.d/app/run
chmod +x /etc/s6-overlay/s6-rc.d/app/finish
```

#### Migration Checklist for Longrun Services

For each `/etc/services.d/name/` service:

- [ ] Create `/etc/s6-overlay/s6-rc.d/name/` directory
- [ ] Create `type` file containing "longrun"
- [ ] Copy and adapt `run` script
- [ ] Make `run` executable: `chmod +x`
- [ ] Copy and adapt `finish` script if exists
- [ ] Make `finish` executable if exists: `chmod +x`
- [ ] Create `dependencies.d/base` (always)
- [ ] Add dependencies on oneshots/other services
- [ ] Add to user bundle: `touch user/contents.d/name`
- [ ] Test the service
- [ ] Remove or rename legacy service directory

### Step 6: Add Dependencies

Define dependencies based on analysis from Step 2.

**Example dependency structure:**

```bash
# App service depends on database initialization
touch /etc/s6-overlay/s6-rc.d/app/dependencies.d/database-init

# App service depends on postgres service
touch /etc/s6-overlay/s6-rc.d/app/dependencies.d/postgres

# Nginx depends on app service
touch /etc/s6-overlay/s6-rc.d/nginx/dependencies.d/app
```

**Dependency rules:**

- All services should depend on `base`
- Longruns should depend on oneshots that prepare their environment
- Services should depend on services they communicate with
- Avoid circular dependencies

### Step 7: Migrate Service Logging

Convert service loggers to pipeline format.

#### Legacy Format

`/etc/services.d/app/log/run`:
```bash
#!/bin/sh
exec logutil-service /var/log/app
```

#### s6-rc Format

Create log preparation, logger service, and pipeline:

`/etc/s6-overlay/s6-rc.d/app-log-prepare/type`:
```
oneshot
```

`/etc/s6-overlay/s6-rc.d/app-log-prepare/up`:
```
if { mkdir -p /var/log/app }
if { chown nobody:nogroup /var/log/app }
chmod 02755 /var/log/app
```

`/etc/s6-overlay/s6-rc.d/app-log-prepare/dependencies.d/base`:
```
(empty file)
```

`/etc/s6-overlay/s6-rc.d/app-log/type`:
```
longrun
```

`/etc/s6-overlay/s6-rc.d/app-log/run`:
```bash
#!/bin/sh
exec logutil-service /var/log/app
```

`/etc/s6-overlay/s6-rc.d/app-log/dependencies.d/app-log-prepare`:
```
(empty file)
```

`/etc/s6-overlay/s6-rc.d/app-log/consumer-for`:
```
app
```

`/etc/s6-overlay/s6-rc.d/app/producer-for`:
```
app-log
```

`/etc/s6-overlay/s6-rc.d/app-log/pipeline-name`:
```
app-pipeline
```

Update user bundle to reference pipeline instead of service:

```bash
# Remove app from user bundle if it was there
rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/app

# Add pipeline to user bundle
touch /etc/s6-overlay/s6-rc.d/user/contents.d/app-pipeline
```

Make run script executable:
```bash
chmod +x /etc/s6-overlay/s6-rc.d/app-log/run
```

### Step 8: Migrate Finalization Scripts

Convert `/etc/cont-finish.d` scripts to s6-rc oneshot down scripts.

#### Legacy Format

`/etc/cont-finish.d/01-cleanup`:
```bash
#!/usr/bin/with-contenv bash
echo "Cleaning up temporary files..."
rm -rf /tmp/app-*
```

#### s6-rc Format

**Option 1: Create dedicated oneshot service**

`/etc/s6-overlay/s6-rc.d/cleanup/type`:
```
oneshot
```

`/etc/s6-overlay/s6-rc.d/cleanup/down`:
```
foreground { echo "Cleaning up temporary files..." }
rm -rf /tmp/app-*
```

`/etc/s6-overlay/s6-rc.d/user/contents.d/cleanup`:
```
(empty file)
```

**Option 2: Add to existing service's down script**

If cleanup is specific to a service, add it to that service's down script:

`/etc/s6-overlay/s6-rc.d/app-init/down`:
```bash
#!/bin/sh
echo "Cleaning up app resources..."
rm -rf /tmp/app-*
```

Make executable:
```bash
chmod +x /etc/s6-overlay/s6-rc.d/app-init/down
```

## Complete Migration Example

### Before: Legacy Format

```
/etc/cont-init.d/
├── 01-setup-dirs
├── 02-init-postgres
└── 03-run-migrations

/etc/services.d/
├── postgres/
│   ├── run
│   └── log/run
└── app/
    ├── run
    ├── finish
    └── log/run

/etc/cont-finish.d/
└── 01-cleanup
```

**01-setup-dirs:**
```bash
#!/usr/bin/with-contenv bash
mkdir -p /var/lib/postgres /var/log/postgres
mkdir -p /var/lib/app /var/log/app
chown postgres:postgres /var/lib/postgres /var/log/postgres
chown app:app /var/lib/app /var/log/app
```

**02-init-postgres:**
```bash
#!/usr/bin/with-contenv bash
if [ ! -f /var/lib/postgres/PG_VERSION ]; then
  su-exec postgres initdb -D /var/lib/postgres
fi
```

**03-run-migrations:**
```bash
#!/usr/bin/with-contenv bash
cd /app
su-exec app flask db upgrade
```

**postgres/run:**
```bash
#!/usr/bin/with-contenv bash
exec 2>&1
exec s6-setuidgid postgres postgres -D /var/lib/postgres
```

**app/run:**
```bash
#!/usr/bin/with-contenv bash
exec 2>&1
cd /app
exec s6-setuidgid app gunicorn --bind 0.0.0.0:8000 wsgi:app
```

### After: s6-rc Format

```
/etc/s6-overlay/s6-rc.d/
├── setup-postgres/
│   ├── type
│   ├── up
│   └── dependencies.d/base
├── init-postgres/
│   ├── type
│   ├── up
│   └── dependencies.d/
│       ├── base
│       └── setup-postgres
├── postgres/
│   ├── type
│   ├── run
│   ├── producer-for
│   └── dependencies.d/
│       ├── base
│       └── init-postgres
├── postgres-log-prepare/
│   ├── type
│   ├── up
│   └── dependencies.d/base
├── postgres-log/
│   ├── type
│   ├── run
│   ├── consumer-for
│   ├── pipeline-name
│   └── dependencies.d/postgres-log-prepare
├── setup-app/
│   ├── type
│   ├── up
│   └── dependencies.d/base
├── run-migrations/
│   ├── type
│   ├── up
│   └── dependencies.d/
│       ├── base
│       ├── postgres
│       └── setup-app
├── app/
│   ├── type
│   ├── run
│   ├── finish
│   ├── producer-for
│   └── dependencies.d/
│       ├── base
│       └── run-migrations
├── app-log-prepare/
│   ├── type
│   ├── up
│   └── dependencies.d/base
├── app-log/
│   ├── type
│   ├── run
│   ├── consumer-for
│   ├── pipeline-name
│   └── dependencies.d/app-log-prepare
├── cleanup/
│   ├── type
│   ├── down
│   └── dependencies.d/base
└── user/
    └── contents.d/
        ├── setup-postgres
        ├── init-postgres
        ├── postgres-pipeline
        ├── setup-app
        ├── run-migrations
        ├── app-pipeline
        └── cleanup
```

**Dependency graph:**
```
base → setup-postgres → init-postgres → postgres (pipeline)
base → setup-app → run-migrations
postgres + run-migrations → app (pipeline)
```

**Benefits achieved:**
- setup-postgres and setup-app run in parallel
- postgres-log-prepare and app-log-prepare run in parallel
- Clear dependency chain ensures correct startup order
- Proper shutdown order (app stops before postgres)

## Testing Migration

### Test Individual Services

Test each migrated service independently:

```bash
# From inside container
s6-rc -u change service-name  # Start service
s6-rc -d change service-name  # Stop service
s6-svstat /run/service/service-name  # Check status
```

### Test Dependency Chain

Verify services start in correct order:

```bash
# Enable verbose logging
export S6_VERBOSITY=3

# Start container and watch logs
docker run -e S6_VERBOSITY=3 myimage
```

Look for service start messages showing correct order.

### Test Parallel Execution

Oneshots with no dependencies should run in parallel:

```bash
# Add timestamps to oneshot scripts for verification
#!/bin/sh
date "+%H:%M:%S.%N Starting setup-postgres"
# ... rest of script
```

Check logs - independent oneshots should have overlapping timestamps.

### Test Shutdown

Verify services stop in reverse dependency order:

```bash
docker stop mycontainer

# Watch logs - should see services stopping in reverse order:
# app → run-migrations → postgres → cleanup
```

## Gradual Migration Strategy

Migrate incrementally rather than all at once:

**Phase 1: Migrate simple oneshots**
- Start with `/etc/cont-init.d` scripts that have no dependencies
- Keep legacy services running
- Test new oneshots

**Phase 2: Migrate infrastructure services**
- Migrate database, cache services
- Add dependencies on Phase 1 oneshots
- Test infrastructure stack

**Phase 3: Migrate application services**
- Migrate main application services
- Add dependencies on Phase 2 services
- Test full application stack

**Phase 4: Migrate logging**
- Convert service loggers to pipelines
- Update user bundle

**Phase 5: Cleanup**
- Remove legacy scripts and services
- Remove compatibility environment variables
- Final testing

## Common Migration Issues

### Issue: Service won't start

**Symptoms:**
```
s6-rc: warning: unable to start service myapp: command exited 111
```

**Causes and solutions:**
- Run script not executable → `chmod +x run`
- Missing dependencies → Check `dependencies.d/`
- Service depends on itself → Remove circular dependency
- Wrong shebang → Use `#!/bin/sh` or `#!/command/execlineb`

### Issue: Services start in wrong order

**Symptoms:**
- App fails because database isn't ready
- Migrations fail because database doesn't exist

**Solution:**
Add missing dependencies:
```bash
touch /etc/s6-overlay/s6-rc.d/app/dependencies.d/database
touch /etc/s6-overlay/s6-rc.d/migrations/dependencies.d/database-init
```

### Issue: Logs not appearing

**Symptoms:**
- No logs in `/var/log/myapp/`
- Logger service not running

**Causes and solutions:**
- Log directory doesn't exist → Create in log-prepare oneshot
- Log directory wrong permissions → `chown nobody:nogroup`
- Pipeline not registered → Check `producer-for`, `consumer-for`, `pipeline-name`
- Pipeline not in user bundle → `touch user/contents.d/myapp-pipeline`

### Issue: Container exits immediately

**Symptoms:**
- Container starts then exits
- No error messages

**Causes and solutions:**
- All services are oneshots, no CMD → Add a longrun service or CMD
- Main service not in user bundle → `touch user/contents.d/myapp`
- Critical service has finish script that halts → Review finish script logic

### Issue: Environment variables not available

**Symptoms:**
- Scripts can't access env vars defined in Dockerfile

**Solution:**
Use `with-contenv` wrapper:
```bash
#!/command/with-contenv sh
# Now env vars are available
echo $MY_ENV_VAR
```

## Migration Validation Checklist

Before considering migration complete:

**Structure:**
- [ ] All services have `type` file
- [ ] All services have appropriate `run`/`up` files
- [ ] All run scripts are executable
- [ ] All services depend on `base`
- [ ] Dependencies match required startup order
- [ ] All services added to user bundle or pipelines

**Functionality:**
- [ ] All services start successfully
- [ ] Services start in correct order
- [ ] Independent oneshots run in parallel
- [ ] Service logs appear in expected locations
- [ ] Container responds correctly to signals
- [ ] Container exits with correct exit codes
- [ ] Services stop in reverse dependency order

**Cleanup:**
- [ ] Legacy scripts removed or disabled
- [ ] Legacy services removed or disabled
- [ ] Temporary compatibility code removed
- [ ] Documentation updated

**Testing:**
- [ ] Container starts successfully
- [ ] All functionality works as before
- [ ] Container stops gracefully
- [ ] Startup is faster than legacy (parallel oneshots)
- [ ] Logs are properly rotated

## Best Practices for Migrated Services

1. **Always depend on base** - Even if legacy scripts didn't have order dependencies
2. **One concern per service** - Split complex init scripts into multiple oneshots
3. **Use descriptive names** - `setup-database` not `01-setup`
4. **Group related services** - Use consistent naming (app, app-init, app-log)
5. **Document dependencies** - Comment why each dependency exists
6. **Test incrementally** - Migrate and test one service at a time
7. **Keep backups** - Keep legacy format until migration is proven
8. **Monitor startup times** - Verify parallel execution provides speedup
9. **Validate exit behavior** - Ensure finish scripts work correctly
10. **Update documentation** - Document new structure for team members
