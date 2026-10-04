# SP3a — Design-system foundation, Part 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the foundation of the MemoX design system from DESIGN.md. Part 1 covers spec §9 Tasks 1–5: the DESIGN.md values (owner gate), the generator, colour, typography and themes, and the primitive layer. Part 2 (Tasks 6–12, the generic `Mx*`, goldens, Impeccable, docs) is written once Task 5 has landed.

**Architecture:**
- The DESIGN.md frontmatter is the only source of every visual value.
- `tools/design/generate.py` compiles it into one committed Dart file, `lib/core/theme/generated/design_values.dart`, which holds the palette, the token classes, the type roles and the contrast pairs. It also writes the value sections of `.impeccable/design.json` and a reference table in DESIGN.md.
- Hand-written `lib/core/theme/` builds the 45-role `ColorScheme`s, three `ThemeExtension`s for theme-dependent MemoX values, the `TextTheme` and the light and dark `ThemeData`.
- `lib/shared/primitives/` holds the internal building blocks the `Mx*` of Part 2 compose.

**Tech Stack:**
- Flutter 3.47.5 / Dart 3.13 (`export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH`).
- Material 3.
- Python 3 standard library, for the generator.
- The repo's guard (`python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`).

**Spec:** `docs/superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md` (revision 2, reviewed by the owner on 2026-10-04: D1–D17).

**Part split (owner, 2026-10-04):**
- Part 1 is this file.
- Part 2 is written after Task 5, against the real theme API, and the owner approves it separately.
- Both parts are the same sub-project, on one branch (`ccr-841d461f-jofe0s`) under one spec.

**Prototype:**
- While writing this plan, the generator, the theme layer, the primitives and their tests were built and run in a scratch copy. The run was: analyze clean, 136 tests passing across `test/core/theme`, `test/shared`, `test/architecture` and `test/app`, the generator's 15 tests passing, and `--check` passing.
- None of it is committed. The code below is that code.

## Global Constraints

- **Source.** The DESIGN.md frontmatter is the only source of values. The generator reads only the frontmatter, never prose (D13).
- **Colour literals.** No colour literal in `lib/` outside `lib/core/theme/generated/` (D4). The guard enforces this from Task 2.
- **One source per token.** A value lives in exactly one place. A constant token has no `ThemeExtension` copy (D10).
- **Brightness branches.** No brightness branch in a component (D4). A theme-dependent value is a `ThemeExtension` field.
- **Imports.**
  - `lib/core/` imports nothing from `shared/`, `app/` or `features/` (ADR-011).
  - `lib/shared/` imports only `lib/core/`.
  - Only `lib/shared/widgets/` and `lib/shared/primitives/` import `lib/shared/primitives/` (ADR-022, D16).
- **Text scale.** Never clamped. Design-system tests cover text scale 1.0, 1.3, 1.5 and 2.0 (D17).
- **Direction.** Directional insets and alignment everywhere; never a hard-coded left or right (D17).
- **Naming.**
  - Booleans read as predicates (`isX`, `hasX`, `canX`, `shouldX`); guard `memox.naming.boolean_reads_as_predicate`.
  - One public class per file. File names are snake case.
- **Dependencies.** No new dependency; `pubspec.yaml` is not touched.
- **Messages.** Messages printed by `tools/` are English. Repo docs keep their language: ADRs are Vietnamese, specs and DESIGN.md English.
- **Commits.** Every commit message ends with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421
  ```
- **Gate.** Every task ends with `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` green. Part 1 has no goldens.
- **The owner.** Every question to the owner goes through `AskUserQuestion`, in Vietnamese.

## Plan-time rulings (shown to the owner with the plan)

- **P1 — `surface-dim` in light is #D2D9EB.**
  - Spec §4.2's rule (surface one step darker) gives #EFF2FA. That sits between `surface` and `surface-container-low`.
  - Material 3 defines `surfaceDim` as the dimmest light surface, darker than `surfaceContainerHighest`. So the rule is applied to `surface-container-highest` minus one container step.
  - Dark is unchanged: it equals `surface`.
  - Cost if wrong: one hex.
- **P2 — a rule for success ink.**
  - DESIGN.md names a success ink (The Ink Is Not The Fill Rule) but gives no rule for it.
  - The plan adds: `success` lerped 40 % toward `on-surface` in light (#206E6A, at least 4.85:1 on every ground) and 0 % in dark.
  - Cost if wrong: one rule.
- **P3 — tint borders.**
  - DESIGN.md says "borders at 22-32%".
  - The plan reads that as 22 % in light and 32 % in dark, for danger, warning and success alike.
  - Cost if wrong: six numbers.
- **P4 — `eyebrow` and `field-label` become frontmatter typography roles.**
  - Their metrics were prose only.
  - Line height is 1.4 for the eyebrow (as caption) and 1.5 for the field label (as body); the prose states neither.
  - Cost if wrong: two numbers.
- **P5 — the generator emits the constant token classes.**
  - `AppSpacing`, `AppRadius`, `AppOpacity`, `AppStroke`, `AppSize`, `AppIconSize`, `AppBreakpoints`, `AppEffects` and `AppDurations` are emitted directly into `design_values.dart`.
  - There are no hand-written `foundations/` files that only re-export generated numbers. CLAUDE.md forbids pass-through layers.
  - The D10 guard rule (Task 3) therefore forbids any literal-valued `static const` in hand-written `lib/core/theme/`.
  - Cost if wrong: the classes move into eight small files that reference the generated ones.
- **P6 — `lib/core/theme/` does not import primitives.**
  - Spec D16 allows it, but ADR-011 forbids `core/` from importing `shared/`, and a theme has no use for a widget.
  - Only `lib/shared/widgets/` and `lib/shared/primitives/` may import them.
  - Cost if wrong: none; core never needs them.
- **P7 — the `targets_pending` entries are removed in Task 6 (Part 2), not Task 5.**
  - The three rules key on the `widget_ui_files` scope, which covers `lib/shared/widgets/` and not `lib/shared/primitives/`.
  - They gain targets only with the first `Mx*`.
  - Cost if wrong: the guard says which entry went stale, in the task that adds it.
- **P8 — the generator pipes its Dart through `dart format`.**
  - It uses `--stdin-name=lib/core/theme/generated/design_values.dart`, so the gate's format step and `--check` agree.
  - Generator tests inject an identity formatter.
- **P9 — the generated file is excluded from the line-count rules** (`common.max_file_lines`, `common.no_large_source_file`), like every other generated file in `overrides.yaml`.

## Findings the owner rules on at the Task 1 gate

- **F1 — White on `mastery` in light measures 4.33:1, below 4.5:1.**
  - DESIGN.md states white for `on-mastery`.
  - Task 1 records the pair at floor 3, which covers glyphs and large text only.
  - The owner chooses one of:
    - keep it at 3;
    - darken `mastery`;
    - change the ink.
- **F2 — `outline` on `surface-container-high` fails 3:1** (light 2.92, dark 2.25). The pair is left out of `contrast`; `outline-edge` exists for the dark sheet.
- **F3 — light `outline-edge` (`outline-variant`) measures 1.3–1.6:1 on every ground.** DESIGN.md claims 3:1 only for dark. It is left out of `contrast`.
- **F4 — the values behind P1–P4,** and the 17 roles of spec §4.2:
  - `onSecondary`, `onTertiary` and `onError` follow the measured rule;
  - the fixed roles are lerped from the containers. All `onXFixed*` hold at least 5.16:1.

## Review Focus

- **A DESIGN.md edit committed without running the generator** never ships stale colours: `--check` fails the gate.
  - Test: Task 2, `test_the_outputs_are_written_then_check_passes_then_a_hand_edit_fails`, plus the gate step.
- **Every ink holds its floor on every ground, in the dark theme too.** It is measured from the scheme and extensions the app uses, not from the palette.
  - Test: Task 3, `every $name contrast pair of DESIGN.md holds`.
- **A runtime switch between light and dark** animates through every `ThemeExtension` without a null extension or a throw.
  - Test: Task 4, `a theme change animates through every extension`.
- **Bold text in the variable font draws bold.** The `wght` axis moves with the weight.
  - Test: Task 4, `withWeight moves the variable font axis with the weight`.
- **Tap targets.** A tap just outside a small control's paint, but inside its 48 dp area, triggers it. A tap outside the 48 dp area does not.
  - Test: Task 5, `a 28 dp control takes 48×48 and a tap at its edge lands`.

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `DESIGN.md` | Frontmatter: all values (§4.1). Body: the generated `### Values` block; the D17 amendment to the Wrap Rule | 1, 2 |
| `PRODUCT.md` | The D17 amendment (line 143) | 1 |
| `tools/design/designdata.py` | Strict frontmatter reader, schema validation, derived colours, contrast, prose check | 2 |
| `tools/design/generate.py` | Writes the Dart, the `design.json` value sections and the DESIGN.md block; `--check` | 2 |
| `tools/design/test_design.py` | Generator tests | 2 |
| `lib/core/theme/generated/design_values.dart` | Generated: `DesignPalette`, token classes, `DesignType`, `DesignTypeSlots`, `designContrastPairs` | 2 |
| `.impeccable/design.json` | Value sections become generated | 2 |
| `.claude/skills/flutter-workflow/scripts/dod_check.sh` | Gate step `design` | 2 |
| `code-verification-guard-v2/registries/projects/memox-v8/{rules,config}/…` | Two new rules, one new scope, the length-rule excludes | 2, 3 |
| `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py` | Probes for the two new rules | 2, 3 |
| `lib/core/theme/app_color_schemes.dart` | `lightColorScheme`, `darkColorScheme` (45 roles) | 3 |
| `lib/core/theme/mx_semantic_colors.dart`, `mx_derived_colors.dart`, `mx_elevation.dart` | Theme-dependent MemoX values | 3 |
| `test/support/theme_colours.dart` | Role and colour maps by DESIGN.md name; contrast ratio | 3, 4 |
| `test/core/theme/colour_values_test.dart` | Parity, 45 roles, shadows, contrast | 3 |
| `lib/core/theme/app_typography.dart`, `mx_text_styles.dart` | TextTheme from type slots; `withWeight`; component roles | 4 |
| `lib/core/theme/app_button_style.dart` | `appButtonStyle` | 4 |
| `lib/core/theme/app_component_themes.dart` | Themes for surfaces Flutter draws itself | 4 |
| `lib/core/theme/app_theme.dart`, `theme_context.dart` | `buildLightTheme`/`buildDarkTheme`; `context.colors` and the others | 4 |
| `lib/app/app.dart` | Uses the two themes | 4 |
| `test/core/theme/typography_test.dart`, `app_theme_test.dart`; `test/app/app_appearance_test.dart` | Theme tests; the app paints them | 4 |
| `lib/shared/primitives/hit_target.dart`, `focus_ring.dart`, `pressable_surface.dart` | Primitives | 5 |
| `test/support/design_system_harness.dart` | `pumpDesignSystem`, `designSystemTextScales` | 5 |
| `test/shared/primitives/*_test.dart` | Primitive tests | 5 |
| `test/architecture/boundary_rules.dart`, `boundary_rules_test.dart`, `boundaries_test.dart` | The ADR-022 import rule | 5 |
| `docs/shared/decisions/ADR-022-lop-primitive-cua-design-system.md` | ADR-022 | 5 |

---

### Task 1: DESIGN.md values (hard gate: the owner approves before any code)

**Files:**
- Modify: `DESIGN.md`
  - frontmatter: the `colors` block, a new `colors-dark`, two typography roles, and the §4.1 blocks;
  - body: a `### Values` block before `## Typography`, and the Wrap Rule.
- Modify: `PRODUCT.md:143`

**Interfaces:**
- Consumes: nothing.
- Produces: the frontmatter schema of spec §4.1, which Task 2's generator reads. The keys are:
  - `colors` and `colors-dark`: the 45 roles plus 13 MemoX colours, kebab case, upper-case `#RRGGBB`;
  - `derived`: per name, a `light` and a `dark` rule, each either `{base, toward, amount}` or `{base, alpha}`;
  - `contrast`: foreground → {ground: 3 | 4.5};
  - `type-slots`: the 15 slots → a typography role;
  - `typography`: now also `eyebrow` and `field-label`;
  - `opacity`, `stroke`, `motion`, `size`, `icon-size`, `breakpoints`, `effects`;
  - `shadows` and `shadows-dark` (`x`, `y`, `blur`, `alpha`);
  - the generated-block markers `<!-- generated:design-values:start -->` / `<!-- generated:design-values:end -->`.

- [ ] **Step 1: Replace the frontmatter `colors:` block**

Replace everything from the line `colors:` up to, but not including, the line `typography:` with this. It is the light block, then the new dark block.

```yaml
colors:
  primary: "#5265F5"
  on-primary: "#FFFFFF"
  primary-container: "#E0E5FE"
  on-primary-container: "#1A2580"
  secondary: "#6E7CD9"
  on-secondary: "#0F1638"
  secondary-container: "#E3E6F7"
  on-secondary-container: "#262E6E"
  tertiary: "#8B6FF5"
  on-tertiary: "#0F1638"
  tertiary-container: "#EBE3FE"
  on-tertiary-container: "#33177E"
  error: "#C02447"
  on-error: "#FFFFFF"
  error-container: "#FBDDE3"
  on-error-container: "#7A0A23"
  surface: "#F7F9FE"
  on-surface: "#0F1638"
  on-surface-variant: "#4A5278"
  outline: "#7C85AB"
  outline-variant: "#C5CBE3"
  shadow: "#0F1638"
  scrim: "#0A0E27"
  inverse-surface: "#34395D"
  on-inverse-surface: "#E8EAFC"
  inverse-primary: "#A0ACFF"
  primary-fixed: "#E0E5FE"
  primary-fixed-dim: "#B5BFFB"
  on-primary-fixed: "#1A2580"
  on-primary-fixed-variant: "#2B38A3"
  secondary-fixed: "#E3E6F7"
  secondary-fixed-dim: "#C0C6EE"
  on-secondary-fixed: "#262E6E"
  on-secondary-fixed-variant: "#3C458E"
  tertiary-fixed: "#EBE3FE"
  tertiary-fixed-dim: "#CEC0FB"
  on-tertiary-fixed: "#33177E"
  on-tertiary-fixed-variant: "#4D31A2"
  surface-dim: "#D2D9EB"
  surface-bright: "#FFFFFF"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#F1F4FB"
  surface-container: "#E9EDF7"
  surface-container-high: "#E2E7F3"
  surface-container-highest: "#DAE0EF"
  mastery: "#1F8A5B"
  on-mastery: "#FFFFFF"
  success: "#2BA88B"
  warning: "#F59E0B"
  on-warning: "#3A2A00"
  warning-ink: "#895806"
  error-fill: "#DC2D4E"
  on-error-fill: "#FFFFFF"
  status-new: "#8C95B8"
  status-learning: "#F59E0B"
  status-reviewing: "#5265F5"
  status-mastered: "#1F8A5B"
  streak: "#F97316"
colors-dark:
  primary: "#5265F5"
  on-primary: "#FFFFFF"
  primary-container: "#2D346A"
  on-primary-container: "#D9DFFF"
  secondary: "#9DA8E8"
  on-secondary: "#0F1638"
  secondary-container: "#343C78"
  on-secondary-container: "#DDE2FB"
  tertiary: "#B5A0FF"
  on-tertiary: "#0F1638"
  tertiary-container: "#443078"
  on-tertiary-container: "#E6DCFF"
  error: "#FF8FA3"
  on-error: "#0F1638"
  error-container: "#7A2036"
  on-error-container: "#FFD9DF"
  surface: "#0A0E27"
  on-surface: "#E4E8FA"
  on-surface-variant: "#A4ACD0"
  outline: "#5A6BAE"
  outline-variant: "#2A3267"
  shadow: "#000000"
  scrim: "#000000"
  inverse-surface: "#34395D"
  on-inverse-surface: "#E8EAFC"
  inverse-primary: "#A0ACFF"
  primary-fixed: "#E0E5FE"
  primary-fixed-dim: "#B5BFFB"
  on-primary-fixed: "#1A2580"
  on-primary-fixed-variant: "#2B38A3"
  secondary-fixed: "#E3E6F7"
  secondary-fixed-dim: "#C0C6EE"
  on-secondary-fixed: "#262E6E"
  on-secondary-fixed-variant: "#3C458E"
  tertiary-fixed: "#EBE3FE"
  tertiary-fixed-dim: "#CEC0FB"
  on-tertiary-fixed: "#33177E"
  on-tertiary-fixed-variant: "#4D31A2"
  surface-dim: "#0A0E27"
  surface-bright: "#232B5A"
  surface-container-lowest: "#131A3A"
  surface-container-low: "#1B2249"
  surface-container: "#232B5A"
  surface-container-high: "#2C356E"
  surface-container-highest: "#353D7E"
  mastery: "#6FE0BD"
  on-mastery: "#11173A"
  success: "#6FE0BD"
  warning: "#FFC658"
  on-warning: "#2A1E00"
  warning-ink: "#FFC658"
  error-fill: "#B0485C"
  on-error-fill: "#FFFFFF"
  status-new: "#6B75A3"
  status-learning: "#FFC658"
  status-reviewing: "#8B9AFF"
  status-mastered: "#6FE0BD"
  streak: "#FFAE6E"
```

- [ ] **Step 2: Add the two typography roles**

In the frontmatter `typography:` block, directly after the `section-label` role (whose last line is `    fontFeature: "tnum"`) and before `rounded:`, insert:

```yaml
  eyebrow:
    fontFamily: "PlusJakartaSans"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "0.8px"
    fontFeature: "tnum"
  field-label:
    fontFamily: "PlusJakartaSans"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.5
```

- [ ] **Step 3: Add the §4.1 blocks**

Insert these directly before the line `components:`, after the `spacing:` block. `on-mastery` is at floor 3 (finding F1); the owner rules on it at Step 8.

```yaml
derived:
  primary-ink:
    light:
      base: primary
      toward: on-surface
      amount: 0.25
    dark:
      base: primary
      toward: on-surface
      amount: 0.45
  ghost-border:
    light:
      base: primary
      alpha: 0.14
    dark:
      base: primary
      alpha: 0.16
  outline-edge:
    light:
      base: outline-variant
      toward: on-surface
      amount: 0
    dark:
      base: outline
      toward: on-surface
      amount: 0.25
  status-new-ink:
    light:
      base: status-new
      toward: on-surface
      amount: 0.4
    dark:
      base: status-new
      toward: on-surface
      amount: 0.4
  status-learning-ink:
    light:
      base: status-learning
      toward: on-surface
      amount: 0.5
    dark:
      base: status-learning
      toward: on-surface
      amount: 0
  status-reviewing-ink:
    light:
      base: status-reviewing
      toward: on-surface
      amount: 0.25
    dark:
      base: status-reviewing
      toward: on-surface
      amount: 0.1
  status-mastered-ink:
    light:
      base: status-mastered
      toward: on-surface
      amount: 0.25
    dark:
      base: status-mastered
      toward: on-surface
      amount: 0
  success-ink:
    light:
      base: success
      toward: on-surface
      amount: 0.4
    dark:
      base: success
      toward: on-surface
      amount: 0
  danger-ink:
    light:
      base: error
      toward: on-surface
      amount: 0.1
    dark:
      base: error
      toward: on-surface
      amount: 0.3
  danger-tint:
    light:
      base: error
      alpha: 0.08
    dark:
      base: error
      alpha: 0.16
  danger-tint-border:
    light:
      base: error
      alpha: 0.22
    dark:
      base: error
      alpha: 0.32
  warning-tint:
    light:
      base: warning
      alpha: 0.12
    dark:
      base: warning
      alpha: 0.18
  warning-tint-border:
    light:
      base: warning
      alpha: 0.22
    dark:
      base: warning
      alpha: 0.32
  success-tint:
    light:
      base: success
      alpha: 0.1
    dark:
      base: success
      alpha: 0.18
  success-tint-border:
    light:
      base: success
      alpha: 0.22
    dark:
      base: success
      alpha: 0.32
contrast:
  on-surface:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  on-surface-variant:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  primary-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  error:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  danger-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  warning-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  success-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  status-new-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  status-learning-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  status-reviewing-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  status-mastered-ink:
    surface: 4.5
    surface-container-lowest: 4.5
    surface-container-low: 4.5
    surface-container-high: 4.5
  on-primary:
    primary: 4.5
  on-secondary:
    secondary: 4.5
  on-tertiary:
    tertiary: 4.5
  on-error:
    error: 4.5
  on-primary-container:
    primary-container: 4.5
  on-secondary-container:
    secondary-container: 4.5
  on-tertiary-container:
    tertiary-container: 4.5
  on-error-container:
    error-container: 4.5
  on-primary-fixed:
    primary-fixed: 4.5
    primary-fixed-dim: 4.5
  on-primary-fixed-variant:
    primary-fixed: 4.5
    primary-fixed-dim: 4.5
  on-secondary-fixed:
    secondary-fixed: 4.5
    secondary-fixed-dim: 4.5
  on-secondary-fixed-variant:
    secondary-fixed: 4.5
    secondary-fixed-dim: 4.5
  on-tertiary-fixed:
    tertiary-fixed: 4.5
    tertiary-fixed-dim: 4.5
  on-tertiary-fixed-variant:
    tertiary-fixed: 4.5
    tertiary-fixed-dim: 4.5
  on-inverse-surface:
    inverse-surface: 4.5
  inverse-primary:
    inverse-surface: 4.5
  on-error-fill:
    error-fill: 4.5
  on-warning:
    warning: 4.5
  on-mastery:
    mastery: 3
  outline:
    surface: 3
    surface-container-lowest: 3
    surface-container-low: 3
  primary:
    surface-container-low: 3
type-slots:
  display-large: stat
  display-medium: display
  display-small: display
  headline-large: headline
  headline-medium: headline
  headline-small: headline
  title-large: title
  title-medium: body-large
  title-small: button-label
  body-large: body-large
  body-medium: body
  body-small: caption
  label-large: button-label
  label-medium: caption
  label-small: caption
opacity:
  disabled: 0.38
  pressed: 0.12
  muted: 0.7
  skeleton-low: 0.45
  skeleton-high: 0.75
stroke:
  hairline: 1
  focus: 2
  focus-offset: 2
  control: 2
  selected-ring: 6
motion:
  toggle: 160
  standard: 200
  scrim-fade: 220
  sheet: 260
  spinner-cycle: 800
  skeleton-pulse: 1400
  snackbar: 4000
  snackbar-with-undo: 8000
  answer-settle: 400
size:
  touch-target: 48
  button-regular: 48
  button-small: 36
  button-compact: 32
  button-chip: 28
  field: 52
  app-bar: 56
  bottom-bar: 64
  bottom-bar-block: 80
  rail: 80
  fab: 52
  icon-button-ink: 36
icon-size:
  small: 16
  medium: 20
  large: 24
breakpoints:
  rail: 600
  content-max: 720
shadows:
  whisper:
    x: 0
    y: 1
    blur: 2
    alpha: 0.04
  chrome:
    x: 0
    y: -2
    blur: 12
    alpha: 0.05
  overlay:
    x: 0
    y: 12
    blur: 32
    alpha: 0.1
  fab:
    x: 0
    y: 8
    blur: 24
    alpha: 0.12
shadows-dark:
  whisper:
    x: 0
    y: 0
    blur: 0
    alpha: 0
  chrome:
    x: 0
    y: -2
    blur: 14
    alpha: 0.36
  overlay:
    x: 0
    y: 16
    blur: 40
    alpha: 0.42
  fab:
    x: 0
    y: 10
    blur: 28
    alpha: 0.5
effects:
  scrim-alpha: 0.45
  glass-alpha: 0.84
  glass-blur: 18
```

- [ ] **Step 4: Add the generated block's place in the body**

Insert directly before the line `## Typography`:

```markdown
### Values

Every colour the app draws, light and dark, with its rule and its lowest measured contrast against the grounds the frontmatter's `contrast` list names. Generated from the frontmatter.

<!-- generated:design-values:start -->
<!-- generated:design-values:end -->

```

- [ ] **Step 5: The D17 amendment**

**PRODUCT.md:143.** Replace the line that begins `  - The default system font scale is the committed target.` with:

```markdown
  - The default system font scale is the committed target for screens. Larger scales are not a design target for screens (owner 2026-09-30: the users are young and keep the default size); text still grows with the system setting and is never clamped, and a cut line at large text on a screen is not a defect. The shared design system (tokens, primitives, `Mx*`) is the exception (owner 2026-10-04, spec 2026-10-04-sp3a D17): its widget and layout tests run at text scale 1.0, 1.3, 1.5 and 2.0 with no overflow, no clipped meaningful text, a 48 dp target and the semantics label kept. Screen tests (widget, golden, visual audit) run at the default scale.
```

**DESIGN.md, Layout → Named Rules, "The Wrap Rule".** Replace its last sentence, `Large text scales are not a design target (PRODUCT.md, owner 2026-09-30), so no new work goes into wrapping for them; a title keeps one line.`, with:

```markdown
Large text scales are not a design target for screens (PRODUCT.md, owner 2026-09-30), so no new screen work goes into wrapping for them; a title keeps one line. The shared components are the exception: each grows or wraps by its contract up to text scale 2.0, and a one-line title keeps its full text in its semantics label (owner 2026-10-04, PRODUCT.md).
```

- [ ] **Step 6: Validate the values with the Task 2 reader (throwaway)**

Save Task 2 Step 3's `designdata.py` as `$W/designdata.py`, where `$W` is the workspace that `sdd-workspace` printed for this plan (git-ignored). This copy is scratch, used only to read the table before the gate. Task 2 builds the real one test-first. Then run:

```bash
python3 - <<PY
import sys; sys.path.insert(0, "$W")
import designdata as d
text = open("DESIGN.md", encoding="utf-8").read()
data, errors = d.load(text)
print("\n".join(errors) or "no errors")
_, body, first = d.read_frontmatter(text)
print("\n".join(d.prose_drift(body, first, data, ("<!-- generated:design-values:start -->", "<!-- generated:design-values:end -->"))) or "no prose drift")
for theme, fg, ground, floor, ratio in data.measured:
    print(f"{theme:5} {fg:28} on {ground:26} {ratio:5.2f}  floor {floor:g}")
PY
```

Expected:
- `no errors` and `no prose drift`, then one line per pair and theme;
- the lowest are `on-mastery on mastery 4.33 floor 3` (light) and `primary on surface-container-low 3.31 floor 3` (dark);
- every ratio at or above its floor.

If a ratio fails, fix the value or the rule's parameter (spec §4.2), and ledger the change as a ruling.

- [ ] **Step 7: Impeccable critique of the values**

Invoke the `impeccable` skill with `critique` on the DESIGN.md colour and typography values, against the rest of DESIGN.md. Name these points:
- the 17 new roles (onSecondary/onTertiary/onError, the 12 fixed roles, surface-dim, shadow);
- P1–P4;
- F1–F3.

Impeccable judges against DESIGN.md, not its own taste (CLAUDE.md). Record each finding in the ledger. A finding that changes a value updates the frontmatter here and is re-validated with Step 6. One that proposes a new token, role or component is put to the owner at Step 8 (D7).

- [ ] **Step 8: The owner's gate — STOP until approved**

Present to the owner in Vietnamese:
- the Step 6 table;
- the 17 new values with their rules;
- P1–P4;
- F1–F3 with the options;
- Impeccable's findings.

Then ask with `AskUserQuestion`:
- **"Duyệt bảng giá trị DESIGN.md"**: approve the values and the F1 decision;
- **"Cần sửa"**: apply the changes, re-run Steps 6–7 and ask again.

Nothing in Task 2 or later starts before the approval. Ledger it as `Task 1: owner approved the DESIGN.md values <date>; F1: <decision>`.

- [ ] **Step 9: Commit**

```bash
git add DESIGN.md PRODUCT.md
git commit -m "$(cat <<'EOF2'
docs(sp3a): DESIGN.md holds every design value in its frontmatter

All 45 Material 3 roles in light and dark (17 derived by rule, spec
§4.2), the MemoX semantic colours, the derived-colour rules, the
contrast pairs, the type slots and the tokens. PRODUCT.md and the Wrap
Rule carry the D17 text-scale ruling. Approved by the owner.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421
EOF2
)"
```

The docs gate still passes (`python3 tools/docs/check.py | tail -1` → `PASS`), since no tool reads the new keys yet.

---

### Task 2: The generator, its outputs, the gate step and the colour-literal rule

**Files:**
- Create:
  - `tools/design/test_design.py`
  - `tools/design/designdata.py`
  - `tools/design/generate.py`
- Generated: `lib/core/theme/generated/design_values.dart`.
- Regenerated:
  - `.impeccable/design.json` (its value sections);
  - the `DESIGN.md` `### Values` block.
- Modify:
  - `.claude/skills/flutter-workflow/scripts/dod_check.sh`, after the `docs` step;
  - in `code-verification-guard-v2/registries/projects/memox-v8/`:
    - `config/scopes.yaml`: a new `colour_literal_surfaces` scope;
    - `rules/memox-design-system-rules.yaml`: a new rule;
    - `config/overrides.yaml`: the length-rule excludes;
  - `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`: the probes.

**Interfaces:**
- Consumes: Task 1's frontmatter schema.
- Produces `lib/core/theme/generated/design_values.dart`. Everything after this task reads only it:
  - `final class DesignPalette`:
    - `static const DesignPalette light` and `dark`;
    - one `final Color` per colour, camelCase of the DESIGN.md name (`primary` … `surfaceContainerHighest`, `mastery` … `streak`, `primaryInk` … `successTintBorder`);
    - `final List<BoxShadow> shadowWhisper`, `shadowChrome`, `shadowOverlay`, `shadowFab`;
    - `Map<String, Color> get byName`, keyed by the kebab-case DESIGN.md name.
  - `abstract final class AppSpacing` (`micro`, `control`, `grouped`, `gutter`, `card`, `section`, `major`, `pageEnd`).
  - `AppRadius` (`xs`, `sm`, `md`, `lg`, `xl`, `full`).
  - `AppOpacity` (`disabled`, `pressed`, `muted`, `skeletonLow`, `skeletonHigh`).
  - `AppStroke` (`hairline`, `focus`, `focusOffset`, `control`, `selectedRing`).
  - `AppSize` (`touchTarget`, `buttonRegular`, `buttonSmall`, `buttonCompact`, `buttonChip`, `field`, `appBar`, `bottomBar`, `bottomBarBlock`, `rail`, `fab`, `iconButtonInk`).
  - `AppIconSize` (`small`, `medium`, `large`).
  - `AppBreakpoints` (`rail`, `contentMax`).
  - `AppEffects` (`scrimAlpha`, `glassAlpha`, `glassBlur`).
  - `AppDurations`: `Duration`s named `toggle`, `standard`, `scrimFade`, `sheet`, `spinnerCycle`, `skeletonPulse`, `snackbar`, `snackbarWithUndo`, `answerSettle`.
  - `final class DesignTypeSpec` (`size`, `weight: FontWeight`, `height`, `letterSpacing`, `hasTabularFigures`).
  - `abstract final class DesignType`: `fontFamily`, plus one `DesignTypeSpec` per role (`stat` … `sectionLabel`, `eyebrow`, `fieldLabel`).
  - `abstract final class DesignTypeSlots`: one per TextTheme slot (`displayLarge` … `labelSmall`).
  - `final class DesignContrastPair(foreground, ground, floor)` and `const List<DesignContrastPair> designContrastPairs`.
- Produces the CLI:
  - `python3 tools/design/generate.py` writes the outputs;
  - `--check` exits 1 when one is stale.

- [ ] **Step 1: Write the generator tests**

`tools/design/test_design.py`:

```python
"""Tests for designdata.py and generate.py:  python3 -m unittest discover -s tools/design"""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import designdata as d  # noqa: E402
import generate as g  # noqa: E402

GREY = "#808080"


def _section(name: str, mapping: dict, indent: int = 0) -> list[str]:
    pad = " " * indent
    lines = [f"{pad}{name}:"]
    for key, value in mapping.items():
        if isinstance(value, dict):
            lines += _section(key, value, indent + 2)
        else:
            lines.append(f"{pad}  {key}: {value}")
    return lines


def _valid() -> dict:
    colours = {name: f'"{GREY}"' for name in d.M3_ROLES + d.SEMANTIC_COLORS}
    colours.update({"surface": '"#FFFFFF"', "on-surface": '"#000000"', "primary": '"#5A6BAE"'})
    shadow = {"x": "0", "y": "1", "blur": "2", "alpha": "0.04"}
    return {
        "colors": dict(colours),
        "colors-dark": dict(colours),
        "derived": {
            "primary-ink": {
                "light": {"base": "primary", "toward": "on-surface", "amount": "0.25"},
                "dark": {"base": "primary", "toward": "on-surface", "amount": "0.25"},
            },
            "ghost-border": {"light": {"base": "primary", "alpha": "0.14"}, "dark": {"base": "primary", "alpha": "0.16"}},
        },
        "contrast": {"on-surface": {"surface": "4.5"}},
        "type-slots": {slot: "body" for slot in d.TYPE_SLOTS},
        "typography": {"body": {"fontFamily": '"PlusJakartaSans"', "fontSize": '"14px"', "fontWeight": "400", "lineHeight": "1.5"}},
        "spacing": {"gutter": '"16px"'},
        "rounded": {"md": '"12px"'},
        "opacity": {"disabled": "0.38"},
        "stroke": {"hairline": "1"},
        "motion": {"standard": "200"},
        "size": {"touch-target": "48"},
        "icon-size": {"small": "16"},
        "breakpoints": {"rail": "600"},
        "effects": {"scrim-alpha": "0.45"},
        "shadows": {name: dict(shadow) for name in d.SHADOWS},
        "shadows-dark": {name: dict(shadow) for name in d.SHADOWS},
    }


def _text(front: dict, body: str = "# Design\n\n" + g.BLOCK_START + "\n" + g.BLOCK_END + "\n") -> str:
    lines = ["---"]
    for key, value in front.items():
        lines += _section(key, value)
    return "\n".join(lines + ["---", body])


class ReaderTest(unittest.TestCase):
    def test_nested_mappings_and_quotes(self):
        front, body, first = d.read_frontmatter('---\na:\n  b: "#FFFFFF"\n  c:\n    d: 1\n---\nbody')
        self.assertEqual(front, {"a": {"b": "#FFFFFF", "c": {"d": "1"}}})
        self.assertEqual((body, first), (["body"], 7))

    def test_yaml_outside_the_subset_is_refused(self):
        for bad in ("a: [1, 2]", "a: {b: 1}", "a: &x 1", "\ta: 1", "a 1"):
            with self.subTest(bad=bad), self.assertRaises(d.SourceError):
                d.read_frontmatter(f"---\n{bad}\n---\n")

    def test_a_duplicate_key_is_refused(self):
        with self.assertRaises(d.SourceError):
            d.read_frontmatter("---\na: 1\na: 2\n---\n")


class LoadTest(unittest.TestCase):
    def test_a_valid_source_loads(self):
        data, errors = d.load(_text(_valid()))
        self.assertEqual(errors, [])
        self.assertEqual(len(data.colors["light"]), 45 + 13 + 2)

    def test_a_missing_role_and_an_unknown_colour_are_errors(self):
        front = _valid()
        del front["colors"]["surface-dim"]
        front["colors-dark"]["surface-tint"] = f'"{GREY}"'
        _, errors = d.load(_text(front))
        self.assertIn("colors: `surface-dim` is missing", errors)
        self.assertIn("colors-dark: `surface-tint` is neither a Material 3 role nor a MemoX colour", errors)

    def test_a_lower_case_hex_is_an_error(self):
        front = _valid()
        front["colors"]["primary"] = '"#5a6bae"'
        _, errors = d.load(_text(front))
        self.assertTrue(any("not an upper-case #RRGGBB" in e for e in errors))

    def test_a_derived_colour_rounds_half_up_like_dart(self):
        # 90 + (228 - 90) * 0.25 = 124.5: half-up gives 125 (0x7D), half-even 124.
        self.assertEqual(d.lerp("#5A6BAE", "#E4E8FA", 0.25), "#7D8AC1")

    def test_a_derived_alpha_keeps_the_base_and_its_alpha(self):
        data, _ = d.load(_text(_valid()))
        border = data.colors["light"]["ghost-border"]
        self.assertEqual((border.hex, border.argb()), ("#5A6BAE", "0x245A6BAE"))

    def test_a_rule_naming_an_unknown_colour_is_an_error(self):
        front = _valid()
        front["derived"]["primary-ink"]["dark"]["toward"] = "ink"
        _, errors = d.load(_text(front))
        self.assertIn("derived.primary-ink.dark: toward `ink` is not a stated colour", errors)

    def test_a_pair_below_its_floor_is_an_error(self):
        front = _valid()
        front["contrast"]["primary"] = {"surface-dim": "4.5"}
        _, errors = d.load(_text(front))
        self.assertTrue(any("primary on surface-dim" in e and "below 4.5:1" in e for e in errors))

    def test_every_type_slot_must_map_to_a_role(self):
        front = _valid()
        del front["type-slots"]["label-small"]
        front["type-slots"]["body-small"] = "caption"
        _, errors = d.load(_text(front))
        self.assertIn("type-slots: `label-small` is missing", errors)
        self.assertIn("type-slots.body-small: `caption` is not a typography role", errors)

    def test_a_shadow_needs_all_four_numbers(self):
        front = _valid()
        del front["shadows"]["fab"]["blur"]
        _, errors = d.load(_text(front))
        self.assertIn("shadows.fab: needs x, y, blur and alpha", errors)


class ProseTest(unittest.TestCase):
    def test_prose_may_name_only_design_values_outside_the_block(self):
        data, _ = d.load(_text(_valid()))
        body = ["Uses #808080.", "Drifted #123456.", g.BLOCK_START, "#ABCDEF", g.BLOCK_END]
        self.assertEqual(
            d.prose_drift(body, 10, data, (g.BLOCK_START, g.BLOCK_END)),
            ["DESIGN.md:11: #123456 is not a value of the frontmatter"],
        )


class BuildTest(unittest.TestCase):
    def _root(self, design_md: str) -> Path:
        root = Path(tempfile.mkdtemp())
        (root / ".impeccable").mkdir()
        (root / g.DESIGN_JSON).write_text(json.dumps({"extensions": {}}), encoding="utf-8")
        (root / g.DESIGN_MD).write_text(design_md, encoding="utf-8")
        return root

    def test_the_outputs_are_written_then_check_passes_then_a_hand_edit_fails(self):
        root = self._root(_text(_valid()))
        identity = lambda text, _: text  # noqa: E731
        outputs, errors = g.build(root, identity)
        self.assertEqual(errors, [])
        self.assertIn("static const DesignPalette light", outputs[g.DART_OUT])
        self.assertIn("static const double gutter = 16;", outputs[g.DART_OUT])
        self.assertIn("| `ghost-border` | #5A6BAE @ 14% |", outputs[g.DESIGN_MD])
        for path, text in outputs.items():
            (root / path).parent.mkdir(parents=True, exist_ok=True)
            (root / path).write_text(text, encoding="utf-8")
        self.assertEqual(g.build(root, identity)[0], outputs)
        meta = json.loads(outputs[g.DESIGN_JSON])["extensions"]["colorMeta"]
        self.assertEqual(meta["primary"]["dark"], "#5A6BAE")

    def test_missing_markers_are_an_error(self):
        root = self._root(_text(_valid(), body="# Design\n"))
        _, errors = g.build(root, lambda text, _: text)
        self.assertTrue(any("markers are missing" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run them and watch them fail**

Run: `python3 -m unittest discover -s tools/design -p 'test_*.py'`
Expected: ERROR, `ModuleNotFoundError: No module named 'designdata'`.

- [ ] **Step 3: The reader and validator**

`tools/design/designdata.py`:

```python
"""Reads, validates and resolves the structured design data in DESIGN.md.

The DESIGN.md frontmatter is the only source of the values the app uses
(spec 2026-10-04-sp3a §4.1, D13). This module reads it with a strict reader
for a YAML subset (nested mappings of scalars; no lists, anchors or flow
collections), checks it against the schema, computes the derived colours and
checks every contrast pair. It never reads a value from the Markdown prose.

Pure functions over text, so the tests feed strings.
"""
from __future__ import annotations

import math
import re
from dataclasses import dataclass, field

M3_ROLES = (
    "primary", "on-primary", "primary-container", "on-primary-container",
    "secondary", "on-secondary", "secondary-container", "on-secondary-container",
    "tertiary", "on-tertiary", "tertiary-container", "on-tertiary-container",
    "error", "on-error", "error-container", "on-error-container",
    "surface", "on-surface", "on-surface-variant", "outline", "outline-variant",
    "shadow", "scrim", "inverse-surface", "on-inverse-surface", "inverse-primary",
    "primary-fixed", "primary-fixed-dim", "on-primary-fixed", "on-primary-fixed-variant",
    "secondary-fixed", "secondary-fixed-dim", "on-secondary-fixed", "on-secondary-fixed-variant",
    "tertiary-fixed", "tertiary-fixed-dim", "on-tertiary-fixed", "on-tertiary-fixed-variant",
    "surface-dim", "surface-bright", "surface-container-lowest", "surface-container-low",
    "surface-container", "surface-container-high", "surface-container-highest",
)
SEMANTIC_COLORS = (
    "mastery", "on-mastery", "success", "warning", "on-warning", "warning-ink",
    "error-fill", "on-error-fill", "status-new", "status-learning",
    "status-reviewing", "status-mastered", "streak",
)
TYPE_SLOTS = (
    "display-large", "display-medium", "display-small",
    "headline-large", "headline-medium", "headline-small",
    "title-large", "title-medium", "title-small",
    "body-large", "body-medium", "body-small",
    "label-large", "label-medium", "label-small",
)
SHADOWS = ("whisper", "chrome", "overlay", "fab")
THEMES = ("light", "dark")
NUMBER_SECTIONS = ("opacity", "stroke", "motion", "size", "icon-size", "breakpoints", "effects")
PX_SECTIONS = ("spacing", "rounded")
REQUIRED = (
    "colors", "colors-dark", "derived", "contrast", "type-slots", "typography",
    *PX_SECTIONS, *NUMBER_SECTIONS, "shadows", "shadows-dark",
)
HEX = re.compile(r"^#[0-9A-F]{6}$")
PX = re.compile(r"^(-?\d+(?:\.\d+)?)px$")
NUMBER = re.compile(r"^-?\d+(?:\.\d+)?$")
KEY = re.compile(r"^[A-Za-z][A-Za-z0-9-]*$")


class SourceError(Exception):
    """The frontmatter cannot be read at all."""


def read_frontmatter(text: str) -> tuple[dict, list[str], int]:
    """Return (mapping, body lines, number of the body's first line)."""
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        raise SourceError("DESIGN.md must open with a `---` frontmatter line")
    try:
        end = lines.index("---", 1)
    except ValueError:
        raise SourceError("the frontmatter has no closing `---` line") from None
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    for number, line in enumerate(lines[1:end], 2):
        if not line.strip():
            continue
        if "\t" in line:
            raise SourceError(f"line {number}: tabs are not allowed")
        indent = len(line) - len(line.lstrip(" "))
        key, colon, raw = line.strip().partition(":")
        if not colon or not KEY.match(key):
            raise SourceError(f"line {number}: expected `key: value`, got `{line.strip()}`")
        while stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        if key in parent:
            raise SourceError(f"line {number}: duplicate key `{key}`")
        value = raw.strip()
        if not value:
            child: dict = {}
            parent[key] = child
            stack.append((indent, child))
            continue
        parent[key] = _scalar(value, number)
    return root, lines[end + 1:], end + 2


def _scalar(value: str, number: int) -> str:
    if value[0] in "\"'":
        if len(value) < 2 or value[-1] != value[0]:
            raise SourceError(f"line {number}: unterminated quoted value")
        return value[1:-1]
    if value[0] in "[{&*!|>#":
        raise SourceError(f"line {number}: `{value}` uses YAML outside the supported subset")
    return value


def camel(key: str) -> str:
    head, *rest = key.split("-")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


def to_rgb(hex_value: str) -> tuple[int, int, int]:
    return tuple(int(hex_value[i:i + 2], 16) for i in (1, 3, 5))  # type: ignore[return-value]


def to_hex(rgb: tuple[float, float, float]) -> str:
    # Half-up rounding, as Dart's round() does: Python's round() is
    # half-to-even and would drift a channel by one.
    return "#" + "".join(f"{int(math.floor(c + 0.5)):02X}" for c in rgb)


def lerp(base: str, toward: str, amount: float) -> str:
    a, b = to_rgb(base), to_rgb(toward)
    return to_hex(tuple(a[i] + (b[i] - a[i]) * amount for i in range(3)))


