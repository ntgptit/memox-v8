"""flutter-project-setup's dependency table is pubspec.yaml as it stands.

`references/dependencies.md` says a package added to `pubspec.yaml` gets a row
there in the same commit. Unchecked, that was a wish: the first API call added
`dio`, `retrofit` and `json_annotation`, and the table went on calling them
absent. A struck-through row (`~~name~~`) is a package the table says not to
add, and the "Add only when" table lists packages the project does not have yet.
"""
from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[5]
PUBSPEC = REPO_ROOT / "pubspec.yaml"
TABLE = (
    REPO_ROOT / ".claude" / "skills" / "flutter-project-setup" / "references" / "dependencies.md"
)

# The SDK itself, which no row explains.
SDK_ENTRIES = {"flutter", "flutter_test"}

# The header row of each kind of table in dependencies.md.
PRESENT_HEADERS = {"| Package | Line | Why it is here |", "| Package | Why |"}
FUTURE_HEADER = "| Package | Add when |"


def _declared(pubspec: str) -> set[str]:
    """The packages under `dependencies:` and `dev_dependencies:`."""
    names: set[str] = set()
    section = None
    for line in pubspec.splitlines():
        header = re.match(r"^(\w+):\s*$", line)
        if header:
            section = header.group(1)
            continue
        entry = re.match(r"^  ([a-z0-9_]+):", line)
        if entry and section in {"dependencies", "dev_dependencies"}:
            names.add(entry.group(1))
    return names - SDK_ENTRIES


def _rows(table: str, headers: set[str]) -> set[str]:
    """The packages named in the first column of the tables with these headers,
    struck-through rows left out."""
    names: set[str] = set()
    inside = False
    for line in table.splitlines():
        if not line.startswith("|"):
            inside = False
            continue
        if line.strip() in headers:
            inside = True
            continue
        if not inside or line.startswith("|---"):
            continue
        first = line.split("|")[1]
        if "~~" in first:
            continue
        names.update(re.findall(r"`([a-z0-9_]+)`", first))
    return names


class ParserTest(unittest.TestCase):
    def test_the_tables_and_the_pubspec_are_read_as_written(self):
        pubspec = (
            "name: app\n"
            "dependencies:\n"
            "  dio: ^5.0.0\n"
            "  flutter:\n"
            "    sdk: flutter\n"
            "dev_dependencies:\n"
            "  build_runner: ^2.0.0\n"
            "flutter:\n"
            "  generate: true\n"
        )
        table = (
            "| Package | Line | Why it is here |\n"
            "|---|---|---|\n"
            "| `dio` | 5.x | The client. |\n"
            "| ~~`legacy`~~ | — | Do not add it. |\n"
            "\n"
            "| Package | Add when |\n"
            "|---|---|\n"
            "| `sentry_flutter` / `firebase_crashlytics` | Release. |\n"
            "\n"
            "| Package | Why |\n"
            "|---|---|\n"
            "| `build_runner` | Runs all generators. |\n"
        )

        self.assertEqual(_declared(pubspec), {"dio", "build_runner"})
        self.assertEqual(_rows(table, PRESENT_HEADERS), {"dio", "build_runner"})
        self.assertEqual(_rows(table, {FUTURE_HEADER}), {"sentry_flutter", "firebase_crashlytics"})


class DependencyTableTest(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        self.declared = _declared(PUBSPEC.read_text(encoding="utf-8"))
        table = TABLE.read_text(encoding="utf-8")
        self.present = _rows(table, PRESENT_HEADERS)
        self.future = _rows(table, {FUTURE_HEADER})

    def test_every_package_in_pubspec_has_a_row(self):
        self.assertEqual(sorted(self.declared - self.present), [])

    def test_every_row_names_a_package_in_pubspec(self):
        self.assertEqual(sorted(self.present - self.declared), [])

    def test_no_package_waits_for_a_need_it_already_has(self):
        self.assertEqual(sorted(self.future & self.declared), [])


if __name__ == "__main__":
    unittest.main()
