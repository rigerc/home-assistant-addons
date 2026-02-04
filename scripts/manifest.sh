#!/bin/bash
#
# Generate manifest.json and update dependabot.yml for Home Assistant addons
#
# This script scans addon directories for config.yaml, build.yaml, and Dockerfile
# files to generate a manifest.json file. It can also update .github/dependabot.yml
# with the discovered addon directories. Can also generate README.md files using gomplate.

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly MANIFEST_OUTPUT="${PROJECT_ROOT}/manifest.json"
readonly DEPENDABOT_CONFIG="${PROJECT_ROOT}/.github/dependabot.yml"
readonly DEPLOYER_V3_WORKFLOW="${PROJECT_ROOT}/.github/workflows/addon-build.yaml"
readonly RELEASE_PLEASE_MANIFEST="${PROJECT_ROOT}/.release-please-manifest.json"

# Options
UPDATE_DEPENDABOT=false
UPDATE_WORKFLOW_DISPATCH=false
GENERATE_README=false
UPDATE_RELEASE_PLEASE=false

# Error handling
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Check if gomplate is installed
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if gomplate is available, 1 otherwise
#######################################
check_gomplate() {
  if ! command -v gomplate &>/dev/null; then
    err "Error: gomplate is required but not installed"
    err "Install from: https://github.com/hairyhenderson/gomplate/releases"
    err "Or run: curl -o /usr/local/bin/gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/download/v4.3.0/gomplate_linux-amd64 && chmod +x /usr/local/bin/gomplate"
    return 1
  fi
  return 0
}

#######################################
# Get repository info from git remote
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Echoes "owner/repo" format, empty if not in git repo
#######################################
get_repo_info() {
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || echo "")"

  # Parse different URL formats:
  # SSH: git@github.com:owner/repo.git → owner/repo
  # HTTPS: https://github.com/owner/repo → owner/repo
  # HTTPS with .git: https://github.com/owner/repo.git → owner/repo

  local repo_path="${remote_url}"
  repo_path="${repo_path#git@github.com:}"      # Remove SSH prefix
  repo_path="${repo_path#https://github.com/}" # Remove HTTPS prefix
  repo_path="${repo_path%.git}"                # Remove .git suffix

  echo "${repo_path}"
}

#######################################
# Setup environment variables for gomplate
# Globals:
#   MANIFEST_OUTPUT
# Arguments:
#   None
# Returns:
#   0 on success, 1 if manifest.json missing
#######################################
setup_gomplate_env() {
  local repo_slug
  repo_slug="$(get_repo_info)"

  # Fallback if git remote not available
  if [[ -z "${repo_slug}" ]]; then
    repo_slug="rigerc/home-assistant-addons"  # Default fallback
  fi

  # Check manifest exists
  if [[ ! -f "${MANIFEST_OUTPUT}" ]]; then
    err "Error: manifest.json not found. Generate it first."
    return 1
  fi

  export REPOSITORY="${repo_slug}"
  export REPOSITORY_URL="https://github.com/${repo_slug}"
  export AUTHOR_NAME="${repo_slug%%/*}"  # Extract owner (before first /)
  local addons_data
  addons_data="$(jq -c '.' "${MANIFEST_OUTPUT}")"
  export ADDONS_DATA="${addons_data}"

  return 0
}

#######################################
# Generate root README.md from template
# Globals:
#   PROJECT_ROOT
# Arguments:
#   None
# Returns:
#   0 on success, 1 on error
#######################################
generate_root_readme() {
  local template_file="${PROJECT_ROOT}/.README.tmpl"
  local output_file="${PROJECT_ROOT}/README.md"

  # Check template exists
  if [[ ! -f "${template_file}" ]]; then
    err "Error: Template not found: ${template_file}"
    return 1
  fi

  # Setup environment variables
  if ! setup_gomplate_env; then
    return 1
  fi

  # Generate README
  echo "Generating root README.md..." >&2
  if ! gomplate --file="${template_file}" --out="${output_file}"; then
    err "Error: Failed to generate README.md"
    return 1
  fi

  echo "Generated ${output_file}" >&2
  return 0
}

