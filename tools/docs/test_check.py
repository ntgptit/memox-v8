"""Tests for check.py's V7 residue check:  python tools/docs/test_check.py"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check  # noqa: E402


def tree(files: dict[str, bytes | str]) -> Path:
    root = Path(tempfile.mkdtemp())
    for name, content in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding="utf-8")
    return root


class V7ResidueTest(unittest.TestCase):
    def test_every_marker_in_every_text_file_is_reported(self):
        root = tree({
            ".claude/skills/a/SKILL.md": "ok\nsee the Widgetbook catalog\n",
            ".claude/skills/a/x.yaml": "# see docs/wbs.md\n",
            ".claude/skills/a/x.sh": "# memox-v7 did this\n",
            ".claude/skills/a/x.py": "# docs/checklist.md\n",
            "docs/shared/x.md": "Covers checklist phases 4 and 5\n",
        })
        hits = {(p.relative_to(root).as_posix(), line) for p, line, _ in check.v7_residue(root)}
        self.assertEqual(hits, {
            (".claude/skills/a/SKILL.md", 2),
            (".claude/skills/a/x.yaml", 1),
            (".claude/skills/a/x.sh", 1),
            (".claude/skills/a/x.py", 1),
            ("docs/shared/x.md", 1),
        })

    def test_a_bare_ledger_name_is_a_marker(self):
        root = tree({
            ".claude/skills/a/x.py": "# recorded in wbs.md M-task outputs\n",
            "docs/a.md": "see [wbs](../wbs.md)\nprogress in wbs_BE.md and wbs_FE.md\n",
        })
        hits = {(p.relative_to(root).as_posix(), line) for p, line, _ in check.v7_residue(root)}
        self.assertEqual(hits, {(".claude/skills/a/x.py", 1), ("docs/a.md", 1)})

    def test_case_does_not_hide_a_marker(self):
        root = tree({"docs/a.md": "WIDGETBOOK\nMemoX-V7\n"})
        self.assertEqual(len(check.v7_residue(root)), 2)

    def test_binary_and_cache_files_are_skipped(self):
        root = tree({
            ".claude/skills/a/__pycache__/t.cpython-311.pyc": b"\x00widgetbook\xff",
            ".claude/skills/a/logo.png": b"\x89PNG widgetbook",
        })
        self.assertEqual(check.v7_residue(root), [])

    def test_historical_records_are_excluded_by_path(self):
        files = {name: "widgetbook\n" for name in check.V7_HISTORY}
        files["docs/wbs_FE.md"] = "widgetbook\n"
        root = tree({(n if "." in Path(n).name else f"{n}/x.md"): c for n, c in files.items()})
        hits = [p.relative_to(root).as_posix() for p, _, _ in check.v7_residue(root)]
        self.assertEqual(hits, ["docs/wbs_FE.md"])

    def test_a_new_spec_or_plan_is_scanned(self):
        root = tree({
            "docs/superpowers/specs/2099-01-01-new-design.md": "add a Widgetbook use-case\n",
            "docs/superpowers/plans/2099-01-01-new.md": "update docs/wbs.md\n",
        })
        self.assertEqual(len(check.v7_residue(root)), 2)

    def test_every_exclusion_is_one_file(self):
        root = Path(__file__).resolve().parents[2]
        for path in check.V7_HISTORY:
            self.assertTrue((root / path).is_file(), path)

    def test_every_exclusion_gives_a_reason(self):
        for path, reason in check.V7_HISTORY.items():
            self.assertTrue(reason.strip(), path)

    def test_the_repository_is_clean(self):
        hits = check.v7_residue(Path(__file__).resolve().parents[2])
        self.assertEqual(hits, [], "\n".join(f"{p}:{n}: {m}" for p, n, m in hits))


if __name__ == "__main__":
    unittest.main()
