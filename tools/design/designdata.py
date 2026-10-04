"""Reads, validates and resolves the structured design data in DESIGN.md.

The DESIGN.md frontmatter is the only source of the values the app uses
(spec 2026-10-04-sp3a §4.1, D13). This module reads it with a strict reader
for a YAML subset (nested mappings of scalars; no lists, anchors or flow
collections), checks it against the schema, computes the derived colours and
checks every contrast pair. It never reads a value from the Markdown prose.

Pure functions over text, so the tests feed strings.
"""
from __future__ import annotations

import math
import re
from dataclasses import dataclass, field

M3_ROLES = (
    "primary", "on-primary", "primary-container", "on-primary-container",
    "secondary", "on-secondary", "secondary-container", "on-secondary-container",
    "tertiary", "on-tertiary", "tertiary-container", "on-tertiary-container",
    "error", "on-error", "error-container", "on-error-container",
    "surface", "on-surface", "on-surface-variant", "outline", "outline-variant",
    "shadow", "scrim", "inverse-surface", "on-inverse-surface", "inverse-primary",
    "primary-fixed", "primary-fixed-dim", "on-primary-fixed", "on-primary-fixed-variant",
    "secondary-fixed", "secondary-fixed-dim", "on-secondary-fixed", "on-secondary-fixed-variant",
    "tertiary-fixed", "tertiary-fixed-dim", "on-tertiary-fixed", "on-tertiary-fixed-variant",
    "surface-dim", "surface-bright", "surface-container-lowest", "surface-container-low",
    "surface-container", "surface-container-high", "surface-container-highest",
)
SEMANTIC_COLORS = (
    "mastery", "on-mastery", "success", "warning", "on-warning", "warning-ink",
    "error-fill", "on-error-fill", "status-new", "status-learning",
    "status-reviewing", "status-mastered", "streak",
)
TYPE_SLOTS = (
    "display-large", "display-medium", "display-small",
    "headline-large", "headline-medium", "headline-small",
    "title-large", "title-medium", "title-small",
    "body-large", "body-medium", "body-small",
    "label-large", "label-medium", "label-small",
)
SHADOWS = ("whisper", "chrome", "overlay", "fab")
THEMES = ("light", "dark")
NUMBER_SECTIONS = ("opacity", "stroke", "motion", "size", "icon-size", "breakpoints", "effects")
PX_SECTIONS = ("spacing", "rounded")
REQUIRED = (
    "colors", "colors-dark", "derived", "contrast", "type-slots", "typography",
    *PX_SECTIONS, *NUMBER_SECTIONS, "shadows", "shadows-dark",
)
HEX = re.compile(r"^#[0-9A-F]{6}$")
PX = re.compile(r"^(-?\d+(?:\.\d+)?)px$")
NUMBER = re.compile(r"^-?\d+(?:\.\d+)?$")
KEY = re.compile(r"^[A-Za-z][A-Za-z0-9-]*$")


class SourceError(Exception):
    """The frontmatter cannot be read at all."""


def read_frontmatter(text: str) -> tuple[dict, list[str], int]:
    """Return (mapping, body lines, number of the body's first line)."""
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise SourceError("DESIGN.md must open with a `---` frontmatter line")
    try:
        end = lines.index("---", 1)
    except ValueError:
        raise SourceError("the frontmatter has no closing `---` line") from None
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    for number, line in enumerate(lines[1:end], 2):
        if not line.strip():
            continue
        if "\t" in line:
            raise SourceError(f"line {number}: tabs are not allowed")
        indent = len(line) - len(line.lstrip(" "))
        key, colon, raw = line.strip().partition(":")
        if not colon or not KEY.match(key):
            raise SourceError(f"line {number}: expected `key: value`, got `{line.strip()}`")
        while stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        if key in parent:
            raise SourceError(f"line {number}: duplicate key `{key}`")
        value = raw.strip()
        if not value:
            child: dict = {}
            parent[key] = child
            stack.append((indent, child))
            continue
        parent[key] = _scalar(value, number)
    return root, lines[end + 1:], end + 2


