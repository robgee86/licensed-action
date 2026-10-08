#!/usr/bin/env bash
# Writes every app's NOTICE file with licensed notices, merging the entries that share a license text, and removes
# the NOTICE files licensed no longer writes. --check compares the existing files with fresh ones, leaving them
# untouched, and --enabled succeeds when there are NOTICE files, which is what turns notices on
set -euo pipefail

notice_files() {
  licensed env --format json |
    ruby -rjson -e 'puts JSON.parse($stdin.read)["apps"].map { |app| app["cache_path"] }.uniq' |
    while read -r dir; do
      [ -d "$dir" ] && find "$dir" -maxdepth 1 -type f \( -name NOTICE -o -name 'NOTICE.*' \)
    done | sort
}

if [ "${1:-}" = "--enabled" ]; then
  [ -n "$(notice_files)" ]
  exit
fi

# The existing files move aside, so the fresh ones are exactly those licensed writes
saved="$(mktemp -d)"
trap 'rm -rf "$saved"' EXIT
mapfile -t existing < <(notice_files)
for file in "${existing[@]}"; do
  cp --parents "$file" "$saved"
  rm "$file"
done

licensed notices
mapfile -t fresh < <(notice_files)
for file in "${fresh[@]}"; do licensed-notice-deduplicate "$file"; done

if [ "${1:-}" != "--check" ]; then
  for file in "${existing[@]}"; do
    [ -f "$file" ] || echo "Removed stale notice file: $file"
  done
  exit 0
fi

outdated=0
for file in "${fresh[@]}"; do
  if [ ! -f "$saved$file" ]; then
    echo "Missing notice file: $file"
    outdated=1
  elif ! cmp -s "$file" "$saved$file"; then
    echo "Outdated notice file: $file"
    outdated=1
  fi
  rm "$file"
done
for file in "${existing[@]}"; do
  [ -n "$(printf '%s\n' "${fresh[@]}" | grep -Fx "$file")" ] || { echo "Stale notice file: $file"; outdated=1; }
  cp "$saved$file" "$file"
done
exit "$outdated"
