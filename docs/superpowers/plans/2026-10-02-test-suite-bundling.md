# MemoX V8 Host Test Suite Bundling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the gate's host test step run the suite through a few bundled entrypoints
instead of one `flutter test` process per file. That takes the non-golden suite from
13 min 31 s to about 2–3 min, without changing how a test is written.

**Architecture:** A new `bundle_tests.py` turns the targets `flutter test` would take into
one generated entrypoint per core under `.dart_tool/memox_test_bundles/`. Each entrypoint
imports many test files and runs each one's `main` inside a `group` named by its path. A new
`test_report.py` reads the run's JSON report and prints the slowest tests, plus each failing
file with the command that re-runs it alone. `dod_check.sh` wires both into its three modes
and keeps `MEMOX_TEST_BUNDLES=0` as the per-file fallback. No Dart source, schema or
dependency changes.

**Tech Stack:** Bash (`dod_check.sh`); Python 3 with the standard library only, because the
gate runs these scripts and their tests (`python3 -m unittest`) with no Python dependency
installed; Flutter 3.47.5 (`flutter test --file-reporter json:<path>`).

**Spec:**
[`docs/superpowers/specs/2026-10-02-test-suite-bundling-design.md`](../specs/2026-10-02-test-suite-bundling-design.md),
approved 2026-10-02 (rulings R1–R3).

