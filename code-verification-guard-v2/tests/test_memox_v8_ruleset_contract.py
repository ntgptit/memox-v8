"""Contract tests for the memox-v8 ruleset: it describes V8 and nothing else,
and it is the only MemoX ruleset beside V6's `memox`."""

from __future__ import annotations

import re
from pathlib import Path

RULESET_ROOT = Path(__file__).parents[1] / "registries" / "projects" / "memox-v8"


def _occurrences(pattern: str) -> list[str]:
    compiled = re.compile(pattern)
    found: list[str] = []
    for path in sorted(RULESET_ROOT.rglob("*")):
        if not path.is_file():
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for number, line in enumerate(lines, start=1):
            for match in compiled.finditer(line):
                where = path.relative_to(RULESET_ROOT).as_posix()
                found.append(f"{where}:{number}: {match.group(0)}")
    return found


def test_memox_v8_names_no_v7_ruleset_rule_or_label() -> None:
    assert _occurrences(r"(?i)memox[-_ ]v7") == []


V7_MARKERS = {
    "the word V7": r"(?i)\bv7\b",
    "a V7 architecture decision": r"\bAD-\d",
    "a V7 business rule": r"\bBR-\d",
    "V7's design-system audit": r"A20\.1|\bP[1-3]-\d\d\b",
    "a V7 milestone": r"\bM\d+\.\d+",
    "V7's work breakdown": r"docs/wbs\.md",
}


def test_memox_v8_cites_no_v7_decision_or_document() -> None:
    found = {name: _occurrences(pattern) for name, pattern in V7_MARKERS.items()}
    assert {name: hits for name, hits in found.items() if hits} == {}


def test_the_memox_rulesets_are_v6_and_v8_only() -> None:
    projects = RULESET_ROOT.parent
    names = {path.name for path in projects.iterdir() if path.is_dir()}
    assert {name for name in names if name.startswith("memox")} == {"memox", "memox-v8"}
