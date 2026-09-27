# MemoX V8 Skills and Documents Without V7 Implementation Plan (package 12c)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-D7 of [`docs/wbs_BE.md`](../../wbs_BE.md), with BE-D3 folded in and
widened by the owner: the skills the repo owns keep nothing of V7. What they cite is V8's
(an ADR, a `BR-<AREA>-NNN` or `UC-<AREA>-NNN`, the WBS files, V8's code), every path they
cite exists, and a contract test in the gate pins both.

**Architecture:** One `unittest` module, `test_skills_without_v7.py`, scans the files of
the repo-owned skills for V7's markers and, from Task 6, for cited paths that do not
exist. Task 1 writes it for `flutter-workflow`; Tasks 2–5 each add the skills they clean,
so every task's red run lists exactly its own work and the gate stays green after every
task. Task 6 widens the markers to V7's names and pins the paths; Task 7 records the
package in ADR-011, the coverage map and the two WBS files. Skills, one test module, eight
comment lines of Dart and four documents change; no behaviour does.

**Tech Stack:** Markdown skills and references; Python 3 (`unittest`, the standard
library) for the contract test, run by the gate's CI tooling tests; Bash and Python gate
scripts whose comments change; Dart comments in `lib/` and `test/`; Flutter 3.47.5 for the
gate's own steps.

**Spec:**
[`docs/superpowers/specs/2026-09-27-skills-without-v7-design.md`](../specs/2026-09-27-skills-without-v7-design.md),
approved 2026-09-27 and amended in this plan's commit (§12: ADR-012 and ADR-013 arrived on
`master` during planning, the owner's three decisions after approval, and the rulings the
prototype needed).

