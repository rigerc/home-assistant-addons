# s6-overlay Environment Variables Reference

Complete reference for all environment variables that control s6-overlay behavior.

## Core Path Configuration

### PATH

**Default:** `/command:/usr/bin:/bin`

**Description:** Default PATH for all processes in the container, including services and CMD.

**Usage:**
```dockerfile
ENV PATH=/custom/bin:/command:/usr/bin:/bin
```

**Notes:**
- `/command`, `/usr/bin`, and `/bin` are always added if missing
- Set this if services need binaries in non-standard locations
- Affects all supervised services and initialization scripts

**Example:**
```dockerfile
# Add Go binaries to path
ENV PATH=/usr/local/go/bin:/command:/usr/bin:/bin
```

## Environment Handling

### S6_KEEP_ENV

**Default:** `0`

**Values:**
- `0` - Reset environment, use curated set
- `1` - Keep original environment variables

**Description:** Controls whether services see the full original environment or a cleaned subset.

**Usage:**
```dockerfile
ENV S6_KEEP_ENV=1
```

**When to use:**
- Set to `1` if services need access to all environment variables from `docker run -e`
- Set to `0` (default) for better security and isolation
- When `1`, `with-contenv` becomes a no-op (environment already available)

**Example:**
```dockerfile
# Keep all environment variables
ENV S6_KEEP_ENV=1
```

## Logging Configuration

### S6_LOGGING

**Default:** `0`

**Values:**
- `0` - All output to stdout/stderr (Docker logs)
- `1` - Use catch-all logger, CMD still goes to stdout/stderr
- `2` - Use catch-all logger for everything, nothing to stdout/stderr

**Description:** Controls where service output is sent.

**Usage:**
```dockerfile
ENV S6_LOGGING=1
```

**Mode details:**

**Mode 0 (default):**
- All service output goes to container stdout/stderr
- Visible with `docker logs`
- No persistent logs inside container
- Best for cloud environments with log aggregation

**Mode 1:**
- Service output goes to `/var/log/s6-uncaught-logs`
- CMD output still goes to stdout/stderr
- Useful when services are noisy but CMD output matters
- Logs persisted inside container

**Mode 2:**
- Everything goes to `/var/log/s6-uncaught-logs`
- Nothing to stdout/stderr
- Container runs silently
- Access logs via `docker exec` or volume mounts

**Example:**
```dockerfile
# Log services internally, show CMD output
ENV S6_LOGGING=1
```

### S6_CATCHALL_USER

**Default:** `root`

**Description:** User account for running the catch-all logger when `S6_LOGGING` is 1 or 2.

**Usage:**
```dockerfile
ENV S6_CATCHALL_USER=nobody
```

**Notes:**
- Only affects logging when `S6_LOGGING` is 1 or 2
- User must exist in `/etc/passwd`
- Running logger as non-root improves security
- Logger needs write permission to `/var/log/s6-uncaught-logs`

**Example:**
```dockerfile
# Run catch-all logger as nobody user
ENV S6_LOGGING=1
ENV S6_CATCHALL_USER=nobody
```

### S6_LOGGING_SCRIPT

**Default:** `"n20 s1000000 T"`

**Description:** Arguments passed to `s6-log` for controlling log rotation and formatting.

**Usage:**
```dockerfile
ENV S6_LOGGING_SCRIPT="n10 s5000000 T"
```

**Common directives:**
- `n<number>` - Keep this many old log files (e.g., `n20` = keep 20 files)
- `s<size>` - Rotate when current file reaches size (e.g., `s1000000` = 1MB)
- `T` - Prepend ISO8601 timestamp to each log line
- `t` - Prepend TAI64N timestamp

**Example:**
```dockerfile
# Keep 10 files, rotate at 5MB, add timestamps
ENV S6_LOGGING_SCRIPT="n10 s5000000 T"
```

**Advanced example:**
```dockerfile
# Keep 50 files, rotate at 10MB, no timestamps
ENV S6_LOGGING_SCRIPT="n50 s10000000"
```

## Behavior Configuration

### S6_BEHAVIOUR_IF_STAGE2_FAILS

**Default:** `0`

**Values:**
- `0` - Continue silently even if scripts fail
- `1` - Continue but print warning
- `2` - Stop container immediately

**Description:** Controls container behavior when initialization or service startup fails.

**Failures that trigger this:**
- Early stage2 hook exits non-zero
- `fix-attrs` fails
- `/etc/cont-init.d` script fails
- s6-rc oneshot fails
- Service fails readiness check (if `S6_CMD_WAIT_FOR_SERVICES_MAXTIME` is set)

