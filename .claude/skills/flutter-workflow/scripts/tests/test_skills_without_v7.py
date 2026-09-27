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
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[5]
SKILLS = REPO_ROOT / ".claude" / "skills"

REPO_OWNED_SKILLS = (
    "flutter-architecture",
    "flutter-data-layer",
    "flutter-design-system",
    "flutter-drift",
    "flutter-feature-slice",
    "flutter-navigation",
    "flutter-product-spec",
    "flutter-project-setup",
    "flutter-ship",
    "flutter-state-riverpod",
    "flutter-testing",
    "flutter-theme-design",
    "flutter-workflow",
    "project-documentation",
    "spring-boot-mybatis-review",
)

# Copied from their upstreams and not the repo's to edit (CLAUDE.md): ECC,
# Superpowers and Impeccable. Every other skill is the repo's, and is scanned.
VENDORED_SKILLS = (
    # ECC
    "android-clean-architecture",
    "compose-multiplatform-patterns",
    "dart-flutter-patterns",
    "flutter-dart-code-review",
    "foundation-models-on-device",
    "java-coding-standards",
    "jpa-patterns",
    "kotlin-coroutines-flows",
    "liquid-glass-design",
    "react-native-patterns",
    "security-review",
    "springboot-patterns",
    "springboot-security",
    "springboot-tdd",
    "springboot-verification",
    "swift-actor-persistence",
    "swift-concurrency-6-2",
    "swift-protocol-di-testing",
    "swiftui-patterns",
    # Superpowers
    "brainstorming",
    "diagnosing-superpowers",
    "dispatching-parallel-agents",
    "executing-plans",
    "finishing-a-development-branch",
    "receiving-code-review",
    "requesting-code-review",
    "subagent-driven-development",
    "systematic-debugging",
    "test-driven-development",
    "using-git-worktrees",
    "using-superpowers",
    "verification-before-completion",
    "writing-plans",
    "writing-skills",
    # Impeccable
    "impeccable",
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


def _occurrences(root: Path = REPO_ROOT, names: tuple[str, ...] = REPO_OWNED_SKILLS) -> list[str]:
    found = []
    for name in names:
        for path in _scanned_files(root / ".claude" / "skills" / name):
            # A skill may ship an image or an archive: a byte that is not UTF-8
            # holds no citation, so it is replaced rather than fatal.
            text = path.read_text(encoding="utf-8", errors="replace")
            for number, line in enumerate(text.splitlines(), start=1):
                if _markers_in(line):
                    relative = path.relative_to(root).as_posix()
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


class ScanTest(unittest.TestCase):
    def test_a_skill_file_is_scanned_and_its_tests_are_not(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill = root / ".claude" / "skills" / "flutter-example"
            (skill / "references").mkdir(parents=True)
            (skill / "tests").mkdir()
            (skill / "SKILL.md").write_text("Covers ADR-011 D4.\n", encoding="utf-8")
            (skill / "references" / "notes.md").write_text(
                "intro\nupdate docs/wbs.md here\n", encoding="utf-8"
            )
            (skill / "tests" / "test_absent.py").write_text(
                "assert 'widgetbook' not in plan\n", encoding="utf-8"
            )
            (skill / "logo.png").write_bytes(b"\x89PNG\r\n\x1a\n\xff\xfe")

            found = _occurrences(root, ("flutter-example",))

        self.assertEqual(
            found,
            [".claude/skills/flutter-example/references/notes.md:2: update docs/wbs.md here"],
        )


class RepoOwnedSkillsTest(unittest.TestCase):
    maxDiff = None

    def test_every_listed_skill_exists(self):
        missing = [name for name in REPO_OWNED_SKILLS if not (SKILLS / name / "SKILL.md").is_file()]
        self.assertEqual(missing, [])

    def test_every_skill_is_repo_owned_or_vendored(self):
        """A skill missing from REPO_OWNED_SKILLS is never scanned, so every
        directory under .claude/skills/ is named here, as one or the other."""
        present = {path.name for path in SKILLS.iterdir() if path.is_dir()}
        self.assertEqual(present, set(REPO_OWNED_SKILLS) | set(VENDORED_SKILLS))
        self.assertEqual(set(REPO_OWNED_SKILLS) & set(VENDORED_SKILLS), set())

    def test_no_repo_owned_skill_names_v7(self):
        self.assertEqual(_occurrences(), [])

    def test_project_documentation_is_its_own_canonical_source(self):
        """The install receipt named a V7 checkout as the skill's source.

        Without it, `skill_distribution.py inspect` treats this copy as
        canonical, and the payload and `skill-manifest.json` are unchanged.
        """
        receipt = SKILLS / "project-documentation" / ".installation.json"
        self.assertFalse(receipt.exists())


if __name__ == "__main__":
    unittest.main()