**Prerequisite:** `claude/be-skills-without-v7` holds the spec and this plan, on `master`
at `3f78fb6` (#109) merged in as `5792aa1`. The plan runs on that branch, from this plan's
commit; the gate passes there with 2349 host tests and the CI tooling tests `Ran 67 tests`
· `OK`. Generated code is not committed: in a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs` first
(root `README.md`, "Commands").

**How this plan was checked:** every block below was written and run first, in a scratch
copy of the repository, task by task, test first. Each task's contract test failed as its
"Expected" line says, then passed, and after every task the gate passed. Each rule the
test pins was also broken on purpose in the scratch copy, one at a time: each marker
coming back in a skill's text: `memox-v7`, the word V7, an `AD-nn`, a `BR-nn`, a milestone
with and without a letter suffix, a review round, `A20.1`, a `P1-08` item, a checklist
phase singular and plural, `docs/checklist.md`, `docs/wbs.md`, `docs/architecture.md`,
`docs/api-spec.md`, Widgetbook, `test/demo/`, V7's four table and column names and
`SurfaceColumnRule`, one in a script and one in `spring-boot-mybatis-review`; the
blueprint, the phase index, a gallery script, the harness note or the receipt coming back;
a dead `lib/`, `docs/`, `test/`, `integration_test/` or skill-relative path; a skill
dropped from the list, and a new skill left unclassified; the scan reading only
`SKILL.md`, reading `tests/`, or stopping on a byte that is not UTF-8; the rule marker
catching V8's rules; the phase, Widgetbook and milestone markers narrowing; and the path
check counting a placeholder, generated output or a path of the skill's own folder as
missing (46 breaks). Every break failed the contract test. This document was then applied,
step by step as written, onto a clean checkout of this plan's commit: each task's files
matched the scratch commit's, no other file moved, and the outputs and counts below are
that run's.

## Global Constraints

Every task's requirements implicitly include these.

- **Scope (spec D1, §12.2):** the fifteen repo-owned skills (the thirteen `flutter-*`
  skills, `project-documentation` and `spring-boot-mybatis-review`), the contract test,
  the eight lines of `lib/` and `test/` that cite AD-12 and AD-15, and the documents of
  spec §6 (ADR-011, `host-coverage-map.md`, `wbs_BE.md`, `wbs_FE.md`). `CLAUDE.md`, the
  vendored skills, the dated specs and plans under `docs/superpowers/`, the V7 provenance
  in other documents, `.github/` and every behaviour of the app do not change (§10).
- **Nothing of V7 (D1, D2):** no file of a repo-owned skill names V7, cites a V7 decision
  (`AD-nn`), rule (`BR-nn`), milestone or audit item, a checklist phase, a V7 document
  (`docs/wbs.md`, `docs/checklist.md`, `docs/architecture.md`, `docs/api-spec.md`),
  Widgetbook, `test/demo/`, or V7's table names; every path it cites in backticks exists
  (§7, §12.2, §12.3).
- **What a skill cites is V8's (§4):** an ADR in `docs/shared/decisions/`, a
  `BR-<AREA>-NNN` or `UC-<AREA>-NNN` in `docs/features/`, the WBS files, V8's code; or
  the reason stated in place; or nothing, when only V7 needed it.
- **ADR-012 and ADR-013 (§12.1):** AD-05 is ADR-012's (Retrofit on one shared Dio,
  added with the first API call; DTOs `json_serializable`, never Freezed); AD-01 and
  AD-03 are ADR-013's (the server is canonical, the app writes Drift first and syncs,
  login comes later). No skill cites ADR-001's superseded rows as in force.
- **Removed (D4, D5, D8, D9, §12.3):** `feature_blueprint.md`, `phase-index.md`,
  `integration-test-harness.md`, `build_screen_gallery.py`, `splice_screen_gallery.py`,
  `wbs_template.md` and `project-documentation/.installation.json`.
- **After every task** the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
- **Language:** skills, code, comments, test names and commit messages are in English;
  `docs/` keeps its Vietnamese. Prose the package edits in a skill wraps at 80 columns.
  Every commit message ends with the session's attribution trailers.

## Clarifications to confirm during plan review

Writing and running the blocks settled what the spec left to the plan. Each is decided
here and implemented as described; say so if one is wrong.

1. **ADR-012 and ADR-013 (spec §12.1).** They reached `master` during planning. A
   sentence that followed ADR-001's local-only or no-auth rows now follows them, and so
   does the V7 guidance beside it that ADR-013 contradicts: `project-baseline.md`'s sync
   section, `persistence.md`'s cache table and `isPendingSync` flow, and the data-layer
   repository example that read the network first. The sync and network guidance
   ADR-013's roadmap needs comes with the slices that build sync, not here.
2. **The contract test grows task by task (§12.3).** Each task adds the skills it cleans
   to `REPO_OWNED_SKILLS`, so its red run is its own work list and the gate stays green.
3. **Fifteen skills, and every skill classified (§12.3).** `spring-boot-mybatis-review`
   is repo-owned (`CLAUDE.md`) and cites nothing of V7; it joins the list in Task 5, with
   `VENDORED_SKILLS` for the other 35 directories and a test that every directory under
   `.claude/skills/` is in one list or the other.
4. **V7 without a marker (§12.3).** The spec's markers do not catch everything V7 left:
   the history in `check_format.sh` and `check_generated.py/.sh` (named by BE-D7's row),
   V7's "due", the emptied deck, V7's error model, dependency tables that were not V8's
   `pubspec.yaml`, the `@freezed` state example, generated code said to be committed, and
   the reference `analysis_options.yaml` claiming to be the root's copy. Each is rewritten
   to V8 where the task touches that skill. Names that only illustrate stay, unpinned.
5. **The error model is ADR-011 D6's**, as `lib/core/error/` has it: a refusal is
   `Rejected(reason)` of `Outcome` with the feature's enum; an unexpected database error
   is a sealed `Failure`, mapped once by `mapDatabaseError`. The examples use V8's types
   and files (`DeckRejection.notFound`, `ReminderWorkloadRepositoryImpl`).
6. **The eight lines of `lib/` and `test/` (the owner, §12.2)** are comments, one message
   (`boundary_rules.dart`) and one test name: no behaviour changes, and the contract test
   does not scan `lib/` or `test/`.
7. **The path check (the owner, §12.2)** reads paths in backticks under `lib/`, `test/`,
   `docs/`, `tools/`, `integration_test/`, or a skill's own `assets/`, `references/` and
   `scripts/`. A placeholder (`<`, `>`, `*`, `{`, `}`, `$`, `…`) or generated output
   (`*.g.dart`, `/generated/`) is not checked. Markdown links are checked once, by Task
   7's link check.
8. **The markers widen (§12.3):** a milestone with a letter suffix and a review round
   (`M99.19a`, `M6 R7`), "Phases" in the plural, `docs/api-spec.md`, and V7's
   `card_review_states`, `review_history`, `parent_deck_id`, `root_deck_id` and
   `SurfaceColumnRule`. `test_v8_citations_are_not_markers` keeps each from catching V8's
   text.
9. **§8's search (§12.3)** finds, outside `docs/superpowers/`, only the contract test,
   `skill_distribution.py`'s receipt constant, and the record of the removal in ADR-011
   and `wbs_BE.md`.
10. **`flutter-theme-design` (the owner, §12.2)** keeps its contract checklists and the
    `[x]` rules that still hold, and loses V7's milestones, history and "Đã ship" claims.
    Reconciling it with V8's theme and widgets is FE-D4 in `wbs_FE.md`.
11. **`integration-test-harness.md` goes in Task 4** with the gallery scripts: it
    described V7's `integration_test/` harness. Its three defect classes move into
    `flutter-testing`'s SKILL.md. The worked examples of §4.3 are `lib/features/deck/` and
    `lib/features/card/`: the two READMEs it names do not exist.
12. **Dates.** The plan and the update entries of the two WBS files are dated 2026-09-27.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person, each
pinned by a test in the task that owns the code:

1. **A skill that leaves the scan** (a new skill added later, a renamed one, or a name
   dropped from the list to silence a failure): the classification test fails — Task 5,
   `test_every_skill_is_repo_owned_or_vendored`.
2. **V8 text that looks like V7's** (`BR-SRS-023`, `UC-DECK-001`, `ADR-011 D4`,
   `docs/wbs_BE.md`, Material 3, `card_schedule`, `parent_id`): no marker — Tasks 1 and 6,
   `test_v8_citations_are_not_markers`.
3. **A path that is no file by design** (`lib/features/<feature>/domain/`,
   `test/**/*_test.dart`, an `*.g.dart` or `/generated/` output, a `references/` path of
   the skill itself): not reported; a real dead path is — Task 6,
   `test_a_cited_path_must_exist`.
4. **A skill that ships a binary file or its own `tests/`**: the scan replaces the bytes
   that are not UTF-8 and skips `tests/`, whose fixtures name V7 on purpose — Task 4,
   `test_a_skill_file_is_scanned_and_its_tests_are_not`.
5. **`project-documentation` reinstalled from a copy that names V7:** the receipt comes
   back and the test fails; without it, `skill_distribution.py inspect` reports this copy
   as canonical — Task 4, `test_project_documentation_is_its_own_canonical_source` and
   the inspect step.

## File Structure

```
.claude/skills/
├── flutter-workflow/
│   ├── SKILL.md, references/definition-of-done.md     routing, ledger (1); paths (6)
│   ├── references/phase-index.md                      deleted (1)
│   ├── scripts/check_{flutter_version,format}.sh,
│   │   check_generated.{py,sh}                        reasons without V7 (1)
│   └── scripts/tests/
│       ├── test_skills_without_v7.py                  new (1); grows (2–6)
│       └── test_architecture_checker.py               docstring (6)
├── flutter-feature-slice/                             SKILL, checklist (2, 6);
│   └── assets/feature_blueprint.md                    deleted (2)
├── flutter-design-system/                             SKILL, components (2, 6)
├── flutter-architecture/                              SKILL, analysis_options,
│                                                      check_architecture.py (2, 6)
├── flutter-drift/                                     SKILL, 9 references (3, 6);
│   └── references/project-baseline.md                 rewritten for V8 (3)
├── flutter-testing/                                   SKILL, golden.Dockerfile (4, 6);
│   ├── references/integration-test-harness.md         deleted (4)
│   └── scripts/{build,splice}_screen_gallery.py       deleted (4)
├── flutter-product-spec/                              SKILL, BR template (4, 6);
│   └── assets/wbs_template.md                         deleted (4)
├── project-documentation/.installation.json           deleted (4)
├── flutter-data-layer/, flutter-navigation/,
│   flutter-project-setup/, flutter-ship/,
│   flutter-state-riverpod/, flutter-theme-design/     V7 out, ADR-012/013 in (5, 6)
lib/features/{card,deck}/presentation/controllers/      AD-12 → ADR-011 D4 (2)
test/architecture/boundary_rules{,_test}.dart           AD-15 → ADR-011 D8 (2)
test/features/{card,deck,trash}/domain/*_test.dart       AD-12 → ADR-011 D4 (2)
docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md     Hệ quả (7)
docs/shared/testing/host-coverage-map.md                 BE-D3 (7)
docs/wbs_BE.md, docs/wbs_FE.md                           BE-D7, BE-D3 done; FE-D4 (7)
```

---


### Task 1: flutter-workflow routes by topic and reads V8's ledger

**Files:**
- Modify: `.claude/skills/flutter-workflow/SKILL.md`, `.claude/skills/flutter-workflow/references/definition-of-done.md`, `.claude/skills/flutter-workflow/scripts/check_flutter_version.sh`, `.claude/skills/flutter-workflow/scripts/check_format.sh`, `.claude/skills/flutter-workflow/scripts/check_generated.py`, `.claude/skills/flutter-workflow/scripts/check_generated.sh`
- Delete: `.claude/skills/flutter-workflow/references/phase-index.md`
- Test (create): `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`

**Interfaces:**
- Consumes: nothing of this plan.
- Produces (`.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`):
  `REPO_ROOT: Path`, `SKILLS: Path`, `REPO_OWNED_SKILLS: tuple[str, ...]`,
  `V7_MARKERS: tuple[str, ...]` (regular expressions), `SKIPPED_DIRECTORIES`,
  `_markers_in(text: str) -> list[str]`, `_scanned_files(skill: Path) -> list[Path]`,
  `_occurrences() -> list[str]`, each hit as `<path>:<line>: <text>`.

Spec §4.3 (`flutter-workflow`), §5, §7, D5–D7; Clarifications 2 and 4.

- [ ] **Step 1: Write the contract test**

The test scans `flutter-workflow` only; each later task adds the skills it cleans
(Clarification 2).

Create `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`:

```python
"""The skills the repo owns keep nothing of V7 (package 12c, BE-D7).

V7 is a reference implementation only (`CLAUDE.md`). Its decisions (`AD-nn`),
its business rules (`BR-nn`), its milestones, its 22-phase checklist, its
documents and its Widgetbook catalog do not exist in V8, so a skill that cites
them sends the agent to something it cannot read. What a skill cites is V8's:
an ADR in `docs/shared/decisions/`, a `BR-<AREA>-NNN` or `UC-<AREA>-NNN` in
`docs/features/`, the WBS files, or V8's code.

The vendored skills (ECC, Superpowers, Impeccable) are not the repo's to edit
and are not scanned. The `tests/` directories are not scanned either: the CI
tooling tests themselves assert that Widgetbook and `memox-api` are absent.
"""
from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[5]
SKILLS = REPO_ROOT / ".claude" / "skills"

REPO_OWNED_SKILLS = (
    "flutter-workflow",
)

V7_MARKERS = (
    r"(?i)memox[-_ ]v7",
    r"(?i)\bv7\b",
    r"\bAD-\d",
    r"\bBR-\d",
    r"\bM\d+\.\d+\b",
    r"A20\.1",
    r"\bP[1-3]-\d\d\b",
    r"(?i)\bphases? \d",
    r"docs/checklist\.md",
    r"docs/wbs\.md",
    r"docs/architecture\.md",
    r"(?i)widgetbook",
    r"test/demo",
    r"feature_blueprint",
    r"phase-index",
    r"screen_gallery",
)

SKIPPED_DIRECTORIES = {"tests", "__pycache__"}


def _markers_in(text: str) -> list[str]:
    return [pattern for pattern in V7_MARKERS if re.search(pattern, text)]


def _scanned_files(skill: Path) -> list[Path]:
    return sorted(
        path
        for path in skill.rglob("*")
        if path.is_file()
        and not SKIPPED_DIRECTORIES.intersection(path.relative_to(skill).parts)
    )


def _occurrences() -> list[str]:
    found = []
    for name in REPO_OWNED_SKILLS:
        for path in _scanned_files(SKILLS / name):
            text = path.read_text(encoding="utf-8")
            for number, line in enumerate(text.splitlines(), start=1):
                if _markers_in(line):
                    relative = path.relative_to(REPO_ROOT).as_posix()
                    found.append(f"{relative}:{number}: {line.strip()}")
    return found


class MarkersTest(unittest.TestCase):
    def test_each_marker_names_what_v7_left(self):
        for text in (
            "work starts on memox-v7",
            "V7's `features/deck` slice",
            "(AD-05 in the architecture notes)",
            "the deck keeps its type (BR-63)",
            "a real bug (M99.61)",
            "until A20.1 P1-08",
            "Covers checklist Phase 15.",
            "Covers checklist Phases 4 (structure) and 5 (lint).",
            "the 22 phases of docs/checklist.md",
            "update docs/wbs.md in this commit",
            "write it in docs/architecture.md",
            "registered in the Widgetbook catalog",
            "the goldens under test/demo/",
            "see assets/feature_blueprint.md",
            "references/phase-index.md",
            "scripts/build_screen_gallery.py",
        ):
            with self.subTest(text=text):
                self.assertTrue(_markers_in(text))

    def test_v8_citations_are_not_markers(self):
        for text in (
            "ADR-011 D4: one use case per interaction",
            "BR-SRS-023 and UC-DECK-001",
            "docs/wbs_BE.md and docs/wbs_FE.md",
            "docs/shared/decisions/ADR-001-quyet-dinh-nen-tang.md",
            "Material 3 in lib/core/theme/",
        ):
            with self.subTest(text=text):
                self.assertEqual(_markers_in(text), [])


class RepoOwnedSkillsTest(unittest.TestCase):
    maxDiff = None

    def test_every_listed_skill_exists(self):
        missing = [name for name in REPO_OWNED_SKILLS if not (SKILLS / name / "SKILL.md").is_file()]
        self.assertEqual(missing, [])

    def test_no_repo_owned_skill_names_v7(self):
        self.assertEqual(_occurrences(), [])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run it to see it fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 4 tests` and `FAILED (failures=1)`: `test_no_repo_owned_skill_names_v7`
lists 15 lines in four files (`SKILL.md` 9, `check_flutter_version.sh` 3,
`definition-of-done.md` 2, `phase-index.md` 1), the first
`.claude/skills/flutter-workflow/SKILL.md:3: description: … whenever work starts on memox-v7 …`.
The three marker tests pass already.

- [ ] **Step 3: Rewrite the skill: its description, the routing table, the ledger**

Replace the whole of `.claude/skills/flutter-workflow/SKILL.md` with:

````markdown
---
name: flutter-workflow
description: Entry point and router for all development work on this Flutter app. Use this skill whenever work starts on MemoX V8 and the next step is not already obvious — "what's next", "let's build X", "continue the app", "add a feature", "is this done", "review before commit" — and whenever you need to know which of the other flutter-* skills applies. It maps each kind of work to the skill that covers it, enforces the dependency order between kinds of work, and holds the Definition of Done. Consult it before starting any non-trivial task so work does not begin on something whose prerequisites are still open.
---

# Flutter workflow router

This skill decides *what to work on next* and *which skill to load*. It does
not contain implementation detail — that lives in the specialised skills.

## First: find out where the project actually is

Do not trust memory or assumption about project state. Check:

```bash
sed -n '1,60p' docs/wbs_BE.md   # backend progress: done, remaining, order
sed -n '1,60p' docs/wbs_FE.md   # frontend progress: done, remaining, order
ls lib/features/                # which features exist
git log --oneline -10
```

`docs/wbs_BE.md` and `docs/wbs_FE.md` are authoritative for progress, and a
screen's row in the
[screen handoff index](../../../docs/shared/ui/screen-handoff/00-index.md) is
authoritative for that screen. If one is clearly stale relative to the code, say
so and fix it before building anything else — every later decision depends on it
being true.

## Routing table

| You are doing | Load skill |
|---|---|
| Defining the product, users, MVP scope, use cases, business rules, WBS, docs | `flutter-product-spec` |
| Creating the Flutter project, dependencies, flavors, bootstrap, error model | `flutter-project-setup` |
| Folder structure, layer boundaries, lint config, naming, code conventions | `flutter-architecture` |
| Design tokens, theming, shared components, responsive, localization, a11y | `flutter-design-system` |
| A component theme in `lib/core/theme/`, an `Mx*` widget's API, admitting a new Material widget, theme ↔ widget parity | `flutter-theme-design` |
| Routes, guards, deep links, nested shells, back behaviour | `flutter-navigation` |
| Providers, controllers, UI state modelling, side effects | `flutter-state-riverpod` |
| Dio, API contracts, repository shape, DTO/entity split, cache, sync, secure storage | `flutter-data-layer` |
| Anything under `lib/core/database/` or a `data/` folder — `.drift` schema and queries, indexes, migrations, DAOs, transactions, stream invalidation — and reviewing a database PR | `flutter-drift` |
| Building one feature end to end | `flutter-feature-slice` |
| Any kind of test | `flutter-testing` |
| Security, performance, logging, analytics, CI/CD, release, post-release | `flutter-ship` |

When a task spans several rows — which most real tasks do — `flutter-feature-slice`
is usually the right entry point; it pulls in the others in the right order.

**Before building a feature, read the two that went first.** Deck and Card are
the worked examples: `lib/features/deck/` and `lib/features/card/` are the
slices, and `flutter-feature-slice` states the method they follow. Take the
**method** from them — layering, where a rule is enforced, what a use case may
know, which test sits at which level — and not the business. Neither feature's
data shape is a template: a third feature that grows a tree or a
`content_type` because Deck has one has copied the wrong half.

## The order of work is a dependency graph, not a suggestion

The recommended order is:

```
business requirements → use cases + business rules → WBS → project foundation
→ architecture boundaries → theme & tokens → minimal shared components → router
→ database/network foundation → features as vertical slices → automated tests
→ pixel comparison → CI/CD → internal testing → production release → monitoring
```

The expensive mistakes this ordering prevents are specific, and worth naming so
you can recognise when someone is about to make one:

- **UI before business rules are settled.** The screens get built around an
  assumption, the rule lands differently, and the state model has to be redone.
  If the rules for a flow are still open, build something else.
- **Features before tokens and the router.** Every feature then hardcodes colours
  and navigation, and you pay to unpick it in every file.
- **Shared components before two real callers exist.** A component abstracted from
  one usage is a guess. Wait for the second caller — it tells you what actually
  varies. Two similar-looking widgets is not a reason to merge them.
- **Tests deferred to "after the feature works".** They then get written against
  whatever the code happens to do, which is not the same as what it should do.

If asked to jump ahead, do not silently refuse and do not silently comply. Say
which prerequisite is open, what the concrete risk is, and offer the smallest
unblocking step. If the user confirms after hearing that, proceed — it is their
call, and a documented deliberate shortcut is fine. Note it in the WBS.

## Definition of Done

Read `references/definition-of-done.md` before marking anything complete. The
mechanical half is automated:

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

That runs the full mechanical gate — codegen freshness, format, analyze, tests, the architecture boundary check, the code-verification guard and the docs guard (see the script header for the exact list). It cannot
judge whether the acceptance criteria are met, whether the UI matches the design,
or whether the WBS entry is honest — that part is on you, and it is the half
that actually catches problems.

## Keeping the ledger honest

Update `docs/wbs_BE.md` or `docs/wbs_FE.md` in the same commit as the work it
describes, and a screen's row in the screen handoff index when the screen is
built. Mark items done only when they are done by the Definition of Done, not
when the code first runs. If something was descoped or deferred, write that down
with the reason — a future session reading "done" on a half-finished item will
build on sand.
````

- [ ] **Step 4: Remove the phase index; the Definition of Done without Widgetbook**

Run:

```bash
git rm -q .claude/skills/flutter-workflow/references/phase-index.md
```

In `.claude/skills/flutter-workflow/references/definition-of-done.md`:

Replace

```markdown
- [ ] No user-visible string outside the ARB files.
- [ ] Registered in the Widgetbook catalog (`widgetbook/`): a new shared
      component gets a knob-driven playground; a new screen gets a use-case
      mounting it with its domain contract faked, states reachable via knobs.
      The catalog is where a human inspects the UI under both themes, text
      scales and viewports without hunting through the app — a screen missing
      from it is invisible to that review.

## Paperwork
- [ ] `docs/wbs.md` updated in this commit.
- [ ] Any doc the change invalidates (data model, API spec, design system) updated
```

with

```markdown
- [ ] No user-visible string outside the ARB files.

## Paperwork
- [ ] `docs/wbs_BE.md` or `docs/wbs_FE.md` updated in this commit; for a screen,
      its row in the screen handoff index too.
- [ ] Any doc the change invalidates (data model, API spec, design system) updated
```

- [ ] **Step 5: State the scripts' reasons without V7's history**

Only `check_flutter_version.sh` carries a marker; the other three are the V7 history
BE-D7's row names (Clarification 4).

In `.claude/skills/flutter-workflow/scripts/check_flutter_version.sh`:

Replace

```bash
#
# **The debt this closes was recorded at M2.2 and had already happened once:**
# M2.1 ran on 3.44.8, the next session started on 3.44.6, and nothing noticed.
# `.fvmrc` declared a version that nothing enforced, so it was documentation
# rather than a pin.
#
```

with

```bash
#
# **Why:** a session can start on a different Flutter than the last one, and
# nothing else would notice. `.fvmrc` declares a version; without this check it
# is documentation rather than a pin.
#
```

Replace

```bash
# runner cannot drift. The half left open was the developer machine, which is
# where the drift actually happened.
#
```

with

```bash
# runner cannot drift. The half left open was the developer machine, which is
# where drift happens.
#
```

Replace

```bash

  This is the failure M2.2 recorded: a session ran 3.44.8, the next started on
  3.44.6, and nothing said so. Generated code, analyzer output and golden
  rasterisation all move between versions, so a green gate on the wrong SDK is
  a green gate about a different project.

```

with

```bash

  Generated code, analyzer output and golden rasterisation all move between
  versions, so a green gate on the wrong SDK is a green gate about a different
  project.

```

Replace the whole of `.claude/skills/flutter-workflow/scripts/check_format.sh` with:

```bash
#!/usr/bin/env bash
# The one definition of *what the formatter looks at*, so the local gate and CI
# cannot disagree about it.
#
# **Why not `dart format .`.** Work on this repo runs in worktrees under
# `.claude/worktrees/`, which are checkouts of this same repository on other
# branches. `.` would hand the formatter another branch's source, so code that
# is not in the working tree could turn the gate red, and it would walk into
# those worktrees' `build/` output, where Gradle deletes directories while they
# are being listed (`PathNotFoundException: Directory listing failed`).
#
# `git ls-files` answers exactly the right question — which Dart files does
# *this* working tree track — and answers it again by itself when a new
# top-level directory appears. Untracked build output is not listed, the
# worktrees are excluded already, and nothing is hardcoded to go stale.
#
# Cut to the first path segment so the formatter gets a handful of directories
# rather than six hundred paths, which on Windows is the difference between one
# process and "The command line is too long".
#
# **CI runs this too, and that is the point of the file.** A fresh clone has no
# worktrees, so CI could run `dart format .`, but that would be a second
# definition of the same check. One definition, one answer, both callers.
#
# A repo without git is a fresh unpacked archive, which has no worktrees either,
# so `.` is the right fallback there.
#
# Usage: check_format.sh [--fix]
# Exit:  0 formatted, 1 drift found (or a write failed under --fix).
set -uo pipefail

roots() {
  if ! command -v git >/dev/null 2>&1; then
    echo "."

    return
  fi

  local found
  found=$(git ls-files '*.dart' | cut -d/ -f1 | sort -u | tr '\n' ' ')
  echo "${found:-.}"
}

if ! command -v dart >/dev/null 2>&1; then
  echo "dart not found on PATH — the format gate cannot run here."
  exit 1
fi

# shellcheck disable=SC2046  # word splitting is the point: one argument per root
if [[ "${1:-}" == "--fix" ]]; then
  exec dart format $(roots)
fi

# shellcheck disable=SC2046
exec dart format --output=none --set-exit-if-changed $(roots)
```

In `.claude/skills/flutter-workflow/scripts/check_generated.py`:

Replace

```python

**Why Python.** Checks 1–3 are unchanged; check 3 (the rebuild) still shells out
to `dart`. The bash version's part-directive scan grepped every source file in a
loop — ~135 forks — and on Windows git-bash the `--skip-rebuild` path took 52
seconds. This reads each source once, in one process. The `.sh` beside it is a
thin wrapper so every caller keeps working.

```

with

```python

**Why Python.** It reads each source once, in one process, instead of forking a
grep per file, which is slow on Windows git-bash. Check 4 (the rebuild) shells
out to `dart`. The `.sh` beside it is a thin wrapper so every caller keeps
working.

```

Replace the whole of `.claude/skills/flutter-workflow/scripts/check_generated.sh` with:

```bash
#!/usr/bin/env bash
# Thin wrapper. The check itself is `check_generated.py`, which reads every
# source once, in one process. The clean-rebuild path (no --skip-rebuild) shells
# out to `dart run build_runner`, with a try/finally that regenerates a usable
# tree if an interrupted rebuild leaves it half-deleted. Kept as `.sh` so every
# caller keeps working.
#
# Usage: check_generated.sh [--skip-rebuild]
# Exit:  0 clean, 1 problems found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$here/check_generated.py" "$@"
```

- [ ] **Step 6: Run the contract test**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 4 tests` and `OK`.

- [ ] **Step 7: Stage the task's files**

The deletions are staged already, by `git rm`. The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-workflow/SKILL.md \
  .claude/skills/flutter-workflow/references/definition-of-done.md \
  .claude/skills/flutter-workflow/scripts/check_flutter_version.sh \
  .claude/skills/flutter-workflow/scripts/check_format.sh \
  .claude/skills/flutter-workflow/scripts/check_generated.py \
  .claude/skills/flutter-workflow/scripts/check_generated.sh \
  .claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 71 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
docs(skills): flutter-workflow routes by topic and reads V8's ledger (BE-D7)

The workflow skill started work "on memox-v7", routed by V7's 22-phase
checklist (docs/checklist.md, the phase column, references/phase-index.md)
and kept its ledger in V7's docs/wbs.md. It now routes by topic and reads
docs/wbs_BE.md, docs/wbs_FE.md and the screen handoff index;
phase-index.md goes. The Definition of Done loses its Widgetbook item: the
golden-parity item beside it is V8's check. The gate scripts state their
reasons without V7's milestones.

A contract test pins that no repo-owned skill names V7, cites a V7
decision, rule, milestone, checklist phase or document, or asks for
Widgetbook. It scans flutter-workflow; each later task adds the skills it
cleans.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: feature-slice, design-system and architecture cite V8

**Files:**
- Modify: `.claude/skills/flutter-architecture/SKILL.md`, `.claude/skills/flutter-architecture/references/analysis_options.yaml`, `.claude/skills/flutter-architecture/scripts/check_architecture.py`, `.claude/skills/flutter-design-system/SKILL.md`, `.claude/skills/flutter-design-system/references/components.md`, `.claude/skills/flutter-feature-slice/SKILL.md`, `.claude/skills/flutter-feature-slice/assets/feature_checklist.md`, `lib/features/card/presentation/controllers/card_actions_controller.dart`, `lib/features/deck/presentation/controllers/deck_actions_controller.dart`, `test/architecture/boundary_rules.dart`, `test/architecture/boundary_rules_test.dart`, `test/features/card/domain/card_write_use_cases_test.dart`, `test/features/deck/domain/deck_write_use_cases_test.dart`, `test/features/trash/domain/trash_use_cases_test.dart`
- Delete: `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`

**Interfaces:**
- Consumes: Task 1's `REPO_OWNED_SKILLS` and `V7_MARKERS`.
- Produces: three more skills in the list, and the marker `docs/api-spec\.md`.

Spec §4.1, §4.3 (`flutter-feature-slice`, `flutter-design-system`,
`flutter-architecture`), D4, D7; §12.2's eight lines; Clarifications 1, 4 and 6.

- [ ] **Step 1: Add the three skills to the contract test**

In `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`:

Replace

```python
REPO_OWNED_SKILLS = (
    "flutter-workflow",
```

with

```python
REPO_OWNED_SKILLS = (
    "flutter-architecture",
    "flutter-design-system",
    "flutter-feature-slice",
    "flutter-workflow",
```

Replace

```python
    r"docs/architecture\.md",
    r"(?i)widgetbook",
```

with

```python
    r"docs/architecture\.md",
    r"docs/api-spec\.md",
    r"(?i)widgetbook",
```

Replace

```python
            "write it in docs/architecture.md",
            "registered in the Widgetbook catalog",
```

with

```python
            "write it in docs/architecture.md",
            "endpoints in docs/api-spec.md",
            "registered in the Widgetbook catalog",
```

- [ ] **Step 2: Run it to see it fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 4 tests` and `FAILED (failures=1)`: 68 lines in eight files, 28 of them in
`feature_blueprint.md` and 15 in the feature-slice `SKILL.md`, the first
`.claude/skills/flutter-architecture/SKILL.md:3: description: …`.

- [ ] **Step 3: Replace the blueprint with the method in flutter-feature-slice**

Run:

```bash
git rm -q .claude/skills/flutter-feature-slice/assets/feature_blueprint.md
```

Replace the whole of `.claude/skills/flutter-feature-slice/SKILL.md` with:

````markdown
---
name: flutter-feature-slice
description: Use when a request asks to build, add, implement or finish a feature or screen in this Flutter app — "add login", "build the deck list", "implement search", "finish the profile screen" — and when a coding task turns out to rest on a missing use case, an undefined state, or an unagreed API contract. It is the usual entry point for feature work.
---

# Building a feature as a vertical slice

This is the loop you run for every feature, and it composes the other skills
rather than repeating them.

**Vertical slice means: database to screen, one feature at a time.** One feature
working end to end proves the architecture and surfaces integration problems
while they are still cheap. Four features each half-built prove nothing and hide
the same problems until they are expensive.

## Step 0 — Pre-flight, before writing any code

Do not skip this because the feature "seems obvious". Every item here that turns
out to be open becomes rework, and the rework is always larger than the check.

- [ ] **Use case approved** — exists in `docs/features/<feature>/usecases/` with main,
      alternative and error flows.
- [ ] **Business rules clear** — the `BR-xx` rules this feature enforces are
      written, and validation rules have their exact user-facing messages.
- [ ] **Design available** — or an explicit agreement to use existing components
      with no new visual design.
- [ ] **State matrix decided** — which of initial / loading / loaded / empty /
      error / refreshing / submitting occur, and what each shows.
- [ ] **API contract known** — N/A until the slice calls the API (ADR-012).
      When it does: endpoints, shapes, error format and pagination in
      `docs/features/<feature>/api.md` first, and build against a fake
      implementing the same interface.
- [ ] **Data model known** — entities, tables, whether a migration is needed.
- [ ] **Acceptance criteria written** in the WBS entry, checkable by someone
      else.
- [ ] **Dependencies identified** — which features or shared components this
      needs, and whether they exist yet.

If something is missing, stop and get it. Load `flutter-product-spec` if the
gap is a use case or business rule. Report which item is open and what you need
— building on an assumption and being wrong costs far more than asking.

The exception worth naming: if the user has heard the gap and says build it
anyway, build it. State the assumption you are proceeding on, record it in the
WBS entry, and continue with the full scope.

## Step 1 — Domain

Layer rules: `flutter-architecture`. No Flutter, no Dio, no Drift here.

```
features/<feature>/domain/
├── entities/       <name>_entity.dart
├── repositories/   <name>_repository.dart          # abstract contract
├── models/         <name>_model.dart               # read model / value object / enum
├── usecases/       <verb>_<noun>_use_case.dart     # one per UI interaction (ADR-011 D4)
└── failures/       <name>_failure.dart             # the feature's rejection enum
```

**The folder does not replace the suffix.** `entities/deck_entity.dart`, not
`entities/deck.dart`: the role is carried by the *file name*, which
`memox.naming.domain_file_role_suffix` enforces and which several guard scopes
select on. `check_architecture.py` additionally pairs each folder with its
required suffix. The authority on layout is ADR-011
(`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`), and this block is a
summary of it. `lib/features/deck/` and `lib/features/card/` are the worked
examples.

- Entities are immutable, with value equality, in domain language. Entity state
  is the enum or sealed class from `docs/features/<feature>/data.md` (state
  machines), so illegal states
  are unrepresentable rather than merely unlikely.
- The repository contract is written from what presentation needs, not from what
  the API happens to offer. If the API needs three calls for one screen, the
  contract still has one method and the implementation makes three.
- Business validation belongs here — it is the same regardless of UI, and here
  it can be unit-tested without a widget or a server.
- **One use case per interaction** (ADR-011 D4). It takes the repository
  *contract*, never an implementation, and it is where the input validation
  lives — a controller that validates and a repository that validates the same
  rule again is the shape this replaced.
- **A rule that needs the tree as it stands at the moment of writing stays in the
  repository**, inside `runInTransaction`. Depth limits, content locks, emptiness
  checks, subtree moves. A use case above the repository would put the check
  outside the transaction, which is a race between the check and the write.
- **A pass-through use case with optional parameters must forward every one of
  them, and gets a test proving it.** Optional params have defaults, so a
  dropped `sort:` or `searchTerm:` compiles clean and analyzes clean — the
  card list shipped exactly this ("Showing 3 of 1", inert sort control) and
  only end-to-end runs caught it. The lock is cheap: a fake repository that
  records every parameter it receives, one assert per param
  (`watch_card_list_items_use_case_test.dart` is the template).

## Step 2 — Data

Details: `flutter-data-layer`.

```
features/<feature>/data/
├── repositories/   <name>_repository_impl.dart
├── mappers/        <name>_mapper.dart              # Row → Entity, AggregateResult → ReadModel
├── datasources/    <name>_dao.dart
└── models/         <name>_model.dart               # DTOs, with the first wire format
```

`models/` does not exist yet: **there is no DTO layer**, and a folder appears
with its first real file (ADR-011 D1). DTOs are the wire format, and no feature
calls the API yet: they arrive with the first call, as `json_serializable`
classes, never Freezed (ADR-012). Until then Drift's generated row is the only
data shape a feature has besides its entity.

Order: the DAO first, then the mapper, then the repository. The repository is
where Drift exceptions become `Failure`s — nowhere else. **There is no cache
policy to apply.** Reads come from `watch()` streams straight off the table:
Drift is the app's durable store, not a cache in front of the server, so a
cache layer here would be a guess at a requirement that does not exist. Nor is
sync built per feature: once it lands, a repository writes its row and one
`sync_outbox` row in the same transaction, and one app-wide `SyncCoordinator`
pushes and pulls (ADR-013). Neither exists yet.

SQL goes in `.drift` files under `lib/core/database/` so `drift_dev` type-checks
it at build time. No business SQL in Dart. Multi-step writes run inside
`dao.runInTransaction`, and every guard that can refuse runs *before* the first
mutation.

## Step 3 — Presentation

Details: `flutter-state-riverpod` for state, `flutter-design-system` for UI,
`flutter-navigation` for routes.

```
features/<feature>/presentation/
├── screens/        <name>_screen.dart
├── controllers/    <name>_controller.dart
├── states/         <name>_state.dart
├── widgets/        <section>_widget.dart
└── providers/      # only when a provider is not a controller
```

MX-VIS-001 derives each screen's required audit path by stripping **only** the
`presentation` segment, so the `screens/` folder is preserved in the companion
path: `test/visual_audit/screens/features/<f>/screens/<name>_visual_audit_test.dart`.
A file holding a provider must still be named `_controller.dart`, not
`_provider.dart` — the guard's widget scopes forbid
`ref.watch(...RepositoryProvider)` and exempt controllers by that suffix, which is
where that read belongs.

Build state and controller before the screen. Writing the state model first
forces the state matrix to be real, and the screen then becomes a rendering of
something already decided rather than the place where the decisions get made
implicitly.

While building the screen:

- Use existing components and tokens. Do not invent visual design mid-feature —
  if the design is genuinely missing, raise it rather than improvising, because
  an improvised variant becomes another thing to reconcile later.
- Do not create a shared component for this feature's first use. Build it
  locally; promote it to `shared/` when a second real caller appears and shows
  you what actually varies.
- Split the screen into section widgets — separate classes, not `_buildX()`
  methods.
- **Render every state in the matrix.** Empty is the one that gets skipped, and
  it is the first thing a new user sees.
- Check dark mode, a 320px screen, 2.0× text scale, and keyboard-open before
  calling the screen done — not in a later pass, when fixing it means
  restructuring.

## Step 4 — Tests

Details: `flutter-testing`.

Minimum for a feature to be done:

- [ ] Unit tests for domain logic and validation, including the rule violations.
      Pure input/output — no database, no widget.
- [ ] Repository tests against **real in-memory SQLite**, not a mocked executor.
      What is in doubt is the SQL: the cascade, the transaction rollback, the NULL
      semantics of a predicate. A mocked data source would only prove the code
      calls the API it was written to call, which is the one thing nobody doubts.
      Use `test/support/test_database.dart` and a per-feature harness.
      There is no cache fallback to cover — see Step 2.
- [ ] Mapper tests, including a null field and an unknown enum value.
- [ ] Controller tests: initial state, loading→loaded, loading→error, refresh,
      submit success, submit failure, duplicate submit.
- [ ] Widget tests for the states that matter — at least loaded, empty, error —
      against a **fake of the domain contract**, not a real database. Driving Drift
      from a widget test leaves its stream-notification timer pending at teardown
      and `flutter_test` fails the test for that rather than for the behaviour.
- [ ] Route tests through the real router: cold start, deep link, back, and the
      branch state if the route sits in the navigation shell.
- [ ] A strict visual audit companion per production screen (MX-VIS-001), one
      call per state, PASS in light and dark.
- [ ] Golden tests if this feature added a shared component.
- [ ] Each golden compared, state by state, with the screen in the kit (the
      Definition of Done's UI section): the machine checks catch overlap and
      contrast; this is where a person *looks*.

`test/features/deck/` and `test/features/card/` show which test sits at which
level, and their size is a reference for a slice of that weight.

## Step 5 — Close it out

- [ ] `.claude/skills/flutter-workflow/scripts/dod_check.sh` passes.
- [ ] `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean
      (`flutter analyze` does not cover the Riverpod and layering rules).
- [ ] `docs/wbs_BE.md` or `docs/wbs_FE.md` updated in this commit — status, and
      anything descoped with the reason; for a screen, its row in the screen
      handoff index.
- [ ] Docs the feature changed (data model, API spec, architecture decisions)
      updated in the same commit.
- [ ] Full Definition of Done reviewed:
      `.claude/skills/flutter-workflow/references/definition-of-done.md`.
- [ ] Conventional commit scoped to the feature: `feat(<feature>): ...`.

`assets/feature_checklist.md` is a copy-paste version of all of the above to
paste into a WBS entry or PR description.

## What does not transfer from Deck and Card

Deck and Card are worked examples of the **method**, not templates for the
data. Everything below exists in one of them **because that feature's business
asked for it**; a new feature that acquires one without its own reason has been
scaffolded, not designed.

| Belongs to | What it is | Why it is not yours |
|---|---|---|
| Deck | The recursive tree (`parent_id`, `root_id`) | A feature whose objects do not *contain* other objects of the same kind has no tree. Most do not. |
| Deck | The content type a deck settles on its first child | A business rule of Deck (ADR-006), not a pattern. |
| Deck | The scheduler on the root deck and its lock | Study's business (ADR-003, ADR-004). It reaches Deck only because a deck is what gets studied. |
| Deck | `DeckRejection` and its values | The *idea* — a refusal carries its reason as a value (ADR-011 D6) — transfers. The values do not. |
| Card | Tags, the flag and the optional detail fields | Card content. A tag table is not a layer. |
| Card | The card statuses derived at read time | Derived-not-stored is decided per feature; *these statuses* answer Card's. |
| Both | The literal folder contents | The buckets are fixed (ADR-011 D8); which of them a feature fills is decided by what it renders. An empty bucket is not a gap. |

**The test to apply instead of copying.** For each thing you are about to bring
across, ask: *"if I delete this, does my feature stop being correct, or does it
stop resembling Deck?"* Only the first is a reason to keep it.

**Where Deck and Card disagree, the disagreement is the answer.** Two examples
exist so the method can be told apart from one feature's habits — a single
example cannot distinguish "this is the rule" from "this is how that one was
built".

## The failure modes this ordering prevents

- **Screen first, then data.** The state model ends up shaped by widget
  convenience, and the error states never appear because the fake never failed.
- **All features' domains, then all their data.** Nothing is demonstrable, and
  the first integration reveals problems in every feature at once.
- **Tests last, after the demo.** They get written to match what the code does,
  which is not the same as what the acceptance criteria say.
- **Promoting a component on first use.** The abstraction is a guess; the second
  caller then needs a parameter, and the third needs a flag that changes the
  layout.
````

In `.claude/skills/flutter-feature-slice/assets/feature_checklist.md`:

Replace

```markdown
- [ ] State matrix decided (initial / loading / loaded / empty / error / refreshing / submitting)
- [ ] API contract in `docs/api-spec.md`
- [ ] Data model and migration need known
```

with

```markdown
- [ ] State matrix decided (initial / loading / loaded / empty / error / refreshing / submitting)
- [ ] API contract in `docs/features/<feature>/api.md`, when the slice calls
      the API (ADR-012)
- [ ] Data model and migration need known
```

Replace

```markdown

## Layout (AD-12, AD-13)
- [ ] `domain/{entities,repositories,models,usecases,failures}/`
```

with

```markdown

## Layout (ADR-011)
- [ ] `domain/{entities,repositories,models,usecases,failures}/`
```

Replace

```markdown
- [ ] Exceptions mapped to `Failure` at the repository boundary
- [ ] Cache / sync policy applied per `docs/architecture.md`
- [ ] Migration written and tested if the schema changed
```

with

```markdown
- [ ] Exceptions mapped to `Failure` at the repository boundary
- [ ] Cache / sync policy applied per its ADR in `docs/shared/decisions/`
- [ ] Migration written and tested if the schema changed
```

Replace

```markdown
- [ ] Golden: any new shared component, light and dark
- [ ] Widgetbook: new screen mounted as a use-case with faked contract and
      state knobs; new shared component as a knob playground (`widgetbook/`)
- [ ] **Every new guard or architecture test fault-injected**: create the
```

with

```markdown
- [ ] Golden: any new shared component, light and dark
- [ ] Golden compared, state by state, with the screen in the kit
- [ ] **Every new guard or architecture test fault-injected**: create the
```

Replace

```markdown
- [ ] `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean
- [ ] `docs/wbs.md` updated in this commit
- [ ] Affected docs updated in this commit
```

with

```markdown
- [ ] `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean
- [ ] `docs/wbs_BE.md` or `docs/wbs_FE.md` updated in this commit; for a screen,
      its row in the screen handoff index
- [ ] Affected docs updated in this commit
```

- [ ] **Step 4: Point flutter-design-system at the goldens**

In `.claude/skills/flutter-design-system/SKILL.md`:

Replace

```markdown
name: flutter-design-system
description: Design tokens, Material 3 theming, the shared component library, responsive layout, localization and accessibility for this Flutter app. Use this skill whenever UI is being built or reviewed — creating or changing a widget, picking a colour/spacing/text style, adding a shared component, wiring light and dark themes, handling small screens or large text scale, adding user-facing strings or ARB entries, or checking semantic labels and contrast. Also use it when reviewing UI code for hardcoded colours, hardcoded padding, or untranslated strings, which are the most common violations in this codebase. Covers checklist phases 7, 12 and 13.
---
```

with

```markdown
name: flutter-design-system
description: Design tokens, Material 3 theming, the shared component library, responsive layout, localization and accessibility for this Flutter app. Use this skill whenever UI is being built or reviewed — creating or changing a widget, picking a colour/spacing/text style, adding a shared component, wiring light and dark themes, handling small screens or large text scale, adding user-facing strings or ARB entries, or checking semantic labels and contrast. Also use it when reviewing UI code for hardcoded colours, hardcoded padding, or untranslated strings, which are the most common violations in this codebase.
---
```

Replace

```markdown
# Design system, localization and accessibility

Covers checklist Phases 7 (tokens, theme, components, responsive), 12
(localization) and 13 (accessibility).

```

with

```markdown
# Design system, localization and accessibility

```

Replace

```markdown

A new shared component is not done until it has a knob-driven playground in the
Widgetbook catalog (`widgetbook/lib/components/`, registered in
`widgetbook/lib/main.dart`) — the catalog is where every state is inspected
under both themes, text scales and viewports without hunting through screens,
and the CI smoke test fails if the tree stops building. New screens go in too,
mounted with their domain contract faked; `widgetbook/README.md` has the
how-to.

```

with

```markdown

A new shared component is not done until its goldens cover every state under
both themes (`test/shared/widgets/goldens/`, per `flutter-testing`) and each is
compared with the component in the kit.

```

In `.claude/skills/flutter-design-system/references/components.md`:

Replace

```markdown
- [ ] Long text truncates or wraps deliberately, not by accident.
- [ ] Golden test for light and dark (Phase 15.4).

```

with

```markdown
- [ ] Long text truncates or wraps deliberately, not by accident.
- [ ] Golden test for light and dark (`flutter-testing`).

```

Replace

```markdown
part of the parent's build, so it rebuilds whenever the parent does and can never
be `const`. Separate classes give narrower rebuild scopes for free — the same
point Phase 17 makes about limiting rebuild range.
```

with

```markdown
part of the parent's build, so it rebuilds whenever the parent does and can never
be `const`. Separate classes give narrower rebuild scopes for free.
```

- [ ] **Step 5: Cite ADR-011 in flutter-architecture**

In `.claude/skills/flutter-architecture/SKILL.md`:

Replace

```markdown
name: flutter-architecture
description: The layering and code-style rules for this Flutter codebase — feature-first folder structure, what each layer may import, when a use case or an interface is actually worth creating, the analysis_options.yaml lint configuration, guard-clause control flow, banning magic values, and file/class naming conventions. Use this skill when creating a new feature folder, deciding where a file belongs, reviewing whether code respects layer boundaries, configuring or tightening lints, resolving an import that feels wrong, or when tempted to add an abstraction. Also use it before any code review or commit that adds new files. Covers checklist phases 4 and 5, and it ships `scripts/check_architecture.sh` to verify the boundaries mechanically.
---
```

with

```markdown
name: flutter-architecture
description: The layering and code-style rules for this Flutter codebase — feature-first folder structure, what each layer may import, when a use case or an interface is actually worth creating, the analysis_options.yaml lint configuration, guard-clause control flow, banning magic values, and file/class naming conventions. Use this skill when creating a new feature folder, deciding where a file belongs, reviewing whether code respects layer boundaries, configuring or tightening lints, resolving an import that feels wrong, or when tempted to add an abstraction. Also use it before any code review or commit that adds new files. It ships `scripts/check_architecture.sh` to verify the boundaries mechanically.
---
```

Replace

```markdown
# Architecture and code conventions

Covers checklist Phases 4 (structure, dependency rules) and 5 (lint, code style,
naming).

```

with

```markdown
# Architecture and code conventions

```

Replace

```markdown
    └── presentation/         # screens/ controllers/ states/ providers/
        └── widgets/          # exactly four buckets, one level deep (AD-15):
                              #   sections/ items/ overlays/ support/
```

with

```markdown
    └── presentation/         # screens/ controllers/ states/ providers/
        └── widgets/          # exactly four buckets, one level deep (ADR-011 D8):
                              #   sections/ items/ overlays/ support/
```

Replace

```markdown
| `domain/failures/` | `_failure` | the feature's rejection-reason enum |
| `domain/usecases/` | `_use_case` | one per UI interaction (AD-12) |
| `data/datasources/` | `_dao`, `_data_source` | a DAO per bounded context |
```

with

```markdown
| `domain/failures/` | `_failure` | the feature's rejection-reason enum |
| `domain/usecases/` | `_use_case` | one per UI interaction (ADR-011 D4) |
| `data/datasources/` | `_dao`, `_data_source` | a DAO per bounded context |
```

Replace

```markdown
| `data/repositories/` | `_repository_impl` | contract implementations; every write in one transaction |
| `data/models/` | `_model` | DTOs; none while the app is local-only (ADR-001) |
| `di/` | `_provider` | repository providers; each constructs its implementation |
```

with

```markdown
| `data/repositories/` | `_repository_impl` | contract implementations; every write in one transaction |
| `data/models/` | `_model` | DTOs, `json_serializable`; none until the first API call (ADR-012) |
| `di/` | `_provider` | repository providers; each constructs its implementation |
```

Replace

```markdown
it needs. The folder never replaces the suffix: `entities/deck_entity.dart`, not
`entities/deck.dart`. These wait for an ADR that opens the need:
`core/network/`, `core/storage/`, `core/utils/`, `app/config/` and flavors,
`app/di/`, `shared/models/`, `shared/extensions/`.

**Placing a widget** is four questions asked in order, stopping at the first
yes (AD-15, ratified for V8 by ADR-011 D8):

```

with

```markdown
it needs. The folder never replaces the suffix: `entities/deck_entity.dart`, not
`entities/deck.dart`. `core/network/` comes with the first API call, holding
the one shared Dio client (ADR-012). These wait for an ADR that opens the need:
`core/storage/`, `core/utils/`, `app/config/` and flavors, `app/di/`,
`shared/models/`, `shared/extensions/`.

**Placing a widget** is four questions asked in order, stopping at the first
yes (ADR-011 D8):

```

Replace

```markdown
  interaction it triggers, read or write, goes through exactly one use case
  (AD-12, ADR-011 D4–D5): never to a DAO, never to Drift.
- **Between features**, a file may import another feature's
```

with

```markdown
  interaction it triggers, read or write, goes through exactly one use case
  (ADR-011 D4–D5): never to a DAO, never to Drift.
- **Between features**, a file may import another feature's
```

Replace

```markdown
- **A layer appears with its first real file, and a feature with a screen has
  one use case per interaction** (AD-12, ratified by ADR-011 D4). A feature with
  no screen has no `presentation/` and no `domain/usecases/`; nothing is
```

with

```markdown
- **A layer appears with its first real file, and a feature with a screen has
  one use case per interaction** (ADR-011 D4). A feature with
  no screen has no `presentation/` and no `domain/usecases/`; nothing is
```

Replace

```markdown

`references/analysis_options.yaml` is the configuration to copy into the project
root. It turns on `strict-casts`, `strict-inference`, `strict-raw-types`, and
promotes the rules that matter to `error`.

It deliberately does **not** declare a `custom_lint` plugin. `custom_lint` and
`riverpod_lint` are descoped — see `Deferred and descoped` in `docs/wbs.md`. Do
not add the block back: a plugin declared but not installed is silently ignored,
so the rules look configured and never run.

```

with

```markdown

The root `analysis_options.yaml` is what `flutter analyze` runs: the three
`strict-*` modes (`strict-casts`, `strict-inference`, `strict-raw-types`) over
`flutter_lints`, and a few rules. `references/analysis_options.yaml` is a
stricter set that the root has not adopted: it enables more lints and promotes
the ones that matter to `error`.

It deliberately does **not** declare a `custom_lint` plugin. `custom_lint` and
`riverpod_lint` are descoped: no published `custom_lint` supports
`analyzer >=10`, which the generator stack requires. Do not add the block back:
a plugin declared but not installed is silently ignored, so the rules look
configured and never run.

```

In `.claude/skills/flutter-architecture/references/analysis_options.yaml`:

Replace

```yaml
# Copy to the project root as analysis_options.yaml.
# This file and the root copy are kept identical apart from these two lines.
#
```

with

```yaml
# A stricter configuration than the one the project runs. The root
# analysis_options.yaml is what `flutter analyze` reads, and it is smaller: the
# three strict-* modes over flutter_lints and a few rules.
#
```

Replace

```yaml
#   2. There is deliberately NO `plugins: - custom_lint` block. custom_lint and
#      riverpod_lint are descoped (see `Deferred and descoped` in docs/wbs.md):
#      no published custom_lint supports analyzer >=10, which the generator
#      stack requires. Do not add it back — a plugin declared but not installed
#      is silently ignored, which is worse than not configuring it, because the
#      rules look active and never run. Those checks now belong to
#      code-verification-guard:
#      `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
```

with

```yaml
#   2. There is deliberately NO `plugins: - custom_lint` block. custom_lint and
#      riverpod_lint are descoped: no published custom_lint supports analyzer
#      >=10, which the generator stack requires. Do not add it back — a plugin
#      declared but not installed is silently ignored, which is worse than not
#      configuring it, because the rules look active and never run. Those checks
#      now belong to code-verification-guard:
#      `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
```

In `.claude/skills/flutter-architecture/scripts/check_architecture.py`:

Replace

```python

**Why Python and not the bash it replaced.** The rules are unchanged; the shape
of the runtime is not. The bash version forked `find lib` seventeen times and a
subprocess per file inside its loops, and on Windows git-bash each fork costs
tens of milliseconds — the whole script took two minutes there while finishing
in a second on Linux CI. This reads every source file once, in one process. The
`.sh` beside it is now a thin wrapper so every `bash …/check_architecture.sh`
caller and every doc that names it still works.

```

with

```python

**Why Python.** It reads every source file once, in one process, instead of
forking a subprocess per file, which is slow on Windows git-bash. The `.sh`
beside it is a thin wrapper so every `bash …/check_architecture.sh` caller and
every doc that names it still works.

```

Replace

```python
    ("/domain/usecases/", ("_use_case.dart",)),
    # CLAUDE.md's domain suffix table also admits _scheduler and _mode, and
    # Study keeps its Strategy files (study_mode.dart, sm2_scheduler.dart, …)
    # under models/ — recorded in wbs.md M-task outputs, the AD-18 dispatch
    # table, and AD-18's boundary section, which all name `domain/models/`.
    ("/domain/models/", ("_model.dart", "_mode.dart", "_scheduler.dart")),
```

with

```python
    ("/domain/usecases/", ("_use_case.dart",)),
    # A pure rule lives in `domain/models/` (ADR-011 D7), and a Strategy file
    # there is named for its role: `_mode` for a study mode, `_scheduler` for
    # a scheduler.
    ("/domain/models/", ("_model.dart", "_mode.dart", "_scheduler.dart")),
```

Replace

```python
            "No lib/ directory and no pubspec.yaml — nothing to check yet\n"
            "(expected before Phase 2.3)."
        )
```

with

```python
            "No lib/ directory and no pubspec.yaml — nothing to check yet\n"
            "(expected before the Flutter project is created)."
        )
```

- [ ] **Step 6: Cite ADR-011 in the eight lines of lib/ and test/**

Comments, one message and one test name: no behaviour changes, and the contract test does
not scan `lib/` or `test/` (Clarification 6).

In `lib/features/card/presentation/controllers/card_actions_controller.dart`:

Replace

```dart
///
/// Each command calls exactly one use case (AD-12) and hands back its result;
/// the widget chooses the feedback. A database `Failure` is thrown through.
@riverpod
```

with

```dart
///
/// Each command calls exactly one use case (ADR-011 D4) and hands back its
/// result; the widget chooses the feedback. A database `Failure` is thrown
/// through.
@riverpod
```

In `lib/features/deck/presentation/controllers/deck_actions_controller.dart`:

Replace

```dart
///
/// Each command calls exactly one use case (AD-12) and hands back its
/// `Outcome`, and the widget chooses the feedback. A database `Failure` is
```

with

```dart
///
/// Each command calls exactly one use case (ADR-011 D4) and hands back its
/// `Outcome`, and the widget chooses the feedback. A database `Failure` is
```

In `test/architecture/boundary_rules.dart`:

Replace

```dart

/// ADR-011 D8 (AD-15): the widget buckets, one level deep.
const _widgetBuckets = {'sections', 'items', 'overlays', 'support'};
```

with

```dart

/// ADR-011 D8: the widget buckets, one level deep.
const _widgetBuckets = {'sections', 'items', 'overlays', 'support'};
```

Replace

```dart
  if (!_widgetBuckets.contains(parts.first)) {
    return 'widgets/${parts.first}/ is not an AD-15 bucket';
  }
```

with

```dart
  if (!_widgetBuckets.contains(parts.first)) {
    return 'widgets/${parts.first}/ is not an ADR-011 D8 bucket';
  }
```

In `test/architecture/boundary_rules_test.dart`:

Replace

```dart

    test('a widget sits one level deep in an AD-15 bucket', () {
      const widgets = 'lib/features/deck/presentation/widgets';
```

with

```dart

    test('a widget sits one level deep in an ADR-011 D8 bucket', () {
      const widgets = 'lib/features/deck/presentation/widgets';
```

In `test/features/card/domain/card_write_use_cases_test.dart`:

Replace

```dart

// The card write use cases forward to one repository call each (AD-12). They
// run here over the real repositories, so the test asserts what a person
// sees, not that a fake was called.
```

with

```dart

// The card write use cases forward to one repository call each (ADR-011 D4).
// They run here over the real repositories, so the test asserts what a person
// sees, not that a fake was called.
```

In `test/features/deck/domain/deck_write_use_cases_test.dart`:

Replace

```dart

// The write use cases forward to one repository call each (AD-12). They are
// exercised here over the real repositories, so the test asserts what a
// person sees in the tree, not that a fake was called.
```

with

```dart

// The write use cases forward to one repository call each (ADR-011 D4). They
// are exercised here over the real repositories, so the test asserts what a
// person sees in the tree, not that a fake was called.
```

In `test/features/trash/domain/trash_use_cases_test.dart`:

Replace

```dart

// The Trash use cases forward to one repository call each (AD-12), over the
// real repositories, so the test asserts what a person sees in the Trash.

```

with

```dart

// The Trash use cases forward to one repository call each (ADR-011 D4), over
// the real repositories, so the test asserts what a person sees in the Trash.

```

- [ ] **Step 7: Run the contract test**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 4 tests` and `OK`.

- [ ] **Step 8: Run the architecture tests**

```bash
flutter test test/architecture/
```

Expected: `+43: All tests passed!`: the renamed test and the boundary rules with their new
message.

- [ ] **Step 9: Stage the task's files**

The deletions are staged already, by `git rm`. The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-architecture/SKILL.md \
  .claude/skills/flutter-architecture/references/analysis_options.yaml \
  .claude/skills/flutter-architecture/scripts/check_architecture.py \
  .claude/skills/flutter-design-system/SKILL.md \
  .claude/skills/flutter-design-system/references/components.md \
  .claude/skills/flutter-feature-slice/SKILL.md \
  .claude/skills/flutter-feature-slice/assets/feature_checklist.md \
  .claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py \
  lib/features/card/presentation/controllers/card_actions_controller.dart \
  lib/features/deck/presentation/controllers/deck_actions_controller.dart \
  test/architecture/boundary_rules.dart \
  test/architecture/boundary_rules_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart \
  test/features/trash/domain/trash_use_cases_test.dart
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 71 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
docs(skills): feature-slice, design-system and architecture cite V8 (BE-D7)

feature_blueprint.md recorded V7's deck and card slices; it goes.
flutter-feature-slice keeps the method, with V8's lib/features/deck and
lib/features/card as its examples and a section on what does not transfer
between them. The three skills cite ADR-011 D4, D7 and D8 in place of V7's
AD-12, AD-15 and AD-18, point at the goldens instead of Widgetbook, and
state in place why custom_lint is descoped. A DTO arrives with the first
API call as a json_serializable class (ADR-012), and sync is not a
feature's to build (ADR-013). The reference analysis_options.yaml no longer
claims to be the root's copy.

The eight lines of lib/ and test/ that cited AD-12 and AD-15, among them
boundary_rules.dart's message, cite ADR-011 D4 and D8. The contract test
now scans the three skills.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: flutter-drift describes V8's database

**Files:**
- Modify: `.claude/skills/flutter-drift/SKILL.md`, `.claude/skills/flutter-drift/references/dynamic-sql-semantics.md`, `.claude/skills/flutter-drift/references/dynamic-sql.md`, `.claude/skills/flutter-drift/references/operations.md`, `.claude/skills/flutter-drift/references/project-baseline.md`, `.claude/skills/flutter-drift/references/review-checklist.md`, `.claude/skills/flutter-drift/references/riverpod-drift.md`, `.claude/skills/flutter-drift/references/schema-conventions.md`, `.claude/skills/flutter-drift/references/testing-database.md`, `.claude/skills/flutter-drift/scripts/check_drift.py`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`

**Interfaces:**
- Consumes: Task 1's `REPO_OWNED_SKILLS`.
- Produces: `flutter-drift` in the list.

Spec §4.1, §4.2, §4.3 (`flutter-drift`), D3; Clarifications 1 and 4.

- [ ] **Step 1: Add flutter-drift to the contract test**

In `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`:

Replace

```python
    "flutter-design-system",
    "flutter-feature-slice",
```

with

```python
    "flutter-design-system",
    "flutter-drift",
    "flutter-feature-slice",
```

- [ ] **Step 2: Run it to see it fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 4 tests` and `FAILED (failures=1)`: 27 lines in ten files, 10 of them in
`project-baseline.md`, the first
`.claude/skills/flutter-drift/SKILL.md:3: description: …`.

- [ ] **Step 3: Rewrite project-baseline.md as V8's baseline**

Every claim was checked against `lib/core/database/`, `docs/shared/data/schema.md` and the
ADRs (spec D3), and the sync section follows ADR-013 (Clarification 1).

Replace the whole of `.claude/skills/flutter-drift/references/project-baseline.md` with:

````markdown
# What V8's database has already settled

Read this before proposing a structural change. Everything below is in the code
today; some of it deliberately differs from generic Drift guidance, and the
difference is a decision, not an oversight. Changing any of it is a task of its
own, with its own WBS entry — never a drive-by inside feature work.

The authority for tables, columns and invariants is
[`docs/shared/data/schema.md`](../../../../docs/shared/data/schema.md); the
decisions behind this file are ADR-001 (the platforms), ADR-002 (sensitive
data, no encryption), ADR-007 (UUID keys), ADR-008 (UTC), ADR-010/ADR-011 (the
layout) and ADR-013 (the server is canonical, Drift is the durable local
store), in `docs/shared/decisions/`. Where this file and `schema.md` differ,
`schema.md` wins.

## The layout

```
lib/core/database/
├── app_database.dart            schemaVersion, migrations, beforeOpen
├── connection.dart              the only file that opens a database (ADR-002)
├── schema_versions.dart         generated step-by-step schemas (drift_schemas/)
├── table_changes.dart           the tables a read watches
├── di/database_provider.dart    @Riverpod(keepAlive: true), closes on dispose
├── tables/                      deck, card, tags, srs, study, settings, trash
└── queries/                     card, deck and trash queries (.drift)

lib/features/<feature>/data/
├── datasources/                 <name>_dao.dart · *_data_source.dart
├── mappers/                     row → entity, one file per shape
└── repositories/                <feature>_repository_impl.dart

drift_schemas/                   drift_schema_v<n>.json, one per released version
test/drift/                      migration_test.dart; generated/ holds the verifier
test/database/                   invariants_test.dart · schema_test.dart
                                 app_settings_row_test.dart · table_changes_test.dart
```

**Tables and queries are central, DAOs are feature-owned** (ADR-010 decision 2,
ADR-011). A generic feature-first checklist will tell you to put a feature's
`.drift` file under `lib/features/<feature>/data/local/`. This project does not,
because the schema is a single interlocking object: `card` references `deck`,
`card_schedule` and `review_log` reference `card`, `study_session` references
both trees, and `delete_batches` owns rows of `deck` and `card`. Splitting the
`.drift` files by feature would put cross-feature foreign keys in whichever
folder won an argument, while the DAO — the part that genuinely belongs to one
feature — is already feature-owned.

## Connection and PRAGMA

- `openAppDatabase()` opens it through `driftDatabase(name: 'memox')` from
  `drift_flutter`, which uses a background isolate on native and the WASM worker
  on web. One call handles both because the Web build is the E2E channel
  (ADR-001) and must genuinely open.
- `PRAGMA foreign_keys = ON` in `beforeOpen`. Without it every
  `ON DELETE CASCADE` in the schema is a comment — SQLite defaults enforcement
  **off per connection**, so deletes would silently orphan rows.
- `beforeOpen` also inserts the one `app_settings` row if it is missing
  (BR-SETTINGS-001), so every surface reads real values from the first open.
- **No WAL, no `busy_timeout`, no read pool, no `synchronous` override.** Not an
  omission: this app has one writer and no read isolates, so the tuning would
  buy nothing measurable and would cost the web build. Add one only with a
  benchmark attached, and put it in `connection.dart` so "which PRAGMAs are set"
  keeps a single answer.
- Nothing in the connection path logs a path, an argument or a row. Card content
  and learning history are sensitive (ADR-002: no content in a log at any
  level); a database log would leak all of it at once.

## Identity, time and enums

| Contract | What this repo does | Why it matters later |
|---|---|---|
| Primary key | `TEXT` UUID, client-generated (ADR-007) | A backend cannot renumber rows a device already created |
| Ownership | nullable `owner_id` on `deck`, `tags` and `delete_batches`; `NULL` until login | Login arrives without a migration; the server takes the owner from its own `CurrentUserProvider`, never from the client (ADR-013) |
| Enums | stable lowercase text codes with a `CHECK` — `eight_box`, `sm2`, `unset`, `card`, `deck`, `learning`, `reviewing` | An ordinal would change meaning the day a value is inserted in the middle |
| Timestamps | `DATETIME` columns holding UTC (ADR-008); **no `build.yaml`**, so Drift's default storage applies | See the warning below |

**The `DATETIME` storage mode is an open contract.** With no `build.yaml`, Drift
stores `DATETIME` as Unix epoch **seconds**. That is workable while everything
is local, and sync (ADR-013) makes it a decision: ISO-8601 text keeps the
offset and debugs easily, epoch integers sort and compare uniformly.
Changing the mode after release is a data migration over every timestamp
column, so **pin the choice before the first sync ships**, not after. Whoever
settles it writes an ADR in `docs/shared/decisions/` and adds the `build.yaml`
option in the same commit as the migration.

## Reads, windows and pagination

- **The card list is a growing window**: the first `windowSize` cards in the
  query's order, re-read whole on every change, with no `OFFSET`
  (`card_list_dao.dart`, UC-CARD-001). An insert above the window cannot
  duplicate or drop a row the way a shifting offset does, and the cost is
  bounded by the window, not the deck. It reads one row past the window to tell
  whether more follow.
- **Keyset pagination where the user seeks deep**: a card's review history pages
  on `(answered_at DESC, id DESC)` after the last row shown (`cardHistoryPage`,
  BR-CARD-015), and library search pages by a cursor (`search_dao.dart`).
  Neither uses `OFFSET`.
- A read that feeds a screen is a `watch()` stream over the tables it names
  (`table_changes.dart`), so a write to any of them emits again.

## Two traps this schema has already paid for

**Resolve the root through `root_id`, never `COALESCE(parent_id, id)`**
(BR-DECK-003). That expression means "my parent, or me if I have none", which is
the correct root only in a one-level tree — from the third level down it
silently returns the level-2 deck. It is dangerous precisely because it works in
every test fixture anyone writes by hand. Every deck carries `root_id`,
including the root itself, so the resolution is a column read rather than a
recursion inside the hottest query in the app. The guard's
`memox.data_model.no_coalesce_parent_id` rule catches the expression.

**Moving a subtree rewrites `root_id` for every node in it, in one
transaction.** Miss a node and it points at the wrong root: queries still run and
merely return less than they should, which is corruption that reports itself as
a missing card rather than as an error. `schema.md` carries the query that
detects it, and `test/database/invariants_test.dart` runs it.

## What this schema does *not* do

Knowing the negatives prevents half of the bad suggestions:

- **Soft delete is a batch, not a flag.** A deck or card in the Trash carries a
  `delete_batch_id` that points at `delete_batches` (BR-TRASH-001); there is no
  `deleted_at`. Every read of active rows filters `delete_batch_id IS NULL`, and
  only a purge deletes a row (BR-TRASH-010).
- **No sync bookkeeping yet.** No `sync_outbox`, no `sync_state`, no
  `server_version` column: ADR-013 adds them in one migration, with the first
  slice that syncs. IDs, timestamps and layer boundaries are already
  sync-shaped, which keeps that migration routine.
- **No encryption.** ADR-002 decides it for now; opening the database in one
  place (`connection.dart`) keeps adding it a change to one function.
- **No `build.yaml`.** Adding one changes code generation for the whole repo —
  treat it as a schema-level decision.
- **No schedule columns in `card`.** Content (`card`), schedule
  (`card_schedule`) and history (`review_log`) are three tables with three
  lifetimes; a due date on `card` would break reset, which starts the schedule
  over and keeps the content (BR-SRS-021). The guard's
  `memox.data_model.no_schedule_columns_on_card_table` rule catches it.

## What "backend-ready" already means here

Sync is decided (ADR-013) and not built. Four things are already shaped for it,
and each one would be expensive to retrofit:

- **IDs are client-generated**, so rows created offline can be referenced
  immediately and never need renumbering.
- **`owner_id` is nullable on user tables**, so login backfills rather than
  migrates.
- **Enum codes are stable text**, so the database, the DTOs and the domain
  share one vocabulary.
- **The migration path is tested from v1** (`test/drift/migration_test.dart`),
  which is what makes adding sync's tables and columns a routine change rather
  than a gamble.

ADR-013 has already made the decisions the schema will carry, once, so no
feature makes them again:

- **A write queues itself.** The row and one `sync_outbox` entry are written in
  the same transaction; the outbox keeps at most one entry per entity, and that
  entry's id is the push's idempotency key, so a retry after an ambiguous
  failure cannot apply the change twice.
- **The server orders conflicts, not a device clock.** Content follows the
  operation the server receives last, the deck tree follows the server's
  invariant checks, and every synced row carries the `server_version` the
  server gave it; last-write-wins keyed on a local `updated_at` is not a policy.
- **Each table has its rule.** `review_log` only grows and never conflicts;
  `card_schedule` is derived, so the app recomputes it after a pull and pushes
  the result, and the server runs no scheduler; the study-session tables and
  the reminder settings stay on the device.

The protocol and the conflict rules by data class are in ADR-013 and its
design, `docs/superpowers/specs/2026-09-27-server-sync-design.md`; the
database's part is only to make those states representable.

## Invariants are executable here

`schema.md` lists the data invariants as queries that must return no row, and
`test/database/invariants_test.dart` runs them against a real SQLite database
seeded with rows that satisfy all of them — no descendant points at the wrong
root, no deck nests deeper than ten levels, no schedule row carries another
scheduler or generation than its root, and so on. They are the reason a schema
change can be trusted beyond the diff.

**A new invariant belongs in `schema.md` and in that test, not in a comment.**
If a change introduces a rule the schema cannot express as a constraint, the
invariant test is where it becomes checkable.
`test/support/invariant_queries.dart` reads the queries out of `schema.md`
itself, so there is no copy to keep in step.
````

- [ ] **Step 4: Cite V8 in the skill, its references and check_drift.py**

In `.claude/skills/flutter-drift/SKILL.md`:

Replace

```markdown
name: flutter-drift
description: Use when a task touches the database in any way — adding or changing a table, column, constraint or index; writing or editing a `.drift` query; bumping `schemaVersion` or writing a migration; adding a DAO or local data source; debugging a Drift stream that will not re-emit, a slow query, a locked database or a failing migration test; and above all when reviewing a pull request that changes anything under `lib/core/database/` or any `data/` folder. Reach for it even when the request sounds like plain feature work ("save the deck", "load cards faster", "why is this list stale") — those are database changes wearing a feature's clothes. Covers checklist phase 11 in depth; `flutter-data-layer` owns the repository/DTO boundary above it.
---
```

with

```markdown
name: flutter-drift
description: Use when a task touches the database in any way — adding or changing a table, column, constraint or index; writing or editing a `.drift` query; bumping `schemaVersion` or writing a migration; adding a DAO or local data source; debugging a Drift stream that will not re-emit, a slow query, a locked database or a failing migration test; and above all when reviewing a pull request that changes anything under `lib/core/database/` or any `data/` folder. Reach for it even when the request sounds like plain feature work ("save the deck", "load cards faster", "why is this list stale") — those are database changes wearing a feature's clothes. `flutter-data-layer` owns the repository/DTO boundary above it.
---
```

Replace

```markdown
on the internet — and most generic checklists, including good ones — assumes a
greenfield repo. memox-v7 is not greenfield, and a well-meant "best practice"
applied here is a refactor nobody asked for. Read
```

with

```markdown
on the internet — and most generic checklists, including good ones — assumes a
greenfield repo. MemoX V8 is not greenfield, and a well-meant "best practice"
applied here is a refactor nobody asked for. Read
```

Replace

```markdown
This is not tidiness. It is the single property that lets a Spring Boot backend
arrive later without `domain/` or `presentation/` changing (AD-01). The day a
`Card` row class reaches a widget, the backend migration becomes a rewrite of the
```

with

```markdown
This is not tidiness. It is the single property that lets a Spring Boot backend
arrive later without `domain/` or `presentation/` changing (ADR-011). The day a
`Card` row class reaches a widget, the backend migration becomes a rewrite of the
```

Replace

```markdown
- Does the fact belong to the **scheduler** rather than the database? Box-day
  tables and SM-2 factors stay in Dart on purpose (BR-16) — in SQL, tuning the
  algorithm becomes a migration.
```

with

```markdown
- Does the fact belong to the **scheduler** rather than the database? Box-day
  tables and SM-2 factors stay in Dart on purpose — in SQL, tuning the
  algorithm becomes a migration.
```

In `.claude/skills/flutter-drift/references/dynamic-sql-semantics.md`:

Replace

```markdown
Never log the keyword itself — it is card content, and content is private at
every level (AD-08). The fingerprint is what makes it possible to see which
combination is slow, which shape stopped using an index after a migration, and
```

with

```markdown
Never log the keyword itself — it is card content, and content is private at
every level (ADR-002). The fingerprint is what makes it possible to see which
combination is slow, which shape stopped using an index after a migration, and
```

In `.claude/skills/flutter-drift/references/dynamic-sql.md`:

Replace

```markdown
lets a list and its count share one definition of "due" instead of two copies
that drift apart. `card_list_query_mapper.dart` names each rule after the
business rule it implements (`dueNowPredicate` — BR-22, `isNewPredicate` —
BR-90), which is why the pill count and the list it opens can never disagree.

```

with

```markdown
lets a list and its count share one definition of "due" instead of two copies
that drift apart. Name each builder after the business rule it implements
(`dueNowPredicate`, `isNewPredicate`) and cite that rule's `BR-<AREA>-NNN`
beside it, so the pill count and the list it opens can never disagree.

```

In `.claude/skills/flutter-drift/references/operations.md`:

Replace

```markdown
Card content, notes, learning history, imports, media and backups are private
(AD-08). A database log touches all of them at once, so the rules are stricter
here than anywhere else in the app:
```

with

```markdown
Card content, notes, learning history, imports, media and backups are private
(ADR-002). A database log touches all of them at once, so the rules are stricter
here than anywhere else in the app:
```

In `.claude/skills/flutter-drift/references/review-checklist.md`:

Replace

```markdown
      `flutter test` all pass.
- [ ] Generated code regenerated and committed — no diff after a fresh
      `build_runner build`.
- [ ] `docs/shared/data/schema.md` and `docs/wbs.md` updated in the same commit.

```

with

```markdown
      `flutter test` all pass.
- [ ] Generated code fresh and uncommitted: `check_generated.sh` passes after a
      clean `build_runner build`.
- [ ] `docs/shared/data/schema.md` and `docs/wbs_BE.md` updated in the same
      commit.

```

In `.claude/skills/flutter-drift/references/riverpod-drift.md`:

Replace

```markdown
Future<void> createCard(...) => _dao.runInTransaction(() async {
  await _dao.insertCard(card);              // content
  await _dao.insertReviewState(state);      // BR-09: exactly one, same transaction
  await _deckDao.lockContentType(deckId);   // BR-62: first child fixes the type
});
```

with

```markdown
Future<void> createCard(...) => _dao.runInTransaction(() async {
  await _dao.insertCard(card);
  // Exactly one schedule row per card.
  await _dao.insertSchedule(schedule);
  // The first child fixes the deck's content type (ADR-006).
  await _deckDao.setContentType(deckId, 'card', now);
});
```

In `.claude/skills/flutter-drift/references/schema-conventions.md`:

Replace

```markdown
`pronunciation` are `NULL` when never filled, and the domain folds `''` to `NULL`
so there is exactly one spelling of "empty" (BR-95). `due_at` is `NULL` for a card
that has never been scheduled, which is why "due" is `due_at IS NULL OR due_at <=
```

with

```markdown
`pronunciation` are `NULL` when never filled, and the domain folds `''` to `NULL`
so there is exactly one spelling of "empty". `due_at` is `NULL` for a card
that has never been scheduled, which is why "due" is `due_at IS NULL OR due_at <=
```

In `.claude/skills/flutter-drift/references/testing-database.md`:

Replace

```markdown
three-level tree, because a one-level fixture would let the root-resolution
invariants pass even with the `COALESCE(parent_deck_id, id)` bug that BR-57
forbids.
```

with

```markdown
three-level tree, because a one-level fixture would let the root-resolution
invariants pass even with the `COALESCE(parent_id, id)` bug that BR-DECK-003
forbids.
```

In `.claude/skills/flutter-drift/scripts/check_drift.py`:

Replace

```python
def check_presentation_free_of_drift() -> None:
    """Drift must not be visible above the repository (AD-01).

```

with

```python
def check_presentation_free_of_drift() -> None:
    """Drift must not be visible above the repository (ADR-011).

```

Replace

```python
        # The composition root is the one place an implementation is named
        # outside its own layer — that is its whole job (CLAUDE.md, AD-13). It
        # binds a DAO to a contract, so it necessarily sees both.
```

with

```python
        # The composition root is the one place an implementation is named
        # outside its own layer — that is its whole job (ADR-011). It
        # binds a DAO to a contract, so it necessarily sees both.
```

Replace

```python
def check_single_opener() -> None:
    """One file opens a database (AD-08).

```

with

```python
def check_single_opener() -> None:
    """One file opens a database (ADR-002).

```

Replace

```python
                rel(path),
                "opens a database; only core/database/connection.dart may (AD-08)",
            )
```

with

```python
                rel(path),
                "opens a database; only core/database/connection.dart may (ADR-002)",
            )
```

- [ ] **Step 5: Run the contract test**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 4 tests` and `OK`.

- [ ] **Step 6: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-drift/SKILL.md \
  .claude/skills/flutter-drift/references/dynamic-sql-semantics.md \
  .claude/skills/flutter-drift/references/dynamic-sql.md \
  .claude/skills/flutter-drift/references/operations.md \
  .claude/skills/flutter-drift/references/project-baseline.md \
  .claude/skills/flutter-drift/references/review-checklist.md \
  .claude/skills/flutter-drift/references/riverpod-drift.md \
  .claude/skills/flutter-drift/references/schema-conventions.md \
  .claude/skills/flutter-drift/references/testing-database.md \
  .claude/skills/flutter-drift/scripts/check_drift.py \
  .claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 71 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
docs(skills): flutter-drift describes V8's database (BE-D7)

project-baseline.md recorded what memox-v7 had settled for Drift. It is
rewritten as V8's baseline, checked against lib/core/database/,
docs/shared/data/schema.md and the ADRs: the layout, the connection,
identity and time, reads and pagination, the two traps the schema has paid
for, what it does not do, what ADR-013 has already decided for sync, and
the executable invariants. The skill and its references cite V8's ADRs and
business rules in place of V7's AD-nn and BR-nn, and check_drift.py cites
ADR-002 and ADR-011. The contract test now scans flutter-drift.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: testing, product-spec and project-documentation without V7's tools

**Files:**
- Modify: `.claude/skills/flutter-product-spec/SKILL.md`, `.claude/skills/flutter-product-spec/assets/business_rules_template.md`, `.claude/skills/flutter-testing/SKILL.md`, `.claude/skills/flutter-testing/scripts/golden.Dockerfile`
- Delete: `.claude/skills/flutter-product-spec/assets/wbs_template.md`, `.claude/skills/flutter-testing/references/integration-test-harness.md`, `.claude/skills/flutter-testing/scripts/build_screen_gallery.py`, `.claude/skills/flutter-testing/scripts/splice_screen_gallery.py`, `.claude/skills/project-documentation/.installation.json`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`

**Interfaces:**
- Consumes: Task 1's `_occurrences` and `_scanned_files`.
- Produces: `_occurrences(root: Path = REPO_ROOT, names: tuple[str, ...] =
  REPO_OWNED_SKILLS) -> list[str]`, reading every file as UTF-8 with `errors="replace"`;
  `ScanTest`; `test_project_documentation_is_its_own_canonical_source`.

Spec §4.3 (`flutter-testing`, `flutter-product-spec`, `project-documentation`), D8, D9,
§8's inspection; Clarification 11; Review Focus 4 and 5.

- [ ] **Step 1: Add the three skills, the scan and the receipt to the contract test**

`ScanTest` builds a skill in a temporary directory, so it pins that the scan reads a
skill's references and skips its `tests/` and a byte that is not UTF-8 without touching
the repository.

In `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`:

Replace

```python
import re
import unittest
```

with

```python
import re
import tempfile
import unittest
```

Replace

```python
    "flutter-feature-slice",
    "flutter-workflow",
)
```

with

```python
    "flutter-feature-slice",
    "flutter-product-spec",
    "flutter-testing",
    "flutter-workflow",
    "project-documentation",
)
```

Replace

```python

def _occurrences() -> list[str]:
    found = []
    for name in REPO_OWNED_SKILLS:
        for path in _scanned_files(SKILLS / name):
            text = path.read_text(encoding="utf-8")
            for number, line in enumerate(text.splitlines(), start=1):
                if _markers_in(line):
                    relative = path.relative_to(REPO_ROOT).as_posix()
                    found.append(f"{relative}:{number}: {line.strip()}")
```

with

```python

def _occurrences(root: Path = REPO_ROOT, names: tuple[str, ...] = REPO_OWNED_SKILLS) -> list[str]:
    found = []
    for name in names:
        for path in _scanned_files(root / ".claude" / "skills" / name):
            # A skill may ship an image or an archive: a byte that is not UTF-8
            # holds no citation, so it is replaced rather than fatal.
            text = path.read_text(encoding="utf-8", errors="replace")
            for number, line in enumerate(text.splitlines(), start=1):
                if _markers_in(line):
                    relative = path.relative_to(root).as_posix()
                    found.append(f"{relative}:{number}: {line.strip()}")
```

Replace

```python

class RepoOwnedSkillsTest(unittest.TestCase):
```

with

```python

class ScanTest(unittest.TestCase):
    def test_a_skill_file_is_scanned_and_its_tests_are_not(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill = root / ".claude" / "skills" / "flutter-example"
            (skill / "references").mkdir(parents=True)
            (skill / "tests").mkdir()
            (skill / "SKILL.md").write_text("Covers ADR-011 D4.\n", encoding="utf-8")
            (skill / "references" / "notes.md").write_text(
                "intro\nupdate docs/wbs.md here\n", encoding="utf-8"
            )
            (skill / "tests" / "test_absent.py").write_text(
                "assert 'widgetbook' not in plan\n", encoding="utf-8"
            )
            (skill / "logo.png").write_bytes(b"\x89PNG\r\n\x1a\n\xff\xfe")

            found = _occurrences(root, ("flutter-example",))

        self.assertEqual(
            found,
            [".claude/skills/flutter-example/references/notes.md:2: update docs/wbs.md here"],
        )


class RepoOwnedSkillsTest(unittest.TestCase):
```

Replace

```python
        self.assertEqual(_occurrences(), [])


if __name__ == "__main__":
```

with

```python
        self.assertEqual(_occurrences(), [])

    def test_project_documentation_is_its_own_canonical_source(self):
        """The install receipt named a V7 checkout as the skill's source.

        Without it, `skill_distribution.py inspect` treats this copy as
        canonical, and the payload and `skill-manifest.json` are unchanged.
        """
        receipt = SKILLS / "project-documentation" / ".installation.json"
        self.assertFalse(receipt.exists())


if __name__ == "__main__":
```

- [ ] **Step 2: Run it to see it fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 6 tests` and `FAILED (failures=2)`: `test_no_repo_owned_skill_names_v7`
lists 39 lines in eight files, 21 of them in `build_screen_gallery.py`, the first
`.claude/skills/flutter-product-spec/SKILL.md:8: Covers checklist Phases 0 and 1. …`; and
`test_project_documentation_is_its_own_canonical_source` fails with
`AssertionError: True is not false`. The two scan tests pass already.

- [ ] **Step 3: Remove V7's tools and harness note from flutter-testing**

Run:

```bash
git rm -q .claude/skills/flutter-testing/scripts/build_screen_gallery.py
```

Run:

```bash
git rm -q .claude/skills/flutter-testing/scripts/splice_screen_gallery.py
```

Run:

```bash
git rm -q .claude/skills/flutter-testing/references/integration-test-harness.md
```

In `.claude/skills/flutter-testing/SKILL.md`:

Replace

```markdown
name: flutter-testing
description: Testing strategy and patterns for this Flutter app — unit tests for use cases, repositories, mappers, validators, Drift queries and migrations and error mapping; Riverpod controller tests for state transitions; widget tests with ProviderScope covering loading/empty/error/dark-mode/text-scale; golden tests with stable rendering; and integration tests for the 60-scenario UI suite (cold start, navigation, CRUD, restart, deep links — no auth/network yet per AD-03/ADR-012). Use this skill whenever writing, fixing or reviewing any test, setting up mocks or fakes, deciding what needs test coverage, debugging a flaky or failing test, or configuring golden-test tolerances. Covers checklist phase 15.
---
```

with

```markdown
name: flutter-testing
description: Testing strategy and patterns for this Flutter app — unit tests for use cases, repositories, mappers, validators, Drift queries and migrations and error mapping; Riverpod controller tests for state transitions; widget tests with ProviderScope covering loading/empty/error/dark-mode/text-scale; golden tests with stable rendering; and integration tests for the 60-scenario UI suite (cold start, navigation, CRUD, restart, deep links — no login and no API call yet, per ADR-013 and ADR-012). Use this skill whenever writing, fixing or reviewing any test, setting up mocks or fakes, deciding what needs test coverage, debugging a flaky or failing test, or configuring golden-test tolerances.
---
```

Replace

```markdown
# Testing

Covers checklist Phase 15.

```

with

```markdown
# Testing

```

Replace

````markdown
```dart
test('deleting the last card keeps the deck card-typed (BR-63)', () async {
  final db = createTestDatabase();          // in-memory, real schema
  final repository = CardRepositoryImpl(db, clock: fixedClock);
  final card = await repository.createCard(deckId: leaf.id, front: f, back: b);

  await repository.deleteCard(card.id);

  final deck = await db.deckById(leaf.id).getSingle();
  expect(deck.contentType, ContentType.card); // emptying ≠ resetting the type
});
````

with

````markdown
```dart
test('deleting the last card of a deck makes it unset (BR-DECK-015)', () async {
  final card = await cards.card(nouns.id);  // real repository, in-memory schema

  final result = await cards.deleteCards(cardIds: {card.id});

  expect(result, isA<Ok<List<String>, CardRejection>>());
  expect(await contentTypeOf(nouns.id), DeckContentType.unset);
});
````

Replace

```markdown
`SqliteException` code the app can hit mapped to its expected `Failure`
(`drift_error_mapper.dart` is the unit under test). It is high-traffic code
that manual testing almost never exercises. (When networking lands per ADR-012,
the same table-driven treatment applies to status codes and
`DioExceptionType`.)

```

with

```markdown
`SqliteException` code the app can hit mapped to its expected `Failure`
(`mapDatabaseError` in `lib/core/error/failure.dart` is the unit under test).
It is high-traffic code that manual testing almost never exercises. When the
app makes its first API call (ADR-012), the same table-driven treatment applies
to HTTP status codes and `DioExceptionType`.

```

Replace

```markdown

`integration_test/`, driving real user actions.

This repo has a full 60-scenario suite (`docs/shared/testing/scenario-catalog.md` ↔
`integration_test/it_*_test.dart`) with its own harness, robot and fixture
layer. Before writing, running or debugging any of it, read
`references/integration-test-harness.md` — it holds the memox-specific rules
(seams, driver anchors, fixtures, emulator setup) and points to the global
`flutter-harness` skill's `e2e-driving.md` for the framework-generic craft
(liveness, finders, scrolling, IME, clock ticks, classifying a red run).

Cover what the app actually has (no auth — AD-03; no network — ADR-012): cold
start, main navigation, deck/card CRUD through the UI, restart with state
restored, the review flows, and each deep link. The canonical list is the 60
scenarios in `docs/shared/testing/scenario-catalog.md` — extend that catalog rather than inventing
parallel coverage.

Deep links and cold start are the highest-value cases here, because they are the
ones nobody exercises during development — you already have the app open and
already logged in.

```

with

```markdown

Host flows live in `test/integration/` and run with the rest of the suite. The
canonical list is the scenario catalog
(`docs/shared/testing/scenario-catalog.md`), and
`docs/shared/testing/agent-execution-guide.md` holds the execution rules: each
scenario's readiness, its profile (`HOST-FLOW`, `HOST-WIDGET`, `DEVICE-E2E`),
its setup and its cleanup. Read both before writing, running or debugging a
scenario.

Cover what the app actually has (no login and no API call yet — ADR-013,
ADR-012): cold start, main navigation, deck/card CRUD through the UI, restart
with state restored, the review flows, and each deep link. The canonical list
is the 60 scenarios in `docs/shared/testing/scenario-catalog.md` — extend that
catalog rather than inventing parallel coverage.

Three defect classes deserve a test of their own:

1. **A pass-through seam that drops optional parameters** — a use case that
   accepts a sort or a search term and forwards neither. Lock every use case
   with optional parameters with a fake that records what it receives.
2. **A Drift stream that misses a table it reads** — see the `riverpod-drift.md`
   reference of `flutter-drift`: a write to that table must re-emit, and a
   repository-level test proves it.
3. **A scenario test that skips a documented step** — diff the test's steps
   against the scenario's table line by line; asserting less than the document
   is a quiet way of lowering the expected result.

Deep links and cold start are the highest-value cases here, because they are the
ones nobody exercises during development — you already have the app open.

```

In `.claude/skills/flutter-testing/scripts/golden.Dockerfile`:

Replace

```
# 2026-09-25), for regenerating them from a Windows or macOS checkout. The
# history below is inherited. The `goldens` job of `.github/workflows/ci.yml`
# compares the pictures on `ubuntu-latest`, as described below; this image is
```

with

```
# 2026-09-25), for regenerating them from a Windows or macOS checkout. The
# `goldens` job of `.github/workflows/ci.yml`
# compares the pictures on `ubuntu-latest`, as described below; this image is
```

Replace

```
#
# **Why this file exists.** Goldens have exactly one authoring platform and
# since M100.24 it is Linux (`dart_test.yaml` carries the reasoning). A Windows
# checkout that runs `--update-goldens` writes PNGs CI rejects, and it does it
# silently — the local run reports every test passing, because a platform always
# agrees with itself. Until M100.30 the only documented answers were "use WSL"
# or "let a cloud session do it"; this is the third, and it is reproducible.
#
```

with

```
#
# **Why this file exists.** Goldens have exactly one authoring platform, Linux
# (`dart_test.yaml` carries the reasoning). A Windows checkout that runs
# `--update-goldens` writes PNGs CI rejects, and it does it silently — the local
# run reports every test passing, because a platform always agrees with itself.
# This image is the reproducible way to write them from any machine.
#
```

- [ ] **Step 4: Name V8's documents in flutter-product-spec**

Run:

```bash
git rm -q .claude/skills/flutter-product-spec/assets/wbs_template.md
```

In `.claude/skills/flutter-product-spec/SKILL.md`:

Replace

```markdown

Covers checklist Phases 0 and 1. Output is documents in `docs/`, not code.

```

with

```markdown

Output is documents in `docs/`, not code.

```

Replace

```markdown
| `docs/features/<feature>/rules/` (+ `ui.md` for validation, `data.md` for entity states) | One file per rule (`BR-<DOMAIN>-NNN-<slug>.md`) with its edge cases | `assets/business_rules_template.md` |
| `docs/wbs.md` | Milestones → features → tasks, the live progress ledger | `assets/wbs_template.md` |
| `docs/architecture.md` | Layering decisions and deviations, written as they are made | — |
| `docs/shared/data/schema.md` | Entities, relationships, Drift schema intent, invariants | — |
| `docs/api-spec.md` | Endpoints, request/response shapes, error format, pagination — not until the backend exists (AD-05) | — |
| `docs/design-system.md` | Owned by `flutter-design-system` | — |
```

with

```markdown
| `docs/features/<feature>/rules/` (+ `ui.md` for validation, `data.md` for entity states) | One file per rule (`BR-<DOMAIN>-NNN-<slug>.md`) with its edge cases | `assets/business_rules_template.md` |
| `docs/wbs_BE.md`, `docs/wbs_FE.md` | Work packages with status, dependencies and evidence, the live progress ledger; the files themselves are the format | — |
| `docs/shared/decisions/` | Architecture and product decisions and their deviations, one ADR each, written as they are made | — |
| `docs/shared/data/schema.md` | Entities, relationships, Drift schema intent, invariants | — |
| `docs/features/<feature>/api.md` | Endpoints, request/response shapes, error format, pagination — from the first slice that calls the API (ADR-012) | — |
| `docs/design-system.md` | Owned by `flutter-design-system` | — |
```

Replace

```markdown
reviewed more than once per day", "a deleted deck stays recoverable for 30 days".
Number them (`BR-01`) so use cases, code comments and tests can cite them.

```

with

```markdown
reviewed more than once per day", "a deleted deck stays recoverable for 30 days".
Number them (`BR-<DOMAIN>-NNN`, such as `BR-DECK-001`) so use cases, code
comments and tests can cite them.

```

Replace

```markdown
write the task — "login works" is not checkable; "invalid credentials show the
inline error from BR-04 and the password field is not cleared" is.

```

with

```markdown
write the task — "login works" is not checkable; "invalid credentials show the
inline error from BR-AUTH-004 and the password field is not cleared" is.

```

Replace

```markdown
end to end beats four features half-built, because only the former proves the
architecture. `docs/wbs.md` is then maintained for the life of the project as
the progress ledger — see `flutter-workflow` for the update discipline.
```

with

```markdown
end to end beats four features half-built, because only the former proves the
architecture. `docs/wbs_BE.md` and `docs/wbs_FE.md` are then maintained for the
life of the project as
the progress ledger — see `flutter-workflow` for the update discipline.
```

In `.claude/skills/flutter-product-spec/assets/business_rules_template.md`:

Replace

```markdown
|---|---|---|---|
| BR-01 | | | stakeholder / regulation / product decision |

```

with

```markdown
|---|---|---|---|
| BR-<DOMAIN>-001 | | | stakeholder / regulation / product decision |

```

- [ ] **Step 5: Remove the install receipt of project-documentation**

Run:

```bash
git rm -q .claude/skills/project-documentation/.installation.json
```

- [ ] **Step 6: Run the contract test**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 6 tests` and `OK`.

- [ ] **Step 7: Inspect project-documentation's distribution**

```bash
python3 .claude/skills/project-documentation/scripts/skill_distribution.py inspect \
  --root . --active .claude/skills/project-documentation
```

Expected: a JSON report with `"ok": true` and `"conflicts": []`; the active copy has
`"role": "canonical source"`, `"managed": false`, `"status": "VALID"` and
`"changed_files": []`, and its one candidate has `"scope": "canonical"`.

- [ ] **Step 8: Stage the task's files**

The deletions are staged already, by `git rm`. The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-product-spec/SKILL.md \
  .claude/skills/flutter-product-spec/assets/business_rules_template.md \
  .claude/skills/flutter-testing/SKILL.md \
  .claude/skills/flutter-testing/scripts/golden.Dockerfile \
  .claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 9: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 73 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
docs(skills): testing, product-spec and project-documentation lose V7's tools (BE-D7)

The two screen-gallery scripts built pages from V7's test/demo/ goldens,
integration-test-harness.md described V7's integration_test/ harness, and
wbs_template.md was V7's milestone format; they go. flutter-testing cites
V8's rules, its host flows and its execution guide, and keeps the three
defect classes the harness note named; golden.Dockerfile explains the
Linux renderer without V7's milestones. flutter-product-spec names V8's
documents and numbers rules BR-<AREA>-NNN. project-documentation's install
receipt named a V7 checkout as its source; without it, this copy is its
own canonical source.

The contract test now scans the three skills. It also pins that the
receipt is gone, and that the scan reads a skill's files but not its
tests.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: The six remaining skills without V7

**Files:**
- Modify: `.claude/skills/flutter-data-layer/SKILL.md`, `.claude/skills/flutter-data-layer/references/networking.md`, `.claude/skills/flutter-data-layer/references/persistence.md`, `.claude/skills/flutter-navigation/SKILL.md`, `.claude/skills/flutter-project-setup/SKILL.md`, `.claude/skills/flutter-project-setup/references/dependencies.md`, `.claude/skills/flutter-ship/SKILL.md`, `.claude/skills/flutter-state-riverpod/SKILL.md`, `.claude/skills/flutter-theme-design/references/buttons-actions.md`, `.claude/skills/flutter-theme-design/references/chrome-navigation.md`, `.claude/skills/flutter-theme-design/references/foundation.md`, `.claude/skills/flutter-theme-design/references/legacy-and-guards.md`, `.claude/skills/flutter-theme-design/references/overlays-menus.md`, `.claude/skills/flutter-theme-design/references/surfaces-containers.md`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`

**Interfaces:**
- Consumes: Task 1's `SKILLS` and `REPO_OWNED_SKILLS`.
- Produces: `REPO_OWNED_SKILLS` complete (15), `VENDORED_SKILLS: tuple[str, ...]` (35),
  and `test_every_skill_is_repo_owned_or_vendored`.

Spec §4.1, §4.2, §4.3 (the six other skills), §12.1, §12.2 (`flutter-theme-design`);
Clarifications 1, 3, 4 and 10; Review Focus 1.

- [ ] **Step 1: Add the six skills to the contract test**

`spring-boot-mybatis-review` joins the list: it cites nothing of V7 (Clarification 3).

In `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`:

Replace

```python
    "flutter-architecture",
    "flutter-design-system",
```

with

```python
    "flutter-architecture",
    "flutter-data-layer",
    "flutter-design-system",
```

Replace

```python
    "flutter-feature-slice",
    "flutter-product-spec",
    "flutter-testing",
    "flutter-workflow",
    "project-documentation",
)
```

with

```python
    "flutter-feature-slice",
    "flutter-navigation",
    "flutter-product-spec",
    "flutter-project-setup",
    "flutter-ship",
    "flutter-state-riverpod",
    "flutter-testing",
    "flutter-theme-design",
    "flutter-workflow",
    "project-documentation",
    "spring-boot-mybatis-review",
)

# Copied from their upstreams and not the repo's to edit (CLAUDE.md): ECC,
# Superpowers and Impeccable. Every other skill is the repo's, and is scanned.
VENDORED_SKILLS = (
    # ECC
    "android-clean-architecture",
    "compose-multiplatform-patterns",
    "dart-flutter-patterns",
    "flutter-dart-code-review",
    "foundation-models-on-device",
    "java-coding-standards",
    "jpa-patterns",
    "kotlin-coroutines-flows",
    "liquid-glass-design",
    "react-native-patterns",
    "security-review",
    "springboot-patterns",
    "springboot-security",
    "springboot-tdd",
    "springboot-verification",
    "swift-actor-persistence",
    "swift-concurrency-6-2",
    "swift-protocol-di-testing",
    "swiftui-patterns",
    # Superpowers
    "brainstorming",
    "diagnosing-superpowers",
    "dispatching-parallel-agents",
    "executing-plans",
    "finishing-a-development-branch",
    "receiving-code-review",
    "requesting-code-review",
    "subagent-driven-development",
    "systematic-debugging",
    "test-driven-development",
    "using-git-worktrees",
    "using-superpowers",
    "verification-before-completion",
    "writing-plans",
    "writing-skills",
    # Impeccable
    "impeccable",
)
```

Replace

```python

    def test_no_repo_owned_skill_names_v7(self):
```

with

```python

    def test_every_skill_is_repo_owned_or_vendored(self):
        """A skill missing from REPO_OWNED_SKILLS is never scanned, so every
        directory under .claude/skills/ is named here, as one or the other."""
        present = {path.name for path in SKILLS.iterdir() if path.is_dir()}
        self.assertEqual(present, set(REPO_OWNED_SKILLS) | set(VENDORED_SKILLS))
        self.assertEqual(set(REPO_OWNED_SKILLS) & set(VENDORED_SKILLS), set())

    def test_no_repo_owned_skill_names_v7(self):
```

- [ ] **Step 2: Run it to see it fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 7 tests` and `FAILED (failures=1)`: 56 lines in fourteen files of the six
skills, the most in `legacy-and-guards.md` (10) and `dependencies.md` (9), the first
`.claude/skills/flutter-data-layer/SKILL.md:3: description: …`. The classification test
passes already: every directory under `.claude/skills/` is in one of the two lists.

- [ ] **Step 3: flutter-data-layer: ADR-012 and ADR-013**

Replace the whole of `.claude/skills/flutter-data-layer/SKILL.md` with:

````markdown
---
name: flutter-data-layer
description: Networking and persistence for this Flutter app. Today only the persistence half is live — dio is deliberately not a dependency (ADR-012), so the networking guidance here is reference for the backend phase, not current work. Covers the future shared Dio client with auth/logging/error/token-refresh/request-ID interceptors, DTO-to-entity mapping, pagination and error-response contracts, offline and retry behaviour, Drift schema design with indexes and migrations, cache strategy with TTL and a declared source of truth, conflict resolution and sync, and secure storage of tokens. Use this skill when calling an API, adding or changing a repository implementation, designing database tables or writing a Drift migration, deciding what to cache or how to sync, handling offline state, or storing anything sensitive.
---

# Data layer: networking and persistence

The repository is the boundary. Above it, domain entities and `Failure`. Below
it, DTOs, Dio and Drift. Nothing from below crosses up — that single rule is
what keeps the UI testable and the domain framework-free.

Read `references/networking.md` for the Dio client and interceptor setup, and
`references/persistence.md` for cache and sync policy.

**For anything below the repository — `.drift` schema and queries, indexes,
migrations, DAOs, transactions, Drift stream invalidation, or reviewing a
database PR — load `flutter-drift` instead.** That skill owns the database in
depth and knows what this project has already settled; this one owns the
repository contract above it.

## Source of truth — already decided for this project

**The server is canonical, and the app is offline-first (ADR-013).** The app
always reads and writes Drift, online or offline: reads come from `watch()`
streams, and a write lands locally first, so the UI never waits for the
network. Drift is the durable store, not a cache. Sync is the data layer's own
job, which use cases and presentation never see, and none of it is built yet:
no feature calls the API, and the repository contract is what lets sync arrive
without touching `domain/` or `presentation/`.

That means the networking half of this skill —
`references/networking.md` — is **reference material for the sync slices**, not
something to build ahead of them. `dio` is deliberately not a dependency yet
(ADR-012).

The generic reasoning below is kept because it is what makes the decision
reviewable.

**Offline-first** — reads always come from the database and are exposed as a
stream, so the UI updates when data changes for any reason. The network is a
background process that fills the database. Writes go to the database first
and are queued for upload. This is more work up front and dramatically better
under bad connectivity, and it is what ADR-013 chose, with the server holding
the canonical copy.

**Online-first** — the network is the source of truth, the database is a cache
with a TTL. Reads try the network, fall back to cache, and say so in the UI when
they are showing stale data.

Whichever it is, record it in an ADR in `docs/shared/decisions/`. And the UI
must never choose: a widget deciding "if offline read local else read remote"
has pulled a data-layer policy into presentation, and that policy will then
differ per screen.

## Repository shape

```dart
final class DeckRepositoryImpl implements DeckRepository {
  const DeckRepositoryImpl(this._remote, this._local, this._mapper);

  @override
  Future<List<Deck>> getDecks() async {
    try {
      final dtos = await _remote.fetchDecks();
      await _local.upsertAll(dtos);
      return dtos.map(_mapper.toEntity).toList();
    } on DioException catch (e, s) {
      _logger.warning('fetchDecks failed', e, s);
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached.map(_mapper.toEntity).toList();
      throw mapDioException(e);          // -> Failure
    } on DriftWrappedException catch (e, s) {
      _logger.error('local read failed', e, s);
      throw DatabaseFailure(message: 'Could not read local data', cause: e);
    }
  }
}
```

What that demonstrates: exceptions are caught at this boundary and only this
boundary; the original is logged with its stack trace and then discarded from
the user-facing path; the returned type is a domain entity, never a DTO.

Put `mapDioException` in `core/error/` and use it from every repository, so the
same status code cannot produce different failures in different features. Test
it directly (`flutter-testing`) — it is high-traffic code that manual testing rarely
exercises.

## DTO and entity are different types

`*_model.dart` in `data/models/` is the wire shape: nullable where the server is
nullable, named as the server names things, `json_serializable` annotations.
`*_entity.dart` in `domain/entities/` is the shape the app reasons about:
non-nullable where the app requires a value, named in domain language.

The mapper between them is where you handle the server's inconsistencies — a
missing field, a date as a string, an enum value you have never seen. Handle an
unknown enum value by mapping to a known `unknown` variant rather than throwing;
a server adding a status should not crash the app for every existing user.

Skipping the split — passing DTOs to the UI — means every server field rename
becomes a UI change, and every nullable server field becomes a null check in a
widget.

## Non-negotiables for this layer

- Never log tokens, passwords, or anything listed as sensitive in
  `docs/shared/decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md`.
  Redact by key name in the logging interceptor, not by
  remembering at each call site.
- Verbose HTTP logging is development-only, gated on `EnvConfig.logLevel`.
- Tokens go in `flutter_secure_storage`, never in SharedPreferences, and are
  cleared on logout along with any cached user data — otherwise the next user of
  the device sees the previous one's content.
- Never retry a non-idempotent mutation blindly. A retried POST can double-charge
  or double-create. Retry GETs; retry mutations only with an idempotency key the
  server honours.
- Wrap multi-step writes in a transaction, so a failure halfway does not leave
  half-applied state.
- Never delete user data on a schema migration.

## Checks before the data layer is done

Now (Drift only; no API call yet, ADR-012):

- [ ] ADR-013's source of truth followed everywhere: the app reads and writes
      Drift, online or offline, and the server is canonical.
- [ ] No Drift exception escapes a repository.
- [ ] Exception→failure mapping in one place, with tests.
- [ ] Generated row types never reach presentation.
- [ ] Sensitive fields redacted in logs; verbose logging off in production.
- [ ] Mutations are not blindly retried; duplicate submits are prevented.
- [ ] Indexes exist for the queries actually run.
- [ ] Migration tested from every released schema version.

When the first API call lands (ADR-012):

- [ ] No `DioException` escapes a repository; DTOs never reach presentation.
- [ ] Timeouts set for connect, receive and send.
- [ ] Token refresh handles concurrent 401s without a refresh storm.
- [ ] Requests cancelled when their screen goes away.
- [ ] Tokens in secure storage, cleared on logout.
````

In `.claude/skills/flutter-data-layer/references/networking.md`:

Replace

```markdown

Document in `docs/api-spec.md`: endpoints, request and response shapes, the
error envelope, pagination style, and auth behaviour.

```

with

```markdown

Document in `docs/features/<feature>/api.md`: endpoints, request and response
shapes, the error envelope, pagination style, and auth behaviour.

```

Replace the whole of `.claude/skills/flutter-data-layer/references/persistence.md` with:

````markdown
# Cache, sync and secure storage

The database half of this file now lives in the `flutter-drift` skill, so that
one question has one answer: schema and `.drift` conventions, index design,
DAO/data-source boundaries, transactions, migrations and stream invalidation are
all there, together with what this project has already settled about them.

Load `flutter-drift` for any of that. What stays here is the policy that sits
*above* the database — what to cache, how to sync, and where secrets go.

## Cache strategy

**Not for the user's data (ADR-013).** Drift is the durable store the app always
reads, not a cache in front of the server: it is never cleared to refresh, and
freshness comes from sync's pull, not from a TTL.

A cache policy applies only to data the app reads from the server without
syncing it, and there is none today. When such a read appears, decide it per
data type in an ADR in `docs/shared/decisions/`: cached or not, the TTL, and
what the UI shows while the copy is stale. Showing stale data with a refresh
indicator beats a spinner over a blank screen: the user sees something
immediately and the update arrives behind it.

TTL lives in the repository. The UI never decides whether to read local or
remote — that policy belongs in one place, or it will drift per screen.

## Sync and conflicts

Decided once for every synced entity by ADR-013 and its design,
`docs/superpowers/specs/2026-09-27-server-sync-design.md`; a feature does not
pick its own conflict policy. What a repository has to know:

- **A write queues itself.** The row and one `sync_outbox` entry go in the same
  Drift transaction. The outbox keeps at most one entry per entity, its id is
  the push's idempotency key, and the entry leaves only once the server has
  answered, so a push that fails loses nothing.
- **The server settles conflicts.** Content follows the operation the server
  receives last, and an operation that would break the deck tree is rejected
  and replaced by the server's copy. No device clock takes part.
- **Sync is not a feature's code.** One `SyncCoordinator` pushes and pulls; use
  cases and presentation never see the network.

## Secure storage

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

- Access and refresh tokens only. Not bulk data — secure storage is slow, and on
  Android it has size limits.
- Never store a raw password. If "remember me" is needed, store the token.
- SharedPreferences is not secure. Nothing sensitive goes there.
- **On logout, clear everything**: tokens, cached user data, and any
  feature-specific tables holding personal data. A device shared between users
  otherwise leaks the previous session's content.
- `KeychainAccessibility.first_unlock` keeps tokens readable for background
  refresh after a reboot without exposing them on a locked device.

If the database itself holds sensitive data, consider SQLCipher via
`sqlcipher_flutter_libs`. Decide this before launch — encrypting an existing
plaintext database in a migration is painful, and it is a decision better made
once in `docs/shared/decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md`.
````

- [ ] **Step 4: flutter-navigation, flutter-project-setup, flutter-ship and flutter-state-riverpod**

In `.claude/skills/flutter-navigation/SKILL.md`:

Replace

```markdown
name: flutter-navigation
description: GoRouter setup and navigation rules for this Flutter app — centralised route declarations, typed routes and path constants, StatefulShellRoute for bottom navigation, auth redirect guards (deferred until auth lands, AD-03), 404 handling, deep links, and correct back behaviour on Android and iOS. Use this skill when adding a screen or route, wiring bottom navigation or nested navigation, implementing login redirects or route guards, handling deep links or cold-start links, passing data between screens, or debugging a wrong back-button or duplicated-stack behaviour. Covers checklist phase 8.
---
```

with

```markdown
name: flutter-navigation
description: GoRouter setup and navigation rules for this Flutter app — centralised route declarations, typed routes and path constants, StatefulShellRoute for bottom navigation, auth redirect guards (deferred until auth lands, ADR-001), 404 handling, deep links, and correct back behaviour on Android and iOS. Use this skill when adding a screen or route, wiring bottom navigation or nested navigation, implementing login redirects or route guards, handling deep links or cold-start links, passing data between screens, or debugging a wrong back-button or duplicated-stack behaviour.
---
```

Replace

```markdown

Covers checklist Phase 8. Router configuration lives in `app/router/`.

```

with

```markdown

Router configuration lives in `app/router/`.

```

Replace

````markdown
├── route_paths.dart     # path + name constants
└── route_guards.dart    # (not yet — auth is deferred, AD-03; add with the auth phase)
```
````

with

````markdown
├── route_paths.dart     # path + name constants
└── route_guards.dart    # (not yet — login comes later, ADR-013; add it with login)
```
````

Replace

```markdown

> **Deferred until auth lands (AD-03).** This section is reference material for
> that phase — do not build an auth guard, login flow or `authStateProvider` now.

```

with

```markdown

> **Deferred until login lands (ADR-013: identity now, login later).** This
> section is reference material for that phase — do not build an auth guard,
> login flow or `authStateProvider` now.

```

In `.claude/skills/flutter-project-setup/SKILL.md`:

Replace

```markdown
name: flutter-project-setup
description: Stands up the Flutter project skeleton and everything that is decided once and constrains the rest of the build — toolchain check, git repo conventions, `flutter create` with the right org and IDs, the dependency set and why each package is there, dev dependencies and code generation, build flavors for dev/staging/prod, the bootstrap function with error boundaries, and the Failure/error model. Use this skill when creating a new Flutter app, adding or auditing dependencies, wiring `main.dart` and bootstrap, setting up environments or flavors, configuring build_runner, or designing how errors are represented across layers. Covers checklist phases 2, 3 and 6.
---
```

with

```markdown
name: flutter-project-setup
description: Stands up the Flutter project skeleton and everything that is decided once and constrains the rest of the build — toolchain check, git repo conventions, `flutter create` with the right org and IDs, the dependency set and why each package is there, dev dependencies and code generation, build flavors for dev/staging/prod, the bootstrap function with error boundaries, and the Failure/error model. Use this skill when creating a new Flutter app, adding or auditing dependencies, wiring `main.dart` and bootstrap, setting up environments or flavors, configuring build_runner, or designing how errors are represented across layers.
---
```

Replace

```markdown

Covers checklist Phases 2 (environment), 3 (dependencies) and 6 (bootstrap,
flavors, error model). These are grouped because they are decided once and
constrain everything after — the flavor decides the log level bootstrap
installs, and the error model decides what the error boundary reports.

Prerequisite: the product section of `docs/README.md` and
`docs/shared/decisions/ADR-001-quyet-dinh-nen-tang.md` answer platforms,
online/offline and auth. Those three answers change the dependency set, so setting up before they
are settled means redoing it.

## 2.1 Toolchain

```

with

```markdown

The environment, the dependencies, bootstrap, flavors and the error model are
grouped because they are decided once and constrain everything after — the
flavor decides the log level bootstrap installs, and the error model decides
what the error boundary reports.

Prerequisite: the product section of `docs/README.md` and two ADRs in
`docs/shared/decisions/` answer platforms (ADR-001), online/offline and
identity (ADR-013). Those three answers change the dependency set, so setting
up before they are settled means redoing it.

## Toolchain

```

Replace

```markdown

Use Flutter stable. Record the exact version in `docs/architecture.md` and pin
it in CI — "works on my machine" is nearly always a toolchain drift.
```

with

```markdown

Use Flutter stable. Record the exact version in `.fvmrc` (ADR-010) and pin
it in CI — "works on my machine" is nearly always a toolchain drift.
```

Replace

```markdown

## 2.2 Repository conventions

- `.gitignore` — start from the Flutter template, then confirm it excludes
  generated code you do not intend to commit (`*.g.dart`, `*.freezed.dart`),
  `.env` files, signing keys, and `**/google-services.json` if it holds secrets.
```

with

```markdown

## Repository conventions

- `.gitignore` — start from the Flutter template, then confirm it excludes
  generated code you do not intend to commit (`*.g.dart`),
  `.env` files, signing keys, and `**/google-services.json` if it holds secrets.
```

Replace

```markdown
  CI must run `build_runner` before analyze. Not committing is the better default
  here because CI already runs codegen as a freshness check (Phase 19.1).
- Conventional Commits, scoped by feature: `feat(deck):`, `fix(card):`.
```

with

```markdown
  CI must run `build_runner` before analyze. Not committing is the better default
  here because CI already runs codegen as a freshness check (`flutter-ship`).
- Conventional Commits, scoped by feature: `feat(deck):`, `fix(card):`.
```

Replace

```markdown

## 2.3 Creating the project

```

with

```markdown

## Creating the project

```

Replace

```markdown

## 6.1 Bootstrap

```

with

```markdown

## Bootstrap

```

Replace

```markdown

## 6.2 Environments and flavors

> **Not in V8 yet.** MemoX V8 is local-only (ADR-001): no API base URL, no
> staging backend, no analytics. So it has no flavors, no `EnvConfig` and no
> `app/config/` (ADR-011). The rest of this section applies once an ADR opens
> networking.

```

with

```markdown

## Environments and flavors

> **Not in V8 yet.** The app calls no API yet (ADR-012): no API base URL, no
> staging backend, no analytics. So it has no flavors, no `EnvConfig` and no
> `app/config/` (ADR-011). The rest of this section applies from the first API
> call, when the base URL has to come from somewhere.

```

Replace

```markdown

## 6.3 Error model

```

with

```markdown

## Error model

```

Replace

```markdown
Put the mapping in one place (`core/error/`) so every repository maps the same
exception to the same failure, and test it (Phase 15.1) — error mapping is the
code most likely to be wrong and least likely to be exercised by hand.
```

with

```markdown
Put the mapping in one place (`core/error/`) so every repository maps the same
exception to the same failure, and test it (`flutter-testing`) — error mapping is the
code most likely to be wrong and least likely to be exercised by hand.
```

Replace the whole of `.claude/skills/flutter-project-setup/references/dependencies.md` with:

````markdown
# Dependencies

Add with `flutter pub add <pkg>` / `flutter pub add --dev <pkg>` so version
constraints are written correctly, then commit `pubspec.lock`.

Do not hardcode versions from memory — check pub.dev for the current release
that matches the Flutter version in use. Versions below are the major line this
project targets, not exact pins.

## Runtime

**Not yet for MemoX V8:** `dio`, `retrofit` and `json_annotation` are
deliberately absent until the first feature calls the API (ADR-012). An unused
HTTP client still costs build time, still needs upgrading, and still suggests a
network layer exists.

The table is `pubspec.yaml` as it stands; a package added there gets a row here
in the same commit.

| Package | Line | Why it is here |
|---|---|---|
| `flutter_riverpod` | 3.x | State + DI. Compile-safe, testable without a widget tree. |
| `riverpod_annotation` | 4.x | Annotations for the generator. |
| `go_router` | 18.x | Declarative routing, deep links, redirect guards. |
| `drift` | 2.x | Typed SQLite with migrations and reactive queries. |
| `drift_flutter` | 0.3.x | Opens the database: a background isolate on native, the WASM worker on web (`lib/core/database/connection.dart`). |
| `sqlite3` | 3.x | The native SQLite library, supplied through native assets, and the `SqliteException` codes `mapDatabaseError` reads. |
| `flutter_localizations` | SDK | Material strings for the supported locales; `flutter: generate: true` builds the ARB files. |
| `intl` | — | Locale-aware dates and numbers. |
| `uuid` | 4.x | Client-generated IDs (ADR-007). Needed **from day one**: a row created offline keeps its ID through sync (ADR-013), and changing the primary-key strategy later means rewriting every foreign key. |
| `characters` | — | Counts user text in graphemes, so a length limit counts what the user sees. |
| `csv` | 8.x | Reads and writes CSV/TSV for import and export (`transfer`). |
| `excel` | 4.x | Reads `.xlsx` sources for import (`transfer`). |
| `file_picker` | 13.x | Picks the file to import. |
| `share_plus` | 13.x | Hands an export to the platform share sheet. |
| ~~`sqlite3_flutter_libs`~~ | — | **Do not add it.** The only version compatible with current Drift is `0.6.0+eol` — a tombstone with no native code in it. `sqlite3` 3.x supplies the native library through native assets instead, so Drift on mobile needs no separate package. The row is struck rather than deleted because a session that has seen the old advice will look for it here. |

Add only when the need is real:

| Package | Add when |
|---|---|
| `dio`, `retrofit`, `json_annotation` | The first API call (ADR-012): one shared `Dio` in `core/network/`, a Retrofit interface per endpoint group, `json_serializable` DTOs in `data/models/`. |
| `flutter_secure_storage` | Tokens exist, which needs login (ADR-013: login comes later). Keychain / EncryptedSharedPreferences, never SharedPreferences. |
| `connectivity_plus` | You show an offline state or trigger sync on reconnect. Note it reports link state, not reachability — a captive portal reads as online. |
| `cached_network_image` | You render remote images in lists. |
| `sentry_flutter` / `firebase_crashlytics` | Entering release (`flutter-ship`). Not before. |

## Dev

| Package | Why |
|---|---|
| `build_runner` | Runs all generators. |
| `riverpod_generator` | `@riverpod` → providers. |
| `drift_dev` | Drift table and DAO codegen, and the schema dumps in `drift_schemas/`. |
| `fake_async` | Drives timers and the day clock in tests. |
| `flutter_lints` | Baseline rule set that `analysis_options.yaml` extends. |
| ~~`riverpod_lint`~~ | **Descoped** — it needs `custom_lint` as its host. Its checks moved to code-verification-guard. |
| ~~`custom_lint`~~ | **Descoped.** No published version supports `analyzer >=10`, which `drift_dev` and the Riverpod generator require. Its job is now code-verification-guard's (the `memox-v8` ruleset). |

Not here, on purpose: `freezed` (value classes are written by hand, and DTOs
are `json_serializable`, never Freezed — ADR-012), `retrofit_generator` and
`json_serializable` until the first API call (ADR-012), `mocktail` (tests fake
the domain contracts instead), and a golden package (goldens run through
`test/support/golden_harness.dart`).

## Code generation

```bash
dart run build_runner build --delete-conflicting-outputs   # one-shot
dart run build_runner watch --delete-conflicting-outputs   # while developing
```

`--delete-conflicting-outputs` is nearly always what you want; without it a
renamed file leaves a stale generated file that then fails the build in a way
that points at the wrong place.

Generated output is not committed (`.gitignore`: `*.g.dart`), so CI runs codegen
before analyze, and `check_generated.py` proves that a clean rebuild reproduces
it.

## Traps worth knowing before you hit them

- **Riverpod 3 dropped the generated per-provider `Ref` subclasses.** Write
  `Ref ref`, not `MyThingRef ref`. Examples written for 2.x will not compile.
- **`riverpod_lint` and `custom_lint` are descoped** — do not try to add them.
  Every published `custom_lint` caps at `analyzer ^8`, while the generator stack
  needs `analyzer >=10`; installing them would force the analyzer, and the
  generators built on it, below the versions this project uses. Their checks
  are owned by **code-verification-guard** (the `memox-v8` ruleset).
  Do **not** put `analyzer: plugins: - custom_lint` in `analysis_options.yaml`:
  a plugin declared but not installed is silently ignored, so the rules look
  configured and never run.
- **Drift does NOT need `sqlite3_flutter_libs`** any more, and adding it is the
  mistake this line used to cause. That package is now `0.6.0+eol` — a tombstone
  that ships no native code — and `sqlite3` 3.x supplies the native library
  through native assets. On mobile Drift works with `sqlite3` alone. If a
  runtime failure to open the database sends you looking for a missing native
  lib, check the `sqlite3` version rather than reaching for the dead package.

## Auditing what is already there

```bash
flutter pub outdated
flutter pub deps --style=compact
```

For each direct dependency ask: is it still used, is it still maintained, is
there a second package doing the same job, and is the licence acceptable? Drop
what fails. An unused dependency still costs build time and still breaks on
upgrade.
````

In `.claude/skills/flutter-ship/SKILL.md`:

Replace

```markdown
name: flutter-ship
description: Everything between "the features work" and "users are running it well" for this Flutter app — security review, performance profiling and rebuild scoping, logging abstraction and crash/analytics integration, CI pipeline with format/analyze/codegen-freshness/test/build gates, PR quality gates, signed flavored release builds, store metadata and Android/iOS submission, the pre-release checklist, and post-release monitoring. Use this skill when setting up or fixing CI, preparing a release or store submission, configuring signing or obfuscation, adding logging or analytics or crash reporting, doing a security or performance pass, or investigating crashes and metrics after a release. Covers checklist phases 16 through 22.
---
```

with

```markdown
name: flutter-ship
description: Everything between "the features work" and "users are running it well" for this Flutter app — security review, performance profiling and rebuild scoping, logging abstraction and crash/analytics integration, CI pipeline with format/analyze/codegen-freshness/test/build gates, PR quality gates, signed flavored release builds, store metadata and Android/iOS submission, the pre-release checklist, and post-release monitoring. Use this skill when setting up or fixing CI, preparing a release or store submission, configuring signing or obfuscation, adding logging or analytics or crash reporting, doing a security or performance pass, or investigating crashes and metrics after a release.
---
```

Replace

```markdown

Covers checklist Phases 16–22. They share a trigger — the project is heading
toward release — and in practice several get touched in one session.

```

with

```markdown

Security, performance, observability, CI/CD and release share a trigger — the
project is heading toward release — and in practice several get touched in one
session.

```

Replace

```markdown

## 16 · Security

```

with

```markdown

## Security

```

Replace

```markdown

## 17 · Performance

```

with

```markdown

## Performance

```

Replace

```markdown

## 18 · Logging, analytics, monitoring

```

with

```markdown

## Logging, analytics, monitoring

```

Replace

```markdown

## 19 · CI/CD

```

with

```markdown

## CI/CD

```

Replace

```markdown

Before shipping, the Phase 21 list, of which these are the ones most often
skipped and most damaging when wrong:
```

with

```markdown

Before shipping, the pre-release list, of which these are the ones most often
skipped and most damaging when wrong:
```

Replace

```markdown

## 22 · After release

```

with

```markdown

## After release

```

Replace

```markdown
stabilised** (a permanent flag is permanent complexity and a permanent untested
code path), and schedule the technical debt recorded in `docs/wbs.md` rather
than letting it accumulate silently.
```

with

```markdown
stabilised** (a permanent flag is permanent complexity and a permanent untested
code path), and schedule the technical debt recorded in `docs/wbs_BE.md` and
`docs/wbs_FE.md` rather
than letting it accumulate silently.
```

In `.claude/skills/flutter-state-riverpod/SKILL.md`:

Replace

```markdown
name: flutter-state-riverpod
description: Riverpod 3.x provider and controller design for this Flutter app — when to use @riverpod codegen, Notifier vs AsyncNotifier, family and autoDispose, how to model screen state as an immutable sealed class covering initial/loading/loaded/empty/error/refreshing/submitting, separating data from task status, and running side effects like navigation, snackbars and dialogs without firing them on rebuild. Use this skill when creating or changing a provider or controller, modelling screen state, deciding where async work belongs, fixing an infinite rebuild or a provider that refuses to dispose, or when a controller is tempted to hold a BuildContext. Covers checklist phase 9.
---
```

with

```markdown
name: flutter-state-riverpod
description: Riverpod 3.x provider and controller design for this Flutter app — when to use @riverpod codegen, Notifier vs AsyncNotifier, family and autoDispose, how to model screen state as an immutable sealed class covering initial/loading/loaded/empty/error/refreshing/submitting, separating data from task status, and running side effects like navigation, snackbars and dialogs without firing them on rebuild. Use this skill when creating or changing a provider or controller, modelling screen state, deciding where async work belongs, fixing an infinite rebuild or a provider that refuses to dispose, or when a controller is tempted to hold a BuildContext.
---
```

Replace

```markdown

Covers checklist Phase 9. Riverpod 3.x with code generation.

```

with

```markdown

Riverpod 3.x with code generation.

```

Replace

```markdown
Stream<List<DeckListItem>> deckList(Ref ref, String? parentId) =>
    ref.watch(watchDeckListUseCaseProvider)(parentId);   // AD-12: through the
                                                         // use case, never the
                                                         // repository directly

```

with

```markdown
Stream<List<DeckListItem>> deckList(Ref ref, String? parentId) =>
    // ADR-011 D4: through the use case, never the repository directly.
    ref.watch(watchDeckListUseCaseProvider)(parentId);

```

Replace

```markdown
for things that are genuinely app-scoped — repositories, the database, config
(and, when networking lands per ADR-012, the HTTP client). Screen data is not app-scoped; keeping it alive is how a user
sees another account's data after switching.

```

with

```markdown
for things that are genuinely app-scoped — repositories, the database, config
(and, when networking lands per ADR-012, the HTTP client). Screen data is not
app-scoped; keeping it alive is how a user sees another account's data after
switching.

```

Replace

```markdown
rebuilds only when that field changes. Watching a whole object to read one field
rebuilds on every unrelated change — the same point Phase 17 makes about limiting
rebuild scope.

```

with

```markdown
rebuilds only when that field changes. Watching a whole object to read one field
rebuilds on every unrelated change.

```

Replace

```markdown
value without subscribing, so the widget silently stops updating — a bug that
looks like "the data is stale" and is hard to trace back. `riverpod_lint` used to
catch this; it is descoped (`docs/wbs.md`), so the check now lives in
**code-verification-guard** (`memox.state_management.no_ref_read_in_build`).
Nothing in `flutter analyze` covers it.

```

with

```markdown
value without subscribing, so the widget silently stops updating — a bug that
looks like "the data is stale" and is hard to trace back. `riverpod_lint` used
to catch this; it is descoped (see `flutter-architecture`), so the check now
lives in **code-verification-guard**
(`memox.state_management.no_ref_read_in_build`). Nothing in `flutter analyze`
covers it.

```

Replace

````markdown
```dart
@freezed
sealed class DeckListState with _$DeckListState {
  const factory DeckListState({
    @Default(AsyncValue<List<Deck>>.loading()) AsyncValue<List<Deck>> decks,
    @Default(false) bool isRefreshing,
    @Default(<String>{}) Set<String> deletingIds,   // per-item, not global
    String? actionError,
  }) = _DeckListState;
}
````

with

````markdown
```dart
@immutable
final class DeckListState {
  const DeckListState({
    this.decks = const AsyncValue<List<Deck>>.loading(),
    this.isRefreshing = false,
    this.deletingIds = const <String>{},   // per-item, not global
    this.actionError,
  });

  final AsyncValue<List<Deck>> decks;
  final bool isRefreshing;
  final Set<String> deletingIds;
  final String? actionError;
}
````

Replace

```markdown

State is immutable — `freezed`, or a hand-written class with `copyWith` and
value equality. A mutated-in-place object can compare equal to itself and the UI
will not rebuild, which presents as "the screen doesn't update" with no error.

```

with

```markdown

State is immutable: an `@immutable` class whose every change builds a new
object, written by hand — V8 does not use `freezed`.
`lib/features/settings/presentation/states/settings_state.dart` is one, with an
in-flight set in the role of `deletingIds`. A mutated-in-place object can
compare equal to itself and the UI will not rebuild, which presents as "the
screen doesn't update" with no error.

```

- [ ] **Step 5: flutter-theme-design: without V7's history**

In `.claude/skills/flutter-theme-design/references/buttons-actions.md`:

Replace

```markdown

**Nguyên tắc chương này, trả giá mới có (M99.61):** đổi resting fill/foreground
của một component khỏi cặp canonical của Material thì **mọi state default
```

with

```markdown

**Nguyên tắc chương này:** đổi resting fill/foreground
của một component khỏi cặp canonical của Material thì **mọi state default
```

Replace

```markdown
      hardcode; đổi resting pair mà bỏ ba slot này là mực hệ khác trên fill hệ
      này (bug thật, M99.61).
- [ ] Size.
```

with

```markdown
      hardcode; đổi resting pair mà bỏ ba slot này là mực hệ khác trên fill hệ
      này.
- [ ] Size.
```

In `.claude/skills/flutter-theme-design/references/chrome-navigation.md`:

Replace

```markdown
- [ ] Selected weight — qua `withWeight`, vì `copyWith(fontWeight:)` trần trên
      variable font vẽ weight cũ (bug thật, M99.61).
- [ ] Label visibility.
```

with

```markdown
- [ ] Selected weight — qua `withWeight`, vì `copyWith(fontWeight:)` trần trên
      variable font vẽ weight cũ.
- [ ] Label visibility.
```

Replace

```markdown

Chỉ build nếu tablet/desktop layout support rail. (Lưu ý: AD-04 hiện không ship
large-screen layout — mục này chờ quyết định đó đổi.)

```

with

```markdown

Chỉ build nếu tablet/desktop layout support rail. (Lưu ý: ADR-001 hiện không
ship large-screen layout — mục này chờ quyết định đó đổi.)

```

In `.claude/skills/flutter-theme-design/references/foundation.md`:

Replace

```markdown

Hoặc `AppTextStyles`, nhưng feature không `.copyWith(fontSize: ...)`.

**Đã ship (M99.66), theo nhánh `AppTextStyles`:** feature chọn rung rồi áp mực
đóng — `texts.bodySmall!.inked(context, AppInk.quiet, isEmphasized:,
isTabular:)` — hoặc vai đặt tên (`cardPrompt`, `sectionLabel`,
`sectionLabelSmall`, `listHeading`, `stateChipLabel`, `heroNumeral`). Guard
`no_text_restyle` cấm `texts.*.copyWith` lẫn đường vòng
`withWeight(...).copyWith`; `withWeight` thuần (nhấn không đổi màu) vẫn hợp lệ.
Tổ hợp nào hai API không nói được là một vai còn thiếu — thêm vào
`lib/core/theme`, không lắp tại chỗ.

**Bẫy variable font (đã trả giá ba lần trong repo này):** cả hai face đều là
variable font có trục `wght`; một `copyWith(fontWeight:)` trần báo weight mới
cho test và vẽ weight cũ trên máy. Mọi re-weight đi qua
`AppTypography.withWeight`, và test pin `fontVariations`, không chỉ
`fontWeight`.

```

with

```markdown

Hoặc một lớp vai chữ đặt tên (V8: `MxTextStyles` trong
`lib/core/theme/mx_text_styles.dart`), nhưng feature không
`.copyWith(fontSize: ...)`.

Guard `no_text_restyle` cấm `texts.*.copyWith` lẫn đường vòng
`withWeight(...).copyWith`; `withWeight` thuần (nhấn không đổi màu) vẫn hợp lệ.
Tổ hợp nào vai chữ không nói được là một vai còn thiếu — thêm vào
`lib/core/theme`, không lắp tại chỗ.

**Bẫy variable font:** font của app là variable font có trục `wght`; một
`copyWith(fontWeight:)` trần báo weight mới cho test và vẽ weight cũ trên máy.
Mọi re-weight đi qua `AppTypography.withWeight`, và test pin `fontVariations`,
không chỉ `fontWeight`.

```

Replace

```markdown

**Đã ship (M99.66).** Tone dùng chung enum `AppInk` với chữ; size enum
`MxIconSize` (16/20/24/40); không nhãn ⇒ tự loại khỏi semantics. `Icon` trần
vẫn hợp lệ trong slot đã theme (leading của button/tile); guard
`no_raw_icon_color` cấm `Icon(color:)` mở — ngoại lệ duy nhất là
`<AppInk>.resolve(context)` cho size không có bậc (hero 32, mark bám font
size).

```

with

```markdown

`Icon` trần vẫn hợp lệ trong slot đã theme (leading của button/tile); guard
`no_raw_icon_color` cấm `Icon(color:)` mở — ngoại lệ duy nhất là màu đọc qua
`.resolve(context)` cho size không có bậc.

```

Replace the whole of `.claude/skills/flutter-theme-design/references/legacy-and-guards.md` with:

````markdown
# X. Legacy · XI. Banned raw widgets · XIV. Static guard · XV. Admission rule

## 53. `ToggleButtonsThemeData`

Policy:

- [ ] Không dùng mới.
- [ ] Dùng `SegmentedButton`.
- [ ] Guard raw `ToggleButtons`.
- [ ] Không tạo Mx wrapper.

## 54. `ButtonThemeData`

Legacy theme used by old Material widgets.

Policy:

- [ ] Không dùng để style modern buttons.
- [ ] Không coi nó là action design system.
- [ ] Chỉ set fallback nếu legacy Flutter widget còn đọc nó.
- [ ] Không tạo shared wrapper dựa trên `ButtonThemeData`.

## XI. Raw widgets không nên có visual freedom ở feature layer

Guard trực tiếp trong `lib/features/**`. **Trạng thái hiện tại:** ba rule
phủ phần đánh dấu `[x]` — `no_raw_button`, `no_raw_widget` và
`no_raw_style_escape`. Mỗi mục thêm phải kèm lượt chạy chứng minh
**hai chiều**: rule bắn đúng site hiện có (hoặc một probe file cố ý vi phạm)
rồi về 0 — và đếm site phải dùng `[<(]` chứ không chỉ `\(`, vì
`RadioListTile<T>(` và `showModalBottomSheet<void>(` lọt lưới `\(` trần.

**Nhóm hoãn:** `TextField` và chips chưa vào danh sách cấm. Wrapper chỉ đáng
dựng khi nó chốt thêm một quyết định mà `InputDecorationTheme` hay `ChipTheme`
chưa chốt; khi chỉ chuyển code sang chỗ khác thì nó chưa đáng dựng.

**Regex theo dòng có lối thoát:** một lời gọi xuống dòng trước tham số
(`Icon(` rồi `color:` ở dòng sau) lọt qua pattern một dòng. Rule cần thấy
*cấu trúc* thì thành test Dart (quét ngoặc cân bằng), không cố nhồi vào regex.
`showModalBottomSheet` **không** vào danh sách cấm: hàm `showX` trong bucket
`overlays/` gọi nó trực tiếp, và đó là pattern hợp lệ (ADR-011 D8).

- [x] `FilledButton`
- [x] `OutlinedButton`
- [x] `TextButton`
- [x] `ElevatedButton`
- [x] `IconButton`
- [x] `FloatingActionButton`
- [x] `Card`
- [x] `ListTile`
- [x] `Checkbox`
- [x] `CheckboxListTile`
- [x] `Radio`
- [x] `RadioListTile`
- [x] `Switch`
- [x] `SwitchListTile`
- [ ] `ChoiceChip`
- [ ] `FilterChip`
- [ ] `ActionChip`
- [ ] `InputChip`
- [x] `SegmentedButton`
- [ ] `TextField`
- [x] `TextFormField`
- [x] `NavigationBar`
- [x] `NavigationDrawer`
- [x] `NavigationRail`
- [x] `BottomNavigationBar`
- [x] `BottomAppBar`
- [x] `Dialog`
- [x] `AlertDialog`
- [x] Direct `showDialog`
- [ ] Direct `showModalBottomSheet`
- [x] `PopupMenuButton`
- [x] `DropdownMenu`
- [x] `DropdownButton`
- [x] `SnackBar`
- [x] `MaterialBanner`
- [x] `SearchBar`
- [x] `SearchAnchor`
- [x] `Slider`
- [x] `RangeSlider`
- [x] `TabBar`
- [x] `ExpansionTile`
- [x] `Badge`
- [x] Direct interactive `InkWell`
- [x] Direct interactive `InkResponse`

Cho phép raw layout primitives: `Row`, `Column`, `Stack`, `Wrap`, `Flex`,
`Expanded`, `Flexible`, `Align`, `Center`, `Positioned`, `Padding`, `SizedBox`,
`Spacer`, `LayoutBuilder`, scrolling/layout primitives khi không tự mang
visual language.

## XIV. Feature layer static guard

Trong `lib/features/**`, fail CI nếu xuất hiện visual escapes như:

- [x] `Color(` — `no_raw_color` (design-token)
- [x] `Colors.` — `no_raw_color`
- [x] `TextStyle(` — `no_raw_text_style`
- [x] `BorderRadius.circular(` số trần — `no_raw_border_radius`
- [x] `BorderSide(` — `no_raw_style_escape`
- [x] `BoxShadow(` — `no_raw_style_escape`
- [x] `ButtonStyle(` — `no_raw_style_escape`
- [x] `.styleFrom(` — `no_raw_style_escape` (features), và
      `no_flat_style_from` scope `widget_ui_files` phủ cả `lib/shared/widgets`
- [x] `ShapeDecoration(` — `no_raw_style_escape`
- [x] `RoundedRectangleBorder(` — `no_raw_style_escape`
- [x] `Icon(size:` số trần — `no_raw_style_escape`
- [x] `WidgetStateProperty`/`MaterialStateProperty` — `no_raw_style_escape`
- [x] `fontWeight: FontWeight.` — `no_bare_font_weight`, scope rộng hơn
      (cả `lib/shared` và `lib/core/theme`), vì bug này không chỉ sống trong
      features
- [x] Raw interactive Material widgets — `no_raw_button` + `no_raw_widget`
- [x] `texts.*.copyWith` và `withWeight(...).copyWith` — `no_text_restyle`:
      feature đọc vai chữ, không pha style
- [x] `Icon(color:)` mở — `no_raw_icon_color`; `.resolve(` là cách
      viết hợp lệ duy nhất cho size ngoài bậc

Allowlist chỉ dành cho:

```
lib/core/theme/**
lib/shared/widgets/**
```

và exception phải có comment/rule ID.

**Chỗ đặt rule trong repo này:**
`code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`,
scope `presentation_files` (không phải `ui_surfaces` — `lib/shared/` là nơi
primitives dựng raw widget hợp lệ). Ruleset `memox` cũ có rule tương tự nhưng
scope layer-first: load lại sẽ **xanh mà không match gì** — viết rule mới, đừng
trỏ manifest sang file cũ.

## XV. Admission rule cho raw Material widget mới

Trước khi feature được dùng một Material widget chưa support:

- [ ] Tìm ThemeData slot tương ứng.
- [ ] Xác định raw widget đọc những default nào — **đọc SDK thật**, đừng đoán:
      default có thể hardcode theo cặp màu cũ (`_FABDefaultsM3`) hoặc tự tổng
      hợp overlay (`IconButton.styleFrom`).
- [ ] Liệt kê các default không thể theme.
- [ ] Map color roles.
- [ ] Map typography.
- [ ] Map radius/shape.
- [ ] Map elevation.
- [ ] Map internal geometry.
- [ ] Map states.
- [ ] Map accessibility.
- [ ] Build shared wrapper nếu ThemeData không đủ.
- [ ] Add golden/state tests.
- [ ] Add raw-widget guard.
- [ ] Sau đó feature mới được sử dụng Mx component.

Không được:

> feature dùng raw trước → thấy xấu → override cục bộ → vài tháng sau mới nghĩ
> đến shared widget.

Luồng đúng:

> Design decision → token → ThemeData → shared widget → tests → feature.

**Ngoại lệ có kiểm soát — planned themes:** một theme cho component chưa render
được phép vào `ThemeData` khi và chỉ khi qua admission test ba điều kiện: chỉ
restate token đã quyết và đã đo; component có tên trong roadmap thật; M3
default sai theo cách đã xác lập.
````

In `.claude/skills/flutter-theme-design/references/overlays-menus.md`:

Replace

```markdown
overlay khai elevation explicit — SnackBar từng là cái cuối cùng để SDK tự
quyết (6.0, kể cả ở dark nơi app đã tắt bóng), và đó là một bug thật (M99.61).

```

with

```markdown
overlay khai elevation explicit — SnackBar từng là cái cuối cùng để SDK tự
quyết (6.0, kể cả ở dark nơi app đã tắt bóng).

```

In `.claude/skills/flutter-theme-design/references/surfaces-containers.md`:

Replace

```markdown

Recipe theo meaning (AD-23, M99.83): `flat` · `raised` · `focal` · `recessed`
· `feedback` · `muted` · `tonal` · `accent` · `tile` · `option` — mỗi recipe
là một named constructor map 1-1 vào private spec. Không đặt tên theo
feature (`study`, `deck`).

- [x] Internal padding là enum đóng `MxCardPadding { none, compact, standard }`;
      `none` = child tự sở hữu content area.
- [x] Interactive card có hover/press/focus riêng; focus ring chỉ vẽ ở
      `FocusHighlightMode.traditional` (cùng gate với autofocus của button).
- [x] Non-interactive card không giả button state; `onLongPress` không cần
      `onTap` vẫn phải reach được.
- [x] Không expose `color/radius/shadow/elevation/EdgeInsets` — enforced bằng
      `test/app/shared_api_closure_test.dart` (allowlist AST) và
      `test/app/card_activation_wrapper_test.dart`.
- [x] Selection: tri-state `isSelected` thuộc card (M99.70); selected fill là
      `MxCardSelectionTreatment { edge, tint }`, không phải `Color`.
- [x] Interactive card giữ sàn 48×48 structural, không nhờ padding.

```

with

```markdown

Biến thể theo meaning, không theo feature (`study`, `deck`): mỗi biến thể map
1-1 vào một spec riêng của card.

- [ ] Internal padding là một lựa chọn đóng; card không nhận `EdgeInsets` tuỳ ý.
- [ ] Interactive card có hover/press/focus riêng; focus ring chỉ vẽ ở
      `FocusHighlightMode.traditional` (cùng gate với autofocus của button).
- [ ] Non-interactive card không giả button state; `onLongPress` không cần
      `onTap` vẫn phải reach được.
- [ ] Không expose `color/radius/shadow/elevation/EdgeInsets`.
- [ ] Selection: `isSelected` thuộc card; treatment của trạng thái chọn là một
      lựa chọn đóng, không phải `Color`.
- [ ] Interactive card giữ sàn 48×48 structural, không nhờ padding.

```

Replace

```markdown
Lưu ý repo: `badgeTheme` từng bị **từ chối** khỏi nhóm component theme chưa có renderer (khi đó là `app_planned_themes.dart`) vì
due-vs-overdue là một quyết định cần màn hình (BR-161) — mục này chỉ mở khi
quyết định đó có screen để check.
```

with

```markdown
Lưu ý repo: `badgeTheme` từng bị **từ chối** khỏi nhóm component theme chưa có renderer (khi đó là `app_planned_themes.dart`) vì
due-vs-overdue là một quyết định cần màn hình — mục này chỉ mở khi
quyết định đó có screen để check.
```

- [ ] **Step 6: Run the contract test**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 7 tests` and `OK`.

- [ ] **Step 7: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-data-layer/SKILL.md \
  .claude/skills/flutter-data-layer/references/networking.md \
  .claude/skills/flutter-data-layer/references/persistence.md \
  .claude/skills/flutter-navigation/SKILL.md \
  .claude/skills/flutter-project-setup/SKILL.md \
  .claude/skills/flutter-project-setup/references/dependencies.md \
  .claude/skills/flutter-ship/SKILL.md \
  .claude/skills/flutter-state-riverpod/SKILL.md \
  .claude/skills/flutter-theme-design/references/buttons-actions.md \
  .claude/skills/flutter-theme-design/references/chrome-navigation.md \
  .claude/skills/flutter-theme-design/references/foundation.md \
  .claude/skills/flutter-theme-design/references/legacy-and-guards.md \
  .claude/skills/flutter-theme-design/references/overlays-menus.md \
  .claude/skills/flutter-theme-design/references/surfaces-containers.md \
  .claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 74 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
docs(skills): the six remaining skills keep nothing of V7 (BE-D7)

flutter-data-layer, flutter-navigation, flutter-project-setup,
flutter-ship, flutter-state-riverpod and flutter-theme-design lose V7's
checklist phases, milestones and documents. What they took from V7's
AD-01, AD-03 and AD-05 now follows ADR-012 (Retrofit on one shared Dio,
added with the first API call; DTOs are json_serializable, never Freezed)
and ADR-013 (the server is canonical, the app writes Drift first and
syncs, login comes later). The dependency tables are V8's pubspec.
flutter-theme-design keeps its contract checklists and drops V7's history
and its "shipped" claims about APIs V8 lacks; reconciling it with V8's
widgets is FE-D4.

The contract test now scans all fifteen repo-owned skills, among them
spring-boot-mybatis-review, which had no V7 to remove. It also pins that
every directory under .claude/skills/ is either one of them or a vendored
skill, so a skill cannot leave the scan unnoticed.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: V7's names, paths and error model leave the skills

**Files:**
- Modify: `.claude/skills/flutter-architecture/SKILL.md`, `.claude/skills/flutter-data-layer/SKILL.md`, `.claude/skills/flutter-design-system/SKILL.md`, `.claude/skills/flutter-design-system/references/components.md`, `.claude/skills/flutter-drift/SKILL.md`, `.claude/skills/flutter-drift/references/dynamic-sql-semantics.md`, `.claude/skills/flutter-drift/references/dynamic-sql.md`, `.claude/skills/flutter-drift/references/layering.md`, `.claude/skills/flutter-drift/references/operations.md`, `.claude/skills/flutter-drift/references/query-conventions.md`, `.claude/skills/flutter-drift/references/riverpod-drift.md`, `.claude/skills/flutter-drift/references/schema-conventions.md`, `.claude/skills/flutter-drift/references/testing-database.md`, `.claude/skills/flutter-feature-slice/SKILL.md`, `.claude/skills/flutter-feature-slice/assets/feature_checklist.md`, `.claude/skills/flutter-navigation/SKILL.md`, `.claude/skills/flutter-product-spec/SKILL.md`, `.claude/skills/flutter-project-setup/SKILL.md`, `.claude/skills/flutter-testing/SKILL.md`, `.claude/skills/flutter-theme-design/references/surfaces-containers.md`, `.claude/skills/flutter-workflow/references/definition-of-done.md`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py`, `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`

**Interfaces:**
- Consumes: Task 4's `_occurrences(root, names)` and `ScanTest`.
- Produces: `CITED_PATH`, `PLACEHOLDER`, `GENERATED` (regular expressions),
  `_missing_paths(root: Path = REPO_ROOT, names: tuple[str, ...] = REPO_OWNED_SKILLS)
  -> list[str]`, `test_a_cited_path_must_exist`, `test_every_path_a_skill_cites_exists`,
  and seven more markers.

Spec §12.2 (the paths), §12.3 (the markers, V7 without a marker); Clarifications 4, 5, 7
and 8; Review Focus 2 and 3.

- [ ] **Step 1: Add V7's table names and the path check to the contract test**

The path check reads paths in backticks only; a placeholder or generated output names no
file in a fresh checkout (Clarification 7).

In `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`:

Replace

```python
    r"\bBR-\d",
    r"\bM\d+\.\d+\b",
    r"A20\.1",
```

with

```python
    r"\bBR-\d",
    r"\bM\d+\.\d+[a-z]*\b",
    r"\bM\d+ R\d+\b",
    r"A20\.1",
```

Replace

```python
    r"screen_gallery",
)

```

with

```python
    r"screen_gallery",
    r"\bcard_review_states\b",
    r"\breview_history\b",
    r"\bparent_deck_id\b",
    r"\broot_deck_id\b",
    r"\bSurfaceColumnRule\b",
)

# A path the skills cite, in backticks, from the repo root or from the skill's
# own folder. A placeholder (`<feature>`, `*`, `…`) names no file, and generated
# output is gitignored, so a fresh checkout does not have it yet.
CITED_PATH = re.compile(
    r"`((?:lib|test|docs|tools|integration_test|assets|references|scripts)/[^`\s]*)`"
)
PLACEHOLDER = re.compile(r"[<>*{}$…]")
GENERATED = re.compile(r"\.g\.dart$|/generated/")

```

Replace

```python
        and not SKIPPED_DIRECTORIES.intersection(path.relative_to(skill).parts)
    )


```

with

```python
        and not SKIPPED_DIRECTORIES.intersection(path.relative_to(skill).parts)
    )