**Usage:**
```dockerfile
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
```

**Recommendations:**
- Development: Use `2` to catch issues early
- Production: Use `1` or `2` depending on failure tolerance
- Only use `0` if failures are expected and acceptable

**Example:**
```dockerfile
# Fail fast in production
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
```

### S6_VERBOSITY

**Default:** `2`

**Values:**
- `0` - Only errors
- `1` - Warnings and errors
- `2` - Normal verbosity (service start/stop messages)
- `3` - Verbose (debug information)
- `4` - Very verbose
- `5` - Maximum verbosity

**Description:** Controls amount of logging from s6-rc and s6 tools.

**Usage:**
```dockerfile
ENV S6_VERBOSITY=1
```

**Recommendations:**
- Production: `1` or `2` (quiet operation)
- Development/debugging: `3` to `5` (detailed information)

**Example:**
```dockerfile
# Quiet operation, only show warnings/errors
ENV S6_VERBOSITY=1
```

## Timing Configuration

### S6_KILL_FINISH_MAXTIME

**Default:** `5000` (5 seconds)

**Description:** Maximum time (milliseconds) to wait for each `/etc/cont-finish.d` script before sending SIGKILL.

**Usage:**
```dockerfile
ENV S6_KILL_FINISH_MAXTIME=10000
```

**Notes:**
- Applies to legacy `/etc/cont-finish.d` scripts
- Scripts run sequentially, so total shutdown time = sum of all timeouts
- Does not apply to s6-rc oneshot `down` scripts

**Example:**
```dockerfile
# Allow 10 seconds for finalization scripts
ENV S6_KILL_FINISH_MAXTIME=10000
```

### S6_SERVICES_READYTIME

**Default:** `50` (milliseconds)

**Description:** Sleep time before testing service readiness for legacy `/etc/services.d` services.

**Usage:**
```dockerfile
ENV S6_SERVICES_READYTIME=100
```

**When to increase:**
- Getting `s6-svwait: fatal: unable to s6_svstatus_read` errors
- Running on slow/busy machines
- Services take time to create their supervision directories

**Notes:**
- Only affects `/etc/services.d` services
- s6-rc services don't need this (immune to race condition)
- Increase if seeing race condition errors

**Example:**
```dockerfile
# Slow machine, increase wait time
ENV S6_SERVICES_READYTIME=200
```

### S6_SERVICES_GRACETIME

**Default:** `3000` (3 seconds)

**Description:** Time (milliseconds) to wait for legacy `/etc/services.d` services to exit gracefully during shutdown.

**Usage:**
```dockerfile
ENV S6_SERVICES_GRACETIME=5000
```

**Notes:**
- Only affects `/etc/services.d` services
- After this time, services receive SIGKILL
- Set higher for services that need more graceful shutdown time

**Example:**
```dockerfile
# Database needs more time to shut down cleanly
ENV S6_SERVICES_GRACETIME=10000
```

### S6_KILL_GRACETIME

**Default:** `3000` (3 seconds)

**Description:** Time (milliseconds) to wait after SIGTERM before sending SIGKILL to all remaining processes.

**Usage:**
```dockerfile
ENV S6_KILL_GRACETIME=5000
```

**Notes:**
- Final step of shutdown process
- Affects all processes still running after services are stopped
- Increase for services that need more time to clean up

**Example:**
```dockerfile
# Allow 10 seconds for graceful shutdown
ENV S6_KILL_GRACETIME=10000
```

### S6_CMD_WAIT_FOR_SERVICES

**Default:** `0`

**Values:**
- `0` - Start CMD immediately after starting services
- `1` - Wait for services to be ready before starting CMD

**Description:** Controls whether container waits for service readiness before running CMD.

**Usage:**
```dockerfile
ENV S6_CMD_WAIT_FOR_SERVICES=1
```

**When to use:**
- Set to `1` when CMD depends on services being fully ready
- Services must implement readiness notifications for this to work
- Only meaningful for `/etc/services.d` services

**Example:**
```dockerfile
# Wait for services before starting CMD
ENV S6_CMD_WAIT_FOR_SERVICES=1
```

### S6_CMD_WAIT_FOR_SERVICES_MAXTIME

**Default:** `0` (infinite)

**Description:** Maximum time (milliseconds) to wait for services to become ready before failing.

**Usage:**
```dockerfile
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000
```

