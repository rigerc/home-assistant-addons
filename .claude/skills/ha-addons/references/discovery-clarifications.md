# Discovery Phase Clarifications Guide

This reference provides detailed guidance on gathering additional information after running the discovery phase when creating Home Assistant add-ons.

## Purpose

Discovery scripts provide automated analysis, but human insight is essential for:
- Verifying discovered information is correct
- Understanding user intent and preferences
- Gathering files that weren't publicly accessible
- Making architectural decisions (ingress vs ports, which features to expose)

## When to Ask Clarifying Questions

**Always ask after discovery completes** - even if discovery found comprehensive information. The user may want:
- Different configuration than what was discovered
- Specific features enabled/disabled
- Custom networking setup
- Additional integration with Home Assistant services

## Using AskUserQuestion Tool

**IMPORTANT:** Use the AskUserQuestion tool to gather clarifications efficiently. This tool:
- Presents structured questions with clear options
- Supports multi-select for questions where multiple answers apply
- Provides a better user experience than free-form text questions
- Ensures consistent data collection

## AskUserQuestion Structure

After discovery, use a single AskUserQuestion call with 3-4 structured questions:

**Example AskUserQuestion call:**

```javascript
{
  "questions": [
    {
      "question": "I analyzed linuxserver/plex:latest and found Alpine Linux base, ports 32400/3005/8324, volumes /config and /transcode, amd64/arm64/armv7 support. Is this the correct application and version for the add-on?",
      "header": "Verification",
      "options": [
        {
          "label": "Yes, proceed with these settings",
          "description": "Discovery results are correct"
        },
        {
          "label": "Different version needed",
          "description": "Need to analyze a different tag or version"
        },
        {
          "label": "Modify findings",
          "description": "Some discovered information needs adjustment"
        }
      ],
      "multiSelect": false
    },
    {
      "question": "Which additional files can you provide to ensure accurate configuration?",
      "header": "Files",
      "options": [
        {
          "label": "Application Dockerfile",
          "description": "Custom or modified Dockerfile with exact dependencies"
        },
        {
          "label": "docker-compose.yaml file",
          "description": "Complete environment and service configuration"
        },
        {
          "label": "Configuration examples",
          "description": "Example config files (.env, settings.yaml, etc.)"
        },
        {
          "label": "None available",
          "description": "Use discovered information only"
        }
      ],
      "multiSelect": true
    },
    {
      "question": "How should users access this application?",
      "header": "Access",
      "options": [
        {
          "label": "Ingress only (embedded in HA UI)",
          "description": "Seamless HA integration with single sign-on"
        },
        {
          "label": "Direct port access only",
          "description": "Independent access, works with external tools"
        },
        {
          "label": "Both ingress and ports (Recommended)",
          "description": "Maximum flexibility for all use cases"
        }
      ],
      "multiSelect": false
    },
    {
      "question": "Which configuration options should be user-configurable in Home Assistant?",
      "header": "Config",
      "options": [
        {
          "label": "Port number",
          "description": "Allow users to change the listening port"
        },
        {
          "label": "Log level",
          "description": "Control logging verbosity (debug, info, warning, error)"
        },
        {
          "label": "All environment variables",
          "description": "Expose all discovered env vars as options"
        },
        {
          "label": "Essential options only",
          "description": "Only expose critical settings, use defaults for others"
        }
      ],
      "multiSelect": true
    }
  ]
}
```

## Required Clarifying Questions

### 1. Verify Discovery Results

**Purpose**: Ensure the discovered information matches user expectations.

**AskUserQuestion structure:**
- **Header**: "Verification"
- **Question**: "I analyzed [source] and found [summary]. Is this the correct application and version for the add-on?"
- **Options**:
  - "Yes, proceed with these settings"
  - "Different version needed"
  - "Modify findings"
- **Multi-select**: false

**Why this matters:**
- Docker images may have multiple tags (latest, stable, specific versions)
- GitHub repos may have multiple branches
- Applications may have different editions (community vs pro)

### 2. Request Additional Files

**Purpose**: Obtain files that weren't discovered or weren't publicly accessible.

**AskUserQuestion structure:**
- **Header**: "Files"
- **Question**: "Which additional files can you provide to ensure accurate configuration?"
- **Options**:
  - "Application Dockerfile" - Custom or modified Dockerfile with exact dependencies
  - "docker-compose.yaml file" - Complete environment and service configuration
  - "Configuration examples" - Example config files (.env, settings.yaml, etc.)
  - "None available" - Use discovered information only
