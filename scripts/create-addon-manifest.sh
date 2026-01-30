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