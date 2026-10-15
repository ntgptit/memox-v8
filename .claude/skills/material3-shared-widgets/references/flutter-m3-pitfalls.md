# Flutter M3 pitfalls (SDK 3.47.5)

Each entry is a trap where the pinned SDK does something other than a reader
would assume. Every line below was read in the 3.47.5 source. Paths are
relative to `/root/.flutter-sdk/3.47.5/flutter/packages/flutter/lib/src/`
unless they start with `flutter_test/`. If `.fvmrc` moves the pin, read each
cited line again before relying on it: the facts are the pin's, not Flutter's.

Project values (what the app chose) are in the ledger, not here.

### 1. AppBar background: a plain `Color` wins both states

**SDK evidence**
- `material/app_bar.dart:875`..`:883` `_resolveColor` returns `WidgetStateProperty.resolveAs(widgetColor)`, else the theme colour, else the default.
- `material/app_bar.dart:928` and `:935` call it once for the normal state and once for the scrolled-under state; `:942` picks one by `WidgetState.scrolledUnder`.
- `widgets/widget_state.dart:848`..`:853` `resolveAs` returns a non-property value unchanged, whatever the states.
- The scrolled-under fallback `colorScheme.surfaceContainer` is only the last argument (`material/app_bar.dart:939`). The M3 default normal colour is `surface` (`material/app_bar.dart:2536`).

**Consequence** An `AppBarTheme` or `AppBar` with a plain `backgroundColor` paints the same colour scrolled and unscrolled. The scrolled-under step silently disappears, and no analyzer or theme-field test notices.

**Do**
- Give the theme a `WidgetStateColor` for `backgroundColor` if the scrolled-under step is wanted.
- Prove it by scrolling a real `Scaffold` under the production theme and reading the painted colour.
- Lint: `M3L08` (planned; ledger DSD-34).

### 2. AppBar action icons: precedence and `foregroundColor`

**SDK evidence**
- `material/app_bar.dart:964`..`:970` the actions icon theme is, in order: `AppBar.actionsIconTheme`, `AppBarTheme.actionsIconTheme`, `AppBar.iconTheme`, `AppBarTheme.iconTheme`, then `defaults.actionsIconTheme` copied with `actionForegroundColor`, then the overall icon theme (`material/app_bar.dart:958`).
- `material/app_bar.dart:963` `actionForegroundColor` is `AppBar.foregroundColor ?? AppBarTheme.foregroundColor`, or null.
- `material/app_bar.dart:2554`..`:2557` the M3 default `actionsIconTheme` colour is `onSurfaceVariant`; `:2548`..`:2551` the leading `iconTheme` is `onSurface`.

**Consequence**
- A theme `foregroundColor` recolours the M3 default action icons too, so actions stop being `onSurfaceVariant`.
- A theme `iconTheme` set without `actionsIconTheme` also recolours the actions (it ranks above the default).

**Do**
- Set `actionsIconTheme` whenever a theme sets `iconTheme` or `foregroundColor` (`M3L07`, planned).
- Test both slots (leading and actions) against the rendered `IconTheme`, not the theme object.

### 3. `ColorScheme.surfaceTint` falls back to `primary`

**SDK evidence**
- `material/color_scheme.dart:1338` `Color get surfaceTint => _surfaceTint ?? primary;`.
- `material/color_scheme.dart:456` (inside `ColorScheme.fromSeed`, `:309`): the seeded scheme sets it to the primary tone.

**Consequence** A hand-written scheme that omits `surfaceTint` gets `primary` as its tint, so any elevated surface that still applies a tint shifts toward the brand colour without any line in the theme saying so.

**Do**
- Declare `surfaceTint` explicitly in the scheme and assert it through the production theme.
- The value is the project's, not the spec's: ledger M3C-11 (CONFLICT, `KEEP_EXISTING`). Never assert `transparent` there.

### 4. Dialog and sheet barriers: three different fallbacks

