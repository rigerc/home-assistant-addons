#!/usr/bin/with-contenv bashio

# Parse configuration
GREETING=$(bashio::config 'greeting')

bashio::log.info "Starting Ingress Example Add-on"
bashio::log.info "Greeting: ${GREETING}"

# Create index.html with greeting
cat > /share/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Ingress Example</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        h1 {
            color: #03a9f4;
        }
        .info {
            background: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>${GREETING}</h1>

    <div class="info">
        <h2>About Ingress</h2>
        <p>This add-on is accessed through Home Assistant's Ingress feature.</p>
        <p>Benefits:</p>
        <ul>
            <li>No need to expose ports</li>
            <li>Authentication handled by Home Assistant</li>
            <li>Seamless integration in the UI</li>
            <li>+2 security rating</li>
        </ul>
    </div>

    <div class="info">
        <h2>Technical Details</h2>
        <p><strong>Port:</strong> 8099 (internal, not exposed)</p>
        <p><strong>Allowed IP:</strong> 172.30.32.2 (Ingress proxy)</p>
        <p><strong>Server:</strong> Nginx</p>
    </div>

    <p><small>Configure the greeting in the add-on configuration page.</small></p>
</body>
</html>
EOF

bashio::log.info "Starting nginx on port 8099"
bashio::log.info "Access via Home Assistant UI (click 'OPEN WEB UI')"

# Start nginx in foreground
exec nginx -g "daemon off; error_log /dev/stdout info;"
