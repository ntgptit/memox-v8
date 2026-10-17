# ForUI API catalog (forui 0.27.6)

The ForUI APIs the MemoX v8 app can use, verified against the version it
resolves. Every entry names its public symbol, its constructors as declared,
how it owns state, its interaction states, focus and semantics, motion,
styling, the limitations found in the source, and the evidence.

## Version and sources

| Item | Value |
|---|---|
| Resolved package | `forui 0.27.6` (`pubspec.yaml` pins `forui: 0.27.6`; `pubspec.lock` sha256 `3ea0d75e…921fa`; `.dart_tool/package_config.json` → pub cache `forui-0.27.6`) |
| Companion packages | `forui_lucide 0.27.0` (icons), `material_ui 1.4.0` (ForUI's Material dependency) |
| Installed source (authoritative) | `forui-0.27.6/lib/` in the pub cache, written below as `forui-0.27.6/lib/...` |
| Official docs for this version | the `docs/content/docs/*.mdx` pages of `github.com/duobaseio/forui` at tag `forui/0.27.6` (commit `e9cb058d`), the source `forui.dev/docs/llms.txt` is generated from (`docs/app/docs/llms.txt/route.ts`). `forui.dev` itself is blocked by this environment's network policy (HTTP 403), so the pages were read from the tagged repository; URLs are given in their published form |
| ForUI's own tests and examples | `forui/test/`, `forui/example/`, `docs_snippets/` at the same tag |
| CLI discovery | `dart run forui snippet ls`, `dart run forui style ls` (read-only). Note: the first `dart run forui` adds `forui_cli` to `dev_dependencies`; that change was reverted, since a dependency change needs the owner |

Claims marked `PROBE` were checked in an isolated throwaway project (outside
this repository) on Flutter 3.47.5 with forui 0.27.6; `UNVERIFIED` marks what
the source alone could not settle. Nothing here was run on a device or with
TalkBack.

## Contents

1. Theme, tokens, variants, foundations, motion, controls
2. Layout, items and tiles, navigation
3. Actions, form inputs, selection controls
4. Data presentation, feedback, overlays


---

## ForUI 0.27.6 catalog A: theme, variants, interaction foundations, motion, controls

Scope: categories 1 to 7 of the brief. Evidence-only; every path is relative to
`forui-0.27.6/lib/` (written `src/...`) unless it starts with `docs:`
(= `.../scratchpad/forui-src/docs/content/docs/`), `test:` (= `.../scratchpad/forui-src/forui/test/src/`)
or `snip:` (= `.../scratchpad/forui-src/docs_snippets/lib/snippets/`).

## 0. Reading notes

- Package requires `sdk >=3.13.0-0`, `flutter >=3.47.0-0` (`pubspec.yaml:21-22`). The source uses the new Dart
  primary-constructor and dot-shorthand syntax: `class const FX({ final T a = 1 }) with M { this; }` declares a
  `const FX({this.a = 1})` constructor; `new foo(...)` declares a named constructor `FX.foo(...)`; `const new(...)` is the
  unnamed const constructor; `const factory(...) = Impl` is an unnamed redirecting factory. Signatures below are
  translated to ordinary Dart.
- Everything below is exported by `package:forui/forui.dart` (`forui.dart:5-9` exports `foundation.dart`, `theme.dart`,
  `assets.dart`, `localizations.dart`, plus `widgets/*.dart`). `assets.dart` re-exports `package:forui_lucide/forui_lucide.dart`
  (`FLucideIcons`). Not exported (internal): `Value`, `And`, `Not`, `Touch`, `Desktop`, `toVariants`'s helper `toTextFieldVariants`,
  `createVariants`, `AnimatedTappable`, `TappableGroupScope`, `GroupEntry`, `FixedConstraints`, `InheritedThemeElement`,
  `AdaptiveScopeElement`, `AccessibilityScopeElement`, `InternalFMultiValueControl`, `InternalFOverlayControl`
  (see the `hide` lists in `foundation.dart` and `theme.dart`).
- "Tier" numbers: platform 0, interaction 1, semantic 2 (`src/theme/variant.dart:101-103`, docs: concepts/themes.mdx).
- Docs base URL: `https://forui.dev/docs/<path>`; foundation widget pages (`widgets/foundation/*.mdx`) are thin (preview + usage
  snippet only); behaviour was taken from source.

---

## 1. Theme and design tokens

### `FTheme` — animated theme host; provides FThemeData, platform variant and accessibility scopes
- Import: `package:forui/forui.dart` (`lib/theme.dart` -> `src/theme/theme.dart:94`)
- Constructor: `const FTheme({required FThemeData data, required Widget child, TextDirection? textDirection, FPlatformVariant? platform, FAccessibility? accessibility, FThemeMotion motion = const FThemeMotion(), VoidCallback? onEnd, Key? key})` (`theme.dart:193-203`).
- Static members:
  - `static FThemeData of(BuildContext)` returns the nearest data, **falling back to `FTheme.neutral.light.touch` when no ancestor `FTheme`** (`theme.dart:137-141`).
  - `static FCapturedTheme capture({required BuildContext from, required BuildContext to})` (`theme.dart:144-153`).
  - `static final neutral = (light: FPlatformThemeData, dark: FPlatformThemeData)` (`theme.dart:160-170`); each has `.desktop` and `.touch` (lazy `late final`, `theme.dart:411-421`).
    Built as `FThemeData(touch: <bool>, debugLabel: ..., colors: FColors.neutralLight|neutralDark)`.
- State / control: stateless; wraps `_AnimatedTheme` (an `ImplicitlyAnimatedWidget`, `theme.dart:225-266`) that tweens
  `FThemeData` with `FThemeData.lerp` (`theme.dart:279`) and renders `FBasicTheme`.
- Brightness: ForUI does **not** pick light/dark; the app passes the `FThemeData` (docs: concepts/themes.mdx "Theme Brightness").
- Touch vs desktop: not auto-selected by `FTheme`. The app chooses `.touch` or `.desktop`; `platform:` only overrides the
  *variant* seen by `context.platformVariant`, not the data (docs: concepts/responsive.mdx; `theme.dart:174-177`).
- Motion: `FThemeMotion({Duration duration = 200ms, Curve curve = Curves.linear})` (`theme.dart:283-292`), applied whenever `data` changes. Use `FBasicTheme` for no animation.
  The animation does not consult `FAccessibility.motion` (UNVERIFIED that anything else gates it; no read of `accessibility` in `_AnimatedTheme`, `theme.dart:225-266`).
- Caveat: `context.theme` called in the same `build` that creates the `FTheme` returns the fallback theme (`theme.dart:15-54` doc comment).
- Evidence: `src/theme/theme.dart:94-292`; docs https://forui.dev/docs/concepts/themes

### `FBasicTheme` — non-animated host
- Constructor: `const FBasicTheme({required FThemeData data, required Widget child, FPlatformVariant? platform, FAccessibility? accessibility, TextDirection? textDirection, Key? key})` (`theme.dart:321-331`).
- Builds, outermost to innermost: `FAccessibilityScope(data: accessibility)` -> `FAdaptiveScope(platform)` -> `_InheritedTheme(data)` -> `Directionality` (falls back to `.ltr`) -> `DefaultTextStyle(style: data.typography.body.sm.copyWith(color: data.colors.foreground))` (`theme.dart:330-345`).
  So every ForUI subtree under `FTheme`/`FBasicTheme` has the scopes that `context.accessibility` needs (see §6).
- `updateShouldNotify` is `data != old.data` (value equality, `theme.dart:369`); theme equality therefore matters (see Equality note under `FThemeData`).

### `FBuildContext` extension on `BuildContext`
- `FThemeData get theme` (`=FTheme.of(this)`), `FAccessibilityContext get accessibility`, `FPlatformVariant get platformVariant` (`=FAdaptiveScope.of(this)`) (`theme.dart:13-60`).
- Note: docs link these as `FThemeBuildContext` / `FAdaptiveBuildContext`; the declared extension name in 0.27.6 is `FBuildContext` (docs: concepts/responsive.mdx vs `theme.dart:13`).

### `FCapturedTheme` — carry theme/accessibility/platform scopes into another subtree (routes, overlays)
- Constructor: `const FCapturedTheme({ValueListenable<FThemeData>? theme, ValueListenable<FAccessibility>? accessibility, ValueListenable<FPlatformVariant>? platform})`; method `Widget wrap(Widget child)` (`src/theme/captured_theme.dart:10-24`).
- Obtain with `FTheme.capture(from:, to:)`: a scope is captured only if the `from` and `to` contexts resolve to different scope elements (`theme.dart:144-153`).
- `wrap` rebuilds via listeners; when the notifier fires during `persistentCallbacks` it defers `setState` to a post-frame callback (`captured_theme.dart:96-110`).
- If a theme was captured it rebuilds a full `FBasicTheme`; otherwise only the platform/accessibility scopes (`captured_theme.dart:112-124`).

### `FThemeData` — immutable theme: tokens + one style per ForUI widget + extensions
- Constructor (a factory, the only public one): `FThemeData({required FColors colors, required bool touch, String? debugLabel, FBreakpoints breakpoints = const FBreakpoints(), FTypography? typography, FIcons? icons, FStyle? style, FHapticFeedback hapticFeedback = const FHapticFeedback(), <one optional param per widget style>, Iterable<ThemeExtension<dynamic>> extensions = const []})` (`src/theme/theme_data.dart:542-615`).
  - Missing `typography` -> `FTypography.inherit(colors, touch)`; `icons` -> `const FIcons.lucide()`; `style` -> `FStyle.inherit(colors, typography, touch)` (`theme_data.dart:616-618`).
  - Every missing widget style -> that style's `.inherit(colors: , typography: , style: , [icons:] [hapticFeedback:] [touch:])` (`theme_data.dart:627-744`). **`touch` only changes sizing/typography defaults; it is not stored.**
- Fields (all `final`, read via `context.theme.<name>`): `debugLabel, breakpoints, colors, typography, icons, style, hapticFeedback,` then widget styles:
  `accordionStyle, autocompleteStyle, alertStyles (FVariants<..FAlertStyle..>), avatarStyle, badgeStyles, bottomNavigationBarStyle, breadcrumbStyle, buttonStyles (FVariants<..FButtonSizeStyles..>), calendarStyle, cardStyle, checkboxStyle, circularProgressStyles, dateFieldStyle, dateTimePickerStyle, determinateProgressStyle, dialogRouteStyle, dialogStyle, dividerStyles, headerStyles, itemStyles, itemGroupStyle, labelStyles, lineCalendarStyle, multiSelectStyle, modalSheetStyle, otpFieldStyle, paginationStyle, persistentSheetStyle, pickerStyle, popoverStyle, popoverMenuStyle, progressStyle, radioStyle, resizableStyles, scaffoldStyle, selectStyle, selectGroupStyle, selectMenuTileStyle, sidebarStyle, sliderStyles, toasterStyle, switchStyle, tabsStyle, tappableStyle, textFieldStyles (FTextFieldSizeStyles), tileStyles, tileGroupStyle, timeFieldStyle, timePickerStyle, tooltipStyle` (`theme_data.dart:27-537`, mixin signatures `theme_data.design.dart:12-70`).
- `FThemeData copyWith({String? debugLabel, FBreakpoints? breakpoints, <FXStyleDelta? per widget style>, FVariantsDelta<..>? <for variant-style fields>, Iterable<ThemeExtension<dynamic>>? extensions})` (`theme_data.dart:1343-1409`).
  - **Cannot change `colors`, `typography`, `style`, `icons` or `hapticFeedback`.** Doc: build a new `FThemeData(colors: ..copyWith(..), typography: ..., style: ...)` so widget styles re-inherit (`theme_data.dart:1299-1341` doc comment).
  - **`copyWith` does not accept or forward `icons`; it calls `FThemeData(touch: true, ...)` without `icons:`, so the copy silently reverts to `FIcons.lucide()`** (`theme_data.dart:1411-1479`; grep of lines 1405-1479 finds no `icons`). `hapticFeedback` is forwarded unchanged (`theme_data.dart:1416`), but styles captured haptic callbacks at inherit time, so a new haptic needs a fresh `FThemeData(hapticFeedback: ...)`.
  - `extensions:` replaces the whole set (`theme_data.dart:1477`).
- `factory FThemeData.lerp(a, b, t)`: colors/typography/style/widget styles lerp; `breakpoints`, `icons`, `hapticFeedback`, `debugLabel` snap at `t < 0.5`; variant maps via `FVariants.lerpWhereUsing` which **only keeps keys present in both** (`theme_data.dart:750-893`, `variants.dart:79-118`).
- Extensions: `T extension<T extends Object>()` (`=> _extensions[T]! as T`, throws a null-check error if absent) and `Set<ThemeExtension<dynamic>> get extensions` (`theme_data.dart:948-954`). Same pattern on `FColors`, `FTypography`/`FTypeface` (needs `FScalableExtension`), `FStyle`. Guide: https://forui.dev/docs/guides/adding-theme-properties
- `ThemeData toApproximateMaterialTheme()` (`theme_data.dart:981-1176`): best-effort Material mapping.
  - `useMaterial3: true`, `splashFactory: NoSplash.splashFactory`, `fontFamily` from `typography.body`, `iconTheme: IconThemeData(color: colors.primary, size: 20)`.
  - `ColorScheme(brightness, primary, onPrimary, secondary, onSecondary, error, onError, surface=background, onSurface=foreground, secondaryContainer=secondary, onSecondaryContainer=secondaryForeground)` (`theme_data.dart:1020-1033`); no tertiary/outline/surface-container roles are set.
  - TextTheme forces `height: 1` and `textBaseline: alphabetic` on every style (`theme_data.dart:984-1018`); display/headline map to `typography.display.xl4..xl`, title/label/body map to `typography.body.lg..xs`.
  - Component themes mapped: NavigationBar/Drawer/Rail, Card, Chip, InputDecoration, DatePicker, TimePicker, Slider, Switch, Elevated/Filled/Outlined/Text/Icon/Segmented/FAB buttons, Dialog, BottomSheet, SnackBar, ListTile, Divider. Shapes use `RoundedSuperellipseBorder`.
  - Docs say the mapping "can change without prior warning"; the CLI can generate an editable copy: `dart run forui snippet create material-theme` (docs: concepts/themes.mdx). The in-source doc comment says `material-mapping` (`theme_data.dart:963`): the two names disagree. UNVERIFIED which is valid (CLI not run).
- Equality: `==` compares all fields; `FTheme` animates when `data` is unequal, so themes built from the same inputs must be equal. Docs: use static functions rather than closure literals in styles; `FIcon`s need `==`/`hashCode` (docs: concepts/themes.mdx "Equality", `snip:concepts/themes/components/equality.dart`).
- Evidence: `src/theme/theme_data.dart`, `theme_data.design.dart`; docs https://forui.dev/docs/concepts/themes

### `FColors` — colour tokens
- Constructors: `FColors({required Brightness brightness, required SystemUiOverlayStyle systemOverlayStyle, required Color barrier, background, foreground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, destructive, destructiveForeground, error, errorForeground, card, border, double hoverLighten = 0.075, double hoverDarken = 0.05, double disabledOpacity = 0.5, Iterable<ThemeExtension<dynamic>> extensions = const []})` (non-const, `src/theme/colors.dart:~185-230`); private const `FColors._`. Presets `FColors.neutralLight` (`colors.dart:144`), `FColors.neutralDark` (`colors.dart:165`). `factory FColors.lerp(a, b, t)` (lerps via `FColors.lerpColor`, converts to Display P3 when colour spaces differ, `colors.dart:~200-260`).
- Asserts: `0 <= hoverLighten/hoverDarken/disabledOpacity <= 1` (`colors.dart:139-141`).
- Methods: `Color hover(Color)` (`colors.dart:280`) shifts HSL lightness (darkens light colours by `hoverDarken`, lightens dark by `hoverLighten`, stronger near extremes); `Color disable(Color, [Color? background])` (`colors.dart:302`) = `alpha * disabledOpacity`, alpha-blended onto `background` if given; `copyWith(...)` (`colors.dart:324`); `extension<T>()`, `extensions`.
- Pairs: `primary/primaryForeground`, `secondary/secondaryForeground`, `muted/mutedForeground`, `destructive/destructiveForeground`, `error/errorForeground`; plus `barrier`, `background`, `foreground`, `card`, `border`.
  **No success/warning/info/surface-tier tokens**: add them through `FColors.extensions` (a `ThemeExtension`).
- Neutral values: light `background 0xFFFFFFFF`, `foreground 0xFF0A0A0A`, `primary 0xFF171717`, `border 0xFFE5E5E5`, `barrier 0x33000000`; dark `background 0xFF0A0A0A`, `primary 0xFFE5E5E5`, `border 0x1AFFFFFF`, `barrier 0x7A000000` (`colors.dart:144-186`).

### `FTypography` — `display` and `body` typefaces
- Constructors: `FTypography({required FTypeface display, required FTypeface body, Iterable<FScalableExtension<dynamic>> extensions = const []})`; `factory FTypography.inherit({required FColors colors, required bool touch, Iterable<FScalableExtension<dynamic>> extensions})` (display and body get the **same** `FTypeface.inherit`; there is no `fontFamily` parameter here) (`src/theme/typography.dart:38-49`).
- `copyWith({FTypeface? display, FTypeface? body, extensions})`, `scale({double sizeScalar = 1})` (scales `fontSize` only), `lerp`, `extension<T>()` (`typography.dart:52-102`).

### `FTypeface` (+ `FScalableExtension<T>`) — 14-step text scale in one family
- Constructor: `FTypeface({String fontFamily = FTypeface.defaultFontFamily, List<String>? fontFamilyFallback, TextStyle? xs3, xs2, xs, sm, md, lg, xl, xl2, xl3, xl4, xl5, xl6, xl7, xl8, Iterable<FScalableExtension<dynamic>> extensions})` (`typography.dart:249-395`); `defaultFontFamily = 'packages/forui/Inter'` (`typography.dart:137`); asserts non-empty family.
  - Direct-constructor defaults carry **no colour** (only family/size/height): sizes 10, 12, 14, 16, 18, 20, 22, 30, 36, 48, 60, 72, 96, 108 for xs3..xl8, heights 1, 1, 1.25, 1.5, 1.75, 1.75, 2, 2.25, 2.5, 1, 1, 1, 1, 1; `leadingDistribution: .even` (`typography.dart:268-393`).
- `factory FTypeface.inherit({required FColors colors, required bool touch, String fontFamily = defaultFontFamily, List<String>? fontFamilyFallback})`: styles carry `color: colors.foreground` (`typography.dart:398-640`).
  - Touch sizes: xs3 10, xs2 12, xs 14, sm 16, md 18, lg 20, xl 22, xl2 30, xl3 36, xl4 48, xl5 60, xl6 72, xl7 96, xl8 108 (lines 406-522).
  - Desktop sizes are two steps smaller at the low end: xs3 8, xs2 10, xs 12, sm 14, md 16, lg 18, xl 20, xl2 22, xl3 30, xl4 36, xl5 48, xl6 60, xl7 72, xl8 96 (lines 523-640); heights are identical to touch.
  - Docs say the styles "only specify `fontSize` and `height`" (docs: concepts/themes.mdx); `inherit` additionally sets colour, family and fallback.
- `copyWith({TextStyle? xs3..xl8, extensions})` (`typography.dart:690`), `scale({double sizeScalar = 1})` multiplies `fontSize ?? 14`, leaves `height` alone (`typography.dart:741-762`), `lerp` (`typography.dart:645`).
- `abstract class FScalableExtension<T extends FScalableExtension<T>> extends ThemeExtension<T>` with `lerp`, `copyWith()`, `scale({double sizeScalar})` (`typography.dart:~886-912`).
- Which scale step a widget uses is fixed in that widget's `inherit`; e.g. `FFormFieldStyle.inherit` uses `body.xs` on touch and `body.sm` on desktop (`src/theme/form_field_style.dart:~38`).

### `FStyle` — misc tokens
- Constructor: `FStyle({required FFormFieldStyle formFieldStyle, required FFocusedOutlineStyle focusedOutlineStyle, required IconThemeData iconStyle, required FSizes sizes, required FTappableStyle tappableStyle, FBorderRadius borderRadius = const FBorderRadius(), double borderWidth = 1, EdgeInsets pagePadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 12), List<BoxShadow> shadow = [BoxShadow(color: 0x0d000000, offset: (0,1), blurRadius: 2)], Iterable<ThemeExtension<dynamic>> extensions = const []})` (`src/theme/style.dart:40-66`); `factory FStyle.inherit({required FColors colors, required FTypography typography, required bool touch})` (`style.dart:74-85`).
  - `inherit`: focus outline = `FFocusedOutlineStyle(color: colors.primary, borderRadius: borderRadius.md)`, `iconStyle = IconThemeData(color: colors.foreground, size: typography.body.lg.fontSize)`, `sizes = FSizes.inherit(touch)`.
- `copyWith({FFormFieldStyleDelta? formFieldStyle, FFocusedOutlineStyleDelta? focusedOutlineStyle, IconThemeDataDelta? iconStyle, FSizes? sizes, FTappableStyleDelta? tappableStyle, FBorderRadius? borderRadius, double? borderWidth, EdgeInsetsDelta? pagePadding, List<BoxShadow>? shadow, Set<ThemeExtension<dynamic>>? extensions})`, `lerp` (`style.design.dart:30-70`).
- Delta: `FStyleDelta.delta(...)`, `FStyleDelta.context()`; an `FStyle` is itself a delta (`call` returns itself) (`style.design.dart:74-77, 137-226`).
- **Two tappable styles exist**: `FThemeData.tappableStyle` (read by `FTappable`, `tappable.dart:587`) and `FThemeData.style.tappableStyle` (`style.dart:28`, used as a base by widget `inherit` constructors). They are separate objects; both default to `FTappableStyle()` (`theme_data.dart:726`, `style.dart:81`).
- `extension Decorations on Decoration` (`style.dart:~125-206`): best-effort getters `color, image, border, borderRadius, shadows, gradient, backgroundBlendMode`; only `BoxDecoration`/`ShapeDecoration` (else null).

### `FSizes`, `FBorderRadius`, `FFormFieldStyle` (sub-tokens of FStyle)
- `FSizes({required ({double xs, sm, md, lg}) field, required double item, required double tile, required double calendar})`; `FSizes.inherit({required bool touch})`: touch `field (32, 40, 44, 48), item 44, tile 48, calendar 44`; desktop `field (24, 32, 36, 40), item 30, tile 48, calendar 32`; `scale`, `copyWith`, `lerp` (`src/theme/sizes.dart:45-111`).
  **Doc: "Changing these values will not update the sizes of actual widgets"** (`sizes.dart:6`): reference tokens only.
- `FBorderRadius({BorderRadius xs2 = 4, xs = 6, sm = 8, md = 10, lg = 14, xl = 18, xl2 = 22, xl3 = 26, pill = 100})` (all `BorderRadius.all(Radius.circular(..))`), `scale(double)`, `copyWith`, `lerp` (`src/theme/border_radius.dart`).
- `FFormFieldStyle({required labelTextStyle, descriptionTextStyle, errorTextStyle})`: `FVariants<FFormFieldVariantConstraint, FFormFieldVariant, TextStyle, TextStyleDelta>` (error text uses `FFormFieldErrorVariant`); variants `disabled (tier 2), error (2), focused (1)` (`src/theme/form_field_style.dart:10-66`).

### `FIcons` / `FIcon` — icon tokens
- `FIcons({required FIcon arrowLeft, calendar, check, chevronDown, chevronLeft, chevronRight, chevronUp, chevronsUpDown, circleAlert, clock4, ellipsis, error, eye, eyeClosed, gripHorizontal, gripVertical, loader, loaderCircle, loaderPinwheel, search, userRound, x})` (22 icons, `src/theme/icons.dart:~25-60`); `const FIcons.lucide()` (`icons.dart:156`). **No `copyWith`/`lerp`** (none declared in `icons.dart`).
- `abstract interface class FIcon { const factory FIcon(IconData icon); Widget call(BuildContext context, {String? semanticsLabel}); }`. Built-in `_Icon` returns `Icon(icon, semanticLabel: semanticsLabel)` (`icons.dart:270-290`); custom `FIcon`s should inherit the ambient `IconTheme` and implement `==`/`hashCode` (docs: guides/customizing-icons.mdx).
- Used e.g. by `FFormFieldProperties.defaultErrorBuilder` (`context.theme.icons.error(context)`, `src/foundation/form_field_properties.dart:~16`).

### `FHapticFeedback` — haptic callbacks
- `const FHapticFeedback({Future<void> Function() heavyImpact, lightImpact, mediumImpact, selectionClick, successNotification, warningNotification, errorNotification, vibrate})` each defaulting to the matching `HapticFeedback.*`; `const FHapticFeedback.none()`; `static Future<void> noFeedback()`; `copyWith(...)` (`src/theme/haptic_feedback.dart:19-102`).
- Passed into styles by `inherit(hapticFeedback: ...)` (e.g. dialog, picker, slider, tooltip, tile group; `theme_data.dart:668-744`). `FTappable` itself does not call haptics; `FTappableGroup.slidePressHapticFeedback` defaults to `noFeedback` (`tappable_group.dart:47-53`).

### `FBreakpoints`
- `const FBreakpoints({double sm = 640, md = 768, lg = 1024, xl = 1280, xl2 = 1536})` (`src/theme/breakpoints.dart:44-60`). Custom breakpoints = extension getters on `FBreakpoints` (docs: concepts/responsive.mdx). See §3.

### Theme extensions
- `FColors`, `FTypography`, `FTypeface`, `FStyle`, `FThemeData` each take `extensions` and expose `extension<T>()` (throws on a missing type) and `extensions` (set). Typography extensions must extend `FScalableExtension` (they are `scale`d). Lerp merges by type (`theme_data.dart:890-892`, `colors.dart:~245`).

---

## 2. Styling and variants

### Variant model: `FVariantConstraint`, `FVariant`, `FPlatformVariant`, `toVariants`
- `sealed class FVariantConstraint` with `static T max<T>(T a, T b)` and `bool satisfiedBy(Set<FVariant>)` (`src/theme/variant.dart:35-98`).
- `sealed class FVariant implements FVariantConstraint { const factory FVariant(int priority, String value) }` (`variant.dart:106-109`). Equality and hash use **only the string** (`variant.dart:122-127`): same-named variants of different widgets are equal.
- Constraint composition: `<WidgetConstraint>.and(other)` (AND), `<WidgetConstraint>.not(variant)` (NOT); there is no OR operator: OR = several list keys in `FVariants(variants: {[a, b]: v})` (`variant.dart:133-175`; `snip:concepts/themes/components/variants.dart`).
- Each widget has a generated extension-type pair `F<X>VariantConstraint` / `F<X>Variant` (e.g. `FTappableVariant` in `src/foundation/tappable/tappable.design.dart:12-100`) that adds platform variants (`touch, desktop, android, iOS, fuchsia, windows, macOS, linux, web`).
- `Set<FVariant> toVariants(Set<WidgetState>)`: `disabled(2), error(2), selected(2), focused(1), hovered(1), pressed(1), dragged(1)` (`variant.dart:9-17`).
- Platform variants (`src/theme/variant_platform.dart`): `FPlatformVariant.android|iOS|fuchsia|windows|macOS|linux|web`, getters `touch`/`desktop` (`variant_platform.dart:85-91`).
  - `touch` constraint is satisfied by any of android/iOS/fuchsia; `desktop` by windows/macOS/linux; `web` is neither (`variant_platform.dart:94-232`).
  - A concrete platform counts as **2** tier-0 operands, `touch`/`desktop`/`web` as 1, so `android` beats `touch` (`variant_platform.dart:109-123`).
- Specificity (`FVariantConstraint.max`, `variant.dart:56-83`): compare per-tier operand counts from the highest tier down (more operands wins); tie -> more total operands; tie -> the lexicographically smaller sorted-operand string wins. `Not(x)` counts as one operand of x's tier (`variant.dart:164`).

### `FVariants<K, E, V, D>` — base value + constraint-keyed overrides
- Generics: `K` constraint type, `E` variant type, `V` value type, `D extends Delta` the delta for `V`. Implements `FVariantsDelta` and `FVariantsValueDelta` (so it can be passed anywhere a delta is accepted, replacing the value) (`src/theme/variants.dart:18-20`).
- Constructors (all in `variants.dart`):
  - `FVariants(V base, {required Map<List<K>, V> variants})` — each constraint in a list key maps to the same value (`variants.dart:127-131`).
  - `FVariants.from(V base, {required Map<List<K>, D> variants})` — each delta is applied to **`base`** (never to other entries) and stored (`variants.dart:134-145`).
  - `const FVariants.all(V base)` — no overrides (`variants.dart:148`).
  - `const FVariants.raw(V base, Map<K, V> variants)` — already-flat map (`variants.dart:151`).
- Field `base`, `variants` (`Map<K, V>`); `apply(List<FVariantOperation>)`, `applyValues(List<FVariantValueDeltaOperation>)`, `cast<T1, T2>()`.
- `V resolve(Set<FVariant> variants)` — exact algorithm (`variants.dart:173-191`):
  1. Iterate every entry; keep only entries whose constraint `satisfiedBy(variants)`.
     `satisfiedBy` is **subset matching**: a constraint matches when all of its operands are present in the active set; extra active variants never disqualify it (`variant.dart:85-95`, `And` `variant.dart:136`, `Not` `variant.dart:161`).
  2. Among matches keep the **most specific** per `FVariantConstraint.max` (tier counts, then operand count, then lexicographic order). Result is independent of map insertion order (except exactly-equal constraints).
  3. If nothing matches return `base`. There is **no partial/merge**: the winning entry's value replaces `base` wholesale (`V` is not composed from several matches).
  - Verified examples (`test:theme/variants_test.dart:186-190`): `{}` -> base; `{a:1}` with active `{a}` -> 1; active `{b}` -> base; `{a:1, ab:2}` with `{a,b}` -> 2 (more specific); `{a:1, b:2}` with `{a,b}` -> 1 (tie -> lexicographic).
  - Doc example: `{hovered}->A, {hovered&focused}->B, {disabled}->C`; `{hovered}` -> A, `{hovered,focused}` -> B, `{hovered,disabled}` -> C (tier 2 > tier 1), `{pressed}` -> base (`variants.dart:157-171`).
  - "Base vs exact vs subset" summary: `resolve` = *subset-match then most-specific-wins, else base*. `exact` / `match` below are **edit-time** operations on the map, not resolve modes.
- Lerp helpers (static): `lerpBoxDecoration, lerpDecoration, lerpColor, lerpIconThemeData, lerpTextStyle, lerpWhere, lerpWhereUsing`. **Only keys present in both maps are interpolated; keys in one side are dropped** (`variants.dart:79-118`).
- Equality: `base == && mapEquals(variants)`; `And` equality is symmetric but its `hashCode` is `Object.hash(left, right)` (order-dependent), so `a.and(b)` and `b.and(a)` are `==` with different hashes (`variant.dart:145-152`). UNVERIFIED whether this ever bites (not exercised).

### `FVariantsDelta<K, E, V, D>` + `FVariantOperation` — edit a `FVariants` of delta-able values (composite types: `TextStyle`, `BoxDecoration`, `IconThemeData`, nested styles)
- `FVariantsDelta.delta(List<FVariantOperation<K, E, V, D>> operations)`; applied in order (`variants.dart:257-274`). Used as e.g. `FAccordion(style: .delta(titleTextStyle: .delta([ .base(const .delta(color: red)), .exact({.hovered.and(.focused)}, .delta(decoration: () => .underline)), .match({.hovered}, const .delta(fontWeight: .bold)) ])))` (`snip:guides/customizing_widget_styles/deltas/variants/variants_delta.dart`); replacing wholesale uses `FVariants.from(...)` (`.../variants_replace.dart`).
- Operations (`variants.dart:277-411`): 
  - `base(D delta)` — delta on base only.
  - `exact(Set<K> constraints, D delta)` — for each given constraint **key** sets `delta(existing[constraint] ?? base)`; creates the entry if missing (key equality, not subset).
  - `match(Set<E> variants, D delta)` — applies to every *existing* entry whose constraint is `satisfiedBy(variants)` (i.e. all of the entry's operands are inside the given set); does nothing if none.
  - `variants(D delta)` — all entries, not base. `all(D delta)` — base and all entries.
  - `remove(Set<K>)` exact keys; `removeMatch(Set<E>)` entries satisfied by the set; `removeAll()`.

### `FVariantsValueDelta<K, E, V, D>` + `FVariantValueDeltaOperation` — same, for atomic values (`Color`, `double`, `MouseCursor`, ...)
- `FVariantsValueDelta.delta(List<FVariantValueDeltaOperation>)`; ops `base(V)`, `exact(Set<K>, V)`, `match(Set<E>, V)`, `variants(V)`, `all(V)`, `remove`, `removeMatch`, `removeAll` with the same semantics but replacing values (`variants.dart:414-558`).
- Which one a style delta accepts depends on `V`: e.g. `FTappableStyleDelta.delta(cursor: FVariantsValueDelta<..MouseCursor..>)` (`tappable.design.dart:~100`), `FThemeData.copyWith(buttonStyles: FVariantsDelta<..>)` (`theme_data.dart:1350`). Passing a whole `FVariants` replaces the field (docs: guides/customizing-widget-styles.mdx).

### Delta infrastructure (`src/theme/delta/*.dart`)
- `mixin Delta { Object call(covariant Object? value); }` (`delta.dart:190-201`). Convention: deltas for Flutter types accept nullable inputs; style deltas do not.
- `extension Sentinels on Never`: `nonNegativeInt, string, color, focusedOutlineStyle, shapeBorder, imageFilter, imageFilterFunction, borderRadius, boxBorder, decorationImage, gradient, fontWeight, locale` — internal "unset" markers compared with `identical` (`delta.dart:9-48`). Omitted argument = keep; explicit `null` = set null for plain nullable params; params typed `T? Function()?` set `T?` via a closure (e.g. `decoration: () => TextDecoration.underline`).
- `TextStyleDelta` (`text_style.dart`): `delta({inherit, color, backgroundColor, fontSize, fontWeight, fontStyle: FontStyle? Function()?, letterSpacing, wordSpacing, textBaseline: Fn, height, leadingDistribution: Fn, locale, foreground: Fn, background: Fn, shadows, fontFeatures, fontVariations, decoration: Fn, decorationColor, decorationStyle: Fn, decorationThickness, debugLabel, fontFamily, fontFamilyFallback, package, overflow: Fn})` and `value(TextStyle)`; `call(TextStyle?)` (`text_style.dart:6-108`).
- `DecorationDelta` (`decoration.dart:46-148`): `boxDelta({color, image, border, borderRadius, boxShadow, gradient, backgroundBlendMode: Fn, shape})` (always yields `BoxDecoration`; converts a `ShapeDecoration` best-effort), `shapeDelta({color, image, gradient, shadows, shape})` (always `ShapeDecoration`), `value(Decoration)`. Throws `UnsupportedError` for other `Decoration` types. `BoxDecorationDelta.delta/value` and `ShapeDecorationDelta.delta/value` are typed variants (`decoration.dart:6-43, 151-197`).
- `EdgeInsetsGeometryDelta` (`add(EdgeInsetsGeometry)`, `scale(double)`, `value`), `EdgeInsetsDelta` (`delta({left, top, right, bottom})` replaces only given edges, `add({...})`, `scale`, `value(EdgeInsets)`), `EdgeInsetsDirectionalDelta` (same with `start/end`) (`edge_insets_geometry.dart`).
- `IconThemeDataDelta.delta({color, opacity, size, fill, weight, grade, opticalSize, shadows, applyTextScaling: bool? Function()?})`, `value(IconThemeData)` (`icon_theme_data.dart`).
- Widget style deltas (generated `*.design.dart`), pattern `F<X>StyleDelta`: `const factory delta({<every style field as nullable delta/value>})`, `const factory context()` (= keep the ambient style), and the style class itself implements the delta (`call` returns itself, i.e. full replacement). Example: `FTappableStyleDelta` (`tappable.design.dart:~190-250`), `FStyleDelta` (`style.design.dart:137-226`). Motion classes have the same family (`FTappableMotionDelta.delta/context`).
- Custom deltas: implement the delta class and override `call` (docs: guides/creating-custom-deltas.mdx).

### `FAdaptiveScope` / `platformVariant`
- `class FAdaptiveScope extends InheritedWidget { FAdaptiveScope({required Widget child, FPlatformVariant? platform, Key? key}); static FPlatformVariant of(BuildContext) }` (`src/theme/adaptive_scope.dart:18-56`).
- `of` returns the ancestor's `platform`, else the host platform: web -> `.web`; otherwise `defaultTargetPlatform` mapped to android/iOS/fuchsia/windows/macOS/linux (`adaptive_scope.dart:21-37`). No ancestor needed.
- `FTheme`/`FBasicTheme` include one (`theme.dart:332`); `FTheme(platform: FPlatformVariant.iOS)` forces a platform variant (`snip:concepts/responsive/platform_override.dart`).
- Widgets read `context.platformVariant` to branch behaviour (not only styling), e.g. `FPopover` anchors (`popover.dart:462`), `FContextMenu` long-press vs secondary press (`context_menu.dart:403-409`), `FSlider` (`slider/track.dart:149`), `FSelect` `autofocusFirst` on desktop (`select/single/select.dart:916`), header `slidableActions` (`header/root_header.dart:33`), toasts (`toast/toast.dart:83`).

---

## 3. Responsive behaviour

- Two mechanisms only: (a) **platform variants** (touch vs desktop, see §2) and the two theme flavours `FTheme.neutral.<light|dark>.<touch|desktop>`; (b) `FBreakpoints` width thresholds (`sm 640, md 768, lg 1024, xl 1280, xl2 1536`, inclusive minimums) exposed as `context.theme.breakpoints` (`breakpoints.dart`; docs https://forui.dev/docs/concepts/responsive).
- ForUI does **not** pick touch vs desktop `FThemeData` from window size or platform; the app does (`snip:concepts/responsive/platform_variants.dart`).
- Library code consults `breakpoints` in exactly one place: `FDialog.adaptive` switches to `verticalBuilder` when `MediaQuery.sizeOf(context).width < breakpoints.sm`, else `horizontalBuilder` (`src/widgets/dialog.dart:342-353`; `rg 'breakpoints'` finds no other use). Default dialog constraints for `.adaptive`: `BoxConstraints(minWidth: 280, maxWidth: 560)`.
- No text-scale handling in the theme; `FTypeface.scale` is a static token scale (`typography.dart:741`). The project's own text-scale policy is out of scope here.
- Overlay positioning reacts to the viewport (`FPortalOverflow`, view padding and keyboard insets, §4).

---

## 4. Interaction foundations

### `FTappable` — pressable surface: hover/focus/press/selected variants, bounce, semantics, keyboard
- Import: `package:forui/forui.dart` (`foundation.dart` -> `src/foundation/tappable/tappable.dart:41`)
- Constructors (identical parameter list; **`FTappable(...)` is animated, `FTappable.static(...)` is not**):
  - `const FTappable({FTappableStyleDelta style = const FTappableStyleDelta.context(), FFocusedOutlineStyleDelta? focusedOutlineStyle, String? semanticsLabel, String? semanticsHint, String? semanticsTooltip, bool semanticsContainer = true, bool semanticsButton = true, bool? semanticsChecked, bool? semanticsExpanded, bool? semanticsInMutuallyExclusiveGroup, SemanticsRole? semanticsRole, bool excludeSemantics = false, bool autofocus = false, bool hoverFocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, bool selected = false, bool selectable = false, HitTestBehavior behavior = HitTestBehavior.translucent, GestureTapDownCallback? onPressDown, GestureTapCancelCallback? onPressCancel, GestureTapMoveCallback? onPressMove, GestureTapUpCallback? onPressUp, VoidCallback? onPress, VoidCallback? onDisabledPress, GestureLongPressDownCallback? onLongPressDown, GestureLongPressCancelCallback? onLongPressCancel, GestureLongPressStartCallback? onLongPressStart, GestureLongPressMoveUpdateCallback? onLongPressMove, GestureLongPressEndCallback? onLongPressEnd, VoidCallback? onLongPress, GestureTapDownCallback? onDoubleTapDown, GestureTapCancelCallback? onDoubleTapCancel, VoidCallback? onDoubleTap, GestureTapDownCallback? onSecondaryPressDown, GestureTapCancelCallback? onSecondaryPressCancel, GestureTapUpCallback? onSecondaryPressUp, VoidCallback? onSecondaryPress, GestureLongPressDownCallback? onSecondaryLongPressDown, GestureLongPressCancelCallback? onSecondaryLongPressCancel, GestureLongPressStartCallback? onSecondaryLongPressStart, GestureLongPressMoveUpdateCallback? onSecondaryLongPressMove, GestureLongPressEndCallback? onSecondaryLongPressEnd, VoidCallback? onSecondaryLongPress, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions, ValueWidgetBuilder<Set<FTappableVariant>> builder = FTappable.defaultBuilder, Widget? child, Key? key})` = redirecting factory to `AnimatedTappable` (`tappable.dart:348-400`).
  - `const FTappable.static({... same params ...})` (`tappable.dart:406-461`).
  - **Required**: none, but `assert(builder != defaultBuilder || child != null)` -> pass `child` or `builder` (`tappable.dart:461`).
- Key optional parameters:
  - `builder(context, Set<FTappableVariant> variants, Widget? child)` receives the live variant set (includes the platform variant); `defaultBuilder` returns `child!` (`tappable.dart:43, 336`).
  - Disabled = **no primary or secondary gesture callback at all** (`_disabled`, `tappable.dart:527`, `_hasPrimaryCallback` `:530-545`, `_hasSecondaryCallback` `:547-558`). `onDisabledPress` does not enable it; it keeps the visual/semantic disabled state but still makes it focusable and activatable (`tappable.dart:173-179, 525, 738`).
  - `onPress` runs after `onPressUp`; `onDoubleTap*` / secondary callbacks stay on the tappable even inside a `FTappableGroup` (`tappable_group.dart:8-15`).
  - `hoverFocus`: hover requests focus, unhover unfocuses (`tappable.dart:751-760`).
  - `selected` adds `FTappableVariant.selected`; `selectable: true` lets descendant text join an enclosing `SelectionArea` (default wraps in `SelectionContainer.disabled`, `tappable.dart:703-705`).
  - `focusedOutlineStyle` null (default) = **no outline is drawn**; non-null wraps the result in `FFocusedOutline` driven by the `focused` variant (`tappable.dart:861-863`).
  - `shortcuts` default `{SingleActivator(.enter): ActivateIntent()}` only if `onPress` or `onDisabledPress` is non-null; `actions` default maps `ActivateIntent` to `_onPress` (`tappable.dart:458-460, 721-735`). Space/numpad-enter are **not** bound by FTappable: UNVERIFIED for a given app; they work only when an ambient `WidgetsApp.defaultShortcuts` maps Space to `ActivateIntent` (Flutter `app.dart:1265-1269`) and the test suite only exercises Enter (`test:foundation/tappable/tappable_test.dart:179,504,712`).
- State / control: no `control:`; state is internal `Set<FTappableVariant> _current` seeded from `selected`, `autofocus`, `_disabled` (`tappable.dart:576-583`). `onVariantChange(previous, current)` fires on add/remove through `_update` (`tappable.dart:632-639`) (focus/hover/press updates; platform variant is added silently in `didChangeDependencies`, `tappable.dart:603-608`).
- Interaction states / variants (`FTappableVariant`): `disabled(2), selected(2), primaryFocused(1), focused(1), hovered(1), pressed(1)` plus platform variants `android, iOS, fuchsia, windows, macOS, linux, web` (+ constraints `touch`, `desktop`) (`tappable.dart:17-24`, `tappable.design.dart:12-100`).
  - `focused`/`primaryFocused` are only tracked while `context.accessibility.focusHighlight` is true (keyboard/traditional focus mode); otherwise they are removed (`tappable.dart:588-601, 741-744`).
  - `pressed` is applied only after `pressedEnterDuration` (default 100 ms) and removed after `pressedExitDuration` (100 ms); a press released earlier than 100 ms never reports `pressed` (stale-timer guard `count == _monotonic`, `tappable.dart:871-909`). The bounce starts immediately (`tappable.dart:871-873`).
  - Nested tappables: only the deepest enabled tappable claims a pointer for press visuals; hovering an inner one also hovers ancestors (doc `tappable.dart:37-38`, `_claims` `tappable.dart:560, 765-785`; tests `test:foundation/tappable/tappable_test.dart:1019-1144`).
- Focus & semantics (source):
  - `Focus(autofocus, focusNode: _focus, canRequestFocus: !_disabled || onDisabledPress != null)`; owns the node unless `focusNode` is passed (`tappable.dart:737-748`, `dispose` `:645-657`).
  - `Semantics(enabled: !_disabled, label, hint, tooltip, container, button, checked, expanded, inMutuallyExclusiveGroup, role, selected: semanticsChecked == null ? selected : null, excludeSemantics)`; `onTap`/`onLongPress` semantic actions are set only when `excludeSemantics` or inside a `FTappableGroup` (to avoid double actions) (`tappable.dart:707-735`).
  - `semanticsTooltip` must be set when the tappable is wrapped in `FTooltip` (doc template `src/foundation/doc_templates.dart:101-107`).
  - Cursor: `MouseRegion(cursor: style.cursor.resolve(_current))` (`tappable.dart:749`); **default cursor is `MouseCursor.defer`** (`tappable.dart:1061-1070`).
  - Pointer handling uses a separate `Listener` plus `GestureDetector` (so wrapping `GestureDetector`s are not starved) (`tappable.dart:763-855`).
- Motion: only on `FTappable(...)`. `AnimatedTappableState` drives a `Bounce` render object (scale paint transform) with `AnimationController` + `CurvedAnimation` (`tappable.dart:985-1058`, `src/foundation/tappable/bounce.dart`).
  - `FTappableMotion({bounceDownDuration = 100ms, bounceUpDuration = 100ms, bounceDownCurve = easeOutQuart, bounceUpCurve = easeOutCubic, Animatable<double> bounceTween = FTappableMotion.defaultBounceTween (1.0 -> 0.97), double? bounceFloor = 5})` (`tappable.dart:1082-1119`). `bounceFloor` caps the shrink in pixels (floor = `1 - bounceFloor / size.longestSide`, `bounce.dart:48-54`).
  - Constants: `FTappableMotion.none`, `defaultBounceTween`, `noBounceTween` (`tappable.dart:1112-1119`).
  - **Reduced motion**: only `FAccessibilityMotion.disabled` switches to `FTappableMotion.none`; `reduced` still bounces (`tappable.dart:1013`).
  - Bounce triggers only when the pressed button has a matching callback kind (`_animate(buttons)`, `tappable.dart:513-515`; tests `...tappable_test.dart:227-298`).
- Styling: `FTappableStyle({FVariants<FTappableVariantConstraint, FTappableVariant, MouseCursor, Delta> cursor = FVariants.all(MouseCursor.defer), Duration pressedEnterDuration = 100ms, Duration pressedExitDuration = 100ms, FTappableMotion motion = const FTappableMotion()})`; delta `FTappableStyleDelta` (`.delta(cursor: FVariantsValueDelta?, pressedEnterDuration, pressedExitDuration, motion: FTappableMotionDelta?)`, `.context()`); resolved via `widget.style(context.theme.tappableStyle)` (`tappable.dart:587, 1061-1076`, `tappable.design.dart`). `FTappableStyle.lerp` snaps `cursor` and durations at `t < 0.5` (`tappable.design.dart:~125`).
- Limitations / caveats:
  - Hard-coded: Enter-only default shortcut; `behavior` default translucent; no per-state haptic hook.
  - `FTappableStyle.motion` is the only bounce switch; there is no widget-level `motion:` parameter, so a per-instance no-bounce choice is `style: .delta(motion: .delta(bounceTween: FTappableMotion.noBounceTween))` or `FTappable.static` (docs: widgets/foundation/tappable.mdx).
  - Outer `FTappableGroup` + `OverlayPortal` content needs `FTappableGroup.isolate` (done automatically by `FPortal`/`FOverlay`) (`doc_templates.dart:112-123`).
- Evidence: `src/foundation/tappable/tappable.dart`, `tappable.design.dart`, `bounce.dart`; docs https://forui.dev/docs/widgets/foundation/tappable; tests `test:foundation/tappable/tappable_test.dart`.

### `FTappableGroup` — slide-across press transfer between tappables
- `const FTappableGroup({required Widget child, Future<void> Function() slidePressHapticFeedback = FHapticFeedback.noFeedback, Key? key})`; `static Widget isolate({required Widget child})` stops descendants registering with an ancestor group (`src/foundation/tappable/tappable_group.dart:24-53`).
- Mechanism: a custom `TappableGroupGestureRecognizer` (RawGestureDetector) owns primary press/long-press for registered tappables; the pressed state follows the finger. Long-press on A then release on B fires `A.onLongPress` and `B.onPress` (doc `tappable_group.dart:17-21`; tests `test:foundation/tappable/tappable_test.dart:773-943`).

### `FFocusedOutline` — layout-neutral focus ring
- `const FFocusedOutline({required bool focused, required Widget child, FFocusedOutlineStyleDelta style = const FFocusedOutlineStyleDelta.context(), Key? key})`, a `SingleChildRenderObjectWidget` (`src/foundation/focused_outline.dart:21-55`).
- Painted only when `context.accessibility.focusHighlight && focused` (`focused_outline.dart:45, 54`; changelog 0.27.0 "outline painted after pointer click" fixed as a breaking change, `CHANGELOG.md`).
- Paint: strokes a `RoundedSuperellipseBorder` path of `(offset & size).inflate(spacing)` after the child; `spacing` is clamped to `>= -min(width, height)/2` (`focused_outline.dart:74-88`). `paintBounds` grows by `spacing` only while focused (`:91`).
- Style: `FFocusedOutlineStyle({required Color color, required BorderRadiusGeometry borderRadius, double width = 1, double spacing = 3})` (assert `0 < width`) (`focused_outline.dart:131-148`). Default comes from `FThemeData.style.focusedOutlineStyle` (colour `colors.primary`, radius `borderRadius.md`, `style.dart:78`). Delta/copyWith/lerp in `focused_outline.design.dart`.
- Limitations: stroke-only (no fill); one ring shape (superellipse).

### `FCollapsible` — clip/size a child by a 0..1 value (no animation of its own)
- `const FCollapsible({required double value, required Widget child, Axis axis = Axis.vertical, Key? key})` (`src/foundation/collapsible.dart:12-23`).
- Layout: child is laid out unconstrained by `value` (`constraints.normalize()`), the box's size = child size x `value` along `axis`, content clipped by `ClipRect` (`collapsible.dart:28-39, 69-131`).
- Semantics/focus: `ExcludeSemantics` and `ExcludeFocus` apply **only when `value == 0` exactly** (`collapsible.dart:32-34`). Hit tests are limited to the visible size (`:93-100`).
- Motion: none built in; caller animates `value` (used by accordion/sidebar/label error).

### `FOverlay` — low-level overlay primitive; Positioned children relative to a child
- `const FOverlay({required List<Widget> overlay, FOverlayControl control = const FOverlayControl.managed(), FOverlayBuilder overlayBuilder = FOverlay.defaultOverlayBuilder, OverlayChildLocation overlayLocation = OverlayChildLocation.nearestOverlay, ValueWidgetBuilder<OverlayPortalController> builder = FOverlay.defaultBuilder, Widget? child, Key? key})`; `assert(builder != defaultBuilder || child != null)` (`src/foundation/overlay/overlay.dart:123-131`).
  `typedef FOverlayBuilder = List<Widget> Function(BuildContext, OverlayPortalController, RenderBox? childRenderBox, List<Widget> overlay)` (`overlay.dart:12-17`).
- State / control: `FOverlayControl` (below). The state holds one `OverlayPortalController`, created in `initState` and replaced by `control.update(old, controller)` in `didUpdateWidget` (`overlay.dart:148-163`).
- Implementation: Flutter `OverlayPortal` + `CompositedChild`/`CompositedOverlay` layer link; content is wrapped in `FTappableGroup.isolate` and an `_UnclippedStack` whose `hitTest` ignores the stack's own bounds (overflowing children are hit-testable) (`overlay.dart:165-209`). The child is wrapped in a `RepaintBoundary`.
- Caveats: needs an `Overlay` ancestor (via `OverlayPortal`); positions use the previous frame's child size (don't use `Positioned.right/bottom` with a resizing child) (`overlay.dart:39-68`).
- Docs: https://forui.dev/docs/widgets/foundation/overlay

### `FOverlayControl` — managed / lifted state for `FOverlay`, `FPortal`, `FPointPortal`
- `sealed class FOverlayControl`: `const factory FOverlayControl.managed({OverlayPortalController? controller, bool? initial})` -> `FOverlayManagedControl` (assert not both; `initial: true` calls `show()` in `createController`); `const factory FOverlayControl.lifted({required bool shown, required ValueChanged<bool> onChange})` (`src/foundation/overlay/overlay_controller.dart:9-75`).
- Lifted: `shown` is mirrored onto the controller on every update (`_updateController`, `overlay_controller.dart:68-74`). **`FOverlay`/`FPortal`/`FPointPortal` never call `onChange`** (`OverlayPortalController` is not observable; `rg onChange` in `foundation/overlay` finds none), so `onChange` fires only if a higher-level widget invokes it. Control-type switches create a new controller (`overlay_controller.control.dart:~40-100`).
- The managed controller is created but never disposed by these widgets (`OverlayPortalController` has no `dispose`).

### `FPortal` — overlay anchored to the child's edges, with overflow handling
- `const FPortal({required Widget Function(BuildContext, OverlayPortalController, ValueListenable<FPortalGeometry?>) portalBuilder, FOverlayControl control = .managed(), FPortalConstraints constraints = const FPortalConstraints(), AlignmentGeometry portalAnchor = Alignment.topCenter, AlignmentGeometry childAnchor = Alignment.bottomCenter, FPortalSpacing spacing = FPortalSpacing.zero, FPortalOverflow overflow = FPortalOverflow.flip, Offset offset = Offset.zero, bool useViewPadding = true, bool useViewInsets = true, EdgeInsetsGeometry padding = EdgeInsets.zero, OverlayChildLocation overlayLocation = .nearestOverlay, bool traversalGrouped = true, Widget Function(RenderBox? cutout)? barrier, ValueWidgetBuilder<OverlayPortalController> builder = FOverlay.defaultBuilder, Widget? child, Key? key})` (`src/foundation/overlay/portal.dart:137-155`). `portalBuilder` got a third `geometry` parameter in 0.27.0 (breaking, `CHANGELOG.md`).
- Placement order: anchors -> `spacing` -> `overflow` -> `offset` (`portal.dart:47-67`). Safe-area/keyboard: `max(viewPadding, viewInsets) + padding`; the portal rebuilds on `didChangeMetrics` while showing so it clears the keyboard even under an inset-consuming `Scaffold` (`portal.dart:202-211, 228-248`).
- Focus: when `traversalGrouped` (default) child gets `NumericFocusOrder(0)` and content `NumericFocusOrder(1)` within an `OrderedTraversalPolicy` group, so Tab goes child then content; set false for combobox-like widgets (`portal.dart:107-114, 214-218, 276-291`).
- Semantics: `barrier` (if any) is wrapped in `BlockSemantics(blocking: false)` + `Semantics(container: true)`; source comment records a **known limitation: semantics blocking does not work correctly** here (`portal.dart:256-270`).
- Content gets `FTappableGroup.isolate` (`portal.dart:273-275`).
- Helper types:
  - `FPortalConstraints`: `sealed`, `const FPortalConstraints({minWidth, maxWidth, minHeight, maxHeight})`, `.tightFor({width, height})`; `FAutoHeightPortalConstraints({minWidth, maxWidth})` (portal height = child height), `FAutoWidthPortalConstraints({minHeight, maxHeight})` (`portal_constraints.dart`).
  - `FPortalOverflow`: `flip` (flip axis, then slide), `slide`, `allow`; custom = implement `Offset call(Size view, FPortalChildRect child, FPortalRect portal)` (`portal_overflow.dart:17-31`).
  - `FPortalSpacing(double spacing, {bool diagonal})` / `.spacing(...)`, `FPortalSpacing.zero` (`portal_spacing.dart:9-25`).
  - `FPortalArrowAlignment` (`childCenter`, `.start(offset)`, `.end(offset)`, `.fraction(f)`), `FPortalArrowDecoration` (wraps a `Decoration`, needs inside-aligned outlined border, no image) and `FPortalArrowStyle` (copyWith/lerp generated) and `typedef FPortalGeometry = ({Rect child, Size portal})` (`portal_arrow_*.dart`).
- Docs: https://forui.dev/docs/widgets/foundation/portal

### `FPointPortal` — overlay anchored at a point inside the child's local coordinates
- `const FPointPortal({required Widget Function(BuildContext, OverlayPortalController) portalBuilder, required Offset point, FOverlayControl control = .managed(), BoxConstraints constraints = const BoxConstraints(), AlignmentGeometry anchor = Alignment.topLeft, double spacing = 0, FPortalOverflow overflow = .flip, Offset offset = .zero, bool useViewPadding = true, bool useViewInsets = true, EdgeInsetsGeometry padding = .zero, OverlayChildLocation overlayLocation = .nearestOverlay, Widget Function(RenderBox? cutout)? barrier, ValueWidgetBuilder<OverlayPortalController> builder = FOverlay.defaultBuilder, Widget? child, Key? key})` (`src/foundation/overlay/point_portal.dart:120-137`). Differs from `FPortal`: single `anchor`/`spacing` double, plain `BoxConstraints`, no `traversalGrouped`, no `geometry` argument.
- Same keyboard-metrics rebuild (`point_portal.dart:181-190`) and tappable-group isolation as `FPortal`.
- Docs: https://forui.dev/docs/widgets/foundation/point-portal

### `FModalBarrier` / `FAnimatedModalBarrier` — scrim that blocks interaction (used by dialog/sheet/portal `barrier:`)
- `const FModalBarrier({required ImageFilter? filter, required VoidCallback? onDismiss, RenderBox? cutout, void Function(Path, Rect) cutoutBuilder = defaultCutoutBuilder, String? semanticsLabel, bool? barrierSemanticsDismissible = true, ValueNotifier<EdgeInsets>? clipDetailsNotifier, String? semanticsOnTapHint, Key? key})`; `FAnimatedModalBarrier` adds `required Animation<double> animation` and a `filter(context, value)` function (`src/foundation/barrier.dart:59-70, 184-195`).
- The barrier has **no colour**, only an optional `ImageFilter` (blur/tint via the filter) (`barrier.dart:~206-215`). With no `onDismiss`, a tap plays `SystemSound.alert` (`barrier.dart:~203`). Barrier semantics are exposed only on android/iOS/macOS and only when `onDismiss != null` (`barrier.dart:~196-200`).
- Reduced motion: `FAnimatedModalBarrier` uses animation value `1.0` when `FAccessibilityMotion.disabled` (`barrier.dart:76`).

### Other `foundation.dart` exports (brief)
- `FChangeNotifier` (disposed flag), `FMultiValueNotifier<T>` (see §7), `FTime(hour, minute)` (`time.dart`), `FImmutableTween<T>({required begin, required end})` (`tween.dart`), `FFormFieldProperties<T>` mixin (label/description/errorBuilder/enabled/onSaved/onReset/validator/autovalidateMode/forceErrorText; `defaultErrorBuilder` prefixes `theme.icons.error`, `form_field_properties.dart`), `FTypeaheadController`, `enum FLayout {ltr, rtl, ttb, btt}` with `vertical` flag (`rendering.dart:5-22`).

---

## 5. Focus and semantics foundations (summary)

| Concern | Where | What the source does |
|---|---|---|
| Focus highlight gating | `accessibility.dart:128`, `focused_outline.dart:45`, `tappable.dart:588-601` | `FAccessibility.focusHighlight` = `FocusManager.highlightMode == traditional` (keyboard mode); outline and `focused`/`primaryFocused` variants appear only when true |
| Focus node ownership | `tappable.dart:572, 645-657` | `FTappable` creates and disposes its node unless `focusNode:` supplied |
| Disabled but focusable | `tappable.dart:738`, doc `:173-179` | `onDisabledPress` makes a disabled tappable focusable/activatable |
| Keyboard activation | `tappable.dart:458-460, 721-735` | Enter -> `ActivateIntent` -> `onPress`; Space relies on app-level default shortcuts (UNVERIFIED) |
| Semantics node | `tappable.dart:707-735` | button/enabled/selected/checked/expanded/role/tooltip flags as parameters, see `FTappable` entry |
| Merge semantics | `semanticsContainer`, `excludeSemantics` | `excludeSemantics` replaces child semantics and forwards `onTap`/`onLongPress` onto the node |
| Collapsed content | `collapsible.dart:32-34` | excluded from semantics and focus only when `value == 0` |
| Portal tab order | `portal.dart:216-217, 276-277, 290` | child then content (`NumericFocusOrder` 0/1), opt-out `traversalGrouped: false` |
| Modal barrier semantics | `barrier.dart:196-244`, `portal.dart:256-270` | `BlockSemantics` + dismiss action on android/iOS/macOS only; portal barrier blocking is a documented known limitation |
| Form-field semantics helper | `doc_templates.dart:93-108` | `semanticsLabel`, `semanticsTooltip` doc templates (tooltip needed when wrapped by `FTooltip`) |
| Text selection | `tappable.dart:703-705` | text inside a tappable is not selectable unless `selectable: true` |

---

## 6. Motion and animation

### `FAccessibility`, `FAccessibilityScope`, `FAccessibilityContext` — how reduced motion is read
- `enum FAccessibilityMotion { all, reduced /* iOS */, disabled /* Android, web */ }` (`src/foundation/accessibility.dart:7-20`).
- `FAccessibility({required bool accessibleNavigation, required FAccessibilityMotion motion, required bool focusHighlight})`, `copyWith` (`accessibility.dart:23-48`).
- `FAccessibilityScope({required Widget child, FAccessibility? data})`: when `data` is null it observes the platform via `WidgetsBindingObserver.didChangeAccessibilityFeatures` and `FocusManager` highlight-mode listener (`accessibility.dart:118-161`). Mapping: `features.disableAnimations ? disabled : features.reduceMotion ? reduced : all`; `accessibleNavigation = features.accessibleNavigation`; `focusHighlight = highlightMode == traditional` (`accessibility.dart:119-130`). An explicit `data` freezes the value (`_update` skips when `widget.data != null`, `:148`).
- Read it with `context.accessibility.motion | .accessibleNavigation | .focusHighlight` (`FAccessibilityContext`, `accessibility.dart:165-174`); an `InheritedModel` per aspect, so a widget rebuilds only for the aspect it reads (`accessibility.dart:176-192`).
- **No fallback**: the static `...Of` helpers force-unwrap the ancestor (`!`, `accessibility.dart:80-97`); `FTheme`/`FBasicTheme` provide the scope (`theme.dart:330`). A ForUI widget that reads `context.accessibility` outside any `FTheme`/`FBasicTheme`/`FAccessibilityScope` will throw a null-check error (reading of code, not executed). Contrast `FTheme.of`/`FAdaptiveScope.of`, which fall back.
- Override per app: `FTheme(accessibility: FAccessibility(...))`.
- Call sites (what each widget does with it; `rg` over `src/`):
  - `motion == disabled` only: `FTappable` bounce -> none (`tappable.dart:1013`), `FCheckbox` (`checkbox.dart:106`), `FRadio` (`radio.dart:108`), `FAvatar` fade (`avatar/avatar_content.dart:22`), `FProgress`/`FCircularProgress`/`FDeterminateProgress` (`progress.dart:86`, `circular_progress.dart:134`, `determinate_progress.dart:91`), `FCalendar` day picker scroll (`calendar/day/day_picker.dart:347`), `FAnimatedModalBarrier` (`barrier.dart:76`).
  - `motion != all` (reduced or disabled): `FAccordion` (`accordion/accordion_item.dart:129`), `FTabs` (`tabs/tabs.dart:159,166`), `FPicker` (`picker/picker.dart:112`), `FCalendar` controller + header (`calendar/calendar.dart:395,405`, `calendar/header.dart:337`), `FLabel` (`label/label.dart:266,318`), `FToaster`/toast (`toast/toaster_stack.dart:66`, `animated_toast.dart:292` also with `accessibleNavigation`).
  - Three-way (`reduced` = fade only, `disabled` = none): `FDialog` (`dialog.dart:423`), `FSheet` (`sheet/sheet.dart:168`), `FPopover` (`popover/popover.dart:461`), `FTooltip` (`tooltip/tooltip.dart:230`), `FContextMenu` (`context_menu.dart:405`), `FSidebarItem` (`sidebar/sidebar_item.dart:150`), `FPickerWheel` (`picker/picker_wheel.dart:145`). Class docs state the same rule (e.g. `dialog.dart:555-557`, `popover.dart:711-713`, `tooltip.dart:482-484`, `sheet.dart:304-306`).
  - Toasts auto-dismiss when `accessibleNavigation` is true (changelog 0.27.3; `animated_toast.dart:252`).
  - `FTheme`'s own colour/theme lerp does not read it (`theme.dart:225-266`).

### Motion style types
Every `*Motion` class below is a `const` value class with generated `copyWith`/`lerp`/`F*MotionDelta`; each hangs off its widget style (the owning widget's catalog entry has the field name). Defaults copied from source.

| Class (file:line) | Fields (default) |
|---|---|
| `FThemeMotion` (`theme/theme.dart:283`) | `duration 200ms`, `curve linear` |
| `FTappableMotion` (`foundation/tappable/tappable.dart:1082`) | bounceDownDuration 100ms, bounceUpDuration 100ms, bounceDownCurve easeOutQuart, bounceUpCurve easeOutCubic, bounceTween 1.0->0.97, bounceFloor 5 |
| `FAccordionMotion` (`widgets/accordion/accordion.dart:204`) | expand/collapseDuration 200ms; expandCurve easeOutCubic; collapseCurve easeInCubic; iconExpand/CollapseCurve easeOut; revealTween 0->1; iconTween 0->0.5 |
| `FCheckboxMotion` (`widgets/checkbox.dart:294`) | fadeIn/OutDuration 100ms; fadeIn/OutCurve linear |
| `FRadioMotion` (`widgets/radio.dart:274`) | transitionDuration 100ms, transitionCurve linear, select/unselectDuration 100ms, selectCurve easeOutCirc |
| `FDialogRouteMotion` (`widgets/dialog.dart:219`) | entrance/exitDuration 150ms; barrierCurve ease |
| `FDialogMotion` (`widgets/dialog.dart:558`) | expandCurve easeOutCubic; collapseCurve easeInCubic; fadeIn/OutCurve linear; scaleTween 0.95->1; fadeTween 0->1; insetDuration 100ms; insetCurve decelerate |
| `FSheetMotion` (abstract) / `FModalSheetMotion` / `FPersistentSheetMotion` (`widgets/sheet/sheet.dart:307`, `modal_sheet.dart:378`, `persistent_sheet.dart:328`) | expand/collapseDuration 200ms; curve easeOutCubic; modal adds barrierCurve easeOutCubic |
| `FLabelMotion` (`widgets/label/label.dart:418`) | textStyleTransition 100ms/linear; errorExpand/Collapse 100ms/easeOut; errorFadeIn/Out 100ms/linear; errorFadeTween (default/`noErrorFadeTween`) |
| `FPopoverMotion` (`widgets/popover/popover.dart:714`) | entrance/exit 100ms; expandCurve easeOutCubic; collapseCurve easeInCubic; fadeIn/OutCurve linear; scaleTween 0.93->1; fadeTween 0->1 |
| `FPopoverMenuMotion` (`widgets/popover_menu/popover_menu.dart:700`) | fade 0.4; fadeDuration 100ms; fadeCurve linear (submenu fade) |
| `FTooltipMotion` (`widgets/tooltip/tooltip.dart:485`) | entrance/exit 100ms; expand/collapseCurve easeOutCubic; fadeIn/OutCurve linear; scaleTween 0.93->1; fadeTween 0->1 |
| `FToasterMotion` (`widgets/toast/toaster_style.dart:128`) | expandDuration 400ms; collapseDuration 300ms; expandCurve easeOutCubic; collapseCurve easeOut |
| `FToastMotion` (`widgets/toast/toaster_style.dart:260`) | entrance 400ms, dismiss 300ms, transition 400ms, reentrance 400ms, exit 400ms, swipeCompletion 150ms; curves easeOutCubic (swipeCompletion easeInCubic); entranceDismissFadeTween 0->1 |
| `FTabMotion` (`widgets/tabs/tab_controller.dart:141`) | duration 300ms; curve easeOutCubic |
| `FSidebarItemMotion` (`widgets/sidebar/sidebar_item.dart:386`) | expand 200ms / collapse 150ms; expandCurve easeOutCubic; collapseCurve easeInCubic; fade curves linear; iconExpand/CollapseCurve easeOut; reveal/fadeTween 0->1; iconTween 0->0.25 |
| `FProgressMotion` (`widgets/progresses/progress.dart:180`) | period 1000ms; interval 500ms; curve ease; value 0.4 |
| `FCircularProgressMotion` (`.../circular_progress.dart:294`) | duration 1s; curve linear; tween 0->1 |
| `FDeterminateProgressMotion` (`.../determinate_progress.dart:169`) | duration 1000ms; curve linear |

Animation knobs that are **not** in a `*Motion` class: `FAvatarStyle.fadeInDuration 500ms` (`avatar/avatar.dart:101`), calendar header `animationDuration 100ms` (`calendar/header.dart:397`), toaster `expandHoverEnter/ExitDuration 200ms` (`toast/toaster_style.dart:43,49`), select scroll-handle `enterDuration 200ms` (`select/content/scroll_handle.dart:147`), method parameters `duration/curve` on `FCalendarController` navigation (200ms/ease, `calendar/calendar_controller.dart:130-313`), `FLineCalendarScrollController` (300ms/easeOutCubic, `line_calendar/line_calendar_scroll_controller.dart:78`), and `duration/curve` on lifted picker/time/date-time controls (§7).

---

## 7. Controls and state concept

### The `control:` pattern
- Widgets take `control: F<X>Control` instead of a raw controller. Two kinds (docs: concepts/controls.mdx, https://forui.dev/docs/concepts/controls):
  - **Managed**: `control: .managed(...)`; widget owns the state through an internal controller built from the passed initial/config, **or** a caller-supplied `controller:` (caller disposes). `controller` cannot be combined with `initial`/`min`/`max`/other config (asserts, e.g. `notifiers.dart:219-232`, `overlay_controller.dart:37-40`).
  - **Lifted**: `control: .lifted(value:, onChange:)`; parent is the source of truth. The widget reflects the passed value; a user interaction calls `onChange(newValue)` and the visible state changes only when the parent rebuilds with a new value. Implemented with a proxy notifier: `_ProxyNotifier.update/value=` call `_onChange` and do not mutate `super.value`; `_update(newValue)` applies the parent's value (`notifiers.dart:120-153`).
- Lifecycle on `didUpdateWidget`: the generated `_update(old, controller, callback)` decides whether to keep or recreate the controller across managed external -> external, internal <-> external, lifted <-> managed switches, removing listeners/disposing only what the widget owns (`notifiers.control.dart:48-85, 124-157`; same shape in `overlay_controller.control.dart`). Generated by `ControlGenerator` for 22 files (`rg 'ControlGenerator'`).
- Custom controllers: subclass the managed control and override `createController()` (always return `controller` if non-null) or pass an external controller (docs: guides/creating-custom-controllers.mdx).
- Default when a widget's `control` param is omitted is usually `.managed()` (e.g. `FOverlay` `overlay.dart:125`, `FMultiValueControl` users `select_group.dart:81`).

### `FMultiValueNotifier<T>` / `FMultiValueControl<T>` / `FChangeNotifier` (foundation)
- `FChangeNotifier` (`ChangeNotifier` + `bool disposed`) (`src/foundation/notifiers.dart:10-29`).
- `FMultiValueNotifier<T>({Set<T> value = const {}, int min = 0, int? max})` extends `ValueNotifier<Set<T>>`; `factory FMultiValueNotifier.radio([T? value])` (single value); `bool contains(T)`; `update(T value, {required bool add})` honours `min`/`max` (silently ignores a violating add/remove); setting `value` throws `ArgumentError` if outside `[min, max]` (`notifiers.dart:32-96`). Error text when only `min` is set reads "must be <= $_min" (`notifiers.dart:78-82`), apparently inverted (cosmetic).
- `FMultiValueControl<T>`: `.managed({FMultiValueNotifier<T>? controller, Set<T>? initial, int min, int? max, ValueChanged<Set<T>>? onChange})`, `.managedRadio({controller, T? initial, onChange})`, `.lifted({required Set<T> value, required ValueChanged<Set<T>> onChange})` (`notifiers.dart:158-179`).
  Lifted variant builds a `_ProxyNotifier` with **no min/max** (`notifiers.dart:121-124, 272`), so min/max are not enforced when lifted.
- Used by `FSelectGroup` and `FSelectTileGroup` (`widgets/select_group/select_group.dart:81`, `select_tile_group/select_tile_group.dart:24`).

### Control catalogue (declared factories; owning widget catalogues give semantics)
| Control (file) | Managed | Lifted |
|---|---|---|
| `FOverlayControl` (`foundation/overlay/overlay_controller.dart`) | `.managed({OverlayPortalController? controller, bool? initial})` | `.lifted({required bool shown, required ValueChanged<bool> onChange})` |
| `FMultiValueControl<T>` (`foundation/notifiers.dart`) | `.managed`, `.managedRadio` | `.lifted({required Set<T> value, onChange})` |
| `FPopoverControl` (`widgets/popover/popover_controller.dart:180`) | `.managed({FPopoverController? controller, bool? initial, ValueChanged<bool>? onChange})` | `.lifted({required bool shown, required ValueChanged<bool> onChange})` |
| `FTooltipControl` (`tooltip/tooltip_controller.dart:176`) | `.managed({FTooltipController?, bool? initial, onChange})` | `.lifted({required bool shown, onChange})` |
| `FAccordionControl` (`accordion/accordion_controller.dart:176`) | `.managed({FAccordionController?, int? min, int? max, ValueChanged<Set<int>>? onChange})` | `.lifted({required Predicate<int> expanded, required void Function(int index, bool expanded) onChange})` |
| `FTabControl` (`tabs/tab_controller.dart:155`) | `.managed({FTabController?, int? initial, FTabMotion? motion, ValueChanged<int>? onChange})` | `.lifted({required int index, required ValueChanged<int> onChange, FTabMotion motion})` |
| `FSelectControl<T>` (`select/single/select_controller.dart:48`) | `.managed({FSelectController<T>?, T? initial, bool toggleable, ValueChanged<T?>? onChange})` | `.lifted({required T? value, onChange})` |
| `FTextFieldControl` (`text_field/text_field_control.dart:89`) | `.managed({TextEditingController?, TextEditingValue? initial, ValueChanged<TextEditingValue>? onChange})` | `.lifted({required TextEditingValue value, onChange})` |
| `FObscureTextControl` (`text_field/obscure_text_control.dart:36`) | `.managed({ValueNotifier<bool>?, bool? initial, onChange})` | `.lifted({required bool value, onChange})` |
| `FAutocompleteControl` (`autocomplete/autocomplete_controller.dart:104`) | `.managed({FAutocompleteController?, TextEditingValue? initial, onChange})` | `.lifted({required TextEditingValue value, onChange})` |
| `FOtpFieldControl` (`otp_field/otp_field_control.dart:16`) | `.managed({FOtpController?, List<Widget> children, TextEditingValue? initial, onChange})` | none declared |
| `FPaginationControl` (`pagination/pagination_controller.dart:186`) | `.managed({FPaginationController?, int? initial, int? pages, int? siblings, bool showEdges, onChange})` | `.lifted({required int page, required onChange, required int pages, int siblings, bool showEdges})` |
| `FPickerControl` (`picker/picker_controller.dart:242`) | `.managed({FPickerController?, List<int>? initial, onChange})` | `.lifted({required List<int> indexes, onChange, Duration duration, Curve curve})` |
| `FTimePickerControl` (`picker/time/time_picker_controller.dart:142`) | `.managed({FTimePickerController?, FTime? initial, onChange})` | `.lifted({required FTime time, onChange, Duration duration, Curve curve})` |
| `FDateTimePickerControl` (`picker/date_time/date_time_picker_controller.dart:159`) | `.managed({FDateTimePickerController?, DateTime? initial, onChange})` | `.lifted({required DateTime dateTime, onChange, Duration duration, Curve curve})` |
| `FTimeFieldControl` (`time_field/time_field_controller.dart:111`) | `.managed({FTimeFieldController?, FTime? initial, FormFieldValidator<FTime>? validator, onChange})` | `.lifted({required FTime? time, onChange, Duration duration, Curve curve})` |
| `FLineCalendarControl` (`line_calendar/line_calendar_controller.dart:67`) | `.managed({FDateSelectionController<DateTime?>?, DateTime? initial, bool? toggleable, onChange})` | `.lifted({required DateTime? date, onChange})` |
| `FLineCalendarScrollControl` (`line_calendar/line_calendar_scroll_controller.dart:123`) | `.managed({FLineCalendarScrollController?, DateTime? start, end, today, initialDate, AlignmentDirectional? initialAlignment, ValueChanged<double>? onChange})` | none |
| `FCalendarControl` (`calendar/calendar_control.dart:6`) | subclasses `FGridCalendarControl`, `FGridSplitCalendarControl`, `FWheelCalendarControl` (`{controller, selectable, start, today, initial, end}`; controller xor other params) | none |
| `FDateSelectionControl<T>` (`calendar/date_selection_control.dart:8`) | static `none()`, `managedSingle({controller, initial, toggleable = true, onChange})`, `managedMulti`, `managedRange`, `managedOpenRange({..., startFirst = true})` | static `liftedSingle({required value, required onChange, toggleable})`, `liftedMulti`, `liftedRange`, `liftedOpenRange` |
| `FSliderControl` (`slider/slider_control.dart:11`) | `managedContinuous`, `managedContinuousRange`, `managedDiscrete`, `managedDiscreteRange` | `liftedContinuous`, `liftedContinuousRange`, `liftedDiscrete`, `liftedDiscreteRange` (all `{required FSliderValue value, required ValueChanged<FSliderValue> onChange, ...}`) |
| `FResizableControl` (`resizable/resizable_control.dart:6`) | `.managed({controller, onResizeUpdate, onResizeEnd})`, `.managedCascade({...})` | none |

### Notifiers/controllers (selected)
- Controllers are `ChangeNotifier`s (usually `FChangeNotifier`/`ValueNotifier`), e.g. `FPopoverController`, `FTooltipController` (show/hide return Futures that must be wrapped in `unawaited` in widget tests, doc template `doc_templates.dart:44-57`), `FSelectController`, `FAccordionController`, `FTabController`. They belong to the owning widget catalogues.

---

## Gaps / surprises (categories 1 to 7)

1. **`FThemeData.copyWith` silently resets `icons` to Lucide** and cannot change `colors`, `typography`, `style`, `icons` or `hapticFeedback` (`theme_data.dart:1343-1479`). A custom `FIcons` or a changed `FColors` requires constructing a new `FThemeData(...)`, which also re-derives every widget style.
2. `FIcons` has no `copyWith`, and `FTypography.inherit` has no `fontFamily` parameter: a custom family needs `FTypography(display: FTypeface.inherit(fontFamily:...), body: FTypeface.inherit(fontFamily:...))` (`typography.dart:38-49, 398`).
3. **No fallback for accessibility scope**: `context.accessibility` force-unwraps the scope (`accessibility.dart:80-97`); every ForUI widget that reads it (FTappable, FFocusedOutline, tooltips, dialogs, ...) assumes an `FTheme`/`FBasicTheme` ancestor, while `context.theme` and `context.platformVariant` silently fall back. Reading of code only.
4. Two independent `FTappableStyle`s: `FThemeData.tappableStyle` (what bare `FTappable` reads) vs `FThemeData.style.tappableStyle` (base for widget defaults). Changing one does not change the other.
5. `FTappable`: default shortcut is Enter only; default cursor is `MouseCursor.defer` (no pointer cursor unless a widget style sets one); `pressed` is delayed 100 ms so very short taps never show `pressed`; `reduced` motion still bounces (only `disabled` disables it).
6. `FOverlayControl.lifted.onChange` is never called by `FOverlay`/`FPortal`/`FPointPortal`; it is only an interface for higher-level widgets (`overlay_controller.dart:13-17`; no `onChange` use in `foundation/overlay`).
7. `FMultiValueControl.lifted` ignores `min`/`max` (proxy notifier is built without them, `notifiers.dart:272`); the min/max error message text looks inverted (`notifiers.dart:78-82`).
8. `FVariants` interpolation (animated theme switch via `FTheme`) drops variant keys that are not in both themes and snaps `cursor`/durations at `t < 0.5` (`variants.dart:79-118`, `tappable.design.dart`). A custom theme whose variant maps differ from the other brightness may flash during the 200 ms transition. `FThemeMotion` default is 200 ms linear and does not respect reduced motion.
9. `FSizes` values are "reference tokens": changing them does not resize widgets (`sizes.dart:6`).
10. `FBreakpoints` are consulted by `FDialog.adaptive` only (`dialog.dart:353`); everything else responsive is platform-variant based and app-selected (touch vs desktop `FThemeData` is not auto-chosen from the screen).
11. `FPortal`'s `barrier` has a documented, unfixed semantics-blocking limitation (`portal.dart:257-261`).
12. `And` equality is symmetric but `hashCode` is order-dependent (`variant.dart:145-152`): `a.and(b)` and `b.and(a)` are `==` with different hash codes. UNVERIFIED impact (hash-keyed maps).
13. Docs vs source naming: docs reference `FThemeBuildContext`/`FAdaptiveBuildContext`, source declares `FBuildContext`; docs say `snippet create material-theme` while the source comment says `material-mapping` (`theme_data.dart:963`); docs say typeface styles "only specify fontSize and height" while `FTypeface.inherit` also sets colour/family.
14. `FTappable` space-key activation is **UNVERIFIED**: the widget binds Enter itself; Space depends on the app's default `Shortcuts` (WidgetsApp/MaterialApp provide `space -> ActivateIntent`, Flutter `app.dart:1265-1269`); tests cover Enter only.
15. Not verified by execution: all claims above are from reading source and ForUI's own tests; nothing was run (no Flutter/Dart execution in this task).

---

## ForUI 0.27.6 catalog B: layout, item/tile, navigation

Scope: FScaffold, FHeader (+FHeaderAction), FResizable, FDivider, FCard, FLabel; FItem, FItemGroup, FTile, FTileGroup, FSelectTileGroup (+FSelectTile), FSelectMenuTile; FBottomNavigationBar (+item), FBreadcrumb (+items), FTabs, FPagination, FSidebar (+group, item).

## Conventions in this file

- All `lib/...` paths are relative to `forui-0.27.6/` (so `lib/src/widgets/scaffold.dart:85`). Test paths are under `.../scratchpad/forui-src/forui/test/src/widgets/`.
- The installed package is written in the new Dart primary-constructor syntax (`const new({...})`, `class X({...})`, dot shorthands like `.context()`). The signatures below are copied as declared; callers still write `FScaffold(...)`, `FItem.raw(...)`, etc.
- Import for everything here: `package:forui/forui.dart`. Per-widget barrels: `lib/widgets/<x>.dart` (listed per entry).
- `.context()` on a `*StyleDelta` param means "the style from `FThemeData`". Every widget's `style` param is a `...StyleDelta` (`.delta(...)` to modify, or a full `...Style(...)` to replace).
- "touch" below = `context.platformVariant` is android/iOS/fuchsia (`lib/src/theme/variant_platform.dart`). It is a different input from `FThemeData(touch: ...)`, which only picks the `*.inherit(touch:)` sizes at theme-build time (`lib/src/theme/theme_data.dart:544`).
- Docs URL base: `https://forui.dev/docs/widgets/...`. The mdx files for these pages are mostly generated usage snippets; all behavioural claims below come from source.

## Cross-cutting mechanisms (referenced by many entries)

### `FTappable` (used by FHeaderAction, FItem/FTile, bottom-nav item, crumb, pagination, sidebar item)
- Source: `lib/src/foundation/tappable/tappable.dart`. `FTappable(...)` is `const factory ... = AnimatedTappable` (:348-400); `FTappable.static` is the non-animated base.
- Variants (:17-24): `disabled`, `selected` (semantic); `primaryFocused`, `focused`, `hovered`, `pressed` (interaction). The platform variant is added to the set (:603-608).
- **Disabled = no callbacks.** `_disabled` is true when no primary and no secondary callback is set (:527). Then `Semantics(enabled: false)` (:708), `Focus.canRequestFocus = !disabled || onDisabledPress != null` (:738), and `onDisabledPress` is used as press (:525).
- Press visuals are delayed: `pressed` is applied after `style.pressedEnterDuration` (default 100 ms) and removed after `pressedExitDuration` (default 100 ms) (:870-910, defaults in `tappable.design.dart` style at :1080ff). A tap shorter than the enter delay can finish before `pressed` is ever shown, unless the widget's style sets the delay to zero (items and tiles do).
- Bounce: `AnimatedTappable` scales to 0.97 (`FTappableMotion.defaultBounceTween`, :1116) with `bounceFloor` 5 px, 100 ms down/up, `easeOutQuart`/`easeOutCubic`. It is skipped when `context.accessibility.motion == .disabled` (:1003-1004). `FAccessibilityMotion.reduced` does NOT disable the bounce.
- Focus highlight (`focused`/`primaryFocused` variants and the outline) only appears when `FAccessibility.focusHighlight` is true, i.e. `FocusManager.highlightMode == traditional` (keyboard/mouse navigation), not on touch (:588-600; `lib/src/foundation/accessibility.dart:120-128`).
- Semantics (:707-724): `button: semanticsButton (true)`, `container: semanticsContainer (true)`, `selected: widget.selected` only when `semanticsChecked == null`, optional label/hint/tooltip/expanded/role. `onTap`/`onLongPress` semantics actions are attached only when `excludeSemantics` or when inside an `FTappableGroup`.
- Enter key activates `onPress` (default shortcut `SingleActivator(.enter): ActivateIntent`, :458-460). Space is not bound.
- `SelectionContainer.disabled` wraps the content unless `selectable` (:703-705).
- Gestures: primary press tracked by a `Listener` plus `GestureDetector` with `behavior: translucent` by default (:826-852). A static `_claims` map makes the deepest tappable win a pointer (:560, :774).

### `FTappableGroup` (slide-across)
- `lib/src/foundation/tappable/tappable_group.dart`. Wraps children so a press can slide from one tappable to another; the group recognizer owns primary press/long-press, and tappables inside it stop attaching their own tap handlers (`_entries == null ? ... : null`, tappable.dart:828-838).
- Applied automatically by: FHeader actions (when `FHeaderStyle.slidableActions`, default `true` for all platforms; root_header.dart:239, nested_header.dart:42-52), FBottomNavigationBar rows (`slideableItems`, bottom_navigation_bar.dart:95-97), FItemGroup (`slideableItems` and only when `maxHeight` is infinite; item_group.dart:437) and FTileGroup (`slideableTiles`; tile_group.dart:329).
- On pointer-up the group defers `onPress` until the gesture arena resolves, so scroll recognizers can still win (`tappable_group_recognizer.dart`, "Defer so scroll recognizers can still win the sweep"). A long-press on an entry with no `onLongPress` falls back to firing `onPress` on release.
- Haptic on slide: `slidePressHapticFeedback` (item/tile groups use `hapticFeedback.selectionClick`; default for a bare group is `FHapticFeedback.noFeedback`).

### Item data inheritance (FItem, FTile, groups)
- `FInheritedItemData` / `FItemData` (`lib/src/widgets/item/item_data.dart:108-264`) carry `styles`, `spacing`, `dividerColor`, `dividerWidth`, `divider`, `enabled`, `index`, `last`, `globalLast`, `intrinsicWidth` from a group to its items. `FInheritedItemData.merge(...)` (:120-161) computes divider per item: not last -> the group's divider; last of a non-last nested group -> parent's divider; globally last -> `none`.
- `FInheritedItemCallbacks` (item_data.dart:47-101) lets a parent (popover menus) inject `onPress`/`onLongPress`/hover and `semanticsRole`; FItem calls both its own and the injected callback (item.dart:380-394).
- Resetting inheritance inside a popover/overlay: wrap in `FInheritedItemData(child: ...)` with null data (documented in item.dart:15-37 and tile.dart:14-40).

### Localized semantic strings used by this category (`lib/src/localizations/localizations_en.dart`, `localizations_vi.dart`)
| Key | en | vi |
|---|---|---|
| `headerBackSemanticsLabel` | Back | Quay lại |
| `headerCloseSemanticsLabel` | Close | Đóng |
| `bottomNavigationBarTabSemanticsLabel(i, n)` | Tab i of n | Thẻ i trong tổng số n |
| `breadcrumbCollapsedSemanticsLabel` | More | Thêm |
| `paginationPageSemanticsLabel(p)` | Page p | Trang p |
| `paginationPreviousSemanticsLabel` | Previous | Trước |
| `paginationNextSemanticsLabel` | Next | Tiếp |
They are only picked up if `FLocalizations.delegate` is in the app's delegates; otherwise `FDefaultLocalizations()` (English) is used (e.g. header_action.dart:342-343, bottom_navigation_bar_item.dart:78).

---

## 1. Layout and screen containers

### `FScaffold` — page frame: optional sidebar, header, content, footer; hosts persistent sheets
- Import: `package:forui/forui.dart` (`lib/widgets/scaffold.dart` -> `lib/src/widgets/scaffold.dart`)
- Constructor (scaffold.dart:85-94): `const FScaffold({required Widget child, FScaffoldStyleDelta scaffoldStyle = const .context(), Widget? header, Widget? sidebar, Widget? footer, bool childPad = true, bool resizeToAvoidBottomInset = true, Key? key})`.
- Key params:
  - `header` is wrapped in `DecoratedBox(style.headerDecoration)` (:121-122); `footer` in `DecoratedBox(style.footerDecoration)` (:97-99); `sidebar` in `ColoredBox(style.sidebarBackgroundColor)` (:117) placed in a `Row` before the content (:116-118).
  - `childPad` applies `FScaffoldStyle.childPadding` (inherit: `pagePadding.copyWith(top: 0, bottom: 0)` = horizontal 12, vertical 0; :196, `lib/src/theme/style.dart:37`).
  - `resizeToAvoidBottomInset` (default true) shrinks the content for the keyboard (see below).
- State / control: stateless; none.
- Layout / insets / keyboard:
  - Custom `RenderBox` (`_RenderScaffold`, :228-290). `size = constraints.biggest` (:246), so the scaffold needs bounded constraints (UNVERIFIED: unbounded parents are not asserted against; `biggest` would be infinite).
  - Children: [content column (header + `Expanded(child)`), footer]. Footer is laid out loose (:249); `footerHeight = resizeToAvoidBottomInset ? max(viewInsets.bottom, footer.height) : footer.height` (:251); content gets `maxHeight = constraints.maxHeight - footerHeight` (:253-254); footer is positioned at `size.height - footer.height` (:257). So when the keyboard is up the content ends at the keyboard top and the footer stays at the bottom edge, underneath the keyboard (it is not lifted above the keyboard). With no footer, the footer slot is a zero-size `SizedBox` (:99-100) and content still shrinks by the inset.
  - `viewInsets` is read with `MediaQuery.viewInsetsOf(context)` of the scaffold's own context (:211, :218). FScaffold does not call `MediaQuery.removeViewInsets`/`removePadding` for its child (rg over `lib/src` finds those only in dialog/sheet/portal code), so descendants still see the full `viewInsets`/`padding`.
  - **No SafeArea of its own.** Top: only `FHeader` applies `SafeArea(bottom: false)` (root_header.dart:244, nested_header.dart:54). Left/right/bottom: none; the footer is not safe-area-wrapped. A bottom nav as footer must handle it itself (`FBottomNavigationBar.safeAreaBottom`). If `header` is not an `FHeader` there is no top inset handling.
  - No floating-action-button slot, no drawer, no bottom-sheet-slot parameters. Only `header`, `sidebar`, `child`, `footer`.
  - Test evidence: `scaffold/scaffold_golden_test.dart:121-165` (viewInsets bottom 800, both flag values, with and without sidebar).
- Hosting of overlays: wraps everything in `FSheets` (scaffold.dart:114), so `showFPersistentSheet`/`showFSheet`-style persistent sheets need an `FScaffold` (or `FSheets`) ancestor (`lib/src/widgets/sheet/persistent_sheet.dart:16, :91-103`). Persistent sheets are stacked over the whole row including the sidebar (`FSheetsState.build` is a `Stack`, :253-266) and close on Escape (:259). **Toasts are not hosted here**: `FToaster` is a separate widget that must be placed above (docs example `lib/src/widgets/toast/toaster.dart:253`: `FToaster(child: child!)` in the app builder); `FToaster.of` uses `findAncestorStateOfType` with `!` (toaster.dart:267).
- Other built-ins: `IconTheme(data: theme.style.iconStyle)` (:111-113, with a TODO "Move to ForuiApp"); `AnnotatedRegion<SystemUiOverlayStyle>(style.systemOverlayStyle)` (:109) as a fallback status-bar style that `FHeader` overrides.
- Interaction states / focus / semantics: none of its own.
- Motion: none (no animation in the file).
- Styling: `FScaffoldStyle` (scaffold.dart:160-203) from `FThemeData.scaffoldStyle` (`lib/src/theme/theme_data.dart:385`). Fields: `systemOverlayStyle`, `backgroundColor` (= colors.background), `sidebarBackgroundColor` (= colors.background), `childPadding`, `footerDecoration` (default: 1 px top border `colors.border`), `headerDecoration = BoxDecoration()`. Delta: `FScaffoldStyleDelta` in `scaffold.design.dart`.
- Caveats: footer top border is doubled if the footer is an `FBottomNavigationBar` (which also draws a top border); both `FScaffoldStyle.footerDecoration` and `FBottomNavigationBarStyle.decoration` must be changed to remove it (documented, scaffold.dart:176-180 area and bottom_navigation_bar.dart:197-200).
- Evidence: scaffold.dart:39-148 (widget), :228-290 (layout); docs `https://forui.dev/docs/widgets/layout/scaffold`.

### `FHeader` — sealed page header (title + actions); two variants
- Import: `package:forui/forui.dart` (`lib/widgets/header.dart` -> `lib/src/widgets/header/header.dart`)
- Constructors (header.dart:34-70), class is `sealed`:
  - `const FHeader({Widget title, FHeaderStyleDelta style, List<Widget> suffixes, Key? key})` -> `_FRootHeader`. Root header: title aligned to start, only trailing `suffixes`.
  - `const FHeader.nested({Widget title, AlignmentGeometry titleAlignment, FHeaderStyleDelta style, List<Widget> prefixes, List<Widget> suffixes, Key? key})` -> `_FNestedHeader`. Defaults: `titleAlignment = .center`, `title = SizedBox()`, `prefixes/suffixes = []` (nested_header.dart:29-36).
- Key params: `title` is a `Widget` (not a String); `prefixes` are the leading side in LTR (trailing in RTL), `suffixes` the other side (nested_header.dart:14-24). Root header has no prefixes, so a back button needs `FHeader.nested`.
- Layout:
  - Root: `Row(spaceBetween)` with `Expanded(DefaultTextStyle.merge(overflow: ellipsis, maxLines: 1, softWrap: false, style: titleTextStyle, child: title))` then the actions row (root_header.dart:254-272); action spacing `FHeaderStyle.actionSpacing` (default 0).
  - Nested: custom render object `_RenderNestedHeader` (nested_header.dart:139-222). Prefixes and suffixes are laid out first, the title gets the remaining width (`maxWidth - prefixes - suffixes`), and the title x offset is `alignment`-based but clamped between the prefix end and the suffix start (:166-185), so it never overlaps actions. Title has 10 px horizontal padding (:70). RTL is handled (:177).
  - Constraint: `style.constraints` default `minHeight` 62 (touch) or 54; padding `pagePadding.copyWith(bottom: 10)` = top 8, horizontal 12, bottom 10 (header.dart:110, :120).
- State / control: stateless.
- Interaction states / variants: style resolved by `headerStyles.resolve({FHeaderVariant.root | nested, platformVariant})` (root_header.dart:230, nested_header.dart:40). Variants: `root`, `nested` (header.dart:17).
- Focus & semantics:
  - The whole header is `SafeArea(bottom: false, child: Semantics(header: true, child: ...))` (root_header.dart:244-246; nested_header.dart:54-56). The `header: true` flag sits on the whole bar, not on the title widget alone. Because `FHeaderAction` is an `FTappable` (semantics container), actions become separate nodes (inference, not run).
  - SafeArea(top) is applied here, not in FScaffold.
  - No page-title announcement/route label is added.
- Motion: none (the optional `backgroundFilter` is a static `BackdropFilter`, root_header.dart:279-290).
- Styling: `FHeaderStyles` (header.dart:101-151) from `FThemeData.headerStyles` (theme_data.dart:235); `FHeaderStyle` (header.dart:154-206): `systemOverlayStyle`, `padding`, `titleTextStyle`, `actionStyle`, `constraints`, `decoration`, `backgroundFilter`, `actionSpacing`, `slidableActions`. Root title: `display.xl2` w700 height 1 (touch 30 px); nested title: `display.xl` w600 (touch 22 px) (header.dart:113, :131). Delta: `FHeaderStyleDelta`.
- Limitations / caveats:
  - Title is single-line only (`maxLines: 1`, `softWrap: false`, ellipsis) and the style is applied via `DefaultTextStyle.merge`; a non-Text title inherits the style only if it reads `DefaultTextStyle`.
  - Both variants always add a `AnnotatedRegion<SystemUiOverlayStyle>` with `systemOverlayStyle` (colors.systemOverlayStyle), which sets status bar icon brightness.
  - `FHeaderData.of` is asserted by actions (see FHeaderAction).
- Evidence: header.dart, root_header.dart, nested_header.dart (line numbers above); tests `header/header_test.dart`, `nested_header_golden_test.dart`; docs `https://forui.dev/docs/widgets/navigation/header`.

### `FHeaderAction` — icon button for FHeader prefixes/suffixes
- Import: same barrel as FHeader (`header_action.dart` is a `part` of `header.dart`).
- Constructors (header_action.dart:299-318, :321, :366):
  - `const FHeaderAction({required Widget icon, required VoidCallback? onPress, FHeaderActionStyleDelta style, bool selected = false, String? semanticsLabel, String? semanticsTooltip, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, VoidCallback? onLongPress, VoidCallback? onDoubleTap, VoidCallback? onSecondaryPress, VoidCallback? onSecondaryLongPress, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions, Key? key})`.
  - `FHeaderAction.back({required VoidCallback? onPress, ...same optional params...})` (icon `icons.arrowLeft`) and `FHeaderAction.x({required VoidCallback? onPress, ...})` (icon `icons.x`). Both are `factory`, not `const`.
- State / control: stateless; `selected` is passed through to `FTappable.selected`.
- Interaction states: `FTappable` variants; icon color via `FHeaderActionStyle.iconStyle` (hovered/pressed -> `colors.hover(foreground)`, disabled -> `colors.disable(foreground)`; header_action.dart:485-491). `onPress == null` (and no other callback) -> disabled variant and not focusable.
- Focus & semantics: `FTappable(semanticsLabel, semanticsTooltip, focusedOutlineStyle)` (:413-432). `.back`/`.x` give the **icon** a localized semantics label ("Back"/"Close", vi "Quay lại"/"Đóng") only when `semanticsLabel == null` (:340-345, :385-390); a plain `FHeaderAction(icon: Icon(...))` has no label unless you pass `semanticsLabel`.
- Hit target: padding only. Root header actions: icon size = `display.xl2` size (touch 30) + padding 7 each side = 44 dp; nested: icon `display.xl` (touch 22) + padding 11 = 44 dp touch, 22 + 16 = 38 dp otherwise (header.dart:114-118, :132-136). Derived from source, not measured.
- Motion: default `style.tappableStyle` (the theme's `FStyle.tappableStyle`), so the 0.97 bounce and 100 ms press delay apply (header_action.dart:493-495).
- Styling: `FHeaderActionStyle` (:461-496): `iconStyle`, `padding`, `focusedOutlineStyle`, `tappableStyle`; delta `FHeaderActionStyleDelta`. The effective style comes from `FHeaderData.of(context).actionStyle` (:412), i.e. from the parent FHeader's style.
- Limitations: requires an `FHeader` ancestor (`FHeaderData.of` asserts, header.dart:78-82). Press-slide between neighbouring actions is on by default (`slidableActions`).
- Evidence: header_action.dart as cited; test `header/header_action_test.dart`.

### `FResizable` + `FResizableRegion` — draggable split panes
- Import: `package:forui/forui.dart` (`lib/widgets/resizable.dart`; hides the internal divider/region classes).
- Constructors:
  - `const FResizable({required Axis axis, required List<FResizableRegion> children, FResizableControl control = const .managedCascade(), FResizableDividerStyleDelta style = const .context(), FResizableDivider divider = .dividerWithThumb, double? crossAxisExtent, double? hitRegionExtent, double resizePercentage = 0.005, String Function(FResizableRegionData first, FResizableRegionData second) semanticFormatterCallback = defaultSemanticFormatterCallback, Key? key})` (resizable.dart:100-112).
  - `FResizableRegion.fixed({required double extent, required ValueWidgetBuilder<FResizableRegionData> builder, double? minExtent, Widget? child, Key? key})` and `const FResizableRegion.flex({required ValueWidgetBuilder<FResizableRegionData> builder, int flex, int? minFlex, Widget? child, Key? key})` (resizable_region.dart).
- Key params: `divider` enum `none | divider | dividerWithThumb` (divider.dart:261-270); `hitRegionExtent` default 60 (touch) / 10 (other) (resizable.dart:168, :179); `resizePercentage` is the keyboard/semantic step (0.5% of total).
- State / control: `FResizableControl.managed({controller, onResizeUpdate, onResizeEnd})` and `FResizableControl.managedCascade({...})` (resizable_control.dart); controller `FResizableController` (resizable_controller.dart:15-70) with `hapticFeedbackVelocity` 6.5. No `lifted` variant exists. `controller` and the callbacks are mutually exclusive (asserts).
- Layout contract: any `flex` region makes the widget fill the parent's main axis, which must be finite (assert, resizable.dart:441-446); fixed regions must fit (assert). Min size of every region is at least `hitRegionExtent` (:310, :397).
- Interaction & semantics: each divider is `Semantics(slider: true, value: formatter(...), increasedValue, decreasedValue, onIncrease, onDecrease)` wrapping a `FocusableActionDetector` with arrow-key shortcuts (left/right for horizontal, up/down for vertical) (divider.dart:53-84, :148-149, :209) and `FFocusedOutline`. Light haptic when a region collides with its neighbour (divider.dart:96, `hapticFeedback`).
- Motion: no animation (drag only); extents rescale on layout via `_scale` (resizable.dart:301ff).
- Styling: `FResizableStyles` (variants `horizontal`/`vertical` + platform) from `FThemeData.resizableStyles` (theme_data.dart:375); `FResizableDividerStyle` {color, focusedOutlineStyle, thumbStyle, hapticFeedback} (divider.dart:273ff).
- Caveats: regions rebuild with new extents via `InheritedData`; `FResizableRegion` must be a direct member of `FResizable` (`InheritedData.of` asserts). Not designed for narrow phone use beyond the 60 dp hit region (each divider eats `hitRegionExtent`).
- Evidence: resizable.dart, divider.dart, resizable_control.dart; tests `resizable/*`; docs `https://forui.dev/docs/widgets/layout/resizable`.

### `FDivider` — hairline separator
- Import: `package:forui/forui.dart` (`lib/widgets/divider.dart`)
- Constructor (divider.dart:48): `const FDivider({FDividerStyleDelta style = const .context(), Axis axis = .horizontal, Key? key})`.
- Behaviour: `Container(margin: style.padding, color: style.color, height|width: style.width)` (divider.dart:56-61). **The default padding is a margin of 16 dp above and below a horizontal divider (16 dp left and right for vertical)** (`FDividerStyle.defaultPadding`, :123-126). Colour defaults to `colors.secondary`, not `colors.border` (:82). Width = `style.borderWidth` (1).
- A horizontal divider takes the width of its parent; a vertical one has no height (it needs a bounded height, e.g. in `IntrinsicHeight`) (:59-60).
- State / semantics / focus / motion: none (no `Semantics`, not focusable, no animation).
- Styling: `FDividerStyles` (variant `FDividerAxis.vertical`) from `FThemeData.dividerStyles` (theme_data.dart:225); `FDividerStyle {color, padding, width=1}`.
- Evidence: divider.dart as cited; docs `https://forui.dev/docs/widgets/layout/divider`.

### `FCard` — bordered, rounded surface (no built-in layout)
- Import: `package:forui/forui.dart` (`lib/widgets/card.dart`)
- Constructor (card.dart:73-80): `const FCard({FCardStyleDelta style = const .context(), Clip clipBehavior = .none, ValueWidgetBuilder<FCardStyle> builder = defaultBuilder, Widget? child, Key? key})`; assert: either `builder` or `child`.
- Behaviour: `DecoratedBox(decoration: style.decoration, child: builder(context, style, child))`, optionally `ClipPath(InnerPathClipper)` when `clipBehavior != none` (card.dart:85-99). **FCard itself applies no padding and no title/subtitle layout**: `FCardStyle.padding` (default 16), `titleTextStyle` and `subtitleTextStyle` exist only for the `builder`/generated snippet layouts to read (docs: `dart run forui snippet create card`). A bare `FCard(child: Text(...))` has no inner padding.
- Default decoration: `ShapeDecoration(RoundedSuperellipseBorder(side: border, radius: lg), color: colors.card)` (card.dart:111-136 region).
- Not tappable, no semantics, no states, no motion.
- Styling: `FCardStyle` from `FThemeData.cardStyle` (theme_data.dart:145); delta `FCardStyleDelta`.
- Evidence: card.dart as cited; docs `https://forui.dev/docs/widgets/data/card`.

### `FLabel` — label/description/error scaffold for a form control
- Import: `package:forui/forui.dart` (`lib/widgets/label.dart`; `Label`/`LabelState` hidden)
- Constructor (label.dart:112-122): `const FLabel({required FLabelLayout layout, required Widget child, FLabelStyleDelta style = const .context(), Widget? label, Widget? description, Widget? error, bool expands = false, Set<FFormFieldVariant> variants = const {}, Key? key})`; assert: `expands` only with `.vertical`.
- `FLabelLayout`: `horizontalLeading` (label left, child right), `horizontalTrailing` (child left, label right; used by checkbox/radio/switch), `vertical` (label above child; used by text field) (label.dart:16-52).
- Behaviour: with no label, description or error it returns `Padding(childPadding, child)` only (:131-133). The error is animated in/out: size (100 ms, easeOut) and fade (0.4 -> 1.0 opacity, 100 ms linear) (`FLabelMotion`, :418-471); **error transitions only work if a label or description was present** (documented, :56-60). Error is shown when `variants` contains `FFormFieldVariant.error` (:206, :255).
- Semantics: description and error text are tagged and merged into the child's semantics as hint; the error carries `validationResult: invalid` and `liveRegion` when the platform has no `supportsAnnounce` (label.dart:306-310; `lib/src/widgets/label/semantics.dart:1-60`).
- Motion: all of it is replaced by `FLabelMotion.none` unless `FAccessibility.motion == all` (label.dart:266, :318).
- Variants: `FFormFieldVariant` = `disabled`, `error`, `focused` (`lib/src/theme/form_field_style.dart:10-14`).
- Styling: `FLabelStyles` {horizontalLeadingStyle, horizontalTrailingStyle, verticalStyle} from `FThemeData.labelStyles` (theme_data.dart:263); `FLabelStyle` extends `FFormFieldStyle` with paddings and `labelMotion`.
- Used by: FTileGroup (as group label/description/error), FSelectMenuTile, form fields.
- Evidence: label.dart as cited; docs `https://forui.dev/docs/widgets/form/label`.

---

## 2. Item and tile layouts

### `FItem` — generic list row (title/subtitle/details/prefix/suffix)
- Import: `package:forui/forui.dart` (`lib/widgets/item.dart`; hides `ItemContent`, `RawItemContent`)
- Constructors (item.dart:216-260, :274-312):
  - `FItem({required Widget title, FItemVariant variant = .primary, FItemStyleDelta style = const .context(), bool? enabled, bool selected = false, String? semanticsLabel, String? semanticsTooltip, bool semanticsButton = true, bool? semanticsChecked, bool? semanticsExpanded, bool? semanticsInMutuallyExclusiveGroup, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, VoidCallback? onPress, VoidCallback? onLongPress, VoidCallback? onDoubleTap, VoidCallback? onSecondaryPress, VoidCallback? onSecondaryLongPress, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions, Widget? prefix, Widget? subtitle, Widget? details, Widget? suffix, Key? key})`.
  - `FItem.raw({required Widget child, ...same params except subtitle/details/suffix, Widget? prefix, ...})`: no custom layout, `child` is laid out after `prefix`.
  - Shorthands for group `children`: `FItemMixin.item(...)`, `FItemMixin.raw(...)`, `FItemMixin.submenu(...)` (item_mixin.dart). **The `FItemMixin.item/raw` shorthands omit `semanticsButton`, `semanticsChecked`, `semanticsExpanded`, `semanticsInMutuallyExclusiveGroup`**; use `FItem(...)` directly when you need those.
- Key behaviour:
  - **Interactivity is decided by callbacks, not by `enabled`.** If all of `onPress`, `onLongPress`, `onDoubleTap`, `onSecondaryPress`, `onSecondaryLongPress` are null, the item is a static row: no `FTappable`, no button semantics, no hover/pressed (item.dart:344-362; test `item/item_test.dart:101-115` "disabled when no press callbacks given").
  - `enabled: false` (or an inherited disabled group) nulls out all callbacks passed to the `FTappable` (item.dart:380-397), producing the `disabled` variant (`Semantics(enabled: false)`, not focusable) and disabled colours. `enabled` defaults to the group's value, else true (item.dart:319).
  - `selected` has a visual effect only on the interactive path: the static path builds variants from `{platform, disabled?}` only (item.dart:320-323), so `selected: true` on a callback-less item changes neither colour nor semantics.
  - Tap/press: `onPress` combines the inherited `FInheritedItemCallbacks.onPress` and its own (:380-388); long-press combined likewise (:389-394).
- Layout of `FItem(...)` (item_content.dart:54-121 + item_content_layout.dart):
  - Order LTR: `[prefix] [title / subtitle column] [details] [suffix]`; reversed in RTL (layout.dart:`performLayout`).
  - Constraint priority: prefix first, then suffix, then (if `details` is a `RenderParagraph`, i.e. a plain `Text`) the title column, else `details` first, then the remaining one gets what is left. Practical result: text `details` is truncated first.
  - Title and subtitle are wrapped in `DefaultTextStyle.merge(overflow: ellipsis)` but **no `maxLines`** (item_content.dart:79-97), so long titles wrap onto more lines instead of staying single-line unless you pass `maxLines: 1`/`overflow` on your own `Text`.
  - `Expanded`/`FTextField` inside title/subtitle/details prevents rendering (documented, item.dart:200-210); use `FItem.raw` for those.
  - Content padding: item `suffixedPadding`/`unsuffixedPadding` = touch `10 / 12.5` (L/T-B), non-touch `10 / 6.5` (item_content.dart:266-269); outer `FItemStyle.padding` 4 dp horizontal (item.dart:551). Spacing: `prefixIconSpacing 8`, `titleSpacing 4`, `middleSpacing 4`, `suffixIconSpacing 8`.
  - Reference heights: `FSizes.item` = 44 (touch) / 30 (desktop) (`lib/src/theme/sizes.dart:46-47`), asserted by `item/item_test.dart:198-218` (skipped off macOS). No hard minimum height is set in code.
  - Hit area: the `FTappable` sits inside the outer `Padding(margin)`, so the 4 dp horizontal margin and the divider margin are not tappable.
- Dividers: drawn by the layout's `paint` (item_content_layout.dart ~ :140-195) at the item's bottom: `full` spans the whole width (including the outer margins), `indented` starts at the title's left edge (after the prefix) in LTR or ends before the prefix in RTL; the colour comes from the group (`dividerColor`), and for `indented` the part under the prefix is painted with `dividerBackground` (the item background) so a hover/selected fill hides it. Enum `FItemDivider { full, indented, none }` (item_data.dart:11-41). The item's bottom margin grows by `dividerWidth` when a divider exists (item.dart:333).
- Group-position effects: the first item adds the group `spacing` to its top margin, the last adds it to the bottom (item.dart:327-333); `style.shape` is applied only when the item is the sole/first-and-globally-last item (standalone) (item.dart:338-340), and default `FItemStyle.shape` is null.
- Interaction states / variants: tappable variants `hovered`, `pressed`, `selected`, `disabled`, `focused`. Default decoration: rounded rectangle (md) colour background; hovered/pressed -> `colors.secondary`; selected -> `colors.secondary`; selected+disabled -> `colors.disable(secondary)` (item.dart:570-583). Text/icon colours have `disabled` variants only (item_content.dart:236-265). Item variant `FItemVariant`: `primary`, `destructive` (item.dart:12).
- Focus & semantics: forwards `autofocus`, `focusNode`, `onFocusChange`, `onHoverChange`, `onVariantChange`, `semanticsLabel`, `semanticsTooltip`, `semanticsButton`, `semanticsChecked`, `semanticsExpanded`, `semanticsInMutuallyExclusiveGroup` (item.dart:363-379) to `FTappable`; `semanticsRole` comes only from `FInheritedItemCallbacks`. The whole row is one semantics container whose text is the merged title/subtitle/details; `FItem` exposes no `excludeSemantics`, so a `semanticsLabel` is added to (not substituted for) the child text (inference from `Semantics(label:, excludeSemantics: false)`, tappable.dart:707-719; UNVERIFIED by a run).
- Motion: `tappableStyle` = theme tappable style with `motion: none`, `pressedEnterDuration: 0`, `pressedExitDuration: 25 ms` (item.dart:599-603): no bounce, instant pressed colour, 25 ms release. No other animation.
- Styling: `FItemStyles` {variants primary/destructive} from `FThemeData.itemStyles` (theme_data.dart:244); `FItemStyle` {backgroundColor, contentDecoration, contentStyle (`FItemContentStyle`), rawContentStyle (`FRawItemContentStyle`), tappableStyle, focusedOutlineStyle (nullable), padding, shape} (item.dart:520-557). When inside a group, the group's `itemStyles` win unless you pass your own `style` (docs item.dart:63-80).
- Limitations: `FItem.raw` + `destructive` variant uses `colors.primary` for prefix and text (item.dart:488-494), not `colors.destructive` as `contentStyle` does and as the tile equivalent does (tile.dart:353-358) (likely upstream inconsistency; UNVERIFIED by render).
- Evidence: item.dart:51-607, item_content.dart, raw_item_content.dart, item_content_layout.dart, item_data.dart, item_mixin.dart; docs `https://forui.dev/docs/widgets/data/item`.

### `FItemGroup` — container for FItem rows (scrolling, dividers, merge)
- Import: `package:forui/forui.dart` (`lib/widgets/item.dart`)
- Constructors (item_group.dart:240-400):
  - `FItemGroup({required List<FItemMixin> children, FItemGroupStyleDelta style = const .context(), ScrollController? scrollController, ScrollCacheExtent? scrollCacheExtent, double maxHeight = .infinity, DragStartBehavior dragStartBehavior = .start, ScrollPhysics physics = const ClampingScrollPhysics(), bool? enabled, bool? intrinsicWidth, FItemDivider divider = .none, String? semanticsLabel, Key? key})`.
  - `FItemGroup.group(...)` = same as the default constructor.
  - `FItemGroup.builder({required NullableIndexedWidgetBuilder itemBuilder, int? count, style, scrollController, scrollCacheExtent, maxHeight, dragStartBehavior, physics, enabled, FItemDivider divider = .none, semanticsLabel, key})`: no `intrinsicWidth`; `itemBuilder` returning null ends the list; `last` is computed by calling `itemBuilder(index + 1)` (item_group.dart:324), so it can be called twice per index.
  - `FItemGroup.merge({required List<FItemGroupMixin> children, ..., FItemDivider divider = .full, ...})`: concatenates groups with a divider between them; the merged children's `scrollController/maxHeight/...` are ignored.
  - Static shorthands: `FItemGroupMixin.group/builder/merge`.
- Docs vs code: the doc comment on `divider` says "Defaults to FItemDivider.indented" (item_group.dart:212) but all constructors default to `.none` (:250, :304) and `merge` to `.full` (:349). Trust the code.
- Behaviour:
  - Root group (no inherited `FInheritedItemData`) renders `Semantics(container: true, label: semanticsLabel) > ConstrainedBox(maxHeight) > DecoratedBox(style.decoration) > ClipPath(InnerPathClipper) > CustomScrollView(shrinkWrap: true, physics)` (item_group.dart:441-453, :427-434) or, with `intrinsicWidth`, `IntrinsicWidth > SingleChildScrollView > Column` (:418-426). So every root group is its own scrollable even when it just shrink-wraps in a page; `ClampingScrollPhysics` by default. Nested groups (inside a `merge` or another group) return only the sliver/column (:411-413).
  - `enabled` and `intrinsicWidth` cascade to items via `FInheritedItemData.merge` (:254-271).
  - Slide-across press is enabled when `maxHeight` is infinite and `style.slideableItems` resolves true (default true everywhere) (:437-439).
  - Divider paints between items (see FItem). `spacing` (default 4) is inner top/bottom padding.
- State / control: stateless; optional external `ScrollController`.
- Semantics: group container with optional label; each item contributes its own node.
- Motion: none.
- Styling: `FItemGroupStyle` {decoration (rounded md, no border by default), dividerColor (variants, default `colors.border`), dividerWidth (borderWidth), itemStyles, slidePressHapticFeedback (`selectionClick`), slideableItems, spacing 4} (item_group.dart:517-563) from `FThemeData.itemGroupStyle` (theme_data.dart:253); provided down the tree via `FItemGroupStyleData`. Variant `FItemGroup.disabled`.
- Caveats: `builder` may loop forever in unbounded parents (documented :272-290). Group `children` are typed `List<FItemMixin>`: only `FItem`/`FSubmenuItem`; an `FTile` does not type-check here.
- Evidence: item_group.dart as cited; docs `https://forui.dev/docs/widgets/data/item-group`.

### `FTile` — card-like list row (FItem with tile styling)
- Import: `package:forui/forui.dart` (`lib/widgets/tile.dart`)
- Constructors (tile.dart:185-236, :250-295): `FTile({required Widget title, FItemVariant variant = .primary, FItemStyleDelta style, bool? enabled, bool selected = false, String? semanticsLabel, String? semanticsTooltip, bool? semanticsExpanded, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, VoidCallback? onPress, VoidCallback? onLongPress, VoidCallback? onDoubleTap, VoidCallback? onSecondaryPress, VoidCallback? onSecondaryLongPress, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions, Widget? prefix, Widget? subtitle, Widget? details, Widget? suffix, Key? key})` and `FTile.raw({required Widget child, ..., Widget? prefix, ...})`. Shorthands `FTileMixin.tile/raw/submenu/selectMenu*`.
- Behaviour: a thin wrapper that builds an `FItem`/`FItem.raw` (tile.dart:211-236) inside `FInheritedItemData.merge(styles: data == null ? theme.tileStyles.toItemStyles() : null, last: true)` (:298-305). Everything in FItem (press logic, static-vs-interactive, enabled, layout, dividers, combine callbacks) applies verbatim.
- Differences from FItem:
  - **No `semanticsButton`, `semanticsChecked`, `semanticsInMutuallyExclusiveGroup`** params (only `semanticsExpanded`).
  - Visuals come from `FTileStyle` (extends `FItemStyle`): background `colors.card`, bordered rounded-md shape, content padding 15 horizontal / 14.5 vertical, `prefixIconSpacing 10`, `titleSpacing 3`, `suffixIconSpacing 5`, subtitle `body.xs2`, details `body.sm` (tile.dart:378-519). Hovered/pressed -> `colors.secondary`; disabled -> `colors.disable(secondary)`.
  - **No `selected` variant in the default tile decoration or text styles** (tile.dart:403-408, :465-488): `selected: true` has no visual effect unless you add it via `style: .delta(...)`; it still sets the `selected` semantics flag. (FItem, by contrast, paints selected = `colors.secondary`.)
  - Destructive variant colours both content styles destructive (tile.dart:345-359), unlike FItem.raw.
  - Same tappable tuning as FItem (no bounce, zero press delay, 25 ms exit) and focused outline spacing `-borderWidth * 2` (tile.dart:422-427).
  - `FSizes.tile` = 48 (`sizes.dart:46-47`).
- Motion/semantics/focus: as FItem.
- Styling: `FTileStyles` from `FThemeData.tileStyles` (theme_data.dart:495); `FTileStyle`, `FTileContentStyle`, `FRawTileContentStyle`; deltas via `FItemStyleDelta` on the widget (the widget's `style` type is `FItemStyleDelta`).
- Limitations: `FTile` goes in `FTileGroup`, not `FItemGroup` (type `FTileMixin`).
- Evidence: tile.dart; tests `tile/tile_test.dart`; docs `https://forui.dev/docs/widgets/tile/tile`.

### `FTileGroup` — group of tiles with optional label/description/error
- Import: `package:forui/forui.dart` (`lib/widgets/tile.dart`)
- Constructors (tile_group.dart:160-293):
  - `FTileGroup({required List<FTileMixin> children, FTileGroupStyleDelta style = const .context(), ScrollController? scrollController, ScrollCacheExtent? scrollCacheExtent, double maxHeight = .infinity, DragStartBehavior dragStartBehavior = .start, ScrollPhysics physics = const ClampingScrollPhysics(), bool? enabled, bool? intrinsicWidth, FItemDivider divider = .indented, String? semanticsLabel, Widget? label, Widget? description, Widget? error, Key? key})`.
  - `FTileGroup.builder({required NullableIndexedWidgetBuilder tileBuilder, int? count, ..., FItemDivider divider = .indented, ...})` (no `intrinsicWidth`).
  - `FTileGroup.merge({required List<FTileGroupMixin> children, ..., FItemDivider divider = .full, ...})`.
  - Shorthands `FTileGroupMixin.group/builder/merge/selectGroup/selectGroupBuilder`.
- Behaviour: same engine as `FItemGroup` (sliver list in a shrink-wrapped `CustomScrollView`, press-slide when `maxHeight` is infinite, `ClipPath`, enabled/intrinsicWidth cascade, tile_group.dart:296-357). Differences:
  - **Default divider is `.indented`** (items group default is `.none`).
  - Root group is wrapped in `FLabel(layout: .vertical, variants: {disabled?, error?}, label, description, error)` (:348-356); labels are ignored when the group is nested (the nested branch returns early, :302-305) and in `merge`.
  - `semanticsLabel` adds a `Semantics(container: true)` only when given (:344-346); FItemGroup always adds the container.
  - Passing `error` switches the label to the error variant; the error text animates in (see FLabel).
  - Tiles inside the group get the group's `tileStyles`, with the per-tile shape replaced by a plain `RoundedSuperellipseBorder()` (no border, zero radius) so the group's decoration supplies the outer border/rounding (tile_group.dart:462-468).
- Styling: `FTileGroupStyle` extends `FLabelStyle` {decoration (border + rounded md), dividerColor, dividerWidth, tileStyles, slidePressHapticFeedback, slideableTiles, label/description/error text styles and paddings} (:403-496), from `FThemeData.tileGroupStyle` (theme_data.dart:505). No `spacing` field (unlike item group).
- State/semantics/motion: as FItemGroup plus FLabel's error motion.
- Evidence: tile_group.dart; docs `https://forui.dev/docs/widgets/tile/tile-group`.

### `FSelectTileGroup<T>` + `FSelectTile<T>` — multi/single choice tiles
- Import: `package:forui/forui.dart` (`lib/widgets/select_tile_group.dart`; hides internal `FSelectTileData`)
- Constructors:
  - `FSelectTileGroup<T>({required List<FSelectTile<T>> children, FMultiValueControl<T>? control, ScrollController? scrollController, FTileGroupStyleDelta style, ScrollCacheExtent? scrollCacheExtent, double maxHeight = .infinity, bool? intrinsicWidth, DragStartBehavior dragStartBehavior = .start, ScrollPhysics physics = const ClampingScrollPhysics(), FItemDivider divider = .indented, Widget? label, Widget? description, String? semanticsLabel, Widget Function(BuildContext, String) errorBuilder = FFormFieldProperties.defaultErrorBuilder, FormFieldSetter<Set<T>>? onSaved, VoidCallback? onReset, FormFieldValidator<Set<T>>? validator, String? forceErrorText, bool enabled = true, AutovalidateMode autovalidateMode = .disabled, Key? formFieldKey, Key? key})` (select_tile_group.dart:122-147).
  - `FSelectTileGroup<T>.builder({required FSelectTile<T>? Function(BuildContext, int) tileBuilder, int? count, ...same minus intrinsicWidth...})` (:153-177).
  - `const FSelectTile<T>({required Widget title, required T value, FItemStyleDelta style, Widget? checkedIcon, Widget? uncheckedIcon, Widget? subtitle, Widget? details, String? semanticsLabel, bool? enabled, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions, Widget? suffix, Key? key})` (select_tile.dart:87-107); `FSelectTile.tile(...)` is identical; `FSelectTile.suffix({..., Widget? prefix, ...})` puts the check mark at the end and your widget at the start (:137-157).
- State / control: value type is `Set<T>` even for single choice. `FMultiValueControl<T>` (`lib/src/foundation/notifiers.dart:158-179`): `.managed({controller, Set<T>? initial, int min, int? max, ValueChanged<Set<T>>? onChange})`, `.managedRadio({controller, T? initial, onChange})` (single, cannot be deselected), `.lifted({required Set<T> value, required ValueChanged<Set<T>> onChange})`. Default when `control == null`: `.managed()` (select_tile_group.dart:213, 219). `FMultiValueNotifier.radio` ignores a press on the selected value (`!add || contains` -> return, notifiers.dart:~95-101), and `min`/`max` bound the set size (update is silently ignored at the limits, notifiers.dart:60-72). It is a `FormField` (validator, onSaved, reset, autovalidate) via `MultiValueFormField`.
- Behaviour: each `FSelectTile` builds an `FTile` with `selected` and `onPress: controller.update(value, add: !selected)` (select_tile.dart:171-197). Default icon is `icons.check`; unselected renders the same icon transparent so row widths do not shift (:162-169). The check goes to the prefix position by default and to the suffix with `.suffix`.
- Interaction states: inherits FTile (hover/press/disabled colours; no selected fill, see FTile). `enabled` on the group disables every tile (`enabled: widget.enabled`, :266, :287).
- Semantics: `selected` flag on the tile (via `FTappable.selected`), no `checked`/radio role because `FSelectTile` passes neither `semanticsChecked` nor `semanticsInMutuallyExclusiveGroup` (FTile does not even expose them). Group label `semanticsLabel` container only.
- Errors: validation text goes through `errorBuilder` and `FTileGroup(error:)`; hidden when disabled (select_tile_group.dart:249-253).
- Doc vs code: `label`/`description` doc says they are "not rendered if the group is disabled or part of a FTileGroup" (select_tile_group.dart:70-76); the code passes them to `FTileGroup` regardless of `enabled` (:265-267, :286-288). Nested-ness is handled by `FTileGroup`. UNVERIFIED which is intended for the disabled case.
- Requires: `FSelectTile` must sit under `FSelectTileGroup`/`FSelectMenuTile` (`FSelectTileData.of` asserts, select_tile.dart:220-223).
- Styling: `FTileGroupStyle` (same as FTileGroup).
- Evidence: select_tile_group.dart, select_tile.dart; tests `select_tile_group/*`; docs `https://forui.dev/docs/widgets/tile/select-tile-group`.

### `FSelectMenuTile<T>` — a tile that opens a popover menu of FSelectTiles
- Import: `package:forui/forui.dart` (`lib/widgets/select_menu_tile.dart`)
- Constructors (select_menu_tile.dart:242-296, :305-411, :430-484): `FSelectMenuTile<T>({required Widget title, required List<FSelectTile<T>> menu, FMultiValueControl<T>? selectControl, FPopoverControl popoverControl = const .managed(), ScrollController? scrollController, FSelectMenuTileStyleDelta style, ScrollCacheExtent? scrollCacheExtent, double maxHeight = .infinity, bool menuIntrinsicWidth = false, DragStartBehavior dragStartBehavior = .start, ScrollPhysics physics = const ClampingScrollPhysics(), FItemDivider divider = .full, AlignmentGeometry menuAnchor = .topRight, AlignmentGeometry tileAnchor = .bottomRight, FPortalSpacing menuSpacing = const .spacing(4), FPortalOverflow menuOverflow = .flip, FPortalArrowAlignment? menuArrow, bool menuUseViewPadding = true, bool menuUseViewInsets = true, OverlayChildLocation menuOverlayLocation = .nearestOverlay, Offset menuOffset = .zero, FPopoverHideRegion menuHideRegion = .excludeChild, VoidCallback? menuOnTapHide, Object? menuGroupId, bool menuCutout = true, void Function(Path, Rect) menuCutoutBuilder, bool autoHide = true, Widget? label, Widget? description, bool autofocus = false, FocusScopeNode? menuFocusNode, ValueChanged<bool>? menuOnFocusChange, TraversalEdgeBehavior? menuTraversalEdgeBehavior, String? menuBarrierSemanticsLabel, bool menuBarrierSemanticsDismissible = true, String? semanticsLabel, Widget? prefix, Widget? subtitle, ValueWidgetBuilder<Set<T>> detailsBuilder = defaultSelectMenuTileBuilder, Widget? details, Widget? suffix, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions, errorBuilder, onSaved, onReset, validator, forceErrorText, bool enabled = true, AutovalidateMode autovalidateMode = .disabled, Key? formFieldKey, Key? key})`; `FSelectMenuTile.fromMap(Map<String, T> menu, {required Text title, ...})`; `FSelectMenuTile.builder({required Widget title, required FSelectTile<T>? Function(BuildContext, int) menuBuilder, int? count, ...})`. Shorthands `FTileMixin.selectMenu/selectMenuFromMap/selectMenuBuilder`.
- State / control: `selectControl` (`FMultiValueControl<T>`, as above; use `.managedRadio` for single choice) and `popoverControl` (`FPopoverControl`). Form field via `MultiValueFormField`.
- Behaviour: an `FPopover` anchored to an `FTile` (select_menu_tile.dart:611-701). Tapping the tile toggles the popover (`onPress: _controller._popover.toggle`, :700); the menu is an `FSelectTileGroup` in an `FInheritedItemData` reset (:647-661); selecting a value hides the popover first when `autoHide` (default true) (`_Notifier.update`, :741-747). **`details` is empty by default**: you must provide `detailsBuilder` (receives the selected `Set<T>`) to show the current value (`defaultSelectMenuTileBuilder` returns `details` or nothing, :15-16). Default suffix is `icons.chevronsUpDown` (:697).
- Semantics: the tile carries `semanticsExpanded` of the popover (:682); the form wrapper adds `validationResult` valid/invalid (:724); `menuBarrierSemanticsLabel`/`Dismissible` forwarded to the popover barrier; `semanticsLabel` applies to the menu group, not the tile.
- Focus: `autofocus` goes to the popover; focus tracking toggles the `focused` form variant for the label only when `FAccessibility.focusHighlight` (:709).
- Label/error: shown (via `FLabel(layout: .vertical)`) only when there is no inherited `FInheritedItemData` and a label, description or error exists (:705-722). Inside an `FTileGroup` the label is ignored.
- Motion: popover/overlay animation is `FPopover`'s (see the popover catalog); tile itself none.
- Styling: `FSelectMenuTileStyle` extends `FLabelStyle` {menuStyle (`FPopoverMenuStyle`), tileStyle (`FTileStyle`)} (:775-823) from `FThemeData.selectMenuTileStyle` (theme_data.dart:415); inside a `FTileGroup` the tile style is replaced by the group's primary tile style (:593-597).
- Caveats: needs an `Overlay` ancestor (popover); the menu is a floating popover, not a bottom sheet, on every platform (no touch-specific variant in this file). The comments recommend `FSelectGroup` on desktop.
- Evidence: select_menu_tile.dart; tests `select_menu_tile/*`; docs `https://forui.dev/docs/widgets/tile/select-menu-tile`.

---

## 3. Navigation

### `FBottomNavigationBar` + `FBottomNavigationBarItem` (+ `FBottomNavigationBarData`)
- Import: `package:forui/forui.dart` (`lib/widgets/bottom_navigation_bar.dart`)
- Constructors:
  - `const FBottomNavigationBar({required List<Widget> children, FBottomNavigationBarStyleDelta style = const .context(), bool safeAreaTop = false, bool safeAreaBottom = false, int index = -1, ValueChanged<int>? onChange, Key? key})` (bottom_navigation_bar.dart:63-71).
  - `const FBottomNavigationBarItem({required Widget icon, Widget? label, String? semanticsLabel, FBottomNavigationBarItemStyleDelta style, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, Key? key})` (bottom_navigation_bar_item.dart:61-72).
- State / control: **fully lifted**: the bar is stateless; the caller owns `index` (default -1 = nothing selected) and `onChange(int)`. Each child gets `FBottomNavigationBarData{itemStyle, selected: i == index, index, length, onChange}` (:81-91). There is no controller class. Children are `List<Widget>`; custom items must read `FBottomNavigationBarData.of(context)` (asserts an ancestor, :146-149).
- Layout: `Row(spaceAround)` with each child in `Expanded` (equal widths), optional `FTappableGroup` slide-across (`slideableItems`, :95-97), `SafeArea(top: safeAreaTop, bottom: safeAreaBottom)` inside a `DecoratedBox(style.decoration)` (top border, `colors.background` fill) (:101-111).
  - **Bottom inset rule:** with `safeAreaBottom: false` (default) it adds `MediaQuery.viewPaddingOf(context).bottom * 2 / 3` as extra bottom padding; with `true` it uses `SafeArea(bottom: true)` and adds 0 (bottom_navigation_bar.dart:99-107; tests `bottom_navigation_bar_test.dart:94-130`). Do not combine with another bottom safe-area wrapper.
  - `style.padding` default 5 all around.
- Item behaviour: `MergeSemantics(FTappable(behavior: .opaque, selected: selected, onPress: () => onChange?.call(index)))` (item.dart:80-92). **`onChange` fires on every tap, including a tap on the already-selected item** (no equality guard). With `onChange == null` the item is still a (non-disabled) tappable because `onPress` is a non-null closure.
- Item layout: `Padding(5) > Column(icon (24 dp, inside ExcludeSemantics), optional label (spacing 2, `body.xs3` touch 10 px, height 1.5, ellipsis), invisible Semantics(label: 'Tab i of n'))`. Icon-only item content height is about 34 dp (5 + 24 + 5, computed from source; UNVERIFIED by render), below 48 dp; adding a label gives roughly 51 dp. Width is 1/n of the bar so the row is wide enough.
- Interaction states: `iconStyle` and `textStyle` variants `hovered/pressed` -> `colors.hover(mutedForeground)`, `selected` -> `colors.primary` (icon weight 700, text bold) (bottom_navigation_bar_item.dart:161-174). Item uses the plain theme `tappableStyle` (bounce 0.97, 100 ms press delay).
- Focus & semantics: the merged node reads `semanticsLabel`/label text, `selected` flag, and a trailing localized "Tab i of n" label (order is deliberately `<label>, <position>`, :110-112). Icon is excluded from semantics, so **an icon-only item needs `semanticsLabel`** (documented, item.dart doc "strongly recommended").
- Motion: no state animation of its own; press bounce from FTappable (suppressed only when `motion == disabled`).
- Styling: `FBottomNavigationBarStyle` {decoration, itemStyle, backgroundFilter, padding, slideableItems} (:194-251) from `FThemeData.bottomNavigationBarStyle` (theme_data.dart:105); `FBottomNavigationBarItemStyle` {iconStyle, textStyle, tappableStyle, focusedOutlineStyle, padding, spacing} (item.dart:135-178).
- Caveats: top border doubles with `FScaffold.footer` (see FScaffold). `children` are not constrained to `FBottomNavigationBarItem`. No badge/dot slot, no per-item disabled state. Does not manage routing (pair with a `StatefulShellRoute` by hand).
- Evidence: bottom_navigation_bar.dart, bottom_navigation_bar_item.dart; tests `bottom_navigation_bar/*`; docs `https://forui.dev/docs/widgets/navigation/bottom-navigation-bar`.

### `FBreadcrumb` + `FBreadcrumbItem` (+ `.collapsed`, `.collapsedTiles`)
- Import: `package:forui/forui.dart` (`lib/widgets/breadcrumb.dart`; hides `FBreadcrumbItemData`)
- Constructors:
  - `const FBreadcrumb({required List<Widget> children, FBreadcrumbStyleDelta style = const .context(), Widget? divider, Key? key})` (breadcrumb.dart:57).
  - `FBreadcrumbItem` is an `abstract interface class`: `const FBreadcrumbItem({required Widget child, bool current = false, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, VoidCallback? onPress, Key? key})`; `const FBreadcrumbItem.collapsed({required List<FItemGroup> menu, Widget? icon, FPopoverMenuStyleDelta popoverMenuStyle, FPopoverControl popoverControl, ScrollController? scrollController, ScrollCacheExtent? scrollCacheExtent, double maxHeight, bool intrinsicWidth, DragStartBehavior dragStartBehavior, FItemDivider divider, AlignmentGeometry menuAnchor, AlignmentGeometry childAnchor, FPortalSpacing spacing, FPortalOverflow overflow, FPortalArrowAlignment? arrow, Offset offset, FPopoverHideRegion hideRegion, bool cutout, void Function(Path, Rect) cutoutBuilder, VoidCallback? onTapHide, bool autofocus, FocusScopeNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, TraversalEdgeBehavior traversalEdgeBehavior, String? semanticsLabel, String? menuSemanticsLabel, Key? key})`; `const FBreadcrumbItem.collapsedTiles({required List<FTileGroup> menu, ...same minus onTapHide...})` (breadcrumb.dart:109-194; defaults at :286-350: `intrinsicWidth = true`, `divider = .full`, `menuAnchor = .topLeft`, `childAnchor = .bottomLeft`, `spacing = .spacing(4)`, `overflow = .flip`; the tiles variant defaults `traversalEdgeBehavior = .closedLoop`).
- State / control: stateless; `current` marks the last crumb; collapsed crumbs own a `FPopoverControl` (default `.managed()`).
- Layout: `Row` of `[crumb, divider, crumb, ...]`, divider default `icons.chevronRight` coloured by `iconStyle` (breadcrumb.dart:64-70). **No `Flexible`/scroll/ellipsis between crumbs**, so a long trail overflows the row (UNVERIFIED by run; crumbs are only wrapped in `Padding`).
- Crumb behaviour (:197-238): `onPress == null` -> plain `Semantics(selected: current ? true : null)` + `DefaultTextStyle` + padding, no tappable, no button semantics; `onPress != null` -> `FTappable(selected: current, onPress)`. `current` makes the text `colors.foreground`; others are `mutedForeground`; hover/press -> foreground.
- Collapsed crumb: an ellipsis icon in an `FTappable` (semantics label "More"/"Thêm" or `semanticsLabel`, `semanticsExpanded`), toggling an `FPopoverMenu` (`.collapsed`) or `FPopoverMenu.tiles` (`.collapsedTiles`) (:415-492). Docs mark it "recommended for desktops & web" (breadcrumb.dart:121-126).
- Touch size: crumb padding touch `6 x 10`, collapsed `6 x 13` (:526-532), plus text height; below 48 dp tall (computed, UNVERIFIED).
- Motion: tappable motion `none`; no other animation (breadcrumb.dart:549).
- Styling: `FBreadcrumbStyle` {textStyle (variants), iconStyle, tappableStyle, focusedOutlineStyle, padding, collapsedPadding} (:496-552) from `FThemeData.breadcrumbStyle` (theme_data.dart:115).
- Requires: `FBreadcrumbItemData.of` asserts an `FBreadcrumb` ancestor (:85-88).
- Evidence: breadcrumb.dart; tests `breadcrumb/*`; docs `https://forui.dev/docs/widgets/navigation/breadcrumb`.

### `FTabs` + `FTabEntry` + `FTabController` / `FTabControl`
- Import: `package:forui/forui.dart` (`lib/widgets/tabs.dart`)
- Constructors:
  - `FTabs({required List<FTabEntry> children, FTabControl control = const .managed(), bool scrollable = false, ScrollPhysics? physics, ScrollPhysics contentPhysics = const BouncingScrollPhysics(), FTabsStyleDelta style = const .context(), ValueChanged<int>? onPress, MouseCursor mouseCursor = .defer, bool expands = false, Key? key})`; assert `children.isNotEmpty` (tabs.dart:115-126). Non-const (the constructor is `new`, not `const new`).
  - `const FTabEntry({required Widget label, required Widget child})` and `const FTabEntry.entry(...)` (tabs.dart:30-35).
  - `FTabController({required int length, required TickerProvider vsync, int index = 0, FTabMotionDelta motion})` (tab_controller.dart); `animateTo(int, {duration, curve})`, `index` get/set, `length`.
- State / control: `FTabControl.managed({FTabController? controller, int? initial, FTabMotion? motion, ValueChanged<int>? onChange})` and `FTabControl.lifted({required int index, required ValueChanged<int> onChange, FTabMotion motion})` (tab_controller.dart `FTabControl`). `controller` is exclusive with `initial`/`motion` (asserts). `onChange` fires only when the index is no longer changing, i.e. after the animation finishes (tabs.dart:175-182); `onPress` fires on tap before the switch animation starts (documented, tabs.dart:91-93).
- **Can it be used without a content pane? Not structurally.** `FTabEntry.child` is required for every tab; with `expands: false` the active `child` is built right under the bar (tabs.dart:226) after a `SizedBox(height: style.spacing)` (default 10) (:215); with `expands: true` a `TabBarView` in `Expanded` is built (:219-225; needs bounded height). A bar-only usage is possible by giving each entry `child: const SizedBox.shrink()` (renders nothing) and setting `style: .delta(spacing: 0)` (the delta takes `spacing`, tabs.design.dart:282-290 region); that is a workaround, not an API. `FTabs` has no `FTabs.bar`-style constructor (checked `lib/src/widgets/tabs/*`).
- Implementation: built on Material's `TabBar` inside `Material(color: transparent)` (tabs.dart:190-197). `tabAlignment` is `fill` (equal widths) unless `scrollable` (then `start`, widths by label) (:198). If no `MaterialLocalizations` exists it injects `GlobalMaterialLocalizations.delegates` itself (:232-238).
- Interaction states: variants only `FTab.selected` (tabs.dart:12). Selected/unselected label style = `labelTextStyle.resolve({platform, selected})`. **No pressed/hover feedback**: `overlayColor` is transparent and `splashFactory` is `NoSplash` (:210-211). The selected tab is shown by the indicator decoration (default: raised background pill, `indicatorSize` `tab` or `label`).
- Focus & semantics: each tab label is wrapped in `FFocusedOutline` driven by the surrounding focus node (tabs.dart:255-285). Semantics come from Material's `TabBar`: `role: tabBar` container, per-tab `role: tab`, `selected`, label "Tab i of n" from `MaterialLocalizations.tabLabel` (not Forui's strings; `material_ui-1.4.0/lib/src/tabs.dart:2143-2170`). Tap target height is `style.minHeight` (default 36) inside the bar `padding` 4; below 48 dp. Material's tap also triggers `enableFeedback` platform feedback (Material default true, tabs.dart:2133 in material_ui).
- Motion: tab switch animation `FTabMotion {duration 300 ms, curve easeOutCubic}` (tab_controller.dart); set to zero duration when `context.accessibility.motion != all` (tabs.dart:159, 166; `_apply`). Content swipe (`expands: true`) uses `contentPhysics` (Bouncing by default).
- Styling: `FTabsStyle {decoration (muted pill), labelTextStyle (variants), indicatorDecoration, focusedOutlineStyle, padding 4, indicatorSize, minHeight 36, spacing 10}` (tabs_style.dart) from `FThemeData.tabsStyle` (theme_data.dart:465).
- Caveats: the `TabController` length is fixed at creation; there is no code path that recreates it when `children.length` changes (tabs.dart:162-167 -> control `_update` default returns the same controller), and Material asserts `"Controller's length property ... does not match"` (material_ui tabs.dart:1981). UNVERIFIED by run. Needs a `TickerProvider` only internally (`FTabs` supplies one).
- Evidence: tabs.dart, tab_controller.dart, tabs_style.dart, tabs.control.dart; tests `tabs/*`; docs `https://forui.dev/docs/widgets/navigation/tabs`.

### `FPagination` + `FPaginationController` / `FPaginationControl`
- Import: `package:forui/forui.dart` (`lib/widgets/pagination.dart`; also exports `FPaginationController`, `FPaginationStyle`)
- Constructor (pagination.dart:51): `const FPagination({FPaginationControl control = const .managed(), FPaginationStyleDelta style = const .context(), Widget? previous, Widget? next, Key? key})`.
- State / control: `FPaginationControl.managed({FPaginationController? controller, int? initial, int? pages, int? siblings, bool showEdges, ValueChanged<int>? onChange})` and `FPaginationControl.lifted({required int page, required ValueChanged<int> onChange, required int pages, int siblings, bool showEdges})` (pagination_controller.dart:~195-260). Pages are 0-based internally and displayed 1-based. `FPaginationController({required int pages, int page = 0, int siblings = 1, bool _showEdges = true})` extends `ValueNotifier<int>` with `next()`, `previous()`, `pages`/`siblings`/`showEdges` setters; assigning `value` outside range throws `StateError`. Without a controller, `.managed()` defaults to `pages = 1` (pagination_controller.dart `createController`). **Changing `pages:` on a rebuilt `.managed()` control has no effect** (the update logic only swaps controllers, `_default` returns the old one; pagination_controller.control.dart:50-77); use `.lifted` or an external controller and set `controller.pages`.
- Layout: `Row(mainAxisAlignment: center)` of `[previous, (first, ellipsis)?, window of pages, (ellipsis, last)?, next]` (pagination.dart:132-150). All pages are shown when `pages <= 3*siblings + 3 + (showEdges ? 1 : 0)` (7 at defaults; from `minPagesDisplayedAtEdges`); beyond that the row always has 9 slots at defaults (prev, first, ellipsis, 3 pages, ellipsis, last, next) (pagination_controller.dart `minPagesDisplayedAtEdges`, `siblingRange`). Each slot is `itemConstraints` tight 44x44 (touch) or 32x32 plus 2 dp horizontal padding each side (pagination_style.dart). On touch that is 9 x 48 = 432 dp, wider than a 360 dp phone: the `Row` has no flex/scroll, so it will overflow (computed from source; UNVERIFIED by run). With `siblings: 0` and `showEdges: false` the row is narrower.
- Interaction: previous/next are `FTappable`s whose `onPress` is null at the edges (so they become `disabled`: dimmed icon, not focusable); page items are `FTappable(selected: value == page, onPress: controller.value = page)`; tapping the selected page re-sets the same value.
- Semantics: page tappable labelled "Page n"/"Trang n" with `selected`; digits excluded from semantics (`ExcludeSemantics`) to avoid duplicate announcement (:241-251); previous/next labelled "Previous"/"Next" ("Trước"/"Tiếp"); ellipsis excluded. `previous`/`next` params replace the **whole** button (including semantics and edge-disable logic), not just the icon (:115-130).
- Motion: no own animation; tappable bounce applies (`actionTappableStyle`/`pageTappableStyle` = theme tappable style).
- Styling: `FPaginationStyle {itemIconStyle, itemDecoration (selected = colors.primary fill), itemTextStyle (selected = primaryForeground), ellipsisTextStyle, actionTappableStyle, pageTappableStyle, focusedOutlineStyle, itemConstraints, itemPadding}` from `FThemeData.paginationStyle` (theme_data.dart:305).
- Evidence: pagination.dart, pagination_controller.dart, pagination_style.dart; tests `pagination/*`; docs `https://forui.dev/docs/widgets/navigation/pagination`.

### `FSidebar` + `FSidebarGroup` + `FSidebarItem`
- Import: `package:forui/forui.dart` (`lib/widgets/sidebar.dart`)
- Constructors:
  - `FSidebar({required List<Widget> children, Widget? header, Widget? footer, FSidebarStyleDelta style, bool autofocus = false, FocusScopeNode? focusNode, TraversalEdgeBehavior? traversalEdgeBehavior, Key? key})` (sidebar.dart:82-95; content is a `ListView(children)`); `FSidebar.builder({required Widget Function(BuildContext, int) itemBuilder, required int itemCount, ...})` (:98-112); `const FSidebar.raw({required Widget child, ...})` (:118-130). `focusNode` and `traversalEdgeBehavior` are mutually exclusive.
  - `const FSidebarGroup({required List<Widget> children, FSidebarGroupStyleDelta style, Widget? label, Widget? action, ValueChanged<bool>? onActionHoverChange, FTappableVariantChangeCallback? onActionVariantChange, VoidCallback? onActionPress, VoidCallback? onActionLongPress, Key? key})` (sidebar_group.dart:63-73).
  - `const FSidebarItem({FSidebarItemStyleDelta style, Widget? icon, Widget? label, bool selected = false, bool initiallyExpanded = false, bool autofocus = false, FocusNode? focusNode, VoidCallback? onPress, VoidCallback? onLongPress, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, List<Widget> children = const [], Key? key})` (sidebar_item.dart:77-91).
- Layout: `FocusScope > DecoratedBox(decoration) > ConstrainedBox(constraints) > Column[header (sticky), Expanded(content), footer (sticky)]` (sidebar.dart:184-205). **Default width is fixed at 256** (`BoxConstraints.tightFor(width: 256)`, :257) with an end-side 1 px border; there is no responsive/collapse behaviour and no overlay/drawer mode. Place it in `FScaffold.sidebar` (docs recommend FHeader/bottom nav for touch: header.dart:27-29 "Prefer FSidebar on desktop and larger screens").
- State / control: sidebar stateless apart from its `FocusScopeNode`; `FSidebarItem` keeps its own expansion state (`initiallyExpanded`; no controller, no external open/close API) (sidebar_item.dart:124, :277-281). Selected state is lifted: the `selected` flag is the caller's.
- Item behaviour: with `children` non-empty, a press toggles expansion **and** then calls `onPress` (:213-218) and shows a chevron that rotates 0 -> 0.25 turn; with no children and no `onPress`, the item is `disabled` (muted colours, not focusable). `FTappable(selected, semanticsExpanded: children.isEmpty ? null : _expanded)`; **no `semanticsLabel` param**: the label widget's text provides the name.
- Group: optional header row (label ellipsis `body.xs` muted + optional action `FTappable` with `onActionPress`/`onActionLongPress`); children spaced by `childrenSpacing` 4; items inherit `groupStyle.itemStyle` (sidebar_group.dart:77-122; sidebar_item.dart:145-149).
- Motion: expand/collapse `FSidebarItemMotion` {expand 200 ms easeOutCubic, collapse 150 ms easeInCubic, icon rotation easeOut} (sidebar_item.dart:386-421). Reduced motion: when `motion != all` the size reveal and icon rotation use zero duration; when `motion == disabled` the fade also becomes instant (sidebar_item.dart:161-174). The fade curves are hard-coded `Curves.easeIn`/`easeOut` (:180), so `FSidebarItemMotion.fadeInCurve`/`fadeOutCurve` are never read (declared at :400-403).
- Styling: `FSidebarStyle {decoration, groupStyle, constraints, backgroundFilter, headerPadding, contentPadding, footerPadding}` (sidebar.dart:249-301) from `FThemeData.sidebarStyle` (theme_data.dart:425); `FSidebarGroupStyle`, `FSidebarItemStyle` (touch padding 12 x 14 vs desktop 8; tappable `motion: none`). Group/item fall back to `context.theme.sidebarStyle...` when no `FSidebar` ancestor, so they work standalone.
- Evidence: sidebar.dart, sidebar_group.dart, sidebar_item.dart; tests `sidebar/*`; docs `https://forui.dev/docs/widgets/navigation/sidebar`.

---

## Gaps / surprises

1. **FScaffold does no safe-area handling except what FHeader (top) and FBottomNavigationBar (bottom, opt-in) do.** No left/right/bottom `SafeArea`, no `removeViewInsets` for descendants, no FAB slot. The footer is not lifted above the keyboard (it sits under it); only the content shrinks to the keyboard top.
2. FScaffold hosts only `FSheets` (persistent sheets). Toasts need an app-level `FToaster`; FScaffold does not provide it.
3. `FItem` / `FTile` are inert (no tappable, no button semantics, `selected` ignored) when all press callbacks are null; `enabled: false` only matters through the callbacks. Shorthand `FItemMixin.item/raw` drop four semantics params that `FItem` has; `FTile` lacks `semanticsButton/Checked/InMutuallyExclusiveGroup` entirely.
4. `FTile.selected` has no default visual in `FTileStyle` (only `FItem` paints it); `FSelectTile` relies on the check icon and the `selected` semantics flag. No `checked`/radio semantics for select tiles.
5. FItemGroup `divider` doc says default `.indented`, code defaults to `.none` (FTileGroup/FSelectTileGroup really default to `.indented`).
6. `FItem.raw` destructive variant colours prefix and text with `colors.primary` (item.dart:488-494), unlike the content style and the tile version.
7. `FItem(...)` titles/subtitles wrap rather than truncate (no `maxLines`); text `details` is truncated first only when it is a plain `Text` render paragraph (item_content_layout.dart).
8. `FDivider` default has 16 dp margin on both sides (surprising spacing) and uses `colors.secondary`; `FCard` applies no padding (the `padding`/title styles are for snippet layouts).
9. `FPagination` managed control ignores later `pages:` changes; at touch size 9 slots x 48 dp = 432 dp overflows a 360 dp screen (computed, not run).
10. `FTabs` always carries a content pane (required `child`, spacing row); built on Material `TabBar` with no pressed feedback; tab count must stay constant.
11. `FBottomNavigationBar` calls `onChange` for re-taps of the selected item; icon-only items need `semanticsLabel`; icon-only touch height is only about 34 dp (computed).
12. `FSidebar` is a fixed 256 dp panel with no collapse/drawer mode; `FSidebarItemMotion.fadeInCurve/fadeOutCurve` are unused.
13. Touch targets below 48 dp by construction: header actions 44 dp, tabs 36 dp, breadcrumb crumbs, bottom-nav icon-only items; pagination items are 44 dp. Items 44 dp / tiles 48 dp are the design sizes (`sizes.dart`), not enforced minimums.
14. FTappable bounce is not disabled by `FAccessibilityMotion.reduced`, only by `disabled`; FLabel/FTabs/FSidebarItem treat `reduced` as "no motion". Items/tiles/crumbs/sidebar items set tappable motion to `none` anyway; header actions, bottom-nav items and pagination keep the bounce.
15. Source incidental: `lib/src/localizations/localizations_vi.dart` has `barrierOnTapHint` returning `'Đóng \$modalRouteContentName'` (escaped `$`), likely a literal in the Vietnamese string (outside this category; seen at the top of that file; not investigated).
16. UNVERIFIED (not run): all rendered sizes, overflow claims, `semanticsLabel` concatenation on FItem, Tabs length-change assertion, nested-scroll behaviour of the shrink-wrapped root `CustomScrollView` inside page-level lists.

---

## ForUI 0.27.6 API catalog C: actions, forms, selection controls

Scope: FButton, FBadge, FAvatar, FTooltip; FTextField, FTextFormField, FOtpField, FAutocomplete, FDateField, FTimeField,
FDateTimePicker, FTimePicker, FPicker (+ wheels), FSelect, FMultiSelect, FLabel; FCheckbox, FRadio, FSwitch, FSlider,
FSelectGroup, FSelectTileGroup (selection model only).

## Method and evidence conventions

- Source root: `forui-0.27.6/lib/`. Paths below are relative to `lib/src/` unless they
  start with `material_ui:` (= `material_ui-1.4.0/lib/src/`).
- Docs root (version-matched): `.../scratchpad/forui-src/docs/content/docs/`; page URL = `https://forui.dev/docs/<path>`.
  Docs snippets: `.../scratchpad/forui-src/docs_snippets/lib/examples/form/*.dart`.
- The package source uses Dart primary-constructor / dot-shorthand syntax (`new({...})`, `const factory`, `.md`); signatures
  below are transcribed from those declarations. `required` is marked.
- Constructors that are `factory(...) = Impl` hide defaults in the redirect target; defaults below are taken from the
  target class.
- **PROBE** = a runtime check I ran (not a code reading). Throwaway Flutter test project (outside the MemoX repo):
  `(isolated probe project)/` (`flutter test test/<file>`
  with `forui: 0.27.6`, Flutter 3.47.5, `FTheme.neutral.light.touch`, `MaterialApp` host, 360dp wide, default text scale).
  Files: `sem_test.dart` (button/badge/avatar), `text_test.dart`, `sel_test.dart`, `pick_test.dart`, `pick2_test.dart`,
  `date_test.dart`, `tip_test.dart`, `reset_test.dart`, `reset2_test.dart`, `form_test.dart`; helper `common.dart` prints the semantics tree.
  Probe output is quoted as `flags / actions / label / value / hint` from `SemanticsNode.getSemanticsData()`.
- "Overlay" caveat: every popover/tooltip-based widget below ends in `OverlayPortal` (`foundation/overlay/portal.dart:220`,
  `overlay.dart:169`), so it needs an `Overlay` ancestor (a `MaterialApp`/`Navigator` provides one). Not exercised without one.
- Common to all widgets: `context.theme.<x>` / `context.platformVariant` come from `FTheme` (`theme/theme.dart:94`);
  `FTheme` also installs `FAccessibilityScope` (`theme/theme.dart:330`, `foundation/accessibility.dart`), the single source
  of `FAccessibility.motion` (`all | reduced | disabled`), `.focusHighlight`, `.accessibleNavigation`.
- Built-in strings (password toggle, clear button, "Select an item", "Pick a date", ...) come from `FLocalizations`
  (`vi` is among the shipped locales: `localizations/localizations_vi.dart`); without a `FLocalizations` delegate the code
  falls back to `FDefaultLocalizations()` (English), e.g. `widgets/text_field/text_field.dart:79`.

---------------------------------------------------------------------------------------------------------------------------
## 1. Actions and controls
---------------------------------------------------------------------------------------------------------------------------

### `FButton` — pressable button (text, icon-only, or raw content)
- Import: `package:forui/forui.dart` (exported via `lib/widgets/button.dart`; `Content`/`IconContent` internals hidden)
- Constructors (`widgets/button/button.dart`):
  - `FButton({required VoidCallback? onPress, FButtonVariant variant = .primary, FButtonSizeVariant size = .md,
    FButtonStyleDelta style = const .context(), VoidCallback? onDisabledPress, onLongPress, onDoubleTap, onSecondaryPress,
    onSecondaryLongPress, String? semanticsLabel, String? semanticsTooltip, bool autofocus = false, FocusNode? focusNode,
    ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange,
    bool selected = false, Map<ShortcutActivator, Intent>? shortcuts, Map<Type, Action<Intent>>? actions,
    MainAxisSize mainAxisSize = .max, MainAxisAlignment mainAxisAlignment = .center,
    CrossAxisAlignment crossAxisAlignment = .center, TextBaseline? textBaseline, FButtonContentBuilder? prefixBuilder,
    Widget? prefix, FButtonContentBuilder? suffixBuilder, Widget? suffix, FButtonContentBuilder builder =
    defaultContentBuilder, Widget? child, Key? key})` (`:178-221`; assert: `builder` or `child` required, `:209`).
    NOT const.
  - `FButton.icon({required onPress, variant = .outline, size = .md, style, onDisabledPress, onLongPress, onDoubleTap,
    onSecondaryPress, onSecondaryLongPress, semanticsLabel, semanticsTooltip, autofocus, focusNode, onFocusChange,
    onHoverChange, onVariantChange, selected, shortcuts, actions, FButtonIconContentBuilder builder =
    defaultIconContentBuilder, Widget? child, key})` (`:230-254`). Default variant is **outline**, not primary. Not const.
  - `const FButton.raw({required VoidCallback? onPress, required Widget child, variant = .primary, size = .md, style, ...same
    callbacks/semantics/focus params..., key})` (`:257-279`). Only const constructor; no padding/constraints/icon theme added
    beyond the decoration (child receives `FButtonData` via `FButtonData.of(context)`, `:726`).
  - Typedefs: `FButtonContentBuilder = Widget Function(BuildContext, FButtonStyle, TextStyle, IconThemeData,
    FCircularProgressStyle, Widget? child)` (`button_content.dart:13`); `FButtonIconContentBuilder = Widget
    Function(BuildContext, FButtonStyle, IconThemeData, Widget? child)` (`:23`).
- Key optional parameters:
  - `variant`: `FButtonVariant` = `primary | secondary | destructive | outline | ghost` (`button.dart:12-18`).
  - `size`: `FButtonSizeVariant` = `xs | sm | md | lg` (`:19-24`). Min content size (dp): touch xs 32 / sm 40 / md 44 / lg 48;
    desktop xs 24 / sm 32 / md 36 / lg 40 (`:509-633`; set by the `touch` flag of `FThemeData`).
  - `selected`: sets `FTappableVariant.selected` (toggle look: hover colour is held) and the semantics `selected` flag (`:301`).
  - `prefix`/`suffix` (+ builders): placed in a `Row`; `mainAxisSize: .max` is the default so the button fills the width;
    pass `.min` to shrink (docs comment `:80`).
  - `onDisabledPress`: makes a disabled button still focusable/tappable for feedback (`tappable.dart:173-178, 738`).
  - `semanticsLabel`: replaces the child semantics (see Focus & semantics).
- State / control: stateless; no controller. Selected/pressed state is owned by the caller (`selected`).
- Interaction states / variants: `FTappableVariant` = `disabled | selected | primaryFocused | focused | hovered | pressed`
  (`foundation/tappable/tappable.dart:17-24`) plus platform variant; style lookup is
  `theme.buttonStyles.resolve({variant, platform}).resolve({size, platform})` (`button.dart:283-285`). Disabled = both `onPress`
  and every other primary/secondary gesture callback null (`tappable.dart:165-171` doc; `_disabled` getter).
- Focus & semantics:
  - Built on `FTappable` -> `AnimatedTappable` (`button.dart:287`, `tappable.dart:400`): `Focus` + `Shortcuts/Actions`
    (`ActivateIntent` -> onPress), `MouseRegion`, `Listener`+`GestureDetector`; focus ring via `FFocusedOutline` only when
    `FAccessibility.focusHighlight` (`tappable.dart:588`). `canRequestFocus` is false when disabled unless `onDisabledPress`
    is set (`:738`).
  - `Semantics(enabled: !disabled, label, tooltip, button: true (default), selected: selected, excludeSemantics:
    semanticsLabel != null)` (`tappable.dart:707-725`, `button.dart:304`).
  - PROBE (`sem_test.dart`): enabled -> `flags=hasSelectedState,isButton,hasEnabledState,isEnabled,isFocusable
    actions=tap,focus label="Save"`; disabled -> no `isEnabled`, no actions; disabled + `onDisabledPress` -> `isFocusable`
    + `tap,focus` but not `isEnabled`; `selected: true` adds `isSelected`.
  - PROBE: setting `semanticsLabel` drops `isFocusable` and the `focus` action from the node (only `tap` remains) because of
    `excludeSemantics: true` (`button.dart:304`). Setting only `semanticsLabel` is therefore not neutral for focus-driven AT.
  - PROBE: `FButton.icon` with an unlabelled icon child exposes a node with **no label** (`isButton` only); give
    `semanticsLabel` or label the icon.
  - PROBE: `semanticsTooltip: 'Add a card'` -> node `tooltip="Add a card"`.
  - Shortcuts: only Activate (Enter/Space via default `ActivateIntent`); override with `shortcuts`/`actions`.
- Motion: pressed bounce (scale 1 -> 0.97, clamped to 5px shrink), 100ms down/up, `easeOutQuart`/`easeOutCubic`
  (`tappable.dart:1067-1116`); pressed-state delay 100ms enter / 100ms exit (`:870-900`). Bounce is replaced by
  `FTappableMotion.none` **only** when `FAccessibility.motion == disabled` (`:1013`); `reduced` (iOS) keeps the bounce.
  Disable per button with `style: .delta(tappableStyle: .delta(motion: FTappableMotion.none))` (pattern used for the
  password toggle, `text_field_style.dart:236-238`).
- Styling: `FButtonStyle` (`button.dart:650`: `decoration` (variants over tappable states), `contentStyle`
  (`FButtonContentStyle`: textStyle, iconStyle, circularProgressStyle, constraints, padding, spacing; `button_content.dart:130`),
  `iconContentStyle`, `tappableStyle`, `focusedOutlineStyle`); delta `FButtonStyleDelta`; defaults from
  `FThemeData.buttonStyles` (`FButtonStyles.inherit`, `:343`). Text is `typography.body.sm`, weight 500, height 1 (`:688`).
- Limitations / caveats:
  - **No built-in loading/busy state or param.** The documented pattern is `prefix: const FCircularProgress()` and
    `onPress: null` (docs_snippets `examples/form/button.dart:157-164`; docs page `widgets/form/button`). PROBE: with a
    `FCircularProgress` prefix the label becomes `"Loading\nSaving"`; no busy flag, and the button stays enabled unless the
    caller passes `onPress: null` (and then the disabled colours apply).
  - `FButton.new`/`.icon` are not const; `FButton.raw` is.
  - Touch xs button is 32dp (below the 44/48dp target the other sizes give).
  - Tappables nested in an `OverlayPortal` need `FTappableGroup.isolate` (`foundation/doc_templates.dart:110-122`); FPortal-based
    widgets do it for you.
- Evidence: `widgets/button/button.dart`, `widgets/button/button_content.dart`, `foundation/tappable/tappable.dart`;
  docs https://forui.dev/docs/widgets/form/button ; PROBE `sem_test.dart`.

### `FBadge` — non-interactive pill for labels/counts
- Import: `package:forui/forui.dart` (via `lib/widgets/badge.dart`)
- Constructors (`widgets/badge.dart`): `FBadge({required Widget child, FBadgeVariant variant = .primary, FBadgeStyleDelta style =
  const .context(), Key? key})` (`:62-68`, not const); `const FBadge.raw({required Widget Function(BuildContext, FBadgeStyle)
  builder, variant = .primary, style, key})` (`:71`).
- Key optional parameters: `variant`: `primary | secondary | outline | destructive` (`:10-15`). `.raw` builder gets the
  resolved style and must apply padding/text style itself (`.new` applies `style.padding` + `labelTextStyle`, `:62-68`).
- State / control: stateless; none.
- Interaction states / variants: none (no tappable); style lookup `badgeStyles.resolve({variant, platform})` (`:75`).
- Focus & semantics: none added; the child `Text` is the node. PROBE: `FBadge(child: Text('New'))` -> node `label="New"`
  only (no flags, no actions).
- Motion: none.
- Styling: `FBadgeStyle {decoration, labelTextStyle, padding}` (`:162`); delta `FBadgeStyleDelta`; default
  `FThemeData.badgeStyles` (`FBadgeStyles.inherit`, `:97`); pill shape (`style.borderRadius.pill`), padding 12x6 touch / 10x6
  desktop (`:114-116`), text `body.xs` w500; `IntrinsicWidth`+`IntrinsicHeight` wrapper (`:76-80`).
- Limitations / caveats: no tap target, no icon slot (use `.raw` or a `Row` child); no semantics role.
- Evidence: `widgets/badge.dart`; docs https://forui.dev/docs/widgets/data/badge ; PROBE `sem_test.dart`.

### `FAvatar` — circular image with fallback
- Import: `package:forui/forui.dart` (via `lib/widgets/avatar.dart`)
- Constructors (`widgets/avatar/avatar.dart`): `FAvatar({required ImageProvider image, FAvatarStyleDelta style = const .context(),
  double size = 40.0, String? semanticsLabel, Widget? fallback, Key? key})` (`:49-56`); `FAvatar.raw({Widget? child, style, size =
  40.0, key})` (`:59`; null `child` -> placeholder icon). Neither is const.
- Key optional parameters: `fallback` (shown while loading and on error; wrapped in `FittedBox(scaleDown)`, `avatar_content.dart:17-20`;
  `null` -> `FAvatarStyle.fallbackIcon`, default `FIcons.userRound`); `semanticsLabel`.
- State / control: stateless; image state is Flutter's `Image` (frameBuilder/loadingBuilder/errorBuilder, `avatar_content.dart:30-40`).
- Interaction states / variants: none.
- Focus & semantics: `.new` wraps the image in `Semantics(label: semanticsLabel, image: true, excludeSemantics: true)`
  (`avatar_content.dart:26-29`); `.raw` adds nothing (its child provides semantics). PROBE: `.new` -> `flags=isImage
  label="Alice"`; `.raw(child: Text('AB'))` -> `label="AB"`.
- Motion: cross-fade `AnimatedSwitcher` from fallback to image, `FAvatarStyle.fadeInDuration` = 500ms; `Duration.zero` when
  `FAccessibility.motion == disabled` (`avatar_content.dart:22-24, 35-37`; `avatar.dart:100`). No fade when the image is available
  synchronously (`wasSynchronouslyLoaded`).
- Styling: `FAvatarStyle {backgroundColor, foregroundColor, textStyle, fallbackIcon, fadeInDuration}` (`avatar.dart:87`),
  default `FThemeData.avatarStyle` (`.inherit` uses `colors.muted`, `typography.display.sm`, `:107-113`); fixed `size` square clipped to a circle
  (`:65-72`).
- Limitations / caveats: not tappable (wrap in `FButton.raw`/`FTappable`); `size` is one number (no size variants).
- Evidence: `widgets/avatar/avatar.dart`, `avatar_content.dart`; docs https://forui.dev/docs/widgets/data/avatar ; PROBE `sem_test.dart`.

### `FTooltip` — hover / keyboard-focus / long-press tip around a child
- Import: `package:forui/forui.dart` (via `lib/widgets/tooltip.dart`, also exports `FTooltipController`, `FTooltipControl`, `FTooltipGroup`)
- Constructors (`widgets/tooltip/tooltip.dart:139-156`): `const FTooltip({required Widget Function(BuildContext,
  FTooltipController) tipBuilder, FTooltipControl control = const .managed(), FTooltipStyleDelta style = const .context(),
  AlignmentGeometry tipAnchor = .bottomCenter, AlignmentGeometry childAnchor = .topCenter, FPortalSpacing spacing = const
  .spacing(7), FPortalOverflow overflow = .flip, FPortalArrowAlignment? arrow = .childCenter, bool? hover, bool? longPress,
  bool useViewPadding = true, bool useViewInsets = true, OverlayChildLocation overlayLocation = .nearestOverlay,
  ValueWidgetBuilder<FTooltipController> builder = defaultBuilder, Widget? child, Key? key})`. Assert: `builder` or `child`
  required. `arrow: null` removes the arrow.
- Key optional parameters: `hover` / `longPress` (null -> enclosing `FTooltipGroup` value -> true; `:231-232`);
  `control` (`FTooltipControl.managed({FTooltipController? controller, bool? initial, ValueChanged<bool>? onChange})` /
  `.lifted({required bool shown, required ValueChanged<bool> onChange})`, `tooltip_controller.dart:178-185`).
- State / control: `FTooltipController` (`FChangeNotifier`; `show({animated})`, `hide`, `toggle`, `status`; needs a `TickerProvider`,
  `tooltip_controller.dart:28-94`). `managed(initial:)` XOR `controller:` (assert `:219`).
- Interaction states / variants: none from `FTappableVariant`; triggers: mouse enter (after `hoverEnterDuration` 500ms),
  mouse exit (after `hoverExitDuration` 100ms), keyboard focus on a descendant (`_toggle`, `:362-380`), long press
  (immediate show + haptic; hide `longPressExitDuration` 1500ms after release, `:269-285, 440-449`), any pointer-down hides
  (`:263`). Esc hides (`:238-242`). Pointer over the tip keeps it open (`:350-353`).
- Focus & semantics:
  - Child gets a non-focusable `Focus(canRequestFocus:false)` that listens to descendant focus (`:183, 236-254`).
  - The long-press region is `GestureDetector(onLongPressStart/End)` around the **whole child** (`:267-286`). Per the class doc
    (`:22-24`) and PROBE (`tip_test.dart`): tip shows on long press of `FButton(onPress: ...)` and of a **disabled** `FButton`;
    it does **not** show if the child has its own long-press (`FButton(onLongPress: ...)` -> tip hidden, button's `onLongPress`
    fires).
  - PROBE: the wrapper adds an extra node with only `actions=longPress` (no label) around the child; when shown the tip is a
    separate sibling node `label="<tip text>"` (`Semantics(container: true)`, `:333`). The tip is NOT merged into the child's node.
  - Doc template (`foundation/doc_templates.dart:101-104`): "Set [semanticsTooltip] when wrapping this widget in an FTooltip, as a
    tooltip cannot annotate its child's semantics node." `FButton(semanticsTooltip: ...)` -> node `tooltip="..."` (PROBE).
- Motion: scale 0.93 -> 1 and fade 0 -> 1, 100ms in/out, `easeOutCubic` scale, linear fade (`tooltip.dart:485-509`); `reduced` ->
  fade only; `disabled` -> none (`:321-331`). Configure via `FTooltipStyle.motion`.
- Styling: `FTooltipStyle {decoration, textStyle, hapticFeedback, backgroundFilter, padding (12x6), constraints, arrowStyle,
  motion, hoverEnterDuration 500ms, hoverExitDuration 100ms, longPressExitDuration 1500ms}` (`:409-450`); default
  `FThemeData.tooltipStyle` (inverted: `colors.foreground` bg, `colors.background` text, `body.xs`, `:465-477`). A surrounding
  `FTooltipGroup` can override the style (`:209`).
- Limitations / caveats:
  - Touch discoverability: tip appears only on long press, hover (mouse) or keyboard focus; there is no tap trigger.
  - `FTooltipGroup` doc says "[FTheme] contains a tooltip group by default" (`tooltip_group.dart` doc) but no `FTooltipGroup(` is
    built anywhere in the package (rg over `lib/`); without a group, `hover`/`longPress` default to true (`:231-232`) and
    "instant subsequent tooltips" do not apply.
  - Needs an `Overlay` ancestor; `FTooltip` is `const`-constructible but `tipBuilder` is a closure.
- Evidence: `widgets/tooltip/tooltip.dart`, `tooltip_controller.dart`, `tooltip_group.dart`; docs
  https://forui.dev/docs/widgets/overlay/tooltip ; PROBE `tip_test.dart`.

---------------------------------------------------------------------------------------------------------------------------
## 2. Form inputs and validation
---------------------------------------------------------------------------------------------------------------------------

Shared form-field facts (apply to every `FFormFieldProperties` widget; `foundation/form_field_properties.dart`):
- Properties: `label`, `description`, `errorBuilder` (default `FFormFieldProperties.defaultErrorBuilder`: `Row[ExcludeSemantics(error
  icon), Flexible(Text(error))]`, `:11-28`), `enabled`, `onSaved`, `onReset`, `validator`, `autovalidateMode`, `forceErrorText`.
- `forceErrorText` overrides the validator; the validator is not called unless it is null (`:83-92`).
- Default `autovalidateMode`: `AutovalidateMode.disabled` for FTextFormField/FOtpField/FSlider/FSelectGroup/FSelectTileGroup;
  `AutovalidateMode.onUnfocus` for FSelect/FMultiSelect/FDateField/FTimeField (`select/single/select.dart:270`,
  `date_field.dart:166`, `time_field.dart` ctor). FAutocomplete: `.disabled` (`autocomplete.dart:139`).
- Controls (`concepts/controls`): `*Control.managed(controller|initial, onChange)` = widget-owned state (an external controller is
  never disposed by the widget); `*Control.lifted(value, onChange)` = caller-owned state via a proxy controller
  (https://forui.dev/docs/concepts/controls).

### `FLabel` — label + description + error wrapper (the form role)
- Import: `package:forui/forui.dart` (via `lib/widgets/label.dart`; `Label`/`LabelState` hidden)
- Constructors (`widgets/label/label.dart:112-122`): `const FLabel({required FLabelLayout layout, required Widget child,
  FLabelStyleDelta style = const .context(), Widget? label, Widget? description, Widget? error, bool expands = false,
  Set<FFormFieldVariant> variants = const {}, Key? key})`. Assert: `expands` only with `.vertical`.
- Key optional parameters: `layout`: `FLabelLayout` = `horizontalLeading | horizontalTrailing | vertical` (`:16-52`; checkbox/radio/switch use
  `horizontalTrailing`, text-likes use `vertical`). `variants` (`FFormFieldVariant` = disabled/error/focused...) drive text colours.
- State / control: stateful internal (error expand/fade controllers); error is kept for the collapse animation (`:194-240`).
- Focus & semantics:
  - `LabelSemantics` render proxy merges label + child into one node, **rewrites description/error into the node's `hint`**
    and error's `validationResult = invalid`; error with a live region is duplicated as a sibling so it is announced
    (`label/semantics.dart:21-42`; use at `vertical_label.dart:36`, `horizontal_label.dart:26, 103`). The error is
    `Semantics(validationResult: .invalid, liveRegion: !MediaQuery.supportsAnnounceOf(context))` (`label.dart:306-311`).
  - PROBE (`text_test.dart`): `FTextField(label:'Deck name', description:'Shown in lists', error:'Required')` -> ONE node
    `label="Deck name" hint="Shown in lists\nRequired" validation=invalid`.
  - The label is **not tappable** (no gesture/focus forwarding in `vertical_label.dart`); tapping the label text does nothing
    (PROBE: tapping the `FMultiSelect` label text did not open it). For horizontal layouts the tappable is the whole
    `FTappable` that wraps the `FLabel` (checkbox/radio).
- Motion: error expand/collapse 100ms `easeOut` + fade 0.4 -> 1 100ms; disabled unless `FAccessibility.motion == all`
  (`label.dart:266, 318`; `FLabelMotion` `:418-471`).
- Styling: `FLabelStyles` (`horizontalLeadingStyle`, `horizontalTrailingStyle`, `verticalStyle`; `FThemeData.labelStyles`) with
  `FLabelStyle` (label/description/error text styles over form-field variants, paddings, `labelMotion`) (`:327-412`).
- Limitations / caveats: "Error transitions require either a label or description"; for error-only fields pass an empty
  `SizedBox.shrink()` label (doc `:52-58`; `label.dart:131` short-circuits to a bare padded child when all three are null).
- Evidence: `widgets/label/*.dart`; docs https://forui.dev/docs/widgets/form/label ; PROBE `text_test.dart`, `form_test.dart`.

### `FTextField` — single/multi-line text input (Material `TextField` underneath)
- Import: `package:forui/forui.dart` (via `lib/widgets/text_field.dart`; also exports `FTextFieldControl`, `FObscureTextControl`,
  `FTextFieldStyle`, `FTextFormField`, `FPasswordFieldIconBuilder`)
- Constructors (`widgets/text_field/text_field.dart`; all `const` except `password`):
  - `const FTextField({FTextFieldControl control = const .managed(), FTextFieldSizeVariant size = .md, FTextFieldStyleDelta style =
    const .context(), FFieldBuilder<FTextFieldStyle> builder = defaultBuilder, Widget? label, String? hint, Widget?
    description, Widget? error, TextMagnifierConfiguration? magnifierConfiguration, Object groupId = EditableText, FocusNode?
    focusNode, TextInputType? keyboardType, TextInputAction? textInputAction, TextCapitalization textCapitalization = .none,
    TextAlign textAlign = .start, TextAlignVertical? textAlignVertical, TextDirection? textDirection, bool autofocus = false,
    WidgetStatesController? statesController, String obscuringCharacter = '•', bool obscureText = false, bool autocorrect = true,
    SmartDashesType? smartDashesType, SmartQuotesType? smartQuotesType, bool enableSuggestions = true, int? minLines, int?
    maxLines = 1, bool expands = false, bool readOnly = false, bool? showCursor, int? maxLength, MaxLengthEnforcement?
    maxLengthEnforcement, GestureTapCallback? onTap, TapRegionCallback? onTapOutside, bool onTapAlwaysCalled = false,
    VoidCallback? onEditingComplete, ValueChanged<String>? onSubmit, AppPrivateCommandCallback? onAppPrivateCommand,
    List<TextInputFormatter>? inputFormatters, bool enabled = true, bool? ignorePointers, bool enableInteractiveSelection =
    true, bool? selectAllOnFocus, TextSelectionControls? selectionControls, DragStartBehavior dragStartBehavior = .start,
    MouseCursor? mouseCursor, FTextFieldCounterBuilder? counterBuilder, ScrollPhysics? scrollPhysics, ScrollController?
    scrollController, Iterable<String>? autofillHints, String? restorationId, bool stylusHandwritingEnabled = true, bool
    enableIMEPersonalizedLearning = true, ContentInsertionConfiguration? contentInsertionConfiguration,
    EditableTextContextMenuBuilder? contextMenuBuilder = defaultContextMenuBuilder, bool canRequestFocus = true,
    UndoHistoryController? undoController, SpellCheckConfiguration? spellCheckConfiguration, FFieldIconBuilder<FTextFieldStyle>?
    prefixBuilder, FFieldIconBuilder<FTextFieldStyle>? suffixBuilder, bool Function(TextEditingValue) clearable =
    defaultClearable, FFieldClearIconBuilder<FTextFieldStyle> clearIconBuilder = defaultClearIconBuilder, Key? key})` (`:904-969`)
  - `const FTextField.email(...)` same params; differences: `label = const LocalizedText.email()`, `keyboardType = .emailAddress`,
    `textInputAction = .next`, `autocorrect = false`, `autofillHints = const [AutofillHints.email]` (`:971-1040`).
  - `const FTextField.multiline(...)` same params; differences: `textCapitalization = .sentences`, `minLines = 4`, `maxLines =
    null` (`:1042-1107`).
  - `static Widget FTextField.password({...})` — a **static method returning a Widget, not a constructor** (`:133-265`). Extra
    param `FObscureTextControl obscureTextControl = const .managed()` (`.managed({ValueNotifier<bool>? controller, bool?
    initial (default true), onChange})` / `.lifted({required bool value, required ValueChanged<bool> onChange})`,
    `obscure_text_control.dart:38-42`); `label = const LocalizedText.password()`, `textInputAction = .next`,
    `autocorrect = false`, `enableSuggestions = false`, `autofillHints = [AutofillHints.password]`, `suffixBuilder =
    defaultObscureIconBuilder` (an eye toggle `FButton.icon`), `prefixBuilder`/`suffixBuilder` are `FPasswordFieldIconBuilder<S> =
    Widget Function(BuildContext, S style, ValueNotifier<bool> obscure, Set<FTextFieldVariant> variants)`
    (`password_field.dart:18-23`). No `obscureText` param.
  - Typedefs: `FTextFieldCounterBuilder = Widget? Function(BuildContext, int currentLength, int? maxLength, bool focused)`
    (`:21`); `FFieldBuilder<T> = Widget Function(BuildContext, T style, Set<FTextFieldVariant>, Widget field)` (`:32`);
    `FFieldIconBuilder<T> = Widget Function(BuildContext, T style, Set<FTextFieldVariant>)` (`:45`);
    `FFieldClearIconBuilder<S> = Widget Function(BuildContext, S style, VoidCallback clear)` (`:53`).
  - Static helpers: `FTextField.prefixIconBuilder(context, style, variants, icon)` (`:115`), `defaultClearIconBuilder` (`:102`),
    `defaultClearable` (always false, `:99`).
- Key optional parameters:
  - `hint` (String), `label`/`description`/`error` (Widgets), `maxLength`, `clearable` (predicate on the current
    `TextEditingValue`, e.g. `(v) => v.text.isNotEmpty`; the clear button is hidden when `enabled` is false, `input.dart:381-389`),
    `prefixBuilder`/`suffixBuilder`, `counterBuilder`, `keyboardType`, `inputFormatters`, `selectAllOnFocus`, `onSubmit(String)`.
  - `error` non-null puts the field in the `error` variant; it should be passed as a stable non-null widget when toggling to avoid
    tree changes (`input.dart:164-170`).
  - `onChange` does not exist as a parameter: use `control`.
- State / control: `FTextFieldControl` (`text_field_control.dart:89-105`): `.managed({TextEditingController? controller,
  TextEditingValue? initial, ValueChanged<TextEditingValue>? onChange})` (controller XOR initial; an external controller is
  not disposed) and `.lifted({required TextEditingValue value, required ValueChanged<TextEditingValue> onChange})` (proxy
  controller whose setter calls `onChange` instead of applying, `:60-83`). `onChange` is attached as a plain controller listener
  (`:35, 50-54`), so it fires on **any** controller notification (text, selection or composing change), not only text edits.
- Interaction states / variants: `FTextFieldVariant` = `disabled | error | focused | hovered | pressed` (+ platform) and
  `FTextFieldSizeVariant` = `sm | md | lg` (`text_field_style.dart:13-24`); heights touch 40/44/48, desktop 32/36/40 (`:65-113`).
  Variants come from Material's `WidgetStatesController` (`input.dart:236-240`).
- Focus & semantics (how label/description/hint/error reach AT):
  - `FLabel(layout: vertical)` wraps a Material `TextField` configured with an `InputDecoration` whose `hintText` is `hint`
    and whose `error` is an empty `SizedBox` when `error != null` (only to trigger the error state) (`input.dart:322-331, 377-415`).
  - The visible `label`, `description`, `error` are rendered by FLabel, **not** by `InputDecoration.labelText/helperText/errorText`.
    The hint reaches semantics through Material's decorator (hint `Text` merged up; `material_ui: input_decorator.dart:2664-2676`
    comment) — it is the node's label while the field is empty.
  - PROBE (`text_test.dart`, touch theme): hint only -> `label="Type here"`; label+description+hint ->
    `label="Deck name\ne.g. Spanish" hint="Shown in lists"`; + error -> `hint="Shown in lists\nRequired" validation=invalid`; once text
    is typed the hint leaves the label (`label="Deck name" value="Latin"`).
  - PROBE flags/actions: enabled `isTextField,hasEnabledState,isEnabled,isFocusable` + `tap,focus`; `enabled:false` ->
    `isReadOnly` and no `isEnabled`/actions; `readOnly:true` -> `isReadOnly,isEnabled` + `focus` only (no `tap`; Material omits the
    semantic tap when read-only, `material_ui: text_field.dart:1825`); `.multiline` adds `isMultiline`; `.password` adds
    `isObscured` and a separate button node `label="Show password"` (`actions=tap,focus`).
  - `maxLength`: Material exposes `maxValueLength`/`currentValueLength` (PROBE `maxLen=20 cur=0`).
  - Material `TextField` is wrapped in `Material(color: transparent)` + `Theme` + `CupertinoTheme` (selection colours) and, if no
    `MaterialLocalizations`, an injected `Localizations` (`input.dart:333-361`).
- Motion: error expand/fade (FLabel); no focus animation owned by forui; caret blink per `FTextFieldStyle.cursorOpacityAnimates`
  (null -> true on iOS/macOS only, `input.dart:262-263`). Text fields do not read `FAccessibility` (rg: no `accessibility` use in
  `widgets/text_field/`).
- Styling: `FTextFieldStyle` (`text_field_style.dart:127`: keyboardAppearance, `color`, `iconStyle`, `clearButtonStyle`,
  `obscureButtonStyle`, `contentTextStyle`, `hintTextStyle`, `counterTextStyle`, `border` (variants -> `InputBorder`), label/description/
  error text styles, cursor, constraints, contentPadding, paddings, `scrollPadding`); sizes via `FTextFieldSizeStyles`; default
  `FThemeData.textFieldStyles` (`FTextFieldSizeStyles.inherit`, `:28-113`). Delta `FTextFieldStyleDelta`.
- Limitations / caveats:
  - **`maxLength` shows no counter by default**: `buildCounter` is always supplied and returns null without `counterBuilder`
    (`input.dart:300-305`); PROBE: no counter node unless `counterBuilder` given, and then `Semantics(container, liveRegion: isFocused)`.
  - Doc comment of `label` says "A builder that creates a widget to display validation errors" (`text_field.dart:305`) — the
    parameter is the label widget.
  - Obscured text disables the `calt` font feature to stop `•` jumping (`input.dart:242-251`).
  - No `onChange`; no built-in `error` text from `validator` here (use `FTextFormField`).
- Evidence: `widgets/text_field/text_field.dart`, `input/input.dart`, `text_field_control.dart`, `text_field_style.dart`; docs
  https://forui.dev/docs/widgets/form/text-field ; PROBE `text_test.dart`.

### `FTextFormField` — `FTextField` as a `FormField<String>`
- Import: `package:forui/forui.dart` (via `lib/widgets/text_field.dart`)
- Constructors (`widgets/text_field/text_form_field.dart`): `const FTextFormField({...every FTextField param except `error`...,
  FormFieldSetter<String>? onSaved, VoidCallback? onReset, FormFieldValidator<String>? validator, AutovalidateMode autovalidateMode =
  .disabled, String? forceErrorText, Widget Function(BuildContext, String message) errorBuilder =
  FFormFieldProperties.defaultErrorBuilder, Key? formFieldKey, Key? key})` (`:387-457`); `.email` (`:460`, same deltas as
  FTextField.email); `.multiline` (`:537`); `static Widget password({...})` (`:33`, + `obscureTextControl`, defaults as
  `FTextField.password`).
- Key optional parameters: `validator`, `autovalidateMode`, `forceErrorText`, `errorBuilder`, `onSaved`, `onReset`, `formFieldKey`.
- State / control: same `FTextFieldControl`; the `FormField` value mirrors the controller text (`input/form_input.dart:39-89`);
  `reset()` sets the controller to the field's `initialValue`, which is re-read as `controller.text` **on every build of the field** (`text_form_field.dart:618`). PROBE (`reset2_test.dart`): `managed(initial: 'a')`, type `abc`, `FormState.reset()` -> `"a"`; but if the parent rebuilds the `FTextFormField` (new widget instance) after typing, `reset()` -> `"abc"` (it resets to the text at the last rebuild, not to the original initial value).
- Interaction states / variants: as FTextField; the error text comes from `state.errorText`, passed through `errorBuilder`
  (`:630-634`).
- Focus & semantics: as FTextField, plus `FormField` wrapper. PROBE (`form_test.dart`): in a `Form`, after `validate()`:
  `role=form` ancestor node and field node `label="Deck name" hint="desc\nRequired" validation=invalid`.
- Motion / styling: as FTextField.
- Limitations / caveats: no `error` parameter (error is derived); `onReset` fires (PROBE `reset_test.dart`: `textFormField` in the
  fired list).
- Evidence: `widgets/text_field/text_form_field.dart`, `form_input.dart`; docs https://forui.dev/docs/widgets/form/text-form-field ;
  PROBE `form_test.dart`, `reset_test.dart`.

### `FOtpField` — one-time-code input (a single hidden text field rendered as boxes)
- Import: `package:forui/forui.dart` (via `lib/widgets/otp_field.dart`; exports `FOtpFieldControl`, `FOtpController`, `FOtpItem`,
  `FOtpDivider`, `FOtpItemMixin`, `FOtpItemScope`, `FOtpFieldStyle`)
- Constructors (`widgets/otp_field/otp_field.dart:205-250`): `FOtpField({FOtpFieldControl control = const .managed(),
  FOtpFieldStyleDelta style = const .context(), FFieldBuilder<FOtpFieldStyle> builder = defaultBuilder, Widget? label, Widget?
  description, TextMagnifierConfiguration? magnifierConfiguration, Object groupId = EditableText, FocusNode? focusNode,
  TextInputType? keyboardType = .text, TextInputAction? textInputAction = .done, TextCapitalization textCapitalization = .none,
  TextDirection? textDirection, bool autofocus = false, WidgetStatesController? statesController, bool readOnly = false,
  GestureTapCallback? onTap, TapRegionCallback? onTapOutside, bool onTapAlwaysCalled = false, VoidCallback? onEditingComplete,
  ValueChanged<String>? onSubmit, AppPrivateCommandCallback? onAppPrivateCommand, List<TextInputFormatter>? inputFormatters
  (null -> `[FilteringTextInputFormatter.digitsOnly]`, `:63, 250`), bool enabled = true, bool? ignorePointers, bool
  enableInteractiveSelection = true, TextSelectionControls? selectionControls, DragStartBehavior dragStartBehavior = .start,
  MouseCursor? mouseCursor, Iterable<String>? autofillHints = const [AutofillHints.oneTimeCode], String? restorationId, bool
  stylusHandwritingEnabled = true, bool enableIMEPersonalizedLearning = true, ContentInsertionConfiguration?
  contentInsertionConfiguration, EditableTextContextMenuBuilder? contextMenuBuilder = FTextField.defaultContextMenuBuilder, bool
  canRequestFocus = true, UndoHistoryController? undoController, FormFieldSetter<String>? onSaved, VoidCallback? onReset,
  FormFieldValidator<String>? validator, AutovalidateMode autovalidateMode = .disabled, String? forceErrorText, Widget
  Function(BuildContext, String) errorBuilder = FFormFieldProperties.defaultErrorBuilder, Key? formFieldKey, Key? key})`.
  Not const. There is **no `length`/`error` parameter**.
- Key optional parameters: `control` (below), `keyboardType` (default is `.text`, so the soft keyboard is alphanumeric unless you
  pass `.number`), `inputFormatters`, `onSubmit`, `validator`/`forceErrorText`.
- State / control: `FOtpFieldControl.managed({FOtpController? controller, List<Widget> children = [6 x FOtpItem()],
  TextEditingValue? initial, ValueChanged<TextEditingValue>? onChange})` — **managed only, no lifted variant**
  (`otp_field_control.dart:16-72`). The number of slots = count of `FOtpItemMixin` widgets in `children`
  (`FOtpController._length`, `:95-102`); `FOtpDivider` is a visual separator and not a slot. `FOtpController extends
  TextEditingController`; read the code with `controller.text`, or `onChange(TextEditingValue)`, `onSubmit(String)`, `onSaved`,
  `validator`. Text longer than the slot count is truncated (`:162-170`); no "complete" callback exists.
- Interaction states / variants: `FTextFieldVariant` for the field, `FOtpFieldItemVariant` (`start | end | focused`) per item
  (`otp_item.dart:84-91`); item size 44x44 touch / 36x36 desktop (`otp_field_style.dart:75`).
- Focus & semantics: one Material `TextField` whose `TextSpan` is built from `WidgetSpan`s (`otp_field_control.dart:106-141`);
  left/right arrow keys traverse items (`otp_field.dart:399-403`); caret hidden (`showCursor:false`), `autocorrect:false`,
  `enableSuggestions:false`, `scrollPhysics: NeverScrollable` (`:430-451`).
  - **PROBE (`text_test.dart`)**: semantics value is the object-replacement character repeated per slot, not the digits:
    `FOtpField(initial '123')` -> `label="Code\n1\n2\n3" value="￼￼￼￼￼￼" hint="6 digits"`. The typed digits appear only as
    merged child text in the *label*; the node *value* is `U+FFFC` x slot-count. No per-slot semantics. UNVERIFIED how
    TalkBack/VoiceOver read this (needs a device).
  - Label/description/error go through `FLabel` exactly as FTextField (PROBE `hint="Wrong code" validation=invalid`).
- Motion: error transition (FLabel); caret blink in `Caret` (`caret.dart`, uses `cursorOpacityAnimates`); no `FAccessibility` reads.
- Styling: `FOtpFieldStyle` (`otp_field_style.dart:24`: keyboardAppearance, `itemSize`, `itemStyles` (per item variants:
  decoration, contentTextStyle), `dividerColor`, `dividerSize` 12x1, ...); default `FThemeData.otpFieldStyle`.
- Limitations / caveats: managed only; digit-only by default via formatter (not via keyboard type); `FOtpField` is not const.
- Evidence: `widgets/otp_field/*.dart`; docs https://forui.dev/docs/widgets/form/otp-field ; PROBE `text_test.dart`.

### `FAutocomplete<T>` — text field with a suggestion popover and inline typeahead
- Import: `package:forui/forui.dart` (via `lib/widgets/autocomplete.dart`; exports `FAutocompleteController`,
  `FAutocompleteControl`, `FAutocompleteItemMixin` (`.item`, `.rawItem`, `.section`, `.richSection`), `FAutocompleteStyle`, content types)
- Constructors (`widgets/autocomplete/autocomplete.dart`):
  - `FAutocomplete<T>({required Map<String, T> items, String Function(T)? format, T? Function(String?)? parse, FutureOr<
    Iterable<T>> Function(String query)? filter (default: prefix match, case-insensitive), FAutocompleteContentBuilder<T>?
    contentBuilder, ...shared params..., Key? key})` (`:809`).
  - `static FAutocomplete<String> FAutocomplete.text({required List<String> items, ...shared..., FutureOr<Iterable<String>>
    Function(String)? filter, FAutocompleteContentBuilder<String>? contentBuilder})` (`:74`) — static method (not a constructor).
  - `static FAutocomplete<String> FAutocomplete.textBuilder({required filter, required contentBuilder, ...})` (`:273`).
  - `const FAutocomplete<T>.builder({required FutureOr<Iterable<T>> Function(String) filter, required String Function(T)
    format, required T? Function(String?) parse, required FAutocompleteContentBuilder<T> contentBuilder, ...})` (`:1018`).
  - Shared params (all ctors): `control = const .managed()` (`FAutocompleteControl`, `.managed({FAutocompleteController?
    controller, TextEditingValue? initial, onChange})` / `.lifted({required TextEditingValue value, required onChange})`),
    `popoverControl`, `size`, `style`, `label`, `hint`, `description`, all text-field params (`keyboardType`, `maxLength`,
    `clearable`, `prefixBuilder`, `suffixBuilder`, ...), `bool enableAutocompletion = true`, `bool autoHide = true`, `bool?
    retainFocus` (null -> true on desktop only), `bool rightArrowToComplete = false`, `contentAnchor = .topStart`,
    `fieldAnchor = .bottomStart`, `contentConstraints = FAutoWidthPortalConstraints(maxHeight: 300)`, `contentEmptyBuilder`
    (null hides popover when no results), `contentLoadingBuilder`, `contentErrorBuilder`, `contentDivider`, `onItemPress(T)`,
    `onSaved/onReset/validator/autovalidateMode/forceErrorText/errorBuilder`.
  - `FAutocompleteContentBuilder<T> = List<FAutocompleteItemMixin<T>> Function(BuildContext, String query, Iterable<T> values)`.
- Key optional parameters / value model: **free text** (not limited to suggestions); `FormField` value is `parse(text)`
  (`onSaved`/`validator` receive `widget.parse(text)`, `autocomplete.dart:1526`). Selecting an item writes `format(value)` to the
  text field then `onItemPress(value)` (`:1604-1607`). Doc: "An autocomplete is not a searchable select ... use FSelect.search"
  (`:33-36`).
- State / control: `FAutocompleteController` (a `FTypeaheadController`: text + suggestions + inline completion, styled via
  `AutocompleteFieldScope`).
- Interaction states / variants: `FTextFieldVariant`; item states per `FItem`.
- Focus & semantics: keys — Esc hides, ArrowDown moves into the list, Tab completes the inline suggestion when present, ArrowRight
  completes only if `rightArrowToComplete` (`:1641-1647`); inside the list ArrowUp/Down navigate (`:1567-1583`).
  `Semantics(expanded: popover open, hint: "Suggestion: <completion>")` around the field (`:1653-1658`);
  `SemanticsService.sendAnnouncement` announces result count (and "no results") when results change (`:1410-1431`).
  PROBE (`pick_test.dart`, typing `Ap`): field node `flags=isTextField,isFocused,hasExpandedState,isExpanded
  actions=tap,...,setText value="Apple" hint="Suggestion: Apple"`; items `isButton ... label="Apple"/"Apricot" actions=tap,focus`.
- Motion: popover motion (FPopover; not catalogued here).
- Styling: `FAutocompleteStyle` (`autocomplete_style.dart`) = field style + content style; `FThemeData.autocompleteStyle`.
- Limitations / caveats: doc comment for `autoHide` says "Defaults to false" (`:744`) but every constructor defaults it to `true`
  (`:155, 355, 892, 1102`) — code wins; `new` takes `Map<String,T>` while `.text` takes `List<String>`; needs `Overlay`.
- Evidence: `widgets/autocomplete/*.dart`; docs https://forui.dev/docs/widgets/form/autocomplete ; PROBE `pick_test.dart`.

### `FDateField` — date picker field (typed input, calendar popover, or both)
- Import: `package:forui/forui.dart` (via `lib/widgets/date_field.dart`; exports `FDateFieldStyle`, `FDateFieldCalendarProperties` and its
  `FDateFieldGridCalendarProperties` / `FDateFieldGridSplitCalendarProperties` / `FDateFieldWheelCalendarProperties`)
- Constructors (`widgets/date_field/date_field.dart`, abstract class with redirecting factories):
  - `FDateField({FDateSelectionControl<DateTime?>? selectionControl, FPopoverControl popoverControl, FTextFieldSizeVariant size
    = .md, FDateFieldStyleDelta style, FocusNode? focusNode, TextInputAction? textInputAction, TextAlign textAlign = .start,
    TextAlignVertical? textAlignVertical, TextDirection? textDirection, bool autofocus = false, bool expands = false, VoidCallback?
    onEditingComplete, ValueChanged<DateTime>? onSubmit, MouseCursor? mouseCursor, bool canRequestFocus = true, bool clearable =
    false, FFieldClearIconBuilder<FTextFieldStyle> clearIconBuilder, int baselineInputYear = 2000, FDateFieldCalendarProperties
    calendar = const FDateFieldGridCalendarProperties(), FFieldBuilder<FDateFieldStyle> builder, prefixBuilder =
    defaultIconBuilder (calendar icon), suffixBuilder, Widget? label, Widget? description, bool enabled = true,
    FormFieldSetter<DateTime>? onSaved, VoidCallback? onReset, AutovalidateMode autovalidateMode = .onUnfocus, String?
    forceErrorText, FormFieldValidator<DateTime> validator = defaultValidator, errorBuilder, Key? formFieldKey, Key? key})`
    = `_InputDateField` (`:212-246`; defaults `input/input_date_field.dart:18-52`): typed input + calendar popover.
  - `FDateField.calendar({selectionControl, popoverControl, size, style, String Function(BuildContext, DateTime, DateFormat) format
    = defaultFormat, textAlign, textAlignVertical, textDirection, expands, MouseCursor mouseCursor = .defer, canRequestFocus,
    clearable, clearIconBuilder, String? hint, autofocus, focusNode, calendar, builder, prefixBuilder, suffixBuilder, label,
    description, enabled, onSaved, onReset, autovalidateMode, forceErrorText, validator, errorBuilder, formFieldKey, key})` =
    `_CalendarDateField` (`:277-308`): read-only text field that opens the calendar; shows `DateFormat.yMMMd(locale)` (`calendar_date_field.dart:89`).
  - `FDateField.input({...same as new minus popoverControl/calendar})` = `_InputOnlyDateField` (`:342`, `input/input_date_field.dart:194-226`): typed input only.
  - Docs recommend `.calendar` on touch, `new`/`.input` on desktop (`date_field.dart:28-35`).
- Key optional parameters: `selectionControl` (`FDateSelectionControl.managedSingle({controller, initial, toggleable = true,
  onChange})` / `.liftedSingle({required value, required onChange, toggleable = true})`, `calendar/date_selection_control.dart:13-67`);
  `calendar:` properties carry the calendar knobs (`autoHide = true`, `fixedWeeks`, `anchor`, `cutout`, `popoverBuilder`,
  `control: FGridCalendarControl({controller, selectable, start, today, initial, end})` for date bounds, `properties.dart`,
  `calendar_control.dart:68-77`).
- State / control: value type `DateTime?`. **All DateTimes are UTC midnight** ("All returned DateTimes are in UTC timezone with no time
  component", `calendar/date_selection_controller.dart:40-41`, `_truncate` `:336`). Single selection is `toggleable` by default: tapping
  the selected day clears it (`date_selection_control.dart:62`).
- Interaction states / variants: `FTextFieldVariant` / `FTextFieldSizeVariant`.
- Focus & semantics:
  - Input mode: a segmented `FTextField` (`foundation/input/input.dart:137-166`, `keyboardType: numberWithOptions(signed: true)`); Up/Down
    adjust the focused segment, Left/Right move (`:115-123`).
  - PROBE (`date_test.dart`): `.calendar` empty -> `flags=isTextField,isReadOnly,isFocusable,hasExpandedState actions=focus label="Due\nPick a
    date"`; with value -> `value="Oct 17, 2026"`; **no `tap` action** (see caveat). `.input` value -> `value="10/17/2026" actions=tap,focus`;
    the new `FDateField` (input+calendar) has `hasExpandedState`.
  - `Semantics(expanded: popover open)` around `.calendar` field (`calendar_date_field.dart:302`).
- Motion: popover/calendar motion owned by FPopover/FCalendar (other catalog).
- Styling: `FDateFieldStyle` (`date_field_style.dart`; field styles per size, `popoverStyle`, `calendarStyle`), `FThemeData.dateFieldStyle`.
- Limitations / caveats:
  - **`onSubmit` is declared and documented ("called when the user submits a valid date value", `date_field.dart:194, 326`) on `new` and
    `.input` but is never used**: `_InputDateField`/`_InputOnlyDateField` never pass it on (`input/input_date_field.dart:11, 26, 68, 187, 201, 241` are
    the only mentions; `DateInput` has no such field). Use `onSaved`/selection `onChange` instead.
  - Input mode with non-western-numeral locales falls back to English (`date_field.dart:36-37`, `input/date_input.dart:72`).
  - `.calendar` mode: `readOnly: true` text field => no semantic `tap` (same issue as FSelect, see below).
  - Validation: a typed-but-incomplete date yields the localized invalid-date error; an empty field calls `validator(null)`
    (`foundation/input/input.dart:130-134`), so "required" must be done in `validator`.
- Evidence: `widgets/date_field/**`, `foundation/input/input.dart`, `widgets/calendar/date_selection_control*.dart`; docs
  https://forui.dev/docs/widgets/form/date-field ; PROBE `date_test.dart`.

### `FTimeField` — time picker field (typed input or wheel-picker popover)
- Import: `package:forui/forui.dart` (via `lib/widgets/time_field.dart`; exports `FTimeFieldController`, `FTimeFieldControl`, `FTimeFieldStyle`; `FTime` from foundation)
- Constructors (`widgets/time_field/time_field.dart`): `const FTimeField({FTimeFieldControl control = const .managed(),
  FPopoverControl popoverControl, size = .md, style, bool? hour24, autofocus, focusNode, builder, prefixBuilder = defaultIconBuilder
  (clock), suffixBuilder, bool clearable = false, clearIconBuilder, TextInputAction? textInputAction, textAlign, textAlignVertical,
  textDirection, bool expands, VoidCallback? onEditingComplete, ValueChanged<FTime>? onSubmit, mouseCursor, canRequestFocus, label,
  description, enabled, FormFieldSetter<FTime>? onSaved, onReset, AutovalidateMode autovalidateMode = .onUnfocus, forceErrorText,
  errorBuilder, formFieldKey, key})` (`time_field.dart:217`, impl `input/input_time_field.dart:14`);
  `const FTimeField.picker({..., String Function(BuildContext, FTime, DateFormat) format = defaultFormat, String? hint, Alignment
  anchor, fieldAnchor, FPortalConstraints constraints = FPortalConstraints(maxWidth:200,maxHeight:200), spacing, overflow, ...,
  FTimeFieldPopoverBuilder popoverBuilder, int hourInterval = 1, int minuteInterval = 1, ...})` (`time_field.dart:299`, impl `picker/picker_time_field.dart:48`).
- Key optional parameters: `hour24` (null -> `MediaQuery.alwaysUse24HourFormatOf`, `picker_time_field.dart` `didChangeDependencies`),
  `hourInterval`/`minuteInterval` (picker only), `clearable`.
- State / control: value `FTime?` (`FTime(hour, minute)`, `foundation/time.dart:4-20`). `FTimeFieldControl.managed({FTimeFieldController?
  controller, FTime? initial, FormFieldValidator<FTime>? validator, ValueChanged<FTime?>? onChange})` / `.lifted({required FTime? time,
  required ValueChanged<FTime?> onChange, Duration duration = 300ms, Curve curve = easeOutCubic})` (`time_field_controller.dart:111-206`);
  **the validator lives on the control/controller** (`FTimeFieldController.validator`), not as a field param.
- Interaction states / variants: as FTextField.
- Focus & semantics: PROBE (`date_test.dart`): `.picker` -> `isTextField,isReadOnly,isFocusable,hasExpandedState actions=focus
  label="At\nPick a time" value="9:30 AM"` (no `tap`); typed `FTimeField` -> `actions=tap,focus value="9:30 AM"`. `Semantics(expanded)` at
  `picker_time_field.dart:314`.
- Motion: wheel motion from FPicker (reduced/disabled -> jump, `picker.dart:112`).
- Styling: `FTimeFieldStyle` (field styles, popover style, picker style); `FThemeData.timeFieldStyle`.
- Limitations / caveats: **`onSubmit` on `FTimeField` (typed) is declared but never used** (`input/input_time_field.dart:10, 21, 61` only);
  picker mode is a `readOnly` text field (no semantic tap); locale with non-western numerals/scripts needing composing falls back to
  English input (doc `time_field.dart:39-40`).
- Evidence: `widgets/time_field/**`; docs https://forui.dev/docs/widgets/form/time-field ; PROBE `date_test.dart`.

### `FPicker` (+ `FPickerWheel`) — generic multi-wheel picker
- Import: `package:forui/forui.dart` (via `lib/widgets/picker.dart`; exports `FPickerController`, `FPickerControl`, `FPickerStyle`,
  `FPickerWheel`, `FPickerWheelMixin`)
- Constructors: `const FPicker({required List<Widget> children, FPickerControl control = const .managed(), FPickerStyleDelta style =
  const .context(), String debugLabel = 'FPicker', Key? key})` (`widgets/picker/picker.dart:64-70`). Children: `FPickerWheelMixin`
  widgets are wheels; anything else (e.g. `Text(':')`) is a separator. `FPickerWheel` (`picker_wheel.dart`): `const FPickerWheel({required
  List<Widget> children, bool loop, int flex = 1, double? itemExtent, String? semanticsLabel, String Function(int index)?
  semanticsValueBuilder, bool autofocus, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, Key? key})` (= `ListWheel`, `:63-74`);
  `const FPickerWheel.builder({required IndexedWidgetBuilder builder, flex, itemExtent, semanticsLabel, semanticsValueBuilder, autofocus,
  focusNode, onFocusChange, key})` (infinite/indexed, `:77-87`).
- State / control: value = `List<int>` of selected item index per wheel. `FPickerControl.managed({FPickerController? controller,
  List<int>? initial, ValueChanged<List<int>>? onChange})` / `.lifted({required List<int> indexes, required onChange, Duration duration =
  300ms, Curve curve = easeOutCubic})` (`picker_controller.dart:242-262`). Values are committed on scroll end
  (`picker.dart:138-158`).
- Interaction states / variants: wheel focus ring when focused and `focusHighlight` (`picker_wheel.dart:211-220`); ArrowUp/ArrowDown change the
  value one step (`:196-206, 235-241`).
- Focus & semantics: **semantics are opt-in per wheel**. With `semanticsValueBuilder`: one merged adjustable node (`increasedValue`,
  `decreasedValue`, `onIncrease`, `onDecrease`, `excludeSemantics`, optional `label`) (`:166-181, 226-230`). With only `semanticsLabel`:
  a labelled container plus the scrollable list items (`inMutuallyExclusiveGroup`) (`:182-184, 286`). With neither: only a focus node + the list.
  PROBE (`date_test.dart`): value-builder wheel -> `actions=increase,decrease,focus label="Level" value="L0" incr="L1" decr="L0"`; none ->
  `isFocusable, actions=focus` + scroll node + items.
- Motion: `reduceMotion = FAccessibility.motion != all` -> `jumpToItem` instead of animating (`picker.dart:112`, `picker_wheel.dart:235-241`);
  haptic on each snap (`style.hapticFeedback`, `:160`); `animateToItem` 100ms `decelerate` for keyboard steps.
- Styling: `FPickerStyle` (`picker_style.dart:13`: textStyle, selectionDecoration, focusedOutlineStyle, hapticFeedback, diameterRatio 1.07,
  squeeze, magnification, overAndUnderCenterOpacity 0.25, spacing 5, selectionHeightAdjustment); `FThemeData.pickerStyle`.
- Limitations / caveats: needs finite height (debug `FiniteConstraintsValidator`, `picker.dart:184-186`); wheel semantics are the caller's job.
- Evidence: `widgets/picker/picker.dart`, `picker_wheel.dart`, `picker_controller.dart`, `picker_style.dart`; docs
  https://forui.dev/docs/widgets/form/picker ; PROBE `date_test.dart`.

### `FTimePicker` — hour/minute(/period) wheels
- Import: `package:forui/forui.dart` (via `lib/widgets/time_picker.dart`)
- Constructors (`widgets/picker/time/time_picker.dart:70`): `const FTimePicker({FTimePickerControl control = const .managed(),
  FTimePickerStyleDelta style = const .context(), bool? hour24, int hourInterval = 1, int minuteInterval = 1, Key? key})` (asserts
  intervals > 0).
- State / control: value `FTime`. `FTimePickerControl.managed({FTimePickerController? controller, FTime? initial, ValueChanged<FTime>?
  onChange})` / `.lifted({required FTime time, required ValueChanged<FTime> onChange, Duration duration, Curve curve})`
  (`time_picker_controller.dart:144-156`).
- Focus & semantics: each wheel built with localized `semanticsLabel` ("Hour"/"Minute") and `semanticsValueBuilder` (`time_picker_wheels.dart:131-154`);
  the AM/PM wheel has value only. PROBE: `label="Hour" value="9" incr="10" decr="8"`, `label="Minute" value="30"`, third wheel `value="AM" incr="PM"`;
  each wheel appears as two nodes with identical label/value (one `isFocusable`, one not) in the dump. Keys: Up/Down value, Left/Right between wheels (doc `:13-16`).
- Motion / styling: as FPicker; `FTimePickerStyle extends FPickerStyle` (+ hourFlex, minuteFlex, periodFlex, padding); `FThemeData.timePickerStyle`.
- Limitations / caveats: changing intervals at runtime resets position (`time_picker_controller.dart:41`, Flutter #162972).
- Evidence: `widgets/picker/time/*.dart`; docs https://forui.dev/docs/widgets/form/time-picker ; PROBE `date_test.dart`.

### `FDateTimePicker` — date + time wheels
- Import: `package:forui/forui.dart` (via `lib/widgets/date_time_picker.dart`)
- Constructors (`widgets/picker/date_time/date_time_picker.dart:94`): `const FDateTimePicker({FDateTimePickerControl control = const
  .managed(), FDateTimePickerStyleDelta style, bool? hour24, int dayInterval = 1, int hourInterval = 1, int minuteInterval = 1, Widget
  Function(BuildContext, DateTime, DateFormat) dateBuilder = defaultDateBuilder ("Today" or `MMMEd`), Key? key})`.
- State / control: value `DateTime` built as local `DateTime(y, m, d, h, min)` (no seconds) (`date_time_picker_controller.dart` `decode`);
  `FDateTimePickerControl.managed({controller, DateTime? initial, onChange})` / `.lifted({required DateTime dateTime, required onChange,
  duration, curve})` (`:161-178`). The date wheel is unbounded in both directions, indexed from the first value's date
  (`_dateTime ??= .utc(y,m,d)`); there are no min/max bounds.
- Focus & semantics: PROBE: date wheel `value="Saturday, October 17, 2026" incr/decr` (no label); hour/minute wheels labelled; period wheel value only
  (`date_time_picker.dart:197-198`).
- Motion / styling: as FPicker; `FThemeData.dateTimePickerStyle`.
- Limitations / caveats: no `firstDate/lastDate`; date wheel has no `semanticsLabel`.
- Evidence: `widgets/picker/date_time/*.dart`; docs https://forui.dev/docs/widgets/form/date-time-picker ; PROBE `date_test.dart`.

### `FSelect<T>` — single-value dropdown (read-only text field + popover list)
- Import: `package:forui/forui.dart` (via `lib/widgets/select.dart`; also `FSelectItem`, `FSelectSection`, `FSelectItemMixin`, `FSelectControl`,
  `FSelectController`, `FSelectSearchFieldProperties`, `FSelectStyle`, `FMultiSelect*`)
- Constructors (`widgets/select/single/select.dart`; abstract class with factories; `new` at `:254`, `rich` `:365`, `search` `:435`, `searchBuilder` `:570`):
  - `FSelect<T>({required Map<String, T> items, FSelectControl<T>? control, FPopoverControl popoverControl, size = .md, style, autofocus,
    focusNode, builder, prefixBuilder, suffixBuilder = defaultIconBuilder (chevron), Widget? label, Widget? description, bool enabled = true,
    FormFieldSetter<T>? onSaved, VoidCallback? onReset, AutovalidateMode autovalidateMode = .onUnfocus, String? forceErrorText,
    FormFieldValidator<T> validator, errorBuilder, String? hint, textAlign, textAlignVertical, textDirection, expands, MouseCursor
    mouseCursor = .defer, canRequestFocus, bool clearable = false, clearIconBuilder, FSelectPopoverBuilder<T> popoverBuilder, contentAnchor
    = .topStart, fieldAnchor = .bottomStart, contentConstraints = FAutoWidthPortalConstraints(maxHeight: 300), contentSpacing, contentOverflow,
    ..., bool autoHide = true, bool? retainFocus, contentEmptyBuilder, contentScrollController, bool contentScrollHandles = false,
    contentPhysics, contentDivider, Key? formFieldKey, Key? key})` (`:254-`); each key of `items` is the display text, keys must map to
    unique values.
  - `const FSelect<T>.rich({required String Function(T) format, required List<FSelectItemMixin> children, ...same})` (`:365`).
  - `FSelect<T>.search({required Map<String, T> items, FutureOr<Iterable<T>> Function(String)? filter, FSelectSearchFieldProperties
    searchFieldProperties, contentLoadingBuilder, contentErrorBuilder, ...same})` (`:435`).
  - `const FSelect<T>.searchBuilder({required String Function(T) format, required filter, required FSelectSearchContentBuilder<T>
    contentBuilder, ...})` (`:570`).
  - Items: `FSelectItem<T>({required Widget title, required T value, FItemStyleDelta style, bool? enabled, Widget? prefix, Widget? subtitle,
    Widget? Function(BuildContext, bool selected) suffixBuilder = check icon when selected, key})`, `.raw({required child, required value,
    ...})`, `FSelectSection<T>({required Widget label, required Map<String,T> items, ...})` / `.rich` (`select_item.dart:29-86, 335-373`).
- State / control: `FSelectControl<T>? control` (nullable, null = managed): `.managed({FSelectController<T>? controller, T? initial, bool
  toggleable, ValueChanged<T?>? onChange})` / `.lifted({required T? value, required ValueChanged<T?> onChange})`
  (`select_controller.dart:48-122`); `FSelectController<T> extends ValueNotifier<T?>` with `toggleable` (re-selecting clears, `:16`).
  Typed value `T?`; the displayed text is `format(value)` written into a read-only text controller (`select.dart:780-830`).
- Interaction states / variants: `FTextFieldVariant`; item states from `FItem`; selected item has the check suffix.
- Focus & semantics:
  - Field = read-only `FTextField` with `onTap: _toggle`, `onTapAlwaysCalled: true`, `readOnly: true` (`select.dart:853-856`); Enter/Space toggle, Backspace
    clears when `clearable`, Esc closes (`:884, 922-933`); `Semantics(expanded: popover open)` (`:936`).
  - **PROBE (`pick_test.dart`, `pick2_test.dart`): the closed field node is `flags=isTextField,isReadOnly,isFocusable,hasExpandedState actions=focus`
    — it has NO `tap` action.** Performing `SemanticsAction.tap` is impossible (node has no tap) and `SemanticsAction.focus` focuses but does not open
    the popover. Pointer tap on `EditableText` opens it (after `pumpAndSettle`); the open items are `hasCheckedState, isInMutuallyExclusiveGroup`
    (+`isChecked` for the selected) with `actions=tap,focus`. Cause: Material omits semantic `onTap` for `readOnly` text fields
    (`material_ui: text_field.dart:1825`) and forui does not add one. Whether a real TalkBack/VoiceOver double-tap can open it is
    UNVERIFIED (needs a device); the framework-level semantic tap action does not exist.
  - PROBE labels: no value -> `label="Language\nSelect an item"` (hint is merged into the label); with value -> `value="French"`.
  - Items set `semanticsButton:false, semanticsChecked: selected, semanticsInMutuallyExclusiveGroup: true` (`select_item.dart:494-512`).
- Motion: popover (FPopover); `ContentData` reads `accessibility.motion` for scroll handles (`select/content/content.dart:225-226`).
- Styling: `FSelectStyle` (`single/select_style.dart`: `fieldStyles` (per size `FTextFieldStyle`), `contentStyle`, `emptyTextStyle`), `FThemeData.selectStyle`.
- Limitations / caveats: see PROBE above (no semantic tap); the `format` closure is `inverse[value]!` for map items (throws if a controller value is
  not among the items, `select.dart:327, 495`); explicit `FSelect<String>` type args needed (class doc `:30-33`); `autoHide` doc says "Defaults to false"
  (`:221`) but defaults to `true`; needs `Overlay`.
- Evidence: `widgets/select/single/*.dart`, `select_item.dart`; docs https://forui.dev/docs/widgets/form/select ; PROBE `pick_test.dart`, `pick2_test.dart`.

### `FMultiSelect<T>` — multi-value select with tags
- Import: `package:forui/forui.dart` (via `lib/widgets/select.dart`; also `FMultiSelectTag`, `FMultiSelectStyle`)
- Constructors (`widgets/select/multi/select.dart`):
  - `FMultiSelect<T>({required Map<String, T> items, FMultiValueControl<T>? control, FPopoverControl popoverControl, size, style, autofocus,
    focusNode, prefixBuilder, suffixBuilder = defaultIconBuilder, label, description, enabled, void Function(Set<T>)? onSaved, onReset,
    autovalidateMode = .onUnfocus, forceErrorText, String? Function(Set<T>) validator, errorBuilder, Widget? hint, bool keepHint = true,
    int Function(T, T)? sort, FMultiSelectTagBuilder<T>? tagBuilder, textAlign, textDirection, bool clearable = false, clearIconBuilder,
    popoverBuilder, content* params, formFieldKey, key})` (`:283-`);
  - `const FMultiSelect<T>.rich({required Widget Function(T) format, required List<FSelectItemMixin> children, ...})` (`:387`);
  - `FMultiSelect<T>.search(Map<String, T> items, {filter, searchFieldProperties, ...})` — **`items` is positional here** (vs named `required items`
    in `FSelect.search`) (`:453`); `const FMultiSelect<T>.searchBuilder({required Widget Function(T) format, required filter, required contentBuilder,
    ...})` (`:580`).
  - `FMultiSelectTagBuilder<T> = Widget Function(BuildContext, bool enabled, FMultiValueNotifier<T> controller, FMultiSelectFieldStyle style, T value,
    Widget label)`; default tag = removable `FMultiSelectTag`.
- State / control: `FMultiValueControl<T>` (`foundation/notifiers.dart:158-`): `.managed({FMultiValueNotifier<T>? controller, Set<T>? initial,
  int min, int? max, ValueChanged<Set<T>>? onChange})`, `.managedRadio({controller, T? initial, onChange})`, `.lifted({required Set<T> value,
  required ValueChanged<Set<T>> onChange})`. `FMultiValueNotifier<T> extends ValueNotifier<Set<T>>`; `update(value, add:)` silently ignores adds past
  `max` and removes below `min` (`:54-66`); setting `value` outside `[min,max]` throws `ArgumentError` (`:70-80`). The `FormField` value is `Set<T>`.
- Focus & semantics: the field is an `FTappable(semanticsContainer:false, semanticsExpanded: open)` + `HintSemantics` (hint tagged child becomes the
  node hint) inside `Semantics(validationResult: valid|invalid)` and `FLabel` (`select.dart:823, 880-895`, `hint_semantics.dart`).
  PROBE: closed -> `flags=isButton,hasExpandedState actions=tap,focus label="Tags" hint="Select items"` plus per-tag button `label="Remove\nA"`
  (`actions=tap,focus`); a semantic tap opens it (items `hasCheckedState` `actions=tap,focus`). Unlike FSelect, the multi-select **is** activatable
  by semantic tap. Backspace removes the last tag (`:918-925`). Tapping the label text does not open it (PROBE).
- Motion / styling: popover; `FMultiSelectStyle` (`multi/select_style.dart`), tag style `FMultiSelectTagStyle`; `FThemeData.multiSelectStyle`.
- Limitations / caveats: **`onReset` is accepted and ignored** (see Gaps); `hint` is a `Widget` (FSelect: `String`); needs explicit `<T>`.
- Evidence: `widgets/select/multi/*.dart`, `foundation/notifiers.dart`; docs https://forui.dev/docs/widgets/form/multi-select ; PROBE `pick_test.dart`, `pick2_test.dart`, `reset_test.dart`.

---------------------------------------------------------------------------------------------------------------------------
## 3. Selection controls
---------------------------------------------------------------------------------------------------------------------------

### `FCheckbox` — boolean checkbox (NOT a FormField)
- Import: `package:forui/forui.dart` (via `lib/widgets/checkbox.dart`)
- Constructors (`widgets/checkbox.dart:87-101`): `const FCheckbox({FCheckboxStyleDelta style = const .context(), bool leadingLabel = false,
  Widget? label, Widget? description, Widget? error, String? semanticsLabel, bool value = false, ValueChanged<bool>? onChange, bool enabled =
  true, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, Key? key})`.
- State / control: **lifted only** — `value` + `onChange(!value)`; no controller, no validator/`onSaved`. For a validated checkbox group use
  `FSelectGroup` (a `FormField<Set<T>>`).
- Interaction states / variants: `FCheckboxVariant` = `disabled | error | selected | focused | hovered | pressed` (`checkbox.dart:13-20`); `error` is set by
  `error != null`.
- Focus & semantics: whole row (label + box) is one `FTappable` (`:112-121`): `semanticsButton:false, semanticsChecked: value, onPress: enabled ?
  onChange(!value) : null`. PROBE (`sel_test.dart`): `flags=hasCheckedState,isChecked,hasEnabledState,isEnabled,isFocusable actions=tap,focus
  label="Remember me" hint="desc"`; disabled: no `isEnabled`/actions; error: `hint="Must accept" validation=invalid`.
  PROBE: `label` + `semanticsLabel` together produce a **duplicated** name (`label="Remember\nRemember me"`); with no `label`, `semanticsLabel` is the name.
- Motion: box fade 100ms linear; `Duration.zero` when `FAccessibility.motion == disabled` (`:106, 139-143`); no bounce (`tappableStyle.motion = none`, `:223`).
- Styling: `FCheckboxStyle` (`:180-290`: tappableStyle, focusedOutlineStyle, iconStyle, `icon`, `decoration` over variants, `leadingLabelStyle`,
  `trailingLabelStyle`, `size` 16 desktop / 20 touch, `motion`); `FThemeData.checkboxStyle`.
- Limitations / caveats: hit target = label row; with no/short label the PROBE node rect is 360x20 on touch (box is 20dp, no min-target padding added);
  not a form field; `FCheckbox` in a `Form` does nothing.
- Evidence: `widgets/checkbox.dart`; docs https://forui.dev/docs/widgets/form/checkbox ; PROBE `sel_test.dart`.

### `FRadio` — single radio (NOT a FormField)
- Import: `package:forui/forui.dart` (via `lib/widgets/radio.dart`)
- Constructors (`widgets/radio.dart:89-103`): `const FRadio({style, leadingLabel, label, description, error, semanticsLabel, bool value = false,
  ValueChanged<bool>? onChange, enabled, autofocus, focusNode, onFocusChange, key})` — same shape as FCheckbox.
- State / control: lifted only. **A standalone `FRadio` calls `onChange(!value)`, so tapping the selected radio reports `false`** (`radio.dart:121`);
  there is no mutual exclusion — use `FSelectGroup` with `FSelectGroupItemMixin.radio` (library doc says so, `lib/widgets/radio.dart`).
- Interaction states / variants: `FRadioVariant` = `disabled | error | selected | focused | hovered | pressed` (`radio.dart:12-19`).
- Focus & semantics: `semanticsChecked: value, semanticsInMutuallyExclusiveGroup: true` always (`:117-120`). PROBE: `hasCheckedState,isChecked,
  isInMutuallyExclusiveGroup actions=tap,focus label="Option A"`.
- Motion: 100ms linear colour/size transitions, indicator `AnimatedSize` 100ms `easeOutCirc`; zero when motion disabled (`:108, 143-163`, `FRadioMotion` `:274-292`).
- Styling: `FRadioStyle` (`:190`; outer size = `indicatorSize` 12 touch / 8 desktop + 2x3 padding + border, `inherit` `:228-235`); `FThemeData.radioStyle`.
- Limitations / caveats: outer circle ~18dp touch (no min-target padding).
- Evidence: `widgets/radio.dart`; docs https://forui.dev/docs/widgets/form/radio ; PROBE `sel_test.dart`.

### `FSwitch` — on/off toggle (NOT a FormField; wraps `CupertinoSwitch`)
- Import: `package:forui/forui.dart` (via `lib/widgets/switch.dart`)
- Constructors (`widgets/switch.dart:100-115`): `const FSwitch({FSwitchStyleDelta style = const .context(), bool leadingLabel = false, Widget? label,
  Widget? description, Widget? error, String? semanticsLabel, bool value = false, ValueChanged<bool>? onChange, bool enabled = true, bool autofocus =
  false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, DragStartBehavior dragStartBehavior = .start, Key? key})`.
- State / control: lifted only (`value`, `onChange`).
- Interaction states / variants: `FSwitchVariant` = `disabled | error | selected` (`switch.dart:12-16`) — no hover/pressed/focused variants (focus colour
  `style.focusColor`).
- Focus & semantics: outer `GestureDetector(onTap)` for the label affordance (`:154`) around `Semantics(label: label == null ? semanticsLabel : null,
  enabled, focusable, focused, toggled: value)` (`:156-162`); the inner `CupertinoSwitch` semantics are excluded (`ExcludeSemantics`, `:172`).
  PROBE: `hasEnabledState,isEnabled,hasToggledState,isToggled,isFocusable actions=tap label="Notifications" hint="desc"`; disabled -> no `isEnabled`/`tap`;
  label-less + `semanticsLabel: 'Notify'` -> `label="Notify"`. No `focus` action in the node (keyboard focus is handled by the inner widget).
- Motion: `CupertinoSwitch`'s own animation; no `FAccessibility` read in `switch.dart` (UNVERIFIED whether Cupertino honours disable-animations).
- Styling: `FSwitchStyle {focusColor, trackColor, thumbColor, leadingLabelStyle, trailingLabelStyle}` (`:206`); `FThemeData.switchStyle`. Track/thumb size is
  fixed by `CupertinoSwitch` (not a style field).
- Limitations / caveats: cannot resize; iOS-style regardless of platform.
- Evidence: `widgets/switch.dart`; docs https://forui.dev/docs/widgets/form/switch ; PROBE `sel_test.dart`.

### `FSlider` — continuous/discrete single or range slider (FormField<FSliderValue>)
- Import: `package:forui/forui.dart` (via `lib/widgets/slider.dart`; exports `FSliderControl`, `FSliderController` family, `FSliderValue`, `FSliderMark`,
  `FSliderStyles`, `FSliderInteraction`, `FSliderActiveThumb`, `FSliderTooltipControls`)
- Constructors (`widgets/slider/slider.dart:126-158`): `FSlider({FSliderControl control = const .managedContinuous(), FSliderStyleDelta style =
  const .context(), FLayout? layout, Widget? label, Widget? description, Widget Function(BuildContext, String) errorBuilder = defaultErrorBuilder,
  List<FSliderMark> marks = const [], double? trackMainAxisExtent, double? trackHitRegionCrossExtent, FSliderTooltipControls tooltipControls = const
  .new(), Widget Function(FTooltipController, double value) tooltipBuilder = defaultTooltipBuilder, String Function(double) semanticValueFormatterCallback =
  defaultSemanticValueFormatter, String Function(FSliderValue)? semanticFormatterCallback, ValueChanged<FSliderValue>? onEnd, FormFieldSetter<FSliderValue>?
  onSaved, VoidCallback? onReset, FormFieldValidator<FSliderValue>? validator, String? forceErrorText, bool enabled = true, AutovalidateMode
  autovalidateMode = .disabled, Key? formFieldKey, Key? key})`. Not const. Throws `StateError` for a vertical slider with label/description/forceErrorText and no
  `trackMainAxisExtent` (`:150-157`); throws `FlutterError` if the main axis is unbounded (`:266-274`).
- Key optional parameters:
  - `layout: FLayout?` (null -> `rtl` if `Directionality.rtl`, else `ltr`; vertical variants use `.ttb/.btt`).
  - `marks: List<FSliderMark>` — `const FSliderMark({required double value (0..1), FSliderMarkStyle? style, bool tick = true, Widget? label})` (`slider_mark.dart`);
    **required (non-empty) for discrete sliders** (`slider_controller.dart:268, 377` assert).
  - `trackHitRegionCrossExtent`: cross-axis size of the track hit region. Doc: default is "the tracker the thumb's cross extent, whichever is larger, on primarily
    touch devices; 0 on non-primarily touch devices" (`slider.dart:68-73`); code: touch -> `Container(height/width: trackHitRegionCrossExtent ??
    max(thumbSize, crossAxisExtent))` (`track.dart:149-153`); defaults `thumbSize` 25 touch / 16 desktop, `crossAxisExtent` 6 (`slider_styles.dart:47, 58, 112, 123`) =>
    **25dp tall hit region on touch unless overridden**; passing a value also enables the hit region on non-touch.
  - `semanticValueFormatterCallback(double fraction)` (per thumb; default `"40%"`, `slider.dart:27`) and `semanticFormatterCallback(FSliderValue)` (whole-slider label;
    default `"40%"` or `"a% - b%"`, `:403-408`).
  - `tooltipControls`: `const FSliderTooltipControls({FTooltipControl min, max})` / `.disabled()` (`slider_control.dart:360-376`); tooltips are ON by default and show
    `defaultTooltipBuilder` (percentage) while dragging; `onEnd(FSliderValue)` fires when the user finishes (not for programmatic changes, `:88-93`).
- State / control: `FSliderControl` (`slider_control.dart`): `.managedContinuous({FContinuousSliderController? controller, FSliderValue? initial, double?
  stepPercentage (0.05), FSliderInteraction? interaction, FSliderActiveThumb? thumb, onChange})`, `.managedContinuousRange(...)`, `.managedDiscrete(...)`,
  `.managedDiscreteRange(...)`, and `.liftedContinuous/.liftedContinuousRange/.liftedDiscrete/.liftedDiscreteRange({required FSliderValue value, required
  ValueChanged<FSliderValue> onChange, ...})` (`:27-143`). `FSliderInteraction` = `slide | slideThumb | tapAndSlideThumb (default) | tap`;
  `FSliderActiveThumb` = `min | max` (`slider_controller.dart:7-27`).
  **Value model is normalised**: `FSliderValue({required double max, double min = 0, ({double min,double max}) constraints = (min:0,max:1)})` — fractions of the
  track (0..1), not domain units (`slider_value.dart`); map to your own range/steps in code. Discrete snaps to mark values (PROBE: an initial 0.4 on a 5-mark
  slider reported as step 3 of 5, i.e. snapped to 0.5).
- Interaction states / variants: `FSliderVariant` (axis horizontal/vertical, platform, disabled/focused/hovered/pressed on thumbs).
- Focus & semantics: `Semantics(slider: true, enabled, value, increasedValue, decreasedValue, onIncrease, onDecrease)` per **active** thumb
  (`track.dart:74-84`); the thumb is a `FocusableActionDetector(includeFocusSemantics:false)` with Home/End and arrow-key intents (`thumb.dart:67-86, 126`). Arrow
  step = `stepPercentage` (continuous) or next mark (discrete). Range sliders expose ONE semantics node that edits one thumb at a time, with hint "Double tap to
  switch thumbs", `onTap` and a custom action ("Select maximum thumb"), and value `"Minimum, 20% - 60%"` (`:84-95, 117-123`).
  PROBE: single `isSlider actions=increase,decrease label="Volume" value="40%" incr="45%" decr="35%" hint="desc"`; range `actions=tap,increase,decrease,customAction
  value="Minimum, 20% - 60%" hint="Double tap to switch thumbs"`; custom formatter `value="3 of 5" incr="4" decr="1"`; disabled -> no `isEnabled` and no actions (value/incr/decr strings still present).
- Motion: no widget animation of its own; tooltip motion = `FTooltipMotion`; no `FAccessibility` read in `slider/` (rg).
- Styling: `FSliderStyles` (axis + platform variants, `FThemeData.sliderStyles`) of `FSliderStyle` (`slider_styles.dart`: activeColor, inactiveColor,
  `thumbStyle`, `markStyle`, `tooltipStyle`, haptics, `crossAxisExtent`, `thumbSize`, paddings). Vertical needs `trackMainAxisExtent` for label/description.
- Limitations / caveats: normalised values; tooltips on by default (disable with `FSliderTooltipControls.disabled()`); touch hit region 25dp by default (override with
  `trackHitRegionCrossExtent`); range slider is single-node for AT; `onReset` fires (PROBE `slider` in list); requires a bounded main axis.
- Evidence: `widgets/slider/*.dart`; docs https://forui.dev/docs/widgets/form/slider ; PROBE `sel_test.dart`, `reset_test.dart`.

### `FSelectGroup<T>` + `FSelectGroupItemMixin` — checkbox/radio group (FormField<Set<T>>)
- Import: `package:forui/forui.dart` (via `lib/widgets/select_group.dart`; also `FSelectGroupStyle`, `FSelectGroupItemData`)
- Constructors: `const FSelectGroup<T>({required List<FSelectGroupItemMixin<T>> children, FMultiValueControl<T>? control, FSelectGroupStyleDelta style =
  const .context(), Widget? label, Widget? description, Widget Function(BuildContext, String) errorBuilder = FFormFieldProperties.defaultErrorBuilder,
  FormFieldSetter<Set<T>>? onSaved, VoidCallback? onReset, FormFieldValidator<Set<T>>? validator, String? forceErrorText, bool enabled = true,
  AutovalidateMode autovalidateMode = .disabled, Key? formFieldKey, Key? key})` (`widgets/select_group/select_group.dart:144-159`). Items are static factories on the
  mixin: `FSelectGroupItemMixin.checkbox<T>({required T value, FCheckboxStyle? style, Widget? label, Widget? description, Widget? error, String? semanticsLabel,
  bool? enabled, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange})` and `.radio<T>({...same with FRadioStyle? style})`
  (`select_group_item.dart:9-56`). Item `style` is a full style object, not a delta.
- State / control: `FMultiValueControl<T>? control` (null = `managed()` = multi-select). **For radio behaviour pass `FMultiValueControl.managedRadio(initial: ...)`**
  (`foundation/notifiers.dart:98-112`: `_RadioNotifier.update(add:false)` is ignored, so the selected radio cannot be deselected; it holds at most one value). Value `Set<T>`.
  `min`/`max` on `.managed(...)` bound the count.
- Interaction states / variants: group `enabled` and error propagate to items via `FSelectGroupItemData` (`select_group.dart:232-238`); item-level `enabled` overrides.
- Focus & semantics: `FLabel(vertical)` around a `Column`; PROBE: group container `label="Level"`; radio items `hasCheckedState,isChecked,
  isInMutuallyExclusiveGroup actions=tap,focus label="A"`; with `forceErrorText` the group node gets `hint="Pick one" validation=invalid` and **each item** gets
  `validation=invalid`. A `liveRegion` error is announced via FLabel.
- Motion / styling: items are FCheckbox/FRadio; `FSelectGroupStyle {checkboxStyle, radioStyle, itemPadding (vertical 4), label styles}` (`:256-346`);
  `FThemeData.selectGroupStyle`.
- Limitations / caveats: **`onReset` accepted and ignored** (not passed to `MultiValueFormField`, `select_group.dart:209-216`; PROBE `reset_test.dart`);
  PROBE item rect height 24 (touch theme); no horizontal layout parameter (always a `Column`).
- Evidence: `widgets/select_group/*.dart`, `foundation/form/multi_value_form_field.dart`, `foundation/notifiers.dart`; docs
  https://forui.dev/docs/widgets/form/select-group ; PROBE `sel_test.dart`, `reset_test.dart`.

### `FSelectTileGroup<T>` + `FSelectTile<T>` — selection model only (tile layout belongs to the tile catalog)
- Import: `package:forui/forui.dart` (via `lib/widgets/select_tile_group.dart`)
- Constructors (`widgets/select_tile_group/select_tile_group.dart`): `FSelectTileGroup<T>({required List<FSelectTile<T>> children, FMultiValueControl<T>?
  control, scrollController, style, scrollCacheExtent, maxHeight, intrinsicWidth, dragStartBehavior, physics, FItemDivider divider = .indented, label, description,
  String? semanticsLabel, errorBuilder, onSaved, onReset, validator, forceErrorText, bool enabled = true, AutovalidateMode autovalidateMode = .disabled, formFieldKey,
  key})` (`:122-146`); `FSelectTileGroup<T>.builder({required FSelectTile<T>? Function(BuildContext, int) tileBuilder, int? count, ...})` (`:153-177`).
  Tiles: `const FSelectTile<T>({required Widget title, required T value, style, checkedIcon, uncheckedIcon, subtitle, details, semanticsLabel, bool? enabled, autofocus, focusNode,
  onFocusChange, onHoverChange, onVariantChange, shortcuts, actions, Widget? suffix, key})` (check icon as prefix) and `const FSelectTile<T>.suffix({..., Widget? prefix})`
  (check icon as suffix); `FSelectTile.tile` is a const factory alias (`select_tile.dart:87, 113, 137`).
- State / control: same `FMultiValueControl<T>` as FSelectGroup (null = multi; `managedRadio` for single). Tile press -> `controller.update(value, add: !selected)` (`select_tile.dart:189`),
  so in radio mode a selected tile cannot be unselected. Value `Set<T>`.
- Focus & semantics: tiles are `FTile(selected: selected)`; PROBE (radio): `hasSelectedState,isSelected,isButton ... actions=tap,focus label="A"`; unselected has no `isSelected`.
  **No `isChecked`/`isInMutuallyExclusiveGroup` on tiles** (contrast FSelectGroup radios); group container `label="Level"`.
- Limitations / caveats: **`onReset` accepted and ignored** (`select_tile_group.dart:240-247` passes no `onReset`; PROBE `reset_test.dart`); selection is expressed to AT only as
  "selected" button.
- Evidence: `widgets/select_tile_group/*.dart`; docs https://forui.dev/docs/widgets/tile/select-tile-group ; PROBE `sel_test.dart`, `reset_test.dart`.

---------------------------------------------------------------------------------------------------------------------------
## Gaps / surprises (my categories)
---------------------------------------------------------------------------------------------------------------------------

1. **`FSelect` single and read-only date/time fields have no semantic `tap` action** (PROBE `pick_test.dart`, `date_test.dart`): `FSelect`, `FDateField.calendar`,
   `FTimeField.picker` are `readOnly` Material text fields whose nodes expose only `focus`; semantic tap cannot open the popover and `focus` does not open it. `FMultiSelect`
   (button-like `FTappable`) and `FAutocomplete`/typed fields do expose `tap`. Real screen-reader behaviour: UNVERIFIED (device needed).
2. **`onReset` is silently ignored** by `FSelectGroup`, `FMultiSelect`, `FSelectTileGroup` (not forwarded to `MultiValueFormField`, which has no such param;
   PROBE `reset_test.dart` fired: textFormField, select, otp, dateCalendar, timePicker, autocomplete, slider; not fired: selectGroup, multiSelect, selectTileGroup). `FormState.reset()`
   still resets the values.
3. **`onSubmit` is dead on `FDateField.new/.input` and `FTimeField` (typed)**: declared, documented, stored, never wired (`input_date_field.dart:11,26,68,187,201,241`;
   `input_time_field.dart:10,21,61`).
4. **`FOtpField` semantics**: node value is `U+FFFC` x slots; typed digits only appear in the *label* (`"Code\n1\n2\n3"`). Default `keyboardType` is `.text`; no `length`
   parameter (slot count = number of `FOtpItem` in `FOtpFieldControl.children`); no completion callback; managed control only.
5. **`FTextField(maxLength:)` renders no counter** unless `counterBuilder` is provided (`input.dart:300-305`).
6. **`semanticsLabel` on `FButton` removes `isFocusable` + the `focus` action** (`excludeSemantics: semanticsLabel != null`, `button.dart:304`; PROBE).
   Icon-only `FButton.icon` without a label has an anonymous node.
7. **No loading/busy API on `FButton`**: only `prefix: FCircularProgress()` (label becomes `"Loading\n<text>"`), and the caller must pass `onPress: null`.
8. **`FCheckbox` + `label` + `semanticsLabel` doubles the accessible name** (PROBE `"Remember\nRemember me"`); `FCheckbox`/`FRadio`/`FSwitch` are not `FormField`s;
   standalone `FRadio` reports `onChange(!value)`.
9. **Touch hit targets**: `FCheckbox` ~20dp, `FRadio` ~18dp outer, `FSlider` track hit region 25dp (touch), `FButton` xs 32dp, `FSelectGroup` rows ~24dp tall (PROBE rects). `FButton` md/lg
   (44/48) and text fields (44) meet 44dp. `trackHitRegionCrossExtent` is the only built-in knob for the slider.
10. **`FSlider` values are fractions 0..1**; discrete sliders require non-empty `marks` (debug assert) and snap the initial value to the nearest mark; tooltips are enabled by default.
11. **`FDateField` values are UTC-midnight `DateTime`s** and single selection is `toggleable` by default (tapping the selected day yields `null`). `FDateTimePicker` returns local `DateTime`
    (no seconds) with an unbounded date wheel. `FTimeField` validator lives on `FTimeFieldControl/Controller`.
12. **Doc/code drift**: `autoHide` documented as "Defaults to false" on `FSelect`/`FAutocomplete` but defaults to `true`; `FTextField.label` doc text describes errors; `FTooltipGroup` doc claims
    `FTheme` includes one but none is created; `FTextField.password` / `FAutocomplete.text` / `FTextFormField.password` are static methods, not constructors; `FMultiSelect.search` takes
    positional `items` while `FSelect.search` takes named `required items`.
13. **Tooltip + long press**: `FTooltip` shows on long press only if the child has no long-press recogniser (PROBE); works on disabled buttons; adds an unlabelled `longPress` semantic node;
    the tip is not part of the child's node (use `semanticsTooltip` on `FButton`).
14. **`FTextFormField.reset()` is rebuild-sensitive**: `initialValue` is `controller.text` at each build, so a parent rebuild between typing and `FormState.reset()` makes reset a no-op (PROBE `reset2_test.dart`). Keep the initial value in the controller (`FTextFieldControl.managed(controller:)` created with the initial text) if reset must restore it — UNVERIFIED that this variant avoids the drift.
15. **Reduced-motion coverage is partial**: FButton bounce, FTooltip, FAvatar, FLabel error, FCheckbox/FRadio, FPicker honour `FAccessibility.motion`; text fields, OTP, slider, FSwitch
    (Cupertino) have no forui hook. FButton keeps its bounce under `reduced` (only `disabled` turns it off).
16. Not verified: behaviour without an `Overlay` ancestor; real AT output (TalkBack/VoiceOver); dark theme / non-default text scale visuals; wheel pickers' duplicated semantics nodes
    (two nodes per wheel in the PROBE dump) on a device.

---

## ForUI 0.27.6 catalog D: data presentation, feedback, overlays

Scope: FAccordion, FAlert, FCircularProgress, FProgress, FDeterminateProgress, FCalendar, FLineCalendar,
FDialog/showFDialog, showFSheet/FModalSheetRoute, showFPersistentSheet/FSheets, FPopover, FPopoverMenu, FContextMenu,
FToaster/FToast/showFToast/showRawFToast, FTooltip (overlay aspects only).

Conventions
- `PKG` = `forui-0.27.6/lib/src/`. Citations are `<path under PKG>:<line>`; a bare
  `widgets/...` path is under PKG.
- `TESTS` = `<scratchpad>/forui-src/forui/test/src/widgets/`. `DOCS` = `https://forui.dev/docs/widgets/`.
- All symbols below are exported from `package:forui/forui.dart` (`lib/forui.dart:9-52` re-exports `lib/widgets/*.dart`;
  `FAccessibility*`, `FModalBarrier`, `FAnimatedModalBarrier`, `FLayout`, `FPortal*` come from `lib/foundation.dart:4-25`).
- The package source uses newer Dart syntax (primary constructors, `.dot` shorthands); signatures below are normalised to
  plain `Name({...})` form, with names, types and defaults copied from source.
- Reduced motion, as read by every widget here: `context.accessibility.motion`, an `FAccessibilityMotion` with values
  `all | reduced | disabled`. The platform scope sets `disabled` when `features.disableAnimations` (Android/web), else
  `reduced` when `features.reduceMotion` (iOS), else `all` (`foundation/accessibility.dart:7-20`, `:118-128`).
  `accessibleNavigation` is a separate flag (screen reader active). An `FAccessibilityScope(data:)` override exists
  (`accessibility.dart:68`, `:131`). Each widget decides separately which of the two values it honours; see each entry.
- Touch vs desktop: `FThemeData(touch: bool)` supplies the `touch` flag to every `*.inherit(...)` style factory.

---

## 1. Data presentation and feedback

### `FAccordion` — vertical stack of expandable items (not scrollable)
- Import: `package:forui/forui.dart` (`widgets/accordion.dart`).
- Constructor: `const FAccordion({required List<Widget> children, FAccordionControl control = const .managed(), FAccordionStyleDelta style = const .context(), Key? key})` (`widgets/accordion/accordion.dart:54`).
- Children: only children that mix in `FAccordionItemMixin` get the inherited controller/style; other children render
  as-is and still consume an index (`accordion.dart:96-109`, index from `children.indexed`). The widget is a plain
  `Column` (`accordion.dart:96`), so it never scrolls.
- State/control (`widgets/accordion/accordion_controller.dart`):
  - `FAccordionControl.managed({FAccordionController? controller, int? min, int? max, ValueChanged<Set<int>>? onChange})` (`:178`). Asserts: controller XOR min/max (`:227-230`). Default controller `.new(min: min ?? 0, max: max)` (`:234`).
  - `FAccordionControl.lifted({required Predicate<int> expanded, required void Function(int index, bool expanded) onChange})` (`:185`). The lifted proxy only calls `onChange` from `expand`/`collapse` and always returns true (`:160-170`); `min`/`max` are not enforced in lifted mode (read from `:140-171`, the proxy has no min/max logic; no test run).
  - `FAccordionController({int min = 0, int? max})` (`:32`), `toggle/expand/collapse(int) -> Future<bool>`, `expanded -> Set<int>` copy (`:44`, `:56`, `:87`, `:101`). When `max` is reached, expanding collapses the oldest expanded index (`:63-71`). `collapse` is refused when `_expanded.length <= min` (`:88`). Methods do nothing before items are built (`:18-19`, `controllers[index] == null`).
  - `onChange` fires from the controller listener in `_FAccordionState._handleOnChange` (`accordion.dart:89-93`).
- `FAccordionItem` (`accordion_item.dart:67`): `const FAccordionItem({required Widget title, required Widget child, FAccordionStyleDelta style = const .context(), Widget? icon, bool? initiallyExpanded, bool autofocus = false, FocusNode? focusNode, ValueChanged<bool>? onFocusChange, ValueChanged<bool>? onHoverChange, FTappableVariantChangeCallback? onVariantChange, Key? key})`. `icon` defaults to `FIcons.chevronDown` (`:214`). `initiallyExpanded` asserts null under lifted control (`:120-123`). More expanded items than `max` at build throws `StateError('Number of expanded items must be within the min and max.')` (`:157-159`).
- Interaction states: title text and icon resolve `FTappableVariant` (`hovered`, `pressed` -> underline by default, `accordion.dart:180-185`; focus via `FFocusedOutline` on the icon, `accordion_item.dart:207-209`). Tappable motion is `FTappableMotion.none` (`accordion.dart:195`): no press bounce.
- Focus & semantics: title is an `FTappable` (button) with `semanticsExpanded: controller.expanded.contains(index)` rebuilt via `ListenableBuilder` (`accordion_item.dart:179-191`). No heading semantics. Collapsed content stays in the tree inside `FCollapsible` (`:225`); whether `FCollapsible` excludes hidden content from semantics is UNVERIFIED (`foundation/collapsible.dart` not read).
- Motion: expand/collapse 200ms, `easeOutCubic`/`easeInCubic`, icon turns 0 -> 0.5, `FAccordionMotion` (`accordion.dart:204-239`; `FAccordionMotion.none` at `:236`). Reduced motion: any `motion != all` (reduced OR disabled) sets both durations to zero (`accordion_item.dart:129-132`). Initial state is applied with `_controller.value`, no animation (`:134-143`).
- Styling: `FAccordionStyle` (`accordion.dart:144`: `titleTextStyle`, `childTextStyle`, `iconStyle`, `focusedOutlineStyle`, `dividerStyle`, `tappableStyle`, `titlePadding` v16, `childPadding` bottom 16, `motion`), delta `FAccordionStyleDelta` (`accordion.design.dart:126`), default `FThemeData.accordionStyle` (`theme/theme_data.dart:55`). Each item ends with an `FDivider` (`accordion_item.dart:233`), so the last item also draws a trailing divider.
- Limitations: no heading semantics; no per-item disabled state (no `enabled`/`onPress` on the item); toggles cannot be vetoed other than via lifted `onChange`.
- Docs: `DOCS` + `data/accordion`.

### `FAlert` — static inline status callout
- Constructor: `const FAlert({required Widget title, FAlertVariant variant = .primary, FAlertStyleDelta style = const .context(), bool liveRegion = true, Clip clipBehavior = .none, Widget? icon, Widget? subtitle, Key? key})` (`widgets/alert.dart:87`). `StatelessWidget`.
- Variants: `FAlertVariant.primary`, `.destructive` plus platform variants (`alert.dart:11`, `alert.design.dart:63`); style resolved from `context.theme.alertStyles.resolve({variant, context.platformVariant})` (`alert.dart:100`). Destructive recolours icon/title/subtitle only, not border or background (`alert.dart:191-195`). No success/warning variants.
- Icon: default `context.theme.icons.circleAlert` (`alert.dart:111`); any widget accepted; `IconTheme` supplies size/colour.
- Focus & semantics: whole alert is `Semantics(container: true, liveRegion: liveRegion, ...)` (`alert.dart:101-103`). Live region defaults to true. No role, no label parameter (text comes from title/subtitle), not focusable, no action or close slot.
- Motion: none.
- Styling: `FAlertStyle` (`alert.dart:209`: `decoration`, `iconStyle` (`IconThemeData`), `titleTextStyle`, `subtitleTextStyle`, `padding` h16 v12), delta `FAlertStyleDelta` (`alert.design.dart:174`), `FThemeData.alertStyles` (`theme_data.dart:75`).
- Limitations: no action buttons or dismiss; layout hard-coded: icon + title row, subtitle indented by `iconStyle.size` plus literal paddings 10 and 2 (`alert.dart:109-131`).
- Docs: `DOCS` + `feedback/alert`.

### `FCircularProgress` — indeterminate spinner
- Constructors (`widgets/progresses/circular_progress.dart`):
  - `const FCircularProgress({FCircularProgressSizeVariant size = .md, FCircularProgressStyleDelta style = const .context(), String? semanticsLabel, FIcon icon = const _Loader(.circle), Key? key})` (`:73`), `FIcons.loaderCircle`.
  - `const FCircularProgress.loader({size, style, semanticsLabel, key})` (`:82`), `FIcons.loader`.
  - `const FCircularProgress.pinwheel({size, style, semanticsLabel, key})` (`:86`), `FIcons.loaderPinwheel`.
- Sizes: `FCircularProgressSizeVariant.xs|sm|md|lg|xl` (`:12-33`, `circular_progress.design.dart:83`). Icon size = `typography.body.<size>.fontSize` (`:259-271`; touch typography is larger). Style comes from `FInheritedCircularProgressStyle.of(context)` first, then `context.theme.circularProgressStyles.resolve({size, platform})` (`:130-133`). That inherited-style widget is public (`:201`), so a parent can override the spinner's style.
- Semantics: label default `FLocalizations.progressSemanticsLabel` (en "Loading", vi "Đang tải", `localizations/localizations_vi.dart:119`) passed to the icon as `semanticsLabel` (`:160-164`); `Icon(icon, semanticLabel:)` (`theme/icons.dart:282`). No `value`, not a live region.
- Motion and reduced motion (cite): one rotation per `FCircularProgressMotion.duration` (1s, linear, repeat) (`:294-306`, `_setup` `:129-148`). Only `FAccessibilityMotion.disabled` stops it: controller stopped at 0 and build returns the bare icon without `Transform.rotate` (`:141-143`, `:167`). `reduced` (iOS Reduce Motion) and `accessibleNavigation` do NOT stop it; it keeps spinning. Class doc agrees: "All motion is automatically disabled when ... disabled" (`:293`). Under `disabled` the spinner is a static glyph.
- Styling: `FCircularProgressStyle({required IconThemeData iconStyle, FCircularProgressMotion motion})` (`:225`), delta `FCircularProgressStyleDelta` (`circular_progress.design.dart:183`), sized variants `FCircularProgressSizeStyles` (`:243`), theme field `circularProgressStyles` (`theme_data.dart:165`). Colour default `colors.mutedForeground` (`:238`).
- Limitations: no explicit size parameter beyond the five size variants; a custom `icon` must honour the `semanticsLabel` argument of `FIcon.call`.
- Docs: `DOCS` + `feedback/circular-progress`.

### `FProgress` — indeterminate linear bar
- Constructor: `const FProgress({FProgressStyleDelta style = const .context(), String? semanticsLabel, Key? key})` (`widgets/progresses/progress.dart:44`).
- Semantics: `Semantics(label: semanticsLabel ?? progressSemanticsLabel)` only (`:112-114`): no value, no live region.
- Motion/reduced (cite): sliding segment, `period` 1000ms + `interval` 500ms, `Curves.ease`, filled fraction `value` 0.4 (`:180-198`). `_setup` runs `motion == .disabled ? _controller.stop() : _controller.repeat()` (`:98`); with `disabled` the bar shows a static partial segment `widthFactor: motion.value` (`:119-123`; comment `:117-118`: a full fill would read as "complete"). `reduced` still animates.
- Styling: `FProgressStyle({required Decoration trackDecoration, required Decoration fillDecoration, BoxConstraints constraints = tightFor(height: 6.0), FProgressMotion motion})` (`:147-159`), delta `FProgressStyleDelta` (`progress.design.dart:82`), `FThemeData.progressStyle` (`theme_data.dart:355`). Width unconstrained (fills the parent).
- Docs: `DOCS` + `feedback/progress`.

### `FDeterminateProgress` — linear bar with a value
- Constructor: `const FDeterminateProgress({required double value, FDeterminateProgressStyleDelta style = const .context(), String? semanticsLabel, Key? key})`; `assert(0.0 <= value && value <= 1.0)` (`widgets/progresses/determinate_progress.dart:49-50`). The field doc "Defaults to null" (`:42`) is stale; `value` is required.
- Semantics: `Semantics(label: semanticsLabel ?? progressSemanticsLabel, value: NumberFormat.percentPattern(localeName).format(value))` (`:115-117`), e.g. "50%". No live region.
- Motion/reduced (cite): fill animates to the new value, `animateTo(value, duration: 1000ms, curve: linear)` (`:89-102`, `:169-175`); `disabled` sets the value instantly (`:96-97`). `reduced` still animates.
- Styling: `FDeterminateProgressStyle({required trackDecoration, required fillDecoration, constraints = tightFor(height: 6.0), motion})` (`:135-148`), delta `FDeterminateProgressStyleDelta` (`determinate_progress.design.dart:82`), `FThemeData.determinateProgressStyle` (`theme_data.dart:195`).
- Docs: `DOCS` + `feedback/determinate-progress`.

### `FCalendar` — month calendar (grid or wheel)
- No default constructor; three named constructors, all with `required FDateSelectionControl<Object?> selectionControl` (`widgets/calendar/calendar.dart`):
  - `FCalendar.grid({selectionControl, FGridCalendarControl control = const FGridCalendarControl(), FCalendarStyleDelta style, bool fixedWeeks = false, ScrollPhysics? day/month/yearScrollPhysics, ScrollCacheExtent? day/month/yearScrollCacheExtent, ScrollBehavior? day/month/yearScrollBehavior, FCalendarHeaderBuilder<FGridCalendarController> headerBuilder, FCalendarFooterBuilder<...> footerBuilder, FCalendarDayBuilder dayBuilder, FCalendarMonthBuilder monthBuilder, FCalendarYearBuilder yearBuilder, FutureOr<void> Function(DateTime)? onDayPress, onDayLongPress, Key? key})` (`:162`). Day -> month -> year picker cycle.
  - `FCalendar.splitGrid({... FGridSplitCalendarControl control ...})` (`:231`). Month and year pickers toggled independently.
  - `FCalendar.wheel({... FWheelCalendarControl control, bool loop = false, int monthFlex = 1, int yearFlex = 1, ...})` (`:294`). Day grid plus a month-year wheel.
- Selection control (`calendar/date_selection_control.dart`): `FDateSelectionControl.none()` (display only, `:10`), `managedSingle({controller, initial, toggleable = true, onChange})` (`:13`), `managedMulti` (`:21`), `managedRange` (`:34`, complete range), `managedOpenRange({..., startFirst = true})` (`:51`), and lifted `liftedSingle({required value, required onChange, toggleable = true})` (`:63`), `liftedMulti` (`:73`), `liftedRange` (`:85`), `liftedOpenRange` (`:98`). Lifted controllers call `onChange` and wait for the parent to rebuild with the new value (`date_selection_controller.dart:103-128`).
- Navigation control `FCalendarControl` is sealed with managed variants only: `FGridCalendarControl/FGridSplitCalendarControl/FWheelCalendarControl({controller, selectable, start, today, initial, end})` (`calendar_control.dart:68-143`); no lifted navigation. Asserts: controller XOR the other params (`:58-61`). Defaults: `start` `DateTime.utc(1900)`, `end` `DateTime.utc(2100)` (`calendar_controller.dart:46-53`), `today` `DateTime.now()` truncated (`:61`), `selectable` always true (`:44`).
- Programmatic nav: `FGridCalendarController.cycle()`, `FGridSplitCalendarController.toggleMonthPicker/toggleYearPicker`, `animateTo/jumpTo DayPicker/MonthPicker/YearPicker([DateTime?])` (`calendar_controller.dart:128-229`, `:258-279`), `FWheelCalendarController.toggleMonthYearPicker/setMonthYear/animateToDayPicker` (`:310-373`).
- Dates: all UTC, truncated to the day; dates outside `[start,end]` are unselectable (class doc `calendar.dart:36-40`; docs callout `data/calendar.mdx:33-36`). `select(date)` truncates to UTC (`date_selection_controller.dart:9-24`). Convert local dates to `DateTime.utc(y,m,d)` before passing or comparing.
- Interaction states: `FCalendarDayVariant`: `single|start|middle|end` (selection), `adjacent`, `today`, `disabled`, `primaryFocused|focused|hovered|pressed` (`day/day.dart:11-25`). Non-selectable days are disabled.
- Focus & semantics: each day is `FTappable.static(selected:, semanticsLabel: DateFormat.yMMMMEEEEd(locale)` plus ", Hôm nay"/"Today" for today, `excludeSemantics: true)` (`day/day.dart:52-61`); header prev/next labels localised (`header.dart:62-65`, `localizations_vi.dart:45-75`). Page changes call `SemanticsService.sendAnnouncement(yMMMM)` (`day/day_picker.dart:91-95`). Own `FocusScopeNode` with `traversalEdgeBehavior: .parentScope` (`calendar.dart:387`). Swipe navigates pages on touch (class doc `:36-37`).
- Motion/reduced (cite): `_controller.reduceMotion(reduce: context.accessibility.motion != .all)` (`calendar.dart:395`, `:405`): under `reduced` OR `disabled` page animations become `jumpToPage` (`grid.dart:280-283`, `:379`); header chevron rotation duration is zero unless `motion == all` (`header.dart:337`). The class doc (`calendar.dart:470-474`) says reduced = "fade transitions", but the code jumps with no fade.
- Layout: width fixed at `7 * dayPickerStyle.daySize.width` (`calendar.dart:430`; day size `style.sizes.calendar` = 44 touch / 32 desktop, `theme/sizes.dart:46-47`) plus `FCalendarStyle.padding` 12 each side (`calendar.dart:495`), about 332dp plus border on touch (computed, not measured). Height follows week rows unless `fixedWeeks: true` (`:442-453`). First day of week = `FCalendarDayPickerStyle.firstDayOfWeek ?? localizations.firstDayOfWeek` (`localizations/localization.dart:36`).
- Styling: `FCalendarStyle({headerStyle, dayPickerStyle, monthPickerStyle, yearPickerStyle, wheelPickerStyle, decoration, padding = EdgeInsets.all(12)})` (`calendar.dart:475`), delta `FCalendarStyleDelta` (`calendar.design.dart:110`), `FThemeData.calendarStyle` (`theme_data.dart:135`). Custom cells: `FCalendarDayBuilder` (`day/day.dart:29`), `defaultDayBuilder/defaultMonthBuilder/defaultYearBuilder` (`calendar.dart:64-109`).
- Docs: `DOCS` + `data/calendar`.

### `FLineCalendar` — single horizontally scrolling row of dates
- Constructor: `const FLineCalendar({FLineCalendarControl control = const .managed(), FLineCalendarScrollControl scrollControl = const .managed(), FLineCalendarStyleDelta style, ScrollPhysics? physics, ScrollCacheExtent? scrollCacheExtent, ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = .manual, bool Function(DateTime) selectable = FCalendarController.defaultSelectable, ValueWidgetBuilder<FLineCalendarItemData> builder = defaultBuilder, Key? key})` (`line_calendar/line_calendar.dart:89`). Recommended for touch (`:25-27`).
- State/control:
  - `FLineCalendarControl.managed({FDateSelectionController<DateTime?>? controller, DateTime? initial, bool? toggleable, ValueChanged<DateTime?>? onChange})` (`line_calendar_controller.dart:69`); default `toggleable: false` (`:132`). Asserts controller XOR initial, controller XOR toggleable (`:120-127`).
  - `FLineCalendarControl.lifted({required DateTime? date, required ValueChanged<DateTime?> onChange})` (`:80`); the proxy ignores re-selecting the selected date (`:30-35`).
  - `FLineCalendarScrollControl.managed({FLineCalendarScrollController? controller, DateTime? start, end, today, initialDate, AlignmentDirectional? initialAlignment, ValueChanged<double>? onChange})` (`line_calendar_scroll_controller.dart:125`). No usable lifted scroll control (`_Lifted` throws `UnimplementedError`, `:203-211`, and no factory exposes it).
  - `FLineCalendarScrollController({initialAlignment = .center, start, end, today, initialDate, keepScrollOffset = true, debugLabel})` (`:41`): `animateToDate(date, {duration 300ms, curve easeOutCubic, alignment})`, `jumpToDate`. `start` default 1900; `end` is EXCLUSIVE and null = unbounded list (`:16-20`; `itemCount` null when end null, `calendar_layout.dart:129`). FCalendar's `end` is inclusive.
- Interaction states: `FLineCalendarItemVariant`: `disabled|selected|today|primaryFocused|focused|hovered|pressed` (`line_calendar.dart:14-22`).
- Focus & semantics: each item is `FTappable(semanticsLabel: yMMMMd [+ ", Today"], selected, semanticsInMutuallyExclusiveGroup: true, excludeSemantics: true, onPress: selectable(date) ? select : null)` (`line_calendar_item.dart:28-34`); unselectable dates have `onPress == null`. Weekday text from `localizations.shortWeekDays` (`:101`). Item height is measured by a speculative layout that includes text scale (`line_calendar.dart:110`, `calendar_layout.dart:109-117`).
- Motion: no widget-owned animation; no `accessibility.motion` reads in `line_calendar/` (rg result: none).
- Styling: `FLineCalendarStyle` (`line_calendar.dart:134`: variant-keyed `decoration`, `todayIndicatorColor`, `dateTextStyle`, `weekdayTextStyle`, `tappableStyle`, `itemSpacing` 10, `contentEdgeSpacing` 13, `contentSpacing` 4), delta `FLineCalendarStyleDelta` (`line_calendar.design.dart:234`), `FThemeData.lineCalendarStyle` (`theme_data.dart:273`). `builder` receives `FLineCalendarItemData = ({style, date, variants})` (`line_calendar_item.dart:9`).
- Docs: `DOCS` + `data/line-calendar` (Shift+scroll on desktop).

---

## 2. Overlays and portals

Shared overlay mechanics
- Route-based (`showFDialog`, `showFSheet`): `Navigator.of(context, rootNavigator: useRootNavigator)` (`widgets/dialog.dart:78`, `widgets/sheet/modal_sheet.dart:90`). Default `false`: under a nested navigator (e.g. a `StatefulShellRoute` branch) the overlay and its barrier cover only that navigator's area; pass `useRootNavigator: true` to cover the whole app including a bottom bar. Both capture the caller's `FTheme`, accessibility scope and adaptive scope into the new route (`dialog.dart:86-87`, `modal_sheet.dart:99-100`; `FTheme.capture` at `theme/theme.dart:145-155`).
- Barrier = `FModalBarrier`/`FAnimatedModalBarrier` (`foundation/barrier.dart`). Tap-up anywhere calls `onDismiss`; if `onDismiss == null` it plays `SystemSound.alert` instead (`:208-214`, gesture `:248-250`). Barrier semantics (label plus tap/dismiss action) exist only on Android/iOS/macOS and only when `onDismiss != null`; the label needs a non-null `semanticsLabel` (`:201-230`). Wrapped in `BlockSemantics` and `ExcludeSemantics(excluding: !including)` (`:245-247`). With `FAccessibilityMotion.disabled` an animated barrier filter is evaluated at 1.0 immediately (`:76`).
- Popover-family (`FPopover`, `FPopoverMenu`, `FContextMenu`, `FTooltip`) use `FPortal`/`FPointPortal` over Flutter `OverlayPortal`, so they need an `Overlay` ancestor (`foundation/overlay/portal.dart:220-283`); `overlayLocation` defaults to `nearestOverlay`. `FPortal` reads view padding from `View.of` and insets from `MediaQuery`, and rebuilds on metrics change (`:182-211`, `:228-233`). Source comment: semantics blocking by the barrier does not work correctly inside portals (`:256-261`).

### `showFDialog` / `FDialogRoute` / `FDialog`
- `Future<T?> showFDialog<T>({required BuildContext context, required Widget Function(BuildContext context, FDialogStyle style, Animation<double> animation) builder, bool useRootNavigator = false, FDialogRouteStyleDelta routeStyle = const .context(), FDialogStyleDelta style = const .context(), String? barrierLabel, bool barrierDismissible = true, RouteSettings? routeSettings, AnimationController? transitionAnimationController, Offset? anchorPoint, bool useSafeArea = false})` (`widgets/dialog.dart:63-75`). Asserts MediaQuery (`:76`).
  - `transitionAnimationController` is declared but never forwarded to `FDialogRoute` (body `:78-95`): it is ignored.
  - `useSafeArea` defaults false here, but `FDialogRoute`'s own default is true (`:127`).
  - Barrier label default `FLocalizations.barrierLabel`; tap hint `barrierOnTapHint(dialogSemanticsLabel)` (`:89-90`). See Gaps for the vi strings.
- `FDialogRoute<T> extends RawDialogRoute<T>` (`:101`): `new({required FDialogRouteStyle style, required builder(context, animation), bool barrierDismissible = true, String? barrierLabel, String? barrierOnTapHint, FCapturedTheme? capturedFTheme, CapturedThemes? capturedThemes, bool useSafeArea = true, settings, requestFocus, anchorPoint, traversalEdgeBehavior, directionalTraversalEdgeBehavior})` (`:119-133`).
  - Barrier tap: `onDismiss: barrierDismissible ? () => Navigator.pop(context) : null` (`:153`, `:164`). With `barrierDismissible: false` the tap only plays `SystemSound.alert` (`barrier.dart:208-214`; test `TESTS dialog/dialog_test.dart:10-38`). The pop carries no result (future completes with `null`).
  - System/Android back is the default `ModalRoute` pop: no `PopScope`/`WillPop` anywhere in the forui lib (rg: none); `barrierDismissible` does not guard it.
  - Barrier colour is `Colors.transparent` (`:184-185`); dimming/blur comes from `FDialogRouteStyle.barrierFilter` (default blur sigma 5 plus tint `colors.barrier`, `:208-215`). If `barrierFilter == null` there is no scrim at all and a non-animated `FModalBarrier` is used (`:160-171`).
  - `buildTransitions` returns the child untouched (`:176-182`); route durations 150ms in/out, barrier curve `Curves.ease` (`:190-194`, `:219-232`). All visible motion is inside `FDialog`, and only if the builder passes it `animation`.
  - `FDialogRouteStyle({ImageFilter Function(BuildContext, double)? barrierFilter, FDialogRouteMotion motion})` (`:198`), `FThemeData.dialogRouteStyle` (`theme_data.dart:205`).
- `FDialog` (`:255`) has no title/body/actions parameters; layout is entirely caller-supplied (docs: "does not provide a built-in content layout", `DOCS overlay/dialog`):
  - `const FDialog({required Widget Function(BuildContext context, FDialogStyle style) builder, FDialogStyleDelta style = const .context(), Clip clipBehavior = .none, Animation<double>? animation, String? semanticsLabel, BoxConstraints constraints = const BoxConstraints(minWidth: 280, maxWidth: 560), bool resizeToAvoidInsets = true, Key? key})` (`:320-329`). There is no separate "raw" constructor in 0.27.6; this builder form is the raw one.
  - `FDialog.adaptive({required horizontalBuilder, required verticalBuilder, style, clipBehavior, animation, semanticsLabel, constraints, resizeToAvoidInsets, key})` (`:342-355`): uses `verticalBuilder` when `MediaQuery.sizeOf(context).width < context.theme.breakpoints.sm` (640, `theme/breakpoints.dart:49`), else `horizontalBuilder`. This is the only "direction" switch; action widgets and the Row/Column layout are the caller's (CLI snippet `forui_cli/tool/snippets/literals/dialog/adaptive_dialog.dart`: `Row(Expanded(action))` on touch-horizontal, `Column(actions)` vertical).
  - `FDialogAxisVariant` (`horizontal|vertical`) is generated (`dialog.dart:14-17`, `dialog.design.dart:64`) but referenced nowhere else in lib (rg): unused by the widget.
- Semantics: `Semantics(scopesRoute: true, explicitChildNodes: true, namesRoute: true, label: widget.semanticsLabel)` (`:483-489`). `semanticsLabel` defaults to null, so the dialog route is unnamed unless the caller passes one.
- Keyboard/insets: `AnimatedPadding` of `viewInsets + insetPadding (h40 v24)` with `MediaQuery.removeViewInsets` (`:468-479`); `resizeToAvoidInsets` toggles it (`:470`). Width clamp via `constraints` (default 280-560).
- Motion: only when `animation != null` (`:385-407`): fade unless `motion == disabled` (`:437`), scale 0.95 -> 1 only when `motion == all` (`:464`); so `reduced` = fade only, `disabled` = none (matches class doc `:555-557`). With `animation: null` the dialog simply appears. `backgroundFilter` requires `animation` (`:513`).
- Styling: `FDialogStyle({decoration, titleTextStyle, bodyTextStyle, slidePressHapticFeedback, backgroundFilter, insetPadding = h40 v24, motion})` (`:498`), delta `FDialogStyleDelta` (`dialog.design.dart:385`), `FThemeData.dialogStyle` (`theme_data.dart:215`).
- Evidence/docs: tests `TESTS dialog/dialog_test.dart` (barrier tap, resizeToAvoidInsets, scope capture); `DOCS overlay/dialog`.

### `showFSheet` / `FModalSheetRoute` — modal sheet from any edge
- `Future<T?> showFSheet<T>({required BuildContext context, required WidgetBuilder builder, required FLayout side, bool useRootNavigator = false, FModalSheetStyleDelta style = const .context(), double? mainAxisMaxRatio = 9 / 16, bool useSafeArea = false, bool resizeToAvoidBottomInset = true, String? barrierLabel, bool barrierDismissible = true, BoxConstraints constraints = const BoxConstraints(), bool draggable = true, RouteSettings? routeSettings, AnimationController? transitionAnimationController, Offset? anchorPoint, VoidCallback? onClosing})` (`widgets/sheet/modal_sheet.dart:70-87`). `FLayout` = `ltr|rtl|ttb|btt` (`foundation/rendering.dart:6-18`).
- `FModalSheetRoute<T> extends PopupRoute<T>` (`:133`, ctor `:225-243`).
- Size: for `btt/ttb` the sheet is forced to full width and `maxHeight = constraints.maxHeight * mainAxisMaxRatio` (null = full); for `ltr/rtl` it is full height with `maxWidth * ratio` (`sheet/shifted_sheet.dart:110-121`). Doc: set the ratio to null if the child has a main-axis scrollable (`modal_sheet.dart:28-31`). A short child shrink-wraps (`Align` heightFactor 1, `sheet.dart:116-124`).
- Barrier: `style.barrierFilter` default = tint only, no blur (`modal_sheet.dart:370-374`; theme default `.inherit()`, `theme_data.dart:693`). Tap -> `Navigator.pop(context)` when `barrierDismissible` (`:298`, `:310`); this path does NOT call `onClosing`. Barrier semantics are clipped to exclude the sheet area via `_clipDetailsNotifier` (`:271-276`, `barrier.dart:241-243`). Test: `TESTS sheet/modal_sheet_test.dart:10-37`.
- Drag-to-dismiss mechanics (`sheet/sheet.dart`, `sheet/gesture_detector.dart`):
  - `draggable` wraps the sheet in `SheetGestureDetector` (`RawGestureDetector`; vertical recogniser for `btt/ttb`, horizontal for `ltr/rtl`; `onlyAcceptDragOnThreshold = true`; `excludeFromSemantics: true`, `gesture_detector.dart:22-45`), so dragging offers no screen-reader action; a11y dismissal is via barrier semantics (Android/iOS) or back.
  - Drag updates the route's animation controller value directly (`sheet.dart:200-221`); on release a fling faster than `style.flingVelocity` (700) closes/opens in the fling direction, else it closes if `controller.value < style.closeProgressThreshold` (0.5), else springs back (`:223-260`, defaults `:282-293`). Closing calls `onClosing?.call()` then `Navigator.pop(context)` if `isCurrent` (`modal_sheet.dart:277-282`).
  - `draggable: true` asserts a controller (`sheet.dart:43`); routes use their own controller (`modal_sheet.dart:260`).
  - A child `DraggableScrollableSheet` reaching min extent also triggers `onClosing` (`sheet.dart:127-134`).
  - System back and barrier tap close the route without `onClosing`.
- Insets: `resizeToAvoidBottomInset` lifts the sheet by `viewInsets.bottom`, only for `btt` (`shifted_sheet.dart:122-127`, `sheet.dart:188`). `useSafeArea` false by default: the sheet extends under the system nav bar and `MediaQuery.removePadding` strips the opposite-side padding so an inner `SafeArea` has no effect there (`modal_sheet.dart:183-193`, `sheet.dart:157-166`); content needs its own bottom padding.
- Semantics: `Semantics(scopesRoute: true, namesRoute: true, explicitChildNodes: true, label: sheetSemanticsLabel` except null on iOS/macOS) (`sheet.dart:174-181`). Barrier hint uses `sheetSemanticsLabel` (`modal_sheet.dart:101`).
- Motion/reduced (cite): expand/collapse 200ms `easeOutCubic` (`sheet.dart:307-317`); the route uses those durations unless a `transitionAnimationController` is passed, which overrides them (`modal_sheet.dart:38-39`, `:245-255`). In `build`: `value: !_dragging && motion != .all ? 1.0 : progress` (the sheet does not slide under reduced/disabled) and `Opacity(!_dragging && motion == .reduced ? progress : 1.0)` (fade only under `reduced`, nothing under `disabled`) (`sheet.dart:187-191`). Drag-dismiss still tracks the finger under reduced/disabled (test `TESTS sheet/modal_sheet_test.dart:44-92`). Barrier filter jumps to full under `disabled` (`barrier.dart:76`).
- Styling: `FModalSheetStyle({barrierFilter, motion: FModalSheetMotion, flingVelocity = 700, closeProgressThreshold = 0.5})` (`modal_sheet.dart:357`), `FModalSheetMotion({barrierCurve = easeOutCubic, expandDuration, collapseDuration, curve})` (`:378`), delta `FModalSheetStyleDelta` (`modal_sheet.design.dart:83`), `FThemeData.modalSheetStyle` (`theme_data.dart:292`).
- Docs: `DOCS overlay/sheet`. Tests `TESTS sheet/modal_sheet_test.dart`.

### `showFPersistentSheet` / `FSheets` / `FPersistentSheetController` — non-modal sheet
- `FPersistentSheetController showFPersistentSheet({required BuildContext context, required FLayout side, required Widget Function(BuildContext context, FPersistentSheetController controller) builder, FPersistentSheetStyleDelta style = const .context(), double? mainAxisMaxRatio = 9 / 16, BoxConstraints constraints = const BoxConstraints(), bool draggable = true, Offset? anchorPoint, bool useSafeArea = false, bool resizeToAvoidBottomInset = true, bool keepAliveOffstage = false, VoidCallback? onClosing, Key? key})` (`sheet/persistent_sheet.dart:76-90`), annotated `@useResult`.
- Required ancestor: `FSheets` or `FScaffold` (`FScaffold` builds `FSheets`, `widgets/scaffold.dart:114`). Found by `context.findAncestorStateOfType<FSheetsState>()`; otherwise throws `FlutterError` (`persistent_sheet.dart:91-106`; test `TESTS sheet/persistent_sheet_test.dart:83`). A duplicate `key` throws (`:274-285`); the auto key is random (`:108`). Sheets render in a `Stack` over `FSheets.child` (`:253-266`); inside `FScaffold` that child is the whole scaffold row, so sheets cover header and footer too (`scaffold.dart:114-135`).
- Controller: `show()`, `toggle()`, `hide()` (all `TickerFuture`), `status`, `dispose()`, public `setState`/`key`/`keepAliveOffstage` (`persistent_sheet.dart:155-218`). It must be disposed or sheets accumulate (`:18-19`). A hidden sheet is dropped from the tree unless `keepAliveOffstage` (`:257`), but its map entry stays until `dispose()`.
- No barrier, no route, no back-button integration; the rest of the app stays interactive. `Escape` runs `controller.reverse` (`:259`; does not call `onClosing`); focus traversal into the sheet is enabled only while `status.isCompleted` (`:260-264`). Drag-to-dismiss uses the same `Sheet` logic as the modal sheet and calls `onClosing` (`:141`, `sheet.dart:257-258`); it hides the sheet but does not dispose the controller.
- Semantics: same `Sheet` semantics (`scopesRoute`, `namesRoute`) as the modal sheet (`sheet.dart:174-181`).
- Motion/reduced: same as the modal sheet (`sheet.dart:168-191`). Style `FPersistentSheetStyle({FPersistentSheetMotion motion, flingVelocity = 700, closeProgressThreshold = 0.5})` (`persistent_sheet.dart:313-324`), `FThemeData.persistentSheetStyle` default `const FPersistentSheetStyle()` (`theme_data.dart:696`), delta `FPersistentSheetStyleDelta` (`persistent_sheet.design.dart:73`).
- Docs: `DOCS overlay/persistent-sheet` (warns calls must be under `FScaffold`/`FSheets`).

### `FPopover` — anchored rich-content popup
- Constructor: `const FPopover({required Widget Function(BuildContext, FPopoverController) popoverBuilder, FPopoverControl control = const .managed(), FPopoverStyleDelta style, FPortalConstraints constraints = const FPortalConstraints(), FPortalSpacing spacing = const .spacing(4), FPortalOverflow overflow = .flip, FPortalArrowAlignment? arrow, bool useViewPadding = true, bool useViewInsets = true, OverlayChildLocation overlayLocation = .nearestOverlay, Offset offset = .zero, Object? groupId, FPopoverHideRegion hideRegion = .excludeChild, VoidCallback? onTapHide, bool? autofocus, FocusScopeNode? focusNode, FocusNode? childFocusNode, ValueChanged<bool>? onFocusChange, TraversalEdgeBehavior? traversalEdgeBehavior, bool traversalGrouped = true, String? barrierSemanticsLabel, bool barrierSemanticsDismissible = true, bool cutout = true, void Function(Path, Rect) cutoutBuilder, String? semanticsLabel, Map<ShortcutActivator, VoidCallback>? shortcuts, ValueWidgetBuilder<FPopoverController> builder = defaultBuilder, Widget? child, AlignmentGeometry? popoverAnchor, AlignmentGeometry? childAnchor, Clip popoverClipBehavior = .none, Key? key})` (`popover/popover.dart:310-342`). Asserts: `groupId` needs `hideRegion == excludeChild`; `focusNode` XOR `traversalEdgeBehavior`; `builder` or `child` required (`:343-351`).
- Default placement depends on platform: touch -> `popoverAnchor: bottomCenter`, `childAnchor: topCenter` (the popover opens ABOVE the trigger); otherwise below (`:463-464`, doc `:96-110`).
- State/control (`popover_controller.dart`): `FPopoverControl.managed({FPopoverController? controller, bool? initial, ValueChanged<bool>? onChange})` (`:182`, asserts controller XOR initial `:223-226`) and `FPopoverControl.lifted({required bool shown, required ValueChanged<bool> onChange})` (`:189`; `show()/hide()` on the proxy only call `onChange`, the state change happens after the parent rebuilds via a post-frame callback, `:143-175`). `FPopoverController({required TickerProvider vsync, bool shown = false})` with `show/hide/toggle({bool animated = true})` and `status` (`:28-102`). Hiding removes the content from the tree, so stateful descendants lose state (`:76-78`).
- Hide behaviour: `FPopoverHideRegion.anywhere | excludeChild | none` (`popover.dart:21-37`). With the default (`barrierFilter == null`) outside taps are handled by `TapRegion.onTapOutside` on the popover and, for `excludeChild`, on the child (`:468-473`, `:537-539`). Escape closes it from trigger focus or content (`:480-489`, `:587-596`; override via `shortcuts`). `onTapHide` fires on outside-tap and Escape hides, not on programmatic `hide()` (`_hide` `:605-612`). Nested popovers/dropdowns need a shared `groupId` (doc `:41-48`).
- Barrier: none by default; present only if `FPopoverStyle.barrierFilter != null` (`:504-518`), then a dismissing `FAnimatedModalBarrier` (optional cutout over the trigger) is drawn and `autofocus` defaults true (`:534`).
- Focus & semantics: `FocusScope(node: _focusNode, autofocus: widget.autofocus ?? (barrierFilter != null))` around content (`:533-535`); `childFocusNode` is refocused on Escape (`:484`, `:593`). Content is `Semantics(label: semanticsLabel, container: true)` (`:530-532`); no role.
- Motion/reduced (cite): fade unless `motion == disabled` (`:554-556`); scale 0.93 -> 1 only when `motion == all` (`:558-564`); 100ms (`:714-738`). `FPopoverMotion.none` exists (`:743`).
- Styling: `FPopoverStyle({decoration, barrierFilter, backgroundFilter, popoverPadding = EdgeInsets.all(5), arrowStyle, motion})` (`:616-690`), delta `FPopoverStyleDelta` (`popover.design.dart:102`), `FThemeData.popoverStyle` (`theme_data.dart:335`). Default decoration has a shadow (`:703`).
- Limitations: an arrow needs `spacing >= arrow height` (doc `:117-118`).
- Docs: `DOCS overlay/popover`.

### `FPopoverMenu` / `FSubmenuItem` / `FSubmenuTile` — popover with item/tile menu
- Constructors (`popover_menu/popover_menu.dart`): `FPopoverMenu({control, scrollController, style: FPopoverMenuStyleDelta, scrollCacheExtent, maxHeight = double.infinity, intrinsicWidth = true, dragStartBehavior = .start, physics = const ClampingScrollPhysics(), divider = FItemDivider.full, menuAnchor = .topCenter, childAnchor = .bottomCenter, spacing = .spacing(4), overflow = .flip, arrow, useViewPadding = true, useViewInsets = true, overlayLocation, offset, groupId, hideRegion = .excludeChild, onTapHide, barrierSemanticsLabel, barrierSemanticsDismissible = true, cutout = true, cutoutBuilder, semanticsLabel, autofocus, focusNode, childFocusNode, onFocusChange, traversalEdgeBehavior, bool? faded, menuBuilder = defaultItemBuilder, List<FItemGroupMixin>? menu, builder = FPopover.defaultBuilder, Widget? child, key})` (`:239`) and `FPopoverMenu.tiles(...)` with `List<FTileGroupMixin>` (`:313`). Asserts: builder or child; menuBuilder or menu (`:279-296`).
- Unlike `FPopover`, anchors default to the menu's top below the child on every platform (`menuAnchor: topCenter`, `childAnchor: bottomCenter`, `:249-250`).
- Built on `FPopover` (`:493-554`): same control type (`FPopoverControl`), hide behaviour and focus handling; width clamp `style.minWidth` 150 / `maxWidth` 250 (`:497`, `:571-581`).
- Item press does NOT close the menu: `FInheritedItemCallbacks` only resets the active submenu (`:527-531`) and no `hide` call exists in `popover_menu/`, `item/` or `tile/` except submenu triggers (rg result). Close from an item's `onPress` via `controller.hide()`.
- Keyboard: arrow up/down/home/end move focus; left (right in RTL) closes a submenu (`:470-491`, `menu_navigation.dart`). Semantics: `Semantics(container: true, role: .menu)`; items get `semanticsRole: .menuItem` (`:518-532`).
- Submenus: `FSubmenuItem({required title, required List<FItemGroupMixin> submenu, ...})` (`submenu_item.dart:183`), `FSubmenuTile` (`submenu_tile.dart:180`); submenu anchors default to side-by-side on desktop and below on touch (`submenu_item.dart:320-321`). `faded` (default true on touch) dims the parent menu to `menuMotion.fade` 0.4 while a submenu is active (`popover_menu.dart:462`, `:540-545`).
- Styling: `FPopoverMenuStyle` extends `FPopoverStyle` (`:560`: `itemGroupStyle`, `tileGroupStyle`, `hapticFeedback`, `minWidth`, `maxWidth`, `hoverEnterDuration` 150ms, `menuMotion: FPopoverMenuMotion`), delta `FPopoverMenuStyleDelta` (`popover_menu.design.dart:152`), `FThemeData.popoverMenuStyle` (`theme_data.dart:345`). Items and tiles inherit that style, not the app's global item/tile styles (explicit `FInheritedItemData` boundary, `:533-537`).
- Docs: `DOCS overlay/popover-menu`.

### `FContextMenu` — menu at the pointer
- Constructors: `FContextMenu({control, style: FPopoverMenuStyleDelta, scrollController, scrollCacheExtent, maxHeight, intrinsicWidth, dragStartBehavior, divider, menuAnchor = .topLeft, double spacing = 0, overflow, useViewPadding, useViewInsets, overlayLocation, offset, groupId, hideRegion = .excludeChild, onTapHide, barrierSemanticsLabel, barrierSemanticsDismissible, cutout = false, cutoutBuilder, semanticsLabel, autofocus, focusNode, onFocusChange, traversalEdgeBehavior, bool? faded, bool? longPress, bool? secondaryPress, builder, child, menuBuilder, List<FItemGroupMixin>? menu, key})` (`widgets/context_menu.dart:165`) and `.tiles(...)` (`:224`).
- Triggers: long press when `longPress ?? touch` (haptic then show, `:423-431`); secondary mouse button when `secondaryPress ?? !touch` (`:412-415`); keyboard Shift+F10 / Ctrl+Enter (macOS) / Menu key opens it below the focused descendant (`:442-463`, class doc `:18-20`). A primary pointer-down anywhere in the child hides it (`:416-418`). Web needs `BrowserContextMenu.disableContextMenu()` (doc `:22-24`).
- Hide: Escape (`:449`, `:464`), outside tap per `hideRegion` (`:434-440`). `onTapHide` is not called for programmatic hides (`_hide` `:591-596`). Items do not auto-close the menu (same item callbacks as `FPopoverMenu`, `:518-523`).
- Control: `FPopoverControl` (same type as `FPopover`); uses `FPointPortal` at the gesture point (`:467-478`).
- Semantics: `Semantics(label, container: true, role: .menu)` (`:495-498`); autofocus defaults true and focus is requested after the first frame when shown (`:380-390`, `:500`).
- Motion/reduced: fade unless disabled, scale only when `all` (`:548-554`), durations from `FPopoverMenuStyle.motion` (100ms).
- Styling: `FPopoverMenuStyle` via `FThemeData.popoverMenuStyle` (`:342`).
- Docs: `DOCS overlay/context-menu`.

### `FToaster` / `FToast` / `showFToast` / `showRawFToast`
- Required ancestor: `FToaster`. `showFToast`/`showRawFToast` look up `context.findAncestorStateOfType<FToasterState>()` and throw `FlutterError` if absent (`widgets/toast/toaster.dart:50-65`, `:126-141`). Nothing in the package places an `FToaster` for you (rg: only the doc comment `toaster.dart:253`; `FScaffold` provides `FSheets` only). Recommended placement: `MaterialApp.builder: (context, child) => FTheme(data: ..., child: FToaster(child: child!))` (`toaster.dart:247-257`; docs `overlay/toast.mdx:27-41`), i.e. above the `Navigator`, so toasts can paint over dialogs/sheets and `showFToast` works with any context below it.
- `FToaster({required Widget child, FToasterStyleDelta style = const .context(), Key? key})` (`:293`). Build: `Overlay.wrap(child: Stack(clipBehavior: .none, fit: .passthrough, children: [child, one Positioned.fill(SafeArea(Padding(style.padding, Align(alignment, ToasterStack)))) per active alignment]))` (`:389-412`). `FToasterState.show` returns the entry without displaying anything when `!mounted` (`:348-350`). `SafeArea` covers view padding only; no `viewInsets` handling exists in `toast/` (rg), so bottom-aligned toasts are not lifted above the keyboard.
- API:
  - `FToasterEntry showFToast({required BuildContext context, required Widget title, FToastVariant variant = .primary, FToastStyleDelta style = const .context(), Widget? icon, Widget? description, Widget Function(BuildContext, FToasterEntry)? suffixBuilder, FToastAlignment? alignment, List<AxisDirection>? swipeToDismiss, double dismissThreshold = 0.5, Duration? duration = const Duration(seconds: 5), VoidCallback? onDismiss})` (`:36-49`).
  - `FToasterEntry showRawFToast({required context, required Widget Function(BuildContext, FToasterEntry) builder, variant, style, alignment, swipeToDismiss, dismissThreshold, duration, onDismiss})` (`:115-125`): same params, caller supplies the whole toast widget.
  - `FToasterEntry` mixin: `dismiss()` (no-op if already dismissing/dismissed) and `bool get showing` (`:417-423`, impl `:440-449`). No update/replace API; to change content, dismiss and show again.
  - `FToast({required Widget title, FToastVariant variant = .primary, FToastStyleDelta style, Clip clipBehavior = .none, Widget? icon, Widget? description, Widget? suffix, Key? key})` (`toast.dart:70`); title and description `maxLines: 100` (`:99-101`). Variants `FToastVariant.primary|destructive` (`toaster_style.dart:12`, `toaster_style.design.dart:63`).
  - `FToastAlignment`: constants `topStart, topEnd, topLeft, topRight, topCenter, bottomStart, bottomEnd, bottomLeft, bottomRight, bottomCenter` plus `FToastAlignment(AlignmentGeometry, double toastAlignment)` (`toaster.dart:157-228`). Default `FToasterStyle.toastAlignment`: `topCenter` on touch, `bottomEnd` otherwise (`toaster_style.dart:74`, `:83`).
- `swipeToDismiss` default derives from alignment: `y<0 -> up`, `y>0 -> down`, `x<0 -> left`, `x>0 -> right`; so `topCenter` = `[up]`, corners = both axes (`toaster.dart:334-339`; tests `TESTS toast/toaster_test.dart:78-117`). An empty list disables swiping. Assert `0 <= dismissThreshold <= 1` (`:328`). Threshold is a fraction of the toast size (`animated_toast.dart:338-345`, `:365-369`).
- Duration: auto-dismiss is a `Timer(duration, ...)` started in `initState` (`animated_toast.dart:122-124`); `duration: null` disables it. The timer is NOT extended or suppressed for `accessibleNavigation`: tests show the toast still auto-dismisses with a screen reader on, and persists only with `duration: null` (`TESTS toast/toaster_test.dart:698-775`). The timer is cancelled by hover, drag start, or pause (below).
- Pause/expand behaviour and the stack's GestureDetector (`toast/toaster_stack.dart`):
  - `:116` `MouseRegion`, `:119-127` `GestureDetector(onTap: ...)` wraps the entire `AnimatedToaster`. `onTap` runs only if `!_hovered` (touch, or a tap without a hovering mouse): `setState(() => _autoDismiss = !_autoDismiss)` and, when `expandBehavior == hoverOrPress`, toggles expansion (`:120-125`).
  - `_autoDismiss == false` cancels every toast's timer (`animated_toast.dart:216-221`); a second tap resumes with a 300ms stagger per index (`:218`). Net effect: on touch, tapping a toast (anywhere not consumed by a child tap target) makes the whole stack sticky until another tap or until the stack empties (`toaster_stack.dart:151-156` resets `_autoDismiss = true` when empty). Verified by tests `press stops auto-close` for all three `FToasterExpandBehavior` values (`TESTS toast/toaster_test.dart:121-225`, `:193-224`) and `press pauses again after all toasts are swiped away while paused` (`:227-252`). No style flag disables this tap-to-pause toggle (the `onTap` branch is unconditional, `toaster_stack.dart:120-126`).
  - Semantics consequence (derived from Flutter source, not executed): a `GestureDetector` with `onTap` and default `excludeFromSemantics: false` installs a `RenderSemanticsGestureHandler` that sets `config.onTap` (Flutter 3.47.5 `widgets/gesture_detector.dart:1488-1591`, `rendering/proxy_box.dart:4195-4235`), so the stack gets an unlabeled tappable semantics node above the toast nodes; each `AnimatedToast`'s `GestureDetector` also installs scroll up/down/left/right semantic actions (`animated_toast.dart:319-373`, same mechanism). UNVERIFIED: how TalkBack/VoiceOver present these; no semantics test covers them (`TESTS toast/toaster_test.dart:606-629` checks only live region plus dismiss).
  - Hover: `_enter/_exit` use `expandHoverEnterDuration/ExitDuration` (200ms) (`toaster_stack.dart:165-192`).
- Toast semantics (cite): each toast is `Semantics(container: true, liveRegion: widget.visible, onDismiss: widget.visible ? _startDismissing : null)` (`animated_toast.dart:378-383`; test `TESTS toast/toaster_test.dart:606-629`), so assistive tech announces it and can dismiss it. Toasts over `max` are wrapped in `IgnorePointer` (`:308-309`) and fully transparent. Under `accessibleNavigation` the dismiss animation is skipped (value snapped to 0, `:252-257`) and entrance slide/fade become instant (`:291-299`).
- Expand behaviour: `FToasterExpandBehavior.always | hoverOrPress (default) | disabled` (`toaster_style.dart:17-26`). `always` sets the controller to 1 at init (`toaster_stack.dart:58-60`); `disabled` never expands. Visible toasts per alignment: `max` = 3 (`toaster_style.dart:34`, `toaster_stack.dart:145`).
- Motion/reduced (cite): `_reduceMotion = accessibleNavigation || motion != all` in the stack (`toaster_stack.dart:66-69`, durations zero) and in each toast (`animated_toast.dart:292-305`: no slide, opacity snaps to visible?1:0, no stacking transition). So `reduced`, `disabled` and screen-reader mode all collapse toast motion, unlike the spinner/progress widgets. Defaults: entrance 400ms, dismiss 300ms, swipe completion 150ms, expand 400ms / collapse 300ms (`toaster_style.dart:128-308`).
- Styling: `FToasterStyle({required FToastStyles toastStyles, double max = 3, EdgeInsetsGeometry padding = h20 v15, FToasterExpandBehavior expandBehavior = hoverOrPress, expandHoverEnterDuration/ExitDuration = 200ms, expandStartSpacing = 0, expandSpacing = 10, collapsedProtrusion = 12, collapsedScale = 0.9, FToasterMotion motion, FToastAlignment toastAlignment = bottomEnd})` (`:29-75`); `FToastStyle({decoration, iconStyle, titleTextStyle, descriptionTextStyle, padding, constraints = BoxConstraints(maxHeight: 250, maxWidth: 400), backgroundFilter, iconSpacing = 10, titleSpacing = 1, suffixSpacing = 12, FToastMotion motion})` (`:146-205`); deltas `FToasterStyleDelta` (`toaster_style.design.dart:230`), `FToastStyleDelta` (`:580`); `FThemeData.toasterStyle` (`theme_data.dart:445`). Toast size is capped at 400w x 250h by default.
- Limitations: one `FToaster` style for all toasts (resolved at `show`, `toaster.dart:332`); per-toast styling only via the `style:` delta; the toast itself is non-interactive apart from its children and the swipe/tap handlers; the unconditional tap-to-pause cannot be replaced.
- Docs: `DOCS overlay/toast`.

### `FTooltip` — overlay aspects only
- `const FTooltip({required Widget Function(BuildContext, FTooltipController) tipBuilder, FTooltipControl control = const .managed(), FTooltipStyleDelta style, AlignmentGeometry tipAnchor = .bottomCenter, AlignmentGeometry childAnchor = .topCenter, FPortalSpacing spacing = const .spacing(7), FPortalOverflow overflow = .flip, FPortalArrowAlignment? arrow = .childCenter, bool? hover, bool? longPress, bool useViewPadding = true, bool useViewInsets = true, OverlayChildLocation overlayLocation = .nearestOverlay, ValueWidgetBuilder<FTooltipController> builder = defaultBuilder, Widget? child, Key? key})` (`widgets/tooltip/tooltip.dart:139-156`). Control: `FTooltipControl.managed({controller, initial, onChange})` / `.lifted({required shown, required onChange})` (`tooltip_controller.dart:178`, `:185`). `FTooltipGroup` shares style/hover/longPress and a 300ms warm-up (`tooltip_group.dart`).
- Portal: `FPortal` over `OverlayPortal` (needs an `Overlay`); the tip opens ABOVE the child by default on all platforms (`tipAnchor: bottomCenter`, `childAnchor: topCenter`). No barrier: pointer-down on the child hides it (`Listener(onPointerDown: _exit)`, `tooltip.dart:263`); the tip stays while hovered (WCAG 1.4.13, `:350-353`).
- Triggers: hover (500ms enter, 100ms exit) and long press (shown while pressed, hides 1500ms after release, haptic) (`tooltip.dart:257-285`, defaults `:440-449`); focus shows it when a descendant has primary focus (`_toggle`, `:362-380`); Escape hides it (`:238-241`).
- Semantics: the tip is wrapped in `Semantics(container: true)` only; no label link to the child (`:333`). Motion: fade unless disabled, scale 0.93 -> 1 only when `all` (`:321-331`), 100ms.
- Styling: `FTooltipStyle` (`:409-450`), delta `FTooltipStyleDelta` (`tooltip.design.dart:142`), `FThemeData.tooltipStyle` (`theme_data.dart:535`).
- Docs: `DOCS overlay/tooltip`.

---

## Gaps / surprises

1. `FToaster` tap-to-pause is unconditional on touch (`toast/toaster_stack.dart:119-127`, confirmed by test `press stops auto-close`): tapping a toast cancels auto-dismiss for the whole stack until the next tap. No style flag turns it off; only `duration: null` or avoiding taps changes the outcome.
2. `FToaster` is not provided by `FTheme`/`FScaffold`; the app must add it (above the `Navigator` to cover dialogs). `showFToast` without it throws. `FScaffold` only brings `FSheets` (`widgets/scaffold.dart:114`).
3. Toast timers ignore screen readers: auto-dismiss still fires after 5s with `accessibleNavigation` on (`TESTS toast/toaster_test.dart:698-775`). A persistent message needs `duration: null` plus a dismiss path; toast semantics offer a `dismiss` action and a live region (`animated_toast.dart:378-383`).
4. Reduced-motion handling is inconsistent across the family. `FCircularProgress`, `FProgress`, `FDeterminateProgress` only stop/skip on `disabled` (iOS "Reduce Motion" = `reduced` keeps spinning: `circular_progress.dart:141`, `progress.dart:98`, `determinate_progress.dart:96`). Accordion, toaster and calendar paging use `motion != all` (`accordion_item.dart:129`, `toaster_stack.dart:66`, `calendar.dart:395`). Dialog, popover, tooltip and sheets use a three-way split (`reduced` = fade, `disabled` = none: `dialog.dart:437/464`, `popover.dart:554/558`, `sheet.dart:187/191`). The calendar class doc says "reduced: fade", but the code jumps pages.
5. `showFDialog`'s `transitionAnimationController` parameter is ignored (`widgets/dialog.dart:72` vs body `:78-95`). `showFDialog.useSafeArea` defaults false while `FDialogRoute.useSafeArea` defaults true. A dialog animates only if the builder forwards `animation` to `FDialog` (`FDialog.animation` default null, `:288`).
6. `FDialog` has no title/actions API and no "raw" constructor beyond `builder`; `FDialogAxisVariant` is generated but unused (rg).
7. `useRootNavigator` defaults to false for `showFDialog` and `showFSheet`; with nested navigators (shell routes) the overlay and its barrier are scoped to that navigator unless `useRootNavigator: true`.
8. Modal sheet `onClosing` fires only for drag/fling dismiss (and `DraggableScrollableNotification`), not for barrier tap, back or Escape (`modal_sheet.dart:277-282` vs `:298`); the persistent sheet's Escape also skips it (`persistent_sheet.dart:259`). Dragging has no semantics action (`gesture_detector.dart:31`).
9. Modal sheet `useSafeArea` defaults false: content runs under the system navigation bar and an inner `SafeArea` is neutralised on the opposite side (`modal_sheet.dart:183-193`). `mainAxisMaxRatio` defaults to 9/16.
10. Localisation defects in `vi` (and 77 other non-English locales): `barrierOnTapHint` returns `'Đóng \$modalRouteContentName'` with an escaped `$` (`localizations/localizations_vi.dart:20`; the same pattern is in 78 of 79 locale files, `rg -l 'return .*\\\$modalRouteContentName'`), so the dialog/sheet/popover barrier hint reads the literal text "$modalRouteContentName" instead of the interpolated name. `barrierLabel` is the English "Scrim" in `vi` (`:16`). These strings feed the barrier `semanticsLabel`/`onTapHint` (`dialog.dart:89-90`, `modal_sheet.dart:101-102`, `popover.dart:513-515`); barrier semantics exist only on Android/iOS/macOS (`barrier.dart:201-206`).
11. `FPopover` default placement on touch is ABOVE the trigger (`popover.dart:463-464`), and `FTooltip` is above on all platforms, but `FPopoverMenu` defaults below on every platform (`popover_menu.dart:249-250`).
12. `FPopoverMenu`/`FContextMenu` items never close the menu on press; the caller must call `controller.hide()`. `onTapHide` runs only for outside-tap/Escape hides.
13. `FPopover` lifted control applies state changes asynchronously via a post-frame callback (`popover_controller.dart:152-167`), and hidden popover content is disposed (`:76-78`).
14. `FCalendar` has no plain constructor (only `grid`, `splitGrid`, `wheel`); its navigation control has no lifted form; every date is UTC midnight; range ends are inclusive here but `FLineCalendarScrollController.end` is exclusive. Fixed width of 7 x day size plus 24dp padding (about 332dp on touch, `calendar.dart:430`).
15. `FLineCalendarScrollControl` has no lifted variant (private `_Lifted` throws `UnimplementedError`, `line_calendar_scroll_controller.dart:203-211`).
16. `FAccordion` lifted control does not enforce `min`/`max` (proxy only forwards `onChange`, `accordion_controller.dart:160-170`); every item draws a trailing `FDivider`; items have no disabled state.
17. `FAlert` has only `primary`/`destructive`, no action/close slot, and is a live region by default (`alert.dart:101-103`), which can cause an announcement every time it rebuilds with changed text.
18. UNVERIFIED (static analysis only; no semantics tree executed): real-device screen-reader output for the toast stack's tap/scroll semantic actions; whether `FCollapsible` removes collapsed accordion content from semantics; platform announcement behaviour of `liveRegion` on `FAlert`/`FToast`.
