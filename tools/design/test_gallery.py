"""Tests for tools/design/gallery.py:  python3 tools/design/test_gallery.py"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gallery  # noqa: E402

DESIGN = """---
name: X
---

## Components

### Catalog

| Component | Purpose | Layer | Consumers | Owner phase | Status |
|---|---|---|---|---|---|
| MxButton | An action | shared | DECK | SP3a | built |
| MxCard | A surface | shared | DECK | SP3a | planned |
| MxRowInk | A ripple | primitive | MxButton | SP3a | built |

### Contracts

#### MxButton
- Variants: primary
- States: enabled
- Accessibility: 48 target
- Tokens: primary
- Golden: tones__light, tones__dark

#### MxRowInk
- Variants: one
- States: one
- Accessibility: none of its own
- Tokens: splash
- Golden: none — paints only the press

## Do's and Don'ts
"""

PNG = bytes.fromhex("89504e470d0a1a0a0000000d4948445200000001000000010806000000")


def tree(goldens: tuple[str, ...]) -> Path:
    root = Path(tempfile.mkdtemp())
    (root / "DESIGN.md").write_text(DESIGN, encoding="utf-8")
    folder = root / gallery.GOLDENS
    folder.mkdir(parents=True)
    for name in goldens:
        (folder / name).write_bytes(PNG)
    return root


class GalleryTest(unittest.TestCase):
    def test_built_components_show_their_goldens_side_by_side(self):
        page, problems = gallery.build(tree(("mx_button__tones__light.png", "mx_button__tones__dark.png")))
        self.assertEqual(problems, [])
        self.assertIn('<section id="mx_button">', page)
        self.assertEqual(page.count("data:image/png;base64,"), 2)
        self.assertIn("mx_button__tones__dark.png", page)
        self.assertIn("<title>MemoX Mx Gallery</title>", page)

    def test_planned_components_are_left_out(self):
        page, _ = gallery.build(tree(("mx_button__tones__light.png", "mx_button__tones__dark.png")))
        self.assertNotIn("MxCard", page)

    def test_a_component_without_goldens_says_why(self):
        page, _ = gallery.build(tree(("mx_button__tones__light.png", "mx_button__tones__dark.png")))
        self.assertIn("none — paints only the press", page)

    def test_a_missing_golden_is_reported(self):
        _, problems = gallery.build(tree(("mx_button__tones__light.png",)))
        self.assertEqual(problems, ["MxButton: mx_button__tones__dark.png is missing"])


if __name__ == "__main__":
    unittest.main()
