# Material Design 3 — Shared Widget Design & UI/UX Specification

> **Historical record (2026-10-17).** The app no longer uses Material 3 as its UI system: ForUI draws it ([ADR-025](../decisions/ADR-025-forui-la-he-component-giao-dien.md)). The rules, gates and files this document names (`tools/m3_lint`, the M3 theme files, `design/tokens.json`) were retired; their replacements are in `docs/forui-migration/FORUI_ARCHITECTURE.md`. Kept unedited below as the record of what the Material 3 system was.

**Version:** 2.6.1 (baseline review candidate)  
**Date:** 2026-10-15  
**Target:** Flutter mobile, Material 3 Standard baseline  
**Status:** **REVIEW CANDIDATE — NOT APPROVED**  
**Scope:** Project-agnostic baseline for a new Flutter mobile design system. No project-specific conflicts or previously approved palette/style assumptions are imported. For integration into an existing project, the real approved registry takes precedence. **Revision 2.6:** Closes iOS/Cupertino modal barrier bypasses, AppBar actions-icon precedence and `AppListItem` disabled-state implementation; repairs registry table and tightens SDK-conditional lint rules. **Revision 2.6.1:** closes the iOS bypass through adaptive Material constructors (`AlertDialog.adaptive`, `Switch.adaptive`, …), names `showCupertinoSheet`/`CupertinoSheetRoute`, defines `AppListItem` disabled+selected, and standardizes iOS simulation on `TargetPlatformVariant`. All decisions remain proposed until approved. See separate CHANGELOG.

## 0. Normative terms, source of truth, and approval gates

- **[SOURCE]**: Verified in Flutter source or official documentation; default behavior remains conditional on Flutter SDK version, component variant, and widget/theme overrides.
- **[DECISION]**: A precise, proposed application policy. Not a Google mandate or an already-approved project decision.
- **[GATE]**: A mechanically or manually testable acceptance criterion.
- **[CONFLICT]**: A proposed decision contradicts an approved existing decision; **do not apply** until resolved.
- **APPROVED > PROPOSED**. No agent may overwrite approved design-system decisions through interpretation of this document.
- **Pin Flutter SDK version and commit/source revision** before treating the `Default Flutter` column as implementation fact. Flutter master is a moving target. Record `flutter --version` and a lockfile or FVM version in the decision registry.
- Component mapping rows express **exactly one token per property per variant/state**. `none` and `transparent` are intentional literal semantic decisions, not unresolved alternatives.
- All numerical units are Flutter logical pixels unless specified as typographic `sp`. Token values in this document are **candidates**, not inherited project values.

### 0.1. Difference between a baseline and a final spec

This document freezes the **proposed mapping**; it cannot freeze actual brand colors because no approved 45-role light/dark HEX values were supplied. Therefore `DSD-02` remains `BLOCKED_BY_PALETTE_APPROVAL`. Never invent colors, silently generate a new palette, or assert the palette has been implemented. Similarly, the Flutter `Default` column must be reverified against the pinned SDK before implementation approval.


## 1. Design-token registry — fixed candidate values

### 1.1. Space scale

| Token | Value | Meaning |
|---|---:|---|
| `space.0` | 0 | Flush alignment |
| `space.1` | 4 | Micro gap |
| `space.2` | 8 | Tight relationship |
| `space.3` | 12 | Compact padding |
| `space.4` | 16 | Standard padding and phone gutter |
| `space.6` | 24 | Section separation |
| `space.8` | 32 | Large-area separation |
| `space.12` | 48 | Intentional whitespace |

**Do not use** 20dp or 40dp without first adding a named token through an approved change request. `space.6` means 24dp, not six logical pixels. The derived layout token `layout.bottomActionSafePadding` resolves to `MediaQuery.paddingOf(context).bottom + space.4` at the **single owner** of a persistent bottom-action footer; do not also wrap it in a second bottom `SafeArea`. This token is **not used** by the scroll-end form CTA in §6.5. Keyboard occlusion (`MediaQuery.viewInsetsOf(context).bottom`) is handled separately; never add `viewPadding.bottom` again.

### 1.2. Shape scale

| Token | Radius | Typical owner |
|---|---:|---|
| `shape.none` | 0 | Edge-to-edge canvas |
| `shape.extraSmall` | 4 | Input, tooltip, popup menu, floating Snackbar |
| `shape.small` | 8 | Chip |
| `shape.medium` | 12 | Standard card |
| `shape.large` | 16 | Featured card, standard FAB |
| `shape.extraLarge` | 28 | Dialog, top corners of modal sheet |
| `shape.full` | Stadium/circle | Buttons and round icon buttons |

**Rule:** same component + same variant -> same token. `shape.full` means a stadium/circle shape, **not** an arbitrary giant radius hardcoded in the widget.

### 1.3. Elevation and scrim registry

**[DECISION — proposed M3 elevation scale]** Elevation is a named property, not an uncontrolled Flutter default. Values are logical dp. Theme/wrapper implementations must map component variants to one of these tokens and verify **effective** state-resolved elevation in the pinned SDK. These candidates do not override approved border-first or other established systems.

| Token | Value (dp) | Usage |
|---|---:|---|
| `elevation.level0` | 0 | Flat containers, standard cards, inputs; enabled flat buttons (hover exceptions below) |
| `elevation.level1` | 1 | Elevated Card, ElevatedButton, NavigationDrawer |
| `elevation.level2` | 3 | NavigationBar, PopupMenu, **Top AppBar scrolledUnder** |
| `elevation.level3` | 6 | Dialog, standard FAB, floating Snackbar |
| `elevation.level4` | 8 | Default FAB hover state (`frameworkM3@SDK`); verify at SDK pin |
| `elevation.level5` | 12 | Reserved; no approved component owner in this baseline |

**[SOURCE vs decision]** Flutter API reports `NavigationBar` default 3, `NavigationDrawer` default 1, FloatingActionButton default 6, Snackbar default 6, and ElevatedButton default 1 in M3. For Card variants and Dialog/PopupMenu, inspect the **specific pinned M3-generated defaults**; class API descriptions can cite legacy fallback values, which do not necessarily identify the selected variant's default. In all cases the table below represents **target policy** even when the SDK requires an override. `D=Match (master)` records already-verified source; `D=Check` remains only on unselected variant/configuration choices, and every source match must be reverified when the SDK is pinned. For stateful buttons, **`frameworkM3@SDK` is the explicit policy token for hover/focus/pressed elevation** until DSD-23 pins the revision; it is not an uncontrolled default. Current master audit: `FilledButton.hovered = elevation.level1`, `ElevatedButton.hovered = elevation.level2`, `FAB.hovered = elevation.level4`. Verify the exact values and focus/pressed states under pinned SDK, and assert the effective Material elevation in widget tests. `elevation.level4` therefore has an owner; no `no owner` assertion is permitted.

**[DECISION] Opaque scrim + one approved alpha:** `colors.scrim = ColorScheme.scrim` (approved **opaque** base color; alpha 1.0) and `effects.scrimOpacity = BLOCKED_PENDING_PALETTE_APPROVAL` (range `0.0..1.0`). The derived, **single component-property token** is `effects.modalBarrierColor = colors.scrim.withValues(alpha: effects.scrimOpacity)`; construct it **exactly once** in the approved theme owner and use it as the route's final `barrierColor`. Never silently substitute `Colors.black54`, `withOpacity(0.54)`, or another guessed alpha. A distinct alpha for different overlay variants would require a separately named and approved token, not an ad-hoc exception. Non-modal components use `effects.scrimOpacity = notApplicable`.

**[GATE] Modal barrier ownership:** The `effects.modalBarrierColor` token is itself **BLOCKED** until its scrim and alpha operands are approved. Set `BottomSheetThemeData.modalBarrierColor`, `DialogThemeData.barrierColor` **and** `DrawerThemeData.scrimColor` from `effects.modalBarrierColor` when the palette is approved. Direct route-level `barrierColor` overrides are prohibited outside an audited, registered variant. `Drawer` is also **mandatory**, not a deferred inventory item: install the same token into `DrawerThemeData.scrimColor`. The Drawer scrim is drawn in `_DrawerControllerState` as an animated `ColoredBox`, **not a `ModalRoute.barrierColor`**; assert theme wiring and inspect the effective fully opened `ColoredBox.color`/rendered scrim. `showRawDialog`, `showGeneralDialog`, `RawDialogRoute`, direct `DialogRoute`/`ModalBottomSheetRoute`, custom `ModalRoute`, and nested navigators require an approved **Material** overlay adapter. **iOS/macOS Cupertino/adaptive modal APIs are prohibited in this baseline** (§1.3c): do not attempt to enforce the approved barrier by passing `barrierColor` to `showAdaptiveDialog`, because the Cupertino branch ignores it. The direct route constructors and general/raw dialog helpers do **not** inherit the ordinary dialog/bottom-sheet theme barrier by default; unregistered production use is prohibited. `Scaffold.drawerScrimColor` takes precedence over `DrawerThemeData.scrimColor` and must not be set outside the approved theme/screen adapter. The source-audited `showRawDialog` helper exists on master; keep it as `D=Check@pinnedSDK` in the inventory (do not compile that symbol when absent). Test **actual `ModalRoute.barrierColor`** for dialog/bottom-sheet routes and actual Drawer scrim color for drawers, then inspect overlay goldens for effective dimming (animated barriers interpolate from transparent on entry). **DSD-02 remains BLOCKED** until `effects.scrimOpacity` and the approved Light/Dark scrim values are supplied.

### 1.3a. Surface tint, scrolled AppBar, and shadows

| Token / state | Exact value | Owner | Flutter default / action |
|---|---|---|---|
| `effects.surfaceTint` | `colors.transparent` | Approved Light/Dark `ColorScheme.surfaceTint` | **[DECISION] explicit scheme value; not optional** |
| `appBar.normal.background` | `surface` | `AppBarThemeData.backgroundColor` state resolver | Match M3, state-aware theme required |
| `appBar.scrolledUnder.background` | `surfaceContainer` | Same state resolver | Match M3, **do not use a plain Color in backgroundColor** |
| `appBar.normal.elevation` | `elevation.level0` | `AppBarThemeData.elevation` | Match M3 0dp |
| `appBar.scrolledUnder.elevation` | `elevation.level2` | `AppBarThemeData.scrolledUnderElevation` | Match M3 3dp |
| `appBar.surfaceTintColor` | `colors.transparent` | Effective AppBar Material tint | Must assert rendered Material property |
| `appBar.shadowColor` | `colors.transparent` | AppBar theme/effective Material | Match M3-generated default; lock |
| `bottomSheet.surfaceTintColor` | `colors.transparent` | BottomSheet theme/effective Material | Match M3-generated default |
| `bottomSheet.shadowColor` | `colors.transparent` | BottomSheet theme/effective Material | Match M3-generated default |
| `searchBar.elevation` | `elevation.level0` | SearchBarThemeData.elevation | **D=Override** from source default 6dp |
| `searchBar.shadowColor` | `colors.transparent` | SearchBarThemeData.shadowColor | **D=Override** from source `shadow`, removes SearchBar default visible shadow |
| `searchView.elevation` | `elevation.level0` | SearchViewThemeData.elevation | **D=Override** from independently generated SearchView default 6dp |
| `searchView.surfaceTintColor` | `colors.transparent` | SearchViewThemeData.surfaceTintColor | D=Match; lock effective Material tint |
| `searchView.dividerColor` | `outline` | SearchViewThemeData.dividerColor | D=Match; lock (ambient DividerTheme can otherwise take precedence) |

`colors.transparent` is a foundation token (`Color(0x00000000)`), not one of the 45 roles. Flutter's `ColorScheme.surfaceTint` getter may otherwise **fallback to `primary`**. Flutter `AppBar` specifically falls back to `theme.colorScheme.surfaceTint`, rather than the M3-generated transparent default, when its theme/widget tint is unspecified. **[DECISION]** Both approved schemes **must explicitly declare `surfaceTint: colors.transparent`**; this is an independent 46th policy assertion, **not** part of the 45-role comparator. Other components that provide their own `surfaceTintColor` override must be checked through their effective Material properties and goldens; transparent at scheme level does not cancel a deliberate nontransparent component override.

Flutter-generated M3 AppBar defaults are 0dp normal/3dp scrolled-under, with normal `surface` and scrolled-under `surfaceContainer`. `AppBarThemeData.backgroundColor = scheme.surface` (plain `Color`) breaks that background transition because it wins both state resolutions. Apply one `WidgetStateColor.resolveWith` returning the exact token for each state. Test the **effective** `Material.color`, `Material.elevation`, `Material.surfaceTintColor`, and `Material.shadowColor` **before and after real scrolling**; theme-property assertions alone are not evidence of scrolled-under behavior. If a custom widget bypasses the normal `ScrollNotificationPredicate`, treat that as an implementation bug, not grounds to weaken the state contract.

**M3 bottom-sheet source differs from the baseline policy:** generated `elevation = modalElevation = 1dp` (`elevation.level1`), with transparent shadow/tint. **[DECISION]** This baseline retains `elevation.level0` for **modal bottom sheets** as a deliberate `D=Override` (must set `BottomSheetThemeData.modalElevation = elevation.level0` and cover any route-level elevation override). Non-modal bottom sheets have an **explicit `D=Check` / `frameworkM3@pinnedSDK` dependency** until given their own approved variant; do not silently implement or mark them approved through the modal variant. A numeric elevation assertion alone cannot prove a visible shadow: use both effective-property tests and golden differences where relevant.

### 1.3b. State-derived opacity tokens (source-aligned, candidate)

| Token | Expression | Use | Status |
|---|---|---|---|
| `effects.disabledFill` | `onSurface` with alpha `0.04` | Disabled filled-field background | D=Match; assert pinned SDK |
| `effects.disabledForeground` | `onSurface` with alpha `0.38` | Disabled input text/icon | D=Match; assert pinned SDK |
| `effects.disabledOutline` | `onSurface` with alpha `0.12` | **Disabled outlined-field boundary only** | D=Match; assert pinned SDK |
| `effects.scrimOpacity` | **UNRESOLVED** | Modal dialog, bottom sheet, drawer | **BLOCKED DSD-02** |

**[INPUT DISABLED]** The disabled **filled** underline uses `effects.disabledForeground` (`onSurface` @0.38), not `effects.disabledOutline` (@0.12). These are two distinct component slots with different effective border colors.

All alpha transformations are owned by the approved foundation/theme layer. Automated tests must check **effective composited contrast** for disabled states, not assume alpha alone proves legibility. An intentionally disabled control is exempt from the WCAG 1.4.3 text requirement, but its state must remain recognizable. The values are source-derived targets, not permission to hardcode random opacities elsewhere.
### 1.3c. Cross-platform modal contract (Cupertino/adaptive) — no unregistered exception

**[SOURCE]** `showAdaptiveDialog` routes to `showCupertinoDialog` on iOS/macOS and **ignores `barrierColor`**, `useSafeArea`, and `traversalEdgeBehavior` there. `showCupertinoDialog`/`CupertinoDialogRoute` use a Cupertino dynamic modal barrier when `barrierColor` is unspecified; `showCupertinoModalPopup` defaults to `kCupertinoModalBarrierColor`. These behaviors are not controlled by Material `DialogThemeData.barrierColor` or `effects.modalBarrierColor` automatically. An ordinary `showCupertinoDialog` may accept its own explicit barrier, but **that does not make `showAdaptiveDialog` safe**.

