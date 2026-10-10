# Indigo Palette Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Tokyo palette with the explicit Indigo Day / Indigo Night tokens and delete every derived colour (`MxDerivedColors`, the `*Ink` family, alpha tints).

**Architecture:** Every colour is a literal: Material roles in `AppColorSchemes`, everything else in `MxSemanticColors`. `MxDerivedColors` and `context.derivedColors` disappear. Soft grounds (tinted cards, banners, outcome tiles) are light in both themes (spec D4), so the content they hold renders under the Indigo Day theme through one shared widget, `MxSoftGround`.

**Tech Stack:** Flutter 3.47, Material 3 `ColorScheme`, `ThemeExtension`, flutter_test, goldens in the Linux container.

**Spec:** `docs/superpowers/specs/2026-10-10-indigo-palette-design.md` (owner-approved 2026-10-10). Epic: DEV-363.

## Global Constraints

- Values are the spec's §4 and §5 tables, verbatim; no other hex value is introduced.
- No `withValues(alpha:)`, `Color.lerp` or `Color.alphaBlend` on a palette colour outside `lib/core/theme/` `lerp` methods, except the interaction states of spec §3 (pressed, disabled, muted, scrim, shadow, scroll-fade, FAB pressed, filter-chip resting count).
- Typography, radii, border widths, spacing, sizes, shadow alphas: unchanged (spec D1).
- Colour vocabulary: no identifier for a colour ends in `Ink` / is named `ink`; Material splash names (`InkWell`, `Ink`, `MxRowInk`, `AppSize.iconButtonInk`) stay.
- The reference brand is never named in code, comments, docs or commits.
- Gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`; targeted tests through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file|dir>…`; goldens only in Task 7.
- Commits end with the session's attribution lines; messages name `DEV-n` of the task's sub-issue.

## Derived rulings (consequences of the approved mapping, recorded here for the owner)

- **R1 Soft ground is a Day island.** A soft ground is light in Indigo Night (D4), but `MxCard` toned variants, `MxInlineBanner`, `MxFloatingNotice` and `MxOutcomeTile` hold caller content (text, `MxButton`s) that reads the theme. `MxSoftGround` paints the ground and themes its child with Indigo Day, so the child resolves Day tokens (dark text, Day button tones). Requires owner approval (new `lib/shared/widgets/` file).
- **R2 Cards draw the `border` hairline in both themes.** Day page and card are both `#FFFFFF`; without an edge a raised card dissolves. The reference's cards carry `border/default` (`#EDEFF4` Day, `#282E3E` Night).
- **R3 Contrast exceptions** are the 29 measured pairs (18 Day, 11 Night) of Task 1's `_exceptions` table (Python WCAG computation, 2026-10-10).

## Review Focus

1. **Night: text inside a soft ground** (success card on Session summary, warning banner on Study home, a danger banner with buttons). Expected: dark readable text and Day-toned buttons, never `#F6F7FB` on `#E6FCF4`. Pinned in Task 3 (`mx_soft_ground_test.dart`, `mx_card_test.dart` dark case).
2. **Day: a raised card on the white page** (Library deck rows, Settings sections). Expected: a visible `#EDEFF4` hairline. Pinned in Task 2 (`app_decorations_test.dart`).
3. **Theme switch at runtime (light ↔ dark ↔ system)** — `ThemeContext` must not serve stale colours once the `Expando` cache is gone. Pinned in Task 4 (`theme_context_test.dart`: pump light, switch to dark, read `semanticColors.primaryText`).
4. **Focus ring visibility** on the page, the field fill and a card in both themes. Expected: `focusRing` `#A8B1FF`, whatever the control (button, toggle, chip, code slot). Pinned in Task 2 (`app_component_themes_test.dart`) and Task 3 (`mx_toggle_test.dart`).
5. **Mastery fill and label agree at the band edges** (0, 0.33, 0.34, 0.66, 0.67, 1). Pinned in Task 2 (`mastery_ramp_test.dart`).

---

### Task 1: Palette tokens and the contrast table

**Files:**
- Modify: `lib/core/theme/app_color_schemes.dart`
- Modify: `lib/core/theme/mx_semantic_colors.dart`
- Modify: `lib/core/theme/app_theme.dart:8-13` (doc comments)
- Modify: `lib/core/theme/foundations/app_effects.dart`
- Test: `test/core/theme/app_color_schemes_test.dart`, `test/core/theme/mx_semantic_colors_test.dart`, `test/core/theme/token_contrast_test.dart`, `test/core/theme/foundations_test.dart` (scrim value if asserted)

**Interfaces:**
- Produces: `MxSemanticColors` fields `primaryText, masteryText, learningText, warningText, focusRing, border, primaryTrack, neutralTrack, primarySoft, onPrimarySoft, successSoft, successBorder, onSuccessSoft, learningSoft, learningBorder, onLearningSoft, warningSoft, warningBorder, onWarningSoft, dangerSoft, dangerBorder, onDangerSoft, neutralSoft, onNeutralSoft, onSoft` (all `Color`), alongside the existing twelve. `AppEffects.scrimOpacity == 0.56`.
- `MxDerivedColors` still compiles in this task (it now derives from the new values); Task 4 deletes it.

- [ ] **Step 1: Write the failing value tests**

Replace `_v3Roles` in `test/core/theme/app_color_schemes_test.dart` (keep `_read` and `main`), and rename the header comment to "Every role of the Indigo palette (spec 2026-10-10 §4), Day then Night":

```dart
const _v3Roles = <String, (int, int)>{
  'primary': (0xFF4255FF, 0xFF4255FF),
  'onPrimary': (0xFFFFFFFF, 0xFFFFFFFF),
  'primaryContainer': (0xFFEDEFFF, 0xFF14125C),
  'onPrimaryContainer': (0xFF4255FF, 0xFFEDEFFF),
  'secondary': (0xFF586380, 0xFF586380),
  'onSecondary': (0xFFFFFFFF, 0xFFF6F7FB),
  'secondaryContainer': (0xFFEDEFF4, 0xFF2E3856),
  'onSecondaryContainer': (0xFF2E3856, 0xFFD9DDE8),
  'tertiary': (0xFF9C63FF, 0xFF9C63FF),
  'onTertiary': (0xFFFFFFFF, 0xFFFFFFFF),
  'tertiaryContainer': (0xFFFAA6FF, 0xFFFAA6FF),
  'onTertiaryContainer': (0xFF282E3E, 0xFF282E3E),
  'error': (0xFFB00020, 0xFFFC3C60),
  'onError': (0xFFFFFFFF, 0xFFFFFFFF),
  'errorContainer': (0xFFFFE8D8, 0xFFFFE8D8),
  'onErrorContainer': (0xFFB00020, 0xFFB00020),
  'surfaceDim': (0xFFEDEFF4, 0xFF0A092D),
  'surface': (0xFFFFFFFF, 0xFF0A092D),
  'surfaceBright': (0xFFFFFFFF, 0xFF2E3856),
  'surfaceContainerLowest': (0xFFFFFFFF, 0xFF202040),
  'surfaceContainerLow': (0xFFF6F7FB, 0xFF2E3856),
  'surfaceContainer': (0xFFF6F7FB, 0xFF2E3856),
  'surfaceContainerHigh': (0xFFEDEFF4, 0xFF282E3E),
  'surfaceContainerHighest': (0xFFD9DDE8, 0xFF586380),
  'onSurface': (0xFF282E3E, 0xFFF6F7FB),
  'onSurfaceVariant': (0xFF586380, 0xFFD9DDE8),
  'outline': (0xFF939BB4, 0xFF586380),
  'outlineVariant': (0xFFD9DDE8, 0xFF586380),
  'inverseSurface': (0xFF1A1D28, 0xFFEDEFF4),
  'onInverseSurface': (0xFFF6F7FB, 0xFF282E3E),
  'inversePrimary': (0xFFF6F7FB, 0xFF586380),
  'scrim': (0xFF010110, 0xFF010110),
  'shadow': (0xFF282E3E, 0xFF282E3E),
};
```

