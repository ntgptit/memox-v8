# MemoX V8 — The guard and the design-token hook without V7 (package 12b)

Status: approved 2026-09-27 (scope, the rules named after V7, the hook approach and
design sections 1–3 in conversation, then this spec) · Path: architectural

## 1. Intent

Build BE-D6 of [`docs/wbs_BE.md`](../../wbs_BE.md), widened by the owner on 2026-09-27:
the guard and the design-token hook keep nothing of V7. The guard is V8's second gate
after `flutter analyze`; its `memox-v8` ruleset was copied from V7's and still speaks
V7 — in its labels and ids, in the decisions it cites, and in the names some of its
rules look for, which V8 does not use, so those rules can never fire.

Success means:

- the `memox-v7` registry is gone and the `memox` (V6) registry stays;
- `memox-v8` names nothing of V7: every label, id, identifier, path, widget, file, test,
  decision and document in its rules, messages, comments, scopes, overrides and README
  exists in V8, or is gone; what it cites is V8's (§6);
- every rule that looked for a V7 name looks for V8's, and a probe shows it fires on the
  defect written in V8's terms and stays silent on V8's correct shape; the guard still
  reports no error on V8's tree;
- the hook applies exactly the guard's design-token rules, scopes and overrides to the
  file just edited, because it loads them through the guard's own loader; a test fails
  if it loads nothing or disagrees with the guard, and the gate runs that test;
- the guard's documents name `ntgptit/memox-v8` as its home;
- the gate passes.

## 2. Context (2026-09-27)

- `master` is at `b0e5549` (#92). The gate runs the guard as
  `guard/run.py check --project . --ruleset memox-v8` and its self-tests with pytest
  (`204 passed`).
- **Three MemoX registries** live under `code-verification-guard-v2/registries/projects/`:
  - `memox` (V6, a layer-first tree): 13 guard test files read it;
  - `memox-v7` (15 files): 4 guard test files read it (25 tests:
    `test_memox_v7_design_system_guard_rules.py`,
    `test_memox_v7_design_token_guard_rules.py`, `test_memox_v7_spacing_literal_rules.py`
    and two tests of `test_memox_false_positive_regressions.py`), and so does the hook;
    `test_max_lines_rule.py` names it in a docstring;
  - `memox-v8`: the gate's ruleset; 10 rule files with 63 rules, a README,
    `config/{overrides,profiles,scopes}.yaml` and `guard-manifest.yaml`. No guard test
    reads it. Pointing the four test files above at it gives `25 passed`.
- **What `memox-v8` still carries of V7** (measured 2026-09-27):
  - "MemoX V7 …" in 10 file headers, 10 registry names and the scopes document's name;
  - 13 ids `memox_v7.design_system.*`, beside V8's own
    `memox_v8.design_system.row_marks_centre_on_the_row`. ADR-011 left them for later;
    no baseline and no suppression comment uses any rule id;
  - rules whose patterns look for V7 identifiers (§5.1): four can never fire on V8, two
    have one dead alternative;
  - globs naming V7 paths (§5.2): three;
  - names V8 does not have in messages and comments (§5.3): V7's widgets and their
    files, four V7 tests and five other V7 files, and V7's measurements and incidents
    (timings, line counts, milestone ids such as M2.1b);
  - 77 references to V7's decisions and documents (§6), counted with the markers of
    §8.1: `AD-` ids (31: AD-01, AD-03, AD-05, AD-06, AD-08, AD-09, AD-11, AD-15, AD-18),
    A20.1 (13: its §8, §9 and phases) and its item ids (10: P1-01…P3-09), V7
    business-rule ids (7: BR-30, BR-57, BR-76), V7 milestone ids (14: M3.1, M4.3,
    M4.10, …) and V7's `docs/wbs.md` (2); beside them, 21 uses of the word V7 in labels
    and prose, two sections of V7's `CLAUDE.md`, and V7 history ("not carried into v7",
    "the 2026-08 theme-composition review").
- **The hook** `.claude/hooks/check_design_tokens.py` runs after every Edit and Write
  (`.claude/settings.json`, PostToolUse, `python`). It reads the six regex rules of
  `memox-v7/rules/memox-design-token-rules.yaml` directly and applies them to the edited
  file when the file matches a hand-written copy of the `ui_surfaces` scope. Three of the
  six rules use wider scopes in the guard: `no_raw_text_style` also covers `lib/app/`,
  `no_raw_duration` and `no_raw_stroke_width` also cover `lib/core/theme/`, so the hook
  misses what the guard reports there. On any exception it exits 0, so a missing rule
  file silences it without a word. It has no test; its docstring says the guard "runs 66
  rules" (85 today).
