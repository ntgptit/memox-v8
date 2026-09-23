# Flutter UI Base — Phase 1 (Theme Foundations) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `lib/core/theme/`, the complete light and dark MemoX V3 theme (ColorScheme, TextTheme, semantic extension, derived colours, tokens, shadows), with the Plus Jakarta Sans font bundled, so phase 2 can build `Mx*` components on it.

**Architecture:** Material 3 `ThemeData` is the spine: a seeded `ColorScheme` with every V3-defined role set explicitly, a `TextTheme` binding the seven V3 type roles, and one `ThemeExtension` (`MxSemanticColors`) holding only the nine `BIND_NOW` product colours. Derived colours are computed once in `MxDerivedColors`. Spacing, radius, size, stroke, opacity, effect and duration values are `abstract final class` constants in `core/theme/foundations/`. Nothing in `lib/app/` or `lib/shared/` is created in this phase; the theme is exercised by tests only.

**Tech Stack:** Flutter 3.47.5 (pinned in `.fvmrc`), Dart ^3.13.4, Material 3, `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`](../specs/2026-09-23-flutter-ui-base-design.md) §4, §8.1 phase 1, §8.2 "Theme", §8.3. Values come from [`01-foundations.md`](../../shared/ui/design-handoff/01-foundations.md) and [`02-theme-binding.md`](../../shared/ui/design-handoff/02-theme-binding.md).

## Global Constraints

- UI only: no file under `lib/features/`, `lib/core/database/`, `lib/core/error/`, `lib/core/id/`, `lib/app/` or `lib/shared/` is created or changed.
- `lib/core/theme/` imports only `package:flutter/*` and other `lib/core/theme/` files (ADR-011: `core/` imports no feature, `app/` or `shared/`).
- Every `import` of a `lib/` file uses `package:memox/...` (`always_use_package_imports`).
- Never write `fontWeight: FontWeight.<x>` anywhere under `lib/core/theme/`; set weights through `AppTypography.withWeight` (guard `memox_v7.design_system.no_bare_font_weight`).
- A `Duration` constant is declared as `static const Duration name = Duration(...)` (guard `memox.design_token.no_raw_duration` exempts exactly that shape).
- Never name a variable `scheme`, `colors` or `colorScheme` unless it is a `ColorScheme`: the guard reads every `<that name>.<member>` as a ColorScheme role (`color_scheme_reads_are_m3_roles`).
- A `ColorScheme` constructor or `copyWith` receives only the 45 M3 role names plus `brightness`.
- Handoff values are implemented as written, including the known contrast debt (spec §9). Do not "fix" a value.
- Commit messages: conventional commits, scope `theme`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Reply language to the user is Vietnamese; code, comments and commits are English.

## Review Focus

1. **Variable-font weight drift.** A `TextTheme` slot outside the seven V3 roles (for example `bodySmall`, `labelLarge`) must render at its declared weight, not at the variable font's default instance. Pinned by the "every slot moves the wght axis with its weight" test in Task 5.
2. **MasteryRamp band edges and bad input.** `0.34` is the first reviewing value, `0.67` the first mastered value, `0` paints no fill, and `NaN`, negatives and values above `1` are rejected rather than painted. Pinned in Task 4.
3. **Derived colour base per theme.** `surfaceHero` blends over `surfaceBright` in light and over `surface` in dark. A single base would still pass a light-only test. Pinned by the per-theme expectations in Task 4.
4. **Theme animation.** `MaterialApp` lerps `ThemeData` when the platform brightness changes, and a broken `MxSemanticColors.lerp` or a missing extension only shows then. Pinned by the `ThemeData.lerp(light, dark, 0.5)` test in Task 6.
5. **Theme without the extension.** A widget reading `context.semanticColors` under a plain `ThemeData()` (a test harness, a future dialog with its own `Theme`) must fail with a message naming the fix, not a bare null-check error. Pinned in Task 6.

---

## File Structure

```
pubspec.yaml                                        + fonts: PlusJakartaSans
assets/fonts/PlusJakartaSans-Variable.ttf           the variable font (wght axis)
assets/fonts/OFL.txt                                its licence
lib/core/theme/foundations/app_spacing.dart         AppSpacing
lib/core/theme/foundations/app_radius.dart          AppRadius
lib/core/theme/foundations/app_size.dart            AppSize
lib/core/theme/foundations/app_icon_size.dart       AppIconSize
lib/core/theme/foundations/app_stroke.dart          AppStroke
lib/core/theme/foundations/app_opacity.dart         AppOpacity (state tokens)
lib/core/theme/foundations/app_effects.dart         AppEffects (glass)
lib/core/theme/foundations/app_durations.dart       AppDurations
lib/core/theme/foundations/app_shadows.dart         AppShadows
lib/core/theme/app_color_schemes.dart               AppColorSchemes.light / .dark
lib/core/theme/mx_semantic_colors.dart              MxSemanticColors (ThemeExtension)
lib/core/theme/mx_derived_colors.dart               MxDerivedColors
lib/core/theme/mastery_ramp.dart                    MasteryRamp
lib/core/theme/app_typography.dart                  AppTypography
lib/core/theme/app_theme.dart                       buildLightTheme() / buildDarkTheme()
lib/core/theme/theme_context.dart                   ThemeContext extension on BuildContext
code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml   − 3 stale entries
test/support/color_matchers.dart                    isColorCloseTo
test/core/theme/foundations_test.dart
test/core/theme/app_shadows_test.dart
test/core/theme/app_color_schemes_test.dart
test/core/theme/mx_semantic_colors_test.dart
test/core/theme/mx_derived_colors_test.dart
test/core/theme/mastery_ramp_test.dart
test/core/theme/app_typography_test.dart
test/core/theme/app_theme_test.dart
```

`app_icons.dart` and `app_component_themes.dart` are not created here. Each arrives in phase 2 with the first component that reads it (spec §3, §4.6).

---

### Task 1: Toolchain precondition

No code and no commit. The pubspec requires Dart `^3.13.4`. On 2026-09-23 this machine ran Flutter 3.44.8 (Dart 3.12.2), where `flutter pub get` fails with "memox requires SDK version ^3.13.4".

- [ ] **Step 1: Check the pinned Flutter**

Run: `bash .claude/skills/flutter-workflow/scripts/check_flutter_version.sh`
Expected: exit 0 (Flutter 3.47.5). If it fails, stop and ask the user to install Flutter 3.47.5, then re-run. Installing an SDK changes the user's machine, so the executor does not do it unasked.

- [ ] **Step 2: Resolve packages and confirm the baseline gate is green**

Run each, all must exit 0:

```bash
flutter pub get
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Use a Python 3.12+ that has `code-verification-guard-v2/requirements-dev.txt` installed. On this machine that is `python` (3.14); the `python3.13` Store stub lacks `typer`. Expected guard summary before any change: `Errors: 0 | Warnings: 0 | Info: 40`.

---

### Task 2: Foundation tokens and the guard entries they retire

**Files:**
- Create: `lib/core/theme/foundations/app_spacing.dart`, `app_radius.dart`, `app_size.dart`, `app_icon_size.dart`, `app_stroke.dart`, `app_opacity.dart`, `app_effects.dart`, `app_durations.dart`
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml:51-52,68-69,72-73`
- Test: `test/core/theme/foundations_test.dart`

**Interfaces:**
- Produces (used by Tasks 3–6 and phase 2):
  - `AppSpacing.micro/control/grouped/gutter/card/section/major/pageEnd` (`double`)
  - `AppRadius.xs/sm/md/lg/xl/full` (`double`)
  - `AppSize.buttonRegular/buttonSmall/buttonCompact/chip/input/iconButtonInk/touchTarget/listRowMin/appBar/bottomNavBlock/bottomNavBar/fab` (`double`)
  - `AppIconSize.inline/compact/standard/large/illustrative` (`double`)
  - `AppStroke.hairline/focus/focusOffset` (`double`)
  - `AppOpacity.disabled/pressed` (`double`)
  - `AppEffects.glassOpacity/glassBlur` (`double`)
  - `AppDurations.toggle/standard/scrimFade/sheet/spinnerCycle/skeletonPulse` (`Duration`)

- [ ] **Step 1: Write the failing test**

