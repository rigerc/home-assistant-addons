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

log_fatal() {
    echo -e "${RED}✗${NC} Stop and inform the user that the discovery script failed, summarize why and suggest possible next steps and wait for further instructions." >&2
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
    local curl_exit_code=0

    if ! repo_data=$(curl -sfS "${api_url}" 2>&1); then
        curl_exit_code=$?
        log_error "Failed to fetch repository metadata (exit code: ${curl_exit_code})"
        case ${curl_exit_code} in
            6)
                log_error "Reason: Could not resolve host - check network connection"
                log_error "Suggestion: Verify internet connectivity or check DNS settings"
                ;;
            22|404)
                log_error "Reason: Repository not found (404) - verify owner/repo name"
                log_error "Suggestion: Check the URL spelling and ensure the repository exists"
                ;;
            28)
                log_error "Reason: Operation timeout - server took too long to respond"
                log_error "Suggestion: Check network connection or try again later"
                ;;
            *)
                log_error "Reason: $(echo "${repo_data}" | head -1)"
                ;;
        esac
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
        local git_output
        local git_exit_code=0
        if ! git_output=$(git clone --depth=1 "https://github.com/${repo_path}.git" "${TEMP_DIR}" 2>&1); then
            git_exit_code=$?
            log_error "Failed to clone repository (exit code: ${git_exit_code})"
            echo "${git_output}" >&2
            case ${git_exit_code} in
                128)
                    if echo "${git_output}" | grep -qi "repository not found"; then
                        log_error "Reason: Repository does not exist or was renamed"
                        log_error "Suggestion: Verify the repository URL and check if it's private"
                    elif echo "${git_output}" | grep -qi "permission denied\|access denied"; then
                        log_error "Reason: Access denied - repository may be private"
                        log_error "Suggestion: If private, use SSH or add GitHub authentication"
                    else
                        log_error "Reason: Repository does not exist or access denied"
                    fi
                    ;;
                124)
                    log_error "Reason: Git operation timed out"
                    log_error "Suggestion: Check network connection or increase git timeout"
                    ;;
                *)
                    log_error "Reason: See git output above"
                    ;;
            esac
            exit 1
        fi
        log_success "Repository cloned successfully"
    else
        log_warning "git not available - downloading archive instead"
        local archive_url="https://github.com/${repo_path}/archive/refs/heads/main.tar.gz"
        local curl_exit_code=0
        local curl_output

        if ! curl_output=$(curl -sfL "${archive_url}" 2>&1); then
            curl_exit_code=$?
            # Try master branch
            archive_url="https://github.com/${repo_path}/archive/refs/heads/master.tar.gz"
            if ! curl_output=$(curl -sfL "${archive_url}" 2>&1); then
                curl_exit_code=$?
                log_error "Failed to download repository archive (exit code: ${curl_exit_code})"
                case ${curl_exit_code} in
                    22)
                        log_error "Reason: Archive not found - repository may use different default branch"
                        log_error "Suggestion: Install git and re-run, or check repository for default branch name"
                        ;;
                    28)
                        log_error "Reason: Download timeout"
                        log_error "Suggestion: Check network connection or try again later"
                        ;;
                    *)
                        log_error "Reason: $(echo "${curl_output}" | head -1)"
                        ;;
                esac
                exit 1
            fi
        fi

        # Extract the archive
        if ! echo "${curl_output}" | tar -xz -C "${TEMP_DIR}" --strip-components=1 2>&1; then
            log_error "Failed to extract repository archive"
            exit 1
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
    compose_files=$(find "${TEMP_DIR}" \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) 2>/dev/null || true)

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

        # Extract and display entrypoint file contents
        local entrypoint_path=""
        # Parse entrypoint path from exec form: ENTRYPOINT ["/path", "arg"]
        if [[ "${entrypoint}" =~ ENTRYPOINT\ \[(.*)\] ]]; then
            entrypoint_path=$(echo "${BASH_REMATCH[1]}" | jq -r '.[0]' 2>/dev/null || echo "${BASH_REMATCH[1]}" | cut -d'"' -f2)
        # Parse entrypoint path from shell form: ENTRYPOINT /path arg1
        elif [[ "${entrypoint}" =~ ENTRYPOINT\ (.+) ]]; then
            entrypoint_path=$(echo "${BASH_REMATCH[1]}" | awk '{print $1}' | tr -d '"')
        fi

        if [[ -n "${entrypoint_path}" ]]; then
            extract_entrypoint_contents "${dockerfile}" "${entrypoint_path}"
        fi
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

