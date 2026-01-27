# Cleanuparr Home Assistant Add-on

[![Release](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/Cleanuparr/Cleanuparr/releases)
![Supports aarch64](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports amd64](https://img.shields.io/badge/amd64-yes-green.svg)
![Supports armv7](https://img.shields.io/badge/armv7-yes-green.svg)

Automated cleanup for Sonarr, Radarr, Lidarr, Readarr, and Whisparr downloads.

## Features

This add-on provides the following features:

- **Strike System** - Mark and track problematic downloads
- **Failed Import Management** - Remove downloads failing to import into *arr applications
- **Stalled Download Detection** - Remove downloads that have stopped making progress
- **Slow Download Management** - Handle downloads with poor performance
- **Content Blocking** - Filter unwanted content using blocklists
- **Malware Blocking** - Remove known malware based on community patterns
- **Automatic Search** - Trigger replacement searches when downloads are removed
- **Seeding Cleanup** - Clean up completed downloads based on time/ratio
- **Orphaned Detection** - Remove downloads no longer referenced by *arr apps
- **Notifications** - Get alerts on strikes and download removals

## Installation

### Option 1: Local Repository (Recommended for Development)

1. Navigate to **Supervisor** → **Add-on Store**
2. Click the menu (⋮) in the top right → **Repositories**
3. Add the following URL:

```
https://github.com/your-username/ha-addons
```

4. Find **Cleanuparr** in the **Local Add-ons** section
5. Click **Install**

### Option 2: Manual Installation

1. SSH into your Home Assistant system
2. Navigate to the add-ons directory: `cd /addons`
3. Create the add-on directory: `mkdir -p cleanuparr`
4. Copy all add-on files to the cleanuparr directory
5. Refresh the add-on store and install

## Configuration

### Add-on Options

The following options can be configured in the add-on options:

#### Application Settings

| Option | Default | Description |
|--------|---------|-------------|
| `log_level` | `info` | Logging verbosity (trace, debug, info, notice, warning, error, fatal) |
| `dry_run` | `true` | Log all operations without making changes (test mode) |
| `display_support_banner` | `true` | Show support section on dashboard |

#### HTTP Settings

| Option | Default | Description |
|--------|---------|-------------|
| `http_max_retries` | `3` | Number of retry attempts for failed HTTP requests |
| `http_timeout` | `30` | Seconds to wait before timing out HTTP requests |
| `http_certificate_validation` | `enabled_for_local_addresses` | SSL certificate validation mode |

#### Search Settings

| Option | Default | Description |
|--------|---------|-------------|
| `search_enabled` | `true` | Automatically search for replacements after removing downloads |
| `search_delay` | `5` | Seconds to wait before triggering replacement searches |

#### Logging Settings

| Option | Default | Description |
|--------|---------|-------------|
| `log_rolling_size_mb` | `10` | Maximum log file size before rotation |
| `log_retained_file_count` | `5` | Number of log files to keep |
| `log_time_limit_hours` | `24` | Maximum age for non-archived logs |
| `log_archive_enabled` | `true` | Archive old logs instead of deleting |
| `log_archive_retained_count` | `3` | Number of archived logs to keep |
| `log_archive_time_limit_days` | `30` | Maximum age for archived logs |

### Web Interface

After starting the add-on:

1. Click **Open Web UI** button
2. The Cleanuparr interface will open within Home Assistant (using Ingress)
3. Configure your *arr applications and download clients through the web interface

## Usage

### First-Time Setup

1. **Install the add-on** (see Installation above)
2. **Start the add-on** with default options (Dry Run mode enabled)
3. **Open the Web UI**
4. **Configure your *arr applications:**
   - Navigate to **Arr Instances** in the sidebar
   - Click **Add Arr Instance**
   - Select type (Sonarr, Radarr, Lidarr, Readarr)
   - Enter connection details:
     - **Name:** Descriptive name (e.g., "My Sonarr")
     - **URL:** `http://homeassistant:8989` (or local IP)
     - **API Key:** From *arr Settings → General → API Key
   - Click **Test Connection** to verify
   - Click **Save**
5. **Configure download clients:**
   - Navigate to **Download Clients** in the sidebar
   - Click **Add Download Client**
   - Select type (qBittorrent, Deluge, Transmission, µTorrent)
   - Enter connection details
   - Test and save
6. **Configure features:**
   - Navigate to each feature section (Queue Cleaner, Download Cleaner, Malware Blocker, etc.)
   - Enable desired features and configure rules
7. **Test in Dry Run mode:**
   - Leave **Dry Run** enabled
   - Monitor logs to see what would be cleaned
   - Adjust configuration as needed
8. **Disable Dry Run:**
   - Once satisfied with the configuration, disable **Dry Run**
   - Restart the add-on

### Recommended Setup

For the best experience, configure the following features:

1. **Queue Cleaner** - Remove stalled and slow downloads
2. **Download Cleaner** - Remove failed imports and blocked downloads
3. **Malware Blocker** - Block known malicious file patterns

## Integration with Home Assistant

### Service Discovery

The add-on can automatically detect *arr applications and download clients running on your network:

- **Arr instances:** Sonarr, Radarr, Lidarr, Readarr, Whisparr
- **Download clients:** qBittorrent, Deluge, Transmission, µTorrent

### Notifications

Cleanuparr can send notifications to various services:

- Discord
- Telegram
- Notifiarr
- Ntfy
- Pushover
- Apprise (supports many notification services)

Configure notifications in the **Notifications** section of the web UI.

## Troubleshooting

### Add-on won't start

**Symptoms:** Add-on fails to start, logs show error

**Solutions:**
1. Check the add-on logs for specific error messages
2. Verify the configuration directory exists: `/addon_configs/cleanuparr_cleanuparr`
3. Ensure the add-on has the necessary permissions
4. Try reinstalling the add-on

### Can't connect to *arr application

**Symptoms:** "Connection failed" when testing Arr instance

**Solutions:**
1. Verify the *arr application is running
2. Check the URL is correct (e.g., `http://homeassistant:8989`)
3. Verify the API key is valid
4. Check if the *arr application has CORS enabled
5. Try using the local IP address instead of `homeassistant`

### Dry Run mode not working

**Symptoms:** Downloads are being removed despite Dry Run being enabled

**Solutions:**
1. Verify **Dry Run** is enabled in add-on options
2. Restart the add-on after changing the option
3. Check the Cleanuparr logs for "Dry Run" confirmation

### Web UI not accessible

**Symptoms:** "Connection refused" when opening Web UI

**Solutions:**
1. Verify the add-on is running
2. Refresh the page
3. Try clearing your browser cache
4. Check the add-on logs for errors

## Support

- **Documentation:** [Cleanuparr Documentation](https://cleanuparr.dev)
- **GitHub Issues:** [Report Issues](https://github.com/Cleanuparr/Cleanuparr/issues)
- **Discord:** [Join Discord](https://discord.gg/SCtMCgtsc4)

## Development

### Building from Source

To build this add-on from source:

```bash
docker run \
  --rm \
  --privileged \
  -v /path/to/ha-addons:/data \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/home-assistant/amd64-builder \
  --target /data/cleanuparr \
  --amd64 \
  --test
```

### Local Testing

To test the add-on locally:

```bash
# Build the add-on
docker build \
  --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:3.20" \
  -t local/cleanuparr \
  /path/to/cleanuparr

# Run the add-on
docker run \
  --rm \
  -it \
  -p 11011:11011 \
  -v /tmp/test-config:/config \
  local/cleanuparr
```

## License

This add-on is licensed under the Apache License 2.0.

## Credits

- **Cleanuparr:** [Cleanuparr Project](https://github.com/Cleanuparr/Cleanuparr)
- **Home Assistant Add-ons:** [Home Assistant](https://www.home-assistant.io)