**Prerequisite:** branch `claude/test-system-optimization-1i5591`, which holds the spec
(`5cb963d`) and this plan. Generated code is not committed. In a fresh working tree,
run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` first.
The full gate on this branch's base passes with 3411 non-golden host tests, and the CI
tooling tests report `Ran 82 tests` · `OK`.

**How this plan was checked:** every code block below was written and run first, in a
scratch worktree of this branch:
- the 17 new unit tests pass (`Ran 99 tests` · `OK` with the existing 82);
- the full gate passed in **3 min 04 s** with `flutter test (full suite, 4 bundles, …)` and
  `test report: 3411 tests`;
- `--changed --base HEAD` with one edited test file ran `1 test files in 1 bundles`;
- `MEMOX_TEST_BUNDLES=0 --fast` ran file by file (`390 tests`, 57 suites);
- a planted failing test made the gate exit 1 with `✗ failed gates: test`, and the report
  named the file and its re-run command.

## Global Constraints

- Every message printed by the new scripts is in English (CLAUDE.md, "Language").
- Python standard library only; the scripts are imported by `unittest` with no extra package.
- Bundles live only under `.dart_tool/memox_test_bundles/`; nothing generated is committed.
- Goldens never run on the host, bundled or not (CLAUDE.md, "The gate").
- `MEMOX_TEST_BUNDLES=<n>` sets the bundle count; unset means `os.cpu_count()`; `0` means
  run file by file.
- The report never changes the gate's verdict: `flutter test`'s exit code is the verdict.
- No `slow` tag (R3), and no budget that fails the gate (R2).

## Review Focus

1. **A new test file with a library-level `@Timeout`, `@TestOn`, `@Skip` or a non-golden
   `@Tags`.** It must be refused with its path named, not run without its annotation. Pinned
   in Task 1 (`test_a_library_level_annotation_is_refused_by_name`).
2. **A test file whose `main` is `async`.** `group` refuses an async body, so it must be
   refused with a fix in the message. Pinned in Task 1 (`test_an_async_main_is_refused_by_name`).
3. **A test file that fails to compile.** Its bundle fails to load, and so can the next
   bundle the compiler takes. The gate must fail, and the report must name each bundle and
   say how to isolate the file. Pinned in Task 2
   (`test_a_suite_that_fails_to_load_is_named`) and run end to end in Task 3, Step 7.
4. **A test that fails only when bundled** (state leaked from an earlier file). The gate
   must fail, and the report must print the standalone re-run. Pinned in Task 2
   (`test_a_failure_prints_its_file_and_the_command_to_run_it_alone`) and run end to end in
   Task 3, Step 6.
5. **A Windows workstation**, with backslash paths and an unknown core count. Pinned in
   Task 1 (`test_windows_separators_become_posix_imports`,
   `test_the_bundle_count_reads_the_environment_then_the_cores`).

---

## File structure

| File | Responsibility |
|---|---|
| `.claude/skills/flutter-workflow/scripts/bundle_tests.py` (create) | targets → runnable files → refusals → bundles on disk |
| `.claude/skills/flutter-workflow/scripts/test_report.py` (create) | JSON report → summary text; never fails |
| `.claude/skills/flutter-workflow/scripts/tests/test_bundle_tests.py` (create) | unit tests of the bundler on fixture repos |
| `.claude/skills/flutter-workflow/scripts/tests/test_test_report.py` (create) | unit tests of the report on recorded events |
| `.claude/skills/flutter-workflow/scripts/dod_check.sh` (modify) | host test step bundled in all three modes; header |
| `docs/shared/testing/README.md`, `.claude/skills/flutter-testing/SKILL.md` (modify) | the "no leaked global state" convention |
| `docs/wbs_BE.md` (modify) | the BE-D11 row and its verification line |
| the spec (modify) | §3.1 async `main`; §3.2 fallback wording; §5 compile-error row, as measured |

`bundle_tests.py` reuses `discover_tests`, `is_golden_only_test` and `normalize_path` from
`build_verification_plan.py`, so "runnable" and "golden-only" mean the same thing in both
scripts.

---

### Task 1: `bundle_tests.py`

**Files:**
- Create: `.claude/skills/flutter-workflow/scripts/bundle_tests.py`
- Test: `.claude/skills/flutter-workflow/scripts/tests/test_bundle_tests.py`

**Interfaces:**
- Consumes: `build_verification_plan.discover_tests(root: Path) -> set[str]`,
  `is_golden_only_test(path: Path) -> bool`, `normalize_path(raw: str) -> str`.
- Produces (Task 3 relies on these):
  - CLI `bundle_tests.py [--root R] [--paths-file F] [targets...]`. `F` is NUL-separated.
    The script reads `MEMOX_TEST_BUNDLES` and writes `.dart_tool/memox_test_bundles/bundle_<k>_test.dart`.
  - **stdout**: one repo-relative bundle path per line.
  - **stderr**: `bundle_tests: <n> test files in <m> bundles under .dart_tool/memox_test_bundles`.
  - **Exit code**: 0 on success, and also 0 with empty stdout when the targets name no
    runnable file (stderr then says so); 1 on a refusal or a bad `MEMOX_TEST_BUNDLES`.
  - Constants: `BUNDLE_DIR = ".dart_tool/memox_test_bundles"`, `BUNDLES_ENV = "MEMOX_TEST_BUNDLES"`.

- [ ] **Step 1: Write the failing tests**

Create `.claude/skills/flutter-workflow/scripts/tests/test_bundle_tests.py`:

```python
"""Tests of `bundle_tests.py` (spec 2026-10-02-test-suite-bundling-design.md §4).

They run against small fixture repositories, never against the real tree, so
they hold whatever tests the app grows.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import subprocess
import sys
import tempfile
import unittest
import unittest.mock
from pathlib import Path


SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


bundle_tests = _load("bundle_tests")

_PLAIN = "void main() { test('t', () {}); }\n"
_GOLDEN = "@Tags(['golden'])\nlibrary;\n\nvoid main() { test('g', () {}); }\n"


def _repo(root: Path, files: dict[str, str]) -> Path:
    """A git repository holding [files], with `.dart_tool/` ignored."""
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    (root / "pubspec.yaml").write_text("name: memox\n", encoding="utf-8")
    (root / ".gitignore").write_text(".dart_tool/\n", encoding="utf-8")
    for path, text in files.items():
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    return root


class BundleTestsTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)

    def _bundle(self, files: dict[str, str], *targets: str, count: str = "2"):
        _repo(self.root, files)
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            with unittest.mock.patch.dict("os.environ", {"MEMOX_TEST_BUNDLES": count}):
                code = bundle_tests.main(["--root", str(self.root), *targets])
        return code, out.getvalue().split(), err.getvalue()

    def _imported(self, bundles: list[str]) -> list[str]:
        found: list[str] = []
        for bundle in bundles:
            text = (self.root / bundle).read_text(encoding="utf-8")
            found += [
                line.split("'")[1].removeprefix("../../")
                for line in text.splitlines()
                if line.startswith("import '../../test/") and "flutter_test_config" not in line
            ]
        return found

    def test_every_runnable_file_is_bundled_once_and_goldens_are_left_out(self) -> None:
        files = {f"test/a/f{index}_test.dart": _PLAIN for index in range(5)}
        files["test/a/w_golden_test.dart"] = _GOLDEN
        code, bundles, err = self._bundle(files, "test")
        self.assertEqual(code, 0)
        self.assertEqual(len(bundles), 2)
        self.assertIn("bundle_tests: 5 test files in 2 bundles", err)
        self.assertEqual(
            sorted(self._imported(bundles)),
            sorted(path for path in files if "golden" not in path),
        )

    def test_a_library_level_annotation_is_refused_by_name(self) -> None:
        files = {
            "test/ok_test.dart": _PLAIN,
            "test/slow_test.dart": "// why\n@Timeout(Duration(minutes: 2))\nlibrary;\n" + _PLAIN,
        }
        code, bundles, err = self._bundle(files, "test")
        self.assertEqual(code, 1)
        self.assertEqual(bundles, [])
        self.assertIn("test/slow_test.dart: library-level @Timeout", err)

    def test_an_async_main_is_refused_by_name(self) -> None:
        files = {"test/late_test.dart": "Future<void> main() async {}\n"}
        code, _, err = self._bundle(files, "test")
        self.assertEqual(code, 1)
        self.assertIn("test/late_test.dart: an async main", err)

    def test_the_partition_is_the_same_whatever_order_the_targets_come_in(self) -> None:
        files = {f"test/f{index}_test.dart": _PLAIN for index in range(7)}
        _, first, _ = self._bundle(files, *sorted(files))
        first_text = [(self.root / b).read_text(encoding="utf-8") for b in first]
        _, second, _ = self._bundle(files, *sorted(files, reverse=True))
        second_text = [(self.root / b).read_text(encoding="utf-8") for b in second]
        self.assertEqual(first_text, second_text)

    def test_more_bundles_than_files_writes_no_empty_bundle(self) -> None:
        files = {"test/a_test.dart": _PLAIN, "test/b_test.dart": _PLAIN}
        code, bundles, _ = self._bundle(files, "test", count="8")
        self.assertEqual(code, 0)
        self.assertEqual(len(bundles), 2)

    def test_a_rerun_removes_the_bundles_of_the_last_run(self) -> None:
        files = {f"test/f{index}_test.dart": _PLAIN for index in range(4)}
        self._bundle(files, "test", count="4")
        _, bundles, _ = self._bundle(files, "test/f0_test.dart", count="4")
        on_disk = sorted(p.name for p in (self.root / bundle_tests.BUNDLE_DIR).glob("*.dart"))
        self.assertEqual(on_disk, ["bundle_0_test.dart"])
        self.assertEqual(len(bundles), 1)

    def test_windows_separators_become_posix_imports(self) -> None:
        files = {"test/a/b_test.dart": _PLAIN}
        _, bundles, _ = self._bundle(files, "test\\a\\b_test.dart")
        self.assertEqual(self._imported(bundles), ["test/a/b_test.dart"])

    def test_targets_naming_no_runnable_file_write_nothing_and_say_so(self) -> None:
        files = {"test/w_golden_test.dart": _GOLDEN}
        code, bundles, err = self._bundle(files, "test")
        self.assertEqual(code, 0)
        self.assertEqual(bundles, [])
        self.assertIn("no runnable test file", err)

    def test_a_missing_file_target_is_an_error(self) -> None:
        code, _, err = self._bundle({"test/a_test.dart": _PLAIN}, "test/gone_test.dart")
        self.assertEqual(code, 1)
        self.assertIn("no such test file: test/gone_test.dart", err)

    def test_the_bundle_count_reads_the_environment_then_the_cores(self) -> None:
        self.assertEqual(bundle_tests.bundle_count(None, 6), 6)
        self.assertEqual(bundle_tests.bundle_count("", None), 1)
        self.assertEqual(bundle_tests.bundle_count("3", 6), 3)
        for bad in ("0", "-1", "four"):
            with self.assertRaises(bundle_tests.BundleError):
                bundle_tests.bundle_count(bad, 6)

    def test_the_config_wraps_the_groups_when_the_repo_has_one(self) -> None:
        files = {"test/a_test.dart": _PLAIN, "test/flutter_test_config.dart": "// config\n"}
        _, bundles, _ = self._bundle(files, "test", count="1")
        text = (self.root / bundles[0]).read_text(encoding="utf-8")
        self.assertIn("import '../../test/flutter_test_config.dart' as config;", text)
        self.assertIn("Future<void> main() => config.testExecutable(() {", text)
        self.assertIn("  group('test/a_test.dart', t0.main);", text)

    def test_a_quote_or_dollar_in_a_path_is_escaped(self) -> None:
        self.assertEqual(bundle_tests._dart_string("test/it's_$x.dart"), "'test/it\\'s_\\$x.dart'")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run them to verify they fail**

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_bundle_tests.py' -v`
Expected: `ERROR` while loading the module, `FileNotFoundError: … bundle_tests.py`.

- [ ] **Step 3: Write the implementation**

Create `.claude/skills/flutter-workflow/scripts/bundle_tests.py`:

```python
#!/usr/bin/env python3
"""Bundle host test files into a few entrypoints for one `flutter test` run.

