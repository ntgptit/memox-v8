# Flutter UI Base — Phase 2 (Chrome, Layout and Their Parts) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first eleven `Mx*` shared widgets: Button, IconButton, EmptyState, AppBar, StudyTopBar, Breadcrumb, BottomNav, Fab, AppShell, ScreenScroll and FooterBar. Each gets widget tests and light/dark goldens, so phase 3 can wire the four-tab shell from them.

**Architecture:**
- Every widget lives in `lib/shared/widgets/mx_<name>.dart`. It reads the theme only through `context.colors` / `texts` / `semanticColors` / `derivedColors` / `textStyles` and the `App*` tokens.
- Component type treatments are named styles in a new `MxTextStyles`, in `lib/core/theme/`. The guard forbids shared widgets from building or restyling a `TextStyle`.
- Material widgets are used where they carry the contract: `TextButton` and `IconButton` with a `ButtonStyle` give the 48 touch area over a smaller painted box; `Scaffold` places the FAB and the bottom bar.
- Custom widgets are used where the contract is richer: the glass bottom nav, the study bar, the breadcrumb.
- Goldens are generated on Windows with the real fonts loaded by `test/flutter_test_config.dart`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Material 3, `flutter_test` (golden files, `meetsGuideline`).

**Spec:** [`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`](../specs/2026-09-23-flutter-ui-base-design.md), §5 component conventions, §8.1 phase 2, §8.2, §8.3 and §9.
- Widget contracts: `docs/shared/ui/design-handoff/widgets/{button,icon-button,empty-state,app-bar,study-top-bar,breadcrumb,bottom-nav,fab,app-shell,screen-scroll,footer-bar}.md`.
- Phase 1 API it builds on: `lib/core/theme/`, merged in #19.

## Global Constraints

- UI only: nothing under `lib/features/`, `lib/core/database|error|id/` or `lib/app/` is created or changed.
- `lib/shared/` imports only `package:flutter/*` and `package:memox/core/...`. `lib/core/theme/` imports only Flutter and itself.
- These guard rules become active on `lib/shared/` and Task 2 deletes their `targets_pending` entries. Shared widget code must satisfy them:
  - No `Color(0x…)`, `Colors.*`, `Color.fromARGB`/`fromRGBO`.
  - No `EdgeInsets…(…<digit>…)`, `SizedBox(width|height: <digit>`, `spacing: <digit>`, `BorderRadius.circular(<digit>`, `TextStyle(`.
  - No `texts.x.copyWith(`, `textStyles.x.copyWith(`, `.styleFrom(`, `fontWeight: FontWeight.`, and no `strokeWidth:`/`width:` literal on a border.
  - No `Text('literal')` with letters, and no `label|title|tooltip|semanticLabel: 'literal'`.
- Component-specific numbers the contract states (a 44 top padding, a 0.10 tint) are named `static const` in the widget file, never inline literals.
- Every interactive widget meets a 48×48 touch area (`androidTapTargetGuideline`) and has a label (`labeledTapTargetGuideline`). Icon-only controls take a required `semanticLabel`.
- No fixed height around text and no text-scale clamping. At text scale 2.0 no widget throws an overflow.
- `MediaQuery.disableAnimationsOf(context)` turns every animation to `Duration.zero`.
- A widget holds no copy. Every string arrives from the caller.
- Goldens: `goldens/<name>_light.png` and `_dark.png` at 360×800. They live in `test/shared/widgets/shared_widgets_golden_test.dart`, tagged `golden`, generated on Windows, tolerance zero.
- Tests find widgets by type, key or semantics, never by an English literal that production code would own. Test inputs such as `'Save'` are the caller's strings and are fine.
- Commits are conventional with scope `ui`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Replies to the user are in Vietnamese.

## Review Focus

1. **Large text in fixed chrome.** AppBar, StudyTopBar and BottomNav are 56/56/64 tall in the contract. At text scale 2.0 a 24px title or a 12px label no longer fits, and a fixed box throws a `RenderFlex overflowed`. They use a minimum height and grow instead (Rulings R1, R3), pinned by a text-scale-2.0 test in Tasks 5, 6 and 8.
2. **Touch targets on painted-small controls.** Button small/compact/chip (36/32/28), IconButton (36) and breadcrumb segments (12px text) must still offer 48×48. Pinned by `expectAccessibleTargets` in Tasks 2, 3 and 7.
3. **Bottom insets.** The gesture inset must be added exactly once: by BottomNav and FooterBar to their own padding, by ScreenScroll to its tail, by AppShell's FAB anchor. A screen with nav plus FAB must not double it. Pinned by the inset tests in Tasks 8 and 10.
4. **Breadcrumb deep paths.** At 10 levels the current (last) segment must be visible without scrolling. A 2-level path must still start at the left gutter rather than hug the right edge. Pinned in Task 7.
5. **Loading button width.** A button entering loading must keep the width it had, or a dialog row jumps. Pinned in Task 2.

## Rulings made while planning (carried into spec §9 by Task 11)

- **R1:** AppBar and StudyTopBar use a *minimum* height of 56 and grow only when text scaling makes the title taller. The contract's "FIXED 56, ellipsis" clips at scale 2.0, and Foundations forbids fixed heights around text. For the same reason MxAppShell places the app bar in-flow at the top of the body instead of in `Scaffold.appBar`, whose fixed `preferredSize` would clip it.
- **R2:** The Button chip size paints `surfaceContainerLowest` whatever the tone. Its ink is UNSPECIFIED in the contract. `onSurface` is used, the ink of that surface, because a primary-tone chip would otherwise paint white on white.
- **R3:** The BottomNav bar has a minimum height of 64 (same reason as R1). Labels stay on one line with ellipsis, the safe default the contract names.
- **R4:** Breadcrumb segments get a 48×48 minimum hit area. The painted text is unchanged, and the row is 48 tall instead of 2 + text + 8. The contract's padding would give 12px-tall targets.
- **R5:** The focus ring is drawn as a 2px `primary` side on the control's own edge. The contract's offset of 2 is not drawn: `ButtonStyle` cannot offset a side, and a custom focus painter is not justified for Android touch-first use.
- **R6:** StudyTopBar's track uses `progress-track` (`surfaceContainerHigh`) from its theme-consumption table, over "surfaceContainer" in its dimension line. `02-theme-binding.md` names `themeRoleUsage` the source of truth for component colours. This follows the critique's "track token mismatch" P1.
- **R7:** EmptyState's tile→title (16) and title→body (8) gaps are UNSPECIFIED. The spacing roles "screen gutter" and "control internal" are used.
- **R8:** EmptyState's footnote slot is deferred to phase 5, when `MxNote` exists. MxButton's loading spinner is a plain `CircularProgressIndicator` until phase 6's `MxSpinner` replaces it.

---

## File Structure

```
lib/core/theme/foundations/app_stroke.dart        + indicator (2)
lib/core/theme/foundations/app_icons.dart         AppIcons: Lucide name → Icons.*
lib/core/theme/mx_text_styles.dart                MxTextStyles: component type treatments
lib/core/theme/app_decorations.dart               AppDecorations.raisedCard
lib/core/theme/theme_context.dart                 + textStyles
lib/shared/widgets/mx_button.dart                 MxButton, MxButtonTone, MxButtonSize
lib/shared/widgets/mx_icon_button.dart            MxIconButton
lib/shared/widgets/mx_empty_state.dart            MxEmptyState, MxEmptyStateTone
lib/shared/widgets/mx_app_bar.dart                MxAppBar, MxAppBarDensity
lib/shared/widgets/mx_study_top_bar.dart          MxStudyTopBar
lib/shared/widgets/mx_breadcrumb.dart             MxBreadcrumb, MxBreadcrumbSegment
lib/shared/widgets/mx_bottom_nav.dart             MxBottomNav, MxNavDestination
lib/shared/widgets/mx_fab.dart                    MxFab
lib/shared/widgets/mx_app_shell.dart              MxAppShell
lib/shared/widgets/mx_screen_scroll.dart          MxScreenScroll, MxScrollClearance
lib/shared/widgets/mx_footer_bar.dart             MxFooterBar
code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml   − 10 entries
dart_test.yaml                                    tag: golden
test/flutter_test_config.dart                     loads bundled fonts for every test
test/support/widget_harness.dart                  pumpMx, pumpMxPage, expectAccessibleTargets
test/support/golden_harness.dart                  expectThemedGoldens
test/core/theme/mx_text_styles_test.dart
test/core/theme/app_decorations_test.dart
test/shared/widgets/mx_<name>_test.dart           one per widget
test/shared/widgets/shared_widgets_golden_test.dart
test/shared/widgets/goldens/*.png                 generated
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md   §9 += R1–R8
```

---

### Task 1: Theme additions and test harness

**Files:**
- Create: `lib/core/theme/foundations/app_icons.dart`, `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/app_decorations.dart`, `dart_test.yaml`, `test/flutter_test_config.dart`, `test/support/widget_harness.dart`, `test/support/golden_harness.dart`
- Modify: `lib/core/theme/foundations/app_stroke.dart`, `lib/core/theme/theme_context.dart`, `test/core/theme/foundations_test.dart`
- Test: `test/core/theme/mx_text_styles_test.dart`, `test/core/theme/app_decorations_test.dart`

**Interfaces:**
- Consumes: phase 1's `AppTypography.withWeight`, `ThemeContext`, `AppShadows.whisper`, `MxDerivedColors`, `buildLightTheme`/`buildDarkTheme`.
- Produces:
  - `AppStroke.indicator` (`double` 2)
  - `AppIcons.<name>` (`IconData`): `add, back, close, more, search, chevronRight, check, delete, retry, play, inbox, tag, library, librarySelected, study, studySelected, progress, progressSelected, settings, settingsSelected`
  - `MxTextStyles(TextTheme, ColorScheme)`:
    - getters `buttonLabel, buttonLabelSmall, contentTitle, screenTitle, emptyTitle, emptyTitleCompact, emptyBody, breadcrumbAncestor, breadcrumbCurrent, counter, footerCaption`
    - methods `studyBadge(Color accent)`, `navLabel({required bool isSelected})`
  - `context.textStyles` → `MxTextStyles`
  - `AppDecorations.raisedCard(ColorScheme, MxDerivedColors)` → `BoxDecoration`
  - Test support:
    - `pumpMx(WidgetTester, Widget, {Brightness brightness, double textScale, EdgeInsets padding})`
    - `pumpMxPage(WidgetTester, Widget, {EdgeInsets padding})`
    - `expectAccessibleTargets(WidgetTester)`
    - `expectThemedGoldens(WidgetTester, String name, Widget child)`

- [ ] **Step 1: Write the failing tests**

Append to `test/core/theme/foundations_test.dart`, inside `main()` after the last test:

```dart
  test('the indicator stroke is the spinner arc width', () {
    expect(AppStroke.indicator, 2);
  });
```