**[SOURCE] Adaptive Material constructors and Cupertino sheets:** `AlertDialog.adaptive`, `Switch.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `Slider.adaptive` and `CircularProgressIndicator.adaptive` select a Cupertino implementation from `Theme.of(context).platform` on iOS/macOS (for example `AlertDialog.adaptive` builds `CupertinoAlertDialog`). On iOS they therefore bypass the §3.2/§3.3 color, shape and typography contract **even when shown inside a Material `DialogRoute` with the approved barrier**; a route-barrier test alone cannot detect this. `showCupertinoSheet` creates a `CupertinoSheetRoute` (a `PageRoute` with a transparent barrier) that presents modal-style sheet content outside the Material bottom-sheet contract.

**[DECISION / scope]** This Flutter **Material 3 Standard** baseline uses **Material-owned dialogs and sheets on Android and iOS**. For application-authored production code **prohibit** calls to `showAdaptiveDialog`, `showCupertinoDialog`, `showCupertinoModalPopup`, direct `CupertinoDialogRoute`, `CupertinoModalPopupRoute`, `showCupertinoSheet`, `CupertinoSheetRoute`, other Cupertino-specific modal route helpers, **and the adaptive Material constructors `AlertDialog.adaptive`, `Switch.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`** outside a separately approved, platform-specific design contract. Shared widgets use the plain Material constructors (`AlertDialog`, `Switch`, `Checkbox`, …) on every platform. The baseline provides **no implicit Cupertino exception**. The existing audited Material adapter may use `showDialog`, `showModalBottomSheet` with installed Material theme barriers, or a guarded custom **Material** route with explicit `effects.modalBarrierColor`. A future Cupertino variant requires its own design decision, per-platform barrier policy, route test and AST allowlist; until then it must fail lint, including within the ordinary Material adapter. Do not forbid `CupertinoPageRoute` (standard page navigation) merely because it is Cupertino; this allowance does **not** cover `CupertinoSheetRoute`/`showCupertinoSheet`. Cupertino visual controls (`CupertinoSwitch`, `CupertinoAlertDialog`, `CupertinoSlider`, `CupertinoActivityIndicator`, …) render outside the §3 Material contract; inside shared widgets and baseline-governed screens they require the same separately approved variant. Icon glyph choice (e.g. `CupertinoIcons`) is governed by the icon-family decision in §5.2, not by this rule.

**[GATE]** Test the actual production Material overlay action under `TargetPlatform.android` and `TargetPlatform.iOS` with `testWidgets(..., variant: TargetPlatformVariant.only(...))`, which sets `debugDefaultTargetPlatformOverride` without touching production theme code. **Production `ThemeData` must not hardcode `platform`**; otherwise the variant cannot take effect, so assert `Theme.of(context).platform == TargetPlatform.iOS` inside the probe before trusting the run. Observe a **Material** route and `ModalRoute.barrierColor == effects.modalBarrierColor`; verify that the iOS branch cannot silently choose `CupertinoDialogRoute`. In the same iOS run, open each production dialog and shared-control screen and assert that `CupertinoAlertDialog`, `CupertinoSwitch`, `CupertinoCheckbox`, `CupertinoRadio`, `CupertinoSlider` and `CupertinoActivityIndicator` find **nothing** inside shared widgets (no adaptive substitution), and capture an iOS golden of dialog content. Analyzer **negative fixtures** must fail for every prohibited Cupertino/adaptive modal symbol listed above (including restoration builders and aliased imports), plus a positive fixture for an approved `showDialog` Material path on iOS. The iOS test may be skipped as not-applicable only if the product has explicitly excluded iOS (record it under DSD-32/39). **No value-based exception for `kCupertinoModalBarrierColor`.**

### 1.4. Sizing and typography tokens

| Token | Value | Meaning |
|---|---:|---|
| `size.touchTargetMin` | 48 | Minimum tappable width/height |
| `size.iconStandard` | 24 | Most icons |
| `size.iconCompact` | 20 | Compact action/supporting icon |
| `size.buttonVisualHeight` | 40 | Standard M3 button visible height (touch region separately >=48) |
| `size.iconButtonVisual` | 40 | Standard icon button visible extent |
| `size.textFieldMinHeight` | 56 | Single-line input baseline; height can grow |
| `size.listRowSingleMin` | 56 | One-line row lower bound |
| `size.listRowDoubleMin` | 72 | Two-line row lower bound |
| `size.listRowTripleMin` | 88 | Three-line row lower bound |
| `size.dialogMaxWidth` | 560 | Maximum width for regular dialog |
| `size.phoneGutter` | 16 | Phone compact horizontal margin |
| `size.tabDividerThickness` | 1 | TabBar divider stroke |
| `size.tooltipMinHeight` | 32 | Tooltip minimum height on mobile (via `BoxConstraints`) |
| `layout.listTile.start` | 16 | Flutter default ListTile leading inset; directional, semantic name |
| `layout.listTile.end` | 24 | Flutter default ListTile trailing inset; directional, semantic name |
| `layout.listTileDirectionalInsets` | `EdgeInsetsDirectional.only(start: layout.listTile.start, end: layout.listTile.end)` | **One composite token**; resolved using approved constants in production |
| `stroke.inputNormal` | 1 | TextField enabled/error/hover indicator or outline unless focused |
| `stroke.inputFocused` | 2 | TextField focused/error+focused indicator or outline |
| `size.sheetDragHandleWidth` | 32 | Default drag handle visible width, **not enabled in baseline** |
| `size.sheetDragHandleHeight` | 4 | Default drag handle visible height, **not enabled in baseline** |
| `size.sheetDragHandleTapTarget` | 48 | Drag handle semantic/tap area if an approved handle-enabled variant is introduced |

Use `ThemeData.textTheme` roles below for text instead of new font-size literals.

### 1.5. Motion tokens (custom components only)

| Motion | Duration token | Curve token |
|---|---|---|
| Selection indicator | `Durations.short3` (150ms) | `Easing.standard` |
| Small expansion | `Durations.medium1` (250ms) | `Easing.standard` |
| Custom overlay enter | `Durations.medium2` (300ms) | `Easing.standardDecelerate` |
| Custom overlay exit | `Durations.medium1` (250ms) | `Easing.standardAccelerate` |
| Built-in route/button/sheet motion | `frameworkDefault` | `frameworkDefault` |

Never replace native Flutter animations just to apply the table. Respect reduce-motion settings and tests.

## 2. Color architecture and role ownership

### 2.1. Scheme generation — one explicit decision

**[DECISION] `MANUAL_APPROVED_COLORSCHEME`**: two immutable, fully approved Light/Dark `ColorScheme` instances from a centralized palette declaration. Do **not** call `ColorScheme.fromSeed` at runtime. Seed generation is allowed only as an **offline proposal tool**, then export/review the chosen actual role values. Do not alter hues when switching between themes unless the approved palette explicitly says so. The document does **not** require `primary(light) != primary(dark)`; equal primary across themes is permissible if both pairings pass contrast. `effects.scrimOpacity` must be approved in the same palette review before modal barrier implementation. **[DECISION]** Each approved scheme must also explicitly set `surfaceTint: colors.transparent`, separate from the 45-role fixture; the scheme must provide an opaque `scrim` base color for one-pass alpha composition.

**[GATE]** every one of the 45 approved M3 role getters observed from `Theme.of(context).colorScheme` equals the independent role fixture, for both brightness modes; assert `brightness` separately and **always assert `surfaceTint == colors.transparent`** as the mandatory 46th policy check; static search fails any runtime `ColorScheme.fromSeed`, `colorSchemeSeed`, unapproved palette override, or `useSystemColors` that changes audited roles. If dynamic colors are later desired, register a separate approved mode with its own assertions and screenshots.

### 2.2. Role groups (45 M3 roles excluding obsolete compatibility fields)

- Primary 8: `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `primaryFixed`, `primaryFixedDim`, `onPrimaryFixed`, `onPrimaryFixedVariant`.
- Secondary 8: `secondary`, `onSecondary`, `secondaryContainer`, `onSecondaryContainer`, `secondaryFixed`, `secondaryFixedDim`, `onSecondaryFixed`, `onSecondaryFixedVariant`.
- Tertiary 8: `tertiary`, `onTertiary`, `tertiaryContainer`, `onTertiaryContainer`, `tertiaryFixed`, `tertiaryFixedDim`, `onTertiaryFixed`, `onTertiaryFixedVariant`.
- Error 4: `error`, `onError`, `errorContainer`, `onErrorContainer`.
- Surface/neutral 10: `surface`, `onSurface`, `surfaceDim`, `surfaceBright`, `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`, `onSurfaceVariant`.
- Utility 7: `outline`, `outlineVariant`, `shadow`, `scrim`, `inverseSurface`, `onInverseSurface`, `inversePrimary`.

45 total. `background`, `onBackground`, `surfaceVariant` are deprecated compatibility fields. `surfaceTint` is a legacy/implementation property and is not part of these 45 semantic roles; it is a **mandatory, explicitly declared, transparent** implementation property in this baseline and must be asserted independently.

### 2.3. Foreground/background pairing rules

| Background | Text/icon |
|---|---|
| `primary` | `onPrimary` |
| `primaryContainer` | `onPrimaryContainer` |
| `secondary` | `onSecondary` |
| `secondaryContainer` | `onSecondaryContainer` |
| `tertiary` | `onTertiary` |
| `tertiaryContainer` | `onTertiaryContainer` |
| `error` | `onError` |
| `errorContainer` | `onErrorContainer` |
| `surface` / `surfaceContainer*` | `onSurface` for primary text; `onSurfaceVariant` for supporting text, **subject to effective contrast validation** |
| `inverseSurface` | `onInverseSurface`; action accent `inversePrimary` |
| Each `*Fixed` or `*FixedDim` container | Corresponding `on*Fixed` or `on*FixedVariant` role, validated |

**[EXCEPTION]** `theme.disabledColor` in raw `ListTile` is a framework `ThemeData` value, not one of the 45 `ColorScheme` roles. It appears as `frameworkM3@SDK` ownership for that specific disabled row. `ListTileThemeData` does **not** expose a dedicated disabled-color property; the custom `AppListItem` wrapper supplies `WidgetStateColor.resolveWith` for **both** `textColor` and `iconColor`, mapping `WidgetState.disabled` to `effects.disabledForeground` and explicitly resolving selected/normal states as described in §3.1. Test the effective disabled title, subtitle, icons and `onTap` behavior; do not assume `ListTileThemeData.selectedColor` alone solves disabled precedence.

Do not substitute `onPrimary` on a surface or `onSurface` on a strong accent without an explicit approved exception. The on-role pairing must pass actual rendered contrast, including transparency/compositing.

## 3. Exact component color contract

**How to read:** each table cell specifies **one** color token for a given property and state. `transparent` is a centralized transparency token; `none` means there is no border. All rows are **[DECISION]** unless marked with verified default. `D=Match` means the inspected Flutter M3 behavior matches the listed color aspect; `D=Override` means the application must install a component theme or wrapper. `D=Check` means the pinned SDK must be compared before implementation; the desired decision still has one value.

### 3.1. Navigation and content

**Anatomy rule:** AppBar leading icon and trailing actions have **distinct slots**, and selected icons/labels are also separate. This table does not assume every component exposes both icon slots. `n/a` means that anatomy slot is absent; `none` means no painted element. Indicators and dividers are separate properties.

| Variant/state | Background | Leading/icon | AppBar actions icon | Label/main text | Supporting text | Indicator | Divider/border | Elevation | Flutter default / action |
|---|---|---|---|---|---|---|---|---|---|
| Scaffold | `surface` | `n/a` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level0` | Match common M3; assert runtime theme |
| Top AppBar normal | `surface` | `onSurface` | `onSurfaceVariant` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level0` | M3 match; background **state-resolved** (`WidgetStateColor`), tint transparent |
| Top AppBar scrolledUnder | **`surfaceContainer`** | `onSurface` | `onSurfaceVariant` | `onSurface` | `onSurfaceVariant` | `none` | `none` | **`elevation.level2`** | M3 match; `WidgetState.scrolledUnder` + state-resolved color; never plain theme Color |
| NavigationBar container | `surfaceContainer` | `n/a` | `n/a` | `n/a` | `n/a` | `none` | `none` | `elevation.level2` | Match M3; lock NavigationBarTheme |
| NavigationBar selected destination | `transparent` | **`onSecondaryContainer`** | `n/a` | **`onSurface`** | `n/a` | `secondaryContainer` | `none` | `elevation.level0` | **Source-verified M3**; selected icon is rendered over indicator |
| NavigationBar unselected destination | `transparent` | `onSurfaceVariant` | `n/a` | `onSurfaceVariant` | `n/a` | `none` | `none` | `elevation.level0` | Source-verified M3 |
| NavigationDrawer container | `surfaceContainerLow` | `n/a` | `n/a` | `n/a` | `n/a` | `none` | `none` | `elevation.level1` | D=Match; surface of Drawer, not item background |
| NavigationDrawer unselected destination | `transparent` | `onSurfaceVariant` | `n/a` | `onSurfaceVariant` | `n/a` | `none` | `none` | `elevation.level0` | D=Match; labelLarge; whole item background transparent |
| NavigationDrawer selected destination | `transparent` | `onSecondaryContainer` | `n/a` | `onSecondaryContainer` | `n/a` | `secondaryContainer` | `none` | `elevation.level0` | D=Match; separate stadium indicator with `shape.full`; **not** a filled rectangular item |
| TabBar.primary selected | `transparent` | `primary` | `n/a` | **`primary`** | `n/a` | `primary` | **`outlineVariant`** | `elevation.level0` | Source-verified M3; divider thickness `size.tabDividerThickness` |
| TabBar.primary unselected | `transparent` | `onSurfaceVariant` | `n/a` | `onSurfaceVariant` | `n/a` | `none` | `outlineVariant` | `elevation.level0` | Source-verified M3 |
| TabBar.secondary selected | `transparent` | `onSurface` | `n/a` | **`onSurface`** | `n/a` | `primary` | `outlineVariant` | `elevation.level0` | Source-verified M3; divider thickness `size.tabDividerThickness` |
| TabBar.secondary unselected | `transparent` | `onSurfaceVariant` | `n/a` | `onSurfaceVariant` | `n/a` | `none` | `outlineVariant` | `elevation.level0` | Source-verified M3 |
| SearchBar | `surfaceContainerHigh` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level0` | **D=Override** source default elevation 6dp and shadow `shadow`; set elevation=0, shadow transparent in SearchBarThemeData; assert Material effect |
| SearchView fullscreen (SearchAnchor) | `surfaceContainerHigh` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `outline` | `elevation.level0` | **D=Override** separate `SearchViewThemeData.elevation` from default 6dp; full-screen shape `shape.none`, divider `outline` from generated M3 view |
| SearchView anchored (SearchAnchor) | `surfaceContainerHigh` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `outline` | `elevation.level0` | **D=Override** elevation 6→0; rounded `shape.extraLarge`, divider `outline`; validate 320dp presentation on pin |
| ListTile normal (framework) | `transparent` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level0` | D=Match; default `EdgeInsetsDirectional.only(start:16, end:24)` (not symmetric) |
| ListTile selected (framework) | `transparent` | `primary` | `n/a` | `primary` | `primary` | `none` | `none` | `elevation.level0` | D=Match; selected title, subtitle, leading/trailing text and icons resolve to `primary`; transparent tile background |
| ListTile disabled (framework) | `transparent` | `theme.disabledColor` | `n/a` | `theme.disabledColor` | `theme.disabledColor` | `none` | `none` | `elevation.level0` | D=Match via `ThemeData.disabledColor`; **do not mislabel as** `onSurface` @0.38 |
| AppListItem normal (wrapper) | `transparent` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level0` | D=Override padding symmetric space.4; own ListTileTheme override or custom Row |
| AppListItem disabled (wrapper) | `transparent` | `effects.disabledForeground` | `n/a` | `effects.disabledForeground` | `effects.disabledForeground` | `none` | `none` | `elevation.level0` | **D=Override** use state-resolving `WidgetStateColor` for `ListTileThemeData.textColor` and `.iconColor`; test effective disabled/selected precedence and no action |
| AppListItem selected (wrapper) | `secondaryContainer` | `onSecondaryContainer` | `n/a` | `onSecondaryContainer` | `onSecondaryContainer` | `none` | `none` | `elevation.level0` | D=Override ListTile selectedTileColor/selectedColor and symmetric padding; apply to wrapper only |
| AppListItem disabled+selected (wrapper) | `secondaryContainer` | `effects.disabledForeground` | `n/a` | `effects.disabledForeground` | `effects.disabledForeground` | `none` | `none` | `elevation.level0` | **[DECISION] proposed**; tile background D=Match source (`selectedTileColor` applies whenever `selected`, regardless of `enabled`); disabled-first text/icon resolution; semantics `selected=true, enabled=false`; no action; composited legibility check (WCAG 1.4.3 exempt, state must remain recognizable) |
| Standard Card (outlined) | `surface` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `outlineVariant` | `elevation.level0` | Match `Card.outlined`; lock CardTheme/shape |
| Filled Card | `surfaceContainerHighest` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level0` | **D=Match; lock and reverify at SDK pin** |
| Elevated Card | `surfaceContainerLow` | `onSurfaceVariant` | `n/a` | `onSurface` | `onSurfaceVariant` | `none` | `none` | `elevation.level1` | **D=Match (master); reverify at SDK pin** |
| Featured Card | `primaryContainer` | `onPrimaryContainer` | `n/a` | `onPrimaryContainer` | `onPrimaryContainer` | `none` | `none` | `elevation.level0` | Custom component; not automatically allowed in existing systems |
| Divider | `transparent` | `n/a` | `n/a` | `n/a` | `n/a` | `none` | `outlineVariant` | `elevation.level0` | Lock DividerTheme |

