#!/bin/bash
# curl_template.sh - Template for curl-based shell scripts
#
# This template provides a secure foundation for curl operations
# with proper error handling, logging, and security practices.

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.*}.log"
readonly CONFIG_FILE="${HOME}/.config/${SCRIPT_NAME%.*}/config.json"

# Default values
TIMEOUT=30
RETRY_COUNT=3
RETRY_DELAY=2
DEBUG=false

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${GREEN}[DEBUG]${NC} $*" | tee -a "$LOG_FILE"
    fi
}

# Configuration management
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        if command -v jq &> /dev/null; then
            API_BASE=$(jq -r '.api_base // empty' "$CONFIG_FILE")
            API_TOKEN=$(jq -r '.api_token // empty' "$CONFIG_FILE")
            TIMEOUT=$(jq -r '.timeout // 30' "$CONFIG_FILE")
            RETRY_COUNT=$(jq -r '.retry_count // 3' "$CONFIG_FILE")
        else
            log_warn "jq not found, using default configuration"
        fi
    fi

    # Validate required configuration
    if [[ -z "${API_BASE:-}" ]]; then
        log_error "API_BASE not configured"
        exit 1
    fi
}

# Secure curl request function
curl_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local extra_args=("$@")

    # Remove first three arguments (method, endpoint, data)
    shift 3
    local curl_opts=("$@")

    local url="${API_BASE}${endpoint}"
    log_debug "Making $method request to $url"

    # Build curl command
    local curl_cmd=(
        curl -s
        -w "\n%{http_code}"
        --max-time "$TIMEOUT"
        --retry 0  # We handle retries ourselves
        -X "$method"
    )

    # Add authentication if token is available
    if [[ -n "${API_TOKEN:-}" ]]; then
        curl_cmd+=(-H "Authorization: Bearer $API_TOKEN")
    fi

    # Add content type for data requests
    if [[ -n "$data" ]]; then
        curl_cmd+=(-H "Content-Type: application/json" -d "$data")
    fi

    # Add custom options
    curl_cmd+=("${curl_opts[@]}" "$url")

    # Execute request with retries
    local attempt=1
    while [[ $attempt -le $RETRY_COUNT ]]; do
        log_debug "Attempt $attempt of $RETRY_COUNT"

        local response
        if response=$("${curl_cmd[@]}" 2>&1); then
            local http_code="${response##*$'\n'}"
            local body="${response%$'\n'*}"

            # Handle different HTTP status codes
            case "$http_code" in
                200|201|204)
                    log_debug "Request successful (HTTP $http_code)"
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
                    log_warn "Rate limited, retrying in ${RETRY_DELAY}s..."
                    sleep $RETRY_DELAY
                    ((attempt++))
                    continue
                    ;;
                5*)
                    log_error "Server Error (HTTP $http_code): $body"
                    if [[ $attempt -lt $RETRY_COUNT ]]; then
                        sleep $RETRY_DELAY
                        ((attempt++))
                        continue
                    else
                        return 1
                    fi
                    ;;
                *)
                    log_error "Unexpected HTTP status: $http_code"
                    return 1
                    ;;
            esac
        else
            log_error "curl failed: $response"
            if [[ $attempt -lt $RETRY_COUNT ]]; then
                sleep $RETRY_DELAY
                ((attempt++))
                continue
            else
                return 1
            fi
        fi

        ((attempt++))
    done

    log_error "All $RETRY_COUNT attempts failed"
    return 1
}

# Validation functions
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        log_error "Invalid URL format: $url"
        return 1
    fi
    return 0
}

validate_json() {
    local json="$1"
    if command -v jq &> /dev/null; then
        if ! echo "$json" | jq empty 2>/dev/null; then
            log_error "Invalid JSON: $json"
            return 1
        fi
    fi
    return 0
}

# Utility functions
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] COMMAND [ARGS]

Options:
    -h, --help          Show this help message
    -d, --debug         Enable debug output
    -c, --config FILE   Use custom configuration file
    -t, --timeout SEC   Set request timeout (default: $TIMEOUT)
    -r, --retry COUNT   Set retry count (default: $RETRY_COUNT)

Commands:
    get ENDPOINT        Perform GET request
    post ENDPOINT DATA  Perform POST request with JSON data
    put ENDPOINT DATA   Perform PUT request with JSON data
    delete ENDPOINT     Perform DELETE request
    health             Check API health
    config             Show current configuration

Examples:
    $SCRIPT_NAME get /users
    $SCRIPT_NAME post /users '{"name":"John","email":"john@example.com"}'
    $SCRIPT_NAME --debug get /users/123
    $SCRIPT_NAME --timeout 60 get /large-data

Configuration file format ($CONFIG_FILE):
{
    "api_base": "https://api.example.com/v1",
    "api_token": "your_api_token_here",
    "timeout": 30,
    "retry_count": 3
}

EOF
}

show_config() {
    echo "Current Configuration:"
    echo "  API Base: ${API_BASE:-not set}"
    echo "  API Token: ${API_TOKEN:+configured}"
    echo "  Timeout: ${TIMEOUT}s"
    echo "  Retry Count: $RETRY_COUNT"
    echo "  Debug Mode: $DEBUG"
    echo "  Config File: $CONFIG_FILE"
    echo "  Log File: $LOG_FILE"
}

# Health check function
health_check() {
    log_info "Performing health check"

    if response=$(curl_request "GET" "/health"); then
        if command -v jq &> /dev/null; then
            status=$(echo "$response" | jq -r '.status // unknown')
            timestamp=$(echo "$response" | jq -r '.timestamp // empty')
            log_info "Health check: $status at $timestamp"
        else
            log_info "Health check: OK"
        fi
        return 0
    else
        log_error "Health check failed"
        return 1
    fi
}

# Main script logic
main() {
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$(dirname "$CONFIG_FILE")"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -r|--retry)
                RETRY_COUNT="$2"
                shift 2
                ;;
            get|post|put|delete|health|config)
                COMMAND="$1"
                shift
                break
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Load configuration
    load_config

    # Execute command
    case "${COMMAND:-help}" in
        get)
            if [[ $# -lt 1 ]]; then
                log_error "get command requires an endpoint"
                exit 1
            fi
            endpoint="$1"
            validate_url "${API_BASE}${endpoint}"
            curl_request "GET" "$endpoint"
            ;;
        post)
            if [[ $# -lt 2 ]]; then
                log_error "post command requires endpoint and data"
                exit 1
            fi
            endpoint="$1"
            data="$2"
            validate_json "$data"
            curl_request "POST" "$endpoint" "$data"
            ;;
        put)
            if [[ $# -lt 2 ]]; then
                log_error "put command requires endpoint and data"
                exit 1
            fi
            endpoint="$1"
            data="$2"
            validate_json "$data"
            curl_request "PUT" "$endpoint" "$data"
            ;;
        delete)
            if [[ $# -lt 1 ]]; then
                log_error "delete command requires an endpoint"
                exit 1
            fi
            endpoint="$1"
            curl_request "DELETE" "$endpoint"
            ;;
        health)
            health_check
            ;;
        config)
            show_config
            ;;
        help|"")
            show_help
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# Trap for cleanup
cleanup() {
    log_debug "Script finished"
}
trap cleanup EXIT

# Start script
log_debug "Starting $SCRIPT_NAME with arguments: $*"
main "$@"