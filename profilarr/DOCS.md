# Profilarr Documentation

## Overview

Profilarr is a profile management tool for *arr applications (Sonarr, Radarr, Lidarr). It allows you to manage, version control, and synchronize your custom formats and quality profiles across multiple *arr applications with Git integration.

## Setup Instructions

### 1. Installation

1. Navigate to **Settings** > **Add-ons** > **Add-on Store**
2. Add this add-on repository to Home Assistant
3. Find "Profilarr" in the add-on store
4. Click **Install**

### 2. Configuration

After installation, configure the add-on options:

| Option | Default | Description |
|--------|---------|-------------|
| **Log Level** | `info` | The log level for the application (trace, debug, info, notice, warning, error, fatal) |
| **Timezone** | `UTC` | The timezone for the application (e.g., "America/New_York", "Europe/London") |
| **Git User Name** | `Profilarr` | Git user name for commits |
| **Git User Email** | `profilarr@dictionarry.com` | Git user email for commits |

### 3. Starting the Add-on

1. Click **Start** on the add-on page
2. Access the web UI via the sidebar ("Profilarr" link)

## Integration with *arr Applications

### Adding an *arr Application

1. Open the Profilarr web UI
2. Navigate to **Settings** > **ARR Applications**
3. Add your Sonarr, Radarr, or Lidarr instance:
   - **Name**: A friendly name for the instance
   - **URL**: The URL of your *arr application (e.g., `http://sonarr:8989`)
   - **API Key**: The API key from your *arr application settings

### Importing Profiles

1. Navigate to **Import** in the Profilarr UI
2. Select the source *arr application
3. Choose the profiles and custom formats to import
4. Configure import options
5. Start the import

### Git Integration

Profilarr includes full Git integration for version control:

1. **Clone a Repository**: Clone an existing Git repository to store your profiles
2. **Commit Changes**: Commit profile changes to Git
3. **Push/Pull**: Synchronize changes with remote repositories
4. **Branch Management**: Create and switch between branches

## Configuration Options

### Log Level

Controls the verbosity of application logs:
- `trace`: Most detailed logging
- `debug`: Detailed debugging information
- `info`: General informational messages (default)
- `notice`: Normal but significant conditions
- `warning`: Warning messages
- `error`: Error conditions
- `fatal`: Critical conditions

### Timezone

Sets the timezone for the application. Use IANA timezone database format (e.g., `America/New_York`, `Europe/London`, `Asia/Tokyo`).

### Git Configuration

Sets the default Git user name and email for commits made through Profilarr.

## Storage

The add-on stores data in the following locations:

- **Configuration**: `/addon_configs/profilarr/`
- **Database**: SQLite database stored in the config directory
- **Profiles**: Custom format and profile definitions
- **Logs**: Application and import logs

## Troubleshooting

### Add-on Won't Start

1. Check the add-on logs for error messages
2. Verify the configuration options are valid
3. Ensure sufficient disk space is available

### Cannot Connect to *arr Application

1. Verify the *arr application is running
2. Check the URL is correct (use internal container names if both are add-ons)
3. Verify the API key is valid
4. Check network connectivity between containers

### Git Operations Failing

1. Verify Git credentials are correct
2. For HTTPS URLs, ensure the Personal Access Token is valid
3. For SSH URLs, ensure SSH keys are properly configured
4. Check the repository URL is correct

### Import Errors

1. Verify the *arr application API is accessible
2. Check the log files in the Profilarr UI
3. Ensure the target profiles exist in the *arr application

## Logs

View the add-on logs in Home Assistant:
1. Navigate to **Settings** > **Add-ons**
2. Click on "Profilarr"
3. Click **Logs**

Or view logs within the Profilarr web UI under **Logs**.

## Security

- The add-on runs with a custom AppArmor profile for security
- Ingress is enabled for secure Home Assistant UI integration
- Only connections from Home Assistant Ingress (172.30.32.2) are allowed
- API keys should be stored securely in the *arr applications

## Advanced Configuration

### External Configuration File

You can provide an external configuration file at `/addon_configs/profilarr/config.yml` for advanced settings.

### Environment Variables

The following environment variables are available for advanced configuration:

- `FLASK_ENV`: Set to `production` (default)
- `LOG_LEVEL`: Override the configured log level
- `TZ`: Override the configured timezone
- `GIT_USER_NAME`: Override the configured Git user name
- `GIT_USER_EMAIL`: Override the configured Git user email

## Support

For issues, feature requests, or contributions:
- GitHub: [https://github.com/rigerc/home-assistant-addons](https://github.com/rigerc/home-assistant-addons)