def _scalar(value: str, number: int) -> str:
    if value[0] in "\"'":
        if len(value) < 2 or value[-1] != value[0]:
            raise SourceError(f"line {number}: unterminated quoted value")
        return value[1:-1]
    if value[0] in "[{&*!|>#":
        raise SourceError(f"line {number}: `{value}` uses YAML outside the supported subset")
    return value


def camel(key: str) -> str:
    head, *rest = key.split("-")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def to_rgb(hex_value: str) -> tuple[int, int, int]:
    return tuple(int(hex_value[i:i + 2], 16) for i in (1, 3, 5))  # type: ignore[return-value]


def to_hex(rgb: tuple[float, float, float]) -> str:
    # Half-up rounding, as Dart's round() does: Python's round() is
    # half-to-even and would drift a channel by one.
    return "#" + "".join(f"{int(math.floor(c + 0.5)):02X}" for c in rgb)


def lerp(base: str, toward: str, amount: float) -> str:
    a, b = to_rgb(base), to_rgb(toward)
    return to_hex(tuple(a[i] + (b[i] - a[i]) * amount for i in range(3)))


def luminance(hex_value: str) -> float:
    def channel(c: int) -> float:
        s = c / 255
        return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(c) for c in to_rgb(hex_value))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


@dataclass(frozen=True)
class Colour:
    """An opaque `#RRGGBB` plus an alpha (1.0 for every stated colour)."""

    hex: str
    alpha: float = 1.0

    def argb(self) -> str:
        return f"0x{int(math.floor(self.alpha * 255 + 0.5)):02X}{self.hex[1:]}"


@dataclass
class DerivedRule:
    base: str
    toward: str | None
    amount: float | None
    alpha: float | None

    def describe(self) -> str:
        if self.alpha is not None:
            return f"{self.base} at {self.alpha:.0%}"
        return f"{self.base} → {self.toward} {self.amount:.0%}"


@dataclass
class TypeRole:
    family: str
    size: float
    weight: int
    height: float
    letter_spacing: float
    tabular: bool


@dataclass
class Shadow:
    x: float
    y: float
    blur: float
    alpha: float


@dataclass
class DesignData:
    colors: dict[str, dict[str, Colour]]
    rules: dict[str, dict[str, DerivedRule]]
    contrast: list[tuple[str, str, float]]
    type_roles: dict[str, TypeRole]
    type_slots: dict[str, str]
    numbers: dict[str, dict[str, float]]
    shadows: dict[str, dict[str, Shadow]]
    measured: list[tuple[str, str, str, float, float]] = field(default_factory=list)

    def all_hex(self) -> set[str]:
        return {c.hex for theme in self.colors.values() for c in theme.values()}


def load(text: str) -> tuple[DesignData | None, list[str]]:
    """Validate the frontmatter of [text]; return the data or the errors."""
    try:
        front, _, _ = read_frontmatter(text)
    except SourceError as error:
        return None, [str(error)]
    errors: list[str] = []
    for key in REQUIRED:
        if not isinstance(front.get(key), dict):
            errors.append(f"frontmatter: `{key}` is missing or not a mapping")
    if errors:
        return None, errors

    colors = {
        "light": _colours(front["colors"], "colors", errors),
        "dark": _colours(front["colors-dark"], "colors-dark", errors),
    }
    rules = _rules(front["derived"], set(M3_ROLES + SEMANTIC_COLORS), errors)
    if not errors:
        for name, by_theme in rules.items():
            for theme, rule in by_theme.items():
                colors[theme][name] = _resolve(rule, colors[theme])
    data = DesignData(
        colors=colors,
        rules=rules,
        contrast=_pairs(front["contrast"], colors["light"], errors),
        type_roles=_type_roles(front["typography"], errors),
        type_slots=_type_slots(front["type-slots"], front["typography"], errors),
        numbers=_numbers(front, errors),
        shadows={t: _shadows(front[k], k, errors) for t, k in (("light", "shadows"), ("dark", "shadows-dark"))},
    )
    if not errors:
        _measure(data, errors)
    return (None, errors) if errors else (data, [])