`flutter test` compiles every test file on its own and starts a fresh
`flutter_tester` for it, so the suite pays about 1.4 s per file however small
the file is (spec 2026-10-02-test-suite-bundling-design.md §1.1). A bundle
imports many files and runs each one's `main` inside a `group` named by its
path, so that cost is paid once per bundle and every reported test still names
its file.

`dod_check.sh` is the only caller. It takes the targets `flutter test` would
take (files or directories under `test/`), writes the bundles under
`.dart_tool/memox_test_bundles/` and prints their paths, one per line.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

from build_verification_plan import discover_tests, is_golden_only_test, normalize_path


BUNDLE_DIR = ".dart_tool/memox_test_bundles"
BUNDLES_ENV = "MEMOX_TEST_BUNDLES"
TEST_CONFIG = "test/flutter_test_config.dart"

# **What a bundle cannot carry.** `flutter test` reads a library-level
# annotation (`@Tags`, `@Timeout`, `@TestOn`, `@Skip`, `@OnPlatform`) from the
# file it is handed, so inside a bundle it would be dropped without a word; and
# `group` refuses an async body, so an async `main` cannot be wrapped. Both are
# refused by name rather than run differently from how they read.
_LEADING_ANNOTATION = re.compile(r"\A(?:\s|//[^\n]*\n|/\*[\s\S]*?\*/)*@(\w+)")
_ASYNC_MAIN = re.compile(r"(?m)^\s*(?:Future<\w+>\s+)?main\s*\(\s*\)\s*async\b")


