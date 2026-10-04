"""Markdown and frontmatter parsing shared by generate.py, specdocs.py and check.py.

No YAML dependency; generate.py's docstring lists the frontmatter limits.
"""
from __future__ import annotations

import re

HEADING = re.compile(r"^(#{1,6}) (.*)$")


def parse_scalar(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        return value[1:-1]
    return value


def parse_value(raw: str) -> object:
    value = raw.strip()
    if not (value.startswith("[") and value.endswith("]")):
        return parse_scalar(value)
    inner = value[1:-1].strip()
    if not inner:
        return []
    return [parse_scalar(item) for item in inner.split(",")]


def split_frontmatter(text: str) -> tuple[dict[str, object] | None, str, str | None]:
    """Return (meta, body, error). meta is None when the file has no block."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, text, None
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        return None, text, "frontmatter has no closing `---` line"
    meta: dict[str, object] = {}
    for line_no, line in enumerate(lines[1:end], 2):
        if not line.strip():
            continue
        if ":" not in line:
            return meta, "\n".join(lines[end + 1 :]), f"frontmatter line {line_no}: expected `key: value`"
        key, raw = line.split(":", 1)
        meta[key.strip()] = parse_value(raw)
    return meta, "\n".join(lines[end + 1 :]), None


def iter_unfenced(text: str):
    """Yield (line_no, line) for lines outside ``` fences."""
    fenced = False
    for line_no, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced:
            yield line_no, line


def h2_sections(body: str) -> list[str]:
    return [line[3:].strip() for _, line in iter_unfenced(body) if line.startswith("## ")]


def split_by_heading(text: str, level: int) -> list[tuple[str, int, str]]:
    """(heading, line_no, body) for each unfenced heading of exactly `level` `#`.

    A body runs to the next unfenced heading of the same or a higher level;
    deeper headings stay inside it. Lines before the first heading are dropped.
    """
    found: list[tuple[str, int, str]] = []
    current: tuple[str, int] | None = None
    body: list[str] = []
    fenced = False
    for line_no, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("```"):
            fenced = not fenced
        match = None if fenced else HEADING.match(line)
        if match and len(match[1]) <= level:
            if current is not None:
                found.append((current[0], current[1], "\n".join(body)))
            current = (match[2].strip(), line_no) if len(match[1]) == level else None
            body = []
            continue
        if current is not None:
            body.append(line)
    if current is not None:
        found.append((current[0], current[1], "\n".join(body)))
    return found
