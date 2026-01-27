# s6-overlay Service Patterns

Comprehensive patterns for common service types in s6-overlay v3 using the s6-rc format.

## Web Server Services

### Nginx Service

**Directory structure:**
```
/etc/s6-overlay/s6-rc.d/
├── nginx-prepare/
│   ├── type (oneshot)
│   ├── up
│   └── dependencies.d/
│       └── base
├── nginx/
│   ├── type (longrun)
│   ├── run
│   ├── producer-for (nginx-log)
│   └── dependencies.d/
│       ├── base
│       └── nginx-prepare
├── nginx-log/
│   ├── type (longrun)
│   ├── run
│   ├── consumer-for (nginx)
│   └── pipeline-name (nginx-pipeline)
└── user/
    └── contents.d/
        └── nginx-pipeline
```

**nginx-prepare/up:**
```bash
#!/command/execlineb -P
if { mkdir -p /var/log/nginx }
if { mkdir -p /var/cache/nginx }
if { chown -R nginx:nginx /var/log/nginx /var/cache/nginx }
if { chmod 0755 /var/log/nginx }
nginx -t
```

**nginx/run:**
```bash
#!/command/execlineb -P
fdmove -c 2 1
s6-setuidgid nginx
nginx -g "daemon off;"
```

**nginx-log/run:**
```bash
#!/bin/sh
exec logutil-service /var/log/nginx
```

### Apache/httpd Service

**httpd/run:**
```bash
#!/bin/sh
exec 2>&1
# Remove existing PID file
rm -f /run/httpd/httpd.pid
# Start Apache in foreground
exec httpd -D FOREGROUND
```

### Caddy Service

**caddy/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid caddy \
  caddy run --config /etc/caddy/Caddyfile
```

## Database Services

### PostgreSQL Service

**Directory structure:**
```
postgres-init/
├── type (oneshot)
├── up
└── dependencies.d/
    └── base
postgres/
├── type (longrun)
├── run
├── finish
└── dependencies.d/
    ├── base
    └── postgres-init
```

**postgres-init/up:**
```bash
#!/bin/sh
set -e

# Create data directory if needed
if [ ! -d /var/lib/postgresql/data ]; then
    mkdir -p /var/lib/postgresql/data
    chown postgres:postgres /var/lib/postgresql/data
    chmod 0700 /var/lib/postgresql/data
fi

