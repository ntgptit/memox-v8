"""generate.py: the DESIGN.md frontmatter and the .impeccable/design.json sidecar."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import generate  # noqa: E402

REPO_ROOT = HERE.parents[2]
TOKENS = json.loads((REPO_ROOT / "design" / "tokens.json").read_text(encoding="utf-8"))
APP_TOKENS = json.loads((REPO_ROOT / "design" / "app_tokens.json").read_text(encoding="utf-8"))
NARRATIVE = {"northStar": "x", "rules": []}


class FrontmatterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.text = generate.render_frontmatter(TOKENS, APP_TOKENS)

    def test_it_is_one_yaml_block_with_the_schema_groups_in_order(self) -> None:
        self.assertTrue(self.text.startswith("---\n"))
        self.assertTrue(self.text.endswith("\n---\n"))
        order = [self.text.index(f"\n{group}:") for group in
                 ("colors", "typography", "rounded", "spacing", "components")]  # fmt: skip
        self.assertEqual(order, sorted(order))

    def test_every_m3_role_and_extension_colour_carries_its_light_value(self) -> None:
        self.assertIn('  primary: "#564BCB"', self.text)
        self.assertIn('  surface-container-high: "#EEEEEE"', self.text)
        self.assertIn("  card-surface: ", self.text)
        self.assertIn("  on-warning-container: ", self.text)
        colors = self.text.split("\ncolors:\n")[1].split("\ntypography:")[0]
        self.assertEqual(colors.count('"#'), 46 + 16)

    def test_the_twelve_type_roles_come_from_the_json(self) -> None:
        typography = self.text.split("\ntypography:\n")[1].split("\nrounded:")[0]
        self.assertEqual(typography.count("fontSize:"), 12)
        self.assertIn('  display-term:\n    fontFamily: "Be Vietnam Pro, Noto Sans KR, system-ui, sans-serif"', typography)

    def test_components_reference_tokens(self) -> None:
        components = self.text.split("\ncomponents:\n")[1]
        self.assertIn('backgroundColor: "{colors.primary}"', components)
        self.assertIn('rounded: "{rounded.full}"', components)

    def test_it_replaces_only_the_leading_block(self) -> None:
        document = "---\nname: old\n---\n\n# Body\n\nprose\n"
        out = generate.with_frontmatter(document, self.text)
        self.assertTrue(out.startswith(self.text))
        self.assertTrue(out.endswith("\n# Body\n\nprose\n"))


class SidecarTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.data = json.loads(generate.render_sidecar(TOKENS, APP_TOKENS, NARRATIVE))

    def test_it_keeps_the_narrative_and_follows_schema_v2(self) -> None:
        self.assertEqual(self.data["schemaVersion"], 2)
        self.assertEqual(self.data["narrative"], NARRATIVE)

    def test_colour_meta_has_both_themes(self) -> None:
        primary = self.data["extensions"]["colorMeta"]["surface"]
        self.assertEqual((primary["light"], primary["dark"]), ("#FFFFFF", "#0A082D"))

    def test_breakpoints_and_motion_come_from_the_json(self) -> None:
        extensions = self.data["extensions"]
        self.assertEqual([b["value"] for b in extensions["breakpoints"]], ["600px", "840px"])
        self.assertIn("cubic-bezier(0.2, 0, 0, 1)", [m["value"] for m in extensions["motion"]])

    def test_components_render_with_literal_token_values(self) -> None:
        primary = next(c for c in self.data["components"] if c["refersTo"] == "button-primary")
        self.assertIn("background: #564BCB", primary["css"])

    def test_output_is_stable(self) -> None:
        again = generate.render_sidecar(TOKENS, APP_TOKENS, NARRATIVE)
        self.assertEqual(json.loads(again), self.data)


if __name__ == "__main__":
    unittest.main()
