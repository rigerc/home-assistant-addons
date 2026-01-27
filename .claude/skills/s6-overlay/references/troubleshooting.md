# s6-overlay Troubleshooting Guide

Comprehensive troubleshooting guide for common issues with s6-overlay v3.

## General Debugging Techniques

### Enable Verbose Logging

Increase verbosity to see detailed information about service lifecycle:

```dockerfile
ENV S6_VERBOSITY=3
```

Or at runtime:
```bash
docker run -e S6_VERBOSITY=3 myimage
```

Verbosity levels:
- `2` - Normal (default): service start/stop messages
- `3` - Verbose: dependency resolution, state transitions
- `4` - Very verbose: detailed execution flow
- `5` - Maximum: everything including internal operations

### Check Service Status

From inside the running container:

```bash
# List all services
s6-rc -a list

# Check specific service status
s6-svstat /run/service/myapp

# List services in a bundle
s6-rc-db -c /run/service/db contents user

# Check service dependencies
s6-rc-db -c /run/service/db dependencies myapp

# View service logs (if using pipelines)
tail -f /var/log/myapp/current
```

### Inspect Init Process

Check what stage the container is in:

```bash
# View process tree
ps auxf

# Check if s6-svscan is running (should be PID 1)
ps aux | grep s6-svscan

# Check running services
ls -la /run/service/
```

### Review Container Logs

```bash
# Docker logs show stdout/stderr
docker logs mycontainer

# Follow logs in real-time
docker logs -f mycontainer

# With timestamps
docker logs -t mycontainer
```

### Access Internal Logs

If using `S6_LOGGING=1` or `S6_LOGGING=2`:

```bash
# Access catch-all logs
docker exec mycontainer tail -f /var/log/s6-uncaught-logs/current

# Access service-specific logs
docker exec mycontainer tail -f /var/log/myapp/current
```

## Container Won't Start

### Symptom: Container exits immediately

**Check container logs:**
```bash
docker logs mycontainer
```

**Common causes:**

**1. Syntax error in service definition**

Error message:
```
/init: line X: syntax error
```

Solution:
- Check YAML/shell syntax in service files
- Verify all quoted strings are properly closed
- Check for missing `type` files

**2. Service fails during startup**

Error message:
```
s6-rc: warning: unable to start service myapp: command exited 111
```

Solution:
- Check service run script exists and is executable
- Verify dependencies exist
- Review service logs for errors
- Test run script manually

**3. Critical service has halt in finish script**

Error message:
```
s6-rc: info: service myapp successfully started
# Container exits
```

Solution:
- Review `finish` script
- Check if finish script calls `/run/s6/basedir/bin/halt`
- Remove halt call unless service failure should stop container

**4. All services are oneshots, no CMD**

Symptom: Container starts all services then exits

Solution:
- Add a CMD in Dockerfile
- Or add a longrun service that should persist
- Or use `tail -f /dev/null` as CMD for development

### Symptom: Container hangs during startup

**Check for circular dependencies:**

```bash
docker exec mycontainer s6-rc-db -c /run/service/db dependencies myapp
```

Solution:
- Review dependency chain
- Ensure no service depends on itself (directly or indirectly)
- Break circular dependencies

**Check for missing dependencies:**

Service waits forever for dependency that doesn't exist.

Solution:
- Verify all dependencies are spelled correctly
- Ensure dependency services exist in `/etc/s6-overlay/s6-rc.d/`
- Check dependency is added to user bundle

## Service Won't Start

### Error: Command exited 111

Full error:
```
s6-rc: warning: unable to start service myapp: command exited 111
```

**Cause 1: Run script not executable**

Solution:
```bash
chmod +x /etc/s6-overlay/s6-rc.d/myapp/run
```

**Cause 2: Run script has errors**

Test manually:
```bash
docker exec mycontainer /etc/s6-overlay/s6-rc.d/myapp/run
```

Check output for errors, fix script.

**Cause 3: Missing dependency**

Check if service depends on something not available:
```bash
docker exec mycontainer s6-rc-db -c /run/service/db dependencies myapp
```

Solution:
- Add missing service
- Or remove incorrect dependency

**Cause 4: Wrong interpreter**

Error in run script:
```
/bin/sh: /command/execlineb: not found
```

Solution:
- Use `#!/bin/sh` instead of `#!/command/execlineb` if execline isn't needed
- Or install execline properly
- Or fix shebang path

### Error: Service starts then immediately stops

**Check service logs:**

```bash
docker exec mycontainer tail -f /var/log/myapp/current
```

**Common causes:**

**1. Process doesn't stay in foreground**

Service starts in daemon mode and exits immediately.

Solution:
- Ensure service runs in foreground mode
- Nginx: `daemon off;`
- Apache: `-D FOREGROUND`
- Most services: check docs for foreground flag

**2. Service crashes on startup**

Solution:
- Check application logs for errors
- Verify configuration files are valid
- Test application outside of s6-overlay
- Check file permissions

**3. Missing required files/directories**

Solution:
- Add initialization oneshot to create directories
- Set proper ownership and permissions
- Verify all config files exist

### Error: Can't find service

Error:
```
s6-rc: fatal: unable to find service myapp
```

**Cause 1: Service not in user bundle**

Solution:
```bash
touch /etc/s6-overlay/s6-rc.d/user/contents.d/myapp
```

**Cause 2: Service name mismatch**

Check directory name matches reference:
```bash
ls /etc/s6-overlay/s6-rc.d/
```

**Cause 3: Service is in pipeline**

If service is part of pipeline, reference the pipeline name instead:
```bash
touch /etc/s6-overlay/s6-rc.d/user/contents.d/myapp-pipeline
```

## Dependency Issues

### Services start in wrong order

**Symptom:** App starts before database is ready

**Diagnosis:**
```bash
# Check dependency chain
docker exec mycontainer s6-rc-db -c /run/service/db dependencies myapp
docker exec mycontainer s6-rc-db -c /run/service/db dependencies postgres
```

**Solution:**

Add missing dependency:
```bash
touch /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/postgres
```

Rebuild image and test.

### Circular dependency detected

**Error:**
```
s6-rc-compile: fatal: circular dependency: service myapp depends on itself
```

**Diagnosis:**

Check full dependency chain:
```
myapp → db-init → database → myapp  # Circular!
```

**Solution:**

Break the circle:
- Identify which dependency is incorrect
- Remove the dependency creating the loop
- Reorganize service structure if needed

### Service waits forever for dependency

**Symptom:** Container hangs during startup, service waiting for dependency

**Check:** Is dependency ever started?

```bash
docker exec mycontainer s6-svstat /run/service/dependency-name
```

**Cause 1: Dependency not in bundle**

Solution:
```bash
touch /etc/s6-overlay/s6-rc.d/user/contents.d/dependency-name
```

**Cause 2: Dependency is failing**

Check dependency logs, fix the dependency first.

**Cause 3: Typo in dependency name**

Verify spelling matches exactly:
```bash
ls /etc/s6-overlay/s6-rc.d/
ls /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/
```

## Logging Issues

### No logs appearing

**Symptom:** Expected logs in `/var/log/myapp/` but directory is empty

**Cause 1: Log directory doesn't exist**

Solution: Create log preparation oneshot:

```bash
mkdir -p /etc/s6-overlay/s6-rc.d/myapp-log-prepare
echo "oneshot" > /etc/s6-overlay/s6-rc.d/myapp-log-prepare/type
cat > /etc/s6-overlay/s6-rc.d/myapp-log-prepare/up << 'EOF'
if { mkdir -p /var/log/myapp }
if { chown nobody:nogroup /var/log/myapp }
chmod 02755 /var/log/myapp
EOF
touch /etc/s6-overlay/s6-rc.d/myapp-log/dependencies.d/myapp-log-prepare
```

**Cause 2: Wrong permissions**

Solution:
```bash
chown nobody:nogroup /var/log/myapp
chmod 02755 /var/log/myapp
```

**Cause 3: Logger not running**

Check logger status:
```bash
docker exec mycontainer s6-svstat /run/service/myapp-log
```

If down, check logger run script and dependencies.

**Cause 4: Pipeline not configured correctly**

Verify pipeline files exist:
```bash
# Check producer-for
cat /etc/s6-overlay/s6-rc.d/myapp/producer-for
# Should contain: myapp-log

# Check consumer-for
cat /etc/s6-overlay/s6-rc.d/myapp-log/consumer-for
# Should contain: myapp

# Check pipeline-name
cat /etc/s6-overlay/s6-rc.d/myapp-log/pipeline-name
# Should contain: myapp-pipeline

# Check pipeline in bundle
ls /etc/s6-overlay/s6-rc.d/user/contents.d/
# Should include myapp-pipeline
```

### Logs go to wrong location

**Symptom:** Logs appear in `docker logs` instead of internal files

**Cause:** Not using logging pipeline

**Solution:** Set up full logging pipeline (see SKILL.md Step 6)

### Can't read log files

**Error:**
```
Permission denied: /var/log/myapp/current
```

**Solution:**

Grant read permissions:
```bash
chmod 0755 /var/log/myapp
# Or for specific user
chown myuser:myuser /var/log/myapp
```

## Permission Issues

### Service can't write to directory

**Error:**
```
Permission denied: /var/lib/myapp/data
```

**Solution:**

Create initialization oneshot:
```bash
mkdir -p /etc/s6-overlay/s6-rc.d/myapp-init
echo "oneshot" > /etc/s6-overlay/s6-rc.d/myapp-init/type
cat > /etc/s6-overlay/s6-rc.d/myapp-init/up << 'EOF'
if { mkdir -p /var/lib/myapp/data }
if { chown myuser:myuser /var/lib/myapp/data }
chmod 0755 /var/lib/myapp/data
EOF
touch /etc/s6-overlay/s6-rc.d/myapp-init/dependencies.d/base
touch /etc/s6-overlay/s6-rc.d/myapp/dependencies.d/myapp-init
touch /etc/s6-overlay/s6-rc.d/user/contents.d/myapp-init
```

### Can't setuid/setgid

**Error:**
```
s6-setuidgid: fatal: unable to setuid: Operation not permitted
```

**Cause 1: Running with USER directive**

s6-setuidgid requires root. If container runs as non-root user:

Solution:
- Remove `s6-setuidgid` from run script
- Or run container as root, use s6-setuidgid to drop privileges

**Cause 2: Security context restricts setuid**

Kubernetes or Docker security policies may prevent setuid.

Solution:
- Run container as target user instead
- Or adjust security policies if possible

## Environment Variable Issues

### Service can't see environment variables

**Symptom:** Variables set with `docker run -e` not available in service

**Cause:** Environment not passed to service

**Solution:**

Use `with-contenv` wrapper:
```bash
#!/command/with-contenv sh
# Now $MY_VAR is available
echo $MY_VAR
exec myapp
```

Or set `S6_KEEP_ENV=1`:
```dockerfile
ENV S6_KEEP_ENV=1
```

### Environment variables lost after s6-setuidgid

**Symptom:** Vars disappear after changing user

**Cause:** Some implementations of setuid clear environment

**Solution:**

Use `with-contenv` before `s6-setuidgid`:
```bash
#!/command/with-contenv sh
exec s6-setuidgid myuser myapp
```

## Signal Handling Issues

### Container doesn't stop gracefully

**Symptom:** `docker stop` kills container immediately

**Check:** Grace period elapsed?

```bash
docker stop -t 30 mycontainer  # 30 second grace period
```

**Cause 1: Service doesn't handle SIGTERM**

Service doesn't respond to SIGTERM, waits for SIGKILL.

Solution:
- Ensure service handles SIGTERM gracefully
- Or increase `S6_SERVICES_GRACETIME`
- Or increase `S6_KILL_GRACETIME`

**Cause 2: Finish script hangs**

Finish script takes too long.

Solution:
- Fix finish script to complete faster
- Or increase `S6_KILL_FINISH_MAXTIME`

### Can't send signals to CMD

**Symptom:** `docker kill -s SIGUSR1` doesn't reach CMD

**Cause:** Signals go to pid 1 by default

**Solution:**

Set `S6_CMD_RECEIVE_SIGNALS=1`:
```dockerfile
ENV S6_CMD_RECEIVE_SIGNALS=1
```

Note: This changes shutdown behavior.

## Build Issues

### Can't extract s6-overlay tarballs

**Error:**
```
tar: This does not look like a tar archive
```

**Cause 1: Missing xz-utils**

Solution:
```dockerfile
RUN apt-get update && apt-get install -y xz-utils
```

**Cause 2: Corrupt download**

Solution:
- Verify checksums
- Re-download tarballs

**Cause 3: Wrong tarball for architecture**

Solution:
- Check `TARGETARCH` vs s6-overlay architecture naming
- See SKILL.md or docs for correct mapping

### Permission errors during build

**Error:**
```
tar: Cannot change ownership: Operation not permitted
```

**Cause:** Not using `-p` flag

**Solution:**
```dockerfile
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
#                 ^ Add -p flag
```

## Runtime Issues

### Container uses 100% CPU

**Symptom:** s6-svscan or service consuming all CPU

**Cause 1: Service respawning rapidly**

Check logs:
```bash
docker logs mycontainer | grep "service myapp"
```

If seeing rapid restart messages:
```
s6-rc: info: service myapp started
s6-rc: info: service myapp stopped
s6-rc: info: service myapp started
```

Solution:
- Fix service so it doesn't immediately exit
- Add proper run script that stays in foreground

**Cause 2: Infinite loop in script**

Check oneshot scripts for infinite loops.

**Cause 3: Resource exhaustion**

Container may be out of memory, swapping constantly.

Solution:
- Increase container memory limits
- Reduce service resource usage

### Memory leak

**Symptom:** Container memory usage grows over time

**Likely cause:** Application issue, not s6-overlay

**Diagnosis:**

Monitor processes:
```bash
docker exec mycontainer ps aux --sort=-%mem
```

Find which process is consuming memory.

**Solution:**
- Fix application memory leak
- Restart service periodically if needed
- Set memory limits

## Read-Only Filesystem Issues

### Can't write to /etc

**Error:**
```
Read-only file system: /etc/myapp/config
```

**Cause:** Using `--read-only` without `S6_READ_ONLY_ROOT`

**Solution:**

```dockerfile
ENV S6_READ_ONLY_ROOT=1
```

And run with tmpfs for /run:
```bash
docker run --read-only --tmpfs /run myimage
```

### Services fail with read-only root

**Cause:** Services try to write to read-only locations

**Solution:**

- Mount writable volumes for data directories
- Use /tmp or /run for temporary files
- Configure services to use writable paths

## Kubernetes-Specific Issues

### Permission errors in Kubernetes

**Error:**
```
s6-overlay: fatal: /run permissions are insecure (0777) and owned by uid 0
```

**Cause:** Kubernetes enforces world-writable /run

**Solution:**

```dockerfile
ENV S6_YES_I_WANT_A_WORLD_WRITABLE_RUN_BECAUSE_KUBERNETES=1
```

Only use in Kubernetes, never in plain Docker.

### Pod fails readiness check

**Symptom:** Pod keeps restarting, never becomes ready

**Cause:** Service not implementing readiness

**Solution:**

Implement readiness check in service or use Kubernetes native readiness probes:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

## Migration Issues

### Legacy services don't start

**Symptom:** Services in `/etc/services.d` work in v2 but not v3

**Cause 1: Different timing**

v3 starts services differently than v2.

**Solution:**
- Add proper dependencies
- Migrate to s6-rc format

**Cause 2: Environment changes**

**Solution:**
- Use `with-contenv` in run scripts
- Or set `S6_KEEP_ENV=1`

### Oneshots run in wrong order

**Symptom:** Scripts that ran in order (01-, 02-) now run out of order

**Cause:** s6-rc runs independent oneshots in parallel

**Solution:**

Add explicit dependencies:
```bash
touch /etc/s6-overlay/s6-rc.d/02-script/dependencies.d/01-script
```

## Getting Help

If issues persist after trying these solutions:

1. **Enable verbose logging:** `S6_VERBOSITY=4`
2. **Check service status:** `s6-svstat`, `s6-rc -a list`
3. **Review logs:** Docker logs + internal logs
4. **Test services independently:** Run scripts manually
5. **Simplify:** Remove services until finding the problem
6. **Check documentation:** https://github.com/just-containers/s6-overlay
7. **Search issues:** https://github.com/just-containers/s6-overlay/issues
8. **Ask for help:** Provide logs, Dockerfile, service definitions

**Useful information when asking for help:**

- s6-overlay version
- Base image
- Full Dockerfile
- Service definitions
- Container logs (`docker logs`)
- Error messages
- Output of `s6-svstat /run/service/myservice`
- Output of `s6-rc -a list`
