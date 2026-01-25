# Curl Troubleshooting Guide

## Common Issues and Solutions

### Connection Problems

#### Timeouts
```bash
# Symptoms:
# curl: (28) Operation timed out after 30000 milliseconds with 0 out of 0 bytes received

# Solutions:
# Increase connection timeout
curl --connect-timeout 60 https://example.com

# Increase total operation timeout
curl --max-time 600 https://example.com

# Set both timeouts together
curl --connect-timeout 30 --max-time 300 https://example.com

# Check network connectivity first
ping -c 3 example.com
traceroute example.com
```

#### DNS Resolution Issues
```bash
# Symptoms:
# curl: (6) Could not resolve host: example.com

# Debug DNS resolution
curl --trace-ascii dns_trace.log https://example.com
grep "getaddrinfo" dns_trace.log

# Use different DNS servers
curl --dns-servers 8.8.8.8,8.8.4.4 https://example.com

# Manual IP resolution
curl --resolve example.com:443:93.184.216.34 https://example.com

# Bypass DNS completely
curl https://93.184.216.34/ -H "Host: example.com"

# Check system DNS
nslookup example.com
dig example.com
```

#### Connection Refused
```bash
# Symptoms:
# curl: (7) Failed to connect to example.com port 80: Connection refused

# Troubleshooting steps:
# Check if port is open
telnet example.com 80
nc -zv example.com 80

# Try different ports
curl https://example.com:443
curl http://example.com:8080

# Check if service is running locally
curl http://localhost:3000
curl http://127.0.0.1:3000

# Verify firewall rules
sudo ufw status
sudo iptables -L
```

### SSL/TLS Issues

#### Certificate Verification Errors
```bash
# Symptoms:
# curl: (60) SSL certificate problem: self-signed certificate

# For testing only (insecure):
curl -k https://example.com

# Proper solutions:
# Update CA certificates
sudo apt-get update && sudo apt-get install -y ca-certificates
# or
sudo yum update ca-certificates

# Use custom CA certificate
curl --cacert /path/to/custom-ca.pem https://example.com

# Use certificate directory
curl --capath /etc/ssl/custom-certs https://example.com

# Get server certificate
openssl s_client -showcerts -connect example.com:443 </dev/null

# Verify certificate chain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt server.crt
```

#### Certificate Expiry
```bash
# Check certificate expiry
echo | openssl s_client -connect example.com:443 2>/dev/null | \
    openssl x509 -noout -dates

# Check certificate details
curl -v https://example.com 2>&1 | grep -E "Server certificate|expire date"

# Automate certificate expiry check
check_cert_expiry() {
    local domain="$1"
    local days_threshold="${2:-30}"

    local expiry_date
    expiry_date=$(echo | openssl s_client -connect "$domain:443" 2>/dev/null | \
        openssl x509 -noout -enddate | cut -d= -f2)

    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))

    if [ $days_until_expiry -lt $days_threshold ]; then
        echo "WARNING: Certificate for $domain expires in $days_until_expiry days"
        return 1
    else
        echo "OK: Certificate for $domain expires in $days_until_expiry days"
        return 0
    fi
}
```

#### Protocol Mismatches
```bash
# TLS version issues
curl --tlsv1.2 https://example.com
curl --tlsv1.3 https://example.com

# SSL version issues
curl --sslv2 https://example.com  # SSLv2 (insecure)
curl --sslv3 https://example.com  # SSLv3 (insecure)

# Force specific cipher
curl --ciphers ECDHE-RSA-AES128-GCM-SHA256 https://example.com

# Disable specific protocols
curl --no-tlsv1.0 --no-tlsv1.1 https://example.com

# Debug SSL handshake
curl -v https://example.com 2>&1 | grep -E "SSL|TLS|Cipher"
```

### Authentication Issues