**[APPLISTITEM DISABLED IMPLEMENTATION]** Use local `ListTileTheme(data: ...)` or approved wrapper-owned `ListTile(textColor: ..., iconColor: ...)` with `WidgetStateColor.resolveWith` on **both** properties. Resolve states in this priority: `disabled → effects.disabledForeground`, `selected → onSecondaryContainer`, `default title/icon → onSurface`/`onSurfaceVariant` as appropriate. Because `ListTile.textColor` is shared by title and subtitle when explicitly set, do **not** claim that a single `WidgetStateColor` yields `onSurface` title and `onSurfaceVariant` subtitle in the normal state. The wrapper must provide **explicit state-resolved subtitle text styling** (e.g., `Text` with a computed `TextStyle.color`, not merely `ListTileThemeData.subtitleTextStyle`, since ListTile applies its effectiveColor to its inherited subtitle style), or use a custom Row layout. Its subtitle color mapping must be disabled → `effects.disabledForeground`, selected → `onSecondaryContainer`, normal → `onSurfaceVariant`. **Disabled+selected:** `ListTile` keeps `selectedTileColor` whenever `selected` is true, even when disabled. The baseline keeps that background so the selection stays visible, and resolves title, subtitle, leading and trailing content to `effects.disabledForeground` through the same disabled-first priority. Do **not** silently pass `selected: false` for disabled items; that hides the selection and changes semantics. Test the actual `Text` style, not just `ListTileThemeData`. This is a proposed implementation contract, **not** a claim that raw ListTile defaults match the wrapper. Example (semantic tokens resolved by the approved theme):

```dart
final textStates = WidgetStateColor.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) return disabledForeground;
  if (states.contains(WidgetState.selected)) return scheme.onSecondaryContainer;
  return scheme.onSurface;
});
final iconStates = WidgetStateColor.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) return disabledForeground;
  if (states.contains(WidgetState.selected)) return scheme.onSecondaryContainer;
  return scheme.onSurfaceVariant;
});
final localListTileTheme = ListTileThemeData(
  textColor: textStates,
  iconColor: iconStates,
  selectedTileColor: scheme.secondaryContainer,
  contentPadding: EdgeInsets.symmetric(horizontal: tokens.space4),
);
// Resolve subtitle Text.style.color explicitly from enabled/selected
// state: disabledForeground / onSecondaryContainer / onSurfaceVariant.
// Do NOT rely on ListTileThemeData.subtitleTextStyle alone; the inherited
// subtitle color is overridden by ListTile effectiveColor.
// Verify the actual Text/semantics and disabled hit-testing.
```

**[SEARCH VIEW SCOPE]** `SearchAnchor.bar` launches a separate framework `SearchView` route with **transparent route barrier**, which is not the approved dimmed `effects.modalBarrierColor`: document it as an explicit non-dimming navigation exception. Its Material surface elevation **does** require the `SearchViewThemeData` override. Set `SearchViewThemeData.dividerColor=outline` to prevent `DividerTheme` precedence from changing the effective divider, and test full-screen vs anchored shapes separately. App-call-site `viewElevation`, `viewDividerColor`, `viewShape`, and `viewSurfaceTintColor` overrides must be blocked outside an approved view variant. The 320dp anchored minimum-width issue is a layout test, not permission to shrink touch targets.

**[APPBAR SCOPE]** Both `Top AppBar` rows apply **only to `AppBar` owned by `Scaffold.appBar` with a correctly connected `ScrollNotificationObserver`**. Explicitly **unsupported in this baseline**: standalone AppBar placed outside that mechanism, `SliverAppBar`, `SliverAppBar.medium`, and `SliverAppBar.large`; these require separate variant rows, constraints and tests before implementation. The app may still use them elsewhere, but cannot claim conformity to this Top AppBar contract. Always assert `AppBarTheme.iconTheme`/leading `onSurface` independently from `actionsIconTheme`/trailing `onSurfaceVariant`. **If `AppBarTheme.iconTheme` or `AppBarTheme.foregroundColor` is set, `AppBarTheme.actionsIconTheme` MUST also be explicitly set** to preserve `onSurfaceVariant`; widget-level `AppBar.iconTheme`/`AppBar.foregroundColor` overrides require an explicit effective action-icon contract (widget-level `actionsIconTheme` or an audited theme owner with proven precedence). Flutter resolves actions through `widget.actionsIconTheme → appBarTheme.actionsIconTheme → widget.iconTheme → appBarTheme.iconTheme → default`; the `foregroundColor` fallback can recolor default actions. Test both slots, including with an iconTheme/foregroundColor override; do not rely on default behavior when a leading override exists.

**[APPBAR RENDERING GATE]** AppBar background, elevation and tint are a **multi-state** contract, not just a token-table lookup. The 0dp→3dp elevation transition may produce no shadow because `appBar.shadowColor` is transparent; the `surface`→`surfaceContainer` color change must remain observable. Do not apply a primary-tinted surface overlay. See §1.3a and §9.3a.

**[DIMENSION]** `size.tabDividerThickness = 1dp` for primary/secondary TabBar. This is separate from the selected tab indicator weight, which remains delegated to pinned Flutter M3 (`frameworkM3`) unless an explicit token is approved. Do not apply the divider twice via `Divider` and TabBar. The inspected Flutter source paints the divider in both regular and scrollable primary/secondary TabBar paths, using different painter logic. **D=Check** only whether the pinned SDK differs. No extra external divider may be added.
### 3.2. Buttons and selection

| Variant/state | Background | Foreground | Border | Elevation | Flutter default / action |
|---|---|---|---|---|---|
| FilledButton enabled | `primary` | `onPrimary` | `none` | `elevation.level0` | Match; lock FilledButtonTheme |
| FilledTonalButton | `secondaryContainer` | `onSecondaryContainer` | `none` | `elevation.level0` | Match; lock FilledButtonTheme |
| ElevatedButton | `surfaceContainerLow` | `primary` | `none` | `elevation.level1` | **D=Match (master); lock, reverify at SDK pin** |
| OutlinedButton | `transparent` | `primary` | `outline` | `elevation.level0` | Match typical M3; lock OutlinedButtonTheme |
| TextButton | `transparent` | `primary` | `none` | `elevation.level0` | Match; lock TextButtonTheme |
| Standard IconButton unselected | `transparent` | `onSurfaceVariant` | `none` | `elevation.level0` | **Verified M3 default** |
| Standard IconButton selected | `transparent` | `primary` | `none` | `elevation.level0` | **Verified M3 default** |
| IconButton filled | `primary` | `onPrimary` | `none` | `elevation.level0` | **D=Match (master); non-toggle, lock** |
| IconButton tonal | `secondaryContainer` | `onSecondaryContainer` | `none` | `elevation.level0` | **D=Match (master); non-toggle, lock** |
| IconButton.filledTonal toggle unselected | `surfaceContainerHighest` | `onSurfaceVariant` | `none` | `elevation.level0` | D=Match, state policy from M3 |
| IconButton.filled toggle unselected | `surfaceContainerHighest` | `primary` | `none` | `elevation.level0` | D=Match, state policy from M3 |
| IconButton.outlined toggle unselected | `transparent` | `onSurfaceVariant` | `outline` | `elevation.level0` | D=Match, explicit variant |
| IconButton.outlined toggle selected | `inverseSurface` | `onInverseSurface` | `none` | `elevation.level0` | D=Match, assert effective border/color in selected state |
| FAB standard | `primaryContainer` | `onPrimaryContainer` | `none` | `elevation.level3` | **D=Match (master) normal 6dp / hovered 8dp; reverify at SDK pin** |
| FilterChip unselected (flat) | `transparent` | `onSurfaceVariant` | `outlineVariant` | `elevation.level0` | **Verified Flutter source** |
| FilterChip selected (flat) | `secondaryContainer` | `onSecondaryContainer` | `none` | `elevation.level0` | **Verified Flutter source** |
| ChoiceChip unselected | `transparent` | `onSurfaceVariant` | `outlineVariant` | `elevation.level0` | **D=Match (master); add unselected anatomy to widget test** |
| ChoiceChip selected | `secondaryContainer` | `onSecondaryContainer` | `none` | `elevation.level0` | **D=Match (master); lock chip theme** |
| Checkbox selected | `primary` | `onPrimary` | `none` | `elevation.level0` | **D=Match; lock** primary selected fill in CheckboxTheme and assert effective color |
| Checkbox unselected | `transparent` | `onSurfaceVariant` | `onSurfaceVariant` | `elevation.level0` | **D=Match (master); lock checkbox theme** |
| Radio unselected | `transparent` | `onSurfaceVariant` | `none` | `elevation.level0` | **D=Match (master); lock RadioThemeData and test inactive/active** |
| Radio selected | `transparent` | `primary` | `none` | `elevation.level0` | **D=Match (master); lock radio theme** |
| Switch selected | `primary` | `onPrimary` (thumb symbol) | `none` | `elevation.level0` | **D=Match (master); track/thumb separately mapped by SwitchTheme, reverify pin** |
| LinearProgressIndicator active indicator | `transparent` | `primary` | `none` | `elevation.level0` | D=Match source active color for 2023/2024; explicit `year2023` value D=Check pending SDK |
| LinearProgressIndicator inactive track | `secondaryContainer` | `none` | `none` | `elevation.level0` | D=Match source for both 2023 and 2024; **not transparent**; test track pixel |
| Slider active track | `primary` | `none` | `none` | `elevation.level0` | D=Match; `year2023` pin pending |
| Slider inactive track | `frameworkM3@SDK` | `none` | `none` | `elevation.level0` | **D=Check**: 2023/2024 color changes (`surfaceContainerHighest`/`secondaryContainer`); resolve to one real role after SDK pin |

For Switch and Slider, the `background/foreground` columns describe the state/track role, not the entire multi-part component. **Anatomy subparts need their own rows in implementation registry**, e.g. `switch.selected.thumb = onPrimary`, `switch.unselected.track = surfaceContainerHighest`, `switch.unselected.border = outline`. **`slider.inactiveTrack` remains `D=Check` under DSD-23, whereas `linearProgress.track = secondaryContainer` is fixed in both appearance branches on the audited master.** The choice of `LinearProgressIndicator.year2023` remains `D=Check` for geometry/behavior rather than for track color. If using the revised 2024 style, the responsible owner must explicitly set and snapshot the choice for the pinned SDK; avoid deprecated flags if that SDK has removed them. Never treat a linear progress track as transparent by default.

### 3.3. Input, overlays, feedback

| Variant/state | Painted fill | Foreground | Border/indicator | Elevation | Flutter default / action |
|---|---|---|---|---|---|
| OutlinedTextField normal | **`transparent`** | `onSurface` | `outline` | `elevation.level0` | **Default no fill**; lock `filled: false` and `outlineBorder` |
| OutlinedTextField focused | **`transparent`** | `onSurface` | `primary` | `elevation.level0` | D=Match; focused outline width `stroke.inputFocused` |
| OutlinedTextField error | **`transparent`** | `onSurface` | `error` | `elevation.level0` | D=Match; error outline width `stroke.inputNormal` |
| OutlinedTextField error+focused | **`transparent`** | `onSurface` | `error` | `elevation.level0` | D=Match; focused error outline width `stroke.inputFocused` |
| OutlinedTextField error+hovered | **`transparent`** | `onSurface` | `onErrorContainer` | `elevation.level0` | D=Match; hovered error outline width `stroke.inputNormal` |
| FilledTextField normal | `surfaceContainerHighest` | `onSurface` | **`onSurfaceVariant`** | `elevation.level0` | **Source-verified M3**; `filled: true`, underline only |
| FilledTextField focused | `surfaceContainerHighest` | `onSurface` | `primary` | `elevation.level0` | Source-verified M3; underline width `stroke.inputFocused` |
| FilledTextField error | `surfaceContainerHighest` | `onSurface` | `error` | `elevation.level0` | D=Match; error underline width `stroke.inputNormal` |
| FilledTextField error+focused | `surfaceContainerHighest` | `onSurface` | `error` | `elevation.level0` | D=Match; underline width `stroke.inputFocused` |
| FilledTextField error+hovered | `surfaceContainerHighest` | `onSurface` | `onErrorContainer` | `elevation.level0` | D=Match; error+hover state priority, width `stroke.inputNormal` |
| OutlinedTextField disabled | `transparent` | `effects.disabledForeground` | `effects.disabledOutline` | `elevation.level0` | D=Match source opacity intent; border alpha=0.12, disabled-state metrics asserted |
| FilledTextField disabled | `effects.disabledFill` | `effects.disabledForeground` | **`effects.disabledForeground`** | `elevation.level0` | **D=Match**: fill alpha=0.04, foreground **and underline** alpha=0.38 (not outlined 0.12) |
| Dialog | `surfaceContainerHigh` | `onSurface` | `none` | `elevation.level3` | Match common M3; lock DialogTheme |
| Modal bottom sheet | `surfaceContainerLow` | `onSurface` | `none` | `elevation.level0` | **D=Override** source M3 defaults to 1dp; set `modalElevation=0`; shadow/tint transparent; `showDragHandle=false` |
| Modal bottom sheet drag handle (disabled baseline) | `none` | `n/a` | `none` | `elevation.level0` | **D=Match** `BottomSheetThemeData.showDragHandle=false`; an enabled variant requires approval; its source handle uses `onSurfaceVariant`, 32×4 visual and 48dp tap target |
| PopupMenu surface | `surfaceContainer` | `onSurface` | `none` | `elevation.level2` | Source-verified M3 color and 4dp shape |
| Tooltip | `inverseSurface` | `onInverseSurface` | `none` | `elevation.level0` | **D=Override** TooltipThemeData decoration/text; D=Match mobile constraints minHeight32 and padding H16/V4; `bodyMedium` |
| Snackbar floating | `inverseSurface` | `onInverseSurface` | `none` | `elevation.level3` | **D=Match colors/shape; Override behavior=floating** |
| Snackbar action | `transparent` | `inversePrimary` | `none` | `elevation.level0` | Source-verified M3, lock action color |
| Error banner | `errorContainer` | `onErrorContainer` | `none` | `elevation.level0` | Custom banner |
| Empty state | `transparent` | `onSurface` | `none` | `elevation.level0` | Supporting copy `onSurfaceVariant` |
| Dialog / modal-sheet route barrier | `effects.modalBarrierColor` | `none` | `none` | `elevation.level0` | **D=Override mandatory**: `DialogThemeData.barrierColor` + `BottomSheetThemeData.modalBarrierColor`; test `ModalRoute.barrierColor`; alpha BLOCKED (DSD-02) |
| Drawer scrim | `effects.modalBarrierColor` | `none` | `none` | `elevation.level0` | **D=Override mandatory** `DrawerThemeData.scrimColor`; test fully opened animated `ColoredBox`/effective scrim, **not ModalRoute** |

