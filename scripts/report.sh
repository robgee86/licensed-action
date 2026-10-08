#!/usr/bin/env bash
# Turns the output of licensed-check into annotations and a step summary
set -uo pipefail

: "${LICENSED_LOG:?LICENSED_LOG must point to the licensed output}"
: "${LICENSED_OUTCOME:?LICENSED_OUTCOME must be the outcome of the licensed step}"
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

# NOTICE files that differ from fresh ones, as "<problem> notice file: <path>" relative to the workspace
notice_problems() {
  sed -nE 's#^(Outdated|Missing|Stale) notice file: /src/[^/]+/(.*)$#\1 \2#p' "$LICENSED_LOG"
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
mapfile -t notices < <(notice_problems)
# licensed fails on stale records only when stale_records_action is error
stale_level="$([ "$LICENSED_OUTCOME" = "success" ] && echo warning || echo error)"

{
  echo "### Dependency licenses"
  echo
  if [ "${#errors[@]}" -gt 0 ]; then
    echo "❌ These dependencies need attention, update the records with licensed cache, then review and commit them."
    echo
    for block in "${errors[@]}"; do printf '```text\n%s\n```\n\n' "$block"; done
  elif [ "$LICENSED_OUTCOME" != "success" ] && [ "${#stale[@]}" -eq 0 ] && [ "${#notices[@]}" -eq 0 ]; then
    echo "❌ The license scan did not complete, check the log of the licensed step."
  elif [ "$LICENSED_OUTCOME" != "success" ]; then
    echo "❌ Stale records or NOTICE files fail the check."
  else
    echo "✅ No dependency license issues found."
  fi
  if [ "${#stale[@]}" -gt 0 ]; then
    echo
    echo "#### Stale records"
    echo
    echo "These records belong to dependencies no longer used, licensed cache removes them."
    echo
    printf -- '- `%s`\n' "${stale[@]}"
  fi
  if [ "${#notices[@]}" -gt 0 ]; then
    echo
    echo "#### NOTICE files"
    echo
    echo "These NOTICE files do not match the records, licensed-notices updates them."
    echo
    for notice in "${notices[@]}"; do echo "- ${notice%% *}: \`${notice#* }\`"; done
  fi
} >> "$summary"

for block in "${errors[@]}"; do annotate error "$block"; done
for record in "${stale[@]}"; do annotate "$stale_level file=$record" "Stale dependency record, licensed cache removes it"; done
for notice in "${notices[@]}"; do annotate "error file=${notice#* }" "${notice%% *} NOTICE file, licensed-notices updates it"; done

[ "$LICENSED_OUTCOME" = "success" ]