`test/core/theme/mx_text_styles_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Component type treatments, each from its widget contract.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme);

  void expectStyle(
    TextStyle style, {
    required double size,
    required FontWeight weight,
    double? tracking,
    Color? color,
  }) {
    expect(style.fontSize, size);
    expect(style.fontWeight, weight);
    expect(
      style.fontVariations,
      contains(FontVariation.weight(weight.value.toDouble())),
    );
    if (tracking != null) expect(style.letterSpacing, tracking);
    if (color != null) expect(style.color, color);
  }

  test('button labels: 14/600 and 12/600, both at 0.1 tracking', () {
    expectStyle(
      styles.buttonLabel,
      size: 14,
      weight: FontWeight.w600,
      tracking: 0.1,
    );
    expectStyle(
      styles.buttonLabelSmall,
      size: 12,
      weight: FontWeight.w600,
      tracking: 0.1,
    );
  });

  test('app-bar titles: content 16/700/-0.3, screen 24/700/-0.5', () {
    expectStyle(
      styles.contentTitle,
      size: 16,
      weight: FontWeight.w700,
      tracking: -0.3,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.screenTitle,
      size: 24,
      weight: FontWeight.w700,
      tracking: -0.5,
      color: scheme.onSurface,
    );
  });

  test('empty state: title 20/700/-0.3, compact 16/700, body 14 at 1.55', () {
    expectStyle(
      styles.emptyTitle,
      size: 20,
      weight: FontWeight.w700,
      tracking: -0.3,
    );
    expectStyle(styles.emptyTitleCompact, size: 16, weight: FontWeight.w700);
    expectStyle(
      styles.emptyBody,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.emptyBody.height, 1.55);
  });

  test('breadcrumb: ancestor 12/500, current 12/700, 0.1 tracking', () {
    expectStyle(
      styles.breadcrumbAncestor,
      size: 12,
      weight: FontWeight.w500,
      tracking: 0.1,
      color: scheme.onSurfaceVariant,
    );
    expectStyle(
      styles.breadcrumbCurrent,
      size: 12,
      weight: FontWeight.w700,
      tracking: 0.1,
      color: scheme.onSurface,
    );
  });

  test('study bar: badge 12/700 in the accent, counter tabular', () {
    const accent = Color(0xFF123456);
    expectStyle(
      styles.studyBadge(accent),
      size: 12,
      weight: FontWeight.w700,
      tracking: 1.2,
      color: accent,
    );
    expect(
      styles.counter.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(styles.counter.color, scheme.onSurfaceVariant);
  });

  test('nav label is primary only when selected', () {
    expect(styles.navLabel(isSelected: true).color, scheme.primary);
    expect(styles.navLabel(isSelected: false).color, scheme.onSurfaceVariant);
    expectStyle(
      styles.navLabel(isSelected: true),
      size: 12,
      weight: FontWeight.w600,
    );
  });

  test('footer caption is 12 onSurfaceVariant', () {
    expectStyle(
      styles.footerCaption,
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
  });
}
```

`test/core/theme/app_decorations_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

// Card contract: surface-raised, radius 20, whisper shadow in light,
// 1px ghost border and no shadow in dark.
void main() {
  test('light: surface-raised with the whisper shadow and no border', () {
    final scheme = AppColorSchemes.light;
    final card = AppDecorations.raisedCard(
      scheme,
      MxDerivedColors.resolve(scheme, MxSemanticColors.light),
    );

    expect(card.color, scheme.surfaceContainerLowest);
    expect(card.borderRadius, BorderRadius.circular(20));
    expect(card.boxShadow, AppShadows.whisper(scheme));
    expect(card.border, isNull);
  });

  test('dark: a 1px ghost border and no shadow', () {
    final scheme = AppColorSchemes.dark;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.dark);
    final card = AppDecorations.raisedCard(scheme, derived);

    expect(card.boxShadow, isEmpty);
    expect(card.border, Border.all(color: derived.ghostBorder));
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/foundations_test.dart test/core/theme/mx_text_styles_test.dart test/core/theme/app_decorations_test.dart`
Expected: FAIL. Compilation errors, because `AppStroke.indicator`, `mx_text_styles.dart` and `app_decorations.dart` do not exist.

- [ ] **Step 3: Implement the theme additions**

In `lib/core/theme/foundations/app_stroke.dart`, add after `focusOffset`:

```dart

  /// Spinner arc and other progress strokes.
  static const double indicator = 2;
```

`lib/core/theme/foundations/app_icons.dart`:

```dart
import 'package:flutter/material.dart';

/// The handoff's Lucide glyph names mapped once, by meaning, to the built-in
/// Material Icons (spec §2). One concept, one glyph. A navigation destination
/// has an outlined resting glyph and a filled selected one.
abstract final class AppIcons {
  static const IconData add = Icons.add; // plus
  static const IconData back = Icons.arrow_back; // arrow-left
  static const IconData close = Icons.close; // x
  static const IconData more = Icons.more_vert; // more-vertical
  static const IconData search = Icons.search; // search
  static const IconData chevronRight = Icons.chevron_right; // chevron-right
  static const IconData check = Icons.check; // check
  static const IconData delete = Icons.delete_outline; // trash-2
  static const IconData retry = Icons.refresh; // refresh-cw
  static const IconData play = Icons.play_arrow; // play
  static const IconData inbox = Icons.inbox_outlined; // inbox
  static const IconData tag = Icons.sell_outlined; // tag

  // Top-level destinations (bottom nav): layers · play · bar-chart-3 · settings.
  static const IconData library = Icons.layers_outlined;
  static const IconData librarySelected = Icons.layers;
  static const IconData study = Icons.play_circle_outline;
  static const IconData studySelected = Icons.play_circle;
  static const IconData progress = Icons.bar_chart_outlined;
  static const IconData progressSelected = Icons.bar_chart;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsSelected = Icons.settings;
}
```

`lib/core/theme/mx_text_styles.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';

/// Component type treatments: the overrides of the nearest V3 role that a
/// widget contract states (spec §4.3). They live in the theme so shared
/// widgets never build or restyle a TextStyle.
@immutable
final class MxTextStyles {
  const MxTextStyles(this._texts, this._scheme);

  final TextTheme _texts;
  final ColorScheme _scheme;

  static const double _labelTracking = 0.1;
  static const double _titleTracking = -0.3;
  static const double _screenTitleTracking = -0.5;
  static const double _emptyBodyHeight = 1.55;

  /// Button label: 14/600, 0.1 tracking (regular, small, study action).
  TextStyle get buttonLabel => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _labelTracking);

  /// Button label on the compact and chip sizes: 12/600, 0.1 tracking.
  TextStyle get buttonLabelSmall =>
      _texts.labelSmall!.copyWith(letterSpacing: _labelTracking);

  /// App-bar content title (deck and card names): 16/700, -0.3.
  TextStyle get contentTitle => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _titleTracking, color: _scheme.onSurface);

  /// App-bar screen title: 24/700, -0.5.
  TextStyle get screenTitle => _texts.headlineSmall!.copyWith(
    letterSpacing: _screenTitleTracking,
    color: _scheme.onSurface,
  );

  /// EmptyState title: 20/700, -0.3.
  TextStyle get emptyTitle => _texts.titleLarge!.copyWith(
    letterSpacing: _titleTracking,
    color: _scheme.onSurface,
  );

  /// Compact EmptyState title: 16/700, -0.3.
  TextStyle get emptyTitleCompact => contentTitle;

  /// EmptyState body: 14 at line-height 1.55.
  TextStyle get emptyBody => _texts.bodyMedium!.copyWith(
    height: _emptyBodyHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// Tappable breadcrumb level: 12/500, 0.1 tracking.
  TextStyle get breadcrumbAncestor => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w500,
  ).copyWith(letterSpacing: _labelTracking, color: _scheme.onSurfaceVariant);

  /// The level the user is on: 12/700, 0.1 tracking.
  TextStyle get breadcrumbCurrent => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _labelTracking, color: _scheme.onSurface);

  /// StudyTopBar mode badge: 12/700, 1.2 tracking, in the caller's accent.
  TextStyle studyBadge(Color accent) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(color: accent);

  /// StudyTopBar n / total counter: 12/600, tabular numerals.
  TextStyle get counter => _texts.labelSmall!.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    color: _scheme.onSurfaceVariant,
  );

  /// BottomNav label: 12/600, primary on the current destination.
  TextStyle navLabel({required bool isSelected}) => _texts.labelSmall!.copyWith(
    color: isSelected ? _scheme.primary : _scheme.onSurfaceVariant,
  );

  /// FooterBar caption under the actions: 12, onSurfaceVariant.
  TextStyle get footerCaption =>
      _texts.labelSmall!.copyWith(color: _scheme.onSurfaceVariant);
}
```

`lib/core/theme/app_decorations.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';

/// Surface treatments shared by more than one component contract.
abstract final class AppDecorations {
  /// The Card surface: surface-raised fill and radius 20; the whisper shadow
  /// in light and a 1px ghost border in dark, which has no shadow.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: scheme.brightness == Brightness.dark
        ? Border.all(color: derived.ghostBorder, width: AppStroke.hairline)
        : null,
    boxShadow: AppShadows.whisper(scheme),
  );
}
```

In `lib/core/theme/theme_context.dart`, add the import and the getter:

```dart
import 'package:memox/core/theme/mx_text_styles.dart';
```

```dart
  MxTextStyles get textStyles => MxTextStyles(texts, colors);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/theme`
Expected: PASS. All theme tests: phase 1's 90 plus 1, 7 and 2 new.

- [ ] **Step 5: Add the test harness**

`dart_test.yaml`:

```yaml
tags:
  golden:
    description: >-
      Pixel comparisons with committed PNGs, generated on Windows
      (spec §8.2). Regenerate with: flutter test --update-goldens --tags golden
```

`test/flutter_test_config.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every font the app bundles (Plus Jakarta Sans, Material Icons), so
/// text and glyphs render for real in every test instead of as Ahem boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  await testMain();
}

Future<void> _loadBundledFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final font in fonts) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
```

`test/support/widget_harness.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

/// The phone frame every shared-widget test runs in (spec §8.2).
const Size phoneSize = Size(360, 800);

void _usePhone(WidgetTester tester) {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

MediaQueryData _media(
  BuildContext context, {
  double textScale = 1,
  EdgeInsets padding = EdgeInsets.zero,
}) => MediaQuery.of(context).copyWith(
  textScaler: TextScaler.linear(textScale),
  padding: padding,
  viewPadding: padding,
);

/// Pumps [child] centred in a Scaffold under the MemoX theme.
Future<void> pumpMx(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  _usePhone(tester);
  return tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? buildLightTheme()
          : buildDarkTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: _media(context, textScale: textScale, padding: padding),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

/// Pumps [page] as the whole route, for widgets that own their Scaffold.
Future<void> pumpMxPage(
  WidgetTester tester,
  Widget page, {
  EdgeInsets padding = EdgeInsets.zero,
}) {
  _usePhone(tester);
  return tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Builder(
        builder: (context) =>
            MediaQuery(data: _media(context, padding: padding), child: page),
      ),
    ),
  );
}

/// Every tappable node is at least 48×48 and has a label.
Future<void> expectAccessibleTargets(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}
```

