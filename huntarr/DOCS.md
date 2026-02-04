# Huntarr Add-on Documentation

Huntarr is an automation utility that continuously searches your media libraries for missing content and quality upgrades. It works with Sonarr, Radarr, Lidarr, Readarr, Whisparr v2, and Whisparr v3 to systematically identify gaps in your media collections and automatically trigger searches.

## Features

- **Automatic Content Discovery**: Continuously scans your media libraries for missing items
- **Quality Upgrades**: Identifies content below your quality thresholds and triggers searches for better versions
- **Multi-Application Support**: Works with Sonarr, Radarr, Lidarr, Readarr, and Whisparr (v2/v3)
- **Web Interface**: Easy-to-use configuration and monitoring dashboard
- **Customizable Settings**: Adjust scan intervals, quality criteria, and more

## Configuration

### Options

- **log_level** (optional): Set the logging verbosity
  - `trace`: Most verbose, useful for deep debugging
  - `debug`: Detailed debugging information
  - `info`: Normal operational messages (default)
  - `warning`: Warning messages only
  - `error`: Error messages only

## Initial Setup

1. Install the add-on
2. Start the add-on
3. Access the web interface through the sidebar or via direct port 9705
4. Configure your *arr applications:
   - Add your Sonarr instance(s)
   - Add your Radarr instance(s)
   - Add any other supported applications (Lidarr, Readarr, Whisparr)
5. Configure search settings:
   - Set scan intervals
   - Define quality thresholds
   - Customize search behavior

## Usage

Once configured, Huntarr will automatically:
1. Scan your media libraries on the configured schedule
2. Identify missing content
3. Identify content below quality thresholds
4. Trigger searches in your *arr applications
5. Display activity and statistics in the web interface

## Web Interface

Access the Huntarr web interface through:
- **Ingress**: Use the sidebar panel in Home Assistant (recommended)
- **Direct Access**: Navigate to `http://homeassistant.local:9705`

## Troubleshooting

### Add-on won't start

1. Check the add-on logs for error messages
2. Verify all required configuration options are set
3. Ensure you have sufficient disk space

### Can't connect to *arr applications

1. Verify the *arr application is running and accessible
2. Check that you're using the correct API key
3. Ensure the hostname/IP and port are correct
4. Verify network connectivity between Huntarr and the *arr application

### Missing features or unexpected behavior

1. Check the Huntarr logs for warnings or errors
2. Verify your configuration settings
3. Consult the official Huntarr documentation at https://plexguide.github.io/Huntarr.io/

## Support

For issues, questions, or feature requests:
- Official Documentation: https://plexguide.github.io/Huntarr.io/
- GitHub Repository: https://github.com/plexguide/Huntarr.io