`test/core/theme/foundations_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

// Pins the V3 foundations values (01-foundations.md). A change here is a
// design change and must come from the handoff, not from a call site.
void main() {
  test('spacing is the V3 rhythm', () {
    expect(
      [
        AppSpacing.micro,
        AppSpacing.control,
        AppSpacing.grouped,
        AppSpacing.gutter,
        AppSpacing.card,
        AppSpacing.section,
        AppSpacing.major,
        AppSpacing.pageEnd,
      ],
      [4, 8, 12, 16, 20, 24, 32, 48],
    );
  });

  test('radius roles are the V3 call sites', () {
    expect(
      [
        AppRadius.xs,
        AppRadius.sm,
        AppRadius.md,
        AppRadius.lg,
        AppRadius.xl,
        AppRadius.full,
      ],
      [4, 8, 12, 16, 20, 999],
    );
  });

  test('component geometry is the V3 dimension table', () {
    expect(AppSize.buttonRegular, 48);
    expect(AppSize.buttonSmall, 36);
    expect(AppSize.buttonCompact, 32);
    expect(AppSize.chip, 28);
    expect(AppSize.input, 52);
    expect(AppSize.iconButtonInk, 36);
    expect(AppSize.touchTarget, 48);
    expect(AppSize.listRowMin, 48);
    expect(AppSize.appBar, 56);
    expect(AppSize.bottomNavBlock, 80);
    expect(AppSize.bottomNavBar, 64);
    expect(AppSize.fab, 52);
  });

  test('icon sizes are the V3 roles and never below 16', () {
    expect(
      [
        AppIconSize.inline,
        AppIconSize.compact,
        AppIconSize.standard,
        AppIconSize.large,
        AppIconSize.illustrative,
      ],
      [16, 20, 24, 32, 40],
    );
  });

  test('strokes, state opacities and glass effect', () {
    expect(AppStroke.hairline, 1);
    expect(AppStroke.focus, 2);
    expect(AppStroke.focusOffset, 2);
    expect(AppOpacity.disabled, 0.38);
    expect(AppOpacity.pressed, 0.12);
    expect(AppEffects.glassOpacity, 0.84);
    expect(AppEffects.glassBlur, 18);
  });

  test('durations are the ones the widget contracts state', () {
    expect(AppDurations.toggle, const Duration(milliseconds: 160));
    expect(AppDurations.standard, const Duration(milliseconds: 200));
    expect(AppDurations.scrimFade, const Duration(milliseconds: 220));
    expect(AppDurations.sheet, const Duration(milliseconds: 260));
    expect(AppDurations.spinnerCycle, const Duration(milliseconds: 800));
    expect(AppDurations.skeletonPulse, const Duration(milliseconds: 1400));
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/theme/foundations_test.dart`
Expected: FAIL — compilation error, `app_durations.dart` (and the others) not found.

- [ ] **Step 3: Write the token files**

`lib/core/theme/foundations/app_spacing.dart`:

```dart
/// V3 spacing rhythm: gap, padding and inset only. Component size is
/// [AppSize]'s, not this scale's.
abstract final class AppSpacing {
  /// Icon-to-label, inside a chip.
  static const double micro = 4;

  /// Button padding, tight stacks.
  static const double control = 8;

  /// Related rows inside one block.
  static const double grouped = 12;

  /// Horizontal screen padding and the gap between list items.
  static const double gutter = 16;

  /// Card and sheet interior.
  static const double card = 20;

  /// Between sections of a screen.
  static const double section = 24;

  /// Between major visual groups.
  static const double major = 32;

  /// Scroll tail above pinned chrome, so the last item is never trapped.
  static const double pageEnd = 48;
}
```

`lib/core/theme/foundations/app_radius.dart`:

```dart
/// V3 radius roles. 24 and 28 exist in the kit but have no call site in V3,
/// so they are not declared.
abstract final class AppRadius {
  /// 20px checkbox.
  static const double xs = 4;

  /// 28 icon tile, compact button.
  static const double sm = 8;

  /// Button, input, note, snackbar, 36–44 icon tile, small controls.
  static const double md = 12;

  /// FAB, bottom-nav bar.
  static const double lg = 16;

  /// Card, dialog, bottom-sheet top corners, 64 empty-state tile.
  static const double xl = 20;

  /// Pill: chip, badge, toggle track, sheet grabber, progress track.
  static const double full = 999;
}
```

`lib/core/theme/foundations/app_size.dart`:

```dart
/// V3 component geometry. Heights around text are minimums: a wrapped label
/// or OS text scaling grows the box. The painted size and the touch area are
/// separate; [touchTarget] is the minimum interactive region for everything.
abstract final class AppSize {
  static const double buttonRegular = 48;
  static const double buttonSmall = 36;
  static const double buttonCompact = 32;

  /// Chip and filter chip. Fixed: a chip never wraps, its row scrolls.
  static const double chip = 28;

  /// Text field and search field.
  static const double input = 52;

  /// The painted circle of an icon button only; the hit area is [touchTarget].
  static const double iconButtonInk = 36;

  static const double touchTarget = 48;

  /// A list row grows to two title lines from here.
  static const double listRowMin = 48;

  static const double appBar = 56;

  /// The bottom-nav block; the bar itself is drawn at [bottomNavBar].
  static const double bottomNavBlock = 80;
  static const double bottomNavBar = 64;

  /// Square, icon only. V3 has no extended FAB.
  static const double fab = 52;
}
```

`lib/core/theme/foundations/app_icon_size.dart`:

```dart
/// V3 icon sizes. Nothing goes below [inline]. The visual size never sets the
/// touch area; see AppSize.touchTarget.
abstract final class AppIconSize {
  /// Inside body text, compact utility.
  static const double inline = 16;

  /// Dense rows, metadata, nav glyphs, FAB glyph.
  static const double compact = 20;

  /// App-bar and navigation actions.
  static const double standard = 24;

  /// Feature tiles.
  static const double large = 32;

  /// Empty states, hero marks.
  static const double illustrative = 40;
}
```

`lib/core/theme/foundations/app_stroke.dart`:

```dart
/// Stroke widths. A component contract that states another width adds a
/// named rung here in the phase that builds that component.
abstract final class AppStroke {
  /// The 1px border on cards, inputs and dividers.
  static const double hairline = 1;

  /// The focus ring, one treatment for every control.
  static const double focus = 2;

  /// Gap between a control and its focus ring.
  static const double focusOffset = 2;
}
```

`lib/core/theme/foundations/app_opacity.dart`:

```dart
/// Global interaction-state tokens (02-theme-binding STATE_TOKEN). Applied
/// once by the state policy, never as a colour. Hover is web-only and not
/// implemented on Android.
abstract final class AppOpacity {
  /// Over the whole control, one value everywhere.
  static const double disabled = 0.38;

  /// The platform pressed overlay.
  static const double pressed = 0.12;
}
```

`lib/core/theme/foundations/app_effects.dart`:

```dart
/// Visual effect configuration (02-theme-binding EFFECT_TOKEN). Translucency,
/// not interaction, so it lives outside [AppOpacity].
abstract final class AppEffects {
  /// Alpha of the bottom-nav glass surface.
  static const double glassOpacity = 0.84;

  /// Backdrop blur sigma behind the glass. The CSS saturate(180%) part of the
  /// source filter has no cheap Flutter equivalent and is dropped (spec §4.4).
  static const double glassBlur = 18;
}
```

`lib/core/theme/foundations/app_durations.dart`:

```dart
/// Every duration a V3 widget contract states, named by what moves.
abstract final class AppDurations {
  /// Toggle track colour and thumb offset.
  static const Duration toggle = Duration(milliseconds: 160);

  /// Dialog scale-in, snackbar sheet-in, study progress fill.
  static const Duration standard = Duration(milliseconds: 200);

  /// Modal scrim fade-in.
  static const Duration scrimFade = Duration(milliseconds: 220);

  /// Bottom sheet translate-in.
  static const Duration sheet = Duration(milliseconds: 260);

  /// One spinner revolution.
  static const Duration spinnerCycle = Duration(milliseconds: 800);

  /// One skeleton pulse, 0.45 to 0.75 opacity and back.
  static const Duration skeletonPulse = Duration(milliseconds: 1400);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/theme/foundations_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Retire the guard entries these files give a target**

Run: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: `stale_targets_pending` warnings for exactly `memox.design_token.no_raw_duration`, `memox.design_token.no_raw_stroke_width` and `memox_v7.design_system.no_bare_font_weight`. `lib/core/theme/` is in their scopes `ui_and_theme_surfaces` and `typography_and_theme_surfaces`. If the list differs, stop and report it.

In `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`, delete these six lines and nothing else:

```yaml
    memox_v7.design_system.no_bare_font_weight:
      targets_pending: app
