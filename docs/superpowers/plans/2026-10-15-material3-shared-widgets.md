# Material 3 shared-widget skill, audit and gates — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `material3-shared-widgets` skill, use it to audit memox-v8's shared widgets against spec M3 v2.6.1, and leave AST and runtime gates that keep the result true.

**Architecture:**
- Documents hold decisions:
  - the canonical spec copy;
  - the adoption ledger.
- The skill holds procedure only.
- `tools/m3_lint` holds the symbol-aware static rules:
  - it uses `package:analyzer` resolved ASTs;
  - it has positive and negative fixtures.
- Runtime gates pump the production `MemoxApp` through the existing `pumpMemoxApp` harness.
- The audit (Task 5) produces the findings. The fix tasks are appended to this plan as Task 6+ by the controller, as a recorded ruling: a fix cannot be written before its finding exists.

**Tech Stack:**
- Flutter 3.47.5 (`.fvmrc`).
- Riverpod.
- `package:analyzer` 14.4.0: already in `pubspec.lock` as a transitive dependency; it becomes a dev dependency at the same version.
- `flutter_test`.
- The repo's Python design tooling.

**Spec:** `docs/superpowers/specs/2026-10-15-material3-shared-widgets-skill-design.md` (owner-approved 2026-10-15). Linear epic DEV-378.

## Global Constraints

- **Precedence:**
  1. approved project decisions;
  2. `design/tokens.json`, `design/app_tokens.json`, `DESIGN.md` and the flutter-theme-design contracts;
  3. pinned SDK 3.47.5 behaviour;
  4. spec v2.6.1;
  5. conventions.
- **Classes:** `ADOPT`, `ALREADY_COMPLIANT`, `CONFLICT` (with `KEEP_EXISTING`), `BLOCKED`, `NOT_APPLICABLE`, `SDK_CHECK`. A `CONFLICT` or `BLOCKED` rule is never implemented.
- **Forbidden edits:**
  - Never edit `design/tokens.json`.
  - Never add a token without an owner decision.
  - Never re-declare a name in `tools/design/removed_symbols.json`.
- **Never weaken a gate:** no `--no-verify`, no `// ignore`, no lowered severity, no golden tolerance, no skipped or deleted test.
- **Code style:** no `else`, early return or throw, English comments, no unneeded static classes or lambdas, sparse comments.
- **Goldens:**
  - only through `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update` (Linux);
  - then a golden-compare page;
  - then a green rerun without `--update`.
  - Environments: 360 dp phone, light and dark, default text scale; plus one 600 dp board where the window size changes behaviour.
  - No 320 dp and no 2.0× goldens (CONFLICT, KEEP_EXISTING).
- **iOS runtime lanes are NOT_APPLICABLE** (ADR-001). The static Cupertino/adaptive bans apply.
- **Commits:**
  - The message carries `DEV-378` or the task's sub-issue `DEV-n`.
  - It ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01CEzApqNd2VEQ4BUF354xgx`.
  - No model id anywhere else.
- **Gates:**
  - `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` must print `mechanical gates passed`.
  - Focused tests run through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>`.
  - `export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH`.

## Review Focus

1. **A rule that matches by text, not by symbol.**
   - Input: `import 'package:flutter/cupertino.dart' as c; c.showCupertinoDialog(...)`, or a local function also named `showGeneralDialog`.
   - Expected: the first is flagged and the second is not.
   - Pinned by fixtures in Task 3.
2. **The 45-role gate passing because it compares the theme with itself.**
   - Expected: the fixture comes from `design/tokens.json`, parsed in the test.
   - Pinned by a corrupted-scheme negative test in Task 4.
3. **The barrier test reading the theme field instead of the route.**
   - Expected: `ModalRoute.of(contentContext).barrierColor` on a dialog and a sheet opened by a real production action.
   - Pinned in Task 4.
4. **The allowlist hiding a real violation.**
   - Expected: an allowlist entry without `reason`/`owner`/`review`, or one naming a file with no matching violation, fails the run.
   - Pinned in Task 3.
5. **Generated, test and fixture files producing false positives.**
   - Expected: `*.g.dart`, `test/` and `tools/m3_lint/fixtures/` are not linted as production code.
   - Pinned in Task 3.

---

### Task 1: Canonical spec copy and adoption ledger (decisions and conflicts)

**Files:**
- Create: `docs/shared/design/m3-shared-widget-spec-v2.6.1.md`
- Create: `docs/shared/design/m3-adoption-ledger.md`

**Interfaces:**
- Produces: the ledger's section anchors, which later tasks append to.
  - `## 1. DSD registry`
  - `## 2. Conflict ledger`
  - `## 3. Inventory`, filled by Task 5.
  - `## 4. Compliance matrix`, filled by Task 5.
  - `## 5. Findings by root cause`, filled by Task 5.
  - `## 6. Blocker register`
  - `## 7. Gate map` (spec §9 → enforcing check)

- [ ] **Step 1: Copy the spec verbatim.**

  `cp /root/.claude/uploads/e4d2e90a-b2d4-517e-8781-d8f01c44ab5d/70a54315-M3_Shared_Widget_Spec_v2_6_1_Baseline_Candidate.md docs/shared/design/m3-shared-widget-spec-v2.6.1.md`

  Then check the copy: `cmp` of the two files must print nothing. No header is added; the file's own status line already says REVIEW CANDIDATE.

- [ ] **Step 2: Write the ledger header.**

  The header states, in English:
  - its purpose: spec §11's external conflict ledger for memox-v8;
  - the precedence (Global Constraints);
  - the classes;
  - that `CONFLICT` and `BLOCKED` entries are never implemented without the owner's signoff.

