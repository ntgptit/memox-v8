# SP3a Phase 1 — Structured design data, generator and theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `DESIGN.md` the one hand-edited source of every design value. A generator turns it into a 45-role light and dark `ColorScheme`, MemoX semantic extensions, a `TextTheme` and the scalar tokens. The gate fails whenever that chain is broken.

**Architecture:**
- **Source.** The `DESIGN.md` frontmatter holds every colour (light key plus `-dark` key), the typography, the radii and the spacing. A `### Text theme` table maps the 15 M3 slots. The sidecar `.impeccable/design.json` holds only colour-free metadata: the extension families, the contrast pairs, opacity, stroke, motion, breakpoints and shadows.
- **Generator.** `tools/design/generate.py` validates that source and writes `lib/core/theme/foundations/*.dart`. Its `--check` mode, run by the gate, fails on invalid data or stale output.
- **Theme.** `AppTheme` builds `ThemeData` from the generated files only.
- **Catalog.** `tools/docs/check.py` gains the `DESIGN.md` component-catalog rules and the retired-ink vocabulary rule.

**Tech Stack:** Python 3.11 standard library only, no new dependency (`tools/`, `unittest`); Flutter 3.47.5 / Dart 3.13 (`ColorScheme`, `ThemeExtension`, `TextTheme`); the `memox-v8` guard ruleset.

**Spec:** `docs/superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md` (approved 2026-10-04, rulings A1–A11). Phase 1 = spec §3 and §4.

## Global Constraints