- **Measured for the hook** in the cloud container: under `python` 3.11 with PyYAML,
  `ConfigManager.load_ruleset_runtime(root, "memox-v8")` imports and loads in 0.23 s, and
  running the six design-token rules through `RuleFactory` on a one-file copy takes about
  2 ms per file. It reports `no_raw_text_style` in `lib/app/`, `no_raw_duration` in
  `lib/core/theme/`, `no_raw_color` in a presentation file, and nothing in `domain/` or
  in a `.g.dart` file.
- **Pointers outside the guard that break** when `memox-v7` goes or its ids change:
  `flutter-theme-design/SKILL.md:14` (the `memox_v7` ids),
  `flutter-theme-design/references/legacy-and-guards.md:142` (the path of `memox-v7`'s
  design-system rules), `flutter-state-riverpod/SKILL.md:198` and
  `flutter-architecture/references/analysis_options.yaml:22` (`--ruleset memox-v7`), and
  ADR-011 line 133 (the ids left for later).
- The guard's `AGENTS.md:15`: "the copy committed here, in `ntgptit/memox-v7`".

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | The guard (`memox-v7`, `memox-v8`, the guard tests, `AGENTS.md`), the hook and its tests, one gate step, and the pointers that break (§2) | Owner, 2026-09-27 (scope: V7 gone from the guard entirely) |
| D2 | Principle | Nothing in `memox-v8`, the hook or the guard's documents names V7. A name, path or reference either exists in V8 or goes | Owner, 2026-09-26 ("không còn muốn phụ thuộc vào V7 bất kì thứ gì nữa") |
| D3 | Registries | Delete `memox-v7`; keep `memox` (V6) and its tests | Owner, 2026-09-26 ("Chỉ bỏ V7") |
| D4 | Labels and ids | §4.2 | Design section 1 |
| D5 | Rules named after V7 | Retarget to V8's names, each with a probe; remove a rule whose invariant V8 does not hold (§5) | Owner, 2026-09-27 (option: V8 names, with tests) |
| D6 | References | Cite V8's authority where one exists (§6); otherwise state the reason in place. V7 history goes | Design section 1 |
| D7 | The hook | Loads `memox-v8` through the guard's loader and runs the guard's own rules on a one-file copy (§7) | Owner, 2026-09-27 (approach A of two) |
| D8 | Hook tests | `.claude/hooks/tests/`, run by a new gate step (§8.2) | Design section 2 |
| D9 | Guard tests | The V7 probes move to `memox-v8`; each retargeted rule gets a probe; a contract test pins that `memox-v8` carries no V7 marker (§8.1) | Design section 2 |
| D10 | Documents | §9, including the `--ruleset memox-v7` pointers, moved from BE-D7 to this package | Design section 3 |
| D11 | Verification | §10 | Design sections 2 and 3 |
| D12 | Branch and PR | Branch `claude/be-guard-without-v7` from `master` `b0e5549`; spec, plan, execution, final review, then a pull request, squash-merged on the local gate while CI is paused | Owner's standing choice |

## 4. The registry

### 4.1 `memox-v7` goes

The whole directory `registries/projects/memox-v7/` is deleted: 15 files, nothing else
reads it once §8.1 and §7 are done.

### 4.2 `memox-v8`'s identity

- "MemoX V7" becomes "MemoX V8" in the 10 file headers, the 10 registry names and the
  scopes document's name.
- The 13 ids `memox_v7.design_system.<name>` become `memox_v8.design_system.<name>`,
  the prefix V8's own design-system rule already uses. The names after the prefix stay.
- Two data-model ids carry a V7 name and change with their rule (§5.1):
  `memox.data_model.no_coalesce_parent_deck_id` →
  `memox.data_model.no_coalesce_parent_id`, and
  `memox.data_model.no_scheduler_generation_on_cards_table` →
  `memox.data_model.no_schedule_columns_on_card_table`.
- Nothing outside the files named in §2 and §9 refers to a rule id.

## 5. Rules and config named after V7

### 5.1 Patterns

