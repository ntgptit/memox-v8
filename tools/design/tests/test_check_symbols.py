"""check.py --symbols: the gate's grep for removed theme names and paths."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import check  # noqa: E402


class SymbolsCheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "lib").mkdir()
        (self.root / "test").mkdir()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_clean_tree_has_no_problems(self) -> None:
        (self.root / "lib" / "a.dart").write_text("final d = context.dimens;")
        self.assertEqual(check.symbol_problems(self.root), [])

    def test_removed_name_in_lib_is_reported_with_file_and_line(self) -> None:
        (self.root / "lib" / "a.dart").write_text("a\nfinal s = AppSpacing.gutter;\n")
        problems = check.symbol_problems(self.root)
        self.assertEqual(len(problems), 1)
        self.assertIn("lib/a.dart:2", problems[0])
        self.assertIn("AppSpacing", problems[0])

    def test_removed_name_in_test_is_reported(self) -> None:
        (self.root / "test" / "a_test.dart").write_text("MxTextStyles(a, b);")
        self.assertEqual(len(check.symbol_problems(self.root)), 1)

    def test_a_listed_path_that_exists_is_reported(self) -> None:
        listed = self.root / "lib/core/theme/foundations"
        listed.mkdir(parents=True)
        (listed / "x.dart").write_text("// nothing")
        problems = check.symbol_problems(self.root)
        self.assertTrue(any("foundations" in p for p in problems), problems)

    def test_an_entry_without_a_replacement_is_reported(self) -> None:
        problems = check.unfilled_replacements({"symbols": {"oldToken": ""}})
        self.assertEqual(len(problems), 1)
        self.assertIn("oldToken", problems[0])


if __name__ == "__main__":
    unittest.main()
