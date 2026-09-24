# Flutter UI Base — Phase 4 (Actions and Inputs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the ten remaining widgets of handoff groups B and C: FilterChip, ChipTrigger, FieldMessage, TextField, SearchField, Toggle, SelectionCheckbox, OptionRow, SegmentedTray and Stepper. Each gets widget tests and light/dark goldens, and joins the debug gallery.

**Architecture:**
- Same shape as phase 2: `lib/shared/widgets/mx_<name>.dart`, theme read only through the `context.*` accessors and `App*` tokens, and component type treatments added to `MxTextStyles`.
- The `ButtonStyle` that `MxButton` builds is extracted into `mxButtonStyle(...)` (`lib/shared/widgets/mx_button_style.dart`), so FilterChip, ChipTrigger and Stepper's buttons share one state policy.
- Text inputs wrap Material `TextField` with an `InputDecoration` driven by the contract, using a `WidgetStateColor` fill for rest and focus.
- Selection controls (toggle, radio ring, tray) are custom-painted over `InkWell` inside `MergeSemantics`, so each announces its state as one node.

**Tech Stack:** Flutter 3.47.5, Material 3, `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`](../specs/2026-09-23-flutter-ui-base-design.md), §5 and §8, and the §9 debt register.
- Contracts: `docs/shared/ui/design-handoff/widgets/{filter-chip,chip-trigger,field-message,text-field,search-field,toggle,selection-checkbox,option-row,segmented-tray,stepper}.md`.
- The phase 2/3 API is merged in #20 and #21.

## Global Constraints

- UI only; no `lib/features/`, no backend source.
- The guard rules active on `lib/shared/` (phase 2 Global Constraints) apply unchanged:
  - No hex, `Colors.*`, digit literals in `EdgeInsets`/`SizedBox`/`spacing:`/`BorderRadius.circular`/`strokeWidth:`/`BorderSide(width:)`.
  - No `TextStyle(`, no `texts|textStyles.x.copyWith(`, no `styleFrom`.
  - No `Text('…letters…')` or `label|title|tooltip|semanticLabel: '…'` literals.
  - A number shown in a `Text` is built with `.toString()`, never `'$value'` (the literal contains letters).
- Component-specific numbers are named `static const` in the widget.
- Every interactive widget meets 48×48 (`androidTapTargetGuideline`) and is labelled (`labeledTapTargetGuideline`). A selection control announces its state (`selected`, `checked` or `toggled`) as one semantics node (`MergeSemantics`).
- A widget holds no copy; semantic labels, hints and messages come from the caller.
- Disabled means the whole control at 0.38 with no interaction (the global rule), unless the contract says otherwise. The contract says otherwise for the Stepper at a bound (no separate look) and for ChipTrigger (no disabled state).
- `MediaQuery.disableAnimationsOf` zeroes every animation.
- Goldens are appended to `test/shared/widgets/shared_widgets_golden_test.dart` through `expectThemedGoldens`, generated on Windows at 3x, and opened and checked against the contract.
- The gate is `dart format` (no changes), `flutter analyze`, `flutter test`, `check_architecture.py`, CI tooling tests, guard `memox-v8` 0/0 and `tools/docs/check.py` 0 errors. Chain the guard with `&&` before every commit.
- Commits use scope `ui` and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Replies to the user are in Vietnamese.

## Rulings made while planning (carried into spec §9 by Task 8)

- **I1:** FieldMessage's warning *text* uses a new derived `warningInk`: `onWarning` in light and `warning` (the amber) in dark. The FieldMessage contract states this kit scoping itself, and it overrides the theme table's plain `on-warning` binding (spec §5 rule). This resolves debt row 1 for FieldMessage.
- **I2:** SelectionCheckbox's check glyph is 14, below the Foundations 16 floor. This is component geometry, where the contract wins.
- **I3:** The Stepper's invalid ring radius is UNSPECIFIED; it uses `AppRadius.md`, the radius of its buttons.
- **I4:** SegmentedTray lays out 48 tall with the 40 recessed tray painted centred, and each segment is at least 48 wide. The contract's 32 thumb in a 40 tray would give 40-tall targets.
- **I5:** Text rows whose contract states only size and colour (OptionRow description, SegmentedTray label, FieldMessage) use the caption role unchanged, including its 1.2 tracking. This extends debt row 17.
- **I6:** SelectionCheckbox is painted only. The row the caller builds is the tap target and carries the `checked` semantics, as the contract makes the whole row the target.
- **I7:** Glyph mapping: chevron-down → `keyboard_arrow_down`, arrow-up-down → `swap_vert`, sliders-horizontal → `tune`, filter → `filter_list`, alert-circle → `error_outline`, minus → `remove`.

## Review Focus

1. **FilterChip and SegmentedTray state for screen readers.** The selected option must be announced as selected in one node, not as a bare button plus a stray flag. Pinned by `isSemantics(isSelected: true, isButton: true)` in Tasks 2 and 6.
2. **TextField error without layout jumps.** Turning `errorText` on must push the following content down (FieldMessage below) and colour the border, not overlay the field or shrink it. Pinned in Task 3.
3. **SearchField clear.** Clear appears only with a query, empties the controller, reports `''` through `onChanged`, and keeps focus behaviour intact. Pinned in Task 4.
4. **Toggle focus ring must not move the thumb.** The ring is a foreground decoration, not a border that pads the child. Pinned by thumb offsets in Task 5.
5. **Stepper at a bound.** A null `onIncrement` stops that button without dimming it, while `isEnabled: false` dims the whole control. Pinned in Task 7.

---

## File Structure

```
lib/core/theme/foundations/app_stroke.dart   + control (2), selectedRing (6)
lib/core/theme/foundations/app_icons.dart    + chevronDown, sort, filters, filter, alert, remove
lib/core/theme/mx_text_styles.dart           + chipCount, fieldMessage, inputHint, searchValue,
                                               searchHint, optionTitle, optionDescription,
                                               trayLabel, stepperValue
lib/core/theme/mx_derived_colors.dart        + warningInk
lib/shared/widgets/mx_button_style.dart      mxButtonStyle(...)
lib/shared/widgets/mx_button.dart            uses mxButtonStyle
lib/shared/widgets/mx_filter_chip.dart       MxFilterChip
lib/shared/widgets/mx_chip_trigger.dart      MxChipTrigger
lib/shared/widgets/mx_field_message.dart     MxFieldMessage, MxFieldMessageTone
lib/shared/widgets/mx_text_field.dart        MxTextField
lib/shared/widgets/mx_search_field.dart      MxSearchField
lib/shared/widgets/mx_toggle.dart            MxToggle
lib/shared/widgets/mx_selection_checkbox.dart MxSelectionCheckbox
lib/shared/widgets/mx_option_row.dart        MxOptionRow
lib/shared/widgets/mx_segmented_tray.dart    MxSegmentedTray<T>, MxSegment<T>
lib/shared/widgets/mx_stepper.dart           MxStepper
lib/app/gallery/gallery_actions_section.dart + chips
lib/app/gallery/gallery_inputs_section.dart  C · inputs
lib/app/gallery/gallery_screen.dart          + inputs section
test/core/theme/*                            text styles, derived, foundations
test/shared/widgets/mx_*_test.dart           one per widget
test/shared/widgets/shared_widgets_golden_test.dart, goldens/*.png
test/app/gallery_test.dart                   + C group; app goldens regenerated
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md   §9
```

---

### Task 1: Theme additions

**Files:**
- Modify: `lib/core/theme/foundations/app_stroke.dart`, `lib/core/theme/foundations/app_icons.dart`, `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/mx_derived_colors.dart`
- Test: `test/core/theme/foundations_test.dart`, `test/core/theme/mx_text_styles_test.dart`, `test/core/theme/mx_derived_colors_test.dart`

**Interfaces:**
- Produces:
  - `AppStroke.control` (2) and `AppStroke.selectedRing` (6)
  - `AppIcons.chevronDown/sort/filters/filter/alert/remove`
  - `MxTextStyles`:
    - methods `chipCount(Color ink)`, `fieldMessage(Color ink)`, `trayLabel({required bool isSelected})`, `stepperValue({required bool isInvalid})`
    - getters `inputHint`, `searchValue`, `searchHint`, `optionTitle`, `optionDescription`
  - `MxDerivedColors.warningInk`

- [ ] **Step 1: Write the failing tests**

Append to `test/core/theme/foundations_test.dart`, inside `main()`:

```dart
  test('control and selected-ring strokes', () {
    expect(AppStroke.control, 2);
    expect(AppStroke.selectedRing, 6);
  });
```

Append to `test/core/theme/mx_derived_colors_test.dart`, inside `main()`:

```dart
  test('warningInk is onWarning in light and the amber in dark (I1)', () {
    expect(light.warningInk, MxSemanticColors.light.onWarning);
    expect(dark.warningInk, MxSemanticColors.dark.warning);
  });
```