class BundleError(Exception):
    """A selection that cannot be bundled; the message names why."""


def bundle_count(env_value: str | None, cpu_count: int | None) -> int:
    """`MEMOX_TEST_BUNDLES` when set, else one bundle per core.

    `0` means "do not bundle"; `dod_check.sh` decides that before calling, so
    reaching here with it is a caller error.
    """
    if env_value is None or not env_value.strip():
        return max(1, cpu_count or 1)
    try:
        count = int(env_value)
    except ValueError:
        raise BundleError(
            f"{BUNDLES_ENV} must be a whole number, got {env_value!r}"
        ) from None
    if count < 1:
        raise BundleError(
            f"{BUNDLES_ENV}={count} disables bundling; dod_check.sh runs the "
            "files one by one then, so this script should not have been called"
        )
    return count


def expand_targets(root: Path, targets: list[str]) -> list[str]:
    """Every runnable test file a target names, sorted and without repeats.

    A `.dart` target is that file; anything else is a directory and stands for
    every runnable test below it, the way `flutter test <dir>` reads it.
    """
    runnable = discover_tests(root)
    selected: set[str] = set()
    for raw in targets:
        target = normalize_path(raw).rstrip("/")
        if not target:
            continue
        if target.endswith(".dart"):
            if not (root / target).is_file():
                raise BundleError(f"no such test file: {target}")
            selected.add(target)
            continue
        prefix = target + "/"
        selected.update(path for path in runnable if path.startswith(prefix))
    return sorted(selected)


def select_files(root: Path, files: list[str]) -> list[str]:
    """[files] without the golden-only ones, refusing what cannot be bundled."""
    kept: list[str] = []
    refused: list[str] = []
    for path in files:
        if is_golden_only_test(root / path):
            continue
        text = (root / path).read_text(encoding="utf-8")
        annotation = _LEADING_ANNOTATION.match(text)
        if annotation:
            refused.append(
                f"{path}: library-level @{annotation.group(1)} would be dropped "
                "in a bundle; put it on the group or test instead"
            )
        elif _ASYNC_MAIN.search(text):
            refused.append(
                f"{path}: an async main cannot run inside a group; make main "
                "synchronous and move the awaits into setUpAll"
            )
        else:
            kept.append(path)
    if refused:
        raise BundleError("cannot bundle:\n  " + "\n  ".join(refused))
    return kept


def partition(files: list[str], count: int) -> list[list[str]]:
    """Deal [files] out in turn over [count] bundles; empty bundles are dropped.

    Sorted input gives the same bundles on every run, and dealing in turn
    measured balanced (60–87 s per bundle over the whole suite, spec §3.1).
    """
    buckets = [files[index::count] for index in range(count)]
    return [bucket for bucket in buckets if bucket]


def _dart_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    return f"'{escaped}'"


def render_bundle(files: list[str], *, with_config: bool) -> str:
    """The Dart source of one bundle importing [files] from `../../`."""
    lines = [
        "// Generated by bundle_tests.py for one `flutter test` run. Do not edit.",
        "import 'package:flutter_test/flutter_test.dart';",
        "",
    ]
    if with_config:
        lines.append(f"import {_dart_string('../../' + TEST_CONFIG)} as config;")
    for index, path in enumerate(files):
        lines.append(f"import {_dart_string('../../' + path)} as t{index};")
    lines.append("")
    groups = [
        f"  group({_dart_string(path)}, t{index}.main);"
        for index, path in enumerate(files)
    ]
    # A bundle under `.dart_tool/` is outside `test/`, so `flutter test` does
    # not apply `test/flutter_test_config.dart` to it; the bundle calls it.
    if with_config:
        lines.append("Future<void> main() => config.testExecutable(() {")
        lines.extend(groups)
        lines.append("});")
    else:
        lines.append("void main() {")
        lines.extend(groups)
        lines.append("}")
    return "\n".join(lines) + "\n"


