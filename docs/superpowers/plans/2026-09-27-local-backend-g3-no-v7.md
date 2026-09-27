# Local backend G3 — nothing of V7 left in skills and documents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The `flutter-*` skills and the live documents stop pointing at V7
(Widgetbook, `docs/wbs.md`, `docs/checklist.md`, `memox-v7`, the V7 baseline and
blueprint), `host-coverage-map.md` stops claiming V8 has no tests, and
`tools/docs/check.py` keeps it that way.

**Architecture:** A new check in `tools/docs/check.py` scans `.claude/skills/**`
and `docs/**` for five V7 markers and reports each hit as an error; historical
records are excluded by path, each with its reason. The check lands first and
fails; the clean-up tasks then make it pass. Documents only, plus comments in
three scripts: no Dart code changes.

**Tech Stack:** Python 3 (`unittest`), Markdown.

**Spec:** `docs/superpowers/specs/2026-09-27-local-backend-completion-design.md` §6

## Global Constraints

- Remove Widgetbook from the Definition of Done and from the
  `flutter-feature-slice` and `flutter-design-system` skills.
- Repoint `docs/wbs.md` to `docs/wbs_BE.md` and `docs/wbs_FE.md`, and repoint
  the V7 checklist to the V8 documents.
- Remove the V7 baselines and blueprints, and the installation record of
  `project-documentation`.
- Remove the V7 history from the comments of `check_format.sh`,
  `check_generated.sh` and `check_architecture.py`.
- BE-D3: `host-coverage-map.md` drops "V8 chưa có test nào" and points to the
  grep that counts the real coverage.
- `tools/docs/check.py` reports an **error** when `.claude/skills/**` or
  `docs/**` mentions Widgetbook, `docs/wbs.md` or `memox-v7`. Historical records
  (ADRs, closed specs and plans) are excluded by path, each with its reason. The
  check fails before the clean-up and passes after it.
- Records: WBS BE-D7 and BE-D3 → `xong`.
- Messages printed by `tools/` scripts are in English (CLAUDE.md, Language).
- The 19 vendored ECC skills are not edited (CLAUDE.md, Vendored ECC skills).

## Review Focus

1. A marker in a file type the scan skips (`.yaml`, `.json`, `.sh`, `.py`
   under `.claude/skills/`): the scan reads every text file, not only `.md`.
2. A binary or cache file (`__pycache__/*.pyc`) must not be read or reported.
3. A marker in mixed case (`Widgetbook`, `WIDGETBOOK`) is still a hit.
4. An exclusion must name one path and its reason; a live document (e.g.
   `docs/wbs_FE.md`, `docs/shared/**` other than the ADRs) is never excluded.
5. A deleted reference file (`project-baseline.md`, `feature_blueprint.md`,
   `phase-index.md`) left named by another skill: every remaining mention is
   repointed.

---

### Task 1: The V7 residue check

**Files:**
- Modify: `tools/docs/check.py` (new section before `# ---- main`, call in `run`)
- Create: `tools/docs/test_check.py`

**Interfaces:**
- Produces: `V7_MARKER: re.Pattern`, `V7_HISTORY: dict[str, str]`
  (path relative to the repo root → reason),
  `v7_residue(root: Path) -> list[tuple[Path, int, str]]`
  (file, 1-based line, matched marker), `check_v7_residue(report: Report) -> None`.

- [ ] **Step 1: Write the failing tests**

```python
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

    def test_every_exclusion_gives_a_reason(self):
        for path, reason in check.V7_HISTORY.items():
            self.assertTrue(reason.strip(), path)

    def test_the_repository_is_clean(self):
        hits = check.v7_residue(Path(__file__).resolve().parents[2])
        self.assertEqual(hits, [], "\n".join(f"{p}:{n}: {m}" for p, n, m in hits))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run them to verify they fail**

Run: `python3 tools/docs/test_check.py`
Expected: every test errors with `AttributeError: module 'check' has no attribute 'v7_residue'` (or `V7_HISTORY`).

- [ ] **Step 3: Implement the check**

In `tools/docs/check.py`, before `# ---- main`:

```python
# ------------------------------------------------------------ V7 residue

# V7 is a reference, not a template (CLAUDE.md). These name V7 things V8 does
# not have: its component catalog, its progress ledger and phase checklist, and
# its repository (local backend spec 2026-09-27 §6, BE-D7).
V7_MARKER = re.compile(
    r"widgetbook|docs/wbs\.md|docs/checklist\.md|memox-v7|checklist phases?\b",
    re.IGNORECASE,
)
V7_SCAN = (".claude/skills", "docs")
# Records of what was decided or done then; they name V7 on purpose.
V7_HISTORY = {
    "docs/shared/decisions": "an ADR records the context its decision was taken in",
    "docs/superpowers/specs": "a spec records what was decided on its date",
    "docs/superpowers/plans": "a plan records what was done on its date",
    "docs/wbs_BE.md": "its rows and log name what BE-D5, BE-D6 and BE-D7 removed",
    ".claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py":
        "asserts that Widgetbook stays out of the gate",
    "tools/docs/test_check.py": "the markers are this check's test data",
}


def is_history(relative: str) -> bool:
    return any(relative == path or relative.startswith(path + "/") for path in V7_HISTORY)


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
```

In `run`, after `check_design_handoff(report)`: `check_v7_residue(report)`.

`tools/docs/test_check.py` sits outside `V7_SCAN`, so its entry in `V7_HISTORY`
is documentation only; keep it so a later widening of `V7_SCAN` does not flag it.

- [ ] **Step 4: Run the tests**

Run: `python3 tools/docs/test_check.py`
Expected: five pass; `test_the_repository_is_clean` FAILS listing the current
hits (the check fails before the clean-up — spec §6). Also run
`python3 tools/docs/check.py | tail -3` → `FAIL — N error(s)`, every error a
V7 residue line.

- [ ] **Step 5: Commit**

```bash
git add tools/docs/check.py tools/docs/test_check.py
git commit -m "feat(docs): check.py reports V7 residue in skills and docs (BE-D7 G3)"
```

---

### Task 2: `flutter-workflow` describes V8

**Files:**
- Modify: `.claude/skills/flutter-workflow/SKILL.md`
- Delete: `.claude/skills/flutter-workflow/references/phase-index.md`
- Modify: `.claude/skills/flutter-workflow/references/definition-of-done.md:57-65`
- Modify: `.claude/skills/flutter-workflow/scripts/check_format.sh:1-36`
- Modify: `.claude/skills/flutter-workflow/scripts/check_generated.sh:1-9`

- [ ] **Step 1: Rewrite `SKILL.md`**

- Frontmatter `description`: "Router for development work on MemoX V8: which
  `flutter-*` skill applies to a task, where progress is recorded
  (`docs/wbs_BE.md`, `docs/wbs_FE.md`), and the Definition of Done. Use it when
  work starts and the owning skill is not obvious — "what's next", "let's build
  X", "add a feature", "is this done", "review before commit". Process (brainstorm,
  plan, execute, review) belongs to Superpowers, per CLAUDE.md."
- Intro: no 22-phase checklist; the skill picks the skill to load, Superpowers
  owns the process.
- "Find out where the project is": `sed -n 1,40p docs/wbs_BE.md`,
  `sed -n 1,40p docs/wbs_FE.md`, `git log --oneline -10`; the two WBS files are
  authoritative for progress.
- Routing table: drop the "Checklist phase" column; the data-layer row reads
  "Retrofit API clients on the shared Dio (ADR-012), repository shape,
  DTO/entity split, cache, sync, secure storage".
- Worked examples: `docs/features/deck/` and `docs/features/card/` with
  `lib/features/deck/` and `lib/features/card/`; drop the blueprint and the
  "until M99.2" paragraph.
- Drop "Phase order is a dependency graph": ordering work is Superpowers'
  (CLAUDE.md, Layers and authority).
- "Keeping the ledger honest": update the WBS row (`wbs_BE.md` or `wbs_FE.md`)
  in the PR that does the work; drop the pointer to `phase-index.md`.

- [ ] **Step 2: Delete `references/phase-index.md`**

`git rm .claude/skills/flutter-workflow/references/phase-index.md`

- [ ] **Step 3: Definition of Done**

Remove the "Registered in the Widgetbook catalog" item. Replace
"`docs/wbs.md` updated in this commit." with "The WBS row (`docs/wbs_BE.md` or
`docs/wbs_FE.md`) updated in the same PR."

- [ ] **Step 4: Script comments**

`check_format.sh` header: what the script checks and why `git ls-files` (it
lists only this tree's tracked Dart files, so other worktrees under
`.claude/worktrees/` and untracked build output stay out), why the paths are
cut to the first segment (Windows command-line length), that the local gate and
CI call this one definition, and the `.` fallback without git. No incident
narrative ("for weeks", "used to run").

`check_generated.sh` header: "Thin wrapper over `check_generated.py`, kept as
`.sh` so every caller keeps working." plus Usage/Exit.