- **Multi-select**: true (allows selecting multiple files)

#### After User Indicates Files Available

If the user selects any files besides "None available", follow up with a request to share them:

```
Please share the files you indicated are available:
[List the selected files]

You can paste the file contents directly, or provide file paths if they're accessible.
```

**What to look for in provided Dockerfile:**
- `RUN apk add` / `RUN apt-get install` - dependencies to include
- `ENV` statements - environment variables to expose as options
- `EXPOSE` - ports to configure
- `VOLUME` - directories to map
- `ENTRYPOINT` / `CMD` - startup command for service script
- `WORKDIR` - working directory for the application
- `USER` - user the application runs as

#### docker-compose.yaml Request

**When to request:**
- Application has complex service dependencies
- Documentation mentions docker-compose setup
- Multiple containers work together

**Template:**
```
If this application has a docker-compose.yaml file, please share it. This helps me understand:
- Complete environment variable configuration
- Volume mount requirements and paths
- Port mappings and network configuration
- Service dependencies (databases, message queues, etc.)
- Resource limits and constraints

This information ensures the add-on is configured correctly from the start.
```

**What to look for in docker-compose.yaml:**
```yaml
services:
  app:
    image: ...           # Confirms Docker image
    ports: ...           # Port mappings
    volumes: ...         # Volume requirements
    environment: ...     # ALL environment variables (comprehensive list)
    depends_on: ...      # Service dependencies to document
    restart: ...         # Restart policy hints
    networks: ...        # Network configuration
```

#### Configuration File Examples

**When to request:**
- Application has complex configuration
- Discovery found config file references but not actual files
- You need to understand default values

**Template:**
```
If you have example configuration files (.env, config.yaml, settings.json, etc.), please share them. This helps me:
- Identify all configurable options and their defaults
- Create proper schema validation in config.yaml
- Set sensible default values
- Document configuration options in DOCS.md

Common files that are helpful: .env, .env.example, config.yaml, settings.json, application.conf
```

**What to extract from config examples:**
```ini
# .env example
DATABASE_URL=postgres://...    # → Database configuration options
SECRET_KEY=changeme            # → Security settings to expose
LOG_LEVEL=info                 # → Logging options
PORT=8080                      # → Network configuration
ENABLE_FEATURE_X=true          # → Optional features to expose
```

### 3. Configuration Preferences

**Purpose**: Understand which options should be user-configurable vs hardcoded.

**AskUserQuestion structure:**
- **Header**: "Config"
- **Question**: "Which configuration options should be user-configurable in Home Assistant?"
- **Options**:
  - "Port number" - Allow users to change the listening port
  - "Log level" - Control logging verbosity (debug, info, warning, error)
  - "All environment variables" - Expose all discovered env vars as options
  - "Essential options only" - Only expose critical settings, use defaults for others
- **Multi-select**: true (allows selecting multiple configuration scopes)

**Decision framework:**
- **Always expose**: Ports, log levels, feature toggles
- **Usually expose**: Paths, URLs, credentials
- **Rarely expose**: Internal timeouts, buffer sizes (unless advanced users need them)
- **Never expose**: Security tokens in plaintext (use SSL certificate configuration instead)

#### Optional Features Question

**When the app has feature flags:**

**Template:**
```
I see this application supports optional features:
- [Feature 1]: [description]
- [Feature 2]: [description]

Should these be:
1. Always enabled (built into add-on)
2. User-configurable (options in config.yaml)
3. Disabled by default (advanced users can enable)
```

**Configuration pattern:**
```yaml
# config.yaml
options:
  enable_feature_x: false
  enable_feature_y: true

schema:
  enable_feature_x: bool
  enable_feature_y: bool
```

### 4. Network Configuration Preferences

**Purpose**: Determine how users will access the application.

**AskUserQuestion structure:**
- **Header**: "Access"
- **Question**: "How should users access this application?"
- **Options**:
  - "Ingress only (embedded in HA UI)" - Seamless HA integration with single sign-on
  - "Direct port access only" - Independent access, works with external tools
  - "Both ingress and ports (Recommended)" - Maximum flexibility for all use cases
- **Multi-select**: false (single choice)

**Implementation impact:**

**Ingress only:**
```yaml
# config.yaml
ingress: true
ingress_port: 8099
panel_icon: mdi:application
```

**Ports only:**
```yaml
# config.yaml
ports:
  8080/tcp: 8080
ports_description:
  8080/tcp: Web interface
```

