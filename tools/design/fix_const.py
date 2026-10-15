#!/usr/bin/env python3
"""Drops the `const` the analyzer rejects once a value became `context.dimens.x`.

Reads `flutter analyze` text output on stdin. For each invalid-constant error it
removes the nearest enclosing `const` that starts a constructor call or a
collection literal. A `const` that declares a field or a local
(`const double x = …`) is left for a person.
"""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CODES = {"invalid_constant", "const_initialized_with_non_constant_value",
         "non_constant_list_element", "non_constant_map_value", "const_with_non_constant_argument",
         "non_constant_default_value", "const_eval_method_invocation"}  # fmt: skip
LINE = re.compile(r"^\s*(?:error|warning|info) • .* • (?P<path>\S+?):(?P<line>\d+):(?P<col>\d+) • (?P<code>\w+)$")
CONSTRUCTOR_START = re.compile(r"const\s+(?:[A-Z_]\w*(?:\.\w+)?\s*(?:<[^>]*>)?\s*\(|[\[{<])")


def offset_of(text: str, line: int, col: int) -> int:
    lines = text.split("\n")
    return sum(len(x) + 1 for x in lines[: line - 1]) + col - 1


def expression_end(text: str, start: int) -> int:
    """End of the const expression starting at [start] (its first bracket group)."""
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                return index + 1
    return len(text)


def enclosing_const(text: str, offset: int) -> re.Match[str] | None:
    candidates = [m for m in CONSTRUCTOR_START.finditer(text) if m.start() < offset]
    for match in reversed(candidates):
        if expression_end(text, match.end() - 1) > offset:
            return match
    return None


def main() -> int:
    errors: dict[str, list[tuple[int, int]]] = defaultdict(list)
    for raw in sys.stdin:
        found = LINE.match(raw.rstrip())
        if found and found.group("code") in CODES:
            errors[found.group("path")].append((int(found.group("line")), int(found.group("col"))))
    fixed = 0
    for relative, spots in errors.items():
        path = REPO_ROOT / relative
        text = path.read_text(encoding="utf-8")
        removals: set[int] = set()
        for line, col in spots:
            match = enclosing_const(text, offset_of(text, line, col))
            if match is not None:
                removals.add(match.start())
        for start in sorted(removals, reverse=True):
            text = text[:start] + re.sub(r"^const\s+", "", text[start:], count=1)
            fixed += 1
        path.write_text(text, encoding="utf-8")
    print(f"fix_const.py: removed {fixed} const keyword(s) in {len(errors)} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
