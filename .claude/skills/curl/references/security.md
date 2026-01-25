# Curl Security Best Practices

## SSL/TLS Security

### Certificate Validation
```bash
# Always verify SSL certificates (default behavior)
curl https://secure.example.com

# Use custom CA certificate bundle
curl --cacert /path/to/ca-bundle.crt https://secure.example.com

# Use certificate directory for additional CAs
curl --capath /etc/ssl/custom-certs https://secure.example.com

# Enable certificate revocation checking
curl --crlfile /path/to/crl.pem https://secure.example.com

# Validate certificate chain manually
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt server.crt
```

### Certificate Pinning
```bash
# Pin server certificate public key hash
curl --pinnedpubkey "sha256//YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=" \
     https://github.com

# Pin multiple certificates
curl --pinnedpubkey "sha256//YLh1dUR9y6Kja30RrAn7JKnbQG/uEtLMkBgFF2Fuihg=;sha256//sRtMgeCkbGmO2jN2dK3R4Y7gN4fGjxCVnZ5u7K4d8E=" \
     https://example.com

# Extract public key hash from certificate
openssl s_client -connect example.com:443 2>/dev/null | \
    openssl x509 -pubkey -noout | \
    openssl pkey -pubin -outform der | \
    openssl dgst -sha256 -binary | \
    openssl enc -base64
```

### TLS Version Configuration
```bash
# Force secure TLS versions
curl --tlsv1.2 https://secure.example.com
curl --tlsv1.3 https://secure.example.com

# Disable insecure SSL/TLS versions
curl --no-sslv2 --no-sslv3 --no-tlsv1 --no-tlsv1.1 https://secure.example.com

# Specify cipher suites
curl --ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256" \
     https://secure.example.com

# Disable weak ciphers
curl --ciphers "!aNULL:!MD5:!DSS" https://secure.example.com
```

## Authentication Security

### Secure Token Management
```bash
# Use environment variables for tokens
export API_TOKEN="your_token_here"
curl -H "Authorization: Bearer $API_TOKEN" https://api.example.com

# Use credential stores (Linux keyring)
SECRET=$(keyctl get_user @s curl:api_token)
curl -H "Authorization: Bearer $SECRET" https://api.example.com

# Secure file storage with proper permissions
chmod 600 ~/.config/app/credentials.json
TOKEN=$(jq -r '.api_token' ~/.config/app/credentials.json)
curl -H "Authorization: Bearer $TOKEN" https://api.example.com

# Temporary credential files (auto-cleanup)
temp_cred=$(mktemp)
chmod 600 "$temp_cred"
echo "token_here" > "$temp_cred"
TOKEN=$(cat "$temp_cred")
rm "$temp_cred"
curl -H "Authorization: Bearer $TOKEN" https://api.example.com
```

### Client Certificate Security
```bash
# Secure client certificate usage
curl --cert client.crt --key client.key https://secure.example.com

# Use encrypted private key
curl --cert client.crt --key client.key --pass "private_key_password" \
     https://secure.example.com

# Use PKCS#12 with certificate chain
curl --cert client.p12:password https://secure.example.com

# Protect certificate files
chmod 600 client.crt client.key client.p12
chown $USER:$USER client.crt client.key client.p12
```

### Password Security
```bash
# Never hardcode passwords in scripts
# BAD: curl -u user:password123 https://api.example.com

# GOOD: Use environment variables
export API_USER="username"
export API_PASS="password"
curl -u "$API_USER:$API_PASS" https://api.example.com

# GOOD: Use .netrc file
cat > ~/.netrc << EOF
machine api.example.com
login username
password password123
EOF
chmod 600 ~/.netrc
curl -n https://api.example.com

# GOOD: Prompt for password interactively
read -s -p "Enter password: " password
curl -u "username:$password" https://api.example.com
unset password
```

## Data Protection

### Secure File Transfers
```bash
# Verify file integrity after download
curl -O https://example.com/file.zip
sha256sum file.zip > file.zip.sha256
# Compare with expected hash

# Download with checksum verification
download_with_checksum() {
    local url="$1"
    local expected_sha256="$2"
    local filename=$(basename "$url")

    curl -O "$url"
    local actual_sha256=$(sha256sum "$filename" | cut -d' ' -f1)

    if [ "$actual_sha256" = "$expected_sha256" ]; then
        echo "Checksum verified: $filename"
    else
        echo "Checksum mismatch: $filename"
        rm "$filename"
        return 1
    fi
}

# Secure file upload with integrity check
secure_upload() {
    local file="$1"
    local url="$2"

    # Calculate file hash before upload
    local file_hash=$(sha256sum "$file" | cut -d' ' -f1)

    # Upload with hash metadata
    curl -F "file=@$file" \
         -F "sha256=$file_hash" \
         "$url"
}
```

