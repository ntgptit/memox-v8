"""Fault-injection probes for the memox-v8 design-token ratchets."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import yaml

from code_verification_guard.factory.rule_factory import RuleFactory

REGISTRY_PATH = (
    Path(__file__).parents[1]
    / "registries"
    / "projects"
    / "memox-v8"
    / "rules"
    / "memox-design-token-rules.yaml"
)


def _rule_config(rule_id: str) -> dict:
    registry = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    for rule_config in registry.get("rules", []):
        if rule_config["id"] == rule_id:
            return deepcopy(rule_config)

    raise AssertionError(f"Rule not found: {rule_id}")


def _violations(rule_id: str, tmp_path: Path, source: str) -> list:
    source_path = tmp_path / "lib" / "shared" / "widgets" / "sample.dart"
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_text(source, encoding="utf-8")

    rule_config = _rule_config(rule_id)
    rule_config.pop("scopes", None)
    rule_config["include"] = ["lib/**/*.dart"]
    rule_config["exclude"] = []
    rule_config["enabled"] = True

    return RuleFactory().create(rule_config).check(tmp_path)


STROKE = "memox.design_token.no_raw_stroke_width"


def test_no_raw_stroke_width_goes_red_on_literals(tmp_path: Path) -> None:
    for bad in (
        "child: CircularProgressIndicator(strokeWidth: 2),",
        "border: Border.all(color: ink, width: 1.5),",
        "side: BorderSide(color: scheme.outline, width: 2),",
    ):
        assert _violations(STROKE, tmp_path, bad), bad


def test_no_raw_stroke_width_accepts_tokens_and_the_default(tmp_path: Path) -> None:
    good = """
    // strokeWidth: 2 was the old spelling.
    child: CircularProgressIndicator(strokeWidth: AppStroke.indicator),
    border: Border.all(color: ink, width: AppStroke.control),
    border: Border.all(color: ink),
    side: BorderSide(color: scheme.outline, width: AppStroke.hairline),
    """
    assert not _violations(STROKE, tmp_path, good)


def test_no_raw_border_radius_is_an_error_now() -> None:
    assert _rule_config("memox.design_token.no_raw_border_radius")["severity"] == "error"


BRIGHTNESS = "memox_v8.design_token.no_brightness_branch"


def test_no_brightness_branch_goes_red_on_a_mode_choice(tmp_path: Path) -> None:
    for bad in (
        "final c = theme.brightness == Brightness.dark ? a : b;",
        "if (Theme.of(context).brightness != Brightness.light) return;",
        "final isDark = MediaQuery.platformBrightnessOf(context);",
        "color: isDarkMode ? scheme.surface : scheme.onSurface,",
    ):
        assert _violations(BRIGHTNESS, tmp_path, bad), bad


def test_no_brightness_branch_leaves_prose_and_theme_mode_alone(
    tmp_path: Path,
) -> None:
    good = """
    // Brightness.dark reads the lighter fixed step (theme_rules.dart).
    themeMode: ThemeMode.dark,
    color: context.accentColor,
    """
    assert not _violations(BRIGHTNESS, tmp_path, good)


ALIAS = "memox_v8.design_token.no_theme_alias"


def test_no_theme_alias_goes_red_on_every_comeback_shape(tmp_path: Path) -> None:
    for bad in (
        "typedef MxSemanticColors = MxColorsExtension;",
        "@Deprecated('use mxColors') Color get warningSoft => warning;",
        "export 'generated/color_schemes.g.dart' show lightColorScheme;",
        "Color get primaryText => primary;",
        "Color get primaryText => colors.primary;",
    ):
        assert _violations(ALIAS, tmp_path, bad), bad


def test_no_theme_alias_leaves_real_getters_and_prose_alone(tmp_path: Path) -> None:
    good = """
    // A typedef here would be an alias; so would `get x => y;`.
    ColorScheme get colors => Theme.of(this).colorScheme;
    Color get accentColor => switch (colors.brightness) {
      Brightness.light => colors.primary,
      Brightness.dark => colors.primaryFixedDim,
    };
    export 'app_icons.dart';
    """
    assert not _violations(ALIAS, tmp_path, good)
