#!/bin/bash
# ==============================================================================
# Home Assistant Add-on Discovery Script
# Inspects GitHub repositories or Docker images to extract useful information
# for creating Home Assistant add-ons
# ==============================================================================

set -o errexit
set -o nounset
set -o pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Global variables
TEMP_DIR=""
TARGET=""
TARGET_TYPE=""

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

log_error() {
    echo -e "${RED}✗${NC} ${1}" >&2
}

log_section() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}${1}${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_dependencies() {
    local missing_deps=()

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v git &> /dev/null; then
        log_warning "git not found - GitHub repository cloning will be limited"
    fi

    if ! command -v docker &> /dev/null; then
        log_warning "docker not found - Docker image inspection will be unavailable"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them and try again"
        exit 1
    fi
}

cleanup() {
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}

trap cleanup EXIT

# ==============================================================================
# GitHub Repository Analysis
# ==============================================================================

detect_target_type() {
    if [[ "${TARGET}" =~ ^https?://github\.com/ ]] || [[ "${TARGET}" =~ ^github\.com/ ]]; then
        TARGET_TYPE="github"
    elif [[ "${TARGET}" =~ : ]] || [[ "${TARGET}" =~ ^[a-z0-9-]+/[a-z0-9-]+ ]]; then
        TARGET_TYPE="docker"
    else
        log_error "Unable to detect target type. Expected GitHub URL or Docker image name"
        exit 1
    fi
}

normalize_github_url() {
    # Remove trailing slashes and .git
    TARGET="${TARGET%.git}"
    TARGET="${TARGET%/}"

    # Extract owner/repo
    if [[ "${TARGET}" =~ github\.com/([^/]+)/([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        log_error "Invalid GitHub URL format"
        exit 1
    fi
}

fetch_github_repo() {
    local repo_path
    repo_path=$(normalize_github_url)

    log_section "GitHub Repository: ${repo_path}"

    # Fetch repository metadata
    log_info "Fetching repository metadata..."
    local api_url="https://api.github.com/repos/${repo_path}"
    local repo_data

    if ! repo_data=$(curl -sf "${api_url}"); then
        log_error "Failed to fetch repository metadata"
        exit 1
    fi

    # Extract basic info
    local description
    local stars
    local language
    local license

    description=$(echo "${repo_data}" | jq -r '.description // "N/A"')
    stars=$(echo "${repo_data}" | jq -r '.stargazers_count // 0')
    language=$(echo "${repo_data}" | jq -r '.language // "N/A"')
    license=$(echo "${repo_data}" | jq -r '.license.name // "N/A"')

    echo "Description:  ${description}"
    echo "Stars:        ${stars}"
    echo "Language:     ${language}"
    echo "License:      ${license}"

    # Clone repository to temp dir
    TEMP_DIR=$(mktemp -d)
    log_info "Cloning repository to ${TEMP_DIR}..."

    if command -v git &> /dev/null; then
        if ! git clone -q --depth=1 "https://github.com/${repo_path}.git" "${TEMP_DIR}" 2>/dev/null; then
            log_error "Failed to clone repository"
            exit 1
        fi
        log_success "Repository cloned successfully"
    else
        log_warning "git not available - downloading archive instead"
        local archive_url="https://github.com/${repo_path}/archive/refs/heads/main.tar.gz"
        if ! curl -sfL "${archive_url}" | tar -xz -C "${TEMP_DIR}" --strip-components=1 2>/dev/null; then
            archive_url="https://github.com/${repo_path}/archive/refs/heads/master.tar.gz"
            if ! curl -sfL "${archive_url}" | tar -xz -C "${TEMP_DIR}" --strip-components=1 2>/dev/null; then
                log_error "Failed to download repository archive"
                exit 1
            fi
        fi
        log_success "Repository downloaded successfully"
    fi

    analyze_repository
}

analyze_repository() {
    log_section "Repository Analysis"

    # Find Dockerfiles
    log_info "Searching for Dockerfiles..."
    local dockerfiles
    dockerfiles=$(find "${TEMP_DIR}" -name "Dockerfile*" -type f 2>/dev/null || true)

    if [[ -n "${dockerfiles}" ]]; then
        log_success "Found Dockerfile(s):"
        echo "${dockerfiles}" | while read -r dockerfile; do
            local rel_path="${dockerfile#${TEMP_DIR}/}"
            echo "  - ${rel_path}"
            analyze_dockerfile "${dockerfile}"
        done
    else
        log_warning "No Dockerfile found"
    fi

    # Check for docker-compose
    log_info "Checking for docker-compose files..."
    local compose_files
    compose_files=$(find "${TEMP_DIR}" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" 2>/dev/null || true)

    if [[ -n "${compose_files}" ]]; then
        log_success "Found docker-compose file(s):"
        echo "${compose_files}" | while read -r compose_file; do
            local rel_path="${compose_file#${TEMP_DIR}/}"
            echo "  - ${rel_path}"
            analyze_docker_compose "${compose_file}"
        done
    fi

    # Check for documentation
    log_info "Checking for documentation..."
    if [[ -f "${TEMP_DIR}/README.md" ]]; then
        log_success "Found README.md"
        extract_readme_info "${TEMP_DIR}/README.md"
    fi

    # Check for common config files
    check_config_files
}

analyze_dockerfile() {
    local dockerfile="${1}"

    log_section "Dockerfile Analysis: $(basename "${dockerfile}")"

    # Base image
    local base_images
    base_images=$(grep -E "^FROM " "${dockerfile}" | awk '{print $2}' || true)
    if [[ -n "${base_images}" ]]; then
        echo -e "${BOLD}Base Images:${NC}"
        echo "${base_images}" | while read -r image; do
            echo "  - ${image}"
            detect_base_os "${image}"
        done
    fi

    # Exposed ports
    local ports
    ports=$(grep -E "^EXPOSE " "${dockerfile}" | awk '{for(i=2;i<=NF;i++) print $i}' || true)
    if [[ -n "${ports}" ]]; then
        echo -e "\n${BOLD}Exposed Ports:${NC}"
        echo "${ports}" | while read -r port; do
            echo "  - ${port}"
        done
    fi

    # Volumes
    local volumes
    volumes=$(grep -E "^VOLUME " "${dockerfile}" | sed 's/VOLUME //g' | tr -d '[]"' | tr ',' '\n' || true)
    if [[ -n "${volumes}" ]]; then
        echo -e "\n${BOLD}Volumes:${NC}"
        echo "${volumes}" | while read -r volume; do
            echo "  - ${volume}"
        done
    fi

    # Environment variables
    local envs
    envs=$(grep -E "^ENV " "${dockerfile}" | sed 's/^ENV //g' || true)
    if [[ -n "${envs}" ]]; then
        echo -e "\n${BOLD}Environment Variables:${NC}"
        echo "${envs}" | while read -r env; do
            echo "  - ${env}"
        done
    fi

    # Package installations (RUN commands)
    echo -e "\n${BOLD}Package Installations:${NC}"
    analyze_package_installations "${dockerfile}"

    # Entrypoint and CMD
    local entrypoint
    entrypoint=$(grep -E "^ENTRYPOINT " "${dockerfile}" | tail -1 || true)
    if [[ -n "${entrypoint}" ]]; then
        echo -e "\n${BOLD}Entrypoint:${NC}"
        echo "  ${entrypoint}"
    fi

    local cmd
    cmd=$(grep -E "^CMD " "${dockerfile}" | tail -1 || true)
    if [[ -n "${cmd}" ]]; then
        echo -e "\n${BOLD}CMD:${NC}"
        echo "  ${cmd}"
    fi

    # Architecture detection
    detect_architectures "${dockerfile}"
}

detect_base_os() {
    local image="${1}"
    local os="Unknown"

    if [[ "${image}" =~ alpine ]]; then
        os="Alpine Linux"
    elif [[ "${image}" =~ debian|ubuntu ]]; then
        os="Debian-based"
    elif [[ "${image}" =~ centos|rhel|fedora ]]; then
        os="RedHat-based"
    elif [[ "${image}" =~ scratch ]]; then
        os="Scratch (minimal)"
    fi

    echo "    OS: ${os}"
}

analyze_package_installations() {
    local dockerfile="${1}"

    # Alpine packages
    local apk_packages
    apk_packages=$(grep -E "apk (add|--no-cache)" "${dockerfile}" | sed -E 's/.*apk (add|--no-cache) //' | tr '\n' ' ' || true)
    if [[ -n "${apk_packages}" ]]; then
        echo "  Alpine (apk): ${apk_packages}"
    fi

    # Debian/Ubuntu packages
    local apt_packages
    apt_packages=$(grep -E "apt-get install|apt install" "${dockerfile}" | sed -E 's/.*(apt-get install|apt install) //' | tr '\n' ' ' || true)
    if [[ -n "${apt_packages}" ]]; then
        echo "  Debian (apt): ${apt_packages}"
    fi

    # Python packages
    local pip_packages
    pip_packages=$(grep -E "pip install" "${dockerfile}" | sed -E 's/.*pip install //' | tr '\n' ' ' || true)
    if [[ -n "${pip_packages}" ]]; then
        echo "  Python (pip): ${pip_packages}"
    fi

    # Node packages
    local npm_packages
    npm_packages=$(grep -E "npm install" "${dockerfile}" | sed -E 's/.*npm install //' | tr '\n' ' ' || true)
    if [[ -n "${npm_packages}" ]]; then
        echo "  Node (npm): ${npm_packages}"
    fi
}

detect_architectures() {
    local dockerfile="${1}"

    echo -e "\n${BOLD}Architecture Support:${NC}"

    # Check for TARGETARCH variable
    if grep -q "TARGETARCH" "${dockerfile}"; then
        log_success "Multi-architecture support detected (BuildKit TARGETARCH)"
        echo "  Supports: likely amd64, aarch64, armv7, etc."
    fi

    # Check for explicit architecture references
    if grep -qE "amd64|x86_64" "${dockerfile}"; then
        echo "  - amd64 (x86_64) detected"
    fi
    if grep -qE "arm64|aarch64" "${dockerfile}"; then
        echo "  - aarch64 (arm64) detected"
    fi
    if grep -qE "armv7|armhf" "${dockerfile}"; then
        echo "  - armv7/armhf detected"
    fi
}

analyze_docker_compose() {
    local compose_file="${1}"

    log_section "Docker Compose Analysis"

    # Extract services
    echo -e "${BOLD}Services:${NC}"
    local services
    services=$(grep -E "^  [a-z]" "${compose_file}" | sed 's/:$//' | sed 's/^  //' || true)
    echo "${services}" | while read -r service; do
        echo "  - ${service}"
    done

    # Extract ports
    echo -e "\n${BOLD}Ports:${NC}"
    local ports
    ports=$(grep -A 10 "ports:" "${compose_file}" | grep -E "^\s+- " | sed 's/^\s*- //' | tr -d '"' || true)
    if [[ -n "${ports}" ]]; then
        echo "${ports}" | while read -r port; do
            echo "  - ${port}"
        done
    else
        echo "  None defined"
    fi

    # Extract volumes
    echo -e "\n${BOLD}Volumes:${NC}"
    local volumes
    volumes=$(grep -A 10 "volumes:" "${compose_file}" | grep -E "^\s+- " | sed 's/^\s*- //' || true)
    if [[ -n "${volumes}" ]]; then
        echo "${volumes}" | while read -r volume; do
            echo "  - ${volume}"
        done
    else
        echo "  None defined"
    fi
}

extract_readme_info() {
    local readme="${1}"

    log_section "README Information"

    # Try to extract port information
    echo -e "${BOLD}Port References:${NC}"
    local port_refs
    port_refs=$(grep -oE ":[0-9]{2,5}" "${readme}" | sort -u || true)
    if [[ -n "${port_refs}" ]]; then
        echo "${port_refs}" | while read -r port; do
            echo "  - ${port}"
        done
    else
        echo "  None found"
    fi

    # Check for environment variables section
    if grep -qi "environment variable" "${readme}"; then
        log_success "Environment variables section found in README"
    fi

    # Check for configuration section
    if grep -qi "configuration\|config" "${readme}"; then
        log_success "Configuration section found in README"
    fi
}

check_config_files() {
    log_section "Configuration Files"

    # Check for common config file patterns
    local config_patterns=(
        "*.conf"
        "*.config"
        "*.ini"
        "*.yaml"
        "*.yml"
        "*.toml"
        "*.json"
        ".env*"
    )

    for pattern in "${config_patterns[@]}"; do
        local files
        files=$(find "${TEMP_DIR}" -name "${pattern}" -type f 2>/dev/null | head -5 || true)
        if [[ -n "${files}" ]]; then
            echo "Found ${pattern} files:"
            echo "${files}" | while read -r file; do
                local rel_path="${file#${TEMP_DIR}/}"
                echo "  - ${rel_path}"
            done
        fi
    done
}

# ==============================================================================
# Docker Image Analysis
# ==============================================================================

analyze_docker_image() {
    local image="${TARGET}"

    log_section "Docker Image: ${image}"

    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not available"
        log_error "Please install Docker to inspect Docker images"
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_error "Please start Docker and try again"
        exit 1
    fi

    # Try to pull image metadata without pulling the entire image
    log_info "Fetching image manifest..."

    # Pull the image
    log_info "Pulling image (this may take a while)..."
    if ! docker pull "${image}" &> /dev/null; then
        log_error "Failed to pull image"
        exit 1
    fi
    log_success "Image pulled successfully"

    # Inspect the image
    log_info "Inspecting image..."
    local inspect_data
    inspect_data=$(docker inspect "${image}")

    # Extract architecture
    echo -e "\n${BOLD}Architecture:${NC}"
    local arch
    arch=$(echo "${inspect_data}" | jq -r '.[0].Architecture // "unknown"')
    echo "  ${arch}"

    # Extract OS
    echo -e "\n${BOLD}Operating System:${NC}"
    local os
    os=$(echo "${inspect_data}" | jq -r '.[0].Os // "unknown"')
    echo "  ${os}"

    # Extract exposed ports
    echo -e "\n${BOLD}Exposed Ports:${NC}"
    local ports
    ports=$(echo "${inspect_data}" | jq -r '.[0].Config.ExposedPorts // {} | keys[]' 2>/dev/null || true)
    if [[ -n "${ports}" ]]; then
        echo "${ports}" | while read -r port; do
            echo "  - ${port}"
        done
    else
        echo "  None"
    fi

    # Extract environment variables
    echo -e "\n${BOLD}Environment Variables:${NC}"
    local envs
    envs=$(echo "${inspect_data}" | jq -r '.[0].Config.Env[]' 2>/dev/null || true)
    if [[ -n "${envs}" ]]; then
        echo "${envs}" | while read -r env; do
            echo "  - ${env}"
        done
    else
        echo "  None"
    fi

    # Extract volumes
    echo -e "\n${BOLD}Volumes:${NC}"
    local volumes
    volumes=$(echo "${inspect_data}" | jq -r '.[0].Config.Volumes // {} | keys[]' 2>/dev/null || true)
    if [[ -n "${volumes}" ]]; then
        echo "${volumes}" | while read -r volume; do
            echo "  - ${volume}"
        done
    else
        echo "  None"
    fi

    # Extract entrypoint
    echo -e "\n${BOLD}Entrypoint:${NC}"
    local entrypoint
    entrypoint=$(echo "${inspect_data}" | jq -r '.[0].Config.Entrypoint // [] | join(" ")' 2>/dev/null || true)
    if [[ -n "${entrypoint}" ]]; then
        echo "  ${entrypoint}"
    else
        echo "  None"
    fi

    # Extract CMD
    echo -e "\n${BOLD}CMD:${NC}"
    local cmd
    cmd=$(echo "${inspect_data}" | jq -r '.[0].Config.Cmd // [] | join(" ")' 2>/dev/null || true)
    if [[ -n "${cmd}" ]]; then
        echo "  ${cmd}"
    else
        echo "  None"
    fi

    # Extract working directory
    echo -e "\n${BOLD}Working Directory:${NC}"
    local workdir
    workdir=$(echo "${inspect_data}" | jq -r '.[0].Config.WorkingDir // "/"' 2>/dev/null || true)
    echo "  ${workdir}"

    # Extract user
    echo -e "\n${BOLD}User:${NC}"
    local user
    user=$(echo "${inspect_data}" | jq -r '.[0].Config.User // "root"' 2>/dev/null || true)
    echo "  ${user}"

    # Extract labels
    echo -e "\n${BOLD}Labels:${NC}"
    local labels
    labels=$(echo "${inspect_data}" | jq -r '.[0].Config.Labels // {} | to_entries[] | .key + "=" + .value' 2>/dev/null || true)
    if [[ -n "${labels}" ]]; then
        echo "${labels}" | while read -r label; do
            echo "  - ${label}"
        done
    else
        echo "  None"
    fi

    # Image size
    echo -e "\n${BOLD}Image Size:${NC}"
    local size
    size=$(echo "${inspect_data}" | jq -r '.[0].Size' 2>/dev/null || true)
    if [[ -n "${size}" ]]; then
        local size_mb=$((size / 1024 / 1024))
        echo "  ${size_mb} MB"
    fi

    # Check for multi-arch support
    check_multiarch_support "${image}"
}

check_multiarch_support() {
    local image="${1}"

    log_section "Multi-Architecture Support"

    # Try to get manifest list (for multi-arch images)
    log_info "Checking for multi-architecture manifest..."

    local manifest
    if manifest=$(docker manifest inspect "${image}" 2>/dev/null); then
        log_success "Multi-architecture image detected"
        echo ""
        echo -e "${BOLD}Available Platforms:${NC}"
        echo "${manifest}" | jq -r '.manifests[] | "  - " + .platform.os + "/" + .platform.architecture' 2>/dev/null || true
    else
        log_warning "Single architecture image or manifest not available"
    fi
}

# ==============================================================================
# Summary and Recommendations
# ==============================================================================

generate_recommendations() {
    log_section "Recommendations for Home Assistant Add-on"

    echo -e "${BOLD}Configuration (config.yaml):${NC}"
    echo "  - Set appropriate arch: (amd64, aarch64, armv7, armhf, i386)"
    echo "  - Define ports and ports_description based on exposed ports"
    echo "  - Consider using ingress: true for web interfaces"
    echo "  - Add map: entries for volumes (share, config, etc.)"
    echo ""

    echo -e "${BOLD}Dockerfile:${NC}"
    echo "  - Use Home Assistant base image: ghcr.io/home-assistant/\${BUILD_ARCH}-base"
    echo "  - Copy rootfs structure with: COPY rootfs /"
    echo "  - Ensure scripts are executable"
    echo "  - Consider multi-stage builds for smaller images"
    echo ""

    echo -e "${BOLD}Services (s6-overlay v2):${NC}"
    echo "  - Create service in: rootfs/etc/services.d/[service-name]/"
    echo "  - Add run script: executable script that starts service in foreground"
    echo "  - Add finish script: handle service crashes/exit"
    echo "  - Use bashio for logging and config access"
    echo ""

    echo -e "${BOLD}Initialization (cont-init.d):${NC}"
    echo "  - Create init scripts in: rootfs/etc/cont-init.d/"
    echo "  - Use numeric prefixes: 00-*, 01-*, etc."
    echo "  - Validate configuration, create directories, run migrations"
    echo ""

    echo -e "${BOLD}Next Steps:${NC}"
    echo "  1. Copy scaffold files to new add-on directory"
    echo "  2. Update config.yaml with discovered values"
    echo "  3. Adapt Dockerfile with identified base image and packages"
    echo "  4. Create s6-overlay service definitions"
    echo "  5. Add initialization scripts as needed"
    echo "  6. Write documentation (README.md, DOCS.md)"
    echo "  7. Test the add-on locally"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

show_usage() {
    cat << EOF
${BOLD}Usage:${NC} ${0} <github-url|docker-image>

${BOLD}Description:${NC}
  Inspects GitHub repositories or Docker images to extract useful information
  for creating Home Assistant add-ons.

${BOLD}Examples:${NC}
  ${0} https://github.com/user/repo
  ${0} linuxserver/plex:latest
  ${0} ghcr.io/user/image:tag

${BOLD}Requirements:${NC}
  - curl (required)
  - jq (required)
  - git (optional, for cloning repositories)
  - docker (required for Docker image inspection)

EOF
}

main() {
    if [[ $# -eq 0 ]] || [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]]; then
        show_usage
        exit 0
    fi

    TARGET="${1}"

    echo -e "${BOLD}${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║      Home Assistant Add-on Discovery Tool                    ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check dependencies
    check_dependencies

    # Detect target type
    detect_target_type

    # Analyze based on type
    if [[ "${TARGET_TYPE}" == "github" ]]; then
        fetch_github_repo
    elif [[ "${TARGET_TYPE}" == "docker" ]]; then
        analyze_docker_image
    fi

    # Generate recommendations
    generate_recommendations

    log_success "Discovery complete!"
}

main "$@"