def luminance(hex_value: str) -> float:
    def channel(c: int) -> float:
        s = c / 255
        return s / 12.92 if s <= 0.03928 else ((s + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(c) for c in to_rgb(hex_value))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


@dataclass(frozen=True)
class Colour:
    """An opaque `#RRGGBB` plus an alpha (1.0 for every stated colour)."""

    hex: str
    alpha: float = 1.0

    def argb(self) -> str:
        return f"0x{int(math.floor(self.alpha * 255 + 0.5)):02X}{self.hex[1:]}"


@dataclass
class DerivedRule:
    base: str
    toward: str | None
    amount: float | None
    alpha: float | None

    def describe(self) -> str:
        if self.alpha is not None:
            return f"{self.base} at {self.alpha:.0%}"
        return f"{self.base} → {self.toward} {self.amount:.0%}"


@dataclass
class TypeRole:
    family: str
    size: float
    weight: int
    height: float
    letter_spacing: float
    tabular: bool


@dataclass
class Shadow:
    x: float
    y: float
    blur: float
    alpha: float


@dataclass
class DesignData:
    colors: dict[str, dict[str, Colour]]
    rules: dict[str, dict[str, DerivedRule]]
    contrast: list[tuple[str, str, float]]
    type_roles: dict[str, TypeRole]
    type_slots: dict[str, str]
    numbers: dict[str, dict[str, float]]
    shadows: dict[str, dict[str, Shadow]]
    measured: list[tuple[str, str, str, float, float]] = field(default_factory=list)

    def all_hex(self) -> set[str]:
        return {c.hex for theme in self.colors.values() for c in theme.values()}


def load(text: str) -> tuple[DesignData | None, list[str]]:
    """Validate the frontmatter of [text]; return the data or the errors."""
    try:
        front, _, _ = read_frontmatter(text)
    except SourceError as error:
        return None, [str(error)]
    errors: list[str] = []
    for key in REQUIRED:
        if not isinstance(front.get(key), dict):
            errors.append(f"frontmatter: `{key}` is missing or not a mapping")
    if errors:
        return None, errors

    colors = {
        "light": _colours(front["colors"], "colors", errors),
        "dark": _colours(front["colors-dark"], "colors-dark", errors),
    }
    rules = _rules(front["derived"], set(M3_ROLES + SEMANTIC_COLORS), errors)
    if not errors:
        for name, by_theme in rules.items():
            for theme, rule in by_theme.items():
                colors[theme][name] = _resolve(rule, colors[theme])
    data = DesignData(
        colors=colors,
        rules=rules,
        contrast=_pairs(front["contrast"], colors["light"], errors),
        type_roles=_type_roles(front["typography"], errors),
        type_slots=_type_slots(front["type-slots"], front["typography"], errors),
        numbers=_numbers(front, errors),
        shadows={t: _shadows(front[k], k, errors) for t, k in (("light", "shadows"), ("dark", "shadows-dark"))},
    )
    if not errors:
        _measure(data, errors)
    return (None, errors) if errors else (data, [])


def _colours(section: dict, name: str, errors: list[str]) -> dict[str, Colour]:
    expected = set(M3_ROLES + SEMANTIC_COLORS)
    for missing in sorted(expected - section.keys()):
        errors.append(f"{name}: `{missing}` is missing")
    for extra in sorted(section.keys() - expected):
        errors.append(f"{name}: `{extra}` is neither a Material 3 role nor a MemoX colour")
    out: dict[str, Colour] = {}
    for key in M3_ROLES + SEMANTIC_COLORS:
        value = section.get(key)
        if value is None:
            continue
        if not isinstance(value, str) or not HEX.match(value):
            errors.append(f"{name}.{key}: `{value}` is not an upper-case #RRGGBB")
            continue
        out[key] = Colour(value)
    return out


def _rules(section: dict, colour_names: set[str], errors: list[str]) -> dict[str, dict[str, DerivedRule]]:
    out: dict[str, dict[str, DerivedRule]] = {}
    for name, by_theme in section.items():
        if name in colour_names:
            errors.append(f"derived.{name}: a derived colour cannot reuse a stated colour's name")
            continue
        if not isinstance(by_theme, dict) or set(by_theme) != set(THEMES):
            errors.append(f"derived.{name}: needs exactly `light` and `dark`")
            continue
        out[name] = {}
        for theme in THEMES:
            rule = _rule(by_theme[theme], f"derived.{name}.{theme}", colour_names, errors)
            if rule is not None:
                out[name][theme] = rule
    return out


def _rule(raw: object, where: str, names: set[str], errors: list[str]) -> DerivedRule | None:
    if not isinstance(raw, dict):
        errors.append(f"{where}: must be a mapping")
        return None
    base = raw.get("base")
    if base not in names:
        errors.append(f"{where}: base `{base}` is not a stated colour")
        return None
    if set(raw) == {"base", "alpha"}:
        alpha = _fraction(raw["alpha"], f"{where}.alpha", errors)
        return None if alpha is None else DerivedRule(base, None, None, alpha)
    if set(raw) == {"base", "toward", "amount"}:
        if raw["toward"] not in names:
            errors.append(f"{where}: toward `{raw['toward']}` is not a stated colour")
            return None
        amount = _fraction(raw["amount"], f"{where}.amount", errors)
        return None if amount is None else DerivedRule(base, raw["toward"], amount, None)
    errors.append(f"{where}: keys must be `base, toward, amount` or `base, alpha`")
    return None


def _fraction(raw: object, where: str, errors: list[str]) -> float | None:
    if not isinstance(raw, str) or not NUMBER.match(raw) or not 0 <= float(raw) <= 1:
        errors.append(f"{where}: `{raw}` is not a number from 0 to 1")
        return None
    return float(raw)


def _resolve(rule: DerivedRule, theme: dict[str, Colour]) -> Colour:
    base = theme[rule.base].hex
    if rule.alpha is not None:
        return Colour(base, rule.alpha)
    return Colour(lerp(base, theme[rule.toward].hex, rule.amount))  # type: ignore[arg-type]


def _pairs(section: dict, light: dict[str, Colour], errors: list[str]) -> list[tuple[str, str, float]]:
    pairs: list[tuple[str, str, float]] = []
    for fg, grounds in section.items():
        if fg not in light:
            errors.append(f"contrast.{fg}: not a stated or derived colour")
            continue
        if not isinstance(grounds, dict) or not grounds:
            errors.append(f"contrast.{fg}: must map grounds to a floor")
            continue
        for ground, floor in grounds.items():
            if ground not in light or light[ground].alpha != 1.0:
                errors.append(f"contrast.{fg}.{ground}: the ground is not an opaque colour")
            elif floor not in ("3", "4.5"):
                errors.append(f"contrast.{fg}.{ground}: the floor is 3 or 4.5, got `{floor}`")
            else:
                pairs.append((fg, ground, float(floor)))
    return pairs


def _measure(data: DesignData, errors: list[str]) -> None:
    for theme in THEMES:
        palette = data.colors[theme]
        for fg, ground, floor in data.contrast:
            ratio = contrast(palette[fg].hex, palette[ground].hex)
            data.measured.append((theme, fg, ground, floor, ratio))
            if palette[fg].alpha != 1.0:
                errors.append(f"contrast.{fg}: a translucent colour has no fixed contrast")
            elif ratio < floor:
                errors.append(f"contrast ({theme}): {fg} on {ground} is {ratio:.2f}:1, below {floor:g}:1")


def _type_roles(section: dict, errors: list[str]) -> dict[str, TypeRole]:
    roles: dict[str, TypeRole] = {}
    for name, raw in section.items():
        where = f"typography.{name}"
        if not isinstance(raw, dict):
            errors.append(f"{where}: must be a mapping")
            continue
        size = PX.match(raw.get("fontSize", ""))
        spacing = PX.match(raw.get("letterSpacing", "0px"))
        weight, height = raw.get("fontWeight", ""), raw.get("lineHeight", "")
        if not size or not spacing or not weight.isdigit() or not NUMBER.match(height):
            errors.append(f"{where}: needs fontSize and letterSpacing in px, a numeric fontWeight and lineHeight")
            continue
        if raw.get("fontFeature", "tnum") != "tnum":
            errors.append(f"{where}: the only supported fontFeature is `tnum`")
            continue
        roles[name] = TypeRole(
            family=raw.get("fontFamily", ""),
            size=float(size[1]),
            weight=int(weight),
            height=float(height),
            letter_spacing=float(spacing[1]),
            tabular=raw.get("fontFeature") == "tnum",
        )
    families = {role.family for role in roles.values()}
    if len(families) > 1:
        errors.append(f"typography: one family is expected, found {sorted(families)}")
    return roles


def _type_slots(section: dict, roles: dict, errors: list[str]) -> dict[str, str]:
    for missing in sorted(set(TYPE_SLOTS) - section.keys()):
        errors.append(f"type-slots: `{missing}` is missing")
    for extra in sorted(section.keys() - set(TYPE_SLOTS)):
        errors.append(f"type-slots: `{extra}` is not a Material 3 TextTheme slot")
    for slot, role in section.items():
        if role not in roles:
            errors.append(f"type-slots.{slot}: `{role}` is not a typography role")
    return {slot: section[slot] for slot in TYPE_SLOTS if slot in section}


def _numbers(front: dict, errors: list[str]) -> dict[str, dict[str, float]]:
    out: dict[str, dict[str, float]] = {}
    for section in PX_SECTIONS + NUMBER_SECTIONS:
        out[section] = {}
        for key, raw in front[section].items():
            pattern = PX if section in PX_SECTIONS else NUMBER
            match = pattern.match(raw) if isinstance(raw, str) else None
            if match is None:
                errors.append(f"{section}.{key}: `{raw}` is not a {'px value' if section in PX_SECTIONS else 'number'}")
                continue
            out[section][key] = float(match[1] if section in PX_SECTIONS else match[0])
    return out


def _shadows(section: dict, name: str, errors: list[str]) -> dict[str, Shadow]:
    out: dict[str, Shadow] = {}
    if set(section) != set(SHADOWS):
        errors.append(f"{name}: needs exactly {', '.join(SHADOWS)}")
    for key in SHADOWS:
        raw = section.get(key)
        if not isinstance(raw, dict) or set(raw) != {"x", "y", "blur", "alpha"}:
            errors.append(f"{name}.{key}: needs x, y, blur and alpha")
            continue
        if not all(isinstance(v, str) and NUMBER.match(v) for v in raw.values()):
            errors.append(f"{name}.{key}: every value is a number")
            continue
        out[key] = Shadow(*(float(raw[k]) for k in ("x", "y", "blur", "alpha")))
    return out


HEX_IN_PROSE = re.compile(r"#[0-9A-Fa-f]{6}\b")


def prose_drift(body: list[str], first_line: int, data: DesignData, skip: tuple[str, str]) -> list[str]:
    """Hex codes the prose names that are not a design value. Reads no value."""
    known = data.all_hex()
    problems: list[str] = []
    inside = False
    for number, line in enumerate(body, first_line):
        if line.strip() == skip[0]:
            inside = True
        elif line.strip() == skip[1]:
            inside = False
        elif not inside:
            for found in HEX_IN_PROSE.findall(line):
                if found.upper() not in known:
                    problems.append(f"DESIGN.md:{number}: {found} is not a value of the frontmatter")
    return problems
```

- [ ] **Step 4: The generator**

`tools/design/generate.py`:

```python
"""Compiles the DESIGN.md frontmatter into the app's design values.

    python3 tools/design/generate.py          # write the three outputs
    python3 tools/design/generate.py --check  # fail if any output is stale

Outputs (spec 2026-10-04-sp3a §5.1):
- lib/core/theme/generated/design_values.dart
- the value sections of .impeccable/design.json
- the reference block in DESIGN.md, between the generated markers

The frontmatter is the only source; nothing here is edited by hand.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from designdata import (  # noqa: E402
    M3_ROLES, SEMANTIC_COLORS, SHADOWS, THEMES, TYPE_SLOTS,
    DesignData, camel, load, prose_drift, read_frontmatter,
)

ROOT = Path(__file__).resolve().parents[2]
DESIGN_MD = "DESIGN.md"
DESIGN_JSON = ".impeccable/design.json"
DART_OUT = "lib/core/theme/generated/design_values.dart"
BLOCK_START = "<!-- generated:design-values:start -->"
BLOCK_END = "<!-- generated:design-values:end -->"
COMMAND = "python3 tools/design/generate.py"

TOKEN_CLASSES = (
    ("spacing", "AppSpacing", "double"),
    ("rounded", "AppRadius", "double"),
    ("opacity", "AppOpacity", "double"),
    ("stroke", "AppStroke", "double"),
    ("size", "AppSize", "double"),
    ("icon-size", "AppIconSize", "double"),
    ("breakpoints", "AppBreakpoints", "double"),
    ("effects", "AppEffects", "double"),
)


def _num(value: float) -> str:
    return f"{value:g}" if value != int(value) else f"{int(value)}"


def dart(data: DesignData) -> str:
    out = [
        f"// GENERATED by `{COMMAND}` from the DESIGN.md frontmatter.",
        "// Do not edit: change DESIGN.md, then run the generator.",
        "// Spec 2026-10-04-sp3a §5.1. The only file in lib/ that holds a colour literal.",
        "library;",
        "",
        "import 'package:flutter/painting.dart';",
        "",
    ]
    out += _palette(data)
    out += _tokens(data)
    out += _type(data)
    out += _contrast(data)
    return "\n".join(out) + "\n"


def _colour_names(data: DesignData) -> list[str]:
    return list(M3_ROLES + SEMANTIC_COLORS) + list(data.rules)


def _palette(data: DesignData) -> list[str]:
    names = _colour_names(data)
    shadows = [f"shadow{name[:1].upper()}{name[1:]}" for name in SHADOWS]
    out = [
        "/// One theme's colours (DESIGN.md `colors`, `colors-dark`, `derived`) and",
        "/// shadows (`shadows`, `shadows-dark`).",
        "final class DesignPalette {",
        "  const DesignPalette({",
        *[f"    required this.{camel(n)}," for n in names],
        *[f"    required this.{s}," for s in shadows],
        "  });",
        "",
        *[f"  final Color {camel(n)};" for n in names],
        *[f"  final List<BoxShadow> {s};" for s in shadows],
        "",
        "  /// Every colour by its DESIGN.md name, for the contrast and parity tests.",
        "  Map<String, Color> get byName => {",
        *[f"    '{n}': {camel(n)}," for n in names],
        "  };",
        "",
    ]
    for theme in THEMES:
        palette = data.colors[theme]
        out.append(f"  static const DesignPalette {theme} = DesignPalette(")
        for n in names:
            out.append(f"    {camel(n)}: Color({palette[n].argb()}),")
        shadow_base = palette["shadow"].hex[1:]
        for name, field in zip(SHADOWS, shadows):
            s = data.shadows[theme][name]
            if s.alpha == 0:
                out.append(f"    {field}: <BoxShadow>[],")
                continue
            alpha = f"{int(s.alpha * 255 + 0.5):02X}"
            out.append(
                f"    {field}: <BoxShadow>[BoxShadow(color: Color(0x{alpha}{shadow_base}), "
                f"offset: Offset({_num(s.x)}, {_num(s.y)}), blurRadius: {_num(s.blur)})],"
            )
        out += ["  );", ""]
    out[-1:] = ["}", ""]
    return out


def _tokens(data: DesignData) -> list[str]:
    out: list[str] = []
    for section, name, kind in TOKEN_CLASSES:
        out.append(f"/// DESIGN.md `{section}`.")
        out.append(f"abstract final class {name} {{")
        for key, value in data.numbers[section].items():
            out.append(f"  static const {kind} {camel(key)} = {_num(value)};")
        out += ["}", ""]
    out.append("/// DESIGN.md `motion`, in milliseconds.")
    out.append("abstract final class AppDurations {")
    for key, value in data.numbers["motion"].items():
        out.append(f"  static const Duration {camel(key)} = Duration(milliseconds: {int(value)});")
    out += ["}", ""]
    return out


def _type(data: DesignData) -> list[str]:
    family = next(iter(data.type_roles.values())).family
    out = [
        "/// The metrics of one DESIGN.md typography role.",
        "final class DesignTypeSpec {",
        "  const DesignTypeSpec({",
        "    required this.size,",
        "    required this.weight,",
        "    required this.height,",
        "    required this.letterSpacing,",
        "    required this.hasTabularFigures,",
        "  });",
        "",
        "  final double size;",
        "  final FontWeight weight;",
        "  final double height;",
        "  final double letterSpacing;",
        "  final bool hasTabularFigures;",
        "}",
        "",
        "/// DESIGN.md `typography`, one constant per role.",
        "abstract final class DesignType {",
        f"  static const String fontFamily = '{family}';",
    ]
    for key, role in data.type_roles.items():
        out.append(
            f"  static const DesignTypeSpec {camel(key)} = DesignTypeSpec(size: {_num(role.size)}, "
            f"weight: FontWeight({role.weight}), height: {_num(role.height)}, "
            f"letterSpacing: {_num(role.letter_spacing)}, hasTabularFigures: {'true' if role.tabular else 'false'});"
        )
    out += ["}", "", "/// DESIGN.md `type-slots`: the role behind each Material 3 TextTheme slot.",
            "abstract final class DesignTypeSlots {"]
    for slot in TYPE_SLOTS:
        out.append(f"  static const DesignTypeSpec {camel(slot)} = DesignType.{camel(data.type_slots[slot])};")
    out += ["}", ""]
    return out


def _contrast(data: DesignData) -> list[str]:
    out = [
        "/// One DESIGN.md `contrast` pair: [foreground] on [ground] holds [floor]:1.",
        "final class DesignContrastPair {",
        "  const DesignContrastPair(this.foreground, this.ground, this.floor);",
        "",
        "  final String foreground;",
        "  final String ground;",
        "  final double floor;",
        "}",
        "",
        "const List<DesignContrastPair> designContrastPairs = [",
    ]
    for fg, ground, floor in data.contrast:
        out.append(f"  DesignContrastPair('{fg}', '{ground}', {floor:g}),")
    out += ["];"]
    return out


def design_json(data: DesignData, current: str) -> str:
    doc = json.loads(current)
    ext = doc.setdefault("extensions", {})
    meta = ext.setdefault("colorMeta", {})
    for name in M3_ROLES + SEMANTIC_COLORS:
        entry = meta.setdefault(name, {"role": name, "displayName": name.replace("-", " ").title()})
        entry["canonical"] = data.colors["light"][name].hex
        entry["light"] = data.colors["light"][name].hex
        entry["dark"] = data.colors["dark"][name].hex
    purposes = {item["name"]: item.get("purpose", "") for item in ext.get("shadows", [])}
    ext["shadows"] = [
        {"name": name, "value": f"light: {_css(data, 'light', name)}; dark: {_css(data, 'dark', name)}",
         "purpose": purposes.get(name, "")}
        for name in SHADOWS
    ]
    motion = {item["name"]: item.get("purpose", "") for item in ext.get("motion", [])}
    ext["motion"] = [
        {"name": key, "value": f"{int(ms)}ms", "purpose": motion.get(key, "")}
        for key, ms in data.numbers["motion"].items()
    ]
    ext["breakpoints"] = [
        {"name": key, "value": f"{_num(dp)}dp"} for key, dp in data.numbers["breakpoints"].items()
    ]
    return json.dumps(doc, indent=2, ensure_ascii=False) + "\n"


def _css(data: DesignData, theme: str, name: str) -> str:
    s = data.shadows[theme][name]
    if s.alpha == 0:
        return "none"
    r, g, b = (int(data.colors[theme]["shadow"].hex[i:i + 2], 16) for i in (1, 3, 5))
    x = f"{_num(s.x)}px" if s.x else "0"
    return f"{x} {_num(s.y)}px {_num(s.blur)}px rgba({r},{g},{b},{s.alpha:g})"


def reference_block(data: DesignData) -> list[str]:
    measured: dict[tuple[str, str], float] = {}
    for theme, fg, ground, _, ratio in data.measured:
        key = (fg, theme)
        measured[key] = min(measured.get(key, ratio), ratio)
    out = [
        BLOCK_START,
        f"<!-- Written by `{COMMAND}` from the frontmatter. Do not edit. -->",
        "",
        "| Colour | Light | Dark | Rule | Lowest contrast (light / dark) |",
        "|---|---|---|---|---|",
    ]
    for name in _colour_names(data):
        light, dark = data.colors["light"][name], data.colors["dark"][name]
        rule = data.rules.get(name)
        how = "stated" if rule is None else f"{rule['light'].describe()} / {rule['dark'].describe()}"
        ratios = " / ".join(
            f"{measured[(name, t)]:.2f}" if (name, t) in measured else "—" for t in THEMES
        )
        out.append(f"| `{name}` | {_swatch(light)} | {_swatch(dark)} | {how} | {ratios} |")
    out += ["", BLOCK_END]
    return out


def _swatch(colour) -> str:
    return colour.hex if colour.alpha == 1.0 else f"{colour.hex} @ {colour.alpha:.0%}"


def with_block(text: str, block: list[str]) -> str | None:
    lines = text.split("\n")
    try:
        start, end = lines.index(BLOCK_START), lines.index(BLOCK_END)
    except ValueError:
        return None
    return "\n".join(lines[:start] + block + lines[end + 1:])


def dart_format(text: str, root: Path) -> str:
    """The text as `dart format` writes it, so the gate's format step agrees."""
    dart_bin = shutil.which("dart")
    if dart_bin is None:
        raise RuntimeError("`dart` is not on PATH; the generator formats its Dart output with it")
    result = subprocess.run(
        [dart_bin, "format", "--output=show", f"--stdin-name={DART_OUT}"],
        input=text, capture_output=True, text=True, cwd=root, check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"dart format failed: {result.stderr.strip()}")
    return result.stdout


def build(
    root: Path, formatter: Callable[[str, Path], str] = dart_format
) -> tuple[dict[str, str], list[str]]:
    """Every output, keyed by its repo-relative path, or the errors."""
    design_text = (root / DESIGN_MD).read_text(encoding="utf-8")
    data, errors = load(design_text)
    if data is None:
        return {}, errors
    _, body, first = read_frontmatter(design_text)
    errors += prose_drift(body, first, data, (BLOCK_START, BLOCK_END))
    design_md = with_block(design_text, reference_block(data))
    if design_md is None:
        errors.append(f"DESIGN.md: the `{BLOCK_START}` and `{BLOCK_END}` markers are missing")
    if errors:
        return {}, errors
    return {
        DART_OUT: formatter(dart(data), root),
        DESIGN_JSON: design_json(data, (root / DESIGN_JSON).read_text(encoding="utf-8")),
        DESIGN_MD: design_md,
    }, []


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="fail if an output is stale")
    parser.add_argument("--root", type=Path, default=ROOT, help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    try:
        outputs, errors = build(args.root)
    except RuntimeError as error:
        print(f"ERROR {error}")
        return 1
    if errors:
        for error in errors:
            print(f"ERROR {error}")
        print(f"FAIL — {len(errors)} error(s) in the design source")
        return 1
    stale = [
        path for path, text in outputs.items()
        if not (args.root / path).is_file() or (args.root / path).read_text(encoding="utf-8") != text
    ]
    if args.check:
        for path in stale:
            print(f"ERROR {path}: stale — run `{COMMAND}`")
        print(f"{'FAIL' if stale else 'PASS'} — {len(stale)} stale output(s)")
        return 1 if stale else 0
    for path in stale:
        target = args.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(outputs[path], encoding="utf-8")
        print(f"wrote {path}")
    print(f"PASS — {len(stale)} output(s) written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 5: Run the tests**

Run: `python3 -m unittest discover -s tools/design -p 'test_*.py'`
Expected: `Ran 15 tests … OK`.

- [ ] **Step 6: Generate, then check**

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH
python3 tools/design/generate.py
python3 tools/design/generate.py --check
```

Expected:
- the first command prints `wrote lib/core/theme/generated/design_values.dart`, `wrote .impeccable/design.json`, `wrote DESIGN.md`, then `PASS — 3 output(s) written`;
- the second prints `PASS — 0 stale output(s)`.

Then run `flutter analyze lib/core/theme` → `No issues found!`, and `dart format --set-exit-if-changed lib/core/theme` → exit 0.

`git diff DESIGN.md` shows only the filled `### Values` block.

- [ ] **Step 7: The gate runs the generator's check and tests**

In `.claude/skills/flutter-workflow/scripts/dod_check.sh`, directly after the `docs` block (the one ending `FAILED+=("document gate unavailable: $DOCS_PY")` / `fi`), insert:

```bash
# The DESIGN.md frontmatter is compiled into lib/core/theme/generated/ and
# .impeccable/design.json (spec 2026-10-04-sp3a D13): a stale output, an
# invalid source or a missed contrast floor fails here, before the commit.
DESIGN_PY="$REPO_ROOT/tools/design/generate.py"
if [[ -n "$PY" && -f "$DESIGN_PY" ]]; then
  plan design "design values" \
    "$PY '$DESIGN_PY' --check && $PY -m unittest discover -s '$REPO_ROOT/tools/design' -p 'test_*.py'"
else
  FAILED+=("design gate unavailable: $DESIGN_PY")
fi
```

- [ ] **Step 8: The colour-literal rule's probes (fail first)**

Append to `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`:

```python


COLOUR_LITERAL = "memox_v8.design_system.no_colour_literal_outside_generated"


def test_no_colour_literal_outside_generated_goes_red_on_each_form(tmp_path: Path) -> None:
    for bad in (
        "final ink = Color(0xFF0F1638);",
        "color: Colors.white,",
        "final ink = Color.fromARGB(255, 15, 22, 56);",
        "final ink = Color.fromRGBO(15, 22, 56, 1);",
    ):
        assert _violations(COLOUR_LITERAL, tmp_path, bad), bad


def test_no_colour_literal_outside_generated_accepts_roles_and_prose(tmp_path: Path) -> None:
    good = """
    // Color(0xFF0F1638) was the ink; the role reads it now.
    final ink = context.colors.onSurface;
    final mixed = Color.lerp(ink, other, t);
    """
    assert not _violations(COLOUR_LITERAL, tmp_path, good)
```

Run: `(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_memox_v8_design_system_guard_rules.py)`
Expected: 2 failed, with `AssertionError: Rule not found: memox_v8.design_system.no_colour_literal_outside_generated`.

- [ ] **Step 9: The scope and the rule**

**Scope.** In `config/scopes.yaml`, under `scopes:`, insert directly before `  theme_files:`:

```yaml
  # Where a colour literal is otherwise legal to the token rules: the
  # composition root and core. lib/core/theme/generated/ is the one file
  # allowed to hold one (spec 2026-10-04-sp3a D4, D13).
  colour_literal_surfaces:
    include:
      - lib/main.dart
      - lib/app/**/*.dart
      - lib/core/**/*.dart
    exclude:
      - '**/*.g.dart'
      - lib/core/theme/generated/**
```

**Rule.** Append to `rules/memox-design-system-rules.yaml`, at the end of `rules:`:

```yaml

  # SP3a (spec 2026-10-04-sp3a D4, D13): a colour exists as a literal in one
  # file only, the one the generator writes from the DESIGN.md frontmatter.
  # Feature and shared UI are already covered by
  # memox.design_token.no_raw_color; this rule covers what that one leaves
  # out on purpose, the composition root and core.
  - id: memox_v8.design_system.no_colour_literal_outside_generated
    type: regex
    severity: error
    enabled: true
    message: >-
      A colour literal lives only in lib/core/theme/generated/design_values.dart,
      which `python3 tools/design/generate.py` writes from the DESIGN.md
      frontmatter. Read a colour role (`context.colors`) or a MemoX colour
      (`context.semanticColors`, `context.derivedColors`) instead; a new colour
      is added to DESIGN.md first.
    scopes:
      - colour_literal_surfaces
    patterns:
      - '^(?!\s*(?://|\*)).*\bColor\s*\(\s*0x[0-9a-fA-F]{6,8}\s*\)'
      - '^(?!\s*(?://|\*)).*\bColors\s*\.\s*[a-z][A-Za-z0-9]*'
      - '^(?!\s*(?://|\*)).*\bColor\s*\.\s*fromARGB\s*\('
      - '^(?!\s*(?://|\*)).*\bColor\s*\.\s*fromRGBO\s*\('
    tags:
      - memox-v8
      - design-system
```

**Length rules.** In `config/overrides.yaml`, add `- lib/core/theme/generated/**` to the `exclude:` lists of both `common.max_file_lines` and `common.no_large_source_file`. Put it on the line before `- lib/core/database/schema_versions.dart`, with the comment `# Written by tools/design/generate.py from DESIGN.md (spec 2026-10-04-sp3a P9).`

- [ ] **Step 10: The probes pass; the guard is clean**

Run:
```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/)
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 | tail -3
```

Expected:
- the guard tests all pass;
- the guard prints `Code verification passed.` with `Errors: 0 | Warnings: 0`;
- the info lines are the five existing `targets_pending` entries.

- [ ] **Step 11: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected:
- `✓ mechanical gates passed`;
- the new `design values` step is green;
- the host suite count is unchanged (1634).

- [ ] **Step 12: Commit**

```bash
git add tools/design lib/core/theme/generated .impeccable/design.json DESIGN.md \
  .claude/skills/flutter-workflow/scripts/dod_check.sh code-verification-guard-v2
git commit -m "$(cat <<'EOF2'
feat(sp3a): compile the DESIGN.md frontmatter into the design values

tools/design/generate.py validates the frontmatter (45 roles, derived
rules, contrast floors, the prose check) and writes
lib/core/theme/generated/design_values.dart, the design.json value
sections and the DESIGN.md reference table; --check runs in the gate. A
guard rule keeps every colour literal in that one generated file.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421
EOF2
)"
```

---

### Task 3: The 45-role schemes and the MemoX colour extensions

**Files:**
- Create:
  - `lib/core/theme/app_color_schemes.dart`
  - `lib/core/theme/mx_semantic_colors.dart`
  - `lib/core/theme/mx_derived_colors.dart`
  - `lib/core/theme/mx_elevation.dart`
- Test:
  - `test/support/theme_colours.dart`
  - `test/core/theme/colour_values_test.dart`
- Modify (guard):
  - `config/scopes.yaml`: a new `hand_written_theme_files` scope;
  - `rules/memox-design-system-rules.yaml`: a new rule;
  - the probes file.

**Interfaces:**
- Consumes: `DesignPalette.light`/`.dark`, `designContrastPairs` (Task 2).
- Produces:
  - `final ColorScheme lightColorScheme`, `darkColorScheme`.
  - `class MxSemanticColors extends ThemeExtension<MxSemanticColors>`:
    - fields `mastery`, `onMastery`, `success`, `warning`, `onWarning`, `warningInk`, `errorFill`, `onErrorFill`, `statusNew`, `statusLearning`, `statusReviewing`, `statusMastered`, `streak`;
    - `static final light`, `dark`; factory `.from(DesignPalette)`.
  - `class MxDerivedColors extends ThemeExtension<MxDerivedColors>`:
    - fields `primaryInk`, `ghostBorder`, `outlineEdge`, `statusNewInk`, `statusLearningInk`, `statusReviewingInk`, `statusMasteredInk`, `successInk`, `dangerInk`, `dangerTint`, `dangerTintBorder`, `warningTint`, `warningTintBorder`, `successTint`, `successTintBorder`;
    - `static final light`, `dark`.
  - `class MxElevation extends ThemeExtension<MxElevation>`:
    - fields `whisper`, `chrome`, `overlay`, `fab` (`List<BoxShadow>`);
    - `static final light`, `dark`.
  - Test support:
    - `Map<String, Color> schemeRoles(ColorScheme)`;
    - `Map<String, Color> coloursOf({scheme, semantic, derived})`;
    - `double contrastRatio(Color, Color)`.

- [ ] **Step 1: The test support and the failing test**

`test/support/theme_colours.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// The 45 Material 3 roles of [scheme], keyed by their DESIGN.md name. The
/// guard's allowlist (`color_scheme_arguments_are_m3_roles`) is the same set.
Map<String, Color> schemeRoles(ColorScheme scheme) => {
  'primary': scheme.primary,
  'on-primary': scheme.onPrimary,
  'primary-container': scheme.primaryContainer,
  'on-primary-container': scheme.onPrimaryContainer,
  'secondary': scheme.secondary,
  'on-secondary': scheme.onSecondary,
  'secondary-container': scheme.secondaryContainer,
  'on-secondary-container': scheme.onSecondaryContainer,
  'tertiary': scheme.tertiary,
  'on-tertiary': scheme.onTertiary,
  'tertiary-container': scheme.tertiaryContainer,
  'on-tertiary-container': scheme.onTertiaryContainer,
  'error': scheme.error,
  'on-error': scheme.onError,
  'error-container': scheme.errorContainer,
  'on-error-container': scheme.onErrorContainer,
  'surface': scheme.surface,
  'on-surface': scheme.onSurface,
  'on-surface-variant': scheme.onSurfaceVariant,
  'outline': scheme.outline,
  'outline-variant': scheme.outlineVariant,
  'shadow': scheme.shadow,
  'scrim': scheme.scrim,
  'inverse-surface': scheme.inverseSurface,
  'on-inverse-surface': scheme.onInverseSurface,
  'inverse-primary': scheme.inversePrimary,
  'primary-fixed': scheme.primaryFixed,
  'primary-fixed-dim': scheme.primaryFixedDim,
  'on-primary-fixed': scheme.onPrimaryFixed,
  'on-primary-fixed-variant': scheme.onPrimaryFixedVariant,
  'secondary-fixed': scheme.secondaryFixed,
  'secondary-fixed-dim': scheme.secondaryFixedDim,
  'on-secondary-fixed': scheme.onSecondaryFixed,
  'on-secondary-fixed-variant': scheme.onSecondaryFixedVariant,
  'tertiary-fixed': scheme.tertiaryFixed,
  'tertiary-fixed-dim': scheme.tertiaryFixedDim,
  'on-tertiary-fixed': scheme.onTertiaryFixed,
  'on-tertiary-fixed-variant': scheme.onTertiaryFixedVariant,
  'surface-dim': scheme.surfaceDim,
  'surface-bright': scheme.surfaceBright,
  'surface-container-lowest': scheme.surfaceContainerLowest,
  'surface-container-low': scheme.surfaceContainerLow,
  'surface-container': scheme.surfaceContainer,
  'surface-container-high': scheme.surfaceContainerHigh,
  'surface-container-highest': scheme.surfaceContainerHighest,
};

/// Every colour one theme holds, keyed by its DESIGN.md name: the 45 roles,
/// the MemoX semantic colours and the derived colours.
Map<String, Color> coloursOf({
  required ColorScheme scheme,
  required MxSemanticColors semantic,
  required MxDerivedColors derived,
}) => {
  ...schemeRoles(scheme),
  'mastery': semantic.mastery,
  'on-mastery': semantic.onMastery,
  'success': semantic.success,
  'warning': semantic.warning,
  'on-warning': semantic.onWarning,
  'warning-ink': semantic.warningInk,
  'error-fill': semantic.errorFill,
  'on-error-fill': semantic.onErrorFill,
  'status-new': semantic.statusNew,
  'status-learning': semantic.statusLearning,
  'status-reviewing': semantic.statusReviewing,
  'status-mastered': semantic.statusMastered,
  'streak': semantic.streak,
  'primary-ink': derived.primaryInk,
  'ghost-border': derived.ghostBorder,
  'outline-edge': derived.outlineEdge,
  'status-new-ink': derived.statusNewInk,
  'status-learning-ink': derived.statusLearningInk,
  'status-reviewing-ink': derived.statusReviewingInk,
  'status-mastered-ink': derived.statusMasteredInk,
  'success-ink': derived.successInk,
  'danger-ink': derived.dangerInk,
  'danger-tint': derived.dangerTint,
  'danger-tint-border': derived.dangerTintBorder,
  'warning-tint': derived.warningTint,
  'warning-tint-border': derived.warningTintBorder,
  'success-tint': derived.successTint,
  'success-tint-border': derived.successTintBorder,
};

/// The WCAG 2 contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final high = la > lb ? la : lb;
  final low = la > lb ? lb : la;
  return (high + 0.05) / (low + 0.05);
}
```

`test/core/theme/colour_values_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

import '../../support/theme_colours.dart';

/// DESIGN.md ↔ code parity for colour (spec 2026-10-04-sp3a §8.1). Every
/// colour of each theme is the generated value of the same DESIGN.md name,
/// so a hand edit in lib/core/theme fails here; a DESIGN.md edit that skips
/// the generator fails `generate.py --check` in the gate.
void main() {
  final themes = {
    'light': (
      lightColorScheme,
      MxSemanticColors.light,
      MxDerivedColors.light,
      MxElevation.light,
      DesignPalette.light,
      Brightness.light,
    ),
    'dark': (
      darkColorScheme,
      MxSemanticColors.dark,
      MxDerivedColors.dark,
      MxElevation.dark,
      DesignPalette.dark,
      Brightness.dark,
    ),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    final (scheme, semantic, derived, elevation, palette, brightness) = theme;

    test('the $name scheme sets all 45 Material 3 roles from DESIGN.md', () {
      final roles = schemeRoles(scheme);

      expect(scheme.brightness, brightness);
      expect(roles, hasLength(45));
      for (final MapEntry(key: role, value: colour) in roles.entries) {
        expect(colour, palette.byName[role], reason: role);
      }
    });

    test('every $name colour is the generated value of its name', () {
      final colours = coloursOf(
        scheme: scheme,
        semantic: semantic,
        derived: derived,
      );

      expect(colours.keys.toSet(), palette.byName.keys.toSet());
      for (final MapEntry(key: key, value: colour) in colours.entries) {
        expect(colour, palette.byName[key], reason: key);
      }
    });

    test('the $name shadows are DESIGN.md\'s', () {
      expect(elevation.whisper, palette.shadowWhisper);
      expect(elevation.chrome, palette.shadowChrome);
      expect(elevation.overlay, palette.shadowOverlay);
      expect(elevation.fab, palette.shadowFab);
    });

    test('every $name contrast pair of DESIGN.md holds', () {
      final colours = coloursOf(
        scheme: scheme,
        semantic: semantic,
        derived: derived,
      );

      for (final pair in designContrastPairs) {
        final ratio = contrastRatio(
          colours[pair.foreground]!,
          colours[pair.ground]!,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(pair.floor),
          reason: '${pair.foreground} on ${pair.ground}: $ratio',
        );
      }
    });
  }

  test('dark draws no whisper shadow: a card takes the ghost border', () {
    expect(MxElevation.dark.whisper, isEmpty);
    expect(MxElevation.light.whisper, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: a compile failure. `app_color_schemes.dart` and the extension files do not exist.

- [ ] **Step 3: The schemes**

`lib/core/theme/app_color_schemes.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The Material 3 colour scheme of each theme, with all 45 roles set from
/// DESIGN.md through the generated palette (spec 2026-10-04-sp3a §5.2).
/// Never `fromSeed`: every role is the value DESIGN.md states.
final ColorScheme lightColorScheme = _scheme(
  DesignPalette.light,
  Brightness.light,
);

final ColorScheme darkColorScheme = _scheme(
  DesignPalette.dark,
  Brightness.dark,
);

ColorScheme _scheme(DesignPalette palette, Brightness brightness) =>
    ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      tertiary: palette.tertiary,
      onTertiary: palette.onTertiary,
      tertiaryContainer: palette.tertiaryContainer,
      onTertiaryContainer: palette.onTertiaryContainer,
      error: palette.error,
      onError: palette.onError,
      errorContainer: palette.errorContainer,
      onErrorContainer: palette.onErrorContainer,
      surface: palette.surface,
      onSurface: palette.onSurface,
      onSurfaceVariant: palette.onSurfaceVariant,
      outline: palette.outline,
      outlineVariant: palette.outlineVariant,
      shadow: palette.shadow,
      scrim: palette.scrim,
      inverseSurface: palette.inverseSurface,
      onInverseSurface: palette.onInverseSurface,
      inversePrimary: palette.inversePrimary,
      primaryFixed: palette.primaryFixed,
      primaryFixedDim: palette.primaryFixedDim,
      onPrimaryFixed: palette.onPrimaryFixed,
      onPrimaryFixedVariant: palette.onPrimaryFixedVariant,
      secondaryFixed: palette.secondaryFixed,
      secondaryFixedDim: palette.secondaryFixedDim,
      onSecondaryFixed: palette.onSecondaryFixed,
      onSecondaryFixedVariant: palette.onSecondaryFixedVariant,
      tertiaryFixed: palette.tertiaryFixed,
      tertiaryFixedDim: palette.tertiaryFixedDim,
      onTertiaryFixed: palette.onTertiaryFixed,
      onTertiaryFixedVariant: palette.onTertiaryFixedVariant,
      surfaceDim: palette.surfaceDim,
      surfaceBright: palette.surfaceBright,
      surfaceContainerLowest: palette.surfaceContainerLowest,
      surfaceContainerLow: palette.surfaceContainerLow,
      surfaceContainer: palette.surfaceContainer,
      surfaceContainerHigh: palette.surfaceContainerHigh,
      surfaceContainerHighest: palette.surfaceContainerHighest,
    );
```

- [ ] **Step 4: The semantic colours**

`lib/core/theme/mx_semantic_colors.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The MemoX colours that no Material 3 role carries (DESIGN.md "Semantic"),
/// one instance per theme (spec 2026-10-04-sp3a D10). Read through
/// `context.semanticColors`.
@immutable
class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.mastery,
    required this.onMastery,
    required this.success,
    required this.warning,
    required this.onWarning,
    required this.warningInk,
    required this.errorFill,
    required this.onErrorFill,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.streak,
  });

  factory MxSemanticColors.from(DesignPalette palette) => MxSemanticColors(
    mastery: palette.mastery,
    onMastery: palette.onMastery,
    success: palette.success,
    warning: palette.warning,
    onWarning: palette.onWarning,
    warningInk: palette.warningInk,
    errorFill: palette.errorFill,
    onErrorFill: palette.onErrorFill,
    statusNew: palette.statusNew,
    statusLearning: palette.statusLearning,
    statusReviewing: palette.statusReviewing,
    statusMastered: palette.statusMastered,
    streak: palette.streak,
  );

  static final MxSemanticColors light = MxSemanticColors.from(
    DesignPalette.light,
  );
  static final MxSemanticColors dark = MxSemanticColors.from(
    DesignPalette.dark,
  );

  final Color mastery;
  final Color onMastery;
  final Color success;
  final Color warning;
  final Color onWarning;
  final Color warningInk;
  final Color errorFill;
  final Color onErrorFill;
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;
  final Color streak;

  @override
  MxSemanticColors copyWith({
    Color? mastery,
    Color? onMastery,
    Color? success,
    Color? warning,
    Color? onWarning,
    Color? warningInk,
    Color? errorFill,
    Color? onErrorFill,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? streak,
  }) => MxSemanticColors(
    mastery: mastery ?? this.mastery,
    onMastery: onMastery ?? this.onMastery,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningInk: warningInk ?? this.warningInk,
    errorFill: errorFill ?? this.errorFill,
    onErrorFill: onErrorFill ?? this.onErrorFill,
    statusNew: statusNew ?? this.statusNew,
    statusLearning: statusLearning ?? this.statusLearning,
    statusReviewing: statusReviewing ?? this.statusReviewing,
    statusMastered: statusMastered ?? this.statusMastered,
    streak: streak ?? this.streak,
  );

  @override
  MxSemanticColors lerp(MxSemanticColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxSemanticColors(
      mastery: mix(mastery, other.mastery),
      onMastery: mix(onMastery, other.onMastery),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      warningInk: mix(warningInk, other.warningInk),
      errorFill: mix(errorFill, other.errorFill),
      onErrorFill: mix(onErrorFill, other.onErrorFill),
      statusNew: mix(statusNew, other.statusNew),
      statusLearning: mix(statusLearning, other.statusLearning),
      statusReviewing: mix(statusReviewing, other.statusReviewing),
      statusMastered: mix(statusMastered, other.statusMastered),
      streak: mix(streak, other.streak),
    );
  }
}
```

- [ ] **Step 5: The derived colours**

`lib/core/theme/mx_derived_colors.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The colours DESIGN.md derives by rule (frontmatter `derived`): the inks
/// that read where a fill would fail contrast, the ghost border, the outline
/// edge and the soft tints. The generator computed them; nothing here does
/// arithmetic on a colour (spec 2026-10-04-sp3a §5.2). Read through
/// `context.derivedColors`.
@immutable
class MxDerivedColors extends ThemeExtension<MxDerivedColors> {
  const MxDerivedColors({
    required this.primaryInk,
    required this.ghostBorder,
    required this.outlineEdge,
    required this.statusNewInk,
    required this.statusLearningInk,
    required this.statusReviewingInk,
    required this.statusMasteredInk,
    required this.successInk,
    required this.dangerInk,
    required this.dangerTint,
    required this.dangerTintBorder,
    required this.warningTint,
    required this.warningTintBorder,
    required this.successTint,
    required this.successTintBorder,
  });

