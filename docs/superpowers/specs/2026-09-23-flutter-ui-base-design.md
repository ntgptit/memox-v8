# MemoX V8 — Flutter UI base design

Status: approved 2026-09-23 · amended while writing the phase 1 plan (§3, §4.2, §4.4, §4.6,
§8.1, §8.3) · Path: architectural

## 1. Intent

`lib/` holds only the default `main.dart`. Before any feature screen can be
built, the app needs the visual base those screens assemble from: one common
theme, the shared component library and the app shell. This spec defines that
base. It is sub-project 2's implementation half in the
[foundation design](2026-09-21-memox-v8-foundation-design.md) decomposition.

The design is already decided. The V3 handoff
([`docs/shared/ui/design-handoff/`](../../shared/ui/design-handoff/00-index.md),
generated from `design-handoff.json`) owns the foundations, the theme binding and
46 widget contracts; [`navigation.md`](../../shared/ui/navigation.md) owns the
four top-level destinations. This spec binds them to Flutter. It does not
redesign them.

**UI only.** No Drift table, repository, use case, provider of business state
or SRS code is created or changed. No `lib/features/*/presentation/` file is
created: a feature screen needs its use cases (AD-12, ADR-011 D4), which belong
to the feature's own sub-project.

**Success:**

- `lib/core/theme/` provides the complete light and dark theme from the V3
  foundations and theme binding.
- All 43 components the handoff marks `IMPLEMENT_COMPONENT` exist as `Mx*`
  widgets in `lib/shared/widgets/`, each with widget tests and light/dark goldens.
- The app launches into a four-tab shell (Thư viện · Học · Tiến độ · Cài đặt),
  each tab showing a placeholder, in English and Vietnamese.
- A debug-only gallery shows every component in every variant and state.
- The phase gate passes (§8.3); `dod_check.sh` joins it once the backend
  adds codegen.

## 2. Decisions

| Topic | Decision |
|---|---|
| Scope | Theme + l10n + shell + all 46 handoff widgets (43 components, 1 utility, 2 platform-owned) |
| Known handoff defects | Implement the handoff as written. The contrast P0s and cross-file contradictions from the 2026-09-21 critique are recorded as debt (§9), not fixed |
| App wiring owner | This sub-project owns `main.dart`, `app/app.dart` and the router. Foundation plan Task 10 shrinks to the retry policy and the DB smoke test (§7) |
| Theme architecture | Material `ColorScheme` + `TextTheme` + component themes, one MemoX `ThemeExtension`, static token classes (approach A) |
| Icons | Built-in Material Icons (`Icons.*`), mapped from the handoff's Lucide names in one place. No icon dependency |
| Font | Plus Jakarta Sans, the variable font (wght axis) bundled as one asset (OFL), used at weights 400–800. No runtime font fetching: the app is offline. Weights are set through `AppTypography.withWeight`, which moves the `wght` axis with `fontWeight` (guard `no_bare_font_weight`) |
| Verification | Widget tests + light/dark goldens per component + a debug-only gallery route |

## 3. Structure

Placement follows [ADR-011](../../shared/decisions/ADR-011-cau-truc-thu-muc-v8.md).
The guard `memox-v8` already expects the theme under `lib/core/theme/` (scope
`theme_files`) and exempts it from the raw-value rules.

```
lib/
├── main.dart                        ProviderScope(child: MemoxApp())
├── app/
│   ├── app.dart                     MemoxApp: MaterialApp.router, themes, l10n
│   ├── placeholder_screen.dart      the stand-in body of each tab
│   ├── router/
│   │   ├── app_router.dart          GoRouter + StatefulShellRoute
│   │   └── app_routes.dart          path constants
│   └── gallery/                     debug-only component gallery
│       ├── gallery_screen.dart
│       └── gallery_<group>_section.dart   one per handoff group A–H
├── core/theme/
│   ├── foundations/
│   │   ├── app_spacing.dart  app_radius.dart  app_size.dart  app_icon_size.dart
│   │   ├── app_stroke.dart   app_opacity.dart app_effects.dart app_durations.dart
│   │   ├── app_shadows.dart
│   │   └── app_icons.dart               Lucide name → Icons.* mapping (phase 2)
│   ├── app_color_schemes.dart       light + dark ColorScheme
│   ├── app_typography.dart          TextTheme + withWeight
│   ├── mx_semantic_colors.dart      ThemeExtension (nine stored colours)
│   ├── mx_derived_colors.dart       the derived colours, computed once
│   ├── mastery_ramp.dart            MasteryRamp utility
│   ├── mx_text_styles.dart          component type treatments (phase 2)
│   ├── app_decorations.dart         raised card surface (phase 2)
│   ├── app_component_themes.dart    Material component themes (grows per phase)
│   ├── app_theme.dart               buildLightTheme() / buildDarkTheme()
│   └── theme_context.dart           context.colors / texts / semanticColors
├── l10n/
│   ├── app_en.arb                   template
│   └── app_vi.arb
└── shared/widgets/mx_<name>.dart    one component per file
assets/fonts/PlusJakartaSans-Variable.ttf, OFL.txt
l10n.yaml
test/core/theme/  test/shared/widgets/  test/app/  test/flutter_test_config.dart
```

