# Curl Performance Optimization

## Connection Optimization

### Connection Reuse
```bash
# Keep connections alive (HTTP Keep-Alive)
curl --keepalive-time 60 https://api.example.com

# Connection pooling (multiple requests)
curl --keepalive https://api.example.com/endpoint1
curl --keepalive https://api.example.com/endpoint2
curl --keepalive https://api.example.com/endpoint3

# Control connection caching
curl --limit-rate 1M --keepalive https://api.example.com/large-file
```

### Parallel Operations
```bash
# Multiple downloads in parallel
curl -O https://example.com/file1.zip \
     -O https://example.com/file2.zip \
     -O https://example.com/file3.zip

# Using xargs for parallel processing
cat urls.txt | xargs -n1 -P4 curl -O

# GNU parallel for better control
parallel -j 5 curl -O {} :::: urls.txt

# Parallel requests with different output files
for i in {1..10}; do
    curl -s "https://api.example.com/data/$i" -o "data_$i.json" &
done
wait  # Wait for all background jobs to complete
```

### Connection Limits
```bash
# Limit concurrent connections
curl --max-conns 10 https://api.example.com

# Limit connections per host
curl --max-conns-per-host 5 https://api.example.com

# Connection rate limiting
curl --rate 2/s https://api.example.com  # 2 requests per second
curl --rate 10/m https://api.example.com  # 10 requests per minute
```

## Bandwidth Management

### Rate Limiting
```bash
# Limit download speed (1KB/s)
curl --limit-rate 1k https://example.com/largefile.zip

# Limit upload speed (500KB/s)
curl --limit-rate 500k -T upload.txt https://ftp.example.com/

# Different units
curl --limit-rate 1M https://example.com/largefile.zip  # 1MB/s
curl --limit-rate 1000B https://example.com/smallfile  # 1000 bytes/s

# Variable rate limiting (for multiple connections)
curl --limit-rate 500k --limit-rate 1M https://example.com/file
```

### Compression
```bash
# Request compressed responses
curl --compressed https://api.example.com/large-data

# Verify compression savings
curl -w "Size downloaded: %{size_download} bytes\n" -o /dev/null -s \
     https://api.example.com/data
curl -w "Size downloaded: %{size_download} bytes\n" -o /dev/null -s \
     --compressed https://api.example.com/data

# Force specific compression
curl -H "Accept-Encoding: gzip, deflate" https://api.example.com/data
curl -H "Accept-Encoding: br" https://api.example.com/data  # Brotli
```

## Timeouts and Reliability

### Optimized Timeout Settings
```bash
# Balanced timeout configuration
curl --connect-timeout 10 --max-time 300 https://api.example.com

# Fast timeout for health checks
curl --connect-timeout 2 --max-time 5 https://api.example.com/health

# Long timeout for large downloads
curl --connect-timeout 30 --max-time 3600 https://example.com/largefile.zip

# Custom timeout script
optimize_timeouts() {
    local url="$1"
    local file_size="${2:-0}"

    if [ "$file_size" -gt 100000000 ]; then  # > 100MB
        curl --connect-timeout 30 --max-time 7200 "$url"  # 2 hours
    elif [ "$file_size" -gt 10000000 ]; then   # > 10MB
        curl --connect-timeout 15 --max-time 1800 "$url"  # 30 minutes
    else
        curl --connect-timeout 10 --max-time 300 "$url"   # 5 minutes
    fi
}
```

### Retry Strategies
```bash
# Exponential backoff retry
retry_with_backoff() {
    local url="$1"
    local max_retries=5
    local base_delay=1
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if curl --fail -s "$url"; then
            echo "Success on attempt $((retry_count + 1))"
            return 0
        fi

        ((retry_count++))
        if [ $retry_count -lt $max_retries ]; then
            local delay=$((base_delay * 2 ** (retry_count - 1)))
            echo "Retry $retry_count of $max_retries in ${delay}s..."
            sleep $delay
        fi
    done

    echo "Failed after $max_retries attempts"
    return 1
}

# Built-in retry with jitter
curl --retry 3 --retry-delay 2 --retry-max-time 60 https://api.example.com

# Retry only on specific errors
curl --retry 3 --retry-all-errors https://api.example.com
curl --retry 3 --retry-connrefused https://api.example.com
```

## HTTP/2 and Protocol Optimization