- [ ] **Step 5: Verify and commit**

Run: `grep -rniE "widgetbook|docs/wbs\.md|docs/checklist\.md|memox-v7|checklist phase|phase-index" .claude/skills/flutter-workflow --exclude-dir=__pycache__ --exclude=test_ci_tooling.py`
Expected: no output.
Run: `bash -n .claude/skills/flutter-workflow/scripts/check_format.sh && bash -n .claude/skills/flutter-workflow/scripts/check_generated.sh && bash .claude/skills/flutter-workflow/scripts/check_format.sh`
Expected: exit 0.

```bash
git add -A .claude/skills/flutter-workflow
git commit -m "docs(skills): flutter-workflow routes V8 work, no V7 checklist or Widgetbook (BE-D7 G3)"
```

---

### Task 3: Feature slice and design system without V7

**Files:**
- Modify: `.claude/skills/flutter-feature-slice/SKILL.md` (description, :60-67, :191-225)
- Delete: `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md`, `assets/feature_checklist.md`
- Modify: `.claude/skills/flutter-design-system/SKILL.md` (description, :74-79)

- [ ] **Step 1: `flutter-feature-slice`**

- Description: drop "Covers checklist phase 14, and"; keep "it is the usual
  entry point for feature work".
- :66: the worked examples are V8's Deck and Card: `docs/features/deck/`,
  `docs/features/card/` and their code under `lib/features/`.
- Step 4 checklist: remove the Widgetbook item and the blueprint sentence after
  it.
- Step 5: `docs/wbs.md` → the WBS row (`docs/wbs_BE.md` or `docs/wbs_FE.md`).
- Remove the `feature_checklist.md` and `feature_blueprint.md` paragraphs.

- [ ] **Step 2: Delete the V7 assets**

`git rm .claude/skills/flutter-feature-slice/assets/feature_blueprint.md .claude/skills/flutter-feature-slice/assets/feature_checklist.md`

- [ ] **Step 3: `flutter-design-system`**

Description: drop "Covers checklist phases 7, 12 and 13". Replace the Widgetbook
paragraph with: a new shared component is not done until its states are pinned
by widget tests and goldens (`flutter-testing`) and the screens that use it are
in the screen gallery.

- [ ] **Step 4: Verify and commit**

Run: `grep -rniE "widgetbook|docs/wbs\.md|checklist phase|feature_blueprint|feature_checklist" .claude/skills/flutter-feature-slice .claude/skills/flutter-design-system .claude/skills/flutter-workflow --exclude-dir=__pycache__ --exclude=test_ci_tooling.py`
Expected: no output.

```bash
git add -A .claude/skills/flutter-feature-slice .claude/skills/flutter-design-system
git commit -m "docs(skills): feature slice and design system drop Widgetbook and the V7 blueprint (BE-D7 G3)"
```

---

### Task 4: Every other skill and record

**Files:**
- Modify: `.claude/skills/flutter-drift/SKILL.md` (description, :16-22, :192)
- Delete: `.claude/skills/flutter-drift/references/project-baseline.md`
- Modify: `.claude/skills/flutter-drift/references/schema-conventions.md:122`,
  `query-conventions.md:127`, `review-checklist.md:146`
- Modify: `.claude/skills/flutter-architecture/SKILL.md` (description, :224),
  `references/analysis_options.yaml:16`, `scripts/check_architecture.py:1-18`
- Modify: `.claude/skills/flutter-project-setup/SKILL.md` (description),
  `references/dependencies.md:51,81`
- Modify: `.claude/skills/flutter-product-spec/SKILL.md:51,106`,
  `flutter-ship/SKILL.md` (description, :164),
  `flutter-state-riverpod/SKILL.md` (description, :52),
  `flutter-data-layer/SKILL.md`, `flutter-navigation/SKILL.md`,
  `flutter-testing/SKILL.md` (descriptions)
- Delete: `.claude/skills/project-documentation/.installation.json`
- Modify: `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md` (Hệ quả)

- [ ] **Step 1: `flutter-drift`**

- :16-22: "Most Drift advice assumes a greenfield repo; this one has settled its
  layout (ADR-010, ADR-011) and its schema (`docs/shared/data/schema.md`).
  Read those before proposing a structural change."
- :192 table row for `project-baseline.md`: removed.
- `schema-conventions.md:122`: the storage mode is Drift's default (no
  `build.yaml`: epoch seconds), every timestamp column is UTC
  (`docs/shared/data/schema.md`); a new timestamp column gets a round-trip test.
