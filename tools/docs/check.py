#!/usr/bin/env python3
"""Check docs/ against the structure described in docs/README.md.

    python tools/docs/check.py [--plan <mapping.md>] [--ledger <ledger.md>]

Run from the repository root. Prints `LEVEL path: message`, one per line.
Exit code 1 when any ERROR is found; WARNINGs never fail.

ERROR
- frontmatter missing, unreadable, missing a required field, or bad `status`
- id format wrong, id not matching the file name / folder DOMAIN, id duplicated
- `rules` pointing to an unknown or deprecated BR; `superseded_by` unknown
- a `code` path or a feature README `depends_on` that does not exist
- a cycle in the feature `depends_on` graph (it must stay a DAG)
- an ADR `superseded` without `superseded_by`, or `supersedes`/`superseded_by`
  that do not point at each other; ADR status is draft | accepted | superseded |
  deprecated. Links in a superseded or deprecated ADR are not checked
- a PRODUCT.md anywhere under docs/ (the product lives in /PRODUCT.md)
- a screen without a catalog row, or a catalog row that disagrees with the
  screen's frontmatter (name, domain, route, status)
- a state heading or `Golden:` line that is malformed; a state key used twice
  or renamed since the merge base (keys are permanent; a removed state keeps
  its heading with `Status: removed`)
- a `built` screen missing a golden its states declare; once any
  `scr_*` golden exists, a golden that matches no declared state
- a broken relative link; a BR/UC id or `invariant Qn` cited but not defined
- a UC / BR / feature README missing a required `##` section
- a hand-written reverse relation (`Used by`, `Invoked by`, `Related Screens`,
  `Related BR`, `Entry points`, `Functional capabilities`) in a BR, feature
  README, UC, FN or screen spec — generate.py writes those
- an id kind a new-layout document may not cite (USE_CASES.md: FN;
  functional-spec/: BR; screens/spec/: FN, UC, SCR, INV-UI; the catalog: SCR,
  INV-UI; NAVIGATION.md: SCR, UC); OPEN QUESTION lines are exempt. In these
  documents an id in `inline code` still counts
- docs/_generated/ stale compared with a fresh `generate.py` run
- a UC section of docs/USE_CASES.md or an FN section of docs/functional-spec/
  with a malformed heading or meta line, a bad field, or a missing `####`/`###`
  sub-section; an FN in a file whose name is not its feature
- a screen spec with a bad frontmatter, a missing `##` section, or a domain
  that is not a feature folder
- `invokes`, an FN's `### Business rules`, or a screen's `Invokes:`,
  `Navigate to:` or `## Related Use Cases` naming an id that does not exist
  or is deprecated; an FN cited in a UC flow but missing from its `Invokes:`
- a file in a retired home: features/*/usecases/, features/*/ui.md, shared/ui/
- a legacy-named golden, or a file under lib/app/gallery/ or test/visual_audit/ (SP2)
- with --plan: a mapping row whose destination does not exist (a mapping
  table is one whose first header cell starts with "Nguồn"; destinations are
  backticked paths relative to docs/, `<slug>` and `*` are wildcards)
- with --ledger: a row without a valid outcome, a moved row whose destination
  does not exist, or an OPEN QUESTION left in the new-layout documents
WARNING
- active BR cited by no FN; active FN invoked by no UC and no screen; ready
  UC with no code (it and its FNs) or with no test
- an INV-UI enforced by nothing; a built screen's state with no golden

Id, invariant and link checks ignore ``` fences and `inline code`. Id checks
skip docs/superpowers/ (historical documents keep old ids) and _generated/;
links are checked everywhere except docs/superpowers/. See generate.py for the frontmatter
limits.
"""
from __future__ import annotations

import argparse
import functools
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate as g  # noqa: E402
import specdocs  # noqa: E402
import ledger  # noqa: E402

BR_ID = re.compile(r"^BR-[A-Z]+-\d{3}$")
UC_ID = re.compile(r"^UC-[A-Z]+-\d{3}$")
ADR_ID = re.compile(r"^ADR-\d{3}$")
SLUG = r"[a-z0-9]+(?:-[a-z0-9]+)*"
INVARIANT_CITE = re.compile(r"\binvariant Q(\d+)\b")
INVARIANT_DEF = re.compile(r"^--\s*(\d+)\.", re.M)
# The one file that defines the numbered invariants cited as `invariant Qn`.
INVARIANT_FILE = "shared/data/schema.md"
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")

