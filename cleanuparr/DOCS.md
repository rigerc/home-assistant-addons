# Cleanuparr Add-on Documentation

## About

Cleanuparr is an automated tool for managing downloads in your *arr ecosystem (Sonarr, Radarr, Lidarr, Readarr, Whisparr). It removes unwanted, stalled, failed, or malicious downloads and can automatically search for replacements.

### Key Features

- **Strike System** - Track problematic downloads with configurable thresholds
- **Failed Import Handling** - Remove downloads that fail to import into *arr apps
- **Stalled Detection** - Remove downloads that have stopped progressing
- **Slow Download Management** - Remove downloads with poor performance
- **Malware Blocking** - Block known malicious file patterns (`.lnk`, `.zipx`, etc.)
- **Automatic Search** - Trigger replacement searches after removal
- **Seeding Cleanup** - Remove completed torrents after meeting criteria
- **Orphaned Detection** - Remove downloads no longer tracked by *arr apps
- **Cross-Seed Support** - Compatible with cross-seed workflows
- **Notifications** - Alert on strikes and removals via multiple services

## Installation

### Adding the Repository

1. Navigate to **Supervisor** → **Add-on Store** in Home Assistant
2. Click the menu (⋮) in the top right → **Repositories**
3. Add this repository URL:
   ```
   https://github.com/your-username/ha-addons
   ```
4. Find **Cleanuparr** in the **Local Add-ons** section
5. Click **Install**

### First Run

1. After installation, click **Start**
2. The add-on will start in **Dry Run** mode (safe testing)
3. Click **Open Web UI** to access the interface
4. Configure your *arr applications and download clients (see below)
5. Monitor the logs to see what would be cleaned
6. When satisfied, disable **Dry Run** and restart

## Configuration

### Add-on Options

Configure these options in the add-on configuration panel:

#### Application Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `log_level` | Select | `info` | Logging verbosity (trace to fatal) |
| `dry_run` | Boolean | `true` | Enable test mode (no actual deletions) |
| `display_support_banner` | Boolean | `true` | Show support links on dashboard |

#### HTTP Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `http_max_retries` | Integer | `3` | HTTP request retry attempts (0-10) |
| `http_timeout` | Integer | `30` | HTTP request timeout in seconds (5-120) |
| `http_certificate_validation` | Select | `enabled_for_local_addresses` | SSL certificate validation mode |

#### Search Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `search_enabled` | Boolean | `true` | Auto-search for replacements |
| `search_delay` | Integer | `5` | Delay before searching in seconds (0-60) |

#### Logging Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `log_rolling_size_mb` | Integer | `10` | Max log file size in MB (1-100) |
| `log_retained_file_count` | Integer | `5` | Number of logs to keep (1-50) |
| `log_time_limit_hours` | Integer | `24` | Max log age in hours (1-168) |
| `log_archive_enabled` | Boolean | `true` | Archive old logs instead of deleting |
| `log_archive_retained_count` | Integer | `3` | Number of archives to keep (1-20) |
| `log_archive_time_limit_days` | Integer | `30` | Max archive age in days (1-365) |

### Arr Instances Configuration

Configure your *arr applications through the web UI:

1. Navigate to **Arr Instances** in the sidebar
2. Click **+ Add Arr Instance**
3. Fill in the required fields:

#### Connection Settings

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Descriptive name for this instance | "Main Radarr" |
| **Type** | Application type | Radarr |
| **URL** | Connection URL | `http://homeassistant:7878` |
| **API Key** | API key from *arr settings | `abc123...` |

#### Finding Your API Key

1. Open your *arr application (Sonarr, Radarr, etc.)
2. Navigate to **Settings** → **General**
3. Scroll to **Security** → **API Key**
4. Click the clipboard icon to copy

#### URL Examples

For *arr applications running on the same Home Assistant system:

- Sonarr: `http://homeassistant:8989`
- Radarr: `http://homeassistant:7878`
- Lidarr: `http://homeassistant:8686`
- Readarr: `http://homeassistant:8787`
- Whisparr: `http://homeassistant:6969`

For *arr applications on different systems, use the local IP:

- `http://192.168.1.100:8989`

### Download Clients Configuration

Configure your download clients through the web UI:

1. Navigate to **Download Clients** in the sidebar
2. Click **+ Add Download Client**
3. Fill in the required fields:

#### qBittorrent

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Descriptive name | "Main qBittorrent" |
| **Type** | qBittorrent | |
| **URL** | Connection URL | `http://homeassistant:8080` |
| **Username** | qBittorrent username | `admin` |
| **Password** | qBittorrent password | `yourpassword` |

#### Deluge

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Descriptive name | "Main Deluge" |
| **Type** | Deluge | |
| **URL** | Connection URL | `http://homeassistant:8112` |
| **Password** | Deluge password | `yourpassword` |

#### Transmission

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Descriptive name | "Main Transmission" |
| **Type** | Transmission | |
| **URL** | Connection URL | `http://homeassistant:9091` |
| **Username** | Transmission username | (optional) |
| **Password** | Transmission password | (optional) |

## Feature Configuration

### Queue Cleaner

Removes downloads from *arr queues based on configurable rules.

#### Stalled Rule

Remove downloads that have stopped progressing:

- **Enable:** Toggle to enable this rule
- **Stalled Duration:** Minutes a download must be stalled (default: 30)
- **Threshold:** Number of checks before removal (default: 2)
- **Blocklist:** Add to *arr blocklist after removal

#### Slow Rule

Remove downloads with poor performance:

- **Enable:** Toggle to enable this rule
- **Minimum Speed:** KB/s threshold (default: 0)
- **Maximum ETA:** Maximum estimated completion time in minutes (default: 0)
- **Minimum Downloaded:** MB to check before applying (default: 50)
- **Blocklist:** Add to *arr blocklist after removal

### Download Cleaner

Removes downloads directly from download clients.

#### Failed Imports Rule

Remove downloads failing to import into *arr:

- **Enable:** Toggle to enable this rule
- **Check Interval:** Minutes between checks (default: 60)
- **Remove From Client:** Delete from download client
- **Remove Data:** Delete data files

#### Seeding Rule

Remove completed torrents based on seeding criteria:

- **Enable:** Toggle to enable this rule
- **Seeding Time:** Minutes to seed before removal (default: 0)
- **Ratio:** Minimum ratio before removal (default: 0)
- **Remove From Client:** Delete from download client

#### Malware Blocker Rule

Block known malicious file patterns:

- **Enable:** Toggle to enable this rule
- **Blocked Patterns:** List of regex patterns to block
  - `\.lnk$` - Windows shortcut files
  - `\.zipx$` - Compressed archive files
  - `\.exe$` - Executable files
  - `\.scr$` - Screensaver files (often malware)

#### Ignore Patterns

Exclude specific downloads from all cleaning operations:

- **Hashes:** Torrent info hashes to ignore
- **Tags:** qBittorrent tags to ignore
- **Categories:** Categories/labels to ignore
- **Trackers:** Tracker domains to ignore

### Malware Blocker

Separate feature for blocking known malware patterns:

- **Enable:** Toggle to enable
- **Check URLs:** Check download URLs against malware patterns
- **Check Names:** Check release names against patterns
- **Blocked Patterns:** Community-maintained malware patterns

### Blacklist Sync

Synchronize blocklists between *arr applications:

- **Enable:** Toggle to enable
- **Sync Interval:** Minutes between syncs (default: 60)
- **Bidirectional:** Sync in both directions

## Notifications

Configure notifications for strikes and download removals.

### Notification Providers

Cleanuparr supports multiple notification services:

#### Discord

1. Create a Discord webhook
2. Enter webhook URL in Cleanuparr
3. Customize notification format

#### Telegram

1. Create a bot via @BotFather
2. Get your bot token
3. Create a chat ID
4. Enter token and chat ID in Cleanuparr

#### Notifiarr

1. Get your API key from Notifiarr
2. Enter API key in Cleanuparr
3. Select notification types

#### Ntfy

1. Choose an ntfy topic
2. Enter topic URL in Cleanuparr
3. Optionally add authentication

#### Pushover

1. Get your Pushover API key
2. Get your user key
3. Enter both keys in Cleanuparr

#### Apprise

1. Enter your Apprise URL
2. Supports many notification services

## Troubleshooting

