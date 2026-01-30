#!/usr/bin/env bash
# Create a manifest.json file for all addons by scanning for config.yaml, build.yaml, and Dockerfile files

set -euo pipefail

OUTPUT="manifest.json"

# Start with an empty JSON array
MANIFEST="[]"

while read -r CONFIG; do
    DIR=$(dirname "$CONFIG")
    DOCKERFILE="$DIR/Dockerfile"
    BUILD_YAML="$DIR/build.yaml"

    # Dockerfile must exist
    [[ -f "$DOCKERFILE" ]] || continue

    # Extract values from YAML (top-level only)
    SLUG=$(yq -r '.slug' "$CONFIG")
    VERSION=$(yq -r '.version' "$CONFIG")
    NAME=$(yq -r '.name' "$CONFIG")
    DESCRIPTION=$(yq -r '.description' "$CONFIG")

    # Extract architectures as JSON array
    ARCHITECTURES=$(yq -r '.arch | @json' "$CONFIG")

    # Extract project from build.yaml if it exists
    PROJECT=""
    if [[ -f "$BUILD_YAML" ]]; then
        PROJECT=$(yq -r '.project // ""' "$BUILD_YAML")
    fi

    [[ -n "$SLUG" && -n "$VERSION" ]] || continue

    # Extract first FROM ... AS line
    FROM_LINE=$(grep -E '^FROM .* AS ' "$DOCKERFILE" | head -n1 || true)
    [[ -n "$FROM_LINE" ]] || continue

    IMAGE_TAG=$(awk '{print $2}' <<< "$FROM_LINE")

    IMAGE="${IMAGE_TAG%%:*}"
    TAG="${IMAGE_TAG#*:}"

    # Merge into manifest
    MANIFEST=$(jq \
      --arg slug "$SLUG" \
      --arg version "$VERSION" \
      --arg name "$NAME" \
      --arg description "$DESCRIPTION" \
      --argjson architectures "$ARCHITECTURES" \
      --arg image "$IMAGE" \
      --arg tag "$TAG" \
      --arg project "$PROJECT" \
      '. + [{
        slug: $slug,
        version: $version,
        name: $name,
        description: $description,
        arch: $architectures,
        image: $image,
        tag: $tag,
        project: $project
      }]' <<< "$MANIFEST")
done < <(find . -mindepth 2 -maxdepth 2 -type f \( -name "config.yaml" -o -name "config.yml" \))

# Write final manifest atomically
echo "$MANIFEST" | jq '.' > "$OUTPUT"

echo "Wrote $OUTPUT"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly MANIFEST="${REPO_ROOT}/manifest.json"
readonly DEPLOYER_YAML="${REPO_ROOT}/.github/workflows/deployer.yaml"
readonly DEPENDABOT_YAML="${REPO_ROOT}/.github/dependabot.yml"

# Error reporting
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

update_github_workflows() {
  if [[ ! -f "${MANIFEST}" ]]; then
    err "manifest.json not found at ${MANIFEST}"
    exit 1
  fi

  # Check if deployer.yaml exists
  if [[ ! -f "${DEPLOYER_YAML}" ]]; then
    err "deployer.yaml not found at ${DEPLOYER_YAML}"
    exit 1
  fi

  # Check if dependabot.yml exists
  if [[ ! -f "${DEPENDABOT_YAML}" ]]; then
    err "dependabot.yml not found at ${DEPENDABOT_YAML}"
    exit 1
  fi

  # Extract slugs from manifest and build options array
  local slugs
  slugs=$(jq -r '[.[].slug] | sort | .[]' "${MANIFEST}" | xargs)

  if [[ -z "${slugs}" ]]; then
    err "No slugs found in manifest.json"
    exit 1
  fi

  echo "Updating deployer.yaml with slugs: ${slugs}"

  # Use yq to update the options array in-place
  # This preserves the entire file structure but replaces the options list
  local temp_file
  temp_file=$(mktemp)

  # Build the new options section
  local new_options="  workflow_dispatch:\n    inputs:\n      addon:\n        description: Addon-Name\n        required: true\n        type: choice\n        options:"

  # Create a temporary yq script to update the file
  yq eval "
    .on.workflow_dispatch.inputs.addon.options = ($(jq -c '[.[].slug]' "${MANIFEST}"))
  " -i "${DEPLOYER_YAML}"

  echo "Updated ${DEPLOYER_YAML}"

  # Update dependabot.yml directories
  echo "Updating dependabot.yml with slugs: ${slugs}"

  # Build directories array with leading slashes
  local dirs_array
  dirs_array=$(jq -r '[.[].slug] | sort | .[] | "/" + .' "${MANIFEST}" | jq -R -s -c 'split("\n") | map(select(length > 0))')

  yq eval "
    .updates[0].directories = ${dirs_array}
  " -i "${DEPENDABOT_YAML}"

  echo "Updated ${DEPENDABOT_YAML}"
}
update_github_workflows