FN_ID = re.compile(r"^FN-[A-Z]+-\d{3}$")
SCR_ID = re.compile(r"^SCR-[A-Z]+-\d{3}$")
ID_PATTERNS = {"BR": BR_ID, "UC": UC_ID, "ADR": ADR_ID, "FN": FN_ID, "SCR": SCR_ID}

# Keyed by schema(doc): "UCS" is a UC section of docs/USE_CASES.md.
STATUS = {
    "BR": {"draft", "active", "deprecated"},
    "UCS": {"draft", "ready", "deprecated"},
    "FN": {"draft", "active", "deprecated"},
    "SCR": {"draft", "ready", "built"},
    "ADR": {"draft", "accepted", "superseded", "deprecated"},
}
REQUIRED_FIELDS = {
    "BR": ("id", "title", "status", "summary"),
    "UCS": ("id", "title", "status", "code", "invokes"),
    "FN": ("id", "title", "status", "code"),
    "SCR": ("id", "name", "status", "domain", "route"),
    "ADR": ("id", "title", "status"),
    "FEATURE": ("feature", "code", "depends_on"),
}
LIST_FIELDS = {"rules", "code", "depends_on", "invokes", "route", "supersedes"}
REQUIRED_SECTIONS = {
    "BR": ("Rule", "Lý do", "Ví dụ", "Edge case"),
    "UCS": ("Mục tiêu / Actor / Precondition", "Main flow", "Alternative / Error flow", "Acceptance criteria"),
    "FN": ("Precondition", "Input", "Kết quả", "Lỗi", "Business rules"),
    "SCR": (
        "Purpose",
        "Related Use Cases",
        "Layout",
        "States",
        "Controls",
        "Responsive Behavior",
        "Accessibility",
        "UI Invariants",
        "Copy",
        "Rulings",
    ),
    "FEATURE": ("Phạm vi", "Không thuộc phạm vi"),
}
SECTION_MARK = {"UCS": "####", "FN": "###"}
# (field, kind of the ID it must name) per schema.
REFERENCE_FIELDS = {"UCS": (("invokes", "FN"),), "FN": (("rules", "BR"),)}
SKIP_ID_CHECK = ("superpowers", "_generated")
# Historical plans and specs keep links to files later retired (ADR-019/ADR-021); they are
# records, not maintained docs, so their links are not checked.
SKIP_LINK_CHECK = ("superpowers",)
# Which ID kinds each new-layout document may cite (spec §4.8, R13); other docs: any kind.
CITE_RULES: tuple[tuple[str, set[str]], ...] = (
    ("USE_CASES.md", {"FN"}),
    # An FN may cite another FN as a contract prerequisite, never as a call graph
    # (owner checkpoint 2026-10-04).
    ("functional-spec/", {"BR", "FN"}),
    ("screens/spec/", {"FN", "UC", "SCR", "INV"}),
    ("screens/SCREEN_CATALOG.md", {"SCR", "INV"}),
    ("NAVIGATION.md", {"SCR", "UC"}),
)
# A UC or FN heading defines its id; it does not cite it.
DEFINITION_LINE = re.compile(r"^#{2,3} (?:UC|FN)-[A-Z]+-\d{3} — ")
REVERSE_HEADING = re.compile(
    r"^#{2,6}\s*(được dùng bởi|used by|invoked by|related screens|related br|"
    r"related business rules|entry points|functional capabilities)\b",
    re.I,
)
PENDING = "pending"
REVERSE_CHECKED = {"BR", "FEATURE", "UCS", "FN", "SCR"}


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


def schema(doc: g.Doc) -> str:
    return "UCS" if doc.kind == "UC" else doc.kind


def where(doc: g.Doc) -> Path | str:
    return f"{show(doc.path)}:{doc.line}" if doc.is_section else doc.path


def allowed_kinds(path: Path) -> set[str] | None:
    rel = path.relative_to(g.DOCS).as_posix()
    for prefix, kinds in CITE_RULES:
        if rel == prefix or (prefix.endswith("/") and rel.startswith(prefix)):
            return kinds
    return None


def pending_screens() -> set[str]:
    """Catalog rows with status `pending`: the screen has an id but no spec yet."""
    rows, _ = screen_catalog()
    return {row.id for row in rows if row.status == PENDING}


def screen_catalog() -> tuple[list[specdocs.CatalogScreen], list[specdocs.Invariant]]:
    path = g.screen_catalog_file()
    if not path.exists():
        return [], []
    text = path.read_text(encoding="utf-8")
    return specdocs.catalog_screens(text), specdocs.catalog_invariants(text)