- [ ] **Step 3: Fill `## 1. DSD registry`.**

  The section is one table with one row per DSD-01 … DSD-39, and these columns:

  `| ID | Spec decision | Class | Project evidence (file:line / ADR / ruling) | Status in repo | Test or gate |`

  Rules:
  - **Before writing a class, read the evidence.** The leads below are known; verify each one in the file before using it:
    - **DSD-02:** RESOLVED by evidence.
      - `design/tokens.json` declares all 45 roles, and `scrim` is `#000000` in both themes;
      - `design/app_tokens.json:21` `opacityScrim` 0.32;
      - `lib/core/theme/app_component_themes.dart:42` builds `scrim` once;
      - `lib/core/theme/app_surface_themes.dart:174` dialog and `:208` sheet.
      - Check whether a Drawer exists (`rg -n "Drawer\(|drawer:" lib`). If none, DrawerTheme is `NOT_APPLICABLE`.
    - **DSD-23:** pin `.fvmrc` 3.47.5.
      - `showRawDialog` exists at `/root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/widgets/dialog.dart:69`.
      - The `year2023` and Slider items stay `SDK_CHECK` until read in the 3.47.5 source. Record the file:line read.
    - **DSD-27:** `CONFLICT`, `KEEP_EXISTING`.
      - `design/tokens.json` `surfaceTint` `#564bcb` ("Elevation tint. Mirrors `primary`.");
      - `lib/core/theme/generated/color_schemes.g.dart:52`, `:102`.
    - **DSD-32:** `BLOCKED`.
      - `rg -n "highContrast" lib docs PRODUCT.md DESIGN.md` finds no decision.
      - Owner role: Product+A11y.
    - **DSD-39:** iOS runtime `NOT_APPLICABLE` (ADR-001 iOS deferred). The static bans are `ADOPT`.
    - **DSD-10 / DSD-21 / DSD-22:**
      - the 320 dp and 2.0× parts are `CONFLICT` (`PRODUCT.md` › Accessibility, owner 2026-09-30; owner 2026-10-15);
      - the 360/600 dp parts are `ADOPT`.
    - **DSD-33:** `CONFLICT` for `titleLarge`: PRODUCT.md WCAG 2.2 AA allows 3:1 for large text. The rest is `ALREADY_COMPLIANT` through `test/core/theme/token_contrast_test.dart` and `design/contrast_exceptions.json`. Read both to confirm.
  - **Every other DSD:** classify it from the code in `lib/core/theme/` and `lib/shared/widgets/`. Where Task 5 must verify per component, write `pending Task 5`.

- [ ] **Step 4: Fill `## 2. Conflict ledger`.**

  The section uses spec §11's fields:

  `| conflictId | existingApprovedReference | proposedBaselineReference | comparison | resolution | owner | evidence | approval |`

  - IDs are `M3C-01`, `M3C-02`, ….
  - Resolution is `KEEP_EXISTING` unless the owner has signed a change.
  - Each comparison quotes both values exactly. Read them from `design/tokens.json`, `design/app_tokens.json`, `DESIGN.md` and the code.
  - At least these entries, each verified in the files:
    - text field radius: `radiusMd` 12 vs `shape.extraSmall` 4;
    - app bar title role: tokens 20/600 vs `titleLarge` 22/400;
    - `bodySmall`: 13/16 vs 12/16;
    - button label weight: 400 vs `labelLarge` w500;
    - icon button extent: `size-control` 48 vs `size.iconButtonVisual` 40;
    - `secondaryContainer` "Never a button background" vs FilledTonalButton and IconButton tonal;
    - card ground `cardSurface` vs `surface` outlined;
    - list title `titleSmall` vs `bodyLarge`;
    - `surfaceTint` `#564bcb` vs transparent;
    - test matrix: 360 dp, default scale vs 320 dp and 2.0×;
    - contrast: WCAG AA 3:1 large vs 4.5:1 `titleLarge`;
    - navigation pill: `secondaryContainer` vs the tokens.json note "NavigationBar has no indicator" (an internal project inconsistency: record it as `BLOCKED`, owner decision);
    - search bar: the tokens `shadow-raised` 8% note vs spec elevation 0 and transparent shadow. Read `searchBarTheme` in `lib/core/theme/app_surface_themes.dart` for the real value.

- [ ] **Step 5: Fill `## 6. Blocker register` and `## 7. Gate map`.**

  - **Blockers:** DSD-32 and every `BLOCKED` conflict, each with:
    - the decision needed;
    - the owner role;
    - what stays unimplemented.
  - **Gate map:** one row per spec §9.1 bullet and §9.2 row, with:
    - the enforcing check: an existing guard rule ID, `tools/design/check.py`, `token_contrast_test.dart`, `tools/m3_lint` rule `M3L0x` (Task 3), a Task 4 test, or `NOT_APPLICABLE`/`CONFLICT`;
    - its file path.
  - **Existing guard rule IDs to map**, from `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`:
    - `no_raw_widget`, `no_raw_sheet_route`, `no_raw_style_escape`, `no_raw_icon_color`, `no_raw_loading_indicator`, `no_raw_screen_chrome`;
    - `color_scheme_arguments_are_m3`, `color_scheme_reads_are_m3`;
    - `no_text_restyle`, `no_bare_font_weight`, `tint_reads_its_base`.
    - Read each rule's patterns before mapping it, and write a gap where none enforces a bullet.
  - Sections 3–5 get one line each: "Filled by Task 5."

- [ ] **Step 6: Verify and commit.**

  - Run `python3 tools/docs/check.py` and `python3 tools/design/check.py`; both must pass.
  - Commit: `docs(design): DEV-n canonical M3 spec v2.6.1 and its adoption ledger`.

### Task 2: The `material3-shared-widgets` skill

**Files:**
- Create: `.claude/skills/material3-shared-widgets/SKILL.md`
- Create: `.claude/skills/material3-shared-widgets/references/workflows.md`
- Create: `.claude/skills/material3-shared-widgets/references/flutter-m3-pitfalls.md`
- Create: `.claude/skills/material3-shared-widgets/references/gates.md`
- Modify: `.claude/skills/flutter-workflow/SKILL.md`: add one router row pointing M3 conformance work to the new skill.

**Interfaces:**
- Consumes:
  - `docs/shared/design/m3-shared-widget-spec-v2.6.1.md`;
  - `docs/shared/design/m3-adoption-ledger.md` (Task 1).
- Produces: the procedure Task 5 follows.
  - `references/workflows.md` sections `## BUILD`, `## AUDIT`, `## FIX`;
  - the inventory row fields;
  - the finding template.

