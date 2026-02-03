# Profilarr V2

## About

Profilarr V2 is the next-generation configuration management platform for Radarr and Sonarr. It provides a centralized interface to manage quality profiles, custom formats, release profiles, and media management settings across multiple instances with Git-backed storage.

**What's New in V2:**
- Rebuilt from the ground up with improved performance
- Enhanced database management with GitHub integration
- Modern compiled binary architecture (Deno-based)
- Improved backup and restore capabilities
- Advanced job scheduling system
- Enhanced logging and debugging

## Installation

1. Navigate to the Supervisor panel in Home Assistant
2. Click on the Add-on Store tab
3. Add this repository if not already added
4. Find "Profilarr V2" in the list
5. Click on the add-on and then click "Install"

## Configuration

### Basic Options

**log_level** (optional, default: "info")
- Set logging verbosity: trace, debug, info, warning, or error
- Use "debug" for troubleshooting

**puid** (optional, default: 1000)
- User ID for file ownership
- Match this to your file system user if needed

**pgid** (optional, default: 1000)
- Group ID for file ownership
- Match this to your file system group if needed

**umask** (optional, default: "022")
- File creation mask (must be octal: 000-777)
- "022" = files: 644, directories: 755
- "002" = files: 664, directories: 775 (group writable)

### Example Configuration

```yaml
log_level: info
puid: 1000
pgid: 1000
umask: "022"
```

## Usage

### First Run

1. Start the add-on
2. Access via the web UI (sidebar panel) or direct port 6868
3. Complete the initial setup wizard
4. Connect your Radarr/Sonarr instances
5. Link to the Profilarr database (Dictionarry by default)

### Features

**Profile Management**
- Centrally manage quality profiles across all instances
- Sync custom formats from Git repositories
- Apply configurations to multiple instances simultaneously

**Database Integration**
- Auto-link to the official Dictionarry database
- Import community-maintained custom formats
- Create and share your own configurations

**Backup & Restore**
- Automatic daily backups
- Manual backup creation
- Restore from previous configurations

**Job Scheduling**
- Automatic database synchronization
- Scheduled profile updates
- Automated cleanup tasks

### Accessing Profilarr

**Via Home Assistant UI (Ingress)**
- Click the Profilarr icon in the sidebar
- Provides seamless integration with Home Assistant

**Direct Access**
- Navigate to `http://homeassistant.local:6868`
- Use this for external tools or automation

### Data Storage

All configuration and data is stored in:
- `/addon_config/profilarr-v2/` - Mapped to add-on config directory
- Subdirectories:
  - `data/` - Application database and runtime data
  - `logs/` - Application logs
  - `backups/` - Automatic and manual backups
  - `databases/` - Linked Git database repositories

## Troubleshooting

### Add-on won't start

1. Check the add-on logs in Home Assistant
2. Verify configuration values are valid
3. Ensure sufficient disk space for databases
4. Set log_level to "debug" for detailed output

### Permission issues

If you encounter permission errors:
1. Check PUID/PGID match your system
2. Verify the config directory is writable
3. Try umask "002" for group write access

### Database sync failing

1. Ensure internet connectivity
2. Check GitHub access (default database is public)
3. Review logs for specific Git errors
4. Verify SSH keys if using private repositories

### Ingress not working

1. Confirm ingress is enabled in config.yaml
2. Restart the add-on after configuration changes
3. Check for conflicts with other add-ons using ingress

## Migration from V1

Profilarr V2 uses a different architecture than V1. To migrate:

1. **Export your V1 configuration** via the V1 backup feature
2. **Install Profilarr V2** as a separate add-on
3. **Complete V2 setup** and connect your instances
4. **Manually recreate configurations** (direct migration not supported)
5. **Keep V1 running** until V2 is fully configured and tested

V1 and V2 can run side-by-side during transition.

## Support

- GitHub Issues: https://github.com/Dictionarry-Hub/profilarr/issues
- Documentation: https://github.com/Dictionarry-Hub/profilarr
- Add-on Repository: https://github.com/rigerc/home-assistant-addons

## License

AGPL-3.0 - See upstream repository for details
