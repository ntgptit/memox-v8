"""PreToolUse hook (Edit|Write): keeps deleted theme names from coming back.

Reads tools/design/removed_symbols.json. Refuses (exit 2) a write that
- puts a removed name into Dart under lib/, test/ or integration_test/,
- writes to a path the file lists as deleted (the old generated theme,
  design/tokens.json and its generator among them, ADR-025).
Any environment problem exits 0: the gate's grep (check.py --symbols) is the
real backstop, and tests/ notice a hook that has stopped working.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "design"))

DART_ROOTS = ("lib/", "test/", "integration_test/")


def relative_path(raw: str) -> str:
    path = Path(raw)
    if not path.is_absolute():
        return path.as_posix()
    try:
        return path.resolve().relative_to(REPO_ROOT.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def verdict(tool_input: dict) -> str | None:
    """The refusal message for this write, or None when it is allowed."""
    import removed_symbols

    raw = tool_input.get("file_path")
    if not raw:
        return None
    relative = relative_path(raw)
    removed, files = removed_symbols.load()

    listed = removed_symbols.forbidden_path(relative, files)
    if listed:
        return (
            f"'{listed}' đã bị xoá. Không tạo lại; giá trị theme nằm ở "
            "lib/core/theme (app_palette.dart, ADR-025)."
        )

    if not relative.endswith(".dart") or not relative.startswith(DART_ROOTS):
        return None
    text = tool_input.get("content") or tool_input.get("new_string") or ""
    hits = removed_symbols.find(text, removed)
    if not hits:
        return None
    lines = [
        f"'{entry.name}' đã bị xoá. Sửa chỗ dùng thành: {entry.replacement} (dòng {line})"
        for entry, line in hits
    ]
    return "\n".join(lines)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        message = verdict(payload.get("tool_input") or {})
    except Exception:  # noqa: BLE001 - the hook must never wedge an edit
        return 0
    if message is None:
        return 0
    print(message, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