```

```yaml
    memox.design_token.no_raw_duration:
      targets_pending: presentation
```

```yaml
    memox.design_token.no_raw_stroke_width:
      targets_pending: presentation
```

Re-run the guard. Expected: `Errors: 0 | Warnings: 0`.

- [ ] **Step 6: Run the phase gate**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
```

Expected: all exit 0, and `dart format` changes nothing.

- [ ] **Step 7: Commit**

```bash
git add lib/core/theme/foundations test/core/theme/foundations_test.dart code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(theme): V3 foundation tokens; retire three stale guard pendings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Colour schemes and shadows

**Files:**
- Create: `lib/core/theme/app_color_schemes.dart`, `lib/core/theme/foundations/app_shadows.dart`
- Test: `test/core/theme/app_color_schemes_test.dart`, `test/core/theme/app_shadows_test.dart`

**Interfaces:**
- Consumes: nothing from Task 2.
- Produces:
  - `AppColorSchemes.light` and `AppColorSchemes.dark` (`ColorScheme`, `static final`)
  - `AppColorSchemes.seed` (`Color`, `#5265F5`)
  - `AppShadows.whisper(ColorScheme)`, `.overlay(ColorScheme)`, `.chrome(ColorScheme)`, `.fab(ColorScheme)`, each `List<BoxShadow>`

- [ ] **Step 1: Write the failing colour-scheme test**

`test/core/theme/app_color_schemes_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';

// Every V3_DEFINED role from 02-theme-binding.md, light then dark.
const _v3Roles = <String, (int, int)>{
  'primary': (0xFF5265F5, 0xFF8B9AFF),
  'onPrimary': (0xFFFFFFFF, 0xFF11173A),
  'primaryContainer': (0xFFE0E5FE, 0xFF2D346A),
  'onPrimaryContainer': (0xFF1A2580, 0xFFD9DFFF),
  'secondary': (0xFF6E7CD9, 0xFF9DA8E8),
  'onSecondary': (0xFFFFFFFF, 0xFF1A2150),
  'secondaryContainer': (0xFFE3E6F7, 0xFF343C78),
  'onSecondaryContainer': (0xFF262E6E, 0xFFDDE2FB),
  'tertiary': (0xFF8B6FF5, 0xFFB5A0FF),
  'onTertiary': (0xFFFFFFFF, 0xFF240B63),
  'tertiaryContainer': (0xFFEBE3FE, 0xFF443078),
  'onTertiaryContainer': (0xFF33177E, 0xFFE6DCFF),
  'error': (0xFFDC2D4E, 0xFFFF8FA3),
  'onError': (0xFFFFFFFF, 0xFF52061B),
  'errorContainer': (0xFFFBDDE3, 0xFF7A2036),
  'onErrorContainer': (0xFF7A0A23, 0xFFFFD9DF),
  'surfaceDim': (0xFFDAE0EF, 0xFF060925),
  'surface': (0xFFF7F9FE, 0xFF0A0E27),
  'surfaceBright': (0xFFFFFFFF, 0xFF232B5A),
  'surfaceContainerLowest': (0xFFFFFFFF, 0xFF131A3A),
  'surfaceContainerLow': (0xFFF1F4FB, 0xFF1B2249),
  'surfaceContainer': (0xFFE9EDF7, 0xFF232B5A),
  'surfaceContainerHigh': (0xFFE2E7F3, 0xFF2C356E),
  'surfaceContainerHighest': (0xFFDAE0EF, 0xFF353D7E),
  'onSurface': (0xFF0F1638, 0xFFE4E8FA),
  'onSurfaceVariant': (0xFF4A5278, 0xFFA4ACD0),
  'outline': (0xFF7C85AB, 0xFF5A6BAE),
  'outlineVariant': (0xFFC5CBE3, 0xFF2A3267),
  'inverseSurface': (0xFF34395D, 0xFF34395D),
  'onInverseSurface': (0xFFE8EAFC, 0xFFE8EAFC),
  'inversePrimary': (0xFF8B9AFF, 0xFF5265F5),
  'scrim': (0xFF0A0E27, 0xFF000000),
  'shadow': (0xFF0F1638, 0xFF000000),
};

final _read = <String, Color Function(ColorScheme)>{
  'primary': (s) => s.primary,
  'onPrimary': (s) => s.onPrimary,
  'primaryContainer': (s) => s.primaryContainer,
  'onPrimaryContainer': (s) => s.onPrimaryContainer,
  'secondary': (s) => s.secondary,
  'onSecondary': (s) => s.onSecondary,
  'secondaryContainer': (s) => s.secondaryContainer,
  'onSecondaryContainer': (s) => s.onSecondaryContainer,
  'tertiary': (s) => s.tertiary,
  'onTertiary': (s) => s.onTertiary,
  'tertiaryContainer': (s) => s.tertiaryContainer,
  'onTertiaryContainer': (s) => s.onTertiaryContainer,
  'error': (s) => s.error,
  'onError': (s) => s.onError,
  'errorContainer': (s) => s.errorContainer,
  'onErrorContainer': (s) => s.onErrorContainer,
  'surfaceDim': (s) => s.surfaceDim,
  'surface': (s) => s.surface,
  'surfaceBright': (s) => s.surfaceBright,
  'surfaceContainerLowest': (s) => s.surfaceContainerLowest,
  'surfaceContainerLow': (s) => s.surfaceContainerLow,
  'surfaceContainer': (s) => s.surfaceContainer,
  'surfaceContainerHigh': (s) => s.surfaceContainerHigh,
  'surfaceContainerHighest': (s) => s.surfaceContainerHighest,
  'onSurface': (s) => s.onSurface,
  'onSurfaceVariant': (s) => s.onSurfaceVariant,
  'outline': (s) => s.outline,
  'outlineVariant': (s) => s.outlineVariant,
  'inverseSurface': (s) => s.inverseSurface,
  'onInverseSurface': (s) => s.onInverseSurface,
  'inversePrimary': (s) => s.inversePrimary,
  'scrim': (s) => s.scrim,
  'shadow': (s) => s.shadow,
};

void main() {
  test('brightness matches each theme', () {
    expect(AppColorSchemes.light.brightness, Brightness.light);
    expect(AppColorSchemes.dark.brightness, Brightness.dark);
  });

  for (final MapEntry(key: role, value: (light, dark)) in _v3Roles.entries) {
    test('$role is the V3 value in both themes', () {
      expect(_read[role]!(AppColorSchemes.light).toARGB32(), light);
      expect(_read[role]!(AppColorSchemes.dark).toARGB32(), dark);
    });
  }

  test('inverseSurface pair is invariant across themes', () {
    expect(AppColorSchemes.light.inverseSurface,
        AppColorSchemes.dark.inverseSurface);
    expect(AppColorSchemes.light.onInverseSurface,
        AppColorSchemes.dark.onInverseSurface);
  });

  test('roles V3 leaves open keep the seed-generated value (REPO_PRESERVED)',
      () {
    for (final brightness in Brightness.values) {
      final seeded = ColorScheme.fromSeed(
        seedColor: AppColorSchemes.seed,
        brightness: brightness,
      );
      final actual = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      expect(actual.primaryFixed, seeded.primaryFixed);
      expect(actual.primaryFixedDim, seeded.primaryFixedDim);
      expect(actual.onPrimaryFixed, seeded.onPrimaryFixed);
      expect(actual.onPrimaryFixedVariant, seeded.onPrimaryFixedVariant);
      expect(actual.secondaryFixed, seeded.secondaryFixed);
      expect(actual.secondaryFixedDim, seeded.secondaryFixedDim);
      expect(actual.onSecondaryFixed, seeded.onSecondaryFixed);
      expect(actual.onSecondaryFixedVariant, seeded.onSecondaryFixedVariant);
      expect(actual.tertiaryFixed, seeded.tertiaryFixed);
      expect(actual.tertiaryFixedDim, seeded.tertiaryFixedDim);
      expect(actual.onTertiaryFixed, seeded.onTertiaryFixed);
      expect(actual.onTertiaryFixedVariant, seeded.onTertiaryFixedVariant);
    }
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/theme/app_color_schemes_test.dart`
Expected: FAIL — `app_color_schemes.dart` not found.

