# Romm - ROM Collection Manager

Romm (ROM Manager) is a self-hosted web-based ROM collection manager and emulator launcher.

## Features

- Scan and organize ROM collections across 400+ platforms
- Automatic metadata fetching from IGDB, ScreenScraper, RetroAchievements, and more
- Custom artwork from SteamGridDB
- In-browser gameplay via EmulatorJS and RuffleRS
- Multi-disk games, DLCs, mods, and patches support
- User management with permission-based access control

## Prerequisites

### MariaDB Database

Romm requires a MariaDB/MySQL database. You must have access to a MariaDB instance before installing this add-on.

Options:
1. Install a MariaDB add-on from the Home Assistant Add-on Store
2. Use an external MariaDB server on your network
3. Use a cloud-hosted MySQL database

**Required database setup:**
```sql
CREATE DATABASE romm;
CREATE USER 'romm-user'@'%' IDENTIFIED BY 'your-secure-password';
GRANT ALL PRIVILEGES ON romm.* TO 'romm-user'@'%';
FLUSH PRIVILEGES;
```

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

- **ScreenScraper**: Register at https://www.screenscraper.fr/
- **RetroAchievements**: Get key at https://retroachievements.org/
- **SteamGridDB**: Get key at https://www.steamgriddb.com/
- **IGDB**: Register at https://api-docs.igdb.com/

Without IGDB credentials, some metadata features may not work properly.

## First Run

1. Install the add-on
2. Configure database connection
3. Set auth secret key
4. Start the add-on
5. Open the Web UI (via sidebar or Ingress)
6. Complete setup wizard with admin username/password
7. Start scanning your ROM library

## Support

For Romm-specific issues, consult:
- Official documentation: https://docs.romm.app/
- GitHub repository: https://github.com/rommapp/romm

For add-on issues, report at: https://github.com/rigerc/home-assistant-addons/issues