def write_bundles(root: Path, files: list[str], count: int) -> list[str]:
    """Replace the bundles under [BUNDLE_DIR]; return their repo-relative paths."""
    out = root / BUNDLE_DIR
    out.mkdir(parents=True, exist_ok=True)
    for stale in out.glob("*.dart"):
        stale.unlink()
    with_config = (root / TEST_CONFIG).is_file()
    written: list[str] = []
    for index, bucket in enumerate(partition(files, count)):
        relative = f"{BUNDLE_DIR}/bundle_{index}_test.dart"
        (root / relative).write_text(
            render_bundle(bucket, with_config=with_config), encoding="utf-8"
        )
        written.append(relative)
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--paths-file", type=Path)
    parser.add_argument("targets", nargs="*")
    args = parser.parse_args(argv)

    targets = list(args.targets)
    if args.paths_file:
        targets.extend(
            item.decode("utf-8")
            for item in args.paths_file.read_bytes().split(b"\0")
            if item
        )
    root = args.root.resolve()
    try:
        count = bundle_count(os.environ.get(BUNDLES_ENV), os.cpu_count())
        files = select_files(root, expand_targets(root, targets))
    except BundleError as error:
        print(f"bundle_tests: {error}", file=sys.stderr)
        return 1
    if not files:
        print("bundle_tests: the targets name no runnable test file", file=sys.stderr)
        return 0
    written = write_bundles(root, files, count)
    print(
        f"bundle_tests: {len(files)} test files in {len(written)} bundles "
        f"under {BUNDLE_DIR}",
        file=sys.stderr,
    )
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_bundle_tests.py' -v`
Expected: `Ran 12 tests` · `OK`.

- [ ] **Step 5: Smoke it against the real tree**

Run: `python3 .claude/skills/flutter-workflow/scripts/bundle_tests.py test`
Expected: stderr `bundle_tests: 483 test files in <cores> bundles under .dart_tool/memox_test_bundles`,
and the bundle paths on stdout. The count is the number of non-golden `_test.dart` files at
the time; it was 483 when this plan was written. `git status --short` shows only the two
new files.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/bundle_tests.py \
        .claude/skills/flutter-workflow/scripts/tests/test_bundle_tests.py
git commit -m "feat(gate): bundle host test files into one entrypoint per core"
```

---

### Task 2: `test_report.py`

**Files:**
- Create: `.claude/skills/flutter-workflow/scripts/test_report.py`
- Test: `.claude/skills/flutter-workflow/scripts/tests/test_test_report.py`

**Interfaces:**
- Consumes: the JSON reporter's events (`suite`, `group`, `testStart`, `testDone`, `done`).
  In a bundle, the first group under a suite's root is named by the original file's path
  (Task 1's `group('<path>', tN.main)`).
- Produces (Task 3 relies on these): CLI `test_report.py <report.jsonl> [--root R] [--top N]`.
  It prints the summary to stdout and **always exits 0**.

- [ ] **Step 1: Write the failing tests**

Create `.claude/skills/flutter-workflow/scripts/tests/test_test_report.py`:

```python
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
        self.assertIn("re-run alone: TZ=UTC flutter test test/a_test.dart", text)

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

    def test_a_missing_report_never_fails_the_gate(self) -> None:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = test_report.main(["/no/such/report.jsonl"])
        self.assertEqual(code, 0)
        self.assertIn("test report unavailable", out.getvalue())


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run them to verify they fail**

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_test_report.py' -v`
Expected: `ERROR` while loading the module, `FileNotFoundError: … test_report.py`.

- [ ] **Step 3: Write the implementation**

Create `.claude/skills/flutter-workflow/scripts/test_report.py`:

```python
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_test_report.py' -v`
Expected: `Ran 5 tests` · `OK`.

- [ ] **Step 5: Run the whole tooling suite**

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'`
Expected: `Ran 99 tests` · `OK` (82 existing + 17 new; skips allowed only where they were before).

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/test_report.py \
        .claude/skills/flutter-workflow/scripts/tests/test_test_report.py
git commit -m "feat(gate): summarise a flutter test JSON report with re-run hints"
```

---

### Task 3: wire the bundles into `dod_check.sh`

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/dod_check.sh`. Replace the whole
  `if [[ $NEEDS_HOST_TESTS -eq 1 ]] && command -v flutter …` block that ends just before
  `# ------------------------------------------------------------- run them all`, and
  update the header.
- Modify: `docs/superpowers/specs/2026-10-02-test-suite-bundling-design.md` (one §3.1 bullet, one §3.2 bullet, one §5 row)

**Interfaces:**
- Consumes: Task 1's CLI and its stdout/stderr/exit contract; Task 2's CLI. From the
  `--changed` plan JSON it reads `p['test_files']` (already in `PLAN_FIELDS`, so
  `GateReadsThePlanTest` stays green) and still reads `p['local_test_targets']`.
- Produces: the `test` step, labelled `flutter test (<scope>, <m> bundles, no goldens, TZ=UTC)`,
  or `flutter test (<scope>, file by file, no goldens, TZ=UTC)` under `MEMOX_TEST_BUNDLES=0`.

- [ ] **Step 1: Replace the host test block**

Delete the block from `if [[ $NEEDS_HOST_TESTS -eq 1 ]] && command -v flutter >/dev/null 2>&1; then`
through its closing `fi`. That block currently contains the three `plan test …` calls:
`--changed: N compressed targets`, `--fast: Deck + app subset` and `full suite, no goldens,
TZ=UTC`. Put this in its place:

```bash
# **Bundled, unless `MEMOX_TEST_BUNDLES=0`.** `flutter test` compiles every
# test file on its own and starts a fresh process for it, so the suite paid
# ~1.4 s per file however small the file: 13m31s for 483 files on 2026-10-02.
# `bundle_tests.py` folds the selected files into one entrypoint per core and
# the same 3411 tests ran in 2m12s (spec 2026-10-02-test-suite-bundling).
# `MEMOX_TEST_BUNDLES=0` runs the same targets file by file, as before: the
# rollback, and the way to tell a real failure from state one file leaks into
# the next.
#
# **`TZ=UTC`, and never goldens here.** Goldens are generated and compared only
# in the Linux container (golden.Dockerfile, CLAUDE.md); a host run compares
# them against a different rasteriser and fails on pixels that are not defects.
# A bundle could not run them anyway: `matchesGoldenFile` resolves the PNG
# beside the test file, so `bundle_tests.py` leaves golden files out.
#
# Either way `test_report.py` prints the slowest tests and, on a failure, each
# failing file with the command that re-runs it alone. It never changes the
# verdict: the subshell exits with `flutter test`'s own code.
BUNDLE_PY="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/bundle_tests.py"
REPORT_PY="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/test_report.py"
TEST_REPORT="$WORK/test-report.jsonl"
TEST_TARGETS_NUL="$WORK/test-targets.nul"

# plan_host_tests <scope> <per-file targets...>
# Bundles the targets listed in $TEST_TARGETS_NUL, or with
# MEMOX_TEST_BUNDLES=0 (or no python) runs the per-file targets as given.
plan_host_tests() {
  local scope="$1"
  shift
  local quoted="" report_tail="; exit \$?)"
  [[ -n "$PY" ]] &&
    report_tail="; rc=\$?; '$PY' '$REPORT_PY' '$TEST_REPORT' --root '$REPO_ROOT'; exit \$rc)"
  if [[ "${MEMOX_TEST_BUNDLES:-}" == "0" || -z "$PY" ]]; then
    [[ $# -gt 0 ]] && printf -v quoted " %q" "$@"
    plan test "flutter test ($scope, file by file, no goldens, TZ=UTC)" \
      "(TZ=UTC flutter test --exclude-tags golden --file-reporter json:'$TEST_REPORT'$quoted$report_tail"
    return
  fi
  local bundle_out bundles=()
  if ! bundle_out="$("$PY" "$BUNDLE_PY" --root "$REPO_ROOT" --paths-file "$TEST_TARGETS_NUL" 2>"$WORK/bundle.err")"; then
    step "test bundling"
    cat "$WORK/bundle.err"
    FAILED+=("test bundling — see above")
    return
  fi
  [[ -n "$bundle_out" ]] && mapfile -t bundles <<<"$bundle_out"
  if [[ ${#bundles[@]} -eq 0 ]]; then
    FAILED+=("test plan selected no test files")
    return
  fi
  printf -v quoted " %q" "${bundles[@]}"
  plan test "flutter test ($scope, ${#bundles[@]} bundles, no goldens, TZ=UTC)" \
    "(cat '$WORK/bundle.err'; TZ=UTC flutter test -j ${#bundles[@]} --exclude-tags golden --file-reporter json:'$TEST_REPORT'$quoted$report_tail"
}

if [[ $NEEDS_HOST_TESTS -eq 1 ]] && command -v flutter >/dev/null 2>&1; then
  if [[ ! -d test ]]; then
    FAILED+=("selected host tests unavailable: no test/ directory")
  elif [[ $CHANGED -eq 1 ]]; then
    # The bundles take the exact `test_files`; the per-file run keeps the
    # compressed `local_test_targets`, which fit a Windows command line.
    "$PY" -c "import json,sys; p=json.load(open(sys.argv[1], encoding='utf-8')); sys.stdout.buffer.write(b''.join(x.encode() + b'\\0' for x in p['test_files']))" "$PLAN_JSON" >"$TEST_TARGETS_NUL"
    mapfile -d '' CHANGED_TEST_TARGETS < <(
      "$PY" -c "import json,sys; p=json.load(open(sys.argv[1], encoding='utf-8')); sys.stdout.buffer.write(b'\\0'.join(x.encode() for x in p['local_test_targets']) + b'\\0')" "$PLAN_JSON"
    )
    if [[ ${#CHANGED_TEST_TARGETS[@]} -eq 0 ]]; then
      FAILED+=("test plan selected no test files")
    else
      plan_host_tests "--changed" "${CHANGED_TEST_TARGETS[@]}"
    fi
  elif [[ $FAST -eq 1 ]]; then
    printf '%s\0' test/app test/features/deck >"$TEST_TARGETS_NUL"
    plan_host_tests "--fast: Deck + app subset" test/app test/features/deck
  else
    printf '%s\0' test >"$TEST_TARGETS_NUL"
    plan_host_tests "full suite"
  fi
fi
```

Why the command is wrapped in `( … )`: the scheduler runs each step as
`{ eval "$cmd" >log; printf "$?" >rc; } &`. A bare `exit` would leave that group before it
writes `rc`, and the step would read as failed. The subshell exits with `flutter test`'s
code after the report has printed.

