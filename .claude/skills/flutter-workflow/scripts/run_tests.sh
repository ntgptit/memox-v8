#!/usr/bin/env bash
# Run host tests the fast way: bundled, once, failures only.
#
# Usage: .claude/skills/flutter-workflow/scripts/run_tests.sh [target ...]
#   target   a test file or a directory under test/ (default: test, the whole
#            non-golden host suite); the same targets `flutter test` takes
#   MEMOX_TEST_BUNDLES=<n>  bundles (default: one per core, at most 8);
#            0 runs the targets file by file, as before 2026-10-02
#
# **Why not `flutter test <dir>`.** It compiles every file on its own and
# starts a process for each: `test/features` took about 4 minutes that way
# and 1m33s bundled (2026-10-02, 4 cores). bundle_tests.py folds the targets
# into one entrypoint per core; every reported test still names its file.
#
# **One run is enough.** The console shows failures only (`-r failures-only`),
# then test_report.py prints the slowest tests and each failing file with the
# command that re-runs it alone. The full JSON report stays in the run's
# directory when a test fails, together with the bundles, so nothing needs a
# second run to be read. A passing run removes the directory.
#
# dod_check.sh runs its host tests through this script in every mode, so a
# subset run here and the gate agree on how tests run. Goldens are
# run_goldens.sh's.

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1
SCRIPTS="$REPO_ROOT/.claude/skills/flutter-workflow/scripts"

TARGETS=("$@")
[[ ${#TARGETS[@]} -gt 0 ]] || TARGETS=(test)

PY=""
for candidate in python python3; do
  command -v "$candidate" >/dev/null 2>&1 && { PY="$candidate"; break; }
done

# **Repo-relative, and one directory per run.** Relative so Git Bash hands
# `json:<path>` to `flutter test` without converting it; per run so a second
# run in this checkout cannot rewrite these bundles while they compile.
BUNDLE_RUN_DIR=".dart_tool/memox_test_bundles/run-$$"
TEST_REPORT="$BUNDLE_RUN_DIR/report.jsonl"
RC_FILE="$BUNDLE_RUN_DIR/rc"
mkdir -p "$BUNDLE_RUN_DIR"
trap '[[ "$(cat "$RC_FILE" 2>/dev/null || echo 0)" == "0" ]] && rm -rf "${REPO_ROOT:?}/${BUNDLE_RUN_DIR:?}"' EXIT

# Without python there is no bundler and no report: the targets run file by
# file, which is slower but still the same tests.
if [[ "${MEMOX_TEST_BUNDLES:-}" == "0" || -z "$PY" ]]; then
  echo "host tests: ${TARGETS[*]}, file by file"
  TZ=UTC flutter test --exclude-tags golden -r failures-only \
    --file-reporter "json:$TEST_REPORT" "${TARGETS[@]}"
else
  if ! listed="$("$PY" "$SCRIPTS/bundle_tests.py" --root "$REPO_ROOT" --out "$BUNDLE_RUN_DIR" "${TARGETS[@]}")"; then
    exit 1
  fi
  bundles=()
  [[ -n "$listed" ]] && mapfile -t bundles <<<"$listed"
  # A Windows Python can end each line with `\r`, which would end up in a path.
  [[ ${#bundles[@]} -gt 0 ]] && bundles=("${bundles[@]%$'\r'}")
  if [[ ${#bundles[@]} -eq 0 ]]; then
    echo "run_tests: ${TARGETS[*]} name no runnable host test" >&2
    exit 1
  fi
  TZ=UTC flutter test -j "${#bundles[@]}" --exclude-tags golden -r failures-only \
    --file-reporter "json:$TEST_REPORT" "${bundles[@]}"
fi
rc=$?
printf '%s' "$rc" >"$RC_FILE"
[[ -n "$PY" ]] && "$PY" "$SCRIPTS/test_report.py" "$TEST_REPORT" --root "$REPO_ROOT"
exit "$rc"
