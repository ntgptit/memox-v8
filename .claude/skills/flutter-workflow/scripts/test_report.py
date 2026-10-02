#!/usr/bin/env python3
"""Summarise one `flutter test --file-reporter json:<path>` run.

`dod_check.sh` prints this below the host test step: the wall clock, the time
of each bundle, the slowest tests, and, when something failed, each failing
test under the file it came from with the command that re-runs that file
alone. A file that passes alone but fails bundled leaks state into the next
file, which is still a failure (spec 2026-10-02-test-suite-bundling-design.md
§3.3).

**Report-only.** It always exits 0: the exit code of `flutter test` is the
verdict, and a report that could change it would be a second gate nobody
reviewed.
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path


TOP_DEFAULT = 10


@dataclass
class TestResult:
    file: str
    name: str
    millis: int
    passed: bool
    skipped: bool


@dataclass
class RunSummary:
    wall_millis: int = 0
    suite_millis: dict[str, int] = field(default_factory=dict)
    results: list[TestResult] = field(default_factory=list)
    load_failures: list[str] = field(default_factory=list)


def _relative(path: str, root: str) -> str:
    path = path.replace("\\", "/")
    prefix = root.replace("\\", "/").rstrip("/") + "/"
    return path[len(prefix):] if path.startswith(prefix) else path


def summarise(lines: list[str], root: str) -> RunSummary:
    """Read the JSON reporter's events into one [RunSummary]."""
    summary = RunSummary()
    suites: dict[int, str] = {}
    groups: dict[int, str] = {}
    tests: dict[int, dict] = {}
    started: dict[int, int] = {}
    suite_span: dict[str, list[int]] = {}
    for line in lines:
        if not line.strip():
            continue
        event = json.loads(line)
        kind = event.get("type")
        if kind == "suite":
            suites[event["suite"]["id"]] = _relative(event["suite"]["path"], root)
        elif kind == "group":
            groups[event["group"]["id"]] = event["group"]["name"] or ""
        elif kind == "testStart":
            tests[event["test"]["id"]] = event["test"]
            started[event["test"]["id"]] = event["time"]
        elif kind == "testDone":
            _record(summary, event, tests, started, suites, groups, suite_span)
        elif kind == "done":
            summary.wall_millis = event["time"]
    summary.suite_millis = {
        suite: span[1] - span[0] for suite, span in suite_span.items()
    }
    return summary


def _record(summary, event, tests, started, suites, groups, suite_span) -> None:
    test = tests[event["testID"]]
    suite = suites.get(test["suiteID"], "?")
    span = suite_span.setdefault(suite, [started[event["testID"]], event["time"]])
    span[0] = min(span[0], started[event["testID"]])
    span[1] = max(span[1], event["time"])
    passed = event["result"] == "success"
    # A suite that fails to compile reports one visible "loading" test.
    if not test.get("groupIDs") and test["name"].startswith("loading "):
        if not passed:
            summary.load_failures.append(suite)
        return
    if event.get("hidden"):
        return
    file, name = _origin(test, suite, groups)
    summary.results.append(
        TestResult(
            file=file,
            name=name,
            millis=event["time"] - started[event["testID"]],
            passed=passed,
            skipped=bool(event.get("skipped")),
        )
    )


def _origin(test: dict, suite: str, groups: dict[int, str]) -> tuple[str, str]:
    """The test file a test came from, and its name without that prefix.

    In a bundle the first group under the suite's root is the file's path; run
    one by one, the suite is the file.
    """
    name = test["name"]
    group_ids = test.get("groupIDs") or []
    if len(group_ids) > 1:
        candidate = groups.get(group_ids[1], "")
        if candidate.endswith("_test.dart"):
            return candidate, name[len(candidate):].strip() or name
    return suite, name


def render(summary: RunSummary, top: int) -> str:
    counted = [result for result in summary.results if not result.skipped]
    lines = [
        f"test report: {len(counted)} tests in "
        f"{summary.wall_millis / 1000:.1f} s wall clock, "
        f"{len(summary.suite_millis)} suite(s)"
    ]
    for suite, millis in sorted(summary.suite_millis.items(), key=lambda item: -item[1])[:top]:
        lines.append(f"  {millis / 1000:6.1f} s  {suite}")
    lines.append(f"slowest {min(top, len(counted))} tests:")
    for result in sorted(counted, key=lambda item: -item.millis)[:top]:
        lines.append(f"  {result.millis / 1000:6.1f} s  {result.file} :: {result.name}")
    failed = [result for result in counted if not result.passed]
    by_file: dict[str, list[str]] = defaultdict(list)
    for result in failed:
        by_file[result.file].append(result.name)
    if failed:
        lines.append(f"failures: {len(failed)} test(s) in {len(by_file)} file(s)")
        for file in sorted(by_file):
            lines.append(f"  {file}")
            lines.extend(f"    - {name}" for name in by_file[file])
            lines.append(f"    re-run alone: TZ=UTC flutter test {file}")
    for suite in summary.load_failures:
        lines.append(
            f"failed to load: {suite}. The compile error above names the file; "
            "MEMOX_TEST_BUNDLES=0 runs the files one by one"
        )
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--root", default=str(Path.cwd()))
    parser.add_argument("--top", type=int, default=TOP_DEFAULT)
    args = parser.parse_args(argv)
    try:
        lines = args.report.read_text(encoding="utf-8").splitlines()
        summary = summarise(lines, str(Path(args.root).resolve()))
    except (OSError, ValueError, KeyError) as error:
        print(f"test report unavailable: {error}")
        return 0
    print(render(summary, args.top))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