- [ ] **Step 1: Write `SKILL.md`, at most about 120 lines.**

  Frontmatter, exactly these two keys:

  ```yaml
  ---
  name: material3-shared-widgets
  description: Material 3 conformance for this app's shared widgets and theme, against spec v2.6.1 and the project's approved decisions. Use when building or changing an Mx* shared widget, a component theme in lib/core/theme/, or a screen composition (BUILD); when auditing shared widgets, theme slots, tokens, component anatomy, states, accessibility or M3 conformance (AUDIT); when fixing a confirmed design-system violation or preventing its regression (FIX). Not for token values (tokens.json owns them) or per-component checklists (flutter-theme-design owns them).
  ---
  ```

  The body holds, in this order:
  1. **Sources and precedence.** The table:
     1. approved decisions: ADRs, PRODUCT.md, owner rulings, screen detail files;
     2. `design/tokens.json`, `design/app_tokens.json`, `DESIGN.md` and flutter-theme-design;
     3. Flutter SDK pinned in `.fvmrc`, with its source under `/root/.flutter-sdk/<version>/flutter/packages/flutter/lib/src/`;
     4. `docs/shared/design/m3-shared-widget-spec-v2.6.1.md`;
     5. conventions.

     Plus: "The ledger `docs/shared/design/m3-adoption-ledger.md` records every classification; read it before judging any rule."
  2. **The 12 mandatory steps**, numbered, verbatim from the request:
     1. read specs and decisions;
     2. inspect code;
     3. ownership and call sites;
     4. pinned SDK behaviour;
     5. classify;
     6. design the correction;
     7. regression tests first;
     8. the smallest shared-layer fix;
     9. targeted verification;
     10. check degrade and similar;
     11. broader gates;
     12. report evidence and blockers.
  3. **The router:**

     | Workflow | Read |
     |---|---|
     | BUILD | `references/workflows.md#build`, the spec section for the component, flutter-theme-design's reference for it |
     | AUDIT | `references/workflows.md#audit`, `references/flutter-m3-pitfalls.md`, the ledger |
     | FIX | `references/workflows.md#fix`, `references/flutter-m3-pitfalls.md`, `superpowers:systematic-debugging` |
     | Gates | `references/gates.md`, every time a check is claimed |
  4. **Definition of done** per workflow, three short checklists.
     - **BUILD:**
       - the component theme is in `lib/core/theme`;
       - the widget is in `lib/shared/widgets`;
       - every state has a test;
       - goldens in light and dark;
       - the ledger row is added;
       - `tools/m3_lint` is clean;
       - the dod gate passes.
     - **AUDIT:**
       - every component has an inventory row;
       - every cell is backed by an executed test, a golden, or code read and marked as such;
       - `UNVERIFIED` is never reported as `PASS`.
     - **FIX:**
       - the root cause stated as a mechanism;
       - a test that fails first;
       - the fix at the lowest shared owner;
       - check degrade and check similar written out;
       - goldens reviewed;
       - the ledger updated.
  5. **Anti-patterns**, at most 10 bullets:
     - treating a spec value as approved;
     - a per-screen patch over a shared defect;
     - a theme-field assertion as proof of rendered behaviour;
     - text search as proof of an AST rule;
     - adding a token silently;
     - a golden update without review;
     - 320 dp or 2.0× goldens (conflict);
     - `Colors.black54` or any guessed scrim;
     - an `.adaptive` constructor;
     - a raw `AppBar` theme without `actionsIconTheme`.
  6. **Related skills:** flutter-design-system for principles, flutter-theme-design for the component checklist, golden-compare, flutter-testing.

- [ ] **Step 2: Write `references/workflows.md`.**

  - **`## BUILD`, `## AUDIT`, `## FIX`:** each is a numbered procedure that applies the 12 steps to that workflow, with concrete commands:
    - `rg -n "<Symbol>\(" lib` for call sites;
    - `rg -n "class _\w+DefaultsM3" /root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/material/<file>.dart` for SDK defaults;
    - `dart run tools/m3_lint/m3_lint.dart`;
    - `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file>`.
  - **`## Inventory row`:** the field list.

    `Component | Source | Category | Variants | States | Theme owner | Consumers | Spec mapping | Compliance (PASS/FIXED/CONFLICT/BLOCKED/N/A/UNVERIFIED/FAIL) | Severity (Critical/Major/Minor) | Evidence | Action`
  - **`## Finding`:** the template. ID `M3F-nn`, then:
    - component and variant;
    - spec reference;
    - approved reference;
    - observed (file:line, executed test);
    - expected;
    - class;
    - severity;
    - root cause (mechanism);
    - the fix owner layer;
    - consumers;
    - similar sites.
  - **`## Severity`:** copied from spec §9.4. Blocked, Major and Minor are mapped to Critical/Major/Minor.

- [ ] **Step 3: Write `references/flutter-m3-pitfalls.md`.**

  Each pitfall is one entry: `### title`, then **SDK evidence** (`<file>.dart:<line>` in 3.47.5, read now), then **Consequence**, then **Do**.

  Cover each of these, and verify each line in the 3.47.5 source before writing it. Drop any that the source contradicts, and say so in the commit body.
  1. AppBar background `resolveAs` and `WidgetState.scrolledUnder`: `material/app_bar.dart`, around 881 and 918. A plain `Color` wins both states.
  2. AppBar actions icon precedence: `actionsIconTheme` → theme `actionsIconTheme` → `iconTheme` → theme `iconTheme`. `foregroundColor` recolours actions. Find the lines in `app_bar.dart`.
  3. `ColorScheme.surfaceTint` falls back to `primary` (`material/color_scheme.dart`). Here it is approved as `#564bcb` (ledger M3C).
  4. `showDialog` with no theme barrier falls back to `Colors.black54`; `DialogRoute` direct (`material/dialog.dart`).
  5. `showGeneralDialog` and `RawDialogRoute` take no theme barrier (`widgets/routes.dart`). `showRawDialog` exists (`widgets/dialog.dart:69`).
  6. The Drawer scrim is a `ColoredBox` in `_DrawerControllerState`, not a route barrier. `Scaffold.drawerScrimColor` takes precedence (`material/drawer.dart`, `material/scaffold.dart`).
  7. `showAdaptiveDialog` ignores `barrierColor` on iOS/macOS. `.adaptive` constructors pick Cupertino from `Theme.of(context).platform`.
  8. SearchBar defaults to elevation 6 with a `shadow` colour, and SearchView has its own 6 dp default (`material/search_anchor.dart`).
  9. `ListTile.textColor` is shared by title and subtitle, and `selectedTileColor` applies even when disabled (`material/list_tile.dart`).
  10. The bottom sheet M3 default `modalElevation` is 1 (`material/bottom_sheet.dart`).
  11. `InputDecorator` disabled border: filled `onSurface@0.38` vs outlined `@0.12`; error+hover uses `onErrorContainer` (`material/input_decorator.dart`).
  12. `LinearProgressIndicator` track is `secondaryContainer`, and the `year2023` default (`material/progress_indicator.dart`). Record the actual default in 3.47.5.
  13. `tester.view.viewInsets` takes physical pixels.
  14. `textContrastGuideline` treats ≥18 px or 14 px bold as large.