  factory MxDerivedColors.from(DesignPalette palette) => MxDerivedColors(
    primaryInk: palette.primaryInk,
    ghostBorder: palette.ghostBorder,
    outlineEdge: palette.outlineEdge,
    statusNewInk: palette.statusNewInk,
    statusLearningInk: palette.statusLearningInk,
    statusReviewingInk: palette.statusReviewingInk,
    statusMasteredInk: palette.statusMasteredInk,
    successInk: palette.successInk,
    dangerInk: palette.dangerInk,
    dangerTint: palette.dangerTint,
    dangerTintBorder: palette.dangerTintBorder,
    warningTint: palette.warningTint,
    warningTintBorder: palette.warningTintBorder,
    successTint: palette.successTint,
    successTintBorder: palette.successTintBorder,
  );

  static final MxDerivedColors light = MxDerivedColors.from(
    DesignPalette.light,
  );
  static final MxDerivedColors dark = MxDerivedColors.from(DesignPalette.dark);

  final Color primaryInk;
  final Color ghostBorder;
  final Color outlineEdge;
  final Color statusNewInk;
  final Color statusLearningInk;
  final Color statusReviewingInk;
  final Color statusMasteredInk;
  final Color successInk;
  final Color dangerInk;
  final Color dangerTint;
  final Color dangerTintBorder;
  final Color warningTint;
  final Color warningTintBorder;
  final Color successTint;
  final Color successTintBorder;

