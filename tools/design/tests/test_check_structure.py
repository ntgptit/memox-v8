"""check.py: the theme's structure (allowed files, ThemeContext) and colour values."""

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

    def test_a_generated_folder_is_reported(self) -> None:
        (self.root / THEME / "generated").mkdir()
        (self.root / THEME / "generated" / "color_schemes.g.dart").write_text("// back")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("color_schemes.g.dart" in p for p in problems), problems)

    def test_an_extra_theme_context_getter_is_reported(self) -> None:
        path = self.root / THEME / "theme_context.dart"
        text = path.read_text(encoding="utf-8")
        marker = "  AppDimens get dimens"
        self.assertIn(marker, text)
        path.write_text(
            text.replace(marker, "  Color get accentInk => colors.primary;\n\n" + marker), encoding="utf-8"
        )
        problems = check.structure_problems(self.root)
        self.assertTrue(any("accentInk" in p for p in problems), problems)

    def test_a_missing_theme_context_getter_is_reported(self) -> None:
        path = self.root / THEME / "theme_context.dart"
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
        kept = [line for line in lines if " get hairline" not in line]
        self.assertLess(len(kept), len(lines))
        path.write_text("".join(kept), encoding="utf-8")
        problems = check.structure_problems(self.root)
        self.assertTrue(any("hairline" in p for p in problems), problems)


class ColorValueTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / THEME).mkdir(parents=True)
        (self.root / "lib/shared").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_a_hex_colour_in_a_widget_is_reported(self) -> None:
        (self.root / "lib/shared/a.dart").write_text("final c = Color(0xFF564BCB);\n")
        problems = check.color_value_problems(self.root)
        self.assertEqual(len(problems), 1)
        self.assertIn("lib/shared/a.dart:1", problems[0])

    def test_a_material_swatch_is_reported(self) -> None:
        (self.root / "lib/shared/a.dart").write_text("final c = Colors.blue;\n")
        self.assertEqual(len(check.color_value_problems(self.root)), 1)

    def test_the_palette_files_may_write_colours(self) -> None:
        for name in ("app_palette.dart", "mx_status_colors.dart"):
            (self.root / THEME / name).write_text("const c = Color(0xFF564BCB);\n")
        self.assertEqual(check.color_value_problems(self.root), [])

    def test_a_computed_colour_and_a_comment_stay_legal(self) -> None:
        (self.root / THEME / "color_tint.dart").write_text(
            "// Color(0xFF000000) is black.\nfinal c = Color.fromARGB(255, r, g, b);\n"
        )
        self.assertEqual(check.color_value_problems(self.root), [])


if __name__ == "__main__":
    unittest.main()