- [ ] **Step 3: Write `app_color_schemes.dart`**

`lib/core/theme/app_color_schemes.dart`:

```dart
import 'package:flutter/material.dart';

/// Tokyo Pure Light and Tokyo Nebula, the two V3 themes (01-foundations.md).
///
/// Each scheme is seeded from [seed] and then given every role V3 defines. The
/// roles V3 leaves open (the *Fixed family) keep the seed-generated value:
/// that is the handoff's REPO_PRESERVED disposition, and no V3 colour is
/// invented for them. Both themes use the same seed so the Fixed family, which
/// M3 defines as theme-independent, stays the same in both.
abstract final class AppColorSchemes {
  /// The V3 light primary, the brand indigo.
  static const Color seed = Color(0xFF5265F5);

  // The one intentionally invariant pair (02-theme-binding.md).
  static const Color _inverseSurface = Color(0xFF34395D);
  static const Color _onInverseSurface = Color(0xFFE8EAFC);

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed)
      .copyWith(
    primary: seed,
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFE0E5FE),
    onPrimaryContainer: const Color(0xFF1A2580),
    secondary: const Color(0xFF6E7CD9),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFFE3E6F7),
    onSecondaryContainer: const Color(0xFF262E6E),
    tertiary: const Color(0xFF8B6FF5),
    onTertiary: const Color(0xFFFFFFFF),
    tertiaryContainer: const Color(0xFFEBE3FE),
    onTertiaryContainer: const Color(0xFF33177E),
    error: const Color(0xFFDC2D4E),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFBDDE3),
    onErrorContainer: const Color(0xFF7A0A23),
    surfaceDim: const Color(0xFFDAE0EF),
    surface: const Color(0xFFF7F9FE),
    surfaceBright: const Color(0xFFFFFFFF),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF1F4FB),
    surfaceContainer: const Color(0xFFE9EDF7),
    surfaceContainerHigh: const Color(0xFFE2E7F3),
    surfaceContainerHighest: const Color(0xFFDAE0EF),
    onSurface: const Color(0xFF0F1638),
    onSurfaceVariant: const Color(0xFF4A5278),
    outline: const Color(0xFF7C85AB),
    outlineVariant: const Color(0xFFC5CBE3),
    inverseSurface: _inverseSurface,
    onInverseSurface: _onInverseSurface,
    inversePrimary: const Color(0xFF8B9AFF),
    scrim: const Color(0xFF0A0E27),
    shadow: const Color(0xFF0F1638),
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF8B9AFF),
    onPrimary: const Color(0xFF11173A),
    primaryContainer: const Color(0xFF2D346A),
    onPrimaryContainer: const Color(0xFFD9DFFF),
    secondary: const Color(0xFF9DA8E8),
    onSecondary: const Color(0xFF1A2150),
    secondaryContainer: const Color(0xFF343C78),
    onSecondaryContainer: const Color(0xFFDDE2FB),
    tertiary: const Color(0xFFB5A0FF),
    onTertiary: const Color(0xFF240B63),
    tertiaryContainer: const Color(0xFF443078),
    onTertiaryContainer: const Color(0xFFE6DCFF),
    error: const Color(0xFFFF8FA3),
    onError: const Color(0xFF52061B),
    errorContainer: const Color(0xFF7A2036),
    onErrorContainer: const Color(0xFFFFD9DF),
    surfaceDim: const Color(0xFF060925),
    surface: const Color(0xFF0A0E27),
    surfaceBright: const Color(0xFF232B5A),
    surfaceContainerLowest: const Color(0xFF131A3A),
    surfaceContainerLow: const Color(0xFF1B2249),
    surfaceContainer: const Color(0xFF232B5A),
    surfaceContainerHigh: const Color(0xFF2C356E),
    surfaceContainerHighest: const Color(0xFF353D7E),
    onSurface: const Color(0xFFE4E8FA),
    onSurfaceVariant: const Color(0xFFA4ACD0),
    outline: const Color(0xFF5A6BAE),
    outlineVariant: const Color(0xFF2A3267),
    inverseSurface: _inverseSurface,
    onInverseSurface: _onInverseSurface,
    inversePrimary: seed,
    scrim: const Color(0xFF000000),
    shadow: const Color(0xFF000000),
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/theme/app_color_schemes_test.dart`
Expected: PASS, 36 tests.

- [ ] **Step 5: Write the failing shadow test**

`test/core/theme/app_shadows_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';

// 02-theme-binding.md, DECORATION. Light shadows are rgba(15,22,56,a), which
// is the light `shadow` role; dark ones are rgba(0,0,0,a), the dark role.
void expectShadow(
  List<BoxShadow> actual,
  ColorScheme scheme, {
  required double dy,
  required double blur,
  required double alpha,
}) {
  expect(actual, hasLength(1));
  expect(actual.single.offset, Offset(0, dy));
  expect(actual.single.blurRadius, blur);
  expect(actual.single.spreadRadius, 0);
  expect(actual.single.color, scheme.shadow.withValues(alpha: alpha));
}

void main() {
  final light = AppColorSchemes.light;
  final dark = AppColorSchemes.dark;

  test('whisper: card and toggle thumb, none in dark', () {
    expectShadow(AppShadows.whisper(light), light,
        dy: 1, blur: 2, alpha: 0.04);
    expect(AppShadows.whisper(dark), isEmpty);
  });

  test('overlay: the dialog shadow (source token shadow-card)', () {
    expectShadow(AppShadows.overlay(light), light,
        dy: 12, blur: 32, alpha: 0.10);
    expectShadow(AppShadows.overlay(dark), dark,
        dy: 16, blur: 40, alpha: 0.42);
  });

  test('chrome: bottom sheet and bottom chrome, cast upward', () {
    expectShadow(AppShadows.chrome(light), light,
        dy: -2, blur: 12, alpha: 0.05);
    expectShadow(AppShadows.chrome(dark), dark,
        dy: -2, blur: 14, alpha: 0.36);
  });

  test('fab: the floating action', () {
    expectShadow(AppShadows.fab(light), light, dy: 8, blur: 24, alpha: 0.12);
    expectShadow(AppShadows.fab(dark), dark, dy: 10, blur: 28, alpha: 0.5);
  });
}
```

- [ ] **Step 6: Run it to verify it fails**

Run: `flutter test test/core/theme/app_shadows_test.dart`
Expected: FAIL — `app_shadows.dart` not found.

- [ ] **Step 7: Write `app_shadows.dart`**

`lib/core/theme/foundations/app_shadows.dart`:

```dart
import 'package:flutter/material.dart';

/// V3 shadow treatments (02-theme-binding DECORATION), named by semantic
/// rather than by source token: the kit's `shadow-card` is the dialog's
/// [overlay] shadow, and the Card uses [whisper].
///
/// The theme owns these values; the component contract owns which one it uses
/// per theme and state. Shadows are neutral, built on the scheme's `shadow`
/// role and never tinted with the brand colour.
abstract final class AppShadows {
  /// card-whisper-shadow: Card, Toggle thumb. None in dark, which draws the
  /// hairline edge instead.
  static List<BoxShadow> whisper(ColorScheme scheme) =>
      switch (scheme.brightness) {
        Brightness.light => [_shadow(scheme, dy: 1, blur: 2, alpha: 0.04)],
        Brightness.dark => const [],
      };

  /// overlay-shadow: Dialog.
  static List<BoxShadow> overlay(ColorScheme scheme) =>
      switch (scheme.brightness) {
        Brightness.light => [_shadow(scheme, dy: 12, blur: 32, alpha: 0.10)],
        Brightness.dark => [_shadow(scheme, dy: 16, blur: 40, alpha: 0.42)],
      };

  /// chrome-shadow: BottomSheet and bottom chrome, cast upward.
  static List<BoxShadow> chrome(ColorScheme scheme) =>
      switch (scheme.brightness) {
        Brightness.light => [_shadow(scheme, dy: -2, blur: 12, alpha: 0.05)],
        Brightness.dark => [_shadow(scheme, dy: -2, blur: 14, alpha: 0.36)],
      };

  /// fab-shadow: the floating action.
  static List<BoxShadow> fab(ColorScheme scheme) =>
      switch (scheme.brightness) {
        Brightness.light => [_shadow(scheme, dy: 8, blur: 24, alpha: 0.12)],
        Brightness.dark => [_shadow(scheme, dy: 10, blur: 28, alpha: 0.5)],
      };

  static BoxShadow _shadow(
    ColorScheme scheme, {
    required double dy,
    required double blur,
    required double alpha,
  }) =>
      BoxShadow(
        color: scheme.shadow.withValues(alpha: alpha),
        offset: Offset(0, dy),
        blurRadius: blur,
      );
}
```

