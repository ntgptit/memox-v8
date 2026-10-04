# SP3a — Design-system foundation

Status: draft for the owner's review · Date: 2026-10-04 · Branch: `ccr-841d461f-jofe0s` (from
`master` at `37919b8`, PR #197 merged)

Sub-project 3a of the UI rebuild. SP2 removed the old UI; DESIGN.md is the only visual source.
This sub-project builds, from DESIGN.md and nothing else, the layers every screen will stand on:
tokens, the Material 3 colour scheme and themes, a primitive layer and the generic `Mx*`
components. It builds no screen and no app shell.

## 1. Context

| Sub-project | Scope |
|---|---|
| SP2 — Remove legacy UI | Done (PR #197). |
| **SP3a — Design-system foundation** (this spec) | DESIGN.md (45 M3 roles, mapping tables) → tokens → Material 3 theme → primitives → generic `Mx*`. |
| SP3b — App shell + SCR-DECK-001 | The shell from NAVIGATION.md, the Library's feature components, one vertical slice with screen goldens. |
| SP3c — The other 33 screens | Batches by domain, after SP3b's sign-off. |

**Sources, in order** (ADR-021): BR, FN, UC → DESIGN.md → this spec → code. Code implements
DESIGN.md; DESIGN.md is never derived from code. The legacy UI (tag `legacy-ui-v8-goldens`) is
not a source. Impeccable is a reviewer, never a source.

**Starting state** (SP2 §10): no theme, tokens or `Mx*` in code; `MemoxApp` uses a bare
`ThemeData(useMaterial3: true)`; the placeholder shell lives in `lib/app/placeholder/`; the
guard's design-system and token rules wait for the new code, three of them under
`targets_pending`.

## 2. Owner rulings (2026-10-04)

- **D1 — Hybrid architecture.** DESIGN.md → tokens → Material 3 `ThemeData` → primitive layer →
  `Mx*` → screens.
  - Material and the theme own the 45 colour roles, light and dark, the typography foundation,
    the focus, pressed and disabled state machinery, base semantics and Material interaction
    behaviour.
  - A `ThemeExtension` holds only MemoX-specific values that no Material 3 role carries
    directly (see D10).
  - `Mx*` is the public design-system API. The name is kept; no legacy implementation is
    reused or read.
- **D2 — Generic components only.** SP3a builds components whose meaning is generic and
  cross-feature. A component with a feature or domain meaning is built by SP3b or later with
  the screen that needs it, and is named after its feature or domain (the `Mx` prefix is not
  required there). No component quota: the list in §6 comes from the semantic contract and
  reuse, not from a target count.
- **D3 — Lowest reusable layer.** A problem that several layers could fix is fixed in the
  lowest one: token → theme → primitive → `Mx` → feature component → screen. A screen is
  never patched for a root cause in the shared foundation.
- **D4 — All 45 Material 3 colour roles**, light and dark.
  - Not allowed: a raw `Color(0x…)` or a hex literal written by hand in production code; a
    deprecated Material 2 role as foundation; `if (isDark)` or any brightness branch in a
    component to pick a colour.
  - Screens and components read only semantic roles and tokens.
- **D5 — The `Mx` contract** (§6.1).
- **D6 — Verification** (§8): DESIGN.md ↔ code parity, so a drift fails a test, plus the
  checks listed there.
- **D7 — Impeccable** reviews and refines the foundation and the components against
  DESIGN.md. A proposal for a new token, colour role or shared component updates DESIGN.md
  and is reviewed by the owner before anything implements it.
- **D8 — Boundary.** SP3a does not build the app shell, SCR-DECK-001, the Library's feature
  components (the ~12 the screen needs beyond §6), any FN, screen state or navigation, or any
  screen golden.
- **D9 — Missing roles derived by rule** (approval 2026-10-04). The 17 roles DESIGN.md lacks
  get values from written derivation rules (§4.2), and the owner approves the resulting table
  in DESIGN.md before any code.
- **D11 — Component goldens** (approval 2026-10-04). `check.py` accepts
  `mx_<component>__<state>__<variant>.png` for a component DESIGN.md defines (§8.3).
- **D12 — UI debt register** (approval 2026-10-04). The register of known UI debt is §11 of
  this spec; CLAUDE.md points at it. The UI-base register (§9 of the 2026-09-23 spec) stays as
  history of the removed UI.

### 2.1 Decisions this spec proposes (confirm at review)

- **D10 — Where a value lives.**
  - A value that is the same in both themes and has no Material slot (spacing, radius, stroke,
    opacity, durations, sizes, icon sizes, breakpoints) is a `static const` on an
    `abstract final class` (`AppSpacing`, `AppRadius`, …).
  - A value that differs between themes and has no Material role (MemoX semantic colours,
    derived inks and tints, shadows, scrim and glass effects) is a `ThemeExtension`.
  - Reason: the guard's messages and the `flutter-design-system` skill already name
    `AppSpacing`, `AppRadius`, `AppDurations`, `AppStroke` and `AppOpacity`. A
    theme-invariant value in a `ThemeExtension` would need a `BuildContext` and a `lerp` for
    nothing.
  - D4's ban on brightness branches is what the `ThemeExtension` serves: a component never
    asks which theme it is in.
- **D13 — DESIGN.md is compiled into code, not copied** (§5).
  - A generator in `tools/design/` reads DESIGN.md and writes one committed Dart file of
    values. It is the only place a colour literal exists in `lib/`.
  - The gate fails when that file is stale.
  - This is how D4 (no hand-written hex) and D6 (drift fails) hold together.
- **D14 — Navigation components move to SP3b with the shell.**
  - `MxAppShell`, `MxBottomNav` and `MxNavRail` have one consumer, the app shell, which D8
    leaves to SP3b. They are built there.
  - `MxAppBar` and `MxScreenScroll` serve every screen and stay here.
- **D15 — `MasteryRamp` moves to SP3b** with the mastery donut and progress bar, its only
  consumers.
- **D16 — A primitive layer folder.**
  - Primitives live in `lib/shared/primitives/`. They are not part of the public API: an
    architecture test forbids `lib/features/**` and `lib/app/**` from importing them.
  - ADR-011, which lists the contents of `shared/`, gets a one-line amendment naming the
    folder.
- **D17 — Text scale and direction.**
  - Text is never clamped. Components are tested at text scale 1.0 and 1.3, the large
    setting Android offers. PRODUCT.md (2026-09-30) makes larger scales a non-goal, so no
    work goes into them.
  - Both locales (en, vi) are LTR. Components use directional insets and alignment, but no
    RTL test or golden is written.

## 3. Scope

**In scope**
- DESIGN.md: the Material 3 role mapping (45 roles, light and dark), the MemoX semantic and
  derived colour tables, the type-slot mapping and the machine-readable token tables (§4).
- `tools/design/`: the generator, its `--check` mode and its tests (§5).
- `lib/core/theme/`: tokens, colour schemes, `ThemeExtension`s, typography, the two themes,
  the button-style helper and the `BuildContext` accessors (§5).
- `lib/shared/primitives/` and the generic `Mx*` in `lib/shared/widgets/` (§6).
- `MemoxApp` uses the new themes. The placeholder shell is otherwise untouched.
- Tests, component goldens, the `check.py` golden rule, guard and architecture updates, the
  Impeccable review, and the repo rules and skills that name the old layout (§7–§9).

**Out of scope**
- The app shell, `MxAppShell`, `MxBottomNav`, `MxNavRail` and the placeholder's replacement
  (SP3b).
- The Library's feature components and `MasteryRamp` (SP3b).
- Every screen, screen state, FN, navigation change and screen golden (SP3b, SP3c).
- Pruning unused ARB keys (SP3, screen by screen).
- New dependencies. None are needed: Plus Jakarta Sans is already bundled as a variable font.

## 4. DESIGN.md first (hard gate)

Task 1 changes DESIGN.md and nothing else. Impeccable critiques the result against the rest of
DESIGN.md. The owner approves the tables before any code is written, the same way the SP2
migration matrix was approved.

### 4.1 Tables added to DESIGN.md

All tables are Markdown tables in the body under fixed headings, so the generator can read
them.
- **Material 3 colour roles.** One row per role: `role` (Flutter name), light hex, dark hex,
  source (`stated` or `derived: <rule>`), and the grounds it must contrast with.
  - All 45 roles appear: the 26 standard roles and the 19 add-on roles of the guard's
    allowlist.
  - `surfaceTint` and the deprecated roles do not appear.
- **MemoX semantic colours.** mastery, on-mastery, success, warning, on-warning, warning-ink,
  error-fill, on-error-fill, status-new, status-learning, status-reviewing, status-mastered,
  streak; light and dark.
- **Derived colours.** Primary ink, ghost border, outline edge, status inks, danger ink and
  the soft tints. Each row has its rule (for example "primary lerped toward on-surface 25 %
  light / 45 % dark") and the resulting hex. The generator recomputes the hex and fails if the
  stated value differs.
- **Type slots.** Each of the 15 Material 3 `TextTheme` slots maps to one DESIGN.md role
  (stat, display, headline, title, body-large, body, caption, button-label, section-label).
  Every slot is set, so no Material widget falls back to default metrics.
- **Tokens.** Spacing and radius already sit in the frontmatter. New tables hold the values
  DESIGN.md now states only in prose:
  - opacity: disabled 0.38, pressed 0.12, muted 0.7;
  - stroke: hairline 1, focus 2, focus offset 2, control 2, selected ring 6;
  - durations: toggle 160, standard 200, scrim fade 220, sheet 260, spinner cycle 800,
    skeleton pulse 1400, snackbar 4000 and 8000 with Undo, answer settle 400;
  - sizes: touch target 48, button 48/36/32/28, field 52, app bar 56, bottom bar 64 in an 80
    block, rail 80, FAB 52, icon button ink 36, icon 16/20/24;
  - breakpoints: rail at 600, content max 720;
  - shadows: whisper, chrome, overlay and FAB, light and dark;
  - effects: scrim 45 %, glass 84 % with blur 18.
- The frontmatter `colors` block stays the light theme. The generator fails if it differs from
  the light column of the role or semantic tables. `.impeccable/design.json` `colorMeta` must
  match both columns too.

### 4.2 Derivation rules for the 17 missing roles

The rules work from values DESIGN.md already states. Every result is listed in the table with
its contrast ratio.
- `onSecondary`, `onTertiary`, `onError`: white when it holds 4.5:1 on the fill, otherwise the
  light theme's `on-surface` (#0F1638). Measured on 2026-10-04:
  - light: secondary gets #0F1638 (4.65:1), tertiary gets #0F1638 (4.77:1), error gets white
    (5.86:1);
  - dark: all three get #0F1638 (7.72, 7.92 and 8.14:1). White fails on every dark fill.
- `primaryFixed`, `primaryFixedDim`, `onPrimaryFixed`, `onPrimaryFixedVariant`, and the same
  four for secondary and tertiary:
  - Material 3 defines the fixed roles as identical in both themes.
  - `xFixed` = the light `xContainer`; `onXFixed` = the light `onXContainer`.
  - `xFixedDim` = `xFixed` lerped toward `x` by 30 %; `onXFixedVariant` = `onXFixed` lerped
    toward `x` by 30 %, held at 4.5:1 on `xFixed` and `xFixedDim`.
- `surfaceDim`: in light, `surface` stepped one surface-container step darker (the distance
  between `surface-container-low` and `surface-container`); in dark, `surface` itself (the
  Nebula Night page is already the dimmest ground).
- `shadow`: light `#0F1638` (on-surface, the base of every light shadow in `design.json`),
  dark `#000000`. The shadow table carries the alpha.

Task 1 may change a rule's parameter (not its intent) to clear a contrast floor, recording the
change in the table. A new rule, or a role whose value Impeccable wants to restyle, goes to the
owner (D7).

## 5. Foundation layers

### 5.1 Generator (`tools/design/`)

`generate.py` uses the Python standard library only, like `tools/docs/`.
- It reads DESIGN.md (frontmatter and the §4.1 tables) and `.impeccable/design.json`.
- It validates them:
  - every one of the 45 roles is present;
  - frontmatter, tables and `colorMeta` agree;
  - each derived hex equals its rule's result;
  - every stated contrast pair holds.
- It writes `lib/core/theme/generated/design_values.dart`:
  - the light and dark colour values per role and per MemoX colour;
  - the token constants;
  - the type-slot metrics;
  - the contrast pairs, as data for the Dart tests.
- `--check` regenerates in memory and fails on any difference. The gate's docs step runs it.
- Its messages are English, like every script in `tools/`.
- The output is committed. Its name avoids `.g.dart`, which `.gitignore` reserves for
  build_runner, and it opens with a "generated, do not edit" header that names the command.

### 5.2 `lib/core/theme/`

`core/theme` imports Flutter and its own files only.

| File | Holds |
|---|---|
| `generated/design_values.dart` | The generator's output (§5.1). Nothing else in `lib/` holds a colour literal. |
| `foundations/app_spacing.dart`, `app_radius.dart`, `app_stroke.dart`, `app_opacity.dart`, `app_durations.dart`, `app_size.dart`, `app_icon_size.dart`, `app_breakpoints.dart` | Theme-invariant tokens (D10) with DESIGN.md's names, as `abstract final class` constants read from the generated values. |
| `app_color_schemes.dart` | `lightColorScheme` and `darkColorScheme`: `ColorScheme(...)` with all 45 roles set explicitly, never `fromSeed`. |
| `mx_semantic_colors.dart` | `MxSemanticColors extends ThemeExtension`: the MemoX semantic colours, light and dark instances. |
| `mx_derived_colors.dart` | `MxDerivedColors extends ThemeExtension`: primary ink, ghost border, outline edge, status, warning and danger inks, and the soft tints with their borders. Values come from the generator; nothing is computed at runtime. |
| `mx_elevation.dart` | `MxElevation extends ThemeExtension`: the four shadows, the scrim and the glass effect, per theme. |
| `app_typography.dart` | The `TextTheme` built from the type-slot table, and `AppTypography.withWeight`, which moves the variable `wght` axis with `fontWeight`. |
| `mx_text_styles.dart` | `MxTextStyles extends ThemeExtension`: component-level styles that are not a type slot (button label, section label, eyebrow, field label, code, input hint). |
| `app_button_style.dart` | `appButtonStyle(...)`: the one place that builds a `ButtonStyle` with explicit state resolution (the guard's `no_flat_style_from`). |
| `app_component_themes.dart` | Every Material 3 component theme MemoX uses or Flutter draws on its own (text selection, scrollbar, tooltip, menu, date and time pickers, progress, divider). |
| `app_theme.dart` | `buildLightTheme()` and `buildDarkTheme()`: Material 3, both schemes, the text theme and every extension. |
| `theme_context.dart` | `extension ThemeContext on BuildContext`: `colors`, `texts`, `textStyles`, `semanticColors`, `derivedColors`, `elevation`. |

`MemoxApp` passes the two themes to `MaterialApp`, and the stored theme mode keeps choosing
between them. The placeholder shell and pages keep their raw Material widgets: `lib/app` is
outside the guard's `presentation_files` scope, and SP3b removes them.

## 6. Primitives and components

### 6.1 The `Mx` contract (D5)

Every `Mx*`:
- composes Material widgets and primitives rather than re-drawing behaviour Material already
  has (ink, focus, semantics, keyboard);
- reads colour, type, shape and motion only from the theme, its extensions and the tokens;
  owns no palette and takes no `Color`, `TextStyle`, `EdgeInsets`, radius or `BuildContext`
  parameter;
- expresses variants and sizes as enums, never as boolean flags that combine;
- holds no business logic, knows no feature, FN or BR, and holds no product copy. Callers pass
  localized strings;
- requires a `semanticLabel` on an icon-only control;
- keeps a 48×48 touch target whatever its painted size;
- never clamps text, never fixes a height around text (heights are minimums) and lets text
  grow with the system scale;
- has a `const` constructor where Flutter allows one;
- is one public class per file, `lib/shared/widgets/mx_<name>.dart`, flat. A `show…` function
  sits beside its widget.

### 6.2 Primitives (`lib/shared/primitives/`)

Primitives exist because more than one `Mx` needs them. The plan may merge or split them, but
not add new public API.
- **Pressable surface.**
  - The surface decoration with a `Material` and `InkWell` inside it (the ink sits inside the
    decoration, not around it).
  - Pressed overlay at `AppOpacity.pressed`, disabled at `AppOpacity.disabled`.
  - A 2 dp focus ring at a 2 dp offset in primary ink.
  - The 48 dp hit area.
- **Focus ring.** The decoration the pressable surface and the text fields share.
- **Hit target.** The constraint that grows the hit area to 48 dp around a smaller painted
  control.

### 6.3 Components (`lib/shared/widgets/`)

The contract each must meet comes from DESIGN.md "Components". The states listed here are
the ones tests and goldens cover.

| Component | Variants / sizes | States covered |
|---|---|---|
| `MxButton` | tones primary, secondary, outline, text, destructive, dangerSoft, warning; sizes regular, small, compact, chip, study; optional icon, brand-mark image, detail line | enabled, pressed, focused, disabled, loading (spinner at the same width); regular label wraps to two lines |
| `MxIconButton` | — | enabled, pressed, focused, disabled; 20 glyph, 36 ink, 48 hit |
| `MxFab` | — | enabled, pressed, focused; square 52, r16, icon only |
| `MxSheetActions` | confirm and cancel; confirm takes 1.3 shares | side by side, stacked when the labels do not fit |
| `MxCard` | tones raised, hero, warning, success, danger, recessed; `isSelected`; `isFullBleed`; optional tap | each tone, selected, pressed, light shadow / dark ghost edge |
| `MxDialog` + `showMxDialog` | widths 340, 320, 300 | open, with a destructive confirm, loading confirm; scrim, scale-in |
| `MxBottomSheet` + `showMxBottomSheet` | — | open with grabber, chrome shadow, top corners 20; scroll content |
| `MxTextField` + `MxFieldMessage` | variants form, detail, meaning, term, code, study | empty with hint, filled, focused, error, warning, disabled, read-only (INV-UI-007); grows with content |
| `MxSearchField` | typing, trigger | empty, filled with clear, trigger |
| `MxListRow` | leading, title (two lines), subtitle, trailing badge or chevron | enabled, pressed, disabled; 48 minimum, grows |
| `MxEmptyState` | tones primary, neutral, success, warning, danger; optional action | each tone |
| `MxErrorState` | with Retry; not-found (no action); network glyph | each |
| `MxSpinner` | four sizes | each size |
| `MxSkeleton` | line, block, row shape | pulse at rest |
| `MxSnackbar` + `showMxSnackbar` | one optional action | plain 4 s; with Undo 8 s (INV-UI-003's timing) |
| `MxAppBar` | densities content, screen; leading control or none | title on the gutter without a leading control, one-line title, actions |
| `MxScreenScroll` | tail clearance none, FAB, FAB above nav | last item clear of the FAB (INV-UI-006); focused field above the keyboard (INV-UI-005) |

The table follows D2. A component the plan finds feature-shaped moves to SP3b and is ledgered
as a ruling. A generic need the plan finds missing is added only when two of DESIGN.md's
components already require it.

## 7. Guard, architecture and tooling

- **Guard.** In the commit that adds the first file under `lib/shared/widgets/`, three
  `targets_pending` entries in `overrides.yaml` go: `no_flat_style_from`,
  `widget_no_database_access` and `widget_no_repository_access`. The `widget_ui_files` scope
  gains targets in that commit, and the guard reports a stale entry. The plan verifies the
  exact set by running the guard.
  - `widgets_grouped_into_buckets` and `production_screen_audit_not_skipped` stay pending for
    SP3b.
- **Architecture.**
  - `test/architecture/boundary_rules.dart` adds the D16 rule: features and app never
    import `shared/primitives/`.
  - `core/theme` imports nothing from `shared/`, `app/` or `features/`.
  - `shared/` imports only `core/`.
- **Docs tooling.** `check.py` accepts `mx_*` goldens (§8.3), and the gate runs the design
  generator's `--check`.
- **Repo rules and skills that name the old layout** are corrected in the same branch:
  - `flutter-design-system`: `references/components.md` uses `*_widget.dart` and `App*`
    names; `references/tokens.md` has a flat file layout; SKILL.md still says text scale 2.0.
  - `flutter-theme-design`: `references/legacy-and-guards.md` says `showModalBottomSheet`
    is not banned; the construction template says text scale 2.0.
  - Where a skill and the guard or DESIGN.md disagree, the skill is corrected.
- **ADR-011** gets the D16 amendment.
- **CLAUDE.md**: "Known UI debt" and the "Where knowledge lives" row point at §11.

## 8. Verification (D6)

Every task ends with the full gate green (`dod_check.sh`). Goldens run after it, in the Linux
container (`run_goldens.sh`).

### 8.1 Foundation tests (`test/core/theme/`)

- **DESIGN.md parity.**
  - The generator's tests check the parser, the validations and the derivation rules, with
    fixtures for each failure.
  - `--check` in the gate fails when DESIGN.md changes and the code does not.
  - A Dart test asserts that each `ColorScheme` role, extension field and token equals the
    generated value. So a hand edit in `lib/core/theme` that bypasses the generator fails too.
- **The 45-role scheme.** Both schemes set every role of the guard's allowlist; none is left
  to a Flutter default (the test compares against a scheme built with sentinel defaults).
- **Light and dark.** `buildLightTheme` and `buildDarkTheme` carry their own scheme, the text
  theme and every extension. `MemoxApp` switches with the stored mode.
- **Contrast floor.** Every pair the role table declares holds 4.5:1 for text and glyphs and
  3:1 for non-text, in both themes, computed from the theme's actual values.
- **Tokens.** Values match DESIGN.md, through the parity test.
- **Typography.** Every `TextTheme` slot uses Plus Jakarta Sans and its mapped role's metrics.
  `withWeight` sets `fontWeight` and moves the `wght` variation.
- **Theme parity.** Each component theme in `app_component_themes.dart` resolves the same
  colours and shapes as the `Mx` it mirrors, as listed in `flutter-theme-design`'s parity
  table.

### 8.2 Component tests (`test/shared/widgets/mx_<name>_test.dart`)

For each component in §6.3:
- the contract: variants, sizes and every state in its row, including enabled, disabled,
  pressed, focused, error and loading where they apply;
- the touch target is at least 48×48 (Flutter's `androidTapTargetGuideline`);
- semantics: role, label, enabled state; an icon-only control's label is required; read-only
  and disabled announce differently (INV-UI-007);
- no overflow at 320 dp width, at text scale 1.0 and 1.3, with an English and a Vietnamese
  label (diacritics, longer words);
- light and dark render without exceptions.

One helper in `test/support/` wraps a widget in the app themes and localization delegates.
Every component test and golden uses it.

### 8.3 Component goldens

- Path: `test/shared/widgets/goldens/mx_<component>__<state>__<variant>.png`.
  - `<component>` is the class name without `Mx`, in snake case.
  - `<state>` is snake case.
  - `<variant>` is `light` or `dark`.
- One golden per row state of §6.3, in both themes, at a 360 dp frame. Files carry
  `@Tags(['golden'])` and use the shared helper.
- `check.py` accepts an `mx_` golden whose component DESIGN.md "Components" names. It reports
  any other non-`scr_` golden as before.
- An `mx_` golden is never an orphan screen golden.
- The owner gets a `golden-compare` page (CLAUDE.md, "The gate") before the merge.

### 8.4 Impeccable (D7)

Impeccable runs twice:
1. On the DESIGN.md tables in Task 1, before the owner's approval.
2. On the component goldens after the build.
   - It critiques and audits them against DESIGN.md.
   - Everything found is fixed in one batch, at the lowest layer (D3).
   - The batch ends with one `impeccable audit`.

A finding that needs a new token, role or component goes to DESIGN.md and the owner first.

## 9. Order of work

Each task leaves the gate green and is its own commit or commits.

| # | Task | Gate |
|---|---|---|
| 1 | DESIGN.md tables (§4), Impeccable critique of them | **Owner approves the tables.** No code before. |
| 2 | Generator and its tests; `design_values.dart`; gate step | `--check` passes; generator tests pass |
| 3 | Tokens, colour schemes, semantic and derived colours, elevation; parity, 45-role and contrast tests | Foundation tests pass |
| 4 | Typography, text styles, component themes, button style, the two themes, `theme_context`; `MemoxApp` uses them | Theme tests pass; the placeholder app runs both themes |
| 5 | Primitives; the architecture rule; guard `targets_pending` removal | Guard 0 warnings |
| 6 | Actions: `MxButton`, `MxIconButton`, `MxFab`, `MxSheetActions` | Component tests |
| 7 | Containers and overlays: `MxCard`, `MxDialog`, `MxBottomSheet`, `MxSnackbar` | Component tests |
| 8 | Inputs: `MxTextField`, `MxFieldMessage`, `MxSearchField` | Component tests |
| 9 | Lists, status and structure: `MxListRow`, `MxEmptyState`, `MxErrorState`, `MxSpinner`, `MxSkeleton`, `MxAppBar`, `MxScreenScroll` | Component tests |
| 10 | `check.py` `mx_` goldens; component goldens; golden-compare page | Goldens pass in the container |
| 11 | Impeccable critique and audit; one fix batch; one audit | Gate and goldens green |
| 12 | Skills, ADR-011, CLAUDE.md pointer, WBS, §11 register | Docs check passes |

Then the final whole-branch review (Opus), one fix pass for Critical and Important findings,
the final gate, and the owner's sign-off.

## 10. Definition of done

- DESIGN.md holds the approved tables, and the generator reproduces `design_values.dart` from
  it exactly.
- The themes implement all 45 roles, light and dark. There is no hand-written colour literal
  in `lib/`, no deprecated role and no brightness branch in a component.
- Every §6.3 component meets §6.1 and has its tests and goldens. Impeccable's batch is fixed
  and audited.
- The guard passes with 0 errors and 0 warnings. The docs check, the gate and the goldens pass.
- Skills, ADR-011, CLAUDE.md and WBS match the new layout.
- The final review is done and its Critical and Important findings are fixed.
- The owner has seen the golden-compare page and signed off.
- The APK build runs on the owner's side (no Android SDK in the container).

## 11. UI debt register

Known UI debt in the rebuilt UI. A row is added when debt is found and closed by the change
that removes it, with that change's reference. Rows of the removed UI live in the 2026-09-23
spec §9, as history.

| # | Debt | Since | Closed by |
|---|---|---|---|
| 1 | The placeholder shell uses raw Material widgets (`NavigationBar`) and no `Mx*` | SP2 | SP3b (app shell) |
| 2 | `run_goldens.sh` passes on an empty golden set (`no_goldens()`) | SP2 | SP3a Task 10, once the first golden exists |
| 3 | CI's goldens job floor (60) exceeds the golden count; CI is paused | SP2 | the first CI run after enough goldens exist |

## 12. Risks

| Risk | Mitigation |
|---|---|
| A derivation rule yields a colour that clears contrast but reads off-palette | Impeccable critiques the table in Task 1, and the owner approves it before code |
| The generator becomes a second source | It reads DESIGN.md only and writes nothing back. Its output is checked and committed, never edited |
| A component grows a feature meaning | D2: it moves to SP3b and the move is ledgered as a ruling |
| The guard's stale-`targets_pending` check fires mid-branch | §7: the entries go in the commit that adds the first shared widget |
| Component goldens collide with the screen-golden rules | §8.3: `mx_` goldens have their own accepted name and are never orphans |
| Material defaults leak where a slot is unset | The 45-role and theme-parity tests compare against sentinel defaults |
