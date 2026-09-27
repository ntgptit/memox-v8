# MemoX V8 Verification Tooling Without V7 Implementation Plan (package 12a)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-D5 of [`docs/wbs_BE.md`](../../wbs_BE.md), widened by the owner: the
verification tooling keeps nothing of V7, so `dod_check.sh --changed` runs only V8's steps
(today it fails on most code changes, on a Widgetbook gate V8 does not have) and the
planner writes only what the gate reads and what explains the selection.

**Architecture:** `dod_check.sh` stays the one gate, and `--changed` still asks
`build_verification_plan.py` which checks and host tests a diff needs. Task 1 takes out
the two steps V8 has no gate for, the Widgetbook smoke test and V7's prompt delivery
contract, and pins by test that the gate reads only fields the plan writes. Task 2 trims
the planner to the eleven fields of spec D3 and to the rules V8's tree uses, and turns
its tests of V7's golden job into tests of the local plan. Task 3 records the package in
the documents. No Dart file, no schema, no dependency.

**Tech Stack:** Bash (`dod_check.sh`); Python 3 with the standard library only (the
planner and its tests, run by `python3 -m unittest`, because the gate runs them with no
Python dependency installed); Flutter 3.47.5 for the gate's own steps.

**Spec:**
[`docs/superpowers/specs/2026-09-26-verification-tooling-design.md`](../specs/2026-09-26-verification-tooling-design.md),
approved 2026-09-26. Package 6's spec
([`2026-09-25-ci-gate-design.md`](../specs/2026-09-25-ci-gate-design.md), D2, D11) is why
the planner has no CI caller.

**Prerequisite:** `claude/be-verification-tooling` holds the spec (`b630635`), its
approval (`738c1c8`) and this plan, on `master` at `0c75383` (#88). The plan runs on that
branch, from this plan's commit; the gate passes there with 2165 host tests and the CI
tooling tests `Ran 77 tests` · `OK (skipped=8)`. Generated code is not committed: in a
fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root `README.md`,
"Commands"). `origin/master` must name `master`'s head: the changed-scope runs compare
against it.

**How this plan was checked:** every code block below was written and run first, in a
scratch copy of the repository, task by task, test first. Each task's tests failed as its
"Expected" line says, then passed, and after every task the gate passed; the changed-scope
run of Task 1 failed on the Widgetbook step before the fix and passed after it. Each rule
the tests pin was also broken on purpose in the scratch copy, one at a time: the plan
writing `needs_widgetbook` again; the CLI printing the plan instead of writing its file;
`widgetbook/`, `memox-api/` and `docs/prompt/` getting their rules back; a picture
claiming a code change, dropping the selection made before it, or reading as `docs`; the
runnable tests keeping golden-only files; the memo handing out its own set, or answering
for every tree; the local targets swapping their two sets; a code change with no test no
longer promoting to the full suite; the gate reading `needs_widgetbook` again, printing
the shard count, or getting its Widgetbook or prompt step back; and a deleted script
coming back (18 breaks). Every break failed at least one test. This document was then
applied, step by step as written, onto a clean checkout of this plan's commit: each task's
files matched the scratch commit's, no other file moved, and the outputs and counts below
are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- **Scope (D1):** the planner, `dod_check.sh`, `verification_impact_map.json`, the CI
  tooling tests and V7's prompt delivery contract, and the two documents of spec §7. The
  guard, the hooks, the other skills' documents and scripts, `CLAUDE.md` and `AGENTS.md`
  do not change (spec §9): they are BE-D6 and BE-D7.
- **Nothing of V7 (D2):** no V7-only rule, flag, output, script or test stays in these
  files, and no comment, docstring or message tells a V7 measurement, incident, path or
  document. What stays describes V8.
- **The plan (D3):** its JSON holds exactly `changed_paths`, `affected_features`,
  `affected_layers`, `reasons`, `unmatched_paths`, `test_files`, `local_test_targets`,
  `risk`, `full_suite`, `needs_static` and `needs_host_tests`. The gate acts on
  `needs_static`, `needs_host_tests` and `local_test_targets`, and prints `risk`,
  `test_files` and `reasons`.
- **What the planner keeps (D5):** every classification rule V8's tree uses, the import
  closure and its per-process memo, the fail-safe widening, the picture rule and
  `compress_test_targets`; the risks `full`, `targeted`, `pixels`, `docs`; the options
  `--root`, `--impact-map`, `--json-output`, `--paths-file`, `--force-full`, `--nul`.
- **Removed rules (D6, D8):** a `widgetbook/` or `memox-api/` path is unrecognised and
  selects the full suite; a `docs/prompt/` path is documentation like any other.
- **The CI tooling tests** use the Python standard library only, and none of them skips.
- **After every task** the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It runs the host suite with
  `TZ=UTC` and `--exclude-tags golden`.
- **Language:** scripts' output and comments, code, identifiers, test names and commit
  messages are in English; `docs/` keeps its Vietnamese. Every commit message ends with
  the session's attribution trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan. Each is decided
here and implemented as described; say so if one is wrong.

1. **What else of V7 the package's files held** (D2). Beyond the lists of spec §4.1 and §5, the
   plan rewrites `dod_check.sh`'s message "That is expected before Phase 2.3" (V7's
   checklist), its closing line naming V7's `docs/wbs.md` (now `docs/wbs_BE.md` and
   `docs/wbs_FE.md`), the history in its comments on `python3` and on the formatter, and
   "seven concurrent processes" (V7's step count); the planner's "AD-14" (V7's
   architecture decision; now the speculative structure `CLAUDE.md` refuses); and in the
   tests the "Phase 2.3" comment, the fixture's history, the docstring naming "V7's
   wiring test", and V7's paths used as inputs (`docs/wbs.md`, `lib/presentation/shared/`,
   `test/demo/`, `design_audit/`).
2. **The pass stamp's figures are V8's** (Task 1). Spec §5 keeps the stamp's explanation,
   but its "~0.4s instead of 50-150s" were V7's; the header now says what the stamp costs
   here: 0.03s against 266s for a full run, measured in the cloud container on
   2026-09-26.
3. **The Windows command line stays as the reason for `compress_test_targets`** (Task 2).
   Spec §4.1 lists "GitHub shards and the Windows command line" among V7's comments. The
   shards go; the Windows limit is why the gate compresses its targets in V8 too, since
   the owner runs the gate on Windows (`CLAUDE.md`, "Hooks"), and the docstring says so in
   V8's terms.
4. **Dead state goes with the fields** (Task 2). `VerificationPlanBuilder.has_docs_changes`
   was set and never read; it goes with `docs_only`.
5. **The golden-job tests become local-plan tests** (Task 2; spec §6): a shared widget
   change runs the full suite; test support outside the known folders runs everything
   (V8's shape of V7's `test/demo/` case); pictures alone give `pixels` and nothing to run;
   a picture beside a widget keeps the widget's selection; documents alone give `docs`
   (in place of the Windows-runner case). The verification-script case names
   `dod_check.sh`, since the workflow case already covers `ci.yml`.
6. **The fixture's thresholds leave in the code step** (Task 2). The test fixture keeps
   `shard_weight_thresholds` until the step that removes the planner's reader of it, so
   the red run fails on the new tests and not in `setUpClass`.
7. **Two more end-to-end runs than the spec's** (§8). Task 2 runs `--changed --force` on
   the eleven-field plan, and Task 3 runs `--changed --base HEAD` on the documents alone,
   the run that skips the static checks and the host tests (Review Focus 1).
8. **What BE-D7 names** (Task 3). The V7 history in the comments of `check_format.sh`,
   `check_generated.sh` and `check_architecture.py`, outside this package's files, joins
   BE-D7's list.
9. **Dates.** The plan and the update entry of `wbs_BE.md` are dated 2026-09-27, the day
   the plan was written; the spec's day was 2026-09-26.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person, each
pinned by a test or a run in the task that owns the code:

1. **A change of documents alone under `--changed`**: the gate skips the static checks
   and the host tests, prints `docs · 0 test files`, runs the document, SDK and tooling
   checks, and passes — Task 3, "Run the changed-scope gate on the documents alone".
2. **A path of a removed rule** (`widgetbook/`, `memox-api/`): the full suite, never a
   green run that checked nothing — Task 2, "a path V8 has no rule for selects
   everything".
3. **A `docs/prompt/` path**: documentation, with no step to run — Task 2, "a prompt set
   is documentation like any other".
4. **A picture beside a code change**: the code's selection stands — Task 2, "a picture
   beside its widget keeps the widget selection".
5. **The gate reading a field the plan no longer writes**: a `KeyError` in the middle of a
   run — Task 1's contract tests pin the six fields statically, and Task 2's changed-scope
   run reads the real eleven-field plan.

## File Structure

```
.claude/skills/flutter-workflow/scripts/
├── dod_check.sh                      help, header, steps, summary (1)
├── check_prompt_contract.py          deleted (1)
├── read_local_prompt_set.ps1         deleted (1)
├── build_verification_plan.py        eleven fields, V8's rules (2)
├── verification_impact_map.json      no shard thresholds (2)
└── tests/
    ├── test_ci_tooling.py            PLAN_FIELDS, GateReadsThePlanTest (1, 2);
    │                                 the planner's tests (2)
    └── test_local_prompt_handoff.py  deleted (1)
.claude/skills/flutter-ship/references/ci.md   the planner's one caller (3)
docs/wbs_BE.md                        BE-D5 done; BE-D6, BE-D7 (3)
```

---


### Task 1: The gate runs only V8's steps

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/dod_check.sh`
- Delete: `.claude/skills/flutter-workflow/scripts/check_prompt_contract.py`, `.claude/skills/flutter-workflow/scripts/read_local_prompt_set.ps1`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`
- Test (delete): `.claude/skills/flutter-workflow/scripts/tests/test_local_prompt_handoff.py`