Append to `test/core/theme/mx_text_styles_test.dart`, inside `main()`:

```dart
  test('chip count 12/700 tabular in the given ink', () {
    const ink = Color(0xFF654321);
    expectStyle(styles.chipCount(ink), size: 12, weight: FontWeight.w700, color: ink);
    expect(
      styles.chipCount(ink).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('field message is the caption role in the given ink', () {
    const ink = Color(0xFF654321);
    expectStyle(styles.fieldMessage(ink), size: 12, weight: FontWeight.w600, color: ink);
  });

  test('input hint 14 onSurfaceVariant; search value 16/400', () {
    expectStyle(styles.inputHint, size: 14, weight: FontWeight.w400, color: scheme.onSurfaceVariant);
    expectStyle(styles.searchValue, size: 16, weight: FontWeight.w400, color: scheme.onSurface);
    expectStyle(styles.searchHint, size: 16, weight: FontWeight.w400, color: scheme.onSurfaceVariant);
  });

  test('option row: title 14/600/-0.1, description 12 at 1.45', () {
    expectStyle(
      styles.optionTitle,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.1,
      color: scheme.onSurface,
    );
    expectStyle(styles.optionDescription, size: 12, weight: FontWeight.w600, color: scheme.onSurfaceVariant);
    expect(styles.optionDescription.height, 1.45);
  });

  test('tray label follows selection; stepper value 16/700 tabular', () {
    expect(styles.trayLabel(isSelected: true).color, scheme.onSurface);
    expect(styles.trayLabel(isSelected: false).color, scheme.onSurfaceVariant);
    expectStyle(
      styles.stepperValue(isInvalid: false),
      size: 16,
      weight: FontWeight.w700,
      color: scheme.onSurface,
    );
    expect(styles.stepperValue(isInvalid: true).color, scheme.error);
    expect(
      styles.stepperValue(isInvalid: false).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme`
Expected: FAIL, with compilation errors on the missing members.

- [ ] **Step 3: Implement**

`app_stroke.dart`, after `focusOffset`:

```dart

  /// Unselected radio ring and checkbox border.
  static const double control = 2;

  /// Selected radio ring: the ring thickens, nothing moves.
  static const double selectedRing = 6;
```

`app_icons.dart`, after `tag`:

```dart
  static const IconData chevronDown = Icons.keyboard_arrow_down; // chevron-down
  static const IconData sort = Icons.swap_vert; // arrow-up-down
  static const IconData filters = Icons.tune; // sliders-horizontal
  static const IconData filter = Icons.filter_list; // filter
  static const IconData alert = Icons.error_outline; // alert-circle
  static const IconData remove = Icons.remove; // minus
```

`mx_derived_colors.dart`:
- Add the field, and pass it in `resolve`:

```dart
      // Kit-scoped (FieldMessage contract): the warning FILL fails as 12px
      // text on light surfaces, so light inks with onWarning and dark with
      // the amber itself.
      warningInk: isDark ? semantic.warning : semantic.onWarning,
```

```dart
  /// Warning TEXT (FieldMessage), never the warning fill.
  final Color warningInk;
```

- Add `required this.warningInk,` to the private constructor.

`mx_text_styles.dart`, add the constants and members:

```dart
  static const double _optionTitleTracking = -0.1;
  static const double _optionDescriptionHeight = 1.45;
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// FilterChip count: 12/700 tabular, in the chip's ink at its opacity.
  TextStyle chipCount(Color ink) => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(fontFeatures: _tabular, color: ink);

  /// FieldMessage line: the caption role in the tone's ink.
  TextStyle fieldMessage(Color ink) => _texts.labelSmall!.copyWith(color: ink);

  /// TextField placeholder: 14, onSurfaceVariant.
  TextStyle get inputHint =>
      _texts.bodyMedium!.copyWith(color: _scheme.onSurfaceVariant);

  /// SearchField value: 16/400.
  TextStyle get searchValue => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w400,
  ).copyWith(color: _scheme.onSurface);

  /// SearchField placeholder: the value style in onSurfaceVariant.
  TextStyle get searchHint =>
      searchValue.copyWith(color: _scheme.onSurfaceVariant);

  /// OptionRow title: 14/600, -0.1.
  TextStyle get optionTitle => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w600,
  ).copyWith(letterSpacing: _optionTitleTracking, color: _scheme.onSurface);

  /// OptionRow description: the caption role at line-height 1.45 (I5).
  TextStyle get optionDescription => _texts.labelSmall!.copyWith(
    height: _optionDescriptionHeight,
    color: _scheme.onSurfaceVariant,
  );

  /// SegmentedTray label: the caption role, onSurface when selected (I5).
  TextStyle trayLabel({required bool isSelected}) => _texts.labelSmall!
      .copyWith(color: isSelected ? _scheme.onSurface : _scheme.onSurfaceVariant);

  /// Stepper value: 16/700 tabular, error when invalid.
  TextStyle stepperValue({required bool isInvalid}) => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w700,
  ).copyWith(
    fontFeatures: _tabular,
    color: isInvalid ? _scheme.error : _scheme.onSurface,
  );
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/core/theme`
Expected: PASS.

- [ ] **Step 5: Gate, commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme test/core/theme
git commit -m "feat(theme): phase 4 strokes, icons, input text styles, warning ink

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `mxButtonStyle`, MxFilterChip, MxChipTrigger

**Files:**
- Create: `lib/shared/widgets/mx_button_style.dart`, `lib/shared/widgets/mx_filter_chip.dart`, `lib/shared/widgets/mx_chip_trigger.dart`
- Modify: `lib/shared/widgets/mx_button.dart`, `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_filter_chip_test.dart`, `test/shared/widgets/mx_chip_trigger_test.dart`

**Interfaces:**
- Produces:
  - `ButtonStyle mxButtonStyle({required Color? fill, required Color ink, required BorderSide edge, required Color focusColor, required double height, required double radius, required double padding, required TextStyle label})`
  - `MxFilterChip({required String label, required bool isSelected, required ValueChanged<bool>? onSelected, int? count, IconData? icon})`
  - `MxChipTrigger({required String label, required VoidCallback? onPressed, IconData icon = AppIcons.chevronDown})`

- [ ] **Step 1: Extract `mxButtonStyle` (refactor under the existing tests)**

`lib/shared/widgets/mx_button_style.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';

/// The ButtonStyle every text-labelled Mx control shares. It has one fill and
/// one ink for every state; dimming a disabled control is the caller's 0.38
/// Opacity. It also sets the 0.12 pressed overlay, the focus ring on the
/// control's edge (ruling R5), and a painted [height] inside a 48 touch area.
ButtonStyle mxButtonStyle({
  required Color? fill,
  required Color ink,
  required BorderSide edge,
  required Color focusColor,
  required double height,
  required double radius,
  required double padding,
  required TextStyle label,
}) {
  final focusRing = BorderSide(color: focusColor, width: AppStroke.focus);
  return ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(fill),
    foregroundColor: WidgetStatePropertyAll(ink),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? ink.withValues(alpha: AppOpacity.pressed)
          : null,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused) ? focusRing : edge,
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: padding),
    ),
    minimumSize: WidgetStatePropertyAll(Size(0, height)),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    textStyle: WidgetStatePropertyAll(label),
  );
}
```

In `mx_button.dart`:
- Delete the `_style` method.
- Replace `style: _style(context, paint, geometry),` with:

```dart
      style: mxButtonStyle(
        fill: paint.fill,
        ink: paint.ink,
        edge: paint.edge,
        focusColor: context.colors.primary,
        height: geometry.height,
        radius: geometry.radius,
        padding: geometry.padding,
        label: geometry.isSmallType
            ? context.textStyles.buttonLabelSmall
            : context.textStyles.buttonLabel,
      ),
```

- Add `import 'package:memox/shared/widgets/mx_button_style.dart';`.
- Remove any import that analyze reports unused.

Run:

```bash
flutter test test/shared/widgets/mx_button_test.dart
flutter test --tags golden test/shared/widgets/shared_widgets_golden_test.dart
```

Expected: PASS, and the `mx_button` goldens are unchanged. This is a pure refactor.

- [ ] **Step 2: Write the failing tests**