- [ ] **Step 2: Update the header**

In the usage block, after the `--force` line, add:

```bash
#   MEMOX_TEST_BUNDLES=<n>  host test bundles (default: one per core); 0 runs
#           the test files one by one, the way the suite ran before 2026-10-02
```

In the pass-stamp paragraph, replace
`already knows and exits at once: 0.03s against 266s for a full run, measured`
`# in the cloud container on 2026-09-26.` with:

```bash
# already knows and exits at once: 0.03s against 184s for a full run with the
# host tests bundled, measured in the cloud container on 2026-10-02.
```

Run: `bash -n .claude/skills/flutter-workflow/scripts/dod_check.sh && echo ok`
Expected: `ok`

- [ ] **Step 3: Align the spec with the code**

In the spec, §3.2, replace the bullet
`` `MEMOX_TEST_BUNDLES=0` restores today's per-file command unchanged. It is the rollback, ``
`and the way to check whether a failure only happens bundled.` with:

```markdown
- `MEMOX_TEST_BUNDLES=0` runs the same targets file by file, as before; the only addition
  is the JSON report that feeds §3.3. It is the rollback, and the way to check whether a
  failure only happens bundled.
```

In §3.1, after the **Refusal** bullet, add:

```markdown
- **Async `main`.** `group` refuses an async body, so a file whose `main` is `async` is
  refused the same way, with the fix in the message: make `main` synchronous and move the
  awaits into `setUpAll`. No file has one today.
```

In the §5 table, replace the row starting
`| A bundle fails to compile because of one file, and the other files in that bundle report nothing |`
with:

```markdown
| One file fails to compile: its bundle, and possibly the next bundle the frontend server compiles, report nothing | The compile error names the file, and `test_report.py` names each bundle that failed to load. The per-file fallback isolates the file. `flutter analyze`, which runs in the same gate, catches the same error. |
```

- [ ] **Step 4: Run the full gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force`
Expected:
- `▶ flutter test (full suite, <cores> bundles, no goldens, TZ=UTC)`, then
  `bundle_tests: <n> test files in <cores> bundles …`;
- `test report: 3411 tests in …` (the same count the base reported);
- `▶ CI tooling unit tests` → `Ran 99 tests` · `OK`;
- `✓ mechanical gates passed`.

Record the wall clock for the PR; it was 3 min 04 s on 4 cores.

- [ ] **Step 5: Check `--changed` and the fallback**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --force
MEMOX_TEST_BUNDLES=0 bash .claude/skills/flutter-workflow/scripts/dod_check.sh --fast --force
```

Expected:
- `--changed`: this branch changes a verification script, so the plan is promoted to the
  full suite (`verification plan: full`) and the step reads
  `flutter test (--changed, <cores> bundles, …)`.
- The `--fast` run prints `flutter test (--fast: Deck + app subset, file by file, …)` and
  `test report: 390 tests in …` across 57 suites.
- Both end with `✓ mechanical gates passed`.

The scratch check also ran a targeted plan: with the scripts committed, one edited test file
and `--base HEAD`, it printed `bundle_tests: 1 test files in 1 bundles`.

- [ ] **Step 6: Prove a failure still fails the gate**

The probe goes under `test/features/deck/` so that `--fast` picks it up:

```bash
printf "import 'package:flutter_test/flutter_test.dart';\n\nvoid main() {\n  test('fails on purpose', () => expect(1, 2));\n}\n" \
  > test/features/deck/zz_fail_probe_test.dart
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --fast --force; echo "rc=$?"
rm test/features/deck/zz_fail_probe_test.dart
```

Expected: `failures: 1 test(s) in 1 file(s)`,
`re-run alone: TZ=UTC flutter test test/features/deck/zz_fail_probe_test.dart`,
`✗ failed gates:` / `  - test`, and `rc=1`. Then `git status --short` shows no probe.

- [ ] **Step 7: Prove a compile error fails the gate and is named**

```bash
printf "void main() { undefinedCall(); }\n" > test/features/deck/zz_broken_probe_test.dart
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --fast --force; echo "rc=$?"
rm test/features/deck/zz_broken_probe_test.dart
```

Expected:
- The `flutter test` step shows `Compilation failed … test/features/deck/zz_broken_probe_test.dart:1:15: Error: Method not found: 'undefinedCall'`.
- The report prints `failed to load: .dart_tool/memox_test_bundles/bundle_<k>_test.dart …`
  for the bundle holding the file. The frontend server can carry the error into the next
  bundle it compiles, so a second `failed to load` line is expected too (the scratch check
  showed two of four).
- `✗ failed gates:` lists `analyze` and `test` (and `format`, since the probe is unformatted).
- `rc=1`. Then `git status --short` shows no probe.

- [ ] **Step 8: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/dod_check.sh \
        docs/superpowers/specs/2026-10-02-test-suite-bundling-design.md