#######################################
# Generate individual addon READMEs from template
# Globals:
#   PROJECT_ROOT
#   MANIFEST_OUTPUT
# Arguments:
#   slugs - Optional specific addon slugs (if empty, generates all)
# Returns:
#   0 on success, 1 on error
#######################################
# shellcheck disable=SC2120
generate_addon_readmes() {
  local -a specific_slugs=("$@")
  local template_file="${PROJECT_ROOT}/.README_ADDON.tmpl"

  # Check template exists
  if [[ ! -f "${template_file}" ]]; then
    err "Error: Template not found: ${template_file}"
    return 1
  fi

  # Setup environment variables
  if ! setup_gomplate_env; then
    return 1
  fi

  # Get list of addons to process
  local -a slugs=()
  if [[ ${#specific_slugs[@]} -gt 0 ]]; then
    slugs=("${specific_slugs[@]}")
  else
    # Read all slugs from manifest
    while IFS= read -r slug; do
      slugs+=("${slug}")
    done < <(jq -r '.[].slug' "${MANIFEST_OUTPUT}")
  fi

  # Generate README for each addon
  for slug in "${slugs[@]}"; do
    local addon_dir="${PROJECT_ROOT}/${slug}"
    local output_file="${addon_dir}/README.md"

    # Skip if addon directory doesn't exist
    if [[ ! -d "${addon_dir}" ]]; then
      err "Warning: Addon directory not found: ${addon_dir}"
      continue
    fi

    echo "Generating README for ${slug}..." >&2
    export ADDON_SLUG="${slug}"

    if ! gomplate --file="${template_file}" --out="${output_file}"; then
      err "Error: Failed to generate README for ${slug}"
      continue
    fi
  done

  echo "Generated addon README files" >&2
  return 0
}

#######################################
# Display usage information
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS]

Generate manifest.json for Home Assistant addons.

OPTIONS:
  -d, --update-dependabot     Update .github/dependabot.yml with addon directories
  -w, --update-workflow       Update addon-build.yaml workflow_dispatch inputs
  -r, --update-release-please Update .release-please-manifest.json with addon packages
  -g, --generate-readme       Generate README.md files using gomplate templates
  -h, --help                  Display this help message

EXAMPLES:
  $(basename "${BASH_SOURCE[0]}")                      # Generate manifest.json only
  $(basename "${BASH_SOURCE[0]}") -d                  # Generate manifest.json and update dependabot.yml
  $(basename "${BASH_SOURCE[0]}") -w                  # Generate manifest.json and update workflow inputs
  $(basename "${BASH_SOURCE[0]}") -r                  # Generate manifest.json and update release-please manifest
  $(basename "${BASH_SOURCE[0]}") -g                  # Generate manifest.json and README files
  $(basename "${BASH_SOURCE[0]}") -d -w -r -g         # Generate manifest.json and update all configs and READMEs

EOF
}

#######################################
# Parse command line arguments
# Globals:
#   UPDATE_DEPENDABOT
#   UPDATE_WORKFLOW_DISPATCH
#   UPDATE_RELEASE_PLEASE
#   GENERATE_README
# Arguments:
#   All script arguments
# Returns:
#   None
#######################################
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--update-dependabot)
        UPDATE_DEPENDABOT=true
        shift
        ;;
      -w|--update-workflow)
        UPDATE_WORKFLOW_DISPATCH=true
        shift
        ;;
      -r|--update-release-please)
        UPDATE_RELEASE_PLEASE=true
        shift
        ;;
      -g|--generate-readme)
        GENERATE_README=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

#######################################
# Extract addon information from config files
# Globals:
#   None
# Arguments:
#   config_file - Path to config.yaml
# Returns:
#   0 on success, 1 on error
#######################################
extract_addon_info() {
  local config_file="$1"
  local dir
  local dockerfile
  local build_yaml
  local slug
  local version
  local name
  local description
  local architectures
  local project
  local from_line
  local image_tag
  local image
  local tag

  dir="$(dirname "${config_file}")"
  dockerfile="${dir}/Dockerfile"
  build_yaml="${dir}/build.yaml"

  # Dockerfile must exist
  [[ -f "${dockerfile}" ]] || return 1

  # Extract values from config.yaml
  slug="$(yq -r '.slug' "${config_file}")"
  version="$(yq -r '.version' "${config_file}")"
  name="$(yq -r '.name' "${config_file}")"
  description="$(yq -r '.description' "${config_file}")"
  architectures="$(yq -r '.arch | @json' "${config_file}")"

  # Extract project from build.yaml if it exists
  project=""
  if [[ -f "${build_yaml}" ]]; then
    project="$(yq -r '.labels.project // ""' "${build_yaml}")"
  fi

  # Validate required fields
  [[ -n "${slug}" && -n "${version}" ]] || return 1

  # Extract first FROM ... AS line from Dockerfile
  from_line="$(grep -iE '^FROM .* AS ' "${dockerfile}" | head -n1 || true)"
  [[ -n "${from_line}" ]] || return 1

  image_tag="$(awk '{print $2}' <<< "${from_line}")"
  image="${image_tag%%:*}"
  tag="${image_tag#*:}"

  # Output JSON object for this addon
  jq -n \
    --arg slug "${slug}" \
    --arg version "${version}" \
    --arg name "${name}" \
    --arg description "${description}" \
    --argjson architectures "${architectures}" \
    --arg image "${image}" \
    --arg tag "${tag}" \
    --arg project "${project}" \
    '{
      slug: $slug,
      version: $version,
      name: $name,
      description: $description,
      arch: $architectures,
      image: $image,
      tag: $tag,
      project: $project
    }'
}