**SDK evidence**
- `material/dialog.dart:1655`..`:1659` `showDialog` resolves `barrierColor` argument, then `DialogTheme.of(context).barrierColor`, then `Theme.of(context).dialogTheme.barrierColor`, then `Colors.black54`.
- `material/dialog.dart:1825` `DialogRoute` constructed directly defaults `barrierColor = Colors.black54` and reads no theme.
- `material/bottom_sheet.dart:1331` `showModalBottomSheet` passes `barrierColor ?? bottomSheetTheme.modalBarrierColor`; `:1109` `ModalBottomSheetRoute.barrierColor` is `modalBarrierColor ?? Colors.black54`, so a direct route reads no theme.

**Consequence**
- With no theme barrier, every dialog and sheet gets the guessed `black54`.
- An explicit `barrierColor` argument on the standard helpers wins over the theme, so it overrides the app's one approved scrim.
- A direct `DialogRoute` or `ModalBottomSheetRoute` skips the theme entirely.

**Do**
- Set the barrier in the dialog and sheet themes only; pass no `barrierColor` to the standard helpers (`M3L04`, planned).
- Prove the barrier on the pushed route: `ModalRoute.barrierColor` (the production-root overlay barrier test, Task 4, planned).

### 5. `showGeneralDialog` and `RawDialogRoute` take no theme barrier

**SDK evidence**
- `widgets/routes.dart:2760`..`:2765` `showGeneralDialog` has `Color barrierColor = const Color(0x80000000)`: a constant default, no theme lookup.
- `widgets/routes.dart:2598` `RawDialogRoute` defaults `barrierColor = const Color(0x80000000)`; `:2626` returns it as given.
- `widgets/dialog.dart:69` `showRawDialog` exists in 3.47.5 and builds routes through `routeBuilder`, so it needs the same ban as the others.

**Consequence**
- Any custom overlay built on these starts from `0x80000000` (alpha 128), which is neither `black54` nor the approved scrim.
- A wrapper that does not read the theme and pass it on is a bypass.

**Do**
- A wrapper around `showGeneralDialog` must read the dialog theme's barrier and pass it (the repo has exactly one such wrapper: ledger DSD-35).
- Everything else uses the wrapper. Lint: `M3L01` (planned), which lists `showRawDialog`.

### 6. The Drawer scrim is not a route barrier

**SDK evidence**
- `material/drawer.dart:693`..`:694` the scrim colour is `widget.scrimColor ?? DrawerTheme.of(context).scrimColor ?? Colors.black54`.
- `material/drawer.dart:698` it is painted by a `ColoredBox` inside `DrawerControllerState` (`:479`), faded by `alpha * _controller.value` (`:695`..`:697`).
- `material/scaffold.dart:2949` and `:2976` `Scaffold.drawerScrimColor` is passed to `DrawerController.scrimColor`, which wins over the theme.
- The class is `DrawerControllerState` (public). The older name `_DrawerControllerState` does not exist in 3.47.5.

**Consequence**
- A route-barrier test does not see a Drawer scrim. `ModalRoute.barrierColor` is not involved.
- A `Scaffold.drawerScrimColor` silently overrides `DrawerThemeData.scrimColor`.

**Do**
- Set the scrim in `DrawerThemeData`; ban `drawerScrimColor` (`M3L03`, planned).
- Test the Drawer by reading the painted `ColoredBox` colour while open, not by a route probe.
- This project has no Drawer today (ledger DSD-02); the rule is a fence.

### 7. `showAdaptiveDialog` and `.adaptive` constructors follow `ThemeData.platform`

**SDK evidence**
- `material/dialog.dart:1707`..`:1760` `showAdaptiveDialog` switches on `theme.platform` at `:1722`. On iOS and macOS it calls `showCupertinoDialog` (`:1743`) without passing `barrierColor` (documented ignored at `:1705`).
- `material/switch.dart:593`..`:597` (adaptation applied) and `:1891`..`:1907` (`_SwitchThemeAdaptation`): `Switch.adaptive` reads `Theme.of(context).platform` (also `:625`); on iOS and macOS the adaptation returns a bare `SwitchThemeData()` (`:1902`..`:1904`), so the app's switch theme is dropped.
- `material/slider.dart:814`..`:827` `Slider.adaptive` builds `CupertinoSlider` on iOS and macOS.
- `.adaptive` constructors also exist on `Checkbox` (`checkbox.dart:123`), `Radio` (`radio.dart:144`) and `CircularProgressIndicator` (`progress_indicator.dart:901`).