**Both:**
```yaml
# config.yaml
ingress: true
ingress_port: 8099
panel_icon: mdi:application
ports:
  8080/tcp: 8080
ports_description:
  8080/tcp: Direct access to web interface
```

#### Service Dependencies Question

**When app needs external services:**

**Template:**
```
Does this application need to communicate with:
- MQTT broker? (for IoT messaging)
- Database? (PostgreSQL, MySQL, etc.)
- Other Home Assistant add-ons?
- External APIs or services?

This affects network configuration and service discovery setup.
```

**Implementation for MQTT:**
```yaml
# config.yaml
services:
  - mqtt:want

# rootfs/etc/cont-init.d/01-setup.sh
if bashio::services.available 'mqtt'; then
    MQTT_HOST="$(bashio::services mqtt 'host')"
    MQTT_PORT="$(bashio::services mqtt 'port')"
    MQTT_USER="$(bashio::services mqtt 'username')"
    MQTT_PASS="$(bashio::services mqtt 'password')"
fi
```

### 5. Architecture and Performance

**Purpose**: Understand deployment requirements and constraints.

**Template:**
```
Architecture and performance questions:

1. Which platforms need to be supported?
   - amd64 (Intel/AMD x64) - most common
   - aarch64 (ARM 64-bit) - Raspberry Pi 4, etc.
   - armv7 (ARM 32-bit) - Raspberry Pi 3, older devices

2. Does this application have significant resource requirements?
   - High memory usage? (might need tmpfs)
   - Heavy CPU? (affects scheduler priority)
   - GPU required? (needs device mapping)

3. Does it need specific hardware access?
   - USB devices (Zigbee, Z-Wave sticks)
   - GPIO pins
   - Audio devices
```

**Implementation for hardware access:**
```yaml
# config.yaml - USB device
usb:
  - path: /dev/ttyUSB0
    description: Zigbee coordinator

# config.yaml - GPIO
gpio: true

# config.yaml - Audio
audio: true
```

## Question Sequencing Strategy

Ask questions in this order to minimize back-and-forth:

### Phase 1: Verification (1 question)
1. Verify discovery results are correct

### Phase 2: File Gathering (1 question with multiple parts)
2. Request all additional files at once:
   - Dockerfile
   - docker-compose.yaml
   - Configuration examples

**Don't ask for files one at a time** - bundle the request.

### Phase 3: Configuration Design (1-2 questions)
3. Ask about configuration preferences and network setup together:
   - Which options to expose
   - Ingress vs ports
   - Service dependencies

### Phase 4: Advanced Requirements (if needed)
4. Only if relevant, ask about:
   - Architecture requirements
   - Hardware access
   - Performance considerations

## Handling Responses

### User Provides Dockerfile

**Actions:**
1. Read the Dockerfile thoroughly
2. Extract all `ENV`, `EXPOSE`, `VOLUME` declarations
3. Note the base image and compare to Home Assistant bases
4. Identify `RUN` commands for dependencies
5. Understand the `ENTRYPOINT`/`CMD` for service script

**Update your checklist:**
```markdown
## Dockerfile Analysis
- Base image: alpine:3.18 → Use ghcr.io/home-assistant/amd64-base:3.23
- Dependencies: python3, py3-pip, bash, curl
- Ports: 8080 (ENV PORT=8080)
- Volumes: /config, /data
- Startup: python /app/main.py --foreground
```

### User Provides docker-compose.yaml

**Actions:**
1. Extract complete environment variable list
2. Note volume mount paths
3. Check for service dependencies
4. Review network configuration
5. Check resource limits

**Update schema based on env vars:**
```yaml
# From docker-compose environment section
options:
  database_url: "sqlite:///data/db.sqlite"
  enable_metrics: false
  worker_threads: 2

schema:
  database_url: str
  enable_metrics: bool
  worker_threads: "int(1,16)"
```

### User Provides Config Examples

**Actions:**
1. Parse all configuration keys
2. Identify sensible defaults
3. Determine which are required vs optional
4. Create schema with appropriate validation

**Example extraction:**
```yaml
# User's config.yaml
server:
  host: 0.0.0.0
  port: 8080
  ssl: false

logging:
  level: info
  file: /var/log/app.log

features:
  cache: true
  analytics: false
```

**Translate to add-on config:**
```yaml
options:
  port: 8080
  log_level: info
  enable_cache: true
  enable_analytics: false

schema:
  port: port
  log_level: list(debug|info|warning|error)
  enable_cache: bool
  enable_analytics: bool
```