def _colours(section: dict, name: str, errors: list[str]) -> dict[str, Colour]:
    expected = set(M3_ROLES + SEMANTIC_COLORS)
    for missing in sorted(expected - section.keys()):
        errors.append(f"{name}: `{missing}` is missing")
    for extra in sorted(section.keys() - expected):
        errors.append(f"{name}: `{extra}` is neither a Material 3 role nor a MemoX colour")
    out: dict[str, Colour] = {}
    for key in M3_ROLES + SEMANTIC_COLORS:
        value = section.get(key)
        if value is None:
            continue
        if not isinstance(value, str) or not HEX.match(value):
            errors.append(f"{name}.{key}: `{value}` is not an upper-case #RRGGBB")
            continue
        out[key] = Colour(value)
    return out


def _rules(section: dict, colour_names: set[str], errors: list[str]) -> dict[str, dict[str, DerivedRule]]:
    out: dict[str, dict[str, DerivedRule]] = {}
    for name, by_theme in section.items():
        if name in colour_names:
            errors.append(f"derived.{name}: a derived colour cannot reuse a stated colour's name")
            continue
        if not isinstance(by_theme, dict) or set(by_theme) != set(THEMES):
            errors.append(f"derived.{name}: needs exactly `light` and `dark`")
            continue
        out[name] = {}
        for theme in THEMES:
            rule = _rule(by_theme[theme], f"derived.{name}.{theme}", colour_names, errors)
            if rule is not None:
                out[name][theme] = rule
    return out


def _rule(raw: object, where: str, names: set[str], errors: list[str]) -> DerivedRule | None:
    if not isinstance(raw, dict):
        errors.append(f"{where}: must be a mapping")
        return None
    base = raw.get("base")
    if base not in names:
        errors.append(f"{where}: base `{base}` is not a stated colour")
        return None
    if set(raw) == {"base", "alpha"}:
        alpha = _fraction(raw["alpha"], f"{where}.alpha", errors)
        return None if alpha is None else DerivedRule(base, None, None, alpha)
    if set(raw) == {"base", "toward", "amount"}:
        if raw["toward"] not in names:
            errors.append(f"{where}: toward `{raw['toward']}` is not a stated colour")
            return None
        amount = _fraction(raw["amount"], f"{where}.amount", errors)
        return None if amount is None else DerivedRule(base, raw["toward"], amount, None)
    errors.append(f"{where}: keys must be `base, toward, amount` or `base, alpha`")
    return None


def _fraction(raw: object, where: str, errors: list[str]) -> float | None:
    if not isinstance(raw, str) or not NUMBER.match(raw) or not 0 <= float(raw) <= 1:
        errors.append(f"{where}: `{raw}` is not a number from 0 to 1")
        return None
    return float(raw)


def _resolve(rule: DerivedRule, theme: dict[str, Colour]) -> Colour:
    base = theme[rule.base].hex
    if rule.alpha is not None:
        return Colour(base, rule.alpha)
    return Colour(lerp(base, theme[rule.toward].hex, rule.amount))  # type: ignore[arg-type]


def _pairs(section: dict, light: dict[str, Colour], errors: list[str]) -> list[tuple[str, str, float]]:
    pairs: list[tuple[str, str, float]] = []
    for fg, grounds in section.items():
        if fg not in light:
            errors.append(f"contrast.{fg}: not a stated or derived colour")
            continue
        if not isinstance(grounds, dict) or not grounds:
            errors.append(f"contrast.{fg}: must map grounds to a floor")
            continue
        for ground, floor in grounds.items():
            if ground not in light or light[ground].alpha != 1.0:
                errors.append(f"contrast.{fg}.{ground}: the ground is not an opaque colour")
            elif floor not in ("3", "4.5"):
                errors.append(f"contrast.{fg}.{ground}: the floor is 3 or 4.5, got `{floor}`")
            else:
                pairs.append((fg, ground, float(floor)))
    return pairs


def _measure(data: DesignData, errors: list[str]) -> None:
    for theme in THEMES:
        palette = data.colors[theme]
        for fg, ground, floor in data.contrast:
            ratio = contrast(palette[fg].hex, palette[ground].hex)
            data.measured.append((theme, fg, ground, floor, ratio))
            if palette[fg].alpha != 1.0:
                errors.append(f"contrast.{fg}: a translucent colour has no fixed contrast")
            elif ratio < floor:
                errors.append(f"contrast ({theme}): {fg} on {ground} is {ratio:.2f}:1, below {floor:g}:1")


