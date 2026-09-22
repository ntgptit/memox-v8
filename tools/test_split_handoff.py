"""Runnable check for split_handoff.py:  python tools/test_split_handoff.py"""
import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import split_handoff as sh  # noqa: E402

FOUNDATIONS = "/x\n\n# Foundations — Việt ✓\r\n  trailing spaces   \nno final newline"
THEME = "# Theme\n"
STATUS_BAR = "# StatusBar\n\n| pipe | stays |\n"
ICON_TILE = "# IconTile"


def sample(widgets=("StatusBar", "IconTile")):
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


def run(tmp: Path, data) -> tuple[int, str]:
    src = tmp / "in.json"
    src.write_text(json.dumps(data), encoding="utf-8")
    code = sh.main([str(src), str(tmp / "out")])
    return code, ""


def snapshot(out: Path) -> dict:
    return {p.relative_to(out).as_posix(): p.read_bytes() for p in out.rglob("*") if p.is_file()}


with tempfile.TemporaryDirectory() as t:
    tmp = Path(t)
    out = tmp / "out"

    assert run(tmp, sample())[0] == 0
    files = snapshot(out)

    # spec content is written byte-for-byte (CRLF, no final newline, unicode, pipes)
    assert files["01-foundations.md"] == FOUNDATIONS.encode("utf-8")
    assert files["02-theme-binding.md"] == THEME.encode("utf-8")
    assert files["widgets/status-bar.md"] == STATUS_BAR.encode("utf-8")
    assert files["widgets/icon-tile.md"] == ICON_TILE.encode("utf-8")
    assert {"00-index.md", "99-traceability.md"} <= files.keys()

    index = files["00-index.md"].decode("utf-8")
    assert "glyph → Icon \\| x" in index and "widgets/icon-tile.md" in index
    trace = files["99-traceability.md"].decode("utf-8")
    assert "`$.widgets[1].spec`" in trace and "`$.foundations.spec`" in trace

    # idempotent: a second run changes nothing, not even mtimes
    mtimes = {p: p.stat().st_mtime_ns for p in out.rglob("*") if p.is_file()}
    assert run(tmp, sample())[0] == 0
    assert snapshot(out) == files
    assert mtimes == {p: p.stat().st_mtime_ns for p in out.rglob("*") if p.is_file()}

    # regenerated JSON without a widget: its file (and only its file) goes away
    stray = out / "notes.md"
    stray.write_text("mine", encoding="utf-8")
    assert run(tmp, sample(("StatusBar",)))[0] == 0
    assert not (out / "widgets/icon-tile.md").exists()
    assert (out / "widgets/status-bar.md").exists() and stray.exists()

    # bad input fails fast and writes nothing new
    bad = sample()
    bad["widgets"][1]["name"] = "status_bar"  # same kebab name as StatusBar
    assert run(tmp, bad)[0] == 2
    bad = sample()
    del bad["foundations"]["spec"]
    assert run(tmp, bad)[0] == 2

assert [sh.kebab(n) for n in ("StatusBar", "Fab", "ActionSheetCommandRow", "HTMLParser")] == [
    "status-bar", "fab", "action-sheet-command-row", "html-parser",
]
print("ok")