def _missing_paths(root: Path = REPO_ROOT, names: tuple[str, ...] = REPO_OWNED_SKILLS) -> list[str]:
    missing = []
    for name in names:
        skill = root / ".claude" / "skills" / name
        for path in _scanned_files(skill):
            text = path.read_text(encoding="utf-8", errors="replace")
            for number, line in enumerate(text.splitlines(), start=1):
                for match in CITED_PATH.finditer(line):
                    cited = match.group(1).rstrip(".,:;")
                    if PLACEHOLDER.search(cited) or GENERATED.search(cited):
                        continue
                    if (root / cited).exists() or (skill / cited).exists():
                        continue
                    relative = path.relative_to(root).as_posix()
                    missing.append(f"{relative}:{number}: {cited}")
    return missing


```

Replace

```python
            "a real bug (M99.61)",
            "until A20.1 P1-08",
```

with

```python
            "a real bug (M99.61)",
            "shipped in Card Import (M99.19a finding V9)",
            "the owner review M6 R7",
            "INNER JOIN card_review_states s",
            "an append-only review_history",
            "COALESCE(parent_deck_id, id)",
            "every deck carries root_deck_id",
            "opt the screen into SurfaceColumnRule",
            "until A20.1 P1-08",
```

Replace

```python
            "Material 3 in lib/core/theme/",
        ):