- Every light and dark colour value lives only in the `DESIGN.md` frontmatter, as `<role>` and `<role>-dark` (A3).
- `.impeccable/design.json` holds no colour literal: no `#hex`, no `rgb(`, no `rgba(` (A3).
- No `*Ink` or `*-ink` role or name anywhere, and no derived ink (A2, A11).
- 45 Material 3 roles in each theme. Never pass `surfaceTint` or a deprecated role (`background`, `onBackground`, `surfaceVariant`).
- Generated files under `lib/core/theme/foundations/` are never edited by hand. They are committed. They are not `*.g.dart` (build_runner's gitignored namespace).
- Phase 1 builds no `Mx*` component (A11).
- `Mx*` names only design-system vocabulary. `MxAppShell` becomes `MxScreenScaffold`, with no alias (A5, A11).
- Only the `primitive` and `shared` layers get paths: `lib/shared/widgets/primitives/<snake>.dart`, `lib/shared/widgets/<snake>.dart`, and the test at `test/shared/widgets/<snake>_test.dart` (spec §4.2).
- Golden names: `scr_<screen>__<state>__<variant>.png` and `mx_<component>__<state>__<variant>.png` (A7).
- Python runs with the standard library only (the gate also runs on Windows, without PyYAML).
- Commit messages end with the two attribution lines this session uses:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Y8YmUXn5BengVUKKmQjAv5`.

## Deviation from the spec (for the owner's review of this plan)

- **`surfaceTint` (spec §3.1 says the theme pins it to transparent).** Guard rule
  `memox_v8.design_system.color_scheme_arguments_are_m3_roles` forbids passing `surfaceTint` to a
  `ColorScheme` or its `copyWith`, because it is an SDK mechanism and not a role.
  - This plan therefore never sets it on the scheme.
  - Each component theme added in Phases 2–4 sets `surfaceTintColor: Colors.transparent`, which
    is what the spec's intent ("no elevation overlay changes a colour") needs.
  - The rule is not weakened.
- **`mastery` merges into `status-mastered`.** The two had the same value and the same meaning
  (learning progress). A2 lists `status-mastered` and not `mastery`, and two roles with one
  meaning break `flutter-theme-design`'s rule against splitting a meaning. `MxBadge`'s
  "mastery" tone reads `status-mastered`.
- **No `info` extension.** No catalog consumer needs one (A2: only members a consumer uses).
- **`error-fill` is retired.** The destructive button is `error` under `on-error` (A2: danger
  is Material's `error*`).

## Review Focus

- **The generator on Windows.** `dart` resolves through `shutil.which`, which honours PATHEXT, and output is written with `newline="\n"`. Task 1 adds a test that a written file holds no `\r`.
- **A colour changed in `DESIGN.md` without regenerating.** `--check` must fail and name the stale file. Task 1 tests this.
- **A typo in a key** (`primary-dark-dark`, `brand` outside any family, `warningInk`). Each must fail with a message that names the key. Task 1 tests this.
- **A hex typed into the sidecar** for the Impeccable panel, for example in a component's CSS. It must fail `--check`. Task 1 tests this.
- **An `Mx*` name in a screen spec or in `DESIGN.md` prose that the catalog lacks** (for example `MxScrollClearance`), and an `mx_*` golden for a planned component. `check.py` must fail on each. Task 6 tests this.

---

### Task 1: The design-token generator

**Files:**
- Create: `tools/design/generate.py`
- Test: `tools/design/test_generate.py`

**Interfaces:**
- Produces:
  - `python3 tools/design/generate.py --check | --write | --report`, run from the repo root;
  - `load(root: Path) -> Design`, `validate(design: Design) -> list[str]`,
    `emit(design: Design) -> dict[Path, str]`,
    `stale(root, design, fmt=dart_format) -> list[str]`, `write(root, design, fmt=dart_format) -> None`;
  - `M3_ROLES` (45 kebab names), `TEXT_THEME_SLOTS` (15);
  - `OUT_DIR = lib/core/theme/foundations`;
  - the generated Dart classes `AppColorSchemes`, `AppSemanticColors`, `AppTextStyles`, `AppSpacing`,
    `AppRadius`, `AppStroke`, `AppOpacity`, `AppBreakpoints`, `AppDurations`, `AppShadow`/`AppShadows`.
- Consumes: nothing from earlier tasks. The generated `AppTextStyles` imports
  `package:memox/core/theme/app_typography.dart`, which Task 3 creates.

- [ ] **Step 1: Write the failing tests**

Create `tools/design/test_generate.py`:

```python
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
```

Then add the Windows line-ending test to `FreshnessTest`:

```python
    def test_written_files_use_lf_only(self):
        root = Path(tempfile.mkdtemp())
        g.write(root, design(), identity)
        for path in (root / g.OUT_DIR).glob("*.dart"):
            self.assertNotIn(b"\r", path.read_bytes(), path.name)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 tools/design/test_generate.py`
Expected: `ModuleNotFoundError: No module named 'generate'`

- [ ] **Step 3: Write the generator**

Create `tools/design/generate.py`:

```python
#!/usr/bin/env python3
"""Generate the theme foundations from DESIGN.md (spec 2026-10-04-sp3a §3.2).

    python3 tools/design/generate.py --check    # the gate: validate, then fail if stale
    python3 tools/design/generate.py --write    # rewrite lib/core/theme/foundations/
    python3 tools/design/generate.py --report   # every contrast pair, both themes

Run from the repository root. DESIGN.md's frontmatter is the only place a colour
value is written by hand: every colour has a light key and a `-dark` key. The
sidecar (.impeccable/design.json `extensions`) holds only what the frontmatter
schema cannot: the semantic extension families, the contrast pairs, opacity,
stroke, motion, breakpoints and shadows. It holds no colour literal.

Exit code 1 when validation fails or, with --check, when the output is stale.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path


ROOT = Path.cwd()
DESIGN_MD = Path("DESIGN.md")
SIDECAR = Path(".impeccable/design.json")
OUT_DIR = Path("lib/core/theme/foundations")
HEADER = "// GENERATED by tools/design/generate.py from DESIGN.md — DO NOT EDIT.\n"

# The 45 non-deprecated colour roles of Flutter 3.47's ColorScheme, in its order.
_TONAL = ("", "on-{}", "{}-container", "on-{}-container", "{}-fixed", "{}-fixed-dim", "on-{}-fixed", "on-{}-fixed-variant")
M3_ROLES = [
    (f.format(p) if f else p) for p in ("primary", "secondary", "tertiary") for f in _TONAL
] + [
    "error", "on-error", "error-container", "on-error-container",
    "surface", "on-surface", "on-surface-variant", "surface-dim", "surface-bright",
    "surface-container-lowest", "surface-container-low", "surface-container",
    "surface-container-high", "surface-container-highest",
    "outline", "outline-variant", "shadow", "scrim",
    "inverse-surface", "on-inverse-surface", "inverse-primary",
]
TEXT_THEME_SLOTS = [
    f"{size}{scale}"
    for size in ("display", "headline", "title", "body", "label")
    for scale in ("Large", "Medium", "Small")
]
DARK = "-dark"
INK = re.compile(r"(?:^|-)ink(?:-|$)|[a-z0-9]Ink(?:[A-Z]|$)")
COLOUR_LITERAL = re.compile(r"#[0-9A-Fa-f]{3,8}\b|\brgba?\(", re.IGNORECASE)
HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")
TOKEN_REF = re.compile(r"^\{(colors|typography|rounded|spacing)\.([a-z0-9-]+)\}$")


@dataclass
class Design:
    colors: dict[str, str]
    typography: dict[str, dict]
    rounded: dict[str, str]
    spacing: dict[str, str]
    components: dict[str, dict]
    text_theme: dict[str, str]
    sidecar_text: str
    extensions: dict


def camel(kebab: str) -> str:
    head, *rest = kebab.split("-")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def px(value: object) -> float:
    return float(str(value).removesuffix("px"))


def number(value: float) -> str:
    """A Dart literal: `40`, `1.5`, `-0.64`."""
    return str(int(value)) if float(value).is_integer() else repr(float(value))


# ------------------------------------------------------------------ loading


def scalar(raw: str) -> object:
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "\"'":
        return raw[1:-1]
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return raw


def frontmatter(text: str) -> dict:
    """DESIGN.md's frontmatter: nested `key: value` maps indented by two spaces,
    scalars quoted or bare. That is all the design.md token schema uses, so no
    YAML library is needed."""
    if not text.startswith("---\n"):
        raise ValueError("DESIGN.md has no frontmatter")
    end = text.index("\n---\n", 4)
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    for number, line in enumerate(text[4:end].splitlines(), start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        key, sep, value = line.strip().partition(":")
        if not sep:
            raise ValueError(f"DESIGN.md:{number}: expected `key: value`")
        while indent <= stack[-1][0]:
            stack.pop()
        parent = stack[-1][1]
        if value.strip():
            parent[key.strip()] = scalar(value)
            continue
        child: dict = {}
        parent[key.strip()] = child
        stack.append((indent, child))
    return root


def table_under(text: str, heading: str) -> list[list[str]]:
    """Body rows of the first Markdown table after `heading` (a whole line)."""
    lines = text.splitlines()
    try:
        start = lines.index(heading)
    except ValueError:
        return []
    rows: list[list[str]] = []
    for line in lines[start + 1:]:
        if line.startswith("#"):
            break
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]
        if set("".join(cells)) <= set("-: "):
            continue
        rows.append(cells)
    return rows[1:]


def load(root: Path) -> Design:
    text = (root / DESIGN_MD).read_text(encoding="utf-8")
    front = frontmatter(text)
    sidecar_text = (root / SIDECAR).read_text(encoding="utf-8")
    sidecar = json.loads(sidecar_text)
    return Design(
        colors={str(k): str(v) for k, v in (front.get("colors") or {}).items()},
        typography=front.get("typography") or {},
        rounded=front.get("rounded") or {},
        spacing=front.get("spacing") or {},
        components=front.get("components") or {},
        text_theme={row[0]: row[1] for row in table_under(text, "### Text theme") if len(row) >= 2},
        sidecar_text=sidecar_text,
        extensions=sidecar.get("extensions") or {},
    )


# --------------------------------------------------------------- validation


def luminance(hex_colour: str) -> float:
    channels = [int(hex_colour[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(a: str, b: str) -> float:
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def base_keys(design: Design) -> list[str]:
    return [key for key in design.colors if not key.endswith(DARK)]


def validate(design: Design) -> list[str]:
    errors: list[str] = []
    colors = design.colors
    for key, value in colors.items():
        if not HEX.match(value):
            errors.append(f"colour `{key}` is `{value}`, not #RRGGBB")
        if INK.search(key.removesuffix(DARK)):
            errors.append(f"colour `{key}` is an ink role; the ink model is retired (A2, A11)")
    for key in base_keys(design):
        if key + DARK not in colors:
            errors.append(f"colour `{key}` has no `{key}{DARK}` value")
    for key in colors:
        if not key.endswith(DARK):
            continue
        light = key.removesuffix(DARK)
        if light.endswith(DARK):
            errors.append(f"colour `{key}` repeats `{DARK}`")
        elif light not in colors:
            errors.append(f"colour `{key}` has no light value `{light}`")
    for role in M3_ROLES:
        if role not in colors:
            errors.append(f"Material 3 role `{role}` is missing")

    families: dict[str, list[str]] = design.extensions.get("semanticExtensions") or {}
    members = {member for family in families.values() for member in family}
    for family, family_members in families.items():
        for member in family_members:
            if INK.search(member):
                errors.append(f"extension `{family}` member `{member}` is an ink role (A11)")
            if member not in colors:
                errors.append(f"extension `{family}` member `{member}` has no colour in DESIGN.md")
    for key in base_keys(design):
        if key not in M3_ROLES and key not in members:
            errors.append(f"colour `{key}` is neither a Material 3 role nor a declared extension member")

    if COLOUR_LITERAL.search(design.sidecar_text):
        errors.append(f"{SIDECAR} holds a colour literal; colour values live only in DESIGN.md (A3)")

    for pair in design.extensions.get("contrastPairs") or []:
        fg, bg, minimum = pair["fg"], pair["bg"], float(pair["min"])
        for theme, suffix in (("light", ""), ("dark", DARK)):
            a, b = colors.get(fg + suffix), colors.get(bg + suffix)
            if a is None or b is None or not HEX.match(a) or not HEX.match(b):
                errors.append(f"contrast pair `{fg}` on `{bg}` names an unknown colour")
                break
            ratio = contrast(a, b)
            if ratio < minimum:
                errors.append(f"contrast: `{fg}` on `{bg}` is {ratio:.2f}:1 in {theme}, below {minimum}:1")

    for slot in TEXT_THEME_SLOTS:
        role = design.text_theme.get(slot)
        if role is None:
            errors.append(f"TextTheme slot `{slot}` has no role in DESIGN.md `### Text theme`")
        elif role not in design.typography:
            errors.append(f"TextTheme slot `{slot}` names unknown typography role `{role}`")
    for slot in design.text_theme:
        if slot not in TEXT_THEME_SLOTS:
            errors.append(f"`### Text theme` names `{slot}`, which is not a TextTheme slot")

    groups = {"colors": colors, "typography": design.typography, "rounded": design.rounded, "spacing": design.spacing}
    for name, props in design.components.items():
        for prop, value in (props or {}).items():
            match = TOKEN_REF.match(str(value))
            if match and match.group(2) not in groups[match.group(1)]:
                errors.append(f"component `{name}` `{prop}` refers to unknown `{value}`")
    return errors


def report(design: Design) -> list[str]:
    lines = []
    for pair in design.extensions.get("contrastPairs") or []:
        fg, bg = pair["fg"], pair["bg"]
        light = contrast(design.colors[fg], design.colors[bg])
        dark = contrast(design.colors[fg + DARK], design.colors[bg + DARK])
        lines.append(f"{fg:32} on {bg:28} light {light:5.2f}  dark {dark:5.2f}  min {pair['min']}")
    return lines


# ----------------------------------------------------------------- emission


def colour(value: str) -> str:
    return f"Color(0xFF{value[1:].upper()})"


def emit_color_schemes(design: Design) -> str:
    def scheme(name: str, brightness: str, suffix: str) -> str:
        args = "".join(f"    {camel(role)}: {colour(design.colors[role + suffix])},\n" for role in M3_ROLES)
        return f"  static const ColorScheme {name} = ColorScheme(\n    brightness: Brightness.{brightness},\n{args}  );\n"

    return (
        HEADER + "import 'package:flutter/material.dart';\n\n"
        "/// The 45 Material 3 roles of each theme, from DESIGN.md.\n"
        "abstract final class AppColorSchemes {\n"
        + scheme("light", "light", "") + "\n" + scheme("dark", "dark", DARK) + "}\n"
    )


def emit_semantic_colors(design: Design) -> str:
    families: dict[str, list[str]] = design.extensions["semanticExtensions"]
    fields = [camel(member) for family in families.values() for member in family]
    kebab = [member for family in families.values() for member in family]

    def instance(name: str, suffix: str) -> str:
        args = "".join(f"    {camel(k)}: {colour(design.colors[k + suffix])},\n" for k in kebab)
        return f"  static const AppSemanticColors {name} = AppSemanticColors(\n{args}  );\n"

    ctor = "".join(f"    required this.{f},\n" for f in fields)
    decl = "".join(f"  final Color {f};\n" for f in fields)
    copy_params = "".join(f"    Color? {f},\n" for f in fields)
    copy_args = "".join(f"      {f}: {f} ?? this.{f},\n" for f in fields)
    lerp_args = "".join(f"      {f}: Color.lerp({f}, other.{f}, t)!,\n" for f in fields)
    return (
        HEADER + "import 'package:flutter/material.dart';\n\n"
        "/// MemoX semantic colours beside the Material 3 scheme (spec 2026-10-04-sp3a A2).\n"
        "@immutable\n"
        "final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {\n"
        f"  const AppSemanticColors({{\n{ctor}  }});\n\n"
        + instance("light", "") + "\n" + instance("dark", DARK) + "\n" + decl + "\n"
        "  @override\n"
        f"  AppSemanticColors copyWith({{\n{copy_params}  }}) {{\n    return AppSemanticColors(\n{copy_args}    );\n  }}\n\n"
        "  @override\n"
        "  AppSemanticColors lerp(AppSemanticColors? other, double t) {\n"
        "    if (other == null) {\n      return this;\n    }\n"
        f"    return AppSemanticColors(\n{lerp_args}    );\n  }}\n"
        "}\n"
    )


def emit_text_styles(design: Design) -> str:
    families = {str(spec["fontFamily"]) for spec in design.typography.values()}
    if len(families) != 1:
        raise ValueError(f"DESIGN.md typography uses {sorted(families)}; one family is expected")
    body = [f"  static const String family = '{families.pop()}';\n"]
    for role, spec in design.typography.items():
        args = ["fontFamily: family", f"fontSize: {number(px(spec['fontSize']))}"]
        if "lineHeight" in spec:
            args.append(f"height: {number(float(spec['lineHeight']))}")
        if "letterSpacing" in spec:
            args.append(f"letterSpacing: {number(px(spec['letterSpacing']))}")
        if spec.get("fontFeature") == "tnum":
            args.append("fontFeatures: <FontFeature>[FontFeature.tabularFigures()]")
        body.append(
            f"\n  static final TextStyle {camel(role)} = AppTypography.withWeight(\n"
            f"    const TextStyle({', '.join(args)}),\n"
            f"    FontWeight.w{int(spec['fontWeight'])},\n  );\n"
        )
    slots = "".join(f"    {slot}: {camel(design.text_theme[slot])},\n" for slot in TEXT_THEME_SLOTS)
    body.append(f"\n  static final TextTheme textTheme = TextTheme(\n{slots}  );\n")
    return (
        HEADER + "import 'package:flutter/material.dart';\n"
        "import 'package:memox/core/theme/app_typography.dart';\n\n"
        "/// DESIGN.md's typography roles and its TextTheme mapping.\n"
        "abstract final class AppTextStyles {\n" + "".join(body) + "}\n"
    )


def emit_scale(class_name: str, doc: str, values: dict[str, object], kind: str = "double") -> str:
    lines = []
    for name, value in values.items():
        if kind == "Duration":
            lines.append(f"  static const Duration {camel(name)} = Duration(milliseconds: {int(value)});\n")
        else:
            lines.append(f"  static const double {camel(name)} = {number(px(value))};\n")
    return HEADER + f"\n/// {doc}\nabstract final class {class_name} {{\n" + "".join(lines) + "}\n"


def emit_shadows(design: Design) -> str:
    shadows: dict[str, dict] = design.extensions["shadows"]
    lines = []
    for name, themes in shadows.items():
        for theme in ("light", "dark"):
            spec = themes.get(theme)
            field = f"{camel(name)}{theme.capitalize()}"
            if spec is None:
                lines.append(f"  static const AppShadow? {field} = null;\n")
                continue
            lines.append(
                f"  static const AppShadow {field} = AppShadow(dy: {number(spec['dy'])}, "
                f"blur: {number(spec['blur'])}, alpha: {number(spec['alpha'])});\n"
            )
    return (
        HEADER + "import 'package:flutter/material.dart';\n\n"
        "/// One named shadow: an offset, a blur and an alpha over the scheme's `shadow` role.\n"
        "@immutable\nfinal class AppShadow {\n"
        "  const AppShadow({required this.dy, required this.blur, required this.alpha});\n\n"
        "  final double dy;\n  final double blur;\n  final double alpha;\n\n"
        "  BoxShadow on(Color shadow) => BoxShadow(\n"
        "    color: shadow.withValues(alpha: alpha),\n    offset: Offset(0, dy),\n    blurRadius: blur,\n  );\n}\n\n"
        "/// DESIGN.md's shadow vocabulary; `null` where a theme draws none.\n"
        "abstract final class AppShadows {\n" + "".join(lines) + "}\n"
    )


def emit(design: Design) -> dict[Path, str]:
    ext = design.extensions
    return {
        OUT_DIR / "app_color_schemes.dart": emit_color_schemes(design),
        OUT_DIR / "app_semantic_colors.dart": emit_semantic_colors(design),
        OUT_DIR / "app_text_styles.dart": emit_text_styles(design),
        OUT_DIR / "app_spacing.dart": emit_scale("AppSpacing", "The spacing steps.", design.spacing),
        OUT_DIR / "app_radius.dart": emit_scale("AppRadius", "Corner radii.", design.rounded),
        OUT_DIR / "app_stroke.dart": emit_scale("AppStroke", "Stroke widths.", ext["stroke"]),
        OUT_DIR / "app_opacity.dart": emit_scale("AppOpacity", "Named opacities.", ext["opacity"]),
        OUT_DIR / "app_breakpoints.dart": emit_scale("AppBreakpoints", "Window-width breakpoints.", ext["breakpoints"]),
        OUT_DIR / "app_durations.dart": emit_scale("AppDurations", "Motion and dwell durations.", ext["motion"], "Duration"),
        OUT_DIR / "app_shadows.dart": emit_shadows(design),
    }


# ------------------------------------------------------------------ running

Formatter = Callable[[Path, str], str]


def dart_format(path: Path, source: str) -> str:
    dart = shutil.which("dart")
    if dart is None:
        raise RuntimeError("dart is not on PATH; the generator formats its output with `dart format`")
    result = subprocess.run(
        [dart, "format", f"--stdin-name={path.as_posix()}"],
        input=source, capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"dart format failed on {path}:\n{result.stderr}")
    return result.stdout


def stale(root: Path, design: Design, fmt: Formatter = dart_format) -> list[str]:
    expected = {path: fmt(path, source) for path, source in emit(design).items()}
    problems = []
    for path, source in expected.items():
        target = root / path
        if not target.exists():
            problems.append(f"{path} is missing; run tools/design/generate.py --write")
        elif target.read_text(encoding="utf-8") != source:
            problems.append(f"{path} is stale or edited by hand; run tools/design/generate.py --write")
    folder = root / OUT_DIR
    if folder.is_dir():
        for path in sorted(folder.glob("*.dart")):
            if path.relative_to(root) not in expected:
                problems.append(f"{path.relative_to(root)} is in the generated folder but not generated")
    return problems


def write(root: Path, design: Design, fmt: Formatter = dart_format) -> None:
    (root / OUT_DIR).mkdir(parents=True, exist_ok=True)
    for path, source in emit(design).items():
        (root / path).write_text(fmt(path, source), encoding="utf-8", newline="\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--report", action="store_true")
    args = parser.parse_args(argv)
    design = load(ROOT)
    errors = validate(design)
    for error in errors:
        print(f"ERROR {error}")
    if errors:
        return 1
    if args.report:
        print("\n".join(report(design)))
        return 0
    if args.write:
        write(ROOT, design)
        print(f"wrote {len(emit(design))} files to {OUT_DIR}")
        return 0
    problems = stale(ROOT, design)
    for problem in problems:
        print(f"ERROR {problem}")
    if problems:
        return 1
    print("PASS — design tokens are valid and the generated theme is fresh")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 tools/design/test_generate.py`
Expected: `Ran 31 tests … OK`

- [ ] **Step 5: Commit**

```bash
git add tools/design/generate.py tools/design/test_generate.py
git commit -m "feat(sp3a): the design-token generator — DESIGN.md is the only source of a value"
```

---

### Task 2: Structured data in `DESIGN.md` and a colour-free sidecar (owner checkpoint)

**Files:**
- Modify: `DESIGN.md` (frontmatter `colors`, `components.button-destructive`, `## Colors`, `### Text theme`)
- Modify: `.impeccable/design.json`

**Interfaces:**
- Consumes: `tools/design/generate.py --report` (Task 1).
- Produces:
  - 66 colour tokens, each with its `-dark` twin: the 45 M3 roles plus 21 extension members;
  - the `semanticExtensions`, `contrastPairs` (75), `opacity`, `stroke`, `motion`,
    `breakpoints` and `shadows` keys that Task 3's generation reads.

- [ ] **Step 1: Replace the frontmatter `colors:` block**

In `DESIGN.md`, replace everything from the line `colors:` up to (not including) the line
`typography:` with:

```yaml
colors:
  primary: "#4151C6"
  primary-dark: "#AAB4FF"
  on-primary: "#FFFFFF"
  on-primary-dark: "#141C66"
  primary-container: "#E0E5FE"
  primary-container-dark: "#2D346A"
  on-primary-container: "#1A2580"
  on-primary-container-dark: "#D9DFFF"
  primary-fixed: "#E0E5FE"
  primary-fixed-dark: "#E0E5FE"
  primary-fixed-dim: "#BAC3FF"
  primary-fixed-dim-dark: "#BAC3FF"
  on-primary-fixed: "#0B1366"
  on-primary-fixed-dark: "#0B1366"
  on-primary-fixed-variant: "#2D3A9E"
  on-primary-fixed-variant-dark: "#2D3A9E"
  secondary: "#5560B8"
  secondary-dark: "#9DA8E8"
  on-secondary: "#FFFFFF"
  on-secondary-dark: "#1B2257"
  secondary-container: "#E3E6F7"
  secondary-container-dark: "#343C78"
  on-secondary-container: "#262E6E"
  on-secondary-container-dark: "#DDE2FB"
  secondary-fixed: "#E3E6F7"
  secondary-fixed-dark: "#E3E6F7"
  secondary-fixed-dim: "#C1C7EC"
  secondary-fixed-dim-dark: "#C1C7EC"
  on-secondary-fixed: "#141A4D"
  on-secondary-fixed-dark: "#141A4D"
  on-secondary-fixed-variant: "#3A4390"
  on-secondary-fixed-variant-dark: "#3A4390"
  tertiary: "#6A4BD8"
  tertiary-dark: "#B5A0FF"
  on-tertiary: "#FFFFFF"
  on-tertiary-dark: "#2A1470"
  tertiary-container: "#EBE3FE"
  tertiary-container-dark: "#443078"
  on-tertiary-container: "#33177E"
  on-tertiary-container-dark: "#E6DCFF"
  tertiary-fixed: "#EBE3FE"
  tertiary-fixed-dark: "#EBE3FE"
  tertiary-fixed-dim: "#CFC0FF"
  tertiary-fixed-dim-dark: "#CFC0FF"
  on-tertiary-fixed: "#1F0A55"
  on-tertiary-fixed-dark: "#1F0A55"
  on-tertiary-fixed-variant: "#4B30A8"
  on-tertiary-fixed-variant-dark: "#4B30A8"
  error: "#C02447"
  error-dark: "#FF8FA3"
  on-error: "#FFFFFF"
  on-error-dark: "#5C0A1E"
  error-container: "#FBDDE3"
  error-container-dark: "#7A2036"
  on-error-container: "#7A0A23"
  on-error-container-dark: "#FFD9DF"
  surface: "#F7F9FE"
  surface-dark: "#0A0E27"
  on-surface: "#0F1638"
  on-surface-dark: "#E4E8FA"
  on-surface-variant: "#4A5278"
  on-surface-variant-dark: "#A4ACD0"
  surface-dim: "#D5DBEA"
  surface-dim-dark: "#0A0E27"
  surface-bright: "#FFFFFF"
  surface-bright-dark: "#2A3266"
  surface-container-lowest: "#FFFFFF"
  surface-container-lowest-dark: "#131A3A"
  surface-container-low: "#F1F4FB"
  surface-container-low-dark: "#1B2249"
  surface-container: "#E9EDF7"
  surface-container-dark: "#232B5A"
  surface-container-high: "#E2E7F3"
  surface-container-high-dark: "#2C356E"
  surface-container-highest: "#DAE0EF"
  surface-container-highest-dark: "#353D7E"
  outline: "#717AA0"
  outline-dark: "#7D8AC1"
  outline-variant: "#C5CBE3"
  outline-variant-dark: "#2A3267"
  shadow: "#0F1638"
  shadow-dark: "#000000"
  scrim: "#0A0E27"
  scrim-dark: "#000000"
  inverse-surface: "#34395D"
  inverse-surface-dark: "#34395D"
  on-inverse-surface: "#E8EAFC"
  on-inverse-surface-dark: "#E8EAFC"
  inverse-primary: "#AAB4FF"
  inverse-primary-dark: "#AAB4FF"
  success: "#176B57"
  success-dark: "#5FD3B4"
  on-success: "#FFFFFF"
  on-success-dark: "#06362A"
  success-container: "#D5F2E9"
  success-container-dark: "#14473A"
  on-success-container: "#0B3B2F"
  on-success-container-dark: "#C9F5E7"
  warning: "#895806"
  warning-dark: "#F5B13D"
  on-warning: "#FFFFFF"
  on-warning-dark: "#3A2A00"
  warning-container: "#FCEFC7"
  warning-container-dark: "#4A3610"
  on-warning-container: "#3A2A00"
  on-warning-container-dark: "#FCE6B8"
  status-new: "#5A6283"
  status-new-dark: "#A4ACD0"
  status-new-container: "#E6E8F0"
  status-new-container-dark: "#2B3256"
  on-status-new-container: "#2B3150"
  on-status-new-container-dark: "#DDE1F2"
  status-learning: "#895806"
  status-learning-dark: "#F5B13D"
  status-learning-container: "#FCEFC7"
  status-learning-container-dark: "#4A3610"
  on-status-learning-container: "#3A2A00"
  on-status-learning-container-dark: "#FCE6B8"
  status-reviewing: "#4151C6"
  status-reviewing-dark: "#AAB4FF"
  status-reviewing-container: "#E0E5FE"
  status-reviewing-container-dark: "#2D346A"
  on-status-reviewing-container: "#1A2580"
  on-status-reviewing-container-dark: "#D9DFFF"
  status-mastered: "#1A6B48"
  status-mastered-dark: "#6FE0BD"
  status-mastered-container: "#D3F0E2"
  status-mastered-container-dark: "#134733"
  on-status-mastered-container: "#0A3B25"
  on-status-mastered-container-dark: "#C6F5E2"
  streak: "#E8620C"
  streak-dark: "#FB8A3C"
```

- [ ] **Step 2: Point the destructive button at `error`**

In the frontmatter, under `components:` → `button-destructive:`, change
`backgroundColor: "{colors.error-fill}"` to `backgroundColor: "{colors.error}"` and
`textColor: "{colors.on-error-fill}"` to `textColor: "{colors.on-error}"`.

- [ ] **Step 3: Replace the `## Colors` section**

Replace everything from the line `## Colors` up to (not including) the line `## Typography`
with:

```markdown
## Colors

A cool indigo-tinted neutral field with one brand indigo, one reserved violet, and greens that only ever mean progress or success. Every colour has a light value and a `-dark` value in the frontmatter, the only place a colour value is written. `tools/design/generate.py` turns them into the two `ColorScheme`s and `AppSemanticColors`, and checks every pair in `.impeccable/design.json` `contrastPairs` in both themes (spec 2026-10-04-sp3a A2, A3).

### The model
- Material 3 roles keep their meaning. A role is text or a glyph on a surface wherever it holds its floor on that surface; the generator proves each declared pair.
- Content on a coloured surface uses the role's pair: `X` → `on-X`, `X-container` → `on-X-container`. `on-X` is never a text colour on a plain surface.
- MemoX adds semantic extensions on the same model, with only the members a consumer uses. There is no separate ink palette and no colour derived at paint time.

### Primary
- **Brand Indigo** (`primary`, #4151C6; dark #AAB4FF): the fill of primary buttons, the FAB, the selected filter chip and progress fills, under `on-primary`; and indigo text, links, icons and the 2dp focus ring on any surface.
- **Indigo Wash** (`primary-container`, `on-primary-container`): quiet selected and informational grounds.
- **Fixed tones** (`primary-fixed`, `primary-fixed-dim`, `on-primary-fixed`, `on-primary-fixed-variant`, and the same for secondary and tertiary): identical in both themes, for a surface that must not follow the theme.

### Secondary
- **Soft Periwinkle** (`secondary`, `secondary-container`): supporting tonal role; rarely painted directly.

### Tertiary
- **Meaningful Violet** (`tertiary`, `tertiary-container`): the reserved accent. Never used for status and never for mastery.

### Neutral
- **Pure Light Page** (`surface`, #F7F9FE): the screen ground. Dark: #0A0E27 (Nebula Night).
- **Raised White** (`surface-container-lowest`): cards, list rows, chips.
- **Muted Fill** (`surface-container-low`): text-field fill at rest, the progress track, navigation rail ground, recessed study face.
- **Sheet Ground** (`surface-container-high`): dialogs and bottom sheets.
- **On Surface** (`on-surface`) and **Variant Text** (`on-surface-variant`): primary and secondary text.
- **Outline** (`outline`): control edges, the outline button's edge included; 3:1 on the page, row, low and sheet grounds in both themes. **Outline Variant** (`outline-variant`): dividers and the everyday 1px hairline.
- **Inverse Surface** (`inverse-surface`, #34395D): the snackbar ground, identical in both themes, with `on-inverse-surface` text and `inverse-primary` for its action.
- **Shadow** (`shadow`) and **Scrim** (`scrim`): the colours every named shadow and the modal scrim are built on.

### Semantic
- **Error** (`error`, `on-error`, `error-container`, `on-error-container`): danger is Material's error. `error` is error text and glyphs, and the destructive button's fill under `on-error`; the danger ground is `error-container` under `on-error-container`.
- **Success** (`success`, `on-success`, `success-container`, `on-success-container`): a right answer and a finished, fine state. Never mastery.
- **Warning** (`warning`, `on-warning`, `warning-container`, `on-warning-container`): a refusal or a limit where nothing was lost. The warning button's fill under `on-warning`, warning text and glyphs, and the warning ground.
- **Status** (`status-new`, `status-learning`, `status-reviewing`, `status-mastered`, each with `-container` and `on-…-container`): a card's learning status as a label, a dot or a progress fill, and as a badge on its container. Mastery is `status-mastered`.
- **Streak** (`streak`): the Progress flame only; a fill, with no text counterpart.

### Named Rules
**The One Indigo Rule.** Indigo means "act". A primary fill appears once per decision; the rest of the screen is neutral. An action in an `MxInlineBanner` or `MxFloatingNotice`, and the action in an `MxFooterBar`, is primary only when the screen shows no other primary for the same decision; otherwise it is outline or secondary (Sync's refused rows, an open session on Study entry, Study home's sync notice). A lone Close stays primary: one primary per decision holds (critique 2026-09-30 part 1, R8).

**The Green Means Progress Rule.** Green is `status-mastered` or `success` and nothing else. Violet is never a status; green is never decoration.

**The Role On Its Ground Rule.** A colour is a semantic role used on a ground it was checked against. Text and glyphs use a role that holds 4.5:1 on that ground; content on a coloured fill or container uses that role's `on-` pair. There is no fill palette beside an ink palette, and no colour derived at paint time.

**The Contrast Floor Rule.** Text and glyphs hold 4.5:1 and non-text (edges, thumbs, progress fill on its track, grabber) hold 3:1, on page, row, low and sheet grounds, in both themes. A role that fails is changed here; nothing patches it with a darker copy.
```

- [ ] **Step 4: Add the `### Text theme` table**

Insert this block directly before the line `## Layout`. It goes after the Typography section's
`### Named Rules` paragraph and is followed by a blank line:

```markdown
### Text theme

| M3 slot | Role |
|---|---|
| displayLarge | stat |
| displayMedium | display |
| displaySmall | display |
| headlineLarge | headline |
| headlineMedium | headline |
| headlineSmall | title |
| titleLarge | title |
| titleMedium | body-large |
| titleSmall | button-label |
| bodyLarge | body-large |
| bodyMedium | body |
| bodySmall | caption |
| labelLarge | button-label |
| labelMedium | section-label |
| labelSmall | caption |
```

Then add one sentence directly under the `### Text theme` heading:
`Each Material 3 TextTheme slot takes one role above; tools/design/generate.py reads this table, so no slot falls back to a Flutter default.`

- [ ] **Step 5: Rewrite the sidecar**

Save this one-off script as `$SCRATCH/rewrite_sidecar.py`, where `$SCRATCH` is the session's
scratchpad (it is not committed). Run it from the repo root: `python3 $SCRATCH/rewrite_sidecar.py`.

```python
"""One-off (SP3a Phase 1, Task 2): strip every colour literal from the sidecar and
give it the machine-readable extensions tools/design/generate.py reads."""
import json
import re
from pathlib import Path

path = Path(".impeccable/design.json")
data = json.loads(path.read_text(encoding="utf-8"))
ext = data["extensions"]
ext.pop("colorMeta")  # light/dark hex values: DESIGN.md is their only home (A3)

TOKEN_OF_HEX = {
    "#5265F5": "primary", "#4151C6": "primary", "#FFFFFF": "on-primary", "#0F1638": "on-surface",
    "#4A5278": "on-surface-variant", "#C5CBE3": "outline-variant", "#DC2D4E": "error",
    "#E9EDF7": "surface-container", "#F1F4FB": "surface-container-low",
}


def no_literal(text: str) -> str:
    text = re.sub(r"rgba\(15,22,56,([0-9.]+)\)",
                  lambda m: f"color-mix(in srgb, var(--color-shadow) {round(float(m.group(1)) * 100)}%, transparent)", text)
    text = text.replace("rgba(82,101,245,0.14)", "var(--color-outline-variant)")
    text = re.sub(r"#fff\b", "var(--color-on-primary)", text, flags=re.IGNORECASE)
    return re.sub(r"#[0-9A-Fa-f]{6}\b", lambda m: f"var(--color-{TOKEN_OF_HEX[m.group(0).upper()]})", text)


for component in data["components"]:
    for key in ("css", "html", "description"):
        component[key] = no_literal(component[key])

STATUSES = ("new", "learning", "reviewing", "mastered")
ext["semanticExtensions"] = {
    "success": ["success", "on-success", "success-container", "on-success-container"],
    "warning": ["warning", "on-warning", "warning-container", "on-warning-container"],
    **{f"status-{s}": [f"status-{s}", f"status-{s}-container", f"on-status-{s}-container"] for s in STATUSES},
    "streak": ["streak"],
}
GROUNDS = ("surface", "surface-container-lowest", "surface-container-low", "surface-container-high")
pairs = []
for fg, use in (
    ("on-surface", "body text"), ("on-surface-variant", "secondary text"),
    ("primary", "primary text, icon, link and focus ring"), ("error", "error text and icon"),
    ("success", "success text and icon"), ("warning", "warning text and icon"),
    *((f"status-{s}", "status label") for s in STATUSES),
):
    pairs += [{"fg": fg, "bg": g, "min": 4.5, "use": use} for g in GROUNDS]
for role in ("primary", "secondary", "tertiary", "error", "success", "warning"):
    pairs.append({"fg": f"on-{role}", "bg": role, "min": 4.5, "use": f"content on a {role} fill"})
    pairs.append({"fg": f"on-{role}-container", "bg": f"{role}-container", "min": 4.5, "use": f"content on a {role} container"})
for s in STATUSES:
    pairs.append({"fg": f"on-status-{s}-container", "bg": f"status-{s}-container", "min": 4.5, "use": "status badge"})
for role in ("primary", "secondary", "tertiary"):
    pairs += [
        {"fg": f"on-{role}-fixed", "bg": f"{role}-fixed", "min": 4.5, "use": "content on a fixed tone"},
        {"fg": f"on-{role}-fixed", "bg": f"{role}-fixed-dim", "min": 4.5, "use": "content on a fixed tone"},
        {"fg": f"on-{role}-fixed-variant", "bg": f"{role}-fixed", "min": 4.5, "use": "content on a fixed tone"},
    ]
pairs += [
    {"fg": "on-inverse-surface", "bg": "inverse-surface", "min": 4.5, "use": "snackbar text"},
    {"fg": "inverse-primary", "bg": "inverse-surface", "min": 4.5, "use": "snackbar action"},
]
pairs += [{"fg": "outline", "bg": g, "min": 3.0, "use": "control edge"} for g in GROUNDS]
pairs += [{"fg": f"status-{s}", "bg": "surface-container-low", "min": 3.0, "use": "progress fill on its track"}
          for s in ("learning", "reviewing", "mastered")]
pairs.append({"fg": "streak", "bg": "surface-container-lowest", "min": 3.0, "use": "streak flame on a card"})
ext["contrastPairs"] = pairs
ext["opacity"] = {"disabled": 0.38, "muted": 0.7, "pressed": 0.12, "scrim": 0.45, "glass": 0.84,
                  "skeleton-low": 0.45, "skeleton-high": 0.75}
ext["stroke"] = {"hairline": 1, "control": 2, "focus": 2, "indicator": 6}
ext["motion"] = {"toggle": 160, "standard": 200, "scrim-fade": 220, "sheet": 260, "settle": 400,
                 "spinner-cycle": 800, "skeleton-pulse": 1400, "toast": 4000, "toast-with-undo": 8000}
ext["breakpoints"] = {"nav-rail": 600, "content-max": 720}
ext["shadows"] = {
    "whisper": {"light": {"dy": 1, "blur": 2, "alpha": 0.04}, "dark": None},
    "chrome": {"light": {"dy": -2, "blur": 12, "alpha": 0.05}, "dark": {"dy": -2, "blur": 14, "alpha": 0.36}},
    "overlay": {"light": {"dy": 12, "blur": 32, "alpha": 0.10}, "dark": {"dy": 16, "blur": 40, "alpha": 0.42}},
    "fab": {"light": {"dy": 8, "blur": 24, "alpha": 0.12}, "dark": {"dy": 10, "blur": 28, "alpha": 0.5}},
}
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
print(f"{len(pairs)} contrast pairs")
```

Expected: `75 contrast pairs`.

- [ ] **Step 6: Validate and print the contrast report**

Run: `python3 tools/design/generate.py --report > $SCRATCH/contrast-report.txt; echo $?`
Expected: exit `0`, no `ERROR` line, 75 rows. Every `light` and `dark` column is at or above
its `min`.

Run: `grep -cP '#[0-9A-Fa-f]{3,8}\b|rgba?\(' .impeccable/design.json`
Expected: `0`.

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`

- [ ] **Step 7: Commit**

```bash
git add DESIGN.md .impeccable/design.json
git commit -m "docs(sp3a): DESIGN.md holds every light and dark role; the sidecar holds no colour (A2, A3)"
```

- [ ] **Step 8: Owner checkpoint**

Stop here. Through the `AskUserQuestion` popup, give the owner:
- the `DESIGN.md` diff of this task;
- `$SCRATCH/contrast-report.txt`;
- the four deviations listed at the top of this plan.

The owner approves, or changes values. A change goes into `DESIGN.md`, then Step 6 runs again,
then it is committed. Task 3 does not start before approval: generated code follows the
approved values (spec §6, step 2).

---

### Task 3: Generated foundations, `AppTypography`, `AppTheme` and the parity test

**Files:**
- Create (generated by `--write`): `lib/core/theme/foundations/app_color_schemes.dart`,
  `app_semantic_colors.dart`, `app_text_styles.dart`, `app_spacing.dart`, `app_radius.dart`,
  `app_stroke.dart`, `app_opacity.dart`, `app_breakpoints.dart`, `app_durations.dart`, `app_shadows.dart`
- Create: `lib/core/theme/app_typography.dart`, `lib/core/theme/app_theme.dart`
- Create: `test/core/theme/app_theme_test.dart`
- Modify: `lib/app/app.dart` (import, the `theme:` and `darkTheme:` arguments, the class doc)
- Modify: `test/app/app_appearance_test.dart` (one assertion)
- Modify: `pubspec.yaml:68-69` (comment only)

**Interfaces:**
- Consumes: Task 1's generator and Task 2's data.
- Produces:
  - `AppTheme.light()` and `AppTheme.dark()`, each returning `ThemeData`;
  - `AppTypography.withWeight(TextStyle, FontWeight) -> TextStyle`;
  - `AppColorSchemes.light` and `.dark`;
  - `AppSemanticColors.light` and `.dark`;
  - `AppTextStyles.family` and `AppTextStyles.textTheme`.

- [ ] **Step 1: Write the failing parity test**

Create `test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';

void main() {
  final Map<String, (ThemeData, ColorScheme, AppSemanticColors)> themes = {
    'light': (AppTheme.light(), AppColorSchemes.light, AppSemanticColors.light),
    'dark': (AppTheme.dark(), AppColorSchemes.dark, AppSemanticColors.dark),
  };

  for (final MapEntry(key: name, value: (theme, scheme, semantic))
      in themes.entries) {
    group('$name theme', () {
      test('carries the generated colour scheme, role for role', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, scheme);
        expect(theme.colorScheme.brightness, scheme.brightness);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
      });

      test('carries the generated semantic colours', () {
        expect(theme.extension<AppSemanticColors>(), semantic);
      });

      test('fills every TextTheme slot from the generated styles', () {
        final TextTheme generated = AppTextStyles.textTheme;
        final List<(TextStyle?, TextStyle?)> slots = [
          (theme.textTheme.displayLarge, generated.displayLarge),
          (theme.textTheme.displayMedium, generated.displayMedium),
          (theme.textTheme.displaySmall, generated.displaySmall),
          (theme.textTheme.headlineLarge, generated.headlineLarge),
          (theme.textTheme.headlineMedium, generated.headlineMedium),
          (theme.textTheme.headlineSmall, generated.headlineSmall),
          (theme.textTheme.titleLarge, generated.titleLarge),
          (theme.textTheme.titleMedium, generated.titleMedium),
          (theme.textTheme.titleSmall, generated.titleSmall),
          (theme.textTheme.bodyLarge, generated.bodyLarge),
          (theme.textTheme.bodyMedium, generated.bodyMedium),
          (theme.textTheme.bodySmall, generated.bodySmall),
          (theme.textTheme.labelLarge, generated.labelLarge),
          (theme.textTheme.labelMedium, generated.labelMedium),
          (theme.textTheme.labelSmall, generated.labelSmall),
        ];
        for (final (built, source) in slots) {
          expect(source, isNotNull);
          expect(built!.fontFamily, AppTextStyles.family);
          expect(built.fontSize, source!.fontSize);
          expect(built.fontWeight, source.fontWeight);
          expect(built.fontVariations, source.fontVariations);
          expect(built.height, source.height);
          expect(built.letterSpacing, source.letterSpacing);
          expect(built.color, scheme.onSurface);
        }
      });

      test('pads every tap target to 48', () {
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });
    });
  }
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: FAIL. The import `package:memox/core/theme/app_theme.dart` is not found.

- [ ] **Step 3: Write `AppTypography`**

Create `lib/core/theme/app_typography.dart`:

```dart
import 'package:flutter/material.dart';

/// Re-weights a style on the bundled variable font.
abstract final class AppTypography {
  /// Sets [weight] and moves the variable font's `wght` axis with it, so the
  /// style reports the weight it paints.
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(
      fontWeight: weight,
      fontVariations: <FontVariation>[
        FontVariation.weight(weight.value.toDouble()),
      ],
    );
  }
}
```

- [ ] **Step 4: Generate the foundations**

Run: `python3 tools/design/generate.py --write`
Expected: `wrote 10 files to lib/core/theme/foundations`

Run: `python3 tools/design/generate.py --check`
Expected: `PASS — design tokens are valid and the generated theme is fresh`

- [ ] **Step 5: Write `AppTheme`**

Create `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';

/// The light and dark themes, built only from the generated foundations
/// (spec 2026-10-04-sp3a §3.3). Component themes join in the phase that
/// builds their `Mx*`.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(AppColorSchemes.light, AppSemanticColors.light);

  static ThemeData dark() =>
      _build(AppColorSchemes.dark, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final TextTheme textTheme = AppTextStyles.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppTextStyles.family,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      splashColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      extensions: <AppSemanticColors>[semantic],
    );
  }
}
```

- [ ] **Step 6: Run the parity test**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: 8 tests pass.

- [ ] **Step 7: Wire the themes into `MemoxApp`**

In `lib/app/app.dart`:
- Add `import 'package:memox/core/theme/app_theme.dart';` after the
  `package:memox/core/logging/di/logging_providers.dart` import.
- Replace `theme: ThemeData(useMaterial3: true),` with `theme: AppTheme.light(),`.
- Replace `darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),` with
  `darkTheme: AppTheme.dark(),`.
- In the class doc, replace
  `The themes are Flutter's\n/// Material 3 defaults until SP3a rebuilds them from DESIGN.md.` with
  `The themes are\n/// generated from DESIGN.md (SP3a); the placeholder shell paints on them until SP3b.`

In `test/app/app_appearance_test.dart`, in the test
`'the first frame already paints the stored theme (FE-A3 D5)'`, add this line after
`expect(_brightness(tester), Brightness.dark);`:

```dart
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).colorScheme,
      AppColorSchemes.dark,
    );
```

Also add `import 'package:memox/core/theme/foundations/app_color_schemes.dart';` to the
test's imports, in sorted order.

In `pubspec.yaml`, replace the comment line
`# AppTypography.withWeight, which moves the axis with fontWeight.` with
`# AppTypography.withWeight (lib/core/theme/app_typography.dart), which moves the axis with fontWeight.`

- [ ] **Step 8: Verify**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/app`
Expected: all pass.

Run: `flutter analyze --no-fatal-infos`
Expected: `No issues found!`

Run: `python3.13 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8`
Use any Python with `typer`; on Windows, `py -3.13`.
Expected: `Code verification passed.` with 0 errors.

The guard rejects `ThemeExtension<dynamic>` (`dart.no_dynamic_usage`). That is why
`AppTheme` passes `extensions: <AppSemanticColors>[semantic]`; keep it that way.

- [ ] **Step 9: Commit**

```bash
git add lib/core/theme test/core/theme lib/app/app.dart test/app/app_appearance_test.dart pubspec.yaml
git commit -m "feat(sp3a): light and dark themes generated from DESIGN.md, wired into MemoxApp"
```

---

### Task 4: The component catalog and the renames

**Files:**
- Modify: `DESIGN.md` (insert `### Catalog` and `### Contracts`; renames in prose)
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml:84,91,137`
- Modify: `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py:78,81`
- Modify: `.claude/skills/flutter-theme-design/SKILL.md:106`
- Modify: `.claude/skills/flutter-theme-design/references/pickers-progress-tabs.md:118`

**Interfaces:**
- Produces: the catalog that Task 6's `design_catalog.parse` reads. It has 57 rows under
  `### Catalog`, all `planned`. Each row has 6 cells: Component, Purpose, Layer, Consumers,
  Owner phase, Status. The `### Contracts` section is empty.

- [ ] **Step 1: Insert the catalog**

In `DESIGN.md`, insert this block directly before the line `## Do's and Don'ts` (it ends the
`## Components` section):

```markdown
### Catalog

The canonical list of components (spec 2026-10-04-sp3a §4, A6). `Layer` is `primitive`, `shared`,
`app-shell`, `product-semantic` or `feature:<domain>`; only `primitive`, `shared` and `app-shell`
names carry `Mx`. `Consumers` are screen domains, SCR ids or other components, taken from the
screen specs. `Status` is `planned`, `implementing`, `built` or `deprecated`. A component leaves
`planned` only with a contract under [Contracts](#contracts); `tools/docs/check.py` enforces both.

| Component | Purpose | Layer | Consumers | Owner phase | Status |
|---|---|---|---|---|---|
| MxRowInk | Shared row ripple and press | primitive | MxListRow, MxSettingsRow, MxOptionRow, MxActionSheetCommandRow | SP3a | planned |
| MxButton | Text-labelled action in seven tones and five sizes | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxIconButton | Icon-only action with a 48 target | shared | CARD, DECK, MONITORING, STARTER, STUDY, TAG, TRASH | SP3a | planned |
| MxFab | Floating primary action, icon only | shared | CARD, DECK | SP3a | planned |
| MxSpinner | Indeterminate wait in four sizes | shared | ACCOUNT, CARD, DECK, MONITORING, REMINDER, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER | SP3a | planned |
| MxTextField | Text input in six variants | shared | ACCOUNT, CARD, DECK, MONITORING, SEARCH, STARTER, STUDY, TAG, TRANSFER | SP3a | planned |
| MxFieldMessage | Error or warning line under a field | shared | ACCOUNT, CARD, DECK, TAG | SP3a | planned |
| MxSearchField | Search input, or a trigger that opens search | shared | ACCOUNT, CARD, DECK, SEARCH, TAG | SP3a | planned |
| MxToggle | On/off switch | shared | ACCOUNT, DECK, MONITORING, PROGRESS, REMINDER, SETTINGS, SRS, TRANSFER | SP3a | planned |
| MxOptionRow | Single-choice radio row | shared | ACCOUNT, DECK, MONITORING, SETTINGS, SRS, STARTER, STUDY, TRANSFER | SP3a | planned |
| MxSelectionCheckbox | Multi-select mark | shared | CARD, TRASH | SP3a | planned |
| MxStepper | Bounded integer with press-and-hold repeat | shared | REMINDER, SETTINGS | SP3a | planned |
| MxSegmentedTray | One of a few segments | shared | MONITORING, PROGRESS, SETTINGS | SP3a | planned |
| MxFilterChip | Filter toggle chip | shared | CARD, TRASH | SP3a | planned |
| MxChipTrigger | Ghost chip that opens a menu or sheet | shared | CARD, DECK, MONITORING, TRANSFER | SP3a | planned |
| MxCard | Raised surface in six tones | shared | CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxSection | Section label over a card | shared | ACCOUNT, CARD, DECK, MONITORING, REMINDER, SETTINGS, STUDY, TAG, TRANSFER | SP3a | planned |
| MxNote | One calm information line, or its footnote form | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxBadge | Short label in a semantic tone | shared | ACCOUNT, CARD, DECK, MONITORING, SEARCH, STARTER, STUDY, TRANSFER, TRASH | SP3a | planned |
| MxStatusBadge | A card's learning status | shared | CARD, MONITORING | SP3a | planned |
| MxTagChip | A tag name | shared | CARD, SEARCH | SP3a | planned |
| MxIconTile | Icon on a toned tile in three sizes | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRASH | SP3a | planned |
| MxLinearProgress | Determinate bar: value, tone, size; knows no mastery | shared | DECK, STUDY | SP3a | planned |
| MxDialog | Modal decision | shared | ACCOUNT, CARD, DECK, REMINDER, SETTINGS, SRS, STARTER, STUDY, TAG, TRASH | SP3a | planned |
| MxBottomSheet | Modal sheet with a grabber, a pinned header and footer | shared | ACCOUNT, CARD, DECK, MONITORING, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxSheetActions | Dialog and sheet footer actions | shared | ACCOUNT, CARD, DECK, MONITORING, REMINDER, SETTINGS, SRS, STARTER, TAG, TRANSFER, TRASH | SP3a | planned |
| MxSnackbar | Transient message with one optional action | shared | ACCOUNT, CARD, DECK, MONITORING, REMINDER, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxInlineBanner | Warning or danger banner owned by its screen | shared | ACCOUNT, CARD, DECK, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TRANSFER, TRASH | SP3a | planned |
| MxEmptyState | Nothing here yet, and what to do | shared | ACCOUNT, CARD, DECK, SEARCH, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxErrorState | Inline load failure with Retry, or not found | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRASH | SP3a | planned |
| MxSkeleton | Loading placeholder family | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRASH | SP3a | planned |
| MxScreenScaffold | Screen frame: app-bar slot, one body, footer slot, FAB slot; not the navigation shell | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxScreenScroll | The screen's scroll body with tail clearance | shared | ACCOUNT, CARD, MONITORING, PROGRESS, STUDY, TRANSFER, TRASH | SP3a | planned |
| MxAppBar | Top bar in two densities | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxBreadcrumb | Path of presentation-neutral items; knows no deck | shared | CARD, DECK, PROGRESS, SETTINGS, SRS, STUDY | SP3a | planned |
| MxFooterBar | In-flow commit bar | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, SEARCH, SETTINGS, STUDY, TRANSFER, TRASH | SP3a | planned |
| MxListRow | List row, 48 minimum, two title lines | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, REMINDER, SEARCH, SETTINGS, SRS, STARTER, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxSettingsRow | Settings row with a trailing value or control | shared | DECK, REMINDER, SETTINGS | SP3a | planned |
| MxListSectionHeader | Header over a list | shared | ACCOUNT, CARD, DECK, MONITORING, PROGRESS, SEARCH, SETTINGS, SRS, STUDY, TAG, TRANSFER, TRASH | SP3a | planned |
| MxActionSheetCommandRow | Command row of an action sheet | shared | ACCOUNT, CARD, DECK, SETTINGS, SRS, TAG, TRASH | SP3a | planned |
| AppNavigationShell | The four-tab navigation shell | app-shell | SCR-DECK-001, SCR-STUDY-001, SCR-PROGRESS-001, SCR-SETTINGS-002 | SP3b | planned |
| MxBottomNav | Bottom bar of the navigation shell | app-shell | AppNavigationShell | SP3b | planned |
| MxNavRail | Navigation rail from 600dp | app-shell | AppNavigationShell | SP3b | planned |
| MasteryRamp | Mastery percentage to its status tone, on MxLinearProgress | product-semantic | CARD, DECK | SP3b | planned |
| MasteryDonut | A level's mastery as a ring | product-semantic | CARD, DECK | SP3b | planned |
| WorkloadBreakdownLine | Overdue, today and new, one colour each | product-semantic | DECK, STUDY | SP3b | planned |
| DeckPickerSheet | Pick a destination deck | feature:deck | CARD, DECK, TRANSFER, TRASH | SP3b | planned |
| DeckRow | A deck in the Library list | feature:deck | SCR-DECK-001 | SP3b | planned |
| DueStrip | The Library's due hero, opening Study | feature:deck | SCR-DECK-001 | SP3b | planned |
| MxFloatingNotice | Notice floating over a screen that does not own the problem | shared | STUDY | SP3c | planned |
| MxStatTile | A figure with its label | shared | STUDY | SP3c | planned |
| MxStackedDayBars | Stacked bars per day | shared | PROGRESS | SP3c | planned |
| MxActionPair | Two footer actions, side by side or stacked | shared | TRASH | SP3c | planned |
| MxDashedNote | Placeholder for a figure to come | shared | CARD | SP3c | planned |
| StudyTopBar | Session close, mode and progress | feature:study | STUDY | SP3c | planned |
| StudyCtaRow | The session's one or two actions | feature:study | STUDY | SP3c | planned |
| SessionFooterHint | The session's one-line hint | feature:study | STUDY | SP3c | planned |
| OutcomeTile | What a reset keeps or loses | feature:srs | SRS | SP3c | planned |

### Contracts

The contract of every component past `planned`: one `####` block with `- Variants:`, `- States:`,
`- Accessibility:`, `- Tokens:` and `- Golden:` (a list of `<state>__<variant>`, or
`none — <reason>`), plus `- Replacement:` once deprecated. The phase that builds a component
writes its block before the code. Component debt lives in its block, as a `- Debt:` line.
```

- [ ] **Step 2: Apply the renames (A5, A11)**

Run from the repo root (a one-off, not committed):

```bash
python3 - <<'EOF'
from pathlib import Path
RENAMES = [("MxAppShell", "MxScreenScaffold"), ("MxMasteryDonut", "MasteryDonut"),
           ("MxWorkloadBreakdownLine", "WorkloadBreakdownLine"), ("MxDeckPickerSheet", "DeckPickerSheet"),
           ("MxStudyTopBar", "StudyTopBar"), ("MxOutcomeTile", "OutcomeTile")]
FILES = ["DESIGN.md",
         "code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml",
         "code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py",
         ".claude/skills/flutter-theme-design/SKILL.md",
         ".claude/skills/flutter-theme-design/references/pickers-progress-tabs.md"]
for name in FILES:
    path = Path(name)
    text = path.read_text(encoding="utf-8")
    for old, new in RENAMES:
        text = text.replace(old, new)
    if name == "DESIGN.md":
        old = "(`MxScrollClearance.fab` or `fabAboveNav`)"
        assert text.count(old) == 1
        text = text.replace(old, "(`MxScreenScroll`'s FAB clearance, above the bar when there is one)")
    path.write_text(text, encoding="utf-8", newline="\n")
EOF
grep -rn "MxAppShell\|MxMasteryDonut\|MxWorkloadBreakdownLine\|MxDeckPickerSheet\|MxStudyTopBar\|MxOutcomeTile\|MxScrollClearance" \
  DESIGN.md code-verification-guard-v2/registries code-verification-guard-v2/tests .claude/skills
```

Expected: the `grep` prints nothing.

- [ ] **Step 3: Verify the guard still tests green**

Run: `(cd code-verification-guard-v2 && python3.13 -m pytest -q)`
Expected: all pass. The renames touch only rule messages, comments and one prose fixture.

- [ ] **Step 4: Commit**

```bash
git add DESIGN.md code-verification-guard-v2 .claude/skills/flutter-theme-design
git commit -m "docs(sp3a): the component catalog in DESIGN.md; MxAppShell is MxScreenScaffold, product semantics drop Mx"
```

---

### Task 5: Retire the ink vocabulary from every document

**Files:**
- Modify: `DESIGN.md` (12 lines outside `## Colors`)
- Modify: 18 screen specs under `docs/screens/spec/`, listed below
- Modify: `.claude/skills/flutter-design-system/SKILL.md:44`,
  `.claude/skills/flutter-design-system/references/components.md:42,56`,
  `.claude/skills/flutter-theme-design/references/chrome-navigation.md:125`
- Modify: `.claude/skills/flutter-design-system/references/tokens.md` (rewritten)
- Modify: `.claude/skills/flutter-theme-design/references/foundation.md:76`
- Modify: `lib/l10n/app_en.arb:4680,4689` (two descriptions)

**Interfaces:**
- Produces: zero matches for Task 6's two ink patterns in `DESIGN.md`, `docs/screens/**/*.md`, the
  two design skills, `lib/**/*.dart` and `lib/l10n/*.arb`.

- [ ] **Step 1: Rewrite the `DESIGN.md` lines outside `## Colors`**

Run from the repo root (a one-off, not committed):

```bash
python3 - <<'EOF'
from pathlib import Path
path = Path("DESIGN.md")
text = path.read_text(encoding="utf-8")
EDITS = [
    ('"Required" is the optional caption\'s size in primary ink.',
     '"Required" is the optional caption\'s size in `primary`.'),
    ("text (no fill and no edge, Indigo Ink: the quiet action beside a decision's fill)",
     "text (no fill and no edge, `primary` text: the quiet action beside a decision's fill)"),
    ("2px focus ring in primary ink.", "2px focus ring in `primary`."),
    ("The outline tone's edge is `outlineEdge`.", "The outline tone's edge is `outline`."),
    ("Ghost edge, primary-ink edge on focus", "`outline-variant` edge, `primary` edge on focus"),
    ("selected fills primary with on-primary ink", "selected fills `primary` under `on-primary`"),
    ("the glyph reads in warning ink or error and the bold title in warning ink or danger ink, and the message stays neutral",
     "it sits on `warning-container` or `error-container`, and its glyph, bold title and message read in that container's `on-` role"),
    ("success tints with success and draws its glyph in success ink, critique 2026-09-30 tone pass; warning draws its glyph in warning ink, part 3d-2",
     "success draws its glyph in `on-success-container` on `success-container`, warning in `on-warning-container` on `warning-container`"),
    ("mastery is learning progress, success a right answer or a finished, fine state, in its success ink;",
     "mastery is learning progress (`status-mastered`), success a right answer or a finished, fine state; each tone is its role's container under its `on-…-container`;"),
    ("below 34% learning ink, 34 to 66% reviewing indigo, from 67% mastered green",
     "below 34% `status-learning`, 34 to 66% `status-reviewing`, from 67% `status-mastered`"),
    ("learning in its ink;", "learning in `status-learning`;"),
    ("and the derived primary ink for any indigo text, icon or focus ring.",
     "and `primary` for indigo text, icons and the focus ring on any ground its contrast pair covers."),
    ("adjust the ink, and keep the contrast test green.",
     "fix a failing role in DESIGN.md, and keep `tools/design/generate.py --check` green."),
    ("**Don't** use a fill colour as text (primary fill, warning fill, success fill, status colour); use its ink.",
     "**Don't** put a role on a ground its contrast pair does not cover, or use `on-X` as text on a plain surface; declare and prove the pair first."),
]
for old, new in EDITS:
    assert text.count(old) == 1, old
    text = text.replace(old, new)
path.write_text(text, encoding="utf-8", newline="\n")
EOF
```

Expected: no `AssertionError`.

- [ ] **Step 2: Reword the screen specs, the skills and the ARB descriptions by meaning**

These are the 42 places that still name an ink. Line numbers are those of `master` at `37919b8`.

| Where | Term | Context |
|---|---|---|
| `docs/screens/spec/SCR-CARD-001-card-list.md:45` | its ink | …  status label in its ink, up to two tag chips and "+{n}"; a trai… |
| `docs/screens/spec/SCR-CARD-001-card-list.md:45` | plain ink | …its ink, up to two tag chips and "+{n}"; a trailing flag in plain ink (the… |
| `docs/screens/spec/SCR-CARD-001-card-list.md:434` | plain ink | …  critique 2026-10-02 (F6): plain ink.… |
| `docs/screens/spec/SCR-CARD-001-card-list.md:446` | plain ink | …spec '2026-10-02-critique2-fixes-design.md'):** the flag is plain ink… |
| `docs/screens/spec/SCR-CARD-002-card-create.md:30` | primary ink | …  primary ink beside it, a live "{count} / 60"; an in… |
| `docs/screens/spec/SCR-CARD-002-card-create.md:236` | primary ink | … labels in sentence case (14/600); Required is a caption in primary ink… |
| `docs/screens/spec/SCR-CARD-003-card-edit.md:247` | primary ink | … labels in sentence case (14/600); Required is a caption in primary ink… |
| `docs/screens/spec/SCR-CARD-003-card-edit.md:254` | plain ink | …spec '2026-10-02-critique2-fixes-design.md'):** the flag is plain ink… |
| `docs/screens/spec/SCR-CARD-004-card-detail.md:220` | plain ink | …spec '2026-10-02-critique2-fixes-design.md'):** the flag is plain ink… |
| `docs/screens/spec/SCR-DECK-001-deck-list.md:91` | learning ink | …ow carries its mastery bar; the learning band is the darker learning ink in light. The… |
| `docs/screens/spec/SCR-DECK-001-deck-list.md:635` | statusLearningInk | …  'statusLearningInk' in light (4.94:1 on the track) and the… |
| `docs/screens/spec/SCR-MONITORING-001-monitoring.md:68` | primary ink | …  row, its '#n' in the primary ink in a fixed-width cell so a wrapped line… |
| `docs/screens/spec/SCR-MONITORING-001-monitoring.md:320` | primary ink | …  fixed-width cell, selectable, the '#n' in the primary ink.… |
| `docs/screens/spec/SCR-PROGRESS-001-progress.md:32` | its ink | …draw at full strength, reviewing in primary and learning in its ink,… |
| `docs/screens/spec/SCR-PROGRESS-001-progress.md:43` | learning ink | …  {l} learning · {r} reviewing" (learning in the learning ink, reviewing in the primary ink), ending … |
| `docs/screens/spec/SCR-PROGRESS-001-progress.md:43` | primary ink | … reviewing" (learning in the learning ink, reviewing in the primary ink), ending in… |
| `docs/screens/spec/SCR-PROGRESS-001-progress.md:245` | its ink | …  strength, reviewing in primary and learning in its ink, each holding 3:1 on the card; Today is… |
| `docs/screens/spec/SCR-SRS-001-review-algorithm.md:93` | mastered ink | …"Kept" in the mastered ink on its tint; "the open session" only wh… |
| `docs/screens/spec/SCR-SRS-001-review-algorithm.md:249` | mastered ink | …- "Kept" uses the mastered ink at 4.5:1 on its tint.… |
| `docs/screens/spec/SCR-SRS-001-review-algorithm.md:299` | mastered ink | …- **Spec A10 (WCAG 2.2 AA):** "Kept" is written in the mastered ink (4.5:1) on an 8% mastery… |
| `docs/screens/spec/SCR-SRS-001-review-algorithm.md:300` | the ink | …  tint; over 12% the ink falls to 4.4:1.… |
| `docs/screens/spec/SCR-STUDY-001-study-home.md:38` | its ink | …  sparkles) in its ink, a zero term muted; "No cards yet" for … |
| `docs/screens/spec/SCR-STUDY-001-study-home.md:239` | its ink | …rm muted, each led by its glyph (history, zap, sparkles) in its ink; a… |
| `docs/screens/spec/SCR-STUDY-002-study-entry.md:29` | plain ink | …  above zero in primary, New above zero muted, a zero in plain ink; the two sets never merge. "{n}… |
| `docs/screens/spec/SCR-STUDY-002-study-entry.md:30` | warning ink | …  of the due cards are overdue" in the warning ink when any are overdue.… |
| `docs/screens/spec/SCR-STUDY-006-study-guess.md:28` | success ink | …  tones (right in 'success': success-soft, success border, success ink; wrong in error), and the rest… |
| `docs/screens/spec/SCR-STUDY-006-study-guess.md:126` | successInk | …  'successBorder' / 'successInk'); green is mastery-only.… |
| `docs/screens/spec/SCR-STUDY-007-study-recall.md:28` | warning ink | …  down; 'warning' / warning ink once timed out. It stops whenever the a… |
| `docs/screens/spec/SCR-STUDY-007-study-recall.md:141` | warningInk | …  while counting down and 'warning' / 'warningInk' once timed out; the top bar is Indigo … |
| `docs/screens/spec/SCR-STUDY-008-study-fill.md:31` | error ink | …ing caret. In wrong: the typed answer struck through in the error ink, the right… |
| `docs/screens/spec/SCR-STUDY-009-session-summary.md:36` | warning ink | …  value in tabular numerals, in the warning ink when wrong > 0. Shown only where the he… |
| `docs/screens/spec/SCR-STUDY-009-session-summary.md:38` | plain ink | …nished row reads "Kept in the history" on a neutral tile in plain ink, and the… |
| `docs/screens/spec/SCR-STUDY-009-session-summary.md:209` | plain ink | …der the finished count, on a neutral tile with the value in plain ink, and "of… |
| `docs/screens/spec/SCR-TAG-001-tags.md:93` | error ink | …The counter "{len} / 50" in the error ink, "A tag name can be at most 50 characte… |
| `docs/screens/spec/SCR-TAG-001-tags.md:237` | its ink | …"Merge tags" uses the warning role with its ink, at AA. Otherwise follows the shared fl… |
| `docs/screens/spec/SCR-TAG-001-tags.md:277` | its ink | …- **D15 (AA):** "Merge tags" uses the warning role with its ink.… |
| `.claude/skills/flutter-design-system/SKILL.md:44` | primaryInk | …imary as text, icon or focus ring is 'context.derivedColors.primaryInk';… |
| `.claude/skills/flutter-design-system/references/components.md:42` | the ink | …2. the target covers **all** of it — the ink layer in Flutter, an absolutely… |
| `.claude/skills/flutter-design-system/references/components.md:56` | the ink | …**Flutter: the ink goes inside the decoration.**… |
| `.claude/skills/flutter-theme-design/references/chrome-navigation.md:125` | primaryInk | …- [x] Không tạo vocabulary selected mới: cùng pill tint, 'primaryInk', 'navLabel'.… |
| `lib/l10n/app_en.arb:4680` | learning ink | …reen handoff 22 (FE-A9): a row's learning card-days, in the learning ink."… |
| `lib/l10n/app_en.arb:4689` | primary ink | …een handoff 22 (FE-A9): a row's reviewing card-days, in the primary ink."… |

Rewrite each one by what it means, not by renaming a string:

| Old term | New wording |
|---|---|
| primary ink, primary-ink, Indigo Ink | `` `primary` `` |
| learning ink, "the darker learning ink" | `` `status-learning` `` (the darker learning band in light is now the role itself) |
| mastered ink | `` `status-mastered` `` |
| warning ink, `warningInk` | `` `warning` `` |
| success ink, `successInk` | `` `success` `` |
| error ink, danger ink | `` `error` `` |
| a status label "in its ink" | "in its status role (`status-*`)" |
| plain ink | `` `on-surface-variant` `` for meta or secondary text (the card flag, a row's trailing mark); `` `on-surface` `` for primary text |
| `statusLearningInk` | `` `statusLearning` `` |
| `context.derivedColors.primaryInk` | `` `context.colors.primary` `` |

Read each sentence. Where the old text explained why an ink existed ("because the fill fails
4.5:1 as text"), replace the explanation with the role and drop the reason.

- [ ] **Step 3: Rewrite `tokens.md`**

Replace the whole of `.claude/skills/flutter-design-system/references/tokens.md` with:

````markdown
# Design tokens

Tokens are generated, never hand-written (spec 2026-10-04-sp3a A2, A3):

```
DESIGN.md frontmatter (every colour, light + `-dark`; typography; radii; spacing)
.impeccable/design.json extensions (contrast pairs, opacity, stroke, motion, breakpoints, shadows; no colour)
        │  python3 tools/design/generate.py --write
        ▼
lib/core/theme/foundations/   (generated, DO NOT EDIT; the gate fails when stale)
├── app_color_schemes.dart    # AppColorSchemes.light / .dark — the 45 Material 3 roles
├── app_semantic_colors.dart  # AppSemanticColors — ThemeExtension, light / dark
├── app_text_styles.dart      # AppTextStyles — DESIGN.md roles and the TextTheme mapping
├── app_spacing.dart          # AppSpacing.micro … pageEnd
├── app_radius.dart           # AppRadius.xs … full
├── app_stroke.dart           # AppStroke.hairline, control, focus, indicator
├── app_opacity.dart          # AppOpacity.disabled, muted, pressed, …
├── app_durations.dart        # AppDurations.toggle, standard, …
├── app_breakpoints.dart      # AppBreakpoints.navRail, contentMax
└── app_shadows.dart          # AppShadows.<name><Light|Dark>, built on the scheme's `shadow`
lib/core/theme/app_typography.dart  # AppTypography.withWeight — moves the variable font's axis
lib/core/theme/app_theme.dart       # AppTheme.light() / .dark()
```

To change a value, edit `DESIGN.md` (or the sidecar for a non-colour metadata
token), run `python3 tools/design/generate.py --write`, and commit both. A value
typed into a generated file is overwritten and fails the gate first.

## Colour roles

`ColorScheme` carries the 45 Material 3 roles; MemoX's semantic roles (success,
warning, the four statuses, streak) are `AppSemanticColors`, a `ThemeExtension`,
so they follow light and dark like the scheme does. A role is used on the ground
its contrast pair names; content on a coloured surface uses the role's `on-`
pair. There is no ink palette: a role that fails its floor is changed in
`DESIGN.md` (DESIGN.md, "The Role On Its Ground Rule").

## Typography

`AppTextStyles.textTheme` fills all 15 `TextTheme` slots from DESIGN.md's
`### Text theme` table. Widgets read a slot from the theme and never build a
`TextStyle`. A weight change goes through `AppTypography.withWeight`, because
on the variable font `fontWeight` alone reports one weight and paints another.

## Verifying tokens are actually used

The guard's design-token rules do this on every Dart file under
`lib/features/*/presentation/` and `lib/shared/`, and the PostToolUse hook runs
them on each edit. Hits in `lib/core/theme/` are expected: that is where values
are defined.
````

In `.claude/skills/flutter-theme-design/references/foundation.md:76`, replace
`lib/core/theme/mx_text_styles.dart` with `lib/core/theme/foundations/app_text_styles.dart`.

- [ ] **Step 4: Verify no ink term is left**

```bash
grep -rnP '\b(?i:(?:primary|secondary|tertiary|status|success|warning|danger|error|learning|reviewing|mastered|new|indigo|variant|its|their|plain|the)[- ]ink)\b|\b[a-z][A-Za-z0-9]*Ink\b' \
  DESIGN.md docs/screens .claude/skills/flutter-design-system .claude/skills/flutter-theme-design lib/l10n/*.arb
```

Expected: no output. `lib/**/*.dart` holds none either, because Task 3's code has none.

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`

- [ ] **Step 5: Commit**

```bash
git add DESIGN.md docs/screens .claude/skills/flutter-design-system .claude/skills/flutter-theme-design lib/l10n/app_en.arb
git commit -m "docs(sp3a): retire the ink vocabulary — roles on their grounds (A2, A11)"
```

---

### Task 6: `check.py` enforces the catalog, `mx_*` goldens and the ink ban

**Files:**
- Create: `tools/docs/design_catalog.py`
- Test: `tools/docs/test_design_catalog.py`
- Modify: `tools/docs/check.py` (docstring, import, `check_legacy_ui`, new `check_design`, `check_screen_states`, `run`)
- Modify: `tools/docs/test_ui_docs_layout.py` (two tests)

**Interfaces:**
- Consumes: the `### Catalog` and `### Contracts` format from Task 4.
- Produces:
  - `design_catalog.check_catalog(root, domains, screens, goldens) -> list[tuple[str, str, str]]`;
  - `design_catalog.check_ink_vocabulary(root) -> list[tuple[str, str, str]]`;
  - `design_catalog.snake(name) -> str`, `source_path(entry)` and `test_path(entry)`. Phases 2–4
    rely on these paths.

- [ ] **Step 1: Write the failing tests**

Create `tools/docs/test_design_catalog.py`:

```python
"""Tests for design_catalog.py:  python3 tools/docs/test_design_catalog.py"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import design_catalog as dc  # noqa: E402

HEADER = "| Component | Purpose | Layer | Consumers | Owner phase | Status |\n|---|---|---|---|---|---|\n"
CONTRACT = """#### MxButton
- Variants: primary
- States: enabled
- Accessibility: 48 target, label read
- Tokens: primary, on-primary
- Golden: primary_enabled__light, primary_enabled__dark
"""
DOMAINS = {"DECK", "CARD"}
SCREENS = {"SCR-DECK-001"}


def design(rows: str, contracts: str = "", body: str = "") -> str:
    return (
        "---\nname: X\n---\n\n# X\n\n## Components\n\n" + body
        + "\n### Catalog\n\n" + HEADER + rows + "\n### Contracts\n\n" + contracts + "\n## Do's and Don'ts\n"
    )


def row(name="MxButton", layer="shared", consumers="DECK, CARD", phase="SP3a", status="planned") -> str:
    return f"| {name} | an action | {layer} | {consumers} | {phase} | {status} |\n"


def tree(files: dict[str, str]) -> Path:
    root = Path(tempfile.mkdtemp())
    for name, content in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return root


def found(files: dict[str, str], goldens=()) -> list[str]:
    root = tree(files)
    golden_paths = {name: root / "test/shared/widgets/goldens" / name for name in goldens}
    return [f"{level} {where}: {message}" for level, where, message in dc.check_catalog(root, DOMAINS, SCREENS, golden_paths)]


def has(lines: list[str], *parts: str) -> bool:
    return any(all(part in line for part in parts) for line in lines)


BUTTON = "class MxButton extends StatelessWidget {}\n"


class CatalogTest(unittest.TestCase):
    def test_a_planned_row_needs_no_code(self):
        self.assertEqual(found({"DESIGN.md": design(row())}), [])

    def test_snake_names(self):
        self.assertEqual(dc.snake("MxButton"), "mx_button")
        self.assertEqual(dc.snake("MxTextField"), "mx_text_field")
        self.assertEqual(dc.snake("MasteryDonut"), "mastery_donut")

    def test_bad_layer_phase_and_status_are_errors(self):
        lines = found({"DESIGN.md": design(row(layer="widget", phase="SP4", status="done"))})
        self.assertTrue(has(lines, "layer `widget`"))
        self.assertTrue(has(lines, "owner phase `SP4`"))
        self.assertTrue(has(lines, "status `done`"))

    def test_feature_layers_are_accepted(self):
        self.assertEqual(found({"DESIGN.md": design(row(name="DeckRow", layer="feature:deck", phase="SP3b"))}), [])

    def test_an_mx_name_on_a_product_semantic_component_is_an_error(self):
        lines = found({"DESIGN.md": design(row(name="MxMasteryDonut", layer="product-semantic", phase="SP3b"))})
        self.assertTrue(has(lines, "`Mx*` names only design-system vocabulary"))

    def test_an_unknown_consumer_is_an_error_and_a_component_consumer_is_not(self):
        rows = row(consumers="DECK, BOGUS") + row(name="MxRowInk", layer="primitive", consumers="MxButton, SCR-DECK-001")
        lines = found({"DESIGN.md": design(rows)})
        self.assertTrue(has(lines, "consumer `BOGUS`"))
        self.assertFalse(has(lines, "consumer `MxButton`"))

    def test_a_duplicate_row_is_an_error(self):
        self.assertTrue(has(found({"DESIGN.md": design(row() + row())}), "two catalog rows"))

    def test_implementing_needs_a_contract_and_the_file(self):
        lines = found({"DESIGN.md": design(row(status="implementing"))})
        self.assertTrue(has(lines, "has no `#### MxButton` contract"))
        lines = found({"DESIGN.md": design(row(status="implementing"), CONTRACT)})
        self.assertTrue(has(lines, "`lib/shared/widgets/mx_button.dart` does not exist"))
        files = {"DESIGN.md": design(row(status="implementing"), CONTRACT), "lib/shared/widgets/mx_button.dart": BUTTON}
        self.assertEqual(found(files), [])

    def test_a_contract_missing_a_field_is_an_error(self):
        contract = CONTRACT.replace("- Tokens: primary, on-primary\n", "")
        files = {"DESIGN.md": design(row(status="implementing"), contract), "lib/shared/widgets/mx_button.dart": BUTTON}
        self.assertTrue(has(found(files), "contract has no `Tokens`"))

    def test_built_needs_its_test_and_every_golden(self):
        files = {"DESIGN.md": design(row(status="built"), CONTRACT), "lib/shared/widgets/mx_button.dart": BUTTON}
        lines = found(files)
        self.assertTrue(has(lines, "no widget test `test/shared/widgets/mx_button_test.dart`"))
        self.assertTrue(has(lines, "missing golden `mx_button__primary_enabled__dark.png`"))
        files["test/shared/widgets/mx_button_test.dart"] = "void main() {}\n"
        goldens = ("mx_button__primary_enabled__light.png", "mx_button__primary_enabled__dark.png")
        self.assertEqual(found(files, goldens), [])

    def test_golden_none_needs_no_png(self):
        contract = CONTRACT.replace("- Golden: primary_enabled__light, primary_enabled__dark", "- Golden: none — a primitive with no paint")
        files = {
            "DESIGN.md": design(row(status="built"), contract),
            "lib/shared/widgets/mx_button.dart": BUTTON,
            "test/shared/widgets/mx_button_test.dart": "void main() {}\n",
        }
        self.assertEqual(found(files), [])

    def test_a_product_semantic_component_cannot_leave_planned_in_sp3a(self):
        contract = CONTRACT.replace("MxButton", "MasteryDonut")
        lines = found({"DESIGN.md": design(row(name="MasteryDonut", layer="product-semantic", phase="SP3b", status="implementing"), contract)})
        self.assertTrue(has(lines, "its path is set by the SP3b spec"))

    def test_deprecated_needs_a_replacement_field(self):
        lines = found({"DESIGN.md": design(row(status="deprecated"), CONTRACT)})
        self.assertTrue(has(lines, "declares no `Replacement`"))
        self.assertEqual(found({"DESIGN.md": design(row(status="deprecated"), CONTRACT + "- Replacement: none\n")}), [])

    def test_a_public_mx_widget_outside_the_catalog_is_an_error(self):
        files = {"DESIGN.md": design(row()), "lib/shared/widgets/mx_chip.dart": "class MxChip extends StatelessWidget {}\n"}
        self.assertTrue(has(found(files), "public widget `MxChip` has no row"))

    def test_an_mx_widget_in_the_wrong_place_is_an_error(self):
        files = {"DESIGN.md": design(row()), "lib/features/deck/presentation/widgets/mx_button.dart": BUTTON}
        self.assertTrue(has(found(files), "it belongs at `lib/shared/widgets/mx_button.dart`"))

    def test_a_non_widget_mx_type_is_not_a_component(self):
        files = {"DESIGN.md": design(row()), "lib/shared/widgets/mx_button.dart": "enum MxButtonTone { primary }\nclass MxButtonStyle {}\n"}
        self.assertEqual(found(files), [])

    def test_an_mx_name_in_design_prose_or_a_screen_spec_must_be_catalogued(self):
        files = {
            "DESIGN.md": design(row(), body="Use `MxButton` and `MxScrollClearance`.\n"),
            "docs/screens/spec/SCR-DECK-001-deck-list.md": "A `MxGhost` here.\n",
        }
        lines = found(files)
        self.assertTrue(has(lines, "DESIGN.md:", "`MxScrollClearance` is not in the DESIGN.md catalog"))
        self.assertTrue(has(lines, "SCR-DECK-001-deck-list.md:1", "`MxGhost`"))
        self.assertFalse(has(lines, "`MxButton` is not"))


class GoldenTest(unittest.TestCase):
    def files(self, status: str) -> dict[str, str]:
        return {
            "DESIGN.md": design(row(status=status), CONTRACT),
            "lib/shared/widgets/mx_button.dart": BUTTON,
            "test/shared/widgets/mx_button_test.dart": "void main() {}\n",
        }

    def test_a_golden_of_an_unknown_component_is_an_error(self):
        self.assertTrue(has(found(self.files("built"), ("mx_chip__on__light.png",)), "names no catalog component"))

    def test_a_golden_outside_the_contract_is_an_error(self):
        lines = found(self.files("implementing"), ("mx_button__secondary_enabled__light.png",))
        self.assertTrue(has(lines, "`secondary_enabled__light` is not in `MxButton`'s Golden list"))

    def test_a_planned_component_has_no_goldens(self):
        lines = found({"DESIGN.md": design(row())}, ("mx_button__primary_enabled__light.png",))
        self.assertTrue(has(lines, "`MxButton` is planned; it has no goldens"))

    def test_without_design_md_a_component_golden_is_an_error(self):
        self.assertTrue(has(found({}, ("mx_button__a__light.png",)), "DESIGN.md has no catalog"))


class InkVocabularyTest(unittest.TestCase):
    def test_ink_terms_are_errors_in_every_scope(self):
        root = tree({
            "DESIGN.md": "Primary ink is retired.\n",
            "docs/screens/spec/SCR-X.md": "a status label in its ink\nlearning ink\n",
            ".claude/skills/flutter-design-system/SKILL.md": "use context.derivedColors.primaryInk\n",
            "lib/x.dart": "final Color warningInk = c;\n",
            "lib/l10n/app_en.arb": '"description": "a row, in the learning ink."\n',
            "lib/l10n/generated/app_localizations.dart": "/// in the learning ink.\n",
        })
        lines = [f"{where}: {message}" for _, where, message in dc.check_ink_vocabulary(root)]
        self.assertEqual(len(lines), 6, lines)

    def test_ripples_links_and_rows_are_not_ink_roles(self):
        root = tree({
            "DESIGN.md": "a link; InkWell; MxRowInk is the row ripple; Ink.image\n",
            "lib/x.dart": "return InkWell(child: Ink(child: c));\n",
        })
        self.assertEqual(dc.check_ink_vocabulary(root), [])


if __name__ == "__main__":
    unittest.main()
```

In `tools/docs/test_ui_docs_layout.py`, apply:

```diff
diff --git a/tools/docs/test_ui_docs_layout.py b/tools/docs/test_ui_docs_layout.py
index c3b2dba..2ba9920 100644
--- a/tools/docs/test_ui_docs_layout.py
+++ b/tools/docs/test_ui_docs_layout.py
@@ -325,6 +325,10 @@ class AdrTest(unittest.TestCase):
         self.assertTrue(has(legacy, "library_root_light.png", "legacy golden (SP2)"))
         self.assertFalse(has(errors(base()), "legacy golden (SP2)"))
 
+    def test_a_component_golden_is_not_legacy(self):
+        found = errors(base(**{"test/shared/widgets/goldens/mx_button__primary_enabled__light.png": ""}))
+        self.assertFalse(has(found, "legacy golden (SP2)"))
+
     def test_the_gallery_is_a_retired_home_but_visual_audits_come_back(self):
         self.assertTrue(has(errors(base(**{"lib/app/gallery/gallery_screen.dart": "// old\n"})), "retired home (SP2)"))
         # MX-VIS-001: the rebuilt screens keep their visual-audit companions.
@@ -375,6 +379,10 @@ class ScreenStateTest(unittest.TestCase):
         found = self.found(base(), ("scr_deck_001__root_loaded__light.png", "scr_deck_001__gone__light.png"))
         self.assertTrue(has(found, "golden matches no screen state"))
 
+    def test_a_component_golden_is_not_a_screen_orphan(self):
+        found = self.found(base(), ("scr_deck_001__root_loaded__light.png", "mx_button__primary_enabled__light.png"))
+        self.assertFalse(has(found, "orphan"))
+
     def test_old_goldens_are_not_orphans_before_the_first_scr_golden(self):
         self.assertFalse(has(self.found(base(), ("library_decks_light.png",)), "orphan"))
 
```

- [ ] **Step 2: Run them to verify they fail**

Run: `python3 tools/docs/test_design_catalog.py`
Expected: `ModuleNotFoundError: No module named 'design_catalog'`

- [ ] **Step 3: Write `design_catalog.py`**

Create `tools/docs/design_catalog.py`:

```python
"""DESIGN.md's component catalog and the design vocabulary (spec 2026-10-04-sp3a §4, A11).

`check.py` calls `check_catalog` and `check_ink_vocabulary`; each returns
`(level, where, message)` findings and never raises on a malformed document.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

DESIGN_MD = "DESIGN.md"
CATALOG_HEADING = "### Catalog"
CONTRACTS_HEADING = "### Contracts"
LAYERS = {"primitive", "shared", "app-shell", "product-semantic"}
FEATURE_LAYER = re.compile(r"^feature:[a-z][a-z-]*$")
PHASES = {"SP3a", "SP3b", "SP3c"}
STATUSES = {"planned", "implementing", "built", "deprecated"}
CONTRACT_FIELDS = ("Variants", "States", "Accessibility", "Tokens", "Golden")
NAME = re.compile(r"^[A-Z][A-Za-z0-9]*$")
MX_NAME = re.compile(r"\bMx[A-Z][A-Za-z0-9]*\b")
MX_WIDGET = re.compile(r"^(?:final\s+|base\s+|sealed\s+)?class\s+(Mx[A-Z]\w*)\b[^{]*?\bextends\s+\w*Widget\b", re.M)
MX_GOLDEN = re.compile(r"^(mx_[a-z0-9_]+?)__([a-z0-9_]+)__([a-z0-9_]+)\.png$")
PROSE_INK = re.compile(
    r"\b(?i:(?:primary|secondary|tertiary|status|success|warning|danger|error|learning|reviewing"
    r"|mastered|new|indigo|variant|its|their|plain|the)[- ]ink)\b"
)
CAMEL_INK = re.compile(r"\b[a-z][A-Za-z0-9]*Ink\b")
INK_SCOPES = (
    "DESIGN.md",
    "docs/screens/**/*.md",
    ".claude/skills/flutter-design-system/**/*.md",
    ".claude/skills/flutter-theme-design/**/*.md",
    "lib/**/*.dart",
    "lib/l10n/*.arb",
)

Finding = tuple[str, str, str]


@dataclass
class Entry:
    name: str
    purpose: str
    layer: str
    consumers: list[str]
    phase: str
    status: str
    line: int


@dataclass
class Contract:
    name: str
    line: int
    fields: dict[str, str] = field(default_factory=dict)

    def goldens(self) -> list[str]:
        value = self.fields.get("Golden", "")
        if value.startswith("none"):
            return []
        return [item.strip().strip("`") for item in value.split(",") if item.strip()]


def snake(name: str) -> str:
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name).lower()


def source_path(entry: Entry) -> str | None:
    if entry.layer == "primitive":
        return f"lib/shared/widgets/primitives/{snake(entry.name)}.dart"
    if entry.layer == "shared":
        return f"lib/shared/widgets/{snake(entry.name)}.dart"
    return None


def test_path(entry: Entry) -> str:
    return f"test/shared/widgets/{snake(entry.name)}_test.dart"


def body_of(text: str) -> tuple[str, int]:
    """The text after the frontmatter, and how many lines the frontmatter took."""
    if not text.startswith("---\n"):
        return text, 0
    end = text.index("\n---\n", 4) + len("\n---\n")
    return text[end:], text[:end].count("\n")


def parse(text: str) -> tuple[list[Entry], dict[str, Contract]]:
    lines = text.splitlines()
    entries: list[Entry] = []
    contracts: dict[str, Contract] = {}
    section = None
    current: Contract | None = None
    for number, line in enumerate(lines, start=1):
        if line.startswith("## ") or line.startswith("### "):
            section = line.strip()
            current = None
            continue
        if section == CATALOG_HEADING and line.startswith("|"):
            cells = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
            if len(cells) != 6 or cells[0] == "Component" or set("".join(cells)) <= set("-: "):
                continue
            name, purpose, layer, consumers, phase, status = cells
            entries.append(Entry(name, purpose, layer, [c.strip() for c in consumers.split(",") if c.strip()], phase, status, number))
        elif section == CONTRACTS_HEADING:
            if line.startswith("#### "):
                current = Contract(line[5:].strip().strip("`"), number)
                contracts[current.name] = current
            elif current is not None and line.startswith("- ") and ":" in line:
                key, value = line[2:].split(":", 1)
                current.fields[key.strip()] = value.strip()
    return entries, contracts


def check_catalog(root: Path, domains: set[str], screens: set[str], goldens: dict[str, Path]) -> list[Finding]:
    findings: list[Finding] = []
    design = root / DESIGN_MD
    mx_goldens = {name: path for name, path in goldens.items() if name.startswith("mx_")}
    if not design.exists():
        return [("ERROR", str(path), "component golden but DESIGN.md has no catalog") for path in mx_goldens.values()]
    text = design.read_text(encoding="utf-8")
    entries, contracts = parse(text)
    names = {e.name for e in entries}
    by_snake = {snake(e.name): e for e in entries}
    where = lambda e: f"{DESIGN_MD}:{e.line}"  # noqa: E731

    seen: set[str] = set()
    for e in entries:
        if e.name in seen:
            findings.append(("ERROR", where(e), f"`{e.name}` has two catalog rows"))
        seen.add(e.name)
        if not NAME.match(e.name):
            findings.append(("ERROR", where(e), f"`{e.name}` is not a component name"))
        if e.layer not in LAYERS and not FEATURE_LAYER.match(e.layer):
            findings.append(("ERROR", where(e), f"`{e.name}` has layer `{e.layer}`; use primitive, shared, app-shell, product-semantic or feature:<domain>"))
        if e.name.startswith("Mx") and (e.layer == "product-semantic" or e.layer.startswith("feature:")):
            findings.append(("ERROR", where(e), f"`{e.name}` is {e.layer}; `Mx*` names only design-system vocabulary (A5)"))
        if e.phase not in PHASES:
            findings.append(("ERROR", where(e), f"`{e.name}` has owner phase `{e.phase}`"))
        if e.status not in STATUSES:
            findings.append(("ERROR", where(e), f"`{e.name}` has status `{e.status}`; use planned, implementing, built or deprecated"))
        for consumer in e.consumers:
            if consumer not in domains and consumer not in screens and consumer not in names:
                findings.append(("ERROR", where(e), f"`{e.name}` names consumer `{consumer}`, which is no domain, screen or component"))
        if e.status == "planned":
            continue
        contract = contracts.get(e.name)
        if contract is None:
            findings.append(("ERROR", where(e), f"`{e.name}` is {e.status} but has no `#### {e.name}` contract"))
            continue
        for key in CONTRACT_FIELDS:
            if not contract.fields.get(key):
                findings.append(("ERROR", f"{DESIGN_MD}:{contract.line}", f"`{e.name}` contract has no `{key}`"))
        if e.status == "deprecated":
            if "Replacement" not in contract.fields:
                findings.append(("ERROR", f"{DESIGN_MD}:{contract.line}", f"deprecated `{e.name}` declares no `Replacement` (or `none`)"))
            continue
        source = source_path(e)
        if source is None:
            findings.append(("ERROR", where(e), f"`{e.name}` is {e.layer}; its path is set by the SP3b spec, so it stays planned until then"))
            continue
        if not (root / source).exists():
            findings.append(("ERROR", where(e), f"`{e.name}` is {e.status} but `{source}` does not exist"))
        if e.status == "built":
            if not (root / test_path(e)).exists():
                findings.append(("ERROR", where(e), f"built `{e.name}` has no widget test `{test_path(e)}`"))
            for golden in contract.goldens():
                name = f"{snake(e.name)}__{golden}.png"
                if name not in mx_goldens:
                    findings.append(("ERROR", where(e), f"built `{e.name}` is missing golden `{name}`"))

    for path in sorted((root / "lib").rglob("*.dart")) if (root / "lib").is_dir() else []:
        relative = path.relative_to(root).as_posix()
        for match in MX_WIDGET.finditer(path.read_text(encoding="utf-8")):
            name = match.group(1)
            entry = next((e for e in entries if e.name == name), None)
            if entry is None:
                findings.append(("ERROR", relative, f"public widget `{name}` has no row in the DESIGN.md catalog"))
            elif source_path(entry) != relative:
                findings.append(("ERROR", relative, f"`{name}` is {entry.layer}; it belongs at `{source_path(entry) or 'a path the SP3b spec sets'}`"))

    body, offset = body_of(text)
    references = [(DESIGN_MD, body, offset)]
    for spec in sorted((root / "docs/screens/spec").glob("*.md")) if (root / "docs/screens/spec").is_dir() else []:
        references.append((spec.relative_to(root).as_posix(), spec.read_text(encoding="utf-8"), 0))
    for relative, content, base in references:
        for number, line in enumerate(content.splitlines(), start=base + 1):
            for name in MX_NAME.findall(line):
                if name not in names:
                    findings.append(("ERROR", f"{relative}:{number}", f"`{name}` is not in the DESIGN.md catalog"))

    for name, path in sorted(mx_goldens.items()):
        match = MX_GOLDEN.match(name)
        entry = by_snake.get(match.group(1)) if match else None
        if entry is None:
            findings.append(("ERROR", str(path), "component golden names no catalog component (mx_<component>__<state>__<variant>.png)"))
            continue
        if entry.status in ("planned", "deprecated"):
            findings.append(("ERROR", str(path), f"`{entry.name}` is {entry.status}; it has no goldens"))
            continue
        contract = contracts.get(entry.name)
        if contract is None or f"{match.group(2)}__{match.group(3)}" not in contract.goldens():
            findings.append(("ERROR", str(path), f"`{match.group(2)}__{match.group(3)}` is not in `{entry.name}`'s Golden list"))
    return findings


def check_ink_vocabulary(root: Path) -> list[Finding]:
    findings: list[Finding] = []
    for pattern in INK_SCOPES:
        for path in sorted(root.glob(pattern)):
            relative = path.relative_to(root).as_posix()
            if not path.is_file() or relative.startswith("lib/l10n/generated/"):
                continue
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
                for match in (*PROSE_INK.finditer(line), *CAMEL_INK.finditer(line)):
                    findings.append(("ERROR", f"{relative}:{number}", f"`{match.group(0)}`: the ink model is retired; name the role (A2, A11)"))
    return findings
```

- [ ] **Step 4: Wire it into `check.py`**

Apply to `tools/docs/check.py`:

```diff
diff --git a/tools/docs/check.py b/tools/docs/check.py
index f41e4c8..93a7e3b 100644
--- a/tools/docs/check.py
+++ b/tools/docs/check.py
@@ -43,6 +43,10 @@ ERROR
   or is deprecated; an FN cited in a UC flow but missing from its `Invokes:`
 - a file in a retired home: features/*/usecases/, features/*/ui.md, shared/ui/
 - a legacy-named golden, or a file under lib/app/gallery/ (SP2)
+- DESIGN.md's component catalog: a bad row, a missing contract, code or test
+  for its status, a public `Mx*` widget outside it or in the wrong place, an
+  `Mx*` name in DESIGN.md or a screen spec that it does not hold, or an `mx_*`
+  golden it does not declare (SP3a §4); a retired ink term (A11)
 - with --plan: a mapping row whose destination does not exist (a mapping
   table is one whose first header cell starts with "Nguồn"; destinations are
   backticked paths relative to docs/, `<slug>` and `*` are wildcards)
@@ -70,6 +74,7 @@ from pathlib import Path
 
 sys.path.insert(0, str(Path(__file__).resolve().parent))
 
+import design_catalog  # noqa: E402
 import generate as g  # noqa: E402
 import specdocs  # noqa: E402
 import ledger  # noqa: E402
@@ -375,14 +380,31 @@ RETIRED_UI_HOMES = ("lib/app/gallery/**/*",)
 
 def check_legacy_ui(report: Report) -> None:
     for path in sorted(g.ROOT.glob("test/**/goldens/*.png")):
-        if not path.name.startswith("scr_"):
-            report.error(path, "legacy golden (SP2): new goldens are named scr_<screen>__<state>__<variant>.png")
+        if not path.name.startswith(("scr_", "mx_")):
+            report.error(
+                path,
+                "legacy golden (SP2): a golden is scr_<screen>__<state>__<variant>.png "
+                "or mx_<component>__<state>__<variant>.png",
+            )
     for pattern in RETIRED_UI_HOMES:
         for path in sorted(g.ROOT.glob(pattern)):
             if path.is_file():
                 report.error(path, "retired home (SP2): the legacy component gallery is gone")
 
 
+def check_design(docs: list[g.Doc], report: Report) -> None:
+    """DESIGN.md's component catalog, `mx_*` goldens and the retired ink vocabulary (SP3a §4, A11)."""
+    screens = {d.id for d in docs if d.kind == "SCR" and d.id}
+    domains = {screen.split("-")[1] for screen in screens}
+    findings = design_catalog.check_catalog(g.ROOT, domains, screens, g.golden_files())
+    findings += design_catalog.check_ink_vocabulary(g.ROOT)
+    for level, where, message in findings:
+        if level == "ERROR":
+            report.error(where, message)
+            continue
+        report.warning(where, message)
+
+
 def check_catalog(docs: list[g.Doc], report: Report) -> None:
     """Each screen has one catalog row that agrees with its frontmatter (plan PT5)."""
     rows, invariants = screen_catalog()
@@ -453,8 +475,9 @@ def check_screen_states(docs, report, goldens: dict[str, Path], base_keys) -> No
                 f"state key `{missing}` was renamed or deleted; keys are permanent — "
                 "keep its heading with `Status: removed`",
             )