`test/support/golden_harness.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'widget_harness.dart';

/// Renders [child] on each theme's page ground at 360×800 and compares it
/// with `goldens/<name>_light.png` and `goldens/<name>_dark.png` beside the
/// calling test file.
Future<void> expectThemedGoldens(
  WidgetTester tester,
  String name,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(phoneSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  for (final (suffix, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/${name}_$suffix.png'),
    );
  }
}
```

- [ ] **Step 6: Confirm the harness breaks nothing**

Run: `flutter test`
Expected: PASS, the whole suite with real fonts loaded. If `FontManifest.json` has no `MaterialIcons` entry, glyphs will still render as boxes in goldens. Stop and report it.

- [ ] **Step 7: Analyze, guard, commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme test/core/theme dart_test.yaml test/flutter_test_config.dart test/support
git commit -m "feat(theme): component text styles, card decoration, icon map, widget test harness

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: analyze clean, guard `Errors: 0 | Warnings: 0`.

---

### Task 2: MxButton, and the guard entries the first shared file retires

**Files:**
- Create: `lib/shared/widgets/mx_button.dart`, `test/shared/widgets/shared_widgets_golden_test.dart`
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
- Test: `test/shared/widgets/mx_button_test.dart`

**Interfaces:**
- Consumes: Task 1's `context.textStyles.buttonLabel/buttonLabelSmall`, `AppStroke.indicator`, `pumpMx`, `expectAccessibleTargets`, `expectThemedGoldens`.
- Produces:
  - `enum MxButtonTone { primary, secondary, outline, destructive }`
  - `enum MxButtonSize { regular, small, compact, chip, study }`
  - `MxButton({required String label, required VoidCallback? onPressed, MxButtonTone tone = primary, MxButtonSize size = regular, IconData? icon, bool isBlock = false, bool isLoading = false})`

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

Material _material(WidgetTester tester) =>
    tester.widget<Material>(_painted.first);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('each size paints its height and keeps a 48 target', (
    tester,
  ) async {
    const heights = {
      MxButtonSize.regular: 48.0,
      MxButtonSize.small: 36.0,
      MxButtonSize.compact: 32.0,
      MxButtonSize.chip: 28.0,
      MxButtonSize.study: 48.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await pumpMx(tester, MxButton(label: 'Go', size: size, onPressed: () {}));

      expect(tester.getSize(_painted.first).height, height, reason: '$size');
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
        reason: '$size',
      );
    }
  });

  testWidgets('tones paint their fill, ink and edge', (tester) async {
    final expected = {
      MxButtonTone.primary: (scheme.primary, scheme.onPrimary, BorderSide.none),
      MxButtonTone.secondary: (
        scheme.surfaceContainer,
        scheme.onSurface,
        BorderSide.none,
      ),
      MxButtonTone.destructive: (
        MxSemanticColors.light.errorFill,
        MxSemanticColors.light.onErrorFill,
        BorderSide.none,
      ),
    };
    for (final MapEntry(key: tone, value: (fill, ink, edge))
        in expected.entries) {
      await pumpMx(tester, MxButton(label: 'Go', tone: tone, onPressed: () {}));
      final material = _material(tester);

      expect(material.color, fill, reason: '$tone');
      expect(material.textStyle!.color, ink, reason: '$tone');
      expect((material.shape! as RoundedRectangleBorder).side, edge);
    }
  });

  testWidgets('outline tone has no fill, primary ink, 1px outlineVariant', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Go', tone: MxButtonTone.outline, onPressed: () {}),
    );
    final material = _material(tester);

    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, scheme.primary);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: scheme.outlineVariant),
    );
  });

  testWidgets('chip size paints its own surface and ghost edge (R2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
    );
    final material = _material(tester);
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);

    expect(material.color, scheme.surfaceContainerLowest);
    expect(material.textStyle!.color, scheme.onSurface);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(color: derived.ghostBorder),
    );
  });

  testWidgets('a tap calls onPressed', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () => taps++));
    await tester.tap(find.byType(MxButton));

    expect(taps, 1);
  });

  testWidgets('disabled dims the whole control to 0.38 and ignores taps', (
    tester,
  ) async {
    await pumpMx(tester, const MxButton(label: 'Go', onPressed: null));

    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byType(TextButton), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.38);
  });

  testWidgets('loading keeps the width, shows a spinner and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(tester, MxButton(label: 'Save changes', onPressed: () {}));
    final restingWidth = tester.getSize(_painted.first).width;

    await pumpMx(
      tester,
      MxButton(
        label: 'Save changes',
        isLoading: true,
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.byType(MxButton), warnIfMissed: false);

    expect(tester.getSize(_painted.first).width, restingWidth);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(taps, 0);
  });

  testWidgets('a leading glyph is painted at 16', (tester) async {
    await pumpMx(
      tester,
      MxButton(label: 'Add', icon: AppIcons.add, onPressed: () {}),
    );

    expect(tester.getSize(find.byIcon(AppIcons.add)).width, 16);
  });

  testWidgets('block fills the parent width', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
      ),
    );

    expect(tester.getSize(_painted.first).width, 300);
  });

  testWidgets('a constrained label wraps and grows the box at 2x text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 160,
        child: MxButton(
          label: 'Move every selected card',
          isBlock: true,
          onPressed: () {},
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_painted.first).height, greaterThan(48));
  });

  testWidgets('small painted sizes still offer 48×48 labelled targets', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxButton(label: 'Pick', size: MxButtonSize.small, onPressed: () {}),
          MxButton(label: 'Undo', size: MxButtonSize.compact, onPressed: () {}),
          MxButton(label: 'Tag', size: MxButtonSize.chip, onPressed: () {}),
        ],
      ),
    );

    await expectAccessibleTargets(tester);
  });
}
```

`test/shared/widgets/shared_widgets_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxButton tones, sizes and states', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_button',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          for (final tone in MxButtonTone.values)
            MxButton(label: tone.name, tone: tone, onPressed: () {}),
          MxButton(
            label: 'Small',
            size: MxButtonSize.small,
            icon: AppIcons.add,
            onPressed: () {},
          ),
          MxButton(label: 'Compact', size: MxButtonSize.compact, onPressed: () {}),
          MxButton(label: 'Chip', size: MxButtonSize.chip, onPressed: () {}),
          MxButton(label: 'Reveal', size: MxButtonSize.study, onPressed: () {}),
          const MxButton(label: 'Disabled', onPressed: null),
          MxButton(label: 'Saving', isLoading: true, onPressed: () {}),
          MxButton(
            label: 'Start review',
            icon: AppIcons.play,
            isBlock: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_button_test.dart`
Expected: FAIL, compilation error: `mx_button.dart` not found.

- [ ] **Step 3: Implement `mx_button.dart`**

`lib/shared/widgets/mx_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Colour role of a button: the contract's four shipped tones.
enum MxButtonTone { primary, secondary, outline, destructive }

/// Painted geometry. [chip] and [study] are the contract's geometry variants;
/// the touch area is 48 for every size.
enum MxButtonSize { regular, small, compact, chip, study }

typedef _Paint = ({Color? fill, Color ink, BorderSide edge});
typedef _Geometry = ({
  double height,
  double radius,
  double padding,
  bool isSmallType,
  bool canWrap,
});

/// The one button contract: height, radius, padding and label type come from
/// [size], colours from [tone]. The caller owns placement and width; [isBlock]
/// fills the parent.
class MxButton extends StatelessWidget {
  const MxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = MxButtonTone.primary,
    this.size = MxButtonSize.regular,
    this.icon,
    this.isBlock = false,
    this.isLoading = false,
  });

  final String label;

  /// Null disables the button under the global 0.38 rule.
  final VoidCallback? onPressed;
  final MxButtonTone tone;
  final MxButtonSize size;

  /// Optional leading glyph, painted at 16.
  final IconData? icon;
  final bool isBlock;

  /// Replaces the label with a spinner, keeps the width and blocks presses.
  final bool isLoading;

  /// A caller-constrained label wraps to at most this many lines.
  static const int _maxWrappedLines = 2;

  /// Study action horizontal padding (contract: 0 36).
  static const double _studyPadding = 36;

  @override
  Widget build(BuildContext context) {
    final paint = _paintFor(context);
    final geometry = _geometryFor(size, hasIcon: icon != null);
    final button = TextButton(
      onPressed: isLoading ? null : onPressed,
      style: _style(context, paint, geometry),
      child: _content(paint.ink, geometry),
    );
    final sized = isBlock
        ? SizedBox(width: double.infinity, child: button)
        : button;
    if (onPressed != null) return sized;
    return Opacity(opacity: AppOpacity.disabled, child: sized);
  }

  _Paint _paintFor(BuildContext context) {
    final colors = context.colors;
    if (size == MxButtonSize.chip) {
      // Chip geometry paints its own surface whatever the tone (ruling R2).
      return (
        fill: colors.surfaceContainerLowest,
        ink: colors.onSurface,
        edge: BorderSide(
          color: context.derivedColors.ghostBorder,
          width: AppStroke.hairline,
        ),
      );
    }
    return switch (tone) {
      MxButtonTone.primary => (
        fill: colors.primary,
        ink: colors.onPrimary,
        edge: BorderSide.none,
      ),
      MxButtonTone.secondary => (
        fill: colors.surfaceContainer,
        ink: colors.onSurface,
        edge: BorderSide.none,
      ),
      MxButtonTone.outline => (
        fill: null,
        ink: colors.primary,
        edge: BorderSide(color: colors.outlineVariant, width: AppStroke.hairline),
      ),
      MxButtonTone.destructive => (
        fill: context.semanticColors.errorFill,
        ink: context.semanticColors.onErrorFill,
        edge: BorderSide.none,
      ),
    };
  }

  static _Geometry _geometryFor(MxButtonSize size, {required bool hasIcon}) =>
      switch (size) {
        MxButtonSize.regular => (
          height: AppSize.buttonRegular,
          radius: AppRadius.md,
          padding: AppSpacing.gutter,
          isSmallType: false,
          canWrap: true,
        ),
        MxButtonSize.small => (
          height: AppSize.buttonSmall,
          radius: AppRadius.md,
          padding: hasIcon ? AppSpacing.gutter : AppSpacing.grouped,
          isSmallType: false,
          canWrap: false,
        ),
        MxButtonSize.compact => (
          height: AppSize.buttonCompact,
          radius: AppRadius.sm,
          padding: AppSpacing.grouped,
          isSmallType: true,
          canWrap: false,
        ),
        MxButtonSize.chip => (
          height: AppSize.chip,
          radius: AppRadius.full,
          padding: AppSpacing.control,
          isSmallType: true,
          canWrap: false,
        ),
        MxButtonSize.study => (
          height: AppSize.buttonRegular,
          radius: AppRadius.full,
          padding: _studyPadding,
          isSmallType: false,
          canWrap: false,
        ),
      };

  ButtonStyle _style(BuildContext context, _Paint paint, _Geometry geometry) {
    final focusRing = BorderSide(
      color: context.colors.primary,
      width: AppStroke.focus,
    );
    final textStyles = context.textStyles;
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(paint.fill),
      foregroundColor: WidgetStatePropertyAll(paint.ink),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.pressed)
            ? paint.ink.withValues(alpha: AppOpacity.pressed)
            : null,
      ),
      // Ruling R5: the focus ring sits on the control's own edge.
      side: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.focused) ? focusRing : paint.edge,
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(geometry.radius),
        ),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: geometry.padding),
      ),
      minimumSize: WidgetStatePropertyAll(Size(0, geometry.height)),
      tapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textStyle: WidgetStatePropertyAll(
        geometry.isSmallType
            ? textStyles.buttonLabelSmall
            : textStyles.buttonLabel,
      ),
    );
  }

  Widget _content(Color ink, _Geometry geometry) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: geometry.canWrap ? _maxWrappedLines : 1,
      softWrap: geometry.canWrap,
    );
    final body = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              Icon(icon, size: AppIconSize.inline),
              Flexible(child: text),
            ],
          );
    if (!isLoading) return body;

    // The hidden label holds the width the button already had.
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility.maintain(visible: false, child: body),
        SizedBox.square(
          dimension: AppIconSize.inline,
          child: CircularProgressIndicator(
            strokeWidth: AppStroke.indicator,
            color: ink,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_button_test.dart`
Expected: PASS, 11 tests.

- [ ] **Step 5: Generate and check the golden**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/shared_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/shared_widgets_golden_test.dart
```

Expected: the first run writes `test/shared/widgets/goldens/mx_button_light.png` and `_dark.png`; the second passes.

Open both PNGs with the Read tool and check them against the Button contract:
- Four tones at 48 with a 12 radius.
- The small/compact/chip heights step down.
- The chip is a pill with a hairline edge.
- The study action is a pill.
- Disabled is visibly dimmed, and the spinner sits in a button of unchanged width.
- The block button fills the width.
- Glyphs render as icons, not boxes.

Any mismatch is a code defect: fix it and regenerate.

- [ ] **Step 6: Retire the guard entries this first shared file satisfies**

Run: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`

Expected: exactly 10 `stale_targets_pending` warnings:
- `memox.architecture.no_transaction_outside_data_layer`
- `memox.architecture.widget_no_database_access`
- `memox.architecture.widget_no_repository_access`
- `memox.design_token.no_raw_border_radius`
- `memox.design_token.no_raw_color`
- `memox.design_token.no_raw_spacing_literal`
- `memox.design_token.no_raw_text_style`
- `memox.i18n.no_literal_user_string`
- `memox_v7.design_system.no_flat_style_from`
- `memox_v7.design_system.no_text_restyle`

If the list differs, stop and report it. Delete exactly those ten two-line entries (`<rule id>:` plus its `targets_pending:` line) from `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`. Re-run the guard. Expected: `Errors: 0 | Warnings: 0`, with no error from the newly active rules on `mx_button.dart`.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test
flutter analyze
flutter test
git add lib/shared test/shared code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(ui): MxButton; retire the ten guard pendings shared/ satisfies

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: MxIconButton

**Files:**
- Create: `lib/shared/widgets/mx_icon_button.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_icon_button_test.dart`

**Interfaces:**
- Consumes: `pumpMx`, `expectAccessibleTargets`, `expectThemedGoldens`, `AppIcons`.
- Produces: `MxIconButton({required IconData icon, required String semanticLabel, required VoidCallback? onPressed})`

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_icon_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(IconButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('a 36 ink circle, a 20 glyph and a 48 target', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.more,
        semanticLabel: 'More',
        onPressed: () {},
      ),
    );

    expect(tester.getSize(_painted.first), const Size.square(36));
    expect(tester.getSize(find.byIcon(AppIcons.more)), const Size.square(20));
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(48),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('the glyph is onSurface on no fill', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(icon: AppIcons.search, semanticLabel: 'Search', onPressed: () {}),
    );
    final glyph = tester.element(find.byIcon(AppIcons.search));

    expect(IconTheme.of(glyph).color, AppColorSchemes.light.onSurface);
    expect(tester.widget<Material>(_painted.first).color?.a ?? 0, 0);
  });

  testWidgets('the semantic label names the control and a tap fires', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxIconButton(
        icon: AppIcons.close,
        semanticLabel: 'Close',
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Close'));

    expect(taps, 1);
  });

  testWidgets('disabled dims to 0.38', (tester) async {
    await pumpMx(
      tester,
      MxIconButton(icon: AppIcons.close, semanticLabel: 'Close', onPressed: null),
    );

    expect(
      tester.widget<Opacity>(
        find.ancestor(of: find.byType(IconButton), matching: find.byType(Opacity)),
      ).opacity,
      0.38,
    );
  });
}
```

Append to `shared_widgets_golden_test.dart`: the import `package:memox/shared/widgets/mx_icon_button.dart`, then this test inside `main()`:

```dart
  testWidgets('MxIconButton resting and disabled', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_icon_button',
      Row(
        children: [
          MxIconButton(icon: AppIcons.back, semanticLabel: 'Back', onPressed: () {}),
          MxIconButton(icon: AppIcons.search, semanticLabel: 'Search', onPressed: () {}),
          MxIconButton(icon: AppIcons.more, semanticLabel: 'More', onPressed: () {}),
          const MxIconButton(icon: AppIcons.close, semanticLabel: 'Close', onPressed: null),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_icon_button_test.dart`
Expected: FAIL: `mx_icon_button.dart` not found.

- [ ] **Step 3: Implement `mx_icon_button.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A 20 glyph in a 36 round ink box with a 48 touch area: the kit's only
/// bare-icon control. [semanticLabel] names it for screen readers and shows as
/// its tooltip.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;

  /// Null disables the control under the global 0.38 rule.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = IconButton(
      icon: Icon(icon),
      tooltip: semanticLabel,
      onPressed: onPressed,
      style: ButtonStyle(
        iconSize: const WidgetStatePropertyAll(AppIconSize.compact),
        foregroundColor: WidgetStatePropertyAll(colors.onSurface),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? colors.onSurface.withValues(alpha: AppOpacity.pressed)
              : null,
        ),
        // Ruling R5: the focus ring sits on the circle's edge.
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: colors.primary, width: AppStroke.focus)
              : null,
        ),
        shape: const WidgetStatePropertyAll(CircleBorder()),
        fixedSize: const WidgetStatePropertyAll(
          Size.square(AppSize.iconButtonInk),
        ),
        minimumSize: const WidgetStatePropertyAll(
          Size.square(AppSize.iconButtonInk),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
    if (onPressed != null) return button;
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_icon_button_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Golden, analyze, guard, commit**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/shared_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/shared_widgets_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets/mx_icon_button.dart test/shared/widgets
git commit -m "feat(ui): MxIconButton

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check `mx_icon_button_light.png` and `_dark.png` with the Read tool: four glyphs, no painted fill, and the last one dimmed. Expected: analyze clean, guard 0/0.

---

### Task 4: MxEmptyState

**Files:**
- Create: `lib/shared/widgets/mx_empty_state.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_empty_state_test.dart`

**Interfaces:**
- Consumes: `MxButton` (Task 2), `AppDecorations.raisedCard`, `context.textStyles.emptyTitle/emptyTitleCompact/emptyBody` (Task 1).
- Produces:
  - `enum MxEmptyStateTone { primary, neutral, success, warning, danger }`
  - `MxEmptyState({required IconData icon, required String title, String? body, MxEmptyStateTone tone = primary, bool isCompact = false, String? actionLabel, VoidCallback? onAction})`, where `actionLabel` and `onAction` come together.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_empty_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import '../../support/widget_harness.dart';

Finder _tile(IconData icon) => find
    .ancestor(of: find.byIcon(icon), matching: find.byType(DecoratedBox))
    .first;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('title, body and a block primary action', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxEmptyState(
        icon: AppIcons.inbox,
        title: 'No decks yet',
        body: 'Create one to start.',
        actionLabel: 'Create deck',
        onAction: () => taps++,
      ),
    );
    await tester.tap(find.byType(MxButton));

    expect(find.text('No decks yet'), findsOneWidget);
    expect(find.text('Create one to start.'), findsOneWidget);
    final button = tester.widget<MxButton>(find.byType(MxButton));
    expect(button.tone, MxButtonTone.primary);
    expect(button.isBlock, isTrue);
    expect(taps, 1);
  });

  testWidgets('no action paints no button', (tester) async {
    await pumpMx(
      tester,
      const MxEmptyState(icon: AppIcons.search, title: 'No match'),
    );

    expect(find.byType(MxButton), findsNothing);
  });

  testWidgets('a label without a callback is a programming error', (
    tester,
  ) async {
    expect(
      () => MxEmptyState(icon: AppIcons.inbox, title: 'x', actionLabel: 'Go'),
      throwsAssertionError,
    );
  });

  testWidgets('tone tints the tile at 10% and paints the glyph', (
    tester,
  ) async {
    final tones = {
      MxEmptyStateTone.primary: scheme.primary,
      MxEmptyStateTone.neutral: scheme.onSurfaceVariant,
      MxEmptyStateTone.success: MxSemanticColors.light.mastery,
      MxEmptyStateTone.warning: MxSemanticColors.light.warning,
      MxEmptyStateTone.danger: scheme.error,
    };
    for (final MapEntry(key: tone, value: color) in tones.entries) {
      await pumpMx(
        tester,
        MxEmptyState(icon: AppIcons.inbox, title: 'T', tone: tone),
      );
      final tile = tester.widget<DecoratedBox>(_tile(AppIcons.inbox));

      expect(
        (tile.decoration as BoxDecoration).color,
        color.withValues(alpha: 0.10),
        reason: '$tone',
      );
      expect(tester.widget<Icon>(find.byIcon(AppIcons.inbox)).color, color);
    }
  });

  testWidgets('full tile is 64/r20/32 glyph, compact 52/r16/24', (
    tester,
  ) async {
    await pumpMx(tester, const MxEmptyState(icon: AppIcons.inbox, title: 'T'));
    expect(tester.getSize(_tile(AppIcons.inbox)), const Size.square(64));
    expect(tester.getSize(find.byIcon(AppIcons.inbox)).width, 32);

    await pumpMx(
      tester,
      const MxEmptyState(icon: AppIcons.inbox, title: 'T', isCompact: true),
    );
    expect(tester.getSize(_tile(AppIcons.inbox)), const Size.square(52));
    expect(tester.getSize(find.byIcon(AppIcons.inbox)).width, 24);
  });

  testWidgets('long copy at 2x text does not overflow', (tester) async {
    await pumpMx(
      tester,
      const MxEmptyState(
        icon: AppIcons.inbox,
        title: 'Nothing is due today across every deck you study',
        body: 'Every card is resting until its next review date arrives.',
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
```

Append to the golden file: the import `package:memox/shared/widgets/mx_empty_state.dart`, then:

```dart
  testWidgets('MxEmptyState full with action, compact neutral', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_empty_state',
      Column(
        spacing: 16,
        children: [
          MxEmptyState(
            icon: AppIcons.inbox,
            title: 'No decks yet',
            body: 'Create a deck or add a starter deck to begin.',
            actionLabel: 'Create deck',
            onAction: () {},
          ),
          const MxEmptyState(
            icon: AppIcons.search,
            title: 'No match',
            body: 'Try another word.',
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_empty_state_test.dart`
Expected: FAIL: `mx_empty_state.dart` not found.

- [ ] **Step 3: Implement `mx_empty_state.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// What the surface's emptiness means: action-led, a plain fact, a calm
/// finish, something to act on, or a failed outcome.
enum MxEmptyStateTone { primary, neutral, success, warning, danger }

/// The centred "this is the state of this surface" card: tinted tile, title,
/// one line of copy and optionally the action that fixes it.
class MxEmptyState extends StatelessWidget {
  const MxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.tone = MxEmptyStateTone.primary,
    this.isCompact = false,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction come together',
       );

  final IconData icon;
  final String title;
  final String? body;
  final MxEmptyStateTone tone;

  /// Inside another card or a sheet.
  final bool isCompact;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const double _tileTint = 0.10;
  static const double _tileSize = 64;
  static const double _compactTileSize = 52;

  /// Full card top padding (contract: 44 24 32).
  static const double _topPadding = 44;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(context);
    final styles = context.textStyles;
    final padding = isCompact
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.section,
            vertical: AppSpacing.major,
          )
        : const EdgeInsets.fromLTRB(
            AppSpacing.section,
            _topPadding,
            AppSpacing.section,
            AppSpacing.major,
          );
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: AppDecorations.raisedCard(
          context.colors,
          context.derivedColors,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tile(icon: icon, color: toneColor, isCompact: isCompact),
              // Ruling R7: the tile→title and title→body gaps are
              // UNSPECIFIED in the contract.
              const SizedBox(height: AppSpacing.gutter),
              Text(
                title,
                textAlign: TextAlign.center,
                style: isCompact ? styles.emptyTitleCompact : styles.emptyTitle,
              ),
              if (body case final body?) ...[
                const SizedBox(height: AppSpacing.control),
                Text(body, textAlign: TextAlign.center, style: styles.emptyBody),
              ],
              if ((actionLabel, onAction) case (
                final label?,
                final onPressed?,
              )) ...[
                const SizedBox(height: AppSpacing.card),
                MxButton(label: label, onPressed: onPressed, isBlock: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(BuildContext context) => switch (tone) {
    MxEmptyStateTone.primary => context.colors.primary,
    MxEmptyStateTone.neutral => context.colors.onSurfaceVariant,
    MxEmptyStateTone.success => context.semanticColors.mastery,
    MxEmptyStateTone.warning => context.semanticColors.warning,
    MxEmptyStateTone.danger => context.colors.error,
  };
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.isCompact,
  });

  final IconData icon;
  final Color color;
  final bool isCompact;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: isCompact
        ? MxEmptyState._compactTileSize
        : MxEmptyState._tileSize,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: MxEmptyState._tileTint),
        borderRadius: BorderRadius.circular(
          isCompact ? AppRadius.lg : AppRadius.xl,
        ),
      ),
      child: Icon(
        icon,
        size: isCompact ? AppIconSize.standard : AppIconSize.large,
        color: color,
      ),
    ),
  );
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_empty_state_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxEmptyState`. Check the golden:
- The card is raised, with a whisper shadow in light and a hairline in dark.
- The tile is tinted with the glyph centred.
- The title is bold and centred, with the action full width below.
- The compact card is tighter, with a smaller tile.

---

### Task 5: MxAppBar

**Files:**
- Create: `lib/shared/widgets/mx_app_bar.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_app_bar_test.dart`

**Interfaces:**
- Consumes: `context.textStyles.contentTitle/screenTitle`, `MxIconButton`.
- Produces:
  - `enum MxAppBarDensity { content, screen }`
  - `MxAppBar({required String title, MxAppBarDensity density = screen, Widget? leading, List<Widget> actions = const []})`. It is a plain widget, not a `PreferredSizeWidget` (ruling R1): MxAppShell places it in-flow.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_app_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('56 tall on the page ground, below the status inset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxAppBar(title: 'Library'),
      padding: const EdgeInsets.only(top: 24),
    );

    expect(tester.getSize(find.byType(MxAppBar)).height, 56 + 24);
  });

  testWidgets('screen density: 24 title, 16 gutter', (tester) async {
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(tester.widget<Text>(find.text('Library')).style!.fontSize, 24);
    expect(
      tester.getTopLeft(find.text('Library')).dx -
          tester.getTopLeft(find.byType(MxAppBar)).dx,
      16,
    );
  });

  testWidgets('content density: 16 title after the leading control', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxAppBar(
        title: 'Japanese N5',
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Japanese N5')).style!.fontSize, 16);
  });

  testWidgets('a long title ellipsises and the actions keep their width', (
    tester,
  ) async {
    final title = 'A deck name that is far too long to fit ' * 3;
    await pumpMx(
      tester,
      MxAppBar(
        title: title,
        density: MxAppBarDensity.content,
        actions: [
          MxIconButton(icon: AppIcons.search, semanticLabel: 'Search', onPressed: () {}),
          MxIconButton(icon: AppIcons.more, semanticLabel: 'More', onPressed: () {}),
        ],
      ),
    );
    final text = tester.widget<Text>(find.text(title));

    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(MxIconButton).last).width, 48);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the title is a header for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxAppBar(title: 'Library'));

    expect(
      tester.getSemantics(find.text('Library')),
      containsSemantics(label: 'Library', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('2x text grows the bar instead of overflowing (R1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxAppBar(title: 'Progress'), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MxAppBar)).height,
      greaterThanOrEqualTo(56),
    );
  });
}
```

Append to the golden file: the import `package:memox/shared/widgets/mx_app_bar.dart`, then:

```dart
  testWidgets('MxAppBar both densities', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_app_bar',
      Column(
        children: [
          const MxAppBar(title: 'Library'),
          MxAppBar(
            title: 'Japanese N5 · Verbs of motion and a very long name',
            density: MxAppBarDensity.content,
            leading: MxIconButton(icon: AppIcons.back, semanticLabel: 'Back', onPressed: () {}),
            actions: [
              MxIconButton(icon: AppIcons.search, semanticLabel: 'Search', onPressed: () {}),
              MxIconButton(icon: AppIcons.more, semanticLabel: 'More', onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_app_bar_test.dart`
Expected: FAIL: `mx_app_bar.dart` not found.

- [ ] **Step 3: Implement `mx_app_bar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Content bar (a back control and a deck/card name) or screen bar (a screen
/// name). Both are 56 tall.
enum MxAppBarDensity { content, screen }

/// The top chrome: leading control, flexible title, trailing actions. The
/// title is the only slot that gives up width; it ellipsises on one line.
///
/// Placed in-flow by MxAppShell. It is 56 tall at minimum and grows only when
/// text scaling makes the title taller (ruling R1).
class MxAppBar extends StatelessWidget {
  const MxAppBar({
    super.key,
    required this.title,
    this.density = MxAppBarDensity.screen,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final MxAppBarDensity density;

  /// Usually an MxIconButton (back, or close in selection mode).
  final Widget? leading;

  /// MxIconButtons or compact MxButtons; never dropped for the title.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isContent = density == MxAppBarDensity.content;
    final styles = context.textStyles;
    return ColoredBox(
      color: context.colors.surface,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.appBar),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isContent ? AppSpacing.control : AppSpacing.gutter,
            ),
            child: Row(
              spacing: AppSpacing.micro,
              children: [
                ?leading,
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isContent
                          ? styles.contentTitle
                          : styles.screenTitle,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`?leading` is Dart 3.8+ null-aware element syntax and is available on Dart 3.13.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_app_bar_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxAppBar`. Check the golden:
- The screen bar shows a 24 bold title at a 16 gutter.
- The content bar shows a back arrow, a 16 bold title cut with an ellipsis, and two actions at the right.
- There is no fill or shadow.

---

### Task 6: MxStudyTopBar

**Files:**
- Create: `lib/shared/widgets/mx_study_top_bar.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_study_top_bar_test.dart`

**Interfaces:**
- Consumes: `MxIconButton`, `MasteryRamp.track`, `context.textStyles.studyBadge/counter`, `AppDurations.standard`.
- Produces: `MxStudyTopBar({required String modeLabel, required int current, required int total, required String closeLabel, required VoidCallback onClose, Color? accent})`. `current` is 1-based, in `[1, total]`, and `total` is at least 1. The accent defaults to `primary`.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_study_top_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import '../../support/widget_harness.dart';

MxStudyTopBar _bar({int current = 3, int total = 10, Color? accent}) =>
    MxStudyTopBar(
      modeLabel: 'Review',
      current: current,
      total: total,
      closeLabel: 'Close session',
      onClose: () {},
      accent: accent,
    );

double _fill(WidgetTester tester) =>
    tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;

void main() {
  testWidgets('fill is current/total and the counter reads n / total', (
    tester,
  ) async {
    await pumpMx(tester, _bar());
    await tester.pumpAndSettle();

    expect(_fill(tester), 0.3);
    expect(find.text('3 / 10'), findsOneWidget);
  });

  testWidgets('the badge is the mode label upper-cased', (tester) async {
    await pumpMx(tester, _bar());

    expect(find.text('REVIEW'), findsOneWidget);
  });

  testWidgets('accent defaults to primary and follows the caller', (
    tester,
  ) async {
    Color fillColor() => tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byType(FractionallySizedBox),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;

    await pumpMx(tester, _bar());
    expect(fillColor(), AppColorSchemes.light.primary);

    await pumpMx(tester, _bar(accent: MxSemanticColors.light.mastery));
    expect(fillColor(), MxSemanticColors.light.mastery);
  });

  testWidgets('the track is progress-track (R6)', (tester) async {
    await pumpMx(tester, _bar());
    final track = tester.widget<ColoredBox>(
      find.ancestor(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      ).first,
    );

    expect(track.color, AppColorSchemes.light.surfaceContainerHigh);
  });

  testWidgets('the fill animates over 200ms unless motion is reduced', (
    tester,
  ) async {
    await pumpMx(tester, _bar(current: 1));
    await pumpMx(tester, _bar(current: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fill(tester), inExclusiveRange(0.1, 0.5));
    await tester.pumpAndSettle();

    Widget reduced(int current) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: _bar(current: current)),
      ),
    );
    await tester.pumpWidget(reduced(1));
    await tester.pumpWidget(reduced(9));
    await tester.pump();
    expect(_fill(tester), 0.9);
  });

  testWidgets('close is a labelled 48 target that fires onClose', (
    tester,
  ) async {
    var closed = 0;
    await pumpMx(
      tester,
      MxStudyTopBar(
        modeLabel: 'Review',
        current: 1,
        total: 2,
        closeLabel: 'Close session',
        onClose: () => closed++,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Close session'));

    expect(closed, 1);
    await expectAccessibleTargets(tester);
  });

  test('current outside [1, total] or an empty session is rejected', () {
    expect(() => _bar(current: 0), throwsAssertionError);
    expect(() => _bar(current: 11), throwsAssertionError);
    expect(() => _bar(current: 1, total: 0), throwsAssertionError);
  });

  testWidgets('2x text grows the bar instead of overflowing (R1)', (
    tester,
  ) async {
    await pumpMx(tester, _bar(), textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
```

Append to the golden file: the imports `package:memox/core/theme/mx_semantic_colors.dart` and `package:memox/shared/widgets/mx_study_top_bar.dart`, then:

```dart
  testWidgets('MxStudyTopBar default and mastery accent', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_study_top_bar',
      Column(
        children: [
          MxStudyTopBar(modeLabel: 'Review', current: 3, total: 10, closeLabel: 'Close', onClose: () {}),
          MxStudyTopBar(
            modeLabel: 'Recall',
            current: 10,
            total: 10,
            closeLabel: 'Close',
            onClose: () {},
            accent: MxSemanticColors.light.mastery,
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_study_top_bar_test.dart`
Expected: FAIL: `mx_study_top_bar.dart` not found.

- [ ] **Step 3: Implement `mx_study_top_bar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Session chrome for the study modes: close, mode badge, a thin progress
/// track and an n / total counter. [accent] (primary by default) drives the
/// badge, its tint and the fill, so one bar carries every mode's colour.
class MxStudyTopBar extends StatelessWidget {
  const MxStudyTopBar({
    super.key,
    required this.modeLabel,
    required this.current,
    required this.total,
    required this.closeLabel,
    required this.onClose,
    this.accent,
  }) : assert(total >= 1, 'a session has at least one card'),
       assert(
         current >= 1 && current <= total,
         'current is 1-based and within total',
       );

  final String modeLabel;

  /// 1-based position of the card on screen; the track is never empty once a
  /// session starts.
  final int current;
  final int total;
  final String closeLabel;

  /// Leaving mid-session is the screen's decision; this bar only reports it.
  final VoidCallback onClose;
  final Color? accent;

  static const double _badgeTint = 0.10;
  static const double _trackHeight = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = accent ?? colors.primary;
    final styles = context.textStyles;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.standard;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        // Ruling R1: 56 at minimum, grows with text scaling.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.appBar),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
            child: Row(
              spacing: AppSpacing.control,
              children: [
                MxIconButton(
                  icon: AppIcons.close,
                  semanticLabel: closeLabel,
                  onPressed: onClose,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: _badgeTint),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.control,
                      vertical: AppSpacing.micro,
                    ),
                    child: Text(
                      modeLabel.toUpperCase(),
                      style: styles.studyBadge(accentColor),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: SizedBox(
                      height: _trackHeight,
                      child: ColoredBox(
                        color: MasteryRamp.track(colors),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: current / total),
                            duration: duration,
                            curve: Easing.standard,
                            builder: (context, fraction, _) =>
                                FractionallySizedBox(
                                  widthFactor: fraction,
                                  heightFactor: 1,
                                  child: ColoredBox(color: accentColor),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text('$current / $total', style: styles.counter),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

The counter sits 8 from the right edge through the row's horizontal padding (contract: "8 right inset").

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_study_top_bar_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxStudyTopBar`. Check the golden:
- An X control.
- A tinted uppercase badge.
- A thin track at 30% in indigo, and a second bar at 100% in green.
- Tabular counters.

---

### Task 7: MxBreadcrumb

**Files:**
- Create: `lib/shared/widgets/mx_breadcrumb.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_breadcrumb_test.dart`

**Interfaces:**
- Consumes: `context.textStyles.breadcrumbAncestor/breadcrumbCurrent`, `AppIcons.chevronRight`.
- Produces:
  - `MxBreadcrumbSegment({required String label, VoidCallback? onTap})`
  - `MxBreadcrumb({required List<MxBreadcrumbSegment> segments})`. The last segment is the current level, and its `onTap` is ignored.

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_breadcrumb_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../../support/widget_harness.dart';

List<MxBreadcrumbSegment> _path(int depth, {void Function(int)? onTap}) => [
  for (var i = 1; i <= depth; i++)
    MxBreadcrumbSegment(label: 'Level $i', onTap: () => onTap?.call(i)),
];

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('ancestors are tappable, the current level is not', (
    tester,
  ) async {
    final tapped = <int>[];
    await pumpMx(tester, MxBreadcrumb(segments: _path(3, onTap: tapped.add)));
    await tester.tap(find.text('Level 1'));
    await tester.tap(find.text('Level 3'), warnIfMissed: false);

    expect(tapped, [1]);
  });

  testWidgets('ancestor 500 onSurfaceVariant, current 700 onSurface', (
    tester,
  ) async {
    await pumpMx(tester, MxBreadcrumb(segments: _path(2)));

    final ancestor = tester.widget<Text>(find.text('Level 1')).style!;
    final current = tester.widget<Text>(find.text('Level 2')).style!;
    expect(ancestor.fontWeight, FontWeight.w500);
    expect(ancestor.color, scheme.onSurfaceVariant);
    expect(current.fontWeight, FontWeight.w700);
    expect(current.color, scheme.onSurface);
  });

  testWidgets('one outline chevron at 16 between each pair', (tester) async {
    await pumpMx(tester, MxBreadcrumb(segments: _path(4)));
    final chevrons = find.byIcon(AppIcons.chevronRight);

    expect(chevrons, findsNWidgets(3));
    expect(tester.widget<Icon>(chevrons.first).color, scheme.outline);
    expect(tester.getSize(chevrons.first).width, 16);
  });

  testWidgets('a short path starts at the 16 gutter', (tester) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(2))),
    );

    expect(
      tester.getTopLeft(find.text('Level 1')).dx -
          tester.getTopLeft(find.byType(MxBreadcrumb)).dx,
      greaterThanOrEqualTo(16),
    );
    expect(
      tester.getTopLeft(find.text('Level 1')).dx -
          tester.getTopLeft(find.byType(MxBreadcrumb)).dx,
      lessThan(40),
    );
  });

  testWidgets('a 10-level path shows the current level without scrolling', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(10))),
    );

    expect(tester.getRect(find.text('Level 10')).right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ancestor segments are 48×48 labelled targets (R4)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxBreadcrumb(
        segments: [
          MxBreadcrumbSegment(label: 'A', onTap: () {}),
          const MxBreadcrumbSegment(label: 'B'),
        ],
      ),
    );

    await expectAccessibleTargets(tester);
  });
}
```

Append to the golden file: the import `package:memox/shared/widgets/mx_breadcrumb.dart`, then:

```dart
  testWidgets('MxBreadcrumb short and deep', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_breadcrumb',
      Column(
        children: [
          MxBreadcrumb(
            segments: [
              MxBreadcrumbSegment(label: 'Japanese', onTap: () {}),
              MxBreadcrumbSegment(label: 'N5', onTap: () {}),
              const MxBreadcrumbSegment(label: 'Verbs'),
            ],
          ),
          MxBreadcrumb(
            segments: [
              for (var i = 1; i < 10; i++)
                MxBreadcrumbSegment(label: 'Level $i', onTap: () {}),
              const MxBreadcrumbSegment(label: 'Level 10'),
            ],
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_breadcrumb_test.dart`
Expected: FAIL: `mx_breadcrumb.dart` not found.

- [ ] **Step 3: Implement `mx_breadcrumb.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One level of a deck path. The id travels in [onTap]'s closure.
@immutable
final class MxBreadcrumbSegment {
  const MxBreadcrumbSegment({required this.label, this.onTap});

  final String label;

  /// Ignored on the last segment, which is the current level.
  final VoidCallback? onTap;
}

/// The deck path inside a nested deck. It never wraps and never truncates a
/// segment. The row scrolls horizontally, opens scrolled to its end so the
/// current level is always in view, and starts at the gutter when it fits.
class MxBreadcrumb extends StatelessWidget {
  const MxBreadcrumb({super.key, required this.segments})
    : assert(segments.length > 0, 'a path has at least the current level');

  final List<MxBreadcrumbSegment> segments;

  @override
  Widget build(BuildContext context) {
    final chevronColor = context.colors.outline;
    // Ruling R4: the row is a 48 touch band, not 2 + text + 8.
    return SizedBox(
      height: AppSize.touchTarget,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.micro,
                children: [
                  for (final (index, segment) in segments.indexed) ...[
                    if (index > 0)
                      Icon(
                        AppIcons.chevronRight,
                        size: AppIconSize.inline,
                        color: chevronColor,
                      ),
                    _Segment(
                      segment: segment,
                      isCurrent: index == segments.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.segment, required this.isCurrent});

  final MxBreadcrumbSegment segment;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    if (isCurrent) {
      return Text(segment.label, style: styles.breadcrumbCurrent);
    }
    return InkWell(
      onTap: segment.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSize.touchTarget,
          minHeight: AppSize.touchTarget,
        ),
        child: Center(
          widthFactor: 1,
          child: Text(segment.label, style: styles.breadcrumbAncestor),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_breadcrumb_test.dart`
Expected: PASS, 6 tests. If "a short path starts at the 16 gutter" fails because the reversed scroll view right-aligns the row, the `ConstrainedBox(minWidth)` wrapper is not taking effect. Debug with superpowers:systematic-debugging, and do not loosen the test: the requirement is left-aligned short paths.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxBreadcrumb`. Check the golden:
- The short path starts at the left.
- The deep path shows "Level 10" at the right edge.
- The chevrons are muted.
- The current level is bold.

---

### Task 8: MxBottomNav

**Files:**
- Create: `lib/shared/widgets/mx_bottom_nav.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_bottom_nav_test.dart`

**Interfaces:**
- Consumes: `context.derivedColors.chromeGlass/ghostBorder`, `AppEffects.glassBlur`, `context.textStyles.navLabel`, `AppIcons` destination glyphs.
- Produces:
  - `MxNavDestination({required IconData icon, required IconData selectedIcon, required String label})`
  - `MxBottomNav({required List<MxNavDestination> destinations, required int selectedIndex, required ValueChanged<int> onSelected})`

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_bottom_nav_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../support/widget_harness.dart';

const _destinations = [
  MxNavDestination(icon: AppIcons.library, selectedIcon: AppIcons.librarySelected, label: 'Library'),
  MxNavDestination(icon: AppIcons.study, selectedIcon: AppIcons.studySelected, label: 'Study'),
  MxNavDestination(icon: AppIcons.progress, selectedIcon: AppIcons.progressSelected, label: 'Progress'),
  MxNavDestination(icon: AppIcons.settings, selectedIcon: AppIcons.settingsSelected, label: 'Settings'),
];

MxBottomNav _nav({int selected = 0, ValueChanged<int>? onSelected}) =>
    MxBottomNav(
      destinations: _destinations,
      selectedIndex: selected,
      onSelected: onSelected ?? (_) {},
    );

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('an 80 block with no inset, 80 + inset with one', (tester) async {
    await pumpMx(tester, _nav());
    expect(tester.getSize(find.byType(MxBottomNav)).height, 80);

    await pumpMx(tester, _nav(), padding: const EdgeInsets.only(bottom: 24));
    expect(tester.getSize(find.byType(MxBottomNav)).height, 80 + 24);
  });

  testWidgets('four equal columns', (tester) async {
    await pumpMx(tester, _nav());
    final widths = [
      for (final d in _destinations)
        tester.getSize(find.ancestor(of: find.text(d.label), matching: find.byType(InkWell))).width,
    ];

    expect(widths.toSet(), hasLength(1));
  });

  testWidgets('the selected destination is primary with its filled glyph', (
    tester,
  ) async {
    await pumpMx(tester, _nav(selected: 1));

    expect(find.byIcon(AppIcons.studySelected), findsOneWidget);
    expect(find.byIcon(AppIcons.study), findsNothing);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color, scheme.primary);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.library)).color, scheme.onSurfaceVariant);
    expect(tester.widget<Text>(find.text('Study')).style!.color, scheme.primary);
  });

  testWidgets('the pill tints primary at 14% in light', (tester) async {
    await pumpMx(tester, _nav());
    final pill = tester.widget<DecoratedBox>(
      find.ancestor(of: find.byIcon(AppIcons.librarySelected), matching: find.byType(DecoratedBox)).first,
    );

    expect((pill.decoration as BoxDecoration).color, scheme.primary.withValues(alpha: 0.14));
  });

  testWidgets('a tap reports the index; the selected item is marked', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? picked;
    await pumpMx(tester, _nav(onSelected: (i) => picked = i));
    await tester.tap(find.text('Progress'));

    expect(picked, 2);
    expect(
      tester.getSemantics(find.text('Library')),
      containsSemantics(label: 'Library', isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('glass: a backdrop blur behind the chrome surface', (tester) async {
    await pumpMx(tester, _nav());

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('2x text grows the bar instead of overflowing (R3)', (
    tester,
  ) async {
    await pumpMx(tester, _nav(), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });
}
```

Append to the golden file: the import `package:memox/shared/widgets/mx_bottom_nav.dart`, then:

```dart
  testWidgets('MxBottomNav on Library', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_bottom_nav',
      Align(
        alignment: Alignment.bottomCenter,
        child: MxBottomNav(
          destinations: const [
            MxNavDestination(icon: AppIcons.library, selectedIcon: AppIcons.librarySelected, label: 'Library'),
            MxNavDestination(icon: AppIcons.study, selectedIcon: AppIcons.studySelected, label: 'Study'),
            MxNavDestination(icon: AppIcons.progress, selectedIcon: AppIcons.progressSelected, label: 'Progress'),
            MxNavDestination(icon: AppIcons.settings, selectedIcon: AppIcons.settingsSelected, label: 'Settings'),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_bottom_nav_test.dart`
Expected: FAIL: `mx_bottom_nav.dart` not found.

- [ ] **Step 3: Implement `mx_bottom_nav.dart`**

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A top-level destination: an outlined resting glyph, a filled selected one.
@immutable
final class MxNavDestination {
  const MxNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The top-level destinations on a translucent glass bar, with a tinted pill
/// behind the current glyph. It is in-flow, never over the scroll, and adds
/// the gesture inset below itself.
class MxBottomNav extends StatelessWidget {
  const MxBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'selectedIndex must name a destination',
       );

  final List<MxNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _pillTintLight = 0.14;
  static const double _pillTintDark = 0.20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final derived = context.derivedColors;
    final inset = MediaQuery.paddingOf(context).bottom;
    final pillTint = colors.primary.withValues(
      alpha: colors.brightness == Brightness.dark
          ? _pillTintDark
          : _pillTintLight,
    );
    final radius = BorderRadius.circular(AppRadius.lg);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.control,
        AppSpacing.micro,
        AppSpacing.control,
        AppSpacing.grouped + inset,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppEffects.glassBlur,
            sigmaY: AppEffects.glassBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: derived.chromeGlass,
              borderRadius: radius,
              border: Border.all(
                color: derived.ghostBorder,
                width: AppStroke.hairline,
              ),
            ),
            // Ruling R3: 64 at minimum, grows with text scaling.
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSize.bottomNavBar,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    for (final (index, destination) in destinations.indexed)
                      Expanded(
                        child: _Item(
                          destination: destination,
                          isSelected: index == selectedIndex,
                          pillTint: pillTint,
                          onTap: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.isSelected,
    required this.pillTint,
    required this.onTap,
  });

  final MxNavDestination destination;
  final bool isSelected;
  final Color pillTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.micro,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected ? pillTint : null,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.micro,
                ),
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: AppIconSize.compact,
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.navLabel(isSelected: isSelected),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_bottom_nav_test.dart`
Expected: PASS, 8 tests.

If the block height is 80 + 1 because the bar grows past 64 at text scale 1, the default label line is too tall for 64. Stop and report it. Do not shrink the text.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxBottomNav`. Check the golden:
- A rounded translucent bar with a hairline.
- Four equal columns.
- An indigo pill behind the filled Library glyph.
- Muted inactive items.

---

### Task 9: MxFab

**Files:**
- Create: `lib/shared/widgets/mx_fab.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_fab_test.dart`

**Interfaces:**
- Consumes: `AppShadows.fab`, `AppSize.fab`.
- Produces: `MxFab({required IconData icon, required String semanticLabel, required VoidCallback onPressed})`. Its placement belongs to MxAppShell (Task 10).

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_fab_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a square 52 primary box, radius 16, 20 onPrimary glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
    );
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(MxFab), matching: find.byType(Material)),
    );

    expect(tester.getSize(find.byType(MxFab)), const Size.square(52));
    expect(material.color, scheme.primary);
    expect(
      (material.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(16),
    );
    expect(tester.widget<Icon>(find.byIcon(AppIcons.add)).color, scheme.onPrimary);
    expect(tester.getSize(find.byIcon(AppIcons.add)).width, 20);
  });

  testWidgets('lifted by the fab shadow', (tester) async {
    await pumpMx(
      tester,
      MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(MxFab), matching: find.byType(DecoratedBox)).first,
    );

    expect((box.decoration as BoxDecoration).boxShadow, AppShadows.fab(scheme));
  });

  testWidgets('the label is its accessible name, never painted', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () => taps++),
    );
    await tester.tap(find.bySemanticsLabel('New deck'));

    expect(find.text('New deck'), findsNothing);
    expect(taps, 1);
    await expectAccessibleTargets(tester);
  });
}
```

Append to the golden file: the import `package:memox/shared/widgets/mx_fab.dart`, then:

```dart
  testWidgets('MxFab resting', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_fab',
      Align(
        alignment: Alignment.bottomRight,
        child: MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_fab_test.dart`
Expected: FAIL: `mx_fab.dart` not found.

- [ ] **Step 3: Implement `mx_fab.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The one pinned action: a square, icon-only 52 box. V3 has no extended FAB.
/// [semanticLabel] is the accessible name and is never painted. Placement
/// belongs to MxAppShell.
class MxFab extends StatelessWidget {
  const MxFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.lg);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.fab(colors),
        ),
        child: Material(
          color: colors.primary,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? colors.onPrimary.withValues(alpha: AppOpacity.pressed)
                  : null,
            ),
            child: SizedBox.square(
              dimension: AppSize.fab,
              child: Icon(
                icon,
                size: AppIconSize.compact,
                color: colors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_fab_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxFab`. Check the golden: a rounded-square indigo box with a white plus and a soft drop shadow in the corner.

---

### Task 10: MxAppShell, MxScreenScroll and MxFooterBar

**Files:**
- Create: `lib/shared/widgets/mx_app_shell.dart`, `lib/shared/widgets/mx_screen_scroll.dart`, `lib/shared/widgets/mx_footer_bar.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_app_shell_test.dart`, `test/shared/widgets/mx_screen_scroll_test.dart`, `test/shared/widgets/mx_footer_bar_test.dart`

**Interfaces:**
- Consumes: `MxAppBar`, `MxBottomNav`, `MxFab`, `MxButton`, `context.textStyles.footerCaption`, `context.derivedColors.ghostBorder`, `pumpMxPage`.
- Produces:
  - `MxAppShell({required Widget body, Widget? appBar, Widget? bottomBar, Widget? footer, Widget? fab})`
  - `enum MxScrollClearance { base, fab, fabAboveNav }`
  - `MxScreenScroll({required List<Widget> children, MxScrollClearance clearance = base})`
  - `MxFooterBar({required Widget child, String? caption})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_app_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../support/widget_harness.dart';

const _bodyKey = Key('body');
const _barKey = Key('bar');
const _footerKey = Key('footer');

Widget _fab() =>
    MxFab(icon: AppIcons.add, semanticLabel: 'New', onPressed: () {});

void main() {
  testWidgets('page ground is surface; app bar above the body', (tester) async {
    await pumpMxPage(
      tester,
      const MxAppShell(
        appBar: MxAppBar(title: 'Library'),
        body: SizedBox.expand(key: _bodyKey),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColorSchemes.light.surface,
    );
    expect(
      tester.getTopLeft(find.byKey(_bodyKey)).dy,
      tester.getBottomLeft(find.byType(MxAppBar)).dy,
    );
  });

  testWidgets('without an app bar the body clears the status inset', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      const MxAppShell(body: SizedBox.expand(key: _bodyKey)),
      padding: const EdgeInsets.only(top: 24),
    );

    expect(tester.getTopLeft(find.byKey(_bodyKey)).dy, 24);
  });

  testWidgets('the footer is in-flow below the body', (tester) async {
    await pumpMxPage(
      tester,
      const MxAppShell(
        body: SizedBox.expand(key: _bodyKey),
        footer: SizedBox(key: _footerKey, height: 72),
      ),
    );

    expect(tester.getBottomLeft(find.byKey(_bodyKey)).dy, 800 - 72);
    expect(tester.getBottomLeft(find.byKey(_footerKey)).dy, 800);
  });

  testWidgets('FAB without nav: 16 from the edge, 24 + inset from the bottom', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      MxAppShell(body: const SizedBox.expand(), fab: _fab()),
      padding: const EdgeInsets.only(bottom: 20),
    );
    await tester.pumpAndSettle();
    final fab = tester.getRect(find.byType(MxFab));

    expect(fab.right, 360 - 16);
    expect(fab.bottom, 800 - 24 - 20);
  });

  testWidgets('FAB above nav: 4 over the bar, inset counted once', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      MxAppShell(
        body: const SizedBox.expand(),
        bottomBar: const SizedBox(key: _barKey, height: 80 + 20),
        fab: _fab(),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(MxFab)).bottom,
      tester.getTopLeft(find.byKey(_barKey)).dy - 4,
    );
  });
}
```

`test/shared/widgets/mx_screen_scroll_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import '../../support/widget_harness.dart';

EdgeInsets _padding(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).padding!.resolve(TextDirection.ltr);

void main() {
  final rows = [for (var i = 0; i < 3; i++) SizedBox(height: 40, key: Key('$i'))];

  testWidgets('16 gutter; base tail 24 + inset', (tester) async {
    await pumpMxPage(
      tester,
      Scaffold(body: MxScreenScroll(children: rows)),
      padding: const EdgeInsets.only(bottom: 20),
    );
    final padding = _padding(tester);

    expect(padding.left, 16);
    expect(padding.right, 16);
    expect(padding.bottom, 24 + 20);
  });

  testWidgets('FAB tail: 24 + 52 + 24 + inset', (tester) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: MxScreenScroll(clearance: MxScrollClearance.fab, children: rows),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );

    expect(_padding(tester).bottom, 24 + 52 + 24 + 20);
  });

  testWidgets('FAB above nav tail: 4 + 52 + 24 + inset', (tester) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: MxScreenScroll(
          clearance: MxScrollClearance.fabAboveNav,
          children: rows,
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );

    expect(_padding(tester).bottom, 4 + 52 + 24 + 20);
  });
}
```

`test/shared/widgets/mx_footer_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('8 / 16 / 16 + inset padding around a block action', (
    tester,
  ) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: MxFooterBar(
            child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );
    final bar = tester.getRect(find.byType(MxFooterBar));
    final button = tester.getRect(find.byType(MxButton));

    expect(button.left - bar.left, 16);
    expect(bar.right - button.right, 16);
    expect(button.top - bar.top, 8);
    expect(bar.bottom - button.bottom, 16 + 20);
  });

  testWidgets('surface fill with a 1px ghost top border', (tester) async {
    await pumpMx(tester, const MxFooterBar(child: SizedBox(height: 48)));
    final decoration = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(MxFooterBar), matching: find.byType(DecoratedBox)).first,
    ).decoration as BoxDecoration;

    expect(decoration.color, scheme.surface);
    expect(
      (decoration.border! as Border).top,
      BorderSide(
        color: MxDerivedColors.resolve(scheme, MxSemanticColors.light).ghostBorder,
      ),
    );
  });

  testWidgets('the caption sits under the action, centred at 0.7', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFooterBar(
        caption: '12 cards selected',
        child: MxButton(label: 'Move', isBlock: true, onPressed: () {}),
      ),
    );

    expect(
      tester.getTopLeft(find.text('12 cards selected')).dy,
      greaterThan(tester.getBottomLeft(find.byType(MxButton)).dy),
    );
    expect(
      tester.widget<Opacity>(find.ancestor(of: find.text('12 cards selected'), matching: find.byType(Opacity))).opacity,
      0.7,
    );
    expect(tester.widget<Text>(find.text('12 cards selected')).textAlign, TextAlign.center);
  });
}
```

Append to the golden file: the imports `package:memox/shared/widgets/mx_app_shell.dart`, `mx_screen_scroll.dart` and `mx_footer_bar.dart`, then:

```dart
  testWidgets('MxAppShell with nav + FAB, and with a footer', (tester) async {
    Widget rows() => MxScreenScroll(
      clearance: MxScrollClearance.fabAboveNav,
      children: [
        for (var i = 0; i < 12; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MxEmptyState(icon: AppIcons.inbox, title: 'Row $i', isCompact: true),
          ),
      ],
    );
    await expectThemedGoldens(
      tester,
      'mx_app_shell',
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: MxAppShell(
              appBar: const MxAppBar(title: 'Library'),
              body: rows(),
              bottomBar: MxBottomNav(
                destinations: const [
                  MxNavDestination(icon: AppIcons.library, selectedIcon: AppIcons.librarySelected, label: 'Library'),
                  MxNavDestination(icon: AppIcons.study, selectedIcon: AppIcons.studySelected, label: 'Study'),
                ],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
              fab: MxFab(icon: AppIcons.add, semanticLabel: 'New', onPressed: () {}),
            ),
          ),
          Expanded(
            child: MxAppShell(
              appBar: const MxAppBar(title: 'Edit'),
              body: rows(),
              footer: MxFooterBar(
                caption: 'Saved on this device',
                child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
              ),
            ),
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_app_shell_test.dart test/shared/widgets/mx_screen_scroll_test.dart test/shared/widgets/mx_footer_bar_test.dart`
Expected: FAIL: the three widget files are not found.

- [ ] **Step 3: Implement the three widgets**

`lib/shared/widgets/mx_screen_scroll.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// Which pinned chrome the scroll's tail must clear. The caller picks it from
/// the chrome its screen has: nav or a footer is [base], because both are
/// in-flow.
enum MxScrollClearance { base, fab, fabAboveNav }

/// The single scrollable region of a screen: the shared 16 gutter and a tail
/// clearance derived from the pinned chrome, plus the gesture inset.
class MxScreenScroll extends StatelessWidget {
  const MxScreenScroll({
    super.key,
    required this.children,
    this.clearance = MxScrollClearance.base,
  });

  final List<Widget> children;
  final MxScrollClearance clearance;

  @override
  Widget build(BuildContext context) {
    final tail = switch (clearance) {
      MxScrollClearance.base => AppSpacing.section,
      MxScrollClearance.fab =>
        AppSpacing.section + AppSize.fab + AppSpacing.section,
      MxScrollClearance.fabAboveNav =>
        AppSpacing.micro + AppSize.fab + AppSpacing.section,
    };
    return ListView(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.gutter,
        end: AppSpacing.gutter,
        bottom: tail + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}
```

`lib/shared/widgets/mx_footer_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The in-flow commit bar (Save, Done, bulk actions): a sibling of the
/// scroll, so it never overlaps content. It owns the gesture inset below
/// itself; call sites never re-declare it.
class MxFooterBar extends StatelessWidget {
  const MxFooterBar({super.key, required this.child, this.caption});

  /// Usually one block MxButton, or a row of them.
  final Widget child;

  /// The calm line under the actions.
  final String? caption;

  static const double _captionOpacity = 0.7;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(
            color: context.derivedColors.ghostBorder,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.control,
          AppSpacing.gutter,
          AppSpacing.gutter + inset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.control,
          children: [
            child,
            if (caption case final caption?)
              Opacity(
                opacity: _captionOpacity,
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: context.textStyles.footerCaption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_app_shell.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The column every screen is: top chrome, one scroll body and a bottom bar,
/// with the FAB layered above. The app bar and footer are in-flow siblings of
/// the body, never overlapping it. The app bar sits in the body column rather
/// than `Scaffold.appBar`, so it can grow with text scaling (ruling R1). The
/// footer sits there too, so it stays above the keyboard.
class MxAppShell extends StatelessWidget {
  const MxAppShell({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.footer,
    this.fab,
  });

  final Widget body;

  /// MxAppBar or MxStudyTopBar.
  final Widget? appBar;

  /// The navigation bar (MxBottomNav). It owns its own gesture inset.
  final Widget? bottomBar;

  /// The commit bar (MxFooterBar).
  final Widget? footer;

  /// The pinned action (MxFab), anchored by the contract's placement rule.
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final appBar = this.appBar;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          ?appBar,
          Expanded(
            child: appBar == null
                ? SafeArea(bottom: false, child: body)
                : MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: body,
                  ),
          ),
          ?footer,
        ],
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: fab,
      floatingActionButtonLocation: _MxFabLocation(
        hasBottomBar: bottomBar != null,
      ),
    );
  }
}

/// FAB placement (Fab contract, caller-owned): 16 from the trailing edge;
/// 24 + gesture inset above the bottom, or 4 above the bottom bar, which
/// already carries the inset.
final class _MxFabLocation extends FloatingActionButtonLocation {
  const _MxFabLocation({required this.hasBottomBar});

  final bool hasBottomBar;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fab = geometry.floatingActionButtonSize;
    final x = switch (geometry.textDirection) {
      TextDirection.ltr =>
        geometry.scaffoldSize.width -
            geometry.minInsets.right -
            AppSpacing.gutter -
            fab.width,
      TextDirection.rtl => geometry.minInsets.left + AppSpacing.gutter,
    };
    // The part of the gesture inset not already covered by a bottom widget.
    final bottomContent = geometry.scaffoldSize.height - geometry.contentBottom;
    final inset = math.max(0.0, geometry.minViewPadding.bottom - bottomContent);
    final gap = hasBottomBar ? AppSpacing.micro : AppSpacing.section;
    return Offset(x, geometry.contentBottom - fab.height - gap - inset);
  }

  @override
  bool operator ==(Object other) =>
      other is _MxFabLocation && other.hasBottomBar == hasBottomBar;

  @override
  int get hashCode => hasBottomBar.hashCode;
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_app_shell_test.dart test/shared/widgets/mx_screen_scroll_test.dart test/shared/widgets/mx_footer_bar_test.dart`
Expected: PASS, 5 + 3 + 3 tests.

If the "FAB without nav" test is off by the inset, the Scaffold's `minViewPadding` did not see the harness `viewPadding`. Check `pumpMxPage` sets both `padding` and `viewPadding` before touching the location math.

- [ ] **Step 5: Golden, analyze, guard, commit**

Same commands as Task 3 Step 5. Commit message: `feat(ui): MxAppShell, MxScreenScroll, MxFooterBar`. Check the golden, two shells side by side:
- The left shell has a title bar, compact rows, a glass nav at the bottom, and a FAB 4 above the nav at the right.
- The right shell has a footer with a hairline top, a full-width Save and a dim centred caption.
- The last row clears the chrome in both.

---

### Task 11: Carry the rulings into the spec, run the gate, hand back

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9 table)

- [ ] **Step 1: Append R1–R8 to the spec's debt register**

In §9, add these rows after row 9. Use the next numbers; these are decisions or gaps, not handoff values.

```markdown
| 10 | AppBar, StudyTopBar (56) and the BottomNav bar (64) are minimum heights that grow with text scaling; MxAppShell places the app bar in-flow instead of `Scaffold.appBar` | phase 2 plan R1, R3 |
| 11 | Button chip size paints `surfaceContainerLowest` + ghost edge with `onSurface` ink whatever the tone; the contract leaves chip ink unspecified | phase 2 plan R2 |
| 12 | Breadcrumb ancestor segments have a 48×48 hit area; the row is 48 tall instead of 2 + text + 8 | phase 2 plan R4 |
| 13 | The focus ring is a 2px `primary` side on the control's own edge; the contract's offset 2 is not drawn | phase 2 plan R5 |
| 14 | StudyTopBar track is `progress-track` (`surfaceContainerHigh`) per its theme-consumption table, over "surfaceContainer" in its dimension line | phase 2 plan R6, critique P1 |
| 15 | EmptyState tile→title (16) and title→body (8) gaps are UNSPECIFIED in the contract and use the spacing roles | phase 2 plan R7 |
| 16 | EmptyState has no footnote slot until MxNote (phase 5); MxButton's loading spinner is a plain `CircularProgressIndicator` until MxSpinner (phase 6) | phase 2 plan R8 |
```

In §3's tree, under `core/theme/`, add these lines after `mastery_ramp.dart`:

```
│   ├── mx_text_styles.dart          component type treatments (phase 2)
│   ├── app_decorations.dart         raised card surface (phase 2)
```

- [ ] **Step 2: Run the phase gate**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: all exit 0. `dart format` changes nothing, the full suite passes with goldens included, and the guard reports `Errors: 0 | Warnings: 0`.

- [ ] **Step 3: Commit and check scope**

```bash
git add docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
git commit -m "docs(spec): record phase 2 rulings in the debt register

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected: paths only under `lib/core/theme/`, `lib/shared/widgets/`, `test/`, `dart_test.yaml`, `docs/superpowers/` and `overrides.yaml`. Anything else is out of scope: revert it.

- [ ] **Step 4: Hand back**

Report to the user in Vietnamese:
- Test and golden counts, and the guard result.
- Every ruling made during execution.
- The golden PNGs checked.

Ask through the AskUserQuestion popup whether to push and open the phase 2 PR. Phase 3's plan is written from the merged API.