| Rule | Looks for (V7) | Looks for (V8) | V8's authority |
|---|---|---|---|
| `no_coalesce_parent_deck_id` → `no_coalesce_parent_id` | `COALESCE(parent_deck_id, id)`, `parentDeckId` | `COALESCE(parent_id, id)`, `parentId`, outside comments: `srs_dao.dart` quotes the forbidden form in a doc comment | BR-DECK-003: the root is `deck.root_id` |
| `no_scheduler_generation_on_cards_table` → `no_schedule_columns_on_card_table` | `CREATE TABLE cards` with `scheduler_generation`, `due_at`, `ease_factor` | `CREATE TABLE card` with a column of `card_schedule`: `generation`, `learned_at`, `due_at`, `current_box`, `ease_factor`, `interval_days`, `repetitions`, `scheduler_type` | ADR-004; `schema.md` |
| `review_actions_from_supported_actions` | the four `ReviewAction` values on one line | the four `Sm2Action` values, or both `EightBoxAction` values, listed on one line in presentation code; an exhaustive `switch` that maps each action to a label spans lines and stays legal | ADR-003: "UI phải render nút từ `supportedActions` … không hardcode" |
| `review_kind_not_inferred` | `reviewKind = …` derived from a box or interval comparison | `kind` assigned from a comparison of `previousBox`, `nextBox`, `currentBox` or `intervalDays` | BR-SRS-015 |
| `widget_no_database_access` | `appDatabase.select(…)` among others | the `appDatabase` alternative goes; reading `databaseProvider` in widget code is the V8 form | ADR-010; ADR-011 D4 |
| `no_text_restyle` (design system) | `inputHintStyle.copyWith(…)` among others | `.inputHint.copyWith(…)` (`MxTextStyles.inputHint`) | the rule's own reason |

Each retargeted pattern is proven twice by a probe (§8.1): it reports the defect written
in V8's names, and it reports nothing on the correct V8 shape, including a comment that
quotes the defect. The exact expressions are fixed in the plan, where every one is run
against V8's tree first.

### 5.2 Globs

| Where | V7 glob | V8 |
|---|---|---|
| `memox_v7.design_system.no_raw_loading_indicator`, `exclude` | `**/card/presentation/widgets/sections/card_progress_panel_widget.dart` | goes: V8 has no such file and no determinate ring in feature code; the comment about its companion test goes with it |
| scope `provider_files`, `include` | `lib/**/controller/**/*.dart` | goes: V8's controllers are `presentation/controllers/*_controller.dart`, already matched by `lib/**/*_controller.dart` |
| scope `provider_files`, `include` | `lib/core/providers/**/*.dart` | goes: V8 declares providers in `di/` and `presentation/providers/`, already matched by `lib/**/*_provider.dart` and `lib/**/providers/**/*.dart` |

Globs that match nothing because V8 has not built the folder yet, or because the files
are generated and untracked (`integration_test/**`, `lib/l10n/generated/**`,
`lib/l10n/app_localizations*.dart`), are V8's and stay.

### 5.3 Names in messages and comments

| V7 name | V8 name |
|---|---|
| `MxActionButton`, `MxTextButton`, `mx_action_button.dart` | `MxButton` (`mx_button.dart`) |
| `MxContentShell` | `MxAppShell` owns the column, `MxAppBar` the bar and the back control |
| `MxLoadingState` | `MxSpinner` and the `MxSkeleton` family |
| `MxPillButton` (pick-one) | `MxOptionRow` and `MxSegmentedTray` |
| `showMxSheet`, `MxSheetHeader`, `mx_sheet.dart` | `showMxBottomSheet` and `MxBottomSheet` (`mx_bottom_sheet.dart`) |
| `architecture_boundary_test.dart` | `test/architecture/boundaries_test.dart` |
| `raw_progress_exclusions_test.dart` | goes with the exclusion it guarded (§5.2) |
| `app_stroke_test.dart` | `test/core/theme/foundations_test.dart`, which pins `AppStroke.hairline` at 1, Flutter's default border width |
| `text_restyle_alias_test.dart` | goes: V8 has no such test; the comment says what a regex cannot see |
| `error_screen_widget.dart`, `MobileFrameWidget` | the reason names what `lib/app/` builds in V8: the gallery and the placeholder screen |
| `cards.drift` with V7's timings | the reason stays (an ambiguous alternation backtracks on every newline); V7's file and timings go |
| `check_docs.sh` and M2.1b, `lib/core/theme/app_colors.dart`'s line counts, `study_mode_resolver.dart` | V7 incidents and measurements: the reason each illustrates stays, stated for V8, and the V7 example goes |

A message still names the V8 owner a feature should use, so the person who trips the rule
learns where to go.

### 5.4 The full pass

