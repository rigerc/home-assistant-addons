#!/bin/bash
#
# Generate manifest.json and update dependabot.yml for Home Assistant addons
#
# This script scans addon directories for config.yaml, build.yaml, and Dockerfile
# files to generate a manifest.json file. It can also update .github/dependabot.yml
# with the discovered addon directories.

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_ROOT
readonly MANIFEST_OUTPUT="${PROJECT_ROOT}/manifest.json"
readonly DEPENDABOT_CONFIG="${PROJECT_ROOT}/.github/dependabot.yml"
readonly DEPLOYER_WORKFLOW="${PROJECT_ROOT}/.github/workflows/deployer.yaml"
RELEASE_DRAFTER_TEMPLATE="${SCRIPT_DIR}/release-drafter-template.yml"
readonly RELEASE_DRAFTER_TEMPLATE
GITHUB_DIR="${PROJECT_ROOT}/.github"
readonly GITHUB_DIR

# Options
UPDATE_DEPENDABOT=false
UPDATE_WORKFLOW_DISPATCH=false
CREATE_RELEASE_DRAFTER=false

# Error handling
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
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
  -d, --update-dependabot   Update .github/dependabot.yml with addon directories
  -w, --update-workflow     Update .github/workflows/deployer.yaml workflow_dispatch options
  -r, --create-release-drafter Create release-drafter config files for addons (if missing)
  -h, --help                Display this help message

EXAMPLES:
  $(basename "${BASH_SOURCE[0]}")                      # Generate manifest.json only
  $(basename "${BASH_SOURCE[0]}") -d                  # Generate manifest.json and update dependabot.yml
  $(basename "${BASH_SOURCE[0]}") -w                  # Generate manifest.json and update workflow_dispatch options
  $(basename "${BASH_SOURCE[0]}") -r                  # Generate manifest.json and create release-drafter configs
  $(basename "${BASH_SOURCE[0]}") -d -w -r            # Generate manifest.json and update all configs

EOF
}

#######################################
# Parse command line arguments
# Globals:
#   UPDATE_DEPENDABOT
#   UPDATE_WORKFLOW_DISPATCH
#   CREATE_RELEASE_DRAFTER
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
      -r|--create-release-drafter)
        CREATE_RELEASE_DRAFTER=true
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
    project="$(yq -r '.project // ""' "${build_yaml}")"
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
# Update workflow_dispatch options in deployer.yaml
# Globals:
#   DEPLOYER_WORKFLOW
# Arguments:
#   slugs - Array of addon slugs (one per line via stdin)
# Returns:
#   0 on success, 1 on error
#######################################
update_workflow_dispatch() {
  local -a slugs
  readarray -t slugs

  [[ "${#slugs[@]}" -gt 0 ]] || {
    err "No addon slugs found for workflow update"
    return 1
  }

  [[ -f "${DEPLOYER_WORKFLOW}" ]] || {
    err "Deployer workflow not found: ${DEPLOYER_WORKFLOW}"
    return 1
  }

  # Check if yq is available
  if ! command -v yq &>/dev/null; then
    err "yq is required for workflow_dispatch updates"
    return 1
  fi

  # Sort slugs alphabetically for consistent output
  local sorted_slugs
  sorted_slugs="$(printf '%s\n' "${slugs[@]}" | sort)"
  mapfile -t slugs <<< "${sorted_slugs}"

  # Build new options array using yq
  # First, clear existing options
  local updated_yaml
  updated_yaml="$(mktemp)"

  yq eval '.on.workflow_dispatch.inputs.addon.options = []' "${DEPLOYER_WORKFLOW}" > "${updated_yaml}"

  # Add each slug as an option
  for slug in "${slugs[@]}"; do
    local next_temp
    next_temp="$(mktemp)"
    yq eval ".on.workflow_dispatch.inputs.addon.options += [\"${slug}\"]" "${updated_yaml}" > "${next_temp}"
    rm -f "${updated_yaml}"
    updated_yaml="${next_temp}"
  done

  # Verify the update is valid YAML
  if ! yq eval . "${updated_yaml}" >/dev/null 2>&1; then
    err "Generated invalid YAML for workflow file"
    rm -f "${updated_yaml}"
    return 1
  fi

  # Replace original file
  mv "${updated_yaml}" "${DEPLOYER_WORKFLOW}"
  echo "Updated ${DEPLOYER_WORKFLOW} with ${#slugs[@]} addon options" >&2
}

#######################################
# Create release-drafter config files from template
# Globals:
#   RELEASE_DRAFTER_TEMPLATE
#   GITHUB_DIR
# Arguments:
#   slugs - Array of addon slugs (one per line via stdin)
# Returns:
#   0 on success, 1 on error
#######################################
create_release_drafter_configs() {
  local -a slugs
  readarray -t slugs

  [[ "${#slugs[@]}" -gt 0 ]] || {
    err "No addon slugs found for release-drafter config creation"
    return 1
  }

  [[ -f "${RELEASE_DRAFTER_TEMPLATE}" ]] || {
    err "Release drafter template not found: ${RELEASE_DRAFTER_TEMPLATE}"
    return 1
  }

  # Ensure .github directory exists
  if [[ ! -d "${GITHUB_DIR}" ]]; then
    mkdir -p "${GITHUB_DIR}" || {
      err "Failed to create .github directory"
      return 1
    }
  fi

  local created_count=0
  local skipped_count=0

  for slug in "${slugs[@]}"; do
    local output_file="${GITHUB_DIR}/release-drafter-${slug}.yml"

    # Skip if file already exists
    if [[ -f "${output_file}" ]]; then
      (( skipped_count++ )) || true
      continue
    fi

    # Create config from template, replacing {slug} with actual slug
    sed "s/{slug}/${slug}/g" "${RELEASE_DRAFTER_TEMPLATE}" > "${output_file}"

    (( created_count++ )) || true
    echo "Created ${output_file}" >&2
  done

  echo "Created ${created_count} release-drafter config files, skipped ${skipped_count} existing files" >&2
}

#######################################
# Main script logic
# Globals:
#   UPDATE_DEPENDABOT
#   UPDATE_WORKFLOW_DISPATCH
#   CREATE_RELEASE_DRAFTER
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

  # Update workflow_dispatch if requested
  if [[ "${UPDATE_WORKFLOW_DISPATCH}" == "true" ]]; then
    update_workflow_dispatch <<< "${slugs_output}"
  fi

  # Create release-drafter configs if requested
  if [[ "${CREATE_RELEASE_DRAFTER}" == "true" ]]; then
    create_release_drafter_configs <<< "${slugs_output}"
  fi
}

main "$@"
