# Local backend G4 — acceptance criteria for 18 UCs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each of the 18 `ready` UCs whose `## Acceptance criteria` holds only
the placeholder line gets checkable Given/When/Then criteria, each checked
against the code and its tests; `tools/docs/check.py` then refuses a `ready` UC
without one.

**Architecture:** Documents plus one check. `check_acceptance_criteria` in
`tools/docs/check.py` reads the `## Acceptance criteria` section of every `ready`
UC and reports an error when no line matches the Given/When/Then form. It lands
first and reports 18 errors; the criteria tasks, one per feature group, bring it
to zero. Where a UC and the code disagree, neither is edited: the criterion is
written as an `OPEN QUESTION` line in the same section.

**Tech Stack:** Python 3 (`unittest`), Markdown.

**Spec:** `docs/superpowers/specs/2026-09-27-local-backend-completion-design.md` §7

## Global Constraints

- In 18 UC files, only the placeholder line of `## Acceptance criteria` (the
  `OPEN QUESTION` line saying the source has no Given/When/Then criteria yet) is
  replaced. Nothing else in a UC changes (docs/README.md, "Hợp đồng và phạm vi
  sửa").
- UC-TRANSFER-001, UC-TRANSFER-002, UC-REMINDER-001 and UC-STARTER-001 already
  carry criteria and are not touched.
- Form, as in those four UCs: `- [ ] **Given** … **when** … **then** … (BR-…, E2)`,
  Vietnamese prose, identifiers in backticks.
- At least one criterion per main-flow outcome and one per alternative or error
  flow (A1…, E1…) the UC lists.
- Source: only the UC itself and its `active` rules. Every criterion is checked
  against the code and tests.
- A UC–code disagreement: neither is edited; the criterion becomes
  `- [ ] OPEN QUESTION: <UC nói gì> — <code làm gì, file:dòng> (BR-…, E…)` in the
  same section. Every such line goes into the PR body and the final report.
- `tools/docs/check.py` reports an **error** when a `ready` UC's acceptance
  criteria hold no Given/When/Then line. Messages in English.
- Records: WBS BE-D4 → `xong`, with the open questions it recorded; its blocker
  row closes.

## Review Focus

1. A criterion that paraphrases the UC but that the code does not do (the
   whole point of "checked against the code"): each criterion names in the
   ledger the test or code that shows it.
2. An alternative or error flow with no criterion (A/E ids listed in the UC but
   absent from the section).
3. A `ready` UC whose section holds only `OPEN QUESTION` lines: the guard must
   still require at least one Given/When/Then line.
4. The guard must read only the `## Acceptance criteria` section, not a
   Given/When/Then phrase elsewhere in the file, and must ignore fenced code.
5. A `draft` or `deprecated` UC without criteria is not an error.

---

### Task 1: The guard

**Files:**
- Modify: `tools/docs/check.py` (new `ACCEPTANCE_LINE`, `section_text`,
  `check_acceptance_criteria`; called from `run` for every UC)
- Modify: `tools/docs/test_check.py` (new `AcceptanceCriteriaTest`)

**Interfaces:**
- Produces: `ACCEPTANCE_LINE: re.Pattern` matching
  `**Given** … **when** … **then**` (case-insensitive on the three words);
  `section_text(body: str, name: str) -> str` (the lines under `## name` up to
  the next `## `, fenced blocks dropped);
  `check_acceptance_criteria(doc: g.Doc, report: Report) -> None`.

- [ ] **Step 1: Write the failing tests**

```python
def uc(status: str, criteria: str, elsewhere: str = "") -> "check.g.Doc":
    body = (
        "## Main flow\n\n" + elsewhere + "\n\n"
        "## Acceptance criteria\n\n" + criteria + "\n"
    )
    return check.g.Doc(
        path=Path("docs/features/x/usecases/UC-X-001-x.md"), kind="UC", feature="x",
        meta={"id": "UC-X-001", "status": status}, body=body,
        sections=check.g.h2_sections(body),
    )


class AcceptanceCriteriaTest(unittest.TestCase):
    GWT = "- [ ] **Given** một deck, **when** xoá, **then** nó vào Trash (BR-TRASH-001)."
    PLACEHOLDER = "- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then."

    def errors(self, doc) -> list[str]:
        report = check.Report()
        check.check_acceptance_criteria(doc, report)
        return [message for _, _, message in report.lines]

    def test_a_ready_uc_with_a_criterion_passes(self):
        self.assertEqual(self.errors(uc("ready", self.GWT)), [])

    def test_a_ready_uc_with_only_the_placeholder_fails(self):
        self.assertEqual(len(self.errors(uc("ready", self.PLACEHOLDER))), 1)

    def test_open_questions_alone_do_not_satisfy_it(self):
        self.assertEqual(len(self.errors(uc("ready", self.PLACEHOLDER + "\n" + self.PLACEHOLDER))), 1)

    def test_a_criterion_outside_the_section_does_not_count(self):
        self.assertEqual(len(self.errors(uc("ready", self.PLACEHOLDER, elsewhere=self.GWT))), 1)

    def test_a_criterion_in_a_fence_does_not_count(self):
        fenced = "```\n" + self.GWT + "\n```"
        self.assertEqual(len(self.errors(uc("ready", fenced))), 1)

    def test_a_draft_uc_is_not_checked(self):
        self.assertEqual(self.errors(uc("draft", self.PLACEHOLDER)), [])
```

- [ ] **Step 2: Run them to verify they fail**

Run: `python3 tools/docs/test_check.py`
Expected: the six new tests error with `AttributeError: module 'check' has no attribute 'check_acceptance_criteria'`; the V7 tests still pass.

- [ ] **Step 3: Implement**

```python
# ------------------------------------------------------- acceptance criteria

ACCEPTANCE_SECTION = "Acceptance criteria"
ACCEPTANCE_LINE = re.compile(r"\*\*given\*\*.*\*\*when\*\*.*\*\*then\*\*", re.IGNORECASE)


def section_text(body: str, name: str) -> str:
    """The unfenced lines under `## name`, up to the next `## ` heading."""
    lines: list[str] = []
    inside = False
    for _, line in g.iter_unfenced(body):
        if line.startswith("## "):
            inside = line[3:].strip() == name
            continue
        if inside:
            lines.append(line)
    return "\n".join(lines)


def check_acceptance_criteria(doc: g.Doc, report: Report) -> None:
    """A `ready` UC is a contract; its criteria are the checkable half (BE-D4)."""
    if doc.kind != "UC" or doc.status != "ready":
        return
    if not ACCEPTANCE_LINE.search(section_text(doc.body, ACCEPTANCE_SECTION)):
        report.error(doc.path, "ready UC has no Given/When/Then line under `## Acceptance criteria`")
```

`g.iter_unfenced(body)` yields `(number, line)` for lines outside fences (it is
what `h2_sections` uses); confirm its signature before relying on it. `doc.status`
is the `Doc` property `check_frontmatter` already reads.

In `run`, inside the per-doc loop after `check_paths(doc, report)`:
`check_acceptance_criteria(doc, report)`.

- [ ] **Step 4: Run**

Run: `python3 tools/docs/test_check.py`
Expected: all tests OK.
Run: `python3 tools/docs/check.py | grep -c "no Given/When/Then"`
Expected: `18`.

- [ ] **Step 5: Commit**

```bash
git add tools/docs/check.py tools/docs/test_check.py
git commit -m "feat(docs): check.py refuses a ready UC without Given/When/Then criteria (BE-D4 G4)"
```

---

### Tasks 2–5: the criteria, one feature group per task

Each task runs the same steps on its UCs.

| Task | UCs |
|---|---|
| 2 | UC-DECK-001 … UC-DECK-006 |
| 3 | UC-CARD-001, UC-CARD-002, UC-TAG-001, UC-SEARCH-001 |
| 4 | UC-STUDY-001, UC-STUDY-002, UC-STUDY-003, UC-SRS-001 |
| 5 | UC-PROGRESS-001, UC-PROGRESS-002, UC-SETTINGS-001, UC-TRASH-001 |

- [ ] **Step 1: Draft from the UC**

For each UC: list its main-flow outcomes, its A/E flows and its `rules:`
(`active` only). Draft one criterion per outcome and per A/E flow in the form of
Global Constraints, citing the BR and the flow id.

- [ ] **Step 2: Check every criterion against the code and tests**

For each criterion find the code that does it (use case, repository, DAO,
controller, widget) and the test that exercises it (`grep -rln "<UC or BR id>"
test/`, then the test body). Record the evidence per criterion in the ledger
(`Task N: UC-…: criterion k → test/…::'<test name>'`). A criterion whose
behaviour the code does not have, or has differently, becomes an
`OPEN QUESTION` line (Global Constraints); the UC and the code stay as they are.

- [ ] **Step 3: Replace the placeholder**

Replace only the placeholder line in each UC with the criteria (and any
`OPEN QUESTION` lines) from Step 2.

- [ ] **Step 4: Verify and commit**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | grep -c "no Given/When/Then"`
Expected: the Task 1 count minus the UCs done so far (Task 2: 12, Task 3: 8, Task 4: 4, Task 5: 0).
Run: `git diff --stat -- docs/features` — only this task's UC files, and in each
only the `## Acceptance criteria` section changed (`git diff -U0` shows hunks
there alone).

```bash
git add docs/features docs/_generated
git commit -m "docs(<feature>): acceptance criteria for <UC ids> (BE-D4 G4)"
```

---

### Task 6: Records

**Files:**
- Modify: `docs/wbs_BE.md` (BE-D4 row, its blocker row, order list, log)

- [ ] **Step 1: WBS**

- BE-D4 → `xong`; Bằng chứng: this plan, the guard, the count of `OPEN QUESTION`
  lines recorded.
- Remove the BE-D4 row from "Điểm chặn và quyết định còn mở".
- Add a dated log line listing the open questions (UC id and one clause each).

- [ ] **Step 2: Verify and commit**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1`
Expected: `PASS — 0 error(s), N warning(s)`, N no more than before the package.
Run: `python3 tools/docs/test_check.py` → OK.

```bash
git add docs/wbs_BE.md docs/_generated
git commit -m "docs(wbs): BE-D4 done (G4)"
```
