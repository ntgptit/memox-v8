from __future__ import annotations

import contextlib
import dataclasses
import importlib.util
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parents[1]
REPO_ROOT = SCRIPTS.parents[3]


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _find_bash() -> str | None:
    """Git Bash, not WSL's — see DodCheckStampTest._bash."""
    shell = os.environ.get("SHELL", "")
    if shell.endswith(("bash", "bash.exe")) and Path(shell).exists():
        return shell
    git = shutil.which("git")
    if git:
        candidate = Path(git).parents[1] / "bin" / "bash.exe"
        if candidate.exists():
            return str(candidate)
    found = shutil.which("bash")
    return found if found and "System32" not in found else None


_BASH = _find_bash()

# The Flutter app does not exist until Phase 2.3; `dod_check.sh` exits early on
# the same condition. Tests that assert facts about that tree wait for it, and
# run again unchanged the day it is created.
_APP_TREE = (REPO_ROOT / "pubspec.yaml").is_file()
requires_app_tree = unittest.skipUnless(
    _APP_TREE, "Flutter app not created yet (no pubspec.yaml at the repo root)"
)


def _fixture_repo(root: Path, *tests: str) -> Path:
    """A committed Flutter-shaped git repository holding only `tests`.

    Logic that does not depend on memox's own tree is tested here, so it runs
    whether or not the app exists and never writes into the real checkout.
    """
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    (root / "pubspec.yaml").write_text("name: memox\n", encoding="utf-8")
    (root / ".gitignore").write_text(".dart_tool/\n", encoding="utf-8")
    for test in tests:
        path = root / test
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("void main() { test('t', () {}); }\n", encoding="utf-8")
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    subprocess.run(
        ["git", "-C", str(root), "-c", "user.name=test", "-c", "user.email=test@example.com",
         "commit", "-q", "-m", "fixture"],
        check=True,
    )
    return root


# ADR-010 fixture for `VerificationPlanBuilderTest`.
#
# `build_verification_plan.py`'s classification rules are exercised here
# against a small, self-contained ADR-010-shaped repository (feature slugs
# from ADR-010 #1, `domain/data/presentation/di` layers from ADR-010 #2) —
# never against the real memox-v8 tree. Before `flutter create` runs that tree
# has no `lib/` or `test/` at all; after it runs, it will have V8 feature
# names and layout, not V7's (`test/app/router/...`, `lib/presentation/shared/
# ...`, a `tag` feature). A planner-logic test tied to either shape breaks the
# other. See ADR-010 and CLAUDE.md ("V7 is a reference, not a template").
_ADR010_SOURCE_FILES: dict[str, str] = {
    "lib/features/card/domain/repositories/card_repository.dart": "// fixture\n",
    "lib/features/card/data/repositories/card_repository_impl.dart": "// fixture\n",
    "lib/features/card/presentation/screens/card_list_screen.dart": "// fixture\n",
    "lib/features/card/presentation/widgets/items/card_tile_widget.dart": "// fixture\n",
    "lib/features/deck/domain/repositories/deck_repository.dart": "// fixture\n",
    "lib/features/study/domain/usecases/start_study_session_use_case.dart": "// fixture\n",
    "lib/core/database/tables/cards.drift": "-- fixture\n",
    "lib/core/database/queries/study.drift": "-- fixture\n",
}

# Each maps to the `package:memox/...` import(s) that make it a transitive
# consumer of the matching source file above, the way a real app_router test
# or a cross-feature repository test would be.
_ADR010_TEST_FILES: dict[str, str] = {
    "test/features/card/domain/card_text_test.dart":
        "void main() { test('t', () {}); }\n",
    "test/features/card/presentation/card_list_screen_test.dart":
        "import 'package:memox/features/card/presentation/screens/card_list_screen.dart';\n"
        "void main() { test('t', () {}); }\n",
    "test/features/card/data/card_repository_impl_test.dart":
        "import 'package:memox/features/card/data/repositories/card_repository_impl.dart';\n"
        "void main() { test('t', () {}); }\n",
    "test/features/deck/data/web/deck_repository_web_test.dart":
        "import 'package:memox/features/card/data/repositories/card_repository_impl.dart';\n"
        "void main() { test('t', () {}); }\n",
    "test/features/study/data/study_flow_test.dart":
        "import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';\n"
        "void main() { test('t', () {}); }\n",
    "test/app/router/app_router_test.dart":
        "import 'package:memox/features/card/presentation/screens/card_list_screen.dart';\n"
        "void main() { test('t', () {}); }\n",
    "test/integration/widgets/navigation_widget_test.dart":
        "import 'package:memox/features/card/presentation/screens/card_list_screen.dart';\n"
        "void main() { test('t', () {}); }\n",
    "test/integration/flows/answer_kind_flow_test.dart":
        "void main() { test('t', () {}); }\n",
    "test/integration/flows/stored_not_inferred_flow_test.dart":
        "void main() { test('t', () {}); }\n",
    "test/database/invariants_after_flow_test.dart":
        "void main() { test('t', () {}); }\n",
    # Filename alone marks this golden-only (`is_golden_only_test`); content
    # does not matter.
    "test/shared/widgets/mx_components_golden_test.dart":
        "void main() {}\n",
}


def _adr010_plan_fixture(root: Path) -> Path:
    """A committed, ADR-010-shaped Flutter repository for planner-logic tests.

    Deliberately small and synthetic: enough features, layers and import
    chains to exercise every classification rule `build_verification_plan.py`
    has, without describing the real app (which does not exist yet, and once
    it does will not look like this fixture either).
    """
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    (root / "pubspec.yaml").write_text("name: memox\n", encoding="utf-8")
    (root / ".gitignore").write_text(".dart_tool/\n", encoding="utf-8")
    for relative, content in {**_ADR010_SOURCE_FILES, **_ADR010_TEST_FILES}.items():
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    subprocess.run(
        ["git", "-C", str(root), "-c", "user.name=test", "-c", "user.email=test@example.com",
         "commit", "-q", "-m", "fixture"],
        check=True,
    )
    return root


