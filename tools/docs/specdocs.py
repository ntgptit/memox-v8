"""Parsers of the UI docs layout (spec 2026-10-04-ui-docs-restructure-design).

- docs/USE_CASES.md: one `### UC-<DOMAIN>-NNN — <title>` per use case, under
  `## <Feature>` groups; its sub-sections are `####`.
- docs/functional-spec/<feature>.md: one `## FN-<DOMAIN>-NNN — <title>` per
  function; its sub-sections are `###`.
- docs/screens/spec/SCR-*.md and docs/screens/SCREEN_CATALOG.md: parse_screen,
  catalog_screens, catalog_invariants.

The line right under a UC or FN heading is its meta line:
`Status: ready · Code: [a.dart, b.dart] · Invokes: [FN-DECK-001]`. Keys are
Status, Code, Invokes (UC only) and Superseded by; parts are separated by
` · `; a bare value of a list key is a one-item list.

Pure functions over text, so the tests feed strings.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from mdparse import iter_unfenced, parse_value, split_by_heading

ANY_ID = re.compile(r"\b((?:BR|UC|FN|SCR)-[A-Z]+-\d{3}|INV-UI-\d{3})\b")
ID_LIKE_HEADING = re.compile(r"^(?:UC|FN)-")
UC_HEADING = re.compile(r"^(UC-[A-Z]+-\d{3}) — (\S.*)$")
FN_HEADING = re.compile(r"^(FN-[A-Z]+-\d{3}) — (\S.*)$")
META_KEYS = {"status": "status", "code": "code", "invokes": "invokes", "superseded by": "superseded_by"}
LIST_KEYS = ("code", "invokes")
META_SEPARATOR = " · "


def id_kind(doc_id: str) -> str:
    """`BR-DECK-001` → `BR`; `INV-UI-001` → `INV`."""
    return doc_id.split("-", 1)[0]


def ids_in(text: str, kind: str | None = None) -> list[str]:
    """IDs on unfenced lines, first-seen order; `inline code` counts."""
    seen: list[str] = []
    for _, line in iter_unfenced(text):
        for found in ANY_ID.findall(line):
            if found not in seen and (kind is None or id_kind(found) == kind):
                seen.append(found)
    return seen


@dataclass
class Section:
    id: str
    title: str
    line: int
    meta: dict[str, object]
    body: str
    subsections: list[str] = field(default_factory=list)
    error: str | None = None


def parse_meta_line(line: str) -> tuple[dict[str, object], str | None]:
    meta: dict[str, object] = {}
    for part in line.split(META_SEPARATOR):
        key, colon, raw = part.partition(":")
        if not colon:
            return meta, f"meta part `{part.strip()}` is not `Key: value`; separate parts with ` · `"
        name = META_KEYS.get(key.strip().lower())
        if name is None:
            return meta, f"unknown meta key `{key.strip()}`"
        value = parse_value(raw)
        if name in LIST_KEYS and not isinstance(value, list):
            value = [value] if value else []
        if isinstance(value, str) and ":" in value:
            return meta, f"value `{value}` holds a `:`; separate parts with ` · `"
        meta[name] = value
    return meta, None


def _sections(text: str, level: int, heading: re.Pattern[str], sub_level: int) -> list[Section]:
    found: list[Section] = []
    for title, line_no, body in split_by_heading(text, level):
        match = heading.match(title)
        if match is None:
            if ID_LIKE_HEADING.match(title):
                error = f"heading `{title}` must be `<ID> — <title>` (an em dash between spaces)"
                found.append(Section("", title, line_no, {}, body, error=error))
            continue
        first = next((raw.strip() for raw in body.splitlines() if raw.strip()), "")
        if first.lower().startswith("status:"):
            meta, error = parse_meta_line(first)
        else:
            meta, error = {}, "missing meta line `Status: … · Code: [...]` right under the heading"
        meta.update(id=match[1], title=match[2].strip())
        subsections = [name for name, _, _ in split_by_heading(body, sub_level)]
        found.append(Section(match[1], match[2].strip(), line_no, meta, body, subsections, error))
    return found


def use_case_sections(text: str) -> list[Section]:
    return _sections(text, 3, UC_HEADING, 4)


def function_sections(text: str) -> list[Section]:
    sections = _sections(text, 2, FN_HEADING, 3)
    for section in sections:
        section.meta["rules"] = ids_in(subsection_text(section.body, "Business rules", 3), "BR")
    return sections


def subsection_text(body: str, name: str, level: int) -> str:
    return next((text for title, _, text in split_by_heading(body, level) if title == name), "")
