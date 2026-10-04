# Design tokens

Tokens are generated, never hand-written (spec 2026-10-04-sp3a A2, A3):

```
DESIGN.md frontmatter (every colour, light + `-dark`; typography; radii; spacing)
.impeccable/design.json extensions (contrast pairs, opacity, stroke, motion, breakpoints, shadows; no colour)
        │  python3 tools/design/generate.py --write
        ▼
lib/core/theme/foundations/   (generated, DO NOT EDIT; the gate fails when stale)
├── app_color_schemes.dart    # AppColorSchemes.light / .dark — the 45 Material 3 roles
├── app_semantic_colors.dart  # AppSemanticColors — ThemeExtension, light / dark
├── app_text_styles.dart      # AppTextStyles — DESIGN.md roles and the TextTheme mapping
├── app_spacing.dart          # AppSpacing.micro … pageEnd
├── app_radius.dart           # AppRadius.xs … full
├── app_stroke.dart           # AppStroke.hairline, control, focus, indicator
├── app_opacity.dart          # AppOpacity.disabled, muted, pressed, …
├── app_durations.dart        # AppDurations.toggle, standard, …
├── app_breakpoints.dart      # AppBreakpoints.navRail, contentMax
└── app_shadows.dart          # AppShadows.<name><Light|Dark>, built on the scheme's `shadow`
lib/core/theme/app_typography.dart  # AppTypography.withWeight — moves the variable font's axis
lib/core/theme/app_theme.dart       # AppTheme.light() / .dark()
```

To change a value, edit `DESIGN.md` (or the sidecar for a non-colour metadata
token), run `python3 tools/design/generate.py --write`, and commit both. A value
typed into a generated file is overwritten and fails the gate first.

## Colour roles

`ColorScheme` carries the 45 Material 3 roles; MemoX's semantic roles (success,
warning, the four statuses, streak) are `AppSemanticColors`, a `ThemeExtension`,
so they follow light and dark like the scheme does. A role is used on the ground
its contrast pair names; content on a coloured surface uses the role's `on-`
pair. There is no ink palette: a role that fails its floor is changed in
`DESIGN.md` (DESIGN.md, "The Role On Its Ground Rule").

## Typography

`AppTextStyles.textTheme` fills all 15 `TextTheme` slots from DESIGN.md's
`### Text theme` table. Widgets read a slot from the theme and never build a
`TextStyle`. A weight change goes through `AppTypography.withWeight`, because
on the variable font `fontWeight` alone reports one weight and paints another.

## Verifying tokens are actually used

The guard's design-token rules do this on every Dart file under
`lib/features/*/presentation/` and `lib/shared/`, and the PostToolUse hook runs
them on each edit. Hits in `lib/core/theme/` are expected: that is where values
are defined.