**Consequence**
- On iOS and macOS the app's barrier, switch theme and slider colours are bypassed with no analyzer signal.
- The `ThemeData(platform:)` argument is the other half: it switches every adaptive widget at once.

**Do**
- Ban `showAdaptiveDialog`, Cupertino modals and `.adaptive` constructors statically (`M3L02`), and `ThemeData(platform:)` (`M3L05`) (both planned).
- iOS runtime lanes are NOT_APPLICABLE here (ledger DSD-39).

### 8. SearchBar and SearchView default to elevation 6

**SDK evidence**
- `material/search_anchor.dart:1862`..`:1863` `_SearchBarDefaultsM3.elevation` is `6.0`; `:1866`..`:1867` `shadowColor` is `colorScheme.shadow`.
- `material/search_anchor.dart:1939` `_SearchViewDefaultsM3.elevation` is `6.0`. The `SearchAnchor` doc says the same at `:267` (`viewElevation`).
- `material/search_anchor.dart:1167` the bar inside an open view is forced to elevation 0 (the bar built at `:1148`).

**Consequence**
- A `SearchBarThemeData` that sets only colours leaves a 6 dp raised bar with a shadow.
- `SearchViewThemeData` is a separate theme, so a flat search bar does not make the expanded view flat.

**Do**
- Set `elevation` and `shadowColor` in `SearchBarThemeData`, and `elevation` in `SearchViewThemeData` when `SearchAnchor` is used.
- Read the project's current position in ledger DSD-30 and DSD-36 (no `SearchBar` or `SearchAnchor` is used today).

### 9. `ListTile.textColor` is shared, and `selectedTileColor` ignores `enabled`

**SDK evidence**
- `material/list_tile.dart:878` `effectiveColor` is one value, used for the title (`:922`), the subtitle (`:938`) and leading and trailing text (`:906`).
- `material/list_tile.dart:1218`..`:1228` `_IndividualOverrides.resolve`: a plain `Color` `textColor` returns `disabledColor` when disabled. The three overrides at `:878`..`:883` pass none, so a disabled tile falls through to `theme.disabledColor` (`:884`..`:889`).
- `material/list_tile.dart:826`..`:830` `effectiveTileColor` depends on `selected` only. `enabled` is not consulted. It is painted at `:1002`.

**Consequence**
- A subtitle cannot be given a different colour from the title through `textColor`; a disabled tile ignores a plain `textColor` and dims everything to the framework disabled colour.
- A disabled and selected tile still paints `selectedTileColor`.

**Do**
- Use `subtitleTextStyle` for a separate subtitle colour, or a wrapper that owns each slot.
- Test disabled, selected and disabled+selected rows by rendering them.
- Project position: ledger DSD-29 and M3C-10 (`ListTile` is banned in features; `MxListRow` is the wrapper).

### 10. The modal bottom sheet default elevation is 1

**SDK evidence**
- `material/bottom_sheet.dart:1486`..`:1487` `_BottomSheetDefaultsM3` has `elevation: 1.0` and `modalElevation: 1.0`.
- `material/bottom_sheet.dart:1150`..`:1154` a modal sheet resolves `elevation ?? sheetTheme.modalElevation ?? sheetTheme.elevation ?? defaults.modalElevation`.
- `material/bottom_sheet.dart:1496`..`:1502` the M3 default background is `surfaceContainerLow`; `surfaceTintColor` (`:1499`) and `shadowColor` (`:1502`) are transparent.

**Consequence**
- A theme that sets neither `modalElevation` nor `elevation` yields a level-1 sheet. A spec that wants level 0 must set it explicitly.
- Setting only `elevation` also sets the modal value (the chain falls through to it).

**Do**
- Set elevation in `BottomSheetThemeData` and assert the effective `Material.elevation` of the pushed sheet.
- Project position: ledger M3C-18 (`KEEP_EXISTING`).

### 11. `InputDecorator` disabled border differs by variant; error+hover differs from error