**[IMPORTANT]** `transparent` for outlined fields means **no fill is painted**, so the parent surface is visible (especially in dialogs/sheets). It does not mean paint an explicit transparent `Material` tile above a parent. The app may use an outlined border, but must not inject an opaque `surface` field background.

**[M3 source distinction]** `SnackBar` colors and 4dp radius already match M3 on inspected Flutter master. The framework default `SnackBarBehavior.fixed` is **not** floating. If the custom variant is called `Snackbar floating`, lock `SnackBarThemeData.behavior = SnackBarBehavior.floating`, and verify layout/elevation in the pinned SDK. This is a behavior override, not a color-default correction.

**No built-in `success`, `warning`, or `info` ColorScheme role** is defined by M3 Core. Such semantic tokens require an explicit `ThemeExtension` containing `container`, `onContainer`, icon and contrast tests. Until approved, do not paint a success panel using arbitrary `tertiary` or a warning panel using `error`.


**Explicit `D=Check` items (not implementation approvals):** Slider/RangeSlider inactive-track color and Slider/ProgressIndicator appearance geometry depend on the pinned `year2023` selection. **LinearProgressIndicator track color is `secondaryContainer` in both audited appearances**; it is NOT an unresolved color choice. TabBar divider painter behavior must be reverified on the pin. Checkbox selected fill is **not** a `D=Check` ambiguity: `CheckboxTheme` MUST lock `primary`, then the effective selected color must be asserted. For iOS builds, the CI a11y matrix MUST include `iOSTapTargetGuideline`.

### 3.3a. Bottom-sheet drag handle contract

**[DECISION]** The baseline **does not show a drag handle** (`BottomSheetThemeData.showDragHandle=false`), matching master when no local override enables it. This is not a ban on dragging a modal sheet if its route enables drag; the indicator and gesture are separate concepts. A future handle-enabled variant must explicitly declare `showDragHandle=true`, `dragHandleColor=onSurfaceVariant`, `dragHandleSize=(size.sheetDragHandleWidth, size.sheetDragHandleHeight) = 32×4`, and an accessible hit region of **48dp**, plus action/semantics testing. It must not be enabled per-screen without registry approval.

### 3.4. Component property exceptions: source default vs baseline override

| Property | Flutter M3 master observed | Baseline v2.6.1 selected token | Decision / gate |
|---|---|---|---|
| `SearchBar.elevation` | 6dp | `elevation.level0` | **D=Override** `SearchBarThemeData.elevation`, assert effective Material |
| `SearchBar.shadowColor` | `shadow` | `colors.transparent` | **D=Override** `SearchBarThemeData.shadowColor`, no actual shadow |
| `SearchView.elevation` | 6dp (separate generated view default) | `elevation.level0` | **D=Override** `SearchViewThemeData.elevation`, test expanded `SearchAnchor.bar` route |
| `SearchView.surfaceTintColor` | `transparent` | `colors.transparent` | D=Match; lock via `SearchViewThemeData` and Material property |
| `ModalBottomSheet.elevation`, `.modalElevation` | 1dp | `elevation.level0` | **D=Override**, numeric and visual check |
| `ListTile.contentPadding.start` | 16dp | `layout.listTile.start` | D=Match on raw Flutter ListTile |
| `ListTile.contentPadding.end` | 24dp | `layout.listTile.end` | D=Match on raw Flutter ListTile; wrapper instead D=Override symmetric 16dp |
| `SnackBar.floating.padding.horizontal` | 16dp | `space.4` | D=Match |
| `SnackBar.floating.padding.vertical` | 14dp | `frameworkM3` | D=Match; do **not** force `space.3` |
| `Tooltip.mobile.padding.horizontal` | 16dp | `space.4` | D=Match; formerly incorrectly 8dp |
| `Tooltip.mobile.padding.vertical` | 4dp | `space.1` | D=Match |
| `Tooltip.mobile.constraints.minHeight` | 32dp | `size.tooltipMinHeight` | D=Match; use `constraints`, not deprecated `height` |
| `Tooltip.mobile.text` | 14sp | `bodyMedium` | D=Match text role; override color to `onInverseSurface` |
| `Slider.year2023` | defaults true currently; deprecated | `frameworkM3@SDK` | **D=Check**: pin and pick true/false explicitly, freeze inactive track color |
| `LinearProgressIndicator.year2023` | defaults true currently; deprecated | `frameworkM3@SDK` | **D=Check** appearance choice; track color `secondaryContainer` for BOTH versions |
| `Checkbox.selected.fill` | `primary` in audited M3 | `primary` | **D=Match; lock** CheckboxThemeData and effective widget assertion; ignore M2 legacy doc fallback |
| `FloatingActionButton.hovered.elevation` | 8dp (master) | `frameworkM3@SDK` | Captured by elevation.level4 in source; choose pinned exact mapping |
| `FilledButton.hovered.elevation` | 1dp (master) | `frameworkM3@SDK` | State-specific source lock, not normal level0 |
| `ElevatedButton.hovered.elevation` | 3dp (master) | `frameworkM3@SDK` | State-specific source lock, not enabled level1 |

`frameworkM3@SDK` means an **explicitly delegated SDK-defined property** with SDK revision recorded, not a wildcard value. All nondelegated component properties must reference exactly one concrete token. Upon SDK pin, the `year2023` policy must be changed from D=Check to a selected boolean in the registry; lack of source verification is not approval.


## 4. Shape, spacing, and anatomy per variant — one token in each slot

### 4.1. Shared component dimensions

| Variant | Radius token | Content padding H | Content padding V | Internal gap | Visual height/min | External gap owner | Elevation |
|---|---|---|---|---|---|---|---|
| Standard Card | `shape.medium` | `space.4` | `space.4` | `space.2` | `intrinsic` | Parent | `elevation.level0` |
| Compact Card | `shape.medium` | `space.3` | `space.3` | `space.1` | `intrinsic` | Parent | `elevation.level0` |
| Featured Card | `shape.large` | `space.6` | `space.6` | `space.2` | `intrinsic` | Parent | `elevation.level0` |
| AppListItem, single-line (wrapper) | `shape.none` | `space.4` | `space.2` | `space.3` | `size.listRowSingleMin` | Parent | `elevation.level0` |
| AppListItem, two-line (wrapper) | `shape.none` | `space.4` | `space.2` | `space.1` | `size.listRowDoubleMin` | Parent | `elevation.level0` |
| AppListItem, three-line (wrapper) | `shape.none` | `space.4` | `space.2` | `space.1` | `size.listRowTripleMin` | Parent | `elevation.level0` |
| ListTile (framework default) | `shape.none` | `layout.listTileDirectionalInsets` | `frameworkM3` | `frameworkM3` | `frameworkM3` | Parent | `elevation.level0` |
| Selection Card | `shape.medium` | `space.4` | `space.4` | `space.3` | `intrinsic` | Parent | `elevation.level0` |
| Flat buttons (filled/tonal/outlined/text) | `shape.full` | `frameworkM3` | `frameworkM3` | `space.2` (icon-label) | `size.buttonVisualHeight` | Parent | `elevation.level0` |
| Elevated Button | `shape.full` | `frameworkM3` | `frameworkM3` | `space.2` | `size.buttonVisualHeight` | Parent | `elevation.level1` |
| Icon Button standard | `shape.full` | `frameworkM3` | `frameworkM3` | `space.0` | `size.iconButtonVisual` | Parent | `elevation.level0` |
| Filter/Choice Chip | `shape.small` | `frameworkM3` | `frameworkM3` | `space.2` | `frameworkM3` | Parent | `elevation.level0` |
| Outlined Text Field | `shape.extraSmall` | `frameworkM3` | `frameworkM3` | `space.2` (icon-text) | `size.textFieldMinHeight` | Form parent | `elevation.level0` |
| Filled Text Field | `shape.extraSmall` | `frameworkM3` | `frameworkM3` | `space.2` (icon-text) | `size.textFieldMinHeight` | Form parent | `elevation.level0` |
| Dialog | `shape.extraLarge` | `space.6` | `space.6` | `space.4` | `intrinsic` | Overlay | `elevation.level3` |
| Modal Bottom Sheet (no handle) | `shape.extraLarge` (top only) | `space.4` | `space.4` | `space.4` | `intrinsic` | Overlay | `elevation.level0` (**override M3 1dp**) |
| Popup Menu | `shape.extraSmall` | `frameworkM3` | `frameworkM3` | `space.0` | `intrinsic` | Overlay | `elevation.level2` |
| Standard FAB | `shape.large` | `frameworkM3` | `frameworkM3` | `space.0` | `frameworkM3` | Scaffold | `elevation.level3` |
| Floating Snackbar | `shape.extraSmall` | `space.4` | `frameworkM3` | `space.2` | `intrinsic` | Scaffold | `elevation.level3` |
| SearchView fullscreen | `shape.none` | `frameworkM3` | `frameworkM3` | `frameworkM3` | `intrinsic` | Overlay | `elevation.level0` (**override M3 6dp**) |
| SearchView anchored | `shape.extraLarge` | `frameworkM3` | `frameworkM3` | `frameworkM3` | `intrinsic` | Overlay | `elevation.level0` (**override M3 6dp**) |
| Tooltip (mobile) | `shape.extraSmall` | `space.4` | `space.1` | `space.0` | `size.tooltipMinHeight` | Overlay | `elevation.level0` |
| Status Banner | `shape.medium` | `space.4` | `space.3` | `space.3` | `intrinsic` | Parent | `elevation.level0` |
| Empty State | `shape.none` | `space.4` | `space.6` | `space.2` | `intrinsic` | Parent | `elevation.level0` |

`layout.listTileDirectionalInsets` is a **single compound token** with asymmetric start/end components; the start/end semantic sub-tokens in §1.4 are its audited parts, not independent choices at call sites. `frameworkM3` is one named **delegation decision**, not a range: preserve the pinned Flutter component's internal padding and evolving density/label scaling. Before changing it, create an explicit replacement token and approval. `intrinsic` means **content-driven** and may grow for text scale. No fixed-height clipping. Rows with `frameworkM3` must be snapshot tested against the pinned SDK.

### 4.2. Screen spacing and layout — deterministic pattern contract

| Relationship | Exactly one token | Owner |
|---|---|---|
| Compact phone page gutter | `space.4` (16) | Screen scaffold/layout |
| Page title -> first content region | `space.6` (24) | Screen layout |
| Section heading -> section body | `space.4` (16) | Section layout |
| Between independent sections | `space.6` (24) | Screen layout |
| Between major screen zones | `space.8` (32) | Screen layout |
| Between sibling standard cards | `space.2` (8) | List parent |
| Between grid siblings | `space.3` (12) | Grid parent |
| Between filter chips (horizontal) | `space.2` (8) | Wrap parent |
| Between filter chip runs (vertical) | `space.2` (8) | Wrap parent |
| Between form fields | `space.4` (16) | Form parent |
| Between action buttons | `space.2` (8) | Action row parent |
| Label -> supporting text | `space.1` (4) | Component |
| Icon -> label | `space.2` (8) | Component |
| TextField -> helper/error line | `space.1` (4) | Field component |
| Content -> persistent bottom action region | `space.6` (24) | Screen layout |
| Bottom persistent action -> system navigation | `layout.bottomActionSafePadding` | Screen layout |
| Dialog title -> content | `space.4` (16) | Dialog |
| Bottom sheet header -> content | `space.4` (16) | Sheet |
| Empty illustration -> title | `space.6` (24) | Empty state |
| Empty state title -> body | `space.2` (8) | Empty state |

**Hierarchy:** related elements use smaller tokens than section separation. This is a relationship, **not** an invitation to choose any value within a range. When a design requires a special spacing variant, name it and add an exact token.

### 4.3. Ownership and no double padding

- Component owns internal padding, shape, tap size and its anatomy.
- Parent pattern owns external gap, grid columns, section grouping and viewport gutter.
- No hidden external margin in shared components. Flutter `Card.margin` must be normalized to zero at component boundary when parent controls gap.
- One alignment grid: app bar/section headers/content cards/primary actions should share their intended text/content start position; exceptions are component anatomies registered by name.
- A touch target's **interactive bounds**, not just visible icon bounds, must be >=48×48 and must not overlap adjacent interactive targets.
- For 320dp screens, avoid two-column layouts whose item min width is not satisfied; content should switch to one column using a registered breakpoint/pattern, not shrink fonts.

## 5. Typography and iconography — full M3 typescale

### 5.1. M3 2021 TextTheme tokens

| Style | Size | Line height | Weight | Letter spacing |
|---|---:|---:|---|---:|
| `displayLarge` | 57 | 64 | w400 | -0.25 |
| `displayMedium` | 45 | 52 | w400 | 0 |
| `displaySmall` | 36 | 44 | w400 | 0 |
| `headlineLarge` | 32 | 40 | w400 | 0 |
| `headlineMedium` | 28 | 36 | w400 | 0 |
| `headlineSmall` | 24 | 32 | w400 | 0 |
| `titleLarge` | 22 | 28 | w400 | 0 |
| `titleMedium` | 16 | 24 | w500 | 0.15 |
| `titleSmall` | 14 | 20 | w500 | 0.1 |
| `bodyLarge` | 16 | 24 | w400 | 0.5 |
| `bodyMedium` | 14 | 20 | w400 | 0.25 |
| `bodySmall` | 12 | 16 | w400 | 0.4 |
| `labelLarge` | 14 | 20 | w500 | 0.1 |
| `labelMedium` | 12 | 16 | w500 | 0.5 |
| `labelSmall` | 11 | 16 | w500 | 0.5 |

**[DECISION] Role assignment:** `pageTitle = titleLarge`; `sectionTitle = titleMedium`; `cardTitle = titleMedium`; `listTitle = bodyLarge`; `supportingBody = bodyMedium`; `metadata = bodySmall`; `buttonLabel = labelLarge`; `chipLabel = labelLarge`; `dialogTitle = headlineSmall`; `dialogBody = bodyMedium`; `navigationBarLabel = labelMedium`; `navigationDrawerLabel = labelLarge`; `tabLabel = titleSmall`; `menuItemLabel = labelLarge`; `snackbarText = bodyMedium`; `searchBarText = bodyLarge`; `tooltipText = bodyMedium`; `textFieldInput = bodyLarge`; `textFieldLabel = bodyLarge`; `textFieldHint = bodyLarge`; `textFieldHelper = bodySmall`; `textFieldError = bodySmall`. These role aliases are chosen **once** and code uses `Theme.of(context).textTheme.<role>`.

