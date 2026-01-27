---
name: s6-overlay
description: This skill should be used when the user asks about "s6-overlay", wants to "create an s6 service", "setup service dependencies", "add s6 logging", "write init scripts", "configure s6-rc", mentions "longrun" or "oneshot" services, or is setting up multi-service Docker containers with process supervision and proper dependency management.
version: 0.1.0
---

# s6-overlay Service Management

## Purpose

Provide comprehensive guidance for using s6-overlay v3 as a Docker init system and process supervisor. This skill covers creating supervised services using the s6-rc format, establishing service dependencies, implementing logging, writing initialization and finalization scripts, and migrating from legacy formats.

## When to Use This Skill

Use this skill when:
- Creating new services in s6-overlay containers
- Setting up multi-service containers with proper dependency chains
- Adding logging to supervised services
- Writing initialization scripts that run before services start
- Configuring service finalization and cleanup
- Migrating from legacy `/etc/services.d` format to s6-rc
- Debugging service startup or dependency issues
- Configuring container exit behavior based on service status

## Core Workflow

### Step 1: Understand Service Types

s6-overlay v3 uses s6-rc service definitions. Choose the appropriate type:

**Longrun Services** - Daemons that run continuously:
- Web servers, databases, background workers
- Supervised by s6, automatically restarted on failure
- Can have optional readiness notifications

**Oneshot Services** - Tasks that run once and exit:
- Initialization tasks (database migrations, config generation)
- Setup operations (directory creation, permission fixes)
- Finalization cleanup tasks

### Step 2: Create Service Definition Directory

Create a service definition in `/etc/s6-overlay/s6-rc.d/[service-name]/`:

**Required files for longruns:**
- `type` - Contains the word "longrun"
- `run` - Executable script that starts the service

**Required files for oneshots:**
- `type` - Contains the word "oneshot"
- `up` - Single command line or path to script that executes the task

**Optional files for both:**
- `dependencies.d/[service-name]` - Empty files declaring dependencies
- `finish` - Script executed when service exits (longruns)
- `down` - Script executed when oneshot needs to stop/rollback

### Step 3: Write the Run Script

For longrun services, create an executable `/etc/s6-overlay/s6-rc.d/myapp/run` script:

```bash
#!/command/execlineb -P
# or
#!/bin/sh

# Redirect stderr to stdout for logging
exec 2>&1

# Drop privileges if needed
s6-setuidgid myuser

# Execute the service in foreground mode
exec myapp --foreground
```

**Critical requirements:**
- Must run the process in the foreground (no daemon mode)
- Should redirect stderr to stdout with `exec 2>&1` for logging
- Should drop privileges using `s6-setuidgid` when appropriate
- Must be executable (`chmod +x`)

### Step 4: Declare Dependencies

Create dependency files to control startup order. Each dependency is an empty file in `dependencies.d/`:

```bash
# Make myapp depend on base (always recommended)
touch /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/base

# Make myapp depend on database service
touch /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/postgres

# Make myapp depend on initialization
touch /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/myapp-init
```

Dependencies ensure services start in the correct order:
- Always depend on `base` to ensure system is ready
- Depend on other services that must be running first
- Dependencies are automatically stopped in reverse order

### Step 5: Add Service to User Bundle

Register the service with the `user` bundle so it starts at container boot:

```bash
# Add empty file to user bundle
touch /etc/s6-overlay/s6-rc.d/user/contents.d/myapp
```

Services in the `user` bundle start automatically when the container boots. Services not in a bundle won't start automatically.

### Step 6: Implement Logging

Create a logger service as a companion to your main service:

**1. Create log preparation oneshot:**

`/etc/s6-overlay/s6-rc.d/myapp-log-prepare/type`:
```
oneshot
```

`/etc/s6-overlay/s6-rc.d/myapp-log-prepare/up`:
```
if { mkdir -p /var/log/myapp }
if { chown nobody:nogroup /var/log/myapp }
chmod 02755 /var/log/myapp
```

**2. Create logger longrun:**

`/etc/s6-overlay/s6-rc.d/myapp-log/type`:
```
longrun
```

`/etc/s6-overlay/s6-rc.d/myapp-log/run`:
```bash
#!/bin/sh
exec logutil-service /var/log/myapp
```

**3. Link producer and consumer:**

`/etc/s6-overlay/s6-rc.d/myapp/producer-for`:
```
myapp-log
```

`/etc/s6-overlay/s6-rc.d/myapp-log/consumer-for`:
```
myapp
```

**4. Name the pipeline:**

`/etc/s6-overlay/s6-rc.d/myapp-log/pipeline-name`:
```
myapp-pipeline
```

**5. Add logger dependency and bundle:**

```bash
touch /etc/s6-overlay/s6-rc.d/myapp-log/dependencies.d/myapp-log-prepare
touch /etc/s6-overlay/s6-rc.d/user/contents.d/myapp-pipeline
```

This creates: `myapp-log-prepare` (oneshot) → `myapp | myapp-log` (pipeline)

### Step 7: Write Initialization Scripts

Create oneshot services for initialization tasks that must run before your main services:

`/etc/s6-overlay/s6-rc.d/myapp-init/type`:
```
oneshot
```

`/etc/s6-overlay/s6-rc.d/myapp-init/up`:
```
/etc/s6-overlay/scripts/myapp-init.sh
```

`/etc/s6-overlay/scripts/myapp-init.sh`:
```bash
#!/bin/sh -e
# Executable script with initialization logic
echo "Running database migrations..."
myapp migrate
echo "Generating configuration..."
myapp config generate
```

