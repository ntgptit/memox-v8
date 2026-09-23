#!/usr/bin/env bash
# Stub-gh test for publish-build-release.sh. Run: bash .github/scripts/publish-build-release_test.sh
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/publish-build-release.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# A fake `gh` that records its arguments; `release view` succeeds only when
# STUB_RELEASE_EXISTS=1, which is how the script tells a re-run from a first run.
mkdir -p "$work/bin"
cat > "$work/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
if [[ "$1 $2" == "release view" ]]; then
  [[ "${STUB_RELEASE_EXISTS:-0}" == "1" ]]
fi
STUB
chmod +x "$work/bin/gh"

run() {
  : > "$work/gh.log"
  (
    cd "$work"
    echo apk > memox-5-abcdef12.apk
    PATH="$work/bin:$PATH" STUB_LOG="$work/gh.log" STUB_RELEASE_EXISTS="$1" \
      GITHUB_SHA=abcdef1234567890 GITHUB_REF_NAME=master GITHUB_RUN_NUMBER=5 \
      GITHUB_STEP_SUMMARY="$work/summary.md" \
      bash "$script" memox-5-abcdef12.apk build-5-abcdef12 >/dev/null
  )
  grep -v '^release view' "$work/gh.log" | cut -d' ' -f1-3
}

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

check "first run creates the pre-release" \
  "release create build-5-abcdef12" "$(run 0)"
check "first run marks it a pre-release" \
  "1" "$(run 0 >/dev/null; grep -c -- '--prerelease' "$work/gh.log")"
check "re-run of the same run replaces the asset instead of failing" \
  "$(printf 'release upload build-5-abcdef12\nrelease edit build-5-abcdef12')" "$(run 1)"
check "re-run uploads with --clobber" \
  "1" "$(run 1 >/dev/null; grep -c -- '--clobber' "$work/gh.log")"

exit "$fail"