-    if any(name.startswith("scr_") for name in goldens):
-        for name in sorted(set(goldens) - declared):
+    screen_goldens = {name for name in goldens if name.startswith("scr_")}
+    if screen_goldens:
+        for name in sorted(screen_goldens - declared):
             report.error(goldens[name], "golden matches no screen state (orphan)")
 
 
@@ -834,6 +857,7 @@ def run(plan: Path | None, base_keys=base_state_keys, ledger_path: Path | None =
     check_single_product(report)
     check_retired_homes(report)
     check_legacy_ui(report)
+    check_design(docs, report)
     check_catalog(docs, report)
     check_screen_states(docs, report, g.golden_files(), base_keys)
     check_text(docs, report)
```

- [ ] **Step 5: Run every docs test and the real check**

Run: `python3 -m unittest discover -s tools/docs -p 'test_*.py'`
Expected: `Ran 134 tests … OK`

Run: `python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), …`. The catalog is complete (Task 4) and no ink term is left
(Task 5).

- [ ] **Step 6: Commit**

```bash
git add tools/docs
git commit -m "feat(sp3a): check.py enforces the component catalog, mx_* goldens and the ink ban"
```

---

### Task 7: The gate, the ledgers and CLAUDE.md

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/dod_check.sh` (after the `DOCS_PY` block, around line 274)
- Modify: `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` (one test class)
- Modify: `CLAUDE.md` ("Where knowledge lives", the "Known UI debt" row)
- Modify: `docs/wbs_FE.md` (the SP3a row and four phase rows)

