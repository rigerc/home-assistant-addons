# Profilarr Home Assistant Add-on

## Overview

Profilarr is a profile manager for Radarr and Sonarr instances that enables centralized management of quality profiles, custom formats, and release profiles across multiple *arr instances. With Git-backed configuration storage, you can version control your media server configurations and easily replicate them across environments.

## Features

- Centralized profile management for Radarr and Sonarr
- Quality profiles, custom formats, and release profiles management
- Git-backed configuration storage for version control
- Web-based UI for easy configuration
- API access for automation
- Multiple authentication modes for different security requirements

## Installation

1. Navigate to the Supervisor panel in Home Assistant
2. Click on the Add-on Store tab
3. Click the menu icon in the top right and select "Repositories"
4. Add this repository URL: `https://github.com/rigerc/home-assistant-addons`
5. Find "Profilarr" in the list
6. Click on the add-on and then click "Install"

## Configuration

### Authentication Mode

- **on** (default): Full authentication required for all access
- **local**: No authentication required for local network access
- **oidc**: OpenID Connect authentication
- **off**: No authentication (not recommended for production)

### Log Level

Controls the verbosity of log output:
- **trace**: Most verbose, shows all details
- **debug**: Detailed information for troubleshooting
- **info** (default): Normal operation logging
- **warning**: Only warnings and errors
- **error**: Only error messages

### Example Configuration

```yaml
auth_mode: "local"
log_level: "info"
```

## Usage

### Accessing the Web UI

After starting the add-on, you can access Profilarr in two ways:

1. **Via Ingress** (recommended): Click "Open Web UI" in the add-on info page or use the sidebar panel
2. **Direct access**: Navigate to `http://homeassistant.local:6868` (or your Home Assistant IP)

### Initial Setup

1. Start the add-on and access the web UI
2. Configure your Git repository for storing Profilarr configurations
3. Add your Radarr and Sonarr instances:
   - Navigate to Settings
   - Add each *arr instance with its URL and API key
4. Begin managing profiles across your instances

### Managing Profiles

1. **Quality Profiles**: Define and sync quality settings across instances
2. **Custom Formats**: Create custom format rules and apply them globally
3. **Release Profiles**: Manage release profile preferences

All changes are committed to your configured Git repository, providing version control and backup.

## Data Storage

Profilarr stores its data in the add-on configuration directory:
- `/addon_config/profilarr/config/` - Application configuration and database
- `/share/` - Accessible for Git repository storage

## API Access

Profilarr provides an API for automation. Access it at:
- Via Ingress: Use the Home Assistant ingress URL
- Direct: `http://homeassistant.local:6868/api`

API keys can be generated from the web UI settings.

## Troubleshooting

### Add-on fails to start

1. Check the add-on logs for error messages
2. Verify your configuration is valid
3. Ensure no port conflicts with other add-ons

### Cannot access Web UI

1. Verify the add-on is running (check status)
2. Try accessing via Ingress first
3. If using direct access, ensure port 6868 is not blocked by firewall

### Git repository sync issues

1. Verify Git repository credentials are correct
2. Check network connectivity to Git server
3. Review logs for specific error messages

### Authentication issues

- If locked out, temporarily set `auth_mode: "off"` to regain access
- Remember to re-enable authentication after fixing the issue

## Support

For issues and feature requests, please visit:
- [GitHub Repository](https://github.com/rigerc/home-assistant-addons)
- [Profilarr Upstream](https://github.com/Dictionarry-Hub/profilarr)

## Credits

This add-on wraps the excellent [Profilarr](https://github.com/Dictionarry-Hub/profilarr) project by santiagosayshey.
