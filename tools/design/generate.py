#!/usr/bin/env python3
"""Generates the theme code from design/tokens.json (+ design/app_tokens.json).

Writes lib/core/theme/generated/*.g.dart (formatted with `dart format`), the
YAML frontmatter of DESIGN.md (its prose is hand-written) and the
.impeccable/design.json sidecar (its `narrative` is hand-written).
Python >= 3.12, standard library only. Output is deterministic.

  generate.py            write into the repository
  generate.py --out DIR  write the generated Dart into DIR instead (check.py)
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
TOKENS_PATH = REPO_ROOT / "design" / "tokens.json"
APP_TOKENS_PATH = REPO_ROOT / "design" / "app_tokens.json"
GENERATED_DIR = REPO_ROOT / "lib" / "core" / "theme" / "generated"
DESIGN_PATH = REPO_ROOT / "DESIGN.md"
SIDECAR_PATH = REPO_ROOT / ".impeccable" / "design.json"

HEADER = "// GENERATED from design/tokens.json by tools/design/generate.py. Do not edit."

M3_ROLE_COUNT = 46
FAMILIES = ("success", "warning", "info")
FAMILY_SUFFIXES = (("color", ""), ("onColor", "on"), ("container", "container"), ("onContainer", "onContainer"))
SURFACE_TOKENS = ("cardSurface", "searchSurface", "tileSurface", "divider")
# Numbers only: the Design System sets tabular figures on the stat style alone.
TABULAR_SLOTS = ("displayMedium",)
SLOT_PATTERN = re.compile(r"\(Flutter (\w+)\)")


def camel(kebab: str) -> str:
    head, *rest = kebab.split("-")
    return head + "".join(part.capitalize() for part in rest)


def dart_color(hex_value: str) -> str:
    return f"Color(0xFF{hex_value.lstrip('#').upper()})"


def number(text: str) -> str:
    """'24px' / '0.08' -> '24' / '0.08' (integers lose their '.0')."""
    value = float(text.removesuffix("px").removesuffix("ms"))
    return str(int(value)) if value == int(value) else repr(value)


def pascal(name: str) -> str:
    return name[0].upper() + name[1:]


def m3_roles(tokens: dict) -> list[dict]:
    roles = tokens["color"]["tokens"][:M3_ROLE_COUNT]
    if roles[0]["name"] != "primary" or roles[-1]["name"] != "surfaceTint":
        raise ValueError("tokens.json: the first 46 color tokens must run primary..surfaceTint")
    return roles


def extension_fields(tokens: dict) -> list[tuple[str, str, dict]]:
    """(dart field, DS token name, token) in declaration order."""
    by_name = {t["name"]: t for t in tokens["color"]["tokens"]}
    fields: list[tuple[str, str, dict]] = []
    for family in FAMILIES:
        for token_suffix, prefix in FAMILY_SUFFIXES:
            token_name = f"{family}-{token_suffix}"
            field = {
                "color": family,
                "onColor": "on" + pascal(family),
                "container": family + "Container",
                "onContainer": "on" + pascal(family) + "Container",
            }[token_suffix]
            fields.append((field, token_name, by_name[token_name]))
    for name in SURFACE_TOKENS:
        fields.append((name, name, by_name[name]))
    return fields


def dimension_tokens(tokens: dict) -> list[tuple[str, str]]:
    """(dart field, numeric literal) for spacing, radius, size, stroke, opacity."""
    fields: list[tuple[str, str]] = []
    for group in ("spacing", "radius", "size", "stroke", "opacity"):
        for token in tokens[group]["tokens"]:
            if token["name"] == "radius-full":
                continue
            fields.append((camel(token["name"]), number(token["value"])))
    return fields


def render_color_schemes(tokens: dict) -> str:
    def scheme(const_name: str, mode: str) -> str:
        brightness = "Brightness.light" if mode == "light" else "Brightness.dark"
        lines = [f"const ColorScheme {const_name} = ColorScheme(", f"  brightness: {brightness},"]
        for role in m3_roles(tokens):
            lines.append(f"  {role['name']}: {dart_color(role['value'][mode])},")
        lines.append(");")
        return "\n".join(lines)

    return "\n".join([
        HEADER, "", "import 'package:flutter/material.dart';", "",
        scheme("lightColorScheme", "light"), "", scheme("darkColorScheme", "dark"), "",
    ])


def render_mx_colors(tokens: dict) -> str:
    fields = extension_fields(tokens)
    names = [f[0] for f in fields]
    out = [HEADER, "", "import 'package:flutter/material.dart';", ""]
    out += [
        "/// The colour tokens of the Design System that Material's [ColorScheme] has no role for.",
        "@immutable",
        "class MxColorsExtension extends ThemeExtension<MxColorsExtension> {",
        "  const MxColorsExtension({",
    ]
    out += [f"    required this.{n}," for n in names]
    out += ["  });", ""]
    for const_name, mode in (("light", "light"), ("dark", "dark")):
        out.append(f"  static const MxColorsExtension {const_name} = MxColorsExtension(")
        out += [f"    {field}: {dart_color(token['value'][mode])}," for field, _, token in fields]
        out += ["  );", ""]
    out += [f"  final Color {n};" for n in names]
    out += ["", "  @override", "  MxColorsExtension copyWith({"]
    out += [f"    Color? {n}," for n in names]
    out += ["  }) {", "    return MxColorsExtension("]
    out += [f"      {n}: {n} ?? this.{n}," for n in names]
    out += ["    );", "  }", "", "  @override",
            "  MxColorsExtension lerp(ThemeExtension<MxColorsExtension>? other, double t) {",
            "    if (other is! MxColorsExtension) return this;", "    return MxColorsExtension("]
    out += [f"      {n}: Color.lerp({n}, other.{n}, t)!," for n in names]
    out += ["    );", "  }", "}", ""]
    return "\n".join(out)


def render_dimens(tokens: dict, app_tokens: dict) -> str:
    fields = dimension_tokens(tokens)
    app_only = [(t["name"], number(str(t["value"])), t.get("usage", "")) for t in app_tokens["tokens"]]
    out = [HEADER, "", "import 'package:flutter/material.dart';", ""]
    out += [
        "/// Spacing, shape, size, breakpoint, stroke and opacity tokens, read as `context.dimens`.",
        "@immutable",
        "class AppDimens extends ThemeExtension<AppDimens> {",
        "  const AppDimens({",
    ]
    out += [f"    this.{n} = {v}," for n, v in fields]
    if app_only:
        out.append("    // App-only — not yet in the design system.")
        out += [f"    this.{n} = {v}," for n, v, _ in app_only]
    out += ["  });", ""]
    out += [f"  final double {n};" for n, _ in fields]
    if app_only:
        out.append("  // App-only — not yet in the design system.")
        for n, _, usage in app_only:
            if usage:
                out.append(f"  /// {usage}")
            out.append(f"  final double {n};")
    out += ["", "  @override", "  AppDimens copyWith() => this;", "", "  @override",
            "  AppDimens lerp(ThemeExtension<AppDimens>? other, double t) => this;", "}", ""]
    return "\n".join(out)


def families(tokens: dict) -> tuple[str, list[str]]:
    sans = tokens["type"]["families"]["sans"]
    names = [re.sub(r"\s+", "", part.strip().strip('"')) for part in sans.split(",")]
    named = [n for n in names if n not in ("system-ui", "sans-serif")]
    return named[0], named[1:]


def render_text_theme(tokens: dict) -> str:
    family, fallback = families(tokens)
    fallback_list = ", ".join(f"'{f}'" for f in fallback)
    out = [HEADER, "", "import 'package:flutter/material.dart';", "",
           f"const String kFontFamily = '{family}';",
           f"const List<String> kFontFamilyFallback = [{fallback_list}];", "",
           "/// The twelve Design System roles; slots the Design System leaves out keep Material's defaults.",
           "const TextTheme generatedTextTheme = TextTheme("]
    for group in tokens["type"]["groups"]:
        for style in group["styles"]:
            slot = SLOT_PATTERN.search(style["usage"]).group(1)
            size = number(style["fontSize"])
            line = number(style["lineHeight"])
            out += [f"  {slot}: TextStyle(", f"    fontSize: {size},", f"    height: {line} / {size},",
                    f"    fontWeight: FontWeight.w{style['fontWeight']},",
                    f"    letterSpacing: {number(style['letterSpacing'])},"]
            if slot in TABULAR_SLOTS:
                out.append("    fontFeatures: [FontFeature.tabularFigures()],")
            out.append("  ),")
    out += [");", ""]
    return "\n".join(out)


def render_constants(tokens: dict) -> str:
    dragged = next(t for t in tokens["opacity"]["tokens"] if t["name"] == "opacity-dragged")
    return "\n".join([
        HEADER, "",
        "/// Tint strength of a state colour over the surface below it (`opacity-dragged`).",
        f"const double kOpacityDragged = {number(dragged['value'])};", "",
    ])


def render_all(tokens: dict, app_tokens: dict) -> dict[str, str]:
    return {
        "color_schemes.g.dart": render_color_schemes(tokens),
        "mx_colors_extension.g.dart": render_mx_colors(tokens),
        "app_dimens.g.dart": render_dimens(tokens, app_tokens),
        "text_theme.g.dart": render_text_theme(tokens),
        "token_constants.g.dart": render_constants(tokens),
    }


DESIGN_NAME = "MemoX V8"
DESIGN_DESCRIPTION = (
    "A quiet, focused study space for spaced-repetition flashcards, "
    "in a light and a dark theme generated from one token file."
)
FRONTMATTER_FENCE = "---\n"


def kebab(name: str) -> str:
    """'surfaceContainerHigh' / 'success-onColor' -> 'surface-container-high' / 'success-on-color'."""
    return re.sub(r"(?<=[a-z0-9])([A-Z])", r"-\1", name).lower()


def hex_upper(value: str) -> str:
    return "#" + value.lstrip("#").upper()


def design_colors(tokens: dict) -> list[tuple[str, dict]]:
    """(frontmatter key, token) for the 46 Material roles, then the 16 extension fields."""
    entries = [(kebab(role["name"]), role) for role in m3_roles(tokens)]
    entries += [(kebab(field), token) for field, _, token in extension_fields(tokens)]
    return entries


def type_styles(tokens: dict) -> list[tuple[dict, str]]:
    """(style, Flutter slot) for the twelve roles, in the Design System's order."""
    return [
        (style, SLOT_PATTERN.search(style["usage"]).group(1))
        for group in tokens["type"]["groups"]
        for style in group["styles"]
    ]


