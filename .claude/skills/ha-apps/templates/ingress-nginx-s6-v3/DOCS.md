# My Application

## Configuration

### Log Level
Controls the verbosity of the application logs.

- **trace** - Extremely verbose debugging
- **debug** - Debugging information
- **info** - General information (default)
- **warning** - Warning messages only
- **error** - Error messages only

### SSL (Optional)
Enable SSL for direct port access. Note: Ingress always uses SSL through Home Assistant.

When enabled, you must provide:
- **Certificate File** - Filename in `/ssl/` (e.g., `fullchain.pem`)
- **Key File** - Filename in `/ssl/` (e.g., `privkey.pem`)

## Access

### Ingress (Recommended)
Access the add-on through the Home Assistant sidebar.
- URL: `https://your-hassio-url/api/hassio_ingress/...`
- Single sign-on with Home Assistant
- No additional configuration needed

### Direct Port
Access the add-on directly on port 8080.
- URL: `http://your-hassio-url:8080`
- Requires port forwarding if accessing externally
- Can be secured with SSL using the SSL option above

## Usage

1. Start the add-on from the Home Assistant add-on store
2. Click "Open Web UI" in the sidebar or use the ingress URL
3. Configure your application settings as needed

## Support

For issues and feature requests, please visit:
https://github.com/yourusername/ha-addons/issues
