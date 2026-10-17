# Design tokens

**The values are not written here.** The app is drawn with ForUI and its values
live in Dart under `lib/core/theme/`; the `DESIGN.md` frontmatter and the token
part of `.impeccable/design.json` are rendered from the production theme
(`test/tools/design_doc_test.dart`). How to change the look is
`docs/agent/visual-change.md`
([ADR-025](../../../../docs/shared/decisions/ADR-025-forui-la-he-component-giao-dien.md)).
Never copy a hex, a size or a duration into code, a test or a document.

## Where things live

```
lib/core/theme/
├── app_palette.dart        # appLightColors / appDarkColors (ForUI FColors): the only colour values
├── mx_status_colors.dart   # MxStatusColors: success, warning, info and their fills (light / dark)
├── app_typography.dart     # AppTypography.build → FTypography; MxTextRoles (the 12 roles); mono family
├── app_dimens.dart         # AppDimens: spacing, margins, layout sizes, breakpoints
├── app_theme.dart          # buildLightTheme() / buildDarkTheme() (FThemeData); materialHostTheme
├── theme_context.dart      # colors, texts, status, dimens, radii, hairline
├── theme_rules.dart        # windowSize, screenMargin
├── color_tint.dart         # Color.tintOver
├── mastery_ramp.dart
└── app_icons.dart          # Lucide glyphs (FLucideIcons)
```

Nothing else belongs in `lib/core/theme/`; `tools/design/check.py` keeps the
list closed.

## Reading the theme

```dart
extension ThemeContext on BuildContext {
  FColors get colors;          // ForUI's palette
  MxTextRoles get texts;       // the twelve roles on ForUI's type scale
  MxStatusColors get status;   // success, warning, info
  AppDimens get dimens;
  FBorderRadius get radii;     // ForUI's radius scale
  double get hairline;         // ForUI's border width
}
```

That is the whole extension. A colour that differs by mode is a palette value
the light and the dark palettes already differ on; no widget branches on
brightness.

- **Colour:** an `FColors` role (`background`, `foreground`, `primary`,
  `primaryForeground`, `secondary`, `muted`, `mutedForeground`, `error`, `card`,
  `border`, `barrier`, …) or a status colour. A tinted ground is
  `colour.tintOver(MxTintBase.of(context))`; never `withValues(alpha:)` or
  `Color.lerp` for a ground.
- **Text:** the role itself, `context.texts.itemTitle`, changing only the
  colour, `copyWith(color: …)`, or for code `copyWith(fontFamily:
  AppTypography.monoFamily)`. Size, weight and height are the role's. A
  single-line label cut with an ellipsis needs a line height of at least 1.5, or
  stacked Vietnamese diacritics (Ẳ, Ổ, Ỗ) are clipped; a screen that clips is
  reported, not patched.
- **Dimensions:** `context.dimens.space16`, `sizeControl`, `context.radii.md`,
  `context.hairline`. A full radius is `StadiumBorder()`. Motion is Flutter's
  own: `Durations.short4`, `Easing.standard`.
- **A value one widget needs and the theme lacks:** a private constant in that
  widget with a doc comment. One several widgets need goes into `AppDimens`.

## Component styles

Components are ForUI's, behind the `Mx*` facades. A component's look is ForUI's
resolved style for the theme, restyled where the app needs it by a style delta
in its `Mx*` widget (see the `forui-shared-widgets` skill). An `Mx*` widget does
not rebuild a colour, a text style or a radius the ForUI style already has.

## Verifying tokens are actually used

```bash
python3 tools/design/check.py          # closed theme files, palette-only colours, no removed name
dart run tools/ui_lint/ui_lint.dart    # ForUI and Material boundaries
rg -n 'Colors\.[a-z]|Color\(0x' lib/features lib/shared
rg -nF 'TextStyle(' lib/features
```

Hits outside the palette files are the defect.