- [ ] **Step 8: Run both tests to verify they pass**

Run: `flutter test test/core/theme/app_color_schemes_test.dart test/core/theme/app_shadows_test.dart`
Expected: PASS.

- [ ] **Step 9: Analyze, guard, commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme/app_color_schemes.dart lib/core/theme/foundations/app_shadows.dart test/core/theme/app_color_schemes_test.dart test/core/theme/app_shadows_test.dart
git commit -m "feat(theme): V3 light/dark colour schemes and shadow treatments

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected before committing: analyze clean, guard `Errors: 0 | Warnings: 0`.

---

### Task 4: Semantic colours, derived colours and MasteryRamp

**Files:**
- Create: `lib/core/theme/mx_semantic_colors.dart`, `lib/core/theme/mx_derived_colors.dart`, `lib/core/theme/mastery_ramp.dart`, `test/support/color_matchers.dart`
- Test: `test/core/theme/mx_semantic_colors_test.dart`, `test/core/theme/mx_derived_colors_test.dart`, `test/core/theme/mastery_ramp_test.dart`

**Interfaces:**
- Consumes: `AppColorSchemes.light/.dark` (Task 3), `AppEffects.glassOpacity` (Task 2).
- Produces:
  - `MxSemanticColors` (`ThemeExtension`) with fields `mastery, warning, onWarning, statusNew, statusLearning, statusReviewing, statusMastered, errorFill, onErrorFill` (all `Color`), and `static const MxSemanticColors light`, `dark`
  - `MxDerivedColors.resolve(ColorScheme scheme, MxSemanticColors semantic)`, with fields `dangerSoft, dangerBorder, warningSoft, surfaceHero, chromeGlass, ghostBorder` (all `Color`)
  - `MasteryRamp.fill(MxSemanticColors semantic, double fraction)` → `Color?`; `MasteryRamp.track(ColorScheme scheme)` → `Color`
  - `isColorCloseTo(int argb)` → `Matcher` (test support)

- [ ] **Step 1: Write the colour matcher (test support)**

`test/support/color_matchers.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Matches a [Color] whose A, R, G and B channels are each within one 8-bit
/// step of [argb]. For blended colours, where the last bit depends on how the
/// blend rounds; an exact role value is compared with `toARGB32()` instead.
Matcher isColorCloseTo(int argb) => _ColorCloseTo(argb);

final class _ColorCloseTo extends Matcher {
  const _ColorCloseTo(this._argb);

  final int _argb;

  static const int _tolerance = 1;
  static const List<int> _channelShifts = [24, 16, 8, 0];
  static const int _channelMask = 0xFF;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Color) return false;

    final actual = item.toARGB32();
    for (final shift in _channelShifts) {
      final actualChannel = (actual >> shift) & _channelMask;
      final expectedChannel = (_argb >> shift) & _channelMask;
      if ((actualChannel - expectedChannel).abs() > _tolerance) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) => description.add(
        'a colour within $_tolerance per channel of '
        '0x${_argb.toRadixString(16).toUpperCase()}',
      );
}
```

- [ ] **Step 2: Write the failing semantic-colours test**

`test/core/theme/mx_semantic_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// The nine BIND_NOW MEMOX_SEMANTIC_COLOR entries, light then dark.
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'mastery': ((c) => c.mastery, 0xFF1F8A5B, 0xFF6FE0BD),
  'warning': ((c) => c.warning, 0xFFF59E0B, 0xFFFFC658),
  'onWarning': ((c) => c.onWarning, 0xFF3A2A00, 0xFF2A1E00),
  'statusNew': ((c) => c.statusNew, 0xFF8C95B8, 0xFF6B75A3),
  'statusLearning': ((c) => c.statusLearning, 0xFFF59E0B, 0xFFFFC658),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF5265F5, 0xFF8B9AFF),
  'statusMastered': ((c) => c.statusMastered, 0xFF1F8A5B, 0xFF6FE0BD),
  'errorFill': ((c) => c.errorFill, 0xFFDC2D4E, 0xFFB0485C),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF),
};

void main() {
  for (final MapEntry(key: name, value: (read, light, dark))
      in _expected.entries) {
    test('$name is the V3 value in both themes', () {
      expect(read(MxSemanticColors.light).toARGB32(), light);
      expect(read(MxSemanticColors.dark).toARGB32(), dark);
    });
  }

  test('copyWith replaces only the named field', () {
    const replacement = Color(0xFF000001);
    final copy = MxSemanticColors.light.copyWith(mastery: replacement);

    expect(copy.mastery, replacement);
    expect(copy.warning, MxSemanticColors.light.warning);
    expect(copy.onErrorFill, MxSemanticColors.light.onErrorFill);
  });

  test('lerp reaches each end and blends in between', () {
    const light = MxSemanticColors.light;
    const dark = MxSemanticColors.dark;

    expect(light.lerp(dark, 0).mastery, light.mastery);
    expect(light.lerp(dark, 1).mastery, dark.mastery);
    expect(
      light.lerp(dark, 0.5).statusNew,
      Color.lerp(light.statusNew, dark.statusNew, 0.5),
    );
  });

  test('lerp against a foreign extension keeps this one', () {
    expect(MxSemanticColors.light.lerp(null, 0.5), MxSemanticColors.light);
  });
}
```

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/core/theme/mx_semantic_colors_test.dart`
Expected: FAIL — `mx_semantic_colors.dart` not found.

- [ ] **Step 4: Write `mx_semantic_colors.dart`**

`lib/core/theme/mx_semantic_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// MemoX product colours that Material has no honest role for
/// (02-theme-binding MEMOX_SEMANTIC_COLOR, BIND_NOW only).
///
/// Holds exactly the nine semantics a V3 component paints. Aliases resolve to
/// their ColorScheme role, derived colours live in MxDerivedColors, and the
/// PRESERVE_ONLY semantics (success, streak, mastery-fixed…) get no field
/// until a component consumes them. Green means mastery, never tertiary.
@immutable
final class MxSemanticColors extends ThemeExtension<MxSemanticColors> {
  const MxSemanticColors({
    required this.mastery,
    required this.warning,
    required this.onWarning,
    required this.statusNew,
    required this.statusLearning,
    required this.statusReviewing,
    required this.statusMastered,
    required this.errorFill,
    required this.onErrorFill,
  });

