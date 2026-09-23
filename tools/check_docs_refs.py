#!/usr/bin/env python3
"""Gate: every BR-<CODE>-nnn, UC-<CODE>-nnn and invariant Qn cited in the V8
docs keep-set resolves to a real definition, and every keep-set file exists.

    python tools/check_docs_refs.py [path ...]

With no argument, checks the whole keep-set. Exits 0 only when every check
passes. Nothing here edits a file.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

BR_DIR = DOCS / "business-rules"
UC_DIR = DOCS / "use-cases"
DM_FILE = DOCS / "data-model.md"

BR_FILES = sorted(BR_DIR.glob("*.md"))
UC_FILES = sorted(UC_DIR.glob("*.md"))

KEEP_SET = [
    DOCS / "README.md",
    DOCS / "document-conventions.md",
    DOCS / "product" / "product.md",
    DOCS / "product" / "master-flow.md",
    DM_FILE,
    *BR_FILES,
    *UC_FILES,
    *sorted((DOCS / "it-scenarios").glob("*.md")),
]

# Definitions: a table row `| BR-<CODE>-nnn |` or a heading `### BR-<CODE>-nnn · ...`.
BR_DEF = re.compile(r"^(?:\|\s*|#+\s*)BR-([A-Z]+-\d+)\b", re.M)
UC_DEF = re.compile(r"^#+\s*UC-([A-Z]+-\d+)\b", re.M)
INV_DEF = re.compile(r"^--\s*(\d+)\.", re.M)
BR_ROW = re.compile(r"^\|\s*BR-[A-Z]+-\d+\s*\|")

problems: list[str] = []


def fail(path: Path, line_no: int, reason: str) -> None:
    shown = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
    problems.append(f"{shown.as_posix()}:{line_no}: {reason}")


def defined_ids(paths: list[Path], pattern: re.Pattern[str]) -> set[str]:
    out: set[str] = set()
    for path in paths:
        if not path.exists():
            continue
        out |= set(pattern.findall(path.read_text(encoding="utf-8")))
    return out


def defined_int_ids(path: Path, pattern: re.Pattern[str]) -> set[int]:
    if not path.exists():
        return set()
    return {int(m) for m in pattern.findall(path.read_text(encoding="utf-8"))}


def check_file(path: Path, br: set[str], uc: set[str], inv: set[int]) -> None:
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        # A rule's definition row still cites other rules in its Related
        # column, so drop only the leading `| BR-<CODE>-nnn |` and scan the
        # rest. Skipping the whole row blinds the check.
        body = BR_ROW.sub("", line.strip(), count=1)
        for n in re.findall(r"\bBR-([A-Z]+-\d+)\b", body):
            if n not in br:
                fail(path, line_no, f"BR-{n} is cited but never defined")
        for n in re.findall(r"\bUC-([A-Z]+-\d+)\b", line):
            if n not in uc:
                fail(path, line_no, f"UC-{n} is cited but never defined")
        for n in re.findall(r"\binvariant Q(\d+)\b", line):
            if int(n) not in inv:
                fail(path, line_no, f"invariant Q{n} is cited but data-model.md has no `-- {n}.`")


def main() -> int:
    targets = [Path(a).resolve() for a in sys.argv[1:]] or KEEP_SET
    br = defined_ids(BR_FILES, BR_DEF)
    uc = defined_ids(UC_FILES, UC_DEF)
    inv = defined_int_ids(DM_FILE, INV_DEF)

    for path in targets:
        if not path.exists():
            problems.append(f"{path}: missing")
            continue
        check_file(path, br, uc, inv)

    for p in problems:
        print(p)
    print(f"\n{len(br)} BR · {len(uc)} UC · {len(inv)} invariants defined")
    if problems:
        print(f"FAIL — {len(problems)} problem(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