The lists above come from three scripted scans run on 2026-09-27: identifiers in each
rule's patterns that appear nowhere in V8's tree, include and exclude globs that match no
tracked file, and backticked `Mx`/`App` names and file names that V8 does not have. The
plan runs the scans over all 63 rules, the three config documents and the README, widened
to every class, widget and file name in their text, and records a disposition for every
finding: retargeted, removed, or V8's (a V8 path that is not built yet, a Flutter or
package name a rule forbids). A rule whose invariant V8 does not hold is removed and named
in the plan; none has been found.

## 6. References to V7's decisions

| V7 reference | What it stood for | In `memox-v8` |
|---|---|---|
| AD-01, `CLAUDE.md` "Layering" | domain knows no infrastructure, so a later backend stays cheap | ADR-010 (the layers); ADR-001 (local-only today) |
| AD-03, AD-05 | network, auth and secure storage deliberately absent | ADR-001 (local-only, no network); ADR-002 (`flutter_secure_storage` when a backend exists) |
| AD-06 | domain code does not read the ambient clock | the reason in place: `now` comes from the injected clock (`lib/core/clock/`), so behaviour is testable at a fixed instant |
| AD-08 (connection) | one site opens the database | `schema.md`: `PRAGMA foreign_keys = ON` in `beforeOpen` |
| AD-08, `CLAUDE.md` (privacy) | card content is private; not logged; media in the app's own directory | BR-CORE-001, BR-CORE-002, BR-CORE-003; ADR-002 |
| AD-09 | content survives every reset | ADR-004 |
| AD-11, BR-76 | the review kind is stored, not inferred | BR-SRS-015 |
| AD-15 | four widget buckets, one level deep | ADR-011 D8 |
| AD-18 | one exhaustive `StudyMode` switch beside the enum | the reason in place |
| BR-30 | buttons come from the scheduler's actions | ADR-003 |
| BR-57 | the root is a stored column | BR-DECK-003 |
| M4.3 | `:now` instead of `CURRENT_TIMESTAMP` | the reason in place (testability; one meaning of "due") |
| other milestone ids (M3.1, M4.10, …) | the V7 milestone that added a scope or profile setting | the reason in place |
| `CLAUDE.md` "UI discipline" | tokens and shared widgets in product UI | the UI kit and `docs/shared/ui/design-handoff/` (V8's `CLAUDE.md`, "UI source of truth") |
| A20.1 (§8, §9, phases, P-items) | V7's design-system audit | the reason in place, with the V8 owner (§5.3) |
| V7's `docs/wbs.md` ("Deferred and descoped") | why the guard carries the Riverpod checks | the reason in place: V8 has neither `custom_lint` nor `riverpod_lint` in `pubspec.yaml` |
| "not carried into v7", "the 2026-08 theme-composition review", counts of V7 call sites | V7 history | gone |

A message keeps its instruction and loses only the citation it cannot keep; it cites a V8
authority only when that authority says the same thing.

## 7. The hook

`.claude/hooks/check_design_tokens.py` keeps its place in `.claude/settings.json`, its
interpreter (`python`) and its exit-code contract; its inside changes:

1. **Payload to path.** Read the PostToolUse payload, take `tool_input.file_path` (or
   `tool_response.filePath`), and make it relative to the repository root. No path, a
   path outside the repository, or a file that no longer exists: exit 0.
2. **Rules.** Load `memox-v8` with `ConfigManager().load_ruleset_runtime(root,
   "memox-v8")` — the loader the gate's guard step uses — and keep the enabled rules whose
   id starts with `memox.design_token.`. Scopes, overrides and profile come resolved.
3. **Check.** Copy the file into a temporary directory at the same relative path and run
   `RuleFactory().create(rule).check(tmp)` for each rule. Include, exclude, line and file
   modes behave exactly as in the guard, because they are the guard's code.
4. **Report.** Findings print the rule id, `path:line`, the line and the message on
   stderr, and the hook exits 2. No finding: exit 0.
5. **Environment.** Any exception still exits 0: the hook is an accelerant and the gate
   is the check. §8.2 is what makes a silent hook visible.

The hand-written scope and its comment go; the docstring stops counting rules. Two
functions carry the logic so a test can call them without a payload or a file in `lib/`:
one turns a payload into a repository-relative path, and `findings_for(relative_path,
text)` returns the findings for a file's text.

## 8. Tests

### 8.1 The guard's tests

- `test_memox_v7_design_system_guard_rules.py`, `test_memox_v7_design_token_guard_rules.py`
  and `test_memox_v7_spacing_literal_rules.py` become `test_memox_v8_*.py`, read
  `memox-v8`, and use the new ids; their docstrings describe V8.
- `test_memox_false_positive_regressions.py` reads `memox-v8`; `test_max_lines_rule.py`'s
  docstring names `memox-v8`.
- **Probes for §5.1**, each with both directions: the four data-model rules in a new
  `test_memox_v8_data_model_guard_rules.py`, `widget_no_database_access` in
  `test_memox_v8_architecture_guard_rules.py`, and `no_text_restyle` beside the other
  design-system probes.
- **Contract test, written first:** no file of `memox-v8` contains `memox-v7`,
  `memox_v7` or the word `V7` in any case; `AD-` or `BR-` followed by digits (V8's
  business rules are `BR-<AREA>-NNN`); `A20.1` or an item id `P1-`…`P3-` with two
  digits; a V7 milestone id (`M` digits, a dot, digits); or `docs/wbs.md`.
- Tests that assert a rule fires are written before the rule changes and seen failing.

### 8.2 The hook's tests

`.claude/hooks/tests/test_check_design_tokens.py`, stdlib `unittest` like the CI tooling
tests, run by a new gate step "hook tests" (`$PY -m unittest discover` over
`.claude/hooks/tests`) in every mode:

- the hook loads exactly the enabled `memox.design_token.*` ids of `memox-v8`; a broken
  load fails here instead of silencing the hook;
- the hook and the guard agree on the same text: `TextStyle(` in `lib/app/`, a raw
  `Duration` and a raw stroke width in `lib/core/theme/`, a raw colour in a presentation
  file; and nothing in `domain/` or in a `.g.dart` file;
- the exit-code contract through a subprocess: a broken payload, and a file outside the
  repository, exit 0.

No test writes into `lib/`: the gate runs `flutter analyze` in parallel with the other
steps.

## 9. Documents and pointers

- `code-verification-guard-v2/AGENTS.md`: the source of truth is the copy committed in
  `ntgptit/memox-v8`.
- `registries/projects/memox-v8/rules/README.md`: §6 and §5.3 applied; the table of
  rulesets keeps `memox` (V6) and loses `memox-v7`.
- The pointers of §2: the two `--ruleset memox-v7` commands name `memox-v8`; the path in
  `legacy-and-guards.md` names `memox-v8`'s file; `flutter-theme-design/SKILL.md` names
  the `memox_v8` ids. Only those lines change: the rest of those files is BE-D7's.
- ADR-011, "Việc để lại cho sau": the 13 ids were renamed in BE-D6 (package 12b).
- `docs/wbs_BE.md`: BE-D6 done, with this spec, its plan and the tests as evidence;
  BE-D7 loses `--ruleset memox-v7`, which BE-D6 did; "Bước tiếp theo" and an update entry
  for 2026-09-27.
- `docs/_generated/` when the generator says so.

## 10. Verification

- Each task is test-first, and the gate passes after each one.
- **Equivalence:** the guard's findings on V8's tree, before and after the package, are
  the same set once ids are mapped through §4.2 and messages are ignored. A retargeted
  rule that finds a real violation stops the plan: fixing app code is the owner's call.
- The contract test (§8.1) passes, and a search of `code-verification-guard-v2/` and
  `.claude/hooks/` for `memox-v7`, `memox_v7` and `MemoX V7` finds nothing.
- The hook's tests pass, and an edit of an in-scope file costs under 0.5 s of hook time
  in the cloud container.

## 11. Out of scope

- The `memox` (V6) registry and its tests.
- The guard's engine (`code_verification_guard/`): nothing in it changes.
- `.claude/settings.json` and the interpreter it runs the hook with.
- The dated specs and plans in `docs/superpowers/` that name `memox_v7` ids: records of
  their day.
- Every other V7 trace in the skills and documents (BE-D7, package 12c).
- App code: a violation a retargeted rule finds goes to the owner (§10).

## 12. Risks and rollback

- **A retargeted rule that fires on legitimate V8 code.** Each probe asserts the silent
  side on V8's correct shape, and the guard runs on V8's whole tree in every gate.
- **A rule lost in the rename.** The equivalence check compares the full set of findings,
  and the contract and probe tests read the rules by id.
- **The hook tied to the guard's internals.** It uses the two entry points the guard's own
  tests use (`ConfigManager.load_ruleset_runtime`, `RuleFactory`); the hook tests fail if
  either changes shape.
- **Rollback.** Revert the merge: the registry, tests, hook and documents come back as
  they were.
