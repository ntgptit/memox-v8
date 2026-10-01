#!/usr/bin/env bash
# Stub-apksigner test for apk-signer.sh. Run: bash .github/scripts/apk-signer_test.sh
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/apk-signer.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# A fake apksigner: prints STUB_OUT and exits STUB_EXIT.
mkdir -p "$work/sdk/build-tools/36.0.0"
cat > "$work/sdk/build-tools/36.0.0/apksigner" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$STUB_OUT"
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$work/sdk/build-tools/36.0.0/apksigner"

release='Signer #1 certificate DN: CN=MemoX
Signer #1 certificate SHA-256 digest: aa
Signer #1 certificate SHA-1 digest: 0123abcd
Signer #1 certificate MD5 digest: bb'
debug='Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
Signer #1 certificate SHA-1 digest: ffff'

# run OUT EXIT HAS_KEY -> "<exit> <dn output line>"; the console goes to log.txt.
run() {
  rm -rf "$work/ws" && mkdir -p "$work/ws/android" && : > "$work/out" && : > "$work/summary"
  [[ "$3" == 1 ]] && touch "$work/ws/android/key.properties"
  local status=0
  (
    cd "$work/ws"
    ANDROID_HOME="$work/sdk" STUB_OUT="$1" STUB_EXIT="$2" \
      GITHUB_OUTPUT="$work/out" GITHUB_STEP_SUMMARY="$work/summary" \
      bash "$script" app.apk
  ) > "$work/log.txt" 2>&1 || status=$?
  echo "$status $(cat "$work/out")"
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

check "a release-signed APK passes and exports its DN" \
  "0 dn=Signer #1 certificate DN: CN=MemoX" "$(run "$release" 0 1)"
check "its SHA-1 reaches the job summary" \
  "1" "$(run "$release" 0 1 >/dev/null; grep -c 'SHA-1 digest: 0123abcd' "$work/summary")"
check "a debug-signed APK without a release key passes" \
  "0 dn=Signer #1 certificate DN: C=US, O=Android, CN=Android Debug" "$(run "$debug" 0 0)"
check "a debug-signed APK with a release key fails" \
  "1" "$(run "$debug" 0 1 | cut -d' ' -f1)"
check "an apksigner failure without a release key only warns" \
  "0 dn=" "$(run $'DOES NOT VERIFY\nERROR: x' 1 0)"
check "an apksigner failure with a release key fails" \
  "1" "$(run $'DOES NOT VERIFY\nERROR: x' 1 1 | cut -d' ' -f1)"
check "an apksigner failure is shown, not swallowed" \
  "1" "$(run $'DOES NOT VERIFY\nERROR: x' 1 0 >/dev/null; grep -c 'ERROR: x' "$work/log.txt")"
check "output in an unknown format is shown and only warns" \
  "0 dn=" "$(run 'Signer (minSdkVersion=24) cert: ?' 0 0)"
check "the unknown output reaches the log" \
  "1" "$(run 'Signer (minSdkVersion=24) cert: ?' 0 0 >/dev/null; grep -c 'minSdkVersion=24' "$work/log.txt")"

exit "$fail"
