# Profilarr Home Assistant Add-on

Profile management for *arr applications (Sonarr, Radarr, Lidarr).

Profilarr allows you to manage, version control, and synchronize your custom formats and quality profiles across multiple *arr applications with Git integration.

## Features

- Profile management for Sonarr, Radarr, and Lidarr
- Git-based version control for configurations
- Import/Export functionality
- Background task scheduling
- SQLite database for local storage
- Web-based UI

## Installation

1. Add this add-on repository to Home Assistant
2. Install the "Profilarr" add-on from the add-on store
3. Configure the add-on options
4. Start the add-on
5. Access the web UI via the sidebar

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| Log Level | `info` | The log level for the application |
| Timezone | `UTC` | The timezone for the application |
| Git User Name | `Profilarr` | Git user name for commits |
| Git User Email | `profilarr@dictionarry.com` | Git user email for commits |

## Support

For issues and feature requests, please visit the [GitHub repository](https://github.com/rigerc/home-assistant-addons).
