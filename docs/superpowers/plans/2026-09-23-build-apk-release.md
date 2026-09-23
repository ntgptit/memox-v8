# Build APK to GitHub Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A manual `build-apk` workflow that publishes one universal APK as a GitHub pre-release and deletes CI-built releases older than 7 days.

**Architecture:** One workflow file drives the build and publish with the preinstalled `gh` CLI. The only logic worth testing — which releases are expired — lives in a small `jq` script that reads `gh release list --json` output, so it runs against fixture JSON locally and against the real list in CI.

**Tech Stack:** GitHub Actions (`actions/checkout`, `actions/setup-java`, `subosito/flutter-action`), `gh`, `jq`, bash.

**Spec:** `docs/superpowers/specs/2026-09-23-build-apk-release-design.md`

## Global Constraints

- Trigger: `workflow_dispatch` only, no inputs.
- Release: published pre-release, tag `build-<run_number>-<sha8>`, asset `memox-<run_number>-<sha8>.apk`, one universal `flutter build apk --release`.
- Cleanup: only after a successful publish; only tags starting with `build-`; older than 7 days (604800 s); `gh release delete <tag> --cleanup-tag --yes`.
- `permissions: contents: write`; `concurrency` group `build-apk`, `cancel-in-progress: false`.
- JDK Temurin 17; Flutter from `.fvmrc`; `dart run build_runner build --delete-conflicting-outputs` before the build.
- `gh release list --limit 1000`.
- Release notes state the debug-key consequences (unknown sources; no upgrade over a production-signed build).

## Review Focus

1. A manual release whose tag merely *contains* `build-` (e.g. `v1-build-fix`) must not be deleted — prefix match only. Pinned in Task 1.
2. A release exactly 7 days old is kept (strictly older is expired). Pinned in Task 1.
3. An empty release list must produce no output and exit 0. Pinned in Task 1.
4. The release just created must never be selected even if the runner clock is skewed slightly — it is seconds old, far from the 7-day boundary; covered by Task 1's 6-day case.
5. A draft `build-` release (no publish date) is still cleaned: the selector reads only `tagName` and `createdAt`, never draft/publish state.

---

### Task 1: Expired-release selector

**Files:**
- Create: `.github/scripts/expired-build-releases.sh`
- Test: `.github/scripts/expired-build-releases_test.sh`

**Interfaces:**
- Produces: `expired-build-releases.sh [NOW_EPOCH]` — reads `gh release list --json tagName,createdAt` JSON on stdin, prints one expired tag per line (sorted), exit 0. `NOW_EPOCH` defaults to the current time.

- [ ] **Step 1: Write the failing test**

`.github/scripts/expired-build-releases_test.sh`:

```bash
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

check "empty list selects nothing" "" "$(printf '[]' | bash "$script" "$now")"

exit "$fail"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .github/scripts/expired-build-releases_test.sh`
Expected: FAIL on both checks (`bash: .../expired-build-releases.sh: No such file or directory`).

- [ ] **Step 3: Write the selector**

`.github/scripts/expired-build-releases.sh`:

```bash
#!/usr/bin/env bash
# Print the tags of CI-built releases (tag prefix `build-`) created more than
# 7 days before NOW, one per line, sorted. Input: the JSON array from
#   gh release list --limit 1000 --json tagName,createdAt
# on stdin. Manual releases (any other tag) are never selected; a release
# exactly 7 days old is kept.
# Usage: expired-build-releases.sh [NOW_EPOCH]
set -euo pipefail
now="${1:-$(date -u +%s)}"
max_age=$((7 * 24 * 3600))
jq -r --argjson now "$now" --argjson max "$max_age" '
  .[]
  | select(.tagName | startswith("build-"))
  | select(($now - (.createdAt | fromdateiso8601)) > $max)
  | .tagName
' | sort
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash .github/scripts/expired-build-releases_test.sh`
Expected: `ok` on both checks, exit 0.

- [ ] **Step 5: Commit**

```bash
chmod +x .github/scripts/expired-build-releases.sh .github/scripts/expired-build-releases_test.sh
git add .github/scripts
git commit -m "ci: add expired build-release selector with fixture test"
```

### Task 2: `build-apk` workflow

**Files:**
- Create: `.github/workflows/build-apk.yml`

**Interfaces:**
- Consumes: `.github/scripts/expired-build-releases.sh` (Task 1).