`test/shared/widgets/mx_filter_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unselected: lowest fill, ghost edge, onSurface label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (_) {}),
    );
    final material = tester.widget<Material>(_painted.first);

    expect(tester.getSize(_painted.first).height, 28);
    expect(material.color, scheme.surfaceContainerLowest);
    expect(material.textStyle!.color, scheme.onSurface);
    expect(
      (material.shape! as RoundedRectangleBorder).side,
      BorderSide(
        color: MxDerivedColors.resolve(scheme, MxSemanticColors.light).ghostBorder,
      ),
    );
  });

  testWidgets('selected: primary fill, onPrimary label, no edge', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );
    final material = tester.widget<Material>(_painted.first);

    expect(material.color, scheme.primary);
    expect(material.textStyle!.color, scheme.onPrimary);
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('the count sits at 60% resting and 75% selected', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', count: 12, isSelected: false, onSelected: (_) {}),
    );
    expect(
      tester.widget<Text>(find.text('12')).style!.color,
      scheme.onSurface.withValues(alpha: 0.6),
    );

    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', count: 12, isSelected: true, onSelected: (_) {}),
    );
    expect(
      tester.widget<Text>(find.text('12')).style!.color,
      scheme.onPrimary.withValues(alpha: 0.75),
    );
  });

  testWidgets('a tap reports the flipped selection', (tester) async {
    bool? reported;
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: false, onSelected: (v) => reported = v),
    );
    await tester.tap(find.byType(MxFilterChip));

    expect(reported, isTrue);
  });

  testWidgets('selection is announced on the button node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxFilterChip(label: 'Due', isSelected: true, onSelected: (_) {}),
    );

    expect(
      tester.getSemantics(find.byType(MxFilterChip)),
      isSemantics(label: 'Due', isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('a 28 pill with a 48 target; disabled at 0.38', (tester) async {
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Cards',
        icon: AppIcons.filter,
        isSelected: false,
        onSelected: (_) {},
      ),
    );
    await expectAccessibleTargets(tester);

    await pumpMx(
      tester,
      const MxFilterChip(label: 'Cards', isSelected: false, onSelected: null),
    );
    expect(
      tester.widget<Opacity>(
        find.ancestor(of: find.byType(TextButton), matching: find.byType(Opacity)),
      ).opacity,
      0.38,
    );
  });
}
```

`test/shared/widgets/mx_chip_trigger_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('ghost: no fill, onSurfaceVariant label, a trailing chevron', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final material = tester.widget<Material>(_painted.first);

    expect(tester.getSize(_painted.first).height, 28);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, AppColorSchemes.light.onSurfaceVariant);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
    expect(tester.getSize(find.byIcon(AppIcons.chevronDown)).width, 16);
  });

  testWidgets('opens its menu on tap and meets the 48 target', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxChipTrigger(label: 'Sort', onPressed: () => taps++));
    await tester.tap(find.byType(MxChipTrigger));

    expect(taps, 1);
    await expectAccessibleTargets(tester);
  });
}
```

Append to the golden file: imports for `mx_filter_chip.dart` and `mx_chip_trigger.dart`, then:

```dart
  testWidgets('MxFilterChip and MxChipTrigger', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_chips',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MxFilterChip(label: 'All', count: 128, isSelected: true, onSelected: (_) {}),
          MxFilterChip(label: 'Cards', count: 96, isSelected: false, onSelected: (_) {}),
          MxFilterChip(label: 'Decks', icon: AppIcons.filter, isSelected: false, onSelected: (_) {}),
          const MxFilterChip(label: 'Disabled', isSelected: false, onSelected: null),
          MxChipTrigger(label: 'Sort: Due', onPressed: () {}),
          MxChipTrigger(label: 'Filters', icon: AppIcons.filters, onPressed: () {}),
        ],
      ),
    );
  });
```

- [ ] **Step 3: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_filter_chip_test.dart test/shared/widgets/mx_chip_trigger_test.dart`
Expected: FAIL, because the widget files do not exist.

- [ ] **Step 4: Implement**

`lib/shared/widgets/mx_filter_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button_style.dart';

/// A selectable filter (All · Cards · Decks). Its selection is exposed as
/// state, not only as a look, so screen readers announce it. It never shrinks
/// or wraps: the caller's row scrolls.
class MxFilterChip extends StatelessWidget {
  const MxFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  final String label;
  final bool isSelected;

  /// Receives the flipped selection. Null disables the chip.
  final ValueChanged<bool>? onSelected;

  /// Shown after the label, lighter than it.
  final int? count;

  /// Optional leading glyph at 16.
  final IconData? icon;

  static const double _countOpacityResting = 0.6;
  static const double _countOpacitySelected = 0.75;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final ink = isSelected ? colors.onPrimary : colors.onSurface;
    final select = onSelected;
    final chip = MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: TextButton(
          onPressed: select == null ? null : () => select(!isSelected),
          style: mxButtonStyle(
            fill: isSelected ? colors.primary : colors.surfaceContainerLowest,
            ink: ink,
            edge: isSelected
                ? BorderSide.none
                : BorderSide(
                    color: context.derivedColors.ghostBorder,
                    width: AppStroke.hairline,
                  ),
            focusColor: colors.primary,
            height: AppSize.chip,
            radius: AppRadius.full,
            padding: AppSpacing.control,
            label: styles.buttonLabelSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              if (icon case final glyph?)
                Icon(glyph, size: AppIconSize.inline),
              Text(label, maxLines: 1, softWrap: false),
              if (count case final value?)
                Text(
                  value.toString(),
                  style: styles.chipCount(
                    ink.withValues(
                      alpha: isSelected
                          ? _countOpacitySelected
                          : _countOpacityResting,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (select != null) return chip;
    return Opacity(opacity: AppOpacity.disabled, child: chip);
  }
}
```

`lib/shared/widgets/mx_chip_trigger.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button_style.dart';

/// A ghost chip that opens a menu (sort, filters). No fill and no border,
/// which sets it apart from MxFilterChip; it never reads as selected. The
/// menu is the caller's.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.chevronDown,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The trailing glyph at 16: chevron-down by default.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: mxButtonStyle(
        fill: null,
        ink: colors.onSurfaceVariant,
        edge: BorderSide.none,
        focusColor: colors.primary,
        height: AppSize.chip,
        radius: AppRadius.full,
        padding: AppSpacing.control,
        label: context.textStyles.buttonLabelSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.micro,
        children: [
          Text(label, maxLines: 1, softWrap: false),
          Icon(icon, size: AppIconSize.inline),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_filter_chip_test.dart test/shared/widgets/mx_chip_trigger_test.dart`
Expected: PASS, 6 + 2 tests.

- [ ] **Step 6: Golden, gate, commit**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/shared_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/shared_widgets_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(ui): MxFilterChip, MxChipTrigger on a shared mxButtonStyle

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Open `mx_chips_light.png` and `_dark.png` and check:
- The selected chip is a primary pill with a lighter count.
- Resting chips are lowest pills with a hairline.
- The disabled chip is dimmed.
- The triggers are ghost labels with a chevron or tune glyph.

The `mx_button` goldens must still be unchanged.

---

### Task 3: MxFieldMessage and MxTextField

**Files:**
- Create: `lib/shared/widgets/mx_field_message.dart`, `lib/shared/widgets/mx_text_field.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_field_message_test.dart`, `test/shared/widgets/mx_text_field_test.dart`

**Interfaces:**
- Produces:
  - `enum MxFieldMessageTone { error, warning }`
  - `MxFieldMessage({required String message, MxFieldMessageTone tone = error})`
  - `MxTextField({TextEditingController? controller, FocusNode? focusNode, String? hintText, String? errorText, bool isMultiline = false, bool isEnabled = true, ValueChanged<String>? onChanged, TextInputAction? textInputAction, Widget? leading, Widget? trailing})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_field_message_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('error: glyph and text in the error colour', (tester) async {
    await pumpMx(tester, const MxFieldMessage(message: 'Name is required'));

    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      AppColorSchemes.light.error,
    );
    expect(
      tester.widget<Text>(find.text('Name is required')).style!.color,
      AppColorSchemes.light.error,
    );
  });

  testWidgets('warning: amber glyph, warning ink text (I1)', (tester) async {
    await pumpMx(
      tester,
      const MxFieldMessage(message: 'Ten tags at most', tone: MxFieldMessageTone.warning),
      brightness: Brightness.dark,
    );

    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      MxSemanticColors.dark.warning,
    );
    expect(
      tester.widget<Text>(find.text('Ten tags at most')).style!.color,
      MxSemanticColors.dark.warning,
    );
  });

  testWidgets('a long message wraps instead of truncating', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 200,
        child: MxFieldMessage(
          message: 'This deck name is already long and still keeps going on',
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));

    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(tester.getSize(find.byType(Text)).height, greaterThan(20));
  });

