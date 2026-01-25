# Curl Authentication Methods

## Basic Authentication

### Username and Password
```bash
# Basic auth with -u flag
curl -u username:password https://api.example.com/protected

# Prompt for password (more secure)
curl -u username https://api.example.com/protected

# URL with credentials (not recommended for security)
curl https://username:password@api.example.com/protected
```

### API Key Authentication
```bash
# API key in header
curl -H "X-API-Key: abc123def456" https://api.example.com/data

# API key as query parameter
curl "https://api.example.com/data?api_key=abc123def456"

# Bearer token authentication
curl -H "Authorization: Bearer abc123def456" https://api.example.com/data
```

## Bearer Token Authentication

### OAuth 2.0 Bearer Tokens
```bash
# Static Bearer token
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
     https://api.example.com/protected

# Token from environment variable
TOKEN=$(cat ~/.config/app/token)
curl -H "Authorization: Bearer $TOKEN" https://api.example.com/protected

# Token from file
curl -H "Authorization: Bearer $(cat ~/.tokens/api)" \
     https://api.example.com/protected
```

### JWT Token Handling
```bash
# Extract JWT payload with jq
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

# Decode JWT payload (requires jq and base64)
echo $TOKEN | cut -d. -f2 | base64 -d | jq .

# Check JWT expiration
exp=$(echo $TOKEN | cut -d. -f2 | base64 -d | jq -r '.exp')
now=$(date +%s)
if [ $exp -lt $now ]; then
    echo "Token expired"
fi
```

## Digest Authentication

```bash
# Digest authentication
curl --digest -u username:password https://api.example.com/protected

# Digest with specific algorithm
curl --digest -u username:password \
     --anyauth https://api.example.com/protected
```

## NTLM Authentication

```bash
# NTLM authentication
curl --ntlm -u username:password https://api.example.com/protected

# NTLM with domain
curl --ntlm -u domain\username:password https://api.example.com/protected
```

## Certificate-Based Authentication

### Client Certificates
```bash
# Client certificate and key
curl --cert client.crt --key client.key https://secure.example.com

# Client certificate with passphrase
curl --cert client.crt --key client.key \
     --pass password123 https://secure.example.com

# PKCS#12 certificate
curl --cert client.p12:password https://secure.example.com
```

### Certificate Verification
```bash
# Use custom CA certificate
curl --cacert /path/to/ca-bundle.crt https://secure.example.com

# Use certificate directory
curl --capath /etc/ssl/certs https://secure.example.com

# Ignore certificate verification (testing only)
curl -k https://secure.example.com

# Certificate revocation checking
curl --crlfile /path/to/crl.pem https://secure.example.com
```

## OAuth 2.0 Flow

### Authorization Code Flow
```bash
# Step 1: Get authorization code (user interaction required)
# Redirect user to:
# https://auth.example.com/authorize?response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=REDIRECT_URI&scope=REQUESTED_SCOPES

# Step 2: Exchange code for token
curl -X POST https://auth.example.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=REDIRECT_URI" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"

# Step 3: Use access token
curl -H "Authorization: Bearer ACCESS_TOKEN" \
     https://api.example.com/protected
```

### Client Credentials Flow
```bash
# Get access token with client credentials
curl -X POST https://auth.example.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "scope=REQUESTED_SCOPES"

# Store and use the token
TOKEN=$(curl -s -X POST https://auth.example.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" https://api.example.com/protected
```

### Resource Owner Password Credentials
```bash
# Direct token exchange with user credentials
curl -X POST https://auth.example.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "username=USER_USERNAME" \
  -d "password=USER_PASSWORD" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

### Refresh Token Flow
```bash
# Refresh expired access token
curl -X POST https://auth.example.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=REFRESH_TOKEN" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## API Key Management

### Secure Key Storage
```bash
# Store API key in environment variable
export API_KEY="your_api_key_here"
curl -H "Authorization: Bearer $API_KEY" https://api.example.com

# Store in config file (secure permissions)
chmod 600 ~/.config/app/config.json
API_KEY=$(jq -r '.api_key' ~/.config/app/config.json)
curl -H "Authorization: Bearer $API_KEY" https://api.example.com

# Use keyring system (Linux keyctl)
KEY=$(keyctl request user app:api_key)
curl -H "Authorization: Bearer $KEY" https://api.example.com
```