  static const MxSemanticColors light = MxSemanticColors(
    mastery: Color(0xFF1F8A5B),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF3A2A00),
    statusNew: Color(0xFF8C95B8),
    statusLearning: Color(0xFFF59E0B),
    statusReviewing: Color(0xFF5265F5),
    statusMastered: Color(0xFF1F8A5B),
    errorFill: Color(0xFFDC2D4E),
    onErrorFill: Color(0xFFFFFFFF),
  );

  static const MxSemanticColors dark = MxSemanticColors(
    mastery: Color(0xFF6FE0BD),
    warning: Color(0xFFFFC658),
    onWarning: Color(0xFF2A1E00),
    statusNew: Color(0xFF6B75A3),
    statusLearning: Color(0xFFFFC658),
    statusReviewing: Color(0xFF8B9AFF),
    statusMastered: Color(0xFF6FE0BD),
    errorFill: Color(0xFFB0485C),
    onErrorFill: Color(0xFFFFFFFF),
  );

  /// Mastery and progress green.
  final Color mastery;
  final Color warning;

  /// Ink on a warning fill.
  final Color onWarning;
  final Color statusNew;
  final Color statusLearning;
  final Color statusReviewing;
  final Color statusMastered;

  /// Solid destructive button fill.
  final Color errorFill;

  /// Label on [errorFill].
  final Color onErrorFill;

  @override
  MxSemanticColors copyWith({
    Color? mastery,
    Color? warning,
    Color? onWarning,
    Color? statusNew,
    Color? statusLearning,
    Color? statusReviewing,
    Color? statusMastered,
    Color? errorFill,
    Color? onErrorFill,
  }) =>
      MxSemanticColors(
        mastery: mastery ?? this.mastery,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        statusNew: statusNew ?? this.statusNew,
        statusLearning: statusLearning ?? this.statusLearning,
        statusReviewing: statusReviewing ?? this.statusReviewing,
        statusMastered: statusMastered ?? this.statusMastered,
        errorFill: errorFill ?? this.errorFill,
        onErrorFill: onErrorFill ?? this.onErrorFill,
      );

  @override
  MxSemanticColors lerp(
    covariant ThemeExtension<MxSemanticColors>? other,
    double t,
  ) {
    if (other is! MxSemanticColors) return this;

    return MxSemanticColors(
      mastery: Color.lerp(mastery, other.mastery, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      statusNew: Color.lerp(statusNew, other.statusNew, t)!,
      statusLearning: Color.lerp(statusLearning, other.statusLearning, t)!,
      statusReviewing: Color.lerp(statusReviewing, other.statusReviewing, t)!,
      statusMastered: Color.lerp(statusMastered, other.statusMastered, t)!,
      errorFill: Color.lerp(errorFill, other.errorFill, t)!,
      onErrorFill: Color.lerp(onErrorFill, other.onErrorFill, t)!,
    );
  }
}
```

- [ ] **Step 5: Run it to verify it passes**

Run: `flutter test test/core/theme/mx_semantic_colors_test.dart`
Expected: PASS, 12 tests.

- [ ] **Step 6: Write the failing derived-colours test**

`test/core/theme/mx_derived_colors_test.dart`. The expected values are worked by hand from the handoff mix ratios. They are not recomputed with the code under test.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

import '../../support/color_matchers.dart';

void main() {
  final light = MxDerivedColors.resolve(
    AppColorSchemes.light,
    MxSemanticColors.light,
  );
  final dark = MxDerivedColors.resolve(
    AppColorSchemes.dark,
    MxSemanticColors.dark,
  );

  test('dangerSoft: error at 8% light, 16% dark', () {
    expect(light.dangerSoft, isColorCloseTo(0x14DC2D4E));
    expect(dark.dangerSoft, isColorCloseTo(0x29FF8FA3));
  });

  test('dangerBorder: error at 22% light, 32% dark', () {
    expect(light.dangerBorder, isColorCloseTo(0x38DC2D4E));
    expect(dark.dangerBorder, isColorCloseTo(0x52FF8FA3));
  });

  test('warningSoft: warning at 12% light, 18% dark', () {
    expect(light.warningSoft, isColorCloseTo(0x1FF59E0B));
    expect(dark.warningSoft, isColorCloseTo(0x2EFFC658));
  });

  test('surfaceHero blends over surfaceBright in light, surface in dark', () {
    // Light: #5265F5 at 5% over #FFFFFF. Dark: #8B9AFF at 12% over #0A0E27.
    expect(light.surfaceHero, isColorCloseTo(0xFFF6F7FE));
    expect(dark.surfaceHero, isColorCloseTo(0xFF191F41));
  });

  test('chromeGlass is surface at the glass opacity, not pre-flattened', () {
    expect(light.chromeGlass, isColorCloseTo(0xD6F7F9FE));
    expect(dark.chromeGlass, isColorCloseTo(0xD60A0E27));
  });

  test('ghostBorder is primary at 14% light, 16% dark', () {
    expect(light.ghostBorder, isColorCloseTo(0x245265F5));
    expect(dark.ghostBorder, isColorCloseTo(0x298B9AFF));
  });
}
```

- [ ] **Step 7: Run it to verify it fails**

Run: `flutter test test/core/theme/mx_derived_colors_test.dart`
Expected: FAIL — `mx_derived_colors.dart` not found.

- [ ] **Step 8: Write `mx_derived_colors.dart`**

`lib/core/theme/mx_derived_colors.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Colours derived from a role at a percentage (02-theme-binding
/// DERIVED_COLOR, BIND_NOW), plus the border-ghost edge colour.
///
/// Each derivation happens here exactly once. A component consuming one of
/// these applies no percentage of its own.
@immutable
final class MxDerivedColors {
  const MxDerivedColors._({
    required this.dangerSoft,
    required this.dangerBorder,
    required this.warningSoft,
    required this.surfaceHero,
    required this.chromeGlass,
    required this.ghostBorder,
  });

  factory MxDerivedColors.resolve(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    return MxDerivedColors._(
      dangerSoft: scheme.error.withValues(
        alpha: isDark ? _dangerSoftDark : _dangerSoftLight,
      ),
      dangerBorder: scheme.error.withValues(
        alpha: isDark ? _dangerBorderDark : _dangerBorderLight,
      ),
      warningSoft: semantic.warning.withValues(
        alpha: isDark ? _warningSoftDark : _warningSoftLight,
      ),
      // The one derivation whose base changes with the theme.
      surfaceHero: Color.alphaBlend(
        scheme.primary.withValues(
          alpha: isDark ? _surfaceHeroDark : _surfaceHeroLight,
        ),
        isDark ? scheme.surface : scheme.surfaceBright,
      ),
      // Composited over the runtime backdrop at paint time, never flattened.
      chromeGlass: scheme.surface.withValues(alpha: AppEffects.glassOpacity),
      ghostBorder: scheme.primary.withValues(
        alpha: isDark ? _ghostBorderDark : _ghostBorderLight,
      ),
    );
  }

  static const double _dangerSoftLight = 0.08;
  static const double _dangerSoftDark = 0.16;
  static const double _dangerBorderLight = 0.22;
  static const double _dangerBorderDark = 0.32;
  static const double _warningSoftLight = 0.12;
  static const double _warningSoftDark = 0.18;
  static const double _surfaceHeroLight = 0.05;
  static const double _surfaceHeroDark = 0.12;
  static const double _ghostBorderLight = 0.14;
  static const double _ghostBorderDark = 0.16;

  /// ErrorState tile tint.
  final Color dangerSoft;

  /// Destructive edge.
  final Color dangerBorder;

  /// Warning tint.
  final Color warningSoft;

  /// Tinted hero card fill.
  final Color surfaceHero;

  /// Bottom-nav glass surface.
  final Color chromeGlass;

  /// The 1px primary-tinted hairline on cards, chips, dividers and chrome.
  final Color ghostBorder;
}
```

- [ ] **Step 9: Run it to verify it passes**

Run: `flutter test test/core/theme/mx_derived_colors_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 10: Write the failing MasteryRamp test**

`test/core/theme/mastery_ramp_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

void main() {
  const semantic = MxSemanticColors.light;

  test('0% paints no fill, only the track', () {
    expect(MasteryRamp.fill(semantic, 0), isNull);
  });

  test('below 34% is learning', () {
    expect(MasteryRamp.fill(semantic, 0.01), semantic.statusLearning);
    expect(MasteryRamp.fill(semantic, 0.3399), semantic.statusLearning);
  });

  test('34% up to 67% is reviewing', () {
    expect(MasteryRamp.fill(semantic, 0.34), semantic.statusReviewing);
    expect(MasteryRamp.fill(semantic, 0.6699), semantic.statusReviewing);
  });

  test('67% and above is mastered', () {
    expect(MasteryRamp.fill(semantic, 0.67), semantic.statusMastered);
    expect(MasteryRamp.fill(semantic, 1), semantic.statusMastered);
  });

  test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
    for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
      expect(
        () => MasteryRamp.fill(semantic, bad),
        throwsArgumentError,
        reason: '$bad',
      );
    }
  });

  test('the track is surfaceContainerHigh (progress-track)', () {
    expect(
      MasteryRamp.track(AppColorSchemes.light),
      AppColorSchemes.light.surfaceContainerHigh,
    );
  });
}
```

- [ ] **Step 11: Run it to verify it fails**

Run: `flutter test test/core/theme/mastery_ramp_test.dart`
Expected: FAIL — `mastery_ramp.dart` not found.

- [ ] **Step 12: Write `mastery_ramp.dart`**

`lib/core/theme/mastery_ramp.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// The single-colour mastery ramp (V3 MasteryRamp utility). One threshold
/// function feeds every mastery fill, so a 40% deck is the same colour on
/// every screen. It paints nothing itself.
abstract final class MasteryRamp {
  /// First fraction painted as reviewing (34%).
  static const double _reviewingFrom = 0.34;