git commit -m "feat(gate): run the host suite bundled, MEMOX_TEST_BUNDLES=0 file by file"
```

---

### Task 4: conventions and tracking

**Files:**
- Modify: `docs/shared/testing/README.md` (§4.1, after the "Khởi động lại ứng dụng" bullet)
- Modify: `.claude/skills/flutter-testing/SKILL.md` (§Layout, after the "Fakes of the domain contracts" paragraph)
- Modify: `docs/wbs_BE.md` (table "Hạ tầng và tài liệu", list "Đã xong và đã kiểm chứng", "Ngữ cảnh cập nhật")

**Interfaces:**
- Consumes: the behaviour of Tasks 1–3 and the measured numbers from Task 3, Step 4.
- Produces: documents only.

- [ ] **Step 1: Add the convention to the testing README**

After the bullet that ends `… bằng chứng thấp hơn một lần hệ điều hành thật thu hồi tiến trình.`
in §4.1, add:

```markdown
- **Gate chạy test theo bundle.** `dod_check.sh` gộp các file `_test.dart` (trừ
  golden) thành mỗi core một entrypoint dưới `.dart_tool/memox_test_bundles/`, nên
  nhiều file chạy chung một tiến trình. Một file test MUST trả lại mọi global state
  nó đổi (biến static, `debug*`, `HttpOverrides.global`, `tester.view`) bằng
  `addTearDown`, MUST NOT có annotation mức library ngoài `@Tags(['golden'])`, và
  `main` MUST đồng bộ. Một test chỉ fail khi chạy chung: chạy riêng file đó bằng
  lệnh mà báo cáo của gate in ra, hoặc chạy cả gate với `MEMOX_TEST_BUNDLES=0`
  ([spec](../../superpowers/specs/2026-10-02-test-suite-bundling-design.md)).
```

- [ ] **Step 2: Add the same rule to the `flutter-testing` skill**

After the paragraph that ends `… so a changed signature is a compile error where it matters.`,
add:

```markdown
The gate runs the host suite bundled: `bundle_tests.py` folds every non-golden
test file into one entrypoint per core, so files share a process. A test file
therefore restores any global state it changes (statics, `debug*` overrides,
`HttpOverrides.global`, `tester.view`) through `addTearDown`, keeps library-level
annotations to `@Tags(['golden'])`, and has a synchronous `main`; the bundler
refuses the last two by name. When a test fails only bundled, run its file alone
with the command the gate's report prints, or the whole gate with
`MEMOX_TEST_BUNDLES=0`.
```

- [ ] **Step 3: Record BE-D11 in `docs/wbs_BE.md`**

Add this row at the end of the "Hạ tầng và tài liệu" table, after `BE-D10`:

```markdown
| BE-D11 | Gate chạy host test theo bundle: `bundle_tests.py` gộp các file `_test.dart` không phải golden thành mỗi core một entrypoint dưới `.dart_tool/memox_test_bundles/`, `test_report.py` in test chậm nhất và lệnh chạy riêng file fail; `dod_check.sh` dùng cho cả ba mode, `MEMOX_TEST_BUNDLES=0` chạy từng file như trước. Suite non-golden từ 13 phút 31 giây xuống khoảng 2–3 phút trên 4 core, cùng 3411 test | xong | BE-D5 | M | [spec](superpowers/specs/2026-10-02-test-suite-bundling-design.md) và [plan](superpowers/plans/2026-10-02-test-suite-bundling.md); `test_bundle_tests.py` và `test_test_report.py` trong `.claude/skills/flutter-workflow/scripts/tests/` | — |
```

In "Đã xong và đã kiểm chứng", after the `BE-D7` entry, add:

```markdown
- **BE-D11** ([spec](superpowers/specs/2026-10-02-test-suite-bundling-design.md),
  [plan](superpowers/plans/2026-10-02-test-suite-bundling.md)): gate full xanh với bước
  test chạy theo bundle, cùng số test non-golden như trước (3411); `--changed`, `--fast`
  với `MEMOX_TEST_BUNDLES=0`, một test fail cố ý và một file không compile đều được kiểm
  chứng làm gate đỏ hoặc xanh đúng như spec §4; final review toàn nhánh trước khi mở PR.
```

At the top of "Ngữ cảnh cập nhật", add:

```markdown
- **Cập nhật ngày 2026-10-02:** BE-D11 xong: gate chạy host test theo bundle (spec
  2026-10-02-test-suite-bundling-design.md). Đo trong cloud container 4 core: suite
  non-golden từ 13 phút 31 giây xuống 2 phút 12 giây, cả gate full còn khoảng 3 phút.
```

- [ ] **Step 4: Run the document gate, then the full gate**

Run: `python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)` (the warnings are the same as before this branch).

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: `✓ mechanical gates passed`.

- [ ] **Step 5: Commit**

```bash
git add docs/shared/testing/README.md .claude/skills/flutter-testing/SKILL.md docs/wbs_BE.md
git commit -m "docs: the bundled host suite convention, BE-D11"
```