### Sensitive Data Handling
```bash
# Avoid logging sensitive data
curl -s -H "Authorization: Bearer $TOKEN" https://api.example.com > /dev/null

# Use secure temporary files
temp_data=$(mktemp -t curl_data.XXXXXX)
chmod 600 "$temp_data"
curl -s https://api.example.com/sensitive-data > "$temp_data"
# Process data...
shred -u "$temp_data"  # Securely delete

# Redact sensitive information from logs
sanitize_log() {
    local log_file="$1"
    sed -i 's/Bearer [^"]*/Bearer [REDACTED]/g' "$log_file"
    sed -i 's/password=[^&]*/password=[REDACTED]/g' "$log_file"
}
```

## Input Validation and Sanitization

### URL Validation
```bash
# Validate URLs before making requests
validate_url() {
    local url="$1"

    # Check URL format
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo "Invalid URL: must start with http:// or https://"
        return 1
    fi

    # Check for dangerous characters
    if [[ "$url" =~ [\<\>\"\'\|\&\;] ]]; then
        echo "Invalid URL: contains potentially dangerous characters"
        return 1
    fi

    # Prevent local file access
    if [[ "$url" =~ ^file:// ]]; then
        echo "Invalid URL: file:// protocol not allowed"
        return 1
    fi

    return 0
}

# Safe URL download
safe_download() {
    local url="$1"
    local output="$2"

    if validate_url "$url"; then
        curl -L -o "$output" "$url"
    else
        echo "Download aborted: invalid URL"
        return 1
    fi
}
```

### Input Sanitization
```bash
# Sanitize user input for curl parameters
sanitize_input() {
    local input="$1"
    # Remove dangerous characters
    echo "$input" | sed 's/[;&|`$()]//g' | tr -d '\0'
}

# Safe parameter passing
safe_curl_request() {
    local url="$1"
    local param_name="$2"
    local param_value="$3"

    # Sanitize inputs
    url=$(sanitize_input "$url")
    param_name=$(sanitize_input "$param_name")
    param_value=$(sanitize_input "$param_value")

    curl -G --data-urlencode "$param_name=$param_value" "$url"
}
```

## Network Security

### Proxy Security
```bash
# Use secure proxy connections
curl -x https://secure-proxy.example.com:8080 https://target.example.com

# Proxy authentication with secure credentials
curl -x "http://user:password@proxy.example.com:8080" https://example.com

# SOCKS proxy for additional security
curl --socks5-hostname secure-socks.example.com:1080 https://example.com

# Validate proxy certificates
curl -x https://proxy.example.com:8080 \
     --cacert /path/to/proxy-ca.crt \
     https://target.example.com
```

### DNS Security
```bash
# Use secure DNS servers
curl --dns-servers 1.1.1.1,8.8.8.8 https://example.com

# DNS over HTTPS (if supported)
curl --doh-url https://dns.google/dns-query https://example.com

# DNSSEC validation (system-level)
# Configure system DNS resolver with DNSSEC validation
curl https://dnssec-validated.example.com

# DNS cache poisoning prevention
curl --dns-cache-timeout 60 https://example.com
```

## Error Handling and Information Disclosure

### Secure Error Handling
```bash
# Avoid exposing sensitive information in error messages
secure_curl_request() {
    local url="$1"
    local error_log="curl_errors.log"

    # Redirect detailed errors to log file
    local response
    response=$(curl -s -w "%{http_code}" "$url" 2>> "$error_log")
    local http_code="${response: -3}"

    case $http_code in
        200|201|204)
            echo "${response%???}"  # Return body without status code
            ;;
        401)
            echo "Authentication failed" >&2
            return 1
            ;;
        403)
            echo "Access denied" >&2
            return 1
            ;;
        404)
            echo "Resource not found" >&2
            return 1
            ;;
        5*)
            echo "Server error occurred" >&2
            return 1
            ;;
        *)
            echo "Request failed" >&2
            return 1
            ;;
    esac
}
```

### Prevent Information Leakage
```bash
# Control User-Agent to avoid version disclosure
curl -H "User-Agent: MyApp/1.0" https://api.example.com

# Disable Referer header to prevent URL leakage
curl --no-referer https://example.com

# Control what information is sent
curl -H "User-Agent: " -H "Accept: " https://example.com

# Remove sensitive headers
curl -H "Authorization:" -H "Cookie:" https://example.com
```

## Auditing and Logging

### Security Auditing
```bash
# Log all curl requests for auditing
curl_with_audit() {
    local url="$1"
    shift
    local curl_args=("$@")

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user=$(whoami)
    local pid=$$

    # Log request metadata (no sensitive data)
    echo "[$timestamp] User: $user, PID: $pid, URL: $url" >> /var/log/curl_audit.log

    # Execute request
    curl "${curl_args[@]}" "$url"
}