```

with

```python
            "Material 3 in lib/core/theme/",
            "card_schedule and review_log, parent_id and root_id",
        ):
```

Replace

```python
        )


class RepoOwnedSkillsTest(unittest.TestCase):
```

with

```python
        )

    def test_a_cited_path_must_exist(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "lib").mkdir()
            (root / "lib" / "present.dart").write_text("", encoding="utf-8")
            skill = root / ".claude" / "skills" / "flutter-example"
            (skill / "references").mkdir(parents=True)
            (skill / "references" / "notes.md").write_text("", encoding="utf-8")
            (skill / "SKILL.md").write_text(
                "See `lib/present.dart`, `references/notes.md` and `lib/absent.dart`.\n"
                "A pattern: `lib/features/<feature>/domain/`, `test/**/*_test.dart`.\n"
                "Generated: `lib/l10n/generated/app_localizations.dart`,"
                " `lib/core/database/app_database.g.dart`.\n",
                encoding="utf-8",
            )

            missing = _missing_paths(root, ("flutter-example",))

        self.assertEqual(missing, [".claude/skills/flutter-example/SKILL.md:1: lib/absent.dart"])


class RepoOwnedSkillsTest(unittest.TestCase):
```

Replace

```python

    def test_project_documentation_is_its_own_canonical_source(self):
