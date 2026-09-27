#!/usr/bin/env bash
# Thin wrapper. The check itself is `check_generated.py`, which reads every
# source once, in one process. The clean-rebuild path (no --skip-rebuild) shells
# out to `dart run build_runner`, with a try/finally that regenerates a usable
# tree if an interrupted rebuild leaves it half-deleted. Kept as `.sh` so every
# caller keeps working.
#
# Usage: check_generated.sh [--skip-rebuild]
# Exit:  0 clean, 1 problems found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$here/check_generated.py" "$@"
