# Curl Automation and Shell Scripting

## Shell Script Integration

### Basic Script Patterns
```bash
#!/bin/bash
# api_client.sh - Basic API client with curl

API_BASE="https://api.example.com"
API_TOKEN="your_token_here"

# Function for authenticated requests
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local url="${API_BASE}${endpoint}"
    local cmd="curl -s -X ${method}"

    cmd+=" -H 'Authorization: Bearer ${API_TOKEN}'"
    cmd+=" -H 'Content-Type: application/json'"

    if [ -n "$data" ]; then
        cmd+=" -d '${data}'"
    fi

    cmd+=" '${url}'"

    eval "$cmd"
}

# Usage examples
get_user() {
    local user_id="$1"
    api_request "GET" "/users/${user_id}"
}

create_user() {
    local name="$1"
    local email="$2"
    local data="{\"name\":\"${name}\",\"email\":\"${email}\"}"
    api_request "POST" "/users" "$data"
}

# Main execution
if [ "$1" = "get" ] && [ -n "$2" ]; then
    get_user "$2"
elif [ "$1" = "create" ] && [ -n "$2" ] && [ -n "$3" ]; then
    create_user "$2" "$3"
else
    echo "Usage: $0 get <user_id> | create <name> <email>"
    exit 1
fi
```

### Configuration Management
```bash
#!/bin/bash
# config_loader.sh - Load and validate configuration

CONFIG_FILE="$HOME/.config/api_client/config.json"

# Load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "jq is required for JSON parsing"
        exit 1
    fi

    # Validate configuration
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "Invalid JSON in configuration file"
        exit 1
    fi

    # Export configuration variables
    export API_BASE=$(jq -r '.api_base' "$CONFIG_FILE")
    export API_TOKEN=$(jq -r '.api_token' "$CONFIG_FILE")
    export TIMEOUT=$(jq -r '.timeout // 30' "$CONFIG_FILE")
    export RETRY_COUNT=$(jq -r '.retry_count // 3' "$CONFIG_FILE")

    # Validate required fields
    if [ -z "$API_BASE" ] || [ "$API_BASE" = "null" ]; then
        echo "api_base not configured"
        exit 1
    fi

    if [ -z "$API_TOKEN" ] || [ "$API_TOKEN" = "null" ]; then
        echo "api_token not configured"
        exit 1
    fi
}

# Usage
load_config
echo "API Base: $API_BASE"
echo "Timeout: ${TIMEOUT}s"
```

### Error Handling and Logging
```bash
#!/bin/bash
# robust_api_client.sh - Robust API client with error handling

set -euo pipefail

# Logging functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2
    fi
}

# HTTP status code handling
handle_response() {
    local response="$1"
    local status_code=$(echo "$response" | head -n1 | cut -d' ' -f2)
    local body=$(echo "$response" | tail -n +2)

    log_debug "HTTP Status: $status_code"
    log_debug "Response Body: $body"

    case $status_code in
        200|201|204)
            echo "$body"
            return 0
            ;;
        400)
            log_error "Bad Request: $body"
            return 1
            ;;
        401)
            log_error "Unauthorized: Check your API token"
            return 1
            ;;
        403)
            log_error "Forbidden: Insufficient permissions"
            return 1
            ;;
        404)
            log_error "Not Found: Resource does not exist"
            return 1
            ;;
        429)
            log_error "Rate Limit Exceeded: Too many requests"
            return 1
            ;;
        5*)
            log_error "Server Error: $body"
            return 1
            ;;
        *)
            log_error "Unexpected Status Code: $status_code"
            return 1
            ;;
    esac
}

# Retry logic
retry_request() {
    local max_retries="${RETRY_COUNT:-3}"
    local retry_delay="${RETRY_DELAY:-1}"
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        log_info "Attempt $attempt of $max_retries"

        if "$@"; then
            return 0
        fi

        if [ $attempt -lt $max_retries ]; then
            log_info "Retrying in ${retry_delay}s..."
            sleep $retry_delay
            retry_delay=$((retry_delay * 2))  # Exponential backoff
        fi

        ((attempt++))
    done

    log_error "All $max_retries attempts failed"
    return 1
}

# API request function
api_request() {
    local method="$1"
    local url="$2"
    shift 2
    local curl_args=("$@")

    log_info "Making $method request to $url"

    local response
    response=$(curl -s -w "\n%{http_code}" \
        --max-time "${TIMEOUT:-30}" \
        --retry 0 \
        -X "$method" \
        "${curl_args[@]}" \
        "$url" 2>&1)

    local curl_exit_code=$?
    if [ $curl_exit_code -ne 0 ]; then
        log_error "curl failed with exit code: $curl_exit_code"
        log_error "curl output: $response"
        return 1
    fi

    handle_response "$response"
}
```

