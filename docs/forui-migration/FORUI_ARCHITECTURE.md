# ForUI architecture

The decision is [ADR-025](../shared/decisions/ADR-025-forui-la-he-component-giao-dien.md).
This page is how it is built and what keeps it that way.

## Layers

```
features (lib/features/**)      Mx* widgets only; no package:forui
        │
Mx* facades (lib/shared/widgets) ForUI components + app contracts
        │                        (48dp targets, held popups, callbacks, semantics)
        │
ForUI 0.27.6 (package:forui)     components, states, focus, overlays
        │
theme (lib/core/theme)           FThemeData: palette, type scale, dimens
        │
host (lib/app/app_theme_host.dart, MaterialApp.router)   infrastructure only
```

## Theme

| Piece | File | Notes |
|---|---|---|
| Palette | `lib/core/theme/app_palette.dart` | `appLightColors`, `appDarkColors` (`FColors`). ForUI neutral base; `primary` is MemoX indigo; `mutedForeground` and light `error`/`destructive` adjusted for contrast (reasons in the file). |
| Status colours | `lib/core/theme/mx_status_colors.dart` | `MxStatusColors` (`success`, `warning`, `info` and their fills), an `FColors` extension. |
| Type | `lib/core/theme/app_typography.dart` | `AppTypography.build(colors)` → `FTypography` (Be Vietnam Pro, Noto Sans KR fallback); `MxTextRoles`, the twelve roles. |
| Dimens | `lib/core/theme/app_dimens.dart` | `AppDimens`, spacing, margins and layout sizes; an `FThemeData` extension. Radii and border width are ForUI's (`context.radii`, `context.hairline`). |
| Theme | `lib/core/theme/app_theme.dart` | `buildLightTheme()`, `buildDarkTheme()`, `themeFor(brightness)`; `materialHostTheme(theme)` for the SDK host, derived from `FColors` and the ForUI type scale. |
| Access | `lib/core/theme/theme_context.dart` | `context.colors`, `texts`, `status`, `dimens`, `radii`, `hairline`; a missing theme throws a `StateError` that names the builders. |

The palette is the only Dart that writes a colour value (`tools/design/check.py`).
`DESIGN.md`'s frontmatter and `.impeccable/design.json` are rendered from the two
production themes by `tools/design/design_doc.dart`; `test/tools/design_doc_test.dart`
fails when the committed files differ. The contrast floor (4.5:1 text, 3:1
non-text) is `test/core/theme/token_contrast_test.dart`, over every palette pair,
with no exception list.

## Theme scope and mode

`MaterialApp.router` stays: go_router builds its pages as Material pages when it
finds a `MaterialApp`, and the SDK widgets kept as infrastructure need a Material
ancestor. Its `theme`/`darkTheme` are `materialHostTheme(...)`, and its `builder`
puts `AppThemeHost` above the Navigator:

```
MaterialApp.router(theme, darkTheme, themeMode, builder: …)
  └─ AppThemeHost(brightness: resolveBrightness(context, themeMode))
       └─ FTheme(data: themeFor(brightness))
            └─ material_ui Theme(data: theme.toApproximateMaterialTheme())
                 └─ Navigator (routes, dialogs, sheets; toasts in its overlay)
```

