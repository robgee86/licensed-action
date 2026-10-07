#!/usr/bin/env bash
# Turns the licensed log and the records changed by licensed cache into annotations and a step summary
set -uo pipefail

: "${LICENSED_LOG:?LICENSED_LOG must point to the licensed output}"
: "${LICENSED_OUTCOME:?LICENSED_OUTCOME must be the outcome of the licensed step}"
outdated="${LICENSED_OUTDATED:-error}"
fix_hint="${LICENSED_FIX_HINT:-run licensed cache locally}"
summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

config_value() {
  sed -nE "s/^\"?$2\"?:[[:space:]]*\"?([^\",]+)\"?,?[[:space:]]*\$/\1/p" "$1" | head -n1
}

# cache_path is relative to root, which defaults to the git repository root and is true for the configuration folder
records_path() {
  local config root path
  for config in .licensed.yml .licensed.yaml .licensed.json; do
    [ -f "$config" ] || continue
    root="$(config_value "$config" root)"
    case "$root" in
      "") root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)" ;;
      true) root="." ;;
    esac
    path="$(config_value "$config" cache_path)"
    realpath -m --relative-to=. "$root/${path:-.licenses}"
    return
  done
  realpath -m --relative-to=. "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.licenses"
}

# Prints each blank line separated block listed under "Errors:" by licensed status, NUL terminated
error_blocks() {
  awk '
    function flush() { if (block != "") { printf "%s%c", block, 0; block = "" } }
    /^Errors:$/ { in_errors = 1; next }
    in_errors && /^\* / { flush(); block = $0; next }
    in_errors && /^[[:space:]]+/ { if (block != "") block = block "\n" $0; next }
    in_errors && /^$/ { flush(); next }
    in_errors { flush(); in_errors = 0 }
    END { flush() }
  ' "$LICENSED_LOG"
}

# Workflow commands need escaped newlines, otherwise only the first line reaches the annotation
annotate() {
  local level="$1" message="$2"
  message="${message//'%'/%25}"
  message="${message//$'\r'/%0D}"
  message="${message//$'\n'/%0A}"
  echo "::$level::$message"
}

records="$(records_path)"
mapfile -d '' errors < <(error_blocks)
# Untracked files count too, licensed cache writes a new record for every new dependency
mapfile -t changed < <(git status --porcelain --untracked-files=all -- "$records" | sed -nE "s#^.. \"?${records}/(.*)\.dep\.ya?ml\"?\$#\1#p" | sort -u)

{
  echo "### Dependency licenses"
  echo
  if [ "${#errors[@]}" -gt 0 ]; then
    echo "❌ These dependencies need attention, $fix_hint, then review and commit the records."
    echo
    for block in "${errors[@]}"; do printf '```text\n%s\n```\n\n' "$block"; done
  elif [ "$LICENSED_OUTCOME" != "success" ]; then
    echo "❌ The license scan did not complete, check the log of the licensed step."
  else
    echo "✅ No dependency license issues found."
  fi
  if [ "${#changed[@]}" -gt 0 ]; then
    echo
    echo "#### Outdated records"
    echo
    echo "licensed cache changed these records, the committed ones do not match the dependencies, $fix_hint, then review and commit the records."
    echo
    printf -- '- `%s`\n' "${changed[@]}"
  fi
} >> "$summary"

for block in "${errors[@]}"; do annotate error "$block"; done
level="$([ "$outdated" = "error" ] && echo error || echo warning)"
for record in "${changed[@]}"; do annotate "$level" "Outdated dependency record: $record"; done

if [ "${#errors[@]}" -gt 0 ] || [ "$LICENSED_OUTCOME" != "success" ]; then exit 1; fi
if [ "${#changed[@]}" -gt 0 ] && [ "$outdated" = "error" ]; then exit 1; fi
exit 0