### Add-on Issues

**Problem:** Add-on won't start

**Solutions:**
1. Check the **Logs** tab for error messages
2. Verify the configuration directory exists
3. Ensure the add-on has sufficient permissions
4. Try reinstalling the add-on

**Problem:** Add-on keeps restarting

**Solutions:**
1. Check if the port 11011 is already in use
2. Review logs for specific errors
3. Verify the configuration is valid
4. Check for resource issues (CPU, memory)

### Connection Issues

**Problem:** Can't connect to *arr application

**Solutions:**
1. Verify the *arr application is running
2. Check the URL is correct
3. Verify the API key is valid
4. Test with `curl`: `curl -H "X-Api-Key: YOUR_KEY" http://homeassistant:8989/api/v3/system/status`

**Problem:** Can't connect to download client

**Solutions:**
1. Verify the download client is running
2. Check the URL and port
3. Verify credentials
4. Check if the client has remote access enabled

### Configuration Issues

**Problem:** Settings not being applied

**Solutions:**
1. Restart the add-on after changing options
2. Check the logs for configuration errors
3. Verify the syntax of your configuration
4. Try resetting to defaults

**Problem:** Dry run mode not working

**Solutions:**
1. Verify **Dry Run** is enabled in add-on options
2. Restart the add-on
3. Check the logs for "Dry Run" messages

### Performance Issues

**Problem:** High CPU usage

**Solutions:**
1. Increase check intervals
2. Reduce the number of monitored items
3. Disable unused features
4. Check for infinite loops in custom rules

**Problem:** Slow response time

**Solutions:**
1. Increase HTTP timeout setting
2. Check network connectivity
3. Verify *arr applications are responsive
4. Reduce the number of concurrent connections

## Advanced Usage

### Cross-Seed Integration

Cleanuparr works with [cross-seed](https://www.cross-seed.org/):

1. Enable **Orphaned Detection** in Download Cleaner
2. Set appropriate thresholds
3. Cleanuparr will detect cross-seed downloads
4. Configure ignore patterns to protect cross-seed downloads

### Multiple *arr Instances

Cleanuparr supports multiple instances of each *arr type:

1. Add multiple Arr instances with different names
2. Each instance has independent configuration
3. Queue Cleaner monitors all instances

### Custom Blocklists

Create custom blocklists for specific use cases:

1. Navigate to **Download Cleaner** → **Malware Blocker**
2. Add custom regex patterns
3. Examples:
   - `\.rar$` - Block RAR archives
   - `-x264\b` - Block x264 encodings
   - `-HDCAM\b` - Block CAM releases

### Import/Export Configuration

Backup and restore your Cleanuparr configuration:

1. Navigate to **Settings** in the web UI
2. Click **Export Configuration** to download
3. Save the JSON file
4. To restore, click **Import Configuration**

## Best Practices

### Initial Setup

1. **Start with Dry Run enabled** - Test your configuration safely
2. **Monitor logs** - Review what would be cleaned
3. **Adjust thresholds** - Fine-tune rules for your setup
4. **Gradually enable features** - Add features one at a time
5. **Disable Dry Run** - Only when satisfied with configuration

### Threshold Recommendations

| Feature | Recommended Starting Value |
|---------|---------------------------|
| Stalled Duration | 30 minutes |
| Slow Minimum Speed | 0 KB/s (disabled) |
| Slow Maximum ETA | 0 minutes (disabled) |
| Seeding Time | Based on tracker rules |
| Check Interval | 60 minutes |

### Safety Tips

1. **Test first** - Always use dry run mode initially
2. **Monitor closely** - Check logs frequently after enabling
3. **Use blocklists** - Add problematic downloads to blocklists
4. **Set appropriate thresholds** - Avoid false positives
5. **Keep backups** - Backup your *arr databases regularly

## Support

For additional help:

- **Documentation:** [cleanuparr.dev](https://cleanuparr.dev)
- **GitHub:** [Cleanuparr GitHub](https://github.com/Cleanuparr/Cleanuparr)
- **Discord:** [Cleanuparr Discord](https://discord.gg/SCtMCgtsc4)
- **Issues:** [Report bugs](https://github.com/Cleanuparr/Cleanuparr/issues)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
