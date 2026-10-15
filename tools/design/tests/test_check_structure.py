"""check.py: the theme's structure (allowed files, ThemeContext, extension fields)."""

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import check  # noqa: E402

REPO_ROOT = HERE.parents[2]
THEME = Path("lib/core/theme")


class StructureTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        shutil.copytree(REPO_ROOT / THEME, self.root / THEME)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_the_repository_theme_is_clean(self) -> None:
        self.assertEqual(check.structure_problems(REPO_ROOT), [])

    def test_a_copy_of_the_theme_is_clean(self) -> None:
        self.assertEqual(check.structure_problems(self.root), [])

    def test_a_file_outside_the_allowed_list_is_reported(self) -> None:
        (self.root / THEME / "app_spacing.dart").write_text("// a token class again")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("app_spacing.dart" in p for p in problems), problems)

    def test_a_hand_written_file_in_generated_is_reported(self) -> None:
        (self.root / THEME / "generated" / "extra.g.dart").write_text("// stray")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("extra.g.dart" in p for p in problems), problems)

    def test_an_extra_theme_context_getter_is_reported(self) -> None:
        path = self.root / THEME / "theme_context.dart"
        text = path.read_text(encoding="utf-8").replace(
            "  AppDimens get dimens",
            "  Color get primaryText => colors.primary;\n\n  AppDimens get dimens",
        )
        path.write_text(text, encoding="utf-8")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("primaryText" in p for p in problems), problems)

    def test_a_missing_theme_context_getter_is_reported(self) -> None:
        path = self.root / THEME / "theme_context.dart"
        text = path.read_text(encoding="utf-8").replace(
            "  TextTheme get texts => Theme.of(this).textTheme;\n", ""
        )
        path.write_text(text, encoding="utf-8")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("texts" in p for p in problems), problems)

    def test_an_extension_field_count_off_the_tokens_is_reported(self) -> None:
        path = self.root / THEME / "generated" / "mx_colors_extension.g.dart"
        text = path.read_text(encoding="utf-8").replace("  final Color divider;\n", "")
        path.write_text(text, encoding="utf-8")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("MxColorsExtension" in p for p in problems), problems)

    def test_a_dimens_field_count_off_the_tokens_is_reported(self) -> None:
        path = self.root / THEME / "generated" / "app_dimens.g.dart"
        text = path.read_text(encoding="utf-8").replace(
            "  final double space4;\n", "  final double space4;\n  final double space5;\n"
        )
        path.write_text(text, encoding="utf-8")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("AppDimens" in p for p in problems), problems)


if __name__ == "__main__":
    unittest.main()
