"""Tests of `test_report.py` (spec 2026-10-02-test-suite-bundling-design.md §4),
against reporter events recorded in the shape `flutter test --file-reporter
json:<path>` writes.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import unittest
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parents[1]


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


test_report = _load("test_report")


def _event(**fields) -> str:
    return json.dumps(fields)


_ROOT = "/repo"
_RECORDED = [
    _event(type="suite", suite={"id": 0, "path": "/repo/.dart_tool/memox_test_bundles/bundle_0_test.dart"}),
    _event(type="testStart", time=1, test={"id": 1, "name": "loading /repo/x", "suiteID": 0, "groupIDs": []}),
    _event(type="testDone", time=900, testID=1, result="success", hidden=True, skipped=False),
    _event(type="group", group={"id": 2, "name": "", "suiteID": 0}),
    _event(type="group", group={"id": 3, "name": "test/a_test.dart", "suiteID": 0}),
    _event(type="testStart", time=1000, test={"id": 4, "name": "test/a_test.dart fast", "suiteID": 0, "groupIDs": [2, 3]}),
    _event(type="testDone", time=1100, testID=4, result="success", hidden=False, skipped=False),
    _event(type="testStart", time=1100, test={"id": 5, "name": "test/a_test.dart slow one", "suiteID": 0, "groupIDs": [2, 3]}),
    _event(type="testDone", time=4100, testID=5, result="failure", hidden=False, skipped=False),
    _event(type="testStart", time=4100, test={"id": 6, "name": "test/a_test.dart skipped", "suiteID": 0, "groupIDs": [2, 3]}),
    _event(type="testDone", time=4100, testID=6, result="success", hidden=False, skipped=True),
    _event(type="done", time=5000, success=False),
]


class TestReportTest(unittest.TestCase):
    def test_a_bundled_run_names_each_test_by_its_original_file(self) -> None:
        summary = test_report.summarise(_RECORDED, _ROOT)
        self.assertEqual(summary.wall_millis, 5000)
        self.assertEqual(
            [(r.file, r.name, r.millis) for r in summary.results if not r.skipped],
            [("test/a_test.dart", "fast", 100), ("test/a_test.dart", "slow one", 3000)],
        )
        self.assertEqual(summary.suite_millis, {".dart_tool/memox_test_bundles/bundle_0_test.dart": 4099})

    def test_a_failure_prints_its_file_and_the_command_to_run_it_alone(self) -> None:
        text = test_report.render(test_report.summarise(_RECORDED, _ROOT), top=10)
        self.assertIn("test report: 2 tests in 5.0 s wall clock", text)
        self.assertIn("     3.0 s  test/a_test.dart :: slow one", text)
        self.assertIn("failures: 1 test(s) in 1 file(s)", text)
        self.assertIn(
            "re-run alone: TZ=UTC flutter test --exclude-tags golden test/a_test.dart", text
        )

    def test_a_bundled_failure_names_the_bundle_it_ran_in(self) -> None:
        text = test_report.render(test_report.summarise(_RECORDED, _ROOT), top=10)
        self.assertIn("ran in .dart_tool/memox_test_bundles/bundle_0_test.dart", text)
        self.assertIn("passes alone", text)

    def test_a_suite_that_fails_to_load_is_named(self) -> None:
        events = list(_RECORDED)
        events[2] = _event(type="testDone", time=900, testID=1, result="error", hidden=False, skipped=False)
        text = test_report.render(test_report.summarise(events, _ROOT), top=10)
        self.assertIn("failed to load: .dart_tool/memox_test_bundles/bundle_0_test.dart", text)

    def test_a_run_file_by_file_names_the_suite_as_the_file(self) -> None:
        events = [
            _event(type="suite", suite={"id": 0, "path": "/repo/test/b_test.dart"}),
            _event(type="group", group={"id": 1, "name": "", "suiteID": 0}),
            _event(type="testStart", time=0, test={"id": 2, "name": "works", "suiteID": 0, "groupIDs": [1]}),
            _event(type="testDone", time=10, testID=2, result="success", hidden=False, skipped=False),
        ]
        summary = test_report.summarise(events, _ROOT)
        self.assertEqual([(r.file, r.name) for r in summary.results], [("test/b_test.dart", "works")])

    def test_a_file_that_fails_to_load_alone_gets_no_bundle_hint(self) -> None:
        events = [
            _event(type="suite", suite={"id": 0, "path": "/repo/test/b_test.dart"}),
            _event(type="testStart", time=0, test={"id": 1, "name": "loading /repo/test/b_test.dart", "suiteID": 0, "groupIDs": []}),
            _event(type="testDone", time=10, testID=1, result="error", hidden=False, skipped=False),
        ]
        text = test_report.render(test_report.summarise(events, _ROOT), top=10)
        self.assertIn("failed to load: test/b_test.dart", text)
        self.assertNotIn("MEMOX_TEST_BUNDLES", text)

    def test_a_truncated_last_line_keeps_the_rest_of_the_report(self) -> None:
        events = list(_RECORDED[:-1]) + ['{"type":"testDo']
        summary = test_report.summarise(events, _ROOT)
        self.assertEqual(len([r for r in summary.results if not r.skipped]), 2)
        self.assertIn("1 unreadable line(s) skipped", test_report.render(summary, top=10))

    def test_a_suite_without_a_path_does_not_break_the_report(self) -> None:
        events = list(_RECORDED)
        events[0] = _event(type="suite", suite={"id": 0, "path": None})
        summary = test_report.summarise(events, _ROOT)
        self.assertEqual(summary.results[0].file, "test/a_test.dart")

    def test_a_missing_report_never_fails_the_gate(self) -> None:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = test_report.main(["/no/such/report.jsonl"])
        self.assertEqual(code, 0)
        self.assertIn("test report unavailable", out.getvalue())


if __name__ == "__main__":
    unittest.main()