### User Doesn't Have Files

**Fallback strategies:**

1. **No Dockerfile**: Use discovery results + documentation
2. **No docker-compose**: Use discovered env vars + reasonable defaults
3. **No config examples**: Expose only essential options, document others in DOCS.md

**Document uncertainty:**
```markdown
## Configuration Notes
- Using defaults from discovery analysis
- Additional options may exist but were not documented
- Users can report missing options as feature requests
```

## Common Pitfalls to Avoid

### Pitfall 1: Skipping Verification

❌ **Bad:**
```
Discovery complete. Moving to scaffolding...
```

✅ **Good:**
```
I've analyzed linuxserver/plex and found it uses Alpine Linux,
exposes ports 32400, 3005, 8324, and needs /config and /transcode volumes.

Is this the correct Plex version you want to wrap? Should I proceed with these settings?
```

### Pitfall 2: Asking for Files Separately

❌ **Bad:**
```
Do you have a Dockerfile?
[wait for response]
Do you have a docker-compose file?
[wait for response]
Do you have config examples?
```

✅ **Good:**
```
To ensure accurate configuration, can you provide any of these if available?
- Dockerfile (for exact dependencies and build process)
- docker-compose.yaml (for complete environment configuration)
- Configuration examples (.env, config.yaml, etc.)

Share whatever you have - even partial information helps!
```

### Pitfall 3: Assuming Preferences

❌ **Bad:**
```
I'll configure this with ingress and expose all environment variables as options.
```

✅ **Good:**
```
How should users access this application?
- Ingress only (embedded in HA UI)
- Direct port access
- Both options

And which environment variables should be user-configurable vs. using defaults?
```

### Pitfall 4: Ignoring Service Dependencies

❌ **Bad:**
```
Moving on to implementation...
```

✅ **Good:**
```
Does this application need to communicate with:
- MQTT broker?
- Database?
- Other services?

This affects the service discovery configuration.
```

## Example Complete Flow

### Starting State
User: "Create an add-on for Bazarr"

### Step 1: Run Discovery
```bash
.claude/skills/ha-addons/scripts/discover.sh linuxserver/bazarr:latest
```

### Step 2: Verify Results
```
I've analyzed linuxserver/bazarr:latest and found:
- Base: LinuxServer.io Alpine image
- Architecture: amd64, arm64, armv7
- Port: 6767/tcp (web UI)
- Volumes: /config, /movies, /tv
- Uses s6-overlay v2

Is this correct? This appears to be for subtitle management. Should I proceed with these settings?
```

### Step 3: Request Additional Files
```
To ensure complete configuration, can you provide:

1. **Dockerfile** (if you have a custom build or modifications)
2. **docker-compose.yaml** (if you're currently using one)
3. **Configuration examples** (config.yaml, settings, etc.)

If you don't have these, I'll work with the discovered information, but they help ensure accuracy.
```

### Step 4: Configuration Questions
```
Configuration questions:

1. **Access method**: Should this be accessible via:
   - Ingress only (embedded in HA UI)
   - Direct port (independent access)
   - Both options

2. **Configurable options**: Should users be able to configure:
   - Port number? (discovered default: 6767)
   - Log level?
   - Any other application-specific options?

3. **Media access**: Should this add-on have access to:
   - Media folder? (for movies/TV shows)
   - Any other directories?
```

### Step 5: Document and Proceed
```markdown
## Bazarr Add-on Configuration

### Verified Settings
- Application: Bazarr (subtitle management)
- Source: linuxserver/bazarr:latest
- Architectures: amd64, aarch64, armv7

### User Preferences
- Access: Both ingress and direct port
- Port: 6767 (user-configurable)
- Media access: Yes (map media folder)

### Files Provided
- docker-compose.yaml ✓ (complete environment config)
- No custom Dockerfile (using linuxserver image)

Proceeding to Phase 2: Setup & Scaffolding...
```

## Summary

**Always ask these questions after discovery:**

1. ✅ "Is the discovered information correct?"
2. ✅ "Can you provide [Dockerfile / docker-compose / config examples]?"
3. ✅ "Which options should be user-configurable?"
4. ✅ "How should users access this (ingress/ports/both)?"
5. ✅ "Does it need [MQTT / databases / other services]?"

**Benefits:**
- Catches errors early (wrong version, wrong app)
- Gets complete configuration info upfront
- Aligns add-on design with user expectations
- Reduces back-and-forth later in process

**Remember:** Discovery provides automation, but human insight ensures the add-on meets user needs.
