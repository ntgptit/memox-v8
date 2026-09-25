# Material Component Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Material component themes of spec UI base §4.6, which were planned but never built.
- `ThemeData` carries the V3 global defaults.
- The `Mx*` widgets read those defaults instead of rebuilding them.

**Architecture:**
- A new `lib/core/theme/app_component_themes.dart` builds the component themes from `ColorScheme`, `TextTheme`, `MxSemanticColors` and the `App*` tokens.
- `app_theme.dart` merges them into `ThemeData`.
- The button style factory moves from `shared/` to `core/theme/`, so the theme and `MxButton` share one source.
- Richer MemoX variants stay in the widgets (spec §4.6):
  - button tones and sizes;
  - the editor field variants;
  - the dialog's width caps and entrance animation.

**Tech Stack:** Flutter 3.47.5 (Material 3), Dart 3.13.

**Spec:**
- `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §4.6 (and §2's "approach A": `ColorScheme` + `TextTheme` + component themes);
- `docs/shared/ui/design-handoff/02-theme-binding.md`, "Material component-theme policy".

## Global Constraints

- Guard `memox-v8` stays 0/0. `core/` never imports `shared/` or `features/`.
- **No visual change to any committed golden.** The refactor is proven by the golden suite in the Linux container passing with no PNG rewritten. A golden that changes is a finding, not an update.
- On Windows run `flutter test --exclude-tags golden`; goldens only in the container.
- Record every category that is *not* configured centrally, and why, in spec §4.6.

## Category decisions (the §4.6 inspection)

| Category | Central theme | Why |
|---|---|---|
| Text/input fields | `InputDecorationTheme` | Every field shares the fill, the ghost/primary/error edges, radius 12, `gapPadding: 0`, the hint style and 12 side padding. The editor variants override only the radius and the fill. |
| Buttons | `FilledButtonTheme` (primary), `OutlinedButtonTheme` (outline), `TextButtonTheme` (text ink) | Framework-built buttons (dialog actions, date picker, license page) and any raw button get the V3 shape, 48 height, label and pressed overlay. `MxButton` keeps its tone × size matrix. |
| Icon buttons | `IconButtonTheme` | `MxIconButton` is the theme's default: 20 glyph, 36 round ink, focus ring, 48 target. |
| Dialogs | `DialogTheme` | `surfaceContainerHigh`, radius 20, no elevation, 45% scrim, V3 title and body text for framework dialogs. `MxDialog` keeps its widths and entrance. |
| Bottom sheets | `BottomSheetThemeData` | `surfaceContainerHigh`, top radius 20, no elevation, 45% scrim. |
| Snackbar | `SnackBarThemeData` | `inverseSurface`, floating, radius 12, gutter margin and padding. |
| Switch, navigation bar, chip, progress | not configured | `MxToggle`, `MxBottomNav`, `MxFilterChip` and `MxSpinner` draw the kit's own controls, not Material's. No Material switch, navigation bar, chip or progress indicator appears in the app or in the framework screens it opens. M3's `ColorScheme`-derived defaults already hold should one appear. |

## Review Focus

1. **A framework dialog** (e.g. `showLicensePage`, `AlertDialog`) opened in the app uses the V3 surface, radius and scrim. Pinned in Task 3.
2. **A raw `TextField` under the theme** looks like the `form` `MxTextField`: fill, ghost edge, radius 12, no 4px gap. Pinned in Task 1.
3. **A raw `FilledButton`/`TextButton`** is 48 tall at the V3 shape and label. Pinned in Task 2.
4. **Every existing golden is unchanged**; the widgets draw the same pixels from the theme. Pinned in Task 4.
5. **Dark theme** builds the same component themes from the dark scheme. Pinned in Tasks 1–3 (tests run both themes).

---

### Task 1: `InputDecorationTheme`, consumed by `MxTextField` and `MxSearchField`

**Files:**
- Create: `lib/core/theme/app_component_themes.dart`
- Modify: `lib/core/theme/app_theme.dart`, `lib/shared/widgets/mx_text_field.dart`, `lib/shared/widgets/mx_search_field.dart`
- Test: `test/core/theme/app_component_themes_test.dart`

**Interfaces:**
- Produces:
  - `InputDecorationTheme appInputDecorationTheme(ColorScheme scheme, MxSemanticColors semantic, TextTheme texts)`;
  - `ThemeData.inputDecorationTheme` set in `_build`.

- [ ] **Step 1: Write the failing test.** For light and dark, a bare `TextField(decoration: InputDecoration(hintText: 'x'))` under `buildLightTheme()`/`buildDarkTheme()` has:
  - `filled`, fill `surfaceContainerLow` at rest and `surfaceContainerLowest` focused;
  - an enabled `OutlineInputBorder` in `ghostBorder`, hairline, radius 12, `gapPadding` 0;
  - a focused edge in `primary`;
  - a hint in `inputHint`.
- [ ] **Step 2: Run it.** Expected: FAIL (M3 default underline/fill).
- [ ] **Step 3: Implement** `appInputDecorationTheme`:
  - `filled: true`, `isDense: true`;
  - `fillColor` as a `WidgetStateColor` (focused → lowest, else low);
  - `contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.grouped)`;
  - `border`/`enabledBorder`/`disabledBorder` ghost;
  - `focusedBorder` primary;
  - `errorBorder`/`focusedErrorBorder` error;
  - all `OutlineInputBorder(gapPadding: 0, radius: AppRadius.md, width: AppStroke.hairline)`;
  - `hintStyle` 14/400 `onSurfaceVariant`.

  Wire it in `_build`.
- [ ] **Step 4: Consume it.**
  - `MxTextField` keeps only what differs:
    - vertical padding;
    - the editor variants' radius, taken as `theme.enabledBorder.copyWith(borderRadius:)`;
    - the editor fill;
    - the error edge when `errorText != null`;
    - the term hint.
  - `MxSearchField` drops its edge builder and keeps only its `surfaceContainer` fill, prefix and suffix.
- [ ] **Step 5: Run** `flutter test test/core test/shared --exclude-tags golden`. Expected: PASS.
- [ ] **Step 6: Commit** `feat(theme): InputDecorationTheme carries the V3 field; MxTextField and MxSearchField read it`.

### Task 2: Button themes from one style factory

**Files:**
- Move: `lib/shared/widgets/mx_button_style.dart` → `lib/core/theme/app_button_style.dart` (`mxButtonStyle` → `appButtonStyle`, same signature)
- Modify: `app_component_themes.dart`, `app_theme.dart`, `mx_button.dart`, `mx_filter_chip.dart`, `mx_snackbar.dart`, `mx_icon_button.dart`
- Test: `test/core/theme/app_component_themes_test.dart`

**Interfaces:**
- Produces: `ButtonStyle appButtonStyle({...})` in core. `filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme` and `iconButtonTheme` are set in `_build`.

- [ ] **Step 1: Write the failing tests** (both themes):
  - a bare `FilledButton` is 48 tall in `primary`/`onPrimary` with the `buttonLabel` style;
  - a bare `OutlinedButton` has the outline edge;
  - a bare `TextButton` inks `primary` with no fill;
  - a bare `IconButton` has a 20 glyph in a 36 circle with a 48 target.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Move the factory (`git mv`) and fix its imports.
  - Build the four themes from `appButtonStyle`, using the regular size and the primary, outline and text tones' values that `MxButton` uses today.
  - `iconButtonTheme` carries `MxIconButton`'s current `ButtonStyle`.
  - `MxIconButton` drops its local style and reads the theme.
  - `MxButton`, `MxFilterChip` and the snackbar action import the factory from core.
- [ ] **Step 4: Run** `flutter test test/core test/shared test/features --exclude-tags golden`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(theme): button and icon-button themes from the V3 style factory`.