`shared/widgets/` stays flat. The four-bucket rule (ADR-011 D8) governs feature
`presentation/widgets/` only; the guard rule `widgets_grouped_into_buckets`
matches `lib/features/*/presentation/widgets/**` and nothing else.

Dependency rules: `core/theme/` imports only Flutter. `shared/` imports only
`core/`. `app/` imports `core/`, `shared/` and `l10n/`. No feature is imported.

## 4. Theme binding

The order follows the 15-step sequence in
[`02-theme-binding.md`](../../shared/ui/design-handoff/02-theme-binding.md).

### 4.1 ColorScheme

Each theme starts from `ColorScheme.fromSeed(seedColor: <V3 primary>, brightness:)`
and applies every V3-defined standard role with `copyWith`.

- Roles V3 does not define, such as the `*Fixed` family, keep the seed-generated
  value. This is the handoff's `REPO_PRESERVED` disposition. No V3 colour is
  invented for them.
- `inverseSurface` `#34395D` and `onInverseSurface` `#E8EAFC` are the same in
  both themes, and a test asserts it.

### 4.2 MemoX semantic colours

`MxSemanticColors extends ThemeExtension<MxSemanticColors>` stores exactly the
nine `BIND_NOW` `MEMOX_SEMANTIC_COLOR` entries:

`mastery · warning · onWarning · statusNew · statusLearning · statusReviewing ·
statusMastered · errorFill · onErrorFill`

- The five `DERIVED_COLOR` entries (`dangerSoft`, `dangerBorder`, `warningSoft`,
  `surfaceHero`, `chromeGlass`) and the `border-ghost` edge colour live in
  `MxDerivedColors`, built from the `ColorScheme`, the extension and the
  brightness at the mix ratios in the foundations, and read as
  `context.derivedColors`. They are not extension fields.
- The five `M3_ALIAS` entries (`bg`, `surface-muted`, `surface-raised`,
  `progress-track`, `text-secondary`) resolve to their `ColorScheme` role and add
  nothing.
- The 15 `PRESERVE_ONLY` semantics get no field.
- The `MasteryRamp` utility (`IMPLEMENT_UTILITY`) lives beside the extension.

### 4.3 Typography

Plus Jakarta Sans for every role. The seven foundation roles bind to these M3
slots:

| Handoff role | Size / weight / line-height / tracking | M3 slot |
|---|---|---|
| stat | 40 / 600 / 1.0 / -0.64 | `displayMedium`, tabular figures |
| display | 32 / 800 / 1.1 / -0.64 | `displaySmall` |
| headline | 24 / 700 / 1.2 / -0.64 | `headlineSmall` |
| title | 20 / 700 / 1.2 / -0.64 | `titleLarge` |
| body large | 16 / 500 / 1.5 / 0 | `bodyLarge` |
| body | 14 / 400 / 1.5 / 0 | `bodyMedium` |
| caption | 12 / 600 / 1.4 / 1.2 | `labelSmall` |

The other M3 slots keep Material's defaults with the family applied. A component
type treatment (the button label at 14/600/0.1, the app-bar title) is a
component-level override of the nearest role, never a new global style.

### 4.4 Tokens

Static `abstract final class` holders in `core/theme/foundations/`:

| Class | Values |
|---|---|
| `AppSpacing` | micro 4 · control 8 · grouped 12 · gutter 16 · card 20 · section 24 · major 32 · pageEnd 48 |
| `AppRadius` | 4 · 8 · 12 · 16 · 20 · 999 (24 and 28 have no V3 call site and are not declared) |
| `AppSize` | button 48 / 36 / 32 / 28 · input 52 · icon-button ink 36 · app bar 56 · bottom nav 80 (bar 64) · FAB 52 · touch target 48 |
| `AppIconSize` | 16 · 20 · 24 · 32 · 40 |
| `AppStroke` | hairline 1 · focus 2, plus each width a component contract states |
| `AppOpacity` | disabled 0.38 · pressed 0.12 (state tokens) |
| `AppEffects` | glassOpacity 0.84 · glassBlur 18 (effect tokens, kept out of the state layer) |
| `AppDurations` | toggle 160 · standard 200 · scrimFade 220 · sheet 260 · spinnerCycle 800 · skeletonPulse 1400 ms — every duration the widget contracts state |
| `AppShadows` | whisper · overlay · chrome · fab, named by the handoff's semantic (the `shadow-card` token is the overlay shadow). Functions of the `ColorScheme` and brightness, because the values differ per theme and dark has no whisper shadow |

The glass effect on the bottom nav is translucent `chromeGlass` plus
`BackdropFilter` blur 18. The saturate(180%) part of the CSS filter is dropped:
Flutter has no cheap equivalent and the handoff allows a plain surface in its
place.

### 4.5 Global state policy

Owned once, referenced by every component:

- **Disabled:** opacity 0.38 over the whole control, and the callback is blocked.
- **Pressed:** the platform overlay at 0.12.
- **Focused:** a 2px `primary` ring, offset 2.
- **Hover:** not implemented. Android has no hover.

Selected, checked, active and error presentation are component-owned (§5).

### 4.6 Material component themes

Each is added in the phase that implements the matching `Mx*` widget, so the
theme slot and the widget land and are reviewed together. Configured centrally
only where the Material theme carries the V3 default without fighting a MemoX
variant: filled/outlined buttons, `InputDecorationTheme`,
dialog, bottom sheet, snackbar, switch, navigation bar, chip, progress indicator.
A variant richer than the Material theme can express stays in the `Mx*` widget,
which still reads `ColorScheme`, `TextTheme` and the tokens.

## 5. Component conventions

- **Naming.** `mx_<name>.dart` holds `Mx<Name>`, for example
  `mx_button.dart` → `MxButton`.
- **Smallest semantic API.** Variants are enums taken from the contract, for
  example `MxButtonTone { primary, secondary, outline, destructive }` and
  `MxButtonSize { regular, small, compact, chip }`. No parameter takes a
  `Color`, `TextStyle`, `EdgeInsets` or radius. Placement and outer spacing
  belong to the caller.
- **Theme only.** A component reads `context.colors`, `context.texts`,
  `context.semanticColors` and the `App*` tokens. It never contains a hex value
  or a bare number the guard forbids.
- **Composition.** A component composes others as the handoff's composition
  table states: `MxSheetActions` → `MxButton`, `MxListRow` → `MxIconTile`,
  `MxDeckPickerSheet` → `MxBottomSheet` + `MxListRow` + `MxEmptyState` +
  `MxSheetActions`, and so on.
- **No feature types.** `shared/` imports only `core/`. `MxDeckPickerSheet`
  takes generic candidates (label, enabled, onTap), not a deck entity.
- **Geometry and touch.** The painted size and the hit area are separate. Every
  interactive component meets a 48 minimum target by widening the hit area
  around the painted box. A height around text is a minimum, never fixed, and
  text scale is never clamped.
- **Accessibility.** Icon-only controls (`MxIconButton`, `MxFab`, the close
  action of `MxStudyTopBar`) take a **required** `semanticLabel`. This changes
  the API, not the picture, so it does not depart from the handoff.
- **Overlays.** Opened through `showMxDialog`, `showMxBottomSheet` and
  `showMxSnackbar`, which use the platform modal route. The barrier is `scrim` at
  45%. The mock's `scrim={false}` flag is not carried over.
- **Copy.** A component holds no copy. The caller passes localized strings. Only
  a component's own built-in labels (a default tooltip, for example) come from
  the ARB files.
- **Motion.** Every duration comes from `AppDurations`. The skeleton pulses
  0.45 ↔ 0.75 over 1.4 s. When `MediaQuery.disableAnimations` is on, the pulse
  and every flip or slide are off.
