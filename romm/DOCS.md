# Romm - ROM Collection Manager

Romm (ROM Manager) is a self-hosted web-based
ROM collection manager and emulator launcher.

## Network Configuration

### Access Methods

The add-on supports two access methods:

1. **Ingress (Default)** - Access through Home Assistant UI:
   - Navigate to **Settings > Add-ons > Romm** and click "Open Web UI"
   - Or use the sidebar icon if added
   - Seamlessly integrated with Home Assistant authentication

2. **Direct Port Access** (Optional):
   - Configure port 5999 in the add-on configuration
   - Access via `http://YOUR_HA_IP:5999`
   - Useful for external reverse proxies or direct access

### Port Configuration

To enable direct port access:
1. Go to **Settings > Add-ons > Romm > Configuration**
2. Under "Network", change port 5999 from "Disabled" to "5999"
3. Restart the add-on

### Security Recommendations

When using direct port access:

1. **Internal Network Only**: Only expose on trusted internal networks
2. **Reverse Proxy**: Use Traefik, nginx Proxy Manager, or similar with authentication layer
3. **Authentication Proxy**: Consider Authelia, Keycloak, or similar for SSO
4. **HTTPS**: Use valid SSL certificates via reverse proxy
5. **Firewall**: Restrict access using firewall rules or VLAN isolation
6. **Strong Passwords**: Use strong passwords for ROMM user accounts

### Reverse Proxy Example (Traefik)

If using Traefik as a reverse proxy with authentication:

```yaml
http:
  routers:
    romm:
      rule: "Host(`romm.yourdomain.com`)"
      service: romm
      middlewares:
        - authelia  # Or your authentication middleware
      tls:
        certResolver: letsencrypt
  services:
    romm:
      loadBalancer:
        servers:
          - url: "http://YOUR_HA_IP:5999"
```

### Reverse Proxy Example (nginx Proxy Manager)

1. Create a new Proxy Host
2. Set Domain Name: `romm.yourdomain.com`
3. Set Scheme: `http`
4. Set Forward Hostname/IP: `YOUR_HA_IP`
5. Set Forward Port: `5999`
6. Enable SSL (recommended)
7. Enable "Force SSL"
8. Optionally add Access List for authentication

## Features

- Scan and organize ROM collections across 400+ platforms
- Automatic metadata fetching from IGDB, ScreenScraper, RetroAchievements, and more
- Custom artwork from SteamGridDB
- In-browser gameplay via EmulatorJS and RuffleRS
- Multi-disk games, DLCs, mods, and patches support
- User management with permission-based access control

## Prerequisites

### MariaDB Database

Romm requires a MariaDB/MySQL database. You must have access to a
MariaDB instance before installing this add-on.

Options:

1. Install a MariaDB add-on from the Home Assistant Add-on Store
2. Use an external MariaDB server on your network
3. Use a cloud-hosted MySQL database

## Configuration

### Required Settings

- **Database Host**: Hostname or IP address of your MariaDB server
- **Database Password**: Password for the database user
- **Auth Secret Key**: Generate with `openssl rand -hex 32`

### Library Path

By default, Romm looks for ROMs in `/share/roms`. Organize your ROMs like:

```
/share/roms/
├── Nintendo 64/
│   ├── Super Mario 64.z64
│   └── Legend of Zelda, The - Ocarina of Time.z64
├── PlayStation/
│   ├── Final Fantasy VII (Disc 1).bin
│   ├── Final Fantasy VII (Disc 1).cue
│   └── ...
└── Game Boy Advance/
    └── Pokemon Emerald.gba
```

### Metadata Providers (Optional but Recommended)

Configure API keys for metadata providers to get rich game information:

- **ScreenScraper**: Register at <https://www.screenscraper.fr/>
- **RetroAchievements**: Get key at <https://retroachievements.org/>
- **SteamGridDB**: Get key at <https://www.steamgriddb.com/>
- **IGDB**: Register at <https://api-docs.igdb.com/>

Without IGDB credentials, some metadata features may not work properly.

## First Run Setup

1. Install and configure the add-on
2. Set required options:
   - Database connection (host, port, name, user, password)
   - Auth secret key (generate with: `openssl rand -hex 32`)
   - Library path (default: `/share/roms`)
3. Optional: Configure metadata provider API keys
4. Start the add-on
6. Open Web UI: `http://YOUR_HA_IP:5999` (or click "Open Web UI" button in add-on interface)
7. Complete setup wizard:
   - Create admin username and password
   - Configure library scan settings
8. Start scanning your ROM library

## Support

For Romm-specific issues, consult:

- Official documentation: <https://docs.romm.app/>
- GitHub repository: <https://github.com/rommapp/romm>

For add-on issues, report at: <https://github.com/rigerc/home-assistant-addons/issues>
