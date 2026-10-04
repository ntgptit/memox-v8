#!/usr/bin/env python3
"""Migration ledger of the UI docs restructure (spec 2026-10-04 §7.1).

    python tools/docs/ledger.py seed OUT.md

One `##` section per source file and one row per source item:
`| \\`<path>:<line>\\` <excerpt> | <outcome> |`. An item is a frontmatter line,
a heading, a table row, a list item, the start of a paragraph, or a non-empty
line inside a fence (mermaid nodes and edges). Goldens get one row per PNG.
Re-running `seed` keeps every outcome already written for an unchanged row.
`check.py --ledger OUT.md` verifies the outcomes.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate as g  # noqa: E402

EXCERPT = 80
FENCE = "`" * 3
LIST_ITEM = re.compile(r"^(?:[-*]|\d+\.)\s")
SEPARATOR_ROW = re.compile(r"^\|[\s:|-]+\|?$")
CELL_SPLIT = re.compile(r"(?<!\\)\|")
OUTCOME = re.compile(
    r"^(?:moved → `(?P<dest>[^`]+)`|superseded → (?P<by>\S.*)|dropped — .+, approved \d{4}-\d{2}-\d{2})$"
)
# Files whose ledger rows cover one section only: path relative to docs/ → heading.
ONE_SECTION = {"README.md": "## Sản phẩm"}
FEATURE_README_SECTION = "## Màn hình → Use case"  # plan PT7


def source_files() -> list[Path]:
    docs = g.DOCS
    files = sorted((docs / "shared" / "ui" / "screen-handoff").glob("*.md"))
    files += sorted(docs.glob("features/*/usecases/*.md"))
    files += sorted(docs.glob("features/*/ui.md"))
    files += sorted(docs.glob("features/*/README.md"))
    files += [path for path in (docs / "shared" / "ui" / "navigation.md", docs / "README.md") if path.exists()]
    return files


def items(text: str) -> list[tuple[int, str]]:
    lines = text.splitlines()
    found: list[tuple[int, str]] = []
    start = 0
    if lines and lines[0].strip() == "---":
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), 0)
        found += [(i + 1, lines[i].strip()) for i in range(1, end) if lines[i].strip()]
        start = end + 1
    fenced = in_block = False
    for index in range(start, len(lines)):
        line_no, stripped = index + 1, lines[index].strip()
        if stripped.startswith(FENCE):
            fenced, in_block = not fenced, False
            continue
        if not stripped:
            in_block = False
            continue
        if stripped.startswith("|") and SEPARATOR_ROW.match(stripped):
            continue
        if fenced or stripped.startswith("#") or stripped.startswith("|"):
            found.append((line_no, stripped))
            in_block = False
            continue
        if LIST_ITEM.match(stripped) or not in_block:
            found.append((line_no, stripped))
            in_block = True
    return found


def section_heading(path: Path) -> str | None:
    rel = path.relative_to(g.DOCS).as_posix()
    if rel in ONE_SECTION:
        return ONE_SECTION[rel]
    if path.name == "README.md" and path.parent.parent.name == "features":
        return FEATURE_README_SECTION
    return None


def source_items(path: Path) -> list[tuple[int, str]]:
    text = path.read_text(encoding="utf-8")
    found = items(text)
    heading = section_heading(path)
    if heading is None:
        return found
    lines = text.splitlines()
    start = next((i + 1 for i, line in enumerate(lines) if line.strip() == heading), None)
    if start is None:
        return []
    end = next((i + 1 for i in range(start, len(lines)) if lines[i].startswith("## ")), len(lines) + 1)
    return [(n, t) for n, t in found if start <= n < end]


def escape(text: str) -> str:
    # The excerpt points at the source; it must not be collected as an open question itself.
    return text[:EXCERPT].rstrip().replace("|", "\\|").replace("OPEN QUESTION", "OPEN·QUESTION")


def table(title: str, sources: list[str], existing: dict[str, str]) -> list[str]:
    lines = [f"## {title}", "", "| Source item | Outcome |", "|---|---|"]
    lines += [f"| {source} | {existing.get(source, '')} |" for source in sources]
    return lines + [""]


def render(existing: dict[str, str]) -> str:
    lines = [
        "# UI docs restructure — migration ledger",
        "",
        "Seeded by `python3 tools/docs/ledger.py seed`; outcomes are written by hand.",
        "An outcome is one of: moved → `<path relative to docs/>`; superseded → <ID or ruling>;",
        "dropped — <reason>, approved <YYYY-MM-DD>. `check.py --ledger` verifies them.",
        "",
    ]
    for path in source_files():
        rel = path.relative_to(g.DOCS).as_posix()
        sources = [f"`{rel}:{n}` {escape(text)}" for n, text in source_items(path)]
        if sources:
            lines += table(rel, sources, existing)
    goldens = [f"`{p.relative_to(g.ROOT).as_posix()}`" for p in g.golden_files().values()]
    if goldens:
        lines += table("Goldens", goldens, existing)
    return "\n".join(lines).rstrip() + "\n"


def rows(text: str) -> list[tuple[int, str, str]]:
    found: list[tuple[int, str, str]] = []
    for line_no, line in enumerate(text.splitlines(), 1):
        if not line.startswith("| `"):
            continue
        cells = [cell.strip() for cell in CELL_SPLIT.split(line)[1:-1]]
        if len(cells) == 2:
            found.append((line_no, cells[0], cells[1]))
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["seed"])
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    existing = {src: outcome for _, src, outcome in rows(args.out.read_text(encoding="utf-8"))} if args.out.exists() else {}
    args.out.write_text(render(existing), encoding="utf-8", newline="\n")
    print(f"OK {args.out}: {len(rows(args.out.read_text(encoding='utf-8')))} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