# ------------------------------------------------------------ per document


def check_frontmatter(doc: g.Doc, report: Report) -> bool:
    """Report field problems; False only when the block itself is unusable."""
    if doc.frontmatter_error:
        report.error(where(doc), doc.frontmatter_error)
        return False
    for key in REQUIRED_FIELDS[schema(doc)]:
        value = doc.meta.get(key)
        if key in LIST_FIELDS and not isinstance(value, list):
            report.error(where(doc), f"`{key}` must be an inline list `[...]`")
        elif key not in LIST_FIELDS and not value:
            report.error(where(doc), f"missing required field `{key}`")
    allowed = STATUS.get(schema(doc))
    if allowed and doc.status and doc.status not in allowed:
        report.error(where(doc), f"`status: {doc.status}` is not one of {sorted(allowed)}")
    if "supersedes" in doc.meta and not isinstance(doc.meta["supersedes"], list):
        report.error(where(doc), "`supersedes` must be an inline list `[...]`")
    return True


def check_identity(doc: g.Doc, report: Report) -> None:
    if not doc.id:
        return
    if not ID_PATTERNS[doc.kind].match(doc.id):
        report.error(where(doc), f"id `{doc.id}` is malformed")
        return
    if not doc.is_section and not re.fullmatch(re.escape(doc.id) + "-" + SLUG + r"\.md", doc.path.name):
        report.error(doc.path, f"file name must be `{doc.id}-<slug-kebab-case>.md`")
    if doc.kind == "ADR":
        return
    if doc.kind == "SCR" and doc.feature not in g.feature_names():
        report.error(doc.path, f"`domain: {doc.feature}` is not a feature folder")
        return
    if not doc.feature:
        report.error(where(doc), f"id `{doc.id}` has a DOMAIN that no feature folder maps to")
        return
    expected = g.domain_of(doc.feature)
    actual = doc.id.split("-")[1]
    if actual != expected:
        report.error(where(doc), f"id `{doc.id}` has DOMAIN `{actual}`; this folder requires `{expected}`")


def check_sections(doc: g.Doc, report: Report) -> None:
    mark = SECTION_MARK.get(schema(doc), "##")
    for name in REQUIRED_SECTIONS.get(schema(doc), ()):
        if name not in doc.sections:
            report.error(where(doc), f"missing section `{mark} {name}`")
    if schema(doc) in REVERSE_CHECKED:
        for _, line in g.iter_unfenced(doc.body):
            if REVERSE_HEADING.match(line):
                report.error(
                    where(doc),
                    f"`{line.strip()}` states a reverse relation; only generate.py writes those (spec R7)",
                )


def check_paths(doc: g.Doc, report: Report) -> None:
    for code_path in doc.as_list("code"):
        if not (g.ROOT / code_path).exists():
            report.error(where(doc), f"path in `code` does not exist: `{code_path}`")


def check_duplicates(docs: list[g.Doc], report: Report) -> dict[str, g.Doc]:
    by_id: dict[str, g.Doc] = {}
    for doc in docs:
        if doc.kind == "FEATURE" or not doc.id:
            continue
        if doc.id in by_id:
            report.error(where(doc), f"id `{doc.id}` duplicates {show(where(by_id[doc.id]))}")
            continue
        by_id[doc.id] = doc
    return by_id


def check_reference(
    doc: g.Doc, label: str, ref: str, kind: str, by_id: dict[str, g.Doc], report: Report,
    pending: frozenset[str] = frozenset(),
) -> None:
    target = by_id.get(ref)
    if target is None and kind == "SCR" and ref in pending:
        report.warning(where(doc), f"`{label}` names {ref}, whose spec is pending")
        return
    if target is None or target.kind != kind:
        report.error(where(doc), f"`{label}` names a {kind} that does not exist: `{ref}`")
    elif target.status == "deprecated":
        report.error(where(doc), f"`{label}` names a deprecated {kind}: `{ref}`")


