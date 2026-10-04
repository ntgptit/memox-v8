#!/usr/bin/env bash
# The golden comparison: the half of the gate that runs after dod_check.sh,
# in the Linux container only (CLAUDE.md, "The gate"; golden.Dockerfile) and
# in CI's `goldens` job.
#
# Usage: .claude/skills/flutter-workflow/scripts/run_goldens.sh
#        [--update] [--report <path>]
#   --update   rewrite the committed pictures (`--update-goldens`) instead of
#              comparing against them. Never on Windows (CLAUDE.md).
#   --report   where the JSON report goes; CI counts the goldens from it.
#   MEMOX_TEST_BUNDLES=<n>  at most n processes: n bundles for a comparison,
#           n files at a time for --update (a memory-limited Docker VM sets it)
#   MEMOX_TEST_BUNDLES=0  compare file by file, as before 2026-10-02.
#
# **Why it is a script.** `flutter test --tags golden` compiles and starts
# every test file in `test/` only to skip the ones without the tag: 529 suites
# for 40 golden files, 7m17s in the cloud container on 2026-10-02. Handing it
# the golden files alone took 1m37s, and the same files bundled took 1m05s.
#
# **Compare bundled, update file by file.** In a bundle each golden file's
# group points `goldenFileComparator` back at the file, so pictures resolve
# where they always did (bundle_tests.py `--goldens`). An update writes the
# pictures, and the one place a wrong path would cost a commit of misplaced
# files is the place this script does not take the shortcut: `--update` hands
# `flutter test` the golden files themselves, with `--tags golden` as before.
#
# Either way the exit code is `flutter test`'s, and test_report.py prints the
# slowest goldens and, on a failure, the file and the command to re-run it.

set -uo pipefail

UPDATE=0
REPORT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --update) UPDATE=1 ;;
    --report)
      shift
      [[ $# -gt 0 ]] || { echo "--report requires a path" >&2; exit 2; }
      REPORT="$1"
      ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1
SCRIPTS="$REPO_ROOT/.claude/skills/flutter-workflow/scripts"

PY=""
for candidate in python python3; do
  command -v "$candidate" >/dev/null 2>&1 && { PY="$candidate"; break; }
done
[[ -n "$PY" ]] || { echo "python is required to select the golden files" >&2; exit 1; }

# Repo-relative, and one directory per run, for the reasons dod_check.sh gives.
RUN_DIR=".dart_tool/memox_test_bundles/golden-$$"
mkdir -p "$RUN_DIR"
REPORT="${REPORT:-$RUN_DIR/golden-report.jsonl}"
RC_FILE="$RUN_DIR/rc"
trap '[[ "$(cat "$RC_FILE" 2>/dev/null || echo 0)" == "0" ]] && rm -rf "${REPO_ROOT:?}/${RUN_DIR:?}"' EXIT

# Processes for a file-by-file run: MEMOX_TEST_BUNDLES when it names a count,
# so the cap a small machine sets for the bundles holds for --update too;
# otherwise one per core, at most eight, like the bundles.
if [[ "${MEMOX_TEST_BUNDLES:-}" =~ ^[1-9][0-9]*$ ]]; then
  JOBS="$MEMOX_TEST_BUNDLES"
else
  JOBS="$("$PY" -c 'import os; print(max(1, min(os.cpu_count() or 1, 8)))')"
fi

# No golden test file is a pass: SP2 (spec 2026-10-04-sp2) deleted the old UI's
# goldens, and the set is empty until SP3b adds the first `scr_*` one. A golden
# that vanished by mistake still shows: docs/screens' `Golden:` lines, and
# tools/docs/check.py's missing-golden check for a built screen.
no_goldens() {
  echo "no golden test file under test/ — nothing to compare"
  exit 0
}

if [[ $UPDATE -eq 1 || "${MEMOX_TEST_BUNDLES:-}" == "0" ]]; then
  if ! listed="$("$PY" "$SCRIPTS/bundle_tests.py" --root "$REPO_ROOT" --goldens --list test)"; then
    exit 1
  fi
  mapfile -t files <<<"$listed"
  files=("${files[@]%$'\r'}")
  [[ -n "${files[0]:-}" ]] || no_goldens
  update_flag=()
  [[ $UPDATE -eq 1 ]] && update_flag=(--update-goldens)
  echo "goldens: ${#files[@]} files, one by one${update_flag:+, updating}"
  TZ=UTC flutter test --tags golden "${update_flag[@]}" -j "$JOBS" \
    --file-reporter "json:$REPORT" "${files[@]}"
else
  if ! listed="$("$PY" "$SCRIPTS/bundle_tests.py" --root "$REPO_ROOT" --goldens --out "$RUN_DIR" test)"; then
    exit 1
  fi
  mapfile -t bundles <<<"$listed"
  bundles=("${bundles[@]%$'\r'}")
  [[ -n "${bundles[0]:-}" ]] || no_goldens
  TZ=UTC flutter test -j "${#bundles[@]}" --file-reporter "json:$REPORT" "${bundles[@]}"
fi
rc=$?
printf '%s' "$rc" >"$RC_FILE"
"$PY" "$SCRIPTS/test_report.py" "$REPORT" --root "$REPO_ROOT" --rerun-flags "--tags golden"
exit "$rc"