Replace `_expected` in `test/core/theme/mx_semantic_colors_test.dart` (header: "Every MxSemanticColors token (spec 2026-10-10 §5), Day then Night"):

```dart
final _expected = <String, (Color Function(MxSemanticColors), int, int)>{
  'mastery': ((c) => c.mastery, 0xFF18AE79, 0xFF18AE79),
  'onMastery': ((c) => c.onMastery, 0xFFFFFFFF, 0xFFFFFFFF),
  'success': ((c) => c.success, 0xFF12815A, 0xFF59E8B5),
  'warning': ((c) => c.warning, 0xFFFFCD1F, 0xFFFFCD1F),
  'onWarning': ((c) => c.onWarning, 0xFF282E3E, 0xFF282E3E),
  'statusNew': ((c) => c.statusNew, 0xFF939BB4, 0xFF586380),
  'statusLearning': ((c) => c.statusLearning, 0xFFFF983A, 0xFFFF983A),
  'statusReviewing': ((c) => c.statusReviewing, 0xFF4255FF, 0xFF4255FF),
  'statusMastered': ((c) => c.statusMastered, 0xFF18AE79, 0xFF18AE79),
  'errorFill': ((c) => c.errorFill, 0xFFB00020, 0xFFB00020),
  'onErrorFill': ((c) => c.onErrorFill, 0xFFFFFFFF, 0xFFFFFFFF),
  'streak': ((c) => c.streak, 0xFFF6406C, 0xFFF6406C),
  'primaryText': ((c) => c.primaryText, 0xFF4255FF, 0xFF7583FF),
  'masteryText': ((c) => c.masteryText, 0xFF12815A, 0xFF59E8B5),
  'learningText': ((c) => c.learningText, 0xFFCC4E00, 0xFFFF983A),
  'warningText': ((c) => c.warningText, 0xFF997700, 0xFFFFCD1F),
  'focusRing': ((c) => c.focusRing, 0xFFA8B1FF, 0xFFA8B1FF),
  'border': ((c) => c.border, 0xFFEDEFF4, 0xFF282E3E),
  'primaryTrack': ((c) => c.primaryTrack, 0xFFDBDFFF, 0xFFDBDFFF),
  'neutralTrack': ((c) => c.neutralTrack, 0xFF939BB4, 0xFF939BB4),
  'primarySoft': ((c) => c.primarySoft, 0xFFEDEFFF, 0xFFEDEFFF),
  'onPrimarySoft': ((c) => c.onPrimarySoft, 0xFF4255FF, 0xFF4255FF),
  'successSoft': ((c) => c.successSoft, 0xFFE6FCF4, 0xFFE6FCF4),
  'successBorder': ((c) => c.successBorder, 0xFF98F1D1, 0xFF98F1D1),
  'onSuccessSoft': ((c) => c.onSuccessSoft, 0xFF12815A, 0xFF12815A),
  'learningSoft': ((c) => c.learningSoft, 0xFFFFF6EF, 0xFFFFF6EF),
  'learningBorder': ((c) => c.learningBorder, 0xFFFFC38C, 0xFFFFC38C),
  'onLearningSoft': ((c) => c.onLearningSoft, 0xFFCC4E00, 0xFFCC4E00),
  'warningSoft': ((c) => c.warningSoft, 0xFFFFEDAB, 0xFFFFEDAB),
  'warningBorder': ((c) => c.warningBorder, 0xFFFFDC62, 0xFFFFDC62),
  'onWarningSoft': ((c) => c.onWarningSoft, 0xFF997700, 0xFF997700),
  'dangerSoft': ((c) => c.dangerSoft, 0xFFFFE8D8, 0xFFFFE8D8),
  'dangerBorder': ((c) => c.dangerBorder, 0xFFFFC38C, 0xFFFFC38C),
  'onDangerSoft': ((c) => c.onDangerSoft, 0xFFB00020, 0xFFB00020),
  'neutralSoft': ((c) => c.neutralSoft, 0xFFEDEFFF, 0xFF586380),
  'onNeutralSoft': ((c) => c.onNeutralSoft, 0xFF2E3856, 0xFFF6F7FB),
  'onSoft': ((c) => c.onSoft, 0xFF282E3E, 0xFF282E3E),
};
```

Rename the loop's test title to `'$name is the Indigo value in both themes'`. Add to the `copyWith` test: `expect(copy.primaryText, MxSemanticColors.light.primaryText);`.

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_color_schemes_test.dart test/core/theme/mx_semantic_colors_test.dart`
Expected: FAIL — compile errors on `primaryText` etc., then value mismatches.

- [ ] **Step 3: Write `AppColorSchemes`**

```dart
import 'package:flutter/material.dart';

/// Indigo Day and Indigo Night, the two themes (spec 2026-10-10 §4).
///
/// Every role is a literal. Only the *Fixed family, which Material requires
/// and MemoX never reads, is still generated from [seed].
abstract final class AppColorSchemes {
  /// The brand indigo, primary in both themes.
  static const Color seed = Color(0xFF4255FF);

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _danger = Color(0xFFB00020);
  static const Color _dangerSoft = Color(0xFFFFE8D8);
  static const Color _overlay = Color(0xFF010110);
  static const Color _shadow = Color(0xFF282E3E);
  static const Color _neutral = Color(0xFF586380);
  static const Color _purple = Color(0xFF9C63FF);
  static const Color _pink = Color(0xFFFAA6FF);
  static const Color _onLight = Color(0xFF282E3E);

