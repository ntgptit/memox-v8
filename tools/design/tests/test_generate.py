"""generate.py: design/tokens.json -> lib/core/theme/generated/*.g.dart."""

from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import generate  # noqa: E402

REPO_ROOT = HERE.parents[2]
TOKENS = json.loads((REPO_ROOT / "design" / "tokens.json").read_text(encoding="utf-8"))
APP_TOKENS = json.loads((REPO_ROOT / "design" / "app_tokens.json").read_text(encoding="utf-8"))

EXTENSION_FIELDS = [
    "success", "onSuccess", "successContainer", "onSuccessContainer",
    "warning", "onWarning", "warningContainer", "onWarningContainer",
    "info", "onInfo", "infoContainer", "onInfoContainer",
    "cardSurface", "searchSurface", "tileSurface", "divider",
]  # fmt: skip


def fields_of(source: str, kind: str) -> list[str]:
    return re.findall(rf"^  final {kind} (\w+);", source, re.M)


class GenerateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.files = generate.render_all(TOKENS, APP_TOKENS)

    def test_every_file_carries_the_generated_header(self) -> None:
        header = "// GENERATED from design/tokens.json by tools/design/generate.py. Do not edit."
        for name, text in self.files.items():
            self.assertTrue(text.startswith(header), name)

    def test_each_scheme_declares_46_roles(self) -> None:
        text = self.files["color_schemes.g.dart"]
        for scheme in ("lightColorScheme", "darkColorScheme"):
            body = text.split(f"const ColorScheme {scheme}")[1].split(");")[0]
            self.assertEqual(len(re.findall(r"Color\(0xFF", body)), 46, scheme)

    def test_a_dark_value_comes_from_the_json(self) -> None:
        text = self.files["color_schemes.g.dart"]
        dark = text.split("const ColorScheme darkColorScheme")[1]
        self.assertIn("surface: Color(0xFF0A082D)", dark)

    def test_extension_has_the_16_fields_in_order(self) -> None:
        source = self.files["mx_colors_extension.g.dart"]
        self.assertEqual(fields_of(source, "Color"), EXTENSION_FIELDS)

    def test_dimens_has_42_token_fields_then_app_only(self) -> None:
        source = self.files["app_dimens.g.dart"]
        names = fields_of(source, "double")
        app_only = [t["name"] for t in APP_TOKENS["tokens"]]
        self.assertEqual(len(names), 42 + len(app_only))
        self.assertEqual(names[0], "space4")
        self.assertEqual(names[41], "opacityDisabledContainer")
        self.assertEqual(names[42:], app_only)
        self.assertEqual("// App-only — not yet in the design system." in source, bool(app_only))

    def test_text_theme_height_is_an_exact_ratio(self) -> None:
        source = self.files["text_theme.g.dart"]
        self.assertIn("height: 32 / 24", source)
        self.assertEqual(source.count("fontSize:"), 12)

    def test_only_display_medium_has_tabular_figures(self) -> None:
        source = self.files["text_theme.g.dart"]
        self.assertEqual(source.count("tabularFigures"), 1)

    def test_font_family_and_fallback_come_from_the_json(self) -> None:
        source = self.files["text_theme.g.dart"]
        self.assertIn("kFontFamily = 'BeVietnamPro'", source)
        self.assertIn("'NotoSansKR'", source)

    def test_opacity_constant_for_tint(self) -> None:
        self.assertIn("kOpacityDragged = 0.16", self.files["token_constants.g.dart"])

    def test_output_is_stable(self) -> None:
        self.assertEqual(self.files, generate.render_all(TOKENS, APP_TOKENS))


if __name__ == "__main__":
    unittest.main()


class RenameDetectionTest(unittest.TestCase):
    def test_a_name_that_disappeared_becomes_a_removed_symbol_without_replacement(self) -> None:
        old = {
            "app_dimens.g.dart": "  final double space4;\n  final double sizeOld;\n",
            "mx_colors_extension.g.dart": "  final Color success;\n  final Color gone;\n",
            "color_schemes.g.dart": "  primary: Color(0xFF000000),\n  dropped: Color(0xFF000000),\n",
        }
        new = {
            "app_dimens.g.dart": "  final double space4;\n",
            "mx_colors_extension.g.dart": "  final Color success;\n",
            "color_schemes.g.dart": "  primary: Color(0xFF000000),\n",
        }
        self.assertEqual(
            generate.vanished_names(old, new),
            {"dimens.sizeOld": "", "mxColors.gone": "", "colors.dropped": ""},
        )

    def test_nothing_vanishes_when_names_are_unchanged(self) -> None:
        self.assertEqual(generate.vanished_names(self_files := {"app_dimens.g.dart": "  final double a;\n"}, self_files), {})
