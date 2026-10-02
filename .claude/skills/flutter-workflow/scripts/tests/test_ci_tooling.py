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

# Tests about the real tree need the Flutter app. `dod_check.sh` exits early
# without a `pubspec.yaml` at the root, and these tests skip on the same
# condition.
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
# from ADR-010 #1, `domain/data/presentation/di` layers from ADR-010 #2),
# never against the real memox-v8 tree: a planner test tied to the real tree
# breaks whenever a feature or a test moves, for reasons that have nothing to
# do with the planner.
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
    has, without describing the real app.
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
# (feature-dependency BFS, database-query ownership) without being tied to
# production data that other tests (`ImpactMapCoverageTest`,
# `ImpactMapMatchesTheDocsTest`) keep in sync with `docs/features/`.
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
}


class DodCheckStampTest(unittest.TestCase):
    """The pass stamp: run twice on an unchanged tree, pay once.

    Running the gate again before commit, again before push and again before the
    PR is one tree state asked three times. The stamp exists so the repetition
    costs a fraction of a second instead of minutes, and so it works without
    anyone having to remember.
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

    Never against `REPO_ROOT`: the fixture makes every assertion below true
    whatever the real tree contains.
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

    def test_a_shared_widget_change_selects_the_full_host_suite(self) -> None:
        """A path under `lib/` outside a feature and `lib/core/` has no rule to
        narrow it, so it runs every non-golden host test."""
        plan = self._plan("lib/shared/widgets/mx_button_pair.dart")
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)

    def test_test_support_outside_the_known_folders_selects_everything(self) -> None:
        """Only `test/features/<feature>/<layer>/`, `test/app/`, `test/core/`
        and `test/shared/` narrow: support code anywhere else could feed any
        test, so it runs them all."""
        path = "test/visual_audit/support/audit_fixture.dart"
        plan = self._plan(path)
        self.assertTrue(plan.full_suite)
        self.assertIn(path, plan.unmatched_paths)

    def test_pictures_alone_need_no_static_check_and_no_host_test(self) -> None:
        """A committed golden image is not code: nothing the gate runs can fail
        on a `.png`, and CI's `goldens` job compares it against a fresh render."""
        plan = self._plan(
            "test/features/deck/presentation/goldens/deck_list_empty_light.png",
            "test/features/card/presentation/goldens/card_list_dark.png",
        )
        self.assertFalse(plan.full_suite)
        self.assertFalse(plan.needs_static)
        self.assertFalse(plan.needs_host_tests)
        self.assertEqual((), plan.test_files)
        self.assertEqual("pixels", plan.risk)

    def test_a_picture_beside_its_widget_keeps_the_widget_selection(self) -> None:
        """The narrowing must not survive contact with a real code change."""
        widget = "lib/features/card/presentation/widgets/items/card_tile_widget.dart"
        alone = self._plan(widget)
        beside = self._plan(
            "test/features/card/presentation/goldens/card_list_light.png", widget
        )
        self.assertTrue(beside.needs_static)
        self.assertTrue(beside.needs_host_tests)
        self.assertEqual("targeted", beside.risk)
        self.assertEqual(alone.test_files, beside.test_files)

    def test_repository_furniture_verifies_nothing(self) -> None:
        """Git plumbing, editor settings and `.github/` templates cannot change
        what Dart compiles or what the tests run."""
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
                self.assertFalse(plan.needs_host_tests)

    def test_the_workflow_itself_still_runs_everything(self) -> None:
        """Not an oversight left in place — the one case where running the
        whole suite *is* the point. Changing what verification runs is a claim
        that the new pipeline works, and only a full run tests that claim.
        """
        plan = self._plan(".github/workflows/ci.yml")
        self.assertTrue(plan.full_suite)

    def test_an_unclassified_path_still_widens_to_everything(self) -> None:
        """The fallback is the safe default: a path nobody classified runs
        everything."""
        plan = self._plan("tools/some_new_thing.py")
        self.assertTrue(plan.full_suite)

    def test_documents_alone_need_no_static_check_and_no_host_test(self) -> None:
        for path in ("docs/wbs_BE.md", ".impeccable/critique/notes.md"):
            with self.subTest(path=path):
                plan = self._plan(path)
                self.assertFalse(plan.needs_static)
                self.assertFalse(plan.needs_host_tests)
                self.assertEqual("docs", plan.risk)

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

    def test_a_prompt_set_is_documentation_like_any_other(self) -> None:
        """V8 has no prompt delivery contract: `docs/prompt/` reaches the
        `docs/` rule."""
        plan = self._plan("docs/prompt/progress/implementation.md")
        self.assertEqual(("documentation contract changed",), plan.reasons)
        self.assertEqual("docs", plan.risk)

    def test_a_path_v8_has_no_rule_for_selects_everything(self) -> None:
        """`widgetbook/` and `memox-api/` have no rule (spec of package 12a,
        D6): like any unrecognised path they run the full suite, until V8's
        API adds its own rule under its ADR."""
        for path in ("widgetbook/lib/main.dart", "memox-api/pom.xml"):
            with self.subTest(path=path):
                plan = self._plan(path)
                self.assertTrue(plan.full_suite)
                self.assertIn(path, plan.unmatched_paths)

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

    def test_use_case_change_adds_data_flow_consumers(self) -> None:
        plan = self._plan(
            "lib/features/study/domain/usecases/start_study_session_use_case.dart"
        )
        self.assertEqual(("domain", "presentation"), plan.affected_layers)
        self.assertIn(
            "test/features/study/data/study_flow_test.dart",
            plan.test_files,
        )

    def test_public_domain_contract_expands_transitive_dependents(self) -> None:
        plan = self._plan(
            "lib/features/deck/domain/repositories/deck_repository.dart"
        )
        self.assertTrue(
            {"deck", "card", "study", "search", "progress", "trash"}
            <= set(plan.affected_features)
        )
        self.assertEqual(("data", "domain", "presentation"), plan.affected_layers)

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
        self.assertEqual(("test",), plan.local_test_targets)

    def test_shared_theme_router_native_and_dependency_changes_are_full(self) -> None:
        for path in (
            "lib/core/theme/app_theme.dart",
            "lib/shared/widgets/mx_card.dart",
            "lib/app/router/app_router.dart",
            "android/app/build.gradle.kts",
            "pubspec.yaml",
        ):
            with self.subTest(path=path):
                self.assertTrue(self._plan(path).full_suite)

    def test_a_verification_script_change_is_full(self) -> None:
        """Like the workflow: a change to the gate's own scripts is proved
        only by the full run it selects."""
        plan = self._plan(".claude/skills/flutter-workflow/scripts/dod_check.sh")
        self.assertTrue(plan.full_suite)

    def test_test_only_change_runs_exact_tracked_test(self) -> None:
        path = "test/features/card/domain/card_text_test.dart"
        plan = self._plan(path)
        self.assertEqual((path,), plan.test_files)

    def test_golden_only_change_uses_runnable_surrogates(self) -> None:
        path = "test/shared/widgets/mx_components_golden_test.dart"
        plan = self._plan(path)
        self.assertNotIn(path, plan.test_files)
        self.assertTrue(plan.test_files)
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
        """The memo must not answer for a different tree.

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
            self.assertEqual({"test/only_test.dart"}, fixture)
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

    def test_a_new_feature_without_tests_promotes_to_the_full_suite(self) -> None:
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
        plan = self._plan("docs/wbs_BE.md", force_full=True)
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)

    def test_sealed_plan_is_immutable_and_json_is_deterministic(self) -> None:
        first = self._plan(
            "lib/features/card/data/repositories/card_repository_impl.dart",
            "docs/wbs_BE.md",
        )
        second = self._plan(
            "docs/wbs_BE.md",
            "lib/features/card/data/repositories/card_repository_impl.dart",
        )
        self.assertEqual(first, second)
        self.assertEqual(first.to_json_dict(), second.to_json_dict())
        with self.assertRaises(dataclasses.FrozenInstanceError):
            first.risk = "docs"

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
        self.assertIn("bash .claude/skills/flutter-workflow/scripts/run_goldens.sh", goldens)
        self.assertNotIn("--update", workflow)
        written = re.search(r"run_goldens\.sh --report (\S+)", goldens)
        counted = re.search(r"count_golden_tests\.py (\S+) (\d+)", goldens)
        self.assertIsNotNone(written, "the golden run writes no JSON report")
        self.assertIsNotNone(counted, "nothing counts the golden tests that ran")
        self.assertEqual(
            written.group(1), counted.group(1),
            "the count reads another file than the one the golden run writes",
        )
        self.assertGreater(int(counted.group(2)), 0, "a floor of 0 lets a run of no test pass")

    def test_the_supabase_job_runs_pgtap(self) -> None:
        """The backend is checked on every run: the migrations apply to a
        local Postgres and pgTAP proves the sync functions (ADR-015)."""
        _, jobs = self._workflow()
        self.assertIn("supabase", jobs, "no job verifies supabase/")
        supabase = jobs["supabase"]
        self.assertIn("supabase db start", supabase)
        self.assertIn("supabase test db", supabase)
        self.assertNotIn("api", jobs, "memox-api-services is frozen (ADR-015)")

    def test_ci_gate_judges_every_other_job_whatever_happened_to_it(self) -> None:
        """A job that the required check does not cover can fail without
        blocking a merge."""
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

    def test_the_workflow_runs_by_hand_while_paused_and_has_no_path_filter(self) -> None:
        """CI is paused (owner, 2026-09-26): only `workflow_dispatch` triggers it.
        Resuming adds `pull_request` back to this set. A path filter would leave
        a required check waiting forever on a pull request that touches none of
        its paths."""
        workflow, _ = self._workflow()
        on = _top_level_block(workflow, "on")
        self.assertEqual(
            {"workflow_dispatch"},
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


# The fields of the verification plan (spec of package 12a, D3): the six
# `dod_check.sh --changed` reads, and five that explain the selection.
PLAN_FIELDS = frozenset({
    "changed_paths",
    "affected_features",
    "affected_layers",
    "reasons",
    "unmatched_paths",
    "test_files",
    "local_test_targets",
    "risk",
    "full_suite",
    "needs_static",
    "needs_host_tests",
})


class GateRunsTheHookTestsTest(unittest.TestCase):
    """The design-token hook exits 0 on any error, so a hook that has stopped
    working looks like a clean file; its tests are what notice, and the gate
    runs them in every mode."""

    def test_the_gate_runs_the_hook_tests(self) -> None:
        script = (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")
        self.assertIn('HOOK_TESTS="$REPO_ROOT/.claude/hooks/tests"', script)
        self.assertIn("-m unittest discover -s '$HOOK_TESTS' -p 'test_*.py'", script)


class GateReadsThePlanTest(unittest.TestCase):
    """`dod_check.sh --changed` runs what `build_verification_plan.py` selects.

    The gate is the planner's only caller, and it reads the plan's JSON by
    field name: a field it reads that the plan does not write stops the run,
    and a step it schedules for a gate V8 does not have fails every run that
    selects it.
    """

    @staticmethod
    def _gate() -> str:
        return (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")

    def test_the_gate_reads_only_fields_the_plan_writes(self) -> None:
        script = self._gate()
        read = set(re.findall(r"read_plan_bool (\w+)", script))
        read |= set(re.findall(r"p\['(\w+)'\]", script))
        # What the gate acts on: a pattern that matched nothing would fail
        # here instead of passing the check below.
        self.assertLessEqual({"needs_static", "needs_host_tests", "local_test_targets"}, read)
        self.assertEqual(set(), read - PLAN_FIELDS)

    def test_the_gate_has_no_step_for_a_gate_v8_does_not_have(self) -> None:
        """No Widgetbook smoke test (V8 has no `widgetbook/`) and no prompt
        delivery contract (V8 has no `docs/prompt/`)."""
        lines = self._gate().lower().splitlines()
        for marker in ("widgetbook", "prompt_contract", "has_prompt_changes"):
            with self.subTest(marker=marker):
                self.assertEqual([], [line for line in lines if marker in line])

    def test_the_plan_holds_exactly_the_eleven_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = _fixture_repo(Path(temp) / "repo", "test/a_test.dart")
            paths = Path(temp) / "paths.txt"
            paths.write_text("test/a_test.dart\n", encoding="utf-8")
            output = Path(temp) / "plan.json"
            subprocess.run(
                [sys.executable, str(SCRIPTS / "build_verification_plan.py"),
                 "--root", str(root), "--paths-file", str(paths),
                 "--json-output", str(output)],
                check=True, capture_output=True, text=True,
            )
            written = json.loads(output.read_text(encoding="utf-8"))
        self.assertEqual(sorted(PLAN_FIELDS), sorted(written))

    def test_the_prompt_delivery_scripts_are_gone(self) -> None:
        for removed in (
            "check_prompt_contract.py",
            "read_local_prompt_set.ps1",
            "tests/test_local_prompt_handoff.py",
        ):
            with self.subTest(path=removed):
                self.assertFalse((SCRIPTS / removed).exists())


if __name__ == "__main__":
    unittest.main()