# A synthetic impact map, deliberately decoupled from
# `verification_impact_map.json`: it exercises the same classification logic
# (feature-dependency BFS, database-query ownership, shard-count thresholds)
# without being tied to production data that other tests (`ImpactMapCoverage
# Test`, `ImpactMapMatchesTheDocsTest`) keep in sync with `docs/features/`.
# The shard-weight thresholds are lowered so the small fixture above still
# exercises the 1/2/5-shard boundaries meaningfully.
_ADR010_IMPACT_MAP_RAW: dict[str, object] = {
    "version": 1,
    "feature_dependencies": {
        "card": ["search", "srs", "starter_decks", "study", "tags", "transfer", "trash"],
        "deck": [
            "card", "progress", "reminders", "search", "settings", "srs",
            "starter_decks", "study", "transfer", "trash",
        ],
        "progress": [],
        "reminders": [],
        "search": [],
        "settings": [],
        "srs": ["progress", "settings", "study", "study_mode", "trash"],
        "starter_decks": [],
        "study": ["progress", "reminders", "settings"],
        "study_mode": ["study"],
        "tags": ["search", "transfer"],
        "transfer": [],
        "trash": [],
    },
    "database_query_features": {"study": ["study", "progress"]},
    "full_scope_prefixes": [
        ".github/",
        ".claude/skills/flutter-workflow/scripts/",
        "lib/app/",
        "lib/core/theme/",
        "lib/l10n/",
        "integration_test/",
        "e2e/",
        "android/",
        "ios/",
        "linux/",
        "macos/",
        "web/",
        "windows/",
    ],
    "full_scope_files": [
        ".fvmrc",
        "analysis_options.yaml",
        "build.yaml",
        "dart_test.yaml",
        "pubspec.lock",
        "pubspec.yaml",
    ],
    "inert_prefixes": [".vscode/", ".idea/", ".github/ISSUE_TEMPLATE/"],
    "inert_files": [
        ".editorconfig",
        ".gitattributes",
        ".gitignore",
        ".github/CODEOWNERS",
        ".github/FUNDING.yml",
        ".github/PULL_REQUEST_TEMPLATE.md",
        "LICENSE",
    ],
    "shard_weight_thresholds": {"one": 2, "two": 5},
}


class DodCheckStampTest(unittest.TestCase):
    """The pass stamp: run twice on an unchanged tree, pay once.

    Running the gate again before commit, again before push and again before the
    PR is one tree state asked three times. The stamp exists so the repetition
    costs ~0.4s instead of 50-150s — and so it works without anyone having to
    remember, which is the part that failed every time it was written down.
    """

    SCRIPT = REPO_ROOT / ".claude/skills/flutter-workflow/scripts/dod_check.sh"

    @staticmethod
    def _bash() -> str | None:
        """Git Bash, not WSL's.

        On Windows `shutil.which("bash")` finds `System32/bash.exe`, the WSL
        launcher, which cannot see the repository's drive path and fails with
        `execvpe(/bin/bash)`. The shell this project's scripts are written for
        ships beside git.
        """
        shell = os.environ.get("SHELL", "")
        if shell.endswith(("bash", "bash.exe")) and Path(shell).exists():
            return shell
        git = shutil.which("git")
        if git:
            candidate = Path(git).parents[1] / "bin" / "bash.exe"
            if candidate.exists():
                return str(candidate)
        found = shutil.which("bash")
        if found and "System32" not in found:
            return found
        return None

    def setUp(self) -> None:
        # The stamp logic reads only git state, so any Flutter-shaped repository
        # answers the same way — and the real checkout's stamp is never touched.
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = _fixture_repo(Path(temp.name))
        self.STAMP = self.root / ".dart_tool/dod_check_stamp"
        self.STAMP.parent.mkdir(parents=True, exist_ok=True)

    def _fingerprint(self) -> str:
        """Asked of the script, not recomputed here — a second definition would
        match the first only until one of them changed."""
        out = subprocess.run(
            [self._bash(), str(self.SCRIPT)],
            cwd=self.root, capture_output=True, text=True,
            env={**os.environ, "PRINT_FINGERPRINT": "1"},
        )
        self.assertEqual(0, out.returncode, out.stderr)
        return out.stdout.strip()

    def _decide(self, *args: str) -> str:
        """Ask which way the stamp decides — never let the gate start.

        An earlier version of this test ran the script for real and killed it on
        a timeout. Killing the shell orphans `flutter test`, so the suite hung
        for seven minutes with the whole gate running behind it. The script
        answers the question directly now.
        """
        out = subprocess.run(
            [_BASH, str(self.SCRIPT), *args], cwd=self.root,
            capture_output=True, text=True, timeout=60,
            env={**os.environ, "STAMP_DECISION_ONLY": "1"},
        )
        self.assertEqual(0, out.returncode, out.stderr)
        return out.stdout.strip()

    def _write_stamp(self, mode: str) -> None:
        self.STAMP.write_text(
            f"{mode}\t{self._fingerprint()}\t2026-01-01T00:00:00Z\n",
            encoding="utf-8",
        )

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_an_unchanged_tree_is_not_verified_twice(self) -> None:
        self._write_stamp("full")
        self.assertEqual("reuse", self._decide())

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_a_full_pass_answers_for_the_narrower_modes(self) -> None:
        """`full` is a superset of both, and this is the case that saves the
        most: the habit is to run the whole gate and then run a narrower one."""
        self._write_stamp("full")
        for args in (("--fast",), ("--changed",)):
            with self.subTest(args=args):
                self.assertEqual("reuse", self._decide(*args))

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_a_narrow_pass_never_answers_for_the_full_gate(self) -> None:
        """The safety property. `--fast` runs the Deck + app subset; letting it
        stamp the full gate would turn a shortcut into a false clean bill."""
        self._write_stamp("fast")
        self.assertEqual("run", self._decide())

    @unittest.skipUnless(_BASH, "needs Git Bash")
    def test_force_ignores_a_valid_stamp(self) -> None:
        self._write_stamp("full")
        self.assertEqual("run", self._decide("--force"))


