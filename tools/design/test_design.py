"""Tests for designdata.py and generate.py:  python3 -m unittest discover -s tools/design"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import designdata as d  # noqa: E402
import generate as g  # noqa: E402

GREY = "#808080"


def _section(name: str, mapping: dict, indent: int = 0) -> list[str]:
    pad = " " * indent
    lines = [f"{pad}{name}:"]
    for key, value in mapping.items():
        if isinstance(value, dict):
            lines += _section(key, value, indent + 2)
        else:
            lines.append(f"{pad}  {key}: {value}")
    return lines


def _valid() -> dict:
    colours = {name: f'"{GREY}"' for name in d.M3_ROLES + d.SEMANTIC_COLORS}
    colours.update({"surface": '"#FFFFFF"', "on-surface": '"#000000"', "primary": '"#5A6BAE"'})
    shadow = {"x": "0", "y": "1", "blur": "2", "alpha": "0.04"}
    return {
        "colors": dict(colours),
        "colors-dark": dict(colours),
        "derived": {
            "primary-ink": {
                "light": {"base": "primary", "toward": "on-surface", "amount": "0.25"},
                "dark": {"base": "primary", "toward": "on-surface", "amount": "0.25"},
            },
            "ghost-border": {"light": {"base": "primary", "alpha": "0.14"}, "dark": {"base": "primary", "alpha": "0.16"}},
        },
        "contrast": {"on-surface": {"surface": "4.5"}},
        "type-slots": {slot: "body" for slot in d.TYPE_SLOTS},
        "typography": {"body": {"fontFamily": '"PlusJakartaSans"', "fontSize": '"14px"', "fontWeight": "400", "lineHeight": "1.5"}},
        "spacing": {"gutter": '"16px"'},
        "rounded": {"md": '"12px"'},
        "opacity": {"disabled": "0.38"},
        "stroke": {"hairline": "1"},
        "motion": {"standard": "200"},
        "size": {"touch-target": "48"},
        "icon-size": {"small": "16"},
        "breakpoints": {"rail": "600"},
        "effects": {"scrim-alpha": "0.45"},
        "shadows": {name: dict(shadow) for name in d.SHADOWS},
        "shadows-dark": {name: dict(shadow) for name in d.SHADOWS},
    }


def _text(front: dict, body: str = "# Design\n\n" + g.BLOCK_START + "\n" + g.BLOCK_END + "\n") -> str:
    lines = ["---"]
    for key, value in front.items():
        lines += _section(key, value)
    return "\n".join(lines + ["---", body])


class ReaderTest(unittest.TestCase):
    def test_nested_mappings_and_quotes(self):
        front, body, first = d.read_frontmatter('---\na:\n  b: "#FFFFFF"\n  c:\n    d: 1\n---\nbody')
        self.assertEqual(front, {"a": {"b": "#FFFFFF", "c": {"d": "1"}}})
        self.assertEqual((body, first), (["body"], 7))

    def test_yaml_outside_the_subset_is_refused(self):
        for bad in ("a: [1, 2]", "a: {b: 1}", "a: &x 1", "\ta: 1", "a 1"):
            with self.subTest(bad=bad), self.assertRaises(d.SourceError):
                d.read_frontmatter(f"---\n{bad}\n---\n")

    def test_a_duplicate_key_is_refused(self):
        with self.assertRaises(d.SourceError):
            d.read_frontmatter("---\na: 1\na: 2\n---\n")


class LoadTest(unittest.TestCase):
    def test_a_valid_source_loads(self):
        data, errors = d.load(_text(_valid()))
        self.assertEqual(errors, [])
        self.assertEqual(len(data.colors["light"]), 45 + 13 + 2)

    def test_a_missing_role_and_an_unknown_colour_are_errors(self):
        front = _valid()
        del front["colors"]["surface-dim"]
        front["colors-dark"]["surface-tint"] = f'"{GREY}"'
        _, errors = d.load(_text(front))
        self.assertIn("colors: `surface-dim` is missing", errors)
        self.assertIn("colors-dark: `surface-tint` is neither a Material 3 role nor a MemoX colour", errors)

    def test_a_lower_case_hex_is_an_error(self):
        front = _valid()
        front["colors"]["primary"] = '"#5a6bae"'
        _, errors = d.load(_text(front))
        self.assertTrue(any("not an upper-case #RRGGBB" in e for e in errors))

    def test_a_derived_colour_rounds_half_up_like_dart(self):
        # 90 + (228 - 90) * 0.25 = 124.5: half-up gives 125 (0x7D), half-even 124.
        self.assertEqual(d.lerp("#5A6BAE", "#E4E8FA", 0.25), "#7D8AC1")

    def test_a_derived_alpha_keeps_the_base_and_its_alpha(self):
        data, _ = d.load(_text(_valid()))
        border = data.colors["light"]["ghost-border"]
        self.assertEqual((border.hex, border.argb()), ("#5A6BAE", "0x245A6BAE"))

    def test_a_rule_naming_an_unknown_colour_is_an_error(self):
        front = _valid()
        front["derived"]["primary-ink"]["dark"]["toward"] = "ink"
        _, errors = d.load(_text(front))
        self.assertIn("derived.primary-ink.dark: toward `ink` is not a stated colour", errors)

    def test_a_pair_below_its_floor_is_an_error(self):
        front = _valid()
        front["contrast"]["primary"] = {"surface-dim": "4.5"}
        _, errors = d.load(_text(front))
        self.assertTrue(any("primary on surface-dim" in e and "below 4.5:1" in e for e in errors))

    def test_every_type_slot_must_map_to_a_role(self):
        front = _valid()
        del front["type-slots"]["label-small"]
        front["type-slots"]["body-small"] = "caption"
        _, errors = d.load(_text(front))
        self.assertIn("type-slots: `label-small` is missing", errors)
        self.assertIn("type-slots.body-small: `caption` is not a typography role", errors)

    def test_a_shadow_needs_all_four_numbers(self):
        front = _valid()
        del front["shadows"]["fab"]["blur"]
        _, errors = d.load(_text(front))
        self.assertIn("shadows.fab: needs x, y, blur and alpha", errors)


class ProseTest(unittest.TestCase):
    def test_prose_may_name_only_design_values_outside_the_block(self):
        data, _ = d.load(_text(_valid()))
        body = ["Uses #808080.", "Drifted #123456.", g.BLOCK_START, "#ABCDEF", g.BLOCK_END]
        self.assertEqual(
            d.prose_drift(body, 10, data, (g.BLOCK_START, g.BLOCK_END)),
            ["DESIGN.md:11: #123456 is not a value of the frontmatter"],
        )


class BuildTest(unittest.TestCase):
    def _root(self, design_md: str) -> Path:
        root = Path(tempfile.mkdtemp())
        (root / ".impeccable").mkdir()
        (root / g.DESIGN_JSON).write_text(json.dumps({"extensions": {}}), encoding="utf-8")
        (root / g.DESIGN_MD).write_text(design_md, encoding="utf-8")
        return root

    def test_the_outputs_are_written_then_check_passes_then_a_hand_edit_fails(self):
        root = self._root(_text(_valid()))
        identity = lambda text, _: text  # noqa: E731
        outputs, errors = g.build(root, identity)
        self.assertEqual(errors, [])
        self.assertIn("static const DesignPalette light", outputs[g.DART_OUT])
        self.assertIn("static const double gutter = 16;", outputs[g.DART_OUT])
        self.assertIn("| `ghost-border` | #5A6BAE @ 14% |", outputs[g.DESIGN_MD])
        for path, text in outputs.items():
            (root / path).parent.mkdir(parents=True, exist_ok=True)
            (root / path).write_text(text, encoding="utf-8")
        self.assertEqual(g.build(root, identity)[0], outputs)
        meta = json.loads(outputs[g.DESIGN_JSON])["extensions"]["colorMeta"]
        self.assertEqual(meta["primary"]["dark"], "#5A6BAE")

    def test_missing_markers_are_an_error(self):
        root = self._root(_text(_valid(), body="# Design\n"))
        _, errors = g.build(root, lambda text, _: text)
        self.assertTrue(any("markers are missing" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
