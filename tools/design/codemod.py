#!/usr/bin/env python3
"""Mechanical 1:1 migration from the removed theme names to the new ones.

Applies only renames whose target is unambiguous by role (see the tables
below, taken from the owner's mapping tables). Anything that needs judgement is
left as it is, so it fails to compile and shows up in `flutter analyze`:
`AppRadius.full`, single-use constants, `MasteryRamp` calls, `AppDecorations`.

  codemod.py [PATH ...] [--dry-run]   default PATH: lib test integration_test
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
D = "context.dimens."

SPACING = {
    "micro": "space4", "control": "space8", "grouped": "space12", "card": "space24",
    "section": "space24", "major": "space32", "pageEnd": "space48",
}  # fmt: skip
RADIUS = {"xs": "radiusXs", "sm": "radiusSm", "md": "radiusMd", "lg": "radiusLg", "xl": "radiusXl"}
SIZE = {
    "touchTarget": "sizeControl", "listRowMin": "sizeControl", "buttonRegular": "sizeButton",
    "buttonSmall": "sizeButtonSmall", "buttonCompact": "sizeButtonSmall", "navRail": "sizeRail",
    "navRailBreakpoint": "breakpointMedium", "contentMaxWidth": "sizeContentMax",
    "bottomNavBar": "sizeNav", "bottomNavBlock": "sizeNav", "chip": "sizeChip",
    "input": "sizeInput", "fab": "sizeFab", "appBar": "sizeAppBar",
}  # fmt: skip
ICON = {"standard": "sizeIcon", "large": "sizeIconTile", "inline": "sizeIconInline", "compact": "sizeIconCompact"}
STROKE = {"hairline": "strokeHairline", "focus": "strokeFocus", "control": "strokeControl", "indicator": "strokeIndicator"}
OPACITY = {"disabled": "opacityDisabledContent", "muted": "opacityMuted", "pressed": "opacityPressed"}
DURATION = {
    "standard": "Durations.short4", "toggle": "Durations.short3",
    "sheet": "Durations.medium2", "scrimFade": "Durations.short4",
}  # fmt: skip
DIMENS_TABLES = {
    "AppSpacing": SPACING, "AppRadius": RADIUS, "AppSize": SIZE, "AppIconSize": ICON,
    "AppStroke": STROKE, "AppOpacity": OPACITY,
}  # fmt: skip

# Text colours: None = the role's own (onSurface).
INK = {
    "V": "context.colors.onSurfaceVariant", "A": "context.accentColor",
    "E": "context.colors.error", "S": "context.colors.onSurface",
    "INV": "context.colors.onInverseSurface", "INVP": "context.colors.inversePrimary",
}  # fmt: skip
TEXT_GETTERS = {
    "buttonLabel": ("labelLarge", None), "buttonLabelSmall": ("labelLarge", None),
    "buttonDetail": ("labelMedium", None), "contentTitle": ("titleMedium", None),
    "screenTitle": ("titleLarge", None), "emptyTitle": ("titleMedium", None),
    "emptyTitleCompact": ("titleSmall", None), "emptyBody": ("bodyMedium", "V"),
    "emptyBodyStrong": ("titleSmall", None), "breadcrumbAncestor": ("labelMedium", "V"),
    "breadcrumbCurrent": ("titleSmall", None), "counter": ("labelSmall", "V"),
    "footerCaption": ("labelSmall", "V"), "inputHint": ("bodyMedium", "V"),
    "disclosureLabel": ("labelMedium", "A"), "fieldCode": ("displaySmall", None),
    "searchValue": ("labelMedium", None), "searchHint": ("labelMedium", "V"),
    "rowTitle": ("titleSmall", None), "rowTitleMatch": ("titleSmall", "A"),
    "rowDescription": ("bodyMedium", "V"), "listRowTitle": ("titleSmall", None),
    "rowSubtitle": ("bodyMedium", "V"), "settingsLabel": ("titleSmall", None),
    "overline": ("labelSmall", None), "eyebrow": ("labelSmall", "V"),
    "fieldLabel": ("labelMedium", None), "statLabel": ("labelSmall", "V"),
    "requiredMarker": ("bodyMedium", "A"), "historyAgo": ("labelSmall", None),
    "removableTagLabel": ("labelSmall", "A"), "tagLabel": ("labelSmall", "V"),
    "noteText": ("bodyMedium", "V"), "studyTerm": ("displaySmall", None),
    "studyMeaning": ("bodyLarge", None), "studyDetail": ("bodyMedium", "V"),
    "sessionHint": ("bodyMedium", "V"), "summaryTitle": ("titleMedium", None),
    "summaryBodyStrong": ("titleSmall", None), "studyPassage": ("bodyLarge", None),
    "workloadText": ("labelMedium", "V"), "compactTitle": ("titleSmall", None),
    "dialogBody": ("bodyMedium", None), "bannerTitle": ("labelMedium", None),
    "snackbarMessage": ("bodyMedium", "INV"), "snackbarAction": ("labelLarge", "INVP"),
}  # fmt: skip
# One positional colour argument.
INK_FUNCTIONS = {
    "studyBadge": "labelSmall", "stepNumber": "labelSmall", "chipCount": "labelSmall",
    "fieldMessage": "labelSmall", "statValue": "displayMedium", "statusLabel": "labelSmall",
    "historyMove": "labelMedium", "badgeLabel": "labelSmall", "statusNote": "bodyMedium",
    "captionIn": "labelSmall", "factValue": "bodyLarge", "studyOption": "bodySmall",
    "studyOptionLetter": "labelSmall", "matchTerm": "headlineSmall",
    "matchMeaning": "bodySmall", "workloadTerm": "labelMedium", "donutLabel": "labelSmall",
}  # fmt: skip
# One named bool: (role, colour when true, colour when false; None drops the argument).
BOOL_FUNCTIONS = {
    "stepLabel": ("labelSmall", "S", "V"), "navLabel": ("labelSmall", "S", "V"),
    "trayLabel": ("labelSmall", "S", "V"), "fieldCount": ("labelSmall", "E", "V"),
    "stepperValue": ("bodyLarge", "E", "S"), "commandLabel": ("titleSmall", "E", "S"),
    "bannerMessage": ("labelMedium", "S", "V"), "dayLabel": ("labelSmall", "V", "V"),
}  # fmt: skip

SEMANTIC = {
    "mastery": "context.mxColors.successContainer", "onMastery": "context.mxColors.onSuccessContainer",
    "success": "context.mxColors.success", "warning": "context.mxColors.warningContainer",
    "onWarning": "context.mxColors.onWarningContainer", "statusNew": "context.colors.outline",
    "statusLearning": "context.mxColors.warningContainer", "statusReviewing": "context.accentColor",
    "statusMastered": "context.mxColors.successContainer", "errorFill": "context.colors.error",
    "onErrorFill": "context.colors.onError", "streak": "context.mxColors.warningContainer",
    "primaryText": "context.accentColor", "masteryText": "context.mxColors.success",
    "learningText": "context.mxColors.warning", "warningText": "context.mxColors.warning",
    "focusRing": "context.colors.primary", "primaryTrack": "context.colors.primary",
    "border": "context.colors.outlineVariant", "neutralTrack": "context.colors.surfaceContainerHighest",
    "primarySoft": "context.accentColor.tintOver(context.colors.surface)",
    "onPrimarySoft": "context.accentColor",
    "successSoft": "context.mxColors.success.tintOver(context.colors.surface)",
    "successBorder": "context.mxColors.success", "onSuccessSoft": "context.mxColors.success",
    "learningSoft": "context.mxColors.warning.tintOver(context.colors.surface)",
    "learningBorder": "context.mxColors.warning", "onLearningSoft": "context.mxColors.warning",
    "warningSoft": "context.mxColors.warning.tintOver(context.colors.surface)",
    "warningBorder": "context.mxColors.warning", "onWarningSoft": "context.mxColors.warning",
    "dangerSoft": "context.colors.error.tintOver(context.colors.surface)",
    "dangerBorder": "context.colors.error", "onDangerSoft": "context.colors.error",
    "neutralSoft": "context.colors.secondaryContainer",
    "onNeutralSoft": "context.colors.onSecondaryContainer", "onSoft": "context.colors.onSurface",
}  # fmt: skip
DERIVED = {
    "dangerSoft": SEMANTIC["dangerSoft"], "dangerBorder": "context.colors.error",
    "warningSoft": SEMANTIC["warningSoft"], "warningBorder": "context.mxColors.warning",
    "successSoft": SEMANTIC["successSoft"], "successBorder": "context.mxColors.success",
    "successInk": "context.mxColors.success",
    "surfaceHero": "context.accentColor.tintOver(context.colors.surface)",
    "chromeGlass": "context.colors.surface", "ghostBorder": "context.colors.outlineVariant",
    "warningInk": "context.mxColors.warning", "dangerInk": "context.colors.error",
    "statusNewInk": "context.colors.onSurfaceVariant", "statusLearningInk": "context.mxColors.warning",
    "statusReviewingInk": "context.accentColor", "statusMasteredInk": "context.mxColors.success",
    "primaryInk": "context.accentColor", "outlineEdge": "context.colors.outline",
}  # fmt: skip

IMPORTS = {
    "context.accentColor": "theme_rules", "context.screenMargin": "theme_rules",
    "context.deckIconColor": "theme_rules", "context.windowSize": "theme_rules",
    "tintOver(": "color_tint", "AppTypography.": "app_typography",
}  # fmt: skip
CONTEXT_USES = ("context.dimens.", "context.colors.", "context.texts.", "context.mxColors.")
IMPORT_PREFIX = "import 'package:memox/core/theme/"


def balanced(text: str, open_index: int) -> int:
    """Index of the ')' closing the '(' at [open_index]; -1 when unbalanced."""
    depth = 0
    for index in range(open_index, len(text)):
        char = text[index]
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                return index
    return -1


def split_top_level(arguments: str) -> list[str]:
    parts: list[str] = []
    depth = 0
    start = 0
    for index, char in enumerate(arguments):
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(arguments[start:index].strip())
            start = index + 1
    tail = arguments[start:].strip()
    if tail:
        parts.append(tail)
    return parts


def with_color(role: str, color: str | None, extra: str = "") -> str:
    if color is None and not extra:
        return f"context.texts.{role}"
    pieces = [piece for piece in (f"color: {color}" if color else "", extra) if piece]
    return f"context.texts.{role}?.copyWith({', '.join(pieces)})"


def text_getter(source: str, match: re.Match[str]) -> tuple[str, int]:
    """Replacement and end offset for `<receiver>.<getter>` at [match]."""
    role, kind = TEXT_GETTERS[match.group("name")]
    color = INK[kind] if kind else None
    end = match.end()
    following = source[end:]
    chained = re.match(r"\.copyWith\(", following)
    if chained:
        open_index = end + chained.end() - 1
        close = balanced(source, open_index)
        arguments = source[open_index + 1 : close]
        has_color = re.search(r"(^|,)\s*color\s*:", arguments) is not None
        lead = f"color: {color}, " if color and not has_color else ""
        return f"context.texts.{role}?.copyWith({lead}{arguments})", close + 1
    if color:
        replacement = with_color(role, color)
        member = re.match(r"\.(?=\w)", following)
        return (replacement + "?", end + 1) if member else (replacement, end)
    member = re.match(r"\.(?=\w)", following)
    return (f"context.texts.{role}?", end + 1) if member else (f"context.texts.{role}", end)


def text_function(source: str, match: re.Match[str]) -> tuple[str, int] | None:
    name = match.group("name")
    open_index = match.end()
    if source[open_index : open_index + 1] != "(":
        return None
    close = balanced(source, open_index)
    arguments = split_top_level(source[open_index + 1 : close])
    if name in INK_FUNCTIONS and len(arguments) == 1 and ":" not in arguments[0].split("(")[0]:
        return with_color(INK_FUNCTIONS[name], arguments[0]), close + 1
    if name in BOOL_FUNCTIONS and len(arguments) == 1:
        role, when_true, when_false = BOOL_FUNCTIONS[name]
        value = arguments[0].split(":", 1)[1].strip()
        if when_true == when_false:
            return with_color(role, INK[when_true]), close + 1
        choice = f"{value} ? {INK[when_true]} : {INK[when_false]}"
        return with_color(role, choice), close + 1
    if name == "fillAnswer":
        ink = arguments[0]
        struck = next(a.split(":", 1)[1].strip() for a in arguments[1:] if a.startswith("isStruck"))
        extra = (
            f"decoration: {struck} ? TextDecoration.lineThrough : null, "
            f"decorationColor: {struck} ? {ink} : null"
        )
        return with_color("displaySmall", ink, extra), close + 1
    return None


def migrate_text(source: str) -> str:
    aliases = re.findall(r"^\s*final (\w+) = context\.textStyles;\n", source, re.M)
    source = re.sub(r"^\s*final \w+ = context\.textStyles;\n", "", source, flags=re.M)
    for alias in aliases:
        source = re.sub(rf"(?<![\w.]){alias}\.(?=\w)", "context.textStyles.", source)
    names = "|".join(sorted({*TEXT_GETTERS, *INK_FUNCTIONS, *BOOL_FUNCTIONS, "fillAnswer", "code"}, key=len, reverse=True))
    pattern = re.compile(rf"context\.textStyles\.(?P<name>{names})\b")
    out: list[str] = []
    cursor = 0
    while True:
        match = pattern.search(source, cursor)
        if match is None:
            out.append(source[cursor:])
            break
        out.append(source[cursor : match.start()])
        name = match.group("name")
        if name == "code":
            out.append("context.texts.bodyMedium?.copyWith(fontFamily: AppTypography.monoFamily)")
            cursor = match.end()
            continue
        if name in TEXT_GETTERS and source[match.end() : match.end() + 1] != "(":
            replacement, cursor = text_getter(source, match)
        else:
            result = text_function(source, match)
            if result is None:
                out.append(match.group(0))
                cursor = match.end()
                continue
            replacement, cursor = result
        out.append(replacement)
    return "".join(out)


def migrate_colors(source: str) -> str:
    for kind, table in (("semanticColors", SEMANTIC), ("derivedColors", DERIVED)):
        aliases = re.findall(rf"^\s*final (\w+) = context\.{kind};\n", source, re.M)
        source = re.sub(rf"^\s*final \w+ = context\.{kind};\n", "", source, flags=re.M)
        for alias in aliases:
            source = re.sub(rf"(?<![\w.]){alias}\.(?=\w)", f"context.{kind}.", source)
        names = "|".join(sorted(table, key=len, reverse=True))
        source = re.sub(
            rf"context\.{kind}\.({names})\b", lambda m, t=table: t[m.group(1)], source
        )
    return source


def migrate_dimens(source: str) -> str:
    for cls, table in DIMENS_TABLES.items():
        source = re.sub(
            rf"\b{cls}\.(\w+)\b",
            lambda m, t=table, c=cls: D + t[m.group(1)] if m.group(1) in t else m.group(0),
            source,
        )
    source = re.sub(
        r"\bAppDurations\.(\w+)\b",
        lambda m: DURATION.get(m.group(1), m.group(0)),
        source,
    )
    return re.sub(
        r"(?P<lead>horizontal:\s*)?\bAppSpacing\.gutter\b",
        lambda m: (m.group("lead") or "") + ("context.screenMargin" if m.group("lead") else D + "space16"),
        source,
    )


def add_imports(source: str) -> str:
    needed = {name for token, name in IMPORTS.items() if token in source}
    if any(use in source for use in CONTEXT_USES):
        needed.add("theme_context")
    if "AppTypography." in source:
        needed.add("app_typography")
    missing = [n for n in sorted(needed) if f"{IMPORT_PREFIX}{n}.dart'" not in source]
    if not missing or "\nimport '" not in "\n" + source:
        return source
    lines = source.split("\n")
    last_import = max(i for i, line in enumerate(lines) if line.startswith("import "))
    for name in reversed(missing):
        lines.insert(last_import + 1, f"{IMPORT_PREFIX}{name}.dart';")
    return "\n".join(lines)


_DELETED_IMPORT = re.compile(
    r"^import 'package:memox/core/theme/(?:foundations/app_(?:spacing|radius|size|icon_size|stroke|"
    r"opacity|durations|effects|shadows)|mx_semantic_colors|mx_derived_colors|mx_text_styles|"
    r"app_color_schemes|app_decorations|app_button_style)\.dart';\n",
    re.M,
)


def drop_deleted_imports(source: str) -> str:
    return _DELETED_IMPORT.sub("", source)


def migrate_source(source: str, path: str) -> tuple[str, list[str]]:
    del path
    log: list[str] = []
    result = migrate_text(source)
    result = migrate_colors(result)
    result = migrate_dimens(result)
    return add_imports(drop_deleted_imports(result)), log


def main(argv: list[str]) -> int:
    dry = "--dry-run" in argv
    targets = [a for a in argv if not a.startswith("--")] or ["lib", "test", "integration_test"]
    changed = 0
    for target in targets:
        root = REPO_ROOT / target
        files = [root] if root.is_file() else sorted(root.rglob("*.dart")) if root.is_dir() else []
        for path in files:
            original = path.read_text(encoding="utf-8")
            migrated, _ = migrate_source(original, path.as_posix())
            if migrated == original:
                continue
            changed += 1
            if not dry:
                path.write_text(migrated, encoding="utf-8")
    print(f"codemod.py: {changed} file(s) {'would change' if dry else 'changed'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