def check_references(docs: list[g.Doc], by_id: dict[str, g.Doc], report: Report) -> None:
    pending = frozenset(pending_screens())
    for doc in docs:
        for label, kind in REFERENCE_FIELDS.get(schema(doc), ()):
            for ref in doc.as_list(label):
                check_reference(doc, label, ref, kind, by_id, report)
        if doc.kind == "SCR" and doc.screen is not None:
            for label, refs, kind in (
                ("Invokes", doc.screen.invokes, "FN"),
                ("Navigate to", doc.screen.navigates, "SCR"),
                ("Related Use Cases", doc.screen.related_ucs, "UC"),
            ):
                for ref in refs:
                    check_reference(doc, label, ref, kind, by_id, report, pending)
        superseded_by = str(doc.meta.get("superseded_by") or "")
        if not superseded_by:
            continue
        if superseded_by not in by_id:
            report.error(where(doc), f"`superseded_by` names an id that does not exist: `{superseded_by}`")
        if doc.status not in ("deprecated", "superseded"):
            report.error(where(doc), "`superseded_by` is only allowed with `status: deprecated` or `superseded`")


def check_invokes_complete(doc: g.Doc, report: Report) -> None:
    """Every FN a UC section's flow cites is on its `Invokes:` line."""
    if schema(doc) != "UCS":
        return
    for fn_id in specdocs.ids_in(doc.body, "FN"):
        if fn_id not in doc.as_list("invokes"):
            report.error(where(doc), f"`{fn_id}` is cited in the flow but missing from `Invokes:`")


def check_supersession(docs: list[g.Doc], by_id: dict[str, g.Doc], report: Report) -> None:
    """`supersedes` and `superseded_by` point at each other (spec R14)."""
    for doc in docs:
        if doc.kind != "ADR":
            continue
        successor = str(doc.meta.get("superseded_by") or "")
        if doc.status == "superseded" and not successor:
            report.error(doc.path, "`status: superseded` needs `superseded_by`")
        if doc.status == "superseded" and successor in by_id and doc.id not in by_id[successor].as_list("supersedes"):
            report.error(doc.path, f"`superseded_by: {successor}` but {successor} has no `supersedes: [{doc.id}]`")
        for old in doc.as_list("supersedes"):
            target = by_id.get(old)
            if target is None or target.kind != "ADR":
                report.error(doc.path, f"`supersedes` names an ADR that does not exist: `{old}`")
            elif target.status != "superseded" or str(target.meta.get("superseded_by")) != doc.id:
                report.error(doc.path, f"`supersedes: [{old}]` but {old} is not `superseded` by {doc.id}")


def check_single_product(report: Report) -> None:
    for path in sorted(g.DOCS.rglob("PRODUCT.md")):
        report.error(path, "product definition lives only in /PRODUCT.md (spec R12)")


# Homes retired after the verified migration (spec §6.1, plan Task 44); their
# content lives in USE_CASES.md, the screen specs and NAVIGATION.md.
RETIRED_HOMES = ("features/*/usecases/*", "features/*/ui.md", "shared/ui/**/*")


def check_retired_homes(report: Report) -> None:
    for pattern in RETIRED_HOMES:
        for path in sorted(g.DOCS.glob(pattern)):
            if path.is_file():
                report.error(path, "retired home (spec §6.1): UCs go in USE_CASES.md, "
                             "screens in screens/spec/, app navigation in NAVIGATION.md")


# SP2 removed the legacy goldens and these UI homes (spec 2026-10-04-sp2 §6); a
# golden is named scr_<screen>__<state>__<variant>.png from now on (R16).
RETIRED_UI_HOMES = ("lib/app/gallery/**/*", "test/visual_audit/**/*")


def check_legacy_ui(report: Report) -> None:
    for path in sorted(g.ROOT.glob("test/**/goldens/*.png")):
        if not path.name.startswith("scr_"):
            report.error(path, "legacy golden (SP2): new goldens are named scr_<screen>__<state>__<variant>.png")
    for pattern in RETIRED_UI_HOMES:
        for path in sorted(g.ROOT.glob(pattern)):
            if path.is_file():
                report.error(path, "retired home (SP2): the legacy gallery and visual audits are gone")