### HTTP/2 Performance
```bash
# Force HTTP/2
curl --http2 https://api.example.com

# HTTP/2 with multiplexing
curl --http2 -O https://example.com/file1.zip \
               -O https://example.com/file2.zip \
               -O https://example.com/file3.zip

# HTTP/2 prior knowledge (for services that support it)
curl --http2-prior-knowledge https://api.example.com

# Compare HTTP/1.1 vs HTTP/2 performance
echo "HTTP/1.1:"
time curl -s -o /dev/null --http1.1 https://api.example.com/data

echo "HTTP/2:"
time curl -s -o /dev/null --http2 https://api.example.com/data
```

### Protocol Selection
```bash
# Try HTTP/2 first, fallback to HTTP/1.1
curl --http2 https://api.example.com

# Force specific HTTP version
curl --http1.1 https://api.example.com
curl --http1.0 https://api.example.com

# Negotiate best protocol
curl --http2 https://api.example.com

# Disable specific protocols
curl --no-npn --no-alpn https://api.example.com
```

## Memory and Resource Optimization

### Streaming Large Files
```bash
# Stream download to file without loading into memory
curl https://example.com/largefile.zip -o largefile.zip

# Stream through pipe for processing
curl https://api.example.com/large-data.json | jq '.items[] | .name'

# Stream upload from file without loading into memory
curl -T @largefile.bin https://upload.example.com/

# Process streaming response
curl https://api.example.com/stream | while read line; do
    echo "Received: $line"
done
```

### Efficient Data Handling
```bash
# Download only part of file (range requests)
curl -r 0-1048575 https://example.com/largefile.zip -o first1mb.zip
curl -r 1048576- https://example.com/largefile.zip -o rest.zip

# Conditional download (only if modified)
curl -z "Jan 1 2024" https://example.com/updated-file
curl -z file.txt https://example.com/file.txt  # Based on local file timestamp

# Resume interrupted download efficiently
curl -C - --keepalive-time 60 https://example.com/largefile.zip
```

## Performance Monitoring

### Timing Analysis
```bash
# Comprehensive timing format
cat > curl-format.txt << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
   size_download:      %{size_download}\n
   speed_download:     %{speed_download}\n
EOF

# Use the format
curl -w "@curl-format.txt" -o /dev/null -s https://api.example.com/data

# Real-time performance monitoring
monitor_performance() {
    local url="$1"
    local interval="${2:-60}"  # seconds
    local duration="${3:-3600}"  # seconds

    local end_time=$(($(date +%s) + duration))
    while [ $(date +%s) -lt $end_time ]; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local metrics=$(curl -w "@curl-format.txt" -o /dev/null -s "$url")
        echo "[$timestamp] $metrics"
        sleep $interval
    done
}
```

### Performance Comparison Script
```bash
#!/bin/bash
# performance_comparison.sh - Compare different curl configurations

URL="${1:-https://api.example.com/data}"
ITERATIONS="${2:-5}"

echo "Performance comparison for: $URL"
echo "Iterations: $ITERATIONS"
echo

test_configuration() {
    local name="$1"
    shift
    local curl_args=("$@")

    echo "Testing: $name"
    local total_time=0

    for i in $(seq 1 $ITERATIONS); do
        local time_result
        time_result=$(curl -w "%{time_total}" -o /dev/null -s "${curl_args[@]}" "$URL")
        total_time=$(echo "$total_time + $time_result" | bc)
        echo -n "."
    done

    local avg_time=$(echo "scale=3; $total_time / $ITERATIONS" | bc)
    echo " Average: ${avg_time}s"
    echo
}

# Test different configurations
test_configuration "Default" "$URL"
test_configuration "HTTP/2" --http2 "$URL"
test_configuration "Compressed" --compressed "$URL"
test_configuration "Keep-alive" --keepalive-time 60 "$URL"
test_configuration "HTTP/2 + Compressed" --http2 --compressed "$URL"
test_configuration "HTTP/2 + Compressed + Keep-alive" --http2 --compressed --keepalive-time 60 "$URL"
```

## Network Optimization

### DNS Optimization
```bash
# Use faster DNS servers
curl --dns-servers 1.1.1.1,8.8.8.8 https://example.com

# DNS caching (some builds support this)
curl --dns-cache-timeout 60 https://example.com

# Bypass DNS with IP address
curl --resolve example.com:443:93.184.216.34 https://example.com

# Pre-resolve DNS
curl --connect-to example.com:443:93.184.216.34 https://example.com
```

### TCP Optimization
```bash
# TCP Fast Open (if supported)
curl --tcp-fastopen https://example.com

# TCP keepalive
curl --keepalive-time 60 https://example.com

# Disable Nagle's algorithm (for small requests)
curl --tcp-nodelay https://api.example.com/small-request

# Optimize TCP buffer sizes
curl --socks5-hostname socks5://proxy.example.com:1080 https://example.com
```

