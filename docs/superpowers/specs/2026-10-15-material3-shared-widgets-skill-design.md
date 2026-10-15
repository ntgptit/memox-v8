# Material 3 shared-widget skill, audit and gates — design

**Date:** 2026-10-15
**Status:** proposed, for the owner's review
**Input:** `M3_Shared_Widget_Spec_v2_6_1_Baseline_Candidate.md`, version 2.6.1,
marked REVIEW CANDIDATE — NOT APPROVED (owner upload, 2026-10-15).

## 1. Goal

Build one reusable project skill, `material3-shared-widgets`, with three
workflows: BUILD, AUDIT and FIX. Then use it on memox-v8:

1. inventory every shared widget and theme slot;
2. classify each spec rule against the project's approved decisions;
3. fix every confirmed violation that can be fixed on its own, with a
   regression test;
4. add the §9 gates that do not depend on a blocked decision.

**Success is:**

- the skill works without this conversation;
- every applicable component has a row in the compliance matrix;
- every fix has a test that failed before it;
- `dod_check.sh` and `run_goldens.sh` pass;
- no blocked or conflicting rule has been turned into code.

## 2. Authority

| Rank | Source | In this repo |
|---|---|---|
| 1 | Approved project decisions | ADRs (`docs/shared/decisions/`), `PRODUCT.md`, owner rulings recorded in merged plans and PRs, the screen detail files |
| 2 | Approved tokens and component contracts | `design/tokens.json` (ADR-022), `design/app_tokens.json`, `DESIGN.md` (generated), the `flutter-theme-design` checklists |
| 3 | Pinned Flutter SDK behaviour | `.fvmrc` → Flutter 3.47.5; source in `/root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/` |
| 4 | Spec v2.6.1 proposals | the canonical copy (§3) |
| 5 | Existing conventions | the code, where nothing above rules |

**Classification.** Each spec rule gets exactly one class:

- `ADOPT`
- `ALREADY_COMPLIANT`
- `CONFLICT`: keep the existing decision and record it
- `BLOCKED`: needs a named external decision
- `NOT_APPLICABLE`
- `SDK_CHECK`: verified against the 3.47.5 source before use

A `CONFLICT` is never implemented. It stays `KEEP_EXISTING` until the owner
signs a change.

## 3. Artifacts and where they live

| Artifact | Path | Why there |
|---|---|---|
| Canonical spec copy (verbatim) | `docs/shared/design/m3-shared-widget-spec-v2.6.1.md` | The upload sits outside the repo. One copy only, next to `memox-design-tokens.md`. It is never edited, and a new spec version is a new file. |
| Adoption ledger: DSD status, conflict ledger, inventory, compliance matrix, blocker register | `docs/shared/design/m3-adoption-ledger.md` | Project decisions are kept apart from the generic spec. This is the "external conflict ledger" of spec §11. |
| Skill | `.claude/skills/material3-shared-widgets/SKILL.md` + `references/` | Procedure only. It points to the spec and the ledger and holds no project values. |
| AST checker | `tools/m3_lint/` (Dart, `package:analyzer`) + fixtures + tests | Owner choice, 2026-10-15. Runs from `dod_check.sh`. |
| Runtime gates | `test/core/theme/` and `test/app/` | These are the existing homes of theme tests and production-root tests. |
| Rulings during execution | the plan's SDD ledger, then the PR | CLAUDE.md "Where knowledge lives". |

**No duplication.**
- `flutter-design-system` owns principles: tokens, l10n, a11y.
- `flutter-theme-design` owns the per-component checklist.
- `material3-shared-widgets` owns the spec-conformance procedure and its gates.
- The new skill links to the other two and does not restate their lists.

## 4. The skill

- **Frontmatter.**
  - `name: material3-shared-widgets`.
  - The description triggers on:
    - building or changing a shared widget, a component theme or a screen composition;
    - an M3 or design-system audit;
    - fixing a design-system violation.