### Token Rotation
```bash
# Function to refresh and store token
refresh_token() {
    local response=$(curl -s -X POST https://auth.example.com/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=refresh_token" \
        -d "refresh_token=$REFRESH_TOKEN" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET")

    ACCESS_TOKEN=$(echo $response | jq -r '.access_token')
    echo $ACCESS_TOKEN > ~/.config/app/access_token
}

# Use token with auto-refresh
access_token=$(cat ~/.config/app/access_token)
response=$(curl -s -H "Authorization: Bearer $access_token" https://api.example.com/data)

if echo "$response" | jq -e '.error == "invalid_token"' > /dev/null; then
    refresh_token
    access_token=$(cat ~/.config/app/access_token)
    response=$(curl -s -H "Authorization: Bearer $access_token" https://api.example.com/data)
fi
```

## Custom Authentication Headers

### AWS Signature Version 4
```bash
# Simplified AWS auth (requires additional tools for full implementation)
curl -H "Authorization: AWS4-HMAC-SHA256 Credential=ACCESS_KEY/REGION/SERVICE/aws4_request, SignedHeaders=host;x-amz-date, Signature=SIGNATURE" \
     -H "X-Amz-Date: $(date -u +%Y%m%dT%H%M%SZ)" \
     https://service.amazonaws.com/endpoint
```

### Custom Headers
```bash
# API-specific authentication
curl -H "X-App-ID: your_app_id" \
     -H "X-App-Secret: your_app_secret" \
     https://api.example.com/data

# Multi-step authentication
# Step 1: Get temporary token
temp_token=$(curl -s -X POST https://api.example.com/auth/temp \
    -H "X-API-Key: $API_KEY" | jq -r '.temp_token')

# Step 2: Use temporary token
curl -H "Authorization: Temp $temp_token" \
     https://api.example.com/protected
```

## Session Management

### Cookie-Based Authentication
```bash
# Login and save session
curl -c session.txt -X POST \
  -d "username=user&password=pass" \
  https://api.example.com/login

# Use session for authenticated requests
curl -b session.txt https://api.example.com/protected

# Update session cookie
curl -b session.txt -c session.txt https://api.example.com/refresh
```

### Session Token Management
```bash
# Function to manage session
manage_session() {
    local session_file="$HOME/.config/app/session.json"
    local session_timeout=3600  # 1 hour

    if [ -f "$session_file" ]; then
        local session_age=$(($(date +%s) - $(stat -c %Y "$session_file")))
        if [ $session_age -lt $session_timeout ]; then
            cat "$session_file"
            return 0
        fi
    fi

    # Create new session
    local session=$(curl -s -X POST https://api.example.com/session \
        -H "X-API-Key: $API_KEY")
    echo "$session" > "$session_file"
    echo "$session"
}

# Use managed session
session=$(manage_session)
token=$(echo "$session" | jq -r '.token')
curl -H "Authorization: Bearer $token" https://api.example.com/protected
```

## Error Handling

### Authentication Error Detection
```bash
# Check authentication response
response=$(curl -s -H "Authorization: Bearer $TOKEN" https://api.example.com/data)

if echo "$response" | jq -e '.error' > /dev/null; then
    error_code=$(echo "$response" | jq -r '.error.code')
    case $error_code in
        "invalid_token")
            echo "Token invalid, refreshing..."
            refresh_token
            ;;
        "token_expired")
            echo "Token expired, refreshing..."
            refresh_token
            ;;
        "insufficient_scope")
            echo "Insufficient permissions"
            ;;
    esac
fi
```

### Retry with Re-authentication
```bash
# Function with automatic retry
authenticated_request() {
    local url="$1"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        local response=$(curl -s -H "Authorization: Bearer $TOKEN" "$url")

        if ! echo "$response" | jq -e '.error' > /dev/null; then
            echo "$response"
            return 0
        fi

        if echo "$response" | jq -e '.error.code == "token_expired"' > /dev/null; then
            refresh_token
            ((retry_count++))
            continue
        fi

        echo "$response"
        return 1
    done

    echo "Max retries exceeded"
    return 1
}
```