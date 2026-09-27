"""The skills the repo owns keep nothing of V7 (package 12c, BE-D7).

V7 is a reference implementation only (`CLAUDE.md`). Its decisions (`AD-nn`),
its business rules (`BR-nn`), its milestones, its 22-phase checklist, its
documents and its Widgetbook catalog do not exist in V8, so a skill that cites
them sends the agent to something it cannot read. What a skill cites is V8's:
an ADR in `docs/shared/decisions/`, a `BR-<AREA>-NNN` or `UC-<AREA>-NNN` in
`docs/features/`, the WBS files, or V8's code.

The vendored skills (ECC, Superpowers, Impeccable) are not the repo's to edit
and are not scanned. The `tests/` directories are not scanned either: the CI
tooling tests themselves assert that Widgetbook and `memox-api` are absent.
"""
from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[5]
SKILLS = REPO_ROOT / ".claude" / "skills"

REPO_OWNED_SKILLS = (
    "flutter-architecture",
    "flutter-design-system",
    "flutter-feature-slice",
    "flutter-workflow",
)

V7_MARKERS = (
    r"(?i)memox[-_ ]v7",
    r"(?i)\bv7\b",
    r"\bAD-\d",
    r"\bBR-\d",
    r"\bM\d+\.\d+\b",
    r"A20\.1",
    r"\bP[1-3]-\d\d\b",
    r"(?i)\bphases? \d",
    r"docs/checklist\.md",
    r"docs/wbs\.md",
    r"docs/architecture\.md",
    r"docs/api-spec\.md",
    r"(?i)widgetbook",
    r"test/demo",
    r"feature_blueprint",
    r"phase-index",
    r"screen_gallery",
)

SKIPPED_DIRECTORIES = {"tests", "__pycache__"}


def _markers_in(text: str) -> list[str]:
    return [pattern for pattern in V7_MARKERS if re.search(pattern, text)]


def _scanned_files(skill: Path) -> list[Path]:
    return sorted(
        path
        for path in skill.rglob("*")
        if path.is_file()
        and not SKIPPED_DIRECTORIES.intersection(path.relative_to(skill).parts)
    )


def _occurrences() -> list[str]:
    found = []
    for name in REPO_OWNED_SKILLS:
        for path in _scanned_files(SKILLS / name):
            text = path.read_text(encoding="utf-8")
            for number, line in enumerate(text.splitlines(), start=1):
                if _markers_in(line):
                    relative = path.relative_to(REPO_ROOT).as_posix()
                    found.append(f"{relative}:{number}: {line.strip()}")
    return found


class MarkersTest(unittest.TestCase):
    def test_each_marker_names_what_v7_left(self):
        for text in (
            "work starts on memox-v7",
            "V7's `features/deck` slice",
            "(AD-05 in the architecture notes)",
            "the deck keeps its type (BR-63)",
            "a real bug (M99.61)",
            "until A20.1 P1-08",
            "Covers checklist Phase 15.",
            "Covers checklist Phases 4 (structure) and 5 (lint).",
            "the 22 phases of docs/checklist.md",
            "update docs/wbs.md in this commit",
            "write it in docs/architecture.md",
            "endpoints in docs/api-spec.md",
            "registered in the Widgetbook catalog",
            "the goldens under test/demo/",
            "see assets/feature_blueprint.md",
            "references/phase-index.md",
            "scripts/build_screen_gallery.py",
        ):
            with self.subTest(text=text):
                self.assertTrue(_markers_in(text))

    def test_v8_citations_are_not_markers(self):
        for text in (
            "ADR-011 D4: one use case per interaction",
            "BR-SRS-023 and UC-DECK-001",
            "docs/wbs_BE.md and docs/wbs_FE.md",
            "docs/shared/decisions/ADR-001-quyet-dinh-nen-tang.md",
            "Material 3 in lib/core/theme/",
        ):
            with self.subTest(text=text):
                self.assertEqual(_markers_in(text), [])


class RepoOwnedSkillsTest(unittest.TestCase):
    maxDiff = None

    def test_every_listed_skill_exists(self):
        missing = [name for name in REPO_OWNED_SKILLS if not (SKILLS / name / "SKILL.md").is_file()]
        self.assertEqual(missing, [])

    def test_no_repo_owned_skill_names_v7(self):
        self.assertEqual(_occurrences(), [])


if __name__ == "__main__":
    unittest.main()