#######################################
# Generate manifest.json from addon directories
# Globals:
#   PROJECT_ROOT
#   MANIFEST_OUTPUT
# Arguments:
#   None
# Returns:
#   0 on success, 1 on error
#   Outputs: Array of addon slugs
#######################################
generate_manifest() {
  local manifest="[]"
  local config_file
  local addon_info
  local -a slugs=()

  cd "${PROJECT_ROOT}"

  while IFS= read -r config_file; do
    if addon_info="$(extract_addon_info "${config_file}" 2>/dev/null)"; then
      manifest="$(jq --argjson addon "${addon_info}" '. + [$addon]' <<< "${manifest}")"

      # Extract slug for dependabot update
      local slug
      slug="$(jq -r '.slug' <<< "${addon_info}")"
      slugs+=("${slug}")
    fi
  done < <(find . -mindepth 2 -maxdepth 2 -type f \( -name "config.yaml" -o -name "config.yml" \))

  # Write manifest atomically
  echo "${manifest}" | jq '.' > "${MANIFEST_OUTPUT}"
  echo "Generated ${MANIFEST_OUTPUT}" >&2

  # Return slugs as newline-separated output to stdout (for dependabot update)
  printf '%s\n' "${slugs[@]}"
}

#######################################
# Update dependabot.yml with addon directories
# Globals:
#   DEPENDABOT_CONFIG
# Arguments:
#   slugs - Array of addon slugs (one per line via stdin)
# Returns:
#   0 on success, 1 on error
#######################################
update_dependabot() {
  local -a slugs
  readarray -t slugs

  [[ "${#slugs[@]}" -gt 0 ]] || {
    err "No addon slugs found for dependabot update"
    return 1
  }

  [[ -f "${DEPENDABOT_CONFIG}" ]] || {
    err "Dependabot config not found: ${DEPENDABOT_CONFIG}"
    return 1
  }

  # Check if yq supports the update operation
  if ! command -v yq &>/dev/null; then
    err "yq is required for dependabot.yml updates"
    return 1
  fi

  # Create temporary file with updated config
  local temp_file
  temp_file="$(mktemp)"

  # Build directories array with proper quoting
  local -a dir_paths=()
  for slug in "${slugs[@]}"; do
    dir_paths+=("\"/${slug}\"")
  done

  # Join paths with comma for yq expression
  local dirs_string
  dirs_string="$(IFS=,; echo "${dir_paths[*]}")"

  # Update the docker ecosystem directories with quoted paths
  yq eval \
    "(.updates[] | select(.[\"package-ecosystem\"] == \"docker\") | .directories) = [${dirs_string}]" \
    "${DEPENDABOT_CONFIG}" > "${temp_file}"

  # Post-process: add quotes around directory paths
  sed -i 's/^- \(\/\)/- "\1/g' "${temp_file}"
  sed -i 's/\(^[[:space:]]*\)- \(\/[^"]*\)$/\1- "\2"/g' "${temp_file}"

  # Verify the update is valid YAML
  if ! yq eval . "${temp_file}" >/dev/null 2>&1; then
    err "Generated invalid YAML for dependabot config"
    rm -f "${temp_file}"
    return 1
  fi

  # Replace original file (mv removes the temp file)
  mv "${temp_file}" "${DEPENDABOT_CONFIG}"
  echo "Updated ${DEPENDABOT_CONFIG} with ${#slugs[@]} addon directories" >&2
}