- **SKILL.md** (short) holds:
  - the precedence table;
  - the 12 mandatory steps;
  - a router for which reference to read for BUILD, AUDIT and FIX;
  - the definition of done for each workflow;
  - anti-patterns.
- **references/**
  - `workflows.md`: the step-by-step BUILD, AUDIT and FIX procedures, the inventory fields and the finding template.
  - `flutter-m3-pitfalls.md`: SDK-specific traps, each checked against 3.47.5 with a file:line in the SDK. Examples:
    - a plain `AppBarTheme.backgroundColor` defeats scrolled-under;
    - `surfaceTint` falls back to `primary`;
    - `ListTile.textColor` is shared between title and subtitle;
    - the Drawer scrim is not a route barrier;
    - `showAdaptiveDialog` ignores `barrierColor` on iOS;
    - `SearchView` has its own 6 dp default.
  - `gates.md`: how to run each gate (AST checker, theme tests, production-root tests, goldens) and what each proves and does not prove.
- **scripts/:** none. The deterministic check is the repo's `tools/m3_lint`, which the skill calls, so there is no second copy.
- **Verification:**
  - the frontmatter parses;
  - every referenced path exists;
  - the skill is run on real components during the audit (§5), and any missing guidance is added.

## 5. Audit method

1. **Inventory.** Use `rg` and the analyzer to cover:
   - `lib/shared/widgets/`;
   - `lib/core/theme/` slots;
   - `ThemeExtension`s and tokens;
   - overlay adapters;
   - every direct Material or Cupertino component used outside `lib/shared`;
   - screen-level style overrides.

   Each component is one row with the fields the owner listed: component, source, category, variants, states, theme owner, consumers, spec mapping, compliance, severity, evidence and action. The work is split by category across Sonnet subagents. Each subagent reads the code and the 3.47.5 source, not the spec alone.
2. **Contract check.** Check colour, geometry, typography, interaction and visual consistency for each variant and state, against:
   - the spec row;
   - the approved token or decision that outranks it.
3. **High-risk checks.** Spec §5 of the request:
   - AppBar states and both icon slots;
   - overlays and barriers (dialog, sheet, drawer, raw routes, adaptive);
   - SearchBar and SearchView;
   - lists and selection;
   - inputs;
   - mobile layout.
4. **Evidence.** A component without an executed test or a golden is `UNVERIFIED`, not `PASS`.

## 6. Fix method

- Group the findings by root cause, then fix them in this order:
  1. a11y and interaction;
  2. theme, palette and barrier bypasses;
  3. tokens and component themes;
  4. states and variants;
  5. layout;
  6. hierarchy;
  7. optical issues.
- Each fix follows `superpowers:systematic-debugging` and TDD:
  - a failing test first;
  - the fix at the lowest shared owner;
  - check degrade, which covers every consumer;
  - check similar, which looks for the same mechanism elsewhere.
- **No new token** without an approved decision.
- **No visual change to an approved value.**
- **Goldens:**
  - changed goldens go through `run_goldens.sh --update`, then a golden-compare page, then a green rerun;
  - the owner reviews them before any merge.

## 7. Gates (spec §9), by status

| Gate | Plan |
|---|---|
| AST rules for overlay bypass, Cupertino/adaptive bans, `Scaffold.drawerScrimColor`, literal `barrierColor`/`modalBarrierColor`/`surfaceTintColor` outside theme owners, `ThemeData(platform:)`, `ColorScheme.fromSeed`/`colorSchemeSeed`, an AppBarTheme that sets `iconTheme`/`foregroundColor` without `actionsIconTheme`, AppBarTheme `backgroundColor` as a plain `Color` | ADOPT: `tools/m3_lint` with positive and negative fixtures, aliased imports and `Navigator.restorablePush` builders. `showRawDialog` only if it exists in 3.47.5. |
| Raw design values (`Colors.*`, `Color(0x…)`, `EdgeInsets` numbers, radius and font-size literals) | Reuse the existing guard rules and `tools/design/check.py`. The ledger maps each spec bullet to the rule that already enforces it, and records any real gap. |
| 45-role comparison against an independent fixture + separate `surfaceTint` assertion | ADOPT. The fixture is read from `design/tokens.json`, the approved export, not from `AppTheme`. It is observed through the production app root in light and dark. |
| Effective AppBar normal vs scrolled-under Material through the production root | ADOPT, on a real scrolling route. |
| Dialog and sheet `ModalRoute.barrierColor`; Drawer scrim | ADOPT for routes the app uses. Drawer only if a `Drawer` exists. |
| SearchBar and SearchView effective elevation, tint and divider | ADOPT if `SearchAnchor`/`SearchBar` is used, otherwise N/A. |
| Input state matrix (filled vs outlined, error+focus/hover, disabled strokes, suffix icon) | ADOPT for the variants the app has. |
| Contrast token pairs | Reuse `token_contrast_test.dart` and `design/contrast_exceptions.json`. The spec's 4.5:1 rule for `titleLarge` is a CONFLICT with PRODUCT.md (WCAG 2.2 AA), so the existing rule stays. |
| Android tap targets, labelled targets, text contrast guidelines | ADOPT on the production root for the main routes. |
| iOS runtime and tap-target lanes | NOT_APPLICABLE (ADR-001: iOS deferred). The static Cupertino/adaptive bans are still adopted, so iOS starts clean. |
| Goldens at 320 dp and at text scale 2.0 | CONFLICT, KEEP_EXISTING (owner 2026-09-30; owner 2026-10-15). New goldens use 360 dp, light and dark, plus one 600 dp board for window-size behaviour, plus long Vietnamese and Korean strings, all at scale 1.0. |
| High contrast | BLOCKED, DSD-32 (no product decision exists). |

## 8. Known decisions entering the audit (to verify, not assumed)

- **DSD-02, palette and scrim.**
  - Evidence so far:
    - `tokens.json` holds the approved light and dark roles (ADR-022);
    - `app_tokens.json` `opacityScrim` 0.32 shipped under the owner's 2026-10-14 ruling and was merged in pull request 281 of `ntgptit/memox-v8`.
  - Still to check:
    - all 45 roles are written out;
    - `scrim` is opaque;
    - the barrier is built once and installed in the dialog, sheet and drawer themes.
  - Status changes only on that evidence.
- **DSD-23, SDK pin.**
  - Evidence: `.fvmrc` pins 3.47.5.
  - Status: partially resolved.
  - Still `SDK_CHECK`, read from the 3.47.5 source:
    - the `year2023` choices;
    - the Slider track;
    - the TabBar divider;
    - `showRawDialog` availability.
- **DSD-32, high contrast.** BLOCKED; no decision in the repo.
- **DSD-27, `surfaceTint`.** The generated schemes do not declare it, so the SDK falls back to `primary`. This is a candidate ADOPT: generate `surfaceTint: transparent`. It does not conflict with `tokens.json`; the audit confirms whether anything visual changes.
- **Known CONFLICTs, already approved project values:**
  - text field radius 12 vs spec 4;
  - app bar title 20/600 vs `titleLarge`;
  - `bodySmall` 13/16;
  - button label weight 400;
  - icon button 48 vs 40;
  - `secondaryContainer` never a button background vs spec FilledTonalButton;
  - card `cardSurface`;
  - list title `titleSmall` vs `bodyLarge`;
  - text scale and 320 dp test matrix.

## 9. Tracking

- **Linear:** one new epic for this spec in the MemoX project, created after this spec is approved. One sub-issue per plan task, labelled `FE`.
- **Branch:** `claude/affectionate-wozniak-608syq`, with the `DEV-n` in commits and the PR.
- **PR:** opened only when the owner asks.

## 10. Out of scope

- New tokens or palette changes.
- Cupertino or iOS variants.
- Changes to approved typography or radii.
- Rebuilding Flutter components that the theme can configure.
- Unrelated refactors.