extract_entrypoint_contents() {
    local dockerfile="${1}"
    local entrypoint_path="${2}"

    log_section "Entrypoint File Contents: ${entrypoint_path}"

    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not available - cannot extract entrypoint contents"
        return 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_warning "Docker daemon is not running - cannot extract entrypoint contents"
        return 1
    fi

    # Build a temporary image from the Dockerfile
    local temp_image
    temp_image="temp-discovery-$(date +%s)"
    local temp_dir
    temp_dir=$(mktemp -d)

    log_info "Building temporary image to extract entrypoint..."
    local docker_output
    if ! docker_output=$(docker build -t "${temp_image}" -f "${dockerfile}" "${temp_dir}" 2>&1); then
        log_warning "Failed to build image - cannot extract entrypoint contents"
        rm -rf "${temp_dir}"
        return 1
    fi

    # Extract and display the entrypoint file contents
    log_info "Extracting entrypoint file..."
    local entrypoint_contents
    if entrypoint_contents=$(docker run --rm --entrypoint /bin/sh "${temp_image}" -c "cat ${entrypoint_path}" 2>/dev/null); then
        echo ""
        echo -e "${BOLD}#!/bin/bash style entrypoint detected${NC}"
        echo ""
        echo "${entrypoint_contents}"
        log_success "Entrypoint file extracted successfully"
    else
        log_warning "Failed to read entrypoint file (file may not exist or container failed to start)"
    fi

    # Cleanup
    docker rmi "${temp_image}" &>/dev/null || true
    rm -rf "${temp_dir}"
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
        log_warning "armv7/armhf detected - these architectures are NOT supported by Home Assistant"
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
        log_error "Reason: Docker executable not found in PATH"
        log_error "Suggestion: Install Docker from https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_error "Reason: Cannot communicate with Docker daemon"
        log_error "Suggestion: Start Docker service (e.g., 'sudo systemctl start docker' or 'sudo service docker start')"
        exit 1
    fi

    # Check if image exists locally, pull if needed
    log_info "Checking for image locally..."
    if ! docker image inspect "${image}" &> /dev/null; then
        log_info "Image not found locally, pulling (this may take a while)..."
        local docker_output
        local docker_exit_code=0

        if ! docker_output=$(docker pull "${image}" 2>&1); then
            docker_exit_code=$?
            log_error "Failed to pull image (exit code: ${docker_exit_code})"
            echo "${docker_output}" >&2

            # Parse common Docker error patterns
            if echo "${docker_output}" | grep -qi "manifest.*not found"; then
                log_error "Reason: Image manifest not found - the image or tag may not exist"
                log_error "Suggestion: Verify image name and tag, or check available tags with 'docker search <name>'"
            elif echo "${docker_output}" | grep -qi "denied\|unauthorized"; then
                log_error "Reason: Access denied - you may need to login to the registry"
                log_error "Suggestion: Run 'docker login <registry>' and try again"
            elif echo "${docker_output}" | grep -qi "pull access denied"; then
                log_error "Reason: Pull access denied - image may be private or require authentication"
                log_error "Suggestion: Login to registry or check if image requires acceptance of license terms"
            elif echo "${docker_output}" | grep -qi "no match for platform"; then
                log_error "Reason: No matching platform/architecture - image not available for your system"
                log_error "Suggestion: Check if image supports your architecture (amd64, arm64, etc.) or try a different tag"
            elif echo "${docker_output}" | grep -qi "connection.*refused\|timeout\|network"; then
                log_error "Reason: Network error - cannot connect to registry"
                log_error "Suggestion: Check your internet connection and registry availability"
            elif echo "${docker_output}" | grep -qi "tls\|certificate\|ssl"; then
                log_error "Reason: TLS/SSL certificate error - registry connection issue"
                log_error "Suggestion: Check system certificates or try insecure registry (not recommended): '--insecure-skip-verify'"
            elif echo "${docker_output}" | grep -qi "disk.*full\|no space"; then
                log_error "Reason: Insufficient disk space to pull image"
                log_error "Suggestion: Free up disk space or prune Docker images: 'docker system prune -a'"
            elif echo "${docker_output}" | grep -qi "quota.*exceeded"; then
                log_error "Reason: Registry quota exceeded - rate limiting may apply"
                log_error "Suggestion: Wait before retrying or authenticate to increase rate limits"
            else
                log_error "Reason: See Docker output above for details"
            fi
            exit 1
        fi
        log_success "Image pulled successfully"
    else
        log_success "Using local image"
    fi

    # Analyze using docker history (primary method)
    analyze_docker_history "${image}"

    # Also run docker inspect for additional metadata
    analyze_docker_inspect "${image}"

    # Check for multi-arch support
    check_multiarch_support "${image}"
}

