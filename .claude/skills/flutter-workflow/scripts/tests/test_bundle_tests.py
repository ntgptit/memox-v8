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