### Batch Processing
```bash
#!/bin/bash
# batch_processor.sh - Process multiple API requests

# Configuration
INPUT_FILE="urls_to_process.txt"
OUTPUT_DIR="results"
PARALLEL_JOBS=5
LOG_FILE="batch_process.log"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Process single URL
process_url() {
    local url="$1"
    local output_file="${OUTPUT_DIR}/$(basename "$url").json"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] Processing: $url" >> "$LOG_FILE"

    if curl -s -L -o "$output_file" -w "%{http_code}" "$url" | grep -q "200"; then
        echo "[$timestamp] SUCCESS: $url -> $output_file" >> "$LOG_FILE"
        echo 0
    else
        echo "[$timestamp] FAILED: $url" >> "$LOG_FILE"
        echo 1
    fi
}

# Export function for parallel processing
export -f process_url
export OUTPUT_DIR LOG_FILE

# Main processing
echo "Starting batch processing at $(date)" | tee "$LOG_FILE"

if command -v parallel &> /dev/null; then
    # Use GNU parallel if available
    total=$(wc -l < "$INPUT_FILE")
    echo "Processing $total URLs with $PARALLEL_JOBS parallel jobs"

    cat "$INPUT_FILE" | parallel -j "$PARALLEL_JOBS" process_url
    success_count=$?

else
    # Fallback to sequential processing
    echo "parallel not found, processing sequentially"
    success_count=0
    total=0

    while IFS= read -r url; do
        ((total++))
        if [ $(process_url "$url") -eq 0 ]; then
            ((success_count++))
        fi
    done < "$INPUT_FILE"
fi

failed_count=$((total - success_count))

echo "Batch processing completed at $(date)" | tee -a "$LOG_FILE"
echo "Total: $total, Success: $success_count, Failed: $failed_count" | tee -a "$LOG_FILE"
```

## CI/CD Integration

### GitHub Actions Example
```yaml
# .github/workflows/api-test.yml
name: API Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  api-test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y curl jq

    - name: Test API endpoints
      env:
        API_BASE: ${{ secrets.API_BASE_URL }}
        API_TOKEN: ${{ secrets.API_TOKEN }}
      run: |
        #!/bin/bash
        set -euo pipefail

        # Test health endpoint
        echo "Testing health endpoint..."
        response=$(curl -s -w "%{http_code}" "${API_BASE}/health")
        status_code="${response: -3}"

        if [ "$status_code" != "200" ]; then
          echo "Health check failed with status: $status_code"
          exit 1
        fi

        echo "Health check passed"

        # Test authenticated endpoint
        echo "Testing authenticated endpoint..."
        user_data=$(curl -s \
          -H "Authorization: Bearer ${API_TOKEN}" \
          "${API_BASE}/user/profile")

        username=$(echo "$user_data" | jq -r '.username')
        if [ -z "$username" ] || [ "$username" = "null" ]; then
          echo "Failed to get user profile"
          exit 1
        fi

        echo "Authentication test passed for user: $username"
```

### Jenkins Pipeline Example
```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        API_BASE = credentials('api-base-url')
        API_TOKEN = credentials('api-token')
    }

    stages {
        stage('API Tests') {
            steps {
                sh '''
                    #!/bin/bash
                    set -euo pipefail

                    # Install dependencies
                    if ! command -v jq &> /dev/null; then
                        sudo apt-get update && sudo apt-get install -y jq
                    fi

                    # Run API tests
                    chmod +x scripts/api_test.sh
                    ./scripts/api_test.sh
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'test_results/*.json', allowEmptyArchive: true
            junit 'test_results/*.xml'
        }
    }
}
```

## Monitoring and Alerting