analyze_docker_history() {
    local image="${1}"

    log_section "Docker History Analysis"

    log_info "Analyzing image layers..."
    local history_output
    local history_exit_code=0

    if ! history_output=$(docker history "${image}" --no-trunc 2>&1); then
        history_exit_code=$?
        log_error "Failed to get image history (exit code: ${history_exit_code})"
        echo "${history_output}" >&2
        return
    fi

    # Detect base OS from history commands
    detect_base_os_from_history "${history_output}"

    # Extract information from layers
    echo -e "\n${BOLD}Layer Information:${NC}"

    # Extract CMD layers
    local cmd_layers
    cmd_layers=$(echo "${history_output}" | grep -E "^.*CMD\s+" | head -5 || true)
    if [[ -n "${cmd_layers}" ]]; then
        echo -e "\n${BOLD}CMD Commands:${NC}"
        echo "${cmd_layers}" | while read -r layer; do
            local cmd
            cmd=$(echo "${layer}" | sed -E 's/^.*CMD\s+(.*)$/\1/' | sed -E 's/\s+# buildkit.*$//' | tr -d '\[\]"' | xargs)
            if [[ -n "${cmd}" ]]; then
                echo "  - ${cmd}"
            fi
        done
    fi

    # Extract ENTRYPOINT layers
    local entrypoint_layers
    entrypoint_layers=$(echo "${history_output}" | grep -E "^.*ENTRYPOINT\s+" | head -3 || true)
    if [[ -n "${entrypoint_layers}" ]]; then
        echo -e "\n${BOLD}ENTRYPOINT Commands:${NC}"
        echo "${entrypoint_layers}" | while read -r layer; do
            local entrypoint
            entrypoint=$(echo "${layer}" | sed -E 's/^.*ENTRYPOINT\s+(.*)$/\1/' | sed -E 's/\s+# buildkit.*$//' | tr -d '\[\]"' | xargs)
            if [[ -n "${entrypoint}" ]]; then
                echo "  - ${entrypoint}"
            fi
        done
    fi

    # Extract EXPOSE layers
    local expose_layers
    expose_layers=$(echo "${history_output}" | grep -E "^.*EXPOSE\s+" | head -10 || true)
    if [[ -n "${expose_layers}" ]]; then
        echo -e "\n${BOLD}Exposed Ports (from history):${NC}"
        echo "${expose_layers}" | while read -r layer; do
            local ports
            ports=$(echo "${layer}" | sed -E 's/^.*EXPOSE\s+(.*)$/\1/' | sed -E 's/\s+# buildkit.*$//' | tr -d '\[\]"' | xargs)
            if [[ -n "${ports}" ]]; then
                echo "  - ${ports}"
            fi
        done
    fi

    # Extract ENV layers
    local env_layers
    env_layers=$(echo "${history_output}" | grep -E "^.*ENV\s+" | grep -v "^#.*ENV" | head -20 || true)
    if [[ -n "${env_layers}" ]]; then
        echo -e "\n${BOLD}Environment Variables (from history):${NC}"
        echo "${env_layers}" | while read -r layer; do
            local env
            env=$(echo "${layer}" | sed -E 's/^.*ENV\s+(.*)$/\1/' | sed -E 's/\s+# buildkit.*$//' | xargs)
            if [[ -n "${env}" ]]; then
                echo "  - ${env}"
            fi
        done
    fi

    # Extract WORKDIR layers
    local workdir_layers
    workdir_layers=$(echo "${history_output}" | grep -E "^.*WORKDIR\s+" | head -5 || true)
    if [[ -n "${workdir_layers}" ]]; then
        echo -e "\n${BOLD}Working Directories:${NC}"
        echo "${workdir_layers}" | while read -r layer; do
            local workdir
            workdir=$(echo "${layer}" | sed -E 's/^.*WORKDIR\s+(.*)$/\1/' | sed -E 's/\s+# buildkit.*$//' | tr -d '\[\]"' | xargs)
            if [[ -n "${workdir}" ]]; then
                echo "  - ${workdir}"
            fi
        done
    fi

    # Extract RUN commands for package installations
    echo -e "\n${BOLD}Package Installations (from RUN commands):${NC}"
    analyze_run_commands "${history_output}"

    # Extract VOLUME layers
    local volume_layers
    volume_layers=$(echo "${history_output}" | grep -E "^.*VOLUME\s+" | head -10 || true)
    if [[ -n "${volume_layers}" ]]; then
        echo -e "\n${BOLD}Volumes (from history):${NC}"
        echo "${volume_layers}" | while read -r layer; do
            local volumes
            volumes=$(echo "${layer}" | sed -E 's/^.*VOLUME\s+(.*)$/\1/' | sed -E 's/\s+# buildkit.*$//' | tr -d '\[\]"' | tr ',' '\n' | xargs)
            if [[ -n "${volumes}" ]]; then
                echo "  - ${volumes}"
            fi
        done
    fi

    # Layer count and total size
    local layer_count
    layer_count=$(echo "${history_output}" | grep -c -v "^IMAGE" || true)
    echo -e "\n${BOLD}Image Statistics:${NC}"
    echo "  Total layers: ${layer_count}"

    # Calculate total size (handle both B and human-readable formats)
    local total_size
    total_size=$(echo "${history_output}" | tail -n +2 | awk '{
        size_field = $NF
        # Remove B suffix if present
        gsub(/B$/, "", size_field)
        # Convert human-readable sizes to bytes
        if (size_field ~ /KB$/) {
            val = substr(size_field, 1, length(size_field)-2)
            size += val * 1024
        } else if (size_field ~ /MB$/) {
            val = substr(size_field, 1, length(size_field)-2)
            size += val * 1024 * 1024
        } else if (size_field ~ /GB$/) {
            val = substr(size_field, 1, length(size_field)-2)
            size += val * 1024 * 1024 * 1024
        } else if (size_field ~ /^[0-9.]+$/) {
            # Already in bytes (numeric only)
            size += size_field
        }
    } END {printf "%.0f", size}' || true)
    if [[ -n "${total_size}" && "${total_size}" != "0" ]]; then
        local size_mb
        size_mb=$(awk "BEGIN {printf \"%.2f\", ${total_size} / 1024 / 1024}")
        echo "  Total size: ${size_mb} MB"
    fi
}