class VerificationPlanBuilderTest(unittest.TestCase):
    """Planner-classification logic, against the ADR-010 fixture above.

    Never against `REPO_ROOT`: before Flutter is initialised it has no
    `lib/`/`test/`, and after it is, it will have V8's feature names and
    layout rather than the V7 paths some of these tests used to assert
    (`test/app/router/app_router_test.dart` importing a V7 `tag` feature,
    etc.). The fixture makes every assertion below true regardless of what
    the real tree currently contains.
    """

    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("build_verification_plan")
        cls._temp = tempfile.TemporaryDirectory()
        temp_root = Path(cls._temp.name)
        cls.root = _adr010_plan_fixture(temp_root / "repo")
        impact_map_path = temp_root / "impact_map.json"
        impact_map_path.write_text(
            json.dumps(_ADR010_IMPACT_MAP_RAW), encoding="utf-8"
        )
        cls.impact_map = cls.module.ImpactMap.load(impact_map_path)

    @classmethod
    def tearDownClass(cls) -> None:
        cls._temp.cleanup()

    def _plan(self, *paths: str, force_full: bool = False):
        return self.module.build_plan(
            paths,
            root=self.root,
            impact_map=self.impact_map,
            force_full=force_full,
        )

    def test_a_shared_widget_change_selects_the_golden_job(self) -> None:
        """#337's shape: six components relaid out, no picture redrawn.

        It passed every check in `ci.yml` because nothing there compares a
        committed PNG against a fresh render — the Windows golden job lives in
        `ci-full.yml`, which is `workflow_dispatch:` only. 26 goldens went
        stale on `main` and the screen gallery published a pre-#337 app.
        """
        plan = self._plan("lib/shared/widgets/mx_button_pair.dart")
        self.assertTrue(plan.needs_goldens)

    def test_a_change_to_the_pictures_themselves_selects_the_golden_job(self) -> None:
        """A PR that only regenerates goldens is the one whose claim needs
        checking most — and a PNG is not code, so `code_required` misses it."""
        plan = self._plan("test/demo/goldens/deck_list_empty_light.png")
        self.assertTrue(plan.needs_goldens)

    def test_a_demo_test_change_selects_the_golden_job(self) -> None:
        plan = self._plan("test/demo/deck_screens_demo_test.dart")
        self.assertTrue(plan.needs_goldens)

    def test_regenerating_pictures_runs_the_golden_job_and_nothing_else(self) -> None:
        """The shape of a golden-regeneration PR, which is the common one.

        Measured before this was classified: two of the last forty commits on
        `main` were exactly this — 26 and 31 PNGs, no Dart — and each ran five
        host shards, `flutter analyze` and the Widgetbook smoke test. A PNG can
        fail none of them. It was not a decision: `require_test_path` claims a
        code change first thing, then finds no rule for `.png` and falls
        through to `require_full("unrecognised test support path")`.
        """
        plan = self._plan(
            "test/demo/goldens/deck_list_empty_light.png",
            "test/demo/goldens/card_list_dark.png",
        )
        self.assertTrue(plan.needs_goldens)
        # The assertions that would have caught it: everything the pictures
        # cannot affect.
        self.assertFalse(plan.full_suite)
        self.assertFalse(plan.needs_static)
        self.assertFalse(plan.needs_host_tests)
        self.assertFalse(plan.needs_widgetbook)
        self.assertEqual(0, plan.shard_count)
        self.assertEqual("pixels", plan.risk)

    def test_a_picture_beside_its_widget_still_verifies_the_widget(self) -> None:
        """The narrowing must not survive contact with a real code change."""
        plan = self._plan(
            "test/demo/goldens/card_list_light.png",
            "lib/features/card/presentation/widgets/items/card_tile_widget.dart",
        )
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)
        self.assertTrue(plan.needs_goldens)

    def test_repository_furniture_verifies_nothing(self) -> None:
        """`.gitignore` and an issue template were selecting the whole suite.

        Both reached `require_full` — the first as an unclassified path, the
        second because `.github/` is a full-scope prefix and a markdown
        template is not a pipeline. One paragraph cost 1847s of runner time.
        """
        for path in (
            ".gitignore",
            ".editorconfig",
            ".vscode/settings.json",
            ".github/ISSUE_TEMPLATE/bug.md",
        ):
            with self.subTest(path=path):
                plan = self._plan(path)
                self.assertFalse(plan.full_suite)
                self.assertFalse(plan.needs_static)
                self.assertFalse(plan.needs_goldens)
                self.assertFalse(plan.needs_host_tests)

    def test_the_workflow_itself_still_runs_everything(self) -> None:
        """Not an oversight left in place — the one case where running the
        whole suite *is* the point. Changing what verification runs is a claim
        that the new pipeline works, and only a full run tests that claim.
        `.github/workflows/` stays full-scope; only its inert neighbours moved.
        """
        plan = self._plan(".github/workflows/ci.yml")
        self.assertTrue(plan.full_suite)

    def test_an_unclassified_path_still_widens_to_everything(self) -> None:
        """The fallback is the safe default and this change does not touch it.

        What was wrong was never the fallback — it was the paths reaching it
        that should have been classified.
        """
        plan = self._plan("tools/some_new_thing.py")
        self.assertTrue(plan.full_suite)

    def test_a_documents_only_change_does_not_pay_for_a_windows_runner(self) -> None:
        """The job is conditional for a reason: Windows minutes cost double."""
        plan = self._plan("design_audit/layout_review/SUMMARY.md")
        self.assertFalse(plan.needs_goldens)

    def test_normalization_preserves_dot_prefixed_directories(self) -> None:
        self.assertEqual(
            ".github/workflows/ci.yml",
            self.module.normalize_path(r"./.github\workflows\ci.yml"),
        )

    def test_newline_input_does_not_turn_a_known_path_into_full_scope(self) -> None:
        plan = self._plan(
            "\ufefflib/features/card/presentation/screens/card_list_screen.dart\r"
        )
        self.assertFalse(plan.full_suite)

    def test_prompt_only_change_uses_python_contract_path(self) -> None:
        plan = self._plan(
            "docs/prompt/progress-v1/implementation.md",
            "docs/prompt/progress-v1/recursive-ui-ux-review.md",
        )
        self.assertTrue(plan.prompt_only)
        self.assertTrue(plan.docs_only)
        self.assertFalse(plan.code_required)
        self.assertFalse(plan.needs_static)
        self.assertFalse(plan.needs_host_tests)
        self.assertFalse(plan.needs_widgetbook)

    def test_prompt_plus_normative_docs_stays_flutter_free(self) -> None:
        plan = self._plan(
            "docs/prompt/sample/implementation.md",
            "docs/wbs.md",
        )
        self.assertFalse(plan.prompt_only)
        self.assertTrue(plan.docs_only)
        self.assertFalse(plan.code_required)

    def test_presentation_change_adds_transitive_app_consumers(self) -> None:
        plan = self._plan(
            "lib/features/card/presentation/screens/card_list_screen.dart"
        )
        self.assertEqual(("card",), plan.affected_features)
        self.assertEqual(("presentation",), plan.affected_layers)
        self.assertTrue(plan.test_files)
        self.assertTrue(
            any(path.startswith("test/features/card/presentation/") for path in plan.test_files)
        )
        self.assertIn(
            "test/app/router/app_router_test.dart",
            plan.test_files,
        )
        self.assertIn(
            "test/integration/widgets/navigation_widget_test.dart",
            plan.test_files,
        )
        self.assertTrue(plan.needs_widgetbook)

    def test_data_change_adds_cross_feature_harness_consumers(self) -> None:
        plan = self._plan(
            "lib/features/card/data/repositories/card_repository_impl.dart"
        )
        self.assertEqual(("data",), plan.affected_layers)
        self.assertTrue(plan.test_files)
        self.assertTrue(
            any(path.startswith("test/features/card/data/") for path in plan.test_files)
        )
        self.assertIn(
            "test/features/deck/data/web/deck_repository_web_test.dart",
            plan.test_files,
        )
        self.assertFalse(plan.needs_widgetbook)

    def test_use_case_change_adds_data_flow_consumers(self) -> None:
        plan = self._plan(
            "lib/features/study/domain/usecases/start_study_session_use_case.dart"
        )
        self.assertEqual(("domain", "presentation"), plan.affected_layers)
        self.assertIn(
            "test/features/study/data/study_flow_test.dart",
            plan.test_files,
        )
        self.assertTrue(plan.needs_widgetbook)

    def test_public_domain_contract_expands_transitive_dependents(self) -> None:
        plan = self._plan(
            "lib/features/deck/domain/repositories/deck_repository.dart"
        )
        self.assertTrue(
            {"deck", "card", "study", "search", "progress", "trash"}
            <= set(plan.affected_features)
        )
        self.assertEqual(("data", "domain", "presentation"), plan.affected_layers)
        self.assertGreaterEqual(plan.shard_count, 2)

    def test_database_query_uses_declared_feature_owner(self) -> None:
        plan = self._plan("lib/core/database/queries/study.drift")
        self.assertIn("study", plan.affected_features)
        self.assertIn("progress", plan.affected_features)
        self.assertIn(
            "test/integration/flows/answer_kind_flow_test.dart",
            plan.test_files,
        )
        self.assertIn(
            "test/integration/flows/stored_not_inferred_flow_test.dart",
            plan.test_files,
        )
        self.assertIn(
            "test/database/invariants_after_flow_test.dart",
            plan.test_files,
        )
        self.assertFalse(plan.full_suite)

    def test_schema_change_promotes_to_full_suite(self) -> None:
        plan = self._plan("lib/core/database/tables/cards.drift")
        self.assertTrue(plan.full_suite)
        self.assertEqual(5, plan.shard_count)
        self.assertTrue(plan.needs_widgetbook)
        self.assertEqual(("test",), plan.local_test_targets)

    def test_shared_theme_router_native_and_dependency_changes_are_full(self) -> None:
        for path in (
            "lib/core/theme/app_theme.dart",
            "lib/presentation/shared/mx_card.dart",
            "lib/app/router/app_router.dart",
            "android/app/build.gradle.kts",
            "pubspec.yaml",
        ):
            with self.subTest(path=path):
                self.assertTrue(self._plan(path).full_suite)

    def test_ci_tooling_change_is_full_so_the_new_gate_proves_itself(self) -> None:
        plan = self._plan(".github/workflows/ci.yml")
        self.assertTrue(plan.full_suite)
        self.assertEqual(5, plan.shard_count)

    def test_test_only_change_runs_exact_tracked_test(self) -> None:
        path = "test/features/card/domain/card_text_test.dart"
        plan = self._plan(path)
        self.assertEqual((path,), plan.test_files)
        self.assertEqual(1, plan.shard_count)

    def test_golden_only_change_uses_runnable_surrogates(self) -> None:
        path = "test/shared/widgets/mx_components_golden_test.dart"
        plan = self._plan(path)
        self.assertNotIn(path, plan.test_files)
        self.assertTrue(plan.test_files)
        self.assertTrue(plan.needs_widgetbook)
        self.assertTrue(
            all(
                not self.module.is_golden_only_test(self.root / test_path)
                for test_path in plan.test_files
            )
        )

    def test_untracked_test_is_part_of_the_local_sealed_plan(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / "pubspec.yaml").write_text("name: memox\n", encoding="utf-8")
            tracked = root / "test" / "tracked_test.dart"
            tracked.parent.mkdir(parents=True)
            tracked.write_text("void main() { test('tracked', () {}); }\n", encoding="utf-8")
            subprocess.run(
                ["git", "-C", str(root), "add", "pubspec.yaml", "test/tracked_test.dart"],
                check=True,
            )
            untracked = root / "test" / "new_test.dart"
            untracked.write_text("void main() { test('new', () {}); }\n", encoding="utf-8")

            plan = self.module.build_plan(
                ["test/new_test.dart"],
                root=root,
            )

            self.assertIn("test/new_test.dart", plan.test_files)
            self.assertIn("test/new_test.dart", plan.local_test_targets)

    def test_the_worktree_scan_is_memoized_per_root_not_globally(self) -> None:
        """The cache that made this suite 43s → 8s must not answer for a
        different tree.

        A memo keyed by anything coarser than the resolved root would hand a
        temporary repository the main repository's file list, and every plan
        built against a fixture would silently describe memox instead. The
        second half is the one that matters: the first assertion passes under a
        global cache too.
        """
        with tempfile.TemporaryDirectory() as temp:
            repo = _fixture_repo(Path(temp) / "repo", "test/a_test.dart", "test/b_test.dart")
            root = _fixture_repo(Path(temp) / "fixture", "test/only_test.dart")

            repo_first = self.module.discover_tests(repo)
            fixture = self.module.discover_tests(root)
            repo_second = self.module.discover_tests(repo)

            self.assertEqual(repo_first, repo_second)
            self.assertEqual({"test/only_test.dart": 1}, fixture)
            self.assertGreater(len(repo_first), 1)

    def test_a_memoized_scan_is_not_shared_mutable_state(self) -> None:
        """`seal` builds sets from what it receives; a shared object would let
        one plan corrupt the next one built in the same process."""
        with tempfile.TemporaryDirectory() as temp:
            repo = _fixture_repo(Path(temp), "test/a_test.dart", "test/b_test.dart")
            first = self.module.discover_tests(repo)
            first.clear()
            self.assertGreater(len(self.module.discover_tests(repo)), 1)

    def test_deleted_test_support_selects_its_layer(self) -> None:
        plan = self._plan("test/features/card/data/support/deleted_fixture.dart")
        self.assertTrue(plan.test_files)
        self.assertTrue(
            all(path.startswith("test/features/card/data/") for path in plan.test_files)
        )

    def test_widgetbook_only_change_skips_host_tests(self) -> None:
        plan = self._plan("widgetbook/lib/main.dart")
        self.assertTrue(plan.code_required)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_widgetbook)
        self.assertFalse(plan.needs_host_tests)

    def test_new_feature_without_tests_promotes_instead_of_trusting_widgetbook(self) -> None:
        plan = self._plan(
            "lib/features/not_yet_mapped/presentation/screens/new_screen.dart"
        )
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.needs_host_tests)

    def test_unknown_and_empty_changes_fail_safe_to_full(self) -> None:
        unknown = self._plan("tool/new_unclassified_binary")
        empty = self._plan()
        self.assertTrue(unknown.full_suite)
        self.assertEqual(("tool/new_unclassified_binary",), unknown.unmatched_paths)
        self.assertTrue(empty.full_suite)

    def test_force_full_disables_docs_fast_path(self) -> None:
        plan = self._plan("docs/wbs.md", force_full=True)
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.code_required)

    def test_sealed_plan_is_immutable_and_json_is_deterministic(self) -> None:
        first = self._plan(
            "lib/features/card/data/repositories/card_repository_impl.dart",
            "docs/wbs.md",
        )
        second = self._plan(
            "docs/wbs.md",
            "lib/features/card/data/repositories/card_repository_impl.dart",
        )
        self.assertEqual(first, second)
        self.assertEqual(first.to_json_dict(), second.to_json_dict())
        with self.assertRaises(dataclasses.FrozenInstanceError):
            first.risk = "docs"

    def test_shard_policy_is_one_two_or_five_and_never_empty(self) -> None:
        choose = self.module.choose_shard_count
        self.assertEqual(0, choose(0, 0, 240, 800))
        self.assertEqual(1, choose(240, 20, 240, 800))
        self.assertEqual(2, choose(700, 50, 240, 800))
        self.assertEqual(5, choose(1200, 50, 240, 800))

    def test_local_targets_never_pull_an_unselected_test_into_scope(self) -> None:
        compress = self.module.compress_test_targets
        selected = {
            "test/features/card/data/a_test.dart",
            "test/features/card/data/b_test.dart",
        }
        all_tests = selected | {"test/features/card/domain/c_test.dart"}
        self.assertEqual(
            ("test/features/card/data",),
            compress(selected, all_tests),
        )