**Interfaces:**
- Consumes: `build_verification_plan.py` as it stands: its JSON is the gate's input.
- Produces:
  - `PLAN_FIELDS`, a `frozenset` of the eleven field names of spec D3, and
    `GateReadsThePlanTest` (`tests/test_ci_tooling.py`).
  - `dod_check.sh --changed` reads `needs_static`, `needs_host_tests` and
    `local_test_targets`, and prints `risk`, `test_files` and `reasons`; no
    `NEEDS_WIDGETBOOK`, no `HAS_PROMPT_CHANGES`.

Spec §5, §6 (contract tests 2 and 3), §8, D7, D8; Clarifications 1 and 2; Review
Focus 5. The end-to-end runs use `--force` so the pass stamp cannot answer for them; this
branch changes a verification script, so its plan is the full suite.

- [ ] **Step 1: Write the contract tests, and remove the test of the prompt contract**

The new class takes the place of `PromptContractTest` and its `HEADER`, which test
`check_prompt_contract.py`, deleted in Step 5. The stamp test's docstring loses V7's
figures (Clarification 2).

In `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`:

Replace

```python
    PR is one tree state asked three times. The stamp exists so the repetition
    costs ~0.4s instead of 50-150s — and so it works without anyone having to
    remember, which is the part that failed every time it was written down.
    """
```

with

```python
    PR is one tree state asked three times. The stamp exists so the repetition
    costs a fraction of a second instead of minutes, and so it works without
    anyone having to remember.
    """
```

Replace

```python

HEADER = """# {title}

| | |
|---|---|
| **Status** | active |
| **Purpose** | Test prompt |
| **Scope** | Test scope |
| **Source of truth for** | Test execution instructions |
| **Depends on** | `AGENTS.md` |
| **Updated by task** | TEST |
| **Last updated** | 2026-08-13 |

"""


class PromptContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = _load("check_prompt_contract")

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.feature = self.root / "docs" / "prompt" / "sample"
        self.feature.mkdir(parents=True)
        self._write_valid_set()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_valid_set(self) -> None:
        (self.feature / "implementation.md").write_text(
            HEADER.format(title="Implementation")
            + "5Why. Check the worktree. Run verification and gate. Clean stop.\n",
            encoding="utf-8",
        )
        (self.feature / "recursive-architecture-logic-review.md").write_text(
            HEADER.format(title="Architecture review")
            + "Audit-only first. Check the worktree, business rules, architecture boundary, database persistence and failure handling. Apply fixes, test, then clean stop.\n",
            encoding="utf-8",
        )
        (self.feature / "recursive-ui-ux-review.md").write_text(
            HEADER.format(title="UI review")
            + "Audit-only production states in the production tree. Check the worktree. Use getRect and golden comparison, list approved divergence, auto-fix, test, and clean stop.\n",
            encoding="utf-8",
        )

    def test_valid_prompt_set_passes(self) -> None:
        self.assertEqual([], self.module.validate_prompt_root(self.root))

    def test_missing_review_file_fails(self) -> None:
        (self.feature / "recursive-ui-ux-review.md").unlink()
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("missing prompt files" in message for message in messages))

    def test_run_file_is_rejected(self) -> None:
        (self.feature / "run.md").write_text("# Run\n", encoding="utf-8")
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("unexpected prompt files" in message for message in messages))

    def test_ui_review_without_geometry_fails(self) -> None:
        path = self.feature / "recursive-ui-ux-review.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace("getRect", "geometry"),
            encoding="utf-8",
        )
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("getRect" in message for message in messages))

    def test_out_of_order_header_fails(self) -> None:
        path = self.feature / "implementation.md"
        text = path.read_text(encoding="utf-8")
        text = text.replace(
            "| **Purpose** | Test prompt |\n| **Scope** | Test scope |",
            "| **Scope** | Test scope |\n| **Purpose** | Test prompt |",
        )
        path.write_text(text, encoding="utf-8")
        messages = [problem.message for problem in self.module.validate_prompt_root(self.root)]
        self.assertTrue(any("header fields" in message for message in messages))

```

with

```python

# The fields of the verification plan (spec of package 12a, D3): the six
# `dod_check.sh --changed` reads, and five that explain the selection.
PLAN_FIELDS = frozenset({
    "changed_paths",
    "affected_features",
    "affected_layers",
    "reasons",
    "unmatched_paths",
    "test_files",
    "local_test_targets",
    "risk",
    "full_suite",
    "needs_static",
    "needs_host_tests",
})


class GateReadsThePlanTest(unittest.TestCase):
    """`dod_check.sh --changed` runs what `build_verification_plan.py` selects.

    The gate is the planner's only caller, and it reads the plan's JSON by
    field name: a field it reads that the plan does not write stops the run,
    and a step it schedules for a gate V8 does not have fails every run that
    selects it.
    """

    @staticmethod
    def _gate() -> str:
        return (SCRIPTS / "dod_check.sh").read_text(encoding="utf-8")

    def test_the_gate_reads_only_fields_the_plan_writes(self) -> None:
        script = self._gate()
        read = set(re.findall(r"read_plan_bool (\w+)", script))
        read |= set(re.findall(r"p\['(\w+)'\]", script))
        # What the gate acts on: a pattern that matched nothing would fail
        # here instead of passing the check below.
        self.assertLessEqual({"needs_static", "needs_host_tests", "local_test_targets"}, read)
        self.assertEqual(set(), read - PLAN_FIELDS)

    def test_the_gate_has_no_step_for_a_gate_v8_does_not_have(self) -> None:
        """No Widgetbook smoke test (V8 has no `widgetbook/`) and no prompt
        delivery contract (V8 has no `docs/prompt/`)."""
        lines = self._gate().lower().splitlines()
        for marker in ("widgetbook", "prompt_contract", "has_prompt_changes"):
            with self.subTest(marker=marker):
                self.assertEqual([], [line for line in lines if marker in line])

    def test_the_prompt_delivery_scripts_are_gone(self) -> None:
        for removed in (
            "check_prompt_contract.py",
            "read_local_prompt_set.ps1",
            "tests/test_local_prompt_handoff.py",
        ):
            with self.subTest(path=removed):
                self.assertFalse((SCRIPTS / removed).exists())

```

- [ ] **Step 2: Run them to see them fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```

Expected: `Ran 75 tests` and `FAILED (failures=7, skipped=8)`. The eight skipped tests are
`test_local_prompt_handoff.py`'s, which need PowerShell 7. The seven failures are the new
tests': `test_the_gate_reads_only_fields_the_plan_writes` names the four fields the gate
reads that the plan will not write (`Items in the second set but not the first:`
`estimated_test_weight`, `shard_count`, `has_prompt_changes`, `needs_widgetbook`);
`test_the_gate_has_no_step_for_a_gate_v8_does_not_have` fails for `widgetbook`,
`prompt_contract` and `has_prompt_changes`, each listing the lines of `dod_check.sh` that
name it; and `test_the_prompt_delivery_scripts_are_gone` fails for each of the three files
(`True is not false`).

- [ ] **Step 3: Watch the changed-scope gate fail on a gate V8 does not have**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --force
```

Expected: it runs for about five minutes and exits 1. It starts with
`verification plan: full · 297 files · weight 1575 · CI shards 5` and the reasons
`documentation contract changed` and
`high-risk or verification-infrastructure path changed` (this branch changes a
verification script, so the plan is the full suite). Every step but one passes, the host
suite with `+2165: All tests passed!`, and it ends with `✗ failed gates:`,
`- selected Widgetbook gate unavailable: <repository>/widgetbook` and `- ci_tooling` (the
contract tests above).

- [ ] **Step 4: Take the Widgetbook and prompt steps out of the gate; describe V8 in its help and header**

In `.claude/skills/flutter-workflow/scripts/dod_check.sh`:

Replace

```bash
#        [--changed [--base <git-ref>]] [--fast] [--fix] [--force]
#   --changed  build the same feature × layer × risk plan as PR CI from the
#              diff against --base (default: origin/master), then run only the
#              selected host tests and Widgetbook surface. Unknown/high-risk
#              paths promote themselves to the full non-golden host suite.
#   --base     comparison ref for --changed; invalid without --changed
#   --fast  the tight-loop mode: run only the Deck + app test subset (what CI's
#           light gate runs), skipping goldens. ~20s instead of ~50s. It does
#           NOT run test/core, test/shared, or another feature's tests — run the
#           full gate (no --fast) before you commit, and always before a merge.
#   --fix   apply `dart format` instead of only reporting drift
```

with

```bash
#        [--changed [--base <git-ref>]] [--fast] [--fix] [--force]
#   --changed  select the checks and host tests from the diff against --base
#              (default: origin/master) through build_verification_plan.py.
#              Unknown and high-risk paths promote the run to the full
#              non-golden host suite. CI never uses it.
#   --base     comparison ref for --changed; invalid without --changed
#   --fast  the tight-loop mode: run only the Deck + app test subset, skipping
#           goldens. It does NOT run test/core, test/shared, or another
#           feature's tests, and CI never runs it: run the full gate (no
#           --fast) before you commit, and always before a merge.
#   --fix   apply `dart format` instead of only reporting drift
```

Replace

```bash
# the tree it verified; a later run with the same fingerprint prints what it
# already knows and exits in ~0.4s instead of 50-150s.
#
```

with

```bash
# the tree it verified; a later run with the same fingerprint prints what it
# already knows and exits at once: 0.03s against 266s for a full run, measured
# in the cloud container on 2026-09-26.
#
```

Replace