- `query-conventions.md:127`: the card list's growing `LIMIT` window is
  `CardListDao.window` (`lib/features/card/data/datasources/card_list_dao.dart`).
- `review-checklist.md:146`: `schema.md` and the WBS row updated in the same PR.

- [ ] **Step 2: Architecture, setup, product spec, ship, state, data, navigation, testing**

- Every `description:` loses its "Covers checklist phase(s) …" clause, keeping
  the rest of the sentence grammatical; so does the "Covers checklist Phase(s)
  …" line near the top of each body (`flutter-architecture`, `-data-layer`,
  `-design-system`, `-feature-slice`, `-navigation`, `-product-spec`,
  `-project-setup`, `-ship`, `-state-riverpod`, `-testing`).
- `flutter-data-layer` description: "dio is deliberately not a dependency
  (ADR-012)" contradicts ADR-012 and `pubspec.yaml` (`dio`, `retrofit`); it
  reads "APIs are called through Retrofit on one shared Dio client (ADR-012)".
- `flutter-product-spec/assets/wbs_template.md:33`: drop the "Checklist
  phases" field.
- `flutter-architecture/SKILL.md:224` and `analysis_options.yaml:16`: the
  descope reason inline — no published `custom_lint` supports `analyzer >=10`,
  which the generator stack requires — instead of `docs/wbs.md`.
- `dependencies.md:51,81`: drop "see `docs/wbs.md`"; the job is
  code-verification-guard's (`--ruleset memox-v8`).
- `flutter-product-spec/SKILL.md:51`: the WBS row names `docs/wbs_BE.md` and
  `docs/wbs_FE.md`; :106 the same.
- `flutter-ship/SKILL.md:164`: technical debt recorded in the WBS
  (`docs/wbs_BE.md`, `docs/wbs_FE.md`).
- `flutter-state-riverpod/SKILL.md:52`: "it is descoped (no `custom_lint` for
  `analyzer >=10`)".
- `check_architecture.py` docstring: what it verifies and that the `.sh` beside
  it is a thin wrapper; drop the "bash it replaced" history.

- [ ] **Step 3: Installation record and ADR-011**

`git rm .claude/skills/project-documentation/.installation.json` (a receipt of
an install from a V7 worktree; without it the copy is unmanaged, which is what a
vendored copy is).

ADR-011 "Hệ quả", after the `feature_blueprint.md` bullet, add:
"  - Cập nhật 2026-09-27 (BE-D7): hai file này đã gỡ; bố cục thuộc ADR này và
    ADR-010, schema thuộc `docs/shared/data/schema.md`, ví dụ mẫu là Deck và Card
    của V8 (`docs/features/deck/`, `docs/features/card/`)."

- [ ] **Step 4: Verify and commit**

Run: `python3 tools/docs/test_check.py`
Expected: all six pass (the repository is clean).
Run: `grep -rn "project-baseline\|feature_blueprint\|feature_checklist\|phase-index" .claude/skills --exclude-dir=__pycache__`
Expected: no output.

```bash
git add -A .claude/skills docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md
git commit -m "docs(skills): no V7 baseline, ledger or checklist left in the skills (BE-D7 G3)"
```

---

### Task 5: BE-D3 and the records

**Files:**
- Modify: `docs/shared/testing/host-coverage-map.md:3`
- Modify: `docs/wbs_BE.md` (BE-D3, BE-D7 rows, the order list, the log)

- [ ] **Step 1: `host-coverage-map.md`**

Replace "V8 chưa có test nào." with: "Bảng dưới đây không phải giấy chứng nhận
coverage. Kịch bản nào đã có test thì tìm bằng id của nó:
`grep -rln "IT-CARD-001" test/` (test mang id kịch bản trong tên hoặc comment)."
and keep the rest of the paragraph ("— nó là bản đồ: …") joined grammatically.

- [ ] **Step 2: WBS**

- BE-D3 and BE-D7 → `xong`, Bằng chứng: this plan, `tools/docs/test_check.py`.
- Remove BE-D7 from the order list; add a dated log line.

- [ ] **Step 3: Verify and commit**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -2`
Expected: `PASS — 0 error(s), 45 warning(s)`.
Run: `python3 tools/docs/test_check.py`
Expected: 6 tests OK.

```bash
git add docs/shared/testing/host-coverage-map.md docs/wbs_BE.md docs/_generated
git commit -m "docs(wbs): BE-D7 and BE-D3 done (G3)"
```