@requires_app_tree
class ImpactMapCoverageTest(unittest.TestCase):
    """Facts about the real repo's `lib/features/`, checked against the map.

    Unlike `VerificationPlanBuilderTest`, this class is deliberately tied to
    the real tree: it is exactly the thing that must stay true of *memox-v8*,
    not of a fixture. Before `lib/features/` exists (fresh post-`flutter
    create` tree, or today, pre-init) each check degrees to "no features to
    check" and passes — a directory that legitimately has nothing in it yet is
    not a coverage gap.
    """

    def _impact(self) -> dict[str, object]:
        return json.loads(
            (SCRIPTS / "verification_impact_map.json").read_text(encoding="utf-8")
        )

    def test_every_database_query_has_a_declared_owner(self) -> None:
        impact = self._impact()
        declared = set(impact["database_query_features"])
        actual = {path.stem for path in (REPO_ROOT / "lib/core/database/queries").glob("*.drift")}
        self.assertEqual(actual, declared & actual)

    def test_every_feature_is_a_node_in_the_dependency_graph(self) -> None:
        impact = self._impact()
        graph = impact["feature_dependencies"]
        nodes = set(graph)
        for dependents in graph.values():
            nodes.update(dependents)
        # `.glob("*")` rather than `.iterdir()`: a freshly-created V8 tree has
        # no `lib/features/` at all yet, and `iterdir()` on a missing
        # directory raises `FileNotFoundError` where `glob()` yields nothing —
        # an empty feature set is not a coverage gap.
        actual = {
            path.name
            for path in (REPO_ROOT / "lib/features").glob("*")
            if path.is_dir()
        }
        self.assertEqual(set(), actual - nodes)

    def test_every_feature_source_uses_a_known_top_level_layer(self) -> None:
        allowed = {"domain", "data", "di", "presentation"}
        bad: list[str] = []
        for path in (REPO_ROOT / "lib/features").rglob("*.dart"):
            relative = path.relative_to(REPO_ROOT).as_posix().split("/")
            if len(relative) < 4 or relative[3] not in allowed:
                bad.append(path.relative_to(REPO_ROOT).as_posix())
        self.assertEqual([], bad)