```bash
#
# ---------------------------------------------------------------------------
# Where the time goes, measured rather than assumed (2026-08-29, this machine,
# warm — the numbers in brackets are the first run in a fresh worktree, where
# touching thousands of files for the first time costs an order of magnitude
# more and every gate pays it at once):
#
#   flutter test    43s          dart format          3s
#   flutter analyze 10s          docs check           2s   [28s]
#   guard (python)  11s          CI tooling tests     8s
#                                architecture guard   2s
#
# **This file is not the bottleneck and rewriting it in another language does
# not help.** It has no per-file loop and no fork storm — the thing that made
# `check_architecture.sh` take two minutes before it became Python. It starts
# seven subprocesses and prints a summary; the cost is inside those seven.
#
# The CI tooling gate was **43s** until 2026-08-29 and the table above did not
# mention it at all, so nothing pointed at the second-largest cost in the run.
# It was not the tests being slow: 32 of them called `build_plan` against this
# repository, and each call re-read every tracked Dart file to weigh the tests
# and build the import graph. That scan is memoized per root now — see
# `build_verification_plan.py`. Keep this table honest when a gate moves; a
# stale one is how a gate grows into the bottleneck without anyone noticing.
#
# Two things in here *were* worth fixing, and both are scheduling rather than
# language:
#
#   1. It shelled into `bash check_*.sh`, and each of those wrappers only
#      `exec`s a `.py`. On Windows git-bash that fork measured **286ms**, three
#      times over — nearly a second spent starting shells that immediately
#      replace themselves. The `.py` is called directly now; the `.sh` wrappers
#      stay for everyone else who calls them by name.
#   2. Every gate ran in series although only one pair has an ordering
#      constraint. They run concurrently now, with each step's output buffered
#      and replayed in a fixed order — parallel execution, serial reading, so a
#      failure is still findable.
# ---------------------------------------------------------------------------

```

with

```bash
#
# **The script's shape.** It calls the Python checks directly, not through the
# `check_*.sh` wrappers that only `exec` them, which stay for anyone who calls
# them by name. It runs the steps in parallel and prints each step's buffered
# output in a fixed order, so a failure is as easy to find as in a serial run.

```

Replace

```bash
if [[ ! -f pubspec.yaml ]]; then
  echo "No pubspec.yaml at $REPO_ROOT — the Flutter project has not been created yet."
  echo "That is expected before Phase 2.3. Nothing to check."
  exit 0
```

with

```bash
if [[ ! -f pubspec.yaml ]]; then
  echo "No pubspec.yaml at $REPO_ROOT, so there is no Flutter project to check."
  exit 0
```

Replace

```bash
# HEAD, every tracked modification, and every untracked file git would not
# ignore. Measured at ~0.4s against a gate that costs 50-150s.
tree_fingerprint() {
```

with

```bash
# HEAD, every tracked modification, and every untracked file git would not
# ignore. A fraction of a second against the minutes a full run takes.
tree_fingerprint() {
```

Replace

```bash

# `python3` as well as `python`. Only `python` was tried once, so on a machine
# where the interpreter is named `python3` — most Linux distributions, and the
# CI runner — the project's main guard was *skipped* and this script still
# printed success. A skip that reads as a pass is the same defect as a rule that
# scans nothing.
PY=""
```

with

```bash

# `python3` as well as `python`: most Linux distributions, and the CI runner,
# name the interpreter `python3`, and a check skipped for want of `python`
# would read as a pass, the same defect as a rule that scans nothing.
PY=""
```

Replace

```bash
NEEDS_HOST_TESTS=1
NEEDS_WIDGETBOOK=0
HAS_PROMPT_CHANGES=0
PLAN_JSON="$WORK/verification-plan.json"
```

with

```bash
NEEDS_HOST_TESTS=1
PLAN_JSON="$WORK/verification-plan.json"
```

Replace

```bash
  NEEDS_HOST_TESTS="$(read_plan_bool needs_host_tests)"
  NEEDS_WIDGETBOOK="$(read_plan_bool needs_widgetbook)"
  HAS_PROMPT_CHANGES="$(read_plan_bool has_prompt_changes)"
  "$PY" -c "import json,sys; p=json.load(open(sys.argv[1], encoding='utf-8')); print('verification plan:', p['risk'], '·', len(p['test_files']), 'files · weight', p['estimated_test_weight'], '· CI shards', p['shard_count']); [print('  -', r) for r in p['reasons']]" "$PLAN_JSON"
fi
```

with

```bash
  NEEDS_HOST_TESTS="$(read_plan_bool needs_host_tests)"
  "$PY" -c "import json,sys; p=json.load(open(sys.argv[1], encoding='utf-8')); print('verification plan:', p['risk'], '·', len(p['test_files']), 'test files'); [print('  -', r) for r in p['reasons']]" "$PLAN_JSON"
fi
```

Replace

```bash
NEEDS_FLUTTER=0
if [[ $NEEDS_STATIC -eq 1 || $NEEDS_HOST_TESTS -eq 1 || $NEEDS_WIDGETBOOK -eq 1 ]]; then
  NEEDS_FLUTTER=1
```

with

```bash
NEEDS_FLUTTER=0
if [[ $NEEDS_STATIC -eq 1 || $NEEDS_HOST_TESTS -eq 1 ]]; then
  NEEDS_FLUTTER=1
```

Replace

```bash
# **What the formatter looks at is `check_format.sh`'s to decide, not this
# file's.** It was inlined here first and CI kept its own `dart format .`, which
# is two definitions of one check — and the pair only agreed by luck, because a
# fresh CI clone happens to have no worktrees. The script is the single answer
# both callers ask; its header carries the reasoning.
#
```

with

```bash
# **What the formatter looks at is `check_format.sh`'s to decide, not this
# file's:** one definition of the check for every caller. Its header carries
# the reasoning.
#
```

Replace

```bash
  FAILED+=("CI tooling tests unavailable: $CI_TOOLING_TESTS")
fi

PROMPT_GUARD="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_prompt_contract.py"
if [[ $HAS_PROMPT_CHANGES -eq 1 ]]; then
  if [[ -n "$PY" && -f "$PROMPT_GUARD" ]]; then
    plan prompt_contract "prompt delivery contract" "$PY '$PROMPT_GUARD'"
  else
    FAILED+=("prompt contract gate unavailable: $PROMPT_GUARD")
  fi
fi
```

with

```bash
  FAILED+=("CI tooling tests unavailable: $CI_TOOLING_TESTS")
fi
```

Replace

```bash

if [[ $NEEDS_WIDGETBOOK -eq 1 ]] && command -v flutter >/dev/null 2>&1; then
  if [[ -d widgetbook ]]; then
    plan widgetbook "Widgetbook smoke test" \
      "(cd '$REPO_ROOT/widgetbook' && flutter test --reporter failures-only)"
  else
    FAILED+=("selected Widgetbook gate unavailable: $REPO_ROOT/widgetbook")
  fi
fi

# ------------------------------------------------------------- run them all
# Output is captured per step rather than streamed. Interleaved output from
# seven concurrent processes is unreadable exactly when it matters — when
# something failed and you are looking for which line said so.
for i in "${!NAMES[@]}"; do
```

with

```bash

# ------------------------------------------------------------- run them all
# Output is captured per step rather than streamed. Interleaved output from
# concurrent processes is unreadable exactly when it matters — when something
# failed and you are looking for which line said so.
for i in "${!NAMES[@]}"; do
```

Replace

```bash
  echo "light/dark, small screen, text scale, loading/empty/error/success,"
  echo "accessibility, and whether docs/wbs.md tells the truth."
  exit 0
```

with

```bash
  echo "light/dark, small screen, text scale, loading/empty/error/success,"
  echo "accessibility, and whether docs/wbs_BE.md and docs/wbs_FE.md tell the truth."
  exit 0
```

- [ ] **Step 5: Delete the prompt delivery contract**

The PowerShell test goes with the script it tests.

Run:

```bash
git rm -q .claude/skills/flutter-workflow/scripts/check_prompt_contract.py
```

Run:

```bash
git rm -q .claude/skills/flutter-workflow/scripts/read_local_prompt_set.ps1
```

Run:

```bash
git rm -q .claude/skills/flutter-workflow/scripts/tests/test_local_prompt_handoff.py
```

- [ ] **Step 6: Run the CI tooling tests**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```

Expected: `Ran 67 tests` and `OK`. No test skips any more: the eight that needed
PowerShell left with their script.

- [ ] **Step 7: Run the changed-scope gate again**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --force
```

Expected: it exits 0 after about five minutes. It starts with
`verification plan: full · 297 test files` and the same two reasons; among its steps the
CI tooling tests `Ran 67 tests` and `OK` and the host suite `+2165: All tests passed!`; it
ends with `⚙ --changed used the sealed verification plan against origin/master.` and
`✓ mechanical gates passed`.

- [ ] **Step 8: Stage the task's files**

