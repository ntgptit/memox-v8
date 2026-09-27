"""Tests for the design-token hook: it runs memox-v8's design-token rules, as
the guard resolves them, on the file just edited.

The hook exits 0 on any error by design (it must never block an edit), so a
hook that has stopped loading its rules looks exactly like a clean file. These
tests are what notice.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import yaml

HOOK = Path(__file__).resolve().parents[1] / "check_design_tokens.py"
REPO_ROOT = HOOK.parents[2]
RULES = (
    REPO_ROOT / "code-verification-guard-v2" / "registries" / "projects" / "memox-v8"
    / "rules" / "memox-design-token-rules.yaml"
)
SCREEN = "lib/features/deck/presentation/screens/sample_screen.dart"


def _load_hook():
    spec = importlib.util.spec_from_file_location("check_design_tokens", HOOK)
    module = importlib.util.module_from_spec(spec)
    sys.modules["check_design_tokens"] = module
    spec.loader.exec_module(module)
    return module


hook = _load_hook()


class LoadsMemoxV8Test(unittest.TestCase):
    def test_it_loads_the_enabled_design_token_rules_of_memox_v8(self) -> None:
        registry = yaml.safe_load(RULES.read_text(encoding="utf-8"))
        expected = {rule["id"] for rule in registry["rules"] if rule.get("enabled")}
        self.assertEqual(expected, {rule["id"] for rule in hook.design_token_rules()})

    def test_the_rules_arrive_with_the_scopes_the_guard_resolves(self) -> None:
        for rule in hook.design_token_rules():
            with self.subTest(rule=rule["id"]):
                self.assertTrue(rule.get("include"))


class AgreesWithTheGuardTest(unittest.TestCase):
    """The hook reports what the guard reports for the same file, including the
    rules whose scopes reach past product UI: text styles in `lib/app/`,
    durations and stroke widths in `lib/core/theme/`."""

    CASES = (
        (SCREEN, "final c = Colors.red;\n", {"memox.design_token.no_raw_color"}),
        ("lib/shared/widgets/sample_widget.dart", "padding: const EdgeInsets.all(8),\n",
         {"memox.design_token.no_raw_spacing_literal"}),
        ("lib/app/sample_screen.dart", "final s = TextStyle(fontSize: 12);\n",
         {"memox.design_token.no_raw_text_style"}),
        ("lib/core/theme/sample_theme.dart", "final d = Duration(milliseconds: 300);\n",
         {"memox.design_token.no_raw_duration"}),
        ("lib/core/theme/sample_theme.dart", "side: BorderSide(color: ink, width: 2),\n",
         {"memox.design_token.no_raw_stroke_width"}),
        ("lib/features/deck/domain/models/sample_model.dart", "final c = Colors.red;\n", set()),
        ("lib/shared/widgets/sample_widget.g.dart", "final c = Colors.red;\n", set()),
    )

    def test_each_file_gets_the_guards_findings(self) -> None:
        for relative_path, text, expected in self.CASES:
            with self.subTest(path=relative_path, text=text):
                found = {finding.rule_id for finding in hook.findings_for(relative_path, text)}
                self.assertEqual(expected, found)


class ReportsTest(unittest.TestCase):
    def test_a_finding_exits_2_and_names_its_rule_and_line(self) -> None:
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            code = hook.report(SCREEN, hook.findings_for(SCREEN, "\nfinal c = Colors.red;\n"))
        self.assertEqual(2, code)
        self.assertIn(f"[memox.design_token.no_raw_color] {SCREEN}:2", stderr.getvalue())

    def test_no_finding_exits_0_and_prints_nothing(self) -> None:
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            code = hook.report(SCREEN, [])
        self.assertEqual((0, ""), (code, stderr.getvalue()))

    def test_main_reads_the_payload_and_reports_the_edited_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            edited = root / SCREEN
            edited.parent.mkdir(parents=True)
            edited.write_text("final c = Colors.red;\n", encoding="utf-8")
            payload = io.StringIO(json.dumps({"tool_input": {"file_path": str(edited)}}))
            with mock.patch.object(hook, "REPO_ROOT", root), mock.patch.object(sys, "stdin", payload), \
                    contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(2, hook.main())


class NeverBlocksTest(unittest.TestCase):
    """Input the hook cannot use, or a guard it cannot load, exits 0."""

    @staticmethod
    def _run(stdin: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, str(HOOK)], input=stdin, capture_output=True, text=True, timeout=120,
        )

    def test_a_broken_payload_exits_0(self) -> None:
        self.assertEqual(0, self._run("not json").returncode)

    def test_a_file_outside_the_repository_exits_0(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            outside = Path(tmp) / "sample_screen.dart"
            outside.write_text("final c = Colors.red;\n", encoding="utf-8")
            payload = json.dumps({"tool_input": {"file_path": str(outside)}})
            self.assertEqual(0, self._run(payload).returncode)

    def test_a_guard_that_cannot_load_exits_0(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            edited = root / SCREEN
            edited.parent.mkdir(parents=True)
            edited.write_text("final c = Colors.red;\n", encoding="utf-8")
            payload = io.StringIO(json.dumps({"tool_input": {"file_path": str(edited)}}))
            broken = ImportError("No module named 'yaml'")
            with mock.patch.object(hook, "REPO_ROOT", root), mock.patch.object(sys, "stdin", payload), \
                    mock.patch.object(hook, "design_token_rules", side_effect=broken):
                self.assertEqual(0, hook.main())


if __name__ == "__main__":
    unittest.main()
