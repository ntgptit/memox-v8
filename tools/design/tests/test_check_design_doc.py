"""check.py: DESIGN.md and the sidecar against design/tokens.json; values stay out of prose."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import check  # noqa: E402
import generate  # noqa: E402

TOKENS, APP_TOKENS = check.generate_inputs()
FRONT = generate.render_frontmatter(TOKENS, APP_TOKENS)
NARRATIVE = {"northStar": "The Quiet Study Desk", "rules": [{"name": "r", "body": "Accent once."}]}


def sidecar(narrative: dict = NARRATIVE) -> str:
    return generate.render_sidecar(TOKENS, APP_TOKENS, narrative)


class DesignDocTest(unittest.TestCase):
    def test_a_generated_document_with_token_names_in_its_prose_is_clean(self) -> None:
        document = FRONT + "\n# Design System\n\nCards sit on `cardSurface`, `space24` in, at 4.5:1.\n"
        self.assertEqual(check.design_doc_problems(document, sidecar()), [])

    def test_a_stale_frontmatter_is_reported(self) -> None:
        document = FRONT.replace('primary: "#564BCB"', 'primary: "#4255FF"') + "\n# Body\n"
        problems = check.design_doc_problems(document, sidecar())
        self.assertTrue(any("frontmatter" in p for p in problems), problems)

    def test_a_hex_or_a_sized_number_in_the_prose_is_reported(self) -> None:
        for prose in ("The page is #FFFFFF.", "Cards are 12px round.", "A 48dp target.", "It fades in 300ms."):
            with self.subTest(prose=prose):
                problems = check.design_doc_problems(FRONT + "\n" + prose + "\n", sidecar())
                self.assertTrue(any("prose" in p for p in problems), problems)

    def test_a_stale_sidecar_is_reported(self) -> None:
        stale = json.loads(sidecar())
        stale["extensions"]["colorMeta"]["primary"]["light"] = "#4255FF"
        problems = check.design_doc_problems(FRONT + "\n# Body\n", json.dumps(stale))
        self.assertTrue(any("design.json" in p for p in problems), problems)

    def test_a_value_in_the_hand_written_narrative_is_reported(self) -> None:
        narrative = {"northStar": "x", "rules": [{"name": "r", "body": "Indigo is #4255FF."}]}
        problems = check.design_doc_problems(FRONT + "\n# Body\n", sidecar(narrative))
        self.assertTrue(any("narrative" in p for p in problems), problems)


if __name__ == "__main__":
    unittest.main()