- **Contradictions inside the handoff.** For a component's own geometry and type,
  the widget's spec file wins, because the handoff gives geometry to the
  component. For a global value, Foundations wins. Each choice is logged in §9.

## 6. Shell, router, l10n

**Router.** `GoRouter` with a `StatefulShellRoute.indexedStack` of four branches,
in the fixed order of `navigation.md`:

| Tab label (vi / en) | Path | Handoff glyph (Lucide) |
|---|---|---|
| Thư viện / Library | `/decks` | layers |
| Học / Study | `/study` | play |
| Tiến độ / Progress | `/progress` | bar-chart-3 |
| Cài đặt / Settings | `/settings` | settings |

- Cold start opens `/decks`.
- Paths are constants in `app_routes.dart`.
- Each branch keeps its own stack, so switching tabs keeps the scroll position.
- System Back is handled by go_router and Android.

**Shell.** `MxAppShell` hosts the `navigationShell`. `MxBottomNav` is an in-flow
sibling of the scrolling body and never overlaps it. The app runs edge-to-edge
and takes every system inset from `MediaQuery`.

**Placeholder.** One `PlaceholderScreen(title:)` serves all four tabs: `MxAppBar`,
`MxScreenScroll` and an `MxEmptyState` saying the screen is coming. A feature's
first real screen replaces the placeholder in its branch.

**Gallery.** The `/gallery` route is registered only when `kDebugMode` is true.
It is opened from a debug-only action on the Settings placeholder app bar.

- Components are grouped A–H as in the handoff index, each shown in every
  variant and in the disabled, loading, error and long-content states.
- A local switch sets light/dark and text scale 1.0/2.0.

**Theme mode and locale.** `ThemeMode.system` and the system locale, with `en`
and `vi` supported. Persisting a chosen theme or language (BR-SETTINGS-005,
BR-SETTINGS-006) belongs to the settings sub-project. Until then `app.dart`
reads no provider.

**l10n.**

- `flutter_localizations` (SDK) and `intl` are added, with gen-l10n configured in
  `l10n.yaml`.
- `app_en.arb` is the template and `app_vi.arb` the translation.
- Every key has an `@description`, as the guard rule
  `memox.i18n.arb_entry_needs_description` requires.
- The only strings are those of the shell, the placeholder and the gallery's
  entry action. The debug-only gallery's own labels and demo copy stay English
  literals (phase 3 ruling G1).

## 7. Boundary with the backend foundation

- `main.dart` is `ProviderScope(child: MemoxApp())` and nothing else.
- [Foundation plan](../plans/2026-09-23-memox-v8-foundation.md) Task 10 is edited
  in its text only, to read: add the retry policy to the existing
  `ProviderScope` and add the DB smoke test; do not create `app.dart` or the
  router, and adjust `app_test.dart` to the shell instead of a placeholder route.
- No backend source file is created or changed by this sub-project.

## 8. Phases and verification

### 8.1 Phases

Each phase is one PR, and a phase starts only when the previous gate is green.
Components are ordered so each one's dependencies land in an earlier phase or
the same one.

| # | Content | Components |
|---|---|---|
| 1 | Foundations: font asset and all of `core/theme/` with its tests | — (`MasteryRamp` utility) |
| 2 | Chrome, layout and the components they compose | Button, IconButton, EmptyState, AppBar, BottomNav, Breadcrumb, StudyTopBar, Fab, AppShell, ScreenScroll, FooterBar (11) |
| 3 | App wiring: l10n setup, `main`, `app`, router, shell, placeholder, gallery; foundation plan Task 10 text edit | — |
| 4 | Actions and inputs | FilterChip, ChipTrigger, SearchField, TextField, FieldMessage, Toggle, OptionRow, SelectionCheckbox, SegmentedTray, Stepper (10) |
| 5 | Surfaces, rows, status and metadata | Card, Section, ListRow, SettingsRow, IconTile, ActionSheetCommandRow, ListSectionHeader, Badge, StatusBadge, TagChip, Note, WorkloadBreakdownLine, MasteryDonut (13) |
| 6 | Overlays, loading, error | Dialog, BottomSheet, SheetActions, Snackbar, InlineBanner, DeckPickerSheet, Skeleton, Spinner, ErrorState (9) |