## Advanced Performance Techniques

### Connection Pooling Script
```bash
#!/bin/bash
# connection_pool.sh - Maintain a pool of curl connections

API_BASE="https://api.example.com"
POOL_SIZE=5
TIMEOUT=300

# Function to create persistent connection
create_connection() {
    local endpoint="$1"
    curl --keepalive-time $TIMEOUT -s -o /dev/null "$API_BASE/$endpoint" &
    echo $!
}

# Create connection pool
declare -a connection_pids
for i in $(seq 1 $POOL_SIZE); do
    connection_pids+=($(create_connection "health"))
done

echo "Created $POOL_SIZE persistent connections"

# Use pooled connections
make_request() {
    local endpoint="$1"
    curl --keepalive-time $TIMEOUT -s "$API_BASE/$endpoint"
}

# Cleanup function
cleanup() {
    echo "Cleaning up connections..."
    for pid in "${connection_pids[@]}"; do
        kill $pid 2>/dev/null
    done
}

trap cleanup EXIT

# Example usage
for endpoint in users products orders; do
    echo "Fetching $endpoint..."
    make_request "$endpoint" > "${endpoint}.json"
done
```

### Parallel Batch Processing
```bash
#!/bin/bash
# batch_processor.sh - High-performance batch processing

INPUT_FILE="urls.txt"
MAX_PARALLEL=10
BATCH_SIZE=50

process_batch() {
    local batch=("$@")
    local pids=()

    for url in "${batch[@]}"; do
        curl -s -L -o "$(basename "$url")" "$url" &
        pids+=($!)

        # Limit parallel jobs
        if [ ${#pids[@]} -ge $MAX_PARALLEL ]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
        fi
    done

    # Wait for remaining jobs
    for pid in "${pids[@]}"; do
        wait $pid
    done
}

# Main processing
total_lines=$(wc -l < "$INPUT_FILE")
processed=0

while [ $processed -lt $total_lines ]; do
    batch=()
    for i in $(seq 1 $BATCH_SIZE); do
        if [ $processed -lt $total_lines ]; then
            line=$(sed -n "$((processed + 1))p" "$INPUT_FILE")
            batch+=("$line")
            ((processed++))
        fi
    done

    echo "Processing batch: $((processed - ${#batch[@]} + 1))-$processed of $total_lines"
    process_batch "${batch[@]}"
done

echo "Batch processing completed"
```

### Performance Benchmarks
```bash
#!/bin/bash
# benchmark.sh - Comprehensive curl performance benchmarking

TEST_URLS=(
    "https://httpbin.org/get"
    "https://httpbin.org/json"
    "https://httpbin.org/uuid"
)

CONFIGS=(
    "default"
    "http2"
    "compressed"
    "keepalive"
    "http2_compressed"
    "http2_compressed_keepalive"
)

run_benchmark() {
    local url="$1"
    local config="$2"

    case $config in
        "default")
            curl -w "%{time_total}" -o /dev/null -s "$url"
            ;;
        "http2")
            curl --http2 -w "%{time_total}" -o /dev/null -s "$url"
            ;;
        "compressed")
            curl --compressed -w "%{time_total}" -o /dev/null -s "$url"
            ;;
        "keepalive")
            curl --keepalive-time 60 -w "%{time_total}" -o /dev/null -s "$url"
            ;;
        "http2_compressed")
            curl --http2 --compressed -w "%{time_total}" -o /dev/null -s "$url"
            ;;
        "http2_compressed_keepalive")
            curl --http2 --compressed --keepalive-time 60 -w "%{time_total}" -o /dev/null -s "$url"
            ;;
    esac
}

# Run benchmarks
echo "URL,Config,Average_Time,Min_Time,Max_Time"
for url in "${TEST_URLS[@]}"; do
    for config in "${CONFIGS[@]}"; do
        times=()
        for i in {1..10}; do
            time_result=$(run_benchmark "$url" "$config")
            times+=($time_result)
        done

        IFS=$'\n' sorted=($(sort -n <<<"${times[*]}"))
        unset IFS

        avg_time=$(printf "%.3f" $(echo "${times[@]}" | tr ' ' '+' | bc -l / ${#times[@]}))
        min_time=${sorted[0]}
        max_time=${sorted[-1]}

        echo "$(basename "$url"),$config,$avg_time,$min_time,$max_time"
    done
done
```

These performance optimization techniques should help you get the best possible performance from curl in various scenarios.