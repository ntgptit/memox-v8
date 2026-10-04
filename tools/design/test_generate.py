"""Tests for tools/design/generate.py:  python3 tools/design/test_generate.py"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate as g  # noqa: E402

TEXT_THEME = "".join(f"| {slot} | body |\n" for slot in g.TEXT_THEME_SLOTS)


def colors() -> dict[str, str]:
    """Every M3 role and one extension, light white and dark black."""
    values: dict[str, str] = {}
    for role in [*g.M3_ROLES, "success", "on-success"]:
        values[role] = "#FFFFFF"
        values[role + "-dark"] = "#000000"
    return values


def extensions() -> dict:
    return {
        "semanticExtensions": {"success": ["success", "on-success"]},
        "contrastPairs": [],
        "opacity": {"disabled": 0.38},
        "stroke": {"hairline": 1},
        "motion": {"standard": 200},
        "breakpoints": {"nav-rail": 600},
        "shadows": {"whisper": {"light": {"dy": 1, "blur": 2, "alpha": 0.04}, "dark": None}},
    }


def design(**changes) -> g.Design:
    fields = dict(
        colors=colors(),
        typography={"body": {"fontFamily": "PlusJakartaSans", "fontSize": "14px", "fontWeight": 400, "lineHeight": 1.5}},
        rounded={"md": "12px"},
        spacing={"gutter": "16px"},
        components={"card": {"backgroundColor": "{colors.surface}", "rounded": "{rounded.md}"}},
        text_theme={slot: "body" for slot in g.TEXT_THEME_SLOTS},
        sidecar_text="{}",
        extensions=extensions(),
    )
    fields.update(changes)
    return g.Design(**fields)


def has(errors: list[str], *parts: str) -> bool:
    return any(all(part in error for part in parts) for error in errors)


class ValidateTest(unittest.TestCase):
    def test_a_complete_design_is_valid(self):
        self.assertEqual(g.validate(design()), [])

    def test_there_are_45_material_roles(self):
        self.assertEqual(len(g.M3_ROLES), 45)
        self.assertEqual(len(set(g.M3_ROLES)), 45)

    def test_a_missing_m3_role_fails(self):
        values = colors()
        del values["surface-dim"], values["surface-dim-dark"]
        self.assertTrue(has(g.validate(design(colors=values)), "Material 3 role `surface-dim` is missing"))

    def test_a_role_without_its_dark_value_fails(self):
        values = colors()
        del values["primary-dark"]
        self.assertTrue(has(g.validate(design(colors=values)), "`primary` has no `primary-dark`"))

    def test_a_dark_value_without_its_light_value_fails(self):
        values = colors()
        values["orphan-dark"] = "#000000"
        self.assertTrue(has(g.validate(design(colors=values)), "`orphan-dark` has no light value"))

    def test_a_doubled_dark_suffix_fails(self):
        values = colors()
        values["primary-dark-dark"] = "#000000"
        self.assertTrue(has(g.validate(design(colors=values)), "`primary-dark-dark` repeats `-dark`"))

    def test_a_colour_outside_m3_and_the_extensions_fails(self):
        values = colors()
        values["brand"], values["brand-dark"] = "#123456", "#654321"
        self.assertTrue(has(g.validate(design(colors=values)), "`brand` is neither"))

    def test_a_declared_extension_member_without_a_colour_fails(self):
        ext = extensions()
        ext["semanticExtensions"]["success"].append("success-container")
        self.assertTrue(has(g.validate(design(extensions=ext)), "member `success-container` has no colour"))

    def test_an_ink_role_fails_as_a_colour_and_as_a_member(self):
        values = colors()
        values["primary-ink"], values["primary-ink-dark"] = "#123456", "#654321"
        ext = extensions()
        ext["semanticExtensions"]["warning"] = ["warningInk"]
        errors = g.validate(design(colors=values, extensions=ext))
        self.assertTrue(has(errors, "`primary-ink` is an ink role"))
        self.assertTrue(has(errors, "member `warningInk` is an ink role"))

    def test_link_is_not_an_ink_role(self):
        self.assertIsNone(g.INK.search("link"))
        self.assertIsNone(g.INK.search("inkwell"))

    def test_a_colour_literal_in_the_sidecar_fails(self):
        for literal in ('{"css": "color:#5265F5"}', '{"css": "color:#fff"}', '{"v": "rgba(15,22,56,0.04)"}'):
            self.assertTrue(has(g.validate(design(sidecar_text=literal)), "holds a colour literal"), literal)

    def test_a_value_that_is_not_hex_fails(self):
        values = colors()
        values["primary"] = "indigo"
        self.assertTrue(has(g.validate(design(colors=values)), "`primary` is `indigo`"))

    def test_a_contrast_pair_below_its_floor_fails_naming_the_theme(self):
        ext = extensions()
        ext["contrastPairs"] = [{"fg": "on-primary", "bg": "primary", "min": 4.5}]
        errors = g.validate(design(extensions=ext))
        self.assertTrue(has(errors, "`on-primary` on `primary` is 1.00:1 in light"))
        self.assertTrue(has(errors, "in dark"))

    def test_a_contrast_pair_that_passes_in_both_themes(self):
        values = colors()
        values["on-primary"], values["on-primary-dark"] = "#000000", "#FFFFFF"
        ext = extensions()
        ext["contrastPairs"] = [{"fg": "on-primary", "bg": "primary", "min": 4.5}]
        self.assertEqual(g.validate(design(colors=values, extensions=ext)), [])

    def test_a_contrast_pair_naming_an_unknown_colour_fails(self):
        ext = extensions()
        ext["contrastPairs"] = [{"fg": "nope", "bg": "primary", "min": 4.5}]
        self.assertTrue(has(g.validate(design(extensions=ext)), "names an unknown colour"))

    def test_an_unmapped_text_theme_slot_fails(self):
        mapping = {slot: "body" for slot in g.TEXT_THEME_SLOTS}
        del mapping["labelSmall"]
        self.assertTrue(has(g.validate(design(text_theme=mapping)), "`labelSmall` has no role"))

    def test_a_text_theme_slot_naming_an_unknown_role_fails(self):
        mapping = {slot: "body" for slot in g.TEXT_THEME_SLOTS}
        mapping["bodySmall"] = "tiny"
        self.assertTrue(has(g.validate(design(text_theme=mapping)), "unknown typography role `tiny`"))

    def test_a_component_reference_to_an_unknown_token_fails(self):
        components = {"card": {"backgroundColor": "{colors.error-fill}"}}
        self.assertTrue(has(g.validate(design(components=components)), "unknown `{colors.error-fill}`"))


class FrontmatterTest(unittest.TestCase):
    def test_nested_maps_and_scalars(self):
        text = (
            '---\nname: X\ndescription: A quiet space: two themes.\ncolors:\n  primary: "#4151C6"\n'
            'typography:\n  body:\n    fontSize: "14px"\n    fontWeight: 400\n    lineHeight: 1.5\n---\n# X\n'
        )
        self.assertEqual(g.frontmatter(text), {
            "name": "X",
            "description": "A quiet space: two themes.",
            "colors": {"primary": "#4151C6"},
            "typography": {"body": {"fontSize": "14px", "fontWeight": 400, "lineHeight": 1.5}},
        })

    def test_a_line_without_a_colon_is_an_error(self):
        with self.assertRaises(ValueError):
            g.frontmatter("---\ncolors\n---\n")


class LoadTest(unittest.TestCase):
    def test_load_reads_frontmatter_text_theme_and_sidecar(self):
        root = Path(tempfile.mkdtemp())
        (root / ".impeccable").mkdir()
        (root / "DESIGN.md").write_text(
            '---\nname: X\ncolors:\n  primary: "#4151C6"\n  primary-dark: "#AAB4FF"\n---\n\n# X\n\n'
            "### Text theme\n\n| M3 slot | Role |\n|---|---|\n" + TEXT_THEME + "\n## Layout\n",
            encoding="utf-8",
        )
        (root / ".impeccable/design.json").write_text(json.dumps({"extensions": extensions()}), encoding="utf-8")
        loaded = g.load(root)
        self.assertEqual(loaded.colors, {"primary": "#4151C6", "primary-dark": "#AAB4FF"})
        self.assertEqual(loaded.text_theme["displayLarge"], "body")
        self.assertEqual(len(loaded.text_theme), 15)
        self.assertEqual(loaded.extensions["stroke"], {"hairline": 1})


class EmitTest(unittest.TestCase):
    def test_the_scheme_sets_every_role_in_both_themes_and_no_surface_tint(self):
        source = g.emit(design())[g.OUT_DIR / "app_color_schemes.dart"]
        self.assertEqual(source.count("onPrimaryFixedVariant: Color(0xFFFFFFFF)"), 1)
        self.assertEqual(source.count("onPrimaryFixedVariant: Color(0xFF000000)"), 1)
        self.assertEqual(source.count("Color(0x"), 90)
        self.assertNotIn("surfaceTint", source)
        self.assertTrue(source.startswith(g.HEADER))

    def test_the_extension_has_a_field_per_member_and_both_instances(self):
        source = g.emit(design())[g.OUT_DIR / "app_semantic_colors.dart"]
        self.assertIn("final Color onSuccess;", source)
        self.assertIn("static const AppSemanticColors light", source)
        self.assertIn("static const AppSemanticColors dark", source)
        self.assertIn("onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!", source)

    def test_text_styles_move_the_weight_axis_and_fill_every_slot(self):
        source = g.emit(design())[g.OUT_DIR / "app_text_styles.dart"]
        self.assertIn("AppTypography.withWeight(", source)
        self.assertIn("FontWeight.w400", source)
        self.assertNotIn("fontWeight:", source)
        for slot in g.TEXT_THEME_SLOTS:
            self.assertIn(f"    {slot}: body,\n", source)

    def test_durations_are_named_constants(self):
        source = g.emit(design())[g.OUT_DIR / "app_durations.dart"]
        self.assertIn("static const Duration standard = Duration(milliseconds: 200);", source)

    def test_a_theme_without_a_shadow_emits_null(self):
        source = g.emit(design())[g.OUT_DIR / "app_shadows.dart"]
        self.assertIn("static const AppShadow? whisperDark = null;", source)
        self.assertIn("static const AppShadow whisperLight = AppShadow(dy: 1, blur: 2, alpha: 0.04);", source)

    def test_two_font_families_are_refused(self):
        typography = {
            "body": {"fontFamily": "A", "fontSize": "14px", "fontWeight": 400},
            "caption": {"fontFamily": "B", "fontSize": "12px", "fontWeight": 600},
        }
        with self.assertRaises(ValueError):
            g.emit(design(typography=typography))


def identity(path: Path, source: str) -> str:
    return source


class FreshnessTest(unittest.TestCase):
    def test_written_output_is_fresh_and_an_edit_makes_it_stale(self):
        root = Path(tempfile.mkdtemp())
        d = design()
        g.write(root, d, identity)
        self.assertEqual(g.stale(root, d, identity), [])
        target = root / g.OUT_DIR / "app_spacing.dart"
        target.write_text(target.read_text() + "// edited\n")
        self.assertTrue(has(g.stale(root, d, identity), "app_spacing.dart is stale"))

    def test_a_changed_design_makes_the_output_stale(self):
        root = Path(tempfile.mkdtemp())
        g.write(root, design(), identity)
        changed = design(spacing={"gutter": "20px"})
        self.assertTrue(has(g.stale(root, changed, identity), "app_spacing.dart is stale"))

    def test_written_files_use_lf_only(self):
        root = Path(tempfile.mkdtemp())
        g.write(root, design(), identity)
        for path in (root / g.OUT_DIR).glob("*.dart"):
            self.assertNotIn(b"\r", path.read_bytes(), path.name)

    def test_a_missing_file_and_a_stray_file_are_reported(self):
        root = Path(tempfile.mkdtemp())
        g.write(root, design(), identity)
        (root / g.OUT_DIR / "app_radius.dart").unlink()
        (root / g.OUT_DIR / "app_colors.dart").write_text("// stray\n")
        problems = g.stale(root, design(), identity)
        self.assertTrue(has(problems, "app_radius.dart is missing"))
        self.assertTrue(has(problems, "app_colors.dart is in the generated folder but not generated"))


if __name__ == "__main__":
    unittest.main()
