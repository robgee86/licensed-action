#!/usr/bin/env bash
# Checks the records with licensed status, and the NOTICE files against fresh ones when there are any
set -uo pipefail

failed=0
licensed status || failed=1
if licensed-notices --enabled; then
  licensed-notices --check || failed=1
fi
exit "$failed"