  testWidgets('announced as a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxFieldMessage(message: 'Name is required'));

    expect(
      tester.getSemantics(find.text('Name is required')),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
```

`test/shared/widgets/mx_text_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import '../../support/widget_harness.dart';

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

Color _edge(InputBorder? border) => (border! as OutlineInputBorder).borderSide.color;

void main() {
  final scheme = AppColorSchemes.light;
  final ghost = MxDerivedColors.resolve(scheme, MxSemanticColors.light).ghostBorder;

  testWidgets('single line is 52 tall', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')));

    expect(tester.getSize(find.byType(TextField)).height, 52);
  });

  testWidgets('multiline starts at 40 and grows with the text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpMx(
      tester,
      SizedBox(width: 300, child: MxTextField(controller: controller, isMultiline: true)),
    );
    expect(tester.getSize(find.byType(TextField)).height, 40);

    controller.text = 'one\ntwo\nthree\nfour';
    await tester.pump();
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(60));
  });

  testWidgets('fill: surface-muted at rest, lowest when focused', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));
    final fill = _decoration(tester).fillColor!;

    expect(WidgetStateProperty.resolveAs(fill, <WidgetState>{}), scheme.surfaceContainerLow);
    expect(
      WidgetStateProperty.resolveAs(fill, {WidgetState.focused}),
      scheme.surfaceContainerLowest,
    );
  });

  testWidgets('edges: ghost at rest, primary focused', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField()));

    expect(_edge(_decoration(tester).enabledBorder), ghost);
    expect(_edge(_decoration(tester).focusedBorder), scheme.primary);
  });

  testWidgets('an error colours the edge and pushes a message below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(errorText: 'Name is required')),
    );

    expect(_edge(_decoration(tester).enabledBorder), scheme.error);
    expect(_edge(_decoration(tester).focusedBorder), scheme.error);
    expect(find.byType(MxFieldMessage), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(MxFieldMessage)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TextField)).dy),
    );
    expect(tester.getSize(find.byType(TextField)).height, 52);
  });

  testWidgets('typing reports the value', (tester) async {
    String? typed;
    await pumpMx(
      tester,
      SizedBox(width: 300, child: MxTextField(onChanged: (v) => typed = v)),
    );
    await tester.enterText(find.byType(TextField), 'Verbs');

    expect(typed, 'Verbs');
  });

  testWidgets('disabled dims the whole field', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxTextField(isEnabled: false)));

    expect(
      tester.widget<Opacity>(
        find.ancestor(of: find.byType(TextField), matching: find.byType(Opacity)),
      ).opacity,
      0.38,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('2x text grows the single-line box', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxTextField(hintText: 'Deck name')),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TextField)).height, greaterThanOrEqualTo(52));
  });
}
```

Append to the golden file: imports for `mx_field_message.dart` and `mx_text_field.dart`, then:

```dart
  testWidgets('MxTextField states and MxFieldMessage tones', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_text_field',
      Column(
        spacing: 16,
        children: [
          const MxTextField(hintText: 'Deck name'),
          MxTextField(controller: TextEditingController(text: 'Japanese N5')),
          const MxTextField(hintText: 'Deck name', errorText: 'Name is required'),
          const MxTextField(hintText: 'Back of the card', isMultiline: true),
          const MxTextField(hintText: 'Disabled', isEnabled: false),
          const MxFieldMessage(
            message: 'Ten tags at most on one card',
            tone: MxFieldMessageTone.warning,
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_field_message_test.dart test/shared/widgets/mx_text_field_test.dart`
Expected: FAIL, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_field_message.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A failure, or a limit reached (not a failure).
enum MxFieldMessageTone { error, warning }

/// The single validation line under a field: an alert glyph and the message.
/// It wraps rather than truncating, because it is the one thing the user must
/// read in full, and it is announced when it appears.
class MxFieldMessage extends StatelessWidget {
  const MxFieldMessage({
    super.key,
    required this.message,
    this.tone = MxFieldMessageTone.error,
  });

  final String message;
  final MxFieldMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (glyph, ink) = switch (tone) {
      MxFieldMessageTone.error => (context.colors.error, context.colors.error),
      // Ruling I1: the amber fill for the glyph, the warning ink for text.
      MxFieldMessageTone.warning => (
        context.semanticColors.warning,
        context.derivedColors.warningInk,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.micro,
          top: AppSpacing.micro,
          right: AppSpacing.micro,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Icon(AppIcons.alert, size: AppIconSize.inline, color: glyph),
            Expanded(
              child: Text(message, style: context.textStyles.fieldMessage(ink)),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/shared/widgets/mx_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

/// Every form field: a filled surface with a ghost edge, a lighter fill and a
/// primary edge on focus, and an error edge with an MxFieldMessage below.
/// Focus, caret, selection and IME are the platform's. Validation and the
/// message text are the caller's.
class MxTextField extends StatelessWidget {
  const MxTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.isMultiline = false,
    this.isEnabled = true,
    this.onChanged,
    this.textInputAction,
    this.leading,
    this.trailing,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// Non-null turns the field to its error tone and shows this message below.
  final String? errorText;

  /// The card editor's box: starts at 40 and grows with the text.
  final bool isMultiline;
  final bool isEnabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;

  static const double _multilineMinHeight = 40;

  /// A single-line box centres its text in its 52 height instead.
  static const double _singleLineVerticalPadding = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ghost = context.derivedColors.ghostBorder;
    final hasError = errorText != null;
    OutlineInputBorder edge(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: AppStroke.hairline),
    );
    final restingEdge = edge(hasError ? colors.error : ghost);
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      onChanged: onChanged,
      textInputAction: textInputAction,
      maxLines: isMultiline ? null : 1,
      keyboardType: isMultiline ? TextInputType.multiline : null,
      style: context.texts.bodyMedium,
      cursorColor: colors.primary,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.textStyles.inputHint,
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.surfaceContainerLowest
              : colors.surfaceContainerLow,
        ),
        isDense: true,
        constraints: BoxConstraints(
          minHeight: isMultiline ? _multilineMinHeight : AppSize.input,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.grouped,
          vertical: isMultiline
              ? AppSpacing.control
              : _singleLineVerticalPadding,
        ),
        prefixIcon: leading == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.grouped,
                  end: AppSpacing.control,
                ),
                child: leading,
              ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.control,
                  end: AppSpacing.grouped,
                ),
                child: trailing,
              ),
        suffixIconConstraints: const BoxConstraints(),
        border: restingEdge,
        enabledBorder: restingEdge,
        disabledBorder: edge(ghost),
        focusedBorder: edge(hasError ? colors.error : colors.primary),
      ),
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (errorText case final message?) MxFieldMessage(message: message),
      ],
    );
    if (isEnabled) return column;
    return Opacity(opacity: AppOpacity.disabled, child: column);
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_field_message_test.dart test/shared/widgets/mx_text_field_test.dart`
Expected: PASS, 4 + 8 tests.

If "single line is 52 tall" reads 52 plus a few pixels, `InputDecorator` added its own dense padding. Keep `constraints` as the only height source and set the vertical padding so the box is exactly 52 at 1x. Do not clamp: the 2x test must still grow. Record the ruling.

- [ ] **Step 5: Golden, gate, commit**

Same commands as Task 2 Step 6. Commit message: `feat(ui): MxFieldMessage, MxTextField`.

Check the golden:
- Muted fields with a hairline, and the placeholder in the secondary colour.
- The filled value in onSurface.
- The error field with a red edge and a red message line below.
- The multiline box shorter than the rest.
- The disabled field dimmed.
- The warning line amber in dark and brown ink in light.

---

### Task 4: MxSearchField

**Files:**
- Create: `lib/shared/widgets/mx_search_field.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_search_field_test.dart`

**Interfaces:**
- Consumes: `MxIconButton`, `AppIcons.search/close`, `context.textStyles.searchValue/searchHint`.
- Produces: `MxSearchField({required TextEditingController controller, required String hintText, required String clearLabel, ValueChanged<String>? onChanged, FocusNode? focusNode})`

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_search_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, {ValueChanged<String>? onChanged}) => pumpMx(
    tester,
    SizedBox(
      width: 328,
      child: MxSearchField(
        controller: controller,
        hintText: 'Search decks and cards',
        clearLabel: 'Clear search',
        onChanged: onChanged,
      ),
    ),
  );

  testWidgets('52 tall, 16/400 value, resting fill and muted glyph', (
    tester,
  ) async {
    await pump(tester);
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(tester.getSize(find.byType(TextField)).height, 52);
    expect(field.style!.fontSize, 16);
    expect(field.decoration!.fillColor, scheme.surfaceContainer);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.search)).color, scheme.onSurfaceVariant);
  });

  testWidgets('no clear button until there is a query', (tester) async {
    await pump(tester);
    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'verb');
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsOneWidget);
  });

  testWidgets('clear empties the query and reports it', (tester) async {
    final reported = <String>[];
    await pump(tester, onChanged: reported.add);
    await tester.enterText(find.byType(TextField), 'verb');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(reported.last, isEmpty);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('focus lightens the fill and tints the glyph', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.decoration!.fillColor, scheme.surfaceContainerLowest);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.search)).color, scheme.primary);
  });

  testWidgets('a long query stays on one line', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'a very long query ' * 8);
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);
    expect(tester.getSize(find.byType(TextField)).height, 52);
  });
}
```

Append to the golden file: import `mx_search_field.dart`, then:

```dart
  testWidgets('MxSearchField empty and filled', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_search_field',
      Column(
        spacing: 16,
        children: [
          MxSearchField(
            controller: TextEditingController(),
            hintText: 'Search decks and cards',
            clearLabel: 'Clear',
          ),
          MxSearchField(
            controller: TextEditingController(text: 'irregular verbs'),
            hintText: 'Search decks and cards',
            clearLabel: 'Clear',
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_search_field_test.dart`
Expected: FAIL, because `mx_search_field.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_search_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The library search input: a leading glyph, a single-line query, and a
/// clear button that appears only once there is something to clear. What the
/// query filters is the caller's.
class MxSearchField extends StatefulWidget {
  const MxSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.clearLabel,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;

  /// The clear button's accessible name.
  final String clearLabel;

  /// Also called with '' when the query is cleared.
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<MxSearchField> createState() => _MxSearchFieldState();
}

class _MxSearchFieldState extends State<MxSearchField> {
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(MxSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_rebuild);
      _focusNode.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.removeListener(_rebuild);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final isFocused = _focusNode.hasFocus;
    final hasQuery = widget.controller.text.isNotEmpty;
    OutlineInputBorder edge(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: AppStroke.hairline),
    );
    final resting = edge(context.derivedColors.ghostBorder);
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      style: styles.searchValue,
      cursorColor: colors.primary,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: styles.searchHint,
        filled: true,
        fillColor: isFocused
            ? colors.surfaceContainerLowest
            : colors.surfaceContainer,
        isDense: true,
        constraints: const BoxConstraints(minHeight: AppSize.input),
        contentPadding: EdgeInsets.zero,
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.gutter,
            end: AppSpacing.control,
          ),
          child: Icon(
            AppIcons.search,
            size: AppIconSize.compact,
            color: isFocused ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        // The clear button owns its inset; an empty field keeps a 12 spacer.
        suffixIcon: hasQuery
            ? Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.micro),
                child: MxIconButton(
                  icon: AppIcons.close,
                  semanticLabel: widget.clearLabel,
                  onPressed: _clear,
                ),
              )
            : const SizedBox(width: AppSpacing.grouped),
        suffixIconConstraints: const BoxConstraints(),
        border: resting,
        enabledBorder: resting,
        focusedBorder: edge(colors.primary),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_search_field_test.dart`
Expected: PASS, 5 tests.

If the clear button (48 target) makes the field taller than 52 once filled, the suffix is inflating the decorator: keep the 52 floor by passing the suffix through `suffixIconConstraints: const BoxConstraints(maxHeight: AppSize.input)`, and record the ruling.

- [ ] **Step 5: Golden, gate, commit**

Same commands as Task 2 Step 6. Commit message: `feat(ui): MxSearchField`.

Check the golden:
- The empty field has a muted glyph and placeholder, and no clear button.
- The filled field shows the query at 16 and an X on the right.

---

### Task 5: MxToggle and MxSelectionCheckbox

**Files:**
- Create: `lib/shared/widgets/mx_toggle.dart`, `lib/shared/widgets/mx_selection_checkbox.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_toggle_test.dart`, `test/shared/widgets/mx_selection_checkbox_test.dart`

**Interfaces:**
- Produces:
  - `MxToggle({required bool value, required ValueChanged<bool>? onChanged, required String semanticLabel})`
  - `MxSelectionCheckbox({required bool isChecked})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_toggle_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

const _trackKey = ValueKey('mx-toggle-track');
const _thumbKey = ValueKey('mx-toggle-thumb');

double _thumbOffset(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_thumbKey)).dx -
    tester.getTopLeft(find.byKey(_trackKey)).dx;

Color _trackColor(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(find.byKey(_trackKey)).decoration! as BoxDecoration).color!;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('off: highest track, thumb at 3; on: primary, thumb at 21', (
    tester,
  ) async {
    await pumpMx(tester, MxToggle(value: false, onChanged: (_) {}, semanticLabel: 'Reminders'));
    expect(tester.getSize(find.byKey(_trackKey)), const Size(44, 26));
    expect(_trackColor(tester), scheme.surfaceContainerHighest);
    expect(_thumbOffset(tester), 3);

    await pumpMx(tester, MxToggle(value: true, onChanged: (_) {}, semanticLabel: 'Reminders'));
    await tester.pumpAndSettle();
    expect(_trackColor(tester), scheme.primary);
    expect(_thumbOffset(tester), 21);
  });

  testWidgets('a tap reports the flipped value', (tester) async {
    bool? reported;
    await pumpMx(
      tester,
      MxToggle(value: false, onChanged: (v) => reported = v, semanticLabel: 'Reminders'),
    );
    await tester.tap(find.byType(MxToggle));

    expect(reported, isTrue);
  });

  testWidgets('announced as a labelled toggle with a 48 target', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, MxToggle(value: true, onChanged: (_) {}, semanticLabel: 'Reminders'));

    expect(
      tester.getSemantics(find.byType(MxToggle)),
      isSemantics(label: 'Reminders', isToggled: true, hasToggledState: true),
    );
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets('focus draws the ring without moving the thumb', (tester) async {
    await pumpMx(tester, MxToggle(value: false, onChanged: (_) {}, semanticLabel: 'Reminders'));
    final before = _thumbOffset(tester);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(
      tester.widget<AnimatedContainer>(find.byKey(_trackKey)).foregroundDecoration,
      isNotNull,
    );
    expect(_thumbOffset(tester), before);
  });

  testWidgets('disabled dims to 0.38 and ignores taps', (tester) async {
    await pumpMx(tester, const MxToggle(value: false, onChanged: null, semanticLabel: 'Reminders'));

    expect(
      tester.widget<Opacity>(
        find.ancestor(of: find.byKey(_trackKey), matching: find.byType(Opacity)),
      ).opacity,
      0.38,
    );
  });
}
```

`test/shared/widgets/mx_selection_checkbox_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../support/widget_harness.dart';

