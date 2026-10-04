"""Tests for design_catalog.py:  python3 tools/docs/test_design_catalog.py"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import design_catalog as dc  # noqa: E402

HEADER = "| Component | Purpose | Layer | Consumers | Owner phase | Status |\n|---|---|---|---|---|---|\n"
CONTRACT = """#### MxButton
- Variants: primary
- States: enabled
- Accessibility: 48 target, label read
- Tokens: primary, on-primary
- Golden: primary_enabled__light, primary_enabled__dark
"""
DOMAINS = {"DECK", "CARD"}
SCREENS = {"SCR-DECK-001"}


def design(rows: str, contracts: str = "", body: str = "") -> str:
    return (
        "---\nname: X\n---\n\n# X\n\n## Components\n\n" + body
        + "\n### Catalog\n\n" + HEADER + rows + "\n### Contracts\n\n" + contracts + "\n## Do's and Don'ts\n"
    )


def row(name="MxButton", layer="shared", consumers="DECK, CARD", phase="SP3a", status="planned") -> str:
    return f"| {name} | an action | {layer} | {consumers} | {phase} | {status} |\n"


def tree(files: dict[str, str]) -> Path:
    root = Path(tempfile.mkdtemp())
    for name, content in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return root


def found(files: dict[str, str], goldens=()) -> list[str]:
    root = tree(files)
    golden_paths = {name: root / "test/shared/widgets/goldens" / name for name in goldens}
    return [f"{level} {where}: {message}" for level, where, message in dc.check_catalog(root, DOMAINS, SCREENS, golden_paths)]


def has(lines: list[str], *parts: str) -> bool:
    return any(all(part in line for part in parts) for line in lines)


BUTTON = "class MxButton extends StatelessWidget {}\n"


class CatalogTest(unittest.TestCase):
    def test_a_planned_row_needs_no_code(self):
        self.assertEqual(found({"DESIGN.md": design(row())}), [])

    def test_snake_names(self):
        self.assertEqual(dc.snake("MxButton"), "mx_button")
        self.assertEqual(dc.snake("MxTextField"), "mx_text_field")
        self.assertEqual(dc.snake("MasteryDonut"), "mastery_donut")

    def test_bad_layer_phase_and_status_are_errors(self):
        lines = found({"DESIGN.md": design(row(layer="widget", phase="SP4", status="done"))})
        self.assertTrue(has(lines, "layer `widget`"))
        self.assertTrue(has(lines, "owner phase `SP4`"))
        self.assertTrue(has(lines, "status `done`"))

    def test_feature_layers_are_accepted(self):
        self.assertEqual(found({"DESIGN.md": design(row(name="DeckRow", layer="feature:deck", phase="SP3b"))}), [])

    def test_an_mx_name_on_a_product_semantic_component_is_an_error(self):
        lines = found({"DESIGN.md": design(row(name="MxMasteryDonut", layer="product-semantic", phase="SP3b"))})
        self.assertTrue(has(lines, "`Mx*` names only design-system vocabulary"))

    def test_an_unknown_consumer_is_an_error_and_a_component_consumer_is_not(self):
        rows = row(consumers="DECK, BOGUS") + row(name="MxRowInk", layer="primitive", consumers="MxButton, SCR-DECK-001")
        lines = found({"DESIGN.md": design(rows)})
        self.assertTrue(has(lines, "consumer `BOGUS`"))
        self.assertFalse(has(lines, "consumer `MxButton`"))

    def test_a_row_with_the_wrong_number_of_cells_is_an_error(self):
        bad = "| MxChip | a chip | with a stray pipe | shared | DECK, CARD | SP3a | planned |\n"
        lines = found({"DESIGN.md": design(row() + bad)})
        self.assertTrue(has(lines, "catalog row has 7 cells; a row has 6"))

    def test_a_duplicate_row_is_an_error(self):
        self.assertTrue(has(found({"DESIGN.md": design(row() + row())}), "two catalog rows"))

    def test_implementing_needs_a_contract_and_the_file(self):
        lines = found({"DESIGN.md": design(row(status="implementing"))})
        self.assertTrue(has(lines, "has no `#### MxButton` contract"))
        lines = found({"DESIGN.md": design(row(status="implementing"), CONTRACT)})
        self.assertTrue(has(lines, "`lib/shared/widgets/mx_button.dart` does not exist"))
        files = {"DESIGN.md": design(row(status="implementing"), CONTRACT), "lib/shared/widgets/mx_button.dart": BUTTON}
        self.assertEqual(found(files), [])

    def test_a_contract_missing_a_field_is_an_error(self):
        contract = CONTRACT.replace("- Tokens: primary, on-primary\n", "")
        files = {"DESIGN.md": design(row(status="implementing"), contract), "lib/shared/widgets/mx_button.dart": BUTTON}
        self.assertTrue(has(found(files), "contract has no `Tokens`"))

    def test_built_needs_its_test_and_every_golden(self):
        files = {"DESIGN.md": design(row(status="built"), CONTRACT), "lib/shared/widgets/mx_button.dart": BUTTON}
        lines = found(files)
        self.assertTrue(has(lines, "no widget test `test/shared/widgets/mx_button_test.dart`"))
        self.assertTrue(has(lines, "missing golden `mx_button__primary_enabled__dark.png`"))
        files["test/shared/widgets/mx_button_test.dart"] = "void main() {}\n"
        goldens = ("mx_button__primary_enabled__light.png", "mx_button__primary_enabled__dark.png")
        self.assertEqual(found(files, goldens), [])

    def test_golden_none_needs_no_png(self):
        contract = CONTRACT.replace("- Golden: primary_enabled__light, primary_enabled__dark", "- Golden: none — a primitive with no paint")
        files = {
            "DESIGN.md": design(row(status="built"), contract),
            "lib/shared/widgets/mx_button.dart": BUTTON,
            "test/shared/widgets/mx_button_test.dart": "void main() {}\n",
        }
        self.assertEqual(found(files), [])

    def test_a_product_semantic_component_cannot_leave_planned_in_sp3a(self):
        contract = CONTRACT.replace("MxButton", "MasteryDonut")
        lines = found({"DESIGN.md": design(row(name="MasteryDonut", layer="product-semantic", phase="SP3b", status="implementing"), contract)})
        self.assertTrue(has(lines, "its path is set by the SP3b spec"))

    def test_deprecated_needs_a_replacement_field(self):
        lines = found({"DESIGN.md": design(row(status="deprecated"), CONTRACT)})
        self.assertTrue(has(lines, "declares no `Replacement`"))
        self.assertEqual(found({"DESIGN.md": design(row(status="deprecated"), CONTRACT + "- Replacement: none\n")}), [])

    def test_a_public_mx_widget_outside_the_catalog_is_an_error(self):
        files = {"DESIGN.md": design(row()), "lib/shared/widgets/mx_chip.dart": "class MxChip extends StatelessWidget {}\n"}
        self.assertTrue(has(found(files), "public `MxChip` has no row"))

    def test_an_mx_widget_in_the_wrong_place_is_an_error(self):
        files = {"DESIGN.md": design(row()), "lib/features/deck/presentation/widgets/mx_button.dart": BUTTON}
        self.assertTrue(has(found(files), "it belongs at `lib/shared/widgets/mx_button.dart`"))

    def test_an_mx_component_on_any_base_class_is_seen(self):
        files = {"DESIGN.md": design(row()), "lib/shared/widgets/mx_chip.dart": "class MxChip extends ButtonStyleButton {}\n"}
        self.assertTrue(has(found(files), "public `MxChip` has no row"))
        files = {"DESIGN.md": design(row()), "lib/features/deck/x.dart": "final class MxButton extends ButtonStyleButton {}\n"}
        self.assertTrue(has(found(files), "it belongs at `lib/shared/widgets/mx_button.dart`"))

    def test_an_mx_type_that_belongs_to_no_component_is_an_error(self):
        files = {"DESIGN.md": design(row()), "lib/shared/widgets/mx_ghost.dart": "enum MxGhostTone { a }\n"}
        self.assertTrue(has(found(files), "public `MxGhostTone` has no row"))

    def test_a_non_widget_mx_type_is_not_a_component(self):
        files = {"DESIGN.md": design(row()), "lib/shared/widgets/mx_button.dart": "enum MxButtonTone { primary }\nclass MxButtonStyle {}\n"}
        self.assertEqual(found(files), [])

    def test_an_mx_name_in_design_prose_or_a_screen_spec_must_be_catalogued(self):
        files = {
            "DESIGN.md": design(row(), body="Use `MxButton` and `MxScrollClearance`.\n"),
            "docs/screens/spec/SCR-DECK-001-deck-list.md": "A `MxGhost` here.\n",
        }
        lines = found(files)
        self.assertTrue(has(lines, "DESIGN.md:", "`MxScrollClearance` is not in the DESIGN.md catalog"))
        self.assertTrue(has(lines, "SCR-DECK-001-deck-list.md:1", "`MxGhost`"))
        self.assertFalse(has(lines, "`MxButton` is not"))


class GoldenTest(unittest.TestCase):
    def files(self, status: str) -> dict[str, str]:
        return {
            "DESIGN.md": design(row(status=status), CONTRACT),
            "lib/shared/widgets/mx_button.dart": BUTTON,
            "test/shared/widgets/mx_button_test.dart": "void main() {}\n",
        }

    def test_a_golden_of_an_unknown_component_is_an_error(self):
        self.assertTrue(has(found(self.files("built"), ("mx_chip__on__light.png",)), "names no catalog component"))

    def test_a_golden_outside_the_contract_is_an_error(self):
        lines = found(self.files("implementing"), ("mx_button__secondary_enabled__light.png",))
        self.assertTrue(has(lines, "`secondary_enabled__light` is not in `MxButton`'s Golden list"))

    def test_a_planned_component_has_no_goldens(self):
        lines = found({"DESIGN.md": design(row())}, ("mx_button__primary_enabled__light.png",))
        self.assertTrue(has(lines, "`MxButton` is planned; it has no goldens"))

    def test_without_design_md_a_component_golden_is_an_error(self):
        self.assertTrue(has(found({}, ("mx_button__a__light.png",)), "DESIGN.md has no catalog"))


class InkVocabularyTest(unittest.TestCase):
    def test_ink_terms_are_errors_in_every_scope(self):
        root = tree({
            "DESIGN.md": "Primary ink is retired.\n",
            "docs/screens/spec/SCR-X.md": "a status label in its ink\nlearning ink\n",
            ".claude/skills/flutter-design-system/SKILL.md": "use context.derivedColors.primaryInk\n",
            "lib/x.dart": "final Color warningInk = c;\n",
            "lib/l10n/app_en.arb": '"description": "a row, in the learning ink."\n',
            "lib/l10n/generated/app_localizations.dart": "/// in the learning ink.\n",
        })
        lines = [f"{where}: {message}" for _, where, message in dc.check_ink_vocabulary(root)]
        self.assertEqual(len(lines), 6, lines)

    def test_the_impeccable_sidecar_is_in_scope(self):
        root = tree({".impeccable/design.json": '"body": "use the derived primary ink"\n'})
        self.assertEqual(len(dc.check_ink_vocabulary(root)), 1)

    def test_private_snake_and_pascal_ink_names_are_errors(self):
        root = tree({"lib/x.dart": "Color get _primaryInk => c;\nfinal primary_ink = c;\nclass StatusInk {}\n"})
        self.assertEqual(len(dc.check_ink_vocabulary(root)), 3)

    def test_a_tone_named_ink_is_an_error(self):
        root = tree({"docs/screens/spec/SCR-X.md": "amber with dark ink; white ink on it\n"})
        self.assertEqual(len(dc.check_ink_vocabulary(root)), 2)

    def test_a_catalogued_component_file_name_is_allowed(self):
        root = tree({"lib/x.dart": "import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';\n"})
        self.assertEqual(dc.check_ink_vocabulary(root, frozenset({"MxRowInk"})), [])
        self.assertEqual(len(dc.check_ink_vocabulary(root)), 1)

    def test_a_catalogued_component_named_ink_is_allowed(self):
        root = tree({"lib/x.dart": "class MxRowInk extends StatelessWidget {}\n"})
        self.assertEqual(dc.check_ink_vocabulary(root, frozenset({"MxRowInk"})), [])

    def test_ripples_links_and_rows_are_not_ink_roles(self):
        root = tree({
            "DESIGN.md": "a link; InkWell; MxRowInk is the row ripple; Ink.image\n",
            "lib/x.dart": "return InkWell(child: Ink(child: c));\n",
        })
        self.assertEqual(dc.check_ink_vocabulary(root, frozenset({"MxRowInk"})), [])


if __name__ == "__main__":
    unittest.main()