#######################################
# Update workflow_dispatch boolean inputs in addon-build.yaml
# Globals:
#   DEPLOYER_V3_WORKFLOW
# Arguments:
#   slugs - Array of addon slugs (one per line via stdin)
# Returns:
#   0 on success, 1 on error
#######################################
update_workflow_dispatch_v3() {
  local -a slugs
  readarray -t slugs

  [[ "${#slugs[@]}" -gt 0 ]] || {
    err "No addon slugs found for addon-build workflow update"
    return 1
  }

  [[ -f "${DEPLOYER_V3_WORKFLOW}" ]] || {
    err "Addon build workflow not found: ${DEPLOYER_V3_WORKFLOW}"
    return 1
  }

  # Check if yq is available
  if ! command -v yq &>/dev/null; then
    err "yq is required for addon-build workflow updates"
    return 1
  fi

  # Sort slugs alphabetically for consistent output
  local sorted_slugs
  sorted_slugs="$(printf '%s\n' "${slugs[@]}" | sort)"
  mapfile -t slugs <<< "${sorted_slugs}"

  local updated_yaml
  updated_yaml="$(mktemp)"

  # Clear existing workflow_dispatch inputs first
  yq eval '.on.workflow_dispatch.inputs = {}' "${DEPLOYER_V3_WORKFLOW}" > "${updated_yaml}"

  # Add each slug as a boolean input with checkbox emoji
  for slug in "${slugs[@]}"; do
    local next_temp
    next_temp="$(mktemp)"

    # Build input block with description (including checkbox emoji), type, and default
    yq eval \
      ".on.workflow_dispatch.inputs.${slug} = {\"description\": \"☑️ Release ${slug}\", \"type\": \"boolean\", \"default\": false}" \
      "${updated_yaml}" > "${next_temp}"

    rm -f "${updated_yaml}"
    updated_yaml="${next_temp}"
  done

  # Verify the update is valid YAML
  if ! yq eval . "${updated_yaml}" >/dev/null 2>&1; then
    err "Generated invalid YAML for addon-build workflow file"
    rm -f "${updated_yaml}"
    return 1
  fi

  # Replace original file
  mv "${updated_yaml}" "${DEPLOYER_V3_WORKFLOW}"
  echo "Updated ${DEPLOYER_V3_WORKFLOW} with ${#slugs[@]} boolean inputs" >&2
}

#######################################
# Update .release-please-manifest.json with addon packages
# Preserves existing version numbers, adds new packages
# Globals:
#   RELEASE_PLEASE_MANIFEST
# Arguments:
#   slugs - Array of addon slugs (one per line via stdin)
# Returns:
#   0 on success, 1 on error
#######################################
update_release_please_manifest() {
  local -a slugs
  readarray -t slugs

  [[ "${#slugs[@]}" -gt 0 ]] || {
    err "No addon slugs found for release-please manifest update"
    return 1
  }

  local temp_file
  temp_file="$(mktemp)"

  # Create new manifest or update existing one
  if [[ -f "${RELEASE_PLEASE_MANIFEST}" ]]; then
    # Read existing manifest to preserve versions
    cp "${RELEASE_PLEASE_MANIFEST}" "${temp_file}"
  else
    # Create new empty manifest
    echo "{}" > "${temp_file}"
  fi

  # Add each slug as a package (preserve existing version, default to 0.1.0 for new)
  for slug in "${slugs[@]}"; do
    local current_version
    current_version="$(jq -r ".[\"${slug}\"] // \"0.1.0\"" "${temp_file}")"

    # Update the manifest entry
    local next_temp
    next_temp="$(mktemp)"
    jq ".[\"${slug}\"] = \"${current_version}\"" "${temp_file}" > "${next_temp}"
    rm -f "${temp_file}"
    temp_file="${next_temp}"
  done

  # Verify the output is valid JSON
  if ! jq . "${temp_file}" >/dev/null 2>&1; then
    err "Generated invalid JSON for release-please manifest"
    rm -f "${temp_file}"
    return 1
  fi

  # Replace original file
  mv "${temp_file}" "${RELEASE_PLEASE_MANIFEST}"
  echo "Updated ${RELEASE_PLEASE_MANIFEST} with ${#slugs[@]} packages" >&2
}

#######################################
# Main script logic
# Globals:
#   UPDATE_DEPENDABOT
#   UPDATE_WORKFLOW_DISPATCH
#   UPDATE_RELEASE_PLEASE
#   GENERATE_README
# Arguments:
#   All script arguments
# Returns:
#   0 on success, non-zero on error
#######################################
main() {
  parse_args "$@"

  # Generate manifest and capture slugs
  local slugs_output
  slugs_output="$(generate_manifest)"

  # Update dependabot if requested
  if [[ "${UPDATE_DEPENDABOT}" == "true" ]]; then
    update_dependabot <<< "${slugs_output}"
  fi

  # Update workflow_dispatch if requested (addon-build.yaml)
  if [[ "${UPDATE_WORKFLOW_DISPATCH}" == "true" ]]; then
    if [[ -f "${DEPLOYER_V3_WORKFLOW}" ]]; then
      update_workflow_dispatch_v3 <<< "${slugs_output}"
    fi
  fi

  # Update release-please manifest if requested
  if [[ "${UPDATE_RELEASE_PLEASE}" == "true" ]]; then
    update_release_please_manifest <<< "${slugs_output}"
  fi

  # Generate README files if requested
  if [[ "${GENERATE_README}" == "true" ]]; then
    # Check gomplate is available
    if ! check_gomplate; then
      exit 1
    fi

    # Generate root README
    if ! generate_root_readme; then
      exit 1
    fi

    # Generate addon READMEs (all addons by default)
    # shellcheck disable=SC2119
    if ! generate_addon_readmes; then
      exit 1
    fi
  fi
}

main "$@"