  static final ColorScheme light = ColorScheme.fromSeed(seedColor: seed)
      .copyWith(
        primary: seed,
        onPrimary: _white,
        primaryContainer: const Color(0xFFEDEFFF),
        onPrimaryContainer: seed,
        secondary: _neutral,
        onSecondary: _white,
        secondaryContainer: const Color(0xFFEDEFF4),
        onSecondaryContainer: const Color(0xFF2E3856),
        tertiary: _purple,
        onTertiary: _white,
        tertiaryContainer: _pink,
        onTertiaryContainer: _onLight,
        error: _danger,
        onError: _white,
        errorContainer: _dangerSoft,
        onErrorContainer: _danger,
        surfaceDim: const Color(0xFFEDEFF4),
        surface: _white,
        surfaceBright: _white,
        surfaceContainerLowest: _white,
        surfaceContainerLow: const Color(0xFFF6F7FB),
        surfaceContainer: const Color(0xFFF6F7FB),
        surfaceContainerHigh: const Color(0xFFEDEFF4),
        surfaceContainerHighest: const Color(0xFFD9DDE8),
        onSurface: _onLight,
        onSurfaceVariant: _neutral,
        outline: const Color(0xFF939BB4),
        outlineVariant: const Color(0xFFD9DDE8),
        // The toast is the inverse surface: dark in Day, light in Night.
        inverseSurface: const Color(0xFF1A1D28),
        onInverseSurface: const Color(0xFFF6F7FB),
        inversePrimary: const Color(0xFFF6F7FB),
        scrim: _overlay,
        shadow: _shadow,
      );

  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: seed,
        onPrimary: _white,
        primaryContainer: const Color(0xFF14125C),
        onPrimaryContainer: const Color(0xFFEDEFFF),
        secondary: _neutral,
        onSecondary: const Color(0xFFF6F7FB),
        secondaryContainer: const Color(0xFF2E3856),
        onSecondaryContainer: const Color(0xFFD9DDE8),
        tertiary: _purple,
        onTertiary: _white,
        tertiaryContainer: _pink,
        onTertiaryContainer: _onLight,
        error: const Color(0xFFFC3C60),
        onError: _white,
        errorContainer: _dangerSoft,
        onErrorContainer: _danger,
        surfaceDim: const Color(0xFF0A092D),
        surface: const Color(0xFF0A092D),
        surfaceBright: const Color(0xFF2E3856),
        surfaceContainerLowest: const Color(0xFF202040),
        surfaceContainerLow: const Color(0xFF2E3856),
        surfaceContainer: const Color(0xFF2E3856),
        surfaceContainerHigh: const Color(0xFF282E3E),
        surfaceContainerHighest: _neutral,
        onSurface: const Color(0xFFF6F7FB),
        onSurfaceVariant: const Color(0xFFD9DDE8),
        outline: _neutral,
        outlineVariant: _neutral,
        inverseSurface: const Color(0xFFEDEFF4),
        onInverseSurface: _onLight,
        inversePrimary: _neutral,
        scrim: _overlay,
        shadow: _shadow,
      );
}
```

- [ ] **Step 4: Write `MxSemanticColors`**

Keep the class shape (const constructor with `required` fields, `light`/`dark` constants, `copyWith`, `lerp`). Field order: the twelve existing, then the twenty-five new in the order of the Step 1 `_expected` map. Class doc:

```dart
/// Every MemoX colour Material has no role for (spec 2026-10-10 §5): status
/// and semantic fills, the text tokens, the edges and tracks, and the soft
/// grounds with their borders and text. Each is a literal per theme; nothing
/// here is derived. Green means mastery or success, never decoration.
```

`light` and `dark` take exactly the Step 1 values (Day = first int, Night = second). Field docs, one line each, for the new fields:

```dart
  /// Primary as text and glyph (links, outline and text buttons, selected
  /// nav), never a fill.
  final Color primaryText;
  /// Mastery as text: a mastered status label, a ramp label.
  final Color masteryText;
  /// Learning as text.
  final Color learningText;
  /// Warning as text and glyph on a plain ground.
  final Color warningText;
  /// The 2dp focus ring of every control.
  final Color focusRing;
  /// The 1px hairline of cards, sections, dividers and chrome.
  final Color border;
  /// A toggle's track when on.
  final Color primaryTrack;
  /// A toggle's track when off.
  final Color neutralTrack;
  /// Soft grounds: light in both themes (spec D4), with their edge and the
  /// text that reads on them.
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color successSoft;
  final Color successBorder;
  final Color onSuccessSoft;
  final Color learningSoft;
  final Color learningBorder;
  final Color onLearningSoft;
  final Color warningSoft;
  final Color warningBorder;
  final Color onWarningSoft;
  final Color dangerSoft;
  final Color dangerBorder;
  final Color onDangerSoft;
  final Color neutralSoft;
  final Color onNeutralSoft;
  /// Body text on any soft ground.
  final Color onSoft;
```

`copyWith` takes every field as `Color?`; `lerp` lerps every field with `Color.lerp(a, b, t)!` (theme animation, allowed by the Global Constraints).

- [ ] **Step 5: Theme names and scrim**

`app_theme.dart`: `/// Indigo Day.` above `buildLightTheme`, `/// Indigo Night. Authored, not a filter over Day.` above `buildDarkTheme`.
`app_effects.dart`: `static const double scrimOpacity = 0.56;` with its doc "Alpha of the `scrim` behind a dialog or a bottom sheet (spec 2026-10-10 §4)."

- [ ] **Step 6: Rewrite `token_contrast_test.dart` on the tokens**

Replace the whole file:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// The palette's text and edge pairs, worked from the tokens (Flutter's
// textContrastGuideline misreads anti-aliased 12px text). A pair at its
// WCAG 2.2 AA floor is asserted at that floor. The palette is fixed (owner
// 2026-10-10, spec D3), so a pair below it is a named exception asserted
// at its measured floor: a palette edit that worsens it, or a new pair that
// fails, turns this red, and an exception that comes to pass must move out.

const double _text = 4.5;
const double _nonText = 3;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Color _tint(Color color, double alpha, Color ground) =>
    Color.alphaBlend(color.withValues(alpha: alpha), ground);

typedef _Pair = (String name, Color fore, Color ground, double minimum);

/// The measured floors of the pairs below AA (owner 2026-10-10, spec D3).
const _exceptions = <String, double>{
  'day/warningText on page': 4.20,
  'day/warningText on row': 4.20,
  'day/warningText on low': 3.92,
  'day/learningText on low': 4.20,
  'day/outline on page': 2.76,
  'day/outline on row': 2.76,
  'day/outline on low': 2.58,
  'day/focusRing on page': 2.01,
  'day/focusRing on row': 2.01,
  'day/focusRing on low': 1.88,
  'day/learning fill on its track': 1.99,
  'day/mastered fill on its track': 2.65,
  'day/toggle off thumb on its track': 2.76,
  'day/learning label on the hero': 3.94,
  'day/mastered label on the hero': 4.25,
  'day/onLearningSoft on learningSoft': 4.22,
  'day/onWarningSoft on warningSoft': 3.59,
  'day/outline on the warning ground': 2.36,
  'night/error on row': 4.43,
  'night/error on low': 3.27,
  'night/primaryText on low': 3.54,
  'night/outline on row': 2.61,
  'night/outline on low': 1.92,
  'night/reviewing bars on the card': 2.95,
  'night/progress fill on its track': 2.18,
  'night/toggle off thumb on its track': 2.76,
  'night/onLearningSoft on learningSoft': 4.22,
  'night/onWarningSoft on warningSoft': 3.59,
  'night/outline on the warning ground': 2.36,
};

List<_Pair> _pairs(
  ColorScheme scheme,
  MxSemanticColors semantic,
  ColorScheme day,
) {
  final page = scheme.surface;
  final row = scheme.surfaceContainerLowest;
  final low = scheme.surfaceContainerLow;
  return [
    for (final (ground, where) in [(page, 'page'), (row, 'row'), (low, 'low')])
      ...[
        ('onSurface on $where', scheme.onSurface, ground, _text),
        ('onSurfaceVariant on $where', scheme.onSurfaceVariant, ground, _text),
        ('error on $where', scheme.error, ground, _text),
        ('primaryText on $where', semantic.primaryText, ground, _text),
        ('masteryText on $where', semantic.masteryText, ground, _text),
        ('learningText on $where', semantic.learningText, ground, _text),
        ('warningText on $where', semantic.warningText, ground, _text),
        ('success on $where', semantic.success, ground, _text),
        ('outline on $where', scheme.outline, ground, _nonText),
        ('focusRing on $where', semantic.focusRing, ground, _nonText),
      ],
    ('reviewing bars on the card', semantic.statusReviewing, row, _nonText),
    ('progress fill on its track', scheme.primary, low, _nonText),
    ('learning fill on its track', semantic.statusLearning, low, _nonText),
    ('mastered fill on its track', semantic.statusMastered, low, _nonText),
    ('snackbar message', scheme.onInverseSurface, scheme.inverseSurface, _text),
    ('snackbar action', scheme.inversePrimary, scheme.inverseSurface, _text),
    ('onPrimary on primary', scheme.onPrimary, scheme.primary, _text),
    ('onWarning on warning', semantic.onWarning, semantic.warning, _text),
    ('onErrorFill on errorFill', semantic.onErrorFill, semantic.errorFill, _text),
    ('toggle off thumb on its track', scheme.onPrimary, semantic.neutralTrack, _nonText),
    ('toggle on thumb on its track', scheme.primary, semantic.primaryTrack, _nonText),
    ('sheet grabber', scheme.onSurfaceVariant, row, _nonText),
    // The donut's 9px label sits on the hero card.
    ('learning label on the hero', semantic.learningText, scheme.primaryContainer, _text),
    ('reviewing label on the hero', semantic.primaryText, scheme.primaryContainer, _text),
    ('mastered label on the hero', semantic.masteryText, scheme.primaryContainer, _text),
    // Soft grounds are light in both themes (D4).
    ('onPrimarySoft on primarySoft', semantic.onPrimarySoft, semantic.primarySoft, _text),
    ('onSuccessSoft on successSoft', semantic.onSuccessSoft, semantic.successSoft, _text),
    ('onLearningSoft on learningSoft', semantic.onLearningSoft, semantic.learningSoft, _text),
    ('onWarningSoft on warningSoft', semantic.onWarningSoft, semantic.warningSoft, _text),
    ('onDangerSoft on dangerSoft', semantic.onDangerSoft, semantic.dangerSoft, _text),
    ('onNeutralSoft on neutralSoft', semantic.onNeutralSoft, semantic.neutralSoft, _text),
    ('onSoft on warningSoft', semantic.onSoft, semantic.warningSoft, _text),
    ('onSoft on dangerSoft', semantic.onSoft, semantic.dangerSoft, _text),
    ('onSoft on successSoft', semantic.onSoft, semantic.successSoft, _text),
    // A soft ground renders its content in Day (R1), so an outline button
    // inside a warning card carries Day's outline in both themes.
    ('outline on the warning ground', day.outline, semantic.warningSoft, _nonText),
    // A Guess option out of play fades as a whole to AppOpacity.muted.
    (
      'faded choice text',
      _tint(scheme.onSurface, AppOpacity.muted, page),
      _tint(row, AppOpacity.muted, page),
      _text,
    ),
  ];
}

