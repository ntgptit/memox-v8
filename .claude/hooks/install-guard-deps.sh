#!/usr/bin/env bash
# SessionStart hook: install the vendored code-verification-guard-v2's
# requirements into the global Python that dod_check.sh picks for the guard
# (newest of python3.13 / python3.12), in Claude Code on the web sessions.
#
# Remote-only. The cloud image's Python is Debian-managed (PEP 668), hence
# --break-system-packages; --ignore-installed lays the pinned versions over
# Debian's (e.g. PyYAML) in /usr/local instead of trying to uninstall them.
# The container is ephemeral, so the system interpreter is not at lasting risk.
set -uo pipefail

if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" ]]; then
  exit 0
fi

fail() {
  echo "✗ install-guard-deps.sh: $*" >&2
  exit 1
}

repo_root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
requirements="$repo_root/code-verification-guard-v2/requirements-dev.txt"
[[ -f "$requirements" ]] || fail "no $requirements — guard not vendored"

python="$(command -v python3.13 || command -v python3.12 || true)"
[[ -n "$python" ]] || fail "the guard needs Python >= 3.12; none found"

if "$python" -c "import yaml, rich, typer, pytest" >/dev/null 2>&1; then
  echo "install-guard-deps.sh: guard dependencies already present for $python"
  exit 0
fi

"$python" -m pip install --break-system-packages --ignore-installed -q -r "$requirements" \
  || fail "pip install -r $requirements failed for $python"

echo "install-guard-deps.sh: guard dependencies installed for $python"
