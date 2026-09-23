#!/usr/bin/env bash
# Publish APK as the GitHub pre-release TAG, writing the release notes.
# A re-run of the same workflow run keeps GITHUB_RUN_NUMBER and GITHUB_SHA, so
# TAG already exists then: the asset is replaced (--clobber) and the notes
# refreshed instead of failing on `gh release create`.
# Env: GITHUB_SHA, GITHUB_REF_NAME, GITHUB_RUN_NUMBER, GITHUB_STEP_SUMMARY (optional).
# Usage: publish-build-release.sh APK TAG
set -euo pipefail
apk="$1"
tag="$2"
sha8="${GITHUB_SHA:0:8}"

{
  echo "Built from \`${sha8}\` on \`${GITHUB_REF_NAME}\` (run ${GITHUB_RUN_NUMBER})."
  echo
  echo "| file | size |"
  echo "|---|---|"
  # Backticks are markdown code spans, not shell expansion.
  # shellcheck disable=SC2016
  printf '| `%s` | %s |\n' "$apk" "$(du -h "$apk" | cut -f1)"
  echo
  echo "Signed with the debug key: allow \"Install from unknown sources\","
  echo "and note it cannot be upgraded over by a production-signed build."
} > notes.md

if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload "$tag" "$apk" --clobber
  gh release edit "$tag" --notes-file notes.md
  action="Refreshed"
else
  gh release create "$tag" "$apk" \
    --prerelease \
    --target "$GITHUB_SHA" \
    --title "MemoX build ${GITHUB_RUN_NUMBER} (${sha8})" \
    --notes-file notes.md
  action="Published"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### ${action} \`${tag}\`"
    echo
    cat notes.md
  } >> "$GITHUB_STEP_SUMMARY"
fi