class DependencyGraphCycleSafetyTest(unittest.TestCase):
    """`require_downstream`'s BFS must terminate on a graph with a real cycle.

    Deliberately independent of `verification_impact_map.json`: the real
    `feature_dependencies` graph (rightly) has none, being derived from
    `docs/features/`'s acyclic `depends_on` declarations and guarded by
    `ImpactMapMatchesTheDocsTest`. Cycle-safety is a property of the BFS in
    `build_verification_plan.py`, so this test builds a small `ImpactMap` with
    an actual cycle rather than assume the production graph will ever have
    one to exercise it with.
    """

    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("build_verification_plan")

    def test_dependency_graph_closure_terminates_even_with_cycles(self) -> None:
        impact_map = self.module.ImpactMap(
            feature_dependencies={"a": ("b",), "b": ("a",)},
            database_query_features={},
            full_scope_prefixes=(),
            full_scope_files=frozenset(),
            inert_prefixes=(),
            inert_files=frozenset(),
            one_shard_max_weight=240,
            two_shard_max_weight=800,
        )
        with tempfile.TemporaryDirectory() as temp:
            root = _fixture_repo(Path(temp))
            plan = self.module.build_plan(
                ["lib/features/a/domain/repositories/a_repository.dart"],
                root=root,
                impact_map=impact_map,
            )
        self.assertIn("a", plan.affected_features)
        self.assertIn("b", plan.affected_features)