  @override
  MxDerivedColors copyWith({
    Color? primaryInk,
    Color? ghostBorder,
    Color? outlineEdge,
    Color? statusNewInk,
    Color? statusLearningInk,
    Color? statusReviewingInk,
    Color? statusMasteredInk,
    Color? successInk,
    Color? dangerInk,
    Color? dangerTint,
    Color? dangerTintBorder,
    Color? warningTint,
    Color? warningTintBorder,
    Color? successTint,
    Color? successTintBorder,
  }) => MxDerivedColors(
    primaryInk: primaryInk ?? this.primaryInk,
    ghostBorder: ghostBorder ?? this.ghostBorder,
    outlineEdge: outlineEdge ?? this.outlineEdge,
    statusNewInk: statusNewInk ?? this.statusNewInk,
    statusLearningInk: statusLearningInk ?? this.statusLearningInk,
    statusReviewingInk: statusReviewingInk ?? this.statusReviewingInk,
    statusMasteredInk: statusMasteredInk ?? this.statusMasteredInk,
    successInk: successInk ?? this.successInk,
    dangerInk: dangerInk ?? this.dangerInk,
    dangerTint: dangerTint ?? this.dangerTint,
    dangerTintBorder: dangerTintBorder ?? this.dangerTintBorder,
    warningTint: warningTint ?? this.warningTint,
    warningTintBorder: warningTintBorder ?? this.warningTintBorder,
    successTint: successTint ?? this.successTint,
    successTintBorder: successTintBorder ?? this.successTintBorder,
  );

  @override
  MxDerivedColors lerp(MxDerivedColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxDerivedColors(
      primaryInk: mix(primaryInk, other.primaryInk),
      ghostBorder: mix(ghostBorder, other.ghostBorder),
      outlineEdge: mix(outlineEdge, other.outlineEdge),
      statusNewInk: mix(statusNewInk, other.statusNewInk),
      statusLearningInk: mix(statusLearningInk, other.statusLearningInk),
      statusReviewingInk: mix(statusReviewingInk, other.statusReviewingInk),
      statusMasteredInk: mix(statusMasteredInk, other.statusMasteredInk),
      successInk: mix(successInk, other.successInk),
      dangerInk: mix(dangerInk, other.dangerInk),
      dangerTint: mix(dangerTint, other.dangerTint),
      dangerTintBorder: mix(dangerTintBorder, other.dangerTintBorder),
      warningTint: mix(warningTint, other.warningTint),
      warningTintBorder: mix(warningTintBorder, other.warningTintBorder),
      successTint: mix(successTint, other.successTint),
      successTintBorder: mix(successTintBorder, other.successTintBorder),
    );
  }
}
```

- [ ] **Step 6: The shadows**

`lib/core/theme/mx_elevation.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// DESIGN.md's shadow vocabulary, per theme (frontmatter `shadows`,
/// `shadows-dark`). Dark has no whisper: a card draws the ghost border there
/// instead. Read through `context.elevation`.
@immutable
class MxElevation extends ThemeExtension<MxElevation> {
  const MxElevation({
    required this.whisper,
    required this.chrome,
    required this.overlay,
    required this.fab,
  });

  factory MxElevation.from(DesignPalette palette) => MxElevation(
    whisper: palette.shadowWhisper,
    chrome: palette.shadowChrome,
    overlay: palette.shadowOverlay,
    fab: palette.shadowFab,
  );

  static final MxElevation light = MxElevation.from(DesignPalette.light);
  static final MxElevation dark = MxElevation.from(DesignPalette.dark);

  final List<BoxShadow> whisper;
  final List<BoxShadow> chrome;
  final List<BoxShadow> overlay;
  final List<BoxShadow> fab;

  @override
  MxElevation copyWith({
    List<BoxShadow>? whisper,
    List<BoxShadow>? chrome,
    List<BoxShadow>? overlay,
    List<BoxShadow>? fab,
  }) => MxElevation(
    whisper: whisper ?? this.whisper,
    chrome: chrome ?? this.chrome,
    overlay: overlay ?? this.overlay,
    fab: fab ?? this.fab,
  );