#### 401 Unauthorized
```bash
# Debug authentication
curl -v -H "Authorization: Bearer token123" https://api.example.com

# Check token format
TOKEN="your_token_here"
echo "Token length: ${#TOKEN}"
echo "Token format: ${TOKEN:0:20}..."

# Test different auth methods
curl -u username:password https://api.example.com
curl -H "X-API-Key: key123" https://api.example.com
curl -H "Authorization: Bearer token123" https://api.example.com

# Decode JWT token (if applicable)
echo "JWT_TOKEN" | cut -d. -f2 | base64 -d | jq .
```

#### 403 Forbidden
```bash
# Check permissions
curl -v -H "Authorization: Bearer token123" https://api.example.com/protected

# Verify scope/permissions
curl -v -H "Authorization: Bearer token123" https://api.example.com/user/profile

# Check rate limiting headers
curl -I -H "Authorization: Bearer token123" https://api.example.com

# Test with different endpoints
curl -H "Authorization: Bearer token123" https://api.example.com/public
curl -H "Authorization: Bearer token123" https://api.example.com/private
```

### Data Transfer Issues

#### File Upload Failures
```bash
# Debug file upload
curl -v -X POST -F "file=@document.pdf" https://api.example.com/upload

# Check file permissions
ls -la document.pdf
file document.pdf

# Test with smaller file
echo "test" > test.txt
curl -v -X POST -F "file=@test.txt" https://api.example.com/upload

# Check content-type
curl -X POST -F "file=@document.pdf;type=application/pdf" https://api.example.com/upload

# Monitor upload progress
curl --progress-bar -X POST -F "file=@largefile.zip" https://api.example.com/upload
```

#### Download Interruptions
```bash
# Resume interrupted download
curl -C - -o largefile.zip https://example.com/largefile.zip

# Check file integrity
md5sum largefile.zip
sha256sum largefile.zip

# Download with retry logic
retry_download() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if curl --fail -L -o "$output" "$url"; then
            echo "Download completed successfully"
            return 0
        fi

        ((retry_count++))
        echo "Retry $retry_count of $max_retries"
        sleep 2
    done

    echo "Download failed after $max_retries attempts"
    return 1
}
```

### Performance Issues

#### Slow Responses
```bash
# Measure timing breakdown
curl -w "@curl-format.txt" -o /dev/null -s https://example.com

# curl-format.txt content:
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#    time_pretransfer:  %{time_pretransfer}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#                     ----------\n
#          time_total:  %{time_total}\n

# Test different endpoints for comparison
curl -w "%{time_total}\n" -o /dev/null -s https://api.example.com/fast
curl -w "%{time_total}\n" -o /dev/null -s https://api.example.com/slow

# Check server response headers for timing info
curl -I https://example.com
```

#### Memory Issues with Large Files
```bash
# Stream large files without loading into memory
curl -o largefile.zip https://example.com/largefile.zip

# Use compression to reduce transfer size
curl --compressed https://example.com/large-data.json

# Download in chunks
curl -r 0-1048575 -o part1.bin https://example.com/largefile.bin
curl -r 1048576- -o part2.bin https://example.com/largefile.bin

# Combine parts
cat part1.bin part2.bin > complete.bin
```

### Debugging Techniques

#### Verbose Output Analysis
```bash
# Full verbose output
curl -v https://example.com > debug.log 2>&1

# Common patterns to search in debug output:
grep -E "About to connect|Connected|HTTP|SSL|Server certificate" debug.log

# DNS lookup details
grep -A 5 -B 5 "getaddrinfo\|Name.*not resolved" debug.log

# SSL/TLS handshake details
grep -A 10 -B 2 "SSL connection\|TLS" debug.log

# HTTP request/response headers
grep -E "^> |^< " debug.log
```

#### Network Level Debugging
```bash
# Trace route to destination
traceroute example.com
tracepath example.com

# Check port connectivity
nc -zv example.com 80
nc -zv example.com 443

# Capture network traffic (requires root)
sudo tcpdump -i any -w capture.pcap host example.com
sudo wireshark capture.pcap

# Check SSL/TLS with openssl
openssl s_client -connect example.com:443 -servername example.com
```