- [ ] **Step 4: Write `references/gates.md`.**

  - **One section per gate**, each giving:
    - its command or test path;
    - what it proves;
    - what it does not prove;
    - its ledger row.
  - **The gates:**
    - `tools/m3_lint` (Task 3);
    - `test/app/m3_production_theme_test.dart` and `test/app/m3_overlay_barrier_test.dart` (Task 4);
    - `test/core/theme/token_contrast_test.dart`;
    - the guard;
    - `tools/design/check.py`;
    - goldens with golden-compare.
  - **Rule:** a gate is "run" only with its output in hand.

- [ ] **Step 5: Add the router row in flutter-workflow.**

  - Read `.claude/skills/flutter-workflow/SKILL.md`.
  - Add one row in its skill-routing table, in that file's language and format:
    - task: Material 3 conformance of shared widgets or themes (build, audit, fix);
    - skill: `material3-shared-widgets`.
  - Change nothing else.

- [ ] **Step 6: Verify and commit.**

  - Run, and expect the frontmatter printed with `name: material3-shared-widgets` and the description:
    ```bash
    head -4 .claude/skills/material3-shared-widgets/SKILL.md
    ```
  - Run, and expect two `ok` lines:
    ```bash
    python3 - <<'EOF'
    import re,pathlib
    t=pathlib.Path('.claude/skills/material3-shared-widgets/SKILL.md').read_text()
    m=re.match(r'^---\nname: ([a-z0-9-]+)\ndescription: (.+?)\n---\n', t, re.S)
    assert m and m.group(1)=='material3-shared-widgets' and len(m.group(2))<1024, 'frontmatter'
    print('ok frontmatter')
    for p in re.findall(r'`((?:docs|references|tools|test|lib|\.claude)/[^`#\s]+)`', t):
        base = pathlib.Path('.claude/skills/material3-shared-widgets') if p.startswith('references') else pathlib.Path('.')
        assert (base/p).exists() or p.startswith(('tools/m3_lint','test/app/m3_')), p
    print('ok paths')
    EOF
    ```
  - Paths to the Task 3 and Task 4 outputs are allowed to be missing until then.
  - Commit: `docs(skill): DEV-n material3-shared-widgets skill with BUILD, AUDIT and FIX`.

### Task 3: `tools/m3_lint`, symbol-aware static rules

**Files:**
- Modify: `pubspec.yaml`, adding to `dev_dependencies` `analyzer: 14.4.0`: the version already resolved in `pubspec.lock`, owner-approved 2026-10-15. Then `flutter pub get`, and confirm with `git diff pubspec.lock` that no other version moved.
- Create: `tools/m3_lint/m3_lint.dart` (CLI)
- Create: `tools/m3_lint/m3_rules.dart` (rules and visitor)
- Create: `tools/m3_lint/allowlist.json`
- Create: `tools/m3_lint/fixtures/negative/*.dart`, `tools/m3_lint/fixtures/positive/*.dart`
- Create: `test/tools/m3_lint_test.dart`
- Modify: `.claude/skills/flutter-workflow/scripts/dod_check.sh`: one `plan m3_lint …` step beside `design_tokens`.

**Interfaces:**
- Produces:
  - `Future<List<M3Violation>> lintPaths(List<String> absolutePaths, {required String root, required List<AllowEntry> allowlist})`;
  - `class M3Violation { final String rule; final String path; final int line; final String message; }`;
  - `List<AllowEntry> loadAllowlist(String jsonPath)`;
  - CLI exit code 0 when clean, 1 on violations, 2 on a malformed allowlist.

**Rules.** The library is identified by `element.library?.uri` starting with `package:flutter/`:

| ID | Flags | Exempt owners (allowlist) |
|---|---|---|
| M3L01 | `showGeneralDialog`, `showRawDialog`, `DialogRoute(`, `RawDialogRoute(`, `ModalBottomSheetRoute(`; any app class that `extends`/`implements` `ModalRoute` or `PopupRoute`; a `Navigator.restorablePush` builder returning any of these | the Material overlay adapter, `lib/shared/widgets/mx_dialog.dart`, which must pass `barrierColor:` (M3L04 checks the value source) |
| M3L02 | `showAdaptiveDialog`, `showCupertinoDialog`, `showCupertinoModalPopup`, `showCupertinoSheet`, `CupertinoDialogRoute(`, `CupertinoModalPopupRoute(`, `CupertinoSheetRoute(`; any constructor named `adaptive` on a class from `package:flutter/src/material/`; `CupertinoSwitch`, `CupertinoCheckbox`, `CupertinoRadio`, `CupertinoSlider`, `CupertinoAlertDialog`, `CupertinoActivityIndicator` in `lib/` | none (iOS deferred, ADR-001) |
| M3L03 | a named argument `drawerScrimColor:` on `Scaffold` | none |
| M3L04 | named arguments `barrierColor:`, `modalBarrierColor:`, `scrimColor:`, `surfaceTintColor:` outside `lib/core/theme/` | `mx_dialog.dart` for `barrierColor:` only, and only when the value reads the theme. Record the reason in the allowlist. |
| M3L05 | `platform:` on `ThemeData(` or `ThemeData.copyWith(` | none |
| M3L06 | `ColorScheme.fromSeed`, `ColorScheme.fromImageProvider`, a `colorSchemeSeed:` argument | none |
| M3L07 | `AppBarTheme(`/`AppBarThemeData(`/`AppBar(` with `iconTheme:` or `foregroundColor:` but no `actionsIconTheme:` | none |
| M3L08 | `AppBarTheme(`/`AppBarThemeData(` `backgroundColor:` whose static type is not assignable to `WidgetStateColor` | none |

Scope:
- lint every `*.dart` under `lib/`, except `*.g.dart`;
- tests lint the fixture directories by path;
- `test/` is never linted.

Allowlist: JSON `[{ "file": "...", "rule": "M3L0x", "reason": "...", "owner": "...", "review": "YYYY-MM-DD" }]`.
- A missing field fails the run (exit 2).
- An entry that suppresses nothing fails the run (a stale exemption).

- [ ] **Step 1: Add the dependency.**

  - Edit `pubspec.yaml` `dev_dependencies`: add `analyzer: 14.4.0`, in alphabetical position.
  - Run `flutter pub get`.
  - Confirm `git diff pubspec.lock` shows only `dependency: transitive` → `"direct dev"` for analyzer.

- [ ] **Step 2: Write the negative fixtures.**

  Write one file per rule under `tools/m3_lint/fixtures/negative/`:
  - `m3l01_overlay_bypass.dart`
  - `m3l02_cupertino_adaptive.dart`
  - `m3l02_aliased_import.dart`
  - `m3l03_drawer_scrim.dart`
  - `m3l04_literal_barrier.dart`
  - `m3l05_theme_platform.dart`
  - `m3l06_seed_scheme.dart`
  - `m3l07_appbar_actions.dart`
  - `m3l08_appbar_plain_background.dart`
  - `m3l01_restorable_push.dart`

  Each fixture is valid Dart that compiles. Example, `m3l02_aliased_import.dart`:

  ```dart
  import 'package:flutter/cupertino.dart' as c;
  import 'package:flutter/material.dart';

  Future<void> openAliased(BuildContext context) =>
      c.showCupertinoDialog<void>(
        context: context,
        builder: (_) => const SizedBox(),
      );

  Widget adaptiveSwitch() => Switch.adaptive(value: true, onChanged: (_) {});
  ```

  Example, `m3l07_appbar_actions.dart`:

  ```dart
  import 'package:flutter/material.dart';

  final theme = AppBarThemeData(
    foregroundColor: const Color(0xFF000000),
    iconTheme: const IconThemeData(),
  );
  ```

- [ ] **Step 3: Write the positive fixtures.**

  Write `tools/m3_lint/fixtures/positive/`:
  - `material_dialog_ok.dart`: `showDialog` with no `barrierColor`, and `showModalBottomSheet` with no barrier override;
  - `local_shadow_ok.dart`: a local top-level function named `showGeneralDialog` defined in the fixture itself, and called;
  - `appbar_ok.dart`: an `AppBarThemeData` that sets `iconTheme`, `actionsIconTheme` and a `WidgetStateColor.resolveWith` background;
  - `cupertino_page_route_ok.dart`: `CupertinoPageRoute(builder: ...)`, which is allowed.

- [ ] **Step 4: Write the failing test.**

  ```dart
  // test/tools/m3_lint_test.dart
  import 'dart:io';

  import 'package:flutter_test/flutter_test.dart';

  import '../../tools/m3_lint/m3_rules.dart';

  String _abs(String p) => File(p).absolute.path;

  Future<List<M3Violation>> _lint(String dir) {
    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.absolute.path)
        .toList();
    return lintPaths(files, root: _abs('.'), allowlist: const []);
  }

  void main() {
    test('every negative fixture trips the rule its name carries', () async {
      final violations = await _lint('tools/m3_lint/fixtures/negative');
      final dir = Directory('tools/m3_lint/fixtures/negative');
      for (final file in dir.listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        final rule = name.substring(0, 5).toUpperCase();
        final hits = violations.where(
          (v) => v.path.endsWith(name) && v.rule == rule,
        );
        expect(hits, isNotEmpty, reason: '$name should trip $rule');
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('aliased Cupertino import and Switch.adaptive are both caught',
        () async {
      final violations = await _lint('tools/m3_lint/fixtures/negative');
      final aliased = violations
          .where((v) => v.path.endsWith('m3l02_aliased_import.dart'))
          .toList();
      expect(aliased.length, 2);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('positive fixtures are clean', () async {
      expect(await _lint('tools/m3_lint/fixtures/positive'), isEmpty);
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('an allowlist entry without a reason is rejected', () {
      final file = File('${Directory.systemTemp.createTempSync().path}/a.json')
        ..writeAsStringSync('[{"file":"lib/x.dart","rule":"M3L01"}]');
      expect(() => loadAllowlist(file.path), throwsFormatException);
    });

    test('an allowlist entry that suppresses nothing is reported', () async {
      final violations = await lintPaths(
        [_abs('tools/m3_lint/fixtures/positive/material_dialog_ok.dart')],
        root: _abs('.'),
        allowlist: [
          AllowEntry(
            file: 'tools/m3_lint/fixtures/positive/material_dialog_ok.dart',
            rule: 'M3L01',
            reason: 'r',
            owner: 'o',
            review: '2027-01-01',
          ),
        ],
      );
      expect(violations.single.rule, 'M3L00');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
  ```

  M3L00 is the stale-allowlist rule.

- [ ] **Step 5: Run it and see it fail.**

  `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/tools/m3_lint_test.dart` fails with `m3_rules.dart` not found.

- [ ] **Step 6: Implement `tools/m3_lint/m3_rules.dart`.**

  - **Resolution:** `AnalysisContextCollection(includedPaths: absolutePaths, resourceProvider: PhysicalResourceProvider.INSTANCE)`. Then, for each path, `context.currentSession.getResolvedUnit(path)` (`ResolvedUnitResult`).
  - **Visitor:** a `RecursiveAstVisitor<void>` over:
    - `MethodInvocation`, using `methodName.element`;
    - `InstanceCreationExpression`, using `constructorName.element` and its `enclosingElement` class;
    - `ClassDeclaration`, for `extends`/`implements` of `ModalRoute`/`PopupRoute`;
    - `NamedExpression`, for argument names inside the creation or invocation they belong to.
  - **Identity:** a symbol matches only if its element's `library?.uri.toString()` starts with `package:flutter/` and its `name` equals the listed name. A local function with the same name does not match.
  - **Line:** `unit.lineInfo.getLocation(node.offset).lineNumber`.
  - **Restorable push:** for `Navigator.restorablePush` / `restorablePushNamed`, read the builder argument's function body and apply the M3L01 checks to it. The plain visitor already reaches the body, so this needs no special case; verify it with the fixture.
  - **Allowlist:**
    - drop the violations matched by (`file` relative to `root`, `rule`);
    - for every entry that matched nothing, add `M3Violation(rule: 'M3L00', path: entry.file, line: 0, message: 'stale allowlist entry')`.
  - **`loadAllowlist`:** throws `FormatException` when any of `file`, `rule`, `reason`, `owner`, `review` is missing or empty.
  - **API:** verify every analyzer API name against `/root/.pub-cache/hosted/pub.dev/analyzer-14.4.0/lib/` before using it.
    - Confirmed to exist: `AnalysisContextCollection`, `getResolvedUnit`, `Element.library`, `LibraryElement.uri`, `Element.name`.
    - Prefer `element` over any deprecated `element2` name.

- [ ] **Step 7: Implement the CLI `tools/m3_lint/m3_lint.dart`.**

  - Collect `lib/**/*.dart`, minus `*.g.dart`.
  - Load `tools/m3_lint/allowlist.json`.
  - Print `path:line rule message` per violation.
  - Exit 0, 1 or 2 as in Interfaces.

- [ ] **Step 8: Run the tests until they pass.**

  `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/tools/m3_lint_test.dart` must PASS.

- [ ] **Step 9: Run on the real code and record the result.**

  Run `dart run tools/m3_lint/m3_lint.dart`. Expected: violations, if any, are real findings. Then handle each:
  - **`mx_dialog.dart` `showGeneralDialog` (M3L01):** add an allowlist entry, with owner `flutter-lead` and review date `2027-04-15`, only after reading that it passes `barrierColor:` from the theme. If it does not, leave it failing and report it: it is a Task 5 finding, not a reason to allowlist.
  - **Any other hit:** report it as a finding in the task report, with file:line. Do not allowlist it and do not change production code in this task. The controller turns it into a fix task.
  - **Hits still unfixed at commit time:** the CLI keeps failing, so add the dod step but keep the task's commit green. Record each hit in `allowlist.json` with `"owner": "pending-fix"` and `review` = today, and the fix task removes the entry. The stale-entry rule then forces the cleanup.

- [ ] **Step 10: Wire it into `dod_check.sh` and verify.**

  - Add next to the `design_tokens` step:
    ```bash
    plan m3_lint "Material 3 AST rules (tools/m3_lint)" "dart run tools/m3_lint/m3_lint.dart"
    ```
  - Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`; expect `mechanical gates passed`.
  - `flutter analyze` must be clean for `tools/m3_lint/fixtures/`. If the fixtures trip ordinary lints, fix the fixture; never add an `// ignore`.

- [ ] **Step 11: Commit.**

  `feat(tools): DEV-n m3_lint, symbol-aware Material 3 overlay and theme rules`

### Task 4: Production-root runtime gates

**Files:**
- Create: `test/app/m3_production_theme_test.dart`
- Create: `test/app/m3_overlay_barrier_test.dart`
- Create: `test/support/approved_palette.dart`: reads `design/tokens.json` into two `Map<String, Color>`s of the 45 roles.

**Interfaces:**
- Consumes:
  - `pumpMemoxApp(tester, env, {initialSettings, overrides})` and `libraryTest(...)` from `test/support/library_harness.dart`;
  - `SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark)`;
  - `env.decks.root('Name')`.
- Produces:
  - `Map<String, Color> approvedRoles(Brightness b)`;
  - `Color approvedRole(String name, Brightness b)`, which also serves `surfaceTint`;
  - `Map<String, Color> m3RoleColors(ColorScheme s)` (the 45 getters);
  - `void expectM3Roles(ColorScheme actual, Map<String, Color> approved)`.

- [ ] **Step 1: Write `test/support/approved_palette.dart`.**

  It parses `design/tokens.json` at test time with `dart:io` and `dart:convert`.
  - Walk `color` for objects that have `name` and `value: {light, dark}`.
  - Convert `#rrggbb` to `Color(0xFFrrggbb)`. An 8-digit hex is `#rrggbbaa` → `Color.fromARGB(aa, rr, gg, bb)`.
  - Return the 45 role names only, as listed in spec §9.3 `m3RoleColors`.
  - Throw if any of the 45 names is missing.

- [ ] **Step 2: Write `m3_production_theme_test.dart`, part 1: palette.**

  ```dart
  for (final scenario in <({ThemeChoice choice, Brightness os, Brightness expected})>[
    (choice: ThemeChoice.system, os: Brightness.light, expected: Brightness.light),
    (choice: ThemeChoice.system, os: Brightness.dark, expected: Brightness.dark),
    (choice: ThemeChoice.light, os: Brightness.dark, expected: Brightness.light),
    (choice: ThemeChoice.dark, os: Brightness.light, expected: Brightness.dark),
  ]) {
    libraryTest('production root: 45 roles '
        'choice=${scenario.choice.name} os=${scenario.os.name}', (tester, env) async {
      tester.platformDispatcher.platformBrightnessTestValue = scenario.os;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await SettingsRepositoryImpl(env.db).setTheme(theme: scenario.choice);
      await pumpMemoxApp(tester, env);
      final probe = find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.byType(Text),
      ).first;
      final theme = Theme.of(tester.element(probe));
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, scenario.expected);
      expectM3Roles(theme.colorScheme, approvedRoles(scenario.expected));
      expect(theme.colorScheme.surfaceTint,
          approvedRole('surfaceTint', scenario.expected),
          reason: 'surfaceTint must equal the approved token (ledger DSD-27)');
    });
  }
  ```

  Plus a negative self-test: `expectM3Roles` on `approvedScheme.copyWith(primary: const Color(0xFF123456))` must throw a `TestFailure` whose message names `primary`.

- [ ] **Step 3: Write `m3_production_theme_test.dart`, part 2: the app bar while content scrolls under it.**

  - Seed 40 root decks: `for (var i = 0; i < 40; i++) await env.decks.root('Deck $i');`.
  - Pump the app, then find the bar's own painted ground. Read `lib/shared/widgets/mx_app_shell.dart` and `mx_app_bar.dart` first to locate the widget that paints it:
    - a `Material` or `ColoredBox` owned by `MxAppShell`;
    - never a descendant button's.
  - At scroll offset 0, assert its colour equals `scheme.surface`.
  - `await tester.drag(find.byType(Scrollable).first, const Offset(0, -600)); await tester.pumpAndSettle();`
  - Assert the colour equals `scheme.surfaceContainer`.
  - Assert the icon slots at both offsets:
    - the leading/back glyph `IconTheme.of` → `scheme.onSurface`;
    - a trailing action glyph → `scheme.onSurfaceVariant`.
  - Run light and dark.
  - If the shell paints the bar without a `Material`, record "Material.elevation/shadow/tint N/A: custom bar" in the test name. Do not invent an elevation assertion.

- [ ] **Step 4: Write `m3_production_theme_test.dart`, part 3: Android a11y guidelines.**

  For each of the four tab routes, light theme:
  - pump the app;
  - tap the tab;
  - `await expectLater(tester, meetsGuideline(androidTapTargetGuideline));`
  - the same with `labeledTapTargetGuideline` and `textContrastGuideline`.

  Use the tab labels from `lookupAppLocalizations(const Locale('en'))`: `navLibrary`, plus the study, progress and settings keys. Read `lib/l10n/app_en.arb` for the exact keys.

- [ ] **Step 5: Write `m3_overlay_barrier_test.dart`.**

  - Seed one root deck `Words`, then pump the app.
  - **Sheet:**
    - tap `find.byTooltip(en.deckMoreActions('Words'))`, then `pumpAndSettle`;
    - `final route = ModalRoute.of(tester.element(find.byType(MxBottomSheet).first))!;`
    - `expect(route, isA<ModalBottomSheetRoute<Object?>>())`;
    - `expect(route.barrierColor, approvedRole('scrim', b).withValues(alpha: AppDimens.<opacityScrim source>))`. Read the generated `app_dimens.g.dart` for how to obtain `opacityScrim` from the theme extension: `Theme.of(ctx).extension<AppDimens>()!.opacityScrim`, verified in the file.
  - **Dialog:**
    - choose the delete action in the sheet; read `deck_action_sheet_test.dart` for the exact flow to reach `deck_delete_dialog_widget.dart`;
    - from the dialog content, `ModalRoute.of(...)!.barrierColor` must equal the same expected colour.
  - Light and dark.
  - Also assert the sheet's own `Material`: `elevation`, `surfaceTintColor` and `shadowColor` match the theme's `bottomSheetTheme` in `lib/core/theme/app_surface_themes.dart`. Read the values there; the spec's level0 vs the project's value is a ledger row, not an assumption.
  - **Drawer:** only if Task 1 found a `Drawer`. Otherwise add no test, and the ledger says `NOT_APPLICABLE`.

- [ ] **Step 6: Run the tests.**

  Run `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/m3_production_theme_test.dart test/app/m3_overlay_barrier_test.dart`.

  A failing assertion here is a **finding**, not a test to bend:
  - keep the test;
  - report the failure with its output;
  - let the controller decide whether the fix task comes before this task's commit. Ruling: the test is committed only when green. A failing gate is fixed in Task 6+ first, or carried as a red-then-green pair in the fix task.

- [ ] **Step 7: Commit.**

  `test(app): DEV-n production-root M3 gates: 45 roles, app bar states, barriers, a11y guidelines`

### Task 5: Audit with the skill (inventory, compliance matrix, findings)

**Files:**
- Modify: `docs/shared/design/m3-adoption-ledger.md` sections 3, 4 and 5.

**Interfaces:**
- Consumes:
  - the skill's AUDIT workflow (Task 2);
  - `tools/m3_lint` output (Task 3);
  - Task 4 results.
- Produces: findings `M3F-nn` grouped by root cause, which the controller turns into Task 6+.

- [ ] **Step 1: Read the inputs.**

  - `.claude/skills/material3-shared-widgets/SKILL.md` and `references/workflows.md#audit`.
  - The ledger, sections 1, 2 and 7.

- [ ] **Step 2: Build the inventory, section 3.**

  - **Discover:**
    - `ls lib/shared/widgets lib/core/theme`;
    - `rg -n "^class (Mx\w+|_?\w+Theme\w*)" lib/shared lib/core/theme`;
    - `rg -n "(Theme|ThemeData)\(" lib/features lib/app` for local overrides;
    - every raw Material/Cupertino component outside `lib/shared`:
      ```bash
      rg -n "\b(AppBar|SearchAnchor|SearchBar|TabBar|Drawer|NavigationDrawer|PopupMenuButton|DropdownMenu|Slider|ListTile|Chip|FilterChip|ChoiceChip|InputChip|TextField|TextFormField|Tooltip|SnackBar|LinearProgressIndicator|CircularProgressIndicator)\(" lib --glob '!lib/shared/**' --glob '!**/*.g.dart'
      ```
  - **Row:** one row per component, with the inventory fields from `references/workflows.md#inventory-row`.
  - **Consumers:** `rg -l "<Class>\(" lib | wc -l` plus a list. Shorten to the first 5 and a count when there are more.

- [ ] **Step 3: Fill the compliance matrix, section 4.**

  - **Rows:** one per component × variant × state that the app has.
  - **Columns:** colour, geometry, typography, interaction, consistency. Each cell is `PASS`, `FAIL`, `CONFLICT(M3C-nn)`, `BLOCKED`, `N/A` or `UNVERIFIED`, with evidence.
  - **Evidence** is one of:
    - an executed test (path and test name);
    - a golden (path);
    - SDK source (file:line);
    - code read (file:line), marked "read".
  - **Rule:** "read" alone is never `PASS` for a state that has a test-able behaviour. It is `UNVERIFIED` until a test runs.
  - **High-risk checks**, each with its own subsection:
    - app bar: shell ground, both icon slots, no raw AppBar theme;
    - overlays: dialog, sheet, drawer, raw and adaptive routes, `MxDialog` barrier source;
    - search: `MxSearchField` and any `SearchAnchor`/`SearchBar`;
    - lists and selection: `MxListRow` selected, disabled, disabled+selected; `MxOptionRow`; chips; icon buttons;
    - inputs: outlined vs filled, focus, error, error+hover, disabled strokes, error suffix icon, helper/label typography, against `app_surface_themes.dart` `inputDecorationTheme`;
    - mobile layout: form CTA placement on the card editor and the settings forms, keyboard reachability, bottom safe-area ownership, touch targets.

- [ ] **Step 4: Write the findings, section 5.**

  - Each `FAIL` becomes a finding `M3F-nn`, using the template in `references/workflows.md#finding`.
  - Group the findings by root cause.
  - Order them by the priority in spec §6:
    1. a11y and interaction;
    2. bypasses;
    3. tokens and themes;
    4. states and variants;
    5. layout;
    6. hierarchy;
    7. optical.
  - Each finding names:
    - the owning shared layer;
    - every consumer;
    - the test that will fail first;
    - its class: only `ADOPT` findings are fixable; `CONFLICT` and `BLOCKED` go to the blocker register.

- [ ] **Step 5: Skill feedback.**

  Where the AUDIT procedure was missing guidance, add it to `references/workflows.md` or `flutter-m3-pitfalls.md`, and list the additions in the task report.

- [ ] **Step 6: Verify and commit.**

  - Run `python3 tools/docs/check.py`; it must pass.
  - Commit: `docs(design): DEV-n M3 audit: inventory, compliance matrix and findings`.

### Task 6+: Fixes (appended by the controller after Task 5)

Written by the controller from the verified findings in `docs/shared/design/m3-adoption-ledger.md` section 5 and the owner rulings of 2026-10-15 recorded there.

**The ledger finding is the brief for its fix.** It gives:
- the mechanism (file:line);
- the expected value and its approved source;
- the consumers;
- the similar sites;
- the failing test to write first.

**Every fix task:**
- follows the skill's FIX workflow and `superpowers:systematic-debugging`;
- writes the failing test first and shows RED, then the fix at the named owner layer, then GREEN;
- runs the tests of every consumer listed in the finding (check degrade) and the similar-site query (check similar), and writes both lists in its report;
- sets the ledger finding to `FIXED` with its test path;
- ends with `dod_check.sh` green;
- does not regenerate goldens (Task Z does, once).

A golden-only failure caused by the intended visual change is expected and named in the report. Any other golden failure is a finding.

A pinned test that encodes a value the owner overturned on 2026-10-15 (M3F-02 ruling O2, M3F-03 SW-REV-001) is corrected to the new value. Cite the owner ruling in the test name or comment. That is a correction, not a weakening.

### Task 6: Theme foundation (ledger groups E, F; M3F-04, M3F-07, M3F-12, M3F-13, M3F-14, M3F-15)

**Files:**
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_component_themes.dart`
- their tests in `test/core/theme/`
- the feature tests whose glyph colour or density expectation changes

Do, in `_build` and the slots:

| Finding | Change |
|---|---|
| M3F-12 | `iconTheme` with colour `onSurfaceVariant` (owner 2026-10-15) and size `sizeIcon` |
| M3F-13 | `hoverColor` = `onSurface @ opacityHover` and `focusColor` = `onSurface @ opacityFocus`, both themes |
| M3F-14 | `visualDensity: VisualDensity.standard`, `materialTapTargetSize: MaterialTapTargetSize.padded` (never `platform:`) |
| M3F-15 | the switch thumb stays `onPrimary` in every on state |
| M3F-04 | the `chipTheme` icon colour reads `t.accent` |
| M3F-07 | `iconButtonTheme` shape is `MxFocusRingBorder(base: CircleBorder(), ring, gap: strokeFocusGap)` on focus |

For M3F-07, check that the ring is not clipped in `MxAppBar`, rows and `MxChipRow` (similar sites in the finding).

### Task 7: Derived colours and the contrast gate (group B; M3F-02, M3F-03)

**Files:**
- `lib/shared/widgets/mx_spinner.dart`
- `lib/shared/widgets/mx_button.dart`
- `lib/shared/widgets/mx_filter_chip.dart`
- `test/core/theme/token_contrast_test.dart`
- the widget tests

Do:
- **M3F-02:** `MxSpinner` takes an optional `color`, replacing `isOnFill` (owner 2026-10-15). Remove `isOnFill` if no caller remains, and update every caller. `MxButton` passes each tone's own foreground.
- **M3F-03:** the resting count drops the 0.6 alpha and uses `onSurfaceVariant`, with hierarchy carried by `labelSmall` (owner 2026-10-15).
- **Gate:** add the rendered spinner pairs and the chip-count pair, light and dark, to the contrast gate.

### Task 8: Focus indicators (group C; M3F-05, M3F-06)

**Files:**
- `lib/shared/widgets/mx_option_row.dart`
- `lib/shared/widgets/mx_breadcrumb.dart`
- `lib/shared/widgets/mx_bottom_nav.dart`, plus `mx_nav_rail.dart` if it shares `MxNavItem`
- `lib/shared/widgets/mx_stepper.dart`
- their tests

Do:
- **M3F-05:** `MxOptionRow` and `MxBreadcrumb` compose `MxRowInk`, which draws the ring. The nav cell draws a pill-shaped ring with the same token (`primary`, `strokeFocus`, M3C-49).
- **M3F-06:** the stepper value becomes focusable, with the shared ring.

No new shared primitive. If one seems needed, stop and report: it is an owner question.

### Task 9: Semantics parity (group D; M3F-08, M3F-09, M3F-10, M3F-11)

**Files:**
- `lib/shared/widgets/mx_app_bar.dart`
- `lib/shared/widgets/mx_bottom_nav.dart`
- `lib/shared/widgets/mx_nav_rail.dart`
- `lib/shared/widgets/mx_row_ink.dart`
- `lib/features/transfer/.../import_source_option_widget.dart` (find it)
- `lib/shared/widgets/mx_fab.dart`
- their tests

Do:
- **M3F-08:** title `namesRoute: true`.
- **M3F-09:** tab role and the "i of n" position (`SemanticsRole.tab`; index and count passed in).
- **M3F-10:** `MxRowInk` takes `isSelected` and sets it on its own node (owner 2026-10-15). `ImportSourceOption` uses it.
- **M3F-11:** `MxFab` sets `tooltip` equal to its semantic label, with no duplicate node.

### Task 10: Input decorator states (group G; M3F-16)

**Files:**
- `lib/core/theme/app_surface_themes.dart` (`inputDecorationTheme`)
- `lib/shared/widgets/mx_text_field.dart`
- their tests

Do:
- Let the SDK resolver run (`WidgetStateInputBorder`, or pass the error to the decorator), so that error+hovered gives `onErrorContainer` at width 1.
- The suffix glyph is `error` in error, and `onErrorContainer` when hovered.
- Keep every other state as today. Pin each state in a test.
- Check `MxCodeField` (a suspect in the finding) and report it.

### Task 11: Row disabled and busy, layout constants (groups H, I; M3F-17, M3F-18, M3F-19)

**Files:**
- `lib/shared/widgets/mx_list_row.dart`
- `lib/shared/widgets/mx_selectable_card_row.dart`
- `lib/shared/widgets/mx_settings_row.dart`
- `lib/shared/widgets/mx_study_top_bar.dart`
- the two feature scroll widgets named in M3F-19
- their tests

Do:
- **M3F-17:** a disabled or busy row blocks hit tests and taps on its tap target and trailing controls, and its semantics say enabled=false (owner 2026-10-15). Then check `MxOptionRow` and `MxActionSheetCommandRow`, the similar sites.
- **M3F-18:** the study bar reads `sizeTrack`.
- **M3F-19:** both bodies use `context.screenMargin`.

### Task Z: Documentation sync, goldens, final gates

**Files:**
- Modify: `DESIGN.md`, only through `python3 tools/design/generate.py` when tokens or app_tokens change, or prose where a shared widget's described behaviour changed.
- Modify: the screen detail files in `docs/shared/ui/screen-handoff/` whose widgets changed.
- Modify: `docs/shared/design/m3-adoption-ledger.md`: final statuses.

- [ ] **Step 1: Run the full gates.**

  - `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → `mechanical gates passed`.
  - `dart run tools/m3_lint/m3_lint.dart` → exit 0.

- [ ] **Step 2: Regenerate and review the goldens.**

  1. Run `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`.
  2. Build the golden-compare page(s) against the merge-base, using the golden-compare skill.
  3. Rerun without `--update`; it must be green.
  4. Grep the log for `overflowed` and `Exception`; both counts must be 0.

- [ ] **Step 3: Write the ledger's final counts.**

  Count Pass / Fixed / Conflict / Blocked / N/A / Unverified, and give the blocker register the decision each blocker needs.

- [ ] **Step 4: Commit.**

  `docs(design): DEV-n M3 ledger final state and goldens`
