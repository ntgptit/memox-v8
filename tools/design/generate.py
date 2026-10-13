#!/usr/bin/env python3
"""Generates the theme code from design/tokens.json (+ design/app_tokens.json).

Writes lib/core/theme/generated/*.g.dart and formats them with `dart format`.
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
    print(f"generate.py: wrote {len(files)} files to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