The deletions are staged already, by `git rm`. The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-workflow/scripts/dod_check.sh \
  .claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py
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
tests `Ran 67 tests` and `OK`; `204 passed` (the guard's self-tests);
`Code verification passed.`; `+2165: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
fix(tooling): the gate runs only V8's steps (BE-D5)

dod_check.sh --changed scheduled a Widgetbook smoke test for every plan with
needs_widgetbook, and V8 has no widgetbook/, so the run failed on most code
changes. The Widgetbook step and the prompt-contract step go, with
NEEDS_WIDGETBOOK and HAS_PROMPT_CHANGES: --changed reads needs_static,
needs_host_tests and local_test_targets, and its summary prints the risk, the
number of test files and the reasons. The help describes V8's --changed and
--fast, and the header loses V7's timings and history; the pass stamp's
figures are V8's.

V7's prompt delivery contract goes: check_prompt_contract.py,
read_local_prompt_set.ps1 and its PowerShell test (the eight tests the suite
skipped), and PromptContractTest. GateReadsThePlanTest pins that the gate
reads only fields the plan writes (spec D3) and has no step for a gate V8
does not have.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The plan holds eleven fields

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/build_verification_plan.py`, `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`
- Test (modify): `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`

**Interfaces:**
- Consumes: Task 1's `PLAN_FIELDS` and `GateReadsThePlanTest`.
- Produces (`build_verification_plan.py`):
  - `VerificationPlan` with exactly the eleven fields, and `to_json_dict()`.
  - `ImpactMap(feature_dependencies, database_query_features, full_scope_prefixes, full_scope_files, inert_prefixes, inert_files)`.
  - `discover_tests(root: Path) -> set[str]`, memoized per resolved root.
  - `compress_test_targets(selected_files: set[str], all_test_files: set[str]) -> tuple[str, ...]`,
    unchanged.
  - The CLI without `--github-output`: with `--json-output` it writes the file, and
    otherwise prints the plan.

Spec §4, §6 (contract test 1), D3–D6, D8; Clarifications 1 and 3–7; Review Focus
2–5. The red run shows five failures and one error; the error is the test that builds an
`ImpactMap` without shard thresholds.

- [ ] **Step 1: Write the failing tests, and rewrite the tests of removed fields**

The test fixture keeps its `shard_weight_thresholds` until Step 4 (Clarification 6).

In `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`:

Replace

```python

# The Flutter app does not exist until Phase 2.3; `dod_check.sh` exits early on
# the same condition. Tests that assert facts about that tree wait for it, and
# run again unchanged the day it is created.
_APP_TREE = (REPO_ROOT / "pubspec.yaml").is_file()
```

with

```python

# Tests about the real tree need the Flutter app. `dod_check.sh` exits early
# without a `pubspec.yaml` at the root, and these tests skip on the same
# condition.
_APP_TREE = (REPO_ROOT / "pubspec.yaml").is_file()
```

Replace

```python
# against a small, self-contained ADR-010-shaped repository (feature slugs
# from ADR-010 #1, `domain/data/presentation/di` layers from ADR-010 #2) —
# never against the real memox-v8 tree. Before `flutter create` runs that tree
# has no `lib/` or `test/` at all; after it runs, it will have V8 feature
# names and layout, not V7's (`test/app/router/...`, `lib/presentation/shared/
# ...`, a `tag` feature). A planner-logic test tied to either shape breaks the
# other. See ADR-010 and CLAUDE.md ("V7 is a reference, not a template").
_ADR010_SOURCE_FILES: dict[str, str] = {
```

with

```python
# against a small, self-contained ADR-010-shaped repository (feature slugs
# from ADR-010 #1, `domain/data/presentation/di` layers from ADR-010 #2),
# never against the real memox-v8 tree: a planner test tied to the real tree
# breaks whenever a feature or a test moves, for reasons that have nothing to
# do with the planner.
_ADR010_SOURCE_FILES: dict[str, str] = {
```

Replace

```python
    chains to exercise every classification rule `build_verification_plan.py`
    has, without describing the real app (which does not exist yet, and once
    it does will not look like this fixture either).
    """
```

with

```python
    chains to exercise every classification rule `build_verification_plan.py`
    has, without describing the real app.
    """
```

Replace

```python
# `verification_impact_map.json`: it exercises the same classification logic
# (feature-dependency BFS, database-query ownership, shard-count thresholds)
# without being tied to production data that other tests (`ImpactMapCoverage
# Test`, `ImpactMapMatchesTheDocsTest`) keep in sync with `docs/features/`.
# The shard-weight thresholds are lowered so the small fixture above still
# exercises the 1/2/5-shard boundaries meaningfully.
_ADR010_IMPACT_MAP_RAW: dict[str, object] = {
```

with

```python
# `verification_impact_map.json`: it exercises the same classification logic
# (feature-dependency BFS, database-query ownership) without being tied to
# production data that other tests (`ImpactMapCoverageTest`,
# `ImpactMapMatchesTheDocsTest`) keep in sync with `docs/features/`.
_ADR010_IMPACT_MAP_RAW: dict[str, object] = {
```

Replace

```python

    Never against `REPO_ROOT`: before Flutter is initialised it has no
    `lib/`/`test/`, and after it is, it will have V8's feature names and
    layout rather than the V7 paths some of these tests used to assert
    (`test/app/router/app_router_test.dart` importing a V7 `tag` feature,
    etc.). The fixture makes every assertion below true regardless of what
    the real tree currently contains.
    """
```

with

```python

    Never against `REPO_ROOT`: the fixture makes every assertion below true
    whatever the real tree contains.
    """
```

Replace

```python

    def test_a_shared_widget_change_selects_the_golden_job(self) -> None:
        """#337's shape: six components relaid out, no picture redrawn.

        It passed every check in `ci.yml` because nothing there compares a
        committed PNG against a fresh render — the Windows golden job lives in
        `ci-full.yml`, which is `workflow_dispatch:` only. 26 goldens went
        stale on `main` and the screen gallery published a pre-#337 app.
        """
        plan = self._plan("lib/shared/widgets/mx_button_pair.dart")
        self.assertTrue(plan.needs_goldens)

    def test_a_change_to_the_pictures_themselves_selects_the_golden_job(self) -> None:
        """A PR that only regenerates goldens is the one whose claim needs
        checking most — and a PNG is not code, so `code_required` misses it."""
        plan = self._plan("test/demo/goldens/deck_list_empty_light.png")
        self.assertTrue(plan.needs_goldens)

    def test_a_demo_test_change_selects_the_golden_job(self) -> None:
        plan = self._plan("test/demo/deck_screens_demo_test.dart")
        self.assertTrue(plan.needs_goldens)

    def test_regenerating_pictures_runs_the_golden_job_and_nothing_else(self) -> None:
        """The shape of a golden-regeneration PR, which is the common one.

        Measured before this was classified: two of the last forty commits on
        `main` were exactly this — 26 and 31 PNGs, no Dart — and each ran five
        host shards, `flutter analyze` and the Widgetbook smoke test. A PNG can
        fail none of them. It was not a decision: `require_test_path` claims a
        code change first thing, then finds no rule for `.png` and falls
        through to `require_full("unrecognised test support path")`.
        """
        plan = self._plan(
            "test/demo/goldens/deck_list_empty_light.png",
            "test/demo/goldens/card_list_dark.png",
        )
        self.assertTrue(plan.needs_goldens)
        # The assertions that would have caught it: everything the pictures
        # cannot affect.
        self.assertFalse(plan.full_suite)
```

with

```python

    def test_a_shared_widget_change_selects_the_full_host_suite(self) -> None:
        """A path under `lib/` outside a feature and `lib/core/` has no rule to
        narrow it, so it runs every non-golden host test."""
        plan = self._plan("lib/shared/widgets/mx_button_pair.dart")
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)

    def test_test_support_outside_the_known_folders_selects_everything(self) -> None:
        """Only `test/features/<feature>/<layer>/`, `test/app/`, `test/core/`
        and `test/shared/` narrow: support code anywhere else could feed any
        test, so it runs them all."""
        path = "test/visual_audit/support/audit_fixture.dart"
        plan = self._plan(path)
        self.assertTrue(plan.full_suite)
        self.assertIn(path, plan.unmatched_paths)

    def test_pictures_alone_need_no_static_check_and_no_host_test(self) -> None:
        """A committed golden image is not code: nothing the gate runs can fail
        on a `.png`, and CI's `goldens` job compares it against a fresh render."""
        plan = self._plan(
            "test/features/deck/presentation/goldens/deck_list_empty_light.png",
            "test/features/card/presentation/goldens/card_list_dark.png",
        )
        self.assertFalse(plan.full_suite)
```

Replace

```python
        self.assertFalse(plan.needs_host_tests)
        self.assertFalse(plan.needs_widgetbook)
        self.assertEqual(0, plan.shard_count)
        self.assertEqual("pixels", plan.risk)

    def test_a_picture_beside_its_widget_still_verifies_the_widget(self) -> None:
        """The narrowing must not survive contact with a real code change."""
        plan = self._plan(
            "test/demo/goldens/card_list_light.png",
            "lib/features/card/presentation/widgets/items/card_tile_widget.dart",
        )
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)
        self.assertTrue(plan.needs_goldens)

    def test_repository_furniture_verifies_nothing(self) -> None:
        """`.gitignore` and an issue template were selecting the whole suite.

        Both reached `require_full` — the first as an unclassified path, the
        second because `.github/` is a full-scope prefix and a markdown
        template is not a pipeline. One paragraph cost 1847s of runner time.
        """
        for path in (
```

with

```python
        self.assertFalse(plan.needs_host_tests)
        self.assertEqual((), plan.test_files)
        self.assertEqual("pixels", plan.risk)

    def test_a_picture_beside_its_widget_keeps_the_widget_selection(self) -> None:
        """The narrowing must not survive contact with a real code change."""
        widget = "lib/features/card/presentation/widgets/items/card_tile_widget.dart"
        alone = self._plan(widget)
        beside = self._plan(
            "test/features/card/presentation/goldens/card_list_light.png", widget
        )
        self.assertTrue(beside.needs_static)
        self.assertTrue(beside.needs_host_tests)
        self.assertEqual("targeted", beside.risk)
        self.assertEqual(alone.test_files, beside.test_files)

    def test_repository_furniture_verifies_nothing(self) -> None:
        """Git plumbing, editor settings and `.github/` templates cannot change
        what Dart compiles or what the tests run."""
        for path in (
```

Replace

```python
                self.assertFalse(plan.needs_static)
                self.assertFalse(plan.needs_goldens)
                self.assertFalse(plan.needs_host_tests)
```

with

```python
                self.assertFalse(plan.needs_static)
                self.assertFalse(plan.needs_host_tests)
```

Replace

```python
        that the new pipeline works, and only a full run tests that claim.
        `.github/workflows/` stays full-scope; only its inert neighbours moved.
        """
```

with

```python
        that the new pipeline works, and only a full run tests that claim.
        """
```

Replace

```python
    def test_an_unclassified_path_still_widens_to_everything(self) -> None:
        """The fallback is the safe default and this change does not touch it.

        What was wrong was never the fallback — it was the paths reaching it
        that should have been classified.
        """
        plan = self._plan("tools/some_new_thing.py")
```

with

```python
    def test_an_unclassified_path_still_widens_to_everything(self) -> None:
        """The fallback is the safe default: a path nobody classified runs
        everything."""
        plan = self._plan("tools/some_new_thing.py")
```

Replace

```python

    def test_a_documents_only_change_does_not_pay_for_a_windows_runner(self) -> None:
        """The job is conditional for a reason: Windows minutes cost double."""
        plan = self._plan("design_audit/layout_review/SUMMARY.md")
        self.assertFalse(plan.needs_goldens)

```

with

```python

    def test_documents_alone_need_no_static_check_and_no_host_test(self) -> None:
        for path in ("docs/wbs_BE.md", ".impeccable/critique/notes.md"):
            with self.subTest(path=path):
                plan = self._plan(path)
                self.assertFalse(plan.needs_static)
                self.assertFalse(plan.needs_host_tests)
                self.assertEqual("docs", plan.risk)

```

Replace

```python

    def test_prompt_only_change_uses_python_contract_path(self) -> None:
        plan = self._plan(
            "docs/prompt/progress-v1/implementation.md",
            "docs/prompt/progress-v1/recursive-ui-ux-review.md",
        )
        self.assertTrue(plan.prompt_only)
        self.assertTrue(plan.docs_only)
        self.assertFalse(plan.code_required)
        self.assertFalse(plan.needs_static)
        self.assertFalse(plan.needs_host_tests)
        self.assertFalse(plan.needs_widgetbook)

    def test_prompt_plus_normative_docs_stays_flutter_free(self) -> None:
        plan = self._plan(
            "docs/prompt/sample/implementation.md",
            "docs/wbs.md",
        )
        self.assertFalse(plan.prompt_only)
        self.assertTrue(plan.docs_only)
        self.assertFalse(plan.code_required)

```

with

```python

    def test_a_prompt_set_is_documentation_like_any_other(self) -> None:
        """V8 has no prompt delivery contract: `docs/prompt/` reaches the
        `docs/` rule."""
        plan = self._plan("docs/prompt/progress/implementation.md")
        self.assertEqual(("documentation contract changed",), plan.reasons)
        self.assertEqual("docs", plan.risk)

    def test_a_path_v8_has_no_rule_for_selects_everything(self) -> None:
        """`widgetbook/` and `memox-api/` have no rule (spec of package 12a,
        D6): like any unrecognised path they run the full suite, until V8's
        API adds its own rule under its ADR."""
        for path in ("widgetbook/lib/main.dart", "memox-api/pom.xml"):
            with self.subTest(path=path):
                plan = self._plan(path)
                self.assertTrue(plan.full_suite)
                self.assertIn(path, plan.unmatched_paths)

```

Replace

```python
            plan.test_files,
        )
        self.assertTrue(plan.needs_widgetbook)

    def test_data_change_adds_cross_feature_harness_consumers(self) -> None:
```

with

```python
            plan.test_files,
        )

    def test_data_change_adds_cross_feature_harness_consumers(self) -> None:
```

Replace

```python
        )
        self.assertFalse(plan.needs_widgetbook)

```

with

```python
        )

```

Replace

```python
            plan.test_files,
        )
        self.assertTrue(plan.needs_widgetbook)

    def test_public_domain_contract_expands_transitive_dependents(self) -> None:
```

with

```python
            plan.test_files,
        )

    def test_public_domain_contract_expands_transitive_dependents(self) -> None:
```

Replace

```python
        self.assertEqual(("data", "domain", "presentation"), plan.affected_layers)
        self.assertGreaterEqual(plan.shard_count, 2)

```

with

```python
        self.assertEqual(("data", "domain", "presentation"), plan.affected_layers)

```

Replace

```python
        self.assertTrue(plan.full_suite)
        self.assertEqual(5, plan.shard_count)
        self.assertTrue(plan.needs_widgetbook)
        self.assertEqual(("test",), plan.local_test_targets)
```

with

```python
        self.assertTrue(plan.full_suite)
        self.assertEqual(("test",), plan.local_test_targets)
```

Replace

```python
            "lib/core/theme/app_theme.dart",
            "lib/presentation/shared/mx_card.dart",
            "lib/app/router/app_router.dart",
```

with

```python
            "lib/core/theme/app_theme.dart",
            "lib/shared/widgets/mx_card.dart",
            "lib/app/router/app_router.dart",
```

Replace

```python

    def test_ci_tooling_change_is_full_so_the_new_gate_proves_itself(self) -> None:
        plan = self._plan(".github/workflows/ci.yml")
        self.assertTrue(plan.full_suite)
        self.assertEqual(5, plan.shard_count)

```

with

```python

    def test_a_verification_script_change_is_full(self) -> None:
        """Like the workflow: a change to the gate's own scripts is proved
        only by the full run it selects."""
        plan = self._plan(".claude/skills/flutter-workflow/scripts/dod_check.sh")
        self.assertTrue(plan.full_suite)

```

Replace

```python
        self.assertEqual((path,), plan.test_files)
        self.assertEqual(1, plan.shard_count)

```

with

```python
        self.assertEqual((path,), plan.test_files)

```

Replace

```python
        self.assertTrue(plan.test_files)
        self.assertTrue(plan.needs_widgetbook)
        self.assertTrue(
```

with

```python
        self.assertTrue(plan.test_files)
        self.assertTrue(
```

Replace

```python
    def test_the_worktree_scan_is_memoized_per_root_not_globally(self) -> None:
        """The cache that made this suite 43s → 8s must not answer for a
        different tree.

```

with

```python
    def test_the_worktree_scan_is_memoized_per_root_not_globally(self) -> None:
        """The memo must not answer for a different tree.

```

Replace

```python
            self.assertEqual(repo_first, repo_second)
            self.assertEqual({"test/only_test.dart": 1}, fixture)
            self.assertGreater(len(repo_first), 1)
```

with

```python
            self.assertEqual(repo_first, repo_second)
            self.assertEqual({"test/only_test.dart"}, fixture)
            self.assertGreater(len(repo_first), 1)
```

Replace

```python

    def test_widgetbook_only_change_skips_host_tests(self) -> None:
        plan = self._plan("widgetbook/lib/main.dart")
        self.assertTrue(plan.code_required)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_widgetbook)
        self.assertFalse(plan.needs_host_tests)

    def test_new_feature_without_tests_promotes_instead_of_trusting_widgetbook(self) -> None:
        plan = self._plan(
```

with

```python

    def test_a_new_feature_without_tests_promotes_to_the_full_suite(self) -> None:
        plan = self._plan(
```

Replace

```python
    def test_force_full_disables_docs_fast_path(self) -> None:
        plan = self._plan("docs/wbs.md", force_full=True)
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.code_required)

```

with

```python
    def test_force_full_disables_docs_fast_path(self) -> None:
        plan = self._plan("docs/wbs_BE.md", force_full=True)
        self.assertTrue(plan.full_suite)
        self.assertTrue(plan.needs_static)
        self.assertTrue(plan.needs_host_tests)

```

Replace

```python
            "lib/features/card/data/repositories/card_repository_impl.dart",
            "docs/wbs.md",
        )
        second = self._plan(
            "docs/wbs.md",
            "lib/features/card/data/repositories/card_repository_impl.dart",
```

with

```python
            "lib/features/card/data/repositories/card_repository_impl.dart",
            "docs/wbs_BE.md",
        )
        second = self._plan(
            "docs/wbs_BE.md",
            "lib/features/card/data/repositories/card_repository_impl.dart",
```

Replace

```python
            first.risk = "docs"

    def test_shard_policy_is_one_two_or_five_and_never_empty(self) -> None:
        choose = self.module.choose_shard_count
        self.assertEqual(0, choose(0, 0, 240, 800))
        self.assertEqual(1, choose(240, 20, 240, 800))
        self.assertEqual(2, choose(700, 50, 240, 800))
        self.assertEqual(5, choose(1200, 50, 240, 800))

```

with

```python
            first.risk = "docs"

```

Replace

```python
            inert_files=frozenset(),
            one_shard_max_weight=240,
            two_shard_max_weight=800,
        )
```

with

```python
            inert_files=frozenset(),
        )
```

Replace

```python
        """A job that the required check does not cover can fail without
        blocking a merge: the failure V7's wiring test caught."""
        _, jobs = self._workflow()
```

with

```python
        """A job that the required check does not cover can fail without
        blocking a merge."""
        _, jobs = self._workflow()
```

Replace

```python

    def test_the_prompt_delivery_scripts_are_gone(self) -> None:
```

with

```python

    def test_the_plan_holds_exactly_the_eleven_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = _fixture_repo(Path(temp) / "repo", "test/a_test.dart")
            paths = Path(temp) / "paths.txt"
            paths.write_text("test/a_test.dart\n", encoding="utf-8")
            output = Path(temp) / "plan.json"
            subprocess.run(
                [sys.executable, str(SCRIPTS / "build_verification_plan.py"),
                 "--root", str(root), "--paths-file", str(paths),
                 "--json-output", str(output)],
                check=True, capture_output=True, text=True,
            )
            written = json.loads(output.read_text(encoding="utf-8"))
        self.assertEqual(sorted(PLAN_FIELDS), sorted(written))

    def test_the_prompt_delivery_scripts_are_gone(self) -> None:
```

- [ ] **Step 2: Run them to see them fail**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```

