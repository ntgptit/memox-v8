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
# Every public top-level `Mx*` type, whatever it extends: a component is known by
# the catalog, not by its superclass's name (final review #7).
MX_TYPE = re.compile(r"^(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*(?:class|enum|mixin|typedef|extension\s+type)\s+(Mx[A-Z]\w*)\b", re.M)
MX_GOLDEN = re.compile(r"^(mx_[a-z0-9_]+?)__([a-z0-9_]+)__([a-z0-9_]+)\.png$")
PROSE_INK = re.compile(
    r"\b(?i:(?:primary|secondary|tertiary|status|success|warning|danger|error|learning|reviewing"
    r"|mastered|new|indigo|variant|its|their|plain|the|dark|light|white|black)[- ]ink)\b"
)
# camelCase (also `_private`), snake_case and PascalCase spellings of an ink role.
# Flutter's own `Ink`, `InkWell`, `InkRipple`… never end in `Ink` after a prefix.
CAMEL_INK = re.compile(r"(?<![A-Za-z0-9])_?[a-z][A-Za-z0-9]*Ink\b")
SNAKE_INK = re.compile(r"(?<![A-Za-z0-9])_?[a-z][a-z0-9]*_ink\b")
PASCAL_INK = re.compile(r"\b[A-Z][A-Za-z0-9]*Ink\b")
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
    entries, contracts, _ = parse_with_errors(text)
    return entries, contracts


def parse_with_errors(text: str) -> tuple[list[Entry], dict[str, Contract], list[tuple[int, int]]]:
    """The catalog rows, the contracts, and each malformed row as (line, cells)."""
    lines = text.splitlines()
    malformed: list[tuple[int, int]] = []
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
            if cells[0] == "Component" or set("".join(cells)) <= set("-: "):
                continue
            if len(cells) != 6:
                malformed.append((number, len(cells)))
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
    return entries, contracts, malformed


def check_catalog(root: Path, domains: set[str], screens: set[str], goldens: dict[str, Path]) -> list[Finding]:
    findings: list[Finding] = []
    design = root / DESIGN_MD
    mx_goldens = {name: path for name, path in goldens.items() if name.startswith("mx_")}
    if not design.exists():
        return [("ERROR", str(path), "component golden but DESIGN.md has no catalog") for path in mx_goldens.values()]
    text = design.read_text(encoding="utf-8")
    entries, contracts, malformed = parse_with_errors(text)
    for number, cells in malformed:
        findings.append(("ERROR", f"{DESIGN_MD}:{number}", f"catalog row has {cells} cells; a row has 6"))
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
        for match in MX_TYPE.finditer(path.read_text(encoding="utf-8")):
            name = match.group(1)
            entry = next((e for e in entries if e.name == name), None)
            if entry is not None:
                if source_path(entry) != relative:
                    findings.append(("ERROR", relative, f"`{name}` is {entry.layer}; it belongs at `{source_path(entry) or 'a path the SP3b spec sets'}`"))
                continue
            # An API type of a catalogued component (`MxButtonTone`) carries its name.
            if not any(name.startswith(e.name) for e in entries):
                findings.append(("ERROR", relative, f"public `{name}` has no row in the DESIGN.md catalog"))

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


def check_ink_vocabulary(root: Path, allowed: frozenset[str] = frozenset()) -> list[Finding]:
    """Ink-role terms; `allowed` holds catalog names such as `MxRowInk`, whose
    "ink" is Flutter's ripple, not a colour."""
    findings: list[Finding] = []
    for pattern in INK_SCOPES:
        for path in sorted(root.glob(pattern)):
            relative = path.relative_to(root).as_posix()
            if not path.is_file() or relative.startswith("lib/l10n/generated/"):
                continue
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
                matches = [*PROSE_INK.finditer(line), *CAMEL_INK.finditer(line), *SNAKE_INK.finditer(line)]
                matches += [m for m in PASCAL_INK.finditer(line) if m.group(0) not in allowed]
                for match in matches:
                    findings.append(("ERROR", f"{relative}:{number}", f"`{match.group(0)}`: the ink model is retired; name the role (A2, A11)"))
    return findings