def token_value(tokens: dict, group: str, name: str) -> str:
    return next(t["value"] for t in tokens[group]["tokens"] if t["name"] == name)


def app_value(app_tokens: dict, name: str) -> str:
    return f"{number(str(next(t['value'] for t in app_tokens['tokens'] if t['name'] == name)))}px"


def style_of(tokens: dict, slot: str) -> str:
    return next(style["name"] for style, found in type_styles(tokens) if found == slot)


def design_components(tokens: dict, app_tokens: dict) -> list[tuple[str, dict[str, str]]]:
    """The component themes of app_component_themes.dart, in the eight-prop schema."""
    label = f"{{typography.{style_of(tokens, 'labelLarge')}}}"
    meta = f"{{typography.{style_of(tokens, 'labelMedium')}}}"
    body = f"{{typography.{style_of(tokens, 'bodyMedium')}}}"
    button = token_value(tokens, "size", "size-button")
    pad = token_value(tokens, "spacing", "space-24")
    chip = app_value(app_tokens, "sizeChip")

    def filled(fill: str, ink: str) -> dict[str, str]:
        return {
            "backgroundColor": f"{{colors.{fill}}}", "textColor": f"{{colors.{ink}}}",
            "typography": label, "rounded": "{rounded.full}", "height": button, "padding": f"0 {pad}",
        }  # fmt: skip

    return [
        ("button-primary", filled("primary", "on-primary")),
        ("button-secondary", filled("surface-container", "on-surface")),
        ("button-outline", {"textColor": "{colors.primary}", "typography": label,
                            "rounded": "{rounded.full}", "height": button, "padding": f"0 {pad}"}),
        ("button-destructive", filled("error", "on-error")),
        ("card", {"backgroundColor": "{colors.card-surface}", "rounded": "{rounded.md}", "padding": pad}),
        ("search-field", {"backgroundColor": "{colors.search-surface}", "textColor": "{colors.on-surface}",
                          "typography": meta, "rounded": "{rounded.full}",
                          "height": token_value(tokens, "size", "size-search")}),
        ("text-field", {"backgroundColor": "{colors.surface-container-low}", "textColor": "{colors.on-surface}",
                        "typography": body, "rounded": "{rounded.md}", "height": app_value(app_tokens, "sizeInput")}),
        ("chip", {"backgroundColor": "{colors.secondary-container}",
                  "textColor": "{colors.on-secondary-container}", "typography": meta,
                  "rounded": "{rounded.sm}", "height": chip}),
        ("filter-chip-selected", {"backgroundColor": "{colors.primary}", "textColor": "{colors.on-primary}",
                                  "typography": label, "rounded": "{rounded.full}", "height": chip}),
        ("nav-indicator", {"backgroundColor": "{colors.secondary-container}",
                           "textColor": "{colors.on-secondary-container}", "rounded": "{rounded.full}",
                           "width": token_value(tokens, "size", "size-nav-indicator-width"),
                           "height": token_value(tokens, "size", "size-nav-indicator-height")}),
    ]  # fmt: skip


