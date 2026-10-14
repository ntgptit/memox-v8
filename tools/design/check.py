#!/usr/bin/env python3
"""Design-system gate.

  check.py --symbols   removed theme names/paths still present in lib/ or test/
  check.py             everything: symbols, unfilled replacements, the theme's
                       structure, and generated files against design/tokens.json

Exit 0 = clean, 1 = problems (printed). Python >= 3.12, standard library only.
"""

from __future__ import annotations

import json
import re
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

import generate  # noqa: E402
import removed_symbols  # noqa: E402

DART_ROOTS = ("lib", "test", "integration_test")


def unfilled_replacements(data: dict) -> list[str]:
    """Entries whose replacement is still empty (the generator adds renames so)."""
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
# ADR-022: the closed list of hand-written theme files, and the generator's.
THEME_FILES = frozenset({
    "app_theme.dart", "app_component_themes.dart", "app_typography.dart", "app_icons.dart",
    "color_tint.dart", "theme_rules.dart", "theme_context.dart", "mastery_ramp.dart",
    "focus_ring_border.dart",
})  # fmt: skip
THEME_CONTEXT_GETTERS = ("colors", "texts", "mxColors", "dimens")
DIMENS_TOKEN_COUNT = 42


def theme_file_problems(root: Path) -> list[str]:
    theme = root / THEME_DIR
    generated = set(generate.render_all(*generate_inputs()))
    problems: list[str] = []
    for path in sorted(p for p in theme.rglob("*") if p.is_file()):
        relative = path.relative_to(theme)
        if relative.parent == Path("generated"):
            allowed = relative.name in generated
        else:
            allowed = relative.parent == Path(".") and relative.name in THEME_FILES
        if not allowed:
            problems.append(f"{THEME_DIR / relative}: not an allowed theme file (ADR-022)")
    return problems


def theme_context_problems(root: Path) -> list[str]:
    path = root / THEME_DIR / "theme_context.dart"
    getters = tuple(re.findall(r"^  [\w<>?]+ get (\w+)\b", path.read_text(encoding="utf-8"), re.M))
    if getters == THEME_CONTEXT_GETTERS:
        return []
    return [f"theme_context.dart: getters {list(getters)}, expected exactly {list(THEME_CONTEXT_GETTERS)}"]


def extension_problems(root: Path) -> list[str]:
    tokens, app_tokens = generate_inputs()
    generated = root / THEME_DIR / "generated"
    expected_dimens = DIMENS_TOKEN_COUNT + len(app_tokens["tokens"])
    found_tokens = len(generate.dimension_tokens(tokens))
    checks = (
        ("MxColorsExtension", "mx_colors_extension.g.dart", "Color", len(generate.extension_fields(tokens))),
        ("AppDimens", "app_dimens.g.dart", "double", expected_dimens),
    )
    problems: list[str] = []
    if found_tokens != DIMENS_TOKEN_COUNT:
        problems.append(f"tokens.json: {found_tokens} dimension tokens, expected {DIMENS_TOKEN_COUNT}")
    for name, file, kind, expected in checks:
        text = (generated / file).read_text(encoding="utf-8")
        fields = re.findall(rf"^  final {kind} (\w+);", text, re.M)
        if len(fields) != expected:
            problems.append(f"{name}: {len(fields)} fields, expected {expected} from the token files")
    return problems


def structure_problems(root: Path = REPO_ROOT) -> list[str]:
    return theme_file_problems(root) + theme_context_problems(root) + extension_problems(root)


def generate_inputs() -> tuple[dict, dict]:
    tokens = json.loads(generate.TOKENS_PATH.read_text(encoding="utf-8"))
    app_tokens = json.loads(generate.APP_TOKENS_PATH.read_text(encoding="utf-8"))
    return tokens, app_tokens


def generated_problems(committed: Path = generate.GENERATED_DIR) -> list[str]:
    """Generated Dart that differs from a fresh generation of design/tokens.json."""
    fresh_files = generate.render_all(*generate_inputs())
    problems: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        fresh = Path(tmp)
        generate.write_dart(fresh_files, fresh)
        for name in sorted(fresh_files):
            current = committed / name
            if not current.is_file():
                problems.append(f"{name}: missing, run tools/design/generate.py")
                continue
            if current.read_text(encoding="utf-8") != (fresh / name).read_text(encoding="utf-8"):
                problems.append(f"{name}: differs from design/tokens.json, run tools/design/generate.py")
    return problems


# A value belongs to tokens.json; prose names tokens. Ratios such as 4.5:1 are
# not token values and stay legal.
PROSE_VALUE = re.compile(r"#[0-9A-Fa-f]{6}\b|\b\d+(?:\.\d+)?\s?(?:px|dp|sp|ms)\b|\b\d+(?:\.\d+)?%")


def _strings(value: object) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [text for item in value.values() for text in _strings(item)]
    if isinstance(value, list):
        return [text for item in value for text in _strings(item)]
    return []


def design_doc_problems(document: str, sidecar: str) -> list[str]:
    """DESIGN.md and .impeccable/design.json against a fresh generation, and no
    token value written into the hand-written parts of either."""
    tokens, app_tokens = generate_inputs()
    problems: list[str] = []
    front = generate.frontmatter_of(document)
    if front != generate.render_frontmatter(tokens, app_tokens):
        problems.append("DESIGN.md: frontmatter differs from design/tokens.json, run tools/design/generate.py")
    for number, line in enumerate(document[len(front):].splitlines(), start=front.count("\n") + 1):
        if match := PROSE_VALUE.search(line):
            problems.append(f"DESIGN.md:{number}: a value in the prose ({match.group(0)}); name the token")
    data = json.loads(sidecar)
    narrative = data.get("narrative", {})
    if sidecar != generate.render_sidecar(tokens, app_tokens, narrative):
        problems.append(".impeccable/design.json: differs from design/tokens.json, run tools/design/generate.py")
    for text in _strings(narrative):
        if match := PROSE_VALUE.search(text):
            problems.append(f".impeccable/design.json: a value in the narrative ({match.group(0)}); name the token")
    return problems


def main(argv: list[str]) -> int:
    problems = symbol_problems(REPO_ROOT)
    if "--symbols" not in argv:
        data = json.loads(removed_symbols.SYMBOLS_FILE.read_text(encoding="utf-8"))
        problems += unfilled_replacements(data)
        problems += structure_problems()
        problems += generated_problems()
        problems += design_doc_problems(
            generate.DESIGN_PATH.read_text(encoding="utf-8"),
            generate.SIDECAR_PATH.read_text(encoding="utf-8"),
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