detect_base_os_from_history() {
    local history="${1}"

    echo -e "${BOLD}Base OS Detection:${NC}"

    # Look for package manager commands in the history
    local os_detected="Unknown"
    local confidence="low"
    local evidence=""

    # Check for Alpine (apk)
    if echo "${history}" | grep -qiE "apk\s+(add|--no-cache|--update)"; then
        os_detected="Alpine Linux"
        confidence="high"
        evidence="Found apk package manager commands"
    # Check for Debian/Ubuntu (apt-get/apt)
    elif echo "${history}" | grep -qiE "apt-get\s+(install|update)|apt\s+install"; then
        os_detected="Debian-based (Debian/Ubuntu)"
        confidence="high"
        evidence="Found apt-get/apt package manager commands"
    # Check for RedHat/CentOS/Fedora (yum/dnf)
    elif echo "${history}" | grep -qiE "yum\s+(install|update)|dnf\s+(install|update)"; then
        os_detected="RedHat-based (CentOS/Fedora/RHEL)"
        confidence="high"
        evidence="Found yum/dnf package manager commands"
    # Check for Alpine in image name
    elif echo "${history}" | grep -qi "alpine"; then
        os_detected="Alpine Linux (likely)"
        confidence="medium"
        evidence="Found 'alpine' in layer history"
    # Check for Debian in image name
    elif echo "${history}" | grep -qiE "debian|ubuntu"; then
        os_detected="Debian-based (likely)"
        confidence="medium"
        evidence="Found 'debian' or 'ubuntu' in layer history"
    # Check for /bin/sh (common base layer indicator)
    elif echo "${history}" | grep -qE "/bin/sh|/bin/bash"; then
        os_detected="Linux distribution (unable to determine family)"
        confidence="low"
        evidence="Found shell commands but no specific package manager"
    fi

    echo "  Detected: ${os_detected}"
    echo "  Confidence: ${confidence}"
    if [[ -n "${evidence}" ]]; then
        echo "  Evidence: ${evidence}"
    fi
}