def check_catalog(docs: list[g.Doc], report: Report) -> None:
    """Each screen has one catalog row that agrees with its frontmatter (plan PT5)."""
    rows, invariants = screen_catalog()
    path = g.screen_catalog_file()
    screens = {d.id: d for d in docs if d.kind == "SCR" and d.id}
    seen: set[str] = set()
    for row in rows:
        at = f"{show(path)}:{row.line}"
        if row.id in seen:
            report.error(at, f"`{row.id}` has two catalog rows")
            continue
        seen.add(row.id)
        doc = screens.get(row.id)
        if row.status == PENDING:
            if doc is not None:
                report.error(at, f"catalog row `{row.id}` is pending but its spec exists")
            continue
        if doc is None:
            report.error(at, f"catalog row `{row.id}` has no screen spec")
            continue
        expected = (str(doc.meta.get("name", "")), doc.feature, doc.as_list("route"), doc.status)
        actual = (row.name, row.domain, row.routes, row.status)
        for label, want, got in zip(("Screen", "Domain", "Route", "Status"), expected, actual):
            if want != got:
                report.error(at, f"`{label}` is `{got}` but {row.id}'s spec says `{want}`")
    for doc_id, doc in sorted(screens.items()):
        if doc_id not in seen:
            report.error(doc.path, "screen has no row in screens/SCREEN_CATALOG.md")
    defined: set[str] = set()
    for inv in invariants:
        at = f"{show(path)}:{inv.line}"
        if inv.id in defined:
            report.error(at, f"`{inv.id}` is defined twice")
        defined.add(inv.id)
        if inv.enforced_by in ("", "—"):
            report.warning(at, f"`{inv.id}` is enforced by nothing yet")


def check_screen_states(docs, report, goldens: dict[str, Path], base_keys) -> None:
    """State keys are unique and permanent; a built screen has its goldens;
    once a `scr_*` golden exists, every golden maps to a declared state (R16)."""
    declared: set[str] = set()
    for doc in [d for d in docs if d.kind == "SCR" and d.id and d.screen is not None]:
        keys: list[str] = []
        for state in doc.screen.states:
            at = f"{show(doc.path)}:{state.line}"
            if state.error:
                report.error(at, state.error)
                continue
            if state.key in keys:
                report.error(at, f"state key `{state.key}` is used twice in this screen")
                continue
            keys.append(state.key)
            if state.removed:
                continue
            names = [specdocs.golden_name(doc.id, state.key, variant) for variant in state.variants]
            declared.update(names)
            if doc.status != "built":
                continue
            if state.golden_none:
                report.warning(at, f"built screen: state `{state.key}` has no golden")
            for name in names:
                if name not in goldens:
                    report.error(at, f"built screen: golden `{name}` is missing")
        for missing in sorted((base_keys(doc.path) or set()) - set(keys)):
            report.error(
                doc.path,
                f"state key `{missing}` was renamed or deleted; keys are permanent — "
                "keep its heading with `Status: removed`",
            )
    if any(name.startswith("scr_") for name in goldens):
        for name in sorted(set(goldens) - declared):
            report.error(goldens[name], "golden matches no screen state (orphan)")


