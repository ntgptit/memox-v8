#!/usr/bin/env bash
# Thin wrapper over `check_generated.py`, which does the check in one process.
# Kept as `.sh` so every caller keeps working.
#
# Usage: check_generated.sh [--skip-rebuild]
# Exit:  0 clean, 1 problems found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$here/check_generated.py" "$@"