Typography fallback for Vietnamese/Korean is approved at the typography theme/foundation level, not per widget. Text must remain readable with large system scaling. Do not hardcode `height`, `fontSize` or `letterSpacing` at individual call sites.

### 5.1a. Input text color/state anatomy (normative)

| Input part / state | Text role | Color role | Enforcement |
|---|---|---|---|
| Input value enabled | `bodyLarge` | `onSurface` | TextField text style + widget snapshot |
| Floating/inline label idle | `bodyLarge` | `onSurfaceVariant` | InputDecoration labelStyle; actual floating scaling per SDK |
| Label focused | `bodyLarge` | `primary` | WidgetState.focused label theme |
| Label error | `bodyLarge` | `error` | InputDecorator error state |
| Hint | `bodyLarge` | `onSurfaceVariant` | InputDecoration hintStyle |
| Helper | `bodySmall` | `onSurfaceVariant` | helperStyle |
| Error/helper replacement | `bodySmall` | `error` | errorStyle |
| Disabled content | `bodyLarge` | `effects.disabledForeground` | Effective opacity/compositing test |

**[INPUT STATE DETAIL]** `stroke.inputNormal=1dp`, `stroke.inputFocused=2dp` for both filled underline and outlined border. `error + focused` resolves `error` at 2dp; `error + hovered` resolves `onErrorContainer` at 1dp. In an error state, suffix-icon color resolves `error` (and `onErrorContainer` when error+hovered) while ordinary prefix/icon remains `onSurfaceVariant` unless explicitly configured. `effects.disabledOutline` applies only to outlined borders; the filled disabled underline uses `effects.disabledForeground`. Add separate goldens/state tests for error+focused, error+hovered, suffix icon error and disabled strokes.

The role specifies the **base style**. Flutter may adjust floating-label scale/metrics through InputDecorator; do not hardcode per-screen replacements. Error precedence (focused error, disabled error combinations) must follow the pinned SDK's state resolver. Rounded outline input remains unfilled (`filled=false`).
### 5.2. Icons

| Aspect | Decision |
|---|---|
| Default glyph size | `size.iconStandard` = 24 |
| Compact glyph size | `size.iconCompact` = 20 |
| Interactive icon target | `size.touchTargetMin` = 48 |
| Icon-label gap | `space.2` = 8 |
| Disabled/secondary | semantic role or component default state layer; no arbitrary opacity |
| Icon family | One approved icon family per application |
| Action semantics | Tooltip + semantic label on icon-only controls |

If an icon appears visually off-center despite geometric centering, correct it in a shared icon asset/wrapper and record the exception. Never add random `Transform.translate` in screen composition.

## 6. Visual-hierarchy, harmony, and screen composition rules

### 6.1. Countable emphasis budget

- **At most 1 visible Filled Primary CTA** per route viewport. If there is a FAB for the same action, **do not** also render a primary Filled CTA.
- **At most 1 FAB** per route (Flutter itself recommends at most one FAB per screen).
- **At most 1 large AccentPanel** (`FeaturedCard`/hero container using primaryContainer/tertiaryContainer) per viewport. Selected chips/list items are NOT counted as AccentPanels.
- `error` is reserved for failures/validation/destructive meaning; do not use it as an arbitrary visual accent.
- Use `secondaryContainer` for selection status; reserve `primary` for focus/CTA and explicit selected standard IconButton.
- Never put accent backgrounds on all cards in a homogeneous list.
- At most 1 nested decorated card layer inside another card; prefer whitespace/grouping. Explicit dashboard exceptions must be approved.
- Use **one** horizontal content grid for each screen area. A card's internal text indent is deliberate and is not a second page gutter.
- Where an outlined card already separates its content, avoid automatically adding a second Divider or extra shadow.

These are **project design constraints**, not M3 official limits. Enforce the countable ones by screen composition wrappers or widget tree tests. Allow exceptions only through decision registry with evidence.

### 6.2. Mutual effects of choosing roles

| Chosen role | Consequence for other components |
|---|---|
| `primary` on CTA | Other ordinary cards remain neutral; only one primary CTA in visible viewport |
| `secondaryContainer` on selected FilterChip | Unselected chips remain transparent with `outlineVariant`; active choice is identified by checkmark/semantics |
| `secondaryContainer` on selected NavigationBar destination | Inactive destinations remain transparent; do not add another accent-colored nav background |
| `primaryContainer` on FeaturedCard | Only one such large accent panel; ordinary cards revert to outlined/neutral |
| `surfaceContainerHigh` on dialog | Avoid auto-decorating every content section inside the dialog as a card |
| `errorContainer` on error banner | Field errors use `error`; leave unaffected content neutral |
| `outlineVariant` on divider | Do not require an additional border between the same groups |
| `inverseSurface` on snackbar/tooltip | Their content uses `onInverseSurface` and actions `inversePrimary`, never `onSurface` |

### 6.3. Aesthetics and composition acceptance checks

- **Scanning order:** page heading -> relevant content/selection -> primary action should be perceptible without reading every item.
- **Whitespace:** spacing reflects relation: within a group < between groups < between screen zones.
- **Density:** default `standard`; compact is a named pattern with a dedicated spec, never implemented by arbitrary per-screen visualDensity changes. Keep touch targets >=48.
- **Borders:** use `outline` when the boundary is essential to recognizing a control and 3:1 is needed; `outlineVariant` for decorative boundaries, and for the verified unselected flat FilterChip default **only if overall control affordance remains identifiable**.
- **Alignment:** headers, cards, list rows, actions should obey the registered content grid; visual off-by-2/4px adjustments require a documented optical exception.
- **Hierarchy:** no arbitrary bolding or saturation to create emphasis; use typography/color role and placement first.
- **Text:** must support Vietnamese and Korean line breaks, multiline labels, RTL if within supported locales, large text scale and no clipped essential actions.
- **Image/icon usage:** maintain fixed aspect ratio per media variant, meaningful alt/semantics, and consistent stroke weight.
- **Motion:** focus, state transitions, and feedback improve understanding; no gratuitous infinite animation.
- **Native UX:** safe area, keyboard insets, back handling, sheets, overscroll and TalkBack must work like Flutter mobile, not desktop-web hover UI.

### 6.4. Screen-specific pattern tokens

| Screen pattern | Page gutter | Section gap | Item gap | Primary action |
|---|---|---|---|---|
| Collection list | `space.4` | `space.6` | `space.2` | One FAB |
| Selection workflow | `space.4` | `space.6` | `space.2` | One persistent Filled CTA |
| Input form | `space.4` | `space.6` | `space.4` | One **body.scrollEnd** Filled CTA |
| Settings | `space.4` | `space.6` | `space.0` for contiguous rows | Per-screen action policy |
| Empty state | `space.4` | `space.8` | `space.2` | One Filled CTA if action exists |

The `primary action` column describes **pattern choice**, not a color token slot. If a screen has no action, it renders no CTA. No decorative FAB for the sake of meeting a template.

### 6.5. Input-form CTA placement — one required slot

**[DECISION] `layout.formCtaSlot = body.scrollEnd`**, including keyboard-open mode. A form action is the **last content child of the scrollable form body**, not `Scaffold.bottomNavigationBar`, `bottomSheet`, `persistentFooterButtons`, or an overlay. For this pattern, **persistent/sticky placement is disallowed** without a separately approved variant. Do not use `layout.bottomActionSafePadding` on the form CTA: the form is already inset by its scroll/body layout.

A conforming pattern uses `Scaffold(resizeToAvoidBottomInset: true)` and one scrollable form body (for example a `ListView` or `CustomScrollView`) containing fields, spacing and the Filled CTA as the final child. The scroll body applies bottom content spacing `space.4`, plus safe-area handling **once**. The CTA must be reachable by scrolling at 320dp width, 2.0 text scale, with 0 and nonzero keyboard insets; focus on the final field must not hide its error/helper text indefinitely.

**Testable properties:**

1. The form CTA is a descendant of the body's scrollable, not the Scaffold bottom navigation/footer slots.
2. With keyboard open, `tester.ensureVisible(find.byKey(formCtaKey))` can expose and activate the CTA without overlap with the IME; test a realistic IME `viewInsets.bottom` and very short available viewport.
3. No duplicated `viewPadding`/`SafeArea` bottom padding; test both zero and gesture-navigation bottom insets.
4. Scrolling and focus restoration keep form fields reachable. No fixed-height wrapper clips controls at text scale 2.0.

Selection workflows using a **persistent** CTA are a **different** pattern (`layout.selectionCtaSlot = body.stickyFooter`), explicitly owned by the `Scaffold.body` layout with one bottom padding owner; these workflows must pass equivalent IME/viewport tests if they include editable fields. They must not inherit the scroll-end form policy implicitly.

## 7. State and behavior matrix

| State | Required treatment | Behavior/semantics | Enforcement |
|---|---|---|---|
| Default | Exact component color/shape/text/elevation token | Normal action | Component golden |
| Pressed | Flutter state layer/ink | Immediate feedback | Widget state test |
| Focused | Visible focus treatment | Keyboard/focus semantics | Focus test |
| Selected | Dedicated role plus non-color signal | `selected` in semantics | Semantics test |
| Disabled | Material disabled-state colors | No action | Disabled callback test |
| Loading | App progress component | Prevent duplicate destructive submissions | State test |
| Error | `error`, helper text, error semantics | Clear recovery | Validation test |
| Expanded | Correct expand icon/layout | Expanded state | Semantics/widget test |
| Dragged | Drag feedback | Valid drop affordance | Gesture test |

Do not require irrelevant states on every widget (e.g. `loading` on a static Divider). Define the applicable subset per component. TextField errors have distinct visual/semantic handling from destructive action buttons.

## 8. Accessibility thresholds and test gates

**[DECISION] App typography policy is stricter than the generic WCAG large-text exception:** every `title*`, `body*`, and `label*` role, including `titleLarge`, must reach **4.5:1** for each approved **foreground/background token pair** in light, dark and any separately approved high-contrast schemes. Display/headline roles may use 3:1 **only if their rendered metrics qualify as large-scale text**; targeting 4.5:1 remains preferred. Use independent token-pair contrast math over the approved palette fixture as the normative gate.

**[SOURCE] WCAG 1.4.3:** ordinary text ≥4.5:1; large text ≥3:1, with thresholds **18pt ≈ 24px regular** or **14pt bold ≈ 18.5px** as written in W3C's explanatory material. Flutter's `textContrastGuideline` may classify text ≥18 logical px or ≥14 logical px and bold `w700` as large based on framework heuristics; it may therefore allow 3:1 for `titleLarge` even though app policy requires 4.5:1. **Passing `meetsGuideline(textContrastGuideline)` alone is NOT sufficient to pass this policy.** Effective overlays, surface tone composition, state layers and text scaling still require rendered/semantics inspection.

- Meaningful controls/icons/boundaries: ≥3:1 against adjacent effective colors when their visual boundary or state must be distinguished. Pure decorative dividers have no fixed 3:1 target.
- Android interactive target: ≥48×48 logical px; iOS guideline: ≥44×44, and app's 48×48 policy remains stricter on both where possible.
- Tap semantics: accessible name, role and state; selected cannot be communicated by color alone; swipe-only destructive gestures require alternatives.
- Text scale 2.0 and width 320: no lost primary action, overlap, hidden important error, or unscrollable layout; **framework clamps must be accounted for in measured expectations** (`NavigationBar` label approximately 1.3x, `AppBar` title approximately 1.34x on audited master; pin SDK before asserting constants).
- Visual/line-height tests must use tolerance rather than rounded fixed pixel assertions: `fontSize × height` can yield fractions (e.g., 63.84 instead of 64). Golden tests use real fonts and a pinned CI OS.
- High contrast: `MaterialApp.highContrastTheme` and `highContrastDarkTheme` exist. **DSD-32 is D=Check, pending product/platform decision**: choose `SUPPORTED` (independently approved high-contrast palette fixtures with full gates) or `FALLBACK` (verify expected default to light/dark theme and accessibility limitations). No statement of high-contrast conformance without explicit decision and tests.
- The Flutter `meetsGuideline` tap/label/contrast matchers are **supplementary**, not substitutions for strict token-policy checks and inspected visual states.

## 9. Enforceability — implementation and CI gates

### 9.0. Approved theme implementation contract (adapter sketch)

The following is **illustrative code for the centralized theme owner, not a runnable palette**. It must consume independent approved light/dark values; do not replace missing approved palette values with fabricated HEX values. `appBarTheme.backgroundColor` must resolve `WidgetState.scrolledUnder`, and `surfaceTint` must be explicit even though it is not among the 45 roles.

```dart
// In the approved foundation/theme layer only. WidgetStateColor is
// supported in the SDK checked against this adapter.
AppBarThemeData appBarThemeFor(ColorScheme scheme) => AppBarThemeData(
  backgroundColor: WidgetStateColor.resolveWith((states) {
    return states.contains(WidgetState.scrolledUnder)
        ? scheme.surfaceContainer
        : scheme.surface;
  }),
  elevation: AppTokens.elevationLevel0,
  scrolledUnderElevation: AppTokens.elevationLevel2,
  shadowColor: AppTokens.transparent,
  surfaceTintColor: AppTokens.transparent,
  iconTheme: IconThemeData(color: scheme.onSurface),
  actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
);

// Palette constructor must explicitly declare surfaceTint:
// surfaceTint: AppTokens.transparent,  // effects.surfaceTint
// This comment is NOT permission to generate/unreview palette colors.

// Once DSD-02 is approved, build the final route barrier exactly once:
Color approvedModalBarrier(ColorScheme scheme, double approvedScrimOpacity) {
  assert(scheme.scrim.a == 1.0, 'Approved scrim must be opaque');
  assert(approvedScrimOpacity >= 0 && approvedScrimOpacity <= 1);
  return scheme.scrim.withValues(alpha: approvedScrimOpacity);
}

// Install the same computed barrier into DialogThemeData.barrierColor,
// BottomSheetThemeData.modalBarrierColor AND DrawerThemeData.scrimColor.
// Drawer paints an animated scrim ColoredBox rather than a ModalRoute barrier.
// Use modalElevation: 0 to intentionally override M3 bottom-sheet 1dp.
// In the same centralized theme owner, configure:
// searchBarTheme: SearchBarThemeData(
//   elevation: WidgetStatePropertyAll(AppTokens.elevationLevel0),
//   shadowColor: const WidgetStatePropertyAll(AppTokens.transparent),
// ),
// drawerTheme: DrawerThemeData(scrimColor: approvedModalBarrier(...)),
// searchViewTheme: SearchViewThemeData(
//   elevation: AppTokens.elevationLevel0,
//   surfaceTintColor: AppTokens.transparent,
//   dividerColor: scheme.outline,
// ),
// bottomSheetTheme: BottomSheetThemeData(showDragHandle: false),
// AppBarTheme.iconTheme and .actionsIconTheme are BOTH set above.
// If an owner sets AppBarTheme.foregroundColor/iconTheme, it MUST also set actionsIconTheme.
// Direct routes (`DialogRoute`, `RawDialogRoute`, `ModalBottomSheetRoute`,
// `showGeneralDialog`, conditionally `showRawDialog`) require the approved
// Material overlay adapter passing `effects.modalBarrierColor` explicitly.
// Do NOT call `showAdaptiveDialog`/Cupertino modal helpers (incl. `showCupertinoSheet`)
// or `.adaptive` Material constructors in this baseline; never set ThemeData.platform.
// `Scaffold.drawerScrimColor` is prohibited outside that adapter.
// tooltipTheme: TooltipThemeData(
//   constraints: const BoxConstraints(minHeight: 32),
//   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//   textStyle: theme.textTheme.bodyMedium?.copyWith(
//      color: scheme.onInverseSurface,
//   ),
//   decoration: ShapeDecoration(
//     color: scheme.inverseSurface,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//   ),
// ),
// Replace numeric values shown in this sketch with the exact tokens from
// §1.2/§1.4 in production implementation. This is a NONRUNNABLE adapter sketch.
```

