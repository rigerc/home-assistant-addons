# Basic Example Add-on

Minimal working Home Assistant add-on that serves a simple web page.

## Features

- User-configurable message
- User-configurable port
- Serves files from `/share` directory
- Demonstrates bashio configuration parsing
- Shows basic logging patterns

## Configuration

```yaml
message: "Hello from Home Assistant!"
port: 8000
```

## Installation

This is an example add-on. To use:

1. Copy this directory to your local add-ons folder
2. Refresh the add-on store
3. Install and start the add-on
4. Navigate to `http://homeassistant.local:8000`

## What This Example Demonstrates

- Basic `config.yaml` structure with required fields
- Simple `Dockerfile` extending Home Assistant base images
- Configuration parsing with bashio in `run.sh`
- Logging with bashio
- Port exposure
- Directory mapping (`share`)
- Options and schema validation
