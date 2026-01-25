# Curl Command Examples

## Basic HTTP Requests

### GET Requests
```bash
# Simple GET
curl https://api.example.com/data

# GET with headers
curl -H "Accept: application/json" https://api.example.com/data

# GET with authentication
curl -H "Authorization: Bearer token123" https://api.example.com/protected

# Follow redirects
curl -L https://example.com/redirect

# Save response to file
curl -o response.json https://api.example.com/data

# Download with original filename
curl -O https://example.com/filename.zip

# Silent mode (no progress)
curl -s https://api.example.com/data

# Verbose output (debug)
curl -v https://api.example.com/data
```

### POST Requests
```bash
# POST form data
curl -X POST -d "name=john&email=john@example.com" https://api.example.com/users

# POST JSON data
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com"}' \
  https://api.example.com/users

# POST file upload
curl -X POST -F "file=@document.pdf" https://api.example.com/upload

# POST multiple files
curl -X POST \
  -F "file1=@doc1.pdf" \
  -F "file2=@doc2.pdf" \
  https://api.example.com/upload

# POST with JSON from file
curl -X POST \
  -H "Content-Type: application/json" \
  -d @data.json \
  https://api.example.com/users
```

### PUT and PATCH
```bash
# PUT request
curl -X PUT \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Name"}' \
  https://api.example.com/users/123

# PATCH request
curl -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"email":"new@example.com"}' \
  https://api.example.com/users/123
```

### DELETE Request
```bash
# Simple DELETE
curl -X DELETE https://api.example.com/users/123

# DELETE with authentication
curl -X DELETE \
  -H "Authorization: Bearer token123" \
  https://api.example.com/users/123
```

## Headers and Options

### Custom Headers
```bash
# Single header
curl -H "User-Agent: MyApp/1.0" https://example.com

# Multiple headers
curl -H "Accept: application/json" \
     -H "User-Agent: MyApp/1.0" \
     -H "X-API-Version: 2.0" \
     https://api.example.com

# Header with value from variable
API_KEY="abc123"
curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

### Output Options
```bash
# Show response headers
curl -i https://example.com

# Show only headers
curl -I https://example.com

# Write to file instead of stdout
curl -o output.html https://example.com

# Use remote filename
curl -O https://example.com/file.zip

# Create directory structure
curl --create-dirs -o path/to/file https://example.com/data
```

## File Operations

### Downloads
```bash
# Resume interrupted download
curl -C - -o largefile.zip https://example.com/largefile.zip

# Limit download speed (1KB/s)
curl --limit-rate 1k https://example.com/largefile.zip

# Download with timestamp check
curl -z "Jan 1 2024" https://example.com/updated-file

# Download multiple files
curl -O https://example.com/file1.zip \
     -O https://example.com/file2.zip \
     -O https://example.com/file3.zip
```

### Uploads
```bash
# Upload via PUT
curl -T upload.txt https://ftp.example.com/

# Upload with custom filename
curl -T localfile.txt https://ftp.example.com/remotefile.txt

# Upload via FTP with auth
curl -T upload.txt -u user:pass ftp://ftp.example.com/
```

## Advanced Options

### Timeouts and Retries
```bash
# Connection timeout (30 seconds)
curl --connect-timeout 30 https://example.com

# Maximum total time (5 minutes)
curl --max-time 300 https://example.com

# Retry failed requests
curl --retry 3 --retry-delay 2 https://example.com

# Retry only on specific errors
curl --retry 3 --retry-max-time 60 https://example.com
```

### Proxy Support
```bash
# HTTP proxy
curl -x http://proxy.example.com:8080 https://example.com

# SOCKS proxy
curl --socks5 proxy.example.com:1080 https://example.com

# Proxy with authentication
curl -x http://user:pass@proxy.example.com:8080 https://example.com
```

### SSL/TLS Options
```bash
# Ignore SSL verification (not recommended)
curl -k https://example.com

# Use custom CA certificate
curl --cacert /path/to/ca-bundle.crt https://example.com

# Client certificate authentication
curl --cert client.crt --key client.key https://example.com

# Force specific TLS version
curl --tlsv1.2 https://example.com
```

## Response Processing

### JSON Processing with jq
```bash
# Pretty print JSON
curl https://api.example.com/data | jq .

# Extract specific field
curl https://api.example.com/users | jq '.users[0].name'

# Filter results
curl https://api.example.com/data | jq '.items[] | select(.price > 100)'

# Save specific field to variable
username=$(curl https://api.example.com/user | jq -r '.username')
```

### Response Headers and Status
```bash
# Get HTTP status code only
curl -w "%{http_code}" -s -o /dev/null https://example.com

# Get response time
curl -w "Time: %{time_total}s\n" -s -o /dev/null https://example.com

# Get all timing information
curl -w "@curl-format.txt" -s -o /dev/null https://example.com
```

## Variable Expansion (curl 8.3.0+)

```bash
# Set variables
curl --variable api_key=abc123 \
     --variable user_id=456 \
     --expand-url = "https://api.example.com/users/{{user_id}}" \
     --expand-header = "Authorization: Bearer {{api_key}}"

# From environment
curl --variable '%API_TOKEN' \
     --expand-header = "Authorization: Bearer {{%API_TOKEN}}" \
     https://api.example.com

# From file
curl --variable data@payload.json \
     --expand-data = "{{data}}" \
     https://api.example.com
```

## Cookie Management

```bash
# Save cookies to file
curl -c cookies.txt https://example.com/login

# Use cookies from file
curl -b cookies.txt https://example.com/protected

# Set cookie directly
curl -b "session_id=abc123" https://example.com

# Save and use cookies in one command
curl -b cookies.txt -c cookies.txt https://example.com
```

## Compression

```bash
# Request compressed response
curl --compressed https://example.com/large-data

# Send compressed request data
curl -H "Content-Encoding: gzip" \
     --data-binary @compressed_data.gz \
     https://api.example.com
```

## FTP Operations

```bash
# List directory
curl ftp://ftp.example.com/

# Download file
curl -O ftp://ftp.example.com/file.txt

# Upload file
curl -T upload.txt ftp://ftp.example.com/

# Delete file (custom command)
curl -Q "DELE oldfile.txt" ftp://ftp.example.com/

# Create directory
curl -Q "MKD newdir" ftp://ftp.example.com/
```