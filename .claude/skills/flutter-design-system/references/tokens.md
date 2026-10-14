# Design tokens

**The values are not written here.** The single source is `design/tokens.json`,
exported from the Design System "Flashcard Color Tokens". Everything under
`lib/core/theme/generated/` and the `DESIGN.md` frontmatter are generated from it
(`python3 tools/design/generate.py`); how to change the look is
`docs/agent/visual-change.md`
([ADR-022](../../../../docs/shared/decisions/ADR-022-mot-nguon-token-va-theme-flutter.md)).
Never copy a hex, a size or a duration into code, a test or a document.

## Where things live

```
design/tokens.json                    # the source (never hand-edited)
design/app_tokens.json                # values the app has and the DS does not
lib/core/theme/
├── generated/                        # written by tools/design/generate.py
│   ├── color_schemes.g.dart          #   const ColorScheme light / dark (46 roles)
│   ├── mx_colors_extension.g.dart    #   MxColorsExtension (16 fields)
│   ├── app_dimens.g.dart             #   AppDimens (spacing, shape, size, stroke, opacity)
│   ├── text_theme.g.dart             #   the 12 TextTheme roles
│   └── token_constants.g.dart        #   constants needed outside a BuildContext
├── app_theme.dart                    # buildLightTheme() / buildDarkTheme()
├── app_component_themes.dart         # component themes, tokens only
├── app_typography.dart               # binds the roles, mono family
├── color_tint.dart                   # Color.tintOver
├── theme_rules.dart                  # accentColor, deckIconColor, screenMargin, windowSize
├── theme_context.dart                # colors, texts, mxColors, dimens
├── mastery_ramp.dart
├── focus_ring_border.dart            # MxFocusRingBorder: the offset focus ring around any OutlinedBorder
└── app_icons.dart
```

Nothing else belongs in `lib/core/theme/`; the guard keeps the list closed.

## Reading the theme

```dart
extension ThemeContext on BuildContext {
  ColorScheme get colors;        // Theme.of(this).colorScheme
  TextTheme get texts;           // Theme.of(this).textTheme
  MxColorsExtension get mxColors;
  AppDimens get dimens;
}
```

That is the whole extension. The Design System rules of the form "this mode uses
role A, that mode role B" are `accentColor` and `deckIconColor`, plus
`screenMargin` and `windowSize`, in `theme_rules.dart`: the only widget-facing
file that branches on `brightness`.

- **Colour:** a `ColorScheme` role when one exists. `MxColorsExtension` holds only
  the DS tokens that have no role: `success`, `warning`, `info` (each with `on…`,
  `…Container`, `on…Container`), `cardSurface`, `searchSurface`, `tileSurface`,
  `divider`. A tinted ground is `colour.tintOver(base)` where `base` is the
  surface right beneath (`colors.surface` on the page, `mxColors.cardSurface`
  inside a card); never `withValues(alpha:)` or `Color.lerp` for a ground.
- **Text:** the role itself, `context.texts.titleSmall`, changing only the
  colour, `copyWith(color: …)`, or for code `copyWith(fontFamily:
  AppTypography.monoFamily)`. Size, weight, tracking and height are the token's.
  A single-line label cut with an ellipsis needs a line height of at least 1.5, or
  stacked Vietnamese diacritics (Ẳ, Ổ, Ỗ) are clipped; the height stays what the
  token says, and a screen that clips is reported, not patched.
- **Dimensions:** `context.dimens.space16`, `radiusMd`, `sizeControl`,
  `strokeHairline`, `opacityPressed`… A full radius is `StadiumBorder()`. Motion is
  Flutter's own: `Durations.short4`, `Easing.standard`.
- **A value one widget needs and the DS lacks:** a private constant in that widget
  with a doc comment. One several widgets need goes into `design/app_tokens.json`.

## Component themes

A Material widget's defaults are set once in `app_component_themes.dart` from
tokens (card, search bar, divider, buttons, navigation bar and rail, progress,
chip, input, dialog, sheet, snack bar, tooltip). An `Mx*` widget composes layout
and reads those; it does not rebuild the colour, text or radius the theme has.

## Verifying tokens are actually used

```bash
python3 tools/design/check.py          # generated code in sync, no removed name left
grep -rnE 'Colors\.[a-z]|Color\(0x' lib/features lib/shared
grep -rn 'TextStyle(' lib/features
```

Hits in `lib/core/theme/` are expected; anywhere else they are the defect.