void main() {
  for (final (theme, scheme, semantic) in [
    ('day', AppColorSchemes.light, MxSemanticColors.light),
    ('night', AppColorSchemes.dark, MxSemanticColors.dark),
  ]) {
    group('$theme palette contrast', () {
      for (final (name, fore, ground, minimum)
          in _pairs(scheme, semantic, AppColorSchemes.light)) {
        final ratio = _contrast(fore, ground);
        final reason =
            '#${fore.toARGB32().toRadixString(16)} on '
            '#${ground.toARGB32().toRadixString(16)}';
        final floor = _exceptions['$theme/$name'];
        if (floor == null) {
          test(name, () {
            expect(ratio, greaterThanOrEqualTo(minimum), reason: reason);
          });
          continue;
        }
        test('$name (exception)', () {
          expect(ratio, greaterThanOrEqualTo(floor), reason: reason);
          expect(ratio, lessThan(minimum), reason: '$reason now passes');
        });
      }
    });
  }

  test('every exception names a checked pair', () {
    final names = {
      for (final (theme, scheme, semantic) in [
        ('day', AppColorSchemes.light, MxSemanticColors.light),
        ('night', AppColorSchemes.dark, MxSemanticColors.dark),
      ])
        for (final pair in _pairs(scheme, semantic, AppColorSchemes.light))
          '$theme/${pair.$1}',
    };
    expect(names.containsAll(_exceptions.keys), isTrue);
  });
}
```

(Floors are the 2026-10-10 Python measurements rounded down by 0.01, so the Flutter luminance formula's last-digit difference cannot flip them. The `night/primaryText on low` floor covers `#7583FF` on `#2E3856`, 3.55.)

- [ ] **Step 7: Run the three tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme/app_color_schemes_test.dart test/core/theme/mx_semantic_colors_test.dart test/core/theme/token_contrast_test.dart test/core/theme/foundations_test.dart`
Expected: PASS. If a pair not in `_exceptions` fails, it is a missing measurement: add it with its measured floor and say so in the task report (never lower a floor).

- [ ] **Step 8: Run analyze and the theme folder**

Run: `flutter analyze lib/core/theme test/core/theme && bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme`
Expected: analyze clean. `mx_derived_colors_test.dart` and `mx_text_styles_ink_test.dart` may fail on old derived values: they are rewritten or deleted in Tasks 2 and 4; list the failures in the task report, change nothing else.

- [ ] **Step 9: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat(theme): DEV-<task1> Indigo Day and Indigo Night tokens"
```

---

### Task 2: Theme layer reads tokens, not derivations

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart` (constructor, `_primaryInk`)
- Modify: `lib/core/theme/theme_context.dart:41` (`textStyles`)
- Modify: `lib/core/theme/app_component_themes.dart`
- Modify: `lib/core/theme/app_theme.dart` (pass `semantic` to component themes)
- Modify: `lib/core/theme/app_decorations.dart`
- Modify: `lib/core/theme/mastery_ramp.dart`
- Modify (signature call sites): `lib/shared/widgets/mx_card.dart`, `mx_empty_state.dart`, `mx_floating_notice.dart`, `mx_linear_progress.dart`, `mx_mastery_donut.dart`, `lib/features/study/presentation/widgets/support/study_choice_widget.dart`, `lib/features/progress/presentation/widgets/sections/progress_streak_widget.dart`
- Test: `test/core/theme/mx_text_styles*_test.dart`, `app_component_themes_test.dart`, `app_decorations_test.dart`, `app_decorations_study_choice_test.dart`, `mastery_ramp_test.dart`, `test/l10n/footer_caption_length_test.dart`

**Interfaces:**
- Consumes: Task 1 tokens.
- Produces:
  - `MxTextStyles(TextTheme texts, ColorScheme scheme, MxSemanticColors semantic)`
  - `AppComponentThemes.fields(ColorScheme, MxSemanticColors, TextTheme)` (unchanged shape), `filledButtons(ColorScheme, MxSemanticColors, TextTheme)`, `outlinedButtons(ColorScheme, MxSemanticColors, TextTheme)`, `textButtons(ColorScheme, MxSemanticColors, TextTheme)`, `iconButtons(ColorScheme, MxSemanticColors)`, `dialogs(ColorScheme, MxSemanticColors, TextTheme)`, `sheets(ColorScheme)`, `snackbars(ColorScheme, MxSemanticColors, TextTheme)`, `tooltips(ColorScheme, TextTheme)`
  - `AppDecorations.raisedCard(ColorScheme, MxSemanticColors)`, `recessedCard(…)`, `heroCard(…)`, `warningCard(…)`, `successCard(…)`, `dangerCard(…)`, `studyChoice(ColorScheme, MxSemanticColors, StudyChoiceTone, {bool isRecessed})`, `studyChoiceForeground(ColorScheme, MxSemanticColors, StudyChoiceTone)`
  - `MasteryRamp.fill(MxSemanticColors, double) → Color?`, `MasteryRamp.label(MxSemanticColors, double) → Color`, `MasteryRamp.track(ColorScheme)` unchanged, `MasteryRamp.percent` unchanged.

- [ ] **Step 1: Write the failing tests**

`test/core/theme/mastery_ramp_test.dart` — replace the `fill`/`ink` groups with:

```dart
  const semantic = MxSemanticColors.light;

  group('fill', () {
    test('is null at 0, where only the track paints', () {
      expect(MasteryRamp.fill(semantic, 0), isNull);
    });
    for (final (fraction, expected) in [
      (0.01, semantic.statusLearning),
      (0.33, semantic.statusLearning),
      (0.34, semantic.statusReviewing),
      (0.66, semantic.statusReviewing),
      (0.67, semantic.statusMastered),
      (1.0, semantic.statusMastered),
    ]) {
      test('at $fraction is the band fill', () {
        expect(MasteryRamp.fill(semantic, fraction), expected);
      });
    }
  });

  group('label', () {
    for (final (fraction, expected) in [
      (0.0, semantic.learningText),
      (0.33, semantic.learningText),
      (0.34, semantic.primaryText),
      (0.66, semantic.primaryText),
      (0.67, semantic.masteryText),
      (1.0, semantic.masteryText),
    ]) {
      test('at $fraction is the band text token', () {
        expect(MasteryRamp.label(semantic, fraction), expected);
      });
    }
    test('rejects a fraction outside [0, 1]', () {
      expect(() => MasteryRamp.label(semantic, 1.1), throwsArgumentError);
    });
  });
