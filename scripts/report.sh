#!/usr/bin/env bash
# Turns the output of licensed status into annotations and a step summary
set -uo pipefail

: "${LICENSED_LOG:?LICENSED_LOG must point to the licensed output}"
: "${LICENSED_OUTCOME:?LICENSED_OUTCOME must be the outcome of the licensed step}"
fix_hint="${LICENSED_FIX_HINT:-run licensed cache locally}"
summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

# Prints each blank line separated block listed under "Errors:", NUL terminated
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

# Records of removed dependencies, relative to the workspace mounted under /src
stale_records() {
  sed -nE 's#^Stale dependency record found: /src/[^/]+/(.*)$#\1#p' "$LICENSED_LOG"
}

# Workflow commands need escaped newlines, otherwise only the first line reaches the annotation
annotate() {
  local command="$1" message="$2"
  message="${message//'%'/%25}"
  message="${message//$'\r'/%0D}"
  message="${message//$'\n'/%0A}"
  echo "::$command::$message"
}

mapfile -d '' errors < <(error_blocks)
mapfile -t stale < <(stale_records)
# licensed fails on stale records only when stale_records_action is error
stale_level="$([ "$LICENSED_OUTCOME" = "success" ] && echo warning || echo error)"

{
  echo "### Dependency licenses"
  echo
  if [ "${#errors[@]}" -gt 0 ]; then
    echo "❌ These dependencies need attention, $fix_hint, then review and commit the records."
    echo
    for block in "${errors[@]}"; do printf '```text\n%s\n```\n\n' "$block"; done
  elif [ "$LICENSED_OUTCOME" != "success" ] && [ "${#stale[@]}" -eq 0 ]; then
    echo "❌ The license scan did not complete, check the log of the licensed step."
  elif [ "$LICENSED_OUTCOME" != "success" ]; then
    echo "❌ Stale records fail the check."
  else
    echo "✅ No dependency license issues found."
  fi
  if [ "${#stale[@]}" -gt 0 ]; then
    echo
    echo "#### Stale records"
    echo
    echo "These records belong to dependencies no longer used, $fix_hint to remove them."
    echo
    printf -- '- `%s`\n' "${stale[@]}"
  fi
} >> "$summary"

for block in "${errors[@]}"; do annotate error "$block"; done
for record in "${stale[@]}"; do annotate "$stale_level file=$record" "Stale dependency record, $fix_hint to remove it"; done

[ "$LICENSED_OUTCOME" = "success" ]