Expected: `Ran 65 tests` and `FAILED (failures=5, errors=1)`. The error is
`test_dependency_graph_closure_terminates_even_with_cycles`:
`TypeError: ImpactMap.__init__() missing 2 required positional arguments: 'one_shard_max_weight' and 'two_shard_max_weight'`.
The five failures: `test_the_plan_holds_exactly_the_eleven_fields`, whose list of the
written fields has twelve more (`changed_count`, `code_required`, `docs_only`,
`estimated_test_weight`, `has_prompt_changes`, `needs_contracts`, `needs_goldens`,
`needs_memox_api`, `needs_widgetbook`, `prompt_only`, `shard_count`, `shard_matrix`);
`test_a_path_v8_has_no_rule_for_selects_everything` for `widgetbook/lib/main.dart` and
`memox-api/pom.xml` (`False is not true`);
`test_a_prompt_set_is_documentation_like_any_other`
(`('documentation contract changed',) != ('prompt delivery contract changed',)`); and
`test_the_worktree_scan_is_memoized_per_root_not_globally`
(`{'test/only_test.dart'} != {'test/only_test.dart': 1}`).

- [ ] **Step 3: Trim the planner to eleven fields and the rules V8 uses**

The blocks are in file order. Each removes what spec §4.1 lists, or says in V8's terms why
the code is as it is (Clarifications 1, 3 and 4).

In `.claude/skills/flutter-workflow/scripts/build_verification_plan.py`:

Replace

```python
high-risk paths promote the plan to the complete non-golden host suite.
"""
```

with

```python
high-risk paths promote the plan to the complete non-golden host suite.

`dod_check.sh --changed` is its only caller; V8's CI runs the full gate.
"""
```

Replace

```python
DEFAULT_IMPACT_MAP = SCRIPT_DIR / "verification_impact_map.json"
PROMPT_PREFIX = "docs/prompt/"
FEATURE_SOURCE_PREFIX = "lib/features/"
```

with

```python
DEFAULT_IMPACT_MAP = SCRIPT_DIR / "verification_impact_map.json"
FEATURE_SOURCE_PREFIX = "lib/features/"
```

Replace

```python
class VerificationPlan:
    changed_paths: tuple[str, ...]
```

with

```python
class VerificationPlan:
    """What `dod_check.sh --changed` runs, and why.

    The gate acts on `needs_static`, `needs_host_tests` and
    `local_test_targets`, and prints `risk`, `test_files` and `reasons`; the
    other fields explain the selection.
    """

    changed_paths: tuple[str, ...]
```

Replace

```python
    local_test_targets: tuple[str, ...]
    changed_count: int
    estimated_test_weight: int
    shard_count: int
    risk: str
    has_prompt_changes: bool
    prompt_only: bool
    docs_only: bool
    code_required: bool
    needs_contracts: bool
    needs_static: bool
    needs_host_tests: bool
    needs_widgetbook: bool
    needs_goldens: bool
    needs_memox_api: bool
    full_suite: bool

    @property
    def shard_matrix(self) -> dict[str, list[dict[str, int]]]:
        total = max(1, self.shard_count)
        return {
            "include": [
                {"shard": index, "label": index + 1, "total": total}
                for index in range(total)
            ]
        }

```

with

```python
    local_test_targets: tuple[str, ...]
    risk: str
    needs_static: bool
    needs_host_tests: bool
    full_suite: bool

```

Replace

```python
        payload["local_test_targets"] = list(self.local_test_targets)
        payload["shard_matrix"] = self.shard_matrix
        return payload
```

with

```python
        payload["local_test_targets"] = list(self.local_test_targets)
        return payload
```

Replace

```python
    inert_files: frozenset[str]
    one_shard_max_weight: int
    two_shard_max_weight: int

```

with

```python
    inert_files: frozenset[str]

```

Replace

```python
            raise ValueError("unsupported verification impact-map version")
        thresholds = raw["shard_weight_thresholds"]
        return cls(
```

with

```python
            raise ValueError("unsupported verification impact-map version")
        return cls(
```

Replace

```python
            inert_files=frozenset(raw.get("inert_files", ())),
            one_shard_max_weight=int(thresholds["one"]),
            two_shard_max_weight=int(thresholds["two"]),
        )
```

with

```python
            inert_files=frozenset(raw.get("inert_files", ())),
        )
```

Replace

```python
        self.unmatched_paths: set[str] = set()
        self.needs_memox_api = False
        self.test_prefixes: set[str] = set()
        self.exact_test_files: set[str] = set()
        self.has_prompt_changes = False
        self.has_docs_changes = False
        self.has_code_changes = False
        self.requires_host_coverage = False
        self.needs_widgetbook = False
        self.has_golden_image_changes = False
```

with

```python
        self.unmatched_paths: set[str] = set()
        self.test_prefixes: set[str] = set()
        self.exact_test_files: set[str] = set()
        self.has_code_changes = False
        self.requires_host_coverage = False
        self.has_golden_image_changes = False
```

Replace

```python
        self.requires_host_coverage = True
        self.needs_widgetbook = True
        self.add_reason(reason)
```

with

```python
        self.requires_host_coverage = True
        self.add_reason(reason)
```

Replace

```python
            self.test_prefixes.add(f"test/features/{feature}/{layer}/")
        if "presentation" in normalized_layers:
            self.needs_widgetbook = True

```

with

```python
            self.test_prefixes.add(f"test/features/{feature}/{layer}/")

```

Replace

```python
        )
        self.needs_widgetbook = True
        self.add_reason(reason)
```

with

```python
        )
        self.add_reason(reason)
```

Replace

```python
            self.test_prefixes.add("test/shared/")
            self.needs_widgetbook = True
            return
```

with

```python
            self.test_prefixes.add("test/shared/")
            return
```

Replace

```python

        if path.startswith(PROMPT_PREFIX):
            self.has_prompt_changes = True
            self.has_docs_changes = True
            self.add_reason("prompt delivery contract changed")
            return

        if path.startswith("docs/") or path in {"AGENTS.md", "CLAUDE.md", "README.md"}:
            self.has_docs_changes = True
            self.add_reason("documentation contract changed")
```

with

```python

        if path.startswith("docs/") or path in {"AGENTS.md", "CLAUDE.md", "README.md"}:
            self.add_reason("documentation contract changed")
```

Replace

```python
        if path.startswith(".claude/") and path.endswith(".md"):
            self.has_docs_changes = True
            self.add_reason("agent workflow documentation changed")
```

with

```python
        if path.startswith(".claude/") and path.endswith(".md"):
            self.add_reason("agent workflow documentation changed")
```

Replace

```python
        # **Before the full-scope check, because `.github/` is a prefix there
        # and an issue template is not a pipeline.** Measured: a one-file
        # markdown template under `.github/` selected the entire Dart suite and
        # the Windows golden job — 1847s of runner time to verify a paragraph.
        #
```

with

```python
        # **Before the full-scope check, because `.github/` is a prefix there
        # and an issue template is not a pipeline.**
        #
```

Replace