def yaml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def render_frontmatter(tokens: dict, app_tokens: dict) -> str:
    sans = ", ".join(part.strip().strip('"') for part in tokens["type"]["families"]["sans"].split(","))
    out = ["---", f"name: {DESIGN_NAME}", f"description: {DESIGN_DESCRIPTION}", "colors:"]
    out += [f"  {key}: {yaml_string(hex_upper(token['value']['light']))}" for key, token in design_colors(tokens)]
    out.append("typography:")
    for style, _ in type_styles(tokens):
        out += [f"  {style['name']}:", f"    fontFamily: {yaml_string(sans)}",
                f"    fontSize: {yaml_string(style['fontSize'])}", f"    fontWeight: {style['fontWeight']}",
                f"    lineHeight: {yaml_string(style['lineHeight'])}",
                f"    letterSpacing: {yaml_string(style['letterSpacing'])}"]  # fmt: skip
    out.append("rounded:")
    out += [f"  {t['name'].removeprefix('radius-')}: {yaml_string(t['value'])}" for t in tokens["radius"]["tokens"]]
    out.append("spacing:")
    out += [f"  {t['name']}: {yaml_string(t['value'])}" for t in tokens["spacing"]["tokens"]]
    out.append("components:")
    for name, props in design_components(tokens, app_tokens):
        out.append(f"  {name}:")
        out += [f"    {prop}: {yaml_string(value)}" for prop, value in props.items()]
    out.append("---")
    return "\n".join(out) + "\n"


