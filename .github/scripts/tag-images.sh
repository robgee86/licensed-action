#!/usr/bin/env bash
# Tags every image found in the bake metadata files given as arguments, joining the digests each platform pushed
set -euo pipefail

: "${VERSION:?VERSION must be the release tag, such as v1.2.3}"
minor="${VERSION%.*}"
major="${minor%.*}"

jq -rs '[.[] | to_entries[] | .value | select(type == "object" and has("image.name")) | .["image.name"]] | unique[]' "$@" |
  while read -r name; do
    sources=()
    while read -r digest; do sources+=("$name@$digest"); done < <(
      jq -rs --arg name "$name" '.[] | to_entries[] | .value | select(type == "object" and .["image.name"] == $name) | .["containerimage.digest"]' "$@"
    )
    docker buildx imagetools create --tag "$name:$VERSION" --tag "$name:$minor" --tag "$name:$major" "${sources[@]}"
  done