@functools.lru_cache(maxsize=1)
def base_commit() -> str | None:
    """Merge base with the first of origin/main, main, HEAD that resolves (plan PT9)."""
    for ref in ("origin/main", "main", "HEAD"):
        result = subprocess.run(["git", "merge-base", "HEAD", ref], cwd=g.ROOT, capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    return None


def base_state_keys(path: Path) -> set[str] | None:
    commit = base_commit()
    if commit is None:
        return None
    shown = subprocess.run(
        ["git", "show", f"{commit}:{path.relative_to(g.ROOT).as_posix()}"],
        cwd=g.ROOT, capture_output=True, encoding="utf-8",
    )
    if shown.returncode != 0:
        return None
    _, body, _ = g.split_frontmatter(shown.stdout)
    return {state.key for state in specdocs.parse_screen(body).states if state.key}


def check_feature_readme(doc: g.Doc, features: list[str], report: Report) -> None:
    if doc.meta.get("feature") != doc.feature:
        report.error(doc.path, f"`feature: {doc.meta.get('feature')}` must match the folder name `{doc.feature}`")
    for dep in doc.as_list("depends_on"):
        if dep not in features:
            report.error(doc.path, f"`depends_on` names a feature that does not exist: `{dep}`")


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
            report.error(readme[feature].path, f"`depends_on` has a cycle: {' → '.join(cycle)}")
            return
        state[feature] = "open"
        for dep in graph.get(feature, []):
            if dep in graph:
                visit(dep, path + [feature])
        state[feature] = "done"

    for feature in sorted(graph):
        visit(feature, [])


def check_warnings(docs: list[g.Doc], report: Report) -> None:
    usage = g.used_by(docs)
    invoked = g.invoked_by(docs)
    functions = {d.id: d for d in docs if d.kind == "FN"}
    ready = [d for d in docs if d.kind == "UC" and d.status == "ready"]
    tests = g.tests_by_id([d.id for d in ready])
    for doc in docs:
        if doc.kind == "BR" and doc.status == "active" and doc.id not in usage:
            report.warning(doc.path, "active BR is cited by no FN")
        if doc.kind == "FN" and doc.status == "active" and doc.id not in invoked:
            report.warning(where(doc), "active FN is invoked by no UC and no screen")
    for doc in ready:
        invoked_fns = [functions[f] for f in doc.as_list("invokes") if f in functions]
        if not doc.as_list("code") and not any(f.as_list("code") for f in invoked_fns):
            report.warning(where(doc), "ready UC: it and every FN it invokes have `Code: []`")
        if not tests[doc.id]:
            report.warning(where(doc), "ready UC has no test that contains its id")


def defined_ids(docs: list[g.Doc]) -> set[str]:
    _, invariants = screen_catalog()
    ids = {d.id for d in docs if d.kind in ("BR", "UC", "FN", "SCR") and d.id}
    return ids | {inv.id for inv in invariants} | pending_screens()


def defined_invariants() -> set[int] | None:
    path = g.DOCS / INVARIANT_FILE
    if not path.exists():
        return None
    return {int(n) for n in INVARIANT_DEF.findall(path.read_text(encoding="utf-8"))}


def markdown_files() -> list[Path]:
    return sorted(g.DOCS.rglob("*.md"))


def is_skipped_for_ids(path: Path) -> bool:
    return path.relative_to(g.DOCS).parts[0] in SKIP_ID_CHECK


def is_skipped_for_links(path: Path) -> bool:
    return path.relative_to(g.DOCS).parts[0] in SKIP_LINK_CHECK


def check_text(docs: list[g.Doc], report: Report) -> None:
    ids = defined_ids(docs)
    # A superseded or deprecated ADR is a record; its body is never edited (plan PT11).
    records = {d.path for d in docs if d.kind == "ADR" and d.status in ("superseded", "deprecated")}
    invariants = defined_invariants()
    for path in markdown_files():
        check_ids = not is_skipped_for_ids(path)
        skip_links = is_skipped_for_links(path) or path in records
        kinds = allowed_kinds(path)
        rel = path.relative_to(g.DOCS).as_posix()
        text = path.read_text(encoding="utf-8")
        body_start = frontmatter_end(text)
        for line_no, raw in g.iter_unfenced(text):
            where_line = f"{show(path)}:{line_no}"
            # `inline code` holds examples and markers, not citations or links.
            line = g.INLINE_CODE.sub("", raw)
            if not skip_links:
                check_links(path, line, where_line, report)
            # Frontmatter ids are checked as fields (`rules`, `superseded_by`).
            if not check_ids or line_no <= body_start:
                continue
            # In the new layout an id in `inline code` is still a citation (plan PT4).
            cited = set(specdocs.ANY_ID.findall(raw if kinds is not None else line))
            for missing in sorted(cited - ids):
                report.error(where_line, f"`{missing}` is cited but not defined")
            if kinds is not None and g.OPEN_QUESTION not in raw and not DEFINITION_LINE.match(raw):
                for wrong in sorted(c for c in cited if specdocs.id_kind(c) not in kinds):
                    report.error(
                        where_line,
                        f"`{wrong}` is a {specdocs.id_kind(wrong)} ID; {rel} may cite only {', '.join(sorted(kinds))}",
                    )
            for n in INVARIANT_CITE.findall(line):
                if invariants is not None and int(n) not in invariants:
                    report.error(where_line, f"`invariant Q{n}` is cited but there is no `-- {n}.`")


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
            report.error(where, f"broken link: `{target}`")


def check_generated(report: Report) -> None:
    """Run generate.py into a temp dir and compare byte-for-byte with docs/_generated/."""
    with tempfile.TemporaryDirectory() as tmp:
        g.write_all(Path(tmp))
        for path in sorted(Path(tmp).iterdir()):
            current = g.GENERATED / path.name
            if not current.exists():
                report.error(current, "not generated — run `python tools/docs/generate.py`")
            elif current.read_bytes() != path.read_bytes():
                report.error(current, "stale — run `python tools/docs/generate.py`")
        if g.GENERATED.is_dir():
            expected = {p.name for p in Path(tmp).iterdir()}
            for extra in sorted(p.name for p in g.GENERATED.iterdir() if p.name not in expected):
                report.error(g.GENERATED / extra, "not produced by generate.py")


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
        report.error(plan, "plan file not found")
        return
    missing: dict[str, int] = {}
    for dest in plan_destinations(plan):
        if not destination_exists(dest):
            missing[dest] = missing.get(dest, 0) + 1
    for dest, rows in sorted(missing.items()):
        report.error(plan, f"destination does not exist ({rows} row(s)): `{dest}`")


def destination_exists(dest: str) -> bool:
    pattern = dest.replace("<slug>", "*")
    if "*" in pattern:
        return any(g.DOCS.glob(pattern.rstrip("/")))
    return (g.DOCS / pattern).exists()


def new_layout_files() -> list[Path]:
    paths = [g.use_cases_file(), g.navigation_file()]
    paths += sorted(g.functional_spec_dir().glob("*.md")) if g.functional_spec_dir().is_dir() else []
    screens = g.DOCS / "screens"
    paths += sorted(screens.rglob("*.md")) if screens.is_dir() else []
    return [path for path in paths if path.exists()]


def check_ledger(path: Path, defined: set[str], report: Report) -> None:
    """Spec §7.1 conditions 1–3: every row has a valid outcome; a moved row's
    destination exists; nothing is still OPEN QUESTION in the new docs."""
    if not path.exists():
        report.error(path, "ledger file not found")
        return
    found = ledger.rows(path.read_text(encoding="utf-8"))
    if not found:
        report.error(path, "ledger has no rows")
    for line_no, _, outcome in found:
        at = f"{show(path)}:{line_no}"
        match = ledger.OUTCOME.match(outcome)
        if match is None:
            report.error(at, f"outcome `{outcome or '(empty)'}` is not `moved → …`, `superseded → …` or `dropped — …, approved <date>`")
        elif match["pending"]:
            report.error(at, f"still pending: `{outcome}` — the target is not written yet")
        elif match["dest"] and not destination_exists(match["dest"].split("#", 1)[0]):
            report.error(at, f"moved to a path that does not exist: `{match['dest']}`")
        elif match["by"]:
            cited = specdocs.ANY_ID.match(match["by"])
            if cited and cited[1] not in defined:
                report.error(at, f"superseded by an undefined id: `{cited[1]}`")
    for new in new_layout_files():
        for line_no, line in g.iter_unfenced(new.read_text(encoding="utf-8")):
            if g.OPEN_QUESTION in g.INLINE_CODE.sub("", line):
                report.error(f"{show(new)}:{line_no}", "an OPEN QUESTION is still open in the new docs (spec §7.1)")


# ------------------------------------------------------- acceptance criteria

ACCEPTANCE_SECTION = "Acceptance criteria"
ACCEPTANCE_LINE = re.compile(r"\*\*given\*\*.*\*\*when\*\*.*\*\*then\*\*", re.IGNORECASE)


def check_acceptance_criteria(doc: g.Doc, report: Report) -> None:
    """A `ready` UC is a contract; its criteria are the checkable half (BE-D4)."""
    if doc.kind != "UC" or doc.status != "ready":
        return
    text = specdocs.subsection_text(doc.body, ACCEPTANCE_SECTION, 4)
    criteria = [line for _, line in g.iter_unfenced(text) if g.OPEN_QUESTION not in line]
    if not any(ACCEPTANCE_LINE.search(line) for line in criteria):
        report.error(where(doc), "ready UC has no Given/When/Then line under `## Acceptance criteria`")


# ------------------------------------------------------------ V7 residue

# V7 is gone from V8 (BE-D7). These name V7 things V8 does
# not have: its component catalog, its progress ledger (`wbs.md` by any path;
# V8's are `wbs_BE.md` and `wbs_FE.md`), its phase checklist, and its
# repository (local backend spec 2026-09-27 §6, BE-D7).
V7_MARKER = re.compile(
    r"widgetbook|\bwbs\.md|docs/checklist\.md|memox-v7|checklist phases?\b",
    re.IGNORECASE,
)
V7_SCAN = (".claude/skills", "docs")
# Records of what was decided or done then; they name V7 on purpose. One file
# per entry, so a new spec, plan or ADR is scanned like any live document.
_DATED = "a dated record of the V7 removal it planned or ran"
V7_HISTORY = {
    "docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md":
        "the ADR's context names the V7 pointers it left for later",
    "docs/superpowers/specs/2026-09-21-memox-v8-foundation-design.md":
        "the foundation decision names where V7 lives",
    "docs/superpowers/specs/2026-09-23-build-apk-release-design.md":
        "records the V7 workflow it took as reference",
    "docs/superpowers/specs/2026-09-23-v8-folder-architecture-design.md": _DATED,
    "docs/superpowers/specs/2026-09-25-ci-gate-design.md": _DATED,
    "docs/superpowers/specs/2026-09-26-verification-tooling-design.md": _DATED,
    "docs/superpowers/specs/2026-09-27-guard-without-v7-design.md": _DATED,
    "docs/superpowers/specs/2026-09-27-local-backend-completion-design.md": _DATED,
    "docs/superpowers/specs/2026-09-27-skills-without-v7-design.md": _DATED,
    "docs/superpowers/plans/2026-09-23-docs-v8-reset.md": _DATED,
    "docs/superpowers/plans/2026-09-23-v8-folder-architecture.md": _DATED,
    "docs/superpowers/plans/2026-09-24-settings-reset-backend.md":
        "a dated plan that quotes the WBS rows of its day",
    "docs/superpowers/plans/2026-09-24-study-session-backend.md":
        "a dated plan that quotes the WBS rows of its day",
    "docs/superpowers/plans/2026-09-25-ci-gate.md": _DATED,
    "docs/superpowers/plans/2026-09-26-reminders-backend.md":
        "a dated plan that quotes the WBS rows of its day",
    "docs/superpowers/plans/2026-09-26-starter-decks-backend.md":
        "a dated plan that quotes the WBS rows of its day",
    "docs/superpowers/plans/2026-09-27-guard-without-v7.md": _DATED,
    "docs/superpowers/plans/2026-09-27-local-backend-g3-no-v7.md": _DATED,
    "docs/superpowers/plans/2026-09-27-skills-without-v7.md": _DATED,
    "docs/superpowers/plans/2026-09-27-verification-tooling.md": _DATED,
    "docs/wbs_BE.md": "its rows and log name what BE-D5, BE-D6 and BE-D7 removed",
    ".claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py":
        "asserts that Widgetbook stays out of the gate",
    ".claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py":
        "the V7 markers it keeps out of every repo-owned skill are its test data",
    "tools/docs/test_check.py": "the markers are this check's test data",
}


def is_history(relative: str) -> bool:
    return relative in V7_HISTORY


def v7_residue(root: Path) -> list[tuple[Path, int, str]]:
    """Every V7 marker in a text file under V7_SCAN, outside V7_HISTORY."""
    hits: list[tuple[Path, int, str]] = []
    for scan in V7_SCAN:
        for path in sorted((root / scan).rglob("*")):
            relative = path.relative_to(root).as_posix()
            if not path.is_file() or "__pycache__" in path.parts or is_history(relative):
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue  # binary: an image, a font, a golden
            for number, line in enumerate(text.splitlines(), start=1):
                match = V7_MARKER.search(line)
                if match:
                    hits.append((path, number, match.group(0)))
    return hits


def check_v7_residue(report: Report) -> None:
    for path, number, marker in v7_residue(g.ROOT):
        report.error(f"{show(path)}:{number}", f"`{marker}` names V7; V8 does not have it (BE-D7)")


# ------------------------------------------------------------------- main


def run(plan: Path | None, base_keys=base_state_keys, ledger_path: Path | None = None) -> Report:
    report = Report()
    docs = g.load_docs()
    features = g.feature_names()
    for feature in features:
        if not (g.DOCS / "features" / feature / "README.md").exists():
            report.error(g.DOCS / "features" / feature, "feature has no README.md")
    for doc in docs:
        if not check_frontmatter(doc, report):
            continue
        if doc.kind == "FEATURE":
            check_feature_readme(doc, features, report)
        else:
            check_identity(doc, report)
        check_sections(doc, report)
        check_paths(doc, report)
        check_acceptance_criteria(doc, report)
        check_invokes_complete(doc, report)
    check_dependency_cycles(docs, report)
    by_id = check_duplicates(docs, report)
    check_references(docs, by_id, report)
    check_supersession(docs, by_id, report)
    check_single_product(report)
    check_retired_homes(report)
    check_legacy_ui(report)
    check_catalog(docs, report)
    check_screen_states(docs, report, g.golden_files(), base_keys)
    check_text(docs, report)
    check_generated(report)
    check_v7_residue(report)
    if plan is not None:
        check_plan(plan, report)
    if ledger_path is not None:
        check_ledger(ledger_path, defined_ids(docs), report)
    check_warnings(docs, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--plan", type=Path, help="Markdown file with mapping tables (first header cell \"Nguồn\")")
    parser.add_argument("--ledger", type=Path, help="migration ledger to verify (spec 2026-10-04 §7.1)")
    args = parser.parse_args()
    if not g.DOCS.is_dir():
        print("ERROR docs: not found — run from the repository root")
        return 1
    report = run(args.plan, ledger_path=args.ledger)
    report.print()
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
