#!/usr/bin/env python3
"""Check docs/ against the structure described in docs/README.md.

    python tools/docs/check.py [--plan <mapping.md>]

Run from the repository root. Prints `LEVEL path: message`, one per line.
Exit code 1 when any ERROR is found; WARNINGs never fail.

ERROR
- frontmatter missing, unreadable, missing a required field, or bad `status`
- id format wrong, id not matching the file name / folder DOMAIN, id duplicated
- `rules` pointing to an unknown or deprecated BR; `superseded_by` unknown
- a `code` path or a feature README `depends_on` that does not exist
- a cycle in the feature `depends_on` graph (it must stay a DAG)
- a broken relative link; a BR/UC id or `invariant Qn` cited but not defined
- a UC / BR / feature README missing a required `##` section
- a BR carrying a hand-written "used by" section (it is generated)
- docs/_generated/ stale compared with a fresh `generate.py` run
- with --plan: a mapping row whose destination does not exist (a mapping
  table is one whose first header cell starts with "Nguồn"; destinations are
  backticked paths relative to docs/, `<slug>` and `*` are wildcards)
WARNING
- active BR used by no UC; ready UC with `code: []`; ready UC with no test

Id, invariant and link checks ignore ``` fences and `inline code`. Id checks
skip docs/superpowers/ (historical documents keep old ids) and _generated/;
links are checked everywhere. See generate.py for the frontmatter
limits.
"""
from __future__ import annotations

import argparse
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate as g  # noqa: E402

BR_ID = re.compile(r"^BR-[A-Z]+-\d{3}$")
UC_ID = re.compile(r"^UC-[A-Z]+-\d{3}$")
ADR_ID = re.compile(r"^ADR-\d{3}$")
SLUG = r"[a-z0-9]+(?:-[a-z0-9]+)*"
ID_IN_TEXT = re.compile(r"\b((?:BR|UC)-[A-Z]+-\d{3})\b")
INVARIANT_CITE = re.compile(r"\binvariant Q(\d+)\b")
INVARIANT_DEF = re.compile(r"^--\s*(\d+)\.", re.M)
# The one file that defines the numbered invariants cited as `invariant Qn`.
INVARIANT_FILE = "shared/data/schema.md"
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
USED_BY_SECTION = re.compile(r"^##+\s*(được dùng bởi|used by)\b", re.I | re.M)

STATUS = {
    "BR": {"draft", "active", "deprecated"},
    "UC": {"draft", "ready", "deprecated"},
    "ADR": {"draft", "active", "deprecated"},
}
REQUIRED_FIELDS = {
    "BR": ("id", "title", "status", "summary"),
    "UC": ("id", "title", "status", "rules", "code"),
    "ADR": ("id", "title", "status"),
    "FEATURE": ("feature", "code", "depends_on"),
}
LIST_FIELDS = {"rules", "code", "depends_on"}
REQUIRED_SECTIONS = {
    "BR": ("Rule", "Lý do", "Ví dụ", "Edge case"),
    "UC": (
        "Mục tiêu / Actor / Precondition",
        "Main flow",
        "Alternative / Error flow",
        "UI",
        "Local",
        "API",
        "Acceptance criteria",
    ),
    "FEATURE": ("Phạm vi", "Màn hình → Use case", "Không thuộc phạm vi"),
}
SKIP_ID_CHECK = ("superpowers", "_generated")


class Report:
    def __init__(self) -> None:
        self.lines: list[tuple[str, str, str]] = []

    def error(self, path: Path | str, message: str) -> None:
        self.lines.append(("ERROR", show(path), message))

    def warning(self, path: Path | str, message: str) -> None:
        self.lines.append(("WARNING", show(path), message))

    @property
    def errors(self) -> int:
        return sum(1 for level, _, _ in self.lines if level == "ERROR")

    def print(self) -> None:
        for level, path, message in self.lines:
            print(f"{level} {path}: {message}")
        warnings = len(self.lines) - self.errors
        print(f"{'FAIL' if self.errors else 'PASS'} — {self.errors} error(s), {warnings} warning(s)")


