#!/usr/bin/env bash
# Print the tags of CI-built releases (tag prefix `build-`) created more than
# 7 days before NOW, one per line, sorted. Input: the JSON array from
#   gh release list --limit 1000 --json tagName,createdAt
# on stdin. Manual releases (any other tag) are never selected; a release
# exactly 7 days old is kept. Fractional seconds in createdAt are dropped
# before parsing (jq fromdateiso8601 accepts only whole seconds).
# Usage: expired-build-releases.sh [NOW_EPOCH]
set -euo pipefail
now="${1:-$(date -u +%s)}"
max_age=$((7 * 24 * 3600))
jq -r --argjson now "$now" --argjson max "$max_age" '
  .[]
  | select(.tagName | startswith("build-"))
  | select(($now - (.createdAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) > $max)
  | .tagName
' | sort