analyze_run_commands() {
    local history="${1}"

    # Alpine packages (apk)
    local apk_cmds
    apk_cmds=$(echo "${history}" | grep -iE "apk\s+(add|--no-cache)" | sed -E 's/^.*apk\s+(add|--no-cache)\s+(.*)$/\2/' | sed -E 's/\s+&&.*$//' | xargs || true)
    if [[ -n "${apk_cmds}" ]]; then
        echo "  Alpine (apk): ${apk_cmds}"
    fi

    # Debian/Ubuntu packages (apt-get/apt) - improved parsing
    local apt_cmds
    apt_cmds=$(echo "${history}" | grep -iE "apt-get\s+install|apt\s+install" | while read -r line; do
        # Extract package list from the apt install command
        # Remove everything before "install" and clean up flags
        pkgs=$(echo "${line}" | sed -E 's/.*(apt-get install|apt install)\s+//' \
               | sed -E 's/\s+-y\s*/ /g' \
               | sed -E 's/\s+--no-install-recommends\s*/ /g' \
               | sed -E 's/\s+--no-install-recommends:.*//' \
               | sed -E 's/\s+&&.*$//' \
               | sed -E 's/\s+--.*//' \
               | xargs)
        if [[ -n "${pkgs}" && "${pkgs}" != "-" ]]; then
            echo "${pkgs}"
        fi
    done | tr '\n' ' ' | xargs || true)
    if [[ -n "${apt_cmds}" ]]; then
        echo "  Debian (apt): ${apt_cmds}"
    fi

    # Python packages (pip)
    local pip_cmds
    pip_cmds=$(echo "${history}" | grep -iE "pip\s+install" | sed -E 's/^.*pip\s+install\s+(.*)$/\1/' | sed -E 's/\s+&&.*$//' | sed -E 's/\s+-r\s+(\S+).*/\1 (requirements file)/' | head -1 | xargs || true)
    if [[ -n "${pip_cmds}" ]]; then
        echo "  Python (pip): ${pip_cmds}"
    fi

    # Node packages (npm)
    local npm_cmds
    npm_cmds=$(echo "${history}" | grep -iE "npm\s+install" | sed -E 's/^.*npm\s+install\s+(.*)$/\1/' | sed -E 's/\s+&&.*$//' | xargs || true)
    if [[ -n "${npm_cmds}" ]]; then
        echo "  Node (npm): ${npm_cmds}"
    fi

    # Check for other common patterns
    if echo "${history}" | grep -qiE "wget\s+|curl\s+-O|curl\s+-L"; then
        echo "  Downloads: Found wget/curl download commands"
    fi

    if echo "${history}" | grep -qiE "tar\s+-xz|tar\s+-xzf|unzip"; then
        echo "  Archives: Found tar/unzip extraction commands"
    fi

    if echo "${history}" | grep -qiE "git\s+clone"; then
        echo "  Source: Found git clone commands"
    fi
}

