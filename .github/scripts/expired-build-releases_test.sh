#!/usr/bin/env bash
# Fixture test for expired-build-releases.sh. Run: bash .github/scripts/expired-build-releases_test.sh
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/expired-build-releases.sh"
now=1790000000   # 2026-09-21T13:33:20Z
day=86400
iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ; }

fixture="$(cat <<JSON
[
  {"tagName": "build-8-aaaaaaaa", "createdAt": "$(iso $((now - 8 * day)))"},
  {"tagName": "build-6-bbbbbbbb", "createdAt": "$(iso $((now - 6 * day)))"},
  {"tagName": "build-7-cccccccc", "createdAt": "$(iso $((now - 7 * day)))"},
  {"tagName": "build-30-dddddddd", "createdAt": "$(iso $((now - 30 * day)))"},
  {"tagName": "v1.0.0", "createdAt": "$(iso $((now - 30 * day)))"},
  {"tagName": "v1-build-fix", "createdAt": "$(iso $((now - 30 * day)))"}
]
JSON
)"

fail=0
check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name"; echo "  expected: $(printf '%q' "$expected")"; echo "  actual:   $(printf '%q' "$actual")"
    fail=1
  fi
}

check "selects only build- releases strictly older than 7 days" \
  "$(printf 'build-30-dddddddd\nbuild-8-aaaaaaaa')" \
  "$(printf '%s' "$fixture" | bash "$script" "$now")"

check "accepts createdAt with fractional seconds" "build-9-eeeeeeee" \
  "$(printf '[{"tagName": "build-9-eeeeeeee", "createdAt": "%s"}]' \
      "$(date -u -d "@$((now - 9 * day))" +%Y-%m-%dT%H:%M:%S.123Z)" | bash "$script" "$now")"

check "empty list selects nothing and exits 0" "rc=0" \
  "$(printf '[]' | bash "$script" "$now"; echo "rc=$?")"

exit "$fail"