```

with

```python

    def test_every_path_a_skill_cites_exists(self):
        self.assertEqual(_missing_paths(), [])

    def test_project_documentation_is_its_own_canonical_source(self):
```

- [ ] **Step 2: Run it to see it fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 9 tests` and `FAILED (failures=2)`: `test_every_path_a_skill_cites_exists`
lists nine paths, the first
`.claude/skills/flutter-design-system/SKILL.md:167: test/features/card/presentation/card_import_alignment_test.dart`;
`test_no_repo_owned_skill_names_v7` lists seven lines, the first
`.claude/skills/flutter-design-system/SKILL.md:128: shipped in Card Import (M99.19a finding V9) and no gate saw it.`

- [ ] **Step 3: flutter-drift: V8's tables, due rule and search**

In `.claude/skills/flutter-drift/SKILL.md`:

Replace

```markdown
on every insert into that table, forever. An index whose query nobody can name is
a permanent cost for a speculative benefit — and this project's own composite
index earned its place by measurement (1193µs → 102µs, recorded in
`cards.drift`), which is the standard to hold a new one to.

```

with

```markdown
on every insert into that table, forever. An index whose query nobody can name is
a permanent cost for a speculative benefit. An index earns its place by a
measurement, `EXPLAIN QUERY PLAN` and a timing before and after, which is the
standard to hold a new one to.

```