# Monitor for suspicious activity
monitor_curl_activity() {
    local log_file="/var/log/curl_audit.log"
    local max_requests_per_minute=100

    # Count requests in last minute
    local recent_requests=$(grep "$(date '+%Y-%m-%d %H:%M')" "$log_file" | wc -l)

    if [ "$recent_requests" -gt "$max_requests_per_minute" ]; then
        echo "ALERT: High curl activity detected - $recent_requests requests in last minute"
        # Send alert to security team
    fi
}
```

### Secure Configuration Management
```bash
# Secure configuration file template
cat > ~/.config/curl_secure.conf << 'EOF'
# Secure curl configuration
# Never include sensitive information here

# Always use HTTPS
proto = https

# Enable certificate validation
insecure = false

# Use secure TLS versions
tlsv1.2

# Secure cipher suites
ciphers = ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256

# Timeout settings
connect-timeout = 30
max-time = 300

# Disable potentially insecure features
disable-epsv
ftp-skip-pasv-ip
EOF

chmod 600 ~/.config/curl_secure.conf

# Use secure configuration
curl -K ~/.config/curl_secure.conf https://secure.example.com
```

## Security Testing Scripts

### SSL Security Tester
```bash
#!/bin/bash
# ssl_security_test.sh - Test SSL/TLS security of endpoints

test_ssl_security() {
    local domain="$1"
    local port="${2:-443}"

    echo "=== SSL Security Test for $domain:$port ==="

    # Test SSL/TLS versions
    echo "Testing SSL/TLS versions..."
    protocols=("ssl2" "ssl3" "tls1" "tls1_1" "tls1_2" "tls1_3")
    for proto in "${protocols[@]}"; do
        if timeout 5 openssl s_client -connect "$domain:$port" -$proto 2>/dev/null | grep -q "Protocol.*$proto"; then
            echo "✗ $proto supported (potentially insecure)"
        else
            echo "✓ $proto not supported"
        fi
    done

    # Test certificate details
    echo -e "\nCertificate Information:"
    echo | openssl s_client -connect "$domain:$port" 2>/dev/null | \
        openssl x509 -noout -dates -subject -issuer

    # Test cipher suites
    echo -e "\nTesting cipher suites..."
    weak_ciphers=("NULL" "MD5" "RC4" "DES")
    for cipher in "${weak_ciphers[@]}"; do
        if timeout 5 openssl s_client -connect "$domain:$port" -cipher "$cipher" 2>/dev/null | grep -q "Cipher.*$cipher"; then
            echo "✗ Weak cipher $cipher supported"
        fi
    done

    # Check certificate transparency (if supported)
    echo -e "\nCertificate Transparency:"
    if command -v ct-submit &> /dev/null; then
        ct-submit "$domain" "$port" && echo "✓ Certificate found in CT logs" || echo "✗ Certificate not found in CT logs"
    fi
}
```

### Security Scanner
```bash
#!/bin/bash
# security_scanner.sh - Scan web applications for security issues

scan_endpoint() {
    local url="$1"

    echo "Scanning: $url"

    # Check for security headers
    echo "Checking security headers..."
    response_headers=$(curl -s -I "$url")

    required_headers=("X-Frame-Options" "X-XSS-Protection" "X-Content-Type-Options" "Strict-Transport-Security")
    for header in "${required_headers[@]}"; do
        if echo "$response_headers" | grep -qi "$header"; then
            echo "✓ $header present"
        else
            echo "✗ $header missing"
        fi
    done

    # Check for HTTPS enforcement
    if [[ "$url" != https://* ]]; then
        echo "✗ Using HTTP instead of HTTPS"

        # Check for HTTPS redirect
        https_url="${url/http:/https:}"
        http_code=$(curl -s -w "%{http_code}" -o /dev/null -L "$https_url")
        if [ "$http_code" = "200" ]; then
            echo "✓ HTTPS version available: $https_url"
        fi
    fi

    # Check for information disclosure
    echo "Checking for information disclosure..."
    server_header=$(curl -s -I "$url" | grep -i "Server:")
    if [ -n "$server_header" ]; then
        echo "✗ Server header exposed: $server_header"
    fi

    # Test for common vulnerabilities
    echo "Testing for common vulnerabilities..."

    # Test for directory traversal
    traversal_response=$(curl -s "$url?file=../../../etc/passwd")
    if echo "$traversal_response" | grep -q "root:x:"; then
        echo "✗ Potential directory traversal vulnerability"
    fi

    # Test for XSS
    xss_payload="<script>alert('xss')</script>"
    xss_response=$(curl -s -G --data-urlencode "input=$xss_payload" "$url")
    if echo "$xss_response" | grep -qi "<script>alert"; then
        echo "✗ Potential XSS vulnerability"
    fi
}
```

These security practices will help you use curl securely in production environments and protect against common security threats.