**[GATE]** Check effective AppBar states, both icon slots, SearchView expanded-state elevation/divider/shape, route-constructor bypasses and modal routes, not only `ThemeData` values. Foundation/theme files are the only locations allowed to specify raw transparency/elevation/alpha as part of approved token construction. Production callers must not pass literal barrier colors that bypass the themes.

### 9.1. Static restrictions

Apply to app and shared-widget source, **excluding explicitly allowlisted foundation/theme files**:

- Reject `Color(0x...)`, `Colors.*`, hardcoded `const Color.fromARGB(...)` or raw hex parsing.
- Reject `EdgeInsets.all(<number>)`, `EdgeInsets.symmetric(horizontal:<number>)`, `SizedBox(height:<number>)` for layout spacing unless authorized by component-specific generated specification.
- Reject `BorderRadius.circular(<number>)`, `Radius.circular(<number>)`, `TextStyle(fontSize:<number>)`, and uncontrolled `BoxShadow`. For durations, reject raw `Duration(milliseconds: ...)` **only when used as a visual/animation duration** (e.g. `AnimationController`, `Animated*`, page transitions); do **not** reject networking, debounce, retry, timeout or cache-expiry durations. A separate runtime/async timing policy can govern those if needed.
- Reject runtime `ColorScheme.fromSeed`, `colorSchemeSeed`, ad hoc `ThemeData` subtrees, and unapproved `ThemeData.copyWith` color changes in app code. Flag `AppBarThemeData.backgroundColor` when supplied as a plain `Color` rather than the approved state-resolver, and flag any literal `barrierColor`, `modalBarrierColor`, `surfaceTintColor` or `scrim` composition outside foundation/theme owners.
- **Overlay bypass rule (mandatory, app-authored code only; not Flutter framework internals):** prohibit direct `DialogRoute(...)`, `ModalBottomSheetRoute(...)`, `RawDialogRoute(...)`, `showGeneralDialog(...)`, and low-level `ModalRoute`/`PopupRoute` constructors **outside a small approved Material overlay adapter**. `showRawDialog(...)` is **D=Check@pinnedSDK**: source master has it, but enable a symbol-aware lint/test fixture only when available in the pinned SDK; when absent, record `NOT_APPLICABLE` and do not generate code importing a nonexistent API. Audit `Navigator.restorablePush` route builders too. The Material adapter MUST pass an explicit `barrierColor: effects.modalBarrierColor` for low-level routes and provide routing/semantics/state-restoration tests. Standard `showDialog` and `showModalBottomSheet` may use the theme-owned barrier, but app-layer explicit `barrierColor` overrides are banned. For custom routes with unusual barrier behavior, require an approved exception ID. Prohibit `Scaffold.drawerScrimColor` in regular screens because it takes priority over `DrawerThemeData.scrimColor`; any explicit override requires the audited adapter and an effective fully-open drawer-scrim test. Capture calls with AST (constructors/function invocations/named arguments); regex-only scanning is insufficient.
- **iOS/adaptive bypass rule (mandatory):** prohibit `showAdaptiveDialog`, `showCupertinoDialog`, `showCupertinoModalPopup`, `showCupertinoSheet`, direct `CupertinoDialogRoute`, `CupertinoModalPopupRoute`, `CupertinoSheetRoute`, related Cupertino modal-route helpers, **and the adaptive constructors `AlertDialog.adaptive`, `Switch.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`** in the **general Material baseline**, including the ordinary Material overlay adapter. Reject `ThemeData(platform: ...)` in production theme owners (it disables `TargetPlatformVariant`-based iOS tests). Keep any future approved Cupertino variant in an **independent** exception registry and code owner; mere explicit `barrierColor` on `showAdaptiveDialog` is never a valid exception because it is ignored on iOS/macOS. AST fixtures must resolve imported symbol identity (including import aliases), not just search source text. Do not ban `CupertinoPageRoute` or Cupertino utilities that render no §3 component; Cupertino visual controls inside shared widgets require the approved variant (§1.3c).
- **AppBar icon precedence rule (mandatory):** an `AppBarThemeData` that specifies `iconTheme` **or** `foregroundColor` must explicitly specify `actionsIconTheme`, with the approved action color `onSurfaceVariant`. Widget-level `AppBar` overrides must preserve the same contract either with `actionsIconTheme` or by proving effective inherited action color, and must be covered by a state/widget test. Reject unaudited override of action icon colors.
- For a production rule, prefer an AST-based `custom_lint`/analyzer plugin; text `rg`/grep is a **fast precheck only**, because regex also finds tests/comments and misses equivalent AST forms.
- Use a narrowly scoped allowlist with **file + rule ID + reason + owner + expiry/review date**, not blanket ignore files.

### 9.2. Automated testing matrix

| Gate | Assertion | Required modes |
|---|---|---|
| **Production root palette integration** | Pump actual root `App()`, drive `platformBrightness` + app `themeMode`, observe `Theme.of` inside shared widget(s), compare against independent approved snapshots | System light/dark + explicit light/dark preference |
| Role pairing | Independent token-pair contrast calculator: ALL title/body/label >=4.5, display/headline conditional >=3; `textContrastGuideline` supplementary | Light + dark |
| Surface tint independence | `ColorScheme.surfaceTint == colors.transparent` and effective AppBar/BottomSheet/other audited Material tint is transparent | Light + dark + representative routes |
| Top AppBar scrolled-under | Actual scroll toggles `surface`/level0 → `surfaceContainer`/level2; effective Material tint/shadow transparent | Normal + scrolled-under, light + dark |
| Modal barrier routing | Real Material dialog/sheet `ModalRoute.barrierColor`, real fully-open Drawer animated scrim == approved `effects.modalBarrierColor`; verify no direct-route/general-dialog bypass or `Scaffold.drawerScrimColor` override | Dialog + sheet + Drawer, light + dark; nested routes inventoried |
| Cross-platform modal gate | Prohibit adaptive/Cupertino modal shortcuts **and adaptive Material constructors**; on iOS (`TargetPlatformVariant`) production Material dialog stays `DialogRoute`, uses approved barrier, and its content contains no Cupertino substitute; AST negatives for Cupertino and `.adaptive` symbols | Android + iOS (if supported), light + dark, nested/restorable routes |
| Component contract | Background, foreground, shape, border width, padding, elevation, shadow/tint and states match registry; SearchBar + SearchView overrides, AppBar 2 icon slots, ListTile selection/disabled, no sheet handle explicit | Each variant + relevant states |
| Input error/disabled detail | Filled disabled underline `onSurface@0.38` vs outlined disabled border `onSurface@0.12`; error+focus/hover stroke and suffix icon colors exact | Filled/outlined normal, focused, hovered, error, disabled |
| SearchAnchor expanded view | `SearchViewThemeData.elevation=0`, divider `outline`, transparent view tint, fullscreen/anchored shape; separate nondimming route barrier | Fullscreen + anchored, 320/390, light/dark |
| AppBar anatomy/scope | Leading icon `onSurface`, actions icon `onSurfaceVariant`; Scaffold.appBar observer required, Sliver variants unsupported by this contract | Normal/scrolled-under, light/dark |
| Android tap targets | `meetsGuideline(androidTapTargetGuideline)` (48×48) | Default text scale + representative scaled mode |
| iOS tap targets | `meetsGuideline(iOSTapTargetGuideline)` (44×44); product 48×48 target is stricter | **Required when shipping iOS** |
| Semantic labels | `meetsGuideline(labeledTapTargetGuideline)` | All actionable components |
| Text contrast | `meetsGuideline(textContrastGuideline)` | Light + dark, with noted limitations |
| Narrow layout | No Flutter overflow, no clipped critical content | Width 320 |
| Reference phone | Golden matches reviewed baseline | Width 390 |
| Wide mobile/tablet | Responsive policy stable; no oversized text rows | Width 600 |
| Large text | No loss of controls or semantic information | Scale 2.0 at width 320 |
| Dark mode | No incorrect hardcoded light colors; state visibility preserved | All high-priority components |
| High contrast handling | Explicit product choice `SUPPORTED` vs `FALLBACK`; verify `highContrastTheme`/`highContrastDarkTheme` through production App root | **D=Check until DSD-32 approved** |
| Text scaling behavior | Account for pinned SDK NavigationBar/AppBar label scale caps, button icon-label spacing and fractional line heights; no clipping | 320/390 at 1.0 and 2.0 |
| Elevated interaction | Filled/ElevatedButton and FAB hover/pressed/focused effective elevation matches `frameworkM3@SDK` state policy | Web pointer simulation where applicable; mobile default |
| Gesture/keyboard | Focus, back, swipe alternatives, insets; sheet drag-handle disabled, optional variant separately approved | Relevant components |
| Cross-component hierarchy | CTA/FAB/AccentPanel count constraints hold | Representative screen compositions |

Proposed golden contexts: `320×800 @1.0 light`, `320×800 @2.0 light`, `320×800 @2.0 dark`, `390×844 @1.0 light`, `390×844 @1.0 dark`, `600×960 @1.0 light`. **Before all multilingual goldens**, load the **real app primary font and Vietnamese/Korean fallback fonts** with `FontLoader`/project font-test setup (and verify the assets resolve); otherwise the Flutter default Ahem test font can produce meaningless square glyphs. Pin the CI **OS, Flutter version, font files/checksums, locale, device pixel ratio and text scaler**, and do not compare cross-OS glyph rasterization as if pixel-identical. Golden update requires reviewed visual diff; `--update-goldens` is not automatic approval.

**Insets-specific gate:** With and without keyboard (`viewInsets.bottom > 0`), assert CTA remains reachable, is not double-offset by safe area, and scrollable form content can be focused. Test gesture-navigation padding and a zero-bottom-inset device separately. **`tester.view.viewInsets` takes physical pixels:** scale any simulated logical IME height by `tester.view.devicePixelRatio`, then call `addTearDown(tester.view.reset)` to restore the test view.

### 9.2a. Strict token-pair contrast gate (normative, independently testable)

The app's `title*`/`body*`/`label*` **4.5:1** policy must be asserted by a deterministic test independent of `textContrastGuideline`. The contrast fixture is an approved list of `(foregroundRole, backgroundRole, textCategory, state)` pairings actually authorized in §3 and §5 for *light and dark*. The test derives the two colors from the independent approved 45-role palette snapshot rather than from theme values built during the test. It must fail with **pair name, brightness, calculated ratio, required threshold**. Example algorithm:

```dart
import 'dart:math' as math;

double contrastRatio(Color a, Color b) {
  // Pair fixture for direct role colors must be opaque. Alpha-based state
  // colors require prior compositing against the actual backing surface.
  assert(a.a == 1 && b.a == 1);
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

// Example per-pair, light and dark:
// final ratio = contrastRatio(approved['onSurface']!, approved['surface']!);
// expect(ratio, greaterThanOrEqualTo(4.5), reason: '...pair...');
```

The authorized pair fixture must enumerate `onSurface`/surface variants, `onPrimary`/`primary`, `onSecondaryContainer`/`secondaryContainer`, `onInverseSurface`/`inverseSurface`, `onError`/`error` and **every other actually used text/container pairing**; do not assume this example list is exhaustive. Status and disabled alpha components need composited-color tests. Separately execute `meetsGuideline(textContrastGuideline)` for rendered detection, recognizing that its large-text logic is more permissive than this baseline for `titleLarge`.

### 9.3. Production-root palette integration gate (adapter sketch)

**Compare exactly 45 M3 semantic getters by name.** `ColorScheme.operator ==` is inappropriate for this gate because it additionally compares `brightness`, `surfaceTint` and deprecated compatibility getters. The independent approved fixture contains only **45 role names and expected `Color` values**; do not build it from `AppTheme` at test runtime. Assert scheme brightness separately, and **always** assert `scheme.surfaceTint == colors.transparent` with its own diagnostic (outside the named 45-role comparison). Source: Flutter `ColorScheme.operator ==`.

**Wrapper contract:** Pump the same production `App`/`AppRouter` root used by the real application. Permitted *outer* test wrappers: `ProviderScope(overrides: ...)` (Riverpod), `MultiProvider`/DI scope, test `GetIt` registrations, locale/test-service adapters, and the app's normal production bootstrap wrapper. They may replace external services or seed theme preference **through the real provider**. Forbidden substitutes: a test-created `MaterialApp`, `CupertinoApp`, `WidgetsApp`, `Theme(data: ...)`, synthetic `MediaQuery(data: ...)`, recreated `ThemeData`, or copied routing/theme wiring. If real production bootstrapping contains a `ProviderScope`, preserve that ownership or provide a documented provider override hook; never insert a second conflicting scope. **Framework test window/view controls used solely to simulate brightness, size, keyboard insets and target platform (`TargetPlatformVariant` / `debugDefaultTargetPlatformOverride`) are allowed**, provided they do not inject an alternate theme or palette.

The following is an **adaption sketch**. Replace imports, service providers and navigation adapter with actual symbols, and verify compilation on the pinned SDK. It is deliberately written with dependency injection **outside** the production app while preserving its `MaterialApp.router` wiring.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Example assumes a Riverpod app. Import flutter_riverpod and real providers
// in the project. For other DI systems, use an equivalent production wrapper.
// Import App, AppButton and the independently approved fixture in test/fixtures.

Map<String, Color> m3RoleColors(ColorScheme s) => {
  'primary': s.primary,
  'onPrimary': s.onPrimary,
  'primaryContainer': s.primaryContainer,
  'onPrimaryContainer': s.onPrimaryContainer,
  'primaryFixed': s.primaryFixed,
  'primaryFixedDim': s.primaryFixedDim,
  'onPrimaryFixed': s.onPrimaryFixed,
  'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
  'secondary': s.secondary,
  'onSecondary': s.onSecondary,
  'secondaryContainer': s.secondaryContainer,
  'onSecondaryContainer': s.onSecondaryContainer,
  'secondaryFixed': s.secondaryFixed,
  'secondaryFixedDim': s.secondaryFixedDim,
  'onSecondaryFixed': s.onSecondaryFixed,
  'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
  'tertiary': s.tertiary,
  'onTertiary': s.onTertiary,
  'tertiaryContainer': s.tertiaryContainer,
  'onTertiaryContainer': s.onTertiaryContainer,
  'tertiaryFixed': s.tertiaryFixed,
  'tertiaryFixedDim': s.tertiaryFixedDim,
  'onTertiaryFixed': s.onTertiaryFixed,
  'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
  'error': s.error,
  'onError': s.onError,
  'errorContainer': s.errorContainer,
  'onErrorContainer': s.onErrorContainer,
  'surface': s.surface,
  'onSurface': s.onSurface,
  'surfaceDim': s.surfaceDim,
  'surfaceBright': s.surfaceBright,
  'surfaceContainerLowest': s.surfaceContainerLowest,
  'surfaceContainerLow': s.surfaceContainerLow,
  'surfaceContainer': s.surfaceContainer,
  'surfaceContainerHigh': s.surfaceContainerHigh,
  'surfaceContainerHighest': s.surfaceContainerHighest,
  'onSurfaceVariant': s.onSurfaceVariant,
  'outline': s.outline,
  'outlineVariant': s.outlineVariant,
  'shadow': s.shadow,
  'scrim': s.scrim,
  'inverseSurface': s.inverseSurface,
  'onInverseSurface': s.onInverseSurface,
  'inversePrimary': s.inversePrimary,
};