In `.claude/skills/flutter-drift/references/dynamic-sql-semantics.md`:

Replace

```markdown
  AnyValue()                  => null,                       // contributes no SQL
  EqualsValue(:final value)   => cards.deckId.equals(value),
  IsNullValue()               => cards.deckId.isNull(),
};
```

with

```markdown
  AnyValue()                  => null,                       // contributes no SQL
  EqualsValue(:final value)   => card.deckId.equals(value),
  IsNullValue()               => card.deckId.isNull(),
};
```

Replace

```markdown

This project already relies on the distinction in the read direction:
`dueNowPredicate` is `due_at IS NULL OR due_at <= :now`, because a never-scheduled
card is due. Null there is a *state*, not an absent filter.

The related smell, and this repo has one: a parameter that is only meaningful in
combination with another. `watchCardListItems(..., DateTime? now)` requires `now`
when the filter is `dueNow` and rejects it at runtime with an `ArgumentError`
otherwise. A criteria object can make that unrepresentable rather than checked —
see the criteria section of `dynamic-sql.md`.

```

with

```markdown

This project relies on the distinction in the read direction: a `NULL`
`learned_at` means the card is new (BR-STUDY-051), so "due" is
`learned_at IS NOT NULL AND due_at <= :now`. Null there is a *state*, not an
absent filter.

The related smell: a parameter that is only meaningful in combination with
another, such as a `now` only one filter reads. A criteria object can make that
unrepresentable rather than checked — see the criteria section of
`dynamic-sql.md`.

```

Replace

````markdown
final to   = DateTime.utc(2026, 8, 5);          // exclusive
cards.createdAt.isBiggerOrEqualValue(from) & cards.createdAt.isSmallerThanValue(to);
```
````

with

````markdown
final to   = DateTime.utc(2026, 8, 5);          // exclusive
card.createdAt.isBiggerOrEqualValue(from) &
    card.createdAt.isSmallerThanValue(to);
```
````

Replace

```markdown

This project already knows it. `tags.drift` says so in the schema, and stores a
`name_folded` column written by Dart's `toLowerCase()` — full Unicode folding at
write time — with the unique index on that column rather than on `name COLLATE
NOCASE`. `card_tag_dao_test.dart` inserts `Động từ` twice and requires the second
to fail; that test is what proved the point.

**Card search did not get the same treatment.** `searchPredicate` compares
`instr(lower(front), :term)` where the needle is lowered in Dart and the haystack
is lowered by SQLite:

```

with

```markdown

This project already knows it. `tags` stores a `name_folded` column, folded in
Dart at write time, with the unique index on that column rather than on
`name COLLATE NOCASE`; `test/features/tags/data/tag_repository_impl_test.dart`
requires a name whose folded form matches an existing tag to reuse that tag.

**Card search gets the same treatment.** `card` stores `front_folded` and
`back_folded`, folded in Dart at write time, and the card list and library
search compare the folded term against them with `instr`. Were the haystack
lowered by SQLite instead, it would be folded ASCII-only:

```

Replace

