# Cleanuparr Add-on Documentation

## About

This add-on wraps [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr) for Home Assistant. Cleanuparr automates the cleanup of unwanted or blocked files in Sonarr, Radarr, and download clients.

## Quick Start

1. Install the add-on from the add-on store
2. Click "Start"
3. Open the web UI at `http://<home-assistant>:11011`
4. Configure your applications through the web UI

## Configuration Options

### Log Level
Controls logging verbosity.
**Options**: Trace, Debug, Information, Warning, Error, Fatal
**Default**: Information

### Dry Run
When enabled, logs all operations without making changes. Useful for testing your configuration before enabling live deletions.
**Default**: false

## Data Persistence

All configuration and database files are stored in `/config`, which is mapped to the add-on's configuration directory. Your settings persist across restarts and updates.

## Troubleshooting

### Add-on won't start
- Check the add-on logs in Home Assistant
- Ensure port 11011 is not in use by another service
- Try setting "Dry Run" to true to test configuration

### Can't access web UI
- Verify the add-on is running
- Check you're using the correct URL: `http://<home-assistant>:11011`
- Check Home Assistant Supervisor logs

### Downloads not being cleaned
- Verify your *arr app API keys are correct
- Ensure download client connection works
- Check Cleanuparr logs in the add-on
- Verify the feature is enabled in Cleanuparr web UI

## Support

For Cleanuparr-specific issues, see:
- [Official Documentation](https://cleanuparr.github.io/Cleanuparr/)
- [GitHub Issues](https://github.com/Cleanuparr/Cleanuparr/issues)
- [Discord](https://discord.gg/SCtMCgtsc4)