**Interfaces:**
- Consumes: `tools/design/generate.py --check` (Task 1), and the tests in `tools/design` and `tools/docs`.

- [ ] **Step 1: Write the failing gate test**

Append to `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`, before the final
`if __name__ == "__main__":` block if there is one:

```python
class GateRunsTheDesignTokensTest(unittest.TestCase):
    """DESIGN.md is the only hand-written source of a colour (spec 2026-10-04-sp3a A3):
    the gate validates it and fails when the generated theme is stale, and it runs the
    tests of the two tools that enforce that."""

    def test_the_gate_checks_the_design_tokens(self) -> None:
        script = (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")
        self.assertIn('DESIGN_PY="$REPO_ROOT/tools/design/generate.py"', script)
        self.assertIn("'$DESIGN_PY' --check", script)

    def test_the_gate_runs_the_docs_and_design_tooling_tests(self) -> None:
        script = (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")
        self.assertIn("-m unittest discover -s '$REPO_ROOT/tools/docs' -p 'test_*.py'", script)
        self.assertIn("-m unittest discover -s '$REPO_ROOT/tools/design' -p 'test_*.py'", script)
```

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_ci_tooling.py' -k Design`
Expected: 2 failures.

- [ ] **Step 2: Add the steps to the gate**

In `dod_check.sh`, directly after the `fi` that closes the `DOCS_PY` block, insert:

```bash
# DESIGN.md is the only hand-written source of a design value (spec
# 2026-10-04-sp3a A3). The generator validates it (every M3 role in both themes,
# no colour in the sidecar, no ink role, every contrast pair) and fails when
# lib/core/theme/foundations/ is stale or edited by hand.
DESIGN_PY="$REPO_ROOT/tools/design/generate.py"
if [[ -n "$PY" && -f "$DESIGN_PY" ]]; then
  plan design_tokens "design tokens (DESIGN.md → theme)" "$PY '$DESIGN_PY' --check"
else
  FAILED+=("design token gate unavailable: $DESIGN_PY")
fi

# The two tools above enforce the rebuild's contracts; their own tests are what
# notice when a rule has stopped matching.
if [[ -n "$PY" ]]; then
  plan tooling_tests "docs and design tooling tests" \
    "$PY -m unittest discover -s '$REPO_ROOT/tools/docs' -p 'test_*.py' && $PY -m unittest discover -s '$REPO_ROOT/tools/design' -p 'test_*.py'"
fi
```

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'`
Expected: OK.

- [ ] **Step 3: CLAUDE.md's debt row (A11)**

In `CLAUDE.md`, "Where knowledge lives", replace the row
`| Known UI debt | the UI-base register (§9 of \`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md\`) |`
with
`| Known UI debt | beside its owner: a screen's in its spec's Rulings, a component's in its \`DESIGN.md\` catalog contract (\`- Debt:\`) |`

