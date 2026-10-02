"""Tests for the test-command hook: a Bash command that runs `flutter test`
file by file over a directory, the whole suite or many files gets a note that
`run_tests.sh` runs the same tests bundled. The hook never blocks a command.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path

HOOK = Path(__file__).resolve().parents[1] / "check_test_command.py"


def _load_hook():
    spec = importlib.util.spec_from_file_location("check_test_command", HOOK)
    module = importlib.util.module_from_spec(spec)
    sys.modules["check_test_command"] = module
    spec.loader.exec_module(module)
    return module


hook = _load_hook()

SCREENSHOT = (
    'flutter test test/features --exclude-tags golden -j 2 2>&1 | '
    'grep -E "^\\S*[0-9:]+ \\+[0-9]+.*(-[0-9]+|All tests|Some tests)" | tail -5; '
    "flutter test test/features --exclude-tags golden -j 2 2>&1 | tail -15"
)


class AdviceTest(unittest.TestCase):
    def test_a_directory_target_is_pointed_at_run_tests(self) -> None:
        note = hook.advise("flutter test test/features --exclude-tags golden 2>&1 | tail -15")
        self.assertIn("run_tests.sh test/features", note)
        self.assertIn("file by file", note)

    def test_the_whole_suite_is_pointed_at_run_tests(self) -> None:
        for command in ("flutter test", "TZ=UTC flutter test --exclude-tags golden -j 4"):
            with self.subTest(command=command):
                self.assertIn("run_tests.sh", hook.advise(command))

    def test_many_files_are_pointed_at_run_tests(self) -> None:
        files = " ".join(f"test/f{index}_test.dart" for index in range(4))
        self.assertIn("run_tests.sh", hook.advise(f"flutter test {files}"))

    def test_running_the_same_tests_twice_is_named(self) -> None:
        note = hook.advise(SCREENSHOT)
        self.assertIn("twice", note)
        self.assertIn("run_tests.sh test/features", note)

    def test_a_broad_golden_run_is_pointed_at_run_goldens(self) -> None:
        note = hook.advise("TZ=UTC flutter test --tags golden")
        self.assertIn("run_goldens.sh", note)

    def test_one_or_two_files_need_no_note(self) -> None:
        for command in (
            "flutter test test/a_test.dart",
            "TZ=UTC flutter test test/a_test.dart test/b_test.dart --plain-name 'x y'",
            "flutter test test/a_test.dart -j 2 --reporter expanded",
        ):
            with self.subTest(command=command):
                self.assertIsNone(hook.advise(command))

    def test_the_gate_scripts_need_no_note(self) -> None:
        for command in (
            "bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features",
            "bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed",
            "bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update",
            "git commit -m 'flutter test test/features is slow'",
            "echo flutter test",
        ):
            with self.subTest(command=command):
                self.assertIsNone(hook.advise(command))

    def test_text_inside_a_heredoc_is_not_a_command(self) -> None:
        command = (
            "python3 - <<'PY'\n"
            'doc = """\n'
            "flutter test test/database/\n"
            '"""\n'
            "PY\n"
            "cat <<-EOF\n\tflutter test test/features\n\tEOF"
        )
        self.assertIsNone(hook.advise(command))

    def test_a_command_after_the_heredoc_is_still_judged(self) -> None:
        command = "cat <<EOF > notes.txt\nflutter test\nEOF\nflutter test test/features"
        self.assertIn("run_tests.sh test/features", hook.advise(command))

    def test_only_a_command_position_counts(self) -> None:
        for command in ("cd app && TZ=UTC flutter test test/features", "time flutter test test/core"):
            with self.subTest(command=command):
                self.assertIsNotNone(hook.advise(command))
        for command in ("python3 -c 'print(1)' flutter test test/x", "ls flutter test test/core"):
            with self.subTest(command=command):
                self.assertIsNone(hook.advise(command))

    def test_an_explicit_file_by_file_run_needs_no_note(self) -> None:
        self.assertIsNone(hook.advise("MEMOX_TEST_BUNDLES=0 flutter test test/features"))

    def test_a_command_that_does_not_parse_still_gets_judged_or_skipped(self) -> None:
        self.assertIsNone(hook.advise("echo 'unterminated"))


class HookProtocolTest(unittest.TestCase):
    def _run(self, payload: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(HOOK)], input=payload, capture_output=True, text=True
        )

    def test_a_note_is_additional_context_and_never_a_decision(self) -> None:
        result = self._run(json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "flutter test test/features"},
        }))
        self.assertEqual(result.returncode, 0)
        output = json.loads(result.stdout)["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertIn("run_tests.sh", output["additionalContext"])
        self.assertNotIn("permissionDecision", output)

    def test_a_command_without_advice_prints_nothing(self) -> None:
        result = self._run(json.dumps({"tool_name": "Bash", "tool_input": {"command": "ls"}}))
        self.assertEqual((result.returncode, result.stdout), (0, ""))

    def test_broken_input_never_breaks_the_command(self) -> None:
        for payload in ("not json", "", json.dumps({"tool_input": None})):
            with self.subTest(payload=payload):
                result = self._run(payload)
                self.assertEqual((result.returncode, result.stdout), (0, ""))


if __name__ == "__main__":
    unittest.main()