Every route and overlay pushed on the root navigator is a descendant of the
`FTheme`, so dialogs, sheets and toasts read the same theme as the page
(`test/app/production_theme_test.dart`). Light, Dark and System change
`themeMode` only; `resolveBrightness` follows the platform brightness for System.
The router is not rebuilt (`production_theme_test.dart`: "switching the theme keeps
the route and its stack").

## The Material bridge (one way)

Material stays only where ForUI has no counterpart or the SDK needs it. Each name
is imported through a `show` list and checked by `tools/ui_lint` UIL03:

| Name | Where | Why |
|---|---|---|
| `MaterialApp`, `ThemeMode` | `lib/app/` | App host, go_router page transitions |
| `Scaffold`, `ScaffoldPrelayoutGeometry`, `FloatingActionButtonLocation` | `mx_app_shell.dart` | Insets, FAB placement, keyboard handling |
| `MaterialPageRoute` | account transition layer | A page route in a nested Navigator |
| `RefreshIndicator` | users list, monitoring server list | Pull to refresh, none in ForUI |
| `ReorderableListView` | deck reorder list | Drag to reorder, none in ForUI |
| `SelectableText`, `SelectionArea` | monitoring code card | Text selection |
| `MaterialLocalizations`, `TimeOfDay` | reminder and settings sections | Localised time formatting |
| `Durations`, `Easing` | motion in shared and study widgets | The motion scale |
| `ThemeExtension`, `InputBorder`, `OutlineInputBorder` (`material_ui`) | theme, text fields | Types ForUI's own API takes |

The bridge runs one way: the host theme is computed from the ForUI theme, never the
reverse, and nothing in `lib/` reads `Theme.of(context)` for a colour.

## Overlays

| Adapter | Route | Barrier | Held behaviour |
|---|---|---|---|
| `showMxDialog` / `MxDialog` | `FDialogRoute` subclass with `MxHeldRoute` | `FColors.barrier` | A held popup ignores barrier taps and Back |
| `showMxBottomSheet` / `MxBottomSheet` | `FModalSheetRoute` subclass with `MxHeldRoute` | `FColors.barrier` | Also absorbs the drag |
| `showMxSnackbar` | ForUI's `FToast` in the root overlay (not ForUI's toaster, whose tap-to-pause lands on the screen's root semantics node unlabelled) | none | Returns `MxSnackbarController`; one toast at a time; a live region; swipe down dismisses; stays while TalkBack is on and it has an action |

## Targets and accessibility

- Every interactive control has a 48dp target. ForUI controls painted smaller
  (chips, stepper steps, checkbox, radio) paint inside the target through
  `mxInsetDecoration` / `MxInsetShapeBorder`.
- `MxTooltip` merges ForUI's tooltip long press into the control's labelled
  semantics node (`labeledTapTargetGuideline`).
- The Android tap-target and labelled-target guidelines run on each tab
  (`production_theme_test.dart`) and per screen (`test/visual_audit/`).

## UI lint rules (`tools/ui_lint`)

Resolved with the analyzer: a symbol counts by the library it comes from, so an
import alias or a local function of the same name changes nothing.

| Rule | Checks | Owner paths exempt |
|---|---|---|
| UIL00 | An allowlist entry that covers nothing, or whose review date passed | — |
| UIL01 | An overlay opened outside the adapters: Material and ForUI dialog/sheet/toast functions and routes, `ScaffoldMessenger.showSnackBar`, a class built on `ModalRoute`/`PopupRoute` | `mx_dialog.dart`, `mx_bottom_sheet.dart`, `mx_snackbar.dart`, `mx_held_route.dart` |
| UIL02 | Cupertino routes, controls and helpers; `.adaptive` constructors | — |
| UIL03 | A Material import without a `show` list, with a prefix, from `src/`, or showing a name outside the infrastructure list (or outside its path) | `app_theme.dart`, `app_theme_host.dart` |
| UIL04 | `barrierColor`, `modalBarrierColor`, `scrimColor`, `drawerScrimColor`, `surfaceTintColor` arguments | `lib/core/theme/` |
| UIL05 | Building `ThemeData`, `ColorScheme`, `TextTheme`, `Typography`, `FThemeData`, `FColors`, `FTypography`, `FTypeface`, `FStyle`; anywhere: seed schemes, `ThemeData(platform:)` | `lib/core/theme/` |
| UIL06 | `package:forui` imported | `lib/core/theme/`, `lib/shared/`, `lib/app/` |

`dart run tools/ui_lint/ui_lint.dart` lints `lib/` (the gate's `ui_lint` step);
its fixtures and tests are `tools/ui_lint/fixtures/` and `test/tools/ui_lint_test.dart`.

## Other gates

| Gate | Checks |
|---|---|
| `tools/design/check.py` | Closed theme file list, `ThemeContext` getters, colour values only in the palette files, no value in `DESIGN.md` prose or the sidecar narrative, no removed name (`tools/design/removed_symbols.json`) |
| `test/tools/design_doc_test.dart` | `DESIGN.md` frontmatter and `.impeccable/design.json` equal the rendering of the production themes |
| Guard (`memox-v8` ruleset) | `colors_reads_are_forui_roles`, `host_scheme_arguments_are_m3_roles`, `no_forui_in_features`, `material_imported_by_name`, and the design-token rules |
| Hooks | `block_removed_theme_symbols.py` refuses removed names and deleted theme paths at edit time |
