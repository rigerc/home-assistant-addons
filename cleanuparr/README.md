# Cleanuparr Home Assistant Add-on

[Cleanuparr](https://github.com/Cleanuparr/Cleanuparr) automatically cleans up unwanted or blocked files in Sonarr, Radarr, and supported download clients like qBittorrent, Transmission, Deluge, and uTorrent.

## Features

- Strike system to mark bad downloads
- Remove downloads that fail to import in *arr apps
- Remove stalled or slow downloads
- Remove blocked or malicious downloads
- Automatically search for replacements
- Clean up completed torrents after seeding
- Remove orphaned downloads
- Notifications on strike or removal

## Installation

1. Add this repository to Home Assistant Supervisor
2. Install the "Cleanuparr" add-on
3. Start the add-on
4. Open the web interface at `http://<home-assistant>:11011`
5. Configure your *arr apps and download clients through the web UI

## Configuration

The add-on has minimal options since Cleanuparr is configured through its web interface:

- **Log Level**: Set logging verbosity (default: Information)
- **Dry Run**: Log operations without making changes (useful for testing)

All other configuration (API keys, URLs, cleanup rules, etc.) is done through the Cleanuparr web UI.

## Web Interface

After starting the add-on, access the web interface at:
```
http://<your-home-assistant-ip>:11011
```

## Supported Applications

- **Sonarr**, **Radarr**, **Lidarr**, **Readarr**, **Whisparr v2**
- **qBittorrent**, **Transmission**, **Deluge**, **uTorrent**

## Documentation

See the [official Cleanuparr documentation](https://cleanuparr.github.io/Cleanuparr/) for detailed configuration guides.
