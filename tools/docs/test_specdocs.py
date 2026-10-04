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


if __name__ == "__main__":
    unittest.main()