class ImpactMapMatchesTheDocsTest(unittest.TestCase):
    """`feature_dependencies` is derived, not authored.

    The feature READMEs under `docs/features/` declare `depends_on`; the map
    stores the inverse (a change to a feature verifies the features that depend
    on it). Feature keys are the docs slugs in snake_case, the `lib/features/`
    directory names. Hand-editing either side without the other fails here.
    """

    @staticmethod
    def _declared_dependents() -> dict[str, list[str]]:
        spec = importlib.util.spec_from_file_location(
            "docs_generate", REPO_ROOT / "tools/docs/generate.py"
        )
        assert spec and spec.loader
        docs = importlib.util.module_from_spec(spec)
        sys.modules["docs_generate"] = docs
        spec.loader.exec_module(docs)

        depends_on: dict[str, list[str]] = {}
        for readme in sorted((REPO_ROOT / "docs/features").glob("*/README.md")):
            meta, _, error = docs.split_frontmatter(readme.read_text(encoding="utf-8"))
            assert meta is not None and error is None, readme
            declared = meta.get("depends_on")
            feature = readme.parent.name.replace("-", "_")
            depends_on[feature] = [
                name.replace("-", "_")
                for name in (declared if isinstance(declared, list) else [])
            ]
        return {
            feature: sorted(
                dependent
                for dependent, needs in depends_on.items()
                if feature in needs
            )
            for feature in sorted(depends_on)
        }

    def test_feature_dependencies_are_the_inverse_of_docs_depends_on(self) -> None:
        impact = json.loads(
            (SCRIPTS / "verification_impact_map.json").read_text(encoding="utf-8")
        )
        declared = self._declared_dependents()
        self.assertTrue(declared, "no feature READMEs found under docs/features/")
        self.assertEqual(
            declared,
            {key: sorted(value) for key, value in impact["feature_dependencies"].items()},
        )


def _golden_report(
    root: Path, *, passed: int, failed: int = 0, skipped: int = 0
) -> Path:
    """A report in the shape `flutter test --file-reporter json:<file>` writes.

    Every test file starts with a hidden "loading" test, the reporter's own
    entry, and the run ends with a `done` event: neither is a golden test. A
    failed golden reports `error`, as a failed `matchesGoldenFile` does.
    """
    events: list[dict] = [
        {"protocolVersion": "0.1.1", "runnerVersion": None, "pid": 1, "type": "start", "time": 0},
        {"suite": {"id": 0, "platform": "vm", "path": "test/x_golden_test.dart"}, "type": "suite", "time": 0},
        {"test": {"id": 1, "name": "loading test/x_golden_test.dart", "suiteID": 0, "groupIDs": []},
         "type": "testStart", "time": 1},
        {"count": 1, "type": "allSuites", "time": 2},
        {"testID": 1, "result": "success", "skipped": False, "hidden": True, "type": "testDone", "time": 3},
    ]
    outcomes = ["success"] * passed + ["error"] * failed + ["skipped"] * skipped
    for test_id, outcome in enumerate(outcomes, start=10):
        events.append(
            {"test": {"id": test_id, "name": f"golden {test_id}", "suiteID": 0, "groupIDs": [2]},
             "type": "testStart", "time": 4}
        )
        events.append({
            "testID": test_id,
            "result": "success" if outcome == "skipped" else outcome,
            "skipped": outcome == "skipped",
            "hidden": False,
            "type": "testDone",
            "time": 5,
        })
    events.append({"success": failed == 0, "type": "done", "time": 6})
    report = root / "golden-report.jsonl"
    report.write_text("".join(json.dumps(event) + "\n" for event in events), encoding="utf-8")
    return report