- [ ] **Step 1: Write the workflow**

`.github/workflows/build-apk.yml`:

```yaml
name: Build APK

# Manual only. Builds one universal release APK and publishes it as a GitHub
# pre-release (downloadable from Releases, never labelled "Latest"), then
# deletes CI-built releases older than 7 days.
# Spec: docs/superpowers/specs/2026-09-23-build-apk-release-design.md
on:
  workflow_dispatch:

permissions:
  contents: write

concurrency:
  group: build-apk
  cancel-in-progress: false

jobs:
  apk:
    name: build and publish APK
    runs-on: ubuntu-latest
    timeout-minutes: 40
    env:
      GH_TOKEN: ${{ github.token }}
    steps:
      - uses: actions/checkout@v7

      # android/app/build.gradle.kts targets JavaVersion.VERSION_17.
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version-file: .fvmrc
          cache: true

      - name: pub get
        run: flutter pub get

      # Generated code is not committed (.gitignore: *.g.dart).
      - name: generate
        run: dart run build_runner build --delete-conflicting-outputs

      - name: build APK
        id: build
        run: |
          set -euo pipefail
          flutter build apk --release
          sha8="${GITHUB_SHA:0:8}"
          name="memox-${GITHUB_RUN_NUMBER}-${sha8}.apk"
          mv build/app/outputs/flutter-apk/app-release.apk "$name"
          {
            echo "apk=$name"
            echo "tag=build-${GITHUB_RUN_NUMBER}-${sha8}"
          } >> "$GITHUB_OUTPUT"

      - name: publish pre-release
        env:
          APK: ${{ steps.build.outputs.apk }}
          TAG: ${{ steps.build.outputs.tag }}
        run: |
          set -euo pipefail
          {
            echo "Built from \`${GITHUB_SHA:0:8}\` on \`${GITHUB_REF_NAME}\` (run ${GITHUB_RUN_NUMBER})."
            echo
            echo "| file | size |"
            echo "|---|---|"
            printf '| `%s` | %s |\n' "$APK" "$(du -h "$APK" | cut -f1)"
            echo
            echo "Signed with the debug key: allow \"Install from unknown sources\","
            echo "and note it cannot be upgraded over by a production-signed build."
          } > notes.md
          gh release create "$TAG" "$APK" \
            --prerelease \
            --target "$GITHUB_SHA" \
            --title "MemoX build ${GITHUB_RUN_NUMBER} (${GITHUB_SHA:0:8})" \
            --notes-file notes.md
          {
            echo "### Published \`$TAG\`"
            echo
            cat notes.md
          } >> "$GITHUB_STEP_SUMMARY"

      # Runs only when every step above succeeded, so a failed build never
      # deletes the previous APKs.
      - name: delete CI releases older than 7 days
        run: |
          set -euo pipefail
          gh release list --limit 1000 --json tagName,createdAt \
            | bash .github/scripts/expired-build-releases.sh > expired.txt
          echo "### Deleted releases older than 7 days" >> "$GITHUB_STEP_SUMMARY"
          if [[ ! -s expired.txt ]]; then
            echo "None." >> "$GITHUB_STEP_SUMMARY"
            exit 0
          fi
          while IFS= read -r tag; do
            gh release delete "$tag" --cleanup-tag --yes
            echo "- \`$tag\`" >> "$GITHUB_STEP_SUMMARY"
          done < expired.txt
```

- [ ] **Step 2: Lint it**

Run: `actionlint .github/workflows/build-apk.yml` (download the release binary from `rhysd/actionlint` into the scratchpad if it is not installed).
Expected: no output, exit 0.

- [ ] **Step 3: Re-run the selector test and the repo gates**

Run: `bash .github/scripts/expired-build-releases_test.sh && python3 tools/docs/check.py | tail -1`
Expected: both `ok`; `PASS — 0 error(s)`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/build-apk.yml
git commit -m "ci: add manual build-apk workflow publishing a pre-release"
```

- [ ] **Step 5: Verify on GitHub after merge**

After the change reaches `master`, trigger `build-apk` (workflow_dispatch on `master`) and check:
Expected: run succeeds; a pre-release `build-<n>-<sha8>` exists with one `memox-<n>-<sha8>.apk` asset; the job summary lists "Deleted releases older than 7 days: None." on the first run.
