# Legacy removal

What the ForUI migration removed, renamed or replaced, and what keeps each from
coming back. Paths are relative to the repository root; the baseline is
`a4f56ce2`.

## Removed

| Removed | Replaced by | Kept out by |
|---|---|---|
| `lib/core/theme/generated/` (`color_schemes`, `mx_colors_extension`, `app_dimens`, `text_theme`, `token_constants` `.g.dart`) | `app_palette.dart`, `mx_status_colors.dart`, `app_dimens.dart`, `app_typography.dart` | `removed_symbols.json` (`files`), `check.py` closed file list, `check_generated.py` (no committed `*.g.dart`), `.gitignore` exception removed |
| `lib/core/theme/app_component_themes.dart`, `app_surface_themes.dart` | ForUI component styles, restyled by deltas in the `Mx*` widgets | `removed_symbols.json`, `check.py` |
| `lib/core/theme/focus_ring_border.dart` (`MxFocusRingBorder`) | ForUI's focused outline (`FFocusedOutline`) | `removed_symbols.json` |
| `design/tokens.json`, `design/app_tokens.json`, `design/contrast_exceptions.json` | Dart values in `lib/core/theme/`; contrast test with no exception list | `removed_symbols.json` (`files`), hook |
| `tools/design/generate.py`, `codemod.py`, `fix_const.py` and their tests | `tools/design/design_doc.dart` + `test/tools/design_doc_test.dart` (docs rendered from the theme) | `removed_symbols.json` (`files`) |
| `test/app/m3_production_theme_test.dart`, `test/app/m3_overlay_barrier_test.dart`, `test/support/approved_palette.dart` | `test/app/production_theme_test.dart` | `removed_symbols.json` (`files`) |
| `test/core/theme/app_component_themes_test.dart`, `app_surface_themes_test.dart`, `app_theme_ambient_test.dart`, `focus_ring_border_test.dart`, `input_decoration_theme_test.dart`, `theme_slot_fixes_test.dart`, `token_values_test.dart`, `token_source.dart` | `test/core/theme/app_theme_test.dart`, `token_contrast_test.dart`, `app_typography_test.dart`, `theme_context_test.dart` and the shared widget contract tests | their subjects no longer exist |
| `tools/m3_lint/` (rules M3L00..M3L08) | `tools/ui_lint/` (UIL00..UIL06); fixtures renamed, AppBar rules M3L07/M3L08 retired (no AppBar exists; UIL03 bans the import) | `removed_symbols.json` (`files`) |
| Skills `material3-shared-widgets`, `flutter-theme-design` | `forui-shared-widgets`; `flutter-design-system` rewritten for ForUI | skill registry test (`test_skills_without_v7.py`) |
| Guard rule `color_scheme_reads_are_m3_roles` | `colors_reads_are_forui_roles` (FColors allowlist) | guard |
| Guard rule `color_scheme_arguments_are_m3_roles` | `host_scheme_arguments_are_m3_roles` (only the SDK host `ColorScheme`) | guard |
| `buildMxSnackBar`, `MxSnackbarContent` | `showMxSnackbar` returning `MxSnackbarController` | `removed_symbols.json` |
| Chip helpers `chipPaint`, `chipDecoration`, `chipButtonStyle`, `chipStartInset`, `chipEndInset`, `chipGap` | `mxChipStyle`, `mxChipDecoration`, `mxChipLabelStyle`, `mxChipIconTheme`, `mxChipPadding`, `mxChipGap` | `removed_symbols.json` |
| `ThemeContext.mxColors`, `ThemeRules.accentColor`, `onAccentColor`, `deckIconColor` | `context.status`, `colors.primary`, `colors.primaryForeground`, `status.info` | `removed_symbols.json`; `check.py` checks the getter list |
| Material 3 roles read on `context.colors` (`onSurfaceVariant`, `surfaceContainer*`, `outlineVariant`, …) and Material text roles on `context.texts` (`titleSmall`, `bodyMedium`, …) | FColors roles and `MxTextRoles` | `removed_symbols.json` (regex entries), guard |
| `AppDimens` radius, stroke, opacity and component size fields | `context.radii`, `context.hairline`, `colors.disabledOpacity`, ForUI sizes | `removed_symbols.json` (regex entries) |
| Whole-library `package:flutter/material.dart` imports (290 files at baseline) | `show` lists of infrastructure names (17 files) | `tools/ui_lint` UIL03, guard `material_imported_by_name` |

No alias, typedef, re-export or forwarding getter was left for any removed name.

## Kept on purpose

| Kept | Why |
|---|---|
| `MaterialApp.router` | go_router builds Material pages under it; it hosts the SDK widgets below |
| `Scaffold` (in `MxAppShell` only) | Insets, FAB placement, keyboard handling |
| `RefreshIndicator`, `ReorderableListView`, `SelectableText`, `SelectionArea`, `MaterialPageRoute`, `MaterialLocalizations`, `TimeOfDay`, `Durations`, `Easing` | No ForUI counterpart; infrastructure, imported by name |
| `docs/shared/design/m3-adoption-ledger.md`, `m3-shared-widget-spec-v2.6.1.md`, `memox-design-tokens.md` | Historical record, marked as such at the top |
| `docs/superpowers/**` plans and specs naming the Material 3 system | History; the docs checker skips them |