def with_frontmatter(document: str, frontmatter: str) -> str:
    """[document] with its leading YAML block replaced by [frontmatter]."""
    if not document.startswith(FRONTMATTER_FENCE):
        return frontmatter + "\n" + document
    end = document.index("\n" + FRONTMATTER_FENCE, len(FRONTMATTER_FENCE)) + len(FRONTMATTER_FENCE) + 1
    return frontmatter + document[end:]


def frontmatter_of(document: str) -> str:
    if not document.startswith(FRONTMATTER_FENCE):
        return ""
    end = document.index("\n" + FRONTMATTER_FENCE, len(FRONTMATTER_FENCE)) + len(FRONTMATTER_FENCE) + 1
    return document[:end]


def color_role(key: str) -> str:
    for family in ("primary", "secondary", "tertiary", "error", "success", "warning", "info"):
        if family in key:
            return family
    return "neutral"


def resolve(tokens: dict, ref: str) -> str:
    """'{colors.primary}' -> its light value; any other string unchanged."""
    match = re.fullmatch(r"\{(\w+)\.([\w-]+)\}", ref)
    if match is None:
        return ref
    group, key = match.groups()
    if group == "colors":
        return next(hex_upper(t["value"]["light"]) for k, t in design_colors(tokens) if k == key)
    if group == "rounded":
        return token_value(tokens, "radius", f"radius-{key}")
    return ref


def component_css(tokens: dict, name: str, props: dict[str, str]) -> str:
    css = {"backgroundColor": "background", "textColor": "color", "rounded": "border-radius",
           "padding": "padding", "height": "min-height", "width": "min-width"}  # fmt: skip
    rules = [f"{css[prop]}: {resolve(tokens, value)}" for prop, value in props.items() if prop in css]
    if name == "button-outline":
        outline = next(hex_upper(t["value"]["light"]) for k, t in design_colors(tokens) if k == "outline")
        rules.append(f"border: {token_value(tokens, 'stroke', 'stroke-hairline')} solid {outline}")
    return f".ds-{name} {{ " + "; ".join(rules + ["display: inline-flex", "align-items: center"]) + "; }"


_COMPONENT_KINDS = {"button": "button", "card": "card", "search": "input", "text": "input", "chip": "chip",
                    "filter": "chip", "nav": "nav"}  # fmt: skip