**Notes:**
- `0` = wait forever (default since v3.1.6.2)
- Only has effect when `S6_CMD_WAIT_FOR_SERVICES=1`
- Includes time for legacy `cont-init.d` and `services.d` setup
- If timeout occurs and `S6_BEHAVIOUR_IF_STAGE2_FAILS >= 2`, container stops

**Example:**
```dockerfile
# Fail if services not ready within 30 seconds
ENV S6_CMD_WAIT_FOR_SERVICES=1
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
```

## CMD Behavior

### S6_CMD_ARG0

**Default:** not set

**Description:** Value prepended to CMD arguments. Useful for migrating images.

**Usage:**
```dockerfile
ENV S6_CMD_ARG0=/usr/bin/oldentrypoint
```

**When to use:**
- Migrating existing images to s6-overlay
- Old ENTRYPOINT becomes S6_CMD_ARG0
- CMD arguments get prepended with this value

**Example:**
```dockerfile
# Old Dockerfile:
# ENTRYPOINT ["/app/start.sh"]
# CMD ["--config", "/etc/app.conf"]

# New Dockerfile:
ENV S6_CMD_ARG0=/app/start.sh
ENTRYPOINT ["/init"]
CMD ["--config", "/etc/app.conf"]
# Runs: /app/start.sh --config /etc/app.conf
```

### S6_CMD_USE_TERMINAL

**Default:** `0`

**Values:**
- `0` - CMD output goes to logging pipe
- `1` - CMD output goes directly to terminal

**Description:** Controls whether CMD uses a terminal for output when running interactively.

**Usage:**
```dockerfile
ENV S6_CMD_USE_TERMINAL=1
```

**When to use:**
- Running container with `docker run -it`
- CMD is interactive and needs terminal
- Using `S6_LOGGING=1` or `S6_LOGGING=2`

**Trade-off:**
- `0` - CMD output is logged (S6_LOGGING > 0) but may not work well interactively
- `1` - CMD output goes to terminal (works interactively) but isn't logged

**Example:**
```dockerfile
# Interactive shell needs terminal
ENV S6_LOGGING=1
ENV S6_CMD_USE_TERMINAL=1
```

### S6_CMD_RECEIVE_SIGNALS

**Default:** `0`

**Values:**
- `0` - Signals go to pid 1 (trigger full container shutdown)
- `1` - Signals go to CMD (only CMD receives signal)

**Description:** Controls signal routing for the container.

**Usage:**
```dockerfile
ENV S6_CMD_RECEIVE_SIGNALS=1
```

**Behavior when `0` (default):**
- `docker stop` sends SIGTERM to pid 1
- Full container shutdown sequence triggered
- CMD killed as part of shutdown
- Good for service containers

**Behavior when `1`:**
- `docker stop` sends SIGTERM to CMD
- Container shutdown only when CMD exits
- Good for batch job containers
- May break interactive CMDs

**Signals affected:**
- SIGTERM, SIGQUIT, SIGINT, SIGUSR1, SIGUSR2, SIGPWR, SIGWINCH

**Example:**
```dockerfile
# Batch job - signal goes to CMD
ENV S6_CMD_RECEIVE_SIGNALS=1
```

## Special Environments

### S6_READ_ONLY_ROOT

**Default:** `0`

**Values:**
- `0` - Normal read-write root filesystem
- `1` - Read-only root filesystem

**Description:** Informs s6-overlay that root filesystem is read-only.

**Usage:**
```dockerfile
ENV S6_READ_ONLY_ROOT=1
```

**When to use:**
- Running container with `--read-only` flag
- Security-hardened environments
- Immutable infrastructure patterns

**What it does:**
- Copies scripts from `/etc` to `/run/s6/etc`
- Uses `/run` for temporary files
- Assumes `/run` is writable (tmpfs)

**Example:**
```dockerfile
ENV S6_READ_ONLY_ROOT=1
```

```bash
docker run --read-only -e S6_READ_ONLY_ROOT=1 myimage
```

### S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES

**Default:** `0`

**Values:**
- `0` - Enforce secure `/run` permissions
- `1` - Allow world-writable `/run` (Kubernetes)

**Description:** Bypass security check for world-writable `/run`.

**Usage:**
```dockerfile
ENV S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES=1
```

**When to use:**
- **ONLY** in Kubernetes environments with enforced world-writable `/run`
- Never in normal Docker environments
- Kubernetes provides isolation through other mechanisms

**Security implications:**
- World-writable `/run` is insecure in normal environments
- Only acceptable in Kubernetes with proper pod security
- s6-overlay will print red warning even when bypassed

**Example:**
```dockerfile
# Kubernetes environment only
ENV S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES=1
```

