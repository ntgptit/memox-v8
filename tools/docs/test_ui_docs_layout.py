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


if __name__ == "__main__":
    unittest.main()
