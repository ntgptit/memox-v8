# MemoX V8 UI Docs Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the UI-facing documentation to six logical document kinds (PRODUCT, USE_CASES,
FUNCTIONAL_SPEC, SCREEN_CATALOG, SCREEN_SPEC, DESIGN) with one-direction relations that
`tools/docs/check.py` verifies. Write all 34 screen specs from the current app before any old
document or UI code is deleted.

**Architecture:** First the tooling: a shared markdown parser (`mdparse.py`), a parser for the
new section and screen documents (`specdocs.py`), new checks in `check.py`, new generated views
in `generate.py`, and a migration ledger tool (`ledger.py`). Then the content: one pilot domain
(deck), the remaining domains, the screens, navigation and product. Then a ledger-based
verification that the owner signs off. Old homes are retired only after that.

**Tech Stack:** Python 3 standard library only (`tools/docs/`, see `docs/README.md`,
"Kiểm chứng"); `unittest`; Markdown.

**Spec:** `docs/superpowers/specs/2026-10-04-ui-docs-restructure-design.md` (R1–R18). Read it
before any task.

## Global Constraints

- `tools/docs/` stays Python 3 standard library only: no YAML, no third-party package.
- IDs are permanent: `UC-`, `BR-`, `FN-`, `SCR-`, `INV-UI-` IDs and screen state keys are never
  renumbered, renamed or reused (spec R4, §4.4.1).
- Canonical relations only: `UC → FN`, `FN → BR`, `SCREEN → FN`, `SCREEN → UC`,
  `SCREEN → SCREEN`, `NAVIGATION → SCREEN`. Reverse relations live only in `docs/_generated/`
  (R7).
- `docs/USE_CASES.md` and screen specs never cite a BR (R13).
- UC, FN and BR text in Vietnamese; screen spec, `SCREEN_CATALOG.md` and `DESIGN.md` in English;
  no mixing in the normative part of one document, except UI copy and technical terms (R11).
- `DESIGN.md` and `PRODUCT.md` stay at the repository root; there is no `PRODUCT.md` under
  `docs/` (R12).
- Nothing listed in spec §6.1 is deleted before Task 43's sign-off (R18). The old UC files,
  `screen-handoff/`, `navigation.md` and the feature `ui.md` files stay in place until Task 44.
- No change to `lib/`, `test/`, Supabase, or the content of any BR file (spec §3).
- Every task ends with `python3 tools/docs/generate.py`, `python3 tools/docs/check.py` (exit 0)
  and `python3 -m unittest discover -s tools/docs -p 'test_*.py'` (all pass). Tasks 11, 13, 26,
  41, 42 and 44 also run the gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
- Subagents run on Sonnet; the final whole-branch review runs on Opus (`.claude/hooks/README.md`).
- Commit messages end with the attribution lines of the session (Co-Authored-By and
  Claude-Session); no model name in any committed text.

## Plan-time rulings

These decide what the spec leaves open. They go to the owner with the plan; each is cheap to
change before Task 1 starts.

- **PT1 — Screen domains.** Each screen takes the feature folder whose README lists it. Where
  none does: 02 Review algorithm → `srs`; 27 Sync and 33 Users → `account`; 28 Monitoring →
  `monitoring`. Sync behaviour (code in `lib/core/sync/`) is written as `FN-ACCOUNT-…`. Full
  table in Task 28's header.
- **PT2 — `OPEN QUESTION` lines are exempt from the citation-kind rule**, so an open question
  that must name a BR (R13 migration) does not break the gate. `check.py --ledger` fails while
  any `OPEN QUESTION` remains in the new documents (spec §7.1 condition 3).
- **PT3 — ADR citations are unrestricted.** The citation-kind table governs UC, FN, BR, SCR and
  INV-UI IDs only.
- **PT4 — In the new documents an ID inside `inline code` is still a citation.** Elsewhere the
  existing rule (inline code holds examples) stays.
- **PT5 — The catalog row must match the screen's frontmatter** (name, domain, route, status);
  a mismatch is an ERROR, so the catalog cannot drift.
- **PT6 — During migration**, a legacy UC file whose ID `USE_CASES.md` already defines is
  ignored as a definition and reported as a WARNING until Task 44 deletes it.
- **PT7 — `## Màn hình → Use case` in each feature README** restates `SCREEN → UC`. Task 44
  removes it (and its required-section rule); `_generated/index.md` lists each feature's screens
  instead. Its rows enter the ledger like any other source.
- **PT8 — `tools/docs/test_*.py` are not wired into `dod_check.sh`.** Each task runs them by
  hand; wiring them into the gate is a separate change for the owner to ask for.
- **PT9 — State-key permanence** compares the screen spec with the merge base of `HEAD` and the
  first of `origin/main`, `main`, `HEAD` that resolves. A rename already merged into `main` is
  not caught.
- **PT10 — The ledger is seeded by a script** (`tools/docs/ledger.py seed`), not enumerated by
  hand, so no source item is missed.
- **PT11 — Links in a `superseded` or `deprecated` ADR are not checked.** R14 forbids editing
  ADR-019's body, and its links to `screen-handoff/` break in Task 44.
- **PT12 — No text-scale invariant.** Spec §4.5 lists "text scale" as an `INV-UI` seed, but the
  owner ruled on 2026-09-30 that large text scale is not a design target (`PRODUCT.md`;
  `.claude/skills/flutter-design-system/SKILL.md` §2), and `DESIGN.md`'s Text Grows Rule already
  covers non-clamping (R15: never restate `DESIGN.md`).

## Review Focus

- **A UC or FN heading typed with a hyphen** (`### UC-DECK-002 - Sửa deck`) must be an ERROR
  that names the line, never a silently missing definition. Tests: Task 2
  (`test_a_hyphen_instead_of_an_em_dash_is_an_error_not_a_silent_skip`), Task 4
  (`test_a_malformed_heading_is_an_error_with_its_line`).
