#!/usr/bin/env bash
# The one definition of *what the formatter looks at*, so the local gate and CI
# cannot disagree about it: both call this script.
#
# The roots come from `git ls-files`, which lists the Dart files *this* working
# tree tracks. `dart format .` would also walk the worktrees under
# `.claude/worktrees/` (other branches' source, and their build output, which
# Gradle deletes while it is being listed) and untracked build output. A new
# top-level directory is picked up by itself; nothing is hardcoded.
#
# The paths are cut to their first segment, so the formatter gets a handful of
# directories rather than hundreds of paths: on Windows that is the difference
# between one process and "The command line is too long".
#
# Without git (an unpacked archive) there are no worktrees either, so `.` is the
# fallback.
#
# Usage: check_format.sh [--fix]
# Exit:  0 formatted, 1 drift found (or a write failed under --fix).
set -uo pipefail

roots() {
  if ! command -v git >/dev/null 2>&1; then
    echo "."

    return
  fi

  local found
  found=$(git ls-files '*.dart' | cut -d/ -f1 | sort -u | tr '\n' ' ')
  echo "${found:-.}"
}

if ! command -v dart >/dev/null 2>&1; then
  echo "dart not found on PATH — the format gate cannot run here."
  exit 1
fi

# shellcheck disable=SC2046  # word splitting is the point: one argument per root
if [[ "${1:-}" == "--fix" ]]; then
  exec dart format $(roots)
fi

# shellcheck disable=SC2046
exec dart format --output=none --set-exit-if-changed $(roots)
