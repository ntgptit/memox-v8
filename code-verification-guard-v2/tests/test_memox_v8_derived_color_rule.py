"""The derived-colour rule bans a rebuilt colour, not colour maths."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import yaml

from code_verification_guard.factory.rule_factory import RuleFactory

REGISTRY_PATH = (
    Path(__file__).parents[1]
    / "registries" / "projects" / "memox-v8" / "rules"
    / "memox-design-token-rules.yaml"
)
SCOPES_PATH = (
    Path(__file__).parents[1]
    / "registries" / "projects" / "memox-v8" / "config" / "scopes.yaml"
)
FIXTURE_DIR = Path(__file__).parent / "fixtures" / "derived_color"
RULE = "memox.design_token.no_derived_color"


def _rule_config() -> dict:
    registry = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    for rule_config in registry.get("rules", []):
        if rule_config["id"] == RULE:
            return deepcopy(rule_config)
    raise AssertionError(f"Rule not found: {RULE}")


def _resolve_scopes(rule_config: dict) -> None:
    """Turn the rule's named scopes into include/exclude, as the guard does.

    `RuleFactory` reads `include`/`exclude` only; the named scopes are resolved
    by the config manager, so the probe resolves them from the real scopes.yaml
    to exercise the scope's own excludes.
    """
    scopes = yaml.safe_load(SCOPES_PATH.read_text(encoding="utf-8"))["scopes"]
    include: list[str] = []
    exclude: list[str] = []
    for name in rule_config.pop("scopes"):
        include += scopes[name]["include"]
        exclude += scopes[name].get("exclude", [])
    rule_config["include"] = include
    rule_config["exclude"] = exclude


def _violations(tmp_path: Path, relative: str, source: str) -> list:
    source_path = tmp_path / relative
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_text(source, encoding="utf-8")
    rule_config = _rule_config()
    _resolve_scopes(rule_config)
    rule_config["enabled"] = True
    return RuleFactory().create(rule_config).check(tmp_path)


def test_valid_colour_handling_is_clean(tmp_path: Path) -> None:
    source = (FIXTURE_DIR / "valid.dart").read_text(encoding="utf-8")
    assert _violations(tmp_path, "lib/shared/widgets/sample.dart", source) == []


def test_each_rebuilt_colour_is_one_finding(tmp_path: Path) -> None:
    source = (FIXTURE_DIR / "invalid.dart").read_text(encoding="utf-8")
    found = _violations(tmp_path, "lib/shared/widgets/sample.dart", source)
    # Line 3 is hit twice (the blend and its literal alpha); every one of the
    # four lines is a finding.
    assert sorted({violation.line_number for violation in found}) == [1, 2, 3, 4]


def test_the_theme_extension_lerp_is_excluded(tmp_path: Path) -> None:
    source = (FIXTURE_DIR / "invalid.dart").read_text(encoding="utf-8")
    assert _violations(tmp_path, "lib/core/theme/mx_semantic_colors.dart", source) == []
