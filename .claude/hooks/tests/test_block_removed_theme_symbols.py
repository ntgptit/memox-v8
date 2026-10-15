"""Tests for the hook that keeps deleted theme names from coming back: a Dart
edit under lib/ or test/ that writes a removed name is refused (exit 2) with the
replacement; generated theme files and the deleted paths cannot be written."""

from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[1] / "block_removed_theme_symbols.py"


def run(tool_input: dict) -> subprocess.CompletedProcess:
    payload = {"tool_name": "Write", "tool_input": tool_input}
    return subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=False,
    )


class RemovedSymbolsTest(unittest.TestCase):
    def test_a_removed_name_in_dart_is_refused_with_its_replacement(self) -> None:
        result = run({"file_path": "lib/x.dart", "content": "final s = MxSemanticColors.light;"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("'MxSemanticColors' đã bị xoá", result.stderr)
        self.assertIn("MxColorsExtension", result.stderr)

    def test_new_string_of_an_edit_is_checked(self) -> None:
        result = run({"file_path": "test/a_test.dart", "new_string": "AppSpacing.gutter"})
        self.assertEqual(result.returncode, 2)

    def test_a_longer_identifier_is_not_a_match(self) -> None:
        result = run({"file_path": "lib/x.dart", "content": "final AppSpacingHelper h;"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_the_same_text_in_a_document_is_allowed(self) -> None:
        result = run({"file_path": "docs/x.md", "content": "MxSemanticColors was removed"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_a_deleted_path_cannot_be_written(self) -> None:
        result = run({"file_path": "lib/core/theme/foundations/app_size.dart", "content": "x"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("đã bị xoá", result.stderr)

    def test_generated_theme_files_cannot_be_edited_by_hand(self) -> None:
        result = run({"file_path": "lib/core/theme/generated/app_dimens.g.dart", "content": "x"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("design/tokens.json", result.stderr)
        self.assertIn("tools/design/generate.py", result.stderr)

    def test_clean_dart_passes(self) -> None:
        result = run({"file_path": "lib/x.dart", "content": "final d = context.dimens;"})
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_a_regex_entry_matches_the_old_access_form_only(self) -> None:
        bad = run({"file_path": "lib/x.dart", "content": "final c = semantic.warning;"})
        good = run({"file_path": "lib/x.dart", "content": "final c = context.mxColors.warning;"})
        self.assertEqual(bad.returncode, 2)
        self.assertEqual(good.returncode, 0, good.stderr)


if __name__ == "__main__":
    unittest.main()
