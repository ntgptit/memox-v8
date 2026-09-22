#!/usr/bin/env python3
"""Gate: the V8 docs keep-set may not cite anything that no longer exists.

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

BR_FILES = [DOCS / "business-rules.md", DOCS / "business-rules" / "study-mode.md"]
UC_FILE = DOCS / "use-cases.md"
DM_FILE = DOCS / "data-model.md"

KEEP_SET = [
    DOCS / "README.md",
    DOCS / "document-conventions.md",
    DOCS / "product.md",
    UC_FILE,
    DOCS / "master-flow.md",
    DM_FILE,
    *BR_FILES,
    *sorted((DOCS / "it-scenarios").glob("*.md")),
]

# Each pattern names something V8 no longer has. Order is report order.
BANNED = [
    (re.compile(r"AD-\d+"), "AD reference — architecture.md is deleted"),
    (re.compile(r"\bM\d+(?:\.\d+)+[a-z]*\b"), "V7 WBS task ID — the ledgers are deleted"),
    (re.compile(r"\blib/"), "V7 source path — V8 has no lib/ yet"),
    (re.compile(r"\b(?:wbs-study|wbs|architecture|checklist)\.md\b"), "deleted document"),
    (
        re.compile(r"\b(?:wbs-archive|wireframes|reviews|claude-design|design-system)/"),
        "deleted directory",
    ),
    (re.compile(r"\b[\w./-]+\.(?:dart|drift)\b"), "V7 source file — V8 has no code yet"),
    (re.compile(r"\b(?:integration_)?test/"), "V7 test path — V8 has no tests yet"),
    (re.compile(r"\b[Ss]chema v\d+\b"), "V7 schema version — V8 has no migration path from V7"),
]

BR_DEF = re.compile(r"^(?:\|\s*|#+\s*)BR-(\d+)\b", re.M)
UC_DEF = re.compile(r"^#+\s*UC-(\d+)\b", re.M)
INV_DEF = re.compile(r"^--\s*(\d+)\.", re.M)
BR_ROW = re.compile(r"^\|\s*BR-\d+\s*\|")

problems: list[str] = []


def fail(path: Path, line_no: int, reason: str) -> None:
    shown = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
    problems.append(f"{shown.as_posix()}:{line_no}: {reason}")


def defined_ids(path: Path, pattern: re.Pattern[str]) -> set[int]:
    if not path.exists():
        return set()
    return {int(m) for m in pattern.findall(path.read_text(encoding="utf-8"))}


def check_file(path: Path, br: set[int], uc: set[int], inv: set[int]) -> None:
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        for pattern, reason in BANNED:
            for hit in pattern.findall(line):
                fail(path, line_no, f"{reason}: {hit}")
        # A rule's definition row still cites other rules in its Related
        # column — 171 of them do — so drop only the leading `| BR-nnn |`
        # and scan the rest. Skipping the whole row blinds the check.
        body = BR_ROW.sub("", line.strip(), count=1)
        for n in re.findall(r"\bBR-(\d+)\b", body):
            if int(n) not in br:
                fail(path, line_no, f"BR-{n} is cited but never defined")
        for n in re.findall(r"\bUC-(\d+)\b", line):
            if int(n) not in uc:
                fail(path, line_no, f"UC-{n} is cited but never defined")
        for n in re.findall(r"\binvariant Q(\d+)\b", line):
            if int(n) not in inv:
                fail(path, line_no, f"invariant Q{n} is cited but data-model.md has no `-- {n}.`")


def main() -> int:
    targets = [Path(a).resolve() for a in sys.argv[1:]] or KEEP_SET
    br: set[int] = set()
    for f in BR_FILES:
        br |= defined_ids(f, BR_DEF)
    uc = defined_ids(UC_FILE, UC_DEF)
    inv = defined_ids(DM_FILE, INV_DEF)

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