- **An ID in `inline code` in a new document** (the owner's own examples use backticks) must
  still be checked for existence and kind. Test: Task 5
  (`test_a_backticked_rule_in_a_screen_is_still_caught`).
- **A legacy UC file and its migrated section side by side** (Tasks 12–25) must give no
  duplicate-ID error, one WARNING, and the legacy `rules:` must stop counting as BR usage.
  Tests: Task 4 (`test_a_migrated_legacy_uc_file_is_not_a_duplicate`), Task 8
  (`test_a_migrated_legacy_file_is_a_warning_and_its_rules_do_not_count`).
- **CRLF line endings** (the owner also works on Windows) must parse exactly like LF. Tests:
  Task 1 (`test_crlf_text_splits_like_lf`), Task 3 (`test_a_crlf_catalog_reads_like_lf`).
- **Old-named goldens while `scr_*` goldens appear** must not raise orphan errors before the
  first `scr_*` golden exists, and must after. Tests: Task 7
  (`test_old_goldens_are_not_orphans_before_the_first_scr_golden`,
  `test_an_undeclared_scr_golden_is_an_orphan`).

## File map

| File | Responsibility |
|---|---|
| `tools/docs/mdparse.py` (new) | frontmatter, fences, headings: the parsing `generate.py` had, plus `split_by_heading` |
| `tools/docs/specdocs.py` (new) | pure parsers of UC/FN sections, screen specs, the screen catalog; ID helpers; golden names |
| `tools/docs/generate.py` | loads every document kind into `Doc`; renders `_generated/` (two new views) |
| `tools/docs/check.py` | all checks; `--ledger` mode |
| `tools/docs/ledger.py` (new) | seeds the migration ledger; parses its rows |
| `tools/docs/test_specdocs.py` (new) | unit tests of `mdparse` and `specdocs` |
| `tools/docs/test_ui_docs_layout.py` (new) | `check`/`generate`/`ledger` against fixture trees |
| `docs/USE_CASES.md`, `docs/functional-spec/`, `docs/screens/`, `docs/NAVIGATION.md` (new) | the new documents |
| `docs/shared/decisions/ADR-021-…md` (new), ADR-001…020 frontmatter | authority, ADR vocabulary |
| `docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md` (new) | the migration ledger (execution ledger of this plan) |
| `docs/README.md`, `PRODUCT.md`, `CLAUDE.md` | conventions, product, repo rules |

---

## Phase A — Tooling (spec §7 step 1)

### Task 1: Extract the shared markdown parser

**Files:**
- Create: `tools/docs/mdparse.py`
- Modify: `tools/docs/generate.py` (remove the five parsers, import them)
- Test: `tools/docs/test_specdocs.py` (create)

**Interfaces:**
- Produces: `mdparse.parse_scalar(raw) -> str`, `parse_value(raw) -> object`,
  `split_frontmatter(text) -> tuple[dict | None, str, str | None]`,
  `iter_unfenced(text)` (yields `(line_no, line)`), `h2_sections(body) -> list[str]`,
  `split_by_heading(text, level) -> list[tuple[str, int, str]]` (heading, 1-based line, body).
  `generate` keeps exposing the first five under the same names.

- [ ] **Step 1: Write the failing test**

Create `tools/docs/test_specdocs.py`:

```python
"""Tests for mdparse.py and specdocs.py:  python tools/docs/test_specdocs.py"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import mdparse  # noqa: E402

FENCE = "`" * 3


class SplitByHeadingTest(unittest.TestCase):
    TEXT = (
        "intro\n## A\none\n### A.1\ntwo\n## B\n"
        + FENCE + "\n## not a heading\n" + FENCE + "\nthree\n"
    )

    def test_level_two_bodies_keep_deeper_headings(self):
        found = mdparse.split_by_heading(self.TEXT, 2)
        self.assertEqual([(t, n) for t, n, _ in found], [("A", 2), ("B", 6)])
        self.assertIn("### A.1", found[0][2])

    def test_a_fenced_heading_is_body_text(self):
        body = mdparse.split_by_heading(self.TEXT, 2)[1][2]
        self.assertIn("## not a heading", body)

    def test_a_deeper_split_ends_at_a_shallower_heading(self):
        found = mdparse.split_by_heading(self.TEXT, 3)
        self.assertEqual([(t, n, b) for t, n, b in found], [("A.1", 4, "two")])

    def test_crlf_text_splits_like_lf(self):
        crlf = self.TEXT.replace("\n", "\r\n")
        self.assertEqual(
            [(t, n) for t, n, _ in mdparse.split_by_heading(crlf, 2)],
            [("A", 2), ("B", 6)],
        )


class GenerateReexportTest(unittest.TestCase):
    def test_generate_still_exposes_the_parsers(self):
        import generate

        for name in ("parse_scalar", "parse_value", "split_frontmatter", "iter_unfenced", "h2_sections"):
            self.assertIs(getattr(generate, name), getattr(mdparse, name))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run it and see it fail**

Run: `python3 tools/docs/test_specdocs.py`
Expected: `ModuleNotFoundError: No module named 'mdparse'`

- [ ] **Step 3: Create `tools/docs/mdparse.py`**

Move `parse_scalar`, `parse_value`, `split_frontmatter`, `iter_unfenced` and `h2_sections`
from `generate.py` **verbatim** (bodies unchanged), then add `split_by_heading`:

```python
"""Markdown and frontmatter parsing shared by generate.py, specdocs.py and check.py.

No YAML dependency; generate.py's docstring lists the frontmatter limits.
"""
from __future__ import annotations

import re

HEADING = re.compile(r"^(#{1,6}) (.*)$")


# parse_scalar, parse_value, split_frontmatter, iter_unfenced, h2_sections:
# moved here verbatim from generate.py.


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
```

In `generate.py`, delete the five moved functions and add after the existing imports:

```python
from mdparse import (  # noqa: F401 — re-exported: check.py and the tests use g.<name>
    h2_sections,
    iter_unfenced,
    parse_scalar,
    parse_value,
    split_frontmatter,
)
```

- [ ] **Step 4: Run the tests and the docs check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: all tests `OK`; `PASS — 0 error(s), 45 warning(s)` (the warning count of 2026-10-04).

- [ ] **Step 5: Commit**

```bash
git add tools/docs/mdparse.py tools/docs/generate.py tools/docs/test_specdocs.py
git commit -m "refactor(docs-tools): move markdown parsing into mdparse.py"
```

### Task 2: Parse UC and FN sections

**Files:**
- Create: `tools/docs/specdocs.py`
- Test: `tools/docs/test_specdocs.py`

**Interfaces:**
- Consumes: `mdparse.iter_unfenced`, `parse_value`, `split_by_heading`.
- Produces: `specdocs.ANY_ID` (regex, group 1 = id), `id_kind(doc_id) -> str` (`"BR"`, `"UC"`,
  `"FN"`, `"SCR"`, `"INV"`), `ids_in(text, kind=None) -> list[str]`,
  `Section(id, title, line, meta, body, subsections, error)`,
  `parse_meta_line(line) -> tuple[dict, str | None]`, `use_case_sections(text) -> list[Section]`,
  `function_sections(text) -> list[Section]` (meta gains `rules`),
  `subsection_text(body, name, level) -> str`.

- [ ] **Step 1: Write the failing tests** (append to `test_specdocs.py`, above the `__main__` guard)

```python
import specdocs  # noqa: E402

UC_TEXT = """# Use cases

## Deck

### UC-DECK-001 — Tạo deck
Status: ready · Code: [lib/a.dart] · Invokes: [FN-DECK-001, FN-DECK-002]

#### Mục tiêu / Actor / Precondition
x
#### Main flow
1. Hệ thống thực hiện `FN-DECK-001`.

### UC-DECK-002 - Sửa deck
Status: draft · Code: []
"""

FN_TEXT = (
    "# Deck\n\n"
    "## FN-DECK-001 — Tạo deck\n"
    "Status: active · Code: [lib/features/deck/domain/usecases/create_root_deck_use_case.dart]\n\n"
    "### Precondition\nx\n"
    "### Business rules\n- BR-DECK-020\n- `BR-DECK-021`\n\n"
    + FENCE + "\n## FN-DECK-009 — inside a fence\n" + FENCE + "\n\n"
    "## FN-DECK-002 — Đổi tên\nStatus: active · Code: []\n"
)


class UseCaseSectionTest(unittest.TestCase):
    def test_a_section_reads_its_meta_line_and_subsections(self):
        first = specdocs.use_case_sections(UC_TEXT)[0]
        self.assertEqual((first.id, first.title, first.line), ("UC-DECK-001", "Tạo deck", 5))
        self.assertEqual(first.meta["status"], "ready")
        self.assertEqual(first.meta["code"], ["lib/a.dart"])
        self.assertEqual(first.meta["invokes"], ["FN-DECK-001", "FN-DECK-002"])
        self.assertEqual(first.subsections, ["Mục tiêu / Actor / Precondition", "Main flow"])
        self.assertIsNone(first.error)

    def test_a_hyphen_instead_of_an_em_dash_is_an_error_not_a_silent_skip(self):
        second = specdocs.use_case_sections(UC_TEXT)[1]
        self.assertEqual((second.id, second.line), ("", 13))
        self.assertIn("em dash", second.error)

    def test_a_bare_invokes_value_is_a_one_item_list(self):
        meta, error = specdocs.parse_meta_line("Status: ready · Code: [] · Invokes: FN-DECK-001")
        self.assertIsNone(error)
        self.assertEqual(meta["invokes"], ["FN-DECK-001"])

    def test_a_missing_meta_line_is_reported(self):
        section = specdocs.use_case_sections("### UC-DECK-003 — X\n\n#### Main flow\n")[0]
        self.assertIn("missing meta line", section.error)

    def test_an_unknown_meta_key_is_reported(self):
        _, error = specdocs.parse_meta_line("Status: ready · Owner: me")
        self.assertIn("unknown meta key `Owner`", error)

    def test_a_wrong_separator_is_reported(self):
        _, error = specdocs.parse_meta_line("Status: ready | Code: []")
        self.assertIn("` · `", error)


class FunctionSectionTest(unittest.TestCase):
    def test_rules_come_from_the_business_rules_subsection(self):
        first = specdocs.function_sections(FN_TEXT)[0]
        self.assertEqual(first.meta["rules"], ["BR-DECK-020", "BR-DECK-021"])

    def test_a_fenced_heading_defines_nothing(self):
        ids = [s.id for s in specdocs.function_sections(FN_TEXT)]
        self.assertEqual(ids, ["FN-DECK-001", "FN-DECK-002"])

    def test_ids_in_counts_inline_code_but_not_fences(self):
        text = "a `FN-DECK-001`\n" + FENCE + "\nFN-DECK-002\n" + FENCE + "\n"
        self.assertEqual(specdocs.ids_in(text, "FN"), ["FN-DECK-001"])

    def test_id_kind(self):
        self.assertEqual([specdocs.id_kind(i) for i in ("BR-X-001", "INV-UI-001", "SCR-A-001")], ["BR", "INV", "SCR"])
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_specdocs.py`
Expected: `ModuleNotFoundError: No module named 'specdocs'`

- [ ] **Step 3: Create `tools/docs/specdocs.py`**

```python
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
```

- [ ] **Step 4: Run the tests**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py'`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add tools/docs/specdocs.py tools/docs/test_specdocs.py
git commit -m "feat(docs-tools): parse UC and FN sections"
```

### Task 3: Parse screen specs and the screen catalog

**Files:**
- Modify: `tools/docs/specdocs.py`
- Test: `tools/docs/test_specdocs.py`

**Interfaces:**
- Produces: `State(key, title, line, variants, removed, error)` with property `golden_none`;
  `Screen(states, invokes, navigates, related_ucs)`; `parse_screen(body, offset=0) -> Screen`
  (`invokes`/`navigates` hold every ID found after `Invokes:` / `Navigate to:`, any kind, so
  `check.py` can reject a wrong kind); `golden_name(screen_id, key, variant) -> str`;
  `GOLDEN_FILE` regex; `CatalogScreen(id, name, domain, routes, status, line)`;
  `Invariant(id, text, enforced_by, line)`; `catalog_screens(text)`, `catalog_invariants(text)`.

- [ ] **Step 1: Write the failing tests** (append to `test_specdocs.py`)

```python
SCREEN_BODY = """
# Library

## Related Use Cases
- UC-DECK-001

## States

### `root_loaded` · Root loaded
Golden: light, dark

### `root_error` · Root error
Golden: none — not golden-covered in V8

### `rootSearch` · Search
Golden: light

### `old_state` · Old
Status: removed

### `no_golden` · Missing line

## Controls

### FAB
- Invokes: `FN-DECK-001`
#### On success
- Navigate to: SCR-DECK-002
"""

CATALOG = """# Screen catalog

## Screens

| ID | Screen | Domain | Route | Status | Spec |
|---|---|---|---|---|---|
| SCR-DECK-001 | Library | deck | `/decks`, `/decks/deck/:deckId` | ready | `spec/SCR-DECK-001-deck-list.md` |

## Invariants for every screen

| ID | Invariant | Enforced by |
|---|---|---|
| INV-UI-001 | A failed save keeps what was typed. | — |
"""


class ScreenTest(unittest.TestCase):
    def setUp(self):
        self.screen = specdocs.parse_screen(SCREEN_BODY, offset=6)

    def test_a_state_reads_key_title_line_and_variants(self):
        loaded = self.screen.states[0]
        self.assertEqual(
            (loaded.key, loaded.title, loaded.line, loaded.variants, loaded.error),
            ("root_loaded", "Root loaded", 15, ["light", "dark"], None),
        )

    def test_none_with_a_reason_has_no_variants(self):
        state = self.screen.states[1]
        self.assertEqual((state.variants, state.error, state.golden_none), ([], None, True))

    def test_a_camel_case_key_is_an_error(self):
        self.assertIn("snake_case", self.screen.states[2].error)

    def test_a_removed_state_needs_no_golden_line(self):
        state = self.screen.states[3]
        self.assertEqual((state.removed, state.error), (True, None))

    def test_a_missing_golden_line_is_an_error(self):
        self.assertIn("no `Golden:` line", self.screen.states[4].error)

    def test_none_without_a_reason_is_an_error(self):
        state = specdocs.parse_screen("## States\n### `x` · X\nGolden: none\n").states[0]
        self.assertIn("say why", state.error)

    def test_controls_give_invokes_and_navigation(self):
        self.assertEqual(self.screen.invokes, ["FN-DECK-001"])
        self.assertEqual(self.screen.navigates, ["SCR-DECK-002"])
        self.assertEqual(self.screen.related_ucs, ["UC-DECK-001"])

    def test_golden_name_round_trips_through_the_file_pattern(self):
        name = specdocs.golden_name("SCR-DECK-001", "root_loaded", "light")
        self.assertEqual(name, "scr_deck_001__root_loaded__light.png")
        self.assertIsNotNone(specdocs.GOLDEN_FILE.match(name))
        self.assertIsNone(specdocs.GOLDEN_FILE.match("scr_deck_001__root__loaded__light.png"))


class CatalogTest(unittest.TestCase):
    def test_screen_rows(self):
        row = specdocs.catalog_screens(CATALOG)[0]
        self.assertEqual(
            (row.id, row.name, row.domain, row.routes, row.status, row.line),
            ("SCR-DECK-001", "Library", "deck", ["/decks", "/decks/deck/:deckId"], "ready", 7),
        )

    def test_invariant_rows(self):
        inv = specdocs.catalog_invariants(CATALOG)[0]
        self.assertEqual(
            (inv.id, inv.text, inv.enforced_by, inv.line),
            ("INV-UI-001", "A failed save keeps what was typed.", "—", 13),
        )

    def test_a_crlf_catalog_reads_like_lf(self):
        crlf = CATALOG.replace("\n", "\r\n")
        self.assertEqual(specdocs.catalog_screens(crlf), specdocs.catalog_screens(CATALOG))
        self.assertEqual(specdocs.catalog_invariants(crlf), specdocs.catalog_invariants(CATALOG))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_specdocs.py`
Expected: `AttributeError: module 'specdocs' has no attribute 'parse_screen'`

- [ ] **Step 3: Add the screen and catalog parsers to `specdocs.py`**

```python
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
    found: list[str] = []
    for _, line in iter_unfenced(text):
        match = pattern.search(line)
        if match:
            found += [doc_id for doc_id in ANY_ID.findall(match[1]) if doc_id not in found]
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
```

- [ ] **Step 4: Run the tests**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py'`
Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add tools/docs/specdocs.py tools/docs/test_specdocs.py
git commit -m "feat(docs-tools): parse screen specs, golden names and the screen catalog"
```

### Task 4: Load the new documents and check their identity, fields and references

**Files:**
- Modify: `tools/docs/generate.py`, `tools/docs/check.py`
- Test: `tools/docs/test_ui_docs_layout.py` (create)

**Interfaces:**
- Consumes: Tasks 2–3 parsers.
- Produces in `generate`: `Doc.line: int = 0`, `Doc.screen: object = None`, `Doc.is_section`;
  kinds `"FN"` and `"SCR"`; `use_cases_file()`, `functional_spec_dir()`, `screen_catalog_file()`,
  `navigation_file()` (functions, so tests can repoint `DOCS`); `feature_of_domain(doc_id) -> str`;
  `load_all() -> tuple[list[Doc], list[Doc]]` (documents, migrated legacy UC files);
  `load_docs()` (first item of `load_all()`).
- Produces in `check`: `schema(doc) -> str` (`"UCS"` for a UC section), `where(doc)`,
  `check_references`, `check_invokes_complete`; `run(plan)` uses `g.load_all()`.
- Produces in the test module: `tree`, `DocsTree`, `base(**overrides)`, `errors(files)`,
  `messages(files)` and the fixture constants, reused by Tasks 5–10.

- [ ] **Step 1: Write the failing tests**

Create `tools/docs/test_ui_docs_layout.py`:

```python
"""check.py / generate.py / ledger.py against fixture trees of the new layout.

    python tools/docs/test_ui_docs_layout.py
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check  # noqa: E402

FEATURE_README = """---
feature: deck
code: []
depends_on: []
---
## Phạm vi
x
## Màn hình → Use case
x
## Không thuộc phạm vi
x
"""

BR_FILE = """---
id: BR-DECK-001
title: Tên deck
status: active
summary: x
---
## Rule
x
## Lý do
x
## Ví dụ
x
## Edge case
x
"""

LEGACY_UC = """---
id: UC-DECK-001
title: Tạo deck
status: ready
rules: [BR-DECK-001]
code: []
---
## Mục tiêu / Actor / Precondition
x
## Main flow
x
## Alternative / Error flow
x
## UI
x
## Local
x
## API
x
## Acceptance criteria
- [ ] **Given** x, **when** y, **then** z.
"""

USE_CASES = """# Use cases

## Deck

### UC-DECK-001 — Tạo deck
Status: ready · Code: [] · Invokes: [FN-DECK-001]

#### Mục tiêu / Actor / Precondition
x
#### Main flow
1. Hệ thống thực hiện FN-DECK-001.
#### Alternative / Error flow
x
#### Acceptance criteria
- [ ] **Given** x, **when** y, **then** z.
"""

FUNCTIONS = """# Deck — functional specification

## FN-DECK-001 — Tạo deck
Status: active · Code: []

### Precondition
x
### Input
x
### Kết quả
x
### Lỗi
x
### Business rules
- BR-DECK-001
"""

STATES = """### `root_loaded` · Root loaded
Golden: light, dark
"""

SCREEN = """---
id: SCR-DECK-001
name: Library
domain: deck
status: {status}
route: [/decks]
---
# Library
## Purpose
x
## Related Use Cases
- UC-DECK-001
## Layout
x
## States
{states}
## Controls
### FAB
- Invokes: FN-DECK-001
#### On success
- Navigate to: SCR-DECK-001
## Responsive Behavior
Follows the shared floor.
## Accessibility
Follows the shared floor.
## UI Invariants
None.
## Copy
x
## Rulings
None.
"""

CATALOG = """# Screen catalog

## Screens

| ID | Screen | Domain | Route | Status | Spec |
|---|---|---|---|---|---|
| SCR-DECK-001 | Library | deck | `/decks` | {status} | `spec/SCR-DECK-001-deck-list.md` |

## Invariants for every screen

| ID | Invariant | Enforced by |
|---|---|---|
| INV-UI-001 | A failed save keeps what was typed. | — |
"""

SCREEN_PATH = "docs/screens/spec/SCR-DECK-001-deck-list.md"
CATALOG_PATH = "docs/screens/SCREEN_CATALOG.md"


def screen(status: str = "ready", states: str = STATES) -> str:
    return SCREEN.replace("{status}", status).replace("{states}", states)


def catalog(status: str = "ready") -> str:
    return CATALOG.replace("{status}", status)


def tree(files: dict[str, str]) -> Path:
    root = Path(tempfile.mkdtemp())
    for name, content in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return root


class DocsTree:
    """Point generate/check at a temp repository holding `files`."""

    def __init__(self, files: dict[str, str]) -> None:
        self.root = tree(files)

    def __enter__(self) -> Path:
        g = check.g
        self.saved = (g.ROOT, g.DOCS, g.GENERATED)
        g.ROOT, g.DOCS, g.GENERATED = self.root, self.root / "docs", self.root / "docs" / "_generated"
        return self.root

    def __exit__(self, *exc: object) -> None:
        check.g.ROOT, check.g.DOCS, check.g.GENERATED = self.saved


def base(**overrides: str | None) -> dict[str, str]:
    files: dict[str, str | None] = {
        "docs/features/deck/README.md": FEATURE_README,
        "docs/features/deck/rules/BR-DECK-001-ten-deck.md": BR_FILE,
        "docs/USE_CASES.md": USE_CASES,
        "docs/functional-spec/deck.md": FUNCTIONS,
        SCREEN_PATH: screen(),
        CATALOG_PATH: catalog(),
    }
    files.update(overrides)
    return {name: text for name, text in files.items() if text is not None}


def messages(files: dict[str, str]) -> list[str]:
    with DocsTree(files):
        report = check.run(None)
    return [f"{level} {path}: {message}" for level, path, message in report.lines]


def errors(files: dict[str, str]) -> list[str]:
    """ERRORs, minus the ones a fixture always has (no docs/_generated/)."""
    return [m for m in messages(files) if m.startswith("ERROR") and "docs/_generated" not in m]


def has(found: list[str], *parts: str) -> bool:
    return any(all(part in line for part in parts) for line in found)


class LayoutLoadTest(unittest.TestCase):
    def test_the_base_layout_has_no_error(self):
        self.assertEqual(errors(base()), [])

    def test_a_migrated_legacy_uc_file_is_not_a_duplicate(self):
        files = base(**{"docs/features/deck/usecases/UC-DECK-001-tao-deck.md": LEGACY_UC})
        self.assertEqual(errors(files), [])

    def test_a_malformed_heading_is_an_error_with_its_line(self):
        text = USE_CASES + "\n### UC-DECK-002 - Sửa deck\nStatus: draft · Code: [] · Invokes: []\n"
        self.assertTrue(has(errors(base(**{"docs/USE_CASES.md": text})), "docs/USE_CASES.md:17", "em dash"))

    def test_a_function_in_the_wrong_feature_file(self):
        files = base(**{"docs/functional-spec/card.md": FUNCTIONS.replace("FN-DECK-001", "FN-DECK-002")})
        self.assertTrue(has(errors(files), "has DOMAIN `DECK`; this folder requires `CARD`"))

    def test_a_missing_use_case_subsection(self):
        text = USE_CASES.split("#### Acceptance criteria")[0]
        self.assertTrue(has(errors(base(**{"docs/USE_CASES.md": text})), "missing section `#### Acceptance criteria`"))

    def test_invokes_names_an_unknown_function(self):
        text = USE_CASES.replace("Invokes: [FN-DECK-001]", "Invokes: [FN-DECK-001, FN-DECK-009]")
        found = errors(base(**{"docs/USE_CASES.md": text}))
        self.assertTrue(has(found, "`invokes` names a FN that does not exist: `FN-DECK-009`"))

    def test_a_function_cited_in_the_flow_must_be_in_invokes(self):
        text = USE_CASES.replace("Invokes: [FN-DECK-001]", "Invokes: []")
        found = errors(base(**{"docs/USE_CASES.md": text}))
        self.assertTrue(has(found, "`FN-DECK-001` is cited in the flow but missing from `Invokes:`"))

    def test_a_function_citing_a_deprecated_rule(self):
        rule = BR_FILE.replace("status: active", "status: deprecated")
        found = errors(base(**{"docs/features/deck/rules/BR-DECK-001-ten-deck.md": rule}))
        self.assertTrue(has(found, "`rules` names a deprecated BR: `BR-DECK-001`"))

    def test_a_screen_invoking_an_unknown_function(self):
        text = screen().replace("- Invokes: FN-DECK-001", "- Invokes: FN-DECK-404")
        found = errors(base(**{SCREEN_PATH: text}))
        self.assertTrue(has(found, "`Invokes` names a FN that does not exist: `FN-DECK-404`"))

    def test_a_screen_in_an_unknown_domain(self):
        text = screen().replace("domain: deck", "domain: decks")
        self.assertTrue(has(errors(base(**{SCREEN_PATH: text})), "`domain: decks` is not a feature folder"))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py`
Expected: failures; `test_the_base_layout_has_no_error` fails because `USE_CASES.md` and
`functional-spec/` are not loaded (`FN-DECK-001` is not defined).

- [ ] **Step 3: Load the new documents in `generate.py`**

Add `import specdocs` after the `mdparse` import. In `Doc`, change the kind comment and add
two fields and a property:

```python
    kind: str  # "BR" | "UC" | "ADR" | "FEATURE" | "FN" | "SCR"
    ...
    sections: list[str] = field(default_factory=list)
    line: int = 0  # heading line of a section document; 0 for a file document
    screen: object = None  # specdocs.Screen for kind "SCR"

    @property
    def is_section(self) -> bool:
        return self.line > 0
```

In `classify`, before `return None`:

```python
    if len(parts) == 3 and parts[0] == "screens" and parts[1] == "spec":
        return "SCR", ""
```

Rename the current `load_docs` to `load_file_docs` and, inside its loop, keep the text it
reads so a screen can be parsed:

```python
def load_file_docs() -> list[Doc]:
    docs: list[Doc] = []
    for path in sorted(DOCS.rglob("*.md")):
        kind_feature = classify(path)
        if kind_feature is None:
            continue
        kind, feature = kind_feature
        text = path.read_text(encoding="utf-8")
        meta, body, error = split_frontmatter(text)
        doc = Doc(
            path=path,
            kind=kind,
            feature=feature,
            meta=meta or {},
            body=body,
            frontmatter_error=error if meta is not None else (error or "missing frontmatter"),
            sections=h2_sections(body),
        )
        if kind == "SCR":
            doc.feature = str(doc.meta.get("domain", ""))
            offset = len(text.splitlines()) - len(body.splitlines())
            doc.screen = specdocs.parse_screen(body, offset)
        docs.append(doc)
    return docs


def use_cases_file() -> Path:
    return DOCS / "USE_CASES.md"


def functional_spec_dir() -> Path:
    return DOCS / "functional-spec"


def screen_catalog_file() -> Path:
    return DOCS / "screens" / "SCREEN_CATALOG.md"


def navigation_file() -> Path:
    return DOCS / "NAVIGATION.md"


def feature_of_domain(doc_id: str) -> str:
    """`UC-DECK-001` → `deck`; "" when no feature folder has that DOMAIN."""
    parts = doc_id.split("-")
    domain = parts[1] if len(parts) == 3 else ""
    return {domain_of(name): name for name in feature_names()}.get(domain, "")


def section_doc(path: Path, kind: str, feature: str, section: specdocs.Section) -> Doc:
    return Doc(
        path=path,
        kind=kind,
        feature=feature,
        meta=section.meta,
        body=section.body,
        frontmatter_error=section.error,
        sections=section.subsections,
        line=section.line,
    )


def load_section_docs() -> list[Doc]:
    docs: list[Doc] = []
    if use_cases_file().exists():
        text = use_cases_file().read_text(encoding="utf-8")
        for section in specdocs.use_case_sections(text):
            docs.append(section_doc(use_cases_file(), "UC", feature_of_domain(section.id), section))
    if functional_spec_dir().is_dir():
        for path in sorted(functional_spec_dir().glob("*.md")):
            if path.name == "README.md":
                continue
            for section in specdocs.function_sections(path.read_text(encoding="utf-8")):
                docs.append(section_doc(path, "FN", path.stem, section))
    return docs


def load_all() -> tuple[list[Doc], list[Doc]]:
    """(documents, migrated): a legacy UC file whose id USE_CASES.md now defines
    is returned apart; the section is the definition (plan PT6, until Task 44)."""
    files = load_file_docs()
    sections = load_section_docs()
    moved = {doc.id for doc in sections if doc.kind == "UC"}
    migrated = [doc for doc in files if doc.kind == "UC" and doc.id in moved]
    migrated_paths = {doc.path for doc in migrated}
    return [doc for doc in files if doc.path not in migrated_paths] + sections, migrated


def load_docs() -> list[Doc]:
    return load_all()[0]
```

- [ ] **Step 4: Check the new kinds in `check.py`**

Add `import specdocs  # noqa: E402` next to `import generate as g`. Replace the constants
block from `STATUS = {` through `REQUIRED_SECTIONS = {…}` with:

```python
FN_ID = re.compile(r"^FN-[A-Z]+-\d{3}$")
SCR_ID = re.compile(r"^SCR-[A-Z]+-\d{3}$")
ID_PATTERNS = {"BR": BR_ID, "UC": UC_ID, "ADR": ADR_ID, "FN": FN_ID, "SCR": SCR_ID}

# Keyed by schema(doc): "UCS" is a UC section of docs/USE_CASES.md, "UC" a legacy UC file.
STATUS = {
    "BR": {"draft", "active", "deprecated"},
    "UC": {"draft", "ready", "deprecated"},
    "UCS": {"draft", "ready", "deprecated"},
    "FN": {"draft", "active", "deprecated"},
    "SCR": {"draft", "ready", "built"},
    "ADR": {"draft", "active", "deprecated"},
}
REQUIRED_FIELDS = {
    "BR": ("id", "title", "status", "summary"),
    "UC": ("id", "title", "status", "rules", "code"),
    "UCS": ("id", "title", "status", "code", "invokes"),
    "FN": ("id", "title", "status", "code"),
    "SCR": ("id", "name", "status", "domain", "route"),
    "ADR": ("id", "title", "status"),
    "FEATURE": ("feature", "code", "depends_on"),
}
LIST_FIELDS = {"rules", "code", "depends_on", "invokes", "route", "supersedes"}
REQUIRED_SECTIONS = {
    "BR": ("Rule", "Lý do", "Ví dụ", "Edge case"),
    "UC": (
        "Mục tiêu / Actor / Precondition",
        "Main flow",
        "Alternative / Error flow",
        "UI",
        "Local",
        "API",
        "Acceptance criteria",
    ),
    "UCS": ("Mục tiêu / Actor / Precondition", "Main flow", "Alternative / Error flow", "Acceptance criteria"),
    "FN": ("Precondition", "Input", "Kết quả", "Lỗi", "Business rules"),
    "SCR": (
        "Purpose",
        "Related Use Cases",
        "Layout",
        "States",
        "Controls",
        "Responsive Behavior",
        "Accessibility",
        "UI Invariants",
        "Copy",
        "Rulings",
    ),
    "FEATURE": ("Phạm vi", "Màn hình → Use case", "Không thuộc phạm vi"),
}
SECTION_MARK = {"UCS": "####", "FN": "###"}
# (field, kind of the ID it must name) per schema.
REFERENCE_FIELDS = {"UC": (("rules", "BR"),), "UCS": (("invokes", "FN"),), "FN": (("rules", "BR"),)}
```

Add after `show`:

```python
def schema(doc: g.Doc) -> str:
    return "UCS" if doc.kind == "UC" and doc.is_section else doc.kind


def where(doc: g.Doc) -> Path | str:
    return f"{show(doc.path)}:{doc.line}" if doc.is_section else doc.path
```

Replace `check_frontmatter`, `check_identity`, `check_sections`, `check_paths`,
`check_duplicates` and `check_references` with:

```python
def check_frontmatter(doc: g.Doc, report: Report) -> bool:
    """Report field problems; False only when the block itself is unusable."""
    if doc.frontmatter_error:
        report.error(where(doc), doc.frontmatter_error)
        return False
    for key in REQUIRED_FIELDS[schema(doc)]:
        value = doc.meta.get(key)
        if key in LIST_FIELDS and not isinstance(value, list):
            report.error(where(doc), f"`{key}` must be an inline list `[...]`")
        elif key not in LIST_FIELDS and not value:
            report.error(where(doc), f"missing required field `{key}`")
    allowed = STATUS.get(schema(doc))
    if allowed and doc.status and doc.status not in allowed:
        report.error(where(doc), f"`status: {doc.status}` is not one of {sorted(allowed)}")
    return True


def check_identity(doc: g.Doc, report: Report) -> None:
    if not doc.id:
        return
    if not ID_PATTERNS[doc.kind].match(doc.id):
        report.error(where(doc), f"id `{doc.id}` is malformed")
        return
    if not doc.is_section and not re.fullmatch(re.escape(doc.id) + "-" + SLUG + r"\.md", doc.path.name):
        report.error(doc.path, f"file name must be `{doc.id}-<slug-kebab-case>.md`")
    if doc.kind == "ADR":
        return
    if doc.kind == "SCR" and doc.feature not in g.feature_names():
        report.error(doc.path, f"`domain: {doc.feature}` is not a feature folder")
        return
    if not doc.feature:
        report.error(where(doc), f"id `{doc.id}` has a DOMAIN that no feature folder maps to")
        return
    expected = g.domain_of(doc.feature)
    actual = doc.id.split("-")[1]
    if actual != expected:
        report.error(where(doc), f"id `{doc.id}` has DOMAIN `{actual}`; this folder requires `{expected}`")


def check_sections(doc: g.Doc, report: Report) -> None:
    mark = SECTION_MARK.get(schema(doc), "##")
    for name in REQUIRED_SECTIONS.get(schema(doc), ()):
        if name not in doc.sections:
            report.error(where(doc), f"missing section `{mark} {name}`")
    if doc.kind == "BR" and USED_BY_SECTION.search(doc.body):
        report.error(doc.path, "a BR must not carry a \"Được dùng bởi\" section — generate.py produces it")


def check_paths(doc: g.Doc, report: Report) -> None:
    for code_path in doc.as_list("code"):
        if not (g.ROOT / code_path).exists():
            report.error(where(doc), f"path in `code` does not exist: `{code_path}`")


def check_duplicates(docs: list[g.Doc], report: Report) -> dict[str, g.Doc]:
    by_id: dict[str, g.Doc] = {}
    for doc in docs:
        if doc.kind == "FEATURE" or not doc.id:
            continue
        if doc.id in by_id:
            report.error(where(doc), f"id `{doc.id}` duplicates {show(where(by_id[doc.id]))}")
            continue
        by_id[doc.id] = doc
    return by_id


def check_reference(doc: g.Doc, label: str, ref: str, kind: str, by_id: dict[str, g.Doc], report: Report) -> None:
    target = by_id.get(ref)
    if target is None or target.kind != kind:
        report.error(where(doc), f"`{label}` names a {kind} that does not exist: `{ref}`")
    elif target.status == "deprecated":
        report.error(where(doc), f"`{label}` names a deprecated {kind}: `{ref}`")


def check_references(docs: list[g.Doc], by_id: dict[str, g.Doc], report: Report) -> None:
    for doc in docs:
        for label, kind in REFERENCE_FIELDS.get(schema(doc), ()):
            for ref in doc.as_list(label):
                check_reference(doc, label, ref, kind, by_id, report)
        if doc.kind == "SCR" and doc.screen is not None:
            for label, refs, kind in (
                ("Invokes", doc.screen.invokes, "FN"),
                ("Navigate to", doc.screen.navigates, "SCR"),
                ("Related Use Cases", doc.screen.related_ucs, "UC"),
            ):
                for ref in refs:
                    check_reference(doc, label, ref, kind, by_id, report)
        superseded_by = str(doc.meta.get("superseded_by") or "")
        if not superseded_by:
            continue
        if superseded_by not in by_id:
            report.error(where(doc), f"`superseded_by` names an id that does not exist: `{superseded_by}`")
        if doc.status != "deprecated":
            report.error(where(doc), "`superseded_by` is only allowed with `status: deprecated`")


def check_invokes_complete(doc: g.Doc, report: Report) -> None:
    """Every FN a UC section's flow cites is on its `Invokes:` line."""
    if schema(doc) != "UCS":
        return
    for fn_id in specdocs.ids_in(doc.body, "FN"):
        if fn_id not in doc.as_list("invokes"):
            report.error(where(doc), f"`{fn_id}` is cited in the flow but missing from `Invokes:`")
```

Replace `check_acceptance_criteria` and delete `section_text` (its only caller):

```python
def check_acceptance_criteria(doc: g.Doc, report: Report) -> None:
    """A `ready` UC is a contract; its criteria are the checkable half (BE-D4)."""
    if doc.kind != "UC" or doc.status != "ready":
        return
    level = 4 if doc.is_section else 2
    text = specdocs.subsection_text(doc.body, ACCEPTANCE_SECTION, level)
    criteria = [line for _, line in g.iter_unfenced(text) if g.OPEN_QUESTION not in line]
    if not any(ACCEPTANCE_LINE.search(line) for line in criteria):
        report.error(where(doc), "ready UC has no Given/When/Then line under `## Acceptance criteria`")
```

In `check_warnings`, report on `where(doc)` instead of `doc.path` (three calls). In `run`,
replace `docs = g.load_docs()` with `docs, migrated = g.load_all()` and call
`check_invokes_complete(doc, report)` after `check_acceptance_criteria(doc, report)` inside the
per-document loop. (`migrated` is used in Task 8.)

In the module docstring, under ERROR, add:

```
- a UC section of docs/USE_CASES.md or an FN section of docs/functional-spec/
  with a malformed heading or meta line, a bad field, or a missing `####`/`###`
  sub-section; an FN in a file whose name is not its feature
- a screen spec with a bad frontmatter, a missing `##` section, or a domain
  that is not a feature folder
- `invokes`, an FN's `### Business rules`, or a screen's `Invokes:`,
  `Navigate to:` or `## Related Use Cases` naming an id that does not exist
  or is deprecated; an FN cited in a UC flow but missing from its `Invokes:`
```

- [ ] **Step 5: Run the tests and the repository check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: `OK`; `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 6: Commit**

```bash
git add tools/docs/generate.py tools/docs/check.py tools/docs/test_ui_docs_layout.py
git commit -m "feat(docs-tools): load UC/FN sections and screen specs, check their fields and references"
```

### Task 5: Citation kinds per document and no hand-written reverse relations

**Files:**
- Modify: `tools/docs/check.py`
- Test: `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Consumes: `specdocs.ANY_ID`, `id_kind`, `catalog_invariants`; `g.screen_catalog_file()`.
- Produces: `screen_catalog() -> tuple[list[CatalogScreen], list[Invariant]]`,
  `allowed_kinds(path) -> set[str] | None`, `defined_ids(docs)` (now BR, UC, FN, SCR and
  INV-UI), `REVERSE_HEADING`.

- [ ] **Step 1: Write the failing tests** (add a class to `test_ui_docs_layout.py`)

```python
class CitationTest(unittest.TestCase):
    def test_a_use_case_may_not_cite_a_rule(self):
        text = USE_CASES.replace("#### Alternative / Error flow\nx", "#### Alternative / Error flow\nTheo BR-DECK-001.")
        found = errors(base(**{"docs/USE_CASES.md": text}))
        self.assertTrue(has(found, "`BR-DECK-001` is a BR ID; USE_CASES.md may cite only FN"))

    def test_an_open_question_may_name_a_rule(self):
        text = USE_CASES + "\n> ⚠️ OPEN QUESTION: BR-DECK-001 không thuộc FN nào.\n"
        self.assertEqual(errors(base(**{"docs/USE_CASES.md": text})), [])

    def test_an_adr_citation_is_free(self):
        text = USE_CASES.replace("#### Alternative / Error flow\nx", "#### Alternative / Error flow\nXem ADR-013.")
        self.assertEqual(errors(base(**{"docs/USE_CASES.md": text})), [])

    def test_a_function_may_not_cite_a_use_case(self):
        text = FUNCTIONS.replace("### Kết quả\nx", "### Kết quả\nDùng trong UC-DECK-001.")
        found = errors(base(**{"docs/functional-spec/deck.md": text}))
        self.assertTrue(has(found, "`UC-DECK-001` is a UC ID; functional-spec/deck.md may cite only BR"))

    def test_a_backticked_rule_in_a_screen_is_still_caught(self):
        text = screen().replace("## Layout\nx", "## Layout\nName field (`BR-DECK-001`).")
        found = errors(base(**{SCREEN_PATH: text}))
        self.assertTrue(has(found, "`BR-DECK-001` is a BR ID; screens/spec/SCR-DECK-001-deck-list.md may cite only"))

    def test_an_undefined_function_in_a_screen_is_caught(self):
        text = screen().replace("## Purpose\nx", "## Purpose\nRuns FN-DECK-404.")
        self.assertTrue(has(errors(base(**{SCREEN_PATH: text})), "`FN-DECK-404` is cited but not defined"))

    def test_the_catalog_may_not_cite_a_use_case(self):
        text = catalog().replace("A failed save keeps what was typed.", "See UC-DECK-001.")
        found = errors(base(**{CATALOG_PATH: text}))
        self.assertTrue(has(found, "`UC-DECK-001` is a UC ID; screens/SCREEN_CATALOG.md may cite only INV, SCR"))

    def test_hand_written_reverse_relations_are_errors(self):
        cases = {
            "docs/functional-spec/deck.md": FUNCTIONS + "### Related Screens\n- SCR-DECK-001\n",
            SCREEN_PATH: screen().replace("## Copy\nx", "## Copy\nx\n## Related BR\nx"),
            "docs/features/deck/rules/BR-DECK-001-ten-deck.md": BR_FILE + "## Used by\nx\n",
        }
        for path, text in cases.items():
            with self.subTest(path=path):
                self.assertTrue(has(errors(base(**{path: text})), "states a reverse relation"))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py CitationTest`
Expected: failures (no kind rule, no reverse-relation rule yet).

- [ ] **Step 3: Implement**

In `check.py`, delete `ID_IN_TEXT` and `USED_BY_SECTION`, and add:

```python
# Which ID kinds each new-layout document may cite (spec §4.8, R13); other docs: any kind.
CITE_RULES: tuple[tuple[str, set[str]], ...] = (
    ("USE_CASES.md", {"FN"}),
    ("functional-spec/", {"BR"}),
    ("screens/spec/", {"FN", "UC", "SCR", "INV"}),
    ("screens/SCREEN_CATALOG.md", {"SCR", "INV"}),
    ("NAVIGATION.md", {"SCR", "UC"}),
)
# A UC or FN heading defines its id; it does not cite it.
DEFINITION_LINE = re.compile(r"^#{2,3} (?:UC|FN)-[A-Z]+-\d{3} — ")
REVERSE_HEADING = re.compile(
    r"^#{2,6}\s*(được dùng bởi|used by|invoked by|related screens|related br|"
    r"related business rules|entry points|functional capabilities)\b",
    re.I,
)
REVERSE_CHECKED = {"BR", "FEATURE", "UC", "UCS", "FN", "SCR"}


def allowed_kinds(path: Path) -> set[str] | None:
    rel = path.relative_to(g.DOCS).as_posix()
    for prefix, kinds in CITE_RULES:
        if rel == prefix or (prefix.endswith("/") and rel.startswith(prefix)):
            return kinds
    return None


def screen_catalog() -> tuple[list[specdocs.CatalogScreen], list[specdocs.Invariant]]:
    path = g.screen_catalog_file()
    if not path.exists():
        return [], []
    text = path.read_text(encoding="utf-8")
    return specdocs.catalog_screens(text), specdocs.catalog_invariants(text)
```

In `check_sections`, replace the BR `USED_BY_SECTION` block with:

```python
    if schema(doc) in REVERSE_CHECKED:
        for _, line in g.iter_unfenced(doc.body):
            if REVERSE_HEADING.match(line):
                report.error(
                    where(doc),
                    f"`{line.strip()}` states a reverse relation; only generate.py writes those (spec R7)",
                )
```

Replace `defined_ids` and `check_text`:

```python
def defined_ids(docs: list[g.Doc]) -> set[str]:
    _, invariants = screen_catalog()
    ids = {d.id for d in docs if d.kind in ("BR", "UC", "FN", "SCR") and d.id}
    return ids | {inv.id for inv in invariants}


def check_text(docs: list[g.Doc], report: Report) -> None:
    ids = defined_ids(docs)
    invariants = defined_invariants()
    for path in markdown_files():
        check_ids = not is_skipped_for_ids(path)
        skip_links = is_skipped_for_links(path)
        kinds = allowed_kinds(path)
        rel = path.relative_to(g.DOCS).as_posix()
        text = path.read_text(encoding="utf-8")
        body_start = frontmatter_end(text)
        for line_no, raw in g.iter_unfenced(text):
            where_line = f"{show(path)}:{line_no}"
            # `inline code` holds examples and markers, not citations or links.
            line = g.INLINE_CODE.sub("", raw)
            if not skip_links:
                check_links(path, line, where_line, report)
            # Frontmatter ids are checked as fields (`rules`, `superseded_by`).
            if not check_ids or line_no <= body_start:
                continue
            # In the new layout an id in `inline code` is still a citation (plan PT4).
            cited = set(specdocs.ANY_ID.findall(raw if kinds is not None else line))
            for missing in sorted(cited - ids):
                report.error(where_line, f"`{missing}` is cited but not defined")
            if kinds is not None and g.OPEN_QUESTION not in raw and not DEFINITION_LINE.match(raw):
                for wrong in sorted(c for c in cited if specdocs.id_kind(c) not in kinds):
                    report.error(
                        where_line,
                        f"`{wrong}` is a {specdocs.id_kind(wrong)} ID; {rel} may cite only {', '.join(sorted(kinds))}",
                    )
            for n in INVARIANT_CITE.findall(line):
                if invariants is not None and int(n) not in invariants:
                    report.error(where_line, f"`invariant Q{n}` is cited but there is no `-- {n}.`")
```

In the docstring, replace the line `- a BR carrying a hand-written "used by" section (it is generated)` with:

```
- a hand-written reverse relation (`Used by`, `Invoked by`, `Related Screens`,
  `Related BR`, `Entry points`, `Functional capabilities`) in a BR, feature
  README, UC, FN or screen spec — generate.py writes those
- an id kind a new-layout document may not cite (USE_CASES.md: FN;
  functional-spec/: BR; screens/spec/: FN, UC, SCR, INV-UI; the catalog: SCR,
  INV-UI; NAVIGATION.md: SCR, UC); OPEN QUESTION lines are exempt. In these
  documents an id in `inline code` still counts
```

- [ ] **Step 4: Run the tests and the repository check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: `OK`; `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 5: Commit**

```bash
git add tools/docs/check.py tools/docs/test_ui_docs_layout.py
git commit -m "feat(docs-tools): citation kinds per document; reject hand-written reverse relations"
```

### Task 6: ADR vocabulary, ADR-021, one PRODUCT

**Files:**
- Modify: `tools/docs/check.py`, `docs/shared/decisions/ADR-0*.md` (frontmatter only),
  `docs/README.md` (the ADR frontmatter line), `CLAUDE.md` (the UI-authority invariant)
- Create: `docs/shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md`
- Test: `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Produces: `STATUS["ADR"] == {"draft", "accepted", "superseded", "deprecated"}`;
  `check_supersession(docs, by_id, report)`; `check_single_product(report)`.

- [ ] **Step 1: Write the failing tests**

```python
def adr(doc_id: str, status: str, extra: str = "", body: str = "x") -> str:
    return f"---\nid: {doc_id}\ntitle: t\nstatus: {status}\n{extra}---\n## Bối cảnh\n{body}\n"


ADR1 = "docs/shared/decisions/ADR-001-a.md"
ADR2 = "docs/shared/decisions/ADR-002-b.md"


class AdrTest(unittest.TestCase):
    def test_a_reciprocal_pair_passes(self):
        files = base(**{
            ADR1: adr("ADR-001", "superseded", "superseded_by: ADR-002\n"),
            ADR2: adr("ADR-002", "accepted", "supersedes: [ADR-001]\n"),
        })
        self.assertEqual(errors(files), [])

    def test_superseded_needs_superseded_by(self):
        self.assertTrue(has(errors(base(**{ADR1: adr("ADR-001", "superseded")})), "needs `superseded_by`"))

    def test_the_successor_must_name_what_it_supersedes(self):
        files = base(**{
            ADR1: adr("ADR-001", "superseded", "superseded_by: ADR-002\n"),
            ADR2: adr("ADR-002", "accepted"),
        })
        self.assertTrue(has(errors(files), "ADR-002 has no `supersedes: [ADR-001]`"))

    def test_active_is_no_longer_an_adr_status(self):
        self.assertTrue(has(errors(base(**{ADR1: adr("ADR-001", "active")})), "`status: active` is not one of"))

    def test_a_product_file_under_docs_is_an_error(self):
        found = errors(base(**{"docs/features/deck/PRODUCT.md": "# Product\n"}))
        self.assertTrue(has(found, "product definition lives only in /PRODUCT.md"))

    def test_links_of_a_superseded_adr_are_not_checked(self):
        files = base(**{
            ADR1: adr("ADR-001", "superseded", "superseded_by: ADR-002\n", "[gone](gone.md)"),
            ADR2: adr("ADR-002", "accepted", "supersedes: [ADR-001]\n"),
        })
        self.assertFalse(has(errors(files), "broken link"))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py AdrTest`
Expected: failures.

- [ ] **Step 3: Implement in `check.py`**

Set `"ADR": {"draft", "accepted", "superseded", "deprecated"},` in `STATUS`. In
`check_frontmatter`, before `return True`:

```python
    if "supersedes" in doc.meta and not isinstance(doc.meta["supersedes"], list):
        report.error(where(doc), "`supersedes` must be an inline list `[...]`")
```

In `check_references`, change the last check to:

```python
        if doc.status not in ("deprecated", "superseded"):
            report.error(where(doc), "`superseded_by` is only allowed with `status: deprecated` or `superseded`")
```

Add:

```python
def check_supersession(docs: list[g.Doc], by_id: dict[str, g.Doc], report: Report) -> None:
    """`supersedes` and `superseded_by` point at each other (spec R14)."""
    for doc in docs:
        if doc.kind != "ADR":
            continue
        successor = str(doc.meta.get("superseded_by") or "")
        if doc.status == "superseded" and not successor:
            report.error(doc.path, "`status: superseded` needs `superseded_by`")
        if doc.status == "superseded" and successor in by_id and doc.id not in by_id[successor].as_list("supersedes"):
            report.error(doc.path, f"`superseded_by: {successor}` but {successor} has no `supersedes: [{doc.id}]`")
        for old in doc.as_list("supersedes"):
            target = by_id.get(old)
            if target is None or target.kind != "ADR":
                report.error(doc.path, f"`supersedes` names an ADR that does not exist: `{old}`")
            elif target.status != "superseded" or str(target.meta.get("superseded_by")) != doc.id:
                report.error(doc.path, f"`supersedes: [{old}]` but {old} is not `superseded` by {doc.id}")


def check_single_product(report: Report) -> None:
    for path in sorted(g.DOCS.rglob("PRODUCT.md")):
        report.error(path, "product definition lives only in /PRODUCT.md (spec R12)")
```

In `check_text`, after `ids = defined_ids(docs)`:

```python
    # A superseded or deprecated ADR is a record; its body is never edited (plan PT11).
    records = {d.path for d in docs if d.kind == "ADR" and d.status in ("superseded", "deprecated")}
```

and change `skip_links = is_skipped_for_links(path)` to
`skip_links = is_skipped_for_links(path) or path in records`.

In `run`, after `check_references(docs, by_id, report)`:

```python
    check_supersession(docs, by_id, report)
    check_single_product(report)
```

Docstring, under ERROR, add:

```
- an ADR `superseded` without `superseded_by`, or `supersedes`/`superseded_by`
  that do not point at each other; ADR status is draft | accepted | superseded |
  deprecated. Links in a superseded or deprecated ADR are not checked
- a PRODUCT.md anywhere under docs/ (the product lives in /PRODUCT.md)
```

- [ ] **Step 4: Run the unit tests**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py'`
Expected: `OK`. (`check.py` on the repository now fails on 19 `active` ADRs; Step 5 fixes it.)

- [ ] **Step 5: Migrate the ADRs and write ADR-021**

```bash
sed -i 's/^status: active$/status: superseded\nsuperseded_by: ADR-021/' docs/shared/decisions/ADR-019-app-la-chuan-ui.md
sed -i '/^superseded_by:$/d' docs/shared/decisions/ADR-019-app-la-chuan-ui.md
sed -i 's/^status: active$/status: accepted/' docs/shared/decisions/ADR-0*.md
head -6 docs/shared/decisions/ADR-019-app-la-chuan-ui.md
grep -h '^status:' docs/shared/decisions/*.md | sort | uniq -c
```

Expected: ADR-019's frontmatter is `id`, `title`, `status: superseded`, `superseded_by: ADR-021`
(its empty `superseded_by:` line removed, body untouched); counts `18 accepted`,
`1 deprecated`, `1 superseded`. Check the deprecated ADR still has its own `superseded_by` line:
`grep -l '^status: deprecated' docs/shared/decisions/*.md | xargs grep -n superseded_by`.

Create `docs/shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md`:

```markdown
---
id: ADR-021
title: Tài liệu dẫn UI khi xây lại; DESIGN.md và screen spec là chuẩn
status: accepted
supersedes: [ADR-019]
---
## Bối cảnh

ADR-019 đặt app làm chuẩn UI: `DESIGN.md` được sinh từ code, file chi tiết của mỗi màn ghi
lại màn đã build kèm golden. Ngày 2026-10-04 chủ dự án quyết định xoá UI và build lại vì nợ
code ở lớp presentation, giữ nguyên hệ thống hình ảnh và UX, và bỏ toàn bộ golden hiện có
([spec](../../superpowers/specs/2026-10-04-ui-docs-restructure-design.md), R1, R2). Khi code
và golden không còn, chuẩn mà ADR-019 dựa vào cũng mất.

## Quyết định

- Thứ tự ưu tiên: BR, FN và UC > `DESIGN.md` > screen spec (`docs/screens/spec/`) > golden đã
  được chủ dự án duyệt. Golden lệch với spec là lỗi ở một trong hai; chủ dự án quyết bên nào.
- `DESIGN.md` là tài liệu viết tay, không sinh từ code; code theo nó. PR đổi hệ thống hình ảnh
  sửa `DESIGN.md` trước.
- PR đổi một màn sửa screen spec của màn đó và hàng của nó trong
  `docs/screens/SCREEN_CATALOG.md`.
- Artifact "Mobile UI Kit v3" vẫn retired, không được đọc.

## Hệ quả

- ADR-019 giữ nguyên văn với `status: superseded`, `superseded_by: ADR-021`.
- Trạng thái ADR là `draft | accepted | superseded | deprecated`; ADR thay thế ADR khác ghi
  `supersedes`.
- Cấu trúc tài liệu, quan hệ một chiều và thứ tự migration theo spec ở trên.
  `docs/shared/ui/screen-handoff/` chỉ thôi là nơi ghi màn sau khi migration được kiểm chứng
  (spec §7.1).
```

In `docs/README.md`, replace

```
ADR — `shared/decisions/`: frontmatter `id`, `title`, `status`
(`draft | active | deprecated`), `superseded_by` khi deprecated.
```

with

```
ADR — `shared/decisions/`: frontmatter `id`, `title`, `status`
(`draft | accepted | superseded | deprecated`), `superseded_by` khi superseded hoặc
deprecated, `supersedes: [ADR-…]` ở ADR thay thế. Link trong ADR superseded hoặc deprecated
không được kiểm (bản ghi, không sửa).
```

In `CLAUDE.md`, replace the bullet that starts `- **The app is the UI authority**` (6 lines)
with:

```markdown
- **Documents are the UI authority** ([ADR-021](docs/shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md),
  superseding ADR-019): BR, FN and UC beat `DESIGN.md`; `DESIGN.md` beats a
  screen spec (`docs/screens/spec/`); a screen spec beats its goldens, which
  the owner reviews. The "Mobile UI Kit v3" artifact is retired and never read.
  A PR that changes the visual system updates `DESIGN.md` first; one that
  changes a screen updates its spec and its row in
  `docs/screens/SCREEN_CATALOG.md`. Until the migration is verified (spec
  2026-10-04 §7.1) the old screen records in `docs/shared/ui/screen-handoff/`
  stay readable.
```

- [ ] **Step 6: Regenerate and check the repository**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1 && python3 -m unittest discover -s tools/docs -p 'test_*.py'`
Expected: `PASS — 0 error(s), 45 warning(s)`; `OK`.

- [ ] **Step 7: Commit**

```bash
git add tools/docs/check.py tools/docs/test_ui_docs_layout.py docs/shared/decisions docs/_generated docs/README.md CLAUDE.md
git commit -m "docs(adr): ADR-021 supersedes ADR-019; ADR status accepted/superseded; one PRODUCT"
```

### Task 7: Screen catalog, state keys and goldens

**Files:**
- Modify: `tools/docs/check.py`
- Test: `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Consumes: `screen_catalog()` (Task 5), `specdocs.golden_name`, `GOLDEN_FILE`.
- Produces: `g.golden_files() -> dict[str, Path]` (in `generate.py`; Task 9 uses it);
  `check_catalog(docs, report)`; `check_screen_states(docs, report, goldens, base_keys)`;
  `base_state_keys(path) -> set[str] | None`; `run(plan, base_keys=base_state_keys)`.

- [ ] **Step 1: Write the failing tests**

```python
class ScreenStateTest(unittest.TestCase):
    def found(self, files, goldens=(), base_keys=None) -> list[str]:
        with DocsTree(files) as root:
            docs = check.g.load_docs()
            report = check.Report()
            check.check_catalog(docs, report)
            golden_paths = {name: root / "test" / "goldens" / name for name in goldens}
            check.check_screen_states(docs, report, golden_paths, lambda path: base_keys)
        return [f"{level} {message}" for level, _, message in report.lines]

    def test_the_base_screen_and_catalog_agree(self):
        self.assertEqual([m for m in self.found(base()) if m.startswith("ERROR")], [])

    def test_an_invariant_enforced_by_nothing_is_a_warning(self):
        self.assertIn("WARNING `INV-UI-001` is enforced by nothing yet", self.found(base()))

    def test_a_catalog_status_that_differs_from_the_spec(self):
        found = self.found(base(**{CATALOG_PATH: catalog("built")}))
        self.assertTrue(has(found, "`Status` is `built` but SCR-DECK-001's spec says `ready`"))

    def test_a_screen_without_a_catalog_row(self):
        found = self.found(base(**{CATALOG_PATH: catalog().split("| SCR-DECK-001")[0]}))
        self.assertTrue(has(found, "screen has no row in screens/SCREEN_CATALOG.md"))

    def test_a_built_screen_needs_its_goldens(self):
        files = base(**{SCREEN_PATH: screen("built"), CATALOG_PATH: catalog("built")})
        found = self.found(files)
        self.assertTrue(has(found, "golden `scr_deck_001__root_loaded__light.png` is missing"))
        self.assertTrue(has(found, "golden `scr_deck_001__root_loaded__dark.png` is missing"))
        present = ("scr_deck_001__root_loaded__light.png", "scr_deck_001__root_loaded__dark.png")
        self.assertFalse(has(self.found(files, present), "ERROR"))

    def test_an_undeclared_scr_golden_is_an_orphan(self):
        found = self.found(base(), ("scr_deck_001__root_loaded__light.png", "scr_deck_001__gone__light.png"))
        self.assertTrue(has(found, "golden matches no screen state"))

    def test_old_goldens_are_not_orphans_before_the_first_scr_golden(self):
        self.assertFalse(has(self.found(base(), ("library_decks_light.png",)), "orphan"))

    def test_a_renamed_state_key_is_an_error(self):
        found = self.found(base(), base_keys={"root_loaded", "old_key"})
        self.assertTrue(has(found, "state key `old_key` was renamed or deleted"))

    def test_a_removed_state_kept_as_a_heading_passes(self):
        states = STATES + "### `old_key` · Old\nStatus: removed\n"
        found = self.found(base(**{SCREEN_PATH: screen(states=states)}), base_keys={"root_loaded", "old_key"})
        self.assertFalse(has(found, "ERROR"))

    def test_a_duplicate_state_key(self):
        found = self.found(base(**{SCREEN_PATH: screen(states=STATES + STATES)}))
        self.assertTrue(has(found, "state key `root_loaded` is used twice"))

    def test_a_built_state_without_goldens_is_a_warning(self):
        states = "### `root_loaded` · Root loaded\nGolden: none — static text only\n"
        files = base(**{SCREEN_PATH: screen("built", states), CATALOG_PATH: catalog("built")})
        self.assertIn("WARNING built screen: state `root_loaded` has no golden", self.found(files))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py ScreenStateTest`
Expected: `AttributeError: module 'check' has no attribute 'check_catalog'`.

- [ ] **Step 3: Implement**

In `generate.py`, after `test_files`:

```python
def golden_files() -> dict[str, Path]:
    """Golden PNG name → path, for every PNG under test/**/goldens/."""
    root = ROOT / "test"
    if not root.is_dir():
        return {}
    return {path.name: path for path in sorted(root.rglob("*.png")) if "goldens" in path.parts}
```

In `check.py`, add `import functools` and `import subprocess` to the imports, and:

```python
def check_catalog(docs: list[g.Doc], report: Report) -> None:
    """Each screen has one catalog row that agrees with its frontmatter (plan PT5)."""
    rows, invariants = screen_catalog()
    path = g.screen_catalog_file()
    screens = {d.id: d for d in docs if d.kind == "SCR" and d.id}
    seen: set[str] = set()
    for row in rows:
        at = f"{show(path)}:{row.line}"
        if row.id in seen:
            report.error(at, f"`{row.id}` has two catalog rows")
            continue
        seen.add(row.id)
        doc = screens.get(row.id)
        if doc is None:
            report.error(at, f"catalog row `{row.id}` has no screen spec")
            continue
        expected = (str(doc.meta.get("name", "")), doc.feature, doc.as_list("route"), doc.status)
        actual = (row.name, row.domain, row.routes, row.status)
        for label, want, got in zip(("Screen", "Domain", "Route", "Status"), expected, actual):
            if want != got:
                report.error(at, f"`{label}` is `{got}` but {row.id}'s spec says `{want}`")
    for doc_id, doc in sorted(screens.items()):
        if doc_id not in seen:
            report.error(doc.path, "screen has no row in screens/SCREEN_CATALOG.md")
    defined: set[str] = set()
    for inv in invariants:
        at = f"{show(path)}:{inv.line}"
        if inv.id in defined:
            report.error(at, f"`{inv.id}` is defined twice")
        defined.add(inv.id)
        if inv.enforced_by in ("", "—"):
            report.warning(at, f"`{inv.id}` is enforced by nothing yet")


def check_screen_states(docs, report, goldens: dict[str, Path], base_keys) -> None:
    """State keys are unique and permanent; a built screen has its goldens;
    once a `scr_*` golden exists, every golden maps to a declared state (R16)."""
    declared: set[str] = set()
    for doc in [d for d in docs if d.kind == "SCR" and d.id and d.screen is not None]:
        keys: list[str] = []
        for state in doc.screen.states:
            at = f"{show(doc.path)}:{state.line}"
            if state.error:
                report.error(at, state.error)
                continue
            if state.key in keys:
                report.error(at, f"state key `{state.key}` is used twice in this screen")
                continue
            keys.append(state.key)
            if state.removed:
                continue
            names = [specdocs.golden_name(doc.id, state.key, variant) for variant in state.variants]
            declared.update(names)
            if doc.status != "built":
                continue
            if state.golden_none:
                report.warning(at, f"built screen: state `{state.key}` has no golden")
            for name in names:
                if name not in goldens:
                    report.error(at, f"built screen: golden `{name}` is missing")
        for missing in sorted((base_keys(doc.path) or set()) - set(keys)):
            report.error(
                doc.path,
                f"state key `{missing}` was renamed or deleted; keys are permanent — "
                "keep its heading with `Status: removed`",
            )
    if any(name.startswith("scr_") for name in goldens):
        for name in sorted(set(goldens) - declared):
            report.error(goldens[name], "golden matches no screen state (orphan)")


@functools.lru_cache(maxsize=1)
def base_commit() -> str | None:
    """Merge base with the first of origin/main, main, HEAD that resolves (plan PT9)."""
    for ref in ("origin/main", "main", "HEAD"):
        result = subprocess.run(["git", "merge-base", "HEAD", ref], cwd=g.ROOT, capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    return None


def base_state_keys(path: Path) -> set[str] | None:
    commit = base_commit()
    if commit is None:
        return None
    shown = subprocess.run(
        ["git", "show", f"{commit}:{path.relative_to(g.ROOT).as_posix()}"],
        cwd=g.ROOT, capture_output=True, encoding="utf-8",
    )
    if shown.returncode != 0:
        return None
    _, body, _ = g.split_frontmatter(shown.stdout)
    return {state.key for state in specdocs.parse_screen(body).states if state.key}
```

Change `run` to `def run(plan: Path | None, base_keys=base_state_keys) -> Report:` and add,
after `check_single_product(report)`:

```python
    check_catalog(docs, report)
    check_screen_states(docs, report, g.golden_files(), base_keys)
```

In the test module, change `messages` to call `check.run(None, base_keys=lambda path: None)`
so no fixture asks git.

Docstring, under ERROR:

```
- a screen without a catalog row, or a catalog row that disagrees with the
  screen's frontmatter (name, domain, route, status)
- a state heading or `Golden:` line that is malformed; a state key used twice
  or renamed since the merge base (keys are permanent; a removed state keeps
  its heading with `Status: removed`)
- a `built` screen missing a golden its states declare; once any
  `scr_*` golden exists, a golden that matches no declared state
```

and under WARNING: `- an INV-UI enforced by nothing; a built screen's state with no golden`.

- [ ] **Step 4: Run the tests and the repository check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: `OK`; `PASS — 0 error(s), 45 warning(s)` (old goldens are not `scr_*`, so no orphan).

- [ ] **Step 5: Commit**

```bash
git add tools/docs/generate.py tools/docs/check.py tools/docs/test_ui_docs_layout.py
git commit -m "feat(docs-tools): check the screen catalog, state keys and goldens"
```

### Task 8: Warnings for the new relations

**Files:**
- Modify: `tools/docs/generate.py`, `tools/docs/check.py`
- Test: `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Produces: `g.used_by(docs)` (BR → FN ids and legacy UC-file ids), `g.invoked_by(docs)`
  (FN → UC and SCR ids); `check_warnings(docs, migrated, report)`.

- [ ] **Step 1: Write the failing tests**

```python
class WarningTest(unittest.TestCase):
    def warnings(self, files) -> list[str]:
        return [m for m in messages(files) if m.startswith("WARNING")]

    def test_a_rule_no_function_cites(self):
        files = base(**{"docs/functional-spec/deck.md": FUNCTIONS.replace("- BR-DECK-001", "Không áp dụng.")})
        self.assertTrue(has(self.warnings(files), "BR-DECK-001", "active BR is cited by no FN"))

    def test_a_function_nobody_invokes(self):
        extra = FUNCTIONS.split("## FN-DECK-001")[1].replace(" — Tạo deck", " — Đổi tên", 1)
        files = base(**{"docs/functional-spec/deck.md": FUNCTIONS + "\n## FN-DECK-002" + extra})
        self.assertTrue(has(self.warnings(files), "active FN is invoked by no UC and no screen"))

    def test_a_ready_use_case_whose_functions_have_no_code(self):
        self.assertTrue(has(self.warnings(base()), "ready UC: it and every FN it invokes have `Code: []`"))

    def test_a_migrated_legacy_file_is_a_warning_and_its_rules_do_not_count(self):
        legacy = {"docs/features/deck/usecases/UC-DECK-001-tao-deck.md": LEGACY_UC}
        files = base(**{"docs/functional-spec/deck.md": FUNCTIONS.replace("- BR-DECK-001", "Không áp dụng."), **legacy})
        found = self.warnings(files)
        self.assertTrue(has(found, "now lives in USE_CASES.md; retire this file"))
        self.assertTrue(has(found, "BR-DECK-001", "active BR is cited by no FN"))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py WarningTest`
Expected: failures.

- [ ] **Step 3: Implement**

In `generate.py`, replace `used_by` and add `invoked_by`:

```python
def used_by(docs: list[Doc]) -> dict[str, list[str]]:
    """BR id → ids of the FNs (and legacy UC files) whose `rules` cite it."""
    usage: dict[str, set[str]] = {}
    for doc in docs:
        if doc.kind == "FN" or (doc.kind == "UC" and not doc.is_section):
            for rule_id in doc.as_list("rules"):
                usage.setdefault(rule_id, set()).add(doc.id)
    return {rule_id: sorted(users) for rule_id, users in usage.items()}


def invoked_by(docs: list[Doc]) -> dict[str, list[str]]:
    """FN id → ids of the UC sections and screens that invoke it."""
    usage: dict[str, set[str]] = {}
    for doc in docs:
        if doc.kind == "UC" and doc.is_section:
            targets = doc.as_list("invokes")
        elif doc.kind == "SCR" and doc.screen is not None:
            targets = doc.screen.invokes
        else:
            continue
        for fn_id in targets:
            usage.setdefault(fn_id, set()).add(doc.id)
    return {fn_id: sorted(users) for fn_id, users in usage.items()}
```

In `check.py`, replace `check_warnings`:

```python
def check_warnings(docs: list[g.Doc], migrated: list[g.Doc], report: Report) -> None:
    usage = g.used_by(docs)
    invoked = g.invoked_by(docs)
    functions = {d.id: d for d in docs if d.kind == "FN"}
    ready = [d for d in docs if d.kind == "UC" and d.status == "ready"]
    tests = g.tests_by_id([d.id for d in ready])
    for doc in docs:
        if doc.kind == "BR" and doc.status == "active" and doc.id not in usage:
            report.warning(doc.path, "active BR is cited by no FN (nor by a UC file not yet migrated)")
        if doc.kind == "FN" and doc.status == "active" and doc.id not in invoked:
            report.warning(where(doc), "active FN is invoked by no UC and no screen")
    for doc in ready:
        if doc.is_section:
            invoked_fns = [functions[f] for f in doc.as_list("invokes") if f in functions]
            if not doc.as_list("code") and not any(f.as_list("code") for f in invoked_fns):
                report.warning(where(doc), "ready UC: it and every FN it invokes have `Code: []`")
        elif not doc.as_list("code"):
            report.warning(doc.path, "ready UC has `code: []`")
        if not tests[doc.id]:
            report.warning(where(doc), "ready UC has no test that contains its id")
    for doc in migrated:
        report.warning(doc.path, f"`{doc.id}` now lives in USE_CASES.md; retire this file in Task 44 (spec §7)")
```

In `run`, call `check_warnings(docs, migrated, report)`. Docstring WARNING list becomes:

```
WARNING
- active BR cited by no FN (nor by a legacy UC file); active FN invoked by no
  UC and no screen; ready UC with no code (legacy: `code: []`; section: it
  and its FNs) or with no test; a legacy UC file already moved to USE_CASES.md
- an INV-UI enforced by nothing; a built screen's state with no golden
```

- [ ] **Step 4: Run the tests and the repository check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: `OK`; `PASS — 0 error(s), 45 warning(s)` (the BR warning text changed; the count did not).

- [ ] **Step 5: Commit**

```bash
git add tools/docs/generate.py tools/docs/check.py tools/docs/test_ui_docs_layout.py
git commit -m "feat(docs-tools): warnings for uncited BRs, uninvoked FNs and migrated UC files"
```

### Task 9: Generated views of the reverse relations

**Files:**
- Modify: `tools/docs/generate.py`
- Test: `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Produces: `render_screens(docs) -> str`, `render_navigation(docs) -> str`; `render_all()`
  returns `index.md`, `traceability.md`, `screens.md`, `navigation-graph.md`,
  `open-questions.md`.

- [ ] **Step 1: Write the failing tests**

```python
class GeneratedTest(unittest.TestCase):
    def render(self, files) -> dict[str, str]:
        with DocsTree(files):
            return check.g.render_all()

    def test_index_lists_a_function_with_who_invokes_it(self):
        out = self.render(base())["index.md"]
        self.assertIn("| [FN-DECK-001](../functional-spec/deck.md) | Tạo deck | active | SCR-DECK-001, UC-DECK-001 |", out)

    def test_index_says_which_function_uses_a_rule(self):
        self.assertIn("| x | FN-DECK-001 |", self.render(base())["index.md"])

    def test_index_lists_the_screens_of_a_feature(self):
        self.assertIn("| [SCR-DECK-001](../screens/spec/SCR-DECK-001-deck-list.md) | Library | ready | `/decks` |", self.render(base())["index.md"])

    def test_traceability_goes_through_functions(self):
        self.assertIn("| ready | FN-DECK-001 | BR-DECK-001 |", self.render(base())["traceability.md"])

    def test_screens_show_rules_entry_points_and_router_entries(self):
        files = base(**{"docs/NAVIGATION.md": "# Navigation\n\nDeep link `/decks` opens SCR-DECK-001.\n"})
        out = self.render(files)["screens.md"]
        self.assertIn("- Rules via FN: BR-DECK-001", out)
        self.assertIn("- Entry points: SCR-DECK-001, NAVIGATION.md", out)
        self.assertIn("| `root_loaded` | light, dark | — |", out)

    def test_the_navigation_graph_has_the_edge(self):
        self.assertIn("| SCR-DECK-001 | SCR-DECK-001 |", self.render(base())["navigation-graph.md"])

    def test_output_is_stable(self):
        self.assertEqual(self.render(base()), self.render(base()))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py GeneratedTest`
Expected: failures (`KeyError: 'screens.md'` and missing rows).

- [ ] **Step 3: Implement in `generate.py`**

In `render_index`, inside the group loop, after `decisions = …`:

```python
        functions = sorted((d for d in group_docs if d.kind == "FN"), key=by_id)
        screens = sorted((d for d in group_docs if d.kind == "SCR"), key=by_id)
        if not (rules or cases or decisions or functions or screens):
```

(replacing the existing `if not (rules or cases or decisions):`). Compute
`invoked = invoked_by(docs)` next to `usage = used_by(docs)`. After the rules table block add:

```python
        if functions:
            lines += ["### Functions", "", "| ID | Title | Status | Invoked by |", "|---|---|---|---|"]
            for d in functions:
                lines.append(
                    f"| [{d.id}]({rel_link(d.path, GENERATED)}) | {cell(d.title)} | {cell(d.status)} "
                    f"| {', '.join(invoked.get(d.id, [])) or '—'} |"
                )
            lines.append("")
```

and after the use-case/decision loop:

```python
        if screens:
            lines += ["### Screens", "", "| ID | Name | Status | Route |", "|---|---|---|---|"]
            for d in screens:
                routes = ", ".join(f"`{route}`" for route in d.as_list("route"))
                lines.append(
                    f"| [{d.id}]({rel_link(d.path, GENERATED)}) | {cell(str(d.meta.get('name', '')))} "
                    f"| {cell(d.status)} | {routes or '—'} |"
                )
            lines.append("")
```

Replace `render_traceability`:

```python
def render_traceability(docs: list[Doc]) -> str:
    cases = sorted((d for d in docs if d.kind == "UC"), key=lambda d: (d.feature, d.id))
    functions = {d.id: d for d in docs if d.kind == "FN"}
    tests = tests_by_id([d.id for d in cases])
    lines = [
        GENERATED_HEADER,
        "",
        "# Traceability",
        "",
        "Use case → functions → rules → code → test. Test = file trong "
        + ", ".join(f"`{name}/`" for name in TEST_DIRS)
        + " có chứa chuỗi ID của UC.",
        "",
        "| UC | Status | Functions | Rules | Code | Tests |",
        "|---|---|---|---|---|---|",
    ]
    for d in cases:
        invoked = [functions[f] for f in d.as_list("invokes") if f in functions]
        rules = d.as_list("rules") if not d.is_section else sorted({r for f in invoked for r in f.as_list("rules")})
        code = list(dict.fromkeys(d.as_list("code") + [c for f in invoked for c in f.as_list("code")]))
        lines.append(
            f"| [{d.id}]({rel_link(d.path, GENERATED)}) | {cell(d.status)} "
            f"| {cell(', '.join(d.as_list('invokes')))} "
            f"| {cell(', '.join(rules))} "
            f"| {cell(', '.join(f'`{c}`' for c in code))} "
            f"| {cell(', '.join(f'`{t}`' for t in tests[d.id]))} |"
        )
    if not cases:
        lines.append("| — | — | — | — | — | — |")
    return "\n".join(lines) + "\n"
```

Add:

```python
def router_entries() -> list[str]:
    path = navigation_file()
    return specdocs.ids_in(path.read_text(encoding="utf-8"), "SCR") if path.exists() else []


def render_screens(docs: list[Doc]) -> str:
    screens = sorted((d for d in docs if d.kind == "SCR" and d.screen is not None), key=lambda d: d.id)
    functions = {d.id: d for d in docs if d.kind == "FN"}
    incoming: dict[str, set[str]] = {}
    for doc in screens:
        for target in doc.screen.navigates:
            incoming.setdefault(target, set()).add(doc.id)
    routed = router_entries()
    goldens = golden_files()
    lines = [GENERATED_HEADER, "", "# Screens", ""]
    if not screens:
        lines += ["Không có.", ""]
    for doc in screens:
        rules = sorted({r for f in doc.screen.invokes if f in functions for r in functions[f].as_list("rules")})
        entries = sorted(incoming.get(doc.id, set())) + (["NAVIGATION.md"] if doc.id in routed else [])
        lines += [
            f"## [{doc.id}]({rel_link(doc.path, GENERATED)}) · {cell(str(doc.meta.get('name', '')))}",
            "",
            f"- Invokes: {', '.join(doc.screen.invokes) or '—'}",
            f"- Rules via FN: {', '.join(rules) or '—'}",
            f"- Use cases: {', '.join(doc.screen.related_ucs) or '—'}",
            f"- Entry points: {', '.join(entries) or '—'}",
            "",
        ]
        states = [s for s in doc.screen.states if s.key and not s.removed]
        if states:
            lines += ["| State | Golden | Present |", "|---|---|---|"]
            for state in states:
                names = [specdocs.golden_name(doc.id, state.key, v) for v in state.variants]
                present = ", ".join(f"`{n}`" for n in names if n in goldens) or "—"
                lines.append(f"| `{state.key}` | {', '.join(state.variants) or 'none'} | {present} |")
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_navigation(docs: list[Doc]) -> str:
    screens = [d for d in docs if d.kind == "SCR" and d.screen is not None]
    edges = sorted({(d.id, target) for d in screens for target in d.screen.navigates})
    lines = [
        GENERATED_HEADER,
        "",
        "# Navigation graph",
        "",
        "Screen → screen edges from each spec's `Navigate to:` lines (spec R9).",
        "",
        "| From | To |",
        "|---|---|",
    ]
    lines += [f"| {source} | {target} |" for source, target in edges] or ["| — | — |"]
    lines += ["", "## Router entries", "", "Screens that `NAVIGATION.md` routes to.", ""]
    lines += [f"- {doc_id}" for doc_id in sorted(router_entries())] or ["Không có."]
    return "\n".join(lines) + "\n"
```

In `render_all`, add `"screens.md": render_screens(docs)` and
`"navigation-graph.md": render_navigation(docs)`; in `main`, print
`f"generated {len(render_all())} files"` — compute once:

```python
    files = render_all()
    args.out.mkdir(parents=True, exist_ok=True)
    for name, content in files.items():
        (args.out / name).write_text(content, encoding="utf-8", newline="\n")
    shown = args.out.relative_to(ROOT) if args.out.is_relative_to(ROOT) else args.out
    print(f"OK {shown}: generated {len(files)} files")
```

(replacing `write_all(args.out)` and the old print in `main`; keep `write_all` for `check.py`).
Update the module docstring's first line to
`"""Generate docs/_generated/{index,traceability,screens,navigation-graph,open-questions}.md.`

- [ ] **Step 4: Regenerate, run the tests and the repository check**

Run: `python3 tools/docs/generate.py && python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: `OK docs/_generated: generated 5 files`; `OK`; `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 5: Commit**

```bash
git add tools/docs/generate.py tools/docs/test_ui_docs_layout.py docs/_generated
git commit -m "feat(docs-tools): generate function users, screens and the navigation graph"
```

### Task 10: Migration ledger tooling

**Files:**
- Create: `tools/docs/ledger.py`
- Modify: `tools/docs/check.py` (`--ledger`)
- Test: `tools/docs/test_ui_docs_layout.py`

**Interfaces:**
- Produces: `ledger.items(text) -> list[tuple[int, str]]`, `ledger.source_items(path)`,
  `ledger.render(existing: dict[str, str]) -> str`, `ledger.rows(text) -> list[tuple[int, str, str]]`
  (line, source cell, outcome), `ledger.OUTCOME`; `check.check_ledger(path, defined, report)`,
  `check.new_layout_files()`, `run(plan, base_keys=…, ledger_path=None)`, CLI `--ledger FILE`.

- [ ] **Step 1: Write the failing tests**

```python
import ledger  # noqa: E402  (next to `import check`)

LEDGER_ROW = "| `features/deck/usecases/UC-DECK-001-x.md:5` Para | {} |\n"


class LedgerItemsTest(unittest.TestCase):
    def test_every_kind_of_item_is_a_row(self):
        fence = "`" * 3
        text = (
            "---\nid: UC-X-001\nrules: [BR-X-001]\n---\n# Title\n\nPara one\ncontinues\n\n"
            "- item a\n  wrapped\n- item b\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n"
            + fence + "mermaid\nA --> B\n" + fence + "\n"
        )
        self.assertEqual(
            [n for n, _ in ledger.items(text)],
            [2, 3, 5, 7, 10, 12, 14, 16, 19],
        )

    def test_reseeding_keeps_outcomes_and_reads_only_the_named_sections(self):
        files = {
            "docs/features/deck/usecases/UC-DECK-001-x.md": "# T\n\nPara\n",
            "docs/features/deck/README.md": "# D\n\n## Phạm vi\n\nS\n\n## Màn hình → Use case\n\nM\n",
            "docs/README.md": "# D\n\n## Sản phẩm\n\nP1\n\n## Bản đồ\n\nX\n",
        }
        with DocsTree(files):
            first = ledger.render({})
            source = next(src for _, src, _ in ledger.rows(first) if "UC-DECK-001" in src)
            second = ledger.render({source: "superseded → R11"})
        self.assertIn(f"| {source} | superseded → R11 |", second)
        self.assertIn("P1", second)
        self.assertNotIn("`README.md:9`", second)
        self.assertIn("`features/deck/README.md:9`", second)
        self.assertNotIn("`features/deck/README.md:5`", second)


class LedgerCheckTest(unittest.TestCase):
    def found(self, outcomes: list[str], **extra: str) -> list[str]:
        files = base(**extra)
        files["ledger.md"] = "## x\n\n| Source item | Outcome |\n|---|---|\n" + "".join(
            LEDGER_ROW.format(outcome) for outcome in outcomes
        )
        with DocsTree(files) as root:
            docs = check.g.load_docs()
            report = check.Report()
            check.check_ledger(root / "ledger.md", check.defined_ids(docs), report)
        return [message for _, _, message in report.lines]

    def test_valid_outcomes_pass(self):
        outcomes = ["moved → `USE_CASES.md`", "superseded → FN-DECK-001", "dropped — implementation detail, approved 2026-10-20"]
        self.assertEqual(self.found(outcomes), [])

    def test_an_empty_outcome_fails(self):
        self.assertTrue(has(self.found([""]), "(empty)"))

    def test_moved_to_a_missing_path_fails(self):
        self.assertTrue(has(self.found(["moved → `nowhere.md`"]), "does not exist"))

    def test_dropped_without_approval_fails(self):
        self.assertTrue(has(self.found(["dropped — not needed"]), "is not"))

    def test_superseded_by_an_undefined_id_fails(self):
        self.assertTrue(has(self.found(["superseded → FN-DECK-404"]), "undefined id"))

    def test_an_open_question_left_in_the_new_docs_fails(self):
        text = USE_CASES + "\n> ⚠️ OPEN QUESTION: x\n"
        self.assertTrue(has(self.found(["moved → `USE_CASES.md`"], **{"docs/USE_CASES.md": text}), "still open"))
```

- [ ] **Step 2: Run and see them fail**

Run: `python3 tools/docs/test_ui_docs_layout.py LedgerItemsTest LedgerCheckTest`
Expected: `ModuleNotFoundError: No module named 'ledger'`.

- [ ] **Step 3: Create `tools/docs/ledger.py`**

```python
#!/usr/bin/env python3
"""Migration ledger of the UI docs restructure (spec 2026-10-04 §7.1).

    python tools/docs/ledger.py seed OUT.md

One `##` section per source file and one row per source item:
`| \\`<path>:<line>\\` <excerpt> | <outcome> |`. An item is a frontmatter line,
a heading, a table row, a list item, the start of a paragraph, or a non-empty
line inside a fence (mermaid nodes and edges). Goldens get one row per PNG.
Re-running `seed` keeps every outcome already written for an unchanged row.
`check.py --ledger OUT.md` verifies the outcomes.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate as g  # noqa: E402

EXCERPT = 80
LIST_ITEM = re.compile(r"^(?:[-*]|\d+\.)\s")
SEPARATOR_ROW = re.compile(r"^\|[\s:|-]+\|?$")
CELL_SPLIT = re.compile(r"(?<!\\)\|")
OUTCOME = re.compile(
    r"^(?:moved → `(?P<dest>[^`]+)`|superseded → (?P<by>\S.*)|dropped — .+, approved \d{4}-\d{2}-\d{2})$"
)
# Files whose ledger rows cover one section only: path relative to docs/ → heading.
ONE_SECTION = {"README.md": "## Sản phẩm"}
FEATURE_README_SECTION = "## Màn hình → Use case"  # plan PT7


def source_files() -> list[Path]:
    docs = g.DOCS
    files = sorted((docs / "shared" / "ui" / "screen-handoff").glob("*.md"))
    files += sorted(docs.glob("features/*/usecases/*.md"))
    files += sorted(docs.glob("features/*/ui.md"))
    files += sorted(docs.glob("features/*/README.md"))
    files += [path for path in (docs / "shared" / "ui" / "navigation.md", docs / "README.md") if path.exists()]
    return files


def items(text: str) -> list[tuple[int, str]]:
    lines = text.splitlines()
    found: list[tuple[int, str]] = []
    start = 0
    if lines and lines[0].strip() == "---":
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), 0)
        found += [(i + 1, lines[i].strip()) for i in range(1, end) if lines[i].strip()]
        start = end + 1
    fenced = in_block = False
    for index in range(start, len(lines)):
        line_no, stripped = index + 1, lines[index].strip()
        if stripped.startswith("```"):
            fenced, in_block = not fenced, False
            continue
        if not stripped:
            in_block = False
            continue
        if stripped.startswith("|") and SEPARATOR_ROW.match(stripped):
            continue
        if fenced or stripped.startswith("#") or stripped.startswith("|"):
            found.append((line_no, stripped))
            in_block = False
            continue
        if LIST_ITEM.match(stripped) or not in_block:
            found.append((line_no, stripped))
            in_block = True
    return found


def section_heading(path: Path) -> str | None:
    rel = path.relative_to(g.DOCS).as_posix()
    if rel in ONE_SECTION:
        return ONE_SECTION[rel]
    if path.name == "README.md" and path.parent.parent.name == "features":
        return FEATURE_README_SECTION
    return None


def source_items(path: Path) -> list[tuple[int, str]]:
    text = path.read_text(encoding="utf-8")
    found = items(text)
    heading = section_heading(path)
    if heading is None:
        return found
    lines = text.splitlines()
    start = next((i + 1 for i, line in enumerate(lines) if line.strip() == heading), None)
    if start is None:
        return []
    end = next((i + 1 for i in range(start, len(lines)) if lines[i].startswith("## ")), len(lines) + 1)
    return [(n, t) for n, t in found if start <= n < end]


def escape(text: str) -> str:
    # The excerpt points at the source; it must not be collected as an open question itself.
    return text[:EXCERPT].rstrip().replace("|", "\\|").replace("OPEN QUESTION", "OPEN·QUESTION")


def table(title: str, sources: list[str], existing: dict[str, str]) -> list[str]:
    lines = [f"## {title}", "", "| Source item | Outcome |", "|---|---|"]
    lines += [f"| {source} | {existing.get(source, '')} |" for source in sources]
    return lines + [""]


def render(existing: dict[str, str]) -> str:
    lines = [
        "# UI docs restructure — migration ledger",
        "",
        "Seeded by `python3 tools/docs/ledger.py seed`; outcomes are written by hand.",
        "An outcome is one of: moved → `<path relative to docs/>`; superseded → <ID or ruling>;",
        "dropped — <reason>, approved <YYYY-MM-DD>. `check.py --ledger` verifies them.",
        "",
    ]
    for path in source_files():
        rel = path.relative_to(g.DOCS).as_posix()
        sources = [f"`{rel}:{n}` {escape(text)}" for n, text in source_items(path)]
        if sources:
            lines += table(rel, sources, existing)
    goldens = [f"`{p.relative_to(g.ROOT).as_posix()}`" for p in g.golden_files().values()]
    if goldens:
        lines += table("Goldens", goldens, existing)
    return "\n".join(lines).rstrip() + "\n"


def rows(text: str) -> list[tuple[int, str, str]]:
    found: list[tuple[int, str, str]] = []
    for line_no, line in enumerate(text.splitlines(), 1):
        if not line.startswith("| `"):
            continue
        cells = [cell.strip() for cell in CELL_SPLIT.split(line)[1:-1]]
        if len(cells) == 2:
            found.append((line_no, cells[0], cells[1]))
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["seed"])
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    existing = {src: outcome for _, src, outcome in rows(args.out.read_text(encoding="utf-8"))} if args.out.exists() else {}
    args.out.write_text(render(existing), encoding="utf-8", newline="\n")
    print(f"OK {args.out}: {len(rows(args.out.read_text(encoding='utf-8')))} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

In `check.py`, add `import ledger  # noqa: E402` and:

```python
def new_layout_files() -> list[Path]:
    paths = [g.use_cases_file(), g.navigation_file()]
    paths += sorted(g.functional_spec_dir().glob("*.md")) if g.functional_spec_dir().is_dir() else []
    screens = g.DOCS / "screens"
    paths += sorted(screens.rglob("*.md")) if screens.is_dir() else []
    return [path for path in paths if path.exists()]


def check_ledger(path: Path, defined: set[str], report: Report) -> None:
    """Spec §7.1 conditions 1–3: every row has a valid outcome; a moved row's
    destination exists; nothing is still OPEN QUESTION in the new docs."""
    if not path.exists():
        report.error(path, "ledger file not found")
        return
    found = ledger.rows(path.read_text(encoding="utf-8"))
    if not found:
        report.error(path, "ledger has no rows")
    for line_no, _, outcome in found:
        at = f"{show(path)}:{line_no}"
        match = ledger.OUTCOME.match(outcome)
        if match is None:
            report.error(at, f"outcome `{outcome or '(empty)'}` is not `moved → …`, `superseded → …` or `dropped — …, approved <date>`")
        elif match["dest"] and not destination_exists(match["dest"].split("#", 1)[0]):
            report.error(at, f"moved to a path that does not exist: `{match['dest']}`")
        elif match["by"]:
            cited = specdocs.ANY_ID.match(match["by"])
            if cited and cited[1] not in defined:
                report.error(at, f"superseded by an undefined id: `{cited[1]}`")
    for new in new_layout_files():
        for line_no, line in g.iter_unfenced(new.read_text(encoding="utf-8")):
            if g.OPEN_QUESTION in g.INLINE_CODE.sub("", line):
                report.error(f"{show(new)}:{line_no}", "an OPEN QUESTION is still open in the new docs (spec §7.1)")
```

Change `run`'s signature to `def run(plan: Path | None, base_keys=base_state_keys, ledger_path: Path | None = None) -> Report:`
and, after the `if plan is not None:` block:

```python
    if ledger_path is not None:
        check_ledger(ledger_path, defined_ids(docs), report)
```

In `main`, add `parser.add_argument("--ledger", type=Path, help="migration ledger to verify (spec 2026-10-04 §7.1)")`
and call `run(args.plan, ledger_path=args.ledger)`. Docstring usage line becomes
`python tools/docs/check.py [--plan <mapping.md>] [--ledger <ledger.md>]`, and under ERROR add:

```
- with --ledger: a row without a valid outcome, a moved row whose destination
  does not exist, or an OPEN QUESTION left in the new-layout documents
```

- [ ] **Step 4: Run the tests and the repository check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py' && python3 tools/docs/check.py | tail -1`
Expected: `OK`; `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 5: Commit**

```bash
git add tools/docs/ledger.py tools/docs/check.py tools/docs/test_ui_docs_layout.py
git commit -m "feat(docs-tools): seed and verify the migration ledger"
```

### Task 11: Conventions, skeleton documents, the seeded ledger

**Files:**
- Modify: `docs/README.md`
- Create: `docs/USE_CASES.md`, `docs/functional-spec/README.md`, `docs/screens/SCREEN_CATALOG.md`,
  `docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md`

- [ ] **Step 1: Rewrite the map and the reading order in `docs/README.md`**

Replace the code block under `## Bản đồ` with:

```
PRODUCT.md                       # root repo — định nghĩa sản phẩm, bản duy nhất
DESIGN.md                        # root repo — hệ thống hình ảnh (ADR-021)
docs/
├── README.md                    # file này: bản đồ và convention
├── USE_CASES.md                 # mọi UC, nhóm theo feature
├── NAVIGATION.md                # điều hướng cấp app và router
├── functional-spec/
│   ├── README.md                # feature → file
│   └── <feature>.md             # FN-<DOMAIN>-NNN
├── screens/
│   ├── SCREEN_CATALOG.md        # mọi màn + invariant chung INV-UI
│   └── spec/                    # SCR-<DOMAIN>-NNN-<slug>.md, một file một màn
├── glossary.md
├── wbs_BE.md, wbs_FE.md, wbs_API.md, wbs_supabase.md
├── shared/
│   ├── rules/                   # BR-CORE-NNN-<slug>.md
│   ├── decisions/               # ADR-NNN-<slug>.md
│   ├── data/                    # schema.md
│   ├── ui/                      # CŨ — screen-handoff/, navigation.md; bỏ sau khi migration được kiểm chứng
│   └── testing/
├── features/<feature>/
│   ├── README.md                # phạm vi, thuật ngữ, depends_on
│   ├── rules/                   # BR-<DOMAIN>-NNN-<slug>.md
│   ├── usecases/                # CŨ — UC chưa chuyển vào USE_CASES.md
│   ├── ui.md                    # CŨ — bỏ sau khi migration được kiểm chứng
│   ├── data.md                  # TÙY CHỌN
│   └── it-scenarios.md          # TÙY CHỌN
├── superpowers/                 # spec + plan (giữ ID lịch sử)
└── _generated/                  # KHÔNG SỬA TAY — index, traceability, screens, navigation-graph, open questions
```

Replace the paragraph that starts `` `shared/ui/screen-handoff/` ghi từng màn`` (3 lines) with:

```
Mỗi màn có một spec trong `screens/spec/` và một hàng trong `screens/SCREEN_CATALOG.md`.
Hệ thống hình ảnh ở [`DESIGN.md`](../DESIGN.md); thứ tự ưu tiên theo
[ADR-021](shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md). Định nghĩa sản phẩm
thuộc `/PRODUCT.md`; không chép phạm vi sản phẩm vào cây `docs/` (mục "Sản phẩm" ở trên chuyển
sang `/PRODUCT.md` và bị xoá khi migration được kiểm chứng).
```

Replace the numbered list under `## Thứ tự đọc` with:

```
1. `CLAUDE.md` ở root repo — ràng buộc áp dụng ở mọi phase.
2. File này.
3. `/PRODUCT.md` khi cần phạm vi sản phẩm.
4. Việc trên một feature: `features/<feature>/README.md`, `functional-spec/<feature>.md`, các UC
   của nó trong `USE_CASES.md`, rồi đúng các BR mà FN trỏ tới. Không đọc hết `docs/`.
5. Việc trên một màn: `screens/SCREEN_CATALOG.md`, spec của màn, các FN nó gọi, `/DESIGN.md`.
6. `shared/decisions/` khi cần biết **vì sao**.
7. [`_generated/open-questions.md`](_generated/open-questions.md) trước khi coi một hành vi là
   đã chốt.
```

- [ ] **Step 2: Rewrite "X viết ở đâu"**

Replace the table under `## X viết ở đâu` and the line after it
(`Nguyên tắc: nghiệp vụ → rule; …`) with:

```
| Nội dung | Vị trí |
|---|---|
| Định nghĩa sản phẩm, phạm vi MVP | `/PRODUCT.md` |
| Mục tiêu và luồng của người dùng | `USE_CASES.md` (UC) |
| Hệ thống làm gì: precondition, input, kết quả, lỗi, BR áp dụng | `functional-spec/<feature>.md` (FN) |
| Ràng buộc nghiệp vụ, một feature sở hữu | `features/<f>/rules/` |
| Ràng buộc nghiệp vụ không feature nào sở hữu | `shared/rules/` (BR-CORE) |
| Một màn: vùng, state, control → FN, điều hướng cục bộ, copy, ruling | `screens/spec/` |
| Danh mục màn; invariant hành vi mọi màn phải giữ | `screens/SCREEN_CATALOG.md` |
| Điều hướng cấp app: shell, tab, deep link, back, guard, boot | `NAVIGATION.md` |
| Hệ thống hình ảnh | `/DESIGN.md` |
| Bảng/field feature dùng, dữ liệu sync, conflict rule riêng | `features/<f>/data.md` |
| Endpoint feature dùng, lỗi đặc thù | `features/<f>/api.md` |
| Request/response, error code | `shared/api/` |
| Cơ chế chung: cache, sync, token | `shared/data/` |
| Kịch bản IT | `features/<f>/it-scenarios.md`, `shared/testing/` |
| Quyết định kỹ thuật có lý do và phương án bị loại | `shared/decisions/` (ADR) |
| Định nghĩa thuật ngữ | `glossary.md` |

Nguyên tắc: mục tiêu → UC; hành vi hệ thống → FN; ràng buộc → BR; giao diện → screen spec.
Không chép nội dung sang chỗ khác — chỉ reference ID hoặc link.
```

- [ ] **Step 3: Add the new IDs and formats under `## Convention`**

In the table under `### ID`, add after the `BR-CORE-NNN` row:

```
| Chức năng | `FN-<DOMAIN>-NNN` | `FN-DECK-001` |
| Màn hình | `SCR-<DOMAIN>-NNN` | `SCR-DECK-001` |
| Invariant UI chung | `INV-UI-NNN` | `INV-UI-001` |
| State của một màn | `snake_case`, duy nhất trong màn | `root_loaded` |
```

and add to the bullet `**ID là vĩnh viễn.**` the sentence: "Áp dụng cho cả FN, SCR, INV-UI
và state key của màn; state bị bỏ giữ heading với `Status: removed`."

After the `### Frontmatter` subsection, add a subsection (content verbatim):

~~~markdown
### UC, FN và screen spec

Mỗi UC là một section của `USE_CASES.md`, dưới nhóm `## <Feature>`. Dòng ngay dưới heading là
dòng meta, các phần cách nhau bởi ` · `:

```markdown
### UC-DECK-001 — <tiêu đề>
Status: ready · Code: [<path>, …] · Invokes: [FN-DECK-001, …]

#### Mục tiêu / Actor / Precondition
#### Main flow                — bước của hệ thống trỏ FN-ID: "Hệ thống thực hiện FN-DECK-001."
#### Alternative / Error flow
#### Acceptance criteria
```

Mỗi FN là một section của `functional-spec/<feature>.md`; tên file là tên thư mục feature:

```markdown
## FN-DECK-001 — <tiêu đề>
Status: active · Code: [lib/features/deck/domain/usecases/<x>_use_case.dart]

### Precondition
### Input
### Kết quả
### Lỗi                — failure type có thật trong lớp domain; không đặt mã lỗi mới
### Business rules     — BR-…, một dòng một BR (quan hệ gốc FN → BR)
```

Mỗi màn là một file `screens/spec/SCR-<DOMAIN>-NNN-<slug>.md`, viết tiếng Anh:

```markdown
---
id: SCR-DECK-001
name: <Screen name>
domain: <feature folder>
status: draft | ready | built
route: [/path, …]
---
# <Screen name>
## Purpose
## Related Use Cases          — UC-ID (quan hệ gốc màn → UC)
## Layout                     — vùng theo vai trò, trên → dưới; không tên class widget
## States                     — mỗi state: ### `<state_key>` · <Title>, rồi "Golden: light, dark" hoặc "Golden: none — <lý do>"
## Controls                   — mỗi control: Type, Purpose, Enabled when, "Invokes: FN-…",
                                #### On success ("Navigate to: SCR-…" hoặc phản hồi UI),
                                #### On failure (<failure type> → cách hiển thị)
## Responsive Behavior        — "Follows the shared floor" khi không có gì riêng
## Accessibility              — như trên
## UI Invariants              — | Invariant | Enforced by |, chỉ invariant riêng của màn
## Copy
## Rulings
```

Golden của state tên `<scr_id>__<state_key>__<variant>.png`, ví dụ
`scr_deck_001__root_loaded__light.png`, nằm dưới `test/**/goldens/`.

Quan hệ gốc chỉ khai báo một chiều; chiều ngược do `generate.py` sinh vào `_generated/`, và một
section viết tay kiểu `Used by`, `Invoked by`, `Related Screens`, `Related BR`, `Entry points`
là ERROR.

| Quan hệ gốc | Viết ở |
|---|---|
| UC → FN | dòng `Invokes:` của UC |
| FN → BR | `### Business rules` của FN |
| Màn → FN | dòng `Invokes:` ở control |
| Màn → UC | `## Related Use Cases` |
| Màn → màn | dòng `Navigate to:` ở control |
| App → màn | `NAVIGATION.md` (deep link, guard, tab, back, boot) |

Loại ID mỗi tài liệu được trích (dòng `OPEN QUESTION` được miễn; trong các tài liệu này, ID
trong `inline code` vẫn tính):

| Tài liệu | Được trích |
|---|---|
| `USE_CASES.md` | FN |
| `functional-spec/` | BR |
| `screens/spec/` | FN, UC, SCR, INV-UI |
| `screens/SCREEN_CATALOG.md` | SCR, INV-UI |
| `NAVIGATION.md` | SCR, UC |

UC và màn không bao giờ trích BR; BR tới UC hay màn chỉ qua FN.
~~~

In the `Use case` frontmatter block's intro line (`Use case — \`features/<f>/usecases/\`:`),
append: "(định dạng cũ, chỉ còn cho UC chưa chuyển vào `USE_CASES.md`)".

Under `## Kiểm chứng`, add after the two existing commands:

```sh
python tools/docs/ledger.py seed docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md
python tools/docs/check.py --ledger docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md
python -m unittest discover -s tools/docs -p 'test_*.py'
```

- [ ] **Step 4: Create the skeleton documents**

`docs/USE_CASES.md`:

```markdown
# Use cases

Mọi use case của app, nhóm theo feature. Định dạng section và dòng meta:
[docs/README.md](README.md), mục "UC, FN và screen spec".
```

`docs/functional-spec/README.md`:

```markdown
# Functional specification

Một file cho mỗi feature, tên file là tên thư mục trong `features/`; mỗi chức năng là một
section. Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen spec".

| Feature | File |
|---|---|
```

`docs/screens/SCREEN_CATALOG.md`:

```markdown
# Screen catalog

Every screen of the app; one spec per screen in `spec/`. The visual system is in
[`DESIGN.md`](../../DESIGN.md); the authority order is
[ADR-021](../shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md).

## Screens

| ID | Screen | Domain | Route | Status | Spec |
|---|---|---|---|---|---|

## Invariants for every screen

Behaviour every screen holds. Visual values (touch targets, contrast, spacing, type) are in
`DESIGN.md` and are not restated here; a rule of one screen lives in that screen's spec.

| ID | Invariant | Enforced by |
|---|---|---|
| INV-UI-001 | A control whose feature is not built yet is hidden, never shown disabled. | — |
| INV-UI-002 | A data display with no data is hidden, never drawn empty: an empty mastery bar would claim 0 %. | — |
| INV-UI-003 | Deleting moves the item to the Trash and offers Undo after one item, for 8 seconds, and under TalkBack until acted on. | — |
| INV-UI-004 | A failed save keeps everything the user entered. | — |
| INV-UI-005 | The on-screen keyboard never covers the focused field. | — |
| INV-UI-006 | A floating action button never hides the last item of a list. | — |
| INV-UI-007 | A read-only control looks and announces differently from a disabled one. | — |
```

(INV-UI-001…003 come from "Rules shared by every screen" in today's `00-index.md`; 004…007
from spec §4.5; no text-scale invariant, plan PT12. For each, search `test/` for a test that
already enforces it, e.g. `grep -rln "Undo" test/features/trash`, and put that file in
`Enforced by` only if its assertions actually check the invariant; otherwise keep `—`.)

- [ ] **Step 5: Seed the ledger**

Run: `python3 tools/docs/ledger.py seed docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md`
Expected: `OK …: <N> rows` with N in the thousands. Open it and check that it has one section
per screen record, per UC file, per `ui.md`, per feature README, `shared/ui/navigation.md`,
`README.md`, and a `Goldens` section with 526 rows.

- [ ] **Step 6: Generate, check, test, gate**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1 && python3 -m unittest discover -s tools/docs -p 'test_*.py' && bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: `PASS — 0 error(s), N warning(s)` (45 + one per INV-UI enforced by nothing); `OK`;
the gate passes.

- [ ] **Step 7: Commit**

```bash
git add docs/README.md docs/USE_CASES.md docs/functional-spec docs/screens docs/_generated docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md
git commit -m "docs: conventions and skeletons of the new UI docs layout; seed the migration ledger"
```

---

## Procedures used by the content tasks

### Procedure P1 — migrate one feature to FN and UC sections

Inputs (named in each task): the feature folder `<f>` and its DOMAIN; its domain use case
classes `lib/features/<d>/domain/usecases/*.dart` (`<d>` = `<f>` with `-` → `_`); its failure
types `lib/features/<d>/domain/failures/*.dart`; its UC files
`docs/features/<f>/usecases/*.md`; the BRs those UCs cite (any feature); its `ui.md` if any.

1. **List the candidate FNs.** One row per use case class: class → FN title, or "not an FN" with
   the reason (internal plumbing: a PM or QA would not test it on its own, spec R6). Add one
   row per behaviour a UC flow performs that no use case class covers; its `Code` points where
   it lives today (a repository or controller path), spec §5. Write this table in the task's
   ledger section of the execution ledger (bottom of the ledger file, `## Task <n> notes`).
2. **Number them** `FN-<DOMAIN>-001…` in the order they first appear in the UC flows, then the
   rest in class-name order. Numbers are final once committed.
3. **Write `docs/functional-spec/<f>.md`**: `# <Feature> — functional specification`, then one
   section per FN exactly in the README format. Fill it from the code and the UCs:
   - `Precondition`, `Input`, `Kết quả`: what the use case requires, takes and guarantees, in
     user-level terms; transactional guarantees stay ("trong một transaction"), table names and
     Drift calls do not.
   - `Lỗi`: each failure variant the use case can return, by its name in `*_failure.dart`, with
     one line on when. None: `Không áp dụng — <why>`.
   - An FN may cite another FN only as a contract prerequisite or another domain's capability
     (spec R21), never as an implementation call graph.
   - `Business rules`: every BR the behaviour enforces: the `rules:` of the UCs whose steps it
     serves, plus each BR those UCs cite in prose for that step. One BR per line, plain text.
   - Add the row `| <Feature> | [<f>.md](<f>.md) |` to `functional-spec/README.md`.
4. **Move each UC into `docs/USE_CASES.md`** under `## <Feature>`: heading
   `### <UC id> — <frontmatter title>`; meta line with the same `Status` and `Code`, and
   `Invokes:` listing its FNs. Copy the four sub-sections, demoted to `####`, at the level of user
   intent (spec R20): keep the goal, the semantic flow and the FN ids; take out every control,
   layout, dialog, FAB, button, inline-vs-snackbar and state-presentation detail. That detail goes
   to the screen spec of its screen; when that spec is not written yet, its ledger row is
   `pending → <SCR id> (<what>)`, with the SCR id of the Phase D table. Otherwise copy verbatim
   except:
   - a system step that performs a behaviour becomes "Hệ thống thực hiện FN-…." (keep the
     user-facing outcome sentence if it says more);
   - every BR citation is removed from the UC (R13); its rule must be on the FN that step
     invokes (add it there if missing). A BR that no FN can carry becomes
     `> ⚠️ OPEN QUESTION: <BR id> chi phối luồng nhưng không thuộc FN nào — <why>` (plan PT2);
   - a citation of another UC becomes the FN it means, or is dropped when the sentence still
     reads;
   - `## UI` is not copied (the screen specs take it, Phase C); `## Local` and `## API`
     content goes into the FN sections it describes (implementation-only lines are dropped and
     ledgered as such).
   The legacy file stays where it is (R18); the tooling now ignores it (PT6).
5. **Fill the ledger rows** of every source of this feature except the screen records:
   each UC file row, and the `ui.md` rows that this feature's FNs or UCs supersede. Outcomes:
   `moved → \`USE_CASES.md\``, `moved → \`functional-spec/<f>.md\``, `superseded → FN-…`, or
   `dropped — <reason>, approved <date>` with the date left as `approved PENDING` for the
   owner's batch approval in Task 43 (the check fails on `PENDING` on purpose until then).
6. **Verify**: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -3 && python3 -m unittest discover -s tools/docs -p 'test_*.py'`.
   Expected: 0 errors. New warnings allowed: "now lives in USE_CASES.md", "invoked by no UC and
   no screen" (screens come in Phase C). Each "active BR is cited by no FN" warning for this
   feature's BRs must be explained in the task notes (a rule the screens enforce, a BR of
   another feature, or an `OPEN QUESTION`).
7. **Spot check**: for three FNs, `ls` each `Code` path and `grep` each `Lỗi` name in the
   failure file.
8. **Commit**: `git commit -m "docs(<f>): functional spec and use cases in the new layout"`.

### Procedure P2 — write one screen spec

Inputs: the screen record `docs/shared/ui/screen-handoff/<NN>-<slug>.md`; the goldens it names;
its presentation code under `lib/features/<d>/presentation/` (and `lib/app/router/` for its
routes); the FNs of Phase B; the feature's `ui.md`; `DESIGN.md`.

1. Create `docs/screens/spec/<SCR id>-<slug>.md` with the frontmatter: `id`, `name` (the
   record's title without its number), `domain` (feature folder), `status: ready`, `route`
   (the path constants in `lib/app/router/*.dart` that open this screen; a sheet or dialog
   without a route of its own belongs to its host screen).
2. `## Purpose`: the record's opening paragraph in English, IDs only of the allowed kinds.
3. `## Related Use Cases`: the UCs the record or the feature README names for this screen.
4. `## Layout`: each layout table row → one bullet `**<Region by role>** — <design>`. Replace
   widget class names (`MxCard`, `MxIconTile`…) by the role ("hero card", "icon tile"). Keep
   every measure the record gives that `DESIGN.md` does not define; name `DESIGN.md` tokens
   where it does.
5. `## States`: each row of the record's States table → `### \`<key>\` · <Title>`. Key =
   snake_case of the record's state name (`rootLoaded` → `root_loaded`). Under it: the "App"
   cell as prose, then `Golden: light, dark` when the record names light and dark goldens, or
   `Golden: none — no golden in V8 (record <NN>)` when it says "no golden".
6. `## Controls`: every control in the layout, action sheet, sort/filter sheet and dialogs.
   Read the screen's controller to find which use case each control calls; write
   `- Invokes: <FN id>` for the FN whose `Code` holds that use case. `Enabled when` only for UI
   conditions. `#### On success`: `- Navigate to: <SCR id>` for a push to another screen of the
   app (a screen without a spec yet uses its Phase D id, listed `pending` in the catalog — spec
   R19), or the UI response. `#### On failure`: each failure type the controller maps → its
   presentation (read the error mapping in the controller or its state class).
7. `## Responsive Behavior`, `## Accessibility`: what the record or code does specially;
   otherwise "Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md)".
8. `## UI Invariants`: rulings of this screen that are checkable invariants, as
   `| Invariant | Enforced by |` (`—` unless a test enforces it). A global one is cited by its
   `INV-UI` id.
9. `## Copy`: the record's copy table, verbatim.
10. `## Rulings`: the record's rulings, verbatim and dated, BR citations removed (R13: name the
    FN instead, or drop the parenthetical); `## Pending` items appended as `Pending — <item>`.
11. Replace the screen's `pending` row in `docs/screens/SCREEN_CATALOG.md` by its real row (same
    name, domain, routes in backticks, status, and the spec path in backticks).
11a. Move into the spec every UC presentation detail ledgered `pending → <this SCR id>`, then set
    those ledger rows to `moved → \`screens/spec/<file>\``.
12. Fill the ledger: every row of the record (`moved → \`screens/spec/<file>\``, or
    `superseded → <SCR id>` for rows the spec restates in another form), each of its goldens
    (`superseded → <SCR id> \`<state_key>\` <variant>`), and the `## UI` rows of the UC files
    that describe this screen.
13. Verify as in P1 step 6 (0 errors; the warning "invoked by no UC and no screen" must shrink).
14. Commit: `git commit -m "docs(screens): <SCR ids> specs from the current app"`.

---

## Phase B — Pilot domain (end of spec §7 step 1)

### Task 12: Pilot — deck FNs and UCs

Follow **P1** with: `<f>` = `deck`, DOMAIN `DECK`; 12 use case classes
(`change_deck_scheduler`, `create_root_deck`, `create_sub_deck`, `delete_deck`,
`get_deck_deletion_summary`, `move_deck`, `rename_deck`, `reorder_deck`, `undo_deck_deletion`,
`watch_deck_level`, `watch_deck_move_targets`, `watch_deck`); failures
`lib/features/deck/domain/failures/deck_failure.dart`; UC-DECK-001…006; `features/deck/ui.md`.

Starting point for step 1 (confirm against the UC flows; renumber by first appearance):

| Use case class | Proposed FN |
|---|---|
| `create_root_deck` | Tạo root deck |
| `watch_deck_level` | Xem một cấp của thư viện kèm tiến độ |
| `reorder_deck` | Sắp xếp lại deck cùng cấp |
| `create_sub_deck` | Tạo deck con và xác lập content type |
| `rename_deck` | Đổi tên deck |
| `get_deck_deletion_summary` | Xem số deck con và card sẽ vào Trash cùng deck |
| `delete_deck` | Chuyển deck và cây con vào Trash |
| `undo_deck_deletion` | Hoàn tác xoá deck |
| `move_deck` | Di chuyển deck trong cây |
| `watch_deck_move_targets` | Xem các đích di chuyển hợp lệ |
| `change_deck_scheduler` | Đổi scheduler của root deck |
| `watch_deck` | Xem một deck |

Files: `docs/functional-spec/deck.md`, `docs/functional-spec/README.md`, `docs/USE_CASES.md`,
the ledger, `docs/_generated/`.

### Task 13: Pilot — SCR-DECK-001 and owner checkpoint

- [ ] Follow **P2** for record `01-deck-list.md` → `docs/screens/spec/SCR-DECK-001-deck-list.md`,
  domain `deck`, routes from the `decks` constant and the open-deck route in
  `lib/app/router/app_routes.dart`.
- [ ] Run the gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: pass.
- [ ] **Owner checkpoint** (`AskUserQuestion`): show the owner `functional-spec/deck.md`,
  the deck part of `USE_CASES.md`, `SCR-DECK-001-deck-list.md`, the deck ledger rows, and the
  `active BR is cited by no FN` warnings for `BR-DECK-*` with their explanations. Options:
  approve the shape and continue; request changes (apply them to the deck documents and
  procedures P1/P2 here before any other domain). No other domain starts before approval.

## Phase C — Remaining features (spec §7 step 2)

Each task follows **P1** with the inputs listed; the files are
`docs/functional-spec/<f>.md`, `docs/functional-spec/README.md`, `docs/USE_CASES.md`, the
ledger and `docs/_generated/`. One commit per task.

### Task 14: card
`<f>` = `card`, DOMAIN `CARD`; 14 use case classes in `lib/features/card/domain/usecases/`;
UC-CARD-001, UC-CARD-002; `features/card/ui.md`.

### Task 15: srs
`<f>` = `srs`, DOMAIN `SRS`; 2 use case classes; UC-SRS-001; `features/srs/ui.md`. The
scheduler change is FN-DECK (Task 12); SRS FNs cite the BR-SRS rules it enforces only if they
own the behaviour.

### Task 16: study and study-mode
`<f>` = `study`, DOMAIN `STUDY`; 13 use case classes; UC-STUDY-001…003; `features/study/ui.md`.
`study-mode` has no use case class and no UC: its 19 BR-MODE rules are cited by the study FNs
that enforce them. Every active BR-MODE either appears in a study FN or gets an `OPEN QUESTION`
in `functional-spec/study.md`; record which in the task notes. No `functional-spec/study-mode.md`
is created.

### Task 17: settings
`<f>` = `settings`, DOMAIN `SETTINGS`; 8 use case classes; UC-SETTINGS-001; `features/settings/ui.md`.

### Task 18: reminders
`<f>` = `reminders`, DOMAIN `REMINDER`; 7 use case classes (`deliver_reminder` and
`reconcile_reminder` are likely "not an FN": confirm); UC-REMINDER-001; `features/reminders/ui.md`.

### Task 19: progress
`<f>` = `progress`, DOMAIN `PROGRESS`; 2 use case classes; UC-PROGRESS-001, UC-PROGRESS-002;
`features/progress/ui.md`.

### Task 20: search
`<f>` = `search`, DOMAIN `SEARCH`; 1 use case class; UC-SEARCH-001.

### Task 21: tags
`<f>` = `tags`, DOMAIN `TAG`; 5 use case classes; UC-TAG-001; `features/tags/ui.md`.

### Task 22: trash
`<f>` = `trash`, DOMAIN `TRASH`; 7 use case classes; UC-TRASH-001. Deck deletion and its undo
are FN-DECK (Task 12); trash FNs cover the Trash screen's own actions.

### Task 23: transfer
`<f>` = `transfer`, DOMAIN `TRANSFER`; 6 use case classes; UC-TRANSFER-001, UC-TRANSFER-002.

### Task 24: starter-decks
`<f>` = `starter-decks`, DOMAIN `STARTER`; 2 use case classes; UC-STARTER-001;
`features/starter-decks/ui.md`.

### Task 25: account (and sync)
`<f>` = `account`, DOMAIN `ACCOUNT`; 5 use case classes; no UC and no BR (the feature README
says behaviour follows the account UI and auth specs in `docs/superpowers/specs/`). Also the
sync behaviours that screen 27 triggers or shows (code in `lib/core/sync/`), as
`FN-ACCOUNT-…` (plan PT1). `### Business rules` of each: `Không áp dụng — feature account chưa
có BR (<spec file>)`.

### Task 26: monitoring
`<f>` = `monitoring`, DOMAIN `MONITORING`; 5 use case classes; no UC, no BR (ADR-018 §6–§8 and
its spec). After this task run the gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.

### Task 27: PRODUCT.md (may run in parallel with Phase C)

**Files:** Modify `PRODUCT.md`; the ledger.

- [ ] Keep every heading and the `<!-- impeccable:product-schema 1 -->` marker
  (`.claude/skills/impeccable/reference/init.md`, Step 4: "Preserve useful legacy headings", so
  an added section is accepted).
- [ ] Add `## MVP Scope` after `## Capabilities and Constraints`, with `### Must`, `### Should`,
  `### Nice to have`, `### Out of scope`: the four tables of the "Sản phẩm" section of
  `docs/README.md`, translated to English, every ID and "done when" condition kept exactly.
- [ ] Where `PRODUCT.md` points at `docs/README.md` ("Target users", "Core value", the MVP
  checklist), point at its own sections instead; add the Problem paragraph to
  `## Product Purpose` if a sentence is missing there. Links to ADRs become
  `docs/shared/decisions/<file>` relative to the root.
- [ ] Ledger: each row of the `README.md` section → `moved → \`../PRODUCT.md\``.
- [ ] Verify (P1 step 6) and commit: `docs(product): MVP scope moves into PRODUCT.md`.
  `docs/README.md` keeps its "Sản phẩm" section until Task 44 (R18).

## Phase D — Screen specs (spec §7 step 3)

Screen IDs and domains (plan PT1). Each task follows **P2** for its records, numbering within
the domain in record order. Files: the new specs, `SCREEN_CATALOG.md`, the ledger,
`docs/_generated/`. One commit per task.

| Record | SCR id | Spec file | Domain |
|---|---|---|---|
| 01 | SCR-DECK-001 | `SCR-DECK-001-deck-list.md` | deck (Task 13) |
| 02 | SCR-SRS-001 | `SCR-SRS-001-review-algorithm.md` | srs |
| 03 | SCR-STARTER-001 | `SCR-STARTER-001-starter-decks.md` | starter-decks |
| 04 | SCR-SEARCH-001 | `SCR-SEARCH-001-library-search.md` | search |
| 05 | SCR-TAG-001 | `SCR-TAG-001-tags.md` | tags |
| 06 | SCR-TRASH-001 | `SCR-TRASH-001-trash.md` | trash |
| 07 | SCR-CARD-001 | `SCR-CARD-001-card-list.md` | card |
| 08 | SCR-CARD-002 | `SCR-CARD-002-card-create.md` | card |
| 09 | SCR-CARD-003 | `SCR-CARD-003-card-edit.md` | card |
| 10 | SCR-CARD-004 | `SCR-CARD-004-card-detail.md` | card |
| 11 | SCR-TRANSFER-001 | `SCR-TRANSFER-001-card-import.md` | transfer |
| 12 | SCR-TRANSFER-002 | `SCR-TRANSFER-002-card-export.md` | transfer |
| 13 | SCR-STUDY-001 | `SCR-STUDY-001-study-home.md` | study |
| 14 | SCR-STUDY-002 | `SCR-STUDY-002-study-entry.md` | study |
| 16 | SCR-STUDY-003 | `SCR-STUDY-003-study-browse.md` | study |
| 16a | SCR-STUDY-004 | `SCR-STUDY-004-study-self-assess.md` | study |
| 17 | SCR-STUDY-005 | `SCR-STUDY-005-study-match.md` | study |
| 18 | SCR-STUDY-006 | `SCR-STUDY-006-study-guess.md` | study |
| 19 | SCR-STUDY-007 | `SCR-STUDY-007-study-recall.md` | study |
| 20 | SCR-STUDY-008 | `SCR-STUDY-008-study-fill.md` | study |
| 21 | SCR-STUDY-009 | `SCR-STUDY-009-session-summary.md` | study |
| 15 | SCR-SETTINGS-001 | `SCR-SETTINGS-001-study-options.md` | settings |
| 23 | SCR-SETTINGS-002 | `SCR-SETTINGS-002-settings.md` | settings |
| 25 | SCR-SETTINGS-003 | `SCR-SETTINGS-003-theme.md` | settings |
| 26 | SCR-SETTINGS-004 | `SCR-SETTINGS-004-language.md` | settings |
| 22 | SCR-PROGRESS-001 | `SCR-PROGRESS-001-progress.md` | progress |
| 24 | SCR-REMINDER-001 | `SCR-REMINDER-001-daily-reminder.md` | reminders |
| 27 | SCR-ACCOUNT-001 | `SCR-ACCOUNT-001-sync.md` | account |
| 29 | SCR-ACCOUNT-002 | `SCR-ACCOUNT-002-welcome.md` | account |
| 30 | SCR-ACCOUNT-003 | `SCR-ACCOUNT-003-sign-in.md` | account |
| 31 | SCR-ACCOUNT-004 | `SCR-ACCOUNT-004-code.md` | account |
| 32 | SCR-ACCOUNT-005 | `SCR-ACCOUNT-005-account.md` | account |
| 33 | SCR-ACCOUNT-006 | `SCR-ACCOUNT-006-users.md` | account |
| 28 | SCR-MONITORING-001 | `SCR-MONITORING-001-monitoring.md` | monitoring |

### Task 28: SCR-SRS-001 (record 02)
### Task 29: SCR-STARTER-001 (record 03)
### Task 30: SCR-SEARCH-001 (record 04)
### Task 31: SCR-TAG-001 (record 05)
### Task 32: SCR-TRASH-001 (record 06)
### Task 33: SCR-CARD-001…004 (records 07–10)
### Task 34: SCR-TRANSFER-001, 002 (records 11–12)
### Task 35: SCR-STUDY-001, 002, 009 (records 13, 14, 21)
### Task 36: SCR-STUDY-003…008 (records 16, 16a, 17–20)
Record 16a is a shape brief with no state table: write its states from the code
(`self_assess` session) and mark each `Golden: none — shape brief, no golden in V8 (record 16a)`.
### Task 37: SCR-SETTINGS-001…004 (records 15, 23, 25, 26)
### Task 38: SCR-PROGRESS-001 (record 22)
### Task 39: SCR-REMINDER-001 (record 24)
### Task 40: SCR-ACCOUNT-001…006 (records 27, 29–33)
### Task 41: SCR-MONITORING-001 (record 28)

After Task 41: every catalog row exists, and the "Rules shared by every screen" rows of
`00-index.md` are ledgered as `superseded → INV-UI-00n` (the copy rule:
`superseded → R11`). Run the gate.

### Task 42: NAVIGATION.md

**Files:** Create `docs/NAVIGATION.md`; the ledger; `docs/_generated/`.

- [ ] Write `docs/NAVIGATION.md` (Vietnamese, like today's `navigation.md`; IDs SCR and UC
  only) with: `## Root navigation` · `## Shell and tabs` · `## Back behaviour` (system back,
  app-bar back, modal dismiss, unsaved changes) · `## Deep links` · `## Guards` (account
  redirect from `lib/app/router/account_redirect.dart`, admin-only routes, recovery) ·
  `## Boot and system routing` · `## Master flows` (the master-flow diagram of today's
  `navigation.md`, nodes renamed to SCR ids). Sources: `docs/shared/ui/navigation.md`, the
  cross-screen parts of every `features/*/ui.md`, `lib/app/router/`.
- [ ] An edge that starts at a control is **not** written here: check it already exists as a
  `Navigate to:` in that screen's spec (add it there if Phase D missed it).
- [ ] Ledger: every row of `shared/ui/navigation.md` and every remaining `ui.md` row
  (`moved → \`NAVIGATION.md\``, `superseded → SCR-…`, or dropped with `approved PENDING`).
- [ ] Verify: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -3`; open
  `docs/_generated/navigation-graph.md` and compare its edges with today's master flow.
- [ ] Gate, commit: `docs(navigation): app-level navigation in NAVIGATION.md`.

## Phase E — Verification and retirement (spec §7 steps 4–5)

### Task 43: Migration verification and owner sign-off

- [ ] Run `python3 tools/docs/check.py --ledger docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md`.
  Expected before approval: errors only on `approved PENDING` rows. Any other error is fixed
  first (missing outcome, missing destination, open question).
- [ ] Re-seed to prove no source item was added since: `python3 tools/docs/ledger.py seed …`
  then `git diff --stat` on the ledger shows no new row.
- [ ] Count outcomes: `grep -c 'moved →'`, `grep -c 'superseded →'`, `grep -c 'dropped —'` on
  the ledger.
- [ ] Check condition 5 per screen: in `docs/_generated/screens.md` every screen lists its
  states, and every `Goldens` row of the ledger is `superseded → SCR-… \`<key>\` <variant>`
  with that key present in the spec.
- [ ] **Owner sign-off** (`AskUserQuestion`), with the counts, every `dropped` row (source,
  excerpt, reason), every resolved `OPEN QUESTION` and the remaining warnings. Options: approve
  all drops (replace `PENDING` with today's date); approve with exceptions (restore the
  excepted items to their new homes, then ask again); stop.
- [ ] After approval: replace `approved PENDING` with `approved <date>`; run
  `check.py --ledger …` → `PASS`; record the sign-off (date, counts) at the top of the ledger;
  commit `docs(ledger): migration verified, owner sign-off <date>`.

### Task 44: Retire the old homes and the legacy tooling

**Files:** delete spec §6.1; modify `tools/docs/generate.py`, `check.py`, `ledger.py`, the tests,
the 15 feature READMEs, `docs/README.md`, `CLAUDE.md`, and the §6.4 files.

- [ ] Delete: `docs/shared/ui/screen-handoff/`, `docs/shared/ui/navigation.md`,
  `docs/features/*/usecases/`, `docs/features/*/ui.md`; the "Sản phẩm" section of
  `docs/README.md` (replace it with one line: "Định nghĩa sản phẩm: [`/PRODUCT.md`](../PRODUCT.md).").
- [ ] Remove `## Màn hình → Use case` from every `docs/features/*/README.md` (plan PT7) and
  `"Màn hình → Use case"` from `REQUIRED_SECTIONS["FEATURE"]`.
- [ ] Remove the legacy UC support: in `generate.py` the `usecases` branch of `classify`,
  `load_all` returns `(file_docs + section_docs, [])` then is folded into `load_docs` (callers
  updated), `used_by` drops the legacy-UC branch, `render_traceability` drops the legacy
  `rules` branch; in `check.py` the `"UC"` entries of `STATUS`, `REQUIRED_FIELDS`,
  `REQUIRED_SECTIONS`, `REFERENCE_FIELDS`, the legacy branch of `check_warnings` and the
  `migrated` parameter; in `ledger.py` nothing (it reads only what exists). Update the tests:
  delete `LEGACY_UC` and the two tests that use it.
- [ ] Update references (spec §6.4) with this mapping, then let `check.py` find the rest:

  | Old | New |
  |---|---|
  | `docs/shared/ui/screen-handoff/00-index.md` | `docs/screens/SCREEN_CATALOG.md` |
  | `docs/shared/ui/screen-handoff/<NN>-*.md` | the SCR spec of the table in Phase D |
  | `docs/shared/ui/navigation.md` | `docs/NAVIGATION.md` |
  | `docs/features/<f>/ui.md` | `docs/NAVIGATION.md` or the screen spec |
  | `docs/features/<f>/usecases/<UC>-*.md` | `docs/USE_CASES.md` |
  | ADR-019 (as the authority) | ADR-021 |

  Files: `CLAUDE.md` (table "Where knowledge lives": the row `A screen's layout, states,
  rulings and copy` → `its spec in docs/screens/spec/ (catalog: docs/screens/SCREEN_CATALOG.md)`;
  step 1 of "A screen's workflow" → "Read the screen's spec, the FNs it invokes,
  `docs/screens/SCREEN_CATALOG.md` and `DESIGN.md`."; drop the last sentence of the authority
  bullet added in Task 6), `PRODUCT.md`, `docs/README.md` (remove the `CŨ` lines from the map
  and the legacy-UC frontmatter block), `docs/agent/session-handoff.md`,
  `.claude/skills/flutter-workflow/SKILL.md`, `docs/features/*/README.md`, `docs/wbs_BE.md`,
  `docs/wbs_FE.md`, `docs/wbs_supabase.md`, the comment above `SKIP_LINK_CHECK` in
  `tools/docs/check.py` (ADR-019 → ADR-019/ADR-021). Find them with
  `grep -rln 'screen-handoff\|shared/ui/navigation\|/ui\.md\|/usecases/' --include='*.md' --include='*.py' --include='*.sh' . | grep -v '^./docs/superpowers\|^./.impeccable\|^./.git/'`.
- [ ] Run `python3 tools/docs/generate.py && python3 tools/docs/check.py`; fix every broken
  link it reports by pointing it at the new home. Expected: `PASS`, and no "now lives in
  USE_CASES.md" warning left.
- [ ] Run all tests and the gate; commit
  `docs: retire screen-handoff, feature ui.md and UC files after the verified migration`.

### Task 45: Whole-branch review and hand-off

- [ ] Final whole-branch review on Opus (the executing skill runs it), against the spec and
  this plan.
- [ ] Report to the owner: what moved, the ledger counts, the warnings left, and the two
  conditions sub-project 2 (deleting the old UI) inherits: this branch merged, and a git tag on
  the last commit that holds the 526 old goldens before any of them is deleted.