  /// First fraction painted as mastered (67%).
  static const double _masteredFrom = 0.67;

  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient.
  static Color? fill(MxSemanticColors semantic, double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return semantic.statusLearning;
    if (fraction < _masteredFrom) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  /// The unfilled track (progress-track = surfaceContainerHigh).
  static Color track(ColorScheme scheme) => scheme.surfaceContainerHigh;
}
```

- [ ] **Step 13: Run all three tests to verify they pass**

Run: `flutter test test/core/theme/mx_semantic_colors_test.dart test/core/theme/mx_derived_colors_test.dart test/core/theme/mastery_ramp_test.dart`
Expected: PASS.

- [ ] **Step 14: Analyze, guard, commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme/mx_semantic_colors.dart lib/core/theme/mx_derived_colors.dart lib/core/theme/mastery_ramp.dart test/support/color_matchers.dart test/core/theme/mx_semantic_colors_test.dart test/core/theme/mx_derived_colors_test.dart test/core/theme/mastery_ramp_test.dart
git commit -m "feat(theme): MemoX semantic and derived colours, MasteryRamp

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected before committing: analyze clean, guard `Errors: 0 | Warnings: 0`.

---

### Task 5: Plus Jakarta Sans and the type scale

**Files:**
- Create: `assets/fonts/PlusJakartaSans-Variable.ttf`, `assets/fonts/OFL.txt`, `lib/core/theme/app_typography.dart`
- Modify: `pubspec.yaml` (the `flutter:` section)
- Test: `test/core/theme/app_typography_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `AppTypography.fontFamily` (`String`, `'PlusJakartaSans'`)
  - `AppTypography.withWeight(TextStyle style, FontWeight weight)` → `TextStyle`
  - `AppTypography.bind(TextTheme base)` → `TextTheme`, which merges the seven V3 roles over `base` and syncs every slot's `wght` axis

- [ ] **Step 1: Ask the user, then download the font**

Downloading needs the user's explicit yes. Ask with the AskUserQuestion popup, naming:
- The two files: `PlusJakartaSans[wght].ttf` (about 200 KB) and `OFL.txt` (about 4 KB).
- The source: the `google/fonts` repository on GitHub, `ofl/plusjakartasans/`, licence SIL OFL 1.1.

On yes:

```bash
mkdir -p assets/fonts
curl -fL -o assets/fonts/PlusJakartaSans-Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf"
curl -fL -o assets/fonts/OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/plusjakartasans/OFL.txt"
head -c 4 assets/fonts/PlusJakartaSans-Variable.ttf | od -An -tx1
```

Expected: the last command prints `00 01 00 00`, the TrueType signature. Any other output means the download is not a font: stop and report it.

- [ ] **Step 2: Declare the font in `pubspec.yaml`**

Replace the `flutter:` section:

```yaml
flutter:
  uses-material-design: true
  fonts:
    # Variable font (wght axis). Weights are set through
    # AppTypography.withWeight, which moves the axis with fontWeight.
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Variable.ttf
```

Run: `flutter pub get`
Expected: exit 0.

- [ ] **Step 3: Write the failing typography test**

`test/core/theme/app_typography_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';

// (slot, size, weight, height, letterSpacing) for the seven V3 roles.
final _roles = <String, (TextStyle? Function(TextTheme), double, FontWeight,
    double, double)>{
  'stat → displayMedium': ((t) => t.displayMedium, 40, FontWeight.w600, 1.0,
      -0.64),
  'display → displaySmall': ((t) => t.displaySmall, 32, FontWeight.w800, 1.1,
      -0.64),
  'headline → headlineSmall': ((t) => t.headlineSmall, 24, FontWeight.w700,
      1.2, -0.64),
  'title → titleLarge': ((t) => t.titleLarge, 20, FontWeight.w700, 1.2,
      -0.64),
  'body large → bodyLarge': ((t) => t.bodyLarge, 16, FontWeight.w500, 1.5, 0),
  'body → bodyMedium': ((t) => t.bodyMedium, 14, FontWeight.w400, 1.5, 0),
  'caption → labelSmall': ((t) => t.labelSmall, 12, FontWeight.w600, 1.4,
      1.2),
};

List<TextStyle?> _allSlots(TextTheme t) => [
      t.displayLarge,
      t.displayMedium,
      t.displaySmall,
      t.headlineLarge,
      t.headlineMedium,
      t.headlineSmall,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bound = AppTypography.bind(
    Typography.material2021(platform: TargetPlatform.android).englishLike,
  );

  for (final MapEntry(key: name, value: (read, size, weight, height, spacing))
      in _roles.entries) {
    test('$name is ${size.toInt()}/${weight.value}/$height/$spacing', () {
      final style = read(bound)!;
      expect(style.fontFamily, AppTypography.fontFamily);
      expect(style.fontSize, size);
      expect(style.fontWeight, weight);
      expect(style.height, height);
      expect(style.letterSpacing, spacing);
    });
  }

  test('the stat role uses tabular figures', () {
    expect(
      bound.displayMedium!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('every slot moves the wght axis with its weight', () {
    for (final style in _allSlots(bound)) {
      final weight = style!.fontWeight ?? FontWeight.w400;
      expect(
        style.fontVariations,
        contains(FontVariation.weight(weight.value.toDouble())),
        reason: '$style',
      );
    }
  });

  test('withWeight sets fontWeight and the wght axis together', () {
    final style = AppTypography.withWeight(const TextStyle(), FontWeight.w700);

    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontVariations, [const FontVariation.weight(700)]);
  });

  test('the font asset is bundled', () async {
    final data =
        await rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf');
    expect(data.lengthInBytes, greaterThan(0));
  });
}
```

- [ ] **Step 4: Run it to verify it fails**

Run: `flutter test test/core/theme/app_typography_test.dart`
Expected: FAIL — `app_typography.dart` not found.

- [ ] **Step 5: Write `app_typography.dart`**

`lib/core/theme/app_typography.dart`:

```dart
import 'package:flutter/material.dart';

/// The V3 type scale bound to Material's TextTheme (01-foundations.md).
///
/// Seven roles, one family. A component's own treatment (the button label, the
/// app-bar title) overrides the nearest role in that component; it never adds a
/// global style here.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static const double _tightTracking = -0.64;
  static const double _captionTracking = 1.2;

  /// Re-weights [style] and moves the variable font's `wght` axis with it.
  /// On a variable font, fontWeight alone reports one weight and paints the
  /// font's default instance.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
      );

  /// [base] with the seven V3 roles merged over it and every slot's `wght`
  /// axis synced to its weight, so the slots V3 does not define still render
  /// at the weight they declare.
  static TextTheme bind(TextTheme base) {
    final merged = base.merge(_roles).apply(fontFamily: fontFamily);
    return merged.copyWith(
      displayLarge: _synced(merged.displayLarge),
      displayMedium: _synced(merged.displayMedium),
      displaySmall: _synced(merged.displaySmall),
      headlineLarge: _synced(merged.headlineLarge),
      headlineMedium: _synced(merged.headlineMedium),
      headlineSmall: _synced(merged.headlineSmall),
      titleLarge: _synced(merged.titleLarge),
      titleMedium: _synced(merged.titleMedium),
      titleSmall: _synced(merged.titleSmall),
      bodyLarge: _synced(merged.bodyLarge),
      bodyMedium: _synced(merged.bodyMedium),
      bodySmall: _synced(merged.bodySmall),
      labelLarge: _synced(merged.labelLarge),
      labelMedium: _synced(merged.labelMedium),
      labelSmall: _synced(merged.labelSmall),
    );
  }

  static final TextTheme _roles = TextTheme(
    // stat: large metric, tabular numerals.
    displayMedium: _role(
      size: 40,
      weight: FontWeight.w600,
      height: 1.0,
      tracking: _tightTracking,
      isTabular: true,
    ),
    // display: hero figure.
    displaySmall: _role(
      size: 32,
      weight: FontWeight.w800,
      height: 1.1,
      tracking: _tightTracking,
    ),
    // headline: screen headline.
    headlineSmall: _role(
      size: 24,
      weight: FontWeight.w700,
      height: 1.2,
      tracking: _tightTracking,
    ),
    // title: section and screen titles.
    titleLarge: _role(
      size: 20,
      weight: FontWeight.w700,
      height: 1.2,
      tracking: _tightTracking,
    ),
    // body large: list titles, emphasised body.
    bodyLarge: _role(size: 16, weight: FontWeight.w500, height: 1.5),
    // body: default running text.
    bodyMedium: _role(size: 14, weight: FontWeight.w400, height: 1.5),
    // caption: overlines, metadata, chips, counts. 12 is a hard floor.
    labelSmall: _role(
      size: 12,
      weight: FontWeight.w600,
      height: 1.4,
      tracking: _captionTracking,
    ),
  );

  static TextStyle _role({
    required double size,
    required FontWeight weight,
    required double height,
    double tracking = 0,
    bool isTabular = false,
  }) =>
      withWeight(
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          height: height,
          letterSpacing: tracking,
          fontFeatures:
              isTabular ? const [FontFeature.tabularFigures()] : null,
        ),
        weight,
      );

  static TextStyle? _synced(TextStyle? style) {
    if (style == null) return null;
    return withWeight(style, style.fontWeight ?? FontWeight.w400);
  }
}
```

- [ ] **Step 6: Run it to verify it passes**

Run: `flutter test test/core/theme/app_typography_test.dart`
Expected: PASS, 11 tests.

- [ ] **Step 7: Analyze, guard, commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add pubspec.yaml pubspec.lock assets/fonts lib/core/theme/app_typography.dart test/core/theme/app_typography_test.dart
git commit -m "feat(theme): bundle Plus Jakarta Sans and bind the V3 type scale

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected before committing: analyze clean, and the guard reports no `no_bare_font_weight` finding (no `fontWeight: FontWeight.` literal exists under `lib/core/theme/`).

---

### Task 6: ThemeData assembly and the context accessors

**Files:**
- Create: `lib/core/theme/app_theme.dart`, `lib/core/theme/theme_context.dart`
- Test: `test/core/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `AppColorSchemes` (Task 3), `MxSemanticColors`, `MxDerivedColors` (Task 4), `AppTypography.bind`, `AppTypography.fontFamily` (Task 5).
- Produces (phase 2 reads these in every `Mx*` widget):
  - `ThemeData buildLightTheme()`, `ThemeData buildDarkTheme()` (top-level functions)
  - `extension ThemeContext on BuildContext` with `ColorScheme get colors`, `TextTheme get texts`, `MxSemanticColors get semanticColors`, `MxDerivedColors get derivedColors`

- [ ] **Step 1: Write the failing theme test**

`test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';

void main() {
  group('buildLightTheme / buildDarkTheme', () {
    final themes = {
      'light': (buildLightTheme(), AppColorSchemes.light, MxSemanticColors.light),
      'dark': (buildDarkTheme(), AppColorSchemes.dark, MxSemanticColors.dark),
    };

    for (final MapEntry(key: name, value: (theme, scheme, semantic))
        in themes.entries) {
      test('$name carries its scheme, extension and page ground', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, scheme);
        expect(theme.extension<MxSemanticColors>(), semantic);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
      });

      test('$name binds the V3 type scale in the theme family', () {
        expect(theme.textTheme.displayMedium!.fontSize, 40);
        expect(theme.textTheme.bodySmall!.fontFamily, AppTypography.fontFamily);
      });

      test('$name text ink is onSurface', () {
        expect(theme.textTheme.bodyMedium!.color, scheme.onSurface);
      });
    }
  });

  test('light to dark lerp keeps the extension (theme animation)', () {
    final mid = ThemeData.lerp(buildLightTheme(), buildDarkTheme(), 0.5);

    expect(
      mid.extension<MxSemanticColors>()!.mastery,
      Color.lerp(
        MxSemanticColors.light.mastery,
        MxSemanticColors.dark.mastery,
        0.5,
      ),
    );
  });

  group('ThemeContext', () {
    Future<BuildContext> pumpUnder(WidgetTester tester, ThemeData theme) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('reads the scheme, text theme and MemoX colours',
        (tester) async {
      final context = await pumpUnder(tester, buildDarkTheme());

      expect(context.colors, AppColorSchemes.dark);
      expect(context.texts.displayMedium!.fontSize, 40);
      expect(context.semanticColors, MxSemanticColors.dark);
      expect(
        context.derivedColors.surfaceHero,
        MxDerivedColors.resolve(AppColorSchemes.dark, MxSemanticColors.dark)
            .surfaceHero,
      );
    });

    testWidgets('a theme without the extension fails with the fix named',
        (tester) async {
      final context = await pumpUnder(tester, ThemeData());

      expect(
        () => context.semanticColors,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('buildLightTheme'),
          ),
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: FAIL — `app_theme.dart` not found.

- [ ] **Step 3: Write `app_theme.dart`**

`lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Tokyo Pure Light.
ThemeData buildLightTheme() =>
    _build(AppColorSchemes.light, MxSemanticColors.light);

/// Tokyo Nebula. Authored, not a filter over light.
ThemeData buildDarkTheme() =>
    _build(AppColorSchemes.dark, MxSemanticColors.dark);

ThemeData _build(ColorScheme scheme, MxSemanticColors semantic) {
  // The base supplies Material's default slots, already inked onSurface.
  final base = ThemeData(colorScheme: scheme);
  return base.copyWith(
    textTheme: AppTypography.bind(base.textTheme),
    scaffoldBackgroundColor: scheme.surface,
    extensions: [semantic],
  );
}
```

- [ ] **Step 4: Write `theme_context.dart`**

`lib/core/theme/theme_context.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// The one way UI code reads the theme.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  MxSemanticColors get semanticColors {
    final semantic = Theme.of(this).extension<MxSemanticColors>();
    if (semantic == null) {
      throw StateError(
        'MxSemanticColors is missing from the ThemeData in scope. Build it '
        'with buildLightTheme() or buildDarkTheme() from '
        'core/theme/app_theme.dart.',
      );
    }
    return semantic;
  }

  MxDerivedColors get derivedColors =>
      MxDerivedColors.resolve(colors, semanticColors);
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS, 9 tests. If `text ink is onSurface` fails, the Flutter base `TextTheme` is not inked from the scheme on this SDK. Stop and report it. Do not add a colour to the roles.

- [ ] **Step 6: Run the full phase gate**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: all exit 0, `dart format` changes nothing, guard `Errors: 0 | Warnings: 0`.

- [ ] **Step 7: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/core/theme/theme_context.dart test/core/theme/app_theme_test.dart
git commit -m "feat(theme): assemble light/dark ThemeData and context accessors

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Hand the phase back

No code.

- [ ] **Step 1: Confirm scope**

Run: `git diff --stat master...HEAD -- lib test pubspec.yaml assets code-verification-guard-v2`
Expected: changes only under `lib/core/theme/`, `test/core/theme/`, `test/support/`, `assets/fonts/`, `pubspec.yaml`, `pubspec.lock` and `overrides.yaml`. Anything else is out of scope: revert it.

- [ ] **Step 2: Report and ask about the PR**

Report to the user in Vietnamese:
- The gate output: test count, and guard `Errors`/`Warnings`.
- Any handoff contradiction met while implementing. Append each one to spec §9 in its own commit.

Ask through the AskUserQuestion popup whether to push the branch and open the phase 1 PR. Opening a PR is outward-facing. Phase 2's plan is written after this phase merges, from the API that actually landed.
