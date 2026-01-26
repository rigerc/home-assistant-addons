#!/usr/bin/with-contenv bashio

bashio::log.info "Creating app wrapper for static file serving..."

# Create a wrapper module that adds static file serving to the app
cat > /backend/app_wrapper.py << 'PYTHON_SCRIPT'
"""
Wrapper module for Romm app that adds static file serving.
This module imports the original app and mounts static files.
"""
import sys
import os
from pathlib import Path

# Import the original app
from main import app

# Try to configure static file serving
try:
    from fastapi.staticfiles import StaticFiles
    from fastapi.responses import RedirectResponse

    static_dir = Path("/var/www/html")
    if static_dir.exists():
        # Mount static files at /romm/ path (Ingress base path)
        app.mount("/romm", StaticFiles(directory=str(static_dir), html=True), name="static")

        # Add a redirect from root to /romm/
        @app.get("/")
        async def redirect_to_romm():
            return RedirectResponse(url="/romm/")

        print("[INFO] Static file serving configured at /romm/", file=sys.stderr)
    else:
        print(f"[WARNING] Static directory {static_dir} not found", file=sys.stderr)
except ImportError as e:
    print(f"[WARNING] Could not import StaticFiles: {e}", file=sys.stderr)
except Exception as e:
    print(f"[WARNING] Error configuring static files: {e}", file=sys.stderr)

# Export the app for gunicorn
# gunicorn will look for 'app' in this module
PYTHON_SCRIPT

bashio::log.info "App wrapper created"
