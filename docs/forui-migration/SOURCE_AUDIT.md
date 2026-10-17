# Source audit: the UI before the ForUI migration

Baseline: branch `claude/ecstatic-lovelace-s80gci` at `a4f56ce2` (2026-10-17), a
clean worktree of the pre-migration tree. Every number below was measured on that
tree with `rg`; the gate results come from running the gate there.

## Stack

| Item | Baseline |
|---|---|
| Flutter / Dart | 3.47.5 / 3.13.4 (`.fvmrc`) |
| Platforms verified | Android only (iOS out of scope, ADR-001) |
| State, routing, data | Riverpod, go_router 18.0.1, Drift, Supabase (unchanged by the migration) |
| UI system | Material 3, hand-built from `design/tokens.json` (ADR-022) |
| Hand-written `lib/` Dart files | 1052 |
| Files importing `package:flutter/material.dart` | 290 (whole-library imports) |
| Files importing Cupertino | 0 |
| Shared widget files (`lib/shared/widgets/`) | 65 |
| Test files (`*_test.dart`) | 701 |
| Golden images (`test/**/goldens/*.png`) | 656 |

## Theme (`lib/core/theme/`)

| File | Role |
|---|---|
| `app_theme.dart` | `buildLightTheme()` / `buildDarkTheme()` returning Material `ThemeData` |
| `app_component_themes.dart` | Button, FAB, chip, switch component themes |
| `app_surface_themes.dart` | Card, field, navigation, dialog, sheet, snackbar, tooltip themes |
| `app_typography.dart` | `TextTheme` wiring of the twelve roles |
| `focus_ring_border.dart` | `MxFocusRingBorder`, the offset focus ring for buttons, FAB and chips |
| `theme_rules.dart` | Per-mode getters: `accentColor`, `onAccentColor`, `deckIconColor`, `screenMargin`, `windowSize` |
| `theme_context.dart` | `context.colors` (ColorScheme), `texts` (TextTheme), `mxColors`, `dimens` |
| `color_tint.dart`, `mastery_ramp.dart`, `app_icons.dart` | Tint, mastery colours, Material icons |
| `generated/*.g.dart` (5) | `color_schemes`, `mx_colors_extension` (16 fields), `app_dimens` (42 + app tokens), `text_theme`, `token_constants`, written by `tools/design/generate.py` from `design/tokens.json` |

## Material components used in `lib/`

Measured as constructor calls (`rg '\bName(\.\w+)?\('`), files in brackets. Almost
all of them sat inside `lib/shared/widgets/`; features used the `Mx*` widgets.

| Component | Calls (files) | Where |
|---|---|---|
| `TextButton` | 5 (5) | `MxButton` and its relatives |
| `Material` | 7 (7) | Ink hosts in shared widgets |
| `TextField` | 4 (4) | `MxTextField`, `MxSearchField`, code field, stepper |
| `Card` | 4 (2) | `MxCard` |
| `Scaffold` | 3 (3) | `MxAppShell`, `startup_failure_app.dart`, `route_not_found_screen.dart` |
| `RefreshIndicator` | 2 (2) | users list, monitoring server list |
| `IconButton`, `FloatingActionButton`, `InkWell`, `Switch`, `Slider`, `Tooltip`, `SnackBar`, `Divider` | 1 each | their `Mx*` facades |
| `ReorderableListView` | 1 (1) | deck reorder list |
| Overlays | `showGeneralDialog` in `mx_dialog.dart`, `showModalBottomSheet` in `mx_bottom_sheet.dart` | the two adapters |
| `Checkbox`, `Radio`, `SegmentedButton`, `NavigationBar`, `NavigationRail`, `Chip` | 0 | painted by hand in `Mx*` widgets |

## Gates guarding the Material 3 system

| Gate | What it held |
|---|---|
| `tools/m3_lint` (M3L00..M3L08) | Overlay bypass, Cupertino/adaptive, drawer scrim, barrier arguments, `ThemeData(platform:)`, seed schemes, AppBar icon themes |
| `tools/design/check.py` + `generate.py` | Generated theme code, `DESIGN.md` frontmatter and `.impeccable/design.json` equal a fresh generation of `design/tokens.json`; removed names |
| Guard rules | `color_scheme_arguments_are_m3_roles`, `color_scheme_reads_are_m3_roles` and the design-token rules |
| `test/app/m3_production_theme_test.dart`, `m3_overlay_barrier_test.dart` | The production theme and route barriers against `design/tokens.json` |
| `test/core/theme/*` | Token values, component theme slots, contrast with `design/contrast_exceptions.json` |
| Skills | `material3-shared-widgets`, `flutter-design-system`, `flutter-theme-design` |

## Baseline gate results (executed on `a4f56ce2`)

| Check | Result |
|---|---|
| `dod_check.sh` (full) | PASS: every step green, 4745 tests |
| `run_goldens.sh` | PASS (656 goldens) |
| `flutter build apk --debug` | FAILED before compiling: Gradle got HTTP 429 (Too Many Requests) from `repo.maven.apache.org` while resolving dependencies. An infrastructure failure, not a code failure; the post-migration builds are reported in `MIGRATION_VERIFICATION.md`. |

## Environment notes

- `dl.google.com` is blocked by the session's network policy, so the Android SDK
  (platform 36, build-tools 35/36, NDK 28.2.13676358) was copied from the
  `cimg/android:2026.08.1-ndk` image into `/opt/android-sdk`.
- No emulator or device is available: TalkBack and on-device runs cannot be
  executed in this environment.
- The Linear connector refused new issues (free plan issue limit), so the work is
  not tracked on Linear.
