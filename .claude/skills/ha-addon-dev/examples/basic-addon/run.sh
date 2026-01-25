#!/usr/bin/with-contenv bashio

# Parse configuration
MESSAGE=$(bashio::config 'message')
PORT=$(bashio::config 'port')

bashio::log.info "Starting Basic Example Add-on"
bashio::log.info "Message: ${MESSAGE}"
bashio::log.info "Port: ${PORT}"

# Create a simple index.html with the message
cat > /share/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Basic Add-on Example</title>
</head>
<body>
    <h1>${MESSAGE}</h1>
    <p>This is a basic Home Assistant add-on example.</p>
    <p>Configuration can be changed in the add-on configuration page.</p>
</body>
</html>
EOF

# Start Python HTTP server
bashio::log.info "Starting HTTP server on port ${PORT}"
exec python3 -m http.server "${PORT}"