```markdown
|---|---|---|
| needle (search term) | Dart `toLowerCase()` — full Unicode | `công` |
| haystack (stored text) | SQLite `lower()` — ASCII only | `cÔng` |

So a card stored as `CÔNG NGHỆ` cannot be found by typing `công nghệ`. Korean is
unaffected (no case), lowercase Vietnamese is unaffected, and uppercase
Vietnamese entries are not — which is why this survives casual testing. The fix
is the pattern the same repo already uses: fold once at write time into a
column and compare against that.

```

with

```markdown
|---|---|---|
| Dart (`foldText`) | full Unicode | `công` |
| SQLite `lower()` | ASCII only | `cÔng` |

and a card stored as `CÔNG NGHỆ` could not be found by typing `công nghệ`.
Korean is unaffected (no case), lowercase Vietnamese is unaffected, and
uppercase Vietnamese entries are not — which is why that bug survives casual
testing.

```

Replace

````markdown
-- …the index must say it too, or the index is not used.
CREATE INDEX idx_decks_name_nocase ON decks (name COLLATE NOCASE);
```
````

with

````markdown
-- …the index must say it too, or the index is not used.
CREATE INDEX idx_deck_name_nocase ON deck (name COLLATE NOCASE);
```
````

Replace

```markdown

Some predicates are not optional: `deleted_at IS NULL`, `owner_id = :current`,
`workspace_id = :current`, any access-control condition. Exposing them as
criteria fields means every caller can forget one, and the one that forgets is a
data leak rather than a wrong list.

```

with

```markdown

Some predicates are not optional: `delete_batch_id IS NULL`,
`owner_id = :current`, `workspace_id = :current`, any access-control condition.
Exposing them as criteria fields means every caller can forget one, and the one
that forgets is a data leak rather than a wrong list.

```

Replace

```markdown
Expression<bool> mandatoryScope(QueryContext context) =>
    cards.deletedAt.isNull() & cards.ownerId.equals(context.ownerId);

```

with

```markdown
Expression<bool> mandatoryScope(QueryContext context) =>
    card.deleteBatchId.isNull() & deck.ownerId.equals(context.ownerId);

```

Replace

````markdown
```sql
UPDATE cards
SET front = :front, version = version + 1, updated_at = :updatedAt
````

with

````markdown
```sql
UPDATE card
SET front = :front, version = version + 1, updated_at = :updatedAt
````

Replace

```markdown
Then check the affected row count — zero means someone else wrote first, and that
is a `ConflictFailure`, not a success. This becomes essential the moment there is
background sync, autosave, import, or a second isolate. There is no `version`
column here yet; it is the natural place for one when sync arrives.

```

with

```markdown
Then check the affected row count — zero means someone else wrote first, and that
is a refusal, not a success. This becomes essential the moment there is
autosave, import, or a second isolate writing. There is no `version` column
here, and sync does not bring one: ADR-013 settles sync conflicts on the
server, in the order it receives operations, with a `server_version` the server
assigns.

```

Replace

````markdown
```
query=watchCardListItems filters=deck,status,keyword,dateRange
sort=createdAtDesc pagination=window pageSize=50 durationMs=18 rows=50
````

with

````markdown
```
query=cardListWindow filters=deck,status,keyword,tags
sort=createdAtDesc pagination=window pageSize=50 durationMs=18 rows=50
````

In `.claude/skills/flutter-drift/references/dynamic-sql.md`:

Replace

````markdown
```sql
SELECT * FROM cards WHERE deck_id = :deckId;
```
````

with

````markdown
```sql
SELECT * FROM card WHERE deck_id = :deckId;
```
````

Replace

````markdown

**Level 2 is this project's default for a varying query**, because it keeps the
statement — the projection, the joins, the tag `GROUP_CONCAT` — in SQL where
`drift_dev` still type-checks it, while letting Dart decide the filter.
`cardListItems` in `lib/core/database/queries/card.drift` is the worked example:

```sql
cardListItems:
SELECT c.**, s.**, ( … ) AS tag_names
FROM cards c
INNER JOIN card_review_states s ON s.card_id = c.id
WHERE $predicate
````

with

````markdown

**Level 2 keeps the statement in SQL**, where `drift_dev` still type-checks the
projection and the joins, while letting Dart decide the filter:

```sql
cardsOfDeck:
SELECT c.**, s.**
FROM card c
INNER JOIN card_schedule s ON s.card_id = c.id
WHERE $predicate
````

Replace

```markdown
`flagged` emits `c.deck_id = ? AND c.is_flagged = 1` — the same text separate
statements would have emitted, and the same query plan. A template can also
declare a default (`$predicate = TRUE`) for callers that pass nothing.
```

with

```markdown
`flagged` emits `c.deck_id = ? AND c.is_flagged = 1` — the same text separate
statements would have emitted, and the same query plan.

The card list is level 3: `CardListDao` builds its window, its filter counts
and Select all from one `_predicate`, so they never disagree about which cards
a query lets through (BR-CARD-012). A template can also
declare a default (`$predicate = TRUE`) for callers that pass nothing.
```

Replace

```markdown
optional filters it is also a single condition block nobody can reason about.
This project rejected exactly that chain in `card_list_query_mapper.dart` — the
comment there records why.

```

with

```markdown
optional filters it is also a single condition block nobody can reason about.
The card list composes instead (`CardListDao._predicate`).

```

Replace

````markdown
```dart
cards.deckId.equals(deckId);                  // value → bound
cards.status.isIn(codes);                     // values → bound
Variable<String>(term.toLowerCase());         // value → bound
````

with

````markdown
```dart
card.deckId.equals(deckId);                   // value → bound
card.id.isIn(ids);                            // values → bound
Variable<String>(term.toLowerCase());         // value → bound
````

Replace

````markdown
// Both wrong, and the second is wrong even with no user input in sight.
customSelect("SELECT * FROM cards WHERE deck_id = '$deckId'");
final sql = 'SELECT * FROM cards ORDER BY ${criteria.sortColumn}';
```
````

with

````markdown
// Both wrong, and the second is wrong even with no user input in sight.
customSelect("SELECT * FROM card WHERE deck_id = '$deckId'");
final sql = 'SELECT * FROM card ORDER BY ${criteria.sortColumn}';
```
````

Replace

````markdown
```dart
OrderBy cardListOrder(CardListSort sort, Cards c, CardReviewStates s) =>
    switch (sort) {
      CardListSort.newest => OrderBy([
        OrderingTerm.desc(c.createdAt),
        OrderingTerm.desc(c.id),          // tie-breaker, always
      ]),
      CardListSort.dueFirst => OrderBy([
        OrderingTerm.asc(s.dueAt),
        OrderingTerm.desc(c.createdAt),
        OrderingTerm.desc(c.id),
      ]),
    };
```
````

with

````markdown
```dart
List<OrderingTerm> order(CardListSort sort) => switch (sort) {
  CardListSort.newest => [
    OrderingTerm.desc(_card.createdAt),
    OrderingTerm.desc(_card.id),        // tie-breaker, always
  ],
  CardListSort.dueFirst => [
    OrderingTerm.asc(_schedule.learnedAt.isNull()),
    OrderingTerm.asc(_schedule.dueAt),
    OrderingTerm.desc(_card.createdAt),
    OrderingTerm.desc(_card.id),
  ],
};
```
````

Replace

```markdown
- A cursor must carry **every** column in the ordering it pages through.
- Changing the sort invalidates the cursor and the window — see the window-reset
  behaviour in `card_list_filter_controller.dart`.
- Every sort a user can pick should have an index that serves it, or it is a full
```

with

```markdown
- A cursor must carry **every** column in the ordering it pages through.
- Changing the sort invalidates the cursor and the window: whoever owns the
  list resets both.
- Every sort a user can pick should have an index that serves it, or it is a full
```

Replace

```markdown

**Where this project stands:** the card list read threads six parameters through
DAO → data source → repository → use case (`watchCardListItems`). It works and it
is typed, but it is at the size where the criteria object starts paying for
itself — particularly `now`, which is required only for one filter value and is
enforced with a runtime `ArgumentError` today. A criteria object could make that
combination unrepresentable instead of merely checked. Treat this as a refactor
worth proposing, not as a rule the existing code violates.

```

with

```markdown

**Where this project stands:** the card list passes one criteria object,
`CardListQuery` (filter, sort, search term, tags), from the use case down to
`CardListDao`.

```

Replace

````markdown
// This project's convention: an empty filter is no filter.
if (statuses.isEmpty) return null;
return cards.status.isIn(statuses.map((s) => s.code));
```
````

with

````markdown
// This project's convention: an empty filter is no filter.
if (tagIds.isEmpty) return const Constant(true);
return existsQuery(/* the card carries one of tagIds */);
```
````

Replace

```markdown
The same question applies to a blank search term, and the card list answers it
explicitly: `if (term.isEmpty) return predicate` — an empty box narrows nothing.

```

with

```markdown
The same question applies to a blank search term, and the card list answers it
explicitly: `if (term.isEmpty) return inDeck;` — an empty box narrows nothing.

```

Replace

```markdown
stream dependencies, and a query plan that changes per call. Write separate read
models instead — `watchCardsByDeck`, `watchCardListItems`,
`cardStateCountsByDeck` are four statements here precisely because they answer
four questions. A varying *result shape* is the signal to split the query, where
a varying *filter* is not.
```

with

```markdown
stream dependencies, and a query plan that changes per call. Write separate read
models instead — the card list's window, its filter counts and the deck's
workload are separate statements precisely because they answer separate
questions. A varying *result shape* is the signal to split the query, where
a varying *filter* is not.
```

In `.claude/skills/flutter-drift/references/layering.md`:

Replace

```markdown

**May:** call DAOs, combine them, translate `SqliteException` /
`DriftWrappedException` into typed failures.

```

with

```markdown

**May:** call DAOs, combine them, turn a database exception into a typed
failure through `mapDatabaseError`.

```

Replace

```markdown
**Map exceptions here, once.** A constraint violation is not a user-facing
message: it is a `ConflictFailure` with a reason the UI can render in its own
words. `core/error/drift_error_mapper.dart` reads `SqliteException.resultCode` so
that "unique constraint failed" becomes a typed failure rather than a string
somebody parses.

```

with

```markdown
**Map exceptions here, once.** A constraint violation is not a user-facing
message: it is a `ConstraintFailure`, and a rule the repository checks first is
a `Rejected` reason the UI can render in its own words. `mapDatabaseError` in
`core/error/failure.dart` reads `SqliteException.resultCode` so that "unique
constraint failed" becomes a typed failure rather than a string somebody parses.

```

In `.claude/skills/flutter-drift/references/operations.md`:

Replace

```markdown
What is safe and useful: the statement text, its duration, the row count, the
transaction duration, and migration `from`/`to`. `query_log_interceptor.dart`
does the first two and is gated on `kDebugMode` — a compile-time constant rather
than a runtime flag, so the tree shaker removes the interceptor and its log lines
from a release build entirely. For anything adjacent to private data that is
stronger than a flag that can be set wrong and still ship.
```

with

```markdown
What is safe and useful: the statement text, its duration, the row count, the
transaction duration, and migration `from`/`to`. A statement log, if one is
added, is gated on `kDebugMode` — a compile-time constant rather than a runtime
flag, so the tree shaker removes it and its log lines from a release build
entirely. For anything adjacent to private data that is
stronger than a flag that can be set wrong and still ship.
```

In `.claude/skills/flutter-drift/references/query-conventions.md`:

Replace

