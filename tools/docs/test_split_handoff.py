"""Tests for split_handoff.py:  python tools/docs/test_split_handoff.py"""
from __future__ import annotations

import contextlib
import hashlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split_handoff as sh  # noqa: E402

FOUNDATIONS = "/x\n\n# Foundations — Việt ✓\r\n  trailing spaces   \nno final newline"
THEME = "# Theme\n"
STATUS_BAR = "# StatusBar\n\n| pipe | stays |\n"
ICON_TILE = "# IconTile"


def sample(widgets=("StatusBar", "IconTile")) -> dict:
    specs = {"StatusBar": STATUS_BAR, "IconTile": ICON_TILE}
    return {
        "generated": "2026-01-01T00:00:00Z",
        "implementationOrder": ["FOUNDATIONS", "THEME_BINDING"],
        "foundations": {"step": 1, "handoffMode": "FOUNDATIONS", "spec": FOUNDATIONS},
        "themeHandoff": {
            "step": 2, "kind": "PREREQ", "spec": THEME,
            "views": {"componentComposition": {"IconTile": ["glyph → Icon | x"]}},
        },
        "widgets": [
            {"name": n, "section": "A", "implementationAction": "IMPLEMENT_COMPONENT",
             "runnableAfter": None if n == "StatusBar" else "THEME_BINDING",
             "spec": specs[n]}
            for n in widgets
        ],
    }


def snapshot(out: Path) -> dict[str, bytes]:
    return {p.relative_to(out).as_posix(): p.read_bytes() for p in out.rglob("*") if p.is_file()}


def split_marker(content: bytes) -> tuple[str, bytes]:
    """(first line, everything after the blank line that follows it)."""
    marker, _, body = content.partition(b"\n\n")
    return marker.decode("utf-8"), body