def show(path: Path | str) -> str:
    if isinstance(path, str):
        return path
    return path.relative_to(g.ROOT).as_posix() if path.is_relative_to(g.ROOT) else str(path)


# ------------------------------------------------------------ per document


def check_frontmatter(doc: g.Doc, report: Report) -> bool:
    """Report field problems; False only when the block itself is unusable."""
    if doc.frontmatter_error:
        report.error(doc.path, doc.frontmatter_error)
        return False
    for key in REQUIRED_FIELDS[doc.kind]:
        value = doc.meta.get(key)
        if key in LIST_FIELDS and not isinstance(value, list):
            report.error(doc.path, f"`{key}` phải là list inline `[...]`")
        elif key not in LIST_FIELDS and not value:
            report.error(doc.path, f"thiếu trường bắt buộc `{key}`")
    allowed = STATUS.get(doc.kind)
    if allowed and doc.status and doc.status not in allowed:
        report.error(doc.path, f"`status: {doc.status}` không thuộc {sorted(allowed)}")
    return True


def check_identity(doc: g.Doc, report: Report) -> None:
    pattern = {"BR": BR_ID, "UC": UC_ID, "ADR": ADR_ID}[doc.kind]
    if not doc.id:
        return
    if not pattern.match(doc.id):
        report.error(doc.path, f"id `{doc.id}` sai format")
        return
    if not re.fullmatch(re.escape(doc.id) + "-" + SLUG + r"\.md", doc.path.name):
        report.error(doc.path, f"tên file phải là `{doc.id}-<slug-kebab-case>.md`")
    if doc.kind == "ADR":
        return
    expected = g.domain_of(doc.feature)
    actual = doc.id.split("-")[1]
    if actual != expected:
        report.error(doc.path, f"id `{doc.id}` có DOMAIN `{actual}`, thư mục này yêu cầu `{expected}`")


def check_sections(doc: g.Doc, report: Report) -> None:
    for name in REQUIRED_SECTIONS.get(doc.kind, ()):
        if name not in doc.sections:
            report.error(doc.path, f"thiếu section `## {name}`")
    if doc.kind == "BR" and USED_BY_SECTION.search(doc.body):
        report.error(doc.path, "BR không được có section \"Được dùng bởi\" — generate.py sinh nó")


def check_paths(doc: g.Doc, report: Report) -> None:
    for code_path in doc.as_list("code"):
        if not (g.ROOT / code_path).exists():
            report.error(doc.path, f"path trong `code` không tồn tại: `{code_path}`")


def check_feature_readme(doc: g.Doc, features: list[str], report: Report) -> None:
    if doc.meta.get("feature") != doc.feature:
        report.error(doc.path, f"`feature: {doc.meta.get('feature')}` phải trùng tên thư mục `{doc.feature}`")
    for dep in doc.as_list("depends_on"):
        if dep not in features:
            report.error(doc.path, f"`depends_on` trỏ tới feature không tồn tại: `{dep}`")


# ------------------------------------------------------------ cross checks


def check_dependency_cycles(docs: list[g.Doc], report: Report) -> None:
    """`depends_on` must stay a DAG — see docs/README.md."""
    graph = {doc.feature: doc.as_list("depends_on") for doc in docs if doc.kind == "FEATURE"}
    readme = {doc.feature: doc for doc in docs if doc.kind == "FEATURE"}
    state: dict[str, str] = {}

    def visit(feature: str, path: list[str]) -> None:
        if state.get(feature) == "done":
            return
        if state.get(feature) == "open":
            cycle = path[path.index(feature):] + [feature]
            report.error(readme[feature].path, f"`depends_on` có chu trình: {' → '.join(cycle)}")
            return
        state[feature] = "open"
        for dep in graph.get(feature, []):
            if dep in graph:
                visit(dep, path + [feature])
        state[feature] = "done"

    for feature in sorted(graph):
        visit(feature, [])