- [ ] **Step 4: The WBS**

In `docs/wbs_FE.md`, set the SP3a row's status to `đang làm`. Fill its evidence with the spec
link and this plan's link, and set its "Việc tiếp theo" to `Phase 1 sign-off`. Add four rows
after it:

```markdown
| SP3a-P1 | Structured data → generator → token → 45 role M3 sáng/tối → extension → TextTheme → kiểm parity/contrast; catalog component; bỏ từ vựng ink | đang làm | SP2 | M | [plan](superpowers/plans/2026-10-04-sp3a-p1-tokens-theme.md) | Owner sign-off |
| SP3a-P2 | Primitive + control (catalog: Owner phase SP3a, phase 2) | chưa bắt đầu | SP3a-P1 | L | — | Plan P2 |
| SP3a-P3 | Surface, feedback, trạng thái (catalog, phase 3) | chưa bắt đầu | SP3a-P2 | L | — | Plan P3 |
| SP3a-P4 | Composition chung (catalog, phase 4) | chưa bắt đầu | SP3a-P3 | M | — | Plan P4 |
```

- [ ] **Step 5: Run the whole gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: every step passes, including `design tokens (DESIGN.md → theme)` and
`docs and design tooling tests`.

Run: `python3 tools/docs/check.py --ledger docs/superpowers/plans/2026-10-04-sp2-remove-legacy-ui-matrix.md | tail -1`
Expected: `PASS`. This confirms the SP2 ledger still verifies.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/flutter-workflow CLAUDE.md docs/wbs_FE.md
git commit -m "chore(sp3a): the gate checks the design tokens and runs the tooling tests"
```

---

### Task 8: Impeccable on the palette and the type scale, then sign-off

**Files:**
- Temporary, not committed: `test/core/theme/specimen_test.dart` and its PNGs in `$SCRATCH`
- Modify (only if findings): `DESIGN.md`, then regenerate

- [ ] **Step 1: Render a specimen of each theme (throwaway)**

Create `test/core/theme/specimen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

