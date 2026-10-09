#!/usr/bin/env python3
"""PreToolUse hook (Edit, Write): deny a change to a released migration.

A released migration is immutable (flutter-drift `references/migrations.md`):
a Supabase migration has already run against the hosted database, and a Drift
schema snapshot is what the migration tests replay. A change to either belongs
in a new migration. "Released" means `master` (local or `origin/master`)
already has the file, so a migration written on the branch can still be edited
until it merges.

Anything the hook cannot read — no path, a path outside the repository, git
missing — passes in silence: the hook is an accelerant, not the gate. It sees
only the Edit and Write tools; a shell edit (`sed -i`) is not covered.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
RELEASE_REFS = ("master", "origin/master")
GIT_TIMEOUT_SECONDS = 4


def _is_migration(relative: str) -> bool:
    if relative.startswith("supabase/migrations/") and relative.endswith(".sql"):
        return True
    return relative.startswith("drift_schemas/") and relative.endswith(".json")


def _released(repo: Path, relative: str) -> bool:
    for ref in RELEASE_REFS:
        result = subprocess.run(
            ["git", "-C", str(repo), "cat-file", "-e", f"{ref}:{relative}"],
            capture_output=True,
            timeout=GIT_TIMEOUT_SECONDS,
        )
        if result.returncode == 0:
            return True
    return False


def deny_reason(payload: dict, repo: Path = REPO_ROOT) -> str | None:
    """Why the edit in [payload] is denied, or None when it may go ahead."""
    raw = (payload.get("tool_input") or {}).get("file_path")
    if not raw:
        return None
    try:
        relative = Path(raw).resolve().relative_to(repo.resolve()).as_posix()
    except ValueError:
        return None
    if not _is_migration(relative) or not _released(repo, relative):
        return None
    return (
        f"`{relative}` is a released migration (master has it), and a released "
        "migration is immutable: the hosted database or the Drift migration tests "
        "already depend on it. Write a new migration instead "
        "(flutter-drift references/migrations.md; supabase/README.md)."
    )


def main() -> int:
    try:
        reason = deny_reason(json.loads(sys.stdin.read() or "{}"))
    except Exception:  # noqa: BLE001 - a hook must never break the edit
        return 0
    if reason:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
