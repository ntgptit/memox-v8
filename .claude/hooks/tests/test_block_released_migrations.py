"""Tests for the released-migration hook: an Edit or Write of a Supabase
migration or a Drift schema snapshot that `master` already has is denied; a
migration that exists only on the branch, and every other file, passes.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[1] / "block_released_migrations.py"


def _load_hook():
    spec = importlib.util.spec_from_file_location("block_released_migrations", HOOK)
    module = importlib.util.module_from_spec(spec)
    sys.modules["block_released_migrations"] = module
    spec.loader.exec_module(module)
    return module


hook = _load_hook()

RELEASED_SQL = "supabase/migrations/20260928000000_deck_sync.sql"
RELEASED_SNAPSHOT = "drift_schemas/drift_schema_v1.json"


def _git(repo: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(repo), *args], check=True, capture_output=True)


class DenialTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name).resolve()
        _git(self.repo, "init", "-q", "-b", "master")
        _git(self.repo, "config", "user.email", "t@example.com")
        _git(self.repo, "config", "user.name", "t")
        for path in (RELEASED_SQL, RELEASED_SNAPSHOT, "lib/main.dart"):
            (self.repo / path).parent.mkdir(parents=True, exist_ok=True)
            (self.repo / path).write_text("x\n", encoding="utf-8")
        _git(self.repo, "add", ".")
        _git(self.repo, "commit", "-q", "-m", "init")
        _git(self.repo, "checkout", "-q", "-b", "feature")

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def _reason(self, path: str) -> str | None:
        return hook.deny_reason({"tool_input": {"file_path": str(self.repo / path)}}, self.repo)

    def test_editing_a_released_supabase_migration_is_denied(self) -> None:
        reason = self._reason(RELEASED_SQL)
        self.assertIn(RELEASED_SQL, reason)
        self.assertIn("new migration", reason)

    def test_editing_a_released_drift_snapshot_is_denied(self) -> None:
        self.assertIn(RELEASED_SNAPSHOT, self._reason(RELEASED_SNAPSHOT))

    def test_a_migration_only_on_the_branch_passes(self) -> None:
        self.assertIsNone(self._reason("supabase/migrations/20261011000000_new.sql"))
        self.assertIsNone(self._reason("drift_schemas/drift_schema_v2.json"))

    def test_other_files_pass(self) -> None:
        self.assertIsNone(self._reason("lib/main.dart"))

    def test_a_path_outside_the_repository_passes(self) -> None:
        payload = {"tool_input": {"file_path": str(self.repo.parent / RELEASED_SQL)}}
        self.assertIsNone(hook.deny_reason(payload, self.repo))

    def test_a_payload_without_a_path_passes(self) -> None:
        self.assertIsNone(hook.deny_reason({"tool_input": {}}, self.repo))


class MainTest(unittest.TestCase):
    def test_main_prints_nothing_for_an_ordinary_file(self) -> None:
        payload = json.dumps({"tool_input": {"file_path": str(HOOK)}})
        result = subprocess.run(
            [sys.executable, str(HOOK)], input=payload, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_main_denies_a_released_migration_of_this_repository(self) -> None:
        released = hook.REPO_ROOT / RELEASED_SQL
        payload = json.dumps({"tool_input": {"file_path": str(released)}})
        result = subprocess.run(
            [sys.executable, str(HOOK)], input=payload, capture_output=True, text=True
        )
        output = json.loads(result.stdout)["hookSpecificOutput"]
        self.assertEqual(output["permissionDecision"], "deny")
        self.assertIn(RELEASED_SQL, output["permissionDecisionReason"])


if __name__ == "__main__":
    unittest.main()