def _type_roles(section: dict, errors: list[str]) -> dict[str, TypeRole]:
    roles: dict[str, TypeRole] = {}
    for name, raw in section.items():
        where = f"typography.{name}"
        if not isinstance(raw, dict):
            errors.append(f"{where}: must be a mapping")
            continue
        size = PX.match(raw.get("fontSize", ""))
        spacing = PX.match(raw.get("letterSpacing", "0px"))
        weight, height = raw.get("fontWeight", ""), raw.get("lineHeight", "")
        if not size or not spacing or not weight.isdigit() or not NUMBER.match(height):
            errors.append(f"{where}: needs fontSize and letterSpacing in px, a numeric fontWeight and lineHeight")
            continue
        if raw.get("fontFeature", "tnum") != "tnum":
            errors.append(f"{where}: the only supported fontFeature is `tnum`")
            continue
        roles[name] = TypeRole(
            family=raw.get("fontFamily", ""),
            size=float(size[1]),
            weight=int(weight),
            height=float(height),
            letter_spacing=float(spacing[1]),
            tabular=raw.get("fontFeature") == "tnum",
        )
    families = {role.family for role in roles.values()}
    if len(families) > 1:
        errors.append(f"typography: one family is expected, found {sorted(families)}")
    return roles


def _type_slots(section: dict, roles: dict, errors: list[str]) -> dict[str, str]:
    for missing in sorted(set(TYPE_SLOTS) - section.keys()):
        errors.append(f"type-slots: `{missing}` is missing")
    for extra in sorted(section.keys() - set(TYPE_SLOTS)):
        errors.append(f"type-slots: `{extra}` is not a Material 3 TextTheme slot")
    for slot, role in section.items():
        if role not in roles:
            errors.append(f"type-slots.{slot}: `{role}` is not a typography role")
    return {slot: section[slot] for slot in TYPE_SLOTS if slot in section}


def _numbers(front: dict, errors: list[str]) -> dict[str, dict[str, float]]:
    out: dict[str, dict[str, float]] = {}
    for section in PX_SECTIONS + NUMBER_SECTIONS:
        out[section] = {}
        for key, raw in front[section].items():
            pattern = PX if section in PX_SECTIONS else NUMBER
            match = pattern.match(raw) if isinstance(raw, str) else None
            if match is None:
                errors.append(f"{section}.{key}: `{raw}` is not a {'px value' if section in PX_SECTIONS else 'number'}")
                continue
            out[section][key] = float(match[1] if section in PX_SECTIONS else match[0])
    return out


def _shadows(section: dict, name: str, errors: list[str]) -> dict[str, Shadow]:
    out: dict[str, Shadow] = {}
    if set(section) != set(SHADOWS):
        errors.append(f"{name}: needs exactly {', '.join(SHADOWS)}")
    for key in SHADOWS:
        raw = section.get(key)
        if not isinstance(raw, dict) or set(raw) != {"x", "y", "blur", "alpha"}:
            errors.append(f"{name}.{key}: needs x, y, blur and alpha")
            continue
        if not all(isinstance(v, str) and NUMBER.match(v) for v in raw.values()):
            errors.append(f"{name}.{key}: every value is a number")
            continue
        out[key] = Shadow(*(float(raw[k]) for k in ("x", "y", "blur", "alpha")))
    return out


HEX_IN_PROSE = re.compile(r"#[0-9A-Fa-f]{6}\b")


def prose_drift(body: list[str], first_line: int, data: DesignData, skip: tuple[str, str]) -> list[str]:
    """Hex codes the prose names that are not a design value. Reads no value."""
    known = data.all_hex()
    problems: list[str] = []
    inside = False
    for number, line in enumerate(body, first_line):
        if line.strip() == skip[0]:
            inside = True
        elif line.strip() == skip[1]:
            inside = False
        elif not inside:
            for found in HEX_IN_PROSE.findall(line):
                if found.upper() not in known:
                    problems.append(f"DESIGN.md:{number}: {found} is not a value of the frontmatter")
    return problems