class GoldenCountTest(unittest.TestCase):
    """`count_golden_tests.py` reads the report of the `goldens` CI job.

    A golden run can pass while comparing fewer pictures than it should: a
    golden file that lost its tag, or moved out of `test/`, is simply not
    selected. The floor notices, and only tests that ran are counted.
    """

    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("count_golden_tests")

    def setUp(self) -> None:
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)

    def _count(self, report: Path, floor: int) -> tuple[int, str]:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = self.module.main(["count_golden_tests.py", str(report), str(floor)])
        return code, out.getvalue()

    def test_a_report_that_meets_the_floor_passes(self) -> None:
        code, out = self._count(_golden_report(self.root, passed=3), floor=3)
        self.assertEqual(0, code, out)
        self.assertIn("golden count floor satisfied (3 >= 3)", out)

    def test_a_failed_golden_fails_whatever_the_count(self) -> None:
        code, out = self._count(_golden_report(self.root, passed=3, failed=1), floor=1)
        self.assertEqual(1, code, out)
        self.assertIn("1 golden test(s) did not pass", out)

    def test_a_count_under_the_floor_fails(self) -> None:
        code, out = self._count(_golden_report(self.root, passed=2), floor=3)
        self.assertEqual(1, code, out)
        self.assertIn("Expected at least 3 golden tests, but only 2 ran", out)

    def test_skipped_tests_and_loading_entries_are_not_counted(self) -> None:
        code, out = self._count(_golden_report(self.root, passed=2, skipped=5), floor=3)
        self.assertEqual(1, code, out)
        self.assertIn("Golden tests discovered: 2", out)

    def test_a_report_with_no_test_fails(self) -> None:
        code, out = self._count(_golden_report(self.root, passed=0), floor=60)
        self.assertEqual(1, code, out)
        self.assertIn("Golden tests discovered: 0", out)

    def test_a_missing_report_fails_and_names_it(self) -> None:
        missing = self.root / "golden-report.jsonl"
        code, out = self._count(missing, floor=60)
        self.assertEqual(1, code, out)
        self.assertIn(f"cannot read the golden report {missing}", out)


_CI_WORKFLOW = REPO_ROOT / ".github/workflows/ci.yml"


def _top_level_block(workflow: str, key: str) -> str:
    """The lines under a top-level `key:` of the workflow, up to the next key."""
    lines = workflow.splitlines()
    block: list[str] = []
    for line in lines[lines.index(f"{key}:") + 1:]:
        if line and not line.startswith(" "):
            break
        block.append(line)
    return "\n".join(block)


def _workflow_jobs(workflow: str) -> dict[str, str]:
    """Each job of the workflow by its key, as the text of its block."""
    jobs: dict[str, list[str]] = {}
    current: list[str] = []
    for line in _top_level_block(workflow, "jobs").splitlines():
        key = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
        if key:
            current = jobs.setdefault(key.group(1), [])
            continue
        current.append(line)
    return {key: "\n".join(lines) for key, lines in jobs.items()}


def _run_script(job: str) -> str:
    """The script of the job's `run: |` step, without its indentation."""
    lines = job.splitlines()
    start = next(i for i, line in enumerate(lines) if line.strip() == "run: |")
    indent = len(lines[start]) - len(lines[start].lstrip()) + 2
    script: list[str] = []
    for line in lines[start + 1:]:
        if line.strip() and len(line) - len(line.lstrip()) < indent:
            break
        script.append(line[indent:])
    return "\n".join(script)


