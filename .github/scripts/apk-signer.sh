#!/usr/bin/env bash
# Report who signed APK: the signer's DN and SHA-1 in the job summary (the
# SHA-1 is what SB-A4 registers as an Android OAuth client), the DN as the
# step output `dn` for the release notes.
# Fails only when android/key.properties exists (a release key was given) and
# the signer cannot be read or is still the debug key. Without a release key a
# reading problem is a warning: the APK is fine, only the report is missing.
# apksigner's whole output is printed whenever it is not understood, so a
# failure is never silent.
# Env: ANDROID_HOME, GITHUB_OUTPUT, GITHUB_STEP_SUMMARY.
# Usage: apk-signer.sh APK
set -uo pipefail
apk="$1"

apksigner="$(ls -d "$ANDROID_HOME"/build-tools/*/ | sort -V | tail -1)apksigner"
echo "apksigner: $apksigner"

status=0
certs="$("$apksigner" verify --print-certs "$apk" 2>&1)" || status=$?
dn="$(grep -m1 'certificate DN:' <<<"$certs" || true)"
sha1="$(grep -m1 'certificate SHA-1 digest:' <<<"$certs" || true)"
echo "dn=$dn" >> "$GITHUB_OUTPUT"

{
  echo '### APK signer'
  echo '```'
  if [[ -n "$dn" ]]; then
    printf '%s\n%s\n' "$dn" "$sha1"
  else
    echo "$certs"
  fi
  echo '```'
} >> "$GITHUB_STEP_SUMMARY"

has_release_key=0
[[ -f android/key.properties ]] && has_release_key=1

if [[ "$status" -ne 0 || -z "$dn" ]]; then
  echo "apksigner exited $status with:"
  echo "$certs"
  if [[ "$has_release_key" -eq 1 ]]; then
    echo "::error::apksigner could not read the APK's signer, so the release key is unconfirmed."
    exit 1
  fi
  echo "::warning::apksigner could not read the APK's signer; see its output above."
  exit 0
fi

echo "$dn"
echo "$sha1"
if [[ "$has_release_key" -eq 1 ]] && grep -q 'CN=Android Debug' <<<"$dn"; then
  echo "::error::android/key.properties exists but the APK is signed with the debug key."
  exit 1
fi