```

`test/core/theme/app_decorations_test.dart` — for both `MxSemanticColors.light`/`AppColorSchemes.light` and the dark pair, assert:

```dart
    test('raised card draws the border hairline in $theme (R2)', () {
      final box = AppDecorations.raisedCard(scheme, semantic);
      expect(box.color, scheme.surfaceContainerLowest);
      expect(box.border, Border.all(color: semantic.border, width: AppStroke.hairline));
    });
    test('hero card fills primaryContainer in $theme', () {
      expect(AppDecorations.heroCard(scheme, semantic).color, scheme.primaryContainer);
    });
    test('toned cards fill their soft token outright in $theme', () {
      expect(AppDecorations.warningCard(scheme, semantic).color, semantic.warningSoft);
      expect(AppDecorations.successCard(scheme, semantic).color, semantic.successSoft);
      expect(AppDecorations.dangerCard(scheme, semantic).color, semantic.dangerSoft);
      expect(
        AppDecorations.dangerCard(scheme, semantic).border,
        Border.all(color: semantic.dangerBorder, width: AppStroke.hairline),
      );
    });
```

`test/core/theme/app_decorations_study_choice_test.dart` — right/wrong grounds are `successSoft`/`dangerSoft` with `successBorder`/`dangerBorder`; `studyChoiceForeground` returns `onSurface`, `onPrimary`, `onSuccessSoft`, `onDangerSoft` for idle, selected, right, wrong; idle edge is `semantic.border`.

`test/core/theme/app_component_themes_test.dart` — assert per theme: the field's `enabledBorder` side colour is `scheme.outline`, `focusedBorder` is `semantic.focusRing`, `disabledBorder` is `semantic.border`; the outlined button's resting side is `scheme.outline` and its foreground `semantic.primaryText`; the text button's foreground `semantic.primaryText`; every button's focused side is `semantic.focusRing`; dialog and sheet background `scheme.surfaceContainerLowest`; barrier `scheme.scrim.withValues(alpha: 0.56)`.

`mx_text_styles*_test.dart` and `footer_caption_length_test.dart`: construct `MxTextStyles(texts, scheme, semantic)`; every expectation that read `MxDerivedColors.primaryInkOf(scheme)` reads `semantic.primaryText`. Rename `mx_text_styles_ink_test.dart` to `mx_text_styles_primary_text_test.dart` (`git mv`).

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/l10n/footer_caption_length_test.dart`
Expected: FAIL (compile errors on the new signatures).

- [ ] **Step 3: `MxTextStyles` and `ThemeContext.textStyles`**

```dart
final class MxTextStyles {
  const MxTextStyles(this._texts, this._scheme, this._semantic);

  final TextTheme _texts;
  final ColorScheme _scheme;
  final MxSemanticColors _semantic;

  /// Primary as text: never the primary fill.
  Color get _primaryText => _semantic.primaryText;
```

Replace every `_primaryInk` with `_primaryText`; drop the `mx_derived_colors.dart` import, add `mx_semantic_colors.dart`. In `theme_context.dart`: `MxTextStyles get textStyles => MxTextStyles(texts, colors, semanticColors);`.

- [ ] **Step 4: `AppComponentThemes` and `app_theme.dart`**

In `fields`: delete `derived`; `final ghost = semantic.border; final rest = scheme.outline;`; `hintStyle: MxTextStyles(texts, scheme, semantic).inputHint`; `focusedBorder: fieldEdge(semantic.focusRing)`. Update its doc: "the outline at rest (the border hairline when disabled), the focus ring on focus".
`_button` gains `MxSemanticColors semantic` and uses `focusColor: semantic.focusRing`, `label: MxTextStyles(texts, scheme, semantic).buttonLabel`; rename its `ink` parameter to `foreground` (and the local `dimmed(ink)` to `dimmed(foreground)`).
`outlinedButtons`: `foreground: semantic.primaryText, edge: BorderSide(color: scheme.outline, width: AppStroke.hairline)`.
`textButtons`: `foreground: semantic.primaryText`. Doc: "TextButton: primary text, no fill".
`iconButtons(ColorScheme scheme, MxSemanticColors semantic)`: focused side `semantic.focusRing`.
`dialogs`: `backgroundColor: scheme.surfaceContainerLowest`; doc "the card ground at radius 20, flat, over the 56% scrim".
`sheets`: `backgroundColor`/`modalBackgroundColor: scheme.surfaceContainerLowest`; doc "the card ground…56% scrim".
`snackbars`/`dialogs` build `MxTextStyles(texts, scheme, semantic)`.
`app_theme.dart` `_build`: pass `semantic` to every builder whose signature now takes it.

- [ ] **Step 5: `AppDecorations`**

Replace the file body with token reads (keep `StudyChoiceTone`):

```dart
abstract final class AppDecorations {
  /// The Card surface: the card ground at radius 12 with the border hairline
  /// in both themes (Day's card and page are both white, R2) and the whisper
  /// shadow.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: semantic.border, width: AppStroke.hairline),
    boxShadow: AppShadows.whisper(scheme),
  );

  /// The answer face of a study card: the low ground with the hairline, flat.
  static BoxDecoration recessedCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => raisedCard(scheme, semantic).copyWith(
    color: scheme.surfaceContainerLow,
    boxShadow: const [],
  );

  /// The hero Card: the primary container with the hairline.
  static BoxDecoration heroCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => raisedCard(scheme, semantic).copyWith(color: scheme.primaryContainer);

  /// The warning Card (screen 02, D-O1): the warning soft ground, light in
  /// both themes, edged in its border.
  static BoxDecoration warningCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _soft(scheme, semantic, semantic.warningSoft, semantic.warningBorder);

  /// The success Card: a finished session (FE-A6 D14).
  static BoxDecoration successCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _soft(scheme, semantic, semantic.successSoft, semantic.successBorder);

  /// The danger Card: a session stopped by an error.
  static BoxDecoration dangerCard(
    ColorScheme scheme,
    MxSemanticColors semantic,
  ) => _soft(scheme, semantic, semantic.dangerSoft, semantic.dangerBorder);

  static BoxDecoration _soft(
    ColorScheme scheme,
    MxSemanticColors semantic,
    Color ground,
    Color edge,
  ) => raisedCard(scheme, semantic).copyWith(
    color: ground,
    border: Border.all(color: edge, width: AppStroke.hairline),
  );

  /// A guess option and a match tile (screens 17 and 18): idle on the card
  /// ground, selected in primary, right on the success soft ground, wrong
  /// on the danger soft ground. [isRecessed] gives an idle tile the answer
  /// face's low ground (part 3c-2, R3).
  static BoxDecoration studyChoice(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone, {
    bool isRecessed = false,
  }) {
    final (Color fill, Color edge) = switch (tone) {
      StudyChoiceTone.idle => (
        isRecessed ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        semantic.border,
      ),
      StudyChoiceTone.selected => (scheme.primary, scheme.primary),
      StudyChoiceTone.right => (semantic.successSoft, semantic.successBorder),
      StudyChoiceTone.wrong => (semantic.dangerSoft, semantic.dangerBorder),
    };
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: edge, width: AppStroke.hairline),
    );
  }

  /// The text and glyph colour on a [studyChoice] surface.
  static Color studyChoiceForeground(
    ColorScheme scheme,
    MxSemanticColors semantic,
    StudyChoiceTone tone,
  ) => switch (tone) {
    StudyChoiceTone.idle => scheme.onSurface,
    StudyChoiceTone.selected => scheme.onPrimary,
    StudyChoiceTone.right => semantic.onSuccessSoft,
    StudyChoiceTone.wrong => semantic.onDangerSoft,
  };
}
```

