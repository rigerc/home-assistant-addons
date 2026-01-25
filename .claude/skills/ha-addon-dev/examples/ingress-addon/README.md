# Ingress Example Add-on

Example Home Assistant add-on demonstrating Ingress integration for seamless web UI access.

## Features

- **Ingress enabled** - Access through Home Assistant UI without exposing ports
- **Nginx web server** - Efficient static file serving
- **IP restriction** - Only accepts connections from Ingress proxy (172.30.32.2)
- **User authentication** - Handled automatically by Home Assistant
- **Security bonus** - +2 security rating from Ingress

## Configuration

```yaml
greeting: "Welcome to Ingress!"
```

## Installation

This is an example add-on. To use:

1. Copy this directory to your local add-ons folder
2. Refresh the add-on store
3. Install and start the add-on
4. Click "OPEN WEB UI" in the add-on info page
5. Access the add-on seamlessly within Home Assistant

## What This Example Demonstrates

### Ingress Configuration

**config.yaml:**
- `ingress: true` - Enable Ingress feature
- `ingress_port: 8099` - Internal port (not exposed to host)
- `panel_icon` - Icon shown in Home Assistant sidebar
- `panel_title` - Title shown in sidebar

### Security Implementation

**ingress.conf:**
```nginx
server {
    listen 8099;
    allow  172.30.32.2;  # Only Ingress proxy
    deny   all;          # Deny everyone else
}
```

This ensures only the Ingress proxy can access the add-on, providing authentication through Home Assistant.

### Benefits Over Exposed Ports

1. **No port conflicts** - Internal port only
2. **No port forwarding** - Works behind NAT
3. **Unified authentication** - Uses Home Assistant users
4. **Better UX** - Seamless integration
5. **Higher security rating** - +2 points

## Usage

After installation:

1. Add-on appears in Home Assistant sidebar (if `panel_admin: true`)
2. Click the panel icon or use "OPEN WEB UI" button
3. Web interface loads within Home Assistant
4. User is already authenticated

## Available Headers

Ingress provides these headers to identify the authenticated user:

- `X-Ingress-Path` - Base URL path for the add-on
- `X-Remote-User-Id` - User ID
- `X-Remote-User-Name` - Username
- `X-Remote-User-Display-Name` - Display name

Access these in your application to personalize the experience or implement authorization.

## Advanced Features

### Dynamic Content

Modify `run.sh` to generate dynamic pages based on:
- Configuration options
- Ingress headers
- Add-on data

### WebSocket Support

Ingress supports WebSockets for real-time communication:

```javascript
const ws = new WebSocket('ws://' + window.location.host + '/ws');
```

### Path Handling

Use `X-Ingress-Path` header to construct correct URLs:

```nginx
location / {
    proxy_set_header X-Ingress-Path $http_x_ingress_path;
    # Your proxy configuration
}
```

## Security Considerations

1. **Always restrict to 172.30.32.2** - Critical for security
2. **Trust Ingress headers** - They're validated by Supervisor
3. **Don't add additional auth** - Home Assistant handles it
4. **Use HTTPS** - Home Assistant handles SSL

## Troubleshooting

**"Cannot connect" error:**
- Check nginx is listening on port 8099
- Verify `allow 172.30.32.2` in nginx config
- Check add-on logs for errors

**Web UI not appearing:**
- Ensure `ingress: true` in config.yaml
- Restart add-on after config changes
- Check Supervisor logs

**Authentication issues:**
- Ingress handles auth automatically
- Don't add login forms
- Use Ingress headers for user info