def check_duplicates(docs: list[g.Doc], report: Report) -> dict[str, g.Doc]:
    by_id: dict[str, g.Doc] = {}
    for doc in docs:
        if doc.kind == "FEATURE" or not doc.id:
            continue
        if doc.id in by_id:
            report.error(doc.path, f"id `{doc.id}` trùng với {show(by_id[doc.id].path)}")
            continue
        by_id[doc.id] = doc
    return by_id


def check_references(docs: list[g.Doc], by_id: dict[str, g.Doc], report: Report) -> None:
    for doc in docs:
        for rule_id in doc.as_list("rules") if doc.kind == "UC" else []:
            target = by_id.get(rule_id)
            if target is None or target.kind != "BR":
                report.error(doc.path, f"`rules` trỏ tới BR không tồn tại: `{rule_id}`")
            elif target.status == "deprecated":
                report.error(doc.path, f"`rules` trỏ tới BR deprecated: `{rule_id}`")
        superseded_by = str(doc.meta.get("superseded_by") or "")
        if not superseded_by:
            continue
        if superseded_by not in by_id:
            report.error(doc.path, f"`superseded_by` trỏ tới id không tồn tại: `{superseded_by}`")
        if doc.status != "deprecated":
            report.error(doc.path, "`superseded_by` chỉ dùng khi `status: deprecated`")


def check_warnings(docs: list[g.Doc], report: Report) -> None:
    usage = g.used_by(docs)
    ready = [d for d in docs if d.kind == "UC" and d.status == "ready"]
    tests = g.tests_by_id([d.id for d in ready])
    for doc in docs:
        if doc.kind == "BR" and doc.status == "active" and doc.id not in usage:
            report.warning(doc.path, "BR active không được UC nào dùng")
    for doc in ready:
        if not doc.as_list("code"):
            report.warning(doc.path, "UC ready có `code: []`")
        if not tests[doc.id]:
            report.warning(doc.path, "UC ready chưa có test chứa ID")


def defined_ids(docs: list[g.Doc]) -> set[str]:
    return {d.id for d in docs if d.kind in ("BR", "UC")}


def defined_invariants() -> set[int] | None:
    path = g.DOCS / INVARIANT_FILE
    if not path.exists():
        return None
    return {int(n) for n in INVARIANT_DEF.findall(path.read_text(encoding="utf-8"))}


def markdown_files() -> list[Path]:
    return sorted(g.DOCS.rglob("*.md"))


def is_skipped_for_ids(path: Path) -> bool:
    return path.relative_to(g.DOCS).parts[0] in SKIP_ID_CHECK


def check_text(docs: list[g.Doc], report: Report) -> None:
    ids = defined_ids(docs)
    invariants = defined_invariants()
    for path in markdown_files():
        check_ids = not is_skipped_for_ids(path)
        text = path.read_text(encoding="utf-8")
        body_start = frontmatter_end(text)
        for line_no, raw in g.iter_unfenced(text):
            where = f"{show(path)}:{line_no}"
            # `inline code` holds examples and markers, not citations or links.
            line = g.INLINE_CODE.sub("", raw)
            check_links(path, line, where, report)
            # Frontmatter ids are checked as fields (`rules`, `superseded_by`).
            if not check_ids or line_no <= body_start:
                continue
            for cited in sorted(set(ID_IN_TEXT.findall(line)) - ids):
                report.error(where, f"`{cited}` được trích nhưng không được định nghĩa")
            for n in INVARIANT_CITE.findall(line):
                if invariants is not None and int(n) not in invariants:
                    report.error(where, f"`invariant Q{n}` được trích nhưng không có `-- {n}.`")