class SplitHandoffTest(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.tmp = Path(tmp.name)
        self.out = self.tmp / "out"

    def run_main(self, src: Path) -> tuple[int, str]:
        """Run the CLI on the JSON file `src`; return (exit code, stdout + stderr)."""
        captured = io.StringIO()
        with contextlib.redirect_stdout(captured), contextlib.redirect_stderr(captured):
            code = sh.main([str(src), str(self.out)])
        return code, captured.getvalue()

    def run_split(self, data) -> tuple[int, str]:
        """run_main on `data` written out as JSON."""
        src = self.tmp / "in.json"
        src.write_text(json.dumps(data), encoding="utf-8")
        return self.run_main(src)

    def test_spec_strings_follow_the_marker_byte_for_byte(self) -> None:
        self.assertEqual(self.run_split(sample())[0], 0)
        files = snapshot(self.out)
        # CRLF, no final newline, unicode and pipes all survive untouched
        for path, spec in (
            ("01-foundations.md", FOUNDATIONS),
            ("02-theme-binding.md", THEME),
            ("widgets/status-bar.md", STATUS_BAR),
            ("widgets/icon-tile.md", ICON_TILE),
        ):
            with self.subTest(path=path):
                self.assertEqual(split_marker(files[path])[1], spec.encode("utf-8"))

    def test_every_markdown_file_is_marked_generated_from_its_json(self) -> None:
        self.run_split(sample())
        markdown = {p: c for p, c in snapshot(self.out).items() if p.endswith(".md")}
        self.assertEqual(len(markdown), 6)
        for path, content in markdown.items():
            with self.subTest(path=path):
                marker = split_marker(content)[0]
                self.assertRegex(marker, r"^<!-- GENERATED .* -->$")
                self.assertIn("DO NOT EDIT", marker)
                self.assertIn("in.json", marker)

    def test_traceability_hashes_the_spec_string_not_the_file(self) -> None:
        self.run_split(sample())
        trace = (self.out / "99-traceability.md").read_text(encoding="utf-8")
        row = next(line for line in trace.splitlines() if "(widgets/icon-tile.md)" in line)
        self.assertIn(f"`{hashlib.sha256(ICON_TILE.encode('utf-8')).hexdigest()}`", row)
        self.assertIn(f"| {len(ICON_TILE)} |", row)

    def test_index_links_widget_files_and_escapes_composition(self) -> None:
        self.run_split(sample())
        index = (self.out / "00-index.md").read_text(encoding="utf-8")
        self.assertIn("glyph → Icon \\| x", index)
        self.assertIn("(widgets/icon-tile.md)", index)

    def test_traceability_names_source_json_paths(self) -> None:
        self.run_split(sample())
        trace = (self.out / "99-traceability.md").read_text(encoding="utf-8")
        self.assertIn("`$.widgets[1].spec`", trace)
        self.assertIn("`$.foundations.spec`", trace)

    def test_second_run_changes_nothing_not_even_mtimes(self) -> None:
        self.run_split(sample())
        files = snapshot(self.out)
        mtimes = {p: p.stat().st_mtime_ns for p in self.out.rglob("*") if p.is_file()}
        self.assertEqual(self.run_split(sample())[0], 0)
        self.assertEqual(snapshot(self.out), files)
        self.assertEqual({p: p.stat().st_mtime_ns for p in self.out.rglob("*") if p.is_file()}, mtimes)

    def test_widget_dropped_from_json_removes_only_its_file(self) -> None:
        self.run_split(sample())
        stray = self.out / "notes.md"
        stray.write_text("mine", encoding="utf-8")
        self.assertEqual(self.run_split(sample(("StatusBar",)))[0], 0)
        self.assertFalse((self.out / "widgets/icon-tile.md").exists())
        self.assertTrue((self.out / "widgets/status-bar.md").exists())
        self.assertTrue(stray.exists())

    def test_regenerating_after_a_json_change_rewrites_untouched_files(self) -> None:
        self.run_split(sample())
        changed = sample()
        changed["themeHandoff"]["spec"] = "# Theme v2\n"
        self.assertEqual(self.run_split(changed)[0], 0)
        body = split_marker((self.out / "02-theme-binding.md").read_bytes())[1]
        self.assertEqual(body, b"# Theme v2\n")

    def test_hand_edited_file_blocks_the_whole_run(self) -> None:
        self.run_split(sample())
        edited = self.out / "widgets/status-bar.md"
        edited.write_bytes(edited.read_bytes() + b"hand edit\n")
        before = snapshot(self.out)
        changed = sample()
        changed["themeHandoff"]["spec"] = "# Theme v2\n"
        code, output = self.run_split(changed)
        self.assertEqual(code, 1)
        self.assertIn("widgets/status-bar.md", output)
        self.assertEqual(snapshot(self.out), before)  # not even the theme file moved

    def test_file_the_split_did_not_write_is_never_overwritten(self) -> None:
        foreign = self.out / "widgets/status-bar.md"
        foreign.parent.mkdir(parents=True)
        foreign.write_text("mine", encoding="utf-8")
        code, output = self.run_split(sample())
        self.assertEqual(code, 1)
        self.assertIn("widgets/status-bar.md", output)
        self.assertEqual(snapshot(self.out), {"widgets/status-bar.md": b"mine"})

    def test_manifest_without_hashes_protects_every_existing_file(self) -> None:
        # The previous version of the script recorded a plain list of paths and
        # wrote specs without a marker; its files may carry hand edits.
        old = self.out / "widgets/status-bar.md"
        old.parent.mkdir(parents=True)
        old.write_text(STATUS_BAR, encoding="utf-8")
        manifest = self.out / ".handoff-split-manifest.json"
        manifest.write_text(json.dumps(["widgets/status-bar.md"]), encoding="utf-8")
        code, output = self.run_split(sample())
        self.assertEqual(code, 1)
        self.assertIn("widgets/status-bar.md", output)
        self.assertEqual(old.read_text(encoding="utf-8"), STATUS_BAR)

    def test_hand_edited_file_the_json_no_longer_produces_is_kept(self) -> None:
        self.run_split(sample())
        edited = self.out / "widgets/icon-tile.md"
        edited.write_text("hand edit", encoding="utf-8")
        code, output = self.run_split(sample(("StatusBar",)))
        self.assertEqual(code, 1)
        self.assertIn("widgets/icon-tile.md", output)
        self.assertEqual(edited.read_text(encoding="utf-8"), "hand edit")

    def test_widget_names_mapping_to_one_file_fail_before_writing(self) -> None:
        bad = sample()
        bad["widgets"][1]["name"] = "status_bar"  # same kebab name as StatusBar
        code, output = self.run_split(bad)
        self.assertEqual(code, 2)
        self.assertIn("widgets/status-bar.md", output)
        self.assertFalse(self.out.exists())

    def test_missing_spec_fails_before_writing(self) -> None:
        bad = sample()
        del bad["foundations"]["spec"]
        code, output = self.run_split(bad)
        self.assertEqual(code, 2)
        self.assertIn("$.foundations.spec", output)
        self.assertFalse(self.out.exists())

    def test_json_of_the_wrong_shape_fails_before_writing(self) -> None:
        # (JSON, text that must locate the problem in the error)
        cases = {
            "top-level value is not an object": ([], "top-level"),
            "widgets is not a list": ({**sample(), "widgets": {}}, "$.widgets"),
            "a widget is not an object": ({**sample(), "widgets": ["StatusBar"]}, "$.widgets[0]"),
            "a widget name is not a string": (
                {**sample(), "widgets": [{"name": 7, "spec": "# x"}]}, "$.widgets[0].name"),
            "a widget name gives no file name": (
                {**sample(), "widgets": [{"name": "!!!", "spec": "# x"}]}, "'!!!'"),
        }
        for i, (label, (data, where)) in enumerate(cases.items()):
            with self.subTest(label):
                self.out = self.tmp / f"out-{i}"  # a failing case must not leak into the next
                code, output = self.run_split(data)
                self.assertEqual(code, 2)
                self.assertIn(where, output)
                self.assertFalse(self.out.exists())

    def test_missing_json_file_fails_before_writing(self) -> None:
        code, output = self.run_main(self.tmp / "absent.json")
        self.assertEqual(code, 2)
        self.assertIn("absent.json", output)
        self.assertFalse(self.out.exists())

    def test_unparsable_json_fails_naming_the_file(self) -> None:
        src = self.tmp / "in.json"
        src.write_text("{not json", encoding="utf-8")
        code, output = self.run_main(src)
        self.assertEqual(code, 2)
        self.assertIn("in.json", output)
        self.assertFalse(self.out.exists())

    def test_kebab_file_names(self) -> None:
        names = ("StatusBar", "Fab", "ActionSheetCommandRow", "HTMLParser")
        self.assertEqual(
            [sh.kebab(n) for n in names],
            ["status-bar", "fab", "action-sheet-command-row", "html-parser"],
        )


class FindDriftTest(unittest.TestCase):
    """find_drift compares an output dir with what the JSON would produce, writing nothing."""

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.src = Path(tmp.name) / "in.json"
        self.src.write_text(json.dumps(sample()), encoding="utf-8")
        self.out = Path(tmp.name) / "out"
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(sh.main([str(self.src), str(self.out)]), 0)

    def drift(self) -> list[tuple[str, str]]:
        return sh.find_drift(self.out, sh.load_files(self.src))

    def test_no_drift_right_after_a_run(self) -> None:
        self.assertEqual(self.drift(), [])

    def test_hand_edited_file_is_changed(self) -> None:
        edited = self.out / "widgets/status-bar.md"
        edited.write_bytes(edited.read_bytes() + b"hand edit\n")
        self.assertEqual(self.drift(), [("widgets/status-bar.md", "changed")])

    def test_deleted_file_is_missing(self) -> None:
        (self.out / "widgets/icon-tile.md").unlink()
        self.assertEqual(self.drift(), [("widgets/icon-tile.md", "missing")])

    def test_deleted_manifest_is_missing(self) -> None:
        (self.out / ".handoff-split-manifest.json").unlink()
        self.assertEqual(self.drift(), [(".handoff-split-manifest.json", "missing")])

    def test_file_the_json_does_not_produce_is_extra(self) -> None:
        (self.out / "notes.md").write_text("mine", encoding="utf-8")
        self.assertEqual(self.drift(), [("notes.md", "extra")])


TOOLS = Path(__file__).resolve().parent


class RepositoryIntegrationTest(unittest.TestCase):
    """The CLI defaults and the docs gate, run from the root of a throwaway repository."""

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.repo = Path(tmp.name)
        ui = self.repo / "docs/shared/ui"
        ui.mkdir(parents=True)
        (ui / "design-handoff.json").write_text(json.dumps(sample()), encoding="utf-8")
        self.handoff = ui / "design-handoff"

    def run_tool(self, script: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, str(TOOLS / script)],
            cwd=self.repo, capture_output=True, text=True, encoding="utf-8",
        )

    def test_default_run_splits_the_json_into_the_folder_next_to_it(self) -> None:
        result = self.run_tool("split_handoff.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        body = split_marker((self.handoff / "widgets/status-bar.md").read_bytes())[1]
        self.assertEqual(body, STATUS_BAR.encode("utf-8"))

    def test_docs_check_passes_on_a_fresh_split(self) -> None:
        self.run_tool("split_handoff.py")
        self.run_tool("generate.py")
        result = self.run_tool("check.py")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_docs_check_fails_on_a_hand_edited_handoff_file(self) -> None:
        self.run_tool("split_handoff.py")
        self.run_tool("generate.py")
        edited = self.handoff / "widgets/status-bar.md"
        edited.write_bytes(edited.read_bytes() + b"hand edit\n")
        result = self.run_tool("check.py")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("docs/shared/ui/design-handoff/widgets/status-bar.md", result.stdout)

    def test_docs_check_fails_when_the_json_was_never_split(self) -> None:
        self.run_tool("generate.py")
        result = self.run_tool("check.py")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("docs/shared/ui/design-handoff/00-index.md", result.stdout)

    def test_docs_check_fails_when_the_split_outlives_its_json(self) -> None:
        self.run_tool("split_handoff.py")
        (self.repo / "docs/shared/ui/design-handoff.json").unlink()
        self.run_tool("generate.py")
        result = self.run_tool("check.py")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("docs/shared/ui/design-handoff.json", result.stdout)

    def test_docs_check_passes_on_a_repository_without_a_handoff(self) -> None:
        (self.repo / "docs/shared/ui/design-handoff.json").unlink()
        self.run_tool("generate.py")
        result = self.run_tool("check.py")
        self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main()
