#!/usr/bin/env python3
"""Design-system gate.

  check.py --symbols   removed theme names/paths still present in lib/ or test/
  check.py             everything: symbols, unfilled replacements, and (once the
                       generator exists) generated files against design/tokens.json

Exit 0 = clean, 1 = problems (printed). Python >= 3.12, standard library only.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

import removed_symbols  # noqa: E402

DART_ROOTS = ("lib", "test", "integration_test")


def unfilled_replacements(data: dict) -> list[str]:
    """Entries whose replacement is still empty (the generator adds renames so)."""
    return [
        f"removed_symbols.json: '{name}' has no replacement text"
        for name, text in data["symbols"].items()
        if not text.strip()
    ]


def symbol_problems(root: Path) -> list[str]:
    removed, files = removed_symbols.load()
    problems: list[str] = []
    for listed in files:
        if (root / listed).exists():
            problems.append(f"{listed} must not exist (listed in removed_symbols.json)")
    for top in DART_ROOTS:
        for path in sorted((root / top).rglob("*.dart")) if (root / top).is_dir() else []:
            text = path.read_text(encoding="utf-8", errors="replace")
            for entry, line in removed_symbols.find(text, removed):
                relative = path.relative_to(root).as_posix()
                problems.append(f"{relative}:{line} uses removed '{entry.name}' -> {entry.replacement}")
    return problems


def main(argv: list[str]) -> int:
    problems = symbol_problems(REPO_ROOT)
    if "--symbols" not in argv:
        data = json.loads(removed_symbols.SYMBOLS_FILE.read_text(encoding="utf-8"))
        problems += unfilled_replacements(data)
    for problem in problems:
        print(problem)
    if problems:
        print(f"check.py: {len(problems)} problem(s)")
        return 1
    print("check.py: clean")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