def frontmatter_end(text: str) -> int:
    """Line number of the closing `---`, or 0 when there is no frontmatter."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return 0
    return next((i + 1 for i in range(1, len(lines)) if lines[i].strip() == "---"), 0)


def check_links(path: Path, line: str, where: str, report: Report) -> None:
    for target in LINK.findall(line):
        if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I) or target.startswith("#"):
            continue
        file_part = target.split("#", 1)[0]
        if not file_part:
            continue
        if not (path.parent / file_part).exists():
            report.error(where, f"link hỏng: `{target}`")


def check_generated(report: Report) -> None:
    """Run generate.py into a temp dir and compare byte-for-byte with docs/_generated/."""
    with tempfile.TemporaryDirectory() as tmp:
        g.write_all(Path(tmp))
        for path in sorted(Path(tmp).iterdir()):
            current = g.GENERATED / path.name
            if not current.exists():
                report.error(current, "chưa được sinh — chạy `python tools/docs/generate.py`")
            elif current.read_bytes() != path.read_bytes():
                report.error(current, "lỗi thời — chạy `python tools/docs/generate.py`")
        if g.GENERATED.is_dir():
            expected = {p.name for p in Path(tmp).iterdir()}
            for extra in sorted(p.name for p in g.GENERATED.iterdir() if p.name not in expected):
                report.error(g.GENERATED / extra, "file không do generate.py sinh")


# ------------------------------------------------------------ plan mapping

PLAN_HEADER = re.compile(r"^\|\s*Nguồn\b")
PLAN_PATH = re.compile(r"`([^`]+?(?:\.md|/))`")


def plan_destinations(plan: Path) -> list[str]:
    """Destination cells of every mapping table: a table whose first header
    cell starts with "Nguồn". Paths are backticked, relative to docs/."""
    destinations: list[str] = []
    in_mapping = False
    for line in plan.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            in_mapping = False
            continue
        if PLAN_HEADER.match(line):
            in_mapping = True
            continue
        cells = line.split("|")
        if not in_mapping or len(cells) < 4 or set(cells[1].strip()) <= set("-: "):
            continue
        destinations += PLAN_PATH.findall(cells[2])
    return destinations


def check_plan(plan: Path, report: Report) -> None:
    if not plan.exists():
        report.error(plan, "không tìm thấy file plan")
        return
    missing: dict[str, int] = {}
    for dest in plan_destinations(plan):
        if not destination_exists(dest):
            missing[dest] = missing.get(dest, 0) + 1
    for dest, rows in sorted(missing.items()):
        report.error(plan, f"đích chưa tồn tại ({rows} dòng): `{dest}`")


def destination_exists(dest: str) -> bool:
    pattern = dest.replace("<slug>", "*")
    if "*" in pattern:
        return any(g.DOCS.glob(pattern.rstrip("/")))
    return (g.DOCS / pattern).exists()


# ------------------------------------------------------------------- main


def run(plan: Path | None) -> Report:
    report = Report()
    docs = g.load_docs()
    features = g.feature_names()
    for feature in features:
        if not (g.DOCS / "features" / feature / "README.md").exists():
            report.error(g.DOCS / "features" / feature, "feature thiếu README.md")
    for doc in docs:
        if not check_frontmatter(doc, report):
            continue
        if doc.kind == "FEATURE":
            check_feature_readme(doc, features, report)
        else:
            check_identity(doc, report)
        check_sections(doc, report)
        check_paths(doc, report)
    check_dependency_cycles(docs, report)
    by_id = check_duplicates(docs, report)
    check_references(docs, by_id, report)
    check_text(docs, report)
    check_generated(report)
    if plan is not None:
        check_plan(plan, report)
    check_warnings(docs, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--plan", type=Path, help="file markdown chứa bảng ánh xạ (cột đầu \"Nguồn\")")
    args = parser.parse_args()
    if not g.DOCS.is_dir():
        print("ERROR docs: không tìm thấy — chạy từ root repo")
        return 1
    report = run(args.plan)
    report.print()
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
