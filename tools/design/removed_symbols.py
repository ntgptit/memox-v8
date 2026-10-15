"""Finds names listed in removed_symbols.json inside Dart source text.

Shared by the PreToolUse hook, check.py and codemod.py so one definition of
"a removed name" serves all three.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path

SYMBOLS_FILE = Path(__file__).resolve().parent / "removed_symbols.json"
REGEX_PREFIX = "re:"
_IDENT = r"A-Za-z0-9_"


@dataclass(frozen=True)
class Removed:
    name: str
    replacement: str
    pattern: re.Pattern[str]


def load(path: Path = SYMBOLS_FILE) -> tuple[list[Removed], list[str]]:
    """The removed names (compiled) and the paths that must not exist."""
    data = json.loads(path.read_text(encoding="utf-8"))
    removed = [_compile(name, text) for name, text in data["symbols"].items()]
    return removed, list(data.get("files", []))


def _compile(name: str, replacement: str) -> Removed:
    if name.startswith(REGEX_PREFIX):
        return Removed(name, replacement, re.compile(name[len(REGEX_PREFIX):]))
    whole_word = rf"(?<![{_IDENT}]){re.escape(name)}(?![{_IDENT}])"
    return Removed(name, replacement, re.compile(whole_word))


def find(text: str, removed: list[Removed]) -> list[tuple[Removed, int]]:
    """Every removed name in [text] with its 1-based line number."""
    hits: list[tuple[Removed, int]] = []
    for entry in removed:
        for match in entry.pattern.finditer(text):
            hits.append((entry, text.count("\n", 0, match.start()) + 1))
    return hits


def forbidden_path(relative: str, files: list[str]) -> str | None:
    """The listed path [relative] is, or sits inside; None when allowed."""
    for listed in files:
        if relative == listed or (listed.endswith("/") and relative.startswith(listed)):
            return listed
    return None