#### Proxy Issues
```bash
# Test without proxy
curl --noproxy "*" https://example.com

# Test with explicit proxy
curl -x http://proxy.example.com:8080 https://example.com

# Debug proxy connection
curl -v -x http://proxy.example.com:8080 https://example.com 2>&1 | \
    grep -i proxy

# Test proxy authentication
curl -x http://user:pass@proxy.example.com:8080 https://example.com

# Check proxy environment variables
echo "$http_proxy"
echo "$https_proxy"
echo "$no_proxy"
```

### Error Code Reference

#### curl Exit Codes
```bash
# Common curl exit codes and their meanings:
# 1  - Unsupported protocol
# 2  - Failed to initialize
# 3  - URL malformed
# 4  - Feature not supported
# 5  - Couldn't resolve proxy
# 6  - Couldn't resolve host
# 7  - Failed to connect to host
# 8  - Weird server reply
# 9  - Access denied to resource
# 10 - Failed to read from file
# 11 - Seek error in file
# 12 - Operation timeout
# 13 - FTP command failure
# 14 - FTP response error
# 15 - Internal failure
# 16 - Failed initialization with curl_easy_init
# 17 - Transfer aborted
# 18 - Partial file
# 19 - FTP operation failed
# 20 - FTP quote command error
# 21 - FTP quote command failed
# 22 - HTTP error (like 404)
# 23 - Write error
# 24 - Malformed upload data
# 25 - Failed to read upload data
# 26 - Out of memory
# 27 - Operation timeout
# 28 - Timeout was reached
# 29 - FTP couldn't set ASCII mode
# 30 - FTP PORT command failed
# 31 - FTP couldn't use REST
# 32 - FTP couldn't get size
# 33 - FTP couldn't use SIZE
# 34 - HTTP post error
# 35 - SSL connect error
# 36 - Bad download resume
# 37 - Couldn't read file
# 38 - LDAP bind failed
# 39 - LDAP search failed
# 40 - Not found on LDAP server
# 41 - Function not found
# 42 - Aborted by callback
# 43 - Internal error
# 44 - Interface error
# 45 - Too many redirects
# 47 - Unknown option
# 48 - Telnet option syntax
# 49 - Peer certificate verification failed
# 51 - Unknown SSL engine error
# 52 - Failed to initialize SSL engine
# 53 - SSL crypto engine not found
# 54 - Cannot set SSL crypto engine as default
# 55 - SSL engine set failed
# 56 - Failed sending network data
# 57 - Failure in receiving network data
# 58 - Problem with SSL crypto engine
# 59 - Couldn't use specified SSL cipher
# 60 - SSL certificate problem
# 61 - SSL cipher problem
# 62 - Couldn't use specified SSL crypto engine
# 63 - Problem with the SSL CA cert
# 64 - Unrecognized transfer encoding
# 65 - Invalid LDAP URL
# 66 - Maximum file size exceeded
# 67 - SSL CA cert problem
# 68 - Transfer aborted due to timeout
# 69 - SSL init error
# 70 - Failed to send SSL data
# 71 - Failed to receive SSL data
# 72 - Bad SSL certificate
# 73 - SSL engine problem
# 74 - SSL shutdown failed
# 75 - SSL socket closed unexpectedly
# 76 - SSL crypto engine initialization error
# 77 - SSL engine not found
# 78 - SSL engine set failed
# 79 - SSL certificate verification error
# 80 - SSL public key error
# 81 - SSL CRL bad format error
# 82 - SSL CRL file bad error
# 83 - Issuer check failed
```

