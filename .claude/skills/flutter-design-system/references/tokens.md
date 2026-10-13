# Design tokens

Location: `lib/core/theme/`. The values are the owner's "Flashcard Color Tokens"
spec ([`docs/shared/design/memox-design-tokens.md`](../../../../docs/shared/design/memox-design-tokens.md),
ADR-022), which outranks every other document; `test/core/theme/flashcard_tokens_spec_test.dart`
pins them. Change a value only through that spec.

```
lib/core/theme/
├── app_theme.dart              # buildLightTheme() / buildDarkTheme()
├── app_color_schemes.dart      # AppColorSchemes.light / .dark: const ColorScheme, 46 literal roles
├── mx_semantic_colors.dart     # MxSemanticColors ThemeExtension: 44 fields (cardSurface, *Soft, info…)
├── app_typography.dart         # AppTypography: Be Vietnam Pro + Noto Sans KR, the 12 TextTheme roles
├── mx_text_styles.dart         # MxTextStyles: each style is one role, only its colour changes
├── app_component_themes.dart   # Material component themes
├── app_button_style.dart       # appButtonStyle, appFocusRing, appStateLayer
├── app_decorations.dart        # card and study-choice surfaces (no edge, no shadow)
├── mastery_ramp.dart           # MasteryRamp thresholds and track
├── theme_context.dart          # context.colors / texts / semanticColors / textStyles
└── foundations/
    ├── app_spacing.dart        # AppSpacing + context.screenMargin / isCompactWindow
    ├── app_radius.dart         # AppRadius (M3 shape scale)
    ├── app_size.dart           # AppSize (buttons, bars, breakpoints, columns)
    ├── app_icon_size.dart      # AppIconSize
    ├── app_stroke.dart         # AppStroke
    ├── app_opacity.dart        # AppOpacity (M3 state layers)
    ├── app_durations.dart      # AppDurations (M3 motion durations)
    ├── app_easing.dart         # AppEasing (M3 easing curves)
    ├── app_shadows.dart        # AppShadows (no resting shadow)
    └── app_effects.dart        # AppEffects.scrimOpacity
```

## Scales

```dart
abstract final class AppSpacing {
  static const double micro = 4;
  static const double control = 8;
  static const double grouped = 12;
  static const double gutter = 16;        // compact screen margin, gap between items
  static const double gutterMedium = 24;  // screen margin from 600
  static const double cardCompact = 16;   // card interior on the overview
  static const double card = 24;          // card interior
  static const double section = 24;
  static const double major = 32;
  static const double pageEnd = 48;
}
// A screen's side margin: context.screenMargin (16 below 600, 24 from 600).

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;     // deck tile, banner
  static const double md = 12;    // every card, match tile, input
  static const double lg = 16;
  static const double xl = 28;    // dialog, bottom sheet
  static const double full = 999; // button, search, progress, nav pill
}

abstract final class AppSize {
  static const double buttonRegular = 40; // M3 Expressive S
  static const double buttonSmall = 32;   // M3 Expressive XS
  static const double touchTarget = 48;
  static const double search = 56;
  static const double appBar = 64;
  static const double bottomNavBar = 64;
  static const double navIndicatorWidth = 56;
  static const double navIndicatorHeight = 32;
  static const double navRail = 80;
  static const double navRailBreakpoint = 600;
  static const double expandedBreakpoint = 840;
  static const double contentMaxWidth = 599;      // compact column, every session
  static const double contentMaxWidthWide = 1040; // from 600
  static const double progressTrack = 4;
  static const double deckTile = 64;
  // … chip 28, input 52, fab 52, avatar 48 (see app_size.dart)
}

abstract final class AppOpacity {
  static const double hover = 0.08;
  static const double pressed = 0.10;
  static const double focus = 0.10;
  static const double dragged = 0.16;
  static const double disabled = 0.38;
  static const double disabledContainer = 0.12;
}

abstract final class AppDurations {
  static const Duration selection = Durations.short2;      // 100
  static const Duration toggle = Durations.short3;         // 150
  static const Duration standard = Durations.short4;       // 200
  static const Duration sheet = Durations.medium2;         // 300
  static const Duration pageTransition = Durations.medium4; // 400
  static const Duration longTransition = Durations.long4;  // 600
}

abstract final class AppEasing {
  static const Curve standard = Easing.standard;
  static const Curve standardDecelerate = Easing.standardDecelerate; // entering
  static const Curve standardAccelerate = Easing.standardAccelerate; // leaving
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve linear = Curves.linear;                         // countdowns
}
```

`abstract final class` is the idiomatic Dart namespace for constants — it cannot
be instantiated or extended, which is exactly what you want from a token holder.

## Semantic colours

`ColorScheme` covers the 46 Material 3 roles; everything else is a field of
`MxSemanticColors`, a `ThemeExtension` with a `light` and a `dark` literal each
(status fills and their text tokens, the soft grounds and their borders and text,
`cardSurface`, `searchSurface`, `tileSurface`, `divider`, `info`,
`infoContainer`, `onInfoContainer`). A soft ground is its colour at 16% over the
theme's surface, precomputed as a solid hex: light in light, dark in dark. Nothing
derives a colour at run time.

```dart
Container(color: context.semanticColors.cardSurface)            // a card
Text(label, style: context.textStyles.rowTitle)                 // a row title
Icon(glyph, color: context.semanticColors.primaryText)          // indigo text or glyph
```

Read it through `ThemeContext` (`lib/core/theme/theme_context.dart`):
`context.colors`, `context.texts`, `context.semanticColors`, `context.textStyles`.

## Typography

The `TextTheme` has twelve roles (spec §3.2): `displaySmall` 24/32, `headlineSmall`
20/28, `displayMedium` 28/36 tabular, `titleLarge` 20/28 w600, `titleMedium` 18/24
w500, `titleSmall` 14/20 w500, `bodyLarge` 16/24, `bodyMedium` 14/20, `bodySmall`
13/16, `labelLarge` 14/20, `labelMedium` 14/20, `labelSmall` 12/16 w500. Widgets read
a component style from `context.textStyles`, which is one role with its colour; they
never build a `TextStyle`.

```dart
Text('Title', style: context.textStyles.screenTitle)               // yes
Text('Title', style: TextStyle(fontSize: 22, color: Colors.black)) // no
```

A hardcoded `fontSize` does not respond to the platform text-scale setting the same
way, and a hardcoded `Colors.black` is invisible in dark mode.

## Theme construction

```dart
ThemeData buildLightTheme() =>
    _build(AppColorSchemes.light, MxSemanticColors.light);
```

`AppColorSchemes.light` and `.dark` are `const ColorScheme(...)` with all 46 roles as
literals; there is no `ColorScheme.fromSeed`. Every pair of text and ground is checked
by `test/core/theme/token_contrast_test.dart`; a pair below AA is a recorded exception
with its measured ratio (spec §2.3).

## Verifying tokens are actually used

```bash
# hardcoded colours in feature code
grep -rnE 'Colors\.[a-z]|Color\(0x' lib/features lib/shared

# hardcoded text styles
grep -rn 'TextStyle(' lib/features

# raw padding values
grep -rnE 'EdgeInsets\.(all|symmetric|only)\([^)]*[0-9]' lib/features
```

Hits in `core/theme/` are expected and fine — that is where the values are
supposed to live. Hits anywhere else are the defect.