Make the script executable and declare dependencies:
```bash
chmod +x /etc/s6-overlay/scripts/myapp-init.sh
touch /etc/s6-overlay/s6-rc.d/myapp-init/dependencies.d/base
touch /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/myapp-init
touch /etc/s6-overlay/s6-rc.d/user/contents.d/myapp-init
```

### Step 8: Handle Service Exit Behavior

Create a finish script to control container exit code when services fail:

`/etc/s6-overlay/s6-rc.d/myapp/finish`:
```bash
#!/bin/sh

# $1 = exit code (256 if killed by signal)
# $2 = signal number (if killed by signal)

if test "$1" -eq 256 ; then
  # Service killed by signal
  e=$((128 + $2))
else
  # Service exited with code
  e="$1"
fi

# Write exit code for container
echo "$e" > /run/s6-linux-init-container-results/exitcode

# Optional: Halt the container
# /run/s6/basedir/bin/halt
```

This allows the container to exit with the service's exit code, enabling proper error reporting in orchestration systems.

### Step 9: Organize Multi-Service Architecture

For complex multi-service containers, organize services into logical groups:

**Example structure:**
```
/etc/s6-overlay/s6-rc.d/
├── database/               # Database service
│   ├── type (longrun)
│   ├── run
│   └── dependencies.d/
│       └── base
├── cache/                  # Cache service
│   ├── type (longrun)
│   ├── run
│   └── dependencies.d/
│       └── base
├── app-init/               # App initialization
│   ├── type (oneshot)
│   ├── up
│   └── dependencies.d/
│       ├── base
│       ├── database
│       └── cache
├── app/                    # Main application
│   ├── type (longrun)
│   ├── run
│   ├── finish
│   └── dependencies.d/
│       ├── base
│       └── app-init
└── user/
    └── contents.d/
        ├── database
        ├── cache
        ├── app-init
        └── app-pipeline
```

This ensures proper startup order: base → database & cache → app-init → app

## Additional Resources

### Reference Files

For detailed information, consult:
- **`references/service-patterns.md`** - Comprehensive patterns for common service types (web servers, databases, workers, cron jobs)
- **`references/migration-guide.md`** - Step-by-step guide for migrating from legacy `/etc/services.d` and `/etc/cont-init.d` formats
- **`references/environment-variables.md`** - Complete reference for all `S6_*` environment variables and customization options
- **`references/troubleshooting.md`** - Common issues, debugging techniques, and solutions

### Example Files

Working examples in `examples/`:
- **`examples/basic-longrun/`** - Simple web server service
- **`examples/longrun-with-logging/`** - Service with full logging pipeline
- **`examples/oneshot-init/`** - Initialization oneshot service
- **`examples/multi-service-dependencies/`** - Complex multi-service setup with proper dependency chains
- **`examples/legacy-migration/`** - Before/after migration examples

### Scripts

Utility scripts in `scripts/`:
- **`scripts/validate-service.sh`** - Validate service definition structure and files
- **`scripts/generate-service-template.sh`** - Generate boilerplate service definitions

## Quick Reference

### Service Startup Sequence

1. Stage 1: Container setup (automatic)
2. Stage 2: Service initialization
   - Attribute fixing (`/etc/fix-attrs.d`) - deprecated
   - Legacy init scripts (`/etc/cont-init.d`) - legacy
   - s6-rc oneshot services (recommended)
   - Legacy longrun services (`/etc/services.d`) - legacy
   - s6-rc longrun services (recommended)
3. CMD execution (if defined)

### Service Shutdown Sequence

1. CMD stopped (if running)
2. s6-rc longruns stopped (reverse dependency order)
3. s6-rc oneshot `down` scripts executed
4. Legacy longrun services stopped
5. Legacy finalization scripts (`/etc/cont-finish.d`)
6. Remaining processes killed

### Essential Commands

Inside running container:
- `/run/s6/basedir/bin/halt` - Stop the container gracefully
- `s6-rc -a list` - List all services
- `s6-rc -u change <service>` - Bring service up
- `s6-rc -d change <service>` - Bring service down
- `s6-svstat /run/service/<service>` - Check service status

### Common Patterns

**Basic longrun:**
```
myapp/
├── type (contains: longrun)
├── run (executable script)
└── dependencies.d/
    └── base
```

**Longrun with logging:**
```
myapp-pipeline/
├── myapp/
│   ├── type (longrun)
│   ├── run
│   ├── producer-for (contains: myapp-log)
│   └── dependencies.d/base
└── myapp-log/
    ├── type (longrun)
    ├── run (exec logutil-service /var/log/myapp)
    ├── consumer-for (contains: myapp)
    └── pipeline-name (contains: myapp-pipeline)
```

**Initialization oneshot:**
```
myapp-init/
├── type (contains: oneshot)
├── up (script or command line)
└── dependencies.d/
    └── base
```

## Integration with Dockerfile

Add s6-overlay to your Dockerfile:

```dockerfile
FROM ubuntu:22.04
ARG S6_OVERLAY_VERSION=3.2.2.0

# Install dependencies
RUN apt-get update && apt-get install -y xz-utils

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz

# Copy service definitions
COPY s6-rc.d/ /etc/s6-overlay/s6-rc.d/

# Set entrypoint
ENTRYPOINT ["/init"]

# Optional CMD
CMD ["/usr/bin/myapp"]
```

Build the image and run with proper configuration through environment variables as needed.