l10n arrives in phase 3 with the first UI string, as ADR-011 places `l10n/`.
`StatusBar` and `Scrim` are `USE_PLATFORM` and get no file. Every component added
in phases 4–6 also gets its gallery entry.

### 8.2 Tests

**Theme** (`test/core/theme/`):

- Both themes carry the complete M3 role set.
- Every V3-defined role equals its handoff value.
- The `inverse*` pair is identical across themes.
- Each of the seven type roles has the stated size, weight, height and tracking.
- Each derived colour matches its mix ratio.
- `MxSemanticColors.lerp` and `copyWith` work.

**Components** (`test/shared/widgets/mx_<name>_test.dart`):

- Every variant and every state in the contract's state matrix renders.
- `meetsGuideline(androidTapTargetGuideline)` and `labeledTapTargetGuideline`
  pass for interactive components.
- Text scale 2.0 renders without overflow.
- Disabled paints at 0.38 and blocks the callback.
- Widgets are found by key or semantics, never by an English literal.

**Goldens:**

- One light and one dark golden per component, at 360×800 logical pixels,
  captured at pixel ratio 3 (1080×2400) with real shadow blur, tagged `golden`
  in `dart_test.yaml` and run with `TZ=UTC`.
- `test/flutter_test_config.dart` loads the real Plus Jakarta Sans, so text does
  not render as Ahem boxes.
- Tolerance is zero.
- Goldens are generated on Windows, the only machine that runs the suite: the
  repository's only workflow is `build-apk.yml`. When a Linux CI test job
  exists, the goldens are regenerated there (§9).

**App** (`test/app/`):

- Cold start lands on `/decks`.
- The four tabs appear in order, and switching tabs keeps each branch's stack.
- `/gallery` is not registered outside debug.
- Under the `vi` locale the tab labels are Vietnamese.

### 8.3 Gate

- **Phases 1–2:** the five-step gate in `README.md` (`flutter analyze`,
  `flutter test`, `check_architecture.py`, CI tooling tests, guard `memox-v8`).
- **The first `lib/core/theme/` file (phase 1)** gives
  `no_raw_duration` and `no_raw_stroke_width` (scope `ui_and_theme_surfaces`)
  and `no_bare_font_weight` (scope `typography_and_theme_surfaces`) their first
  target. Their entries are deleted in that commit.