```python

        # The Java backend is a build input, but not a Dart one. Without this branch
        # `memox-api/**` reaches the unrecognised-path rule at the bottom and promotes
        # itself to the full Flutter suite — goldens and Widgetbook included — none of
        # which a Spring Boot change can fail. It selects its own Maven job instead.
        if path.startswith("memox-api/"):
            self.needs_memox_api = True
            self.add_reason("memox-api changed; the Maven verify job covers it")
            return

        if path.startswith("widgetbook/"):
            self.has_code_changes = True
            self.needs_widgetbook = True
            self.add_reason("Widgetbook catalog changed")
            return

        # **A picture is not code, and it was only ever reaching the full
        # suite by accident.** `require_test_path` sets `has_code_changes`
        # first thing and then finds no rule for a `.png`, so every golden
        # image fell through to `require_full("unrecognised test support
        # path")`. Measured on real history: two of the last forty commits were
        # golden-regeneration PRs — 26 and 31 PNGs — and each one ran five host
        # shards, `flutter analyze` and the Widgetbook smoke test. A PNG cannot
        # fail any of them.
        #
        # What checks a regenerated picture is the golden job comparing it
        # against a fresh render, and `needs_goldens` already fires on
        # `/goldens/` independently of `code_required` — so returning here
        # without claiming a code change selects exactly that job and no other.
        if "/goldens/" in path and not path.endswith(".dart"):
```

with

```python

        # **A picture is not code.** Nothing the gate runs can fail on a
        # committed golden image; CI's `goldens` job is what compares it
        # against a fresh render. Returning here without claiming a code
        # change keeps a plan of pictures alone at no static check and no host
        # test, with the risk `pixels`. A picture beside a code change does not
        # narrow the plan: the code's own rule selects its checks.
        if "/goldens/" in path and not path.endswith(".dart"):
```

Replace

```python
        if path.endswith(".md"):
            self.has_docs_changes = True
            self.add_reason("markdown documentation changed")
```

with

```python
        if path.endswith(".md"):
            self.add_reason("markdown documentation changed")
```

Replace

```python
            {path for path in self.changed_paths if path.endswith(".dart")},
            set(runnable_tests),
        )
```

with

```python
            {path for path in self.changed_paths if path.endswith(".dart")},
            runnable_tests,
        )
```

Replace

```python
            selected = {
                path: weight
                for path, weight in runnable_tests.items()
                if path in self.exact_test_files
```

with

```python
            selected = {
                path
                for path in runnable_tests
                if path in self.exact_test_files
```

Replace

```python

        estimated_weight = sum(selected.values())
        local_targets = compress_test_targets(set(selected), set(runnable_tests))
        shard_count = choose_shard_count(
            estimated_weight,
            len(selected),
            self.impact_map.one_shard_max_weight,
            self.impact_map.two_shard_max_weight,
        ) if needs_host_tests else 0

        changed = tuple(sorted(self.changed_paths))
        prompt_only = bool(changed) and all(
            path.startswith(PROMPT_PREFIX) for path in changed
        )
        docs_only = bool(changed) and not code_required
        # `pixels` rather than `docs` for a picture-only change: both require no
```

with

```python

        # `pixels` rather than `docs` for a picture-only change: both require no
```

Replace

```python
        )
        # **Pixel comparison belongs on the PR, not only in a dispatch-only
        # workflow.** `ci-full.yml` has always had a `goldens` job on Windows,
        # and it is `workflow_dispatch:` — so in practice nothing ever compared
        # a committed PNG against a fresh render. #337 changed how six
        # components lay out, committed no goldens, went green on every check,
        # and left 26 stale pictures on `main`; the gallery published a
        # pre-#337 app until someone ran the suite by hand.
        #
        # Any code change can move a pixel, so `code_required` is the trigger.
        # A change that touches the pictures themselves counts too, because a
        # PR that only regenerates goldens is exactly the one whose claim needs
        # checking — and PNGs are not code, so `code_required` is false there.
        needs_goldens = code_required or any(
            "/goldens/" in path or path.startswith("test/demo/")
            for path in changed
        )
        return VerificationPlan(
            changed_paths=changed,
            affected_features=tuple(sorted(self.features)),
```

with

```python
        )
        return VerificationPlan(
            changed_paths=tuple(sorted(self.changed_paths)),
            affected_features=tuple(sorted(self.features)),
```

Replace

```python
            test_files=tuple(sorted(selected)),
            local_test_targets=local_targets,
            changed_count=len(changed),
            estimated_test_weight=estimated_weight,
            shard_count=shard_count,
            risk=risk,
            has_prompt_changes=self.has_prompt_changes,
            prompt_only=prompt_only,
            docs_only=docs_only,
            code_required=code_required,
            needs_contracts=True,
            needs_static=code_required,
            needs_host_tests=needs_host_tests,
            needs_widgetbook=self.needs_widgetbook,
            needs_goldens=needs_goldens,
            needs_memox_api=self.needs_memox_api,
            full_suite=self.full_suite,
        )


def choose_shard_count(
    weight: int,
    file_count: int,
    one_shard_max_weight: int,
    two_shard_max_weight: int,
) -> int:
    if file_count <= 0:
        return 0
    if weight <= one_shard_max_weight or file_count == 1:
        return 1
    if weight <= two_shard_max_weight or file_count < 5:
        return min(2, file_count)
    return min(5, file_count)

```

with

```python
            test_files=tuple(sorted(selected)),
            local_test_targets=compress_test_targets(selected, runnable_tests),
            risk=risk,
            needs_static=code_required,
            needs_host_tests=needs_host_tests,
            full_suite=self.full_suite,
        )

```

Replace

```python
) -> tuple[str, ...]:
    """Compress an exact plan to safe local CLI targets.

    GitHub shards need exact files. Windows' command line cannot carry hundreds
    of them, so the local gate replaces a complete selected subtree with that
    directory while proving no unselected tracked test lives below it.
    """
```

with

```python
) -> tuple[str, ...]:
    """Compress an exact selection to the fewest command-line targets.

    `dod_check.sh` hands the targets to `flutter test` on one command line,
    which on Windows cannot carry hundreds of files. A complete selected
    subtree becomes its directory, and only when no unselected test lives
    below it.
    """
```

Replace

```python
# **The worktree scan is memoized per process, and that is a scheduling fix
# rather than a correctness one.** Sealing a plan reads every tracked Dart file
# twice — once to weigh the runnable tests, once to build the reverse import
# graph — which is ~2,150 files on this repo and about 1.2s. One `build_plan`
# per process pays that once and nobody notices; `test_ci_tooling.py` calls it
# 32 times against an unchanging tree and paid it 32 times, which measured
# **37.5s of the suite's 43s** (2026-08-29). The gate that suite belongs to runs
# on every local iteration, so that was most of the wait between "fix a doc
# line" and "learn whether the guard agrees".
#
```

with

```python
# **The worktree scan is memoized per process, and that is a scheduling fix
# rather than a correctness one.** Sealing a plan reads each test file to find
# the runnable ones, and every tracked Dart file to build the reverse import
# graph. The CLI builds one plan per process and pays that once;
# `test_ci_tooling.py` builds many plans against unchanging trees and would
# otherwise pay it for every one.
#
```

Replace

```python
# plans, and the plan is a statement about one tree. Adding the escape hatch
# before a caller exists is the habit this repository names in AD-14 and
# refuses everywhere else.
_WORKTREE_SCAN_CACHE: dict[str, frozenset[str]] = {}
_RUNNABLE_TEST_CACHE: dict[str, dict[str, int]] = {}
_REVERSE_IMPORT_CACHE: dict[str, dict[str, set[str]]] = {}
```

with

```python
# plans, and the plan is a statement about one tree. Adding the escape hatch
# before a caller exists is the speculative structure `CLAUDE.md` refuses.
_WORKTREE_SCAN_CACHE: dict[str, frozenset[str]] = {}
_RUNNABLE_TEST_CACHE: dict[str, frozenset[str]] = {}
_REVERSE_IMPORT_CACHE: dict[str, dict[str, set[str]]] = {}
```

Replace

```python

def discover_tests(root: Path) -> dict[str, int]:
    key = str(root.resolve())
```

with

```python

def discover_tests(root: Path) -> set[str]:
    """The runnable test files: every `_test.dart` under `test/` that is not
    golden-only."""
    key = str(root.resolve())
```

Replace

```python
    if cached is not None:
        return dict(cached)
    paths = sorted(
        path
```

with

```python
    if cached is not None:
        return set(cached)
    paths = {
        path
```

Replace

```python
        and not is_golden_only_test(root / path)
    )
    declaration = re.compile(r"\b(?:testWidgets|testGoldens|test)\s*\(")
    weights = {
        path: max(1, len(declaration.findall((root / path).read_text(encoding="utf-8"))))
        for path in paths
    }
    _RUNNABLE_TEST_CACHE[key] = dict(weights)
    return weights

```

with

```python
        and not is_golden_only_test(root / path)
    }
    _RUNNABLE_TEST_CACHE[key] = frozenset(paths)
    return paths

```

Replace

```python

def _bool(value: bool) -> str:
    return "true" if value else "false"


def write_github_output(path: Path, plan: VerificationPlan) -> None:
    values = {
        "changed_count": str(plan.changed_count),
        "has_prompt_changes": _bool(plan.has_prompt_changes),
        "prompt_only": _bool(plan.prompt_only),
        "docs_only": _bool(plan.docs_only),
        "code_required": _bool(plan.code_required),
        "needs_contracts": _bool(plan.needs_contracts),
        "needs_static": _bool(plan.needs_static),
        "needs_host_tests": _bool(plan.needs_host_tests),
        "needs_widgetbook": _bool(plan.needs_widgetbook),
        "needs_goldens": _bool(plan.needs_goldens),
        "needs_memox_api": _bool(plan.needs_memox_api),
        "full_suite": _bool(plan.full_suite),
        "risk": plan.risk,
        "shard_count": str(plan.shard_count),
        "shard_matrix": json.dumps(plan.shard_matrix, separators=(",", ":")),
        "test_files_json": json.dumps(plan.test_files, separators=(",", ":")),
    }
    with path.open("a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def main() -> int:
```

with

```python

def main() -> int:
```

Replace

```python
    parser.add_argument("--impact-map", type=Path, default=DEFAULT_IMPACT_MAP)
    parser.add_argument("--github-output", type=Path)
    parser.add_argument("--json-output", type=Path)
```

with

```python
    parser.add_argument("--impact-map", type=Path, default=DEFAULT_IMPACT_MAP)
    parser.add_argument("--json-output", type=Path)
```

Replace

```python
    )
    if args.github_output:
        write_github_output(args.github_output, plan)
    payload = json.dumps(plan.to_json_dict(), ensure_ascii=False, separators=(",", ":"))
```

with

```python
    )
    payload = json.dumps(plan.to_json_dict(), ensure_ascii=False, separators=(",", ":"))
```

Replace

```python
        args.json_output.write_text(payload + "\n", encoding="utf-8")
    if not args.github_output and not args.json_output:
        print(payload)
    return 0
```

with

```python
        args.json_output.write_text(payload + "\n", encoding="utf-8")
        return 0
    print(payload)
    return 0
```

- [ ] **Step 4: Drop the shard thresholds from the impact map and the test fixture**

The planner reads no thresholds now, so the map and the fixture drop them.

In `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`:

Replace

```json
    "LICENSE"
  ],
  "shard_weight_thresholds": {
    "one": 240,
    "two": 800
  }
}
```

with

```json
    "LICENSE"
  ]
}
```

In `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py`:

Replace

```python
    ],
    "shard_weight_thresholds": {"one": 2, "two": 5},
}
```

with

```python
    ],
}
```

- [ ] **Step 5: Run the CI tooling tests**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
```

Expected: `Ran 65 tests` and `OK`.

- [ ] **Step 6: Run the changed-scope gate on the eleven-field plan**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --force
```

Expected: it exits 0 after about five minutes, the gate reading its six fields from a plan
that now has eleven: `verification plan: full · 297 test files`, the CI tooling tests
`Ran 65 tests` and `OK`, `+2165: All tests passed!` and `✓ mechanical gates passed`.

- [ ] **Step 7: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-workflow/scripts/build_verification_plan.py \
  .claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py \
  .claude/skills/flutter-workflow/scripts/verification_impact_map.json
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
tests `Ran 65 tests` and `OK`; `204 passed` (the guard's self-tests);
`Code verification passed.`; `+2165: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
refactor(tooling): the verification plan holds eleven fields (BE-D5)

build_verification_plan.py serves dod_check.sh --changed only, so what V7's
sharded CI read goes: the shard count and matrix with the impact map's
thresholds, the test weights, --github-output, needs_widgetbook,
needs_memox_api, the prompt-set rule and fields, and needs_goldens,
needs_contracts, code_required, docs_only and changed_count. widgetbook/ and
memox-api/ paths are unrecognised and select the full suite (spec D6); a
docs/prompt/ path is documentation. discover_tests returns the runnable
paths. Every classification rule V8's tree uses, the import closure, the
fail-safe widening, the picture rule and compress_test_targets stay.

The tests pin the local plan: pictures alone need no static check and no
host test, a picture beside a code change keeps the code's selection, and
the CLI's JSON holds exactly the eleven fields of spec D3. The tests of the
removed behaviour go, and comments and docstrings describe V8.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: Documents

**Files:**
- Modify: `.claude/skills/flutter-ship/references/ci.md`, `docs/wbs_BE.md`

**Interfaces:**
- Consumes: the paths of the spec and of this plan.
- Produces: the documents of spec §7.

Spec §7; Clarifications 8 and 9; Review Focus 1.

- [ ] **Step 1: Say what the planner serves, and record BE-D5, BE-D6 and BE-D7**

In `.claude/skills/flutter-ship/references/ci.md`:

Replace

```markdown
  runs, in full: never `--fast` or `--changed`, and no selection by the
  planner. `build_verification_plan.py` still serves `dod_check.sh --changed`
  on a workstation; its CI-only outputs (shards, `--github-output`) are BE-D5
  in `docs/wbs_BE.md`.
- **`CI gate` is the one required check.** It needs every other job and runs
```

with

```markdown
  runs, in full: never `--fast` or `--changed`, and no selection by the
  planner. `build_verification_plan.py` serves `dod_check.sh --changed` on a
  workstation and nothing else: it writes no output for CI.
- **`CI gate` is the one required check.** It needs every other job and runs
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-C4 | Lọc card list theo tag (BR-TAG-004): `CardListQuery.tagIds`, một `EXISTS` trên `card_tags` trong vị từ chung của danh sách, số đếm và Select all; số đếm trạng thái và workload vẫn tính cả deck | xong | BE-B2 | S | Spec gói 8 §8; `test/features/card/data/card_list_tag_filter_test.dart` | — |

```

with

```markdown
| BE-C4 | Lọc card list theo tag (BR-TAG-004): `CardListQuery.tagIds`, một `EXISTS` trên `card_tags` trong vị từ chung của danh sách, số đếm và Select all; số đếm trạng thái và workload vẫn tính cả deck | xong | BE-B2 | S | Spec gói 8 §8; `test/features/card/data/card_list_tag_filter_test.dart` | — |
| BE-D5 | Công cụ kiểm chứng không còn gì của V7 (mở rộng theo chủ dự án): `build_verification_plan.py` chỉ phục vụ `dod_check.sh --changed`, plan còn 11 field, bỏ shard, `--github-output`, Widgetbook, memox-api và prompt set; `dod_check.sh` không còn bước Widgetbook và bước prompt contract, nên `--changed` hết fail trên mọi thay đổi code; lời giúp và header tả V8; gỡ `check_prompt_contract.py`, `read_local_prompt_set.ps1` và test PowerShell của nó | xong | BE-D2 | M | [spec](superpowers/specs/2026-09-26-verification-tooling-design.md) và [plan](superpowers/plans/2026-09-27-verification-tooling.md) gói 12a; `GateReadsThePlanTest` và test của planner trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | BE-D6, BE-D7 |

```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D5 | Tỉa phần chỉ phục vụ CI của `build_verification_plan.py` (shard, `--github-output`, cờ Widgetbook và memox-api) cùng test của nó; sửa lời giúp của `dod_check.sh`, nơi `--changed` và `--fast` còn được tả theo CI của V7 | chưa bắt đầu | BE-D2 | M | CI của V8 chạy gate đầy đủ, không dùng planner ([spec gói 6](superpowers/specs/2026-09-25-ci-gate-design.md) D2, D11); planner vẫn phục vụ `dod_check.sh --changed` | Giữ phần `--changed` dùng, bỏ phần chỉ CI của V7 cần, kèm test |

```

with

```markdown
|---|---|---|---|---|---|---|
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Làm trong BE-D7 (gói 12c) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở 18 UC; UC-TRANSFER-001 và UC-TRANSFER-002 (BE-B3), UC-STARTER-001 (BE-B4), UC-REMINDER-001 (BE-B5a) đã có, trong phạm vi spec của gói | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
| BE-D6 | Guard và hook design token không còn V7: gỡ registry `memox-v7` của `code-verification-guard-v2` cùng test của nó; hook `.claude/hooks/check_design_tokens.py` đọc rule của `memox-v8`; tài liệu của guard ghi `memox-v8` là nơi của nó. Giữ registry `memox` (V6) | chưa bắt đầu | — | M | Chủ dự án tách phần V7 còn lại thành hai gói ngày 2026-09-26 ([spec gói 12a](superpowers/specs/2026-09-26-verification-tooling-design.md) §2, §9) | Gói 12b: brainstorm, spec, plan |
| BE-D7 | Skill và tài liệu không còn V7: Widgetbook trong Definition of Done và trong skill `flutter-feature-slice`, `flutter-design-system`; các con trỏ tới `docs/wbs.md` và checklist của V7; `--ruleset memox-v7`; baseline và blueprint của V7; bản ghi cài đặt của skill `project-documentation`; lịch sử của V7 trong comment của các script khác của `flutter-workflow` và `flutter-architecture` (`check_format.sh`, `check_generated.sh`, `check_architecture.py`). Gồm BE-D3 | chưa bắt đầu | BE-D6 | M | [Spec gói 12a](superpowers/specs/2026-09-26-verification-tooling-design.md) §2, §9 | Gói 12c: brainstorm, spec, plan |

```

Replace

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
```

with

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **BE-D5** (gói 12a, [spec](superpowers/specs/2026-09-26-verification-tooling-design.md),
  [plan](superpowers/plans/2026-09-27-verification-tooling.md)): gate xanh sau mỗi task;
  `dod_check.sh --changed --force` fail ở bước Widgetbook trước khi sửa và xanh sau đó;
  final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 22/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-REMINDER-001, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STARTER-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 11a (BE-B5a).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 12a (BE-D5).

```

Replace

```markdown

1. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.

```

with

```markdown

1. BE-D6 (gói 12b), rồi BE-D7 (gói 12c), theo thứ tự chủ dự án chọn ngày 2026-09-26.
2. BE-B5b cùng hoặc sau FE-B5, khi có Android SDK hoặc thiết bị (xem Điểm chặn).

```

Replace

```markdown
  chuyển sang BE-B5b.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  chuyển sang BE-B5b.
- **Cập nhật ngày 2026-09-27:** BE-D5 xong trong gói 12a, mở rộng theo chủ dự án: công cụ
  kiểm chứng không còn gì của V7, và `dod_check.sh --changed` hết chọn bước Widgetbook mà
  V8 không có. Phần V7 còn lại tách thành BE-D6 (guard và hook, gói 12b) và BE-D7 (skill
  và tài liệu, gói 12c); BE-D3 làm trong BE-D7.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `generate.py` prints `OK docs/_generated: generated 3 files` and changes nothing
under `docs/_generated/`; `check.py` ends with `PASS — 0 error(s), 45 warning(s)`.

- [ ] **Step 2: Stage the task's files**

The task is staged before the gate runs, so the commit holds the tree the gate verified.

```bash
git add .claude/skills/flutter-ship/references/ci.md \
  docs/wbs_BE.md
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a
space in its second.

- [ ] **Step 3: Run the changed-scope gate on the documents alone**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --changed --base HEAD
```

Expected: it takes a few seconds: `verification plan: docs · 0 test files` with the
reasons `agent workflow documentation changed` and `documentation contract changed`; only
`document integrity`, `Flutter SDK matches .fvmrc` and `CI tooling unit tests` run; it
ends with `⚙ --changed used the sealed verification plan against HEAD.` and
`✓ mechanical gates passed`.

- [ ] **Step 4: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps: `No issues found!`;
`✓ generated code is fresh, complete and uncommitted`; `✓ architecture boundaries clean`;
`PASS — 0 error(s), 45 warning(s)` (the warnings are older than this plan); the CI tooling
tests `Ran 65 tests` and `OK`; `204 passed` (the guard's self-tests);
`Code verification passed.`; `+2165: All tests passed!`.

- [ ] **Step 5: Commit**

```bash
git commit -F - <<'EOF'
docs(tooling): the planner serves --changed only; BE-D5 done, BE-D6 and BE-D7 added

flutter-ship's CI reference says the planner serves dod_check.sh --changed
and writes no output for CI. wbs_BE.md: BE-D5 is done (package 12a); the
owner split what is left of V7 into BE-D6, the guard and the design-token
hook (package 12b), and BE-D7, the skills and documents (package 12c), which
takes BE-D3. The next steps are BE-D6, BE-D7, then BE-B5b when it is
unblocked.
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-verification-tooling` and open its pull request against `master`, then
subscribe to its activity.

Expected: CI is paused during active development (root `README.md`, "CI"), so no check
runs on the pull request; it merges on the local gate.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-verification-tooling` if it moved, run the gate once more
on the branch head, and squash-merge only while it ends with `✓ mechanical gates passed`.
Then unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** D1, §9: no step touches the guard, a hook, another skill's files,
  `CLAUDE.md` or `AGENTS.md`. D2: Tasks 1 and 2, and Clarification 1. D3, §6's contract
  tests: Task 1 (the fields the gate reads, the steps, the removed scripts) and Task 2 (the
  eleven fields). D4, §4.1: Task 2. D5, §4.2: Task 2 keeps every rule, and its unchanged
  tests pin them. D6, D8: Task 2's tests, and Task 1 for the prompt contract's files. D7,
  §5: Task 1. D9, §6: Tasks 1 and 2. D10, §7: Task 3. D11, §8: every task's gate, the
  runs of Task 1 before and after the fix, and no skipped test from Task 1 on. D12: the
  branch and the pull request above.
- **Placeholders.** None: every step carries its code or its command and its expected
  output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run ran
  every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test or its run in the task that owns
  the code.