### Health Check Script
```bash
#!/bin/bash
# health_check.sh - Service health monitoring

SERVICES=(
    "https://api.example.com/health"
    "https://payment.example.com/health"
    "https://user.example.com/health"
)

ALERT_EMAIL="admin@example.com"
LOG_FILE="/var/log/health_checks.log"
TIMEOUT=10

send_alert() {
    local service="$1"
    local error="$2"

    echo "ALERT: $service - $error" | \
        mail -s "Service Alert: $service" "$ALERT_EMAIL"

    echo "[$(date)] ALERT: $service - $error" >> "$LOG_FILE"
}

check_service() {
    local service="$1"
    local service_name=$(basename "$service")

    local response
    response=$(curl -s -w "%{http_code}" \
        --max-time "$TIMEOUT" \
        "$service" 2>&1)

    local curl_exit_code=$?
    local status_code="${response: -3}"

    if [ $curl_exit_code -ne 0 ]; then
        send_alert "$service_name" "curl error: $response"
        return 1
    fi

    case $status_code in
        200)
            echo "[$(date)] OK: $service_name" >> "$LOG_FILE"
            return 0
            ;;
        503)
            send_alert "$service_name" "Service Unavailable"
            return 1
            ;;
        *)
            send_alert "$service_name" "HTTP $status_code"
            return 1
            ;;
    esac
}

# Check all services
for service in "${SERVICES[@]}"; do
    check_service "$service"
done
```

### Performance Monitoring
```bash
#!/bin/bash
# performance_monitor.sh - API performance monitoring

API_ENDPOINTS=(
    "https://api.example.com/users"
    "https://api.example.com/products"
    "https://api.example.com/orders"
)

THRESHOLD_WARNING=1000  # ms
THRESHOLD_CRITICAL=3000  # ms
RESULTS_FILE="/var/log/api_performance.csv"

measure_endpoint() {
    local endpoint="$1"
    local endpoint_name=$(basename "$endpoint")

    local response_time
    response_time=$(curl -s -o /dev/null \
        -w "%{time_total}" \
        --connect-timeout 5 \
        --max-time 10 \
        "$endpoint")

    # Convert to milliseconds
    local time_ms=$(echo "$response_time * 1000" | bc)

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint")

    # Log result
    echo "$timestamp,$endpoint_name,$time_ms,$status_code" >> "$RESULTS_FILE"

    # Check thresholds
    if (( $(echo "$time_ms > $THRESHOLD_CRITICAL" | bc -l) )); then
        echo "CRITICAL: $endpoint_name - ${time_ms}ms"
    elif (( $(echo "$time_ms > $THRESHOLD_WARNING" | bc -l) )); then
        echo "WARNING: $endpoint_name - ${time_ms}ms"
    else
        echo "OK: $endpoint_name - ${time_ms}ms"
    fi
}

# Create CSV header if file doesn't exist
if [ ! -f "$RESULTS_FILE" ]; then
    echo "timestamp,endpoint,response_time_ms,status_code" > "$RESULTS_FILE"
fi

# Measure all endpoints
for endpoint in "${API_ENDPOINTS[@]}"; do
    measure_endpoint "$endpoint"
done
```

## Data Processing Pipelines

### ETL Script with curl
```bash
#!/bin/bash
# etl_pipeline.sh - Extract, Transform, Load pipeline

# Configuration
SOURCE_API="https://source.example.com/data"
TARGET_API="https://target.example.com/data"
LOG_FILE="/var/log/etl_pipeline.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

extract() {
    log "Starting data extraction from $SOURCE_API"

    local data
    data=$(curl -s -H "Authorization: Bearer $SOURCE_TOKEN" "$SOURCE_API")

    if [ -z "$data" ]; then
        log "ERROR: No data extracted from source"
        return 1
    fi

    echo "$data" > "raw_data_$(date +%Y%m%d_%H%M%S).json"
    log "Extraction completed"
}

transform() {
    log "Starting data transformation"

    local latest_file=$(ls -t raw_data_*.json | head -n1)

    # Transform data with jq
    jq '[.items[] | {
        id: .id,
        name: .name,
        processed_at: now
        | strftime("%Y-%m-%d %H:%M:%S")
    }]' "$latest_file" > "transformed_data_$(date +%Y%m%d_%H%M%S).json"

    log "Transformation completed"
}

load() {
    log "Starting data load to $TARGET_API"

    local latest_file=$(ls -t transformed_data_*.json | head -n1)

    local response
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $TARGET_TOKEN" \
        -H "Content-Type: application/json" \
        -d @"$latest_file" \
        "$TARGET_API")

    local status=$(echo "$response" | jq -r '.status // "unknown"')

    if [ "$status" = "success" ]; then
        log "Data load completed successfully"
    else
        log "ERROR: Data load failed - $response"
        return 1
    fi
}

# Main pipeline
main() {
    log "Starting ETL pipeline"

    if extract && transform && load; then
        log "ETL pipeline completed successfully"

        # Cleanup old files
        find . -name "raw_data_*.json" -mtime +7 -delete
        find . -name "transformed_data_*.json" -mtime +7 -delete

        return 0
    else
        log "ETL pipeline failed"
        return 1
    fi
}

# Execute pipeline
main "$@"
```