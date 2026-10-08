#!/usr/bin/env bash
# Runs LICENSED_SETUP and then the given command, by default updating the records, and the NOTICE files when there
# are any, then checking them with licensed status
set -euo pipefail

# The tools run as root, their files go back to the owner of the workspace mounted under /src
workspace="${PWD#/src/}"
workspace="$([ "$workspace" != "$PWD" ] && echo "/src/${workspace%%/*}" || echo "$PWD")"
owner="$(stat -c %u:%g "$workspace")"
trap 'chown -R "$owner" "$workspace" /cache 2>/dev/null || true' EXIT

# Evaluated in this shell, so the variables it exports reach the command
eval "${LICENSED_SETUP:-}"

if [ $# -eq 0 ]; then
  licensed cache
  if licensed-notices --enabled; then licensed-notices; fi
  licensed status
else
  "$@"
fi
