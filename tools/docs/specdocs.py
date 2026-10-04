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


STATE_HEADING = re.compile(r"^`([^`]*)` · (\S.*)$")
SNAKE = re.compile(r"^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$")
GOLDEN_NONE = re.compile(r"^none\s+—\s+\S")
GOLDEN_FILE = re.compile(
    r"^(scr_[a-z]+_\d{3})__([a-z][a-z0-9]*(?:_[a-z0-9]+)*)__([a-z][a-z0-9]*(?:_[a-z0-9]+)*)\.png$"
)
INVOKES = re.compile(r"\bInvokes:(.*)$")
NAVIGATE = re.compile(r"\bNavigate to:(.*)$")
TABLE_ROW = re.compile(r"^\|(.*)\|$")
BACKTICKED = re.compile(r"`([^`]+)`")


@dataclass
class State:
    key: str
    title: str
    line: int
    variants: list[str]
    removed: bool
    error: str | None = None

    @property
    def golden_none(self) -> bool:
        return self.error is None and not self.removed and not self.variants


@dataclass
class Screen:
    states: list[State]
    invokes: list[str]
    navigates: list[str]
    related_ucs: list[str]


def parse_screen(body: str, offset: int = 0) -> Screen:
    """`offset` = file line of the body's first line, minus one."""
    sections = {title: (line_no, text) for title, line_no, text in split_by_heading(body, 2)}
    states_line, states_text = sections.get("States", (0, ""))
    controls = sections.get("Controls", (0, ""))[1]
    return Screen(
        states=[
            _state(title, states_line + line_no + offset, text)
            for title, line_no, text in split_by_heading(states_text, 3)
        ],
        invokes=_ids_after(controls, INVOKES),
        navigates=_ids_after(controls, NAVIGATE),
        related_ucs=ids_in(sections.get("Related Use Cases", (0, ""))[1], "UC"),
    )


def _state(title: str, line: int, text: str) -> State:
    match = STATE_HEADING.match(title)
    if match is None:
        return State("", title, line, [], False, f"state heading `{title}` must be `` `<state_key>` · <Title> ``")
    key = match[1]
    lines = [raw.strip() for _, raw in iter_unfenced(text)]
    removed = "Status: removed" in lines
    golden = next((raw[len("Golden:"):].strip() for raw in lines if raw.startswith("Golden:")), None)
    error = None if SNAKE.match(key) else f"state key `{key}` must be snake_case (a-z, 0-9, single `_`)"
    variants: list[str] = []
    if golden is None:
        if not removed:
            error = error or "state has no `Golden:` line"
    elif golden.lower().startswith("none"):
        if not GOLDEN_NONE.match(golden):
            error = error or "`Golden: none` must say why: `Golden: none — <reason>`"
    else:
        variants = [variant.strip() for variant in golden.split(",")]
        if not all(SNAKE.match(variant) for variant in variants):
            error = error or f"`Golden:` lists snake_case variants (`light, dark`); got `{golden}`"
    return State(key, match[2].strip(), line, variants, removed, error)


def _ids_after(text: str, pattern: re.Pattern[str]) -> list[str]:
    """IDs after `pattern` on its line and on the indented lines its bullet
    wraps onto; the next bullet, heading or unindented line ends it."""
    found: list[str] = []
    is_open = False
    for _, line in iter_unfenced(text):
        match = pattern.search(line)
        if match:
            tail, is_open = match[1], True
        elif is_open and line.startswith("  ") and not line.lstrip().startswith("- "):
            tail = line
        else:
            is_open = False
            continue
        found += [doc_id for doc_id in ANY_ID.findall(tail) if doc_id not in found]
    return found


def golden_name(screen_id: str, key: str, variant: str) -> str:
    return f"{screen_id.lower().replace('-', '_')}__{key}__{variant}.png"


@dataclass
class CatalogScreen:
    id: str
    name: str
    domain: str
    routes: list[str]
    status: str
    line: int


@dataclass
class Invariant:
    id: str
    text: str
    enforced_by: str
    line: int


def _rows(text: str, section: str, first_cell: re.Pattern[str]) -> list[tuple[int, list[str]]]:
    heading_line, body = next(
        ((line_no, body) for title, line_no, body in split_by_heading(text, 2) if title == section),
        (0, ""),
    )
    rows: list[tuple[int, list[str]]] = []
    for line_no, line in iter_unfenced(body):
        match = TABLE_ROW.match(line.strip())
        if match is None:
            continue
        cells = [cell.strip() for cell in match[1].split("|")]
        if first_cell.match(cells[0]):
            rows.append((heading_line + line_no, cells))
    return rows


def catalog_screens(text: str) -> list[CatalogScreen]:
    return [
        CatalogScreen(cells[0], cells[1], cells[2], BACKTICKED.findall(cells[3]), cells[4], line)
        for line, cells in _rows(text, "Screens", re.compile(r"^SCR-[A-Z]+-\d{3}$"))
        if len(cells) >= 6
    ]


def catalog_invariants(text: str) -> list[Invariant]:
    return [
        Invariant(cells[0], cells[1], cells[2], line)
        for line, cells in _rows(text, "Invariants for every screen", re.compile(r"^INV-UI-\d{3}$"))
        if len(cells) >= 3
    ]