void expectM3Roles(
  ColorScheme actual,
  Map<String, Color> independentlyApprovedFixture,
) {
  final observed = m3RoleColors(actual);
  expect(observed.length, 45, reason: '45 M3 role getters required');
  expect(independentlyApprovedFixture.length, 45,
      reason: 'Fixture must declare all 45 roles');
  expect(independentlyApprovedFixture.keys.toSet(), observed.keys.toSet(),
      reason: 'Missing/extra approved role names');

  final mismatches = <String>[];
  for (final role in observed.keys) {
    final expected = independentlyApprovedFixture[role];
    if (observed[role] != expected) {
      mismatches.add('$role: observed=${observed[role]}, approved=$expected');
    }
  }
  expect(mismatches, isEmpty,
      reason: 'Production descendant ColorScheme mismatches by role:\n'
          '${mismatches.join('\n')}');
}

void main() {
  final cases = <({ThemeMode preference, Brightness os, Brightness expected})>[
    (preference: ThemeMode.system, os: Brightness.light, expected: Brightness.light),
    (preference: ThemeMode.system, os: Brightness.dark, expected: Brightness.dark),
    (preference: ThemeMode.light, os: Brightness.dark, expected: Brightness.light),
    (preference: ThemeMode.dark, os: Brightness.light, expected: Brightness.dark),
  ];

  for (final scenario in cases) {
    testWidgets(
      'production 45 roles: pref=${scenario.preference.name}, '
      'os=${scenario.os.name}',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = scenario.os;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        // Example Riverpod adapter: preserve production root + provider wiring.
        // Use overrides for the REAL theme-preference provider, plus fake
        // network/database dependencies; do not construct a MaterialApp here.
        await tester.pumpWidget(
          ProviderScope(
            overrides: productionTestOverrides(scenario.preference),
            child: const App(),
          ),
        );
        await navigateToProductionScreenWithAppButton(tester);
        await tester.pumpAndSettle();

        final appButton = find.byType(AppButton);
        expect(appButton, findsWidgets);
        final inside = find.descendant(
          of: appButton.first,
          matching: find.byType(Text),
        );
        expect(inside, findsWidgets);
        final theme = Theme.of(tester.element(inside.first));
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, scenario.expected);
        expect(theme.colorScheme.brightness, scenario.expected);

        final approved = scenario.expected == Brightness.light
            ? ApprovedPaletteSnapshot.light45
            : ApprovedPaletteSnapshot.dark45;
        expectM3Roles(theme.colorScheme, approved);
        // REQUIRED independent 46th policy check (not in 45-role fixture):
        expect(theme.colorScheme.surfaceTint, Colors.transparent,
            reason: 'surfaceTint leakage: AppBar can fall back to primary');
      },
    );
  }
}
```

The test is **not runnable unchanged**, since `productionTestOverrides`, the DI import, route adapter, and palette fixture are project-specific. It must not be counted as a passing gate until these adapters are implemented and tested in the actual repository. Theme modes are driven through real provider overrides (or normal persisted preference), not by replacing `MaterialApp` in tests.

**High-contrast extension:** After DSD-32 is resolved, extend the production-root scenario matrix with platform highContrast true/false × OS light/dark × applicable theme preferences; on Flutter tests use supported platform accessibility flags and the production `MaterialApp`'s `highContrastTheme`/`highContrastDarkTheme` wiring. `SUPPORTED` requires **independent** high-contrast 45-role fixtures; `FALLBACK` verifies exactly the documented fallback to light/dark and has explicit accessibility limitations. Until then mark this lane `D=Check`, not `PASS`.

**Coverage expansion:** Run the same 45-role probe for real descendants in shared widgets on all major routes, dialogs, modal sheets, navigation surfaces and nested navigators. The root view alone cannot detect local `Theme(data: ...)` overrides. Add a static AST rule that prohibits unapproved color-scheme-changing nested themes; a widget may legitimately scope typography or component themes provided the 45 approved color roles remain unchanged.

Further integration gates: role-pair contrast tests, **mandatory transparent `surfaceTint` and effective component tint checks**, route-level scrim-opacity/barrier-compositing tests after approval, and independently reviewed fixture updates. The test suite must produce a named per-role mismatch for a deliberately corrupted `Theme` and fail if a production route injects `colorSchemeSeed` or a wrong `darkTheme`.

### 9.3a. Effective AppBar and route-barrier test contract

**Top AppBar scrolled-under:** pump the **production app** with the allowed DI wrapper (§9.3), navigate to an actual scrolling route, and record the AppBar's own outer `Material` properties while the scroll offset is 0. Scroll the underlying `Scrollable` until `WidgetState.scrolledUnder` is triggered, then re-read them. Do not merely inspect `AppBarThemeData`; the contract must assert:

| State | `Material.color` | `Material.elevation` | `Material.surfaceTintColor` | `Material.shadowColor` |
|---|---|---:|---|---|
| normal | `scheme.surface` | `0.0` | `colors.transparent` | `colors.transparent` |
| scrolled-under | `scheme.surfaceContainer` | `3.0` | `colors.transparent` | `colors.transparent` |

Resolve the **AppBar-owned Material**, not a descendant button's Material or a parent Scaffold. Also inspect a scrolled-under golden to prove the background treatment actually changed. Perform light/dark tests. If `notificationPredicate` or scroll nesting changes state detection, fix the production widget wiring.

**Modal route barrier AND Drawer (Material-only baseline on iOS too):** open the real production dialog/sheet through its production action, and open the real Scaffold Drawer through its navigation action. Within each open overlay, obtain its route (e.g. `ModalRoute.of(tester.element(dialogContentFinder))`) and compare its `barrierColor` directly to `expectedBarrier = approvedScheme.scrim.withValues(alpha: ApprovedEffects.scrimOpacity)`. For a modal sheet also assert `route is ModalBottomSheetRoute` and check the modal sheet's **effective** 0dp elevation and transparent tint/shadow. For a dialog, assert a Material `DialogRoute` and check its configured barrier. **Drawer is not a `ModalRoute`:** assert `DrawerTheme.of(drawerContext).scrimColor == expectedBarrier` and inspect the opened Drawer scrim `ColoredBox` after animation settles; do not call `ModalRoute.barrierColor` for Drawer. A manual overlay golden supplements the effective-colored-box assertion and must show no accidental default black54. Assert `barrierColor != Colors.black54` **only when the approved expected barrier differs from black54**; otherwise value equality alone cannot prove it didn't arrive via fallback. Audit the actual non-null theme/route parameter wiring with static checks as well. Do **not** assert the animated barrier's transient alpha immediately after route push: wait for settle before the pixel/golden comparison, while route `barrierColor` can be inspected independently.

The sketches below are **adapter pseudocode** and require real project finders, route launchers and SDK-pinned types:

```dart
// After opening production dialog or bottom-sheet overlay (light and dark cases):
final route = ModalRoute.of(tester.element(overlayContentFinder));
expect(route, isNotNull);
final expected = approvedScheme.scrim.withValues(
  alpha: ApprovedEffects.scrimOpacity, // blocked until DSD-02 approval
);
expect(route!.barrierColor, expected,
    reason: 'Overlay route bypasses approved theme barrier');

