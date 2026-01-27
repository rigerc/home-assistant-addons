#!/usr/bin/with-contenv bashio
# =============================================================================
# Home Assistant Add-on: Cleanuparr
# Initialization Script
# =============================================================================

# Set up error handling
set -e

bashio::log.info "Initializing Cleanuparr add-on..."

# =============================================================================
# Directory Setup
# =============================================================================

bashio::log.info "Setting up directories..."

# Create main configuration directory
CONFIG_DIR="/config/cleanuparr"
if [ ! -d "${CONFIG_DIR}" ]; then
  bashio::log.info "Creating configuration directory: ${CONFIG_DIR}"
  mkdir -p "${CONFIG_DIR}"
fi

# Create log directory
LOG_DIR="${CONFIG_DIR}/logs"
if [ ! -d "${LOG_DIR}" ]; then
  bashio::log.info "Creating log directory: ${LOG_DIR}"
  mkdir -p "${LOG_DIR}"
fi

# Create data directory
DATA_DIR="${CONFIG_DIR}/data"
if [ ! -d "${DATA_DIR}" ]; then
  bashio::log.info "Creating data directory: ${DATA_DIR}"
  mkdir -p "${DATA_DIR}"
fi

# =============================================================================
# Configuration Generation
# =============================================================================

bashio::log.info "Generating Cleanuparr configuration..."

# Create appsettings.json from Home Assistant options
# Cleanuparr stores its configuration in a JSON file
APPSETTINGS_FILE="${CONFIG_DIR}/appsettings.json"

# Get options from Home Assistant
LOG_LEVEL=$(bashio::config 'log_level')
DRY_RUN=$(bashio::config 'dry_run')
DISPLAY_SUPPORT_BANNER=$(bashio::config 'display_support_banner')
HTTP_MAX_RETRIES=$(bashio::config 'http_max_retries')
HTTP_TIMEOUT=$(bashio::config 'http_timeout')
HTTP_CERT_VALIDATION=$(bashio::config 'http_certificate_validation')
SEARCH_ENABLED=$(bashio::config 'search_enabled')
SEARCH_DELAY=$(bashio::config 'search_delay')
LOG_ROLLING_SIZE_MB=$(bashio::config 'log_rolling_size_mb')
LOG_RETAINED_FILE_COUNT=$(bashio::config 'log_retained_file_count')
LOG_TIME_LIMIT_HOURS=$(bashio::config 'log_time_limit_hours')
LOG_ARCHIVE_ENABLED=$(bashio::config 'log_archive_enabled')
LOG_ARCHIVE_RETAINED_COUNT=$(bashio::config 'log_archive_retained_count')
LOG_ARCHIVE_TIME_LIMIT_DAYS=$(bashio::config 'log_archive_time_limit_days')

# Map HA log levels to Cleanuparr log levels
case "${LOG_LEVEL}" in
  trace)
    CLEANUPARR_LOG_LEVEL="Trace"
    ;;
  debug)
    CLEANUPARR_LOG_LEVEL="Debug"
    ;;
  info)
    CLEANUPARR_LOG_LEVEL="Information"
    ;;
  notice)
    CLEANUPARR_LOG_LEVEL="Information"
    ;;
  warning)
    CLEANUPARR_LOG_LEVEL="Warning"
    ;;
  error)
    CLEANUPARR_LOG_LEVEL="Error"
    ;;
  fatal)
    CLEANUPARR_LOG_LEVEL="Fatal"
    ;;
  *)
    CLEANUPARR_LOG_LEVEL="Information"
    ;;
esac

# Convert boolean to lowercase for JSON
DRY_RUN_JSON=$(bashio::var.true "${DRY_RUN}" && echo "true" || echo "false")
DISPLAY_SUPPORT_BANNER_JSON=$(bashio::var.true "${DISPLAY_SUPPORT_BANNER}" && echo "true" || echo "false")
SEARCH_ENABLED_JSON=$(bashio::var.true "${SEARCH_ENABLED}" && echo "true" || echo "false")
LOG_ARCHIVE_ENABLED_JSON=$(bashio::var.true "${LOG_ARCHIVE_ENABLED}" && echo "true" || echo "false")

# Create the configuration file
# Only create if it doesn't exist, or if it's from an older version
# This preserves user's configuration when upgrading
if [ ! -f "${APPSETTINGS_FILE}" ]; then
  bashio::log.info "Creating new configuration file: ${APPSETTINGS_FILE}"

  cat > "${APPSETTINGS_FILE}" <<EOF
{
  "General": {
    "LogLevel": "${CLEANUPARR_LOG_LEVEL}",
    "DryRun": ${DRY_RUN_JSON},
    "DisplaySupportBanner": ${DISPLAY_SUPPORT_BANNER_JSON},
    "SearchEnabled": ${SEARCH_ENABLED_JSON},
    "SearchDelay": ${SEARCH_DELAY},
    "IgnoredDownloads": []
  },
  "Http": {
    "MaxRetries": ${HTTP_MAX_RETRIES},
    "Timeout": ${HTTP_TIMEOUT},
    "SslVerification": "${HTTP_CERT_VALIDATION}"
  },
  "Logging": {
    "LogLevel": "${CLEANUPARR_LOG_LEVEL}",
    "RollingSizeMb": ${LOG_ROLLING_SIZE_MB},
    "RetainedFileCount": ${LOG_RETAINED_FILE_COUNT},
    "TimeLimit": "${LOG_TIME_LIMIT_HOURS}:00:00",
    "ArchiveEnabled": ${LOG_ARCHIVE_ENABLED_JSON},
    "ArchiveRetainedCount": ${LOG_ARCHIVE_RETAINED_COUNT},
    "ArchiveTimeLimit": "${LOG_ARCHIVE_TIME_LIMIT_DAYS}.00:00:00"
  }
}
EOF
  bashio::log.info "Configuration file created"
else
  bashio::log.info "Configuration file already exists, preserving existing configuration"
fi

# =============================================================================
# Environment Variable Setup
# =============================================================================

bashio::log.info "Setting up environment variables..."

# Set port for Cleanuparr
# Use the Ingress port if available, otherwise use default
export PORT="11011"
export BASE_PATH=""

# Set configuration directory
export CLEANUPARR_CONFIG_DIR="${CONFIG_DIR}"

# Pass log level to environment
export CLEANUPARR_LOG_LEVEL="${CLEANUPARR_LOG_LEVEL}"

# =============================================================================
# Permission Setup
# =============================================================================

bashio::log.info "Setting permissions..."

# Ensure the configuration directory is writable
chmod -R 755 "${CONFIG_DIR}"

# =============================================================================
# Completion
# =============================================================================

bashio::log.info "Initialization complete"
bashio::log.info "Configuration directory: ${CONFIG_DIR}"
bashio::log.info "Log directory: ${LOG_DIR}"
bashio::log.info "Data directory: ${DATA_DIR}"