def render_sidecar(tokens: dict, app_tokens: dict, narrative: dict) -> str:
    color_meta = {}
    for key, token in design_colors(tokens):
        light, dark = hex_upper(token["value"]["light"]), hex_upper(token["value"]["dark"])
        color_meta[key] = {
            "role": color_role(key), "displayName": key.replace("-", " ").title(), "canonical": light,
            "light": light, "dark": dark, "tonalRamp": list(dict.fromkeys([light, dark])),
            "usage": token.get("usage", ""),
        }  # fmt: skip
    typography_meta = {
        style["name"]: {"displayName": style["name"].replace("-", " ").title(),
                        "flutterRole": slot, "purpose": style["usage"]}
        for style, slot in type_styles(tokens)
    }  # fmt: skip
    breakpoints = [
        {"name": t["name"].removeprefix("breakpoint-"), "value": t["value"]}
        for t in tokens["size"]["tokens"] if t["name"].startswith("breakpoint-")
    ]  # fmt: skip
    components = [
        {"name": name.replace("-", " ").title(), "kind": _COMPONENT_KINDS[name.split("-")[0]], "refersTo": name,
         "description": f"The {name.replace('-', ' ')} of the generated theme.",
         "html": f'<span class="ds-{name}">Aa</span>', "css": component_css(tokens, name, props)}
        for name, props in design_components(tokens, app_tokens)
    ]  # fmt: skip
    data = {
        "schemaVersion": 2,
        "title": f"Design System: {DESIGN_NAME}",
        "extensions": {
            "colorMeta": color_meta,
            "typographyMeta": typography_meta,
            "shadows": [{"name": t["name"], "value": t["value"]["light"], "dark": t["value"]["dark"],
                         "purpose": t["usage"]} for t in tokens["shadow"]["tokens"]],
            "motion": [{"name": t["name"], "value": t["value"], "purpose": t["usage"]}
                       for t in tokens["motion"]["tokens"]],
            "breakpoints": breakpoints,
        },
        "components": components,
        "narrative": narrative,
    }  # fmt: skip
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def write_design_docs(tokens: dict, app_tokens: dict) -> None:
    document = DESIGN_PATH.read_text(encoding="utf-8")
    DESIGN_PATH.write_text(with_frontmatter(document, render_frontmatter(tokens, app_tokens)), encoding="utf-8")
    narrative = json.loads(SIDECAR_PATH.read_text(encoding="utf-8")).get("narrative", {})
    SIDECAR_PATH.write_text(render_sidecar(tokens, app_tokens, narrative), encoding="utf-8")


_NAME_PATTERNS = {
    "app_dimens.g.dart": ("dimens", re.compile(r"^  final double (\w+);", re.M)),
    "mx_colors_extension.g.dart": ("mxColors", re.compile(r"^  final Color (\w+);", re.M)),
    "color_schemes.g.dart": ("colors", re.compile(r"^  (\w+): Color\(", re.M)),
}


def vanished_names(old: dict[str, str], new: dict[str, str]) -> dict[str, str]:
    """Accessor names the previous generation had and this one lacks, as
    removed_symbols.json entries with an empty replacement to be filled in."""
    gone: dict[str, str] = {}
    for file, (receiver, pattern) in _NAME_PATTERNS.items():
        before = set(pattern.findall(old.get(file, "")))
        after = set(pattern.findall(new.get(file, "")))
        for name in sorted(before - after):
            gone[f"{receiver}.{name}"] = ""
    return gone


def record_vanished(old: dict[str, str], new: dict[str, str]) -> None:
    gone = vanished_names(old, new)
    if not gone:
        return
    path = HERE / "removed_symbols.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    for name, replacement in gone.items():
        data["symbols"].setdefault(name, replacement)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"generate.py: {len(gone)} renamed/removed token(s) added to removed_symbols.json; fill in the replacements")


def write_dart(files: dict[str, str], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, text in files.items():
        (out_dir / name).write_text(text, encoding="utf-8")
    dart = shutil.which("dart")
    if dart is None:
        raise SystemExit("generate.py: `dart` is not on PATH; it formats the generated files")
    subprocess.run([dart, "format", str(out_dir)], check=True, capture_output=True)


def main(argv: list[str]) -> int:
    tokens = json.loads(TOKENS_PATH.read_text(encoding="utf-8"))
    app_tokens = json.loads(APP_TOKENS_PATH.read_text(encoding="utf-8"))
    out_dir = Path(argv[argv.index("--out") + 1]) if "--out" in argv else GENERATED_DIR
    files = render_all(tokens, app_tokens)
    previous = {n: (out_dir / n).read_text(encoding="utf-8") for n in files if (out_dir / n).is_file()}
    write_dart(files, out_dir)
    if "--out" not in argv:
        record_vanished(previous, {n: (out_dir / n).read_text(encoding="utf-8") for n in files})
        write_design_docs(tokens, app_tokens)
    print(f"generate.py: wrote {len(files)} files to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