// After navigating to a real production scrolling screen:
// 1. Locate AppBar's own Material (not a child action Material).
// 2. Record color/elevation/tint/shadow in initial state.
// 3. Scroll the real Scrollable until AppBar notices scrolled-under.
// 4. Re-read the same kind of Material and assert the state table.
```

**Additional v2.6.1 targeted assertions (includes v2.5/v2.6 gates):**

1. Render an **actual** `SearchAnchor.bar`, open its SearchView, and resolve the expanded view `Material`: elevation 0, tint transparent, divider `outline`, shape token depending on fullscreen/anchored mode. The SearchView route is a deliberate transparent-barrier navigation exception; it must not be mistaken for a modal dimming failure.
2. In a real `Scaffold.appBar` descendant, resolve leading and action icon themes separately; confirm `onSurface` versus `onSurfaceVariant` before and after scrolling. Ensure a `SliverAppBar` does not pass this test by virtue of being a toolbar.
3. Assert actual `InputDecorator` disabled BorderSide colors independently: filled underline `effects.disabledForeground` (alpha .38), outlined border `effects.disabledOutline` (alpha .12). Verify error+focused border width 2, error+hovered `onErrorContainer`, suffix error icon color and the selected ListTile subtitle/disabled theme coloring.
4. Run analyzer AST **negative fixtures** constructing direct `DialogRoute`, `RawDialogRoute`, `ModalBottomSheetRoute`, `showGeneralDialog`, `Scaffold.drawerScrimColor`, **`showAdaptiveDialog`, `showCupertinoDialog`, `showCupertinoModalPopup`, `showCupertinoSheet`, `CupertinoDialogRoute`, `CupertinoModalPopupRoute`, `CupertinoSheetRoute`, `AlertDialog.adaptive`, `Switch.adaptive`, `Checkbox.adaptive`, `Radio.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`**, a production `ThemeData(platform: ...)`, plus an aliased Cupertino import and a `Navigator.restorablePush` builder; **each available prohibited API must fail** in app code outside its approved owner. For **`showRawDialog`**, run the negative fixture **only when that symbol exists in the pinned SDK**, otherwise mark `NOT_APPLICABLE` and compile no references to it. Run **positive fixtures** for `showDialog`/`showModalBottomSheet` using theme-owned barriers and approved Material adapter routes with explicit `effects.modalBarrierColor`. Add an **iOS runtime** case (`variant: TargetPlatformVariant.only(TargetPlatform.iOS)` on the real production root; never inject `ThemeData.platform` or a synthetic MaterialApp) proving the effective route is Material and its `barrierColor` equals the approved token, without falling back to Cupertino's default. The iOS case is conditionally required if iOS shipping is in scope; otherwise record platform exclusion in DSD-39.
5. Run a widget/theme assertion where both `AppBarTheme.iconTheme` and `AppBarTheme.foregroundColor` are overridden by the approved owner; the leading icon must remain `onSurface`, actions icon must remain `onSurfaceVariant` via an explicitly set `actionsIconTheme`. Add a negative fixture that omits `actionsIconTheme` and confirm the AST rule rejects it. Exercise a widget-level AppBar override and verify effective actions color. 
6. Render an `AppListItem` in normal, selected, disabled, and disabled+selected states; assert effective title/subtitle/leading/trailing colors against §3.1, check that the two state-resolving `WidgetStateColor` values take disabled precedence, and verify disabled controls are not tappable. Disabled+selected expects the `secondaryContainer` tile, `effects.disabledForeground` for every text/icon slot, and semantics `selected=true, enabled=false`.
7. Under `TargetPlatformVariant.only(TargetPlatform.iOS)`, open every production dialog and render every shared selection control; assert no `CupertinoAlertDialog`, `CupertinoSwitch`, `CupertinoCheckbox`, `CupertinoRadio`, `CupertinoSlider` or `CupertinoActivityIndicator` appears inside shared widgets, and compare iOS goldens of dialog content with the Material contract. This catches `AlertDialog.adaptive` inside `showDialog`, which passes the route-barrier assertion alone.

**Approval condition:** tests for route barriers are defined but cannot pass until DSD-02 has approved actual light/dark scrim colors and opacity. Screenshot tests complement property assertions; they do not replace them. In particular, 1dp elevation with transparent shadow and tint may be visually indistinguishable from 0dp, but the numeric policy still needs a test.

### 9.3b. Keyboard/safe-area layout contract

- Input form CTA placement is **exactly** `layout.formCtaSlot = body.scrollEnd` (§6.5), not a `Scaffold.bottomNavigationBar` button. The CTA and fields are in a scrollable `Scaffold.body` with `resizeToAvoidBottomInset: true`; it must remain scroll-to-reachable with keyboard open.
- The token `layout.bottomActionSafePadding = MediaQuery.paddingOf(context).bottom + space.4` is reserved for a separately approved **sticky footer** pattern where one parent owns that bottom gap. A form's scroll-end CTA uses the body scroll padding policy instead; do not apply both.
- If the form scroll body already uses `SafeArea`, do not add a second manual system inset. Simulate keyboard by controlling the test view's `viewInsets`; do not synthesize a new `MediaQuery(data: ...)` around the production app.
- **Physical-pixel adapter, not logical dp:** `final keyboardPhysical = keyboardLogical * tester.view.devicePixelRatio; tester.view.viewInsets = FakeViewPadding(bottom: keyboardPhysical); addTearDown(tester.view.reset);` (then `await tester.pump()`). For example, a **300 logical pixel** IME at DPR 3 must set **900 physical pixels**, not 300. Exercise a non-1 DPR scenario and ensure no test state leaks across cases.
- Tests cover focus on the last field, `ensureVisible(CTA)`, actual hit-testing above the IME, 320dp width, 2.0 text scaling, gesture navigation padding and zero bottom inset.

### 9.3c. Text metrics and scaled-layout test precision

At system `TextScaler.linear(2.0)`, **do not require a 2.0x label size for every framework widget**: `NavigationBar` destination labels can clamp around 1.3 and AppBar titles around 1.34 in master; button icon-label gaps may contract from 8 to 4. These are **`frameworkM3@SDK` delegated behaviors** (DSD-23), not permission to change the application's typography scale globally. Test usable bounds, clipped essential text and semantic visibility, not naïve global 2× metrics. If a metric assertion is needed, use tolerant floating comparisons rather than exact integer rounding (`fontSize × height` can result in 63.84). Golden CI must load approved fonts and pin OS/SDK/scaler.

### 9.4. Quality gates and approval

**Blocked if any of:** missing approved 45-role palette/scrim-alpha when modal barriers are in scope, missing pinned SDK verification, missing explicit transparent `surfaceTint` declaration/assertion, AppBar scrolled-under contract failure, missing Dialog/BottomSheet/Drawer theme scrim wiring or effective route/drawer scrim test, adaptive/Cupertino modal bypass or overlay bypass via unapproved route constructor, missing AppBar action-icon precedence test, missing SearchView elevation override when SearchAnchor is used, Critical UI/accessibility violations, unreviewed theme override, unresolved design conflict, or missing relevant component-state test.

**Major:** mismatch in component role mapping, repeated arbitrary radii/spacing, double padding, competing primary CTA, or golden diff not reviewed.

**Minor:** purely optical alignment issues that do not affect access/action.

**Design review:** design gallery shows anatomy, variants, light/dark, selected/error/loading/disabled, long Vietnamese/Korean strings and narrow width. Visual HTML is **only** an artifact for review; it cannot attest to Flutter touch semantics, rendering or keyboard behavior.

## 10. Design Decision Registry (DSD) with traceability

| ID | Decision | Status now | Owner role | Enforced by |
|---|---|---|---|---|
| DSD-01 | Material 3 Standard baseline | Proposed | Design Lead | SDK/theming review |
| DSD-02 | Manual approved Light/Dark 45-role scheme + opaque scrim and `effects.scrimOpacity` | **Blocked by palette/scrim approval** | Design Lead | Independent 45-role fixture + independent surfaceTint check + scrim composition + actual-route barrier tests |
| DSD-03 | Color mapping per component state | Proposed | Design+Flutter | Theme/widget tests |
| DSD-04 | Color role interaction/screen emphasis | Proposed | Design Lead | Composition tests + review |
| DSD-05 | One CTA / one FAB / one large accent panel | Proposed | Product+Design | Widget composition checks |
| DSD-06 | Status semantic extensions | Not started | Design Lead | ThemeExtension/contrast |
| DSD-07 | Spacing tokens 0/4/8/12/16/24/32/48 | Proposed | Design Lead | Static lint |
| DSD-08 | Internal component padding | Proposed | Flutter Lead | Widget bounds tests |
| DSD-09 | External gap and grouping | Proposed | Design+Flutter | Layout tests |
| DSD-10 | Phone gutter, keyboard, safe area and `body.scrollEnd` form CTA | Proposed | Flutter Lead | Keyboard-open/closed, 320/390 goldens + CTA placement and hit-test |
| DSD-11 | Touch target and component size | Proposed | Flutter+A11y | Accessibility tests |
| DSD-12 | M3 TextTheme with full metrics | Proposed | Design+Flutter | Typography snapshot |
| DSD-13 | Icon family and semantic icon usage | Proposed | Design Lead | Asset lint + semantics |
| DSD-14 | Shape scale and component mapping | Proposed | Design Lead | Static lint + golden |
| DSD-15 | Border/elevation.level0–5 and state-specific elevation; modal sheet intentionally level0 override | Proposed | Design Lead | Component theme + effective elevation and shadow/tint tests + golden |
| DSD-16 | Visual hierarchy and density | Proposed | Product+Design | Design review |
| DSD-17 | Component variants, API ownership | Proposed | Flutter Lead | Component API tests |
| DSD-18 | State matrix | Proposed | Flutter Lead | State transition tests |
| DSD-19 | M3 Durations/Easing for custom motion | Proposed | Flutter Lead | Static lint + animation tests |
| DSD-20 | Contrast, accessibility, locale | Proposed | A11y+Flutter | A11y/localization tests |
| DSD-21 | Responsive mobile layouts | Proposed | Flutter Lead | 320/390/600 goldens |
| DSD-22 | Review and approval gates incl. font-loaded goldens | Proposed | QA+Design | Pinned CI + visual signoff |
| DSD-23 | Flutter SDK/source version pinning; Slider/ProgressIndicator `year2023` appearance, Slider inactive track, TabBar divider, state elevation/text clamps, `showRawDialog` availability | **Blocked until SDK supplied** | Flutter Lead | `flutter --version` + lockfile + exact-theme snapshots |
| DSD-24 | Approved-project conflict resolution | Mandatory gate | Product+Design | Conflict ledger/signoff |
| DSD-25 | Input form CTA slot (`body.scrollEnd`) | Proposed | Product+Flutter | Production screen widget test with physical-pixel IME simulation and scroll |
| DSD-26 | Normal/scrolled-under AppBar state mapping `surface`/0 → `surfaceContainer`/3 | Proposed | Design+Flutter | `WidgetStateColor` theme resolver + effective Material state test/golden |
| DSD-27 | Explicit `ColorScheme.surfaceTint = transparent` on both palettes | Proposed policy, pending DSD-02 fixture | Design Lead | Separate 46th assertion + effective tinted-Material audit |
| DSD-28 | Modal dialog/sheet **and Drawer** scrim from approved scrim + opacity | Blocked by DSD-02 values | Design+Flutter | Dialog/BottomSheet/Drawer themes + real route barrier and Drawer effective scrim tests |
| DSD-29 | NavigationDrawer indicator anatomy, ListTile default vs wrapper selection/padding/disabled and disabled+selected (`WidgetStateColor`) | Proposed | Design+Flutter | M3 source audit + state-resolver/wrapper widget tests |
| DSD-30 | SearchBar and expanded SearchView flat elevation=0 (both override separate source defaults of 6dp) | Proposed | Design+Flutter | SearchBarThemeData + SearchViewThemeData + effective Material tests |
| DSD-31 | Input anatomy (filled disabled underline @0.38, normal/focused stroke widths, error+hover/focus), toggle IconButton, Tooltip, Snackbar | Proposed; source-verified on master, requires SDK pin | Flutter Lead | Component-theme state/golden tests |
| DSD-32 | High contrast strategy `SUPPORTED` vs `FALLBACK` | **D=Check (product decision)** | Product+A11y | MaterialApp high-contrast integration matrix and contrast fixtures as applicable |
| DSD-33 | Strict 4.5:1 title/body/label independent token-pair gate; `textContrastGuideline` supplemental | Proposed | A11y+Flutter | Independent contrast fixture script + widget guidelines |
| DSD-34 | AppBar leading vs actions icon colors, mandatory actionsIconTheme when iconTheme/foregroundColor overridden, Scaffold.appBar scope, SliverAppBar excluded | Proposed | Design+Flutter | Two-icon effective theme tests, AST precedence rule + negative fixture, Scaffold scroll test |
| DSD-35 | Material route-bypass prevention for DialogRoute, RawDialogRoute, general/raw dialogs (showRawDialog SDK-conditional), modal sheet route, drawerScrimColor | Proposed | Flutter Lead | Symbol-aware AST rule + adapter audit + real Material route/drawer scrim tests |
| DSD-36 | SearchViewTheme elevation=0, divider=outline, fullscreen/anchored shapes; transparent non-dimming route barrier exception | Proposed | Design+Flutter | Expanded SearchAnchor.bar widget test/golden, 320dp layout |
| DSD-37 | BottomSheet drag handle disabled; handle-enabled variant separate approval | Proposed | Design+Flutter | BottomSheetThemeData.showDragHandle=false + modal interaction tests |
| DSD-38 | `stroke.inputNormal`/`stroke.inputFocused` and enabled/error/disabled border colors | Proposed | Flutter Lead | InputDecorator effective border + golden state matrix |
| DSD-39 | Material modal and control baseline on iOS; adaptive/Cupertino modal helpers/routes (incl. `showCupertinoSheet`) and adaptive Material constructors (`AlertDialog.adaptive`, `Switch.adaptive`, …) forbidden without separately approved design contract; iOS tested via `TargetPlatformVariant` | Proposed | Product+Flutter | AST deny rules, Android/iOS production-root Material-route barrier test, restoration fixture |

A real registry must additionally store `proposedValue`, `approvedValue`, `sourceReference`, `date`, `decisionOwner`, `reviewer`, `testPath`, `exceptionId`, and `supersedes` fields. Owner roles are proposals; do not claim assigned people.

## 11. Existing-project adoption protocol (no project-specific assumptions)

This document is a **general baseline**. It does **not** declare that any particular existing project uses border-first styling, fixed primary HEX across brightness modes, or a specific shape scale. Those are **not** facts in this baseline and must never silently influence another project.

If adopted into an existing design system, first retrieve its actually approved decisions and token registry, then open a project-specific **external conflict ledger**. Do not embed invented or previously remembered conflicts inside this baseline.

| Field | Required value |
|---|---|
| `conflictId` | Project-specific stable ID |
| `existingApprovedReference` | Actual file/decision ID and approved property |
| `proposedBaselineReference` | v2.6.1 section/row/token |
| `comparison` | Exact existing value vs proposed value |
| `resolution` | `KEEP_EXISTING`, `CHANGE_PROPOSED`, `BLOCKED`, `NOT_APPLICABLE` |
| `owner` | Named accountable owner role/person after assignment |
| `evidence` | Screenshot, source test, contrast/visual diff |
| `approval` | Explicit signoff before implementation |

Process: read actual approved decisions -> property-by-property diff -> classify -> request signoff for `CHANGE_PROPOSED` -> implement and test -> update registry. Until approval, **existing approved decisions win**. In a new greenfield project with no existing approvals, this conflict step is not applicable.

## 12. Component acceptance template

For each `<Component>/<Variant>`, store:

1. **Purpose & when to use/avoid** (one sentence each).
2. **Anatomy**: exact child slots, min sizes, order, interactive surface.
3. **Role map**: background, text, icon, border, indicator for each relevant state; **one token per cell**.
4. **Metrics**: shape token, padding H/V token, internal-gap token, min visual size token, tap bounds.
5. **Text & icons**: text role, icon size/family, overflow/long-text rule.
6. **Behavior**: callbacks, keyboard/back/screen-reader behavior, loading/error handling.
7. **Theme implementation**: Flutter default match vs override by named ThemeData field; include effective elevation, surfaceTint, normal/scrolled-under AppBar, and dialog/bottom-sheet route barrier plus drawer scrim configuration.
8. **Tests**: state test, tap/labels/contrast tests, dark/light + narrow/large-text goldens.
9. **Compatibility**: pinned SDK revision, existing design decisions, conflict link.
10. **Approval**: owner, reviewer, status and evidence.

A component is not `Approved` if a required property (including elevation, AppBar state/tint, route barrier, scrim opacity and keyboard-aware action slot where applicable) is unresolved or says "8–12", "surface or primary", "depending on design", or "similar to existing". Convert the ambiguity into an explicit variant with fixed tokens, or block it as `UNRESOLVED`.

## 13. Official source references, verification notes

- Flutter ColorScheme (45 roles): https://api.flutter.dev/flutter/material/ColorScheme-class.html
- Flutter ThemeData creation, seed versus explicit: https://api.flutter.dev/flutter/material/ThemeData/ThemeData.html
- FilterChip source, flat default `outlineVariant`, 8dp shape: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/filter_chip.dart
- IconButton source, selected standard `primary`/transparent: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/icon_button.dart
- Tooltip source, fallback grey/white: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/tooltip.dart
- Flutter TextTheme (size/height/weight/spacing): https://api.flutter.dev/flutter/material/TextTheme-class.html
- Flutter M3 motion durations: https://api.flutter.dev/flutter/material/Durations-class.html
- Flutter M3 easing: https://api.flutter.dev/flutter/material/Easing-class.html
- Flutter OutlineInputBorder default shape: https://api.flutter.dev/flutter/material/OutlineInputBorder/OutlineInputBorder.html
- Flutter PopupMenu M3 4dp shape (generated defaults): https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/popup_menu.dart
- Flutter NavigationBar selected icon/label distinction: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/navigation_bar.dart
- Flutter TabBar primary/secondary color + 1dp outlineVariant divider: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/tabs.dart
- Flutter InputDecorator M3 idle/active indicator colors: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/input_decorator.dart
- Flutter `InputDecoration.filled` defaults to false: https://api.flutter.dev/flutter/material/InputDecoration/filled.html
- Flutter Snackbar M3 inverse roles and default fixed behavior: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/snack_bar.dart
- Flutter test platform brightness override: https://api.flutter.dev/flutter/flutter_test/TestPlatformDispatcher/platformBrightnessTestValue.html
- Flutter floating SnackBar default shape: https://api.flutter.dev/flutter/material/SnackBar/shape.html
- Flutter test accessibility matcher: https://api.flutter.dev/flutter/flutter_test/meetsGuideline.html
- WCAG large-text exception: https://www.w3.org/WAI/WCAG22/Techniques/general/G145
- WCAG non-text contrast: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast

- Flutter ColorScheme equality (compares compatibility fields beyond 45): https://api.flutter.dev/flutter/material/ColorScheme/operator_equals.html
- Flutter NavigationBar elevation default 3: https://api.flutter.dev/flutter/material/NavigationBar/elevation.html
- Flutter NavigationDrawer elevation default 1: https://api.flutter.dev/flutter/material/NavigationDrawer/elevation.html
- Flutter FAB elevation default 6: https://api.flutter.dev/flutter/material/FloatingActionButton/elevation.html
- Flutter Snackbar elevation default 6: https://api.flutter.dev/flutter/material/SnackBar/elevation.html
- Flutter M3 Slider year2023 appearance switch: https://docs.flutter.dev/release/breaking-changes/updated-material-3-slider
- Flutter M3 ProgressIndicator year2023 appearance switch: https://docs.flutter.dev/release/breaking-changes/updated-material-3-progress-indicators
- Flutter Scaffold body keyboard resize: https://api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomInset.html
- Flutter iOS minimum tap guideline: https://api.flutter.dev/flutter/flutter_test/iOSTapTargetGuideline-constant.html

- Flutter AppBar actual state/elevation/color/tint fallback: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/app_bar.dart
- Flutter BottomSheet generated M3 defaults + modal route barrier fallback: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/bottom_sheet.dart
- Flutter `showDialog` theme-barrier/black54 fallback: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/dialog.dart
- Flutter `ColorScheme.surfaceTint` fallback to primary: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/color_scheme.dart
- Flutter `FlutterView.viewInsets` source of physical-pixel semantics: https://api.flutter.dev/flutter/dart-ui/FlutterView/viewInsets.html
- Flutter test `TestFlutterView.reset`: https://api.flutter.dev/flutter/flutter_test/TestFlutterView/reset.html

- Flutter SearchBar defaults (elevation 6, shadow role, search style): https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/search_anchor.dart
- Flutter NavigationDrawer indicator, label roles and container: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/navigation_drawer.dart
- Flutter Drawer animated scrim and `DrawerTheme.scrimColor`: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/drawer.dart
- Flutter ListTile directional default contentPadding and selected text/icon: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/list_tile.dart
- Flutter Tooltip mobile 32dp minHeight and H16/V4 defaults: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/tooltip.dart
- Flutter LinearProgressIndicator 2023 and 2024 `secondaryContainer` track: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/progress_indicator.dart
- Flutter `SearchViewThemeData` generated SearchView 6dp independent elevation: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/search_anchor.dart
- Flutter `showGeneralDialog` / `RawDialogRoute` raw barrier defaults: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/widgets/routes.dart
- Flutter DialogRoute direct `Colors.black54` fallback: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/dialog.dart
- Flutter `Scaffold.drawerScrimColor` precedence: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/scaffold.dart
- Flutter bottom-sheet drag handle default/size: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/bottom_sheet.dart
- Flutter AppBar iconTheme vs actionsIconTheme and Sliver variants: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/app_bar.dart
- Flutter `showAdaptiveDialog` ignores barrierColor on iOS/macOS: https://api.flutter.dev/flutter/material/showAdaptiveDialog.html
- Flutter CupertinoDialogRoute resolved default Cupertino barrier: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/cupertino/route.dart
- Flutter Cupertino modal-popup default barrier: https://api.flutter.dev/flutter/cupertino/showCupertinoModalPopup.html
- Flutter `ListTile.textColor` state-resolved disabled/selected roles: https://api.flutter.dev/flutter/material/ListTile/textColor.html
- Flutter `WidgetStateColor.resolveWith`: https://api.flutter.dev/flutter/widgets/WidgetStateColor-class.html
- Flutter `AlertDialog.adaptive` (Cupertino on iOS/macOS): https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/dialog.dart
- Flutter `Switch.adaptive` / `Checkbox.adaptive` / `Radio.adaptive` / `Slider.adaptive` / `CircularProgressIndicator.adaptive`: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/switch.dart
- Flutter `showCupertinoSheet` / `CupertinoSheetRoute` (PageRoute, transparent barrier): https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/cupertino/sheet.dart
- Flutter test `TargetPlatformVariant` (sets `debugDefaultTargetPlatformOverride`): https://api.flutter.dev/flutter/flutter_test/TargetPlatformVariant-class.html
- Flutter ListTile `selectedTileColor` applied whenever `selected`, independent of `enabled`: https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/material/list_tile.dart
- Flutter MaterialApp high-contrast themes: https://api.flutter.dev/flutter/material/MaterialApp/highContrastTheme.html
- W3C WCAG 1.4.3 large-text `14pt ≈18.5px`: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum

**Verification note:** v2.6.1 additionally closes adaptive Material constructor substitution on iOS, names `showCupertinoSheet`, fixes the `AppListItem` disabled+selected contract against ListTile source, and moves iOS simulation to `TargetPlatformVariant`. v2.6 retains the v2.5 audited M3 mappings and explicitly denies adaptive/Cupertino modal shortcuts whose runtime barrier can bypass the approved Material theme. Source `master` confirms `showRawDialog`; whether it exists in the **pinned stable SDK** is a separate DSD-23 check. Flutter master can differ from a project SDK. This document does not assert a repository has passed tests or that any proposed token is already approved. **D=Match (master)** records a source review, not implementation approval; SDK pin/retest and palette approval remain separate.