#### HTTP Status Codes
```bash
# Common HTTP status codes:
# 2xx Success
# 200 - OK
# 201 - Created
# 204 - No Content

# 3xx Redirection
# 301 - Moved Permanently
# 302 - Found
# 304 - Not Modified

# 4xx Client Error
# 400 - Bad Request
# 401 - Unauthorized
# 403 - Forbidden
# 404 - Not Found
# 429 - Too Many Requests

# 5xx Server Error
# 500 - Internal Server Error
# 502 - Bad Gateway
# 503 - Service Unavailable
# 504 - Gateway Timeout

# Test different status codes
curl -w "%{http_code}\n" -o /dev/null -s https://httpbin.org/status/200
curl -w "%{http_code}\n" -o /dev/null -s https://httpbin.org/status/404
curl -w "%{http_code}\n" -o /dev/null -s https://httpbin.org/status/500
```

### Troubleshooting Scripts

#### Comprehensive Diagnostic Script
```bash
#!/bin/bash
# curl_diagnostic.sh - Comprehensive curl diagnostic tool

URL="${1:-https://example.com}"
TIMEOUT=10

echo "=== Curl Diagnostic for $URL ==="

# Basic connectivity test
echo -e "\n1. Basic Connectivity Test"
if curl --connect-timeout 5 -s "$URL" > /dev/null; then
    echo "✓ Basic connection successful"
else
    echo "✗ Basic connection failed"
    exit 1
fi

# DNS resolution
echo -e "\n2. DNS Resolution"
if nslookup "$(echo "$URL" | sed 's|https\?://||' | cut -d/ -f1)" > /dev/null; then
    echo "✓ DNS resolution successful"
else
    echo "✗ DNS resolution failed"
fi

# SSL certificate check (if HTTPS)
if [[ "$URL" == https://* ]]; then
    echo -e "\n3. SSL Certificate Check"
    if curl -k -s "$URL" > /dev/null; then
        echo "✓ SSL connection (ignoring cert) successful"

        # Certificate expiry
        expiry_date=$(echo | openssl s_client -connect "$(echo "$URL" | sed 's|https://||')" 2>/dev/null | \
            openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry_date" ]; then
            echo "  Certificate expires: $expiry_date"
        fi
    else
        echo "✗ SSL connection failed"
    fi
fi

# Response time measurement
echo -e "\n4. Performance Test"
time_total=$(curl -w "%{time_total}" -o /dev/null -s "$URL")
echo "  Total time: ${time_total}s"

# HTTP status code
echo -e "\n5. HTTP Status"
status_code=$(curl -w "%{http_code}" -o /dev/null -s "$URL")
echo "  Status code: $status_code"

# Response headers
echo -e "\n6. Response Headers"
curl -s -I "$URL" | head -10

echo -e "\n=== Diagnostic Complete ==="
```

#### Automated Test Suite
```bash
#!/bin/bash
# curl_test_suite.sh - Automated curl testing suite

TEST_URLS=(
    "https://httpbin.org/get"
    "https://httpbin.org/status/200"
    "https://httpbin.org/delay/1"
)

RESULTS_FILE="curl_test_results.csv"

# Initialize results file
echo "timestamp,url,status,response_time,error" > "$RESULTS_FILE"

run_test() {
    local url="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "Testing: $url"

    local response_time
    response_time=$(curl -w "%{time_total}" -o /dev/null -s "$url" 2>/dev/null)
    local curl_exit_code=$?

    if [ $curl_exit_code -eq 0 ]; then
        local status_code=$(curl -w "%{http_code}" -o /dev/null -s "$url")
        echo "✓ Status: $status_code, Time: ${response_time}s"
        echo "$timestamp,$url,$status_code,$response_time," >> "$RESULTS_FILE"
    else
        local error_msg="curl error $curl_exit_code"
        echo "✗ Error: $error_msg"
        echo "$timestamp,$url,error,$response_time,$error_msg" >> "$RESULTS_FILE"
    fi
}

# Run tests
for url in "${TEST_URLS[@]}"; do
    run_test "$url"
done

echo -e "\nTest results saved to: $RESULTS_FILE"
```

These troubleshooting techniques and scripts should help you diagnose and resolve most curl-related issues efficiently.