# Initialize database if needed
if [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
    su-exec postgres initdb -D /var/lib/postgresql/data
fi
```

**postgres/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid postgres \
  postgres -D /var/lib/postgresql/data
```

**postgres/finish:**
```bash
#!/bin/sh
# Ensure clean shutdown
if test "$1" -ne 0 -a "$1" -ne 256 ; then
    echo "$1" > /run/s6-linux-init-container-results/exitcode
    /run/s6/basedir/bin/halt
fi
```

### MySQL/MariaDB Service

**mysql-init/up:**
```bash
#!/bin/sh
set -e

if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Create log directory
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql
chmod 0755 /var/log/mysql
```

**mysql/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid mysql \
  mysqld --datadir=/var/lib/mysql \
         --bind-address=0.0.0.0
```

### Redis Service

**redis/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid redis \
  redis-server /etc/redis/redis.conf \
  --daemonize no
```

### MongoDB Service

**mongodb/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid mongodb \
  mongod --config /etc/mongodb/mongod.conf
```

## Message Queue Services

### RabbitMQ Service

**rabbitmq-prepare/up:**
```bash
#!/bin/sh
set -e

# Set up data directories
mkdir -p /var/lib/rabbitmq /var/log/rabbitmq
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq
chmod 0755 /var/lib/rabbitmq /var/log/rabbitmq

# Enable management plugin if needed
rabbitmq-plugins enable rabbitmq_management
```

**rabbitmq/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid rabbitmq \
  rabbitmq-server
```

### Redis Queue (RQ) Worker

**rq-worker/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid appuser \
  with-contenv \
  rq worker --url redis://redis:6379 default
```

**rq-worker/dependencies.d:**
```
base
redis
app-init
```

### Celery Worker

**celery-worker/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid appuser \
  with-contenv \
  celery -A myapp worker --loglevel=info
```

**celery-beat/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid appuser \
  with-contenv \
  celery -A myapp beat --loglevel=info \
  --pidfile= --schedule=/tmp/celerybeat-schedule
```

## Application Services

### Python/Flask Application

**app-init/up:**
```bash
#!/bin/sh
set -e
cd /app
# Run database migrations
flask db upgrade
# Create necessary directories
mkdir -p /var/log/app /tmp/app
chown appuser:appuser /var/log/app /tmp/app
```

**app/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid appuser \
  with-contenv \
  gunicorn --bind 0.0.0.0:5000 \
           --workers 4 \
           --access-logfile - \
           --error-logfile - \
           wsgi:app
```

### Node.js Application

**node-app/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid node \
  with-contenv \
  node server.js
```

### Python Uvicorn (FastAPI)

**uvicorn/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid appuser \
  with-contenv \
  uvicorn main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --log-level info
```

### Ruby on Rails (Puma)

**rails-app/run:**
```bash
#!/bin/sh
exec 2>&1
cd /app
exec s6-setuidgid rails \
  with-contenv \
  bundle exec puma -C config/puma.rb
```

## Cron and Scheduled Tasks

### Cron Service

**cron-prepare/up:**
```bash
#!/bin/sh
set -e
# Load crontab
crontab -u appuser /etc/cron.d/app-crontab
# Ensure log directory exists
mkdir -p /var/log/cron
chmod 0755 /var/log/cron
```

**cron/run:**
```bash
#!/bin/sh
exec 2>&1
# Run cron in foreground
exec cron -f -L 15
```

**Alternative: Custom Scheduler**

For simple periodic tasks, create a dedicated service:

**scheduled-task/type:**
```
longrun
```

**scheduled-task/run:**
```bash
#!/command/execlineb -P
fdmove -c 2 1
backtick -D 3600 INTERVAL { printenv TASK_INTERVAL }
loopwhilex
importas -u interval INTERVAL
foreground { /app/scripts/run-task.sh }
s6-sleep -- ${interval}
```

This runs a task every TASK_INTERVAL seconds (default 3600).

## Cache Services

### Memcached Service

**memcached/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid memcached \
  memcached -m 64 -c 1024 -u memcached -l 0.0.0.0
```

### Varnish Service

**varnish-prepare/up:**
```bash
#!/bin/sh
set -e
# Compile VCL
varnishd -C -f /etc/varnish/default.vcl > /tmp/varnish.compiled.vcl
mkdir -p /var/lib/varnish
```

**varnish/run:**
```bash
#!/bin/sh
exec 2>&1
exec varnishd -F \
  -f /etc/varnish/default.vcl \
  -s malloc,256M \
  -a :6081
```

## Proxy and Load Balancer Services

### HAProxy Service

**haproxy-validate/up:**
```bash
#!/bin/sh
# Validate configuration before starting
haproxy -c -f /etc/haproxy/haproxy.cfg
```

**haproxy/run:**
```bash
#!/bin/sh
exec 2>&1
exec haproxy -db -f /etc/haproxy/haproxy.cfg
```

### Envoy Proxy

**envoy/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid envoy \
  envoy -c /etc/envoy/envoy.yaml \
        --log-level info
```

## Monitoring and Logging Services

### Prometheus Node Exporter

**node-exporter/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid nobody \
  node_exporter --web.listen-address=:9100
```

### Fluentd Service

**fluentd-prepare/up:**
```bash
#!/bin/sh
set -e
mkdir -p /var/log/fluentd /fluentd/log
chown -R fluent:fluent /var/log/fluentd /fluentd/log
```

**fluentd/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid fluent \
  fluentd -c /fluentd/etc/fluent.conf
```

### Logstash Service

**logstash/run:**
```bash
#!/bin/sh
exec 2>&1
exec s6-setuidgid logstash \
  logstash -f /etc/logstash/logstash.conf
```

## SSH and Remote Access

### OpenSSH Server

**sshd-prepare/up:**
```bash
#!/bin/sh
set -e
# Generate host keys if missing
ssh-keygen -A
# Create privilege separation directory
mkdir -p /run/sshd
chmod 0755 /run/sshd
# Create log directory
mkdir -p /var/log/sshd
chmod 0755 /var/log/sshd
```

**sshd/run:**
```bash
#!/bin/sh
exec 2>&1
# Run sshd in foreground
exec /usr/sbin/sshd -D -e
```

## Complex Multi-Service Application

Example: Full web application stack with database, cache, workers, and web server.

**Directory structure:**
```
/etc/s6-overlay/s6-rc.d/
├── postgres-init/        # Initialize database
├── postgres/             # Database service
├── redis/                # Cache service
├── app-init/             # Run migrations, prepare app
├── app-worker/           # Background job worker
├── app-web/              # Web application
├── nginx-prepare/        # Prepare nginx
├── nginx/                # Reverse proxy
└── user/contents.d/
    ├── postgres-pipeline
    ├── redis
    ├── app-init
    ├── app-worker-pipeline
    ├── app-web-pipeline
    └── nginx-pipeline
```

**Dependency chain:**
```
base → postgres-init → postgres
base → redis
base + postgres + redis → app-init → app-worker, app-web
base → nginx-prepare → nginx
```

**app-init/dependencies.d:**
```
base
postgres
redis
```

**app-worker/dependencies.d:**
```
base
app-init
```

**app-web/dependencies.d:**
```
base
app-init
```

**nginx/dependencies.d:**
```
base
nginx-prepare
app-web
```

This ensures:
1. Database and cache start first
2. App initialization runs after infrastructure is ready
3. App services start after initialization
4. Nginx starts last, after app is ready

## Service Readiness Notifications

For services that need time to become ready, implement readiness notifications.

**Service with notification:**

**postgres/notification-fd:**
```
3
```

**postgres/run:**
```bash
#!/command/execlineb -P
fdmove -c 2 1
background {
  # Wait for PostgreSQL to be ready
  s6-setuidgid postgres
  foreground {
    loopwhilex -x 1
    redirfd -w 2 /dev/null
    pg_isready -h localhost
  }
  # Send readiness notification
  s6-notifyoncheck
}
s6-setuidgid postgres
postgres -D /var/lib/postgresql/data
```

This tells s6 that the service is ready when `pg_isready` succeeds, not just when it starts.

## Service Templates

### Generic Application Template

```
myapp-init/          # Initialization
├── type (oneshot)
├── up
└── dependencies.d/
    └── base

myapp/               # Main service
├── type (longrun)
├── run
├── finish
├── producer-for (myapp-log)
└── dependencies.d/
    ├── base
    └── myapp-init

myapp-log-prepare/   # Log directory setup
├── type (oneshot)
├── up
└── dependencies.d/
    └── base

myapp-log/           # Logging
├── type (longrun)
├── run
├── consumer-for (myapp)
├── pipeline-name (myapp-pipeline)
└── dependencies.d/
    └── myapp-log-prepare
```

Use this as a starting point and customize for specific application needs.

## Best Practices

1. **Always depend on base** - Ensures system is ready before service starts
2. **Use pipelines for logging** - Automatic log rotation and management
3. **Prepare resources in oneshots** - Create directories, validate configs before starting services
4. **Drop privileges** - Use `s6-setuidgid` to run as non-root users
5. **Redirect stderr to stdout** - `exec 2>&1` or `fdmove -c 2 1` for proper logging
6. **Run in foreground** - Never use daemon mode, s6 handles backgrounding
7. **Handle signals properly** - Let services handle SIGTERM gracefully
8. **Implement finish scripts for critical services** - Control container exit behavior
9. **Use readiness notifications** - Ensure dependent services wait for readiness
10. **Keep run scripts simple** - Complex logic belongs in separate scripts
