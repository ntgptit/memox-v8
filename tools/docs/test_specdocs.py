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
