# Cleanuparr - Documentation

## Overview

Cleanuparr is a powerful automation tool for maintaining clean download queues in media management systems. It integrates with Sonarr, Radarr, Lidarr, Readarr, and Whisparr to automatically remove unwanted downloads.

## Installation

[![Open your Home Assistant instance and show the add-on store.](https://my.home-assistant.io/badges/supervisor_store.svg)](https://my.home-assistant.io/redirect/supervisor_store/)

1. In Home Assistant, go to **Settings** > **Add-ons** > **Add-on Store**
2. Click the three dots menu and select "Add new repository"
3. Enter: `https://github.com/rigerc/home-assistant-addons`
4. Find and install "Cleanuparr"

## Configuration

### Basic Configuration

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| log_level | select | No | info | Log level (trace, debug, info, notice, warning, error, fatal) |

**Port Configuration:** The web interface port (default: 11011) is configured through the add-on's port mapping settings, not via options. You can change the port mapping in the add-on configuration panel.

## Usage

### Getting Started

After installation and configuration:

1. Start the add-on
2. Open the web UI (click "Open Web UI" in the add-on info panel)
3. Configure your download clients:
   - qBittorrent
   - Transmission
   - Deluge
   - µTorrent
4. Configure your *arr applications:
   - Sonarr
   - Radarr
   - Lidarr
   - Readarr
   - Whisparr
5. Set up cleaning rules and schedules
6. Configure notifications (optional)

### Key Features

**Queue Cleaner**
- Removes downloads that fail to import
- Tracks strikes per download
- Removes stalled downloads
- Removes slow downloads based on speed threshold

**Download Cleaner**
- Cleans up completed torrents after seeding
- Removes unlinked/orphaned downloads (cross-seed support)
- Supports ratio and time-based cleanup rules

**Malware Blocker**
- Auto-updates malware patterns every 5 minutes
- Blocks known malware torrents
- Supports custom blocklists (URL or file)

**Notifications**
- Apprise (supports 80+ notification services)
- Discord
- Notifiarr
- ntfy
- Pushover
- Telegram
- Custom webhooks

## Configuration File

Cleanuparr stores its configuration in `/config/cleanuparr/config.json`. The web UI provides a full interface for configuring all options, but you can also edit the JSON directly.

### Example Configuration

```json
{
  "displayBanner": true,
  "dryRun": false,
  "downloadClients": [
    {
      "enabled": true,
      "name": "qBittorrent",
      "type": "qBittorrent",
      "host": "http://192.168.1.100:8080",
      "username": "admin",
      "password": "your-password"
    }
  ],
  "apps": [
    {
      "enabled": true,
      "name": "Radarr",
      "type": "Radarr",
      "host": "http://192.168.1.100:7878",
      "apiKey": "your-api-key"
    }
  ],
  "queueCleaner": {
    "enabled": true,
    "scheduleMode": "Interval",
    "intervalMinutes": 30,
    "failedImports": {
      "enabled": true,
      "maximumStrikes": 3
    }
  }
}
```

## Troubleshooting

### Add-on won't start

Check the logs:
1. Go to the add-on page
2. Click the "Logs" tab
3. Look for error messages

### Common Issues

**Issue:** Cannot connect to download client
**Solution:** Verify the host URL and credentials are correct. Check if the add-on can reach your download client (same network, correct port).

**Issue:** Downloads not being cleaned
**Solution:** Check if you have enabled the cleaner modules and configured rules correctly. Try enabling dry run mode first to see what would be cleaned.

**Issue:** Configuration not saving
**Solution:** Check that the `/config` directory has write permissions. Restart the add-on and try again.

## Development

For development information, see the [Cleanuparr GitHub repository](https://github.com/Cleanuparr/Cleanuparr).

## Support

- **Issues:** [GitHub Issues](https://github.com/Cleanuparr/Cleanuparr/issues)
- **Discussions:** [GitHub Discussions](https://github.com/Cleanuparr/Cleanuparr/discussions)
- **Documentation:** [Cleanuparr Docs](https://cleanuparr.com)

## License

This add-on is licensed under the [MIT License](LICENSE). Cleanuparr is also licensed under the MIT License.
