# MemoX V8 — Verification tooling without V7 (package 12a)

Status: approved 2026-09-26 (design sections 1 and 2 in conversation, then this spec) · Path: architectural

## 1. Intent

Build BE-D5 of [`docs/wbs_BE.md`](../../wbs_BE.md), widened by the owner on 2026-09-26:
the verification tooling keeps nothing of V7. `dod_check.sh --changed` is the fast gate
a contributor runs on a workstation; V8's CI runs the full gate and never uses the
planner ([spec of package 6](2026-09-25-ci-gate-design.md) D2, D11). What V7's sharded
pipeline needed from the planner, and V7's prompt delivery contract, go.

Success means:

- `dod_check.sh --changed` no longer selects a gate V8 does not have: today it fails on
  most code changes (§2, "The Widgetbook defect");
- the plan the planner writes holds exactly the fields the gate reads and the fields
  that explain the selection, and a test keeps the two sides in step;
- no script, test, rule, flag, output or comment of the verification tooling describes
  V7: no shards, GitHub outputs, Widgetbook, memox-api or prompt sets, and no V7
  measurements;
- the CI tooling tests skip nothing for want of PowerShell;
- the gate passes.

## 2. Context (2026-09-26)

- `master` is at `0c75383` (#88).
- **The planner**, `.claude/skills/flutter-workflow/scripts/build_verification_plan.py`
  (780 lines), classifies each changed path by feature and layer, adds the tests that
  import a changed Dart file, and falls back to the full non-golden host suite for any
  path it does not know. Its only caller is `dod_check.sh --changed`, which reads
  `needs_static`, `needs_host_tests`, `needs_widgetbook`, `has_prompt_changes`,
  `local_test_targets`, and, for one summary line, `risk`, `test_files`,
  `estimated_test_weight`, `shard_count` and `reasons`.
- **What only V7's CI read:** `write_github_output` and `--github-output`; the shard
  count and matrix, with the impact map's `shard_weight_thresholds` and a weight per
  test file; `needs_goldens`, `needs_contracts`, `needs_widgetbook`, `needs_memox_api`,
  `code_required`, `docs_only`, `prompt_only` and `changed_count`. Two classification
  rules serve paths V8 does not have: `widgetbook/` and `memox-api/`.
- **The Widgetbook defect.** The planner sets `needs_widgetbook` for every presentation
  change, every `test/shared/` change and every full-suite plan. Measured on `master`:
  `lib/features/deck/presentation/screens/deck_list_screen.dart` gives
  `needs_widgetbook: true`, and `lib/core/clock/day_clock.dart` gives a full plan with
  `needs_widgetbook: true`. `dod_check.sh --changed` then schedules its Widgetbook step,
  which fails with `selected Widgetbook gate unavailable`: V8 has no `widgetbook/`.
  A full run is unaffected, because it starts with `NEEDS_WIDGETBOOK=0`.
- **V7's prompt delivery contract.** `check_prompt_contract.py` (250 lines) validates
  prompt sets under `docs/prompt/<feature>/`, the contract V7's `AGENTS.md` gave them.
  `read_local_prompt_set.ps1` (120 lines, PowerShell) hands such a set between
  worktrees, and `tests/test_local_prompt_handoff.py` tests it: its 8 tests skip on any
  machine without PowerShell 7, which is why the gate prints `OK (skipped=8)`. The
  planner has a `docs/prompt/` rule, `dod_check.sh` a prompt-contract step, and
  `test_ci_tooling.py` a `PromptContractTest`. V8 has no `docs/prompt/`.
- **`dod_check.sh`'s help** says `--changed` builds "the same feature × layer × risk
  plan as PR CI" and "the selected host tests and Widgetbook surface", and that `--fast`
  runs "what CI's light gate runs". Neither is true of V8. Its header carries a table of
  V7 timings (2026-08-29) and V7's history of the CI tooling gate and of Windows
  git-bash.
- **The CI tooling tests** (`python3 -m unittest discover` over
  `.claude/skills/flutter-workflow/scripts/tests`): `Ran 77 tests`, `OK (skipped=8)`.
  `test_ci_tooling.py` has 61 test methods; several assert the removed outputs
  (shards, the golden job, Widgetbook), and their docstrings retell V7 incidents
  (#337, `ci-full.yml`, a Windows runner).
- **What stays outside this package** (owner, 2026-09-26): the guard's `memox-v7`
  registry and the design-token hook that reads it (package 12b, BE-D6); the skills and
  documents that still point at V7, with BE-D3 (package 12c, BE-D7); `CLAUDE.md`.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | The planner, `dod_check.sh`, `verification_impact_map.json`, the CI tooling tests, and V7's prompt delivery contract. Not the guard, the hooks, the skills' other documents or `CLAUDE.md` (§2) | Owner, 2026-09-26 (three packages) |
| D2 | Principle | Nothing of V7 stays in these files: no V7-only rule, flag, output, script or test, and no V7 measurement or incident in a comment. What stays describes V8 | Owner, 2026-09-26 |
| D3 | The plan | The plan JSON holds eleven fields: `changed_paths`, `affected_features`, `affected_layers`, `reasons`, `unmatched_paths`, `test_files`, `local_test_targets`, `risk`, `full_suite`, `needs_static`, `needs_host_tests`. The gate reads six of them (§5); the rest explain the selection | Owner, 2026-09-26 (approach 1 of three) |
| D4 | Planner removals | §4.1 | Design section 1 |
| D5 | Planner keeps | §4.2: every classification rule V8's tree uses, the import closure, the fail-safe widening, the picture rule, and the target compression | Design section 1 |
| D6 | Paths of removed rules | A `widgetbook/` or `memox-api/` path falls through to the unrecognised-path rule and selects the full suite. V8's API, when its sub-project starts, adds its own rule under its own ADR | Owner, 2026-09-26 ("tao vẫn muốn làm API") |
| D7 | The gate | §5 | Design section 1 |
| D8 | Prompt contract | Delete `check_prompt_contract.py`, `read_local_prompt_set.ps1` and `tests/test_local_prompt_handoff.py`; the planner's prompt rule, the gate's prompt step and `PromptContractTest` go with them. A `docs/prompt/` path is documentation like any other | Owner, 2026-09-26 |
| D9 | Tests | §6: the tests of removed behaviour go; the picture tests pin the local plan; three contract tests are written first and seen failing | Design section 2 |
| D10 | Documents | §7 | Design section 2 |
| D11 | Verification | §8, including a `--changed` run that fails before the fix and passes after it | Design section 2 |
| D12 | Branch and PR | Branch `claude/be-verification-tooling` from `master` `0c75383`; spec, plan, execution, final review, then a pull request, squash-merged on the local gate while CI is paused | Owner's standing choice |

## 4. The planner

### 4.1 What goes

- **Shards:** `VerificationPlan.shard_count` and `shard_matrix`, `choose_shard_count`,
  `ImpactMap.one_shard_max_weight` and `two_shard_max_weight`, and the impact map's
  `shard_weight_thresholds`.
- **Weights:** `estimated_test_weight`, and the weight `discover_tests` computes for each
  test file. `discover_tests` returns the runnable test paths.
- **GitHub output:** `write_github_output`, `_bool` and the `--github-output` option.
- **Widgetbook:** `needs_widgetbook`, every place that sets it, and the `widgetbook/`
  rule.
- **memox-api:** `needs_memox_api` and the `memox-api/` rule.
- **Prompt sets:** `PROMPT_PREFIX`, `has_prompt_changes`, `prompt_only` and the
  `docs/prompt/` rule; such a path reaches the `docs/` rule.
- **Fields nobody reads:** `needs_goldens`, `needs_contracts`, `code_required`,
  `docs_only` and `changed_count`.
- **V7 in comments and docstrings:** the incidents and measurements (the one-file
  issue template that ran the Windows golden job, the forty-commit sample of golden
  regenerations, the 37.5 s of a 43 s suite, `ci-full.yml`, #337, GitHub shards and the
  Windows command line). A comment that stays says why the code is as it is in V8.

### 4.2 What stays

- The classification rules: feature × layer, with the public domain buckets widening to
  the dependents of `feature_dependencies`; use cases, data, presentation and `di/`;
  database queries through `database_query_features`, with `test/database/` and
  `test/integration/`; the database, `lib/core/`, `lib/main*` and any other `lib/` path
  widening to the full suite; test paths, with a golden-only test answered by its
  non-golden presentation surrogates; repository furniture (`inert_*`); the full-scope
  paths; documents and markdown.
- **The picture rule:** a committed image under `/goldens/` is not code. A plan of
  pictures only needs no static check and no host test, and its risk is `pixels`; CI's
  golden job is what compares them. A picture beside a code change does not narrow the
  plan.
- **The import closure** (`discover_test_consumers`) and the per-process memoized scans.
- **The fail-safe widening:** an empty change set, `--force-full`, a code change that
  selects no test, and any unrecognised path select the full suite.
- **`compress_test_targets`**, which turns the selected files into the fewest
  command-line targets that pull in no unselected test.
- **Risk values:** `full`, `targeted`, `pixels`, `docs`.
- **The CLI:** `--root`, `--impact-map`, `--json-output`, `--paths-file`,
  `--force-full`, `--nul`; with no `--json-output`, the plan goes to standard output.

## 5. The gate

- **Help.** `--changed`: select the host tests from the diff against `--base` (default
  `origin/master`) through `build_verification_plan.py`; unknown and high-risk paths
  promote the run to the full host suite; CI never uses it. `--fast`: the Deck and app
  test subset for a tight loop; CI never runs it; run the full gate before a commit.
- **Steps.** No Widgetbook step and no prompt-contract step, and no `NEEDS_WIDGETBOOK` or
  `HAS_PROMPT_CHANGES`. `--changed` reads `needs_static`, `needs_host_tests` and
  `local_test_targets`.
- **The plan summary** prints the risk, the number of selected test files and the
  reasons: with the three above, the six fields the gate reads.
- **The header** keeps the pass stamp's explanation and says in two sentences what the
  script's shape is for: it calls the Python checks directly, and it runs the steps in
  parallel and prints their output in a fixed order. The table of V7 timings and V7's
  history go.

## 6. Tests

- **Removed with their behaviour:** the shard policy test; the Widgetbook-only test; the
  two prompt-set plan tests; `PromptContractTest`; `tests/test_local_prompt_handoff.py`.
  The test of a new feature without tests keeps its fail-safe assertion and loses its
  Widgetbook one.
- **Rewritten to pin the local plan:** the tests that asserted the golden job now assert
  what a picture change selects locally: pictures only give a `pixels` plan with no
  static check and no host test; a picture beside a code change keeps the code's
  selection; a shared widget change still selects its tests. The repository furniture
  and documents-only tests assert the local plan, not a runner.
- **Written first, and seen failing on `master`'s code:**
  1. the plan JSON has exactly the eleven fields of D3;
  2. every plan field `dod_check.sh` reads (`read_plan_bool` and the `p['…']`
     expressions) is one of them;
  3. `dod_check.sh` has no Widgetbook step and no prompt-contract step, and the removed
     scripts are gone.
- **Docstrings** state what each test pins in V8's terms; the fixture's history of V7
  paths goes.
- The impact map fixture of `test_ci_tooling.py` drops `shard_weight_thresholds`.

## 7. Documents

- `.claude/skills/flutter-ship/references/ci.md`: the planner serves
  `dod_check.sh --changed` only; its CI-only outputs are gone (BE-D5).
- `docs/wbs_BE.md`:
  - BE-D5: done, with this spec and its plan;
  - BE-D6, new: the guard and the design-token hook without V7 (package 12b): the
    `memox-v7` registry and its tests go, the hook reads `memox-v8`'s rules, the guard's
    documents name `memox-v8` as their home; the `memox` (V6) registry stays;
  - BE-D7, new: the skills and documents without V7 (package 12c): Widgetbook in the
    Definition of Done and the feature-slice and design-system skills, the pointers to
    V7's `docs/wbs.md`, `--ruleset memox-v7`, the V7 baseline and blueprint, the
    project-documentation skill's installation record; BE-D3 is done inside it;
  - BE-D3: its next step points at BE-D7;
  - "Bước tiếp theo": BE-D6, then BE-D7, then BE-B5b when it is unblocked;
  - an update entry for 2026-09-26.
- `docs/_generated/` when the generator says so.

## 8. Verification

- Each task is test-first, and the gate passes after each one.
- `python3 -m unittest discover` over the CI tooling tests reports no skipped test.
- **The defect, end to end:** on the branch, before the gate is fixed,
  `dod_check.sh --changed --force` against `origin/master` fails with
  `selected Widgetbook gate unavailable` (the branch changes a verification script, so
  the plan is full); after the fix, the same command passes.
- The planner still answers as before for V8's tree: the classification tests that do
  not assert a removed field pass unchanged.

## 9. Out of scope

- The guard's `memox-v7` registry, its tests, and `.claude/hooks/check_design_tokens.py`
  (BE-D6, package 12b).
- The skills and documents that point at V7, and BE-D3 (BE-D7, package 12c).
- `CLAUDE.md`, `AGENTS.md`, and the provenance of rules migrated from V7 in `docs/`.
- `verify_invariants.py`, which checks V8's `schema.md` and is not V7's.
- A Widgetbook catalog for V8: a product decision, not tooling.

## 10. Risks and rollback

- **A classification rule removed by mistake.** D5 keeps every rule V8's tree uses, and
  the classification tests that assert no removed field run unchanged, so a rule that
  disappears fails them.
- **A caller of a removed field.** The gate is the planner's only caller (§2); the
  contract tests fail if it reads a field the plan no longer writes.
- **Rollback.** Revert the merge: the scripts, tests and documents come back as they
  were, and nothing else depends on them.