### S6_WAIT_FOR_CLOSING_FD

**Default:** `0`

**Values:**
- `0`, `1`, `2` - No synchronization
- `3+` - File descriptor number to wait on

**Description:** Synchronize container startup with container manager using file descriptor.

**Usage:**
```dockerfile
ENV S6_WAIT_FOR_CLOSING_FD=3
```

**When to use:**
- Container manager requires FD synchronization
- Some Docker setups use fd 3
- Some systemd setups use fd 4
- Check container manager documentation

**How it works:**
- Container manager spawns container with FD open
- s6-overlay waits for EOF on that FD
- When FD closes, container manager is ready
- Container proceeds with boot

**Example:**
```dockerfile
# Wait for container manager on fd 3
ENV S6_WAIT_FOR_CLOSING_FD=3
```

## Advanced Configuration

### S6_SYNC_DISKS

**Default:** `0`

**Values:**
- `0` - Don't sync filesystems
- `1` - Sync filesystems before shutdown

**Description:** Controls whether to sync filesystems during stage 3 shutdown.

**Usage:**
```dockerfile
ENV S6_SYNC_DISKS=1
```

**Notes:**
- Syncs **all** filesystems on host (not just container)
- Use cautiously, may impact host system
- Generally not needed in containerized environments

**Example:**
```dockerfile
# Ensure filesystem sync before shutdown
ENV S6_SYNC_DISKS=1
```

### S6_STAGE2_HOOK

**Default:** not set

**Description:** Shell code executed in early stage 2, before services start.

**Usage:**
```dockerfile
ENV S6_STAGE2_HOOK='echo "Custom stage2 hook running"'
```

**When to use:**
- Dynamic service database patching at runtime
- Last-minute configuration adjustments
- Advanced use cases only

**Risks:**
- Wrong hook can prevent container from starting
- Security implications if hook is compromised
- Only use if you know exactly what you're doing

**Example:**
```dockerfile
# Dynamically add service based on environment
ENV S6_STAGE2_HOOK='/scripts/dynamic-service-setup.sh'
```

### S6_FIX_ATTRS_HIDDEN

**Default:** `0`

**Values:**
- `0` - Exclude hidden files/directories
- `1` - Process all files/directories

**Description:** Controls whether `fix-attrs` processes hidden files.

**Usage:**
```dockerfile
ENV S6_FIX_ATTRS_HIDDEN=1
```

**Notes:**
- Only affects deprecated `fix-attrs` functionality
- Not recommended for new deployments
- Use proper Dockerfile ownership instead

**Example:**
```dockerfile
# Process hidden files with fix-attrs
ENV S6_FIX_ATTRS_HIDDEN=1
```

## Common Configuration Patterns

### Development Environment

```dockerfile
# Verbose logging, fail fast
ENV S6_VERBOSITY=3
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_LOGGING=0
```

### Production Environment

```dockerfile
# Quiet operation, catch-all logging
ENV S6_VERBOSITY=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_LOGGING=1
ENV S6_CATCHALL_USER=nobody
```

### Interactive Container

```dockerfile
# Terminal support for interactive CMD
ENV S6_LOGGING=1
ENV S6_CMD_USE_TERMINAL=1
```

### Kubernetes Pod

```dockerfile
# Kubernetes-specific configuration
ENV S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES=1
ENV S6_LOGGING=0  # Use Kubernetes log collection
ENV S6_VERBOSITY=1
```

### Batch Job Container

```dockerfile
# CMD receives signals, exits determine container lifecycle
ENV S6_CMD_RECEIVE_SIGNALS=1
ENV S6_LOGGING=0
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
```

### Read-Only Container

```dockerfile
# Read-only root filesystem
ENV S6_READ_ONLY_ROOT=1
ENV S6_LOGGING=1  # Logs go to /run (tmpfs)
```

### High-Availability Service

```dockerfile
# Wait for services, fail if not ready
ENV S6_CMD_WAIT_FOR_SERVICES=1
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=60000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_VERBOSITY=1
```

## Environment Variable Priority

Order of precedence (highest to lowest):

1. Runtime: `docker run -e VAR=value`
2. Dockerfile: `ENV VAR=value`
3. s6-overlay defaults

Runtime variables always override Dockerfile and defaults.

## Debugging Environment Issues

Enable verbose output to see environment handling:

```bash
docker run -e S6_VERBOSITY=4 myimage
```

Check environment in running container:

```bash
docker exec mycontainer env
```

Test with-contenv:

```bash
docker exec mycontainer with-contenv sh -c 'env'
```
