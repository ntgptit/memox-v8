# MemoX V8 Guard and Design-Token Hook Without V7 Implementation Plan (package 12b)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-D6 of [`docs/wbs_BE.md`](../../wbs_BE.md), widened by the owner: the
guard and the design-token hook keep nothing of V7. `memox-v7` goes; `memox-v8` names
itself V8, its rules look for V8's names and cite V8's decisions; the hook applies exactly
the guard's design-token rules to the file just edited.

**Architecture:** The guard's engine does not change; its `memox-v8` registry does. Task 1
renames the registry's labels and its thirteen V7 ids and moves V7's probe files onto it.
Task 2 retargets the six rules whose patterns look for V7's names, each with a probe both
ways. Task 3 rewrites every message, comment and reason that cites V7 or names V7's code,
and drops three globs that match no file. Task 4 rebuilds the hook on the guard's own
loader and rule code, with tests the gate runs. Task 5 deletes `memox-v7` and points the
documents at `memox-v8`. No Dart file, no schema, no dependency.

**Tech Stack:** the guard's YAML rule registries (regex rules); Python 3: the guard's
pytest suite, the hook and its `unittest` tests (PyYAML and the standard library, under
`python`), the CI tooling tests (standard library); Bash (`dod_check.sh`); Flutter 3.47.5
for the gate's own steps.

**Spec:**
[`docs/superpowers/specs/2026-09-27-guard-without-v7-design.md`](../specs/2026-09-27-guard-without-v7-design.md),
approved 2026-09-27. Package 12a's spec
([`2026-09-26-verification-tooling-design.md`](../specs/2026-09-26-verification-tooling-design.md),
§2, §9) split BE-D6 off.