class WorkflowContractTest(unittest.TestCase):
    """What `.github/workflows/ci.yml` must keep doing, and what `dod_check.sh`
    must never skip.

    The workflow is read as text, without PyYAML: `dod_check.sh` runs these
    tests with no Python dependency installed. Comment lines are dropped
    first, so a comment may name what the workflow must not do.
    """

    def _workflow(self) -> tuple[str, dict[str, str]]:
        if not _CI_WORKFLOW.is_file():
            self.fail(".github/workflows/ci.yml is missing: no pull request is verified")
        workflow = "\n".join(
            line
            for line in _CI_WORKFLOW.read_text(encoding="utf-8").splitlines()
            if not line.lstrip().startswith("#")
        )
        return workflow, _workflow_jobs(workflow)

    def test_the_gate_job_runs_the_whole_local_gate(self) -> None:
        """The gate a contributor runs, in full, and generated code rebuilt
        from nothing: CI must not trust a narrower selection than that."""
        _, jobs = self._workflow()
        gate = jobs["gate"]
        self.assertIn("bash .claude/skills/flutter-workflow/scripts/dod_check.sh", gate)
        self.assertIn(".claude/skills/flutter-workflow/scripts/check_generated.py", gate)
        for narrowing in ("--fast", "--changed", "--skip-rebuild"):
            with self.subTest(flag=narrowing):
                self.assertNotIn(narrowing, gate)

    def test_the_goldens_job_compares_the_pictures_and_counts_them(self) -> None:
        workflow, jobs = self._workflow()
        goldens = jobs["goldens"]
        self.assertIn("flutter test --tags golden", goldens)
        self.assertNotIn("--update-goldens", workflow)
        written = re.search(r"--file-reporter json:(\S+)", goldens)
        counted = re.search(r"count_golden_tests\.py (\S+) (\d+)", goldens)
        self.assertIsNotNone(written, "the golden run writes no JSON report")
        self.assertIsNotNone(counted, "nothing counts the golden tests that ran")
        self.assertEqual(
            written.group(1), counted.group(1),
            "the count reads another file than the one the golden run writes",
        )
        self.assertGreater(int(counted.group(2)), 0, "a floor of 0 lets a run of no test pass")

    def test_ci_gate_judges_every_other_job_whatever_happened_to_it(self) -> None:
        """A job that the required check does not cover can fail without
        blocking a merge: the failure V7's wiring test caught."""
        _, jobs = self._workflow()
        named = [
            key for key, block in jobs.items()
            if re.search(r"(?m)^    name: CI gate\s*$", block)
        ]
        self.assertEqual(1, len(named), "exactly one job must be named CI gate")
        gate = jobs[named[0]]
        self.assertRegex(gate, r"(?m)^    if: always\(\)\s*$")
        needs = re.search(r"(?m)^    needs: \[([^\]]*)\]\s*$", gate)
        self.assertIsNotNone(needs, "CI gate declares no one-line needs: [...] list")
        self.assertEqual(
            set(jobs) - {named[0]},
            {name.strip() for name in needs.group(1).split(",")},
        )
        self.assertIn("toJSON(needs)", gate, "CI gate does not judge every job it waits for")

    @unittest.skipUnless(_BASH and shutil.which("jq"), "needs bash and jq, as the runner has")
    def test_ci_gate_is_green_only_when_every_job_succeeded(self) -> None:
        """Runs the gate's own script on the results GitHub hands it: a job
        that failed, was cancelled or was skipped must turn it red."""
        _, jobs = self._workflow()
        gate = next(
            block for block in jobs.values()
            if re.search(r"(?m)^    name: CI gate\s*$", block)
        )
        cases = {
            "success": {"gate": "success", "goldens": "success"},
            "failure": {"gate": "failure", "goldens": "success"},
            "cancelled": {"gate": "success", "goldens": "cancelled"},
            "skipped": {"gate": "skipped", "goldens": "success"},
        }
        for case, results in cases.items():
            needs = {job: {"result": result, "outputs": {}} for job, result in results.items()}
            run = subprocess.run(
                [_BASH, "-eo", "pipefail", "-c", _run_script(gate)],
                env={**os.environ, "NEEDS": json.dumps(needs)},
                capture_output=True, text=True,
            )
            with self.subTest(case=case):
                self.assertEqual(case == "success", run.returncode == 0, run.stdout + run.stderr)
                for job, result in results.items():
                    self.assertIn(f"{job}: {result}", run.stdout)

    def test_every_pull_request_runs_the_workflow_whatever_it_changes(self) -> None:
        """A path filter would leave a required check waiting forever on a pull
        request that touches none of its paths."""
        workflow, _ = self._workflow()
        on = _top_level_block(workflow, "on")
        self.assertEqual(
            {"pull_request", "workflow_dispatch"},
            set(re.findall(r"(?m)^  ([A-Za-z_]+):", on)),
        )
        for path_filter in ("paths:", "paths-ignore:"):
            with self.subTest(filter=path_filter):
                self.assertNotIn(path_filter, on)

    def test_every_flutter_install_reads_the_pinned_version(self) -> None:
        _, jobs = self._workflow()
        installs = {
            key: block for key, block in jobs.items() if "subosito/flutter-action" in block
        }
        self.assertTrue(installs, "no job installs Flutter")
        for key, block in installs.items():
            with self.subTest(job=key):
                self.assertIn("flutter-version-file: .fvmrc", block)
                self.assertNotIn("flutter-version:", block)

    def test_local_gate_fails_closed_when_required_tools_are_missing(self) -> None:
        script = (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")
        self.assertIn("--diff-filter=ACMRTD", script)
        self.assertIn(
            'FAILED+=("flutter unavailable for selected mandatory gates")',
            script,
        )
        self.assertIn('FAILED+=("document gate unavailable:', script)
        self.assertIn('FAILED+=("CI tooling tests unavailable:', script)
        self.assertNotIn('SKIPPED+=("format', script)
        self.assertNotIn('SKIPPED+=("test', script)


HEADER = """# {title}

| | |
|---|---|
| **Status** | active |
| **Purpose** | Test prompt |
| **Scope** | Test scope |
| **Source of truth for** | Test execution instructions |
| **Depends on** | `AGENTS.md` |
| **Updated by task** | TEST |
| **Last updated** | 2026-08-13 |

"""


class PromptContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("check_prompt_contract")

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.feature = self.root / "docs" / "prompt" / "sample"
        self.feature.mkdir(parents=True)
        self._write_valid_set()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_valid_set(self) -> None:
        (self.feature / "implementation.md").write_text(
            HEADER.format(title="Implementation")
            + "5Why. Check the worktree. Run verification and gate. Clean stop.\n",
            encoding="utf-8",
        )
        (self.feature / "recursive-architecture-logic-review.md").write_text(
            HEADER.format(title="Architecture review")
            + "Audit-only first. Check the worktree, business rules, architecture boundary, database persistence and failure handling. Apply fixes, test, then clean stop.\n",
            encoding="utf-8",
        )
        (self.feature / "recursive-ui-ux-review.md").write_text(
            HEADER.format(title="UI review")
            + "Audit-only production states in the production tree. Check the worktree. Use getRect and golden comparison, list approved divergence, auto-fix, test, and clean stop.\n",
            encoding="utf-8",
        )

    def test_valid_prompt_set_passes(self) -> None:
        self.assertEqual([], self.module.validate_prompt_root(self.root))

    def test_missing_review_file_fails(self) -> None:
        (self.feature / "recursive-ui-ux-review.md").unlink()
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("missing prompt files" in message for message in messages))

    def test_run_file_is_rejected(self) -> None:
        (self.feature / "run.md").write_text("# Run\n", encoding="utf-8")
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("unexpected prompt files" in message for message in messages))

    def test_ui_review_without_geometry_fails(self) -> None:
        path = self.feature / "recursive-ui-ux-review.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace("getRect", "geometry"),
            encoding="utf-8",
        )
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("getRect" in message for message in messages))

    def test_out_of_order_header_fails(self) -> None:
        path = self.feature / "implementation.md"
        text = path.read_text(encoding="utf-8")
        text = text.replace(
            "| **Purpose** | Test prompt |\n| **Scope** | Test scope |",
            "| **Scope** | Test scope |\n| **Purpose** | Test prompt |",
        )
        path.write_text(text, encoding="utf-8")
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("header fields" in message for message in messages))


if __name__ == "__main__":
    unittest.main()