- [ ] **Step 6: `MasteryRamp`**

```dart
  /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
  /// track is painted. Never a gradient.
  static Color? fill(MxSemanticColors semantic, double fraction) {
    _check(fraction);
    if (fraction == 0) return null;
    if (fraction < _reviewingFrom) return semantic.statusLearning;
    if (fraction < _masteredFrom) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  /// The text token of [fraction]'s band, for a percentage beside or inside
  /// the fill. 0 reads in the lowest band.
  static Color label(MxSemanticColors semantic, double fraction) {
    _check(fraction);
    if (fraction < _reviewingFrom) return semantic.learningText;
    if (fraction < _masteredFrom) return semantic.primaryText;
    return semantic.masteryText;
  }

  static void _check(double fraction) {
    if (fraction.isNaN || fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
    }
  }
```

`percent` calls `_check(fraction)` too. Drop the `mx_derived_colors.dart` import.

- [ ] **Step 7: Update the signature call sites**

In the seven call-site files, `AppDecorations.x(context.colors, context.derivedColors…)` becomes `AppDecorations.x(context.colors, context.semanticColors…)`; `AppDecorations.studyChoiceInk` becomes `studyChoiceForeground`; `MasteryRamp.fill(semantic, derived, f)` becomes `MasteryRamp.fill(semantic, f)`; `MasteryRamp.ink(semantic, derived, f)` becomes `MasteryRamp.label(semantic, f)`. Change nothing else in those files in this task.

- [ ] **Step 8: Run the tests**

Run: `flutter analyze && bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/theme test/l10n test/shared/widgets/mx_card_test.dart test/shared/widgets/mx_mastery_donut_test.dart test/shared/widgets/mx_linear_progress_test.dart test/features/study test/features/progress`
Expected: analyze clean; theme tests PASS. Widget tests that assert an old derived value may fail: list them in the report; Tasks 3–4 rewrite them.

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "feat(theme): DEV-<task2> theme layer reads the Indigo tokens"
```

---

### Task 3: Soft grounds — `MxSoftGround` and the widgets that tinted locally

**Files:**
- Create: `lib/shared/widgets/mx_soft_ground.dart`
- Modify: `lib/shared/widgets/mx_card.dart`, `mx_inline_banner.dart`, `mx_floating_notice.dart`, `mx_outcome_tile.dart`, `mx_badge.dart`, `mx_status_badge.dart`, `mx_icon_tile.dart`, `mx_empty_state.dart`, `mx_error_state.dart`, `mx_study_top_bar.dart`, `mx_action_sheet_command_row.dart`, `mx_toggle.dart`
- Modify: `lib/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart`, `lib/features/card/presentation/widgets/sections/card_schedule_widget.dart`
- Test: `test/shared/widgets/mx_soft_ground_test.dart` (new) and the existing test of every widget above

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces: `MxSoftGround({Key? key, required BoxDecoration decoration, required Widget child})`.

- [ ] **Step 1: Write the failing `MxSoftGround` test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_soft_ground.dart';

void main() {
  testWidgets('a soft ground themes its content with Indigo Day in Night', (
    tester,
  ) async {
    late Color onSurface;
    late Color primaryText;
    late Color defaultText;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: MxSoftGround(
          decoration: const BoxDecoration(color: Color(0xFFE6FCF4)),
          child: Builder(
            builder: (context) {
              onSurface = context.colors.onSurface;
              primaryText = context.semanticColors.primaryText;
              defaultText = DefaultTextStyle.of(context).style.color!;
              return const Text('x');
            },
          ),
        ),
      ),
    );

    expect(onSurface, const Color(0xFF282E3E));
    expect(primaryText, MxSemanticColors.light.primaryText);
    expect(defaultText, const Color(0xFF282E3E));
  });

  testWidgets('it paints the decoration it is given', (tester) async {
    const decoration = BoxDecoration(color: Color(0xFFFFEDAB));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const MxSoftGround(decoration: decoration, child: Text('x')),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('x'), matching: find.byType(DecoratedBox)).first,
    );
    expect(box.decoration, decoration);
  });
}
```

Add a dark case to `test/shared/widgets/mx_card_test.dart`:

```dart
  testWidgets('a success card renders its content in Day text in Night', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
          body: MxCard(
            isSuccess: true,
            child: Builder(
              builder: (context) => Text('done', style: TextStyle(color: context.colors.onSurface)),
            ),
          ),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('done')).style!.color, const Color(0xFF282E3E));
  });
```