  @override
  MxElevation lerp(MxElevation? other, double t) {
    if (other == null) return this;
    List<BoxShadow> mix(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? const [];
    return MxElevation(
      whisper: mix(whisper, other.whisper),
      chrome: mix(chrome, other.chrome),
      overlay: mix(overlay, other.overlay),
      fab: mix(fab, other.fab),
    );
  }
}
```

- [ ] **Step 7: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: 9 tests, all pass:
- 4 per theme: the 45 roles, every colour, the shadows, the contrast pairs;
- plus the whisper test.

- [ ] **Step 8: The one-source rule (D10): probes first**

Append to `code-verification-guard-v2/tests/test_memox_v8_design_system_guard_rules.py`:

```python


THEME_CONSTANT = "memox_v8.design_system.theme_constant_reads_generated"


def test_theme_constant_reads_generated_goes_red_on_a_literal(tmp_path: Path) -> None:
    for bad in (
        "  static const double gap = 16;",
        "  static const Color ink = Color(0xFF0F1638);",
        "  static const Duration fade = Duration(milliseconds: 200);",
    ):
        assert _violations(THEME_CONSTANT, tmp_path, bad), bad


def test_theme_constant_reads_generated_accepts_generated_values(tmp_path: Path) -> None:
    good = """
    // static const double gap = 16; was the old spelling.
    static const double gap = AppSpacing.gutter;
    static const Duration fade = AppDurations.standard;
    """
    assert not _violations(THEME_CONSTANT, tmp_path, good)
```

Run: `(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_memox_v8_design_system_guard_rules.py)`
Expected: 2 failed (`Rule not found: memox_v8.design_system.theme_constant_reads_generated`).

**Scope.** In `config/scopes.yaml`, insert directly before `  theme_files:`. It lands in this task because the rule needs hand-written theme files to scan; with none, the guard reports `rule_without_targets`.

```yaml
  # The hand-written theme: every value it uses comes from the generated file
  # (spec 2026-10-04-sp3a D10).
  hand_written_theme_files:
    include:
      - lib/core/theme/**/*.dart
    exclude:
      - '**/*.g.dart'
      - lib/core/theme/generated/**
```

**Rule.** Append to `rules/memox-design-system-rules.yaml`:

```yaml

  # SP3a (spec 2026-10-04-sp3a D10): every token has one source. The
  # generator writes the constant token classes; hand-written theme code
  # reads them and never states a value of its own.
  - id: memox_v8.design_system.theme_constant_reads_generated
    type: regex
    severity: error
    enabled: true
    message: >-
      A `static const` in the hand-written theme takes its value from
      lib/core/theme/generated/design_values.dart (`AppSpacing.gutter`,
      `DesignPalette.light.primary`), never from a literal: the DESIGN.md
      frontmatter is the one source of every value.
    scopes:
      - hand_written_theme_files
    patterns:
      - '^\s*static\s+const\s+(?:double|int|num|Color|Duration)\s+\w+\s*=\s*(?:-?[0-9]|Color\s*\(|Duration\s*\()'
    tags:
      - memox-v8
      - design-system
```

Run:
```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/)
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 | tail -3
```

Expected: all guard tests pass, and the guard reports `Errors: 0 | Warnings: 0`.

- [ ] **Step 9: The gate, then commit**

Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`.

```bash
git add lib/core/theme test/support/theme_colours.dart test/core/theme code-verification-guard-v2
git commit -m "$(cat <<'EOF2'
feat(sp3a): the 45-role colour schemes and the MemoX colour extensions

lightColorScheme and darkColorScheme set every Material 3 role from the
generated palette; MxSemanticColors, MxDerivedColors and MxElevation hold
what no role carries. Tests pin each colour to its DESIGN.md name and
every declared contrast floor in both themes. A guard rule keeps every
theme constant on the generated values.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421
EOF2
)"
```

---

### Task 4: Typography, the two themes, the context accessors and the app

**Files:**
- Create:
  - `lib/core/theme/app_typography.dart`
  - `lib/core/theme/mx_text_styles.dart`
  - `lib/core/theme/app_button_style.dart`
  - `lib/core/theme/app_component_themes.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/core/theme/theme_context.dart`
- Modify:
  - `lib/app/app.dart`;
  - `test/support/theme_colours.dart` (append `themeColours`);
  - `test/app/app_appearance_test.dart`.
- Test:
  - `test/core/theme/typography_test.dart`
  - `test/core/theme/app_theme_test.dart`

**Interfaces:**
- Consumes:
  - Task 2: `DesignType`, `DesignTypeSlots`, `DesignTypeSpec`, the token classes.
  - Task 3: the schemes and the three extensions.
- Produces:
  - `abstract final class AppTypography`:
    - `static TextStyle role(DesignTypeSpec)`;
    - `static TextStyle withWeight(TextStyle, FontWeight)`;
    - `static TextTheme textTheme(ColorScheme)`.
  - `class MxTextStyles extends ThemeExtension<MxTextStyles>`: fields `buttonLabel`, `sectionLabel`, `eyebrow`, `fieldLabel`; factory `.from(ColorScheme)`.
  - `ButtonStyle appButtonStyle({required Color ink, required Color focusRing, required TextStyle label, Color? fill, Color? edge, double minHeight, double radius, double horizontalPadding})`.
  - `abstract final class AppComponentThemes`, with `textSelection`, `progress`, `dialog`, `datePicker`, `timePicker` and `textButton`.
  - `ThemeData buildLightTheme()`, `ThemeData buildDarkTheme()`.
  - `extension ThemeContext on BuildContext`: `colors`, `texts`, `textStyles`, `semanticColors`, `derivedColors`, `elevation`.
  - Test support: `Map<String, Color> themeColours(ThemeData)`.

- [ ] **Step 1: The failing tests**

Append to `test/support/theme_colours.dart`, before `/// The WCAG 2 contrast ratio`:

```dart
/// Every colour [theme] holds, keyed by its DESIGN.md name.
Map<String, Color> themeColours(ThemeData theme) => coloursOf(
  scheme: theme.colorScheme,
  semantic: theme.extension<MxSemanticColors>()!,
  derived: theme.extension<MxDerivedColors>()!,
);
```

`test/core/theme/typography_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

void main() {
  test('every TextTheme slot is Plus Jakarta Sans in its DESIGN.md role', () {
    final texts = buildLightTheme().textTheme;
    final slots = {
      'displayLarge': (texts.displayLarge, DesignTypeSlots.displayLarge),
      'displayMedium': (texts.displayMedium, DesignTypeSlots.displayMedium),
      'displaySmall': (texts.displaySmall, DesignTypeSlots.displaySmall),
      'headlineLarge': (texts.headlineLarge, DesignTypeSlots.headlineLarge),
      'headlineMedium': (texts.headlineMedium, DesignTypeSlots.headlineMedium),
      'headlineSmall': (texts.headlineSmall, DesignTypeSlots.headlineSmall),
      'titleLarge': (texts.titleLarge, DesignTypeSlots.titleLarge),
      'titleMedium': (texts.titleMedium, DesignTypeSlots.titleMedium),
      'titleSmall': (texts.titleSmall, DesignTypeSlots.titleSmall),
      'bodyLarge': (texts.bodyLarge, DesignTypeSlots.bodyLarge),
      'bodyMedium': (texts.bodyMedium, DesignTypeSlots.bodyMedium),
      'bodySmall': (texts.bodySmall, DesignTypeSlots.bodySmall),
      'labelLarge': (texts.labelLarge, DesignTypeSlots.labelLarge),
      'labelMedium': (texts.labelMedium, DesignTypeSlots.labelMedium),
      'labelSmall': (texts.labelSmall, DesignTypeSlots.labelSmall),
    };

    for (final MapEntry(key: slot, value: (style, spec)) in slots.entries) {
      expect(style!.fontFamily, DesignType.fontFamily, reason: slot);
      expect(style.fontSize, spec.size, reason: slot);
      expect(style.height, spec.height, reason: slot);
      expect(style.letterSpacing, spec.letterSpacing, reason: slot);
      expect(style.fontWeight, spec.weight, reason: slot);
    }
  });

  test('withWeight moves the variable font axis with the weight', () {
    final style = AppTypography.withWeight(const TextStyle(), FontWeight.w700);

    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontVariations, [const FontVariation('wght', 700)]);
  });

  test('a tabular role draws tabular figures', () {
    expect(AppTypography.role(DesignType.stat).fontFeatures, [
      const FontFeature.tabularFigures(),
    ]);
    expect(AppTypography.role(DesignType.body).fontFeatures, isNull);
  });

  test('the text theme and the component styles are inked per theme', () {
    for (final theme in [buildLightTheme(), buildDarkTheme()]) {
      final scheme = theme.colorScheme;
      final styles = theme.extension<MxTextStyles>()!;

      expect(theme.textTheme.bodyMedium!.color, scheme.onSurface);
      expect(styles.eyebrow.color, scheme.onSurfaceVariant);
      expect(styles.sectionLabel.color, scheme.onSurfaceVariant);
      expect(styles.fieldLabel.color, scheme.onSurface);
      expect(styles.buttonLabel.fontSize, DesignType.buttonLabel.size);
    }
  });
}
```

`test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

import '../../support/theme_colours.dart';

void main() {
  final themes = {
    'light': (buildLightTheme(), lightColorScheme, DesignPalette.light),
    'dark': (buildDarkTheme(), darkColorScheme, DesignPalette.dark),
  };

  for (final MapEntry(key: name, value: (theme, scheme, palette))
      in themes.entries) {
    test(
      'the $name theme is Material 3 with its scheme and every extension',
      () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, same(scheme));
        expect(theme.extension<MxSemanticColors>(), isNotNull);
        expect(theme.extension<MxDerivedColors>(), isNotNull);
        expect(theme.extension<MxElevation>(), isNotNull);
        expect(theme.extension<MxTextStyles>(), isNotNull);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      },
    );

    test('every $name colour the theme holds is DESIGN.md\'s', () {
      final colours = themeColours(theme);

      for (final MapEntry(key: key, value: colour) in colours.entries) {
        expect(colour, palette.byName[key], reason: key);
      }
    });

    test('the $name system surfaces follow DESIGN.md', () {
      final ink = theme.extension<MxDerivedColors>()!.primaryInk;
      final floating = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      );

      expect(theme.textSelectionTheme.cursorColor, ink);
      expect(theme.textSelectionTheme.selectionHandleColor, ink);
      expect(theme.progressIndicatorTheme.color, ink);
      expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainerHigh);
      expect(theme.dialogTheme.shape, floating);
      expect(theme.datePickerTheme.shape, floating);
      expect(theme.timePickerTheme.shape, floating);
    });

    test('the $name text button is the quiet ink action', () {
      final style = theme.textButtonTheme.style!;
      const none = <WidgetState>{};
      final ink = theme.extension<MxDerivedColors>()!.primaryInk;

      expect(style.foregroundColor!.resolve(none), ink);
      expect(
        style.overlayColor!.resolve({WidgetState.pressed}),
        ink.withValues(alpha: AppOpacity.pressed),
      );
      expect(
        style.foregroundColor!.resolve({WidgetState.disabled})!.a,
        closeTo(ink.a * AppOpacity.disabled, 0.001),
      );
      expect(style.minimumSize!.resolve(none)!.height, AppSize.buttonRegular);
      expect(
        style.side!.resolve({WidgetState.focused})!.width,
        AppStroke.focus,
      );
    });
  }

  test('a theme change animates through every extension', () {
    final halfway = ThemeData.lerp(buildLightTheme(), buildDarkTheme(), 0.5);

    expect(halfway.extension<MxSemanticColors>(), isNotNull);
    expect(halfway.extension<MxDerivedColors>(), isNotNull);
    expect(halfway.extension<MxElevation>(), isNotNull);
    expect(halfway.extension<MxTextStyles>(), isNotNull);
  });
}
```

In `test/app/app_appearance_test.dart`:
- add the imports `package:memox/core/theme/generated/design_values.dart` and `package:memox/core/theme/mx_derived_colors.dart`, in alphabetical order after `go_router`;
- add this as the first test of `main()`:

```dart
  libraryTest('the app paints DESIGN.md\'s light and dark themes (SP3a)', (
    tester,
    env,
  ) async {
    ThemeData theme() => Theme.of(tester.element(find.byType(NavigationBar)));
    await pumpMemoxApp(tester, env);

    expect(theme().colorScheme.primary, DesignPalette.light.primary);
    expect(
      theme().extension<MxDerivedColors>()!.primaryInk,
      DesignPalette.light.primaryInk,
    );

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();

    expect(
      theme().colorScheme.surface,
      isSameColorAs(DesignPalette.dark.surface),
    );
    expect(
      theme().extension<MxDerivedColors>()!.primaryInk,
      isSameColorAs(DesignPalette.dark.primaryInk),
    );
  });
```

- [ ] **Step 2: Run them and watch them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/app/app_appearance_test.dart`
Expected: compile failures. `app_theme.dart` and `app_typography.dart` do not exist yet.

- [ ] **Step 3: Typography**

`lib/core/theme/app_typography.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// DESIGN.md typography: one family (Plus Jakarta Sans, a variable font) and
/// the roles of the frontmatter, mapped onto Material 3's fifteen TextTheme
/// slots by `type-slots` (spec 2026-10-04-sp3a §5.2).
abstract final class AppTypography {
  /// The style of one DESIGN.md role, without a colour.
  static TextStyle role(DesignTypeSpec spec) => withWeight(
    TextStyle(
      fontFamily: DesignType.fontFamily,
      fontSize: spec.size,
      height: spec.height,
      letterSpacing: spec.letterSpacing,
      fontFeatures: spec.hasTabularFigures
          ? const [FontFeature.tabularFigures()]
          : null,
    ),
    spec.weight,
  );

  /// [style] at [weight]. The family is variable, so the `wght` axis moves
  /// with `fontWeight`; setting only `fontWeight` would draw the default
  /// instance at a synthetic weight.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );

  /// The fifteen Material 3 slots, each in its DESIGN.md role, inked in
  /// [scheme]'s `onSurface`.
  static TextTheme textTheme(ColorScheme scheme) => TextTheme(
    displayLarge: role(DesignTypeSlots.displayLarge),
    displayMedium: role(DesignTypeSlots.displayMedium),
    displaySmall: role(DesignTypeSlots.displaySmall),
    headlineLarge: role(DesignTypeSlots.headlineLarge),
    headlineMedium: role(DesignTypeSlots.headlineMedium),
    headlineSmall: role(DesignTypeSlots.headlineSmall),
    titleLarge: role(DesignTypeSlots.titleLarge),
    titleMedium: role(DesignTypeSlots.titleMedium),
    titleSmall: role(DesignTypeSlots.titleSmall),
    bodyLarge: role(DesignTypeSlots.bodyLarge),
    bodyMedium: role(DesignTypeSlots.bodyMedium),
    bodySmall: role(DesignTypeSlots.bodySmall),
    labelLarge: role(DesignTypeSlots.labelLarge),
    labelMedium: role(DesignTypeSlots.labelMedium),
    labelSmall: role(DesignTypeSlots.labelSmall),
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}
```

`lib/core/theme/mx_text_styles.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The DESIGN.md roles that are not a Material 3 TextTheme slot, inked for
/// one theme. A component overrides the nearest role inside itself; it never
/// adds a global style (DESIGN.md, The Seven Roles Rule). Read through
/// `context.textStyles`.
@immutable
class MxTextStyles extends ThemeExtension<MxTextStyles> {
  const MxTextStyles({
    required this.buttonLabel,
    required this.sectionLabel,
    required this.eyebrow,
    required this.fieldLabel,
  });

  factory MxTextStyles.from(ColorScheme scheme) => MxTextStyles(
    buttonLabel: AppTypography.role(DesignType.buttonLabel),
    sectionLabel: AppTypography.role(DesignType.sectionLabel)
        .apply(color: scheme.onSurfaceVariant),
    eyebrow: AppTypography.role(DesignType.eyebrow)
        .apply(color: scheme.onSurfaceVariant),
    fieldLabel: AppTypography.role(DesignType.fieldLabel)
        .apply(color: scheme.onSurface),
  );

  /// Every text-labelled control; the control sets the colour.
  final TextStyle buttonLabel;

  /// The overline of a list or a settings group; the widget upper-cases it.
  final TextStyle sectionLabel;

  /// The one context line above a big title or number.
  final TextStyle eyebrow;

  /// The name of an input or of a read-only field.
  final TextStyle fieldLabel;

  @override
  MxTextStyles copyWith({
    TextStyle? buttonLabel,
    TextStyle? sectionLabel,
    TextStyle? eyebrow,
    TextStyle? fieldLabel,
  }) => MxTextStyles(
    buttonLabel: buttonLabel ?? this.buttonLabel,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    eyebrow: eyebrow ?? this.eyebrow,
    fieldLabel: fieldLabel ?? this.fieldLabel,
  );

  @override
  MxTextStyles lerp(MxTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return MxTextStyles(
      buttonLabel: mix(buttonLabel, other.buttonLabel),
      sectionLabel: mix(sectionLabel, other.sectionLabel),
      eyebrow: mix(eyebrow, other.eyebrow),
      fieldLabel: mix(fieldLabel, other.fieldLabel),
    );
  }
}
```

- [ ] **Step 4: The button style and the component themes**

`lib/core/theme/app_button_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The one place a `ButtonStyle` is built, with every state resolved
/// explicitly (guard `no_flat_style_from`). [ink] is the label and icon
/// colour, [fill] the ground (none for a text or outline button), [edge] the
/// outline (none unless the tone has one) and [focusRing] the 2 dp ring.
/// Pressed lays [ink] over the ground at `AppOpacity.pressed`; disabled draws
/// the whole control at `AppOpacity.disabled` (DESIGN.md, MxButton).
ButtonStyle appButtonStyle({
  required Color ink,
  required Color focusRing,
  required TextStyle label,
  Color? fill,
  Color? edge,
  double minHeight = AppSize.buttonRegular,
  double radius = AppRadius.md,
  double horizontalPadding = AppSpacing.gutter,
}) {
  Color faded(Color color) =>
      color.withValues(alpha: color.a * AppOpacity.disabled);
  final transparent = ink.withValues(alpha: 0);
  return ButtonStyle(
    textStyle: WidgetStatePropertyAll(label),
    minimumSize: WidgetStatePropertyAll(Size(AppSize.touchTarget, minHeight)),
    padding: WidgetStatePropertyAll(
      EdgeInsetsDirectional.symmetric(horizontal: horizontalPadding),
    ),
    tapTargetSize: MaterialTapTargetSize.padded,
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? faded(ink) : ink,
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      final ground = fill ?? transparent;
      return states.contains(WidgetState.disabled) ? faded(ground) : ground;
    }),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? ink.withValues(alpha: AppOpacity.pressed)
          : transparent,
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: focusRing, width: AppStroke.focus);
      }
      if (edge == null) return BorderSide.none;
      final color = states.contains(WidgetState.disabled) ? faded(edge) : edge;
      return BorderSide(color: color, width: AppStroke.hairline);
    }),
  );
}
```

`lib/core/theme/app_component_themes.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// The component themes of the surfaces Flutter draws on its own — the text
/// cursor and handles, progress, pickers and their dialogs and buttons —
/// where DESIGN.md states something Material 3's scheme-driven default does
/// not (spec 2026-10-04-sp3a §5.2). Each `Mx*` that mirrors a Material
/// component adds its theme here when it is built, with a parity test.
abstract final class AppComponentThemes {
  /// Primary as a cursor or a handle is the ink, never the fill (DESIGN.md,
  /// The Ink Is Not The Fill Rule).
  static TextSelectionThemeData textSelection(MxDerivedColors derived) =>
      TextSelectionThemeData(
        cursorColor: derived.primaryInk,
        selectionHandleColor: derived.primaryInk,
      );

  /// A spinner is drawn in the primary ink.
  static ProgressIndicatorThemeData progress(MxDerivedColors derived) =>
      ProgressIndicatorThemeData(color: derived.primaryInk);

  /// Dialogs float: the sheet ground and the 20 radius.
  static DialogThemeData dialog(ColorScheme scheme) => DialogThemeData(
    backgroundColor: scheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
  );

  static DatePickerThemeData datePicker(ColorScheme scheme) =>
      DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );

  static TimePickerThemeData timePicker(ColorScheme scheme) =>
      TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      );

  /// The quiet action of a system dialog: DESIGN.md's text tone of MxButton.
  static TextButtonThemeData textButton(
    MxDerivedColors derived,
    MxTextStyles styles,
  ) => TextButtonThemeData(
    style: appButtonStyle(
      ink: derived.primaryInk,
      focusRing: derived.primaryInk,
      label: styles.buttonLabel,
    ),
  );
}
```

- [ ] **Step 5: The themes and the accessors**

`lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// Tokyo Pure Light: DESIGN.md's light theme.
ThemeData buildLightTheme() => _theme(
  scheme: lightColorScheme,
  semantic: MxSemanticColors.light,
  derived: MxDerivedColors.light,
  elevation: MxElevation.light,
);

/// Tokyo Nebula: DESIGN.md's dark theme, authored on its own.
ThemeData buildDarkTheme() => _theme(
  scheme: darkColorScheme,
  semantic: MxSemanticColors.dark,
  derived: MxDerivedColors.dark,
  elevation: MxElevation.dark,
);

ThemeData _theme({
  required ColorScheme scheme,
  required MxSemanticColors semantic,
  required MxDerivedColors derived,
  required MxElevation elevation,
}) {
  final styles = MxTextStyles.from(scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: DesignType.fontFamily,
    textTheme: AppTypography.textTheme(scheme),
    scaffoldBackgroundColor: scheme.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [semantic, derived, elevation, styles],
    textSelectionTheme: AppComponentThemes.textSelection(derived),
    progressIndicatorTheme: AppComponentThemes.progress(derived),
    dialogTheme: AppComponentThemes.dialog(scheme),
    datePickerTheme: AppComponentThemes.datePicker(scheme),
    timePickerTheme: AppComponentThemes.timePicker(scheme),
    textButtonTheme: AppComponentThemes.textButton(derived, styles),
  );
}
```

`lib/core/theme/theme_context.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// The one way a widget reads the design system: the scheme's 45 roles, the
/// type slots and the MemoX extensions of the current theme.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  MxTextStyles get textStyles => Theme.of(this).extension<MxTextStyles>()!;

  MxSemanticColors get semanticColors =>
      Theme.of(this).extension<MxSemanticColors>()!;

  MxDerivedColors get derivedColors =>
      Theme.of(this).extension<MxDerivedColors>()!;

  MxElevation get elevation => Theme.of(this).extension<MxElevation>()!;
}
```

- [ ] **Step 6: The app uses them**

In `lib/app/app.dart`:
- Add `import 'package:memox/core/theme/app_theme.dart';` in alphabetical order among the `package:memox/core/` imports.
- Replace
  ```dart
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
  ```
  with
  ```dart
        theme: _lightTheme,
        darkTheme: _darkTheme,
  ```
- Directly before the doc comment ``/// `system` follows the platform's brightness as it changes.``, add:
  ```dart
  /// DESIGN.md's two themes, built once: a new ThemeData each build would
  /// hand MaterialApp a new object on every settings change.
  final ThemeData _lightTheme = buildLightTheme();
  final ThemeData _darkTheme = buildDarkTheme();

  ```
- In the class doc comment, replace `The themes are Flutter's` / `/// Material 3 defaults until SP3a rebuilds them from DESIGN.md.` with `The themes are` / `/// DESIGN.md's, built in lib/core/theme (SP3a).`

- [ ] **Step 7: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/app`
Expected: all pass. In the prototype that was 9 + 4 + 9 theme tests and every `test/app` test, with the new appearance test among them.

Then:
- `flutter analyze` → `No issues found!`;
- guard → `Errors: 0 | Warnings: 0`.

- [ ] **Step 8: The gate, then commit**

Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`.

```bash
git add lib/core/theme lib/app/app.dart test/core/theme test/support/theme_colours.dart test/app/app_appearance_test.dart
git commit -m "$(cat <<'EOF2'
feat(sp3a): DESIGN.md's light and dark themes

The fifteen TextTheme slots from the type-slot table, withWeight moving
the variable font's wght axis, the MemoX component text styles,
appButtonStyle, the component themes of the surfaces Flutter draws itself,
buildLightTheme/buildDarkTheme and the context accessors. MemoxApp paints
them.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421
EOF2
)"
```

---

### Task 5: The primitive layer, the test harness and ADR-022

**Files:**
- Create:
  - `lib/shared/primitives/hit_target.dart`
  - `lib/shared/primitives/focus_ring.dart`
  - `lib/shared/primitives/pressable_surface.dart`
  - `test/support/design_system_harness.dart`
  - `docs/shared/decisions/ADR-022-lop-primitive-cua-design-system.md`
- Test:
  - `test/shared/primitives/hit_target_test.dart`
  - `test/shared/primitives/pressable_surface_test.dart`
- Modify:
  - `test/architecture/boundary_rules.dart`
  - `test/architecture/boundary_rules_test.dart`
  - `test/architecture/boundaries_test.dart`

**Interfaces:**
- Consumes:
  - Task 2: `AppSize.touchTarget`, `AppStroke`, `AppOpacity`, `AppSpacing`, `AppRadius`.
  - Task 4: `context.derivedColors`, `buildLightTheme`/`buildDarkTheme`.
- Produces (Part 2 builds on these):
  - `class HitTarget extends SingleChildRenderObjectWidget`: `HitTarget({required Widget child})`. It grows the hit area to at least 48×48 and sends a tap in the grown area to the child.
  - `class FocusRing extends StatelessWidget`: `FocusRing({required bool isVisible, required ShapeBorder shape, required Widget child})`. It paints the 2 dp primary-ink ring 2 dp outside `shape`.
  - `class PressableSurface extends StatefulWidget`, with:
    - `PressableSurface({required ShapeBorder shape, required Color inkColor, required Widget child, Color? color, VoidCallback? onTap, VoidCallback? onLongPress, EdgeInsetsGeometry padding = EdgeInsetsDirectional.zero, String? semanticLabel, bool isButton = true, bool shouldDimWhenDisabled = true})`;
    - with no action it is disabled: announced so, and dimmed to `AppOpacity.disabled` unless `shouldDimWhenDisabled` is false;
    - a `semanticLabel` replaces what the child announces.
  - In `test/support/design_system_harness.dart`:
    - `const designSystemTextScales = [1.0, 1.3, 1.5, 2.0]`;
    - `Future<void> pumpDesignSystem(WidgetTester, Widget, {Brightness brightness, Locale locale, double width = 360, double height = 800, double textScale = 1.0, TextDirection direction})`.
  - `List<String> primitiveViolations(List<SourceFile>)` in `boundary_rules.dart`.

- [ ] **Step 1: The harness and the failing tests**

`test/support/design_system_harness.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The text scales every design-system component is tested at
/// (spec 2026-10-04-sp3a D17).
const designSystemTextScales = [1.0, 1.3, 1.5, 2.0];

/// Pumps [child] the way the app would show it: in the light or dark theme,
/// the en or vi localization, a [width] dp wide phone screen, at
/// [textScale] and in [direction]. Every design-system test and golden goes
/// through here (spec §8.2).
Future<void> pumpDesignSystem(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double width = 360,
  double height = 800,
  double textScale = 1.0,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
```

`test/shared/primitives/hit_target_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/shared/primitives/hit_target.dart';

import '../../support/design_system_harness.dart';

void main() {
  testWidgets('a 28 dp control takes 48×48 and a tap at its edge lands', (
    tester,
  ) async {
    var taps = 0;
    await pumpDesignSystem(
      tester,
      HitTarget(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(width: 28, height: 28),
        ),
      ),
    );

    final box = tester.getRect(find.byType(HitTarget));
    expect(box.size, const Size(AppSize.touchTarget, AppSize.touchTarget));

    await tester.tapAt(box.topLeft + const Offset(2, 2));
    expect(taps, 1);

    await tester.tapAt(box.topLeft - const Offset(4, 4));
    expect(taps, 1, reason: 'a tap outside the 48 dp area is not the control');
  });

  testWidgets('a control already 48 or larger keeps its size', (tester) async {
    await pumpDesignSystem(
      tester,
      const HitTarget(child: SizedBox(width: 120, height: 56)),
    );

    expect(tester.getSize(find.byType(HitTarget)), const Size(120, 56));
  });
}
```

`test/shared/primitives/pressable_surface_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/shared/primitives/focus_ring.dart';
import 'package:memox/shared/primitives/pressable_surface.dart';

import '../../support/design_system_harness.dart';

final _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppRadius.md),
);

PressableSurface _surface({VoidCallback? onTap, Widget? child}) =>
    PressableSurface(
      shape: _shape,
      inkColor: const Color(0xFF000000),
      onTap: onTap,
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.gutter),
      semanticLabel: 'Open',
      child: child ?? const Text('Open the deck'),
    );

void main() {
  testWidgets('a tap runs the action, and the press inks at 12 %', (
    tester,
  ) async {
    var taps = 0;
    await pumpDesignSystem(tester, _surface(onTap: () => taps++));

    await tester.tap(find.text('Open the deck'));
    expect(taps, 1);
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(
      ink.overlayColor!.resolve({WidgetState.pressed}),
      const Color(0xFF000000).withValues(alpha: AppOpacity.pressed),
    );
  });

  testWidgets('without an action it is disabled: dimmed and announced so', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDesignSystem(tester, _surface());

    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      AppOpacity.disabled,
    );
    expect(
      tester.getSemantics(find.byType(PressableSurface)),
      matchesSemantics(
        label: 'Open',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('keyboard focus draws the ring, and only then', (tester) async {
    await pumpDesignSystem(tester, _surface(onTap: () {}));
    expect(tester.widget<FocusRing>(find.byType(FocusRing)).isVisible, isFalse);

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(tester.widget<FocusRing>(find.byType(FocusRing)).isVisible, isTrue);
  });

  testWidgets('start padding is on the right in a right-to-left layout', (
    tester,
  ) async {
    await pumpDesignSystem(
      tester,
      _surface(onTap: () {}),
      direction: TextDirection.rtl,
    );

    final surface = tester.getRect(find.byType(InkWell));
    final text = tester.getRect(find.text('Open the deck'));
    expect(surface.right - text.right, AppSpacing.gutter);
  });

  for (final scale in designSystemTextScales) {
    testWidgets('at text scale $scale it grows and keeps a 48 dp target', (
      tester,
    ) async {
      await pumpDesignSystem(
        tester,
        SizedBox(width: 320, child: _surface(onTap: () {})),
        width: 320,
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(PressableSurface));
      expect(size.height, greaterThanOrEqualTo(AppSize.touchTarget));
    });
  }
}
```

**Architecture.** In `test/architecture/boundary_rules_test.dart`, add this group as the last one in `main()`:

```dart
  group('primitives (ADR-022)', () {
    const primitive = 'package:memox/shared/primitives/pressable_surface.dart';

    test('the shared widgets and the primitives may import them', () {
      final sources = [
        _file('lib/shared/widgets/mx_card.dart', [primitive]),
        _file('lib/shared/primitives/focus_ring.dart', [primitive]),
      ];

      expect(primitiveViolations(sources), isEmpty);
    });

    test('a feature, the app or core importing them is rejected', () {
      final sources = [
        _file('lib/features/deck/presentation/screens/x_screen.dart', [
          primitive,
        ]),
        _file('lib/app/app.dart', [primitive]),
        _file('lib/core/theme/app_theme.dart', [primitive]),
      ];

      expect(primitiveViolations(sources), hasLength(3));
    });
  });
```

In `test/architecture/boundaries_test.dart`, directly before `test('the feature import map is acyclic', …)`, add:

```dart
  test('only the shared widgets import the primitive layer (ADR-022)', () {
    expect(primitiveViolations(sources), isEmpty);
  });

```

- [ ] **Step 2: Run them and watch them fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared test/architecture`
Expected: compile failures. The primitives and `primitiveViolations` do not exist.

- [ ] **Step 3: The primitives**

`lib/shared/primitives/hit_target.dart`:

```dart
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// Grows the touch area of a smaller painted control to 48×48 without
/// changing what it paints (DESIGN.md, The 48 Floor Rule). A tap anywhere in
/// the grown area lands on the control, as Material's padded tap target does.
class HitTarget extends SingleChildRenderObjectWidget {
  const HitTarget({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitTarget();
}

class _RenderHitTarget extends RenderShiftedBox {
  _RenderHitTarget() : super(null);

  static const double _floor = AppSize.touchTarget;

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(
        child.size.width < _floor ? _floor : child.size.width,
        child.size.height < _floor ? _floor : child.size.height,
      ),
    );
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Alignment.center.alongOffset(
      (size - child.size) as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    final center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child!.hitTest(result, position: center),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _atLeastFloor(child!.getMinIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _atLeastFloor(child!.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _atLeastFloor(child!.getMaxIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _atLeastFloor(child!.getMaxIntrinsicHeight(width));

  double _atLeastFloor(double value) => value < _floor ? _floor : value;
}
```

`lib/shared/primitives/focus_ring.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The 2 dp keyboard-focus ring, in the primary ink, drawn 2 dp outside
/// [shape] (DESIGN.md, Shapes). It paints over nothing and takes no space.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.isVisible,
    required this.shape,
    required this.child,
  });

  final bool isVisible;
  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: isVisible
        ? _RingPainter(shape, context.derivedColors.primaryInk)
        : null,
    child: child,
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.shape, this.color);

  final ShapeBorder shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppStroke.focusOffset + AppStroke.focus / 2;
    final rect = (Offset.zero & size).inflate(inset);
    canvas.drawPath(
      shape.getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.focus
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.shape != shape || old.color != color;
}
```

`lib/shared/primitives/pressable_surface.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/shared/primitives/focus_ring.dart';
import 'package:memox/shared/primitives/hit_target.dart';

/// The surface every tappable `Mx*` stands on (spec 2026-10-04-sp3a §6.2):
/// the decoration with the ink inside it, the pressed overlay at
/// `AppOpacity.pressed`, the focus ring, a 48 dp hit area, and, when
/// [onTap] is null, the disabled look at `AppOpacity.disabled`.
///
/// Internal to the design system: only `lib/shared/widgets/` imports it.
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.shape,
    required this.inkColor,
    required this.child,
    this.color,
    this.onTap,
    this.onLongPress,
    this.padding = EdgeInsetsDirectional.zero,
    this.semanticLabel,
    this.isButton = true,
    this.shouldDimWhenDisabled = true,
  });

  /// The outline of the surface; also the ink's clip and the ring's path.
  final ShapeBorder shape;

  /// The ground; null for a surface with no fill.
  final Color? color;

  /// The colour of the pressed overlay, at `AppOpacity.pressed`.
  final Color inkColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final bool isButton;

  /// A component that dims only part of itself when disabled (a settings
  /// row dims its tile and label, never the reason) sets this to false.
  final bool shouldDimWhenDisabled;
  final Widget child;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _isFocused = false;

  bool get _isEnabled => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final surface = Material(
      type: widget.color == null
          ? MaterialType.transparency
          : MaterialType.canvas,
      color: widget.color,
      shape: widget.shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        customBorder: widget.shape,
        onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? widget.inkColor.withValues(alpha: AppOpacity.pressed)
              : widget.inkColor.withValues(alpha: 0),
        ),
        child: Padding(
          padding: widget.padding,
          // A [semanticLabel] replaces what the child would announce.
          child: ExcludeSemantics(
            excluding: widget.semanticLabel != null,
            child: widget.child,
          ),
        ),
      ),
    );
    final dimmed = !_isEnabled && widget.shouldDimWhenDisabled;
    return Semantics(
      button: widget.isButton,
      enabled: _isEnabled,
      label: widget.semanticLabel,
      child: HitTarget(
        child: FocusRing(
          isVisible: _isFocused,
          shape: widget.shape,
          child: dimmed
              ? Opacity(opacity: AppOpacity.disabled, child: surface)
              : surface,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: The import rule**

In `test/architecture/boundary_rules.dart`, directly before the doc comment `/// ADR-011 D2: every cycle in [map], each written as \`a -> b -> a\`.`, add:

```dart
/// ADR-022: the primitive layer is internal to the design system. Only the
/// shared `Mx*` widgets and the primitives themselves import it.
List<String> primitiveViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (!_mayUsePrimitives(source.path))
      for (final uri in source.imports)
        if (uri.startsWith(_primitivesPackage)) '${source.path} imports $uri',
];

const _primitivesPackage = 'package:memox/shared/primitives/';

bool _mayUsePrimitives(String path) =>
    path.startsWith('lib/shared/widgets/') ||
    path.startsWith('lib/shared/primitives/');

```

- [ ] **Step 5: ADR-022**

`docs/shared/decisions/ADR-022-lop-primitive-cua-design-system.md`:

```markdown
---
id: ADR-022
title: Lớp primitive nội bộ của design system
status: accepted
superseded_by:
---
## Bối cảnh

SP3a ([spec](../../superpowers/specs/2026-10-04-sp3a-design-system-foundation-design.md), D16)
dựng design system theo thứ tự token → theme → primitive → `Mx*`. Primitive là khối dựng mà
nhiều `Mx*` cùng dùng: bề mặt nhấn được (ink nằm trong decoration, lớp phủ khi nhấn, vòng
focus, vùng chạm 48 dp), vòng focus và vùng chạm. Cây thư mục của
[ADR-011](ADR-011-cau-truc-thu-muc-v8.md) chỉ ghi `shared/widgets/`. Một thư mục mới có
ranh giới import riêng là một quyết định, nên được ghi ở ADR này thay vì sửa ADR-011.

## Quyết định

- `lib/shared/primitives/` chứa primitive của design system. Tên class không có tiền tố
  `Mx`, vì primitive không phải API công khai.
- Chỉ `lib/shared/widgets/` và chính `lib/shared/primitives/` được import thư mục này.
  Feature, `app/` và màn hình không import nó; `core/` không import `shared/` (ADR-011).
- `primitiveViolations` trong `test/architecture/boundary_rules.dart` kiểm luật này trên
  `lib/` thật, qua `boundaries_test.dart`.

## Hệ quả

- ADR này bổ sung ADR-011, không thay thế nó. Các quyết định khác của ADR-011 giữ nguyên.
- Màn hình cần hành vi của một primitive thì dùng `Mx*` bọc primitive đó. Nếu chưa có
  `Mx*` phù hợp, component được thêm vào `DESIGN.md` trước (spec D7).
```

- [ ] **Step 6: Run the tests and the checks**

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared test/architecture
flutter analyze
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 | tail -3
python3 tools/docs/generate.py && python3 tools/docs/check.py | tail -1
```

Expected:
- all tests pass:
  - `hit_target_test` 2;
  - `pressable_surface_test`: 4, plus 4 text scales;
  - the architecture suite, with the 3 new tests;
- analyze: `No issues found!`;
- guard: `Errors: 0 | Warnings: 0`. The `targets_pending` entries stay, because primitives are not in `widget_ui_files` (P7);
- docs: `PASS`.

- [ ] **Step 7: The gate, then commit**

Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`.

```bash
git add lib/shared test/shared test/support/design_system_harness.dart test/architecture \
  docs/shared/decisions/ADR-022-lop-primitive-cua-design-system.md docs/_generated
git commit -m "$(cat <<'EOF2'
feat(sp3a): the primitive layer, the design-system harness and ADR-022

HitTarget grows a small control's touch area to 48 dp, FocusRing draws
the 2 dp ring 2 dp out, and PressableSurface puts the ink inside the
decoration with the pressed overlay, the disabled look and the semantics.
pumpDesignSystem runs every component test in either theme, locale,
width, text scale and direction. ADR-022 records the folder and its
import boundary, which an architecture test enforces.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01PTeB2TNXWoBZfvGojSw421
EOF2
)"
```

---

## Part 2 outline (Tasks 6–12): written in full after Task 5

Part 2 gets its own plan file, `docs/superpowers/plans/2026-10-04-sp3a-design-system-foundation-part-2.md`. It is written against the real API Tasks 2–5 left behind, and the owner approves it before Task 6 starts. What it must hold:

**Every component task (6–9):**
- **Contract.** Each component meets spec §6.1 and its §6.3 row:
  - it composes Material and the Task 5 primitives;
  - it reads only `context.*` and the generated tokens;
  - variants are enums;
  - it takes no `Color`, `TextStyle`, `EdgeInsets`, radius or `BuildContext` parameter;
  - it holds no copy;
  - an icon-only control requires a `semanticLabel`;
  - booleans read as predicates;
  - one public class per file in `lib/shared/widgets/mx_<name>.dart`, with any `show…` function beside its widget.
- **Tests,** in `test/shared/widgets/mx_<name>_test.dart` through `pumpDesignSystem`:
  - every variant and every state of the §6.3 row;
  - `androidTapTargetGuideline`;
  - semantics: role, label and enabled state, plus read-only vs disabled for `MxTextField` (INV-UI-007);
  - at 320 dp and at each of `designSystemTextScales`, with an English and a Vietnamese label: no overflow, no clipped meaningful text, growth by contract, a 48 dp target, and the label kept;
  - light and dark.
- **Theme parity.** A component that mirrors a Material component adds that component's theme to `AppComponentThemes`, with a parity test (spec §8.1). The table is in `flutter-theme-design`.
- **Layer.** A fix lands at the lowest layer that can hold it (D3).

| Task | Components | Also |
|---|---|---|
| 6 | `MxButton`, `MxIconButton`, `MxFab`, `MxSheetActions` | The first file in `lib/shared/widgets/`. Remove the `targets_pending` entries the guard then reports stale. Expected: `no_flat_style_from`, `widget_no_database_access`, `widget_no_repository_access` (P7). |
| 7 | `MxCard`, `MxDialog` + `showMxDialog`, `MxBottomSheet` + `showMxBottomSheet`, `MxSnackbar` + `showMxSnackbar` | Snackbar: 4 s, or 8 s with Undo (INV-UI-003's timing). |
| 8 | `MxTextField` + `MxFieldMessage`, `MxSearchField` | Read-only vs disabled (INV-UI-007). The `code` variant's style joins `MxTextStyles` through DESIGN.md first (D7): its tracking is not in the frontmatter yet. |
| 9 | `MxListRow`, `MxEmptyState`, `MxErrorState`, `MxSpinner`, `MxSkeleton`, `MxAppBar`, `MxScreenScroll` | `MxScreenScroll` keeps the last item clear of the FAB (INV-UI-006) and the focused field above the keyboard (INV-UI-005). |
| 10 | Component goldens | Accept `mx_<component>__<state>__<variant>.png` in `tools/docs/check.py` for components DESIGN.md names, never as orphans, with tests first. Goldens light and dark at 360 dp and text scale 1.0, plus 2.0 for each component that wraps or stacks. Remove `no_goldens()` from `run_goldens.sh` once goldens exist (§11 row 2). Give the owner a `golden-compare` page. |
| 11 | Impeccable | Critique and audit of the goldens against DESIGN.md. One fix batch at the lowest layer, then one `impeccable audit`. A new token, role or component goes to DESIGN.md and the owner first. |
| 12 | Docs | The `flutter-design-system` and `flutter-theme-design` skills match the layout (`mx_<name>.dart`, `Mx*`, text scales, `showModalBottomSheet` banned). CLAUDE.md's "Known UI debt" and its "Where knowledge lives" row point at spec §11. Update the WBS SP3a row. |

Then comes the final whole-branch review on Opus, one fix pass for Critical and Important findings, the final gate, the owner's golden review and sign-off, and the APK build on the owner's side.
