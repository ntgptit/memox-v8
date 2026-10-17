"""check.py: values stay out of DESIGN.md's prose and the sidecar's narrative.

That the frontmatter and the token part equal the production theme is
test/tools/design_doc_test.dart's (they are rendered from Dart).
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import check  # noqa: E402

FRONT = '---\nname: MemoX V8\ncolors:\n  primary: "#564BCB"\n---\n'
NARRATIVE = {"northStar": "The Quiet Study Desk", "rules": [{"name": "r", "body": "Accent once."}]}


def sidecar(narrative: dict = NARRATIVE) -> str:
    return json.dumps({"schemaVersion": 2, "extensions": {"colorMeta": {}}, "narrative": narrative})


class DesignDocTest(unittest.TestCase):
    def test_the_committed_documents_are_clean(self) -> None:
        problems = check.design_doc_problems(
            check.DESIGN_PATH.read_text(encoding="utf-8"),
            check.SIDECAR_PATH.read_text(encoding="utf-8"),
        )
        self.assertEqual(problems, [])

    def test_role_names_in_the_prose_are_clean(self) -> None:
        document = FRONT + "\n# Design System\n\nCards sit on `card`, `space24` in, at 4.5:1.\n"
        self.assertEqual(check.design_doc_problems(document, sidecar()), [])

    def test_the_frontmatter_may_hold_values(self) -> None:
        self.assertEqual(check.design_doc_problems(FRONT + "\n# Body\n", sidecar()), [])

    def test_a_missing_frontmatter_is_reported(self) -> None:
        problems = check.design_doc_problems("# Body\n", sidecar())
        self.assertTrue(any("frontmatter" in p for p in problems), problems)

    def test_a_hex_or_a_sized_number_in_the_prose_is_reported(self) -> None:
        for prose in ("The page is #FFFFFF.", "Cards are 12px round.", "A 48dp target.", "It fades in 300ms."):
            with self.subTest(prose=prose):
                problems = check.design_doc_problems(FRONT + "\n" + prose + "\n", sidecar())
                self.assertTrue(any("prose" in p for p in problems), problems)

    def test_a_value_in_the_hand_written_narrative_is_reported(self) -> None:
        narrative = {"northStar": "x", "rules": [{"name": "r", "body": "Indigo is #564BCB."}]}
        problems = check.design_doc_problems(FRONT + "\n# Body\n", sidecar(narrative))
        self.assertTrue(any("narrative" in p for p in problems), problems)


if __name__ == "__main__":
    unittest.main()