analyze_docker_inspect() {
    local image="${1}"

    log_section "Docker Inspect Metadata"

    log_info "Getting image metadata..."
    local inspect_data
    local inspect_exit_code=0

    if ! inspect_data=$(docker inspect "${image}" 2>&1); then
        inspect_exit_code=$?
        log_error "Failed to inspect image (exit code: ${inspect_exit_code})"
        echo "${inspect_data}" >&2
        case ${inspect_exit_code} in
            1)
                if echo "${inspect_data}" | grep -qi "No such image\|not found"; then
                    log_error "Reason: Image not found locally"
                    log_error "Suggestion: Try pulling again with 'docker pull ${image}'"
                else
                    log_error "Reason: Image format is invalid or corrupt"
                    log_error "Suggestion: Remove and re-pull: 'docker rmi ${image} && docker pull ${image}'"
                fi
                ;;
            *)
                log_error "Reason: See Docker output above"
                ;;
        esac
        return
    fi

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
    echo -e "\n${BOLD}Exposed Ports (metadata):${NC}"
    local ports
    ports=$(echo "${inspect_data}" | jq -r '.[0].Config.ExposedPorts // {} | keys[]' 2>/dev/null || true)
    if [[ -n "${ports}" ]]; then
        echo "${ports}" | while read -r port; do
            echo "  - ${port}"
        done
    else
        echo "  None"
    fi

    # Extract volumes
    echo -e "\n${BOLD}Volumes (metadata):${NC}"
    local volumes
    volumes=$(echo "${inspect_data}" | jq -r '.[0].Config.Volumes // {} | keys[]' 2>/dev/null || true)
    if [[ -n "${volumes}" ]]; then
        echo "${volumes}" | while read -r volume; do
            echo "  - ${volume}"
        done
    else
        echo "  None"
    fi

    # Extract user
    echo -e "\n${BOLD}User:${NC}"
    local user
    user=$(echo "${inspect_data}" | jq -r '.[0].Config.User // "root"' 2>/dev/null || true)
    echo "  ${user}"

    # Extract working directory
    echo -e "\n${BOLD}Working Directory:${NC}"
    local workdir
    workdir=$(echo "${inspect_data}" | jq -r '.[0].Config.WorkingDir // "/"' 2>/dev/null || true)
    echo "  ${workdir}"

    # Extract labels
    echo -e "\n${BOLD}Labels:${NC}"
    local labels
    labels=$(echo "${inspect_data}" | jq -r '.[0].Config.Labels // {} | to_entries[] | .key + "=" + .value' 2>/dev/null || true)
    if [[ -n "${labels}" ]]; then
        echo "${labels}" | head -10 | while read -r label; do
            echo "  - ${label}"
        done
        local label_count
        label_count=$(echo "${inspect_data}" | jq -r '.[0].Config.Labels // {} | length' 2>/dev/null || true)
        if [[ "${label_count}" -gt 10 ]]; then
            echo "  ... and $((label_count - 10)) more"
        fi
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
}

check_multiarch_support() {
    local image="${1}"

    log_section "Multi-Architecture Support"

    # Try to get manifest list (for multi-arch images)
    log_info "Checking for multi-architecture manifest..."

    local manifest
    local manifest_exit_code=0
    local manifest_output

    if ! manifest_output=$(docker manifest inspect "${image}" 2>&1); then
        manifest_exit_code=$?
        # Don't fail on manifest errors - just warn
        case ${manifest_exit_code} in
            1)
                if echo "${manifest_output}" | grep -qi "manifest.*not found\|no such manifest"; then
                    log_warning "Single architecture image (no multi-arch manifest)"
                elif echo "${manifest_output}" | grep -qi "unsupported"; then
                    log_warning "Manifest inspection not supported by registry"
                else
                    log_warning "Could not inspect manifest (exit code: ${manifest_exit_code})"
                    log_warning "Reason: $(echo "${manifest_output}" | head -1)"
                fi
                ;;
            *)
                log_warning "Could not inspect manifest (exit code: ${manifest_exit_code})"
                ;;
        esac
    else
        manifest="${manifest_output}"
        log_success "Multi-architecture image detected"
        echo ""
        echo -e "${BOLD}Available Platforms:${NC}"
        echo "${manifest}" | jq -r '.manifests[] | "  - " + .platform.os + "/" + .platform.architecture' 2>/dev/null || true
    fi
}

# ==============================================================================
# Summary and Recommendations
# ==============================================================================

generate_recommendations() {
    log_section "Recommendations for Home Assistant Add-on"

    echo -e "${BOLD}Configuration (config.yaml):${NC}"
    echo "  - Set appropriate arch: (amd64, aarch64 - armv7, armhf, i386 are NOT SUPPORTED)"
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
