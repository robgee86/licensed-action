#!/usr/bin/env bash
# Runs the image the way a developer does, with the workspace under /src and the cache directory at /cache,
# the arguments replace the default command of the image
set -euo pipefail

: "${LICENSED_IMAGE:?LICENSED_IMAGE must name the image to run}"

# Keeping the folder name preserves the app names licensed derives from it, and so the records layout
mount="/src/$(basename "$PWD")"
args=(--rm --volume "$PWD:$mount" --workdir "$mount/${LICENSED_WORKING_DIRECTORY:-.}")
# An empty setup keeps the one the image sets
[ -n "${LICENSED_SETUP:-}" ] && args+=(--env LICENSED_SETUP)
if [ -n "${LICENSED_CACHE_DIR:-}" ]; then
  mkdir -p "$LICENSED_CACHE_DIR"
  args+=(--volume "$LICENSED_CACHE_DIR:/cache")
fi
# Git reads its config from these variables, so the token reaches private modules without touching any file
if [ -n "${LICENSED_GITHUB_TOKEN:-}" ]; then
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="url.https://x-access-token:${LICENSED_GITHUB_TOKEN}@github.com/.insteadOf"
  export GIT_CONFIG_VALUE_0="https://github.com/"
  args+=(--env GIT_CONFIG_COUNT --env GIT_CONFIG_KEY_0 --env GIT_CONFIG_VALUE_0)
fi

exec docker run "${args[@]}" "$LICENSED_IMAGE" "$@"