### Task 3: Dialog, bottom-sheet and snackbar themes

**Files:**
- Modify: `app_component_themes.dart`, `app_theme.dart`, `mx_dialog.dart`, `mx_bottom_sheet.dart`, `mx_snackbar.dart`
- Test: `test/core/theme/app_component_themes_test.dart`

- [ ] **Step 1: Write the failing tests** (both themes):
  - `showDialog` with an `AlertDialog`: surface `surfaceContainerHigh`, radius 20, elevation 0, barrier at 45% scrim;
  - `showModalBottomSheet`: same surface, top radius 20;
  - a bare `SnackBar`: `inverseSurface`, floating, radius 12.
- [ ] **Step 2: Run them.** Expected: FAIL.
- [ ] **Step 3: Implement.**
  - `DialogThemeData`: `backgroundColor`, `shape`, `elevation: 0`, `barrierColor`, `titleTextStyle`, `contentTextStyle`.
  - `BottomSheetThemeData`: `backgroundColor`, `shape`, `elevation: 0`, `modalBarrierColor`.
  - `SnackBarThemeData`: `backgroundColor`, `behavior`, `shape`, `insetPadding`.
  - Each `Mx*` reads its values from `Theme.of(context).…Theme`, keeping only its own variants:
    - `MxDialog`: widths, entrance, shadow;
    - `MxBottomSheet`: max height, grabber, shadow;
    - `MxSnackbar`: content layout.
- [ ] **Step 4: Run** `flutter test --exclude-tags golden`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(theme): dialog, bottom sheet and snackbar themes`.

### Task 4: Spec, goldens, gate

- [ ] **Step 1:** Amend spec §4.6 with the category table above. Add a `lib/core/theme/app_component_themes.dart` line to the §3 tree if it is absent.
- [ ] **Step 2:** Windows gate:
  - format, analyze, guard 0/0;
  - architecture check;
  - `flutter test --exclude-tags golden`;
  - docs check.
- [ ] **Step 3:** Run the golden suite in the container **without** `--update-goldens`. Expected: green, no PNG changed. Any failure is a regression to fix, not a golden to update.
- [ ] **Step 4:** Commit `docs(ui): §4.6 component-theme decisions`; final review (opus); PR after the owner's popup.