void main() {
  for (final (name, theme) in [('light', AppTheme.light()), ('dark', AppTheme.dark())]) {
    testWidgets('specimen $name', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.reset);
      final ColorScheme s = theme.colorScheme;
      final AppSemanticColors x = theme.extension<AppSemanticColors>()!;
      final List<(String, Color, Color)> pairs = [
        ('primary', s.primary, s.onPrimary),
        ('primaryContainer', s.primaryContainer, s.onPrimaryContainer),
        ('secondaryContainer', s.secondaryContainer, s.onSecondaryContainer),
        ('tertiaryContainer', s.tertiaryContainer, s.onTertiaryContainer),
        ('error', s.error, s.onError),
        ('errorContainer', s.errorContainer, s.onErrorContainer),
        ('success', x.success, x.onSuccess),
        ('successContainer', x.successContainer, x.onSuccessContainer),
        ('warning', x.warning, x.onWarning),
        ('warningContainer', x.warningContainer, x.onWarningContainer),
        ('statusNewContainer', x.statusNewContainer, x.onStatusNewContainer),
        ('statusLearningContainer', x.statusLearningContainer, x.onStatusLearningContainer),
        ('statusReviewingContainer', x.statusReviewingContainer, x.onStatusReviewingContainer),
        ('statusMasteredContainer', x.statusMasteredContainer, x.onStatusMasteredContainer),
        ('inverseSurface', s.inverseSurface, s.onInverseSurface),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(padding: const EdgeInsets.all(16), children: [
            for (final (label, ground, content) in pairs)
              Container(color: ground, padding: const EdgeInsets.all(8), child: Text(label, style: TextStyle(color: content))),
            for (final c in [s.surface, s.surfaceContainerLowest, s.surfaceContainerLow, s.surfaceContainerHigh])
              Container(
                color: c,
                padding: const EdgeInsets.all(8),
                child: Wrap(spacing: 8, children: [
                  Text('primary', style: TextStyle(color: s.primary)),
                  Text('error', style: TextStyle(color: s.error)),
                  Text('success', style: TextStyle(color: x.success)),
                  Text('warning', style: TextStyle(color: x.warning)),
                  Text('new', style: TextStyle(color: x.statusNew)),
                  Text('learning', style: TextStyle(color: x.statusLearning)),
                  Text('mastered', style: TextStyle(color: x.statusMastered)),
                  Text('variant', style: TextStyle(color: s.onSurfaceVariant)),
                ]),
              ),
            Text('Stat 128', style: theme.textTheme.displayLarge),
            Text('Display', style: theme.textTheme.displayMedium),
            Text('Headline', style: theme.textTheme.headlineLarge),
            Text('Title', style: theme.textTheme.titleLarge),
            Text('Body large — Học từ mới mỗi ngày', style: theme.textTheme.bodyLarge),
            Text('Body — 한국어 문장과 tiếng Việt', style: theme.textTheme.bodyMedium),
            Text('Caption 12', style: theme.textTheme.bodySmall),
            Text('SECTION LABEL', style: theme.textTheme.labelMedium),
          ]),
        ),
      ));
      await expectLater(find.byType(Scaffold), matchesGoldenFile('specimen_$name.png'));
    });
  }
}
```

Run: `flutter test test/core/theme/specimen_test.dart --update-goldens`, then move
`test/core/theme/specimen_*.png` to `$SCRATCH/`. Delete `specimen_test.dart`.
Run: `git status --short test/core/theme`
Expected: nothing to commit from this step.

The font is bundled, so the text renders in Plus Jakarta Sans and not as boxes. If the default
test font (Ahem) shows, load `assets/fonts/PlusJakartaSans-Variable.ttf` with a `FontLoader`
in a `setUpAll` before pumping.

- [ ] **Step 2: Impeccable critique at the token layer**

Run the `impeccable` skill's `critique`, measured against `DESIGN.md`'s Colors and Typography
sections. Give it the two specimen PNGs and `$SCRATCH/contrast-report.txt`.

Apply A10 to each finding:
- A finding that changes a value changes `DESIGN.md`, then runs `generate.py --write` and the
  Task 3 tests.
- A finding that only reflects taste, while the roles meet `DESIGN.md` and contrast, does not
  change a role value (A2).

Fix all findings in one batch, then run one `impeccable audit` of what changed (CLAUDE.md).
Report what it found to the owner and do not run a further audit.

- [ ] **Step 3: Gate and sign-off**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: PASS.

Commit any fix:

```bash
git commit -am "fix(sp3a): Impeccable findings on the palette and type scale"
```

Push the branch: `git push -u origin claude/wonderful-ride-dnypk9`.

Ask the owner for the Phase 1 sign-off through the `AskUserQuestion` popup. Include:
- the gate result;
- the contrast report;
- the specimen PNGs;
- the Impeccable findings and what was done with each.

After sign-off, set the WBS rows to SP3a-P1 `xong` and SP3a `đang làm` (next: Plan P2), and
commit.