(`MxCard`'s toned flags are `isWarning`, `isSuccess`, `isDanger`; `isHero` and `isRecessed` are not soft grounds.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets/mx_soft_ground_test.dart test/shared/widgets/mx_card_test.dart`
Expected: FAIL — `mx_soft_ground.dart` does not exist.

- [ ] **Step 3: Write `MxSoftGround`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_theme.dart';

/// A soft ground (a toned card, a banner, an outcome tile). Soft grounds are
/// light in both themes (spec 2026-10-10 D4), so the content they hold
/// renders under Indigo Day: its text, glyphs and buttons read Day's tokens.
class MxSoftGround extends StatelessWidget {
  const MxSoftGround({super.key, required this.decoration, required this.child});

  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final day = _day;
    final onSurface = day.colorScheme.onSurface;
    return DecoratedBox(
      decoration: decoration,
      child: Theme(
        data: day,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: onSurface),
          child: IconTheme.merge(
            data: IconThemeData(color: onSurface),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Built once: the Day theme is immutable and identical for every soft ground.
final ThemeData _day = buildLightTheme();
```

- [ ] **Step 4: Use it in the four composite widgets**

- `MxCard`: when the tone is warning, success or danger, wrap the decorated content in `MxSoftGround(decoration: …, child: …)` in place of the outer `DecoratedBox`; raised, hero and recessed keep `DecoratedBox`. Keep the selected-ring `foregroundDecoration` path working (read the file; the ring stays outside `MxSoftGround`).
- `MxInlineBanner`: build the ground through `MxSoftGround`; its tone tuple becomes `(semantic.warningSoft, semantic.warningBorder, semantic.onWarningSoft, semantic.onWarningSoft)` for warning and `(semantic.dangerSoft, semantic.dangerBorder, semantic.onDangerSoft, semantic.onDangerSoft)` for danger (ground, edge, glyph, title). The message keeps `styles.bannerMessage(...)`, which under the Day theme reads Day's `onSurface` (`#282E3E` = `onSoft`). Rename `titleInk` to `titleForeground`.
- `MxFloatingNotice`: `MxSoftGround(decoration: AppDecorations.warningCard(context.colors, context.semanticColors), child: …)`; glyph `context.semanticColors.onWarningSoft`.
- `MxOutcomeTile`: `MxSoftGround` with `(semantic.successSoft, semantic.successBorder, semantic.onSuccessSoft)` for kept and `(semantic.warningSoft, semantic.warningBorder, semantic.onWarningSoft)` for lost; delete `_keptTint`.

- [ ] **Step 5: The widgets that tinted locally read tokens**

- `MxBadge` — delete `_tint`; one switch gives `(ground, foreground)`:

```dart
    final semantic = context.semanticColors;
    final (ground, foreground) = switch ((isSolid, tone)) {
      (true, _) => (colors.primary, colors.onPrimary),
      (false, MxBadgeTone.primary) => (semantic.primarySoft, semantic.onPrimarySoft),
      (false, MxBadgeTone.mastery) => (semantic.successSoft, semantic.onSuccessSoft),
      (false, MxBadgeTone.success) => (semantic.successSoft, semantic.onSuccessSoft),
      (false, MxBadgeTone.warning) => (semantic.warningSoft, semantic.onWarningSoft),
      (false, MxBadgeTone.danger) => (semantic.dangerSoft, semantic.onDangerSoft),
      (false, MxBadgeTone.neutral) => (semantic.neutralSoft, semantic.onNeutralSoft),
    };
```

- `MxStatusBadge` — delete `_tint`; the dot keeps the status fill; pill ground and label:

```dart
    final (ground, foreground) = switch (status) {
      MxCardStatus.newCard => (semantic.neutralSoft, semantic.onNeutralSoft),
      MxCardStatus.learning => (semantic.learningSoft, semantic.onLearningSoft),
      MxCardStatus.reviewing => (semantic.primarySoft, semantic.onPrimarySoft),
      MxCardStatus.mastered => (semantic.successSoft, semantic.onSuccessSoft),
    };
```

- `MxIconTile` — delete `_primaryTintLight/_primaryTintDark/_seedTint`. `tinted` → `(semantic.primarySoft, seed ?? semantic.onPrimarySoft)`; a `seed` keeps its own glyph colour on `primarySoft`; `success` → `(successSoft, onSuccessSoft)`; `caution` → `(warningSoft, onWarningSoft)`; `danger` → `(dangerSoft, onDangerSoft)`; `primary` and `warning` unchanged.
- `MxEmptyState` — delete `_tileTint`; the tile ground per tone: primary `primarySoft`, neutral `neutralSoft`, success `successSoft`, warning `warningSoft`, danger `dangerSoft`; the glyph: `onPrimarySoft`, `onNeutralSoft`, `onSuccessSoft`, `onWarningSoft`, `onDangerSoft`.
- `MxErrorState` — tile `semantic.dangerSoft`, glyph `semantic.onDangerSoft`.
- `MxStudyTopBar` — delete `_badgeTint`; badge ground `semantic.primarySoft`, text `semantic.onPrimarySoft` (rename `accentInk` to `badgeForeground`); the progress fill stays `colors.primary`.
- `MxActionSheetCommandRow` — delete `_tileTint`; tile `(isDestructive ? semantic.dangerSoft : semantic.primarySoft)`, glyph `(isDestructive ? semantic.onDangerSoft : semantic.onPrimarySoft)`; rename local `ink` to `foreground`.
- `card_removable_tag_chip_widget.dart` — ground `semantic.primarySoft`, label/glyph `semantic.onPrimarySoft`; delete `_tint`.
- `card_schedule_widget.dart:180` — past bars `semantic.primaryTrack`; delete `_pastAlpha`.
- `MxToggle`:

```dart
  BoxDecoration? _ring(BuildContext context) {
    if (_hasFocus) return _edge(context.semanticColors.focusRing, AppStroke.focus);
    return null;
  }
```

track colour `widget.isOn ? semantic.primaryTrack : semantic.neutralTrack`; thumb `widget.isOn ? colors.primary : colors.onPrimary`. Remove the off-track outline ring and its comment (the reference's switch has no edge; the measured exception covers the off thumb).

- [ ] **Step 6: Update each widget's test**

For every widget of Step 5, its test asserts the tokens above in both `buildLightTheme()` and `buildDarkTheme()` (ground colour from the `DecoratedBox`, foreground from the `Text`/`Icon`). Replace any expectation built from `withValues(alpha:)` or `derivedColors`. Add `mx_toggle_test.dart` cases: on → track `primaryTrack`, thumb `primary`; off → `neutralTrack`, thumb `#FFFFFF`; focused → `foregroundDecoration` border `focusRing`.

- [ ] **Step 7: Run the tests**

Run: `flutter analyze && bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/shared/widgets test/features/card`
Expected: PASS, analyze clean.

- [ ] **Step 8: Commit**

```bash
git add lib test
git commit -m "feat(ui): DEV-<task3> soft grounds render in Day; badges and tiles read tokens"
```

---

### Task 4: Every other consumer, then delete `MxDerivedColors`

**Files:**
- Modify: every file still listed by `grep -rlE "derivedColors|MxDerivedColors|primaryInkOf" lib test`
- Modify: `lib/core/theme/theme_context.dart` (delete `_derived` and `derivedColors`)
- Delete: `lib/core/theme/mx_derived_colors.dart`, `test/core/theme/mx_derived_colors_test.dart`
- Create: `test/core/theme/theme_context_test.dart`
- Test: every test touched

**Interfaces:**
- Consumes: Tasks 1–3. Produces: no `MxDerivedColors` symbol anywhere.

- [ ] **Step 1: Write the theme-switch test (Review Focus 3)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';

void main() {
  testWidgets('semanticColors follows a theme switch', (tester) async {
    final mode = ValueNotifier(ThemeMode.light);
    late Color primaryText;
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: mode,
        builder: (_, value, _) => MaterialApp(
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: value,
          home: Builder(
            builder: (context) {
              primaryText = context.semanticColors.primaryText;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(primaryText, MxSemanticColors.light.primaryText);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();
    expect(primaryText, MxSemanticColors.dark.primaryText);
  });
}
```

- [ ] **Step 2: Migrate the consumers by this table**

| Old read | New read on a plain ground | New read on a soft ground |
|---|---|---|
| `derivedColors.primaryInk` as text/glyph | `semanticColors.primaryText` | `semanticColors.onPrimarySoft` |
| `derivedColors.primaryInk` as `focusColor` or a focus edge | `semanticColors.focusRing` | — |
| `warningInk` | `warningText` | `onWarningSoft` |
| `dangerInk` | `colors.error` | `onDangerSoft` |
| `successInk` | `semanticColors.success` | `onSuccessSoft` |
| `statusNewInk` | `colors.onSurfaceVariant` | `onNeutralSoft` |
| `statusLearningInk` | `learningText` | `onLearningSoft` |
| `statusReviewingInk` | `primaryText` | `onPrimarySoft` |
| `statusMasteredInk` | `masteryText` | `onSuccessSoft` |
| `ghostBorder` | `semanticColors.border` | — |
| `outlineEdge` | `colors.outline` | — |
| `surfaceHero` | `colors.primaryContainer` | — |
| `dangerSoft` / `warningSoft` / `successSoft` and their borders | the `semanticColors` field of the same name | — |

"Soft ground" means the widget paints on a `*Soft` token itself. Example, `lib/shared/widgets/mx_nav_rail.dart:121`:

```dart
// before
? context.derivedColors.primaryInk
// after
? context.semanticColors.primaryText
```

Example, `lib/shared/widgets/mx_button.dart:124` (`focusColor: context.derivedColors.primaryInk`) → `focusColor: context.semanticColors.focusRing`.

Files expected (from the 2026-10-10 grep; Task 2–3 already handled some): `lib/shared/widgets/` `mx_row_ink, mx_empty_state, mx_nav_rail, mx_spinner, mx_search_field, mx_chip_trigger, mx_bottom_nav, mx_filter_chip, mx_option_row, mx_stat_tile, mx_code_field, mx_workload_breakdown_line, mx_stepper, mx_button, mx_divided_column, mx_field_message, mx_footer_bar, mx_note, mx_selection_checkbox, mx_sheet_actions, mx_linear_progress, mx_mastery_donut`; `lib/features/` `card_add_details, card_history_event, card_row, monitoring_code_card, progress_deck_row, progress_streak, progress_today, theme_choice_card, sync_status_section, session_summary_facts, study_browse, study_entry_hero, study_fill, study_recall, recall_countdown_bar, study_choice, tag_rename_dialog, import_preview_row, import_step_tracker`, `account_transition_layer`, `study_grade_row`. A comment that explains an ink ("primaryInk for the primary tone (spec 2026-09-27 D2)") is rewritten to name the token.

- [ ] **Step 3: Delete the derivation**

Delete `lib/core/theme/mx_derived_colors.dart` and its test. In `theme_context.dart` delete the `_derived` `Expando`, its `ponytail` comment, the `derivedColors` getter and the import.

- [ ] **Step 4: Migrate the tests**

`grep -rlE "derivedColors|MxDerivedColors|primaryInkOf|Ink\b" test` — every hit reads the token of the Step 2 table. No expectation is dropped; an expectation on a removed behaviour (the toggle's off outline) is replaced by the Task 3 expectation.

- [ ] **Step 5: Verify nothing derived is left**

Run:
```bash
grep -rnE "derivedColors|MxDerivedColors|primaryInkOf|(primary|warning|danger|success|status[A-Za-z]+)Ink\b|surfaceHero|ghostBorder|outlineEdge" lib test
grep -rnE "withValues\(alpha|Color\.lerp|alphaBlend" lib --include=*.dart
```
Expected: the first prints nothing. The second prints only `mx_semantic_colors.dart` `lerp`, `app_component_themes.dart` (disabled dim, pressed, scrim), `app_button_style.dart` (pressed), `app_theme.dart` (splash/highlight), `app_shadows.dart`, `mx_fab.dart` (pressed), `mx_filter_chip.dart` (resting count), `mx_scroll_fade.dart` (transparent end).

- [ ] **Step 6: Run analyze and the suite**

Run: `flutter analyze && bash .claude/skills/flutter-workflow/scripts/run_tests.sh test`
Expected: PASS (goldens excluded by the script).

- [ ] **Step 7: Commit**

```bash
git add -A lib test
git commit -m "refactor(theme): DEV-<task4> delete MxDerivedColors; consumers read tokens"
```

---

### Task 5: Colour vocabulary — `ink` becomes `foreground`

**Files:**
- Modify: `lib/core/theme/app_button_style.dart` (`ink` parameter), every caller of `appButtonStyle`, and every colour local/parameter named `ink`/`…Ink` listed by Step 1.

- [ ] **Step 1: List the colour identifiers**

Run: `grep -rnwE "ink|[a-z][A-Za-z]*Ink" lib test --include=*.dart | grep -vE "InkWell|InkResponse|MxRowInk|iconButtonInk|\bInk\(|Ink\.image"`
Every hit that holds a `Color` is in scope; a hit that is a splash/ripple is not.

- [ ] **Step 2: Rename**

`appButtonStyle({required Color foreground, …})` (doc: "one fill and one foreground for every state"); callers pass `foreground:`. Locals: `ink` → `foreground`, `titleInk` → `titleForeground`, `accentInk` → `badgeForeground` (if Task 3 missed it), and so on. Doc comments that say "ink" for a colour say "foreground" or the token's name.

- [ ] **Step 3: Verify and run**

Run: Step 1's grep again — expected: no colour hit. Then `flutter analyze && bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core test/shared`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add -A lib test
git commit -m "refactor(theme): DEV-<task5> colour parameters are foregrounds, not inks"
```

---

### Task 6: Documentation

**Files:**
- Modify: `DESIGN.md`, `.impeccable/design.json`
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`, `02-review-algorithm.md`, `18-study-guess.md`, `19-study-recall.md`, `25-theme.md`

- [ ] **Step 1: `DESIGN.md` frontmatter**

`description:` "A quiet, focused study space for spaced-repetition flashcards, in two themes, Indigo Day and Indigo Night." `colors:` holds the Day values of spec §4 (Material roles, kebab-case as today) and §5 (semantic, kebab-case: `primary-text`, `mastery-text`, `learning-text`, `warning-text`, `focus-ring`, `border`, `primary-track`, `neutral-track`, `primary-soft`, `on-primary-soft`, `success-soft`, `success-border`, `on-success-soft`, `learning-soft`, `learning-border`, `on-learning-soft`, `warning-soft`, `warning-border`, `on-warning-soft`, `danger-soft`, `danger-border`, `on-danger-soft`, `neutral-soft`, `on-neutral-soft`, `on-soft`, plus the existing `mastery`, `on-mastery`, `success`, `warning`, `on-warning`, `error-fill`, `on-error-fill`, `status-*`, `streak`); delete `warning-ink`. `components:` `dialog.backgroundColor: "{colors.surface-container-lowest}"`.

- [ ] **Step 2: `DESIGN.md` body**

- Overview: the two themes are Indigo Day (white page, white cards edged in a cool hairline) and Indigo Night (deep indigo page `#0A092D`, cards `#202040`, surfaces `#2E3856`); the brand indigo `#4255FF` holds in both.
- Colors: rewrite Primary, Neutral, Semantic on the tokens of spec §4–5 with Day / Night values; a **Soft grounds** subsection: light in both themes, content renders in Day through `MxSoftGround` (R1); remove every "Ink" paragraph (Indigo Ink, Outline Edge derivation, Warning Ink, Danger Ink, derived tints).
- Named Rules: replace **The Ink Is Not The Fill Rule** with **The Text Token Rule** (spec §8 wording); **The Contrast Floor Rule** becomes "Text holds 4.5:1 and non-text 3:1 where the palette allows; the palette is fixed (owner 2026-10-10), and the pairs below the floor are the exceptions `token_contrast_test.dart` lists with their measured floors."
- Elevation: scrim at 56 %; shadows tinted `#282E3E`.
- Components: every "primary ink", "warning ink", "Outline Edge", "Ghost Border", "success ink", "danger ink", "status ink" names the token (`primaryText`, `warningText`, `outline`, `border`, `success`, `error`/`onDangerSoft`, the status text tokens); MxCard: "toned variants are soft grounds (`MxSoftGround`)"; MxToggle: "track `primaryTrack` on, `neutralTrack` off, thumb primary on, white off"; MxDialog/MxBottomSheet: card ground; Do's and Don'ts: "Don't use a fill colour as text; use its text token."

- [ ] **Step 3: `.impeccable/design.json` and the screen files**

`design.json`: theme names Indigo Day / Indigo Night; the colour metadata to the spec values (read the file's shape first; keep its schema). Screen files: each sentence naming an ink names its token (grep `-n "ink\|Ink" docs/shared/ui/screen-handoff/{01,02,18,19,25}-*.md`); `25-theme.md`'s preview description says the previews paint Indigo Day and Indigo Night.

- [ ] **Step 4: Verify**

Run: `python3 tools/docs/check.py && grep -nE "Tokyo|Nebula|primaryInk|warningInk|Indigo Ink|Outline Edge|Ghost Border|Ink Is Not" DESIGN.md .impeccable/design.json docs/shared/ui/screen-handoff/*.md`
Expected: check passes; grep prints nothing.

- [ ] **Step 5: Commit**

```bash
git add DESIGN.md .impeccable/design.json docs/shared/ui/screen-handoff
git commit -m "docs(design): DEV-<task6> Indigo Day and Indigo Night in DESIGN.md"
```

---

### Task 7: Gate, goldens, golden review and the audit

**Files:**
- Modify: every `test/**/goldens/*.png` the regeneration rewrites

- [ ] **Step 1: The gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: PASS (format, analyze, generated, architecture, docs, guard, suite). Fix any failure at its owner and rerun.

- [ ] **Step 2: Regenerate the goldens**

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update` then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh`
Expected: the second run PASS; `git status --short test | grep -c png` reports the changed count.

- [ ] **Step 3: Golden review page**

Use the `golden-compare` skill on the branch's changed PNGs; publish the page; send the owner the link.

- [ ] **Step 4: Impeccable audit**

One `impeccable audit` of the regenerated goldens (light and dark, every screen) against the updated `DESIGN.md`, with Review Focus 1–2 checked explicitly. Findings are fixed in one batch, the gate and goldens rerun once, and the findings are reported to the owner; no second audit.

- [ ] **Step 5: Commit**

```bash
git add test
git commit -m "test(golden): DEV-<task7> regenerate goldens for the Indigo palette"
```
