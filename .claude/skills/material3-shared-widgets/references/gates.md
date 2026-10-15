# Gates

The checks that enforce Material 3 conformance, what each proves, and what it
does not. The map of spec rules to checks, with its gaps, is ledger section 7
(`docs/shared/design/m3-adoption-ledger.md`); this file is the operating
manual for the checks themselves.

**Rule.** A gate is "run" only with its output in hand. Paste the command and
its tail (or the failing lines) into the report. A gate that was not run, or
whose path does not exist, is reported `UNVERIFIED`, never `PASS`. Never weaken a gate to get green: no `--no-verify`, no `// ignore`, no
lowered severity, no golden tolerance, no skipped or deleted test.

Setup for Flutter commands:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH
```

## tools/m3_lint

- **Command:** `dart run tools/m3_lint/m3_lint.dart` (about 80 s on `lib/`). Exit 1 on a hit, 2 on a malformed allowlist entry or an unresolved import. `dod_check.sh` runs it; its own tests are `test/tools/m3_lint_test.dart`.
- **Rules:**
  - `M3L00`: a stale allowlist entry, or one whose review date has passed (file, rule id, reason, owner and a strict `YYYY-MM-DD` review date; a malformed date exits 2). The allowlist is `tools/m3_lint/allowlist.json`: today two entries, both the one overlay adapter `mx_dialog.dart` (M3L01, M3L04).
  - `M3L01`: overlay route bypass (`DialogRoute`, `RawDialogRoute`, `ModalBottomSheetRoute`, `showGeneralDialog`, `showRawDialog`, a class that extends or implements `ModalRoute`, `PopupRoute` or one of the overlay routes).
  - `M3L02`: `showAdaptiveDialog`, Cupertino modals and controls, `.adaptive` constructors.
  - `M3L03`: `Scaffold.drawerScrimColor`.
  - `M3L04`: `barrierColor`, `modalBarrierColor`, `scrimColor`, `surfaceTintColor` arguments, with any value, on any callee outside the theme owners.
  - `M3L05`: `ThemeData(platform:)`.
  - `M3L06`: seed schemes (`ColorScheme.fromSeed`, `colorSchemeSeed`).
  - `M3L07`: `AppBarTheme` with `iconTheme` or `foregroundColor` and no `actionsIconTheme`.
  - `M3L08`: an `AppBarTheme` `backgroundColor` that is a plain `Color`.
- **Proves:** the syntax tree of `lib/` contains none of those constructs outside a dated, owned allowlist entry.
- **Does not prove:**
  - rendered behaviour (a clean lint says nothing about the painted barrier or AppBar colour, or that a sheet adapter covers the shell);
  - that an allowlisted file passes its other rules: the M3L04 exemption is per file for all four argument names, so the runtime barrier test is the compensating control;
  - anything about `scrim` composition, which is not a named-argument form;
  - nested `Theme` subtrees.
  - A text search is not this gate, and is not a proof of an AST rule.
- **Ledger rows:** section 7.1, spec 9.1 d to h (DSD-34, DSD-35, DSD-39).

## test/app/m3_production_theme_test.dart

- **Command:** `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/m3_production_theme_test.dart`
- **Proves:**
  - the 45 roles (and `surfaceTint` as a separate assertion) through the real `App()` for system and explicit light and dark;
  - the AppBar-style scrolled-under step and both icon slots on the production root;
  - Android tap targets and semantic labels on the four tabs.
- **Does not prove:**
  - dialog or sheet barriers (that is the next gate);
  - `textContrastGuideline` as a requirement (if run at all, it is a non-gating observation: ledger M3C-30);
  - high contrast (BLOCKED, DSD-32);
  - the spec's `surfaceTint = transparent` (CONFLICT M3C-11: the approved value is asserted).
- **Ledger rows:** section 7.2 rows 1, 3, 4, 10, 11, 13, 14.

## test/app/m3_overlay_barrier_test.dart

- **Command:** `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/app/m3_overlay_barrier_test.dart`
- **Proves:** `ModalRoute.barrierColor` of the dialog and the sheet actually pushed from the production helpers equals the one approved scrim at the approved alpha.
- **Does not prove:**
  - the Drawer scrim (no Drawer exists; it would be a `ColoredBox`, see pitfall 6);
  - overlays opened outside the helpers (that is `M3L01`);
  - that the overlay covers the shell: it reads `ModalRoute.barrierColor`, not the barrier's rect;
  - the sheet route's own `Material` (it asserts the inner `MxBottomSheet` Material only);
  - the iOS lane (NOT_APPLICABLE, ADR-001).
- **Ledger rows:** section 7.2 row 5; DSD-02, DSD-28, DSD-35.

## test/core/theme/token_contrast_test.dart

- **Command:** `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/token_contrast_test.dart`
- **Proves:** each token pair computed from `design/tokens.json` meets its floor (4.5:1 text, 3:1 non-text), and every pair below its floor is recorded in `design/contrast_exceptions.json` with a matching measurement.
- **Does not prove:**
  - a rendered widget uses the pair;
  - colours a widget derives itself: an alpha blend, a spinner ink chosen by a boolean, a glyph that reads `primary`, or `primary` as a non-text mark on a card ground (ledger M3F-02, M3F-03, M3F-04, M3C-49);
  - disabled alpha composites (not covered yet);
  - the spec's 4.5:1 for large text (CONFLICT M3C-13).
- **Ledger rows:** section 7.2 row 2 and 7.3 spec 9.2a; DSD-33. `textContrastGuideline` is supplementary and non-gating (M3C-30; pitfall 14).

## The guard

- **Command:** `python3 code-verification-guard-v2/guard/run.py check --project "$PWD" --ruleset memox-v8` (also part of `dod_check.sh`).
- **Rules:** `memox_v8.design_system.*` and `memox.design_token.*`, in `code-verification-guard-v2/registries/projects/memox-v8/rules/`.
- **Proves:** features and shared widgets contain none of the banned raw widgets, colours, spacing, radii and text styles that the rule files match.
- **Does not prove:**
  - anything outside rule scope: `ui_surfaces` excludes `lib/app` and `lib/core/theme`, and `no_raw_style_escape` does not scan `lib/shared/`;
  - symbol resolution (rules match text);
  - spec conformance (section 7 lists the gaps; `no_raw_duration` is a warning).
- **Ledger rows:** section 7.1, spec 9.1 a to c; DSD-07, DSD-13, DSD-14, DSD-17.

## tools/design/check.py

- **Command:** `python3 tools/design/check.py` (also part of `dod_check.sh`; its own tests: `python3 -m unittest discover -s tools/design/tests -p 'test_*.py'`).
- **Proves:** no removed theme name from `tools/design/removed_symbols.json` remains in `lib/`, `test/` or `integration_test/`; the theme-file list is closed; generated files equal what `design/tokens.json` generates.
- **Does not prove:** any spec rule. It checks no M3 behaviour.
- **Ledger rows:** section 7 header and 7.3 spec 9.0.

## The mechanical gate

- **Command:** `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It must print `mechanical gates passed`.
- **Proves:** format, analyze, generated code freshness, architecture, docs, the guard, `tools/design/check.py` and the full host suite. A subset runs through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file|dir>`.
- **Does not prove:** goldens, the owner's visual judgement, or any state it has no test for. It runs `m3_lint` and the full suite, which includes both Task 4 files.

## Goldens and golden-compare

- **Commands (Linux container only):**
  - compare: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`;
  - rewrite: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, and never `--update-goldens` on Windows;
  - review: the `golden-compare` skill builds the before, after and diff page the owner reads.
- **Environments:** 360 dp phone, light and dark, default text scale; plus one 600 dp board where the window size changes behaviour. No 320 dp and no 2.0x (CONFLICT M3C-12, `KEEP_EXISTING`).
- **Sequence:** `--update`, then the golden-compare page, then a green rerun without `--update`.
- **Proves:** pixels equal the committed pictures in the pinned container with real fonts.
- **Does not prove:**
  - keyboard, semantics, touch or state behaviour (a picture is not a test);
  - that a changed picture is right: only the owner's review of the page says so. Changed images on their own are not a review.
- **Ledger rows:** DSD-22; section 7.2 rows 15 to 19.

## What to put in the report

For each gate used: the command, the exit status, and the line that shows the
result (`mechanical gates passed`, the test count, or the failing rule ids).
For each gate not run: the reason, and the compliance cells it leaves
`UNVERIFIED`.