**SDK evidence**
- `material/input_decorator.dart:5974` filled (`activeIndicatorBorder`) disabled: `onSurface` at 0.38.
- `material/input_decorator.dart:5997` outlined (`outlineBorder`) disabled: `onSurface` at 0.12.
- `material/input_decorator.dart:5981` and `:6004`: error plus hovered is `onErrorContainer`, error plus focused is `error` at width 2, plain error is `error`.
- `material/input_decorator.dart:5958` hint disabled is `onSurface` at 0.38.

**Consequence**
- A test or token that assumes one disabled alpha for both variants is wrong for one of them.
- A theme that overrides `border` with a single colour loses the hover-in-error step.

**Do**
- Assert each variant's disabled border separately, and the error+hover state if the theme keeps the framework border.
- Project position: ledger DSD-31 and DSD-38.

### 12. `LinearProgressIndicator`: track colour and the `year2023` flag

**SDK evidence**
- `material/progress_indicator.dart:595` `year2023 = widget.year2023 ?? indicatorTheme.year2023 ?? true`. In 3.47.5 the default is `true` (the flag is deprecated: `:511`..`:516`).
- `material/progress_indicator.dart:1565` (`..Year2023` defaults) and `:1621` (new defaults): `linearTrackColor` is `secondaryContainer` in both. Height is 4 in both (`:1568`, `:1624`).
- `material/progress_indicator.dart:609`..`:621` the stop indicator, its radius and the track gap apply only when `year2023` is false; `:1626`..`:1636` the new defaults add radius, stop indicator and a 4 dp gap.

**Consequence**
- A spec that "inherits the SDK track" gets `secondaryContainer`, whichever flag is chosen.
- The visual difference between the flag values is the stop dot, the gap and the rounded track, not the track colour.

**Do**
- Choose `year2023` explicitly in the theme if the component is used, and record the choice in the ledger first (DSD-23).
- Project position: ledger M3C-27 (the app draws its own track).

### 13. `tester.view.viewInsets` takes physical pixels

**SDK evidence**
- `flutter_test/lib/src/window.dart:1205`..`:1210` `TestFlutterView.viewInsets` is a `FakeViewPadding`, a `ViewPadding`, i.e. physical pixels.
- `widgets/media_query.dart:309` `MediaQueryData.viewInsets` is `EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio)`: logical = physical / `devicePixelRatio`.
- The repo harness pins `tester.view.devicePixelRatio = 1` (`widget_harness.dart:10` in `test/support/`), where the two coincide.

**Consequence** At any other pixel ratio a keyboard of `FakeViewPadding(bottom: 300)` is 300 / dpr logical pixels, and a test sized in logical pixels checks the wrong thing. Setting `MediaQueryData(viewInsets:)` instead is logical and skips this path.

**Do**
- Set `devicePixelRatio` explicitly in the same test, or convert (`logical * dpr`) when writing `FakeViewPadding`.
- Always `addTearDown(tester.view.reset)`.

### 14. `textContrastGuideline` is a sampler with a size rule

**SDK evidence**
- `flutter_test/lib/src/accessibility.dart:498`..`:505` the target is 3.0 when the font size is at least 18 (`:292`, `kLargeTextMinimumSize`), or bold and at least 14 (`:298`); else 4.5. A missing size counts as 12 (`:310`).
- `flutter_test/lib/src/accessibility.dart:433` and `:436` "bold" is `fontWeight == FontWeight.bold` exactly, so `w600` is not bold.
- `flutter_test/lib/src/accessibility.dart:461`..`:463` the ratio is measured from sampled pixels, with a `-0.01` tolerance (`:312`). The constant's doc (`:806`..`:817`) calls the partition "very naive".

**Consequence**
- Anti-aliased small text and text on filled buttons can fail it for a pair that the token maths passes, and a 20 px title of any weight is held to 3:1, not 4.5:1.
- It is not a proof of a token pair's contrast.

**Do**
- Treat it as supplementary and non-gating in this project (ledger M3C-30, owner FE-C1 2026-09-28): run it for observation, never as a required check. The gate is `test/core/theme/token_contrast_test.dart`.
- Large-text allowance at 3:1 is the project's WCAG 2.2 AA reading (ledger M3C-13).