```markdown
Tables in `tables/*.drift`, queries in `queries/*.drift`, one pair per bounded
area (`deck`, `card`, `tag`, `study`). A query file imports the table files it
reads:
```

with

```markdown
Tables in `tables/*.drift`, queries in `queries/*.drift`, one pair per bounded
area (`deck`, `card`, `trash`). A query file imports the table files it
reads:
```

Replace

````markdown
```sql
import '../tables/cards.drift';
```
````

with

````markdown
```sql
import '../tables/card.drift';
```
````

Replace

```markdown
  card.created_at
FROM cards AS card
WHERE card.deck_id = :deckId
```

with

```markdown
  card.created_at
FROM card
WHERE card.deck_id = :deckId
```

Replace

```markdown
SELECT card.id, card.deck_id, card.front, card.created_at
FROM cards AS card
WHERE card.deck_id = :deckId
```

with

```markdown
SELECT card.id, card.deck_id, card.front, card.created_at
FROM card
WHERE card.deck_id = :deckId
```

Replace

```markdown
- **Do not create an index without a query you can name.** Write the query in the
  index's comment, as `cards.drift` does.
- **Verify with `EXPLAIN QUERY PLAN`** before claiming a speed-up. The signal to
```

with

```markdown
- **Do not create an index without a query you can name.** Write the query in the
  index's comment.
- **Verify with `EXPLAIN QUERY PLAN`** before claiming a speed-up. The signal to
```

In `.claude/skills/flutter-drift/references/riverpod-drift.md`:

Replace

```markdown
db.customSelect(
  'SELECT COUNT(*) AS total FROM cards WHERE deck_id = ?',
  variables: [Variable<String>(deckId)],
  readsFrom: {cards},          // ← without this it emits once and goes silent
).watchSingle();
```

with

```markdown
db.customSelect(
  'SELECT COUNT(*) AS total FROM card WHERE deck_id = ?',
  variables: [Variable<String>(deckId)],
  readsFrom: {card},           // ← without this it emits once and goes silent
).watchSingle();
```

Replace

```markdown

**…with one proven exception.** drift 2.34's analyzer omits tables that a
`.drift` query reads *only through a subquery* when the query also uses nested
star columns (`c.**`) and Dart placeholders (`$predicate`/`$order`). This is
not theory: `cardListItems` reads `card_tags`/`tags` inside its `tag_names`
subquery, and the generated `readsFrom` lists only `cards` and
`card_review_states` — moving the join into `FROM` as a derived table changed
nothing, while `orphanedTags` (a plain query with a `WHERE` subquery) gets its
tables counted fine. The symptom is the silent kind: the list emitted once and
never re-emitted on a tag write, so the row kept a stale chip until something
else touched `cards`.

So, whenever a `.drift` query reads a table only via subquery:

1. **Check the generated `readsFrom`** in `app_database.g.dart` after building.
2. If a table is missing, **complete the dependency set in the DAO** — merge
   the generated watch with `db.tableUpdates(TableUpdateQuery.onAllTables([...]))`
   over the missing tables, re-running `query.get()` on each update
   (`CardDao.watchCardListItems` is the template). The DAO is the right layer:
   it owns Drift specifics, and the repository contract stays untouched.
   Do *not* restructure the SQL to appease the analyzer if that costs the
   query plan (the correlated form keeps the index's early stop).
3. **Pin it with a both-ways repository-level test** — write to the subquery's
   table, expect a re-emit; remove, expect another
   (`test/features/card/data/card_list_tag_invalidation_test.dart`).

```

with

```markdown

**…with one exception worth knowing.** drift's analyzer can leave out of the
generated `readsFrom` a table that a `.drift` query reads *only through a
subquery*, when the query also uses nested star columns (`c.**`) and Dart
placeholders (`$predicate`/`$order`). The symptom is the silent kind: the stream
emits once and never re-emits on a write to that table.

So, whenever a query reads a table only via subquery, or a read is assembled
from several statements:

1. **Check the generated `readsFrom`** in `app_database.g.dart` after building.
2. If a table is missing, **complete the dependency set in the DAO**: watch
   `db.tableUpdates(TableUpdateQuery.onAllTables([...]))` over every table the
   read touches and re-run the read on each update (`CardListDao.changes()`
   watches `card`, `card_schedule`, `card_tags` and `tags`). The DAO is the
   right layer: it owns Drift specifics, and the repository contract stays
   untouched. Do *not* restructure the SQL to appease the analyzer if that
   costs the query plan.
3. **Pin it with a repository-level test** that writes to the table and expects
   a re-emit (`test/features/card/data/card_list_read_test.dart`: tagging a card
   re-emits the list with its tags).

```

Replace

````markdown
```dart
await db.batch((batch) => batch.insertAll(cards, companions));
```
````

with

````markdown
```dart
await db.batch((batch) => batch.insertAll(db.card, companions));
```
````

In `.claude/skills/flutter-drift/references/schema-conventions.md`:

Replace

```markdown
|---|---|---|
| Table | plural `snake_case` | `decks`, `card_review_states`, `review_history` |
| Column | `snake_case` | `deck_id`, `created_at`, `is_flagged` |
```

with

```markdown
|---|---|---|
| Table | `snake_case`, as `docs/shared/data/schema.md` names it | `deck`, `card_schedule`, `review_log` |
| Column | `snake_case` | `deck_id`, `created_at`, `is_flagged` |
```

Replace

```markdown
| Foreign key | `<entity>_id` | `deck_id`, `card_id`, `session_id` |
| Timestamp | `<verb>_at` | `created_at`, `updated_at`, `first_review_at` |
| Boolean | `is_` / `has_` / `can_` | `is_flagged`, `has_completed` |
| Index | `idx_<table>_<cols>` | `idx_cards_deck_created` |
| Unique index | `uq_<table>_<cols>` | `uq_tags_owner_folded` |
| Named query | `lowerCamelCase` | `watchCardsByDeck`, `cardStateCountsByDeck` |

```

with

```markdown
| Foreign key | `<entity>_id` | `deck_id`, `card_id`, `session_id` |
| Timestamp | `<verb>_at` | `created_at`, `updated_at`, `first_answered_at` |
| Boolean | `is_` / `has_` / `can_` | `is_flagged`, `has_completed` |
| Index, unique or not | `idx_<table>_<cols>` | `idx_card_deck_created`, `idx_tags_owner_name_folded` |
| Named query | `lowerCamelCase` | `cardDetail`, `cardHistoryPage` |

```

Replace

```markdown
so there is exactly one spelling of "empty". `due_at` is `NULL` for a card
that has never been scheduled, which is why "due" is `due_at IS NULL OR due_at <=
:now` and not just the comparison.

```

with

```markdown
so there is exactly one spelling of "empty". `due_at` is `NULL` for a card
that is not learned yet, and a card that is not learned is new, never due
(BR-STUDY-051): "due" is `learned_at IS NOT NULL AND due_at <= :now`.

```

Replace

```markdown
That last row is the one this schema is built around, and it is worth restating:
`cards` holds content, `card_review_states` holds the schedule, `review_history`
is append-only. They are separate because reset drops the schedule and keeps the
content and the history. A column added to the wrong one of the three breaks a
rule that no test in the feature you are working on will notice.
```

with

```markdown
That last row is the one this schema is built around, and it is worth restating:
`card` holds content, `card_schedule` holds the schedule, `review_log` is
append-only. They are separate because reset starts the schedule over and keeps
the content and the history (BR-SRS-021). A column added to the wrong one of the
three breaks a rule that no test in the feature you are working on will notice.
```

In `.claude/skills/flutter-drift/references/testing-database.md`:

Replace

```markdown
- [ ] Pagination neither duplicates nor drops a row across a window growth or a
      cursor step — `card_list_window_test.dart` does this by growing the window
      over a deck and comparing the id sets.

```

with

```markdown
- [ ] Pagination neither duplicates nor drops a row across a window growth or a
      cursor step: grow the window over a deck and compare the id sets.

```

Replace

```markdown

This is how "the index is used" stops being a claim. `card_list_window_test.dart`
pins exactly that for the card window: the composite index supplies the order, so
`LIMIT` stops early instead of sorting the deck and putting a lid on it.

```

with

```markdown

This is how "the index is used" stops being a claim: pin it for every query
whose order an index is meant to supply, so `LIMIT` stops early instead of
sorting the whole deck and putting a lid on it.

```

Replace

```markdown
- Repository tests assert **domain** results and failure mapping — a constraint
  violation surfacing as `ConflictFailure`, a missing row as `NotFoundFailure` —
  never the SQL that produced them.
- Provider tests override at `appDatabaseProvider` with an in-memory database, so
```

with

```markdown
- Repository tests assert **domain** results and failure mapping — a constraint
  violation surfacing as `ConstraintFailure`, a missing deck as
  `Rejected(DeckRejection.notFound)` — never the SQL that produced them.
- Provider tests override at `appDatabaseProvider` with an in-memory database, so
```

- [ ] **Step 4: The other skills: V8's paths and error model**

The error model follows ADR-011 D6 as `lib/core/error/` has it; the examples name V8's
real types (Clarification 5).

In `.claude/skills/flutter-architecture/SKILL.md`:

Replace

````markdown
```dart
Future<Deck> loadDeck(String id) async {
  if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');

  final deck = await _repository.findById(id);
  if (deck == null) throw const NotFoundFailure(message: 'Deck not found');

  return deck;
}
```

````

with

````markdown
```dart
Future<Outcome<DeckEntity, DeckRejection>> call(String deckId) async {
  if (deckId.isEmpty) {
    throw ArgumentError.value(deckId, 'deckId', 'must not be empty');
  }

  final deck = await _decks.findById(deckId);
  if (deck == null) return const Rejected(DeckRejection.notFound);

  return Ok(deck);
}
```

A missing deck is an expected outcome, so it is a `Rejected` reason
(ADR-011 D6); an empty id is a programming error, so it throws.

````

In `.claude/skills/flutter-data-layer/SKILL.md`:

Replace

````markdown
```dart
final class DeckRepositoryImpl implements DeckRepository {
  const DeckRepositoryImpl(this._remote, this._local, this._mapper);

  @override
  Future<List<Deck>> getDecks() async {
    try {
      final dtos = await _remote.fetchDecks();
      await _local.upsertAll(dtos);
      return dtos.map(_mapper.toEntity).toList();
    } on DioException catch (e, s) {
      _logger.warning('fetchDecks failed', e, s);
      final cached = await _local.getAll();
      if (cached.isNotEmpty) return cached.map(_mapper.toEntity).toList();
      throw mapDioException(e);          // -> Failure
    } on DriftWrappedException catch (e, s) {
      _logger.error('local read failed', e, s);
      throw DatabaseFailure(message: 'Could not read local data', cause: e);
    }
````

with

````markdown
```dart
final class ReminderWorkloadRepositoryImpl
    implements ReminderWorkloadRepository {
  ReminderWorkloadRepositoryImpl(AppDatabase db)
    : _dao = ReminderWorkloadDao(db);

  final ReminderWorkloadDao _dao;

  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    try {
      final rows = await _dao.rootDeckRows(now: now, startOfToday: startOfToday);
      return [for (final row in rows) reminderDeckWorkloadOf(row, startOfToday)];
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
````

Replace

```markdown

What that demonstrates: exceptions are caught at this boundary and only this
boundary; the original is logged with its stack trace and then discarded from
the user-facing path; the returned type is a domain entity, never a DTO.

Put `mapDioException` in `core/error/` and use it from every repository, so the
same status code cannot produce different failures in different features. Test
it directly (`flutter-testing`) — it is high-traffic code that manual testing rarely
exercises.

```

with

```markdown

What that demonstrates: the repository reads Drift through its DAO; rows become
domain types before they leave; and an exception is mapped at this boundary and
only here, by `mapDatabaseError` in `lib/core/error/failure.dart`, keeping its
stack trace (ADR-011 D6). A watch does the same with `.mapDatabaseErrors()`
(`progress_repository_impl.dart`). The example is
`lib/features/reminders/data/repositories/reminder_workload_repository_impl.dart`.

When the first API call lands, its `DioException` mapping goes next to
`mapDatabaseError` in `core/error/` and every repository uses it (ADR-012), so
the same status code cannot produce different failures in different features.
Test both directly (`flutter-testing`) — they are high-traffic code that manual
testing rarely exercises.

```

In `.claude/skills/flutter-design-system/SKILL.md`:

Replace

```markdown
column with dead space at the right, and the band above them measures
perfectly because *the Wrap* is full-width — only the cards are not. This
shipped in Card Import (M99.19a finding V9) and no gate saw it.

```

with

```markdown
column with dead space at the right, and the band above them measures
perfectly because *the Wrap* is full-width — only the cards are not. No
analyzer, guard or golden sees it.

```

Replace

```markdown

**The visual audit can enforce a declared row-of-surfaces contract.**
For screens whose wireframe declares one surface column, opt that screen into
`SurfaceColumnRule` and provide the production-surface finder explicitly. The
rule groups those surfaces into rows by vertical overlap and fails when a
row's union stops short of the column the other surfaces establish. It is not
global: another screen may intentionally contain nested or asymmetric card
groups, and the harness must not invent a layout contract merely because it
sees an `MxCard`. Its synthetic unit tests pin what it catches, while the
screen's `getRect` tests remain the primary proof of the declared geometry.

```

with

```markdown

**The visual audit does not check geometry.**
`test/visual_audit/screen_audit.dart` (MX-VIS-001) runs each production screen
in both themes at 1× and 2× text and fails on an overflow, a small tap target or
an unlabelled one. The declared geometry is proved by the screen's `getRect`
tests.

```

Replace

```markdown

`test/features/card/presentation/card_import_alignment_test.dart` is the
worked example: one helper, every band of every state, plus the stacked case
at 320dp. Measure the widgets a reader sees — a card, a panel — never the
invisible box that holds them, which is what hid the original defect.

```

with

```markdown

`test/shared/widgets/mx_footer_bar_test.dart` measures a shared widget this
way. Measure the widgets a reader sees — a card, a panel — never the invisible
box that holds them.

```

In `.claude/skills/flutter-design-system/references/components.md`:

Replace

```markdown

`mx_card.dart` is the worked example, `deck_tile_widget.dart` the caller, and
`deck_tile_target_test.dart` pins it by geometry — which is the only way to see
it, since the widget tree is identical either way and only the reacting pixels
differ.

```

with

```markdown

`lib/shared/widgets/mx_card.dart` is the worked example. Only a test of the
reacting pixels can pin it, since the widget tree is identical either way.

```

In `.claude/skills/flutter-feature-slice/SKILL.md`:

Replace

```markdown
  them, and gets a test proving it.** Optional params have defaults, so a
  dropped `sort:` or `searchTerm:` compiles clean and analyzes clean — the
  card list shipped exactly this ("Showing 3 of 1", inert sort control) and
  only end-to-end runs caught it. The lock is cheap: a fake repository that
  records every parameter it receives, one assert per param
  (`watch_card_list_items_use_case_test.dart` is the template).

```

with

```markdown
  them, and gets a test proving it.** Optional params have defaults, so a
  dropped `sort:` or `searchTerm:` compiles clean and analyzes clean, and
  only an end-to-end run would catch it. The lock is cheap: a fake repository
  that records every parameter it receives, one assert per param.

```

In `.claude/skills/flutter-feature-slice/assets/feature_checklist.md`:

Replace

```markdown
      widget to decide which field to mark
- [ ] `ValidationFailure` carries `Set<Enum> problems`, so one attempt reports
      every wrong field. No `Map<String, String>`: the value would be copy the UI
      must not render, which is what makes presentation re-derive the rule
- [ ] Any rule needing the data *as it stands at write time* stays in the
      repository, inside its transaction
- [ ] Failure reasons are enums in `domain/failures/`, never sentences in
      `Failure.message`
- [ ] No Flutter / Dio / Drift / json_annotation imports
```

with

```markdown
      widget to decide which field to mark
- [ ] A refusal is `Rejected(reason)` (ADR-011 D6), its reason a value of the
      feature's enum in `domain/failures/`, never a sentence: the UI maps the
      value to its own copy, so presentation never re-derives the rule
- [ ] Any rule needing the data *as it stands at write time* stays in the
      repository, inside its transaction
- [ ] No Flutter / Dio / Drift / json_annotation imports
```

Replace

```markdown
- [ ] Sections split into separate widget classes
- [ ] Route path in `app/router/route_paths.dart`; its **name** and path
      parameters in `core/navigation/route_names.dart`
- [ ] Only tokens and existing components used
```

with

```markdown
- [ ] Sections split into separate widget classes
- [ ] Route path and its path parameters in `lib/app/router/app_routes.dart`
- [ ] Only tokens and existing components used
```

In `.claude/skills/flutter-navigation/SKILL.md`:

Replace

````markdown
├── app_router.dart      # GoRouter instance, redirect logic
├── route_paths.dart     # path + name constants
└── route_guards.dart    # (not yet — login comes later, ADR-013; add it with login)
```

````

with

````markdown
├── app_router.dart      # GoRouter instance, redirect logic
└── app_routes.dart      # path and path-parameter constants
```

A `route_guards.dart` comes with login, which ADR-013 leaves for later.

````

Replace

```markdown
cards), backing out of the target lands on the *redirect source*, which the
user never saw on the way in. Found the hard way as IT-TREE-003: back from a
card list dropped onto the intermediate deck level. There are two honest
responses, and the project chose per-site: `push` the target instead of `go`
where the source screen is a real place the user should return through
(`deck_list_screen.dart` does this), or accept the extra back-tap and record
it — never assume the redirect will "undo" itself on the way back, and never
```

with

```markdown
cards), backing out of the target lands on the *redirect source*, which the
user never saw on the way in. There are two honest
responses, and the project chose per-site: `push` the target instead of `go`
where the source screen is a real place the user should return through, or
accept the extra back-tap and record
it — never assume the redirect will "undo" itself on the way back, and never
```

Replace

```markdown

- [ ] No path string outside `route_paths.dart`.
- [ ] Every route reachable by name.
```

with

```markdown

- [ ] No path string outside `app_routes.dart`.
- [ ] Every route reachable by name.
```

In `.claude/skills/flutter-product-spec/SKILL.md`:

Replace

```markdown
| `docs/features/<feature>/api.md` | Endpoints, request/response shapes, error format, pagination — from the first slice that calls the API (ADR-012) | — |
| `docs/design-system.md` | Owned by `flutter-design-system` | — |
| `docs/testing-strategy.md` | Owned by `flutter-testing` | — |
| `docs/release-checklist.md` | Owned by `flutter-ship` | — |

Do not create empty placeholder files for the last four before the phase that
owns them — an empty document reads as "considered and found to need nothing",
which is worse than an absent one. `docs/README.md` should list what exists and
what is deliberately not written yet.

```

with

```markdown
| `docs/features/<feature>/api.md` | Endpoints, request/response shapes, error format, pagination — from the first slice that calls the API (ADR-012) | — |
| `docs/shared/ui/` | The design and screen handoffs from the kit; owned by `flutter-design-system` | — |
| `docs/shared/testing/` | Scenario catalog, coverage map, execution guide; owned by `flutter-testing` | — |

Do not create an empty placeholder before the work that owns it — an `api.md`
before the slice that calls the API, a release checklist before release. An
empty document reads as "considered and found to need nothing", which is worse
than an absent one. `docs/README.md` should list what exists and what is
deliberately not written yet.

```

In `.claude/skills/flutter-project-setup/SKILL.md`:

Replace

````markdown

**Data layer throws typed exceptions.** `DioException`, `DriftWrappedException`
and friends are caught at the *repository boundary* and never travel further.

**Domain layer speaks `Failure`.** A sealed class, so `switch` over it is
exhaustive and the compiler tells you when a new failure type needs handling:

```dart
sealed class Failure {
  const Failure({required this.message, this.cause});
  final String message;   // safe to show a user
  final Object? cause;    // for logs only, never rendered
}

final class NetworkFailure extends Failure { ... }
final class UnauthorizedFailure extends Failure { ... }
final class ForbiddenFailure extends Failure { ... }
final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, this.problems = const <Enum>{}});
  final Set<Enum> problems;  // typed field problems; drives inline form errors
}
final class NotFoundFailure extends Failure { ... }
final class ConflictFailure extends Failure { ... }
final class DatabaseFailure extends Failure { ... }
final class UnknownFailure extends Failure { ... }
```

`ValidationFailure` carries a **set of typed problems** because that is what the
UI needs to show an error under the right input. Flattened to one string, the UI has
to guess which field is wrong.

Two details memox learned the hard way, both worth copying:

* a `Set`, not a single value, because a form can fail in two places at once — a
  blank name *and* an unchosen option — and one reason means the user is sent round
  twice;
* `Enum` values, not `Map<String, String>`. The map's key was a repeated string
  literal nothing checked, and its value was a message the UI is forbidden to
  render — so presentation ignored the value and re-derived the problem from the raw
  input, which quietly gave the validation rule a second owner. `Enum` rather than a
  feature type because `core/` may not import a feature, and on the *base* class
  because `Failure` is `sealed`, so a feature cannot add a subtype.

**Result type or exceptions?** Either works. Pick one and hold to it —
`Result<T>` makes failure explicit in the signature at the cost of ceremony;
throwing `Failure` and catching in the controller is lighter but easier to
forget. Whichever you choose, the invariant is that a `DioException` never
reaches presentation.

````

with

````markdown

MemoX V8's is ADR-011 D6, in `lib/core/error/`. It has two kinds of "no":

- **A refusal is a value.** A write the rules refuse (a blank name, a move into
  the deck's own subtree) returns `Rejected(reason)`, an `Outcome<T, R extends
  Enum>` (`core/error/outcome.dart`). `R` is the feature's own reason enum in
  `domain/failures/` (`DeckRejection`, …), so `core/` names no business reason,
  a `switch` over it stays exhaustive, and the UI maps each value to its own
  words. A rule the repository checks first is a reason, never an exception.
- **An unexpected error is a `Failure`.** `core/error/failure.dart` holds a
  sealed `Failure` with a `message` safe to show and a `cause` for logs only:
  `ConstraintFailure`, `DatabaseLockedFailure`, `UnknownDatabaseFailure`.

```dart
sealed class Outcome<T, R extends Enum> { const Outcome(); }
final class Ok<T, R extends Enum> extends Outcome<T, R> { … final T value; }
final class Rejected<T, R extends Enum> extends Outcome<T, R> {
  … final R reason;
}
```

**The data layer maps once.** Drift and sqlite3 exceptions are caught at the
repository boundary and turned into a `Failure` by `mapDatabaseError`; a watch
does the same through `mapDatabaseErrors()`. No repository inspects a driver
exception itself, and no driver exception reaches presentation. When networking
lands, its failures join the sealed class and are mapped in one place the same
way.

````

Replace

```markdown

Put the mapping in one place (`core/error/`) so every repository maps the same
exception to the same failure, and test it (`flutter-testing`) — error mapping is the
code most likely to be wrong and least likely to be exercised by hand.
```

with

```markdown

Keep the mapping in one place (`core/error/`) so every repository maps the same
exception to the same failure, and test it (`test/core/error/failure_test.dart`,
per `flutter-testing`) — error mapping is the code most likely to be wrong and
least likely to be exercised by hand.
```

In `.claude/skills/flutter-testing/SKILL.md`:

Replace

```markdown

Record the strategy in `docs/testing-strategy.md` (create it — the file is deliberately absent until this phase, see `docs/README.md`), including what you have
deliberately decided not to test and why.

```

with

```markdown

Record the strategy in `docs/shared/testing/` (`README.md` and
`testing-pyramid-audit.md` hold it today), including what you have deliberately
decided not to test and why.

```

Replace

```markdown

Folders appear with their first test (ADR-011 D1, D12). The suites that come
with the UI (visual audits under `test/visual_audit/`, which the guard's
`memox.visual.*` rules already target, goldens and `integration_test/`) are
placed when the UI sub-project starts.

`mocktail` for mocks — no codegen, so a changed signature is a compile error
where it matters rather than a stale generated file.

```

with

```markdown

Folders appear with their first test (ADR-011 D1, D12). The suites that came
with the UI are in place: visual audits under `test/visual_audit/` (MX-VIS-001,
which the guard's `memox.visual.*` rules also target) and goldens beside the
widget tests. A device end-to-end suite does not exist yet.

Fakes of the domain contracts, not mocks: `test/support/` holds the shared ones
(`fake_day_clock.dart`, `fake_reminder_platform.dart`, …), so a changed
signature is a compile error where it matters.

```

Replace

```markdown

The checklist's pixel-difference threshold (under 3%) is for comparing against
the design kit. For golden regression tests between runs, keep tolerance at or
near zero — the whole point is to notice change.
```

with

```markdown

The pixel-difference threshold for comparing against the design kit is under
3%. For golden regression tests between runs, keep tolerance at or
near zero — the whole point is to notice change.
```

In `.claude/skills/flutter-theme-design/references/surfaces-containers.md`:

Replace

```markdown

Lưu ý repo: `badgeTheme` từng bị **từ chối** khỏi nhóm component theme chưa có renderer (khi đó là `app_planned_themes.dart`) vì
due-vs-overdue là một quyết định cần màn hình — mục này chỉ mở khi
quyết định đó có screen để check.

```

with

```markdown

Lưu ý repo: `badgeTheme` chưa vào `ThemeData` vì due-vs-overdue là một quyết
định cần màn hình — mục này chỉ mở khi quyết định đó có screen để check.

```

In `.claude/skills/flutter-workflow/references/definition-of-done.md`:

Replace

```markdown
      the guard, the colour audit and to a golden that was first recorded while
      wrong. See the Responsive section of `flutter-design-system` and
      `test/features/card/presentation/card_import_alignment_test.dart`.
      A screen MAY additionally opt its declared surface group into
      `SurfaceColumnRule`; this is never global because nested and asymmetric
      card groups can be intentional. The widget test remains the authority for
      headings, fields, exact gutters, gaps and baselines.
- [ ] A new or updated golden was compared state-by-state with the actual
```

with

```markdown
      the guard, the colour audit and to a golden that was first recorded while
      wrong. See the Responsive section of `flutter-design-system`. The widget
      test is the authority for headings, fields, exact gutters, gaps and
      baselines.
- [ ] A new or updated golden was compared state-by-state with the actual
```

In `.claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py`:

Replace

```python

**The debt this pays was recorded at T0.1 and is the oldest open row in the
ledger:** *"`check_architecture.sh` chưa có test tự động — regression trong
checker âm thầm ngừng enforce boundary"*. A guard nobody tests is a guard that
can stop finding anything and still print a tick, which is worse than no guard
because the tick is believed.

The mitigation added at M4.10b — the checker prints how many files it scanned
and treats zero as a failure — closes the worst case, where the guard sees
nothing at all. It does not close the case this file is for: the guard scanning
everything and *recognising* nothing.

```

with

```python

A guard nobody tests is a guard that can stop finding anything and still print
a tick, which is worse than no guard because the tick is believed.

The checker prints how many files it scanned and treats zero as a failure,
which closes the worst case, where the guard sees nothing at all. It does not
close the case this file is for: the guard scanning everything and
*recognising* nothing.

```

Replace

```python
    def test_a_project_with_no_lib_but_a_pubspec_fails(self) -> None:
        # The M4.10b mitigation, pinned: a skip before the project exists is
        # honest, a skip after it exists is the checker reporting success for
```

with

```python
    def test_a_project_with_no_lib_but_a_pubspec_fails(self) -> None:
        # The zero-scope failure, pinned: a skip before the project exists is
        # honest, a skip after it exists is the checker reporting success for
```

- [ ] **Step 5: Run the contract test**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_skills_without_v7.py'
```

Expected: `Ran 9 tests` and `OK`.

- [ ] **Step 6: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-architecture/SKILL.md \
  .claude/skills/flutter-data-layer/SKILL.md \
  .claude/skills/flutter-design-system/SKILL.md \
  .claude/skills/flutter-design-system/references/components.md \
  .claude/skills/flutter-drift/SKILL.md \
  .claude/skills/flutter-drift/references/dynamic-sql-semantics.md \
  .claude/skills/flutter-drift/references/dynamic-sql.md \
  .claude/skills/flutter-drift/references/layering.md \
  .claude/skills/flutter-drift/references/operations.md \
  .claude/skills/flutter-drift/references/query-conventions.md \
  .claude/skills/flutter-drift/references/riverpod-drift.md \
  .claude/skills/flutter-drift/references/schema-conventions.md \
  .claude/skills/flutter-drift/references/testing-database.md \
  .claude/skills/flutter-feature-slice/SKILL.md \
  .claude/skills/flutter-feature-slice/assets/feature_checklist.md \
  .claude/skills/flutter-navigation/SKILL.md \
  .claude/skills/flutter-product-spec/SKILL.md \
  .claude/skills/flutter-project-setup/SKILL.md \
  .claude/skills/flutter-testing/SKILL.md \
  .claude/skills/flutter-theme-design/references/surfaces-containers.md \
  .claude/skills/flutter-workflow/references/definition-of-done.md \
  .claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py \
  .claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 76 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
docs(skills): V7's names, paths and error model leave the skills (BE-D7)

The skills cited paths V8 does not have and used V7's tables
(card_review_states, review_history, parent_deck_id, root_deck_id) and
V7's semantics: a due card without learned_at, a Failure per error kind,
a ValidationFailure carrying a set of problems. They now name V8's tables
and files, V8's due rule (BR-STUDY-051), its folded search columns, and its
error model (ADR-011 D6): Outcome and Rejected for refusals, a sealed
Failure for database errors, mapped once by mapDatabaseError.

The contract test adds V7's table names and SurfaceColumnRule to its
markers, and pins that every path a skill cites, from the repository root
or from the skill's own folder, exists.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 7: Documents: BE-D3, ADR-011 and the WBS

**Files:**
- Modify: `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`, `docs/shared/testing/host-coverage-map.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`

**Interfaces:**
- Consumes: the contract test's `REPO_OWNED_SKILLS` and `_scanned_files`, which the link
  check imports.
- Produces: the records of spec §5 and §6.

Spec §5, §6, §8's search and links; Clarifications 9 and 12.

- [ ] **Step 1: Record BE-D7 and BE-D3: host-coverage-map, ADR-011 and the two WBS files**

In `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`:

Replace

```markdown
  `docs/architecture.md` của V7. `feature_blueprint.md` và `project-baseline.md` trở
  thành tài liệu tham khảo V7.
- Foundation plan ngày 2026-09-23 đã được sửa theo ADR này trước khi chạy Task 2.
```

with

```markdown
  `docs/architecture.md` của V7. `feature_blueprint.md` và `project-baseline.md` trở
  thành tài liệu tham khảo V7; ở BE-D7 (gói 12c), `feature_blueprint.md` bị gỡ và
  `project-baseline.md` được viết lại cho V8.
- Foundation plan ngày 2026-09-23 đã được sửa theo ADR này trước khi chạy Task 2.
```

Replace

```markdown
  - Các tham chiếu V7 trong skill không liên quan tới thư mục (`docs/checklist.md`,
    `docs/wbs.md`, các số AD khác).
  - 13 rule `memox_v7.design_system.*` trong ruleset `memox-v8`: đã đổi thành
```

with

```markdown
  - Các tham chiếu V7 trong skill không liên quan tới thư mục (`docs/checklist.md`,
    `docs/wbs.md`, các số AD khác): đã gỡ ở BE-D7 (gói 12c).
  - 13 rule `memox_v7.design_system.*` trong ruleset `memox-v8`: đã đổi thành
```

In `docs/shared/testing/host-coverage-map.md`:

Replace

```markdown

V8 chưa có test nào. Bảng dưới đây không phải giấy chứng nhận coverage — nó
là bản đồ: mỗi kịch bản thuộc `scenario-catalog.md` nhắm tới hồ sơ thực thi
```

with

```markdown

Bảng dưới đây không phải giấy chứng nhận coverage — nó
là bản đồ: mỗi kịch bản thuộc `scenario-catalog.md` nhắm tới hồ sơ thực thi
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-D6 | Guard và hook design token không còn gì của V7 (mở rộng theo chủ dự án): gỡ registry `memox-v7` của `code-verification-guard-v2` cùng test của nó; `memox-v8` mang nhãn "MemoX V8" và 13 id `memox_v8.design_system.*`; sáu rule mang tên của V7 tìm tên của V8, hai id đổi theo; message, comment và lý do dẫn quyết định của V8; hook `.claude/hooks/check_design_tokens.py` nạp `memox-v8` bằng bộ nạp của guard và chạy chính rule của guard trên file vừa sửa, có test riêng và bước "hook tests" trong gate; tài liệu của guard ghi `ntgptit/memox-v8`. Giữ registry `memox` (V6) | xong | — | M | [spec](superpowers/specs/2026-09-27-guard-without-v7-design.md) và [plan](superpowers/plans/2026-09-27-guard-without-v7.md) gói 12b; `test_memox_v8_ruleset_contract.py`, `test_memox_v8_data_model_guard_rules.py` và `test_memox_v8_architecture_guard_rules.py` trong `code-verification-guard-v2/tests/`; `.claude/hooks/tests/test_check_design_tokens.py` | BE-D7 |

```

with

```markdown
| BE-D6 | Guard và hook design token không còn gì của V7 (mở rộng theo chủ dự án): gỡ registry `memox-v7` của `code-verification-guard-v2` cùng test của nó; `memox-v8` mang nhãn "MemoX V8" và 13 id `memox_v8.design_system.*`; sáu rule mang tên của V7 tìm tên của V8, hai id đổi theo; message, comment và lý do dẫn quyết định của V8; hook `.claude/hooks/check_design_tokens.py` nạp `memox-v8` bằng bộ nạp của guard và chạy chính rule của guard trên file vừa sửa, có test riêng và bước "hook tests" trong gate; tài liệu của guard ghi `ntgptit/memox-v8`. Giữ registry `memox` (V6) | xong | — | M | [spec](superpowers/specs/2026-09-27-guard-without-v7-design.md) và [plan](superpowers/plans/2026-09-27-guard-without-v7.md) gói 12b; `test_memox_v8_ruleset_contract.py`, `test_memox_v8_data_model_guard_rules.py` và `test_memox_v8_architecture_guard_rules.py` trong `code-verification-guard-v2/tests/`; `.claude/hooks/tests/test_check_design_tokens.py` | BE-D7 |
| BE-D7 | Skill và tài liệu không còn V7 (mở rộng theo chủ dự án): 15 skill do repo sở hữu không còn dẫn V7 — quyết định `AD-nn`, luật `BR-nn`, mốc, checklist 22 phase, `docs/wbs.md`, `docs/architecture.md`, Widgetbook, tên bảng và tên file của V7 — và mọi đường dẫn chúng nêu đều có thật; gỡ `feature_blueprint.md`, `phase-index.md`, `integration-test-harness.md`, hai script gallery, `wbs_template.md` và receipt cài đặt của `project-documentation`; `project-baseline.md` và bảng dependency viết lại theo V8; error model theo ADR-011 D6; câu nào dẫn ADR-001 về local-only hay chưa có auth thì dẫn ADR-012 và ADR-013; 8 dòng AD-12/AD-15 trong `lib/` và `test/` trỏ ADR-011. Gồm BE-D3 | xong | BE-D6 | M | [spec](superpowers/specs/2026-09-27-skills-without-v7-design.md) và [plan](superpowers/plans/2026-09-27-skills-without-v7.md) gói 12c; `.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`, test này cũng ghim mọi thư mục skill là của repo hoặc vendored | FE-D4 |
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) không còn ghi "V8 chưa có test nào"; skill `flutter-workflow` đọc `docs/wbs_BE.md` và `docs/wbs_FE.md` | xong | — | S | Làm trong BE-D7 (gói 12c) | — |

```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Làm trong BE-D7 (gói 12c) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D7 | Skill và tài liệu không còn V7: Widgetbook trong Definition of Done và trong skill `flutter-feature-slice`, `flutter-design-system`; các con trỏ tới `docs/wbs.md` và checklist của V7; baseline và blueprint của V7; bản ghi cài đặt của skill `project-documentation`; lịch sử của V7 trong comment của các script khác của `flutter-workflow` và `flutter-architecture` (`check_format.sh`, `check_generated.sh`, `check_architecture.py`). Gồm BE-D3 | chưa bắt đầu | BE-D6 | M | [Spec gói 12a](superpowers/specs/2026-09-26-verification-tooling-design.md) §2, §9 | Gói 12c: brainstorm, spec, plan |

```

with

```markdown
|---|---|---|---|---|---|---|
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |

```

Replace

```markdown
  ở những chỗ spec liệt kê; final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
```

with

```markdown
  ở những chỗ spec liệt kê; final review toàn nhánh trước khi mở PR.
- **BE-D7** (gói 12c, [spec](superpowers/specs/2026-09-27-skills-without-v7-design.md),
  [plan](superpowers/plans/2026-09-27-skills-without-v7.md)): gate xanh sau mỗi task;
  test hợp đồng `test_skills_without_v7.py` đỏ với đúng các dấu V7 của nhóm skill mỗi
  task nhận, rồi xanh; final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 12b (BE-D6).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 12c (BE-D7).

```

Replace

```markdown

1. BE-D7 (gói 12c), gồm BE-D3, theo thứ tự chủ dự án chọn ngày 2026-09-26.
2. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).

```

with

```markdown

1. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).

```

Replace

```markdown
  chuyển sang `memox-v8` trong gói này, nên BE-D7 không còn việc đó.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  chuyển sang `memox-v8` trong gói này, nên BE-D7 không còn việc đó.
- **Cập nhật ngày 2026-09-27:** BE-D7 xong trong gói 12c, gồm BE-D3, mở rộng theo chủ dự
  án: skill và tài liệu không còn V7. Việc đối chiếu `flutter-theme-design` với code V8
  tách thành FE-D4 trong [`wbs_FE.md`](wbs_FE.md).
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-D3 | Kịch bản `DEVICE-E2E`: 8 kịch bản cần emulator hoặc thiết bị | bị chặn | — | M | [host-coverage-map.md](shared/testing/host-coverage-map.md); §9 dòng 18: máy phát triển không có emulator | Cần môi trường có emulator hoặc thiết bị |

```

with

```markdown
| FE-D3 | Kịch bản `DEVICE-E2E`: 8 kịch bản cần emulator hoặc thiết bị | bị chặn | — | M | [host-coverage-map.md](shared/testing/host-coverage-map.md); §9 dòng 18: máy phát triển không có emulator | Cần môi trường có emulator hoặc thiết bị |
| FE-D4 | Đối chiếu skill `flutter-theme-design` với V8: tên widget, API và hợp đồng component so với `lib/core/theme/`, `lib/shared/widgets/` và [design handoff](shared/ui/design-handoff/00-index.md); bỏ hoặc đổi các mục quy định widget mà V8 đã dựng dưới tên khác | chưa bắt đầu | — | M | Tách từ BE-D7 (gói 12c, [spec](superpowers/specs/2026-09-27-skills-without-v7-design.md)), vốn chỉ gỡ phần của V7: mốc, lịch sử, câu "Đã ship" về API mà V8 không có | Làm cùng gói FE đầu tiên chạm design system |

```

Replace

```markdown
   (starter) đã xong. BE-B5a xong trong gói 11a; FE-B5 còn chờ BE-B5b, adapter Android.

```

with

```markdown
   (starter) đã xong. BE-B5a xong trong gói 11a; FE-B5 còn chờ BE-B5b, adapter Android.
4. FE-D4 cùng gói FE đầu tiên chạm design system.

```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `generate.py` prints `OK docs/_generated: generated 3 files` and changes nothing
under `docs/_generated/`; `check.py` ends with `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 2: Search the tree for the removed files**

```bash
git grep -n -I -E 'feature_blueprint|phase-index|screen_gallery|integration-test-harness|wbs_template|\.installation\.json' -- . ':!docs/superpowers'
echo "git grep exit $?"
```

Expected: eleven lines and `git grep exit 0`: the contract test's markers and its receipt
test (seven lines), `skill_distribution.py:22: RECEIPT = ".installation.json"`, ADR-011's
two lines on the blueprint, and the BE-D7 row of `wbs_BE.md`. Nothing else outside
`docs/superpowers/` (Clarification 9).

- [ ] **Step 3: Check the skills' relative links**

```bash
python3 - <<'EOF'
import importlib.util
import re
from pathlib import Path
spec = importlib.util.spec_from_file_location(
    "contract", ".claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py")
contract = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contract)
link = re.compile(r"\]\(([^)\s#]+)(?:#[^)]*)?\)")
checked, broken = 0, []
for name in contract.REPO_OWNED_SKILLS:
    for path in contract._scanned_files(Path(".claude/skills", name)):
        if path.suffix != ".md":
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for match in link.finditer(line):
                if re.match(r"^[a-z]+:", match.group(1)):
                    continue
                checked += 1
                if not (path.parent / match.group(1)).exists():
                    broken.append(f"{path}:{number}: {match.group(1)}")
print(len(contract.REPO_OWNED_SKILLS), "skills,", checked, "relative links,", len(broken), "broken")
print("\n".join(broken))
EOF
```

Expected: `15 skills, 62 relative links, 0 broken`, then an empty line.

- [ ] **Step 4: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md \
  docs/shared/testing/host-coverage-map.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 5: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 76 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `219 passed` (the
guard's self-tests); `Code verification passed.`; `+2349: All tests passed!`.

- [ ] **Step 6: Commit**

```bash
git commit -F - <<'EOF'
docs: BE-D7 and BE-D3 done; ADR-011 records the skills without V7 (BE-D7)

host-coverage-map.md no longer opens with "V8 chưa có test nào" (BE-D3).
ADR-011's consequences record that feature_blueprint.md is gone and
project-baseline.md describes V8. wbs_BE.md moves BE-D7 and BE-D3 to done,
with the contract test as their evidence; wbs_FE.md adds FE-D4, reconciling
flutter-theme-design with V8's widgets in the first FE package that touches
the design system.
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-skills-without-v7` and open its pull request against `master`, then
subscribe to its activity.

Expected: the checks the repository runs on a pull request start; the local gate above is
the evidence the plan gives.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-skills-without-v7` if it moved, run the gate once more on
the branch head, and squash-merge only while it ends with `✓ mechanical gates passed`.
Then unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** D1, §10: no step touches `CLAUDE.md`, a vendored skill, a dated spec
  or plan, `.github/` or app behaviour. D2, §4: Tasks 1–6. D3: Task 3. D4: Task 2. D5:
  Task 1. D6: Tasks 1 and 7. D7: Tasks 1 and 2. D8, D9: Task 4. D10, §7: Tasks 1–6, one
  test each. §5: Tasks 1 and 7. §6: Task 7. §8: every task's gate, Task 4's inspection,
  Task 7's search and link check. §12.1: Tasks 2, 3 and 5. §12.2: Tasks 2, 5 and 6.
  §12.3: Tasks 4, 5 and 6.
- **Placeholders.** None: every step carries its content or its command and its expected
  output.
- **Type consistency.** The Interfaces blocks name each function once; the dry run
  applied every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the task that owns the code.
