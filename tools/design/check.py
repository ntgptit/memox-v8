#!/usr/bin/env python3
"""Design-system gate (ADR-025).

  check.py --symbols   removed theme names/paths still present in lib/ or test/
  check.py             everything: symbols, unfilled replacements, the theme's
                       closed file list and ThemeContext getters, colour values
                       outside the palette files, and values in DESIGN.md prose

The values themselves live in Dart (lib/core/theme/app_palette.dart and
mx_status_colors.dart); test/tools/design_doc_test.dart proves DESIGN.md's
frontmatter and .impeccable/design.json equal a rendering of them.

Exit 0 = clean, 1 = problems (printed). Python >= 3.12, standard library only.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

import removed_symbols  # noqa: E402

DART_ROOTS = ("lib", "test", "integration_test")
DESIGN_PATH = REPO_ROOT / "DESIGN.md"
SIDECAR_PATH = REPO_ROOT / ".impeccable/design.json"


def unfilled_replacements(data: dict) -> list[str]:
    """Entries whose replacement text is still empty."""
    return [
        f"removed_symbols.json: '{name}' has no replacement text"
        for name, text in data["symbols"].items()
        if not text.strip()
    ]


def symbol_problems(root: Path) -> list[str]:
    removed, files = removed_symbols.load()
    problems: list[str] = []
    for listed in files:
        if (root / listed).exists():
            problems.append(f"{listed} must not exist (listed in removed_symbols.json)")
    for top in DART_ROOTS:
        for path in sorted((root / top).rglob("*.dart")) if (root / top).is_dir() else []:
            text = path.read_text(encoding="utf-8", errors="replace")
            for entry, line in removed_symbols.find(text, removed):
                relative = path.relative_to(root).as_posix()
                problems.append(f"{relative}:{line} uses removed '{entry.name}' -> {entry.replacement}")
    return problems


THEME_DIR = Path("lib/core/theme")
# ADR-025: the closed list of theme files. The palette files are the only
# Dart that writes a colour value.
THEME_FILES = frozenset({
    "app_theme.dart", "app_palette.dart", "app_typography.dart", "app_dimens.dart",
    "mx_status_colors.dart", "app_icons.dart", "color_tint.dart", "theme_rules.dart",
    "theme_context.dart", "mastery_ramp.dart",
})  # fmt: skip
PALETTE_FILES = frozenset({THEME_DIR / "app_palette.dart", THEME_DIR / "mx_status_colors.dart"})
THEME_CONTEXT_GETTERS = ("colors", "texts", "status", "dimens", "radii", "hairline")

# A colour written as a value: a hex literal or a Material swatch.
COLOR_VALUE = re.compile(r"\bColor\(\s*0x[0-9A-Fa-f]+|\bColors\.\w+|\bColor\.fromRGBO\(\s*\d")


def theme_file_problems(root: Path) -> list[str]:
    theme = root / THEME_DIR
    problems: list[str] = []
    for path in sorted(p for p in theme.rglob("*") if p.is_file()):
        relative = path.relative_to(theme)
        if relative.parent != Path(".") or relative.name not in THEME_FILES:
            problems.append(f"{THEME_DIR / relative}: not an allowed theme file (ADR-025)")
    return problems


def theme_context_problems(root: Path) -> list[str]:
    path = root / THEME_DIR / "theme_context.dart"
    getters = tuple(re.findall(r"^  [\w<>?]+ get (\w+)\b", path.read_text(encoding="utf-8"), re.M))
    if getters == THEME_CONTEXT_GETTERS:
        return []
    return [f"theme_context.dart: getters {list(getters)}, expected exactly {list(THEME_CONTEXT_GETTERS)}"]


def color_value_problems(root: Path) -> list[str]:
    """A colour value in lib/ outside the two palette files."""
    problems: list[str] = []
    lib = root / "lib"
    for path in sorted(lib.rglob("*.dart")) if lib.is_dir() else []:
        relative = path.relative_to(root)
        if relative in PALETTE_FILES or path.name.endswith(".g.dart"):
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if line.lstrip().startswith("//"):
                continue
            if match := COLOR_VALUE.search(line):
                problems.append(
                    f"{relative.as_posix()}:{number}: a colour value ({match.group(0)}); "
                    "colours are written in app_palette.dart or mx_status_colors.dart only"
                )
    return problems


def structure_problems(root: Path = REPO_ROOT) -> list[str]:
    return theme_file_problems(root) + theme_context_problems(root) + color_value_problems(root)


# A value belongs to the palette or the theme; prose names the role. Ratios
# such as 4.5:1 are not values and stay legal.
PROSE_VALUE = re.compile(r"#[0-9A-Fa-f]{6}\b|\b\d+(?:\.\d+)?\s?(?:px|dp|sp|ms)\b|\b\d+(?:\.\d+)?%")


def _strings(value: object) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [text for item in value.values() for text in _strings(item)]
    if isinstance(value, list):
        return [text for item in value for text in _strings(item)]
    return []


def frontmatter_of(document: str) -> str:
    """The `---` block that opens [document], closing line included."""
    if not document.startswith("---\n"):
        return ""
    end = document.find("\n---\n", 4)
    return document[: end + 5] if end >= 0 else ""


def design_doc_problems(document: str, sidecar: str) -> list[str]:
    """No value written into the hand-written parts of DESIGN.md or the
    sidecar's narrative; the rendered parts are design_doc_test.dart's."""
    problems: list[str] = []
    front = frontmatter_of(document)
    if not front:
        problems.append("DESIGN.md: no frontmatter; run MEMOX_WRITE_DESIGN_DOCS=1 on test/tools/design_doc_test.dart")
    for number, line in enumerate(document[len(front):].splitlines(), start=front.count("\n") + 1):
        if match := PROSE_VALUE.search(line):
            problems.append(f"DESIGN.md:{number}: a value in the prose ({match.group(0)}); name the role")
    narrative = json.loads(sidecar).get("narrative", {})
    for text in _strings(narrative):
        if match := PROSE_VALUE.search(text):
            problems.append(f".impeccable/design.json: a value in the narrative ({match.group(0)}); name the role")
    return problems


def main(argv: list[str]) -> int:
    problems = symbol_problems(REPO_ROOT)
    if "--symbols" not in argv:
        data = json.loads(removed_symbols.SYMBOLS_FILE.read_text(encoding="utf-8"))
        problems += unfilled_replacements(data)
        problems += structure_problems()
        problems += design_doc_problems(
            DESIGN_PATH.read_text(encoding="utf-8"),
            SIDECAR_PATH.read_text(encoding="utf-8"),
        )
    for problem in problems:
        print(problem)
    if problems:
        print(f"check.py: {len(problems)} problem(s)")
        return 1
    print("check.py: clean")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
