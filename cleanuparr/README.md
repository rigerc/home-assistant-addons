# Cleanuparr

Automated cleanup for Sonarr, Radarr, Lidarr, Readarr, and Whisparr downloads.

## About

Cleanuparr helps maintain a clean download queue by automatically removing:
- Stalled downloads
- Slow downloads (based on speed threshold)
- Failed imports (when *arr apps can't import files)
- Completed torrents after specified seeding time
- Orphaned downloads (for cross-seed setups)
- Known malware torrents

## Features

- **Strike System**: Mark bad downloads and remove after max strikes
- **Queue Cleaning**: Remove failed imports and stalled downloads
- **Slow Download Removal**: Remove downloads below speed threshold
- **Seeding Cleanup**: Remove completed torrents after ratio/time
- **Malware Blocker**: Auto-remove known malware torrents
- **Notification Support**: Apprise, Discord, Notifiarr, ntfy, Pushover, Telegram
- **Cross-seed Support**: Detect and handle orphaned downloads
- **Automatic Search**: Trigger search for deleted items in *arr apps

## Installation

1. Add this repository to Home Assistant
2. Install the add-on from the add-on store
3. Start the add-on
4. Open the web UI to configure your download clients and *arr apps

## Configuration

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| log_level | No | info | Log level (trace, debug, info, notice, warning, error, fatal) |

> **Note:** The web interface port (default: 11011) is configured through the add-on's port mapping settings.

## Support

For issues and questions, please visit [Cleanuparr GitHub](https://github.com/Cleanuparr/Cleanuparr).