- **The first `lib/shared/` file (phase 2)** gives the `targets_pending:
  presentation` rules in
  `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
  their first target. Their entries are deleted in that same commit.
- **The first `lib/app/` file (phase 3)** does the same for the two
  `targets_pending: app` entries.
- **From phase 3** the gate adds `python tools/docs/check.py`.
  `dod_check.sh` becomes the gate once the backend adds Riverpod/Drift codegen;
  its generated-code step reports zero scope until then (phase 3 ruling G2).

**Toolchain.** Every gate runs on the Flutter that `.fvmrc` pins (3.47.5); the
pubspec needs Dart ^3.13.4, which older SDKs cannot resolve.

The `domain`, `providers` and `data` entries stay pending: they wait for the
backend foundation plan, which this sub-project does not touch.

**Visual check.** At the end of phases 3 and 6 the app runs on an Android emulator
or device, and the gallery is captured in both themes as evidence. One native
`impeccable audit` pass runs over the gallery at the end of phase 6. Its findings
are added to §9. They do not change tokens.

## 9. Debt register

Recorded, not fixed, by the "implement the handoff as written" decision. Each
item names where it comes from.

| # | Item | Source |
|---|---|---|
| 1 | Dark `onWarning` `#2A1E00` bound as text on `#131A3A` is 1.04:1 | critique 2026-09-21 P0 |
| 2 | Snackbar action in dark, `inversePrimary` `#5265F5` on `#34395D`, is 2.40:1 | critique P0 |
| 3 | `statusLearning` text about 2.15:1 and `statusNew` about 2.96:1 | critique P0 |
| 4 | Non-text edges under 3:1: input border 1.24, toggle off 1.25, progress track 1.18 | critique P0 |
| 5 | Line-heights 1.0–1.2 may clip stacked Vietnamese diacritics | critique P2 |
| 6 | AppBar title 16/700 in `app-bar.md` vs 20/700 in `02-theme-binding.md`: the widget spec (16/700) is implemented | critique P1, §5 rule |
| 7 | ListRow title 14/600 vs foundations 16/500: the widget spec is implemented | critique P1, §5 rule |
| 8 | MasteryDonut label under the 12px floor: the widget spec is implemented | critique P1, §5 rule |
| 9 | Goldens are Windows-generated and must be regenerated when Linux CI exists | §8.2 |
| 10 | AppBar, StudyTopBar (56) and the BottomNav bar (64) are minimum heights that grow with text scaling; MxAppShell places the app bar in-flow instead of `Scaffold.appBar` | phase 2 plan R1, R3 |
| 11 | Button chip size paints `surfaceContainerLowest` + ghost edge with `onSurface` ink whatever the tone; the contract leaves chip ink unspecified | phase 2 plan R2 |
| 12 | Breadcrumb ancestor segments have a 48×48 hit area; the row is 48 tall instead of 2 + text + 8 | phase 2 plan R4 |
| 13 | The focus ring is a 2px `primary` side on the control's own edge; the contract's offset 2 is not drawn | phase 2 plan R5 |
| 14 | StudyTopBar track is `progress-track` (`surfaceContainerHigh`) per its theme-consumption table, over "surfaceContainer" in its dimension line | phase 2 plan R6, critique P1 |
| 15 | EmptyState tile→title (16) and title→body (8) gaps are UNSPECIFIED in the contract and use the spacing roles | phase 2 plan R7 |
| 16 | EmptyState has no footnote slot until MxNote (phase 5); MxButton's loading spinner is a plain `CircularProgressIndicator` until MxSpinner (phase 6) | phase 2 plan R8 |
| 17 | BottomNav labels and the FooterBar caption inherit the caption role's 1.2 tracking; their contracts state only size and weight, and the result reads airy | phase 2 execution |
| 18 | No Android emulator on the development machine: the phase 3 visual check is app-level goldens (Library, gallery; light, dark; 3x) instead of a device run | phase 3 plan G3 |
| 19 | The debug gallery's labels and demo copy are English literals, not ARB strings | phase 3 plan G1 |
| 20 | FieldMessage warning text uses a derived `warningInk` (onWarning light, the amber dark), as the FieldMessage contract scopes it; this resolves row 1 for FieldMessage | phase 4 plan I1 |
| 21 | SelectionCheckbox's check glyph is 14, below the 16 icon floor, as its contract states | phase 4 plan I2 |
| 22 | Stepper invalid-ring radius is UNSPECIFIED and uses `AppRadius.md`, its buttons' radius | phase 4 plan I3 |
| 23 | SegmentedTray lays out 48 tall with the 40 tray painted centred; each segment is at least 48 wide | phase 4 plan I4 |
| 24 | OptionRow description, SegmentedTray label and FieldMessage keep the caption role's 1.2 tracking (extends row 17) | phase 4 plan I5 |
| 25 | SelectionCheckbox is painted only; the caller's row owns the tap and the checked semantics | phase 4 plan I6 |
| 26 | FilterChip's count keeps the label's 0.1 tracking, not the caption role's 1.2, so the digits do not read spaced | phase 4 execution |
| 27 | TextField and SearchField reach their floors through vertical content padding, not `InputDecoration.constraints`, which painted the box at text height; the multiline field pads 9.5 instead of 8 | phase 4 execution |
| 28 | Badge offers no `streak` tone: its colour is PRESERVE_ONLY with no V3 call site, and §4.2 keeps the extension at nine fields | phase 5 plan S1 |
| 29 | Badge's `neutral` tone, whose colour the contract does not name, paints `onSurfaceVariant`, as EmptyState's neutral tone does | phase 5 plan S2 |
| 30 | A tonal warning Badge reads in `warningInk` (extends row 20); a solid Badge's label is `onPrimary` for every tone as written, so a solid warning badge is white on amber | phase 5 plan S3 |
| 31 | Pill and count text (Badge, StatusBadge, TagChip, WorkloadBreakdownLine, MasteryDonut label) takes the 0.1 label tracking (extends row 26) | phase 5 plan S4 |
| 32 | 12px text whose contract states only size and colour (the ListRow, ActionSheetCommandRow and SettingsRow sub-lines, Note) keeps the caption role (extends row 24) | phase 5 plan S5 |
| 33 | StatusBadge's four names come from the caller, since `shared/` cannot import `l10n/`; the bare dot announces the same name | phase 5 plan S6 |
| 34 | ActionSheetCommandRow's glyph (16) and label→sub gap (2) are UNSPECIFIED and use the small IconTile step and the ListRow gap | phase 5 plan S7 |
| 35 | Section draws the ghost dividers between its rows, renders its note as MxNote, and keeps its 16 bottom gap although §5 gives outer spacing to the caller | phase 5 plan S8, S9 |
| 36 | MasteryDonut's track is `surfaceContainer` as its contract states, not MasteryRamp's progress-track; at 0% the label takes the lowest band colour; the label scales down to stay inside the ring | phase 5 plan S10 |
| 37 | Badge, StatusBadge and TagChip heights (22, 18) are minimums that text scaling grows | phase 5 plan S11 |
| 38 | WorkloadBreakdownLine paints no top margin; the row that stacks it owns the 2 gap. The suffix follows the terms after a space | phase 5 plan S12 |
| 39 | IconTile's `seed` is the one `Color` parameter among the shared widgets: per-deck data the contract passes per instance | phase 5 plan S16 |
| 40 | SettingsRow's wide control keeps its own width, start-aligned under the label, since Stepper and SegmentedTray are intrinsic-width | phase 5 plan S17 |
| 41 | Badge's leading glyph is 12, below the 16 icon floor, as its contract states | phase 5 plan S18 |
| 42 | Row 16's footnote half is resolved: EmptyState's `footnote` renders an MxNote 20 below the action | phase 5 plan S19 |
| 43 | ListRow and SettingsRow put the 12/12 vertical inset on the text column only, so a 48 trailing target (overflow button, toggle) sits inside the text height instead of growing the row; the painted rows match the contract's "one title + one sub + 12/12" | phase 5 execution |
| 44 | TagChip's label keeps the caption line-height 1.4, not the contract's 1: an ellipsized label clips to its text box, and a 12px box cut the descenders | phase 5 execution |
| 45 | MxSpinner is a fixed three-quarter 2px ring turning once every 0.8s, not Material's growing arc, and it keeps turning under reduced motion because it is the only sign of work in flight | phase 6 plan O1 |
| 46 | Row 16's spinner half is resolved: MxButton, MxListRow and MxStepper spin MxSpinner, onPrimary inside a filled button and primary elsewhere, so a loading outline or secondary button spins in primary | phase 6 plan O2 |
| 47 | Skeleton's radius 6 is a component constant; the skeleton row ships as MxSkeletonRow on ListRow geometry, with an UNSPECIFIED 8 between its bars | phase 6 plan O3 |
| 48 | ErrorState's tile → title gap is UNSPECIFIED and uses EmptyState's 16 | phase 6 plan O4 |
| 49 | Dialog title and body typography and insets are UNSPECIFIED: `compactTitle` (the ErrorState and DeckPickerSheet title), a 14 onSurface body, 20 in, 8 apart, scrolling when the text outgrows the screen | phase 6 plan O5 |
| 50 | InlineBanner's warning border is a new derived `warningBorder` at the contract's 26% / 32% (the theme gap it reports); actions always sit under the message, so the single-line trailing-action form is not built; its text keeps the caption role at 1.55 (extends row 24) | phase 6 plan O6 |
| 51 | The BottomSheet opens with the platform modal route's slide at 260ms, not a 20% translate; the Dialog keeps the contract's 0.94 scale and fade | phase 6 plan O7 |
| 52 | The scrim's 45% is a new effect token, `AppEffects.scrimOpacity` | phase 6 plan O8 |
| 53 | Snackbar is the platform floating SnackBar with a 16 margin; its action is a 32 compact button in a 48 target with an UNSPECIFIED radius of 8 | phase 6 plan O9 |
| 54 | DeckPickerSheet's footer is one button (outline Cancel with targets, primary OK without); its title → rule gap is UNSPECIFIED and uses 4 | phase 6 plan O11 |
| 55 | The toast's 10 vertical padding sits on the message, not on the SnackBar, so the action's 48 target fits inside the 48 floor instead of making an action toast 68 tall (the ListRow rule of row 43) | phase 6 execution |

Further contradictions found while implementing are appended here with the same
rule applied. `docs/_generated/open-questions.md` is generated and is not
edited by hand.

## 10. Out of scope

- Any feature screen, controller, provider of business state or use case.
- Persisting theme mode or locale.
- Fixing the handoff values listed in §9.
- A Linux CI test workflow.
- Widgetbook or any other gallery dependency.