BoxDecoration _box(WidgetTester tester) => tester
    .widget<DecoratedBox>(
      find.descendant(of: find.byType(MxSelectionCheckbox), matching: find.byType(DecoratedBox)),
    )
    .decoration as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unchecked: a 20 box with a 2px outline, no fill', (tester) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));

    expect(tester.getSize(find.byType(MxSelectionCheckbox)), const Size.square(20));
    expect(_box(tester).color, isNull);
    expect(_box(tester).border, Border.all(color: scheme.outline, width: 2));
    expect(find.byIcon(AppIcons.check), findsNothing);
  });

  testWidgets('checked: primary fill, 14 onPrimary check, no border (I2)', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: true));

    expect(_box(tester).color, scheme.primary);
    expect(_box(tester).border, isNull);
    expect(tester.widget<Icon>(find.byIcon(AppIcons.check)).color, scheme.onPrimary);
    expect(tester.getSize(find.byIcon(AppIcons.check)).width, 14);
  });
}
```

Append to the golden file: imports for `mx_toggle.dart` and `mx_selection_checkbox.dart`, then:

```dart
  testWidgets('MxToggle and MxSelectionCheckbox', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_toggle_checkbox',
      Row(
        spacing: 8,
        children: [
          MxToggle(value: false, onChanged: (_) {}, semanticLabel: 'Off'),
          MxToggle(value: true, onChanged: (_) {}, semanticLabel: 'On'),
          const MxToggle(value: true, onChanged: null, semanticLabel: 'Disabled'),
          const MxSelectionCheckbox(isChecked: false),
          const MxSelectionCheckbox(isChecked: true),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_toggle_test.dart test/shared/widgets/mx_selection_checkbox_test.dart`
Expected: FAIL, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_toggle.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The on/off switch (Settings, Reminder). One size ships; the thumb slides,
/// it does not resize. Its 44×26 track sits inside a 48 touch area.
class MxToggle extends StatefulWidget {
  const MxToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;

  /// Receives the flipped value. Null disables the toggle.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  State<MxToggle> createState() => _MxToggleState();
}

class _MxToggleState extends State<MxToggle> {
  static const double _trackWidth = 44;
  static const double _trackHeight = 26;
  static const double _thumbSize = 20;
  static const double _thumbInset = 3;

  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onChanged = widget.onChanged;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.toggle;
    final track = AnimatedContainer(
      key: const ValueKey('mx-toggle-track'),
      duration: duration,
      curve: Easing.standard,
      width: _trackWidth,
      height: _trackHeight,
      padding: const EdgeInsets.all(_thumbInset),
      decoration: BoxDecoration(
        color: widget.value ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      // A foreground ring, so focus never pads the thumb (ruling R5).
      foregroundDecoration: _hasFocus
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: colors.primary, width: AppStroke.focus),
            )
          : null,
      child: AnimatedAlign(
        duration: duration,
        curve: Easing.standard,
        alignment: widget.value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: DecoratedBox(
          key: const ValueKey('mx-toggle-thumb'),
          decoration: BoxDecoration(
            color: colors.surfaceBright,
            shape: BoxShape.circle,
            boxShadow: AppShadows.whisper(colors),
          ),
          child: const SizedBox.square(dimension: _thumbSize),
        ),
      ),
    );
    final control = MergeSemantics(
      child: Semantics(
        toggled: widget.value,
        label: widget.semanticLabel,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged(!widget.value),
          onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSize.touchTarget,
              minHeight: AppSize.touchTarget,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: track),
          ),
        ),
      ),
    );
    if (onChanged != null) return control;
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }
}
```

`lib/shared/widgets/mx_selection_checkbox.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The selection-mode box on a card row. It is painted only (ruling I6): the
/// caller's row is the tap target and carries the checked semantics.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({super.key, required this.isChecked});

  final bool isChecked;

  static const double _boxSize = 20;

  /// Contract geometry, below the 16 icon floor (ruling I2).
  static const double _checkSize = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: _boxSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isChecked ? colors.primary : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: isChecked
              ? null
              : Border.all(color: colors.outline, width: AppStroke.control),
        ),
        child: isChecked
            ? Center(
                child: Icon(
                  AppIcons.check,
                  size: _checkSize,
                  color: colors.onPrimary,
                ),
              )
            : null,
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_toggle_test.dart test/shared/widgets/mx_selection_checkbox_test.dart`
Expected: PASS, 5 + 2 tests.

- [ ] **Step 5: Golden, gate, commit**

Same commands as Task 2 Step 6. Commit message: `feat(ui): MxToggle, MxSelectionCheckbox`.

Check the golden:
- The off toggle has a grey track and the thumb on the left.
- The on toggle has a primary track and the thumb on the right.
- The disabled toggle is dimmed.
- The empty box has an outline ring; the checked box is a primary fill with a white check.

---

### Task 6: MxOptionRow and MxSegmentedTray

**Files:**
- Create: `lib/shared/widgets/mx_option_row.dart`, `lib/shared/widgets/mx_segmented_tray.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_option_row_test.dart`, `test/shared/widgets/mx_segmented_tray_test.dart`

**Interfaces:**
- Produces:
  - `MxOptionRow({required String title, required bool isSelected, required VoidCallback? onSelected, String? description, Widget? trailing, bool hasDivider = true})`
  - `MxSegment<T>({required T value, required String label})`
  - `MxSegmentedTray<T>({required List<MxSegment<T>> segments, required T selected, required ValueChanged<T> onSelected, bool isWide = false})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_option_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../support/widget_harness.dart';

const _radioKey = ValueKey('mx-option-radio');

Border _ring(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(find.byKey(_radioKey)).decoration as BoxDecoration).border! as Border;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unselected 2px outline ring; selected 6px primary', (
    tester,
  ) async {
    await pumpMx(tester, MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}));
    expect(_ring(tester).top, BorderSide(color: scheme.outline, width: 2));
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(20));

    await pumpMx(tester, MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}));
    expect(_ring(tester).top, BorderSide(color: scheme.primary, width: 6));
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(20));
  });

  testWidgets('at least 48 tall; a description wraps and grows the row', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxOptionRow(title: 'Eight box', isSelected: false, onSelected: () {})),
    );
    final short = tester.getSize(find.byType(MxOptionRow)).height;
    expect(short, greaterThanOrEqualTo(48));

    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          description: 'Cards climb eight boxes, each a longer interval than the '
              'last, and drop back to the first when forgotten.',
          isSelected: false,
          onSelected: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(MxOptionRow)).height, greaterThan(short));
  });

  testWidgets('a tap selects; announced as a checked exclusive option', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(tester, MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () => taps++));
    await tester.tap(find.byType(MxOptionRow));

    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(MxOptionRow)),
      isSemantics(
        label: 'SM-2',
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('divider unless last; disabled at 0.38', (tester) async {
    await pumpMx(tester, MxOptionRow(title: 'A', isSelected: false, onSelected: () {}, hasDivider: false));
    expect(
      tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(MxOptionRow), matching: find.byType(DecoratedBox)),
      ).where((box) => (box.decoration as BoxDecoration).border is Border && box.key != _radioKey),
      isEmpty,
    );

    await pumpMx(tester, const MxOptionRow(title: 'A', isSelected: false, onSelected: null));
    expect(
      tester.widget<Opacity>(
        find.ancestor(of: find.byKey(_radioKey), matching: find.byType(Opacity)),
      ).opacity,
      0.38,
    );
  });
}
```

`test/shared/widgets/mx_segmented_tray_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import '../../support/widget_harness.dart';

enum _Range { week, month }

const _segments = [
  MxSegment(value: _Range.week, label: '7d'),
  MxSegment(value: _Range.month, label: '30d'),
];

BoxDecoration _thumb(WidgetTester tester, String label) => tester
    .widget<DecoratedBox>(
      find.ancestor(of: find.text(label), matching: find.byType(DecoratedBox)).first,
    )
    .decoration as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('the active option sits on a raised lowest thumb', (tester) async {
    await pumpMx(
      tester,
      MxSegmentedTray(segments: _segments, selected: _Range.week, onSelected: (_) {}),
    );

    expect(_thumb(tester, '7d').color, scheme.surfaceContainerLowest);
    expect(_thumb(tester, '7d').boxShadow, AppShadows.whisper(scheme));
    expect(_thumb(tester, '30d').color, isNull);
    expect(tester.widget<Text>(find.text('7d')).style!.color, scheme.onSurface);
    expect(tester.widget<Text>(find.text('30d')).style!.color, scheme.onSurfaceVariant);
  });

  testWidgets('a tap reports the option; 48×48 targets (I4)', (tester) async {
    _Range? picked;
    await pumpMx(
      tester,
      MxSegmentedTray(segments: _segments, selected: _Range.week, onSelected: (v) => picked = v),
    );
    await tester.tap(find.text('30d'));

    expect(picked, _Range.month);
    expect(tester.getSize(find.byType(MxSegmentedTray<_Range>)).height, 48);
    await expectAccessibleTargets(tester);
  });

  testWidgets('announced as a selected exclusive option', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxSegmentedTray(segments: _segments, selected: _Range.week, onSelected: (_) {}),
    );

    expect(
      tester.getSemantics(find.text('7d')),
      isSemantics(label: '7d', isSelected: true, isButton: true, isInMutuallyExclusiveGroup: true),
    );
    handle.dispose();
  });

  test('two or three options only', () {
    expect(
      () => MxSegmentedTray(
        segments: const [MxSegment(value: 1, label: 'a')],
        selected: 1,
        onSelected: (_) {},
      ),
      throwsAssertionError,
    );
  });
}
```

Append to the golden file: imports for `mx_option_row.dart` and `mx_segmented_tray.dart`, then:

```dart
  testWidgets('MxOptionRow and MxSegmentedTray', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_option_tray',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Column(
            children: [
              MxOptionRow(
                title: 'Eight box',
                description: 'Cards climb eight boxes, each a longer interval.',
                isSelected: true,
                onSelected: () {},
              ),
              MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
              const MxOptionRow(title: 'Disabled', isSelected: false, onSelected: null, hasDivider: false),
            ],
          ),
          MxSegmentedTray(
            segments: const [
              MxSegment(value: 0, label: 'Light'),
              MxSegment(value: 1, label: 'Dark'),
              MxSegment(value: 2, label: 'System'),
            ],
            selected: 2,
            onSelected: (_) {},
          ),
          MxSegmentedTray(
            segments: const [MxSegment(value: 7, label: '7 days'), MxSegment(value: 30, label: '30 days')],
            selected: 7,
            onSelected: (_) {},
            isWide: true,
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_option_row_test.dart test/shared/widgets/mx_segmented_tray_test.dart`
Expected: FAIL, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_option_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A single-choice row (algorithm, study mode, direction). The radio is a ring
/// that thickens when selected, so nothing moves between states. The whole
/// row is the target.
class MxOptionRow extends StatelessWidget {
  const MxOptionRow({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onSelected,
    this.description,
    this.trailing,
    this.hasDivider = true,
  });

  final String title;
  final bool isSelected;

  /// Null disables the row.
  final VoidCallback? onSelected;

  /// Wraps to as many lines as it needs; the row grows.
  final String? description;
  final Widget? trailing;

  /// The ghost rule under the row; the caller turns it off on the last row.
  final bool hasDivider;

  static const double _radioColumn = 22;
  static const double _radioSize = 20;
  static const double _descriptionGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final row = MergeSemantics(
      child: Semantics(
        checked: isSelected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onSelected,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: hasDivider
                  ? Border(
                      bottom: BorderSide(
                        color: context.derivedColors.ghostBorder,
                        width: AppStroke.hairline,
                      ),
                    )
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.grouped,
                ),
                child: Row(
                  spacing: AppSpacing.grouped,
                  children: [
                    SizedBox(
                      width: _radioColumn,
                      child: Center(
                        child: DecoratedBox(
                          key: const ValueKey('mx-option-radio'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.outline,
                              width: isSelected
                                  ? AppStroke.selectedRing
                                  : AppStroke.control,
                            ),
                          ),
                          child: const SizedBox.square(dimension: _radioSize),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: styles.optionTitle),
                          if (description case final text?) ...[
                            const SizedBox(height: _descriptionGap),
                            Text(text, style: styles.optionDescription),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (onSelected != null) return row;
    return Opacity(opacity: AppOpacity.disabled, child: row);
  }
}
```

`lib/shared/widgets/mx_segmented_tray.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One option of an MxSegmentedTray.
@immutable
final class MxSegment<T> {
  const MxSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// A two- or three-option exclusive switch: a recessed tray with a raised
/// thumb behind the active option. Beyond three options, or when labels stop
/// fitting, use MxOptionRow instead.
class MxSegmentedTray<T> extends StatelessWidget {
  const MxSegmentedTray({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.isWide = false,
  }) : assert(
         segments.length >= _minSegments && segments.length <= _maxSegments,
         'a tray holds two or three options',
       );

  final List<MxSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  /// The Progress range tray's wider option padding (16 instead of 12).
  final bool isWide;

  static const int _minSegments = 2;
  static const int _maxSegments = 3;
  static const double _thumbHeight = 32;
  static const double _segmentGap = 2;

  @override
  Widget build(BuildContext context) {
    // Ruling I4: the tray paints 40 tall inside a 48 layout band.
    const trayHeight = _thumbHeight + AppSpacing.micro + AppSpacing.micro;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(
              height: trayHeight,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: _segmentGap,
            children: [
              for (final segment in segments)
                _Segment(
                  label: segment.label,
                  isSelected: segment.value == selected,
                  padding: isWide ? AppSpacing.gutter : AppSpacing.grouped,
                  onTap: () => onSelected(segment.value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.padding,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final double padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.sm);
    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        button: true,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSize.touchTarget,
              minHeight: AppSize.touchTarget,
            ),
            child: Center(
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceContainerLowest : null,
                  borderRadius: radius,
                  boxShadow: isSelected ? AppShadows.whisper(colors) : null,
                ),
                child: SizedBox(
                  height: MxSegmentedTray._thumbHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: context.textStyles.trayLabel(
                          isSelected: isSelected,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_option_row_test.dart test/shared/widgets/mx_segmented_tray_test.dart`
Expected: PASS, 4 + 4 tests.

`_thumb(tester, '30d')` finds the nearest `DecoratedBox` above the inactive label. That box is the thumb box with a null colour. If the finder lands on the tray instead, key the thumb box, `ValueKey('mx-tray-thumb-$label')`, and find by key. Record it as a test-only ruling.

- [ ] **Step 5: Golden, gate, commit**

Same commands as Task 2 Step 6. Commit message: `feat(ui): MxOptionRow, MxSegmentedTray`.

Check the golden:
- The selected radio is a thick primary ring; the unselected one is a thin outline.
- The description wraps.
- The disabled row is dimmed, and the last row has no rule.
- The trays show a recessed track with a raised thumb behind "System" and "7 days"; the wide tray has more padding.

---

### Task 7: MxStepper

**Files:**
- Create: `lib/shared/widgets/mx_stepper.dart`
- Modify: `test/shared/widgets/shared_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_stepper_test.dart`

**Interfaces:**
- Consumes: `mxButtonStyle`, `AppIcons.remove/add`, `context.textStyles.stepperValue`.
- Produces: `MxStepper({required int value, required String decrementLabel, required String incrementLabel, required VoidCallback? onDecrement, required VoidCallback? onIncrement, bool isInvalid = false, bool isBusy = false, bool isEnabled = true})`

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_stepper_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import '../../support/widget_harness.dart';

const _valueKey = ValueKey('mx-stepper-value');

MxStepper _stepper({
  int value = 20,
  VoidCallback? onDecrement,
  VoidCallback? onIncrement,
  bool isInvalid = false,
  bool isBusy = false,
  bool isEnabled = true,
}) => MxStepper(
  value: value,
  decrementLabel: 'Fewer cards',
  incrementLabel: 'More cards',
  onDecrement: onDecrement ?? () {},
  onIncrement: onIncrement ?? () {},
  isInvalid: isInvalid,
  isBusy: isBusy,
  isEnabled: isEnabled,
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('minus and plus fire; the value reads in onSurface', (tester) async {
    final calls = <String>[];
    await pumpMx(
      tester,
      _stepper(onDecrement: () => calls.add('-'), onIncrement: () => calls.add('+')),
    );
    await tester.tap(find.byTooltip('Fewer cards'));
    await tester.tap(find.byTooltip('More cards'));

    expect(calls, ['-', '+']);
    expect(tester.widget<Text>(find.text('20')).style!.color, scheme.onSurface);
  });

  testWidgets('36 buttons with 48 targets; the value column is at least 48', (
    tester,
  ) async {
    await pumpMx(tester, _stepper(value: 1));
    final painted = find.descendant(of: find.byType(TextButton), matching: find.byType(Material));

    expect(tester.getSize(painted.first), const Size.square(36));
    expect(tester.getSize(find.byKey(_valueKey)).width, greaterThanOrEqualTo(48));
    await expectAccessibleTargets(tester);
  });

  testWidgets('invalid: error number inside a 1px error ring', (tester) async {
    await pumpMx(tester, _stepper(value: 250, isInvalid: true));
    final ring = (tester.widget<DecoratedBox>(find.byKey(_valueKey)).decoration as BoxDecoration).border!;

    expect(tester.widget<Text>(find.text('250')).style!.color, scheme.error);
    expect(ring, Border.all(color: scheme.error));
  });

  testWidgets('valid carries no ring, so turning invalid moves nothing', (
    tester,
  ) async {
    await pumpMx(tester, _stepper());
    final validSize = tester.getSize(find.byKey(_valueKey));
    expect((tester.widget<DecoratedBox>(find.byKey(_valueKey)).decoration as BoxDecoration).border, isNull);

    await pumpMx(tester, _stepper(isInvalid: true));
    expect(tester.getSize(find.byKey(_valueKey)), validSize);
  });

  testWidgets('busy: a spinner replaces the number, widths hold', (tester) async {
    await pumpMx(tester, _stepper());
    final width = tester.getSize(find.byType(MxStepper)).width;

    await pumpMx(tester, _stepper(isBusy: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('20'), findsNothing);
    expect(tester.getSize(find.byType(MxStepper)).width, width);
  });

  testWidgets('at a bound the button stops without dimming', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxStepper(
        value: 200,
        decrementLabel: 'Fewer cards',
        incrementLabel: 'More cards',
        onDecrement: () {},
        onIncrement: null,
      ),
    );
    await tester.tap(find.byTooltip('More cards'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      find.ancestor(of: find.byKey(_valueKey), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('disabled dims the whole control and ignores taps', (tester) async {
    var taps = 0;
    await pumpMx(tester, _stepper(isEnabled: false, onIncrement: () => taps++));
    await tester.tap(find.byTooltip('More cards'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester.widget<Opacity>(
        find.ancestor(of: find.byKey(_valueKey), matching: find.byType(Opacity)),
      ).opacity,
      0.38,
    );
  });
}
```

Append to the golden file: import `mx_stepper.dart`, then:

```dart
  testWidgets('MxStepper default, invalid, busy, disabled', (tester) async {
    Widget stepper({int value = 20, bool isInvalid = false, bool isBusy = false, bool isEnabled = true}) =>
        MxStepper(
          value: value,
          decrementLabel: 'Fewer',
          incrementLabel: 'More',
          onDecrement: () {},
          onIncrement: () {},
          isInvalid: isInvalid,
          isBusy: isBusy,
          isEnabled: isEnabled,
        );
    await expectThemedGoldens(
      tester,
      'mx_stepper',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          stepper(),
          stepper(value: 250, isInvalid: true),
          stepper(isBusy: true),
          stepper(isEnabled: false),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_stepper_test.dart`
Expected: FAIL, because `mx_stepper.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_stepper.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button_style.dart';

/// The bounded integer input (cards per session). It owns the invalid ring,
/// the busy spinner and the disabled dim. The bounds, the clamping and the
/// validation message are the caller's: at a bound, pass null for that
/// button's callback and it stops without a separate look.
class MxStepper extends StatelessWidget {
  const MxStepper({
    super.key,
    required this.value,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
    this.isInvalid = false,
    this.isBusy = false,
    this.isEnabled = true,
  });

  final int value;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool isInvalid;

  /// A spinner replaces the number while the write is in flight.
  final bool isBusy;
  final bool isEnabled;

  /// So 1 and 200 occupy the same width.
  static const double _valueColumn = 48;
  static const double _buttonPadding = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final control = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        _StepButton(
          icon: AppIcons.remove,
          label: decrementLabel,
          onPressed: isEnabled ? onDecrement : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _valueColumn,
            minHeight: AppSize.buttonSmall,
          ),
          child: DecoratedBox(
            key: const ValueKey('mx-stepper-value'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              // Ruling I3. A null border when valid: turning invalid adds
              // colour, never layout.
              border: isInvalid
                  ? Border.all(color: colors.error, width: AppStroke.hairline)
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: isBusy
                  ? SizedBox.square(
                      dimension: AppIconSize.inline,
                      child: CircularProgressIndicator(
                        strokeWidth: AppStroke.indicator,
                        color: colors.primary,
                      ),
                    )
                  : Text(
                      value.toString(),
                      style: context.textStyles.stepperValue(
                        isInvalid: isInvalid,
                      ),
                    ),
            ),
          ),
        ),
        _StepButton(
          icon: AppIcons.add,
          label: incrementLabel,
          onPressed: isEnabled ? onIncrement : null,
        ),
      ],
    );
    if (isEnabled) return control;
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: label,
      child: TextButton(
        onPressed: onPressed,
        style:
            mxButtonStyle(
              fill: colors.surfaceContainer,
              ink: colors.onSurface,
              edge: BorderSide.none,
              focusColor: colors.primary,
              height: AppSize.buttonSmall,
              radius: AppRadius.md,
              padding: MxStepper._buttonPadding,
              label: context.textStyles.buttonLabel,
            ).copyWith(
              fixedSize: const WidgetStatePropertyAll(
                Size.square(AppSize.buttonSmall),
              ),
            ),
        child: Icon(icon, size: AppIconSize.compact),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_stepper_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Golden, gate, commit**

Same commands as Task 2 Step 6. Commit message: `feat(ui): MxStepper`.

Check the golden:
- Two 36 tonal squares around a bold tabular number.
- The invalid row shows a red number in a red ring.
- The busy row shows a spinner in the value column at the same width.
- The disabled row is dimmed.

---

### Task 8: Gallery, spec, gate, hand back

**Files:**
- Create: `lib/app/gallery/gallery_inputs_section.dart`
- Modify: `lib/app/gallery/gallery_actions_section.dart`, `lib/app/gallery/gallery_screen.dart`, `test/app/gallery_test.dart`, `test/app/goldens/*.png`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`

- [ ] **Step 1: Write the failing gallery test**

In `test/app/gallery_test.dart`, add `'C · Inputs & selection'` to the list in "the four phase-2 groups are present", after `'B · Actions'`. Rename the test to `'every built group is present'`.

Run: `flutter test test/app/gallery_test.dart`
Expected: FAIL, because 'C · Inputs & selection' is not found.

- [ ] **Step 2: Add the chips to group B and create group C**

In `gallery_actions_section.dart`:
- Add imports for `mx_filter_chip.dart` and `mx_chip_trigger.dart`.
- Append this child after the IconButton `Row`:

```dart
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxFilterChip(label: 'All', count: 128, isSelected: true, onSelected: (_) {}),
          MxFilterChip(label: 'Cards', count: 96, isSelected: false, onSelected: (_) {}),
          MxFilterChip(label: 'Decks', icon: AppIcons.filter, isSelected: false, onSelected: (_) {}),
          MxChipTrigger(label: 'Sort: Due', icon: AppIcons.sort, onPressed: () {}),
          MxChipTrigger(label: 'Filters', icon: AppIcons.filters, onPressed: () {}),
        ],
      ),
```

`lib/app/gallery/gallery_inputs_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Group C: fields, messages and selection controls, live where they have
/// state so the gallery can be poked at.
class GalleryInputsSection extends StatefulWidget {
  const GalleryInputsSection({super.key});

  @override
  State<GalleryInputsSection> createState() => _GalleryInputsSectionState();
}

class _GalleryInputsSectionState extends State<GalleryInputsSection> {
  static const int _minCards = 1;
  static const int _maxCards = 200;

  final _search = TextEditingController();
  var _isReminderOn = true;
  var _scheduler = 0;
  var _theme = 2;
  var _cards = 20;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'C · Inputs & selection',
    children: [
      MxSearchField(
        controller: _search,
        hintText: 'Search decks and cards',
        clearLabel: 'Clear search',
      ),
      const MxTextField(hintText: 'Deck name'),
      const MxTextField(hintText: 'Deck name', errorText: 'Name is required'),
      const MxTextField(hintText: 'Back of the card', isMultiline: true),
      const MxFieldMessage(
        message: 'Ten tags at most on one card',
        tone: MxFieldMessageTone.warning,
      ),
      Row(
        children: [
          MxToggle(
            value: _isReminderOn,
            onChanged: (value) => setState(() => _isReminderOn = value),
            semanticLabel: 'Daily reminder',
          ),
          const MxSelectionCheckbox(isChecked: false),
          const MxSelectionCheckbox(isChecked: true),
        ],
      ),
      Column(
        children: [
          MxOptionRow(
            title: 'Eight box',
            description: 'Cards climb eight boxes, each a longer interval.',
            isSelected: _scheduler == 0,
            onSelected: () => setState(() => _scheduler = 0),
          ),
          MxOptionRow(
            title: 'SM-2',
            description: 'Intervals from four answers and an ease factor.',
            isSelected: _scheduler == 1,
            onSelected: () => setState(() => _scheduler = 1),
            hasDivider: false,
          ),
        ],
      ),
      MxSegmentedTray(
        segments: const [
          MxSegment(value: 0, label: 'Light'),
          MxSegment(value: 1, label: 'Dark'),
          MxSegment(value: 2, label: 'System'),
        ],
        selected: _theme,
        onSelected: (value) => setState(() => _theme = value),
      ),
      MxStepper(
        value: _cards,
        decrementLabel: 'Fewer cards',
        incrementLabel: 'More cards',
        onDecrement: _cards > _minCards ? () => setState(() => _cards--) : null,
        onIncrement: _cards < _maxCards ? () => setState(() => _cards++) : null,
      ),
    ],
  );
}
```

In `gallery_screen.dart`, import `gallery_inputs_section.dart`, and add `GalleryInputsSection(),` right after `GalleryActionsSection(),`.

Run: `flutter test test/app/gallery_test.dart`
Expected: PASS, 5 tests, including the 2x scroll-through with no exception.

- [ ] **Step 3: Regenerate the app goldens and look**

Group B grows, so the gallery golden changes on purpose. The Library golden must not change.

```bash
flutter test --tags golden test/app/app_golden_test.dart
flutter test --update-goldens --tags golden test/app/app_golden_test.dart
flutter test --tags golden test/app/app_golden_test.dart
```

Expected:
- The first run fails only on `app_gallery_*`.
- The last run passes.

Open `app_gallery_light.png` and `_dark.png`: the chips row is now under the icon buttons.

- [ ] **Step 4: Record the rulings in spec §9**

Append after row 19:

```markdown
| 20 | FieldMessage warning text uses a derived `warningInk` (onWarning light, the amber dark), as the FieldMessage contract scopes it; this resolves row 1 for FieldMessage | phase 4 plan I1 |
| 21 | SelectionCheckbox's check glyph is 14, below the 16 icon floor, as its contract states | phase 4 plan I2 |
| 22 | Stepper invalid-ring radius is UNSPECIFIED and uses `AppRadius.md`, its buttons' radius | phase 4 plan I3 |
| 23 | SegmentedTray lays out 48 tall with the 40 tray painted centred; each segment is at least 48 wide | phase 4 plan I4 |
| 24 | OptionRow description, SegmentedTray label and FieldMessage keep the caption role's 1.2 tracking (extends row 17) | phase 4 plan I5 |
| 25 | SelectionCheckbox is painted only; the caller's row owns the tap and the checked semantics | phase 4 plan I6 |
```

- [ ] **Step 5: Gate, scope, commit, hand back**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python tools/docs/check.py
git add lib/app test/app docs/superpowers
git commit -m "feat(app): phase 4 widgets in the gallery; record phase 4 rulings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected:
- All gate commands exit 0.
- The diff lists only `lib/core/theme/`, `lib/shared/widgets/`, `lib/app/gallery/`, `test/` and `docs/superpowers/`.

Report to the user in Vietnamese:
- Counts and results.
- Every execution ruling.
- The regenerated gallery goldens, sent with SendUserFile.

Ask through AskUserQuestion whether to open the PR, merge it, and continue to phase 5.