**Prerequisite:** `claude/be-guard-without-v7` holds the spec (`7f2f030`) and this plan,
on `master` at `b0e5549` (#92). The plan runs on that branch, from this plan's commit; the
gate passes there with 2244 host tests, the CI tooling tests `Ran 65 tests` · `OK` and the
guard's tests `204 passed`. Generated code is not committed: in a fresh working tree, run
`flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root `README.md`,
"Commands"). The guard's tests need a Python 3.12 or newer with
`code-verification-guard-v2/requirements-dev.txt` installed: `python3.13` in the cloud
container, which is the one the gate picks there.

**How this plan was checked:** every code block below was written and run first, in a
scratch copy of the repository, task by task, test first. Each task's tests failed as its
"Expected" line says, then passed, and after every task the gate passed; the comparison of
resolved rules showed 0, 6 and 10 changed rules after Tasks 1, 2 and 3, each one named by
the spec. Each rule the tests pin was also broken on purpose in the scratch copy, one at a
time: a `memox_v7` id or a "MemoX V7" label coming back; the coalesce rule looking for
V7's column again, reading comments, or turning case-sensitive; the card-table rule
looking for V7's table again or stopping at the first `;`; a label `switch` counting as a
hardcoded set, and the `eight_box` set going unseen; a kind inferred from the boxes going
unseen, and a kind decided from the session counting as inferred; `databaseProvider` going
unseen, and a comment naming it tripping the rule; the hint style going unseen; each of
the six V7 markers coming back in a comment; `memox-v7` coming back, and the V6 ruleset
going; the hook loading no rule, reading `memox-v7`, ignoring the guard's scopes, letting
a finding through, dropping the line from its report, blocking on a broken payload or on a
guard it cannot load; and the gate dropping the hook tests (30 breaks). Every break failed
at least one test. This document was then applied, step by step as written, onto a clean
checkout of this plan's commit: each task's files matched the scratch commit's, no other
file moved, and the outputs and counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- **Scope (D1, §11):** the `memox-v7` and `memox-v8` registries, the guard's tests and
  `AGENTS.md`, the hook and its tests, one gate step (`dod_check.sh` and its CI tooling
  test), and the pointers of spec §9. The guard's engine (`code_verification_guard/`), the
  `memox` (V6) registry and its tests, `.claude/settings.json`, the dated specs and plans,
  app code, and every other V7 trace in the skills and documents (BE-D7) do not change.
- **Nothing of V7 (D2):** no file of `memox-v8`, the hook or the guard's documents names V7.
  Every label, id, identifier, path, widget, file, test, decision and document they name
  exists in V8, or goes; what they cite is V8's (§6).
- **Ids (§4.2):** `memox_v7.design_system.<name>` becomes `memox_v8.design_system.<name>`
  (13 ids, names unchanged); `memox.data_model.no_coalesce_parent_deck_id` becomes
  `memox.data_model.no_coalesce_parent_id`, and
  `memox.data_model.no_scheduler_generation_on_cards_table` becomes
  `memox.data_model.no_schedule_columns_on_card_table`. No other id changes.
- **Probes (§5.1, §8.1):** every retargeted pattern reports the defect written in V8's
  names, and reports nothing on V8's correct shape, including a comment that quotes the
  defect.
- **Equivalence (§10):** the guard reports no violation on V8's tree, before and after.
  `memox-v8`'s rules as the guard resolves them differ from `master`'s only where the spec
  says: the six patterns of §5.1, the loading rule's `exclude` and `provider_files`'
  `include` (§5.2). A retargeted rule that finds a real violation in app code stops the
  plan: fixing app code is the owner's call.
- **The hook (§7):** keeps its entry in `.claude/settings.json`, its interpreter (`python`)
  and its exit codes: 2 with its findings on stderr, 0 otherwise, including on any
  exception. It loads `memox-v8` with `ConfigManager().load_ruleset_runtime(root,
  "memox-v8")` and runs `RuleFactory().create(rule).check(tmp)` on a one-file copy. No
  test writes into `lib/`.
- **Keep (D3):** the `memox` (V6) registry and its tests.
- **After every task** the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
- **Language:** code, comments, identifiers, rule messages, test names and commit messages
  are in English; `docs/` keeps its Vietnamese. Every commit message ends with the
  session's attribution trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan. Each is decided
here and implemented as described; say so if one is wrong.

1. **The expressions of §5.1** (Task 2), each run against V8's tree first:
   - `no_coalesce_parent_id` matches `coalesce(` in any case, in SQL or in Drift's
     `coalesce([deck.parentId, …])`, with or without a table prefix. A line that starts as
     a comment (`//`, `*`, `--`) is prose, which keeps `srs_dao.dart`'s doc comment
     silent.
   - `no_schedule_columns_on_card_table` names every column of `card_schedule` but
     `card_id`: twelve, where the spec lists eight. The table's body runs to the line
     that closes it, not to the first `;`, because `card.drift` has a comment with a `;`
     inside the table. Its tempered dot takes each character one way and fails fast:
     0.03 ms per file, 13 ms on a file padded to 160 KB.
   - `review_actions_from_supported_actions` flags the four `Sm2Action` values, or both
     `EightBoxAction` values, written side by side with nothing but commas between them.
     The exhaustive label `switch` (`=>` between the values) stays legal, and so does
     `Sm2Action.values`, which `StudyGradeRowWidget` iterates because it is the sm2 grade
     row.
   - `review_kind_not_inferred` flags `kind`, or any `…Kind`, given a value from a
     comparison of `previousBox`, `nextBox`, `currentBox` or `intervalDays`. V7's second
     pattern, a ternary between two kinds, goes: V8 decides a kind from the session
     (BR-SRS-016, BR-SRS-017), and that is legal.
   - `widget_no_database_access` loses the `appDatabase` alternative and gains
     `databaseProvider` outside comments; `no_text_restyle`'s `inputHintStyle` becomes
     `\binputHint`.
2. **The data-model messages are V8's in Task 2**, with their patterns: the four rules'
   messages, hints and comments cite BR-DECK-003, ADR-004, ADR-003 and BR-SRS-015.
3. **The comparison of resolved rules** (Tasks 1–3) is a script in the plan's workspace,
   not committed. It loads `memox-v8` at `b0e5549` and in the working tree through the
   guard's loader, leaves prose out, maps an old id to its §4.2 rename when the tree has
   the new id, and prints what differs. The guard's findings are empty before and after,
   so they cannot show a lost rule; the resolved rules can (§12, "a rule lost in the
   rename").
4. **What the full pass decided** (Task 3; §5.4). Retargeted and removed: the lists of
   spec §5 and §6. Kept as V8's: the globs of generated, built or not-yet-built files
   (`**/*.g.dart`, `**/*.freezed.dart`, `**/*.drift.dart`, `lib/l10n/generated/**`,
   `lib/l10n/app_localizations*.dart`, `build/**`, `**/.dart_tool/**`,
   `integration_test/**/*.dart`) and the guard's own directory; the names a rule forbids
   and V8 does not use (`StateNotifier`, `ChangeNotifierProvider`, `ChoiceChip`,
   `styleFrom`, `CURRENT_TIMESTAMP`, `DioException`, `flutter_secure_storage`, …);
   Flutter's `AppBarTheme`; and `MyThingRef`, the placeholder in a message's example.
   The icon-colour rule keeps its `.resolve(` exemption, for `MxDerivedColors.resolve`;
   the colour-scheme rule says the SDK resolves the tint for itself; the README's table
   of files gains the design-system row it lacked. No rule is removed: V8 holds every
   invariant.
5. **The loading rule's exclusion test goes with its exclusion** (Task 3; §5.2):
   `test_no_raw_loading_indicator_excludes_the_determinate_ring` tested V7's file.
6. **The contract pattern** (Task 1) is `(?i)memox[-_ ]v7`. It catches `memox-v7`,
   `memox_v7` and "MemoX V7" without spelling any of them, so §10's search of the guard
   finds nothing, the contract test included.
7. **A test pins the deletion** (Task 5): the MemoX rulesets are `memox` and `memox-v8`,
   which also pins D3's `memox` (V6).
8. **The hook's environment is unchanged.** The guard's loader and rule code import PyYAML
   and the standard library only, as the old hook did, and run under the cloud image's
   `python` 3.11.
9. **The hook's report** prints the rule id, `path:line`, the line and the message; the
   message comes on one line, because the registry folds long messages over several.
10. **Two things the hook tests add to spec §8.2.** They load the hook the way the CI
    tooling tests load their scripts (the module registered in `sys.modules` first,
    which the hook's dataclass needs). And a test pins §7's fifth point, the one a
    silent hook breaks first: a guard that cannot load exits 0 (Review Focus 1).
11. **`AGENTS.md` changes in Task 5**, with the deletion it describes. The guard's
    `VERSION` stays: `AGENTS.md` bumps it when the engine, the matchers or the common
    rules change, and none does.
12. **Dates.** The plan and the update entry of `wbs_BE.md` are dated 2026-09-27.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person, each
pinned by a test in the task that owns the code:

1. **A guard the hook cannot load** (no PyYAML under `python`, a registry that does not
   parse): the hook exits 0 and the edit goes through; the gate's hook tests go red
   instead — Task 4, `test_a_guard_that_cannot_load_exits_0`.
2. **A comment that quotes a forbidden form** (`srs_dao.dart`'s doc comment quoting
   `COALESCE(parent_id, id)`, a comment naming `databaseProvider`): silent — Task 2, the
   silent probes of both rules.
3. **A `;` in a comment inside `CREATE TABLE card`**: the rule still sees a schedule column
   after it — Task 2, the card-table probe, before and after that comment.
4. **V8's own shapes beside a retargeted pattern** (the label `switch` over the actions,
   `supportedActions`, a kind decided from the session): silent — Task 2's silent probes;
   and the guard runs on V8's whole tree in every gate.
5. **A file in a scope wider than product UI, or in none** (`lib/app/`, `lib/core/theme/`;
   `domain/`, a `.g.dart` file): the hook reports what the guard reports — Task 4,
   `test_each_file_gets_the_guards_findings`.

## File Structure

```
code-verification-guard-v2/
├── AGENTS.md                                  names ntgptit/memox-v8 (5)
├── registries/projects/
│   ├── memox-v7/                              deleted (5)
│   └── memox-v8/
│       ├── config/scopes.yaml                 its name (1); reasons, globs (3)
│       ├── config/{overrides,profiles}.yaml   reasons (3)
│       └── rules/
│           ├── README.md                      V8's authorities (3)
│           └── memox-*-rules.yaml (10)        labels, ids (1); six patterns (2);
│                                              references and names (3)
└── tests/
    ├── test_memox_v8_ruleset_contract.py      new (1); markers (3); rulesets (5)
    ├── test_memox_v8_design_system_guard_rules.py   from test_memox_v7_* (1);
    │                                                probes (2, 3)
    ├── test_memox_v8_design_token_guard_rules.py    from test_memox_v7_* (1)
    ├── test_memox_v8_spacing_literal_rules.py       from test_memox_v7_* (1)
    ├── test_memox_v8_data_model_guard_rules.py      new (2)
    ├── test_memox_v8_architecture_guard_rules.py    new (2)
    ├── test_memox_false_positive_regressions.py     reads memox-v8 (1)
    └── test_max_lines_rule.py                       docstring (1)
.claude/hooks/
├── check_design_tokens.py                     the guard's loader and rule code (4)
└── tests/test_check_design_tokens.py          new (4)
.claude/skills/
├── flutter-workflow/scripts/dod_check.sh      the "hook tests" step (4)
├── flutter-workflow/scripts/tests/test_ci_tooling.py   GateRunsTheHookTestsTest (4)
├── flutter-theme-design/SKILL.md              the memox_v8 ids (1)
├── flutter-theme-design/references/legacy-and-guards.md   memox-v8's path (5)
├── flutter-state-riverpod/SKILL.md            --ruleset memox-v8 (5)
└── flutter-architecture/references/analysis_options.yaml   --ruleset memox-v8 (5)
docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md   the ids renamed (1)
docs/wbs_BE.md                                 BE-D6 done; BE-D7 (5)
```

---


### Task 1: memox-v8 names itself V8

**Files:**
- Modify: `.claude/skills/flutter-theme-design/SKILL.md`, `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-error-handling-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-i18n-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-naming-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-privacy-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-state-management-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml`, `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`
- Test (create): `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py`
- Test (rename, then modify): `code-verification-guard-v2/tests/test_memox_v7_design_system_guard_rules.py` → `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`
- Test (rename, then modify): `code-verification-guard-v2/tests/test_memox_v7_design_token_guard_rules.py` → `code-verification-guard-v2/tests/test_memox_v8_design_token_guard_rules.py`
- Test (rename, then modify): `code-verification-guard-v2/tests/test_memox_v7_spacing_literal_rules.py` → `code-verification-guard-v2/tests/test_memox_v8_spacing_literal_rules.py`
- Test (modify): `code-verification-guard-v2/tests/test_max_lines_rule.py`, `code-verification-guard-v2/tests/test_memox_false_positive_regressions.py`

**Interfaces:**
- Consumes: `memox-v8` as it stands at `b0e5549`; V7's three probe files.
- Produces:
  - `tests/test_memox_v8_ruleset_contract.py`: `RULESET_ROOT` (the `memox-v8` directory)
    and `_occurrences(pattern: str) -> list[str]`, each hit as `<file>:<line>: <match>`.
  - The ids `memox_v8.design_system.<name>` (13), read by the probe files by id.
  - `.superpowers/sdd/2026-09-27-guard-without-v7/compare_rules.py COMMIT`, not
    committed: prints `<n> rules before, <n> after; only before: [...]; only after:
    [...]`, one `changed <id>: <keys>` line per rule that differs, and `<n> changed`.

Spec §4.2, §8.1 (the contract test and V7's probes), D4, D9; Clarifications 3 and 6. The
red run fails on the probes' new ids and on the contract test; the comparison at the end
shows the rename lost no rule.

- [ ] **Step 1: Write the contract test, and move V7's probes to memox-v8**

The three `git mv` commands keep the files' history; each is followed by the blocks that
point the file at `memox-v8` and its new ids. The contract test spells none of the names
it refuses (Clarification 6).

In `code-verification-guard-v2/tests/test_max_lines_rule.py`:

Replace

```python
    `///` is caught by the `//` prefix rather than by a rule of its own, which is
    easy to break while tidying `_is_logical_source_line`. memox-v7 points its
    main file-length gate at this mode precisely because one of its files is 400
    raw lines and 56 logical ones, so this is the case that matters most there.
    """
```

with

```python
    `///` is caught by the `//` prefix rather than by a rule of its own, which is
    easy to break while tidying `_is_logical_source_line`. memox-v8 points its
    file-length gates at this mode (`config/overrides.yaml`), because a
    documented file is mostly dartdoc, so this is the case that matters most there.
    """
```

In `code-verification-guard-v2/tests/test_memox_false_positive_regressions.py`:

Replace

```python
    / "projects"
    / "memox-v7"
    / "rules"
```

with

```python
    / "projects"
    / "memox-v8"
    / "rules"
```

Run:

```bash
git mv code-verification-guard-v2/tests/test_memox_v7_design_system_guard_rules.py code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py
```

In `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`:

Replace

```python
"""Fault-injection probes for the memox-v7 design-system ratchets (A20.1 §9).

Every rule that lands for the Design System V1 closure ships three proofs:
a positive synthetic probe (the rule goes red on the thing it bans), a
comment false-positive probe (prose that names the thing stays green), and
the live-tree scan the CI guard performs. The first two live here.
"""
```

with

```python
"""Fault-injection probes for the memox-v8 design-system ratchets.

Every design-system rule ships three proofs: a positive synthetic probe (the
rule goes red on the thing it bans), a comment false-positive probe (prose that
names the thing stays green), and the live-tree scan the gate's guard step
performs. The first two live here.
"""
```

Replace

```python
    / "projects"
    / "memox-v7"
    / "rules"
```

with

```python
    / "projects"
    / "memox-v8"
    / "rules"
```

Replace

```python

SCREEN_CHROME = "memox_v7.design_system.no_raw_screen_chrome"
CHOICE_CHIP = "memox_v7.design_system.no_raw_choice_chip"

```

with

```python

SCREEN_CHROME = "memox_v8.design_system.no_raw_screen_chrome"
CHOICE_CHIP = "memox_v8.design_system.no_raw_choice_chip"

```

Replace

```python

SHEET_ROUTE = "memox_v7.design_system.no_raw_sheet_route"
LOADING = "memox_v7.design_system.no_raw_loading_indicator"
RESTYLE = "memox_v7.design_system.no_text_restyle"

```

with

```python

SHEET_ROUTE = "memox_v8.design_system.no_raw_sheet_route"
LOADING = "memox_v8.design_system.no_raw_loading_indicator"
RESTYLE = "memox_v8.design_system.no_text_restyle"

```

Run:

```bash
git mv code-verification-guard-v2/tests/test_memox_v7_design_token_guard_rules.py code-verification-guard-v2/tests/test_memox_v8_design_token_guard_rules.py
```

In `code-verification-guard-v2/tests/test_memox_v8_design_token_guard_rules.py`:

Replace

```python
"""Fault-injection probes for the memox-v7 design-token ratchets (A20.1 §9)."""

```

with

```python
"""Fault-injection probes for the memox-v8 design-token ratchets."""

```

Replace

```python
    / "projects"
    / "memox-v7"
    / "rules"
```

with

```python
    / "projects"
    / "memox-v8"
    / "rules"
```

Create `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py`:

```python
"""Contract tests for the memox-v8 ruleset: it describes V8 and nothing else."""

from __future__ import annotations

import re
from pathlib import Path

RULESET_ROOT = Path(__file__).parents[1] / "registries" / "projects" / "memox-v8"


def _occurrences(pattern: str) -> list[str]:
    compiled = re.compile(pattern)
    found: list[str] = []
    for path in sorted(RULESET_ROOT.rglob("*")):
        if not path.is_file():
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for number, line in enumerate(lines, start=1):
            for match in compiled.finditer(line):
                where = path.relative_to(RULESET_ROOT).as_posix()
                found.append(f"{where}:{number}: {match.group(0)}")
    return found


def test_memox_v8_names_no_v7_ruleset_rule_or_label() -> None:
    assert _occurrences(r"(?i)memox[-_ ]v7") == []
```

Run:

```bash
git mv code-verification-guard-v2/tests/test_memox_v7_spacing_literal_rules.py code-verification-guard-v2/tests/test_memox_v8_spacing_literal_rules.py
```

In `code-verification-guard-v2/tests/test_memox_v8_spacing_literal_rules.py`:

Replace

```python
"""Tests for the memox-v7 raw-spacing rule, including the widened patterns.

The rule originally caught only ``EdgeInsets.*`` and ``SizedBox(width|height:``
with a bare number. Three real gaps were closed — ``Gap(8)``, the
``spacing:``/``runSpacing:`` parameters of Row/Column/Wrap, and
``EdgeInsetsDirectional`` — and each is pinned here in both directions: the raw
literal fires, the token form does not. Loading the rule from the registry YAML
rather than re-declaring the pattern is what makes these tests guard the fix
itself, not a copy of it.
"""
```

with

```python
"""Tests for the memox-v8 raw-spacing rule and every spelling it catches.

Besides ``EdgeInsets.*`` and ``SizedBox(width|height:`` with a bare number, the
rule catches ``Gap(8)``, the ``spacing:``/``runSpacing:`` parameters of
Row/Column/Wrap, and ``EdgeInsetsDirectional``; each is pinned here in both
directions: the raw literal fires, the token form does not. Loading the rule
from the registry YAML rather than re-declaring the pattern is what makes these
tests guard the rule itself, not a copy of it.
"""
```

Replace

```python
    / "projects"
    / "memox-v7"
    / "rules"
```

with

```python
    / "projects"
    / "memox-v8"
    / "rules"
```

- [ ] **Step 2: Run the guard tests to see them fail**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `14 failed, 191 passed`. Thirteen failures are the probes of
`test_memox_v8_design_system_guard_rules.py`, each with
`AssertionError: Rule not found: memox_v8.design_system.<name>` for
`no_raw_screen_chrome`, `no_raw_choice_chip`, `no_raw_sheet_route`,
`no_raw_loading_indicator` and `no_text_restyle`: the probes read the new ids, which Step
4 creates. The fourteenth is `test_memox_v8_names_no_v7_ruleset_rule_or_label`, which
lists 33 occurrences, the first `'config/scopes.yaml:4: MemoX V7'`. The design-token and
spacing probes pass already: their ids are the same in both registries.

- [ ] **Step 3: Write the comparison of resolved rules (not committed)**

The script lives in the plan's workspace, which `.superpowers/sdd/.gitignore` keeps out of
git: it is a check of this plan, not a file of the repository, and Tasks 2 and 3 run it
again (Clarification 3).

Create `.superpowers/sdd/2026-09-27-guard-without-v7/compare_rules.py`:

```python
"""Compares memox-v8's rules as the guard resolves them, in a commit and in the
working tree. An id of the commit counts as its spec §4.2 rename when the working
tree has the new id. Prose (message, description, fix, tags, name) is left out.
Not committed.

Usage (from the repository root): python3 compare_rules.py COMMIT
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

DUMP = """
import json, sys
from pathlib import Path
root = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(root / "code-verification-guard-v2"))
from code_verification_guard.config.config_manager import ConfigManager
_, rules = ConfigManager().load_ruleset_runtime(root, "memox-v8")
prose = {"message", "description", "fix", "tags", "name"}
for rule in rules:
    print(json.dumps({k: v for k, v in rule.items() if k not in prose}, sort_keys=True))
"""
RENAMED = {
    "memox.data_model.no_coalesce_parent_deck_id": "memox.data_model.no_coalesce_parent_id",
    "memox.data_model.no_scheduler_generation_on_cards_table":
        "memox.data_model.no_schedule_columns_on_card_table",
}


def rules_in(root: Path) -> dict[str, dict]:
    out = subprocess.run([sys.executable, "-c", DUMP, str(root)],
                         capture_output=True, text=True, check=True).stdout
    rules = [json.loads(line) for line in out.splitlines()]
    return {rule["id"]: rule for rule in rules}


def renamed(rule_id: str, now: dict[str, dict]) -> str:
    new_id = RENAMED.get(rule_id, rule_id.replace("memox_v7.design_system.", "memox_v8.design_system."))
    return new_id if new_id in now else rule_id


after = rules_in(Path.cwd())
with tempfile.TemporaryDirectory() as tmp:
    archive = subprocess.run(["git", "archive", sys.argv[1], "code-verification-guard-v2"],
                             capture_output=True, check=True).stdout
    subprocess.run(["tar", "-x", "-C", tmp], input=archive, check=True)
    before = {}
    for rid, rule in rules_in(Path(tmp)).items():
        before[renamed(rid, after)] = {**rule, "id": renamed(rid, after)}
changed = sorted(rid for rid in before.keys() & after.keys() if before[rid] != after[rid])
print(f"{len(before)} rules before, {len(after)} after; "
      f"only before: {sorted(before.keys() - after.keys())}; only after: {sorted(after.keys() - before.keys())}")
for rid in changed:
    keys = sorted(k for k in before[rid].keys() | after[rid].keys() if before[rid].get(k) != after[rid].get(k))
    print(f"changed {rid}: {', '.join(keys)}")
print(f"{len(changed)} changed")
```

- [ ] **Step 4: Name memox-v8 V8: its labels, its scopes document and the 13 design-system ids**

Each file's header and registry name say "MemoX V8"; the design-system file also renames
its thirteen ids. Nothing else changes in this step.

In `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`:

Replace

```yaml
  id: memox-v8-ruleset-scopes
  name: MemoX V7 Ruleset Scopes
  description: >-
```

with

```yaml
  id: memox-v8-ruleset-scopes
  name: MemoX V8 Ruleset Scopes
  description: >-
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: architecture
#
```

with

```yaml
# MemoX V8 guard rules — domain: architecture
#
```

Replace

```yaml
  id: memox-v8-architecture
  name: MemoX V7 Architecture Rules
  description: Layer boundaries, dependency direction, and data-layer ownership.
```

with

```yaml
  id: memox-v8-architecture
  name: MemoX V8 Architecture Rules
  description: Layer boundaries, dependency direction, and data-layer ownership.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: data_model
#
```

with

```yaml
# MemoX V8 guard rules — domain: data_model
#
```

Replace

```yaml
  id: memox-v8-data-model
  name: MemoX V7 Data Model Rules
  description: Deck-tree, scheduler and review-history invariants (BR-xx, AD-06, AD-11).
```

with

```yaml
  id: memox-v8-data-model
  name: MemoX V8 Data Model Rules
  description: Deck-tree, scheduler and review-history invariants (BR-xx, AD-06, AD-11).
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: design_system
#
```

with

```yaml
# MemoX V8 guard rules — domain: design_system
#
```

Replace

```yaml
  id: memox-v8-design-system
  name: MemoX V7 Design System Rules
  description: >-
```

with

```yaml
  id: memox-v8-design-system
  name: MemoX V8 Design System Rules
  description: >-
```

Replace

```yaml
rules:
  - id: memox_v7.design_system.no_raw_button
    type: regex
```

with

```yaml
rules:
  - id: memox_v8.design_system.no_raw_button
    type: regex
```

Replace

```yaml
  # longer is.
  - id: memox_v7.design_system.no_raw_widget
    type: regex
```

with

```yaml
  # longer is.
  - id: memox_v8.design_system.no_raw_widget
    type: regex
```

Replace

```yaml
  # that is not a prohibition on features (A20.1 §9, FRAMEWORK_PRIMITIVE_ALLOWED).
  - id: memox_v7.design_system.no_raw_screen_chrome
    type: regex
```

with

```yaml
  # that is not a prohibition on features (A20.1 §9, FRAMEWORK_PRIMITIVE_ALLOWED).
  - id: memox_v8.design_system.no_raw_screen_chrome
    type: regex
```

Replace

```yaml
  # (A20.1 P1-01 → P1-03): guarding first would have banned the only route.
  - id: memox_v7.design_system.no_raw_sheet_route
    type: regex
```

with

```yaml
  # (A20.1 P1-01 → P1-03): guarding first would have banned the only route.
  - id: memox_v8.design_system.no_raw_sheet_route
    type: regex
```

Replace

```yaml
  # determinate caller is added here **with its reason** in the same change.
  - id: memox_v7.design_system.no_raw_loading_indicator
    type: regex
```

with

```yaml
  # determinate caller is added here **with its reason** in the same change.
  - id: memox_v8.design_system.no_raw_loading_indicator
    type: regex
```

Replace

```yaml

  - id: memox_v7.design_system.no_raw_choice_chip
    type: regex
```

with

```yaml

  - id: memox_v8.design_system.no_raw_choice_chip
    type: regex
```

Replace

```yaml

  - id: memox_v7.design_system.no_raw_style_escape
    type: regex
```

with

```yaml

  - id: memox_v8.design_system.no_raw_style_escape
    type: regex
```

Replace

```yaml
  # file allowed to touch the field never matches.
  - id: memox_v7.design_system.no_flat_style_from
    type: regex
```

with

```yaml
  # file allowed to touch the field never matches.
  - id: memox_v8.design_system.no_flat_style_from
    type: regex
```

Replace

```yaml

  - id: memox_v7.design_system.no_bare_font_weight
    type: regex
```

with

```yaml

  - id: memox_v8.design_system.no_bare_font_weight
    type: regex
```

Replace

```yaml
  # `text_restyle_alias_test.dart`'s, a two-pass scan a regex cannot be.
  - id: memox_v7.design_system.no_text_restyle
    type: regex
```

with

```yaml
  # `text_restyle_alias_test.dart`'s, a two-pass scan a regex cannot be.
  - id: memox_v8.design_system.no_text_restyle
    type: regex
```

Replace

```yaml
  # a glyph, which MxIcon exists to own.
  - id: memox_v7.design_system.no_raw_icon_color
    type: regex
```

with

```yaml
  # a glyph, which MxIcon exists to own.
  - id: memox_v8.design_system.no_raw_icon_color
    type: regex
```

Replace

```yaml
  # call written on one line.
  - id: memox_v7.design_system.color_scheme_arguments_are_m3_roles
    type: regex
```

with

```yaml
  # call written on one line.
  - id: memox_v8.design_system.color_scheme_arguments_are_m3_roles
    type: regex
```

Replace

```yaml
  # exactly this reason).
  - id: memox_v7.design_system.color_scheme_reads_are_m3_roles
    type: regex
```

with

```yaml
  # exactly this reason).
  - id: memox_v8.design_system.color_scheme_reads_are_m3_roles
    type: regex
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: design_token
#
```

with

```yaml
# MemoX V8 guard rules — domain: design_token
#
```

Replace

```yaml
  id: memox-v8-design-token
  name: MemoX V7 Design Token Rules
  description: Colour, typography and spacing must come from tokens, not literals.
```

with

```yaml
  id: memox-v8-design-token
  name: MemoX V8 Design Token Rules
  description: Colour, typography and spacing must come from tokens, not literals.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-error-handling-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: error_handling
#
```

with

```yaml
# MemoX V8 guard rules — domain: error_handling
#
```

Replace

```yaml
  id: memox-v8-error-handling
  name: MemoX V7 Error Handling Rules
  description: Exception handling, failure mapping and logging discipline.
```

with

```yaml
  id: memox-v8-error-handling
  name: MemoX V8 Error Handling Rules
  description: Exception handling, failure mapping and logging discipline.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-i18n-rules.yaml`:

Replace

```yaml
  id: memox-v8-i18n
  name: MemoX V7 Localization Rules
  description: User-visible strings must come from ARB, not from literals.
```

with

```yaml
  id: memox-v8-i18n
  name: MemoX V8 Localization Rules
  description: User-visible strings must come from ARB, not from literals.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-naming-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: naming
#
```

with

```yaml
# MemoX V8 guard rules — domain: naming
#
```

Replace

```yaml
  id: memox-v8-naming
  name: MemoX V7 Naming Rules
  description: File naming, role suffixes, and banned vague type names.
```

with

```yaml
  id: memox-v8-naming
  name: MemoX V8 Naming Rules
  description: File naming, role suffixes, and banned vague type names.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-privacy-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: privacy
#
```

with

```yaml
# MemoX V8 guard rules — domain: privacy
#
```

Replace

```yaml
  id: memox-v8-privacy
  name: MemoX V7 Privacy Rules
  description: Card content and other private data must never reach logs or exports.
```

with

```yaml
  id: memox-v8-privacy
  name: MemoX V8 Privacy Rules
  description: Card content and other private data must never reach logs or exports.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-state-management-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: state_management
#
```

with

```yaml
# MemoX V8 guard rules — domain: state_management
#
```

Replace

```yaml
  id: memox-v8-state-management
  name: MemoX V7 State Management Rules
  description: Riverpod 3 provider and controller rules — the riverpod_lint replacement.
```

with

```yaml
  id: memox-v8-state-management
  name: MemoX V8 State Management Rules
  description: Riverpod 3 provider and controller rules — the riverpod_lint replacement.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml`:

Replace

```yaml
# MemoX V7 guard rules — domain: testing
#
```

with

```yaml
# MemoX V8 guard rules — domain: testing
#
```

Replace

```yaml
  id: memox-v8-testing
  name: MemoX V7 Testing Rules
  description: Test hygiene — no silently disabled or focused tests.
```

with

```yaml
  id: memox-v8-testing
  name: MemoX V8 Testing Rules
  description: Test hygiene — no silently disabled or focused tests.
```

- [ ] **Step 5: Point the skill and ADR-011 at the new ids**

In `.claude/skills/flutter-theme-design/SKILL.md`:

Replace

```markdown
**Trạng thái vs. đích.** Checklist này là *đích*, không phải mô tả hiện trạng.
Guard `memox_v7.design_system.no_raw_button` hôm nay mới phủ bốn nút; danh sách
cấm đầy đủ ở `references/legacy-and-guards.md` §XI là nơi guard sẽ lớn tới.
```

with

```markdown
**Trạng thái vs. đích.** Checklist này là *đích*, không phải mô tả hiện trạng.
Guard `memox_v8.design_system.no_raw_button` hôm nay mới phủ bốn nút; danh sách
cấm đầy đủ ở `references/legacy-and-guards.md` §XI là nơi guard sẽ lớn tới.
```

In `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`:

Replace

```markdown
    `docs/wbs.md`, các số AD khác).
  - 13 rule `memox_v7.design_system.*` trong ruleset `memox-v8`.
```

with

```markdown
    `docs/wbs.md`, các số AD khác).
  - 13 rule `memox_v7.design_system.*` trong ruleset `memox-v8`: đã đổi thành
    `memox_v8.design_system.*` ở BE-D6 (gói 12b).
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `generate.py` prints `OK docs/_generated: generated 3 files` and changes nothing
under `docs/_generated/`; `check.py` ends with `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 6: Run the guard tests**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `205 passed`: the base's 204 and the contract test.

- [ ] **Step 7: Compare the resolved rules with the base**

```bash
python3 .superpowers/sdd/2026-09-27-guard-without-v7/compare_rules.py b0e5549
```

Expected: `85 rules before, 85 after; only before: []; only after: []` and `0 changed`:
the thirteen ids are renamed, and no rule changed or went missing.

- [ ] **Step 8: Stage the task's files**

The renames and deletions are staged already, by `git mv` and `git rm`. The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-theme-design/SKILL.md \
  code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-error-handling-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-i18n-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-naming-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-privacy-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-state-management-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml \
  code-verification-guard-v2/tests/test_max_lines_rule.py \
  code-verification-guard-v2/tests/test_memox_false_positive_regressions.py \
  code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py \
  code-verification-guard-v2/tests/test_memox_v8_design_token_guard_rules.py \
  code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py \
  code-verification-guard-v2/tests/test_memox_v8_spacing_literal_rules.py \
  docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md
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
tests `Ran 65 tests` and `OK`; `205 passed` (the guard's self-tests);
`Code verification passed.`; `+2244: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
refactor(guard): memox-v8 names itself V8 (BE-D6)

memox-v8 was born as a copy of memox-v7 and still called itself "MemoX V7":
its ten file headers, its ten registry names and its scopes document. It
now says "MemoX V8", and its thirteen memox_v7.design_system.* ids become
memox_v8.design_system.*, the prefix V8's own design-system rule already
uses. The names after the prefix stay.

V7's three probe files move to memox-v8 as test_memox_v8_*.py, read the
memox-v8 registry and use the new ids; the false-positive regressions read
memox-v8, and the max-lines docstring names it. A contract test pins that
no file of memox-v8 names memox-v7, memox_v7 or "MemoX V7". The theme skill
and ADR-011 name the new ids.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The rules named after V7 look for V8's names

**Files:**
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`
- Test (create): `code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py`, `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py`
- Test (modify): `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`

**Interfaces:**
- Consumes: Task 1's probe files and their `_rule_config(rule_id)` and
  `_violations(rule_id, tmp_path, …)` helpers; the comparison script.
- Produces: the ids `memox.data_model.no_coalesce_parent_id` and
  `memox.data_model.no_schedule_columns_on_card_table`, and the probe files
  `test_memox_v8_data_model_guard_rules.py` and
  `test_memox_v8_architecture_guard_rules.py`.

Spec §5.1, §8.1 (the probes), D5; Clarifications 1–3; Review Focus 2–4.

- [ ] **Step 1: Write the probes, both directions**

Each probe has both directions: the defect in V8's names goes red, and V8's correct shape,
including a comment that quotes the defect, stays silent (Clarification 1).

Create `code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py`:

```python
"""Fault-injection probes for the memox-v8 architecture rules that name V8's code."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import yaml

from code_verification_guard.factory.rule_factory import RuleFactory

REGISTRY_PATH = (
    Path(__file__).parents[1]
    / "registries"
    / "projects"
    / "memox-v8"
    / "rules"
    / "memox-architecture-rules.yaml"
)
DB_ACCESS = "memox.architecture.widget_no_database_access"


def _rule_config(rule_id: str) -> dict:
    registry = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    for rule_config in registry.get("rules", []):
        if rule_config["id"] == rule_id:
            return deepcopy(rule_config)

    raise AssertionError(f"Rule not found: {rule_id}")


def _violations(rule_id: str, tmp_path: Path, source: str) -> list:
    source_path = (
        tmp_path / "lib" / "features" / "deck" / "presentation" / "widgets" / "sections"
        / "sample_section_widget.dart"
    )
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_text(source, encoding="utf-8")

    rule_config = _rule_config(rule_id)
    rule_config.pop("scopes", None)
    rule_config["include"] = ["lib/**/*.dart"]
    rule_config["exclude"] = []
    rule_config["enabled"] = True

    return RuleFactory().create(rule_config).check(tmp_path)


def test_widget_database_access_goes_red_on_v8s_database(tmp_path: Path) -> None:
    for bad in (
        "    final database = ref.watch(databaseProvider);\n",
        "    final rows = await ref.read(databaseProvider).select(table).get();\n",
        "    final rows = await database.select(database.card).get();\n",
        "    final decks = await deckDao.rootDecks();\n",
    ):
        assert _violations(DB_ACCESS, tmp_path, bad), bad


def test_widget_database_access_leaves_use_cases_and_prose_alone(tmp_path: Path) -> None:
    good = """
    // A widget reads through a use case, never databaseProvider.
    final decks = ref.watch(deckListProvider);
    final result = await ref.read(renameDeckUseCaseProvider).call(id, name);
    """
    assert not _violations(DB_ACCESS, tmp_path, good)
```

Create `code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py`:

```python
"""Fault-injection probes for the memox-v8 data-model rules.

Each rule looks for V8's names, and each is pinned in both directions: it
reports the defect written the way V8's code would write it, and it stays
silent on V8's correct shape, including a comment that quotes the defect.
"""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import yaml

from code_verification_guard.factory.rule_factory import RuleFactory

REGISTRY_PATH = (
    Path(__file__).parents[1]
    / "registries"
    / "projects"
    / "memox-v8"
    / "rules"
    / "memox-data-model-rules.yaml"
)


def _rule_config(rule_id: str) -> dict:
    registry = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    for rule_config in registry.get("rules", []):
        if rule_config["id"] == rule_id:
            return deepcopy(rule_config)

    raise AssertionError(f"Rule not found: {rule_id}")


def _violations(rule_id: str, tmp_path: Path, relative_path: str, source: str) -> list:
    source_path = tmp_path / relative_path
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_text(source, encoding="utf-8")

    rule_config = _rule_config(rule_id)
    rule_config.pop("scopes", None)
    rule_config["include"] = [relative_path]
    rule_config["exclude"] = []
    rule_config["enabled"] = True

    return RuleFactory().create(rule_config).check(tmp_path)


DAO = "lib/features/srs/data/datasources/sample_dao.dart"
QUERIES = "lib/core/database/tables/sample.drift"
CARD_TABLE = "lib/core/database/tables/card.drift"
SCREEN = "lib/features/study/presentation/widgets/sections/sample_widget.dart"
MODEL = "lib/features/srs/domain/models/sample_model.dart"

COALESCE = "memox.data_model.no_coalesce_parent_id"
CARD_COLUMNS = "memox.data_model.no_schedule_columns_on_card_table"
ACTIONS = "memox.data_model.review_actions_from_supported_actions"
KIND = "memox.data_model.review_kind_not_inferred"


def test_no_coalesce_parent_id_goes_red_on_every_spelling(tmp_path: Path) -> None:
    for relative_path, bad in (
        (QUERIES, "SELECT COALESCE(d.parent_id, d.id) AS root_id FROM deck d;\n"),
        (QUERIES, "SELECT coalesce(parent_id, id) FROM deck;\n"),
        (DAO, "        'SELECT COALESCE(parent_id, id) FROM deck'\n"),
        (DAO, "    final root = coalesce([deck.parentId, deck.id]);\n"),
    ):
        assert _violations(COALESCE, tmp_path, relative_path, bad), bad


def test_no_coalesce_parent_id_leaves_the_root_column_and_prose_alone(tmp_path: Path) -> None:
    dao = """
  /// The root of [cardId]'s tree, reached through `card.deck_id` and then
  /// `deck.root_id` — never `COALESCE(parent_id, id)` (BR-DECK-003); null
  /// when the card or its deck is in the Trash (BE-C3).
          ' JOIN deck root ON root.id = d.root_id'
"""
    queries = "-- never COALESCE(parent_id, id): the root is root_id\nSELECT root_id FROM deck;\n"
    assert not _violations(COALESCE, tmp_path, DAO, dao)
    assert not _violations(COALESCE, tmp_path, QUERIES, queries)


_TABLES = """CREATE TABLE card (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES deck (id) ON DELETE CASCADE,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  -- NULL = active; otherwise a tombstone of that batch. Its schedule, due_at
  -- and all, lives in card_schedule.
  delete_batch_id TEXT REFERENCES delete_batches (id) ON DELETE CASCADE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) AS CardRow;

CREATE TABLE card_schedule (
  card_id TEXT NOT NULL PRIMARY KEY REFERENCES card (id) ON DELETE CASCADE,
  generation INTEGER NOT NULL,
  due_at DATETIME,
  current_box INTEGER,
  ease_factor REAL,
  interval_days INTEGER
) AS CardSchedule;
"""


def test_no_schedule_columns_on_card_table_goes_red_on_a_schedule_column(tmp_path: Path) -> None:
    # Before and after the comment whose `;` ends a naive `[^;]*` scan.
    for anchor in ("  back TEXT NOT NULL,\n", "  created_at DATETIME NOT NULL,\n"):
        for column in ("generation INTEGER NOT NULL", "due_at DATETIME", "current_box INTEGER",
                       "ease_factor REAL", "interval_days INTEGER", "scheduler_type TEXT"):
            bad = _TABLES.replace(anchor, f"{anchor}  {column},\n", 1)
            assert _violations(CARD_COLUMNS, tmp_path, CARD_TABLE, bad), (anchor, column)


def test_no_schedule_columns_on_card_table_leaves_v8s_tables_alone(tmp_path: Path) -> None:
    assert not _violations(CARD_COLUMNS, tmp_path, CARD_TABLE, _TABLES)


def test_review_actions_go_red_on_a_hardcoded_set(tmp_path: Path) -> None:
    for bad in (
        "for (final a in [Sm2Action.again, Sm2Action.hard, Sm2Action.good, Sm2Action.easy]) {}\n",
        """const grades = [
  Sm2Action.again,
  Sm2Action.hard,
  Sm2Action.good,
  Sm2Action.easy,
];
""",
        "const actions = [EightBoxAction.forgotten, EightBoxAction.remembered];\n",
    ):
        assert _violations(ACTIONS, tmp_path, SCREEN, bad), bad


def test_review_actions_leave_the_label_switch_and_supported_actions_alone(tmp_path: Path) -> None:
    good = """
  String studyGrade(Sm2Action action) => switch (action) {
    Sm2Action.again => cardActionAgain,
    Sm2Action.hard => cardActionHard,
    Sm2Action.good => cardActionGood,
    Sm2Action.easy => cardActionEasy,
  };
  String cardAction(Object action) => switch (action) {
    EightBoxAction.forgotten => cardActionForgotten,
    EightBoxAction.remembered => cardActionRemembered,
    _ => '',
  };
  final buttons = [for (final action in scheduler.supportedActions) button(action)];
"""
    assert not _violations(ACTIONS, tmp_path, SCREEN, good)


def test_review_kind_goes_red_when_inferred_from_the_boxes(tmp_path: Path) -> None:
    for bad in (
        "final kind = previousBox == nextBox ? ReviewKind.relearning : ReviewKind.scheduled;\n",
        "    kind: entry.previousBox != entry.nextBox ? ReviewKind.scheduled : ReviewKind.relearning,\n",
        "final turnKind = before.currentBox == after.currentBox ? ReviewKind.relearning : null;\n",
    ):
        assert _violations(KIND, tmp_path, MODEL, bad), bad


def test_review_kind_leaves_the_stored_and_session_kinds_alone(tmp_path: Path) -> None:
    good = """
  if (round > 1 || answersInSession > 0) return ReviewKind.relearning;
        kind: ReviewKind.scheduled,
    kind: round > 1 ? ReviewKind.relearning : ReviewKind.scheduled,
  final kind = turn.kind;
"""
    assert not _violations(KIND, tmp_path, MODEL, good)
```

In `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`:

Replace

```python

def test_no_text_restyle_sees_the_hint_accessor(tmp_path: Path) -> None:
    # A20.1 P1-09: the extension's fifth accessor is a resolved style; a
    # `.copyWith(` on it is the same restyle in a new spelling.
    violations = _violations(
```

with

```python

def test_no_text_restyle_sees_the_hint_style(tmp_path: Path) -> None:
    # `MxTextStyles.inputHint` is a resolved style like the others; a
    # `.copyWith(` on it is the same restyle, however the styles are reached.
    assert _violations(
        RESTYLE,
        tmp_path,
        "final s = context.textStyles.inputHint.copyWith(color: Colors.red);\n",
    )
    violations = _violations(
```

Replace

```python
        tmp_path,
        "final s = context.inputHintStyle!.copyWith(color: Colors.red);\n",
    )
    assert len(violations) == 1
```

with

```python
        tmp_path,
        "final s = MxTextStyles(texts, scheme).inputHint.copyWith(color: ink);\n",
    )
    assert len(violations) == 1


def test_no_text_restyle_leaves_the_hint_style_alone(tmp_path: Path) -> None:
    good = """
    hintStyle: MxTextStyles(texts, scheme).inputHint,
    style: context.textStyles.inputHint,
    """
    assert not _violations(RESTYLE, tmp_path, good)
```

- [ ] **Step 2: Run the guard tests to see them fail**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `8 failed, 208 passed`: `test_widget_database_access_goes_red_on_v8s_database`
for `final database = ref.watch(databaseProvider);`; the four probes of the coalesce and
card-table rules with `AssertionError: Rule not found:` and their new ids;
`test_review_actions_go_red_on_a_hardcoded_set` for
`[Sm2Action.again, Sm2Action.hard, Sm2Action.good, Sm2Action.easy]`;
`test_review_kind_goes_red_when_inferred_from_the_boxes` for
`final kind = previousBox == nextBox ? …`; and `test_no_text_restyle_sees_the_hint_style`
(`assert 0 == 1`). The silent probes of the actions, the kind and the database rules pass
already: V7's patterns see none of V8's names.

- [ ] **Step 3: Retarget the four data-model rules**

The patterns of Clarification 1, and the messages, hints and comments that cite V8's
owners (Clarification 2).

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml` with:

```yaml
# MemoX V8 guard rules — domain: data_model
#
# These encode the memox invariants that are cheap to violate and expensive to
# discover. BR-DECK-003 is the headline: COALESCE(parent_id, id) LOOKS like it
# resolves the root deck and does so correctly for a two-level tree — it returns
# the wrong deck from the third level down. Every test written against a shallow
# fixture passes. Only a real user with a nested deck finds it.
version: 1
metadata:
  id: memox-v8-data-model
  name: MemoX V8 Data Model Rules
  description: Deck-tree, scheduler and review-history invariants (BR-xx, AD-06, AD-11).
  owner: memox-v8
rules:
  - id: memox.data_model.no_coalesce_parent_id
    type: regex
    severity: error
    enabled: true
    message: >-
      BR-DECK-003 — never resolve a root deck with `COALESCE(parent_id, id)`.
      It returns the level-2 deck at depth 3 and every shallow-fixture test
      still passes. Use `deck.root_id`.
    scopes:
      - dart_source
      - drift_sql_files
    # SQL in any case, in a `.drift` file or a Dart string, and Drift's
    # `coalesce([deck.parentId, …])`. A comment line that quotes the form is
    # prose: `srs_dao.dart` says why it joins on `root_id` in these words.
    patterns:
      - '^(?!\s*(?://|\*|--)).*\b(?i:coalesce)\s*\(\s*\[?\s*(?:[A-Za-z_][A-Za-z0-9_]*\.)?(?:parent_id|parentId)\b'
    tags:
      - memox
      - data-model
      - correctness
    fix:
      hint: Join on `deck.root_id`, which every deck carries (BR-DECK-003).

  # AD-06: scheduling must be a pure function of its inputs, or the whole matrix
  # of box x action becomes untestable.
  - id: memox.data_model.scheduler_no_ambient_now
    type: regex
    severity: error
    enabled: true
    message: >-
      AD-06 — domain code must not read the ambient clock. `now` is passed in,
      so behaviour is testable at a fixed instant; for the scheduler this is what
      makes the full 8-box x action matrix deterministic.
    scopes:
      - domain_files
    patterns:
      - \bDateTime\s*\.\s*now\s*\(
      - \bclock\s*\.\s*now\s*\(
    tags:
      - memox
      - data-model
      - correctness

  # M4.3: "due" must mean the same thing in every query, and a hardcoded
  # CURRENT_TIMESTAMP makes a query untestable at a fixed point in time.
  - id: memox.data_model.drift_no_current_timestamp
    type: regex
    severity: error
    enabled: true
    message: >-
      Use a `:now` parameter instead of `CURRENT_TIMESTAMP` in SQL — in .drift
      files and in raw SQL passed to customStatement/customSelect alike — so
      "due" is testable at a fixed instant and means the same thing everywhere.
    scopes:
      - dart_source
      - drift_sql_files
    patterns:
      - \bCURRENT_TIMESTAMP\b
      - "\\bdatetime\\s*\\(\\s*'now'"
    tags:
      - memox
      - data-model
      - correctness

  # BR-SRS-015: a turn's kind is stored when the turn is written, never inferred
  # by comparing the state before and after it. A scheduled turn on a box-8
  # card answered `remembered` has `previous_box == next_box == 8` and would
  # read as relearning, and history written with the wrong label cannot be
  # recomputed later. A kind decided from the session (BR-SRS-016, BR-SRS-017)
  # compares no states and stays legal.
  - id: memox.data_model.review_kind_not_inferred
    type: regex
    severity: error
    enabled: true
    message: >-
      BR-SRS-015 — a turn's `kind` is stored, never inferred. Deriving it from a
      box or interval comparison is wrong for a scheduled turn on a box-8 card,
      and mislabelled history cannot be recomputed later.
    scopes:
      - dart_lib
    # `kind` or any `…Kind` given a value (`:` or a single `=`) from a
    # comparison of the boxes or the interval.
    patterns:
      - '\b(?:kind|[A-Za-z_][A-Za-z0-9_]*Kind)\s*(?::|=(?!=))[^;]*\b(?:previousBox|nextBox|currentBox|intervalDays)\s*[!=]='
    tags:
      - memox
      - data-model
      - correctness

  # ADR-004: a reset starts a new generation of a deck's schedules and keeps
  # every card's content. That holds while `card` keeps the content and
  # `card_schedule` the schedule: a schedule column on `card` is content a
  # reset would have to touch.
  - id: memox.data_model.no_schedule_columns_on_card_table
    type: regex
    severity: error
    enabled: true
    message: >-
      `card` holds content only; the schedule lives in `card_schedule`
      (`generation`, `due_at`, `current_box`, `ease_factor`, …). Content must
      survive every reset (ADR-004).
    scopes:
      - dart_source
      - drift_sql_files
    # A column is a line of the table's body that starts with its name, and the
    # body runs to the line that closes the table, not to the first `;`: a
    # comment inside the table may hold one. `(?:(?!\n\)).)*?` takes each
    # character one way, so a table with no schedule column fails fast; an
    # alternation such as `(?:[^;]|\n)*` gives every newline two ways to be
    # consumed and backtracks exponentially.
    patterns:
      - '(?s)CREATE\s+TABLE\s+card\s*\((?:(?!\n\)).)*?\n\s*(?:generation|learned_at|due_at|last_answered_at|answer_count|lapse_count|current_box|ease_factor|interval_days|repetitions|scheduler_type|scheduler_version)\s+\w'
    mode: file
    tags:
      - memox
      - data-model
      - correctness

  # ADR-003: the two schedulers have different action sets, and the UI renders
  # the buttons from the deck's scheduler. Hardcoding sm2's four is wrong for
  # every eight_box deck.
  - id: memox.data_model.review_actions_from_supported_actions
    type: regex
    severity: error
    enabled: true
    message: >-
      ADR-003 — render review buttons from the scheduler's `supportedActions`.
      `eight_box` has two actions and `sm2` has four; a hardcoded set is wrong
      for every deck of the other scheduler.
    scopes:
      - presentation_files
    # A set written out: the values side by side with nothing but commas
    # between them, on one line or over several. A `switch` that maps each
    # action to its label puts `=>` between them and stays legal.
    patterns:
      - 'Sm2Action\.again\s*,\s*Sm2Action\.hard\s*,\s*Sm2Action\.good\s*,\s*Sm2Action\.easy\b'
      - 'EightBoxAction\.forgotten\s*,\s*EightBoxAction\.remembered\b'
    mode: file
    tags:
      - memox
      - data-model
      - correctness
```

- [ ] **Step 4: Retarget widget_no_database_access and no_text_restyle**

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`:

Replace

```yaml
      - widget_ui_files
    patterns:
      - '\b(?:_?database|_?db|appDatabase)\s*\.\s*(?:select|into|update|delete|customSelect|customStatement|customSelectStream)\s*\('
      - '\b_?[A-Za-z0-9]*Dao\s*\.\s*[a-z][A-Za-z0-9_]*\s*\('
    tags:
```

with

```yaml
      - widget_ui_files
    # A query on the database or a DAO, or the database provider itself, read
    # outside a comment.
    patterns:
      - '\b(?:_?database|_?db)\s*\.\s*(?:select|into|update|delete|customSelect|customStatement|customSelectStream)\s*\('
      - '\b_?[A-Za-z0-9]*Dao\s*\.\s*[a-z][A-Za-z0-9_]*\s*\('
      - '^(?!\s*(?://|\*)).*\bdatabaseProvider\b'
    tags:
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`:

Replace

```yaml
      - '^(?!\s*(?://|\*)).*\btextStyles\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
      # `inputHintStyle` is a resolved style, consumed whole; a `.copyWith(`
      # on it is the same restyle through the extension's fifth accessor
      # (A20.1 P1-09).
      - '^(?!\s*(?://|\*)).*\binputHintStyle[!?]?\s*\.copyWith\s*\('
      - '^(?!\s*(?://|\*)).*\btextTheme\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
```

with

```yaml
      - '^(?!\s*(?://|\*)).*\btextStyles\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
      # `MxTextStyles.inputHint` is a resolved style, consumed whole; a
      # `.copyWith(` on it is the same restyle, however the styles are reached.
      - '^(?!\s*(?://|\*)).*\binputHint[!?]?\s*\.copyWith\s*\('
      - '^(?!\s*(?://|\*)).*\btextTheme\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
```

- [ ] **Step 5: Run the guard tests**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `216 passed`.

- [ ] **Step 6: Compare the resolved rules with the base**

```bash
python3 .superpowers/sdd/2026-09-27-guard-without-v7/compare_rules.py b0e5549
```

Expected: `85 rules before, 85 after; only before: []; only after: []`, then one
`changed <id>: patterns` line for each of `memox.architecture.widget_no_database_access`,
`memox.data_model.no_coalesce_parent_id`,
`memox.data_model.no_schedule_columns_on_card_table`,
`memox.data_model.review_actions_from_supported_actions`,
`memox.data_model.review_kind_not_inferred` and `memox_v8.design_system.no_text_restyle`,
and `6 changed`.

- [ ] **Step 7: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml \
  code-verification-guard-v2/tests/test_memox_v8_architecture_guard_rules.py \
  code-verification-guard-v2/tests/test_memox_v8_data_model_guard_rules.py \
  code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py
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
tests `Ran 65 tests` and `OK`; `216 passed` (the guard's self-tests);
`Code verification passed.`; `+2244: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
fix(guard): the rules named after V7 look for V8's names (BE-D6)

Six memox-v8 rules matched names V8 does not have, so they could never
fire. They now match V8's shapes (spec 5.1), each pinned by a probe that
fires on the violation and stays silent on V8's correct code:

- no_coalesce_parent_id (was no_coalesce_parent_deck_id): COALESCE on
  parent_id or parentId, in SQL of any case or Drift's coalesce([...]);
  the root lives in deck.root_id (BR-DECK-003).
- no_schedule_columns_on_card_table (was
  no_scheduler_generation_on_cards_table): a schedule column in CREATE
  TABLE card; they live in card_schedule.
- review_actions_from_supported_actions: a hardcoded list of all four
  Sm2Action or both EightBoxAction values (ADR-003); the label switch
  stays legal.
- review_kind_not_inferred: a kind assigned from a box or interval
  comparison (BR-SRS-015).
- widget_no_database_access: databaseProvider, V8's handle on the
  database, in place of V7's appDatabase.
- no_text_restyle: V8's inputHint style in place of V7's inputHintStyle.

The four data-model rules' messages and hints name V8's owners.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: memox-v8 cites V8 and names V8's code

**Files:**
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/config/profiles.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/README.md`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-error-handling-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-naming-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-privacy-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-state-management-rules.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml`
- Test (modify): `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`, `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py`

**Interfaces:**
- Consumes: Task 1's `_occurrences`; the comparison script.
- Produces: `V7_MARKERS` (six named patterns) and
  `test_memox_v8_cites_no_v7_decision_or_document` in the contract test.

Spec §5.2–§5.4, §6, D2, D6; Clarifications 3–5.

- [ ] **Step 1: Write the contract test for V7's references, and give the probes V8's names**

The probe samples take V8's names (`MxAppShell`, `MxAppBar`, `MxFilterChip`,
`showMxBottomSheet`, `MxBottomSheet`, `MxSpinner`, `MxSkeletonList`,
`textStyles.rowTitle`), and the loading rule's exclusion test goes with the exclusion
(Clarification 5).

In `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`:

Replace

```python
    good = """
    // The shell used to build an AppBar( here; it now owns the chrome.
    /// A doc comment that says SliverAppBar( is still prose.
    final AppBarTheme theme = AppBarTheme(centerTitle: false);
    return MxContentShell(title: title, body: child);
    """
```

with

```python
    good = """
    // MxAppShell owns the chrome; a raw AppBar( here would route around it.
    /// A doc comment that says SliverAppBar( is still prose.
    final AppBarTheme theme = AppBarTheme(centerTitle: false);
    return MxAppShell(appBar: MxAppBar(title: title), body: child);
    """
```

Replace

```python
    good = """
    // MxPillButton wraps a ChoiceChip( so features never build one.
    Chip(label: Text(tag.name), onDeleted: remove),
    ActionChip(avatar: const Icon(Icons.add), label: Text(add), onPressed: open),
    MxPillButton(label: label, isSelected: isSelected, onPressed: onPick),
    """
```

with

```python
    good = """
    // MxFilterChip owns the pick-one chip, so features never build a ChoiceChip(.
    Chip(label: Text(tag.name), onDeleted: remove),
    ActionChip(avatar: const Icon(Icons.add), label: Text(add), onPressed: open),
    MxFilterChip(label: label, isSelected: isSelected, onSelected: onPick),
    """
```

Replace

```python
      context: context,
      builder: (sheetContext) => MxActionSheet(actions: actions),
    );
```

with

```python
      context: context,
      builder: (sheetContext) => MxBottomSheet(child: options),
    );
```

Replace

```python
    good = """
    // showModalBottomSheet( used to be called here; showMxSheet owns it.
    final chosen = await showMxSheet<DeckListSort>(
      context,
      builder: (sheetContext) => MxActionSheet(actions: actions),
    );
```

with

```python
    good = """
    // showMxBottomSheet owns the route; a raw showModalBottomSheet( bypasses it.
    final chosen = await showMxBottomSheet<DeckListSort>(
      context,
      builder: (sheetContext) => MxBottomSheet(child: options),
    );
```

Replace

```python
    // A bare CircularProgressIndicator( announces nothing.
    child: MxLoadingState.inline(semanticsLabel: label),
    child: MxLoadingState(semanticsLabel: label),
    """
    assert not _violations(LOADING, tmp_path, good)


def test_no_raw_loading_indicator_excludes_the_determinate_ring() -> None:
    rule = _rule_config(LOADING)
    assert rule["exclude"] == [
        "**/card/presentation/widgets/sections/card_progress_panel_widget.dart"
    ]

```

with

```python
    // A bare CircularProgressIndicator( announces nothing.
    child: MxSpinner(semanticLabel: label),
    child: MxSkeletonList(semanticLabel: label),
    """
    assert not _violations(LOADING, tmp_path, good)

```

Replace

```python
        "style: context.texts.bodySmall?.copyWith(color: colors.error),",
        "style: context.textStyles.sectionLabel.copyWith(color: colors.onSurfaceVariant),",
        "style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),",
```

with

```python
        "style: context.texts.bodySmall?.copyWith(color: colors.error),",
        "style: context.textStyles.rowTitle.copyWith(color: colors.onSurfaceVariant),",
        "style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),",
```

Replace

```python

def test_no_text_restyle_accepts_inked_and_prose(tmp_path: Path) -> None:
    good = """
    // texts.bodySmall!.copyWith( is the spelling this rule refuses.
    style: context.texts.bodySmall!.inked(context, AppInk.quiet),
    style: AppTypography.withWeight(
```

with

```python

def test_no_text_restyle_accepts_named_styles_and_prose(tmp_path: Path) -> None:
    good = """
    // texts.bodySmall!.copyWith( is the spelling this rule refuses.
    style: context.textStyles.rowTitle,
    style: AppTypography.withWeight(
```

Replace

```python
      FontWeight.w600,
    ).inked(context, AppInk.stated).copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
```

with

```python
      FontWeight.w600,
    ),
```

In `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py`:

Replace

```python
    assert _occurrences(r"(?i)memox[-_ ]v7") == []
```

with

```python
    assert _occurrences(r"(?i)memox[-_ ]v7") == []


V7_MARKERS = {
    "the word V7": r"(?i)\bv7\b",
    "a V7 architecture decision": r"\bAD-\d",
    "a V7 business rule": r"\bBR-\d",
    "V7's design-system audit": r"A20\.1|\bP[1-3]-\d\d\b",
    "a V7 milestone": r"\bM\d+\.\d+",
    "V7's work breakdown": r"docs/wbs\.md",
}


def test_memox_v8_cites_no_v7_decision_or_document() -> None:
    found = {name: _occurrences(pattern) for name, pattern in V7_MARKERS.items()}
    assert {name: hits for name, hits in found.items() if hits} == {}
```

- [ ] **Step 2: Run the guard tests to see them fail**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `1 failed, 215 passed`: `test_memox_v8_cites_no_v7_decision_or_document` finds
all six markers (66 hits), among them `config/scopes.yaml:266: A20.1`. The probes with
V8's names pass already: the rules refuse raw widgets, whatever the owner's name.

- [ ] **Step 3: Rewrite the configuration: overrides, profiles and scopes**

Every reason states V8's authority or its reason in place (spec §6); `provider_files`
loses its two V7 globs (spec §5.2).

In `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`:

Replace

```yaml
    # same measurement at two severities — a warning at 400 and an error at 500
    # — and until this line they counted in different units, so the ladder was
    # not a ladder. Raw counting also measured the wrong thing for this
    # codebase: `lib/core/theme/app_colors.dart` is 400 raw lines and **56
    # logical** ones, because 86% of it is the rationale for each colour. A
    # budget that a paragraph can exhaust teaches people to delete the
    # paragraph, which is the opposite of what a maintainability rule is for.
    #
```

with

```yaml
    # same measurement at two severities — a warning at 400 and an error at 500
    # — and they must count in one unit, or the ladder is not a ladder. Raw
    # counting also measures the wrong thing for this codebase, where a theme
    # or domain file is mostly the rationale in its dartdoc. A budget that a
    # paragraph can exhaust teaches people to delete the paragraph, which is
    # the opposite of what a maintainability rule is for.
    #
```

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/config/profiles.yaml` with:

```yaml
version: 1

profiles:
  # Local and CI are deliberately identical. A guard that is stricter in CI than
  # on the developer's machine teaches people to push and find out, which is the
  # slowest possible feedback loop.
  #
  # Every rule has real targets, so warnings are failures. A
  # `rule_without_targets` diagnostic is never noise waiting for code to
  # arrive: a scope that matches no file leaves its rule guarding nothing, and
  # the diagnostic is the only thing that says so. It must never be silenced;
  # a rule that waits for a layer V8 has not built says so with
  # `targets_pending` in `overrides.yaml`.
  local:
    failure:
      fail_on:
        - error
        - warning
      warning_as_error: true
    report:
      format: console
      show_code_line: true
      show_fix_hint: true
    overrides:
      disabled_rules: []
      severity: {}
      rule_options: {}

  ci:
    failure:
      fail_on:
        - error
        - warning
      warning_as_error: true
    report:
      format: console
      show_code_line: true
      show_fix_hint: true
    overrides:
      disabled_rules: []
      severity: {}
      rule_options: {}
```

In `code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml`:

Replace

```yaml
  # ---- memox-v8 layer scopes ----
  # Layer boundaries per CLAUDE.md "Layering". These three are the load-bearing
  # scopes: most architecture rules are just "this pattern, in this layer".
```

with

```yaml
  # ---- memox-v8 layer scopes ----
  # Layer boundaries per ADR-010 and ADR-011. These three are the load-bearing
  # scopes: most architecture rules are just "this pattern, in this layer".
```

Replace

```yaml
  # Business layers that must NOT branch on StudyMode. Dispatch belongs to one
  # exhaustive switch beside the enum, in `study_mode.dart` (AD-18); a handler
  # owns its own mode, so it never needs to ask. presentation/ is deliberately
```

with

```yaml
  # Business layers that must NOT branch on StudyMode. Dispatch belongs to one
  # exhaustive switch beside the enum, in `study_mode.dart`; a handler
  # owns its own mode, so it never needs to ask. presentation/ is deliberately
```

Replace

```yaml
  #
  # `**/*_mode.dart` is the one exemption, and it is the only one that can be.
  # This scope used to exempt `study_mode_resolver.dart` as well — a file that
  # cannot exist: `memox.naming.domain_file_role_suffix` admits no `_resolver`
  # suffix under domain/, so the two rules could never both be satisfied by that
  # name. Dead config in a guard is worse than no config: it reads as a
  # permission somebody relied on, and the next reader spends time looking for
  # the file it protects.
  study_mode_non_dispatch:
```

with

```yaml
  #
  # `**/*_mode.dart` is the one exemption: `study_mode.dart` holds the dispatch,
  # and each other `*_mode.dart` is a mode's own handler.
  study_mode_non_dispatch:
```

Replace

```yaml
      - '**/*_state.dart'
      # `presentation/providers/` — added at M4.10 with the use-case layer. A file
      # whose whole job is dependency wiring reads a repository *by definition*
      # and hands it to a use case that the widgets then reach through a
```

with

```yaml
      - '**/*_state.dart'
      # `presentation/providers/`: a file whose whole job is dependency wiring
      # reads a repository *by definition*
      # and hands it to a use case that the widgets then reach through a
```

Replace

```yaml

  # Product UI only. lib/app/** is deliberately OUT: it is the dev-channel shell
  # (MobileFrameWidget's backdrop colour is not product UI and is documented as
  # such), and lib/core/theme/** is where raw values are legitimately defined.
  ui_surfaces:
```

with

```yaml

  # Product UI only. lib/app/** is deliberately OUT: it is the composition root
  # and the debug-only widget gallery, not product UI; and lib/core/theme/** is
  # where raw values are legitimately defined.
  ui_surfaces:
```

Replace

```yaml
  # there IS the token — linting it would be flagging the definition as the
  # crime. A duration is not like that. `AppDurations` declares its three rungs
  # as *named* constants, and so does every legitimate non-motion duration in
  # the repo, so the theme directory has nothing that needs the exemption — and
  # it is exactly where `Duration(milliseconds: 500)` sat anonymously inside
  # `tooltipTheme` until M4.10ao. A rule scoped to `ui_surfaces` alone could not
  # catch the case it was written for.
  ui_and_theme_surfaces:
```

with

```yaml
  # there IS the token — linting it would be flagging the definition as the
  # crime. A duration is not like that. `AppDurations` declares every duration
  # as a *named* constant, and so does every legitimate non-motion duration in
  # the repo, so the theme directory has nothing that needs the exemption — and
  # a component theme is exactly where an anonymous `Duration(milliseconds: …)`
  # hides. A rule scoped to `ui_surfaces` alone could not see it there.
  ui_and_theme_surfaces:
```

Replace

```yaml

  # **Typography only, plus `lib/app/`** (A20.1 P2-22). The composition root
  # was in no typography scope, and `error_screen_widget.dart` — the one
  # screen that must render with no `Theme` — set two literal sizes in the
  # platform font because nothing looked. It builds from `AppTypography` now;
  # these two scopes are what keep it there. Colour is *not* widened: the
  # error screen's fallback palette and `MobileFrameWidget` hold literals for
  # reasons their files state, and the colour rules keep their scopes.
  typography_ui_surfaces:
```

with

```yaml

  # **Typography only, plus `lib/app/`.** The composition root and the
  # debug-only gallery set text too (`placeholder_screen.dart`, the gallery's
  # sections), and a text style there comes from the theme like anywhere else;
  # these two scopes are what keep it so. Colour is *not* widened: `lib/app/`
  # is not product UI, and the colour rules keep their scopes.
  typography_ui_surfaces:
```

Replace

```yaml
    include:
      - lib/**/controller/**/*.dart
      - lib/**/*_controller.dart
```

with

```yaml
    include:
      - lib/**/*_controller.dart
```

Replace

```yaml
      - lib/**/providers/**/*.dart
      - lib/core/providers/**/*.dart
    exclude:
```

with

```yaml
      - lib/**/providers/**/*.dart
    exclude:
```

- [ ] **Step 4: Rewrite the registry's README**

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/rules/README.md` with:

````markdown
# memox-v8 ruleset

The main guard for the memox-v8 repository. It owns every check
`flutter analyze` cannot express.

```bash
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

## Why this ruleset exists separately from `memox`

`memox` is the one other MemoX ruleset beside it. It stays for one reason — the
guard's own test suite exercises its rule engine through that ruleset — and it
does not fit this repository:

| Ruleset | Why it does not apply |
|---|---|
| `memox` | Flutter, but a layer-first tree (`lib/presentation/features/**`, `lib/data/datasources/**`). memox-v8 is **feature-first**: `lib/features/<feature>/{domain,data,presentation}`. Every scope path differs, so the rules would silently match nothing. |

No ruleset for another tree is vendored beside them: it would be easy to run
the wrong one, and a ruleset that matches nothing reports a clean pass.

## What it replaces

V8 runs neither `custom_lint` nor `riverpod_lint`: `pubspec.yaml` has neither,
so `flutter analyze` checks no Riverpod usage.

`memox-state-management-rules.yaml` makes those checks. The rule that matters
most is `memox.state_management.no_ref_read_in_build`: `ref.read` inside
`build()` reads without subscribing, so the widget silently stops updating. It
surfaces as "the data is stale" and is very hard to trace back to that line.

## Files

| File | Covers |
|---|---|
| `memox-architecture-rules.yaml` | Layer boundaries (ADR-010, ADR-011), a domain free of infrastructure, one database connection site, deferred dependencies (ADR-001, ADR-002) |
| `memox-state-management-rules.yaml` | Riverpod 3 usage — the riverpod_lint replacement |
| `memox-error-handling-rules.yaml` | Swallowed exceptions, `print`, Failure mapping |
| `memox-design-token-rules.yaml` | No raw colour / text style / spacing in product UI |
| `memox-design-system-rules.yaml` | Features compose the Mx shared widgets; weights, text styles and colour roles go through the theme |
| `memox-i18n-rules.yaml` | No user-visible string outside ARB |
| `memox-data-model-rules.yaml` | The root through `root_id` (BR-DECK-003), no ambient clock in domain, the schedule apart from the card (ADR-004), the stored review kind (BR-SRS-015), buttons from `supportedActions` (ADR-003) |
| `memox-privacy-rules.yaml` | Card content never logged, no secrets, app-private storage |
| `memox-naming-rules.yaml` | snake_case and role suffixes |
| `memox-testing-rules.yaml` | No skipped or focused tests |

## Scope discipline

Design-token and i18n rules run on `ui_surfaces` — `lib/features/*/presentation`
plus `lib/shared` — and deliberately **not** on:

- `lib/core/theme/**`, where raw values are legitimately *defined*; linting it
  would flag the definition as the crime
- `lib/app/**`, the composition root and the debug-only widget gallery, which
  are not product UI. The typography rules still cover it
  (`typography_ui_surfaces`).

## A `rule_without_targets` warning is a finding — do not silence it

A rule whose scope matches no file checks nothing and passes green. The engine
reports it as `guard.config.rule_without_targets`, and both profiles fail on
warnings, so it cannot pass unnoticed. A rule that waits for a layer V8 has not
built yet says so with `targets_pending` in `config/overrides.yaml`.

## Adding a rule

1. Put it in the file whose domain it belongs to; keep the
   `memox.<domain>.<name>` id convention.
2. Prefer an existing scope over a per-rule `include:`.
3. Write the message so it says *why*, not just *what* — the message is the only
   thing the person who trips it will read.
4. **Fault-inject it.** Write a file that violates it, confirm the guard exits 1
   and names your rule, delete the file, confirm exit 0. A rule that has never
   fired is not known to work.
````

- [ ] **Step 5: Rewrite the architecture, data-model, design-system and design-token rules**

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml` with:

```yaml
# MemoX V8 guard rules — domain: architecture
#
# Encodes the layer boundaries of ADR-010 and ADR-011. The single most
# valuable rule here is domain_no_infrastructure_import: V8.0 is local-only
# (ADR-001), and a backend added later stays cheap only if domain/ never learned
# about Drift. That property is invisible until the backend lands, which is
# exactly when breaking it is most expensive — so it has to be machine-checked
# from day one.
version: 1
metadata:
  id: memox-v8-architecture
  name: MemoX V8 Architecture Rules
  description: Layer boundaries, dependency direction, and data-layer ownership.
  owner: memox-v8
rules:
  - id: memox.architecture.domain_no_infrastructure_import
    type: forbidden_import
    severity: error
    enabled: true
    message: >-
      `domain/` may import only Dart and other domain code — no Flutter, Drift,
      Dio or json_annotation. If a domain file needs one of these, the
      abstraction is in the wrong place (ADR-010).
    scopes:
      - domain_files
    patterns:
      - package:flutter/.*
      - package:drift/.*
      - package:dio/.*
      - package:json_annotation/.*
      - package:sqlite3/.*
      - package:path_provider/.*
    tags:
      - memox
      - architecture
    fix:
      hint: Move the type to data/ and map it to a domain entity at the repository boundary.

  - id: memox.architecture.presentation_no_data_import
    type: regex
    severity: error
    enabled: true
    message: >-
      `presentation/` must talk to use cases or repository contracts, never to a
      data source, DAO or repository implementation directly.
    scopes:
      - presentation_files
    patterns:
      - "^\\s*import\\s+'[^']*\\bdata/[^']*';"
      - "^\\s*import\\s+'package:memox/features/[^/]+/data/[^']*';"
    tags:
      - memox
      - architecture

  - id: memox.architecture.no_drift_type_in_domain
    type: regex
    severity: error
    enabled: true
    message: >-
      Drift-generated types must never appear in `domain/`. Using a Drift row
      class as an entity is what quietly ties the domain to the local database,
      which a later backend would have to untangle (ADR-010).
    scopes:
      - domain_files
    patterns:
      - \bDriftWrappedException\b
      - \bGeneratedDatabase\b
      - \bDataClass\b
      - \bCompanion\b
      - \bTableInfo\b
    tags:
      - memox
      - architecture

  - id: memox.architecture.no_transaction_outside_data_layer
    type: regex
    severity: error
    enabled: true
    message: >-
      Database transactions belong to the data or database layer. A transaction
      opened from a widget or use case cannot be reasoned about or tested.
    scopes:
      - non_data_layer_source
    patterns:
      - \btransaction\s*\(
    tags:
      - memox
      - architecture

  - id: memox.architecture.widget_no_database_access
    type: regex
    severity: error
    enabled: true
    message: >-
      Widgets must not read the database: no `databaseProvider`, no query, no
      DAO call. A widget reaches data through a use case (ADR-011 D4).
    scopes:
      - widget_ui_files
    # A query on the database or a DAO, or the database provider itself, read
    # outside a comment.
    patterns:
      - '\b(?:_?database|_?db)\s*\.\s*(?:select|into|update|delete|customSelect|customStatement|customSelectStream)\s*\('
      - '\b_?[A-Za-z0-9]*Dao\s*\.\s*[a-z][A-Za-z0-9_]*\s*\('
      - '^(?!\s*(?://|\*)).*\bdatabaseProvider\b'
    tags:
      - memox
      - architecture

  - id: memox.architecture.widget_no_repository_access
    type: regex
    severity: error
    enabled: true
    message: >-
      Widgets must not read or watch repository providers directly. Go through a
      controller so the screen has one place that owns its state.
    scopes:
      - widget_ui_files
    patterns:
      - 'ref\s*\.\s*(?:read|watch)\s*\(\s*\w*[Rr]epositoryProvider'
    tags:
      - memox
      - architecture

  # Exactly one place opens the database connection. More than one means two
  # configurations, and the second one is always the one missing a PRAGMA
  # (`schema.md`: `PRAGMA foreign_keys = ON` in `beforeOpen`).
  - id: memox.architecture.single_database_connection_site
    type: regex
    severity: error
    enabled: true
    message: >-
      Only `lib/core/database/connection.dart` may open a database connection.
      A second call site means a second configuration, and it is always
      the one missing `PRAGMA foreign_keys`.
    scopes:
      - dart_lib
    exclude:
      # The one site, written as a glob.
      - '**/core/database/connection.dart'
    patterns:
      - \bNativeDatabase\s*[.(]
      - \bdriftDatabase\s*\(
    tags:
      - memox
      - architecture

  # Dependencies deliberately absent: V8.0 is local-only (ADR-001) and holds no
  # credential until a backend exists (ADR-002). Catch the import before the
  # package sneaks into pubspec.
  - id: memox.architecture.no_deferred_dependency_import
    type: forbidden_import
    severity: error
    enabled: true
    message: >-
      `dio`, `connectivity_plus` and `flutter_secure_storage` are deliberately
      absent: V8.0 is local-only (ADR-001) and stores no credential until a
      backend exists (ADR-002). Adding one is a documented decision, not an
      import.
    scopes:
      - dart_source
    patterns:
      - package:dio/.*
      - package:connectivity_plus/.*
      - package:flutter_secure_storage/.*
    tags:
      - memox
      - architecture
      - dependencies


  # ADR-011 D8: a feature's presentation/widgets is grouped into exactly four
  # fixed buckets, one level deep — widgets/<bucket>/<file>.dart and nothing
  # else. This is the guard's half of the enforcement; the boundary test
  # (test/architecture/boundaries_test.dart, with its rules in
  # boundary_rules.dart) owns the same shape with richer per-shape messages.
  # Change the bucket list in ADR-011 first, then in that test, then here.
  #
  # `file_path`, not `file_name`: the rule is about where a file sits, and the
  # healthy state must keep a non-empty target set or the runner's own
  # rule_without_targets diagnostic fires; a file_name pattern over a carved
  # include/exclude matches nothing when the tree is healthy.
  # The pattern deliberately ends in `[^/]+\.dart` rather than requiring the
  # `_widget` suffix: memox.naming.presentation_file_role_suffix already owns
  # suffixes, and one finding per defect beats two rules reporting one mistake.
  - id: memox.architecture.widgets_grouped_into_buckets
    type: file_path
    severity: error
    enabled: true
    message: >-
      A feature's widgets sit in exactly one of four buckets, one level deep —
      sections/ (bands the screen composes), items/ (the repeated row and its
      parts), overlays/ (sheets, dialogs, forms and their open functions),
      support/ (presentation mapping used across buckets). Nothing sits
      directly under widgets/, buckets never nest, and a fifth bucket is an
      ADR-011 change, not a new folder.
    include:
      - lib/features/*/presentation/widgets/**/*.dart
    exclude:
      - '**/*.g.dart'
      - '**/*.freezed.dart'
    pattern: '^lib/features/[^/]+/presentation/widgets/(?:sections|items|overlays|support)/[^/]+\.dart$'
    tags:
      - memox
      - architecture

  - id: memox.architecture.single_study_mode_dispatch
    type: regex
    severity: error
    enabled: true
    message: >-
      StudyMode is dispatched in exactly one exhaustive switch, beside the enum
      in study_mode.dart. A second branch on StudyMode in domain/ or data/ is
      where a mode's policy leaks out of its handler and back into the shared
      flow —
      the thing the handler exists to prevent. A handler already knows which
      mode it is and never needs to ask.
    scopes:
      - study_mode_non_dispatch
    patterns:
      - 'case\s+StudyMode\.'
      - 'StudyMode\.[a-z]\w*\s*=>'
    tags:
      - memox
      - architecture
    fix:
      hint: >-
        Move the branch into the handler for that mode, or into a hook on
        StudyModeHandler that every mode answers.
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml`:

Replace

```yaml
  name: MemoX V8 Data Model Rules
  description: Deck-tree, scheduler and review-history invariants (BR-xx, AD-06, AD-11).
  owner: memox-v8
```

with

```yaml
  name: MemoX V8 Data Model Rules
  description: Deck-tree, scheduler and review-history invariants of V8.
  owner: memox-v8
```

Replace

```yaml

  # AD-06: scheduling must be a pure function of its inputs, or the whole matrix
  # of box x action becomes untestable.
  - id: memox.data_model.scheduler_no_ambient_now
```

with

```yaml

  # Scheduling is a pure function of its inputs, or the whole matrix of box x
  # action becomes untestable.
  - id: memox.data_model.scheduler_no_ambient_now
```

Replace

```yaml
    message: >-
      AD-06 — domain code must not read the ambient clock. `now` is passed in,
      so behaviour is testable at a fixed instant; for the scheduler this is what
```

with

```yaml
    message: >-
      Domain code must not read the ambient clock. `now` is passed in,
      so behaviour is testable at a fixed instant; for the scheduler this is what
```

Replace

```yaml

  # M4.3: "due" must mean the same thing in every query, and a hardcoded
  # CURRENT_TIMESTAMP makes a query untestable at a fixed point in time.
```

with

```yaml

  # "Due" must mean the same thing in every query, and a hardcoded
  # CURRENT_TIMESTAMP makes a query untestable at a fixed point in time.
```

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml` with:

```yaml
# MemoX V8 guard rules — domain: design_system
#
# The design system's component boundary: a feature composes shared primitives
# (`Mx*`), it does not rebuild them from raw Material widgets. The shared
# widgets say so in their own documentation, but prose on a shared widget is
# read by the person editing the shared widget, not by the person writing a
# new dialog in a feature; these rules are what enforce it.
#
# Scope note: `presentation_files` (features/*/presentation only), NOT
# `ui_surfaces` — `lib/shared/` is where the primitives legitimately build the
# raw widgets these rules ban. Linting it would flag the definition as the
# crime, the same argument `memox-design-token-rules.yaml` makes for
# `lib/core/theme/`.
version: 1
metadata:
  id: memox-v8-design-system
  name: MemoX V8 Design System Rules
  description: >-
    Features compose shared Mx primitives; raw Material control widgets stay in
    lib/shared where the primitives are defined.
  owner: memox-v8
rules:
  - id: memox_v8.design_system.no_raw_button
    type: regex
    severity: error
    enabled: true
    message: >-
      No raw Material buttons in feature code. Use `MxButton` (tones: primary /
      secondary / outline / destructive / dangerSoft; sizes: regular / small /
      compact / chip / study) or the other shared button primitives
      (`MxIconButton`, `MxFab`), so every action in the app resolves through one
      style pipeline. A shape the shared widget cannot express is a gap in the
      widget — extend it in lib/shared, do not route around it here.
    scopes:
      - presentation_files
    # `\b` keeps a longer name that ends in one of these (an `Mx…` wrapper, say)
    # legal without a lookbehind: the letters either side are word characters,
    # so there is no boundary inside the name.
    patterns:
      - '\bElevatedButton(?:\.[A-Za-z_][A-Za-z0-9_]*)?\s*\('
      - '\bFilledButton(?:\.[A-Za-z_][A-Za-z0-9_]*)?\s*\('
      - '\bOutlinedButton(?:\.[A-Za-z_][A-Za-z0-9_]*)?\s*\('
      - '\bTextButton(?:\.[A-Za-z_][A-Za-z0-9_]*)?\s*\('
    tags:
      - memox-v8
      - design-system

  # Every pattern below is line-anchored with the comment exemption the
  # duration rule uses: prose that *names* a banned widget must not trip the
  # rule that bans it.
  - id: memox_v8.design_system.no_raw_widget
    type: regex
    severity: error
    enabled: true
    message: >-
      No raw Material component widgets in feature code. Use the Mx shared
      primitive (`MxCard`, `MxListRow`, `MxIconButton`, `MxFab`, `MxOptionRow`,
      `MxToggle`, dialogs through `showMxDialog`, …) so the component's visual
      grammar has one owner. A widget with no Mx wrapper yet goes through the
      admission rule in the flutter-theme-design skill first — wrapper, tests,
      then guard — never raw-first.
    scopes:
      - presentation_files
    patterns:
      - '^(?!\s*(?://|\*)).*\b(?:Card|ListTile|IconButton|FloatingActionButton|InkResponse|ExpansionTile|Badge)\s*\('
      - '^(?!\s*(?://|\*)).*\b(?:Checkbox|Radio|TextFormField|Slider|RangeSlider|SegmentedButton|ToggleButtons)\s*[<(]'
      - '^(?!\s*(?://|\*)).*\b(?:NavigationBar|NavigationDrawer|NavigationRail|BottomNavigationBar|BottomAppBar|TabBar)\s*\('
      - '^(?!\s*(?://|\*)).*\b(?:Dialog|AlertDialog|SimpleDialog|MaterialBanner|SearchBar|SearchAnchor|DropdownMenu)\s*[<(]'
      - '^(?!\s*(?://|\*)).*\bshowDialog\s*[<(]'
      - '^(?!\s*(?://|\*)).*\b(?:SnackBar|SnackBarAction|InkWell)\s*\('
      - '^(?!\s*(?://|\*)).*\.showSnackBar\s*\('
      - '^(?!\s*(?://|\*)).*\b(?:Switch|SwitchListTile|CheckboxListTile|RadioListTile|RadioGroup)\s*[<(]'
      - '^(?!\s*(?://|\*)).*\b(?:PopupMenuButton|PopupMenuItem|DropdownButton|DropdownButtonHideUnderline)\s*[<(]'
    tags:
      - memox-v8
      - design-system

  # Two ratchets: neither name appears in `lib/features/*/presentation/`, so
  # neither can go red on existing code. They exist so the next screen cannot
  # quietly build its own chrome or its own pick-one control.
  #
  # `Scaffold` is deliberately NOT here. It is the framework's layout host, not
  # a design-system component: no architecture decision forbids a feature from
  # owning one, and `MxAppShell` builds its own for a reason its file states —
  # that is not a prohibition on features.
  - id: memox_v8.design_system.no_raw_screen_chrome
    type: regex
    severity: error
    enabled: true
    message: >-
      No raw screen chrome in feature code. `MxAppShell` lays out the chrome and
      `MxAppBar` owns the bar and its back control, so every screen's chrome
      resolves through one owner. A bar they cannot express is a gap in them —
      extend them in lib/shared, do not build an `AppBar` / `SliverAppBar` here.
    scopes:
      - presentation_files
    # Line-anchored with the comment exemption every rule in this file uses.
    # `\b` keeps `MxAppBar`-style names legal and `\s*\(` keeps `AppBarTheme(`
    # (a theme, not chrome) legal.
    patterns:
      - '^(?!\s*(?://|\*)).*\b(?:AppBar|SliverAppBar)\s*\('
    tags:
      - memox-v8
      - design-system

  # A sheet opens through `showMxBottomSheet`, the one route that carries the
  # theme's surface, radius and scrim.
  - id: memox_v8.design_system.no_raw_sheet_route
    type: regex
    severity: error
    enabled: true
    message: >-
      No raw bottom-sheet route in feature code. `showMxBottomSheet` owns the
      route, the scrim and the motion, and `MxBottomSheet` keeps its header and
      footer in view while only the body scrolls; each caller deciding those is
      how one sheet ends up under the navigation bar and another under the
      status bar. Open the sheet through
      lib/shared/widgets/mx_bottom_sheet.dart.
    scopes:
      - presentation_files
    patterns:
      - '^(?!\s*(?://|\*)).*\bshow(?:Modal)?BottomSheet\s*[<(]'
    tags:
      - memox-v8
      - design-system

  # A ring or bar that shows `value:` is progress, not loading, and the shared
  # widgets own both kinds: a feature needs no raw indicator at all.
  - id: memox_v8.design_system.no_raw_loading_indicator
    type: regex
    severity: error
    enabled: true
    message: >-
      No raw progress indicator in feature code. A wait shows `MxSpinner` or
      the `MxSkeleton` family, which carry the accessible name a bare spinner
      lacks; progress shown with `value:` is `MxLinearProgress` or
      `MxMasteryDonut`.
    scopes:
      - presentation_files
    patterns:
      - '^(?!\s*(?://|\*)).*\b(?:CircularProgressIndicator|LinearProgressIndicator)(?:\.adaptive)?\s*\('
    tags:
      - memox-v8
      - design-system

  # `MxFilterChip` owns the pick-one chip; this rule bans the raw `ChoiceChip`.
  - id: memox_v8.design_system.no_raw_choice_chip
    type: regex
    severity: error
    enabled: true
    message: >-
      No raw `ChoiceChip` in feature code. `MxFilterChip` owns the pick-one
      chip — its selection is state a screen reader announces, not only a look —
      so every such chip in the app is one component.
    scopes:
      - presentation_files
    patterns:
      - '^(?!\s*(?://|\*)).*\bChoiceChip(?:\.[A-Za-z_][A-Za-z0-9_]*)?\s*\('
    tags:
      - memox-v8
      - design-system

  - id: memox_v8.design_system.no_raw_style_escape
    type: regex
    severity: error
    enabled: true
    message: >-
      No hand-built styles in feature code. `ButtonStyle`, `styleFrom`,
      `BorderSide`, `BoxShadow`, `ShapeDecoration`, `RoundedRectangleBorder`,
      `WidgetStateProperty` and literal icon sizes are the design system's
      vocabulary — a feature that needs one is describing a variant the shared
      widget should own. Extend the Mx widget or the theme in lib/shared /
      lib/core/theme, then select it semantically here.
    scopes:
      - presentation_files
    patterns:
      - '^(?!\s*(?://|\*)).*\b(?:ButtonStyle|BorderSide|BoxShadow|ShapeDecoration|RoundedRectangleBorder)\s*\('
      - '^(?!\s*(?://|\*)).*\.styleFrom\s*\('
      - '^(?!\s*(?://|\*)).*\b(?:WidgetStateProperty|MaterialStateProperty)\b'
      - '^(?!\s*(?://|\*)).*\bIcon\s*\([^)]*\bsize\s*:\s*\d'
    tags:
      - memox-v8
      - design-system

  # The app's face, Plus Jakarta Sans, is a variable font with a `wght` axis,
  # and renderers read the axis over `TextStyle.fontWeight` once it is present
  # — so a bare `copyWith(fontWeight:)` reports the new weight to every test and
  # paints the rung's old one on the device. `AppTypography.withWeight` moves
  # the axis with the weight and is the only legal spelling.
  #
  # The pattern requires the `FontWeight.` literal on purpose:
  # `withWeight`'s own implementation writes `fontWeight: weight`, so the one
  # file allowed to touch the field never matches.
  - id: memox_v8.design_system.no_flat_style_from
    type: regex
    severity: error
    enabled: true
    message: >-
      No `styleFrom(` in widgets — feature or shared. `styleFrom` builds flat
      WidgetStatePropertyAll values that shadow the theme's resolvers for
      every state at once, so a pressed or disabled state stops showing. State
      pairs come from `appButtonStyle` (`app_button_style.dart`) or a
      ButtonStyle with explicit resolveWith; V8 calls `styleFrom` nowhere, the
      theme included.
    scopes:
      - widget_ui_files
    patterns:
      - '^(?!\s*(?://|\*)).*\.styleFrom\s*\('
    tags:
      - memox-v8
      - design-system

  - id: memox_v8.design_system.no_bare_font_weight
    type: regex
    severity: error
    enabled: true
    message: >-
      Never set `fontWeight:` directly — on a variable font it reports one
      weight and paints another. Re-weight through
      `AppTypography.withWeight(style, FontWeight.wXXX)`, which moves the
      `wght` axis with it.
    scopes:
      - typography_and_theme_surfaces
    patterns:
      - '^(?!\s*(?://|\*)).*\bfontWeight\s*:\s*FontWeight\.'
    tags:
      - memox-v8
      - design-system
      - typography

  # A widget picks a named style; it does not restyle one. Five spellings of
  # the same escape, and the scope is the whole UI surface: features *and*
  # `lib/shared/`. File mode, because
  # `withWeight(...)` is written over three lines by `dart format` and a
  # line-scoped pattern could not see the `.copyWith(` on the fourth; the
  # balanced-paren walk stops at a bare paren, so an unbalanced one inside a
  # comment shortens the check rather than leaking it.
  #
  # What it cannot see is a restyle through a local alias
  # (`final text = texts.bodyMedium!; text.copyWith(color:)`): that takes a
  # two-pass scan a regex cannot be.
  - id: memox_v8.design_system.no_text_restyle
    type: regex
    mode: file
    severity: error
    enabled: true
    message: >-
      No per-site text styling in UI code. Use a named style on
      `context.textStyles` (`MxTextStyles`), or re-weight a rung with
      `AppTypography.withWeight`. A combination neither can express is a
      missing style — add it to `MxTextStyles` in lib/core/theme, do not
      assemble it here.
    scopes:
      - ui_surfaces
    patterns:
      - '^(?!\s*(?://|\*)).*\btexts\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
      - '^(?!\s*(?://|\*)).*\btextStyles\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
      # `MxTextStyles.inputHint` is a resolved style, consumed whole; a
      # `.copyWith(` on it is the same restyle, however the styles are reached.
      - '^(?!\s*(?://|\*)).*\binputHint[!?]?\s*\.copyWith\s*\('
      - '^(?!\s*(?://|\*)).*\btextTheme\.[a-zA-Z]+[!?]?\s*\.copyWith\s*\('
      - '\bwithWeight\s*\((?:[^()]|\([^()]*\))*\)\s*\.copyWith\s*\('
    tags:
      - memox-v8
      - design-system
      - typography

  # A colour on a raw `Icon` is an open colour on a glyph; `MxIconTile` and
  # `MxIconButton` own the coloured glyph. A colour computed by a
  # `….resolve(…)` call stays legal: it comes out of a theme-owned set
  # (`MxDerivedColors.resolve`).
  - id: memox_v8.design_system.no_raw_icon_color
    type: regex
    severity: error
    enabled: true
    message: >-
      No open `Icon(color:)` in feature code. A coloured glyph is an
      `MxIconTile` (tones: tinted / primary / warning / success / caution /
      danger) or an `MxIconButton`; an `Icon` that must stay raw takes its
      colour from a theme-owned set through `….resolve(…)`.
    scopes:
      - presentation_files
    patterns:
      - '^(?!\s*(?://|\*)).*\bIcon\s*\([^)]*\bcolor\s*:\s*(?![A-Za-z_][\w.]*\.resolve\()'
    tags:
      - memox-v8
      - design-system

  # `ColorScheme` is the 45 Material 3 colour roles — 26 standard, 19 add-on —
  # and the guard locks the names to that list by allowlist, in both
  # directions. The SDK's constructor accepts a few more names
  # (three deprecated roles and a tint mechanism it resolves for itself), and
  # any name that is not on the list is a finding, so none of them has to be
  # spelled here to stay out. `brightness` is the one non-role argument the
  # constructor takes.
  #
  # Argument side, file mode: the callee is the unnamed constructor, one of
  # the four brightness-named constructors, or `copyWith` on one of the three
  # identifiers the codebase gives a scheme (`scheme`, `colors`,
  # `colorScheme`); `fromSeed` is not a role list and is left to the scheme
  # header's own argument. The balanced-paren walk stops at a bare `(` or
  # `)`, so an unbalanced paren in a comment inside the call shortens what is
  # checked rather than leaking the check into the code after it. The first
  # pattern reads an argument at the start of its own line, which is where
  # `dart format` puts every argument of a call this long — and where a
  # comment never starts with an identifier and a colon; the second covers a
  # call written on one line.
  - id: memox_v8.design_system.color_scheme_arguments_are_m3_roles
    type: regex
    mode: file
    severity: error
    enabled: true
    message: >-
      A `ColorScheme` is built from the 45 Material 3 colour roles only (26
      standard + 19 add-on), plus `brightness`. Any other argument name is
      either a deprecated role or a mechanism the SDK already resolves — do
      not pass it; this rule's allowlist is the set.
    scopes:
      - dart_lib
    patterns:
      - '(?:\bColorScheme(?:\.(?:light|dark|highContrastLight|highContrastDark))?|\b(?:scheme|colors|colorScheme)\??\.copyWith)\s*\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*?^\s+(?!(?:brightness|surfaceContainerHighest|onSecondaryFixedVariant|surfaceContainerLowest|onTertiaryFixedVariant|onPrimaryFixedVariant|onSecondaryContainer|surfaceContainerHigh|onTertiaryContainer|surfaceContainerLow|onPrimaryContainer|secondaryContainer|tertiaryContainer|secondaryFixedDim|primaryContainer|onErrorContainer|onSurfaceVariant|onInverseSurface|surfaceContainer|onSecondaryFixed|tertiaryFixedDim|primaryFixedDim|onTertiaryFixed|errorContainer|outlineVariant|inverseSurface|inversePrimary|onPrimaryFixed|secondaryFixed|surfaceBright|tertiaryFixed|primaryFixed|onSecondary|onTertiary|surfaceDim|onPrimary|secondary|onSurface|tertiary|primary|onError|surface|outline|shadow|error|scrim)\s*:)[A-Za-z_]\w*\s*:'
      - '(?:\bColorScheme(?:\.(?:light|dark|highContrastLight|highContrastDark))?|\b(?:scheme|colors|colorScheme)\??\.copyWith)\s*\([^()\n]*?\b(?!(?:brightness|surfaceContainerHighest|onSecondaryFixedVariant|surfaceContainerLowest|onTertiaryFixedVariant|onPrimaryFixedVariant|onSecondaryContainer|surfaceContainerHigh|onTertiaryContainer|surfaceContainerLow|onPrimaryContainer|secondaryContainer|tertiaryContainer|secondaryFixedDim|primaryContainer|onErrorContainer|onSurfaceVariant|onInverseSurface|surfaceContainer|onSecondaryFixed|tertiaryFixedDim|primaryFixedDim|onTertiaryFixed|errorContainer|outlineVariant|inverseSurface|inversePrimary|onPrimaryFixed|secondaryFixed|surfaceBright|tertiaryFixed|primaryFixed|onSecondary|onTertiary|surfaceDim|onPrimary|secondary|onSurface|tertiary|primary|onError|surface|outline|shadow|error|scrim)\s*:)[A-Za-z_]\w*\s*:'
    tags:
      - memox-v8
      - design-system

  # Read side, line mode: on the three identifiers the codebase gives a
  # scheme, a member must be one of the 45 roles, `brightness`, or
  # `copyWith`. Comment lines are exempt because prose names files such as
  # `colors.css`. `?.` is accepted so a nullable scheme is not a way around
  # the rule. `context.colors.<role>` and `theme.colorScheme.<role>` are the
  # shapes this catches; a scheme held under another name is a naming
  # finding first.
  - id: memox_v8.design_system.color_scheme_reads_are_m3_roles
    type: regex
    severity: error
    enabled: true
    message: >-
      Read a `ColorScheme` through one of its 45 Material 3 role names (or
      `brightness` / `copyWith`). Anything else is a deprecated role, a
      mechanism the SDK resolves for itself, or a typo — name the role you
      mean, e.g. `onSurface`, `surfaceContainerHighest`.
    scopes:
      - dart_lib
    patterns:
      - '^(?!\s*//).*?\b(?:scheme|colors|colorScheme)\??\.(?!(?:brightness|copyWith|surfaceContainerHighest|onSecondaryFixedVariant|surfaceContainerLowest|onTertiaryFixedVariant|onPrimaryFixedVariant|onSecondaryContainer|surfaceContainerHigh|onTertiaryContainer|surfaceContainerLow|onPrimaryContainer|secondaryContainer|tertiaryContainer|secondaryFixedDim|primaryContainer|onErrorContainer|onSurfaceVariant|onInverseSurface|surfaceContainer|onSecondaryFixed|tertiaryFixedDim|primaryFixedDim|onTertiaryFixed|errorContainer|outlineVariant|inverseSurface|inversePrimary|onPrimaryFixed|secondaryFixed|surfaceBright|tertiaryFixed|primaryFixed|onSecondary|onTertiary|surfaceDim|onPrimary|secondary|onSurface|tertiary|primary|onError|surface|outline|shadow|error|scrim)\b)[A-Za-z_]\w*'
    tags:
      - memox-v8
      - design-system

  # A row's leading and trailing marks — a status dot, a checkbox, an icon
  # tile, a row number, a status mark, ⋮ — centre on the row, as
  # `MxListRow`, `MxOptionRow` and `MxSettingsRow` already do (owner
  # 2026-09-26, extending spec 2026-09-26 D4). Hand-rolled rows had pinned
  # them to the top with `CrossAxisAlignment.start`, and one checkbox was
  # patched back to the centre with `IntrinsicHeight` + `Align` while its
  # neighbours stayed pinned. The pattern stops at `children:`, so a nested
  # Column's alignment never matches.
  #
  # Excluded by file, each with its reason — a row whose children are not
  # leading/trailing marks:
  - id: memox_v8.design_system.row_marks_centre_on_the_row
    type: regex
    severity: error
    enabled: true
    mode: file
    message: >-
      A row centres its leading and trailing marks (dot, checkbox, icon,
      number, status mark, ⋮) on the row: drop `crossAxisAlignment:
      CrossAxisAlignment.start` (owner 2026-09-26). A row that is not a
      leading/trailing layout goes on this rule's `exclude:` with its reason.
    scopes:
      - dart_lib
    exclude:
      # Prose callouts: the glyph sits on the first line of a paragraph,
      # and a banner's actions sit under its text (kit Note, InlineBanner).
      - lib/shared/widgets/mx_note.dart
      - lib/shared/widgets/mx_inline_banner.dart
      - lib/shared/widgets/mx_field_message.dart
      # A two-column grid of facts: each cell starts at the top of its line.
      - lib/features/card/presentation/widgets/sections/card_schedule_widget.dart
      # Three stat tiles side by side: their tops align, not their centres.
      - lib/features/study/presentation/widgets/sections/session_summary_hero_widget.dart
      # Three theme cards side by side (screen 25): their tops align.
      - lib/features/settings/presentation/screens/theme_screen.dart
    patterns:
      - '\bRow\((?:(?!\bchildren:)[\s\S]){0,240}?\bcrossAxisAlignment:\s*CrossAxisAlignment\.start\b'
    tags:
      - memox-v8
      - design-system
```

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml` with:

```yaml
# MemoX V8 guard rules — domain: design_token
#
# The UI kit and its design handoff (`docs/shared/ui/design-handoff/`): no
# hardcoded colours, text styles or padding — everything comes from design
# tokens.
#
# Scope note: these run on `ui_surfaces` (features/*/presentation + shared), NOT
# on lib/app/** or lib/core/theme/**. lib/core/theme is where raw values are
# legitimately DEFINED — linting it would be flagging the definition as the
# crime — and lib/app is the composition root and the debug-only gallery, not
# product UI.
version: 1
metadata:
  id: memox-v8-design-token
  name: MemoX V8 Design Token Rules
  description: Colour, typography and spacing must come from tokens, not literals.
  owner: memox-v8
rules:
  - id: memox.design_token.no_raw_color
    type: regex
    severity: error
    enabled: true
    message: >-
      No hardcoded colours in product UI. Use the semantic tokens from
      `lib/core/theme/` (`context.colors` / `context.semanticColors`) so light,
      dark and contrast stay correct in one place.
    scopes:
      - ui_surfaces
    patterns:
      - '\bColor\s*\(\s*0x[0-9a-fA-F]{6,8}\s*\)'
      - '\bColors\s*\.\s*[a-z][A-Za-z0-9]*'
      - '\bColor\s*\.\s*fromARGB\s*\('
      - '\bColor\s*\.\s*fromRGBO\s*\('
    tags:
      - memox
      - design-token
      - ui
    fix:
      hint: Use a semantic token; add one to MxSemanticColors if none fits.

  - id: memox.design_token.no_raw_text_style
    type: regex
    severity: error
    enabled: true
    message: >-
      No hardcoded `TextStyle` in product UI. Use the typography tokens
      (`context.texts`) so text scales consistently.
    scopes:
      - typography_ui_surfaces
    patterns:
      - '\bTextStyle\s*\('
    tags:
      - memox
      - design-token
      - ui

  - id: memox.design_token.no_raw_spacing_literal
    type: regex
    severity: error
    enabled: true
    message: >-
      No hardcoded padding or spacing. Use `AppSpacing` tokens — the 4/8/12/16/
      24/32 scale — so spacing stays on the scale instead of drifting per screen.
    scopes:
      - ui_surfaces
    patterns:
      - '\bEdgeInsets\s*\.\s*(?:all|symmetric|only|fromLTRB)\s*\([^)]*\b\d'
      - '\bEdgeInsetsDirectional\s*\.\s*(?:all|symmetric|only|fromSTEB)\s*\([^)]*\b\d'
      - '\bSizedBox\s*\(\s*(?:width|height)\s*:\s*\d'
      - '\bGap\s*\(\s*\d'
      - '\b(?:spacing|runSpacing)\s*:\s*\d'
    tags:
      - memox
      - design-token
      - ui
    fix:
      hint: Use AppSpacing.* instead of a bare number.

  - id: memox.design_token.no_raw_duration
    type: regex
    severity: warning
    enabled: true
    message: >-
      No anonymous `Duration` literal in product UI. Use an `AppDurations` token
      or, when the value is not motion, declare a named `const Duration` beside
      the thing that reads it and say what it is for.
    # **`ui_and_theme_surfaces`, not `ui_surfaces`, and that is the whole point
    # of the rule.** A component theme in `lib/core/theme` is where an inline
    # `Duration(milliseconds: …)` hides, and `ui_surfaces` deliberately excludes
    # that directory: scoped there, the rule would pass the very regression its
    # message describes.
    #
    # **This replaces `flutter.no_hardcoded_duration`, disabled in
    # overrides.yaml.** That rule fired on `AppDurations`' own declarations and
    # on domain date arithmetic like `Duration(days: 1)`. Neither needs a scope
    # exemption — both are *named* constants, and the lookahead below exempts
    # those by shape. So the theme comes back into scope and domain code stays
    # out of it, which is the split the original rule could not express.
    scopes:
      - ui_and_theme_surfaces
    # Two exemptions, both in the lookahead so they are structural rather than a
    # list of blessed files:
    #
    #   `//` and `*` — a comment line. A doc comment that says what a duration
    #     must not be quotes the literal to say it, and a rule that fails on the
    #     prose describing it is a rule people switch off.
    #   `const Duration` — a *named* declaration. `AppDurations`' tokens,
    #     `searchDebounce` and `startupSettingsLimit` are all written this way,
    #     which is the shape the message asks for.
    patterns:
      - >-
        ^(?!\s*(?://|\*|(?:static\s+)?const\s+Duration\s)).*\bDuration\s*\(\s*(?:days|hours|minutes|seconds|milliseconds|microseconds)\s*:\s*\d
    tags:
      - memox
      - design-token
      - ui
    fix:
      hint: >-
        Use an AppDurations token, or name it as a const with a comment
        explaining why it is not on the motion scale.

  - id: memox.design_token.no_raw_border_radius
    type: regex
    # `error`, like the spacing rule beside it: a warning nobody reads is a
    # rule nobody has.
    severity: error
    enabled: true
    message: No hardcoded corner radius in product UI. Use `AppRadius` tokens.
    scopes:
      - ui_surfaces
    patterns:
      - '\bBorderRadius\s*\.\s*circular\s*\(\s*\d'
      - '\bRadius\s*\.\s*circular\s*\(\s*\d'
    tags:
      - memox
      - design-token
      - ui

  # A stroke width is a design decision with named tokens (`AppStroke.hairline`,
  # `control`, `focus`, `indicator`, `selectedRing`); a literal beside
  # `strokeWidth:` or `width:` on a border is a width nobody named.
  # `Border.all(color:)` with no width is legal — Flutter's default IS the
  # hairline, and `test/core/theme/foundations_test.dart` pins
  # `AppStroke.hairline` at 1.
  - id: memox.design_token.no_raw_stroke_width
    type: regex
    severity: error
    enabled: true
    message: >-
      No literal stroke width. `AppStroke` names the scale — hairline, control,
      focus, indicator — so a border or an arc is one of four weights, not a
      number typed at the site. A width none of them fits is a fifth rung to
      argue for in lib/core/theme/foundations/app_stroke.dart.
    scopes:
      - ui_and_theme_surfaces
    patterns:
      - '^(?!\s*(?://|\*)).*\bstrokeWidth\s*:\s*\d'
      - '^(?!\s*(?://|\*)).*\b(?:BorderSide|Border\.all|Border\.symmetric)\s*\([^)]*\bwidth\s*:\s*\d'
    tags:
      - memox-v8
      - design-token
```

- [ ] **Step 6: Rewrite the error-handling, naming, privacy, state-management and testing rules**

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-error-handling-rules.yaml`:

Replace

```yaml
#
# CLAUDE.md "Errors" and "Control flow". A swallowed exception is the defect
# class that costs the most to diagnose later, because the evidence is destroyed
# at the moment the failure happens.
version: 1
```

with

```yaml
#
# The `flutter-architecture` skill, "Control flow". A swallowed exception is
# the defect class that costs the most to diagnose later, because the evidence
# is destroyed at the moment the failure happens.
version: 1
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-naming-rules.yaml`:

Replace

```yaml
#
# CLAUDE.md "Naming": files are snake_case with a suffix that states the role.
# The suffix is not decoration — check_architecture.sh and several scopes in
```

with

```yaml
#
# The `flutter-architecture` skill, "Naming": files are snake_case with a
# suffix that states the role.
# The suffix is not decoration — check_architecture.sh and several scopes in
```

Replace

```yaml

      `_provider` was added at M4.10 with `presentation/providers/`: a provider
      that only wires a use case into the graph is not a controller and must not
      borrow the controller exemptions. Anything holding submit state or a
```

with

```yaml

      `_provider` names a file of `presentation/providers/`: a provider that
      only wires a use case into the graph is not a controller and must not
      borrow the controller exemptions. Anything holding submit state or a
```

Replace the whole of `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-privacy-rules.yaml` with:

```yaml
# MemoX V8 guard rules — domain: privacy
#
# BR-CORE-001: private data here is broader than it looks — deck and card
# content, notes, learning history, imports, images, audio and backups.
# BR-CORE-002: none of it is logged, at any level. This is the rule most likely
# to be broken by a debugging session that then gets committed.
version: 1
metadata:
  id: memox-v8-privacy
  name: MemoX V8 Privacy Rules
  description: Card content and other private data must never reach logs or exports.
  owner: memox-v8
rules:
  - id: memox.privacy.no_card_content_in_logs
    type: regex
    severity: error
    enabled: true
    message: >-
      Never log card content at any level (BR-CORE-002). This includes the
      temporary log line added while debugging — that is exactly the one that
      gets committed.
    scopes:
      - dart_lib
    patterns:
      - '\b(?:log|logger|_log|_logger)\s*\.\s*[a-z]+\s*\([^)]*\b(?:card|front|back|answer|question|note)(?:Text|Content|Body)?\b'
      - '\b(?:print|debugPrint)\s*\([^)]*\bcard\s*\.\s*(?:front|back|answer|question|note)'
    tags:
      - memox
      - privacy
      - security

  - id: memox.privacy.no_secret_literal
    type: regex
    severity: error
    enabled: true
    message: No secrets in the repository. Move it to an untracked env file.
    scopes:
      - source_and_config_files
    patterns:
      - '(?i)\b(?:api[_-]?key|secret[_-]?key|access[_-]?token|client[_-]?secret)\s*[:=]\s*[''"][A-Za-z0-9_\-]{16,}[''"]'
    tags:
      - memox
      - privacy
      - security

  # BR-CORE-003: media lives in the app's private directory. A path under
  # external storage puts card content where any other app can read it.
  - id: memox.privacy.no_external_storage_path
    type: regex
    severity: error
    enabled: true
    message: >-
      Media lives in the app's private directory (BR-CORE-003). External
      storage makes private data readable by any other app (BR-CORE-001).
    scopes:
      - dart_lib
    patterns:
      - \bgetExternalStorageDirectory\s*\(
      - "'/sdcard/"
      - "'/storage/emulated/"
    tags:
      - memox
      - privacy
      - security
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-state-management-rules.yaml`:

Replace

```yaml
#
# This file is the replacement for riverpod_lint, which is descoped (see
# "Deferred and descoped" in docs/wbs.md). `flutter analyze` covers NONE of
# these, so without this file they are unguarded.
#
```

with

```yaml
#
# V8 runs no riverpod_lint: neither it nor custom_lint is in pubspec.yaml.
# `flutter analyze` covers NONE of these, so without this file they are
# unguarded.
#
```

Replace

```yaml
  # Controllers holding a BuildContext outlive the widget that provided it.
  # CLAUDE.md states this as a non-negotiable.
  # ---------------------------------------------------------------------------
```

with

```yaml
  # Controllers holding a BuildContext outlive the widget that provided it.
  # The `flutter-state-riverpod` skill: never store a `BuildContext`.
  # ---------------------------------------------------------------------------
```

Replace

```yaml
  # ---------------------------------------------------------------------------
  # One isLoading for every operation on a screen is the bug CLAUDE.md calls out
  # by name under "State".
  # ---------------------------------------------------------------------------
```

with

```yaml
  # ---------------------------------------------------------------------------
  # One isLoading for every operation on a screen is the bug the
  # `flutter-state-riverpod` skill calls out by name.
  # ---------------------------------------------------------------------------
```

In `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml`:

Replace

```yaml

  # CLAUDE.md: UI must be checked in light + dark + small screen + large text.
  # A widget test that never varies textScaler cannot catch the overflow that
```

with

```yaml

  # The `flutter-testing` skill: a widget test covers dark mode and text scale
  # as well as the states.
  # A widget test that never varies textScaler cannot catch the overflow that
```

- [ ] **Step 7: Run the guard tests**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `216 passed`: Task 2's count, since the markers test arrived as the exclusion
test left.

- [ ] **Step 8: Compare the resolved rules with the base**

```bash
python3 .superpowers/sdd/2026-09-27-guard-without-v7/compare_rules.py b0e5549
```

Expected: the six lines of Task 2, and four more:
`changed memox.state_management.controller_no_build_context: include`,
`changed memox.state_management.notifier_no_public_mutable_field: include`,
`changed memox.state_management.state_write_after_await_requires_mounted: include`
(`provider_files` without its two V7 globs) and
`changed memox_v8.design_system.no_raw_loading_indicator: exclude`; then `10 changed`.
These are the spec's §5.1 and §5.2, and nothing else.

- [ ] **Step 9: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/config/profiles.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/config/scopes.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/README.md \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-data-model-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-error-handling-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-naming-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-privacy-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-state-management-rules.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml \
  code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py \
  code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py
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
tests `Ran 65 tests` and `OK`; `216 passed` (the guard's self-tests);
`Code verification passed.`; `+2244: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
refactor(guard): memox-v8 cites V8's decisions and names V8's code (BE-D6)

memox-v8's messages, comments and reasons cited V7: its architecture
decisions (AD-n), its business rules (BR-n), its design-system audit, its
milestones and its docs/wbs.md, and named classes, files and folders V8
does not have. Each now cites the V8 authority that holds the rule (the
ADRs, the BR/UC files, the design handoff) or states its reason in place,
and names V8's code (spec 5.3, 6).

The scan of every rule, scope and override (spec 5.4) also found three
globs that matched no file: the loading rule's exclusion of a V7 widget
and provider_files' two V7 folders. They go. A contract test pins that no
file of memox-v8 carries a V7 marker, and the design-system probes use V8's
widgets.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: The design-token hook runs the guard's memox-v8 rules

**Files:**
- Modify: `.claude/hooks/check_design_tokens.py`, `.claude/skills/flutter-workflow/scripts/dod_check.sh`
- Test (create): `.claude/hooks/tests/test_check_design_tokens.py`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`

**Interfaces:**
- Consumes: `memox-v8`'s six enabled `memox.design_token.*` rules as Tasks 1–3 leave them.
- Produces (`.claude/hooks/check_design_tokens.py`):
  - `REPO_ROOT: Path`, `GUARD_ROOT: Path`, `RULESET = "memox-v8"`,
    `RULE_PREFIX = "memox.design_token."`.
  - `Finding(rule_id: str, line: int, code_line: str, message: str)`, a frozen dataclass.
  - `repository_path(payload: dict) -> str | None`;
    `design_token_rules() -> list[dict]`;
    `findings_for(relative_path: str, text: str) -> list[Finding]`;
    `report(relative_path: str, findings: list[Finding]) -> int`; `main() -> int`.
  - The gate step `hook_tests`, labelled "hook tests".

Spec §7, §8.2, D7, D8, and §10's time budget; Clarifications 8–10; Review Focus 1 and 5.

- [ ] **Step 1: Write the hook tests, and the test that the gate runs them**

The hook tests load the hook the way the CI tooling tests load their scripts
(Clarification 10). No test writes into `lib/`: the agreement cases run on a temporary
directory.

Create `.claude/hooks/tests/test_check_design_tokens.py`:

```python
"""Tests for the design-token hook: it runs memox-v8's design-token rules, as
the guard resolves them, on the file just edited.

The hook exits 0 on any error by design (it must never block an edit), so a
hook that has stopped loading its rules looks exactly like a clean file. These
tests are what notice.
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import yaml

HOOK = Path(__file__).resolve().parents[1] / "check_design_tokens.py"
REPO_ROOT = HOOK.parents[2]
RULES = (
    REPO_ROOT / "code-verification-guard-v2" / "registries" / "projects" / "memox-v8"
    / "rules" / "memox-design-token-rules.yaml"
)
SCREEN = "lib/features/deck/presentation/screens/sample_screen.dart"


def _load_hook():
    spec = importlib.util.spec_from_file_location("check_design_tokens", HOOK)
    module = importlib.util.module_from_spec(spec)
    sys.modules["check_design_tokens"] = module
    spec.loader.exec_module(module)
    return module


hook = _load_hook()


class LoadsMemoxV8Test(unittest.TestCase):
    def test_it_loads_the_enabled_design_token_rules_of_memox_v8(self) -> None:
        registry = yaml.safe_load(RULES.read_text(encoding="utf-8"))
        expected = {rule["id"] for rule in registry["rules"] if rule.get("enabled")}
        self.assertEqual(expected, {rule["id"] for rule in hook.design_token_rules()})

    def test_the_rules_arrive_with_the_scopes_the_guard_resolves(self) -> None:
        for rule in hook.design_token_rules():
            with self.subTest(rule=rule["id"]):
                self.assertTrue(rule.get("include"))


class AgreesWithTheGuardTest(unittest.TestCase):
    """The hook reports what the guard reports for the same file, including the
    rules whose scopes reach past product UI: text styles in `lib/app/`,
    durations and stroke widths in `lib/core/theme/`."""

    CASES = (
        (SCREEN, "final c = Colors.red;\n", {"memox.design_token.no_raw_color"}),
        ("lib/shared/widgets/sample_widget.dart", "padding: const EdgeInsets.all(8),\n",
         {"memox.design_token.no_raw_spacing_literal"}),
        ("lib/app/sample_screen.dart", "final s = TextStyle(fontSize: 12);\n",
         {"memox.design_token.no_raw_text_style"}),
        ("lib/core/theme/sample_theme.dart", "final d = Duration(milliseconds: 300);\n",
         {"memox.design_token.no_raw_duration"}),
        ("lib/core/theme/sample_theme.dart", "side: BorderSide(color: ink, width: 2),\n",
         {"memox.design_token.no_raw_stroke_width"}),
        ("lib/features/deck/domain/models/sample_model.dart", "final c = Colors.red;\n", set()),
        ("lib/shared/widgets/sample_widget.g.dart", "final c = Colors.red;\n", set()),
    )

    def test_each_file_gets_the_guards_findings(self) -> None:
        for relative_path, text, expected in self.CASES:
            with self.subTest(path=relative_path, text=text):
                found = {finding.rule_id for finding in hook.findings_for(relative_path, text)}
                self.assertEqual(expected, found)


class ReportsTest(unittest.TestCase):
    def test_a_finding_exits_2_and_names_its_rule_and_line(self) -> None:
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            code = hook.report(SCREEN, hook.findings_for(SCREEN, "\nfinal c = Colors.red;\n"))
        self.assertEqual(2, code)
        self.assertIn(f"[memox.design_token.no_raw_color] {SCREEN}:2", stderr.getvalue())

    def test_no_finding_exits_0_and_prints_nothing(self) -> None:
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            code = hook.report(SCREEN, [])
        self.assertEqual((0, ""), (code, stderr.getvalue()))

    def test_main_reads_the_payload_and_reports_the_edited_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            edited = root / SCREEN
            edited.parent.mkdir(parents=True)
            edited.write_text("final c = Colors.red;\n", encoding="utf-8")
            payload = io.StringIO(json.dumps({"tool_input": {"file_path": str(edited)}}))
            with mock.patch.object(hook, "REPO_ROOT", root), mock.patch.object(sys, "stdin", payload), \
                    contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(2, hook.main())


class NeverBlocksTest(unittest.TestCase):
    """Input the hook cannot use, or a guard it cannot load, exits 0."""

    @staticmethod
    def _run(stdin: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, str(HOOK)], input=stdin, capture_output=True, text=True, timeout=120,
        )

    def test_a_broken_payload_exits_0(self) -> None:
        self.assertEqual(0, self._run("not json").returncode)

    def test_a_file_outside_the_repository_exits_0(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            outside = Path(tmp) / "sample_screen.dart"
            outside.write_text("final c = Colors.red;\n", encoding="utf-8")
            payload = json.dumps({"tool_input": {"file_path": str(outside)}})
            self.assertEqual(0, self._run(payload).returncode)

    def test_a_guard_that_cannot_load_exits_0(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            edited = root / SCREEN
            edited.parent.mkdir(parents=True)
            edited.write_text("final c = Colors.red;\n", encoding="utf-8")
            payload = io.StringIO(json.dumps({"tool_input": {"file_path": str(edited)}}))
            broken = ImportError("No module named 'yaml'")
            with mock.patch.object(hook, "REPO_ROOT", root), mock.patch.object(sys, "stdin", payload), \
                    mock.patch.object(hook, "design_token_rules", side_effect=broken):
                self.assertEqual(0, hook.main())


if __name__ == "__main__":
    unittest.main()
```

In `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`:

Replace

```python

class GateReadsThePlanTest(unittest.TestCase):
```

with

```python

class GateRunsTheHookTestsTest(unittest.TestCase):
    """The design-token hook exits 0 on any error, so a hook that has stopped
    working looks like a clean file; its tests are what notice, and the gate
    runs them in every mode."""

    def test_the_gate_runs_the_hook_tests(self) -> None:
        script = (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")
        self.assertIn('HOOK_TESTS="$REPO_ROOT/.claude/hooks/tests"', script)
        self.assertIn("-m unittest discover -s '$HOOK_TESTS' -p 'test_*.py'", script)


class GateReadsThePlanTest(unittest.TestCase):
```

- [ ] **Step 2: Run the hook tests to see them fail**

```bash
python3 -m unittest discover -s .claude/hooks/tests -p 'test_*.py'
```

Expected: `Ran 9 tests` and `FAILED (errors=13)`: the old hook has no `design_token_rules`
(2), `findings_for` (7, one per case of the agreement test), `report` (2), or `REPO_ROOT`
to patch (2). The two subprocess tests pass: the old hook already exits 0 on a broken
payload and on a file outside the repository.

- [ ] **Step 3: Run the CI tooling tests to see the new one fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```

Expected: `Ran 66 tests` and `FAILED (failures=1)`: `test_the_gate_runs_the_hook_tests`
with `AssertionError: 'HOOK_TESTS="$REPO_ROOT/.claude/hooks/tests"' not found in` the
gate.

- [ ] **Step 4: Rewrite the hook on the guard's loader and rule code**

Replace the whole of `.claude/hooks/check_design_tokens.py` with:

```python
"""PostToolUse hook: the guard's design-token rules, on the file just edited.

The guard (`guard/run.py check --ruleset memox-v8`) runs every rule over the
whole tree and is the real gate — but it runs at the gate, after the code is
written. This hook closes that latency gap: after every Edit or Write of a Dart
file it loads memox-v8 through the guard's own loader, keeps the design-token
rules, and runs them on a copy of that one file, reporting violations back into
the same working turn.

The rules, their scopes and the overrides come from the guard's loader, and the
check is the guard's own rule code, so the hook reports exactly what the guard
would for that file.

Exit codes: 0 = clean or out of scope; 2 = violations (stderr is fed back to
the model). Any environment problem (a missing package, an unreadable registry)
exits 0 — the hook is an accelerant, not the gate. The tests in
`.claude/hooks/tests/`, which the gate runs, are what notice a hook that has
stopped working.
"""

from __future__ import annotations

import json
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GUARD_ROOT = REPO_ROOT / "code-verification-guard-v2"
RULESET = "memox-v8"
RULE_PREFIX = "memox.design_token."


@dataclass(frozen=True)
class Finding:
    rule_id: str
    line: int
    code_line: str
    message: str


def _put_guard_on_path() -> None:
    if str(GUARD_ROOT) not in sys.path:
        sys.path.insert(0, str(GUARD_ROOT))


def repository_path(payload: dict) -> str | None:
    """The edited file's path relative to the repository; None when the payload
    names no file, a file that is gone, or one outside the repository."""
    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}
    raw = tool_input.get("file_path") or tool_response.get("filePath")
    if not raw:
        return None
    path = Path(raw).resolve()
    if not path.is_file():
        return None
    try:
        return path.relative_to(REPO_ROOT.resolve()).as_posix()
    except ValueError:
        return None


def design_token_rules() -> list[dict]:
    """memox-v8's enabled design-token rules, as the guard's loader resolves them."""
    _put_guard_on_path()
    from code_verification_guard.config.config_manager import ConfigManager

    _, rules = ConfigManager().load_ruleset_runtime(REPO_ROOT, RULESET)
    return [
        rule
        for rule in rules
        if rule["id"].startswith(RULE_PREFIX) and rule.get("enabled", True)
    ]


def findings_for(relative_path: str, text: str) -> list[Finding]:
    """What the design-token rules report for [text] at [relative_path]."""
    rules = design_token_rules()
    from code_verification_guard.factory.rule_factory import RuleFactory

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        copy = root / relative_path
        copy.parent.mkdir(parents=True, exist_ok=True)
        copy.write_text(text, encoding="utf-8")
        findings = [
            Finding(
                violation.rule_id,
                violation.line_number or 0,
                violation.code_line or "",
                " ".join(violation.message.split()),
            )
            for rule in rules
            for violation in RuleFactory().create(rule).check(root)
        ]
    return sorted(findings, key=lambda finding: (finding.line, finding.rule_id))


def report(relative_path: str, findings: list[Finding]) -> int:
    if not findings:
        return 0
    blocks = [
        f"[{finding.rule_id}] {relative_path}:{finding.line}\n"
        f"  {finding.code_line}\n"
        f"  {finding.message}"
        for finding in findings
    ]
    print(
        "Design-token check failed for the file just edited "
        "(the guard's memox-v8 rules):\n\n" + "\n\n".join(blocks),
        file=sys.stderr,
    )
    return 2


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    if not isinstance(payload, dict):
        return 0
    relative_path = repository_path(payload)
    if relative_path is None or not relative_path.endswith(".dart"):
        return 0

    try:
        text = (REPO_ROOT / relative_path).read_text(encoding="utf-8")
        findings = findings_for(relative_path, text)
    except Exception:  # noqa: BLE001 — the hook must never block on env issues
        return 0
    return report(relative_path, findings)


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 5: Run the hook tests in the gate**

In `.claude/skills/flutter-workflow/scripts/dod_check.sh`:

Replace

```bash

# The guard's own probes, and they belong wherever the guard runs. A rule that
```

with

```bash

# The design-token hook exits 0 on any error by design, so a hook that has
# stopped loading its rules looks like a clean file; its tests are what notice.
HOOK_TESTS="$REPO_ROOT/.claude/hooks/tests"
if [[ -n "$PY" && -d "$HOOK_TESTS" ]]; then
  plan hook_tests "hook tests" \
    "$PY -m unittest discover -s '$HOOK_TESTS' -p 'test_*.py'"
else
  FAILED+=("hook tests unavailable: $HOOK_TESTS")
fi

# The guard's own probes, and they belong wherever the guard runs. A rule that
```

- [ ] **Step 6: Run the hook tests**

```bash
python3 -m unittest discover -s .claude/hooks/tests -p 'test_*.py'
```

Expected: `Ran 9 tests` and `OK`.

- [ ] **Step 7: Run the CI tooling tests**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```

Expected: `Ran 66 tests` and `OK`.

- [ ] **Step 8: Time the hook on an edited file**

```bash
payload=$(printf '{"tool_input":{"file_path":"%s/lib/shared/widgets/mx_button.dart"}}' "$PWD")
start=$(date +%s%N)
printf '%s' "$payload" | python .claude/hooks/check_design_tokens.py
code=$?
echo "exit $code in $(( ($(date +%s%N) - start) / 1000000 )) ms"
```

Expected: `exit 0 in <n> ms`, with `<n>` under 500 (spec §10): 197 in the scratch run and
260 in the dry run, in the cloud container. `mx_button.dart` is in the design-token scopes
and clean, so the hook ran all six rules on it.

- [ ] **Step 9: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/hooks/check_design_tokens.py \
  .claude/hooks/tests/test_check_design_tokens.py \
  .claude/skills/flutter-workflow/scripts/dod_check.sh \
  .claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py
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
tests `Ran 66 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `216 passed` (the
guard's self-tests); `Code verification passed.`; `+2244: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
fix(hooks): the design-token hook runs the guard's memox-v8 rules (BE-D6)

check_design_tokens.py read memox-v7's design-token file and applied its
own copy of V7's ui_surfaces scope, so it missed what memox-v8 checks
outside product UI: text styles in lib/app/, durations and stroke widths in
lib/core/theme/. It now loads memox-v8 through the guard's loader
(ConfigManager.load_ruleset_runtime), keeps the enabled
memox.design_token.* rules with their resolved scopes, and runs the
guard's own rule code (RuleFactory) on a copy of the edited file at the
same relative path. Findings print the rule id, the path and line, the
line and the message, and exit 2; anything else exits 0, as before.

The hook exits 0 on any error by design, so a hook that stopped loading its
rules would look like a clean file. Its tests, in .claude/hooks/tests/,
pin the rules it loads, its agreement with the guard on each scope, its
report and its exit codes, and the gate runs them in a new "hook tests"
step.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: memox-v7 goes; the pointers name memox-v8

**Files:**
- Modify: `.claude/skills/flutter-architecture/references/analysis_options.yaml`, `.claude/skills/flutter-state-riverpod/SKILL.md`, `.claude/skills/flutter-theme-design/references/legacy-and-guards.md`, `code-verification-guard-v2/AGENTS.md`, `docs/wbs_BE.md`
- Delete: `code-verification-guard-v2/registries/projects/memox-v7/` (15 files)
- Test (modify): `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py`

**Interfaces:**
- Consumes: Task 1's `RULESET_ROOT`; nothing reads `memox-v7` after Tasks 1 and 4.
- Produces: `test_the_memox_rulesets_are_v6_and_v8_only`; the documents of spec §9.

Spec §4.1, §9, D3, D10, and §10's search; Clarifications 7 and 11.

- [ ] **Step 1: Write the test that memox-v7 is gone**

In `code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py`:

Replace

```python
"""Contract tests for the memox-v8 ruleset: it describes V8 and nothing else."""

```

with

```python
"""Contract tests for the memox-v8 ruleset: it describes V8 and nothing else,
and it is the only MemoX ruleset beside V6's `memox`."""

```

Replace

```python
    assert {name: hits for name, hits in found.items() if hits} == {}
```

with

```python
    assert {name: hits for name, hits in found.items() if hits} == {}


def test_the_memox_rulesets_are_v6_and_v8_only() -> None:
    projects = RULESET_ROOT.parent
    names = {path.name for path in projects.iterdir() if path.is_dir()}
    assert {name for name in names if name.startswith("memox")} == {"memox", "memox-v8"}
```

- [ ] **Step 2: Run the guard tests to see it fail**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `1 failed, 216 passed`: `test_the_memox_rulesets_are_v6_and_v8_only` with
`Extra items in the left set:` `'memox-v7'`.

- [ ] **Step 3: Delete memox-v7**

Nothing reads the registry any more: its probes moved to `memox-v8` in Task 1, and the
hook loads `memox-v8` since Task 4.

Run:

```bash
git rm -r -q code-verification-guard-v2/registries/projects/memox-v7
```

- [ ] **Step 4: Run the guard tests**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `217 passed`.

- [ ] **Step 5: Point the guard's AGENTS.md and the skills at memox-v8, and record BE-D6**

In `.claude/skills/flutter-architecture/references/analysis_options.yaml`:

Replace

```yaml
#      code-verification-guard:
#      `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7`
#
```

with

```yaml
#      code-verification-guard:
#      `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
#
```

In `.claude/skills/flutter-state-riverpod/SKILL.md`:

Replace

```markdown
- [ ] `select` used where only part of a state object is needed.
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` clean —
      `flutter analyze` does not cover these rules.
```

with

```markdown
- [ ] `select` used where only part of a state object is needed.
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean —
      `flutter analyze` does not cover these rules.
```

In `.claude/skills/flutter-theme-design/references/legacy-and-guards.md`:

Replace

```markdown
**Chỗ đặt rule trong repo này:**
`code-verification-guard-v2/registries/projects/memox-v7/rules/memox-design-system-rules.yaml`,
scope `presentation_files` (không phải `ui_surfaces` — `lib/shared/` là nơi
```

with

```markdown
**Chỗ đặt rule trong repo này:**
`code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`,
scope `presentation_files` (không phải `ui_surfaces` — `lib/shared/` là nơi
```

In `code-verification-guard-v2/AGENTS.md`:

Replace

```markdown

- There is one source of truth for the guard: the copy committed here, in `ntgptit/memox-v7`. Changes to the engine, the common rules, or the MemoX rulesets are made **in place**, reviewed, and committed together with the MemoX change that motivated them — the same as any other file in MemoX.
- Do **not** `git clone` a separate `code-verification-guard` remote over this directory. A re-clone silently discards fixes made here — for example the `common.no_commented_out_code` false-positive fix and the `DateTime.now()`-in-comment fix, both of which live only in this vendored copy and are pinned by `tests/test_memox_false_positive_regressions.py`. The historical "refresh from upstream" procedure was exactly the two-source-of-truth trap that this ownership note removes.
```

with

```markdown

- There is one source of truth for the guard: the copy committed here, in `ntgptit/memox-v8`. Changes to the engine, the common rules, or the MemoX rulesets are made **in place**, reviewed, and committed together with the MemoX change that motivated them — the same as any other file in MemoX.
- Do **not** `git clone` a separate `code-verification-guard` remote over this directory. A re-clone silently discards fixes made here — for example the `common.no_commented_out_code` false-positive fix and the `DateTime.now()`-in-comment fix, both of which live only in this vendored copy and are pinned by `tests/test_memox_false_positive_regressions.py`. The historical "refresh from upstream" procedure was exactly the two-source-of-truth trap that this ownership note removes.
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-D5 | Công cụ kiểm chứng không còn gì của V7 (mở rộng theo chủ dự án): `build_verification_plan.py` chỉ phục vụ `dod_check.sh --changed`, plan còn 11 field, bỏ shard, `--github-output`, Widgetbook, memox-api và prompt set; `dod_check.sh` không còn bước Widgetbook và bước prompt contract, nên `--changed` hết fail trên mọi thay đổi code; lời giúp và header tả V8; gỡ `check_prompt_contract.py`, `read_local_prompt_set.ps1` và test PowerShell của nó | xong | BE-D2 | M | [spec](superpowers/specs/2026-09-26-verification-tooling-design.md) và [plan](superpowers/plans/2026-09-27-verification-tooling.md) gói 12a; `GateReadsThePlanTest` và test của planner trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | BE-D6, BE-D7 |

```

with

```markdown
| BE-D5 | Công cụ kiểm chứng không còn gì của V7 (mở rộng theo chủ dự án): `build_verification_plan.py` chỉ phục vụ `dod_check.sh --changed`, plan còn 11 field, bỏ shard, `--github-output`, Widgetbook, memox-api và prompt set; `dod_check.sh` không còn bước Widgetbook và bước prompt contract, nên `--changed` hết fail trên mọi thay đổi code; lời giúp và header tả V8; gỡ `check_prompt_contract.py`, `read_local_prompt_set.ps1` và test PowerShell của nó | xong | BE-D2 | M | [spec](superpowers/specs/2026-09-26-verification-tooling-design.md) và [plan](superpowers/plans/2026-09-27-verification-tooling.md) gói 12a; `GateReadsThePlanTest` và test của planner trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | BE-D6, BE-D7 |
| BE-D6 | Guard và hook design token không còn gì của V7 (mở rộng theo chủ dự án): gỡ registry `memox-v7` của `code-verification-guard-v2` cùng test của nó; `memox-v8` mang nhãn "MemoX V8" và 13 id `memox_v8.design_system.*`; sáu rule mang tên của V7 tìm tên của V8, hai id đổi theo; message, comment và lý do dẫn quyết định của V8; hook `.claude/hooks/check_design_tokens.py` nạp `memox-v8` bằng bộ nạp của guard và chạy chính rule của guard trên file vừa sửa, có test riêng và bước "hook tests" trong gate; tài liệu của guard ghi `ntgptit/memox-v8`. Giữ registry `memox` (V6) | xong | — | M | [spec](superpowers/specs/2026-09-27-guard-without-v7-design.md) và [plan](superpowers/plans/2026-09-27-guard-without-v7.md) gói 12b; `test_memox_v8_ruleset_contract.py`, `test_memox_v8_data_model_guard_rules.py` và `test_memox_v8_architecture_guard_rules.py` trong `code-verification-guard-v2/tests/`; `.claude/hooks/tests/test_check_design_tokens.py` | BE-D7 |

```

Replace

```markdown
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D6 | Guard và hook design token không còn V7: gỡ registry `memox-v7` của `code-verification-guard-v2` cùng test của nó; hook `.claude/hooks/check_design_tokens.py` đọc rule của `memox-v8`; tài liệu của guard ghi `memox-v8` là nơi của nó. Giữ registry `memox` (V6) | chưa bắt đầu | — | M | Chủ dự án tách phần V7 còn lại thành hai gói ngày 2026-09-26 ([spec gói 12a](superpowers/specs/2026-09-26-verification-tooling-design.md) §2, §9) | Gói 12b: brainstorm, spec, plan |
| BE-D7 | Skill và tài liệu không còn V7: Widgetbook trong Definition of Done và trong skill `flutter-feature-slice`, `flutter-design-system`; các con trỏ tới `docs/wbs.md` và checklist của V7; `--ruleset memox-v7`; baseline và blueprint của V7; bản ghi cài đặt của skill `project-documentation`; lịch sử của V7 trong comment của các script khác của `flutter-workflow` và `flutter-architecture` (`check_format.sh`, `check_generated.sh`, `check_architecture.py`). Gồm BE-D3 | chưa bắt đầu | BE-D6 | M | [Spec gói 12a](superpowers/specs/2026-09-26-verification-tooling-design.md) §2, §9 | Gói 12c: brainstorm, spec, plan |

```

with

```markdown
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D7 | Skill và tài liệu không còn V7: Widgetbook trong Definition of Done và trong skill `flutter-feature-slice`, `flutter-design-system`; các con trỏ tới `docs/wbs.md` và checklist của V7; baseline và blueprint của V7; bản ghi cài đặt của skill `project-documentation`; lịch sử của V7 trong comment của các script khác của `flutter-workflow` và `flutter-architecture` (`check_format.sh`, `check_generated.sh`, `check_architecture.py`). Gồm BE-D3 | chưa bắt đầu | BE-D6 | M | [Spec gói 12a](superpowers/specs/2026-09-26-verification-tooling-design.md) §2, §9 | Gói 12c: brainstorm, spec, plan |

```

Replace

```markdown
  final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
```

with

```markdown
  final review toàn nhánh trước khi mở PR.
- **BE-D6** (gói 12b, [spec](superpowers/specs/2026-09-27-guard-without-v7-design.md),
  [plan](superpowers/plans/2026-09-27-guard-without-v7.md)): gate xanh sau mỗi task;
  cấu hình rule của `memox-v8` do bộ nạp của guard resolve, trước và sau gói, chỉ khác
  ở những chỗ spec liệt kê; final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 12a (BE-D5).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 12b (BE-D6).

```

Replace

```markdown

1. BE-D6 (gói 12b), rồi BE-D7 (gói 12c), theo thứ tự chủ dự án chọn ngày 2026-09-26.
2. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).
```

with

```markdown

1. BE-D7 (gói 12c), gồm BE-D3, theo thứ tự chủ dự án chọn ngày 2026-09-26.
2. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).
```

Replace

```markdown
  và tài liệu, gói 12c); BE-D3 làm trong BE-D7.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  và tài liệu, gói 12c); BE-D3 làm trong BE-D7.
- **Cập nhật ngày 2026-09-27:** BE-D6 xong trong gói 12b, mở rộng theo chủ dự án: guard
  và hook design token không còn gì của V7. Hai lệnh `--ruleset memox-v7` trong skill
  chuyển sang `memox-v8` trong gói này, nên BE-D7 không còn việc đó.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `generate.py` prints `OK docs/_generated: generated 3 files` and changes nothing
under `docs/_generated/`; `check.py` ends with `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 6: Search the guard and the hooks for V7's names**

```bash
git grep -n -I -E 'memox-v7|memox_v7|MemoX V7' -- code-verification-guard-v2 .claude/hooks
echo "git grep exit $?"
```

Expected: only `git grep exit 1`: `git grep` found nothing.

- [ ] **Step 7: Stage the task's files**

The renames and deletions are staged already, by `git mv` and `git rm`. The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-architecture/references/analysis_options.yaml \
  .claude/skills/flutter-state-riverpod/SKILL.md \
  .claude/skills/flutter-theme-design/references/legacy-and-guards.md \
  code-verification-guard-v2/AGENTS.md \
  code-verification-guard-v2/tests/test_memox_v8_ruleset_contract.py \
  docs/wbs_BE.md
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
tests `Ran 66 tests` and `OK`; the hook tests `Ran 9 tests` and `OK`; `217 passed` (the
guard's self-tests); `Code verification passed.`; `+2244: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
chore(guard): memox-v7 goes, and its pointers name memox-v8 (BE-D6)

Nothing reads memox-v7 any more: its probes moved to memox-v8 and the
design-token hook loads memox-v8. The registry goes, and a contract test
pins that the MemoX rulesets are memox (V6, kept by the owner's choice)
and memox-v8.

The guard's AGENTS.md names ntgptit/memox-v8 as the source of truth; the
two --ruleset memox-v7 commands in the skills and the path in
legacy-and-guards.md name memox-v8. wbs_BE.md records BE-D6 as done, and
BE-D7 no longer carries the --ruleset commands.
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-guard-without-v7` and open its pull request against `master`, then
subscribe to its activity.

Expected: CI is paused during active development (root `README.md`, "CI"), so no check
runs on the pull request; it merges on the local gate.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-guard-without-v7` if it moved, run the gate once more on
the branch head, and squash-merge only while it ends with `✓ mechanical gates passed`.
Then unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** D1, §11: no step touches the engine, the `memox` registry or its
  tests, `.claude/settings.json`, a dated spec or plan, app code, or a skill line beyond
  §9's. D2, §6: Tasks 1–3, pinned by the contract tests of Tasks 1 and 3. D3, §4.1:
  Task 5. D4, §4.2: Tasks 1 and 2. D5, §5.1: Task 2. D6, §5.2–§5.4: Task 3 and
  Clarification 4. D7, §7: Task 4. D8, §8.2: Task 4. D9, §8.1: Tasks 1, 2, 3 and 5. D10,
  §9: Tasks 1 (the skill's ids, ADR-011) and 5. D11, §10: every task's gate, the
  comparison of Tasks 1–3, the timing of Task 4 and the search of Task 5. D12: the branch
  and the pull request above.
- **Placeholders.** None: every step carries its code or its command and its expected
  output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run ran
  every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the task that owns the code.
