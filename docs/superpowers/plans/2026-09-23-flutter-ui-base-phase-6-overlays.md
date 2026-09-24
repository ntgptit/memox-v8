# Flutter UI Base — Phase 6 (Overlays, Loading, Error) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the last nine widgets of handoff groups F and G:
- Group F: Dialog, BottomSheet, SheetActions, Snackbar, InlineBanner, DeckPickerSheet.
- Group G: Skeleton, Spinner, ErrorState.

The existing `CircularProgressIndicator` uses switch to MxSpinner. Every new widget joins the gallery. The phase closes with the native impeccable audit over the gallery.

**Architecture:**
- Same shape as phases 4 and 5: `lib/shared/widgets/mx_<name>.dart`. Theme is read only through the `context.*` accessors and the `App*` tokens. Type treatments go into `MxTextStyles`.
- Overlays open through `showMxDialog`, `showMxBottomSheet` and `showMxSnackbar`, which wrap the platform modal routes and the `ScaffoldMessenger` (spec §5). The barrier is `scrim` at 45%.
- `MxDialog` and `MxBottomSheet` paint their own surface on a `Material`, as `MxCard` does, so the ripple of a row inside them is visible.
- `MxBottomSheet` has `header`, `child` and `footer` slots. Only the child scrolls, so a footer (SheetActions) stays visible when the sheet stops at 85%.

**Tech Stack:** Flutter 3.47.5, Material 3, `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`](../specs/2026-09-23-flutter-ui-base-design.md), §5, §8 (the phase 6 audit is in §8.3) and the §9 debt register.
- Contracts: `docs/shared/ui/design-handoff/widgets/{dialog,bottom-sheet,sheet-actions,snackbar,inline-banner,deck-picker-sheet,skeleton,spinner,error-state}.md`.
- Phases 1–5 are merged (#19–#23).

## Global Constraints

- UI only: no `lib/features/` and no backend source.
- The guard rules active on `lib/shared/` apply unchanged:
  - No hex values and no `Colors.*`.
  - No digit literals in `EdgeInsets`, `SizedBox`, `spacing:`, `BorderRadius.circular`, `strokeWidth:` or `BorderSide(width:)`.
  - No `TextStyle(`, no `texts|textStyles.x.copyWith(`, no `styleFrom`.
  - No `Text('…letters…')` literals, and no `label|title|tooltip|semanticLabel: '…'` literals.
  - Booleans read as predicates.
  - A source file stays under 400 lines.
- Component-specific numbers are named `static const` in the widget.
- Every interactive widget meets the 48 minimum and is labelled.
- A widget holds no copy. Titles, messages, labels and reasons come from the caller.
- Disabled means the whole control at 0.38 with no tap.
- Heights around text are minimums, and text scale is never clamped.
- `MediaQuery.disableAnimationsOf` turns off the skeleton pulse and the overlay transitions (spec §5).
- Goldens go into two new files, each under 400 lines:
  - `test/shared/widgets/loading_widgets_golden_test.dart`: Spinner, Skeleton, ErrorState.
  - `test/shared/widgets/overlay_widgets_golden_test.dart`: SheetActions, InlineBanner, Dialog, BottomSheet, Snackbar, DeckPickerSheet.
- Goldens use `expectThemedGoldens`, are generated on Windows at 3x, and are opened and checked against the contract.
- The gate, run before every commit:
  - `dart format` produces no changes.
  - `flutter analyze` is clean.
  - The guard `memox-v8` reports **0 errors and 0 warnings**.
- The end-of-phase gate adds:
  - `flutter test`.
  - `check_architecture.py`.
  - The CI tooling tests.
  - `tools/docs/check.py` with 0 errors.
- Commits use scope `ui`, `theme` or `app` and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Replies to the user are in Vietnamese.

## Rulings made while planning (carried into spec §9 by Task 8)

- **O1:** MxSpinner is a custom 2px ring with one quarter open, turning linearly once every 0.8s.
  - Material's indeterminate `CircularProgressIndicator` grows and shrinks its arc. The contract draws a fixed three-quarter ring.
  - The spinner keeps turning under reduced motion. It is the only sign that work is in flight, and spec §5 lists only the pulse, flips and slides as motion to stop.
- **O2:** The spinner's colour is `isOnFill`: `onPrimary` inside a filled (primary or destructive) button, and `primary` everywhere else.
  - A loading secondary or outline MxButton therefore spins in `primary` instead of its ink.
  - This resolves the spinner half of row 16.
- **O3:** Skeleton:
  - Its radius of 6 has no token, so it is a component constant.
  - The contract's "skeleton row" (a tile plus bars at 70% and 45%) ships as `MxSkeletonRow`, with ListRow's padding and gap.
  - The gap between the bars is UNSPECIFIED and uses 8.
- **O4:** ErrorState:
  - The tile → title gap is UNSPECIFIED and uses EmptyState's 16 (row 15).
  - Its card is `MxCard(isFullBleed: true)` with the contract's 40 24 padding.
- **O5:** Titles and dialog text:
  - One style, `compactTitle` (16/700/-0.2), serves the ErrorState title, the DeckPickerSheet title and the Dialog title.
  - The Dialog's title and body typography and its insets are UNSPECIFIED. The title is `compactTitle`, the body is 14 in `onSurface`, the text is inset 20, and the gaps are 8.
  - Dialog text scrolls when it outgrows the screen; the actions stay.
- **O6:** InlineBanner:
  - The warning border is a new derived `warningBorder` at the contract's 26% light / 32% dark. This is the theme gap the contract reports.
  - The message is the `onSurface` lead when there is no title, and the `onSurfaceVariant` detail under a title.
  - Actions always sit under the message. The single-line form with the action in the trailing slot is not built.
  - The padding starts after the hairline, as in MxNote.
  - The text keeps the caption role (I5) at line-height 1.55.
- **O7:** Overlay motion:
  - The Dialog uses `showGeneralDialog` with the contract's 200ms fade and 0.94 → 1 scale.
  - The BottomSheet uses the platform modal route's slide at 260ms with the standard curve, instead of translate 20% → 0 (spec §5: overlays use the platform modal route).
  - Both open with `Duration.zero` under reduced motion.
- **O8:** The scrim's 45% is a new effect token, `AppEffects.scrimOpacity`.
- **O9:** Snackbar:
  - It is the platform floating `SnackBar`, configured with the contract's surface: inverse fill, radius 12, padding 10 16, and a 16 margin.
  - `MxSnackbarContent` owns the text and the action.
  - The action is a 32 compact `TextButton` on `mxButtonStyle`, with a 48 hit area. Its radius is UNSPECIFIED and uses 8.
  - Tapping the action hides the toast, then calls `onAction`.
  - The golden checks the content on a surface built in the test.
- **O10:** SheetActions:
  - The shares are flex 10:13 (1 : 1.3).
  - A custom footer uses `MxSheetActions.custom`.
  - An optional `confirmIcon` passes through to the confirm Button.
- **O11:** DeckPickerSheet:
  - Candidates are the generic `MxPickerCandidate(label, onTap, reason, icon, isEnabled)`.
  - The footer is one button: the outline dismiss when there are targets, and the primary one when there is nowhere to go.
  - The title → rule gap is UNSPECIFIED and uses 4.
  - The empty state's glyph is the folder.
- **O12:** MxBottomSheet:
  - The header and footer are fixed, and only the child scrolls.
  - A bottom `SafeArea` sits inside the surface, so the fill runs under the gesture bar.
- **O13:** The phase 6 audit's findings go to §9 and change no token (spec §8.3). There is no emulator (row 18), so the visual evidence is the gallery goldens.

## Review Focus

1. **Long content in a bottom sheet.**
   - Expected: the sheet stops at 85%, the list scrolls inside it, and the footer stays visible and tappable.
   - Pinned in Tasks 6 and 7.
2. **Dismissing a dialog or a sheet.**
   - Expected: a scrim tap closes it and returns `null`, and the scrim is `scrim` at 45%.
   - Pinned in Task 6.
3. **A confirm that cannot act yet.**
   - Expected: the confirm is dimmed with no tap, and Cancel stays live.
   - Pinned in Task 5.
4. **Reduced motion.**
   - Expected: the skeleton rests at 0.5 with no running animation.
   - Expected: the dialog opens without a transition.
   - Pinned in Tasks 2 and 6.
5. **The snackbar action.**
   - Expected: tapping Undo calls `onAction` once and dismisses the toast.
   - Expected: a long message wraps, and the action keeps its width.
   - Pinned in Task 7.

---

## File Structure

```
lib/core/theme/
  mx_text_styles.dart            modify: compactTitle, dialogBody, bannerTitle, bannerMessage,
                                         snackbarMessage, snackbarAction
  mx_derived_colors.dart         modify: warningBorder
  foundations/app_effects.dart   modify: scrimOpacity
  foundations/app_icons.dart     modify: offline
lib/shared/widgets/
  mx_spinner.dart                create
  mx_skeleton.dart               create (MxSkeleton, MxSkeletonRow)
  mx_error_state.dart            create
  mx_sheet_actions.dart          create
  mx_inline_banner.dart          create
  mx_dialog.dart                 create (MxDialog, showMxDialog)
  mx_bottom_sheet.dart           create (MxBottomSheet, showMxBottomSheet)
  mx_snackbar.dart               create (MxSnackbarContent, buildMxSnackBar, showMxSnackbar)
  mx_deck_picker_sheet.dart      create (MxPickerCandidate, MxDeckPickerSheet)
  mx_button.dart, mx_list_row.dart, mx_stepper.dart   modify: MxSpinner
lib/app/gallery/
  gallery_overlays_section.dart  create (group F)
  gallery_states_section.dart    modify (group G)
  gallery_screen.dart            modify
test/core/theme/{mx_text_styles_test,mx_derived_colors_test,foundations_test}.dart   modify
test/shared/widgets/mx_<name>_test.dart                                             create
test/shared/widgets/{mx_button,mx_list_row,mx_stepper}_test.dart                    modify
test/shared/widgets/{loading,overlay}_widgets_golden_test.dart                      create
test/app/gallery_test.dart                                                          modify
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md                         modify (§9)
```

---

### Task 1: Theme additions

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/mx_derived_colors.dart`, `lib/core/theme/foundations/app_effects.dart`, `lib/core/theme/foundations/app_icons.dart`
- Test: `test/core/theme/mx_text_styles_test.dart`, `test/core/theme/mx_derived_colors_test.dart`, `test/core/theme/foundations_test.dart`

**Interfaces:**
- Produces on `MxTextStyles`:
  - Getters: `compactTitle`, `dialogBody`, `bannerTitle`, `snackbarMessage`, `snackbarAction`.
  - Method: `bannerMessage({required bool isLead})`.
- Produces `MxDerivedColors.warningBorder`, `AppEffects.scrimOpacity` (0.45) and `AppIcons.offline`.

- [ ] **Step 1: Write the failing tests**

Append to `test/core/theme/mx_text_styles_test.dart`, inside `main`:

```dart
  test('compact title 16/700/-0.2; dialog body 14 onSurface', () {
    expectStyle(
      styles.compactTitle,
      size: 16,
      weight: FontWeight.w700,
      tracking: -0.2,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.dialogBody,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurface,
    );
  });

  test('banner: 12/700 title and a 12 message at 1.55, lead or detail', () {
    expectStyle(
      styles.bannerTitle,
      size: 12,
      weight: FontWeight.w700,
      color: scheme.onSurface,
    );
    expect(styles.bannerTitle.height, 1.55);
    expect(styles.bannerMessage(isLead: true).color, scheme.onSurface);
    expectStyle(
      styles.bannerMessage(isLead: false),
      size: 12,
      weight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.bannerMessage(isLead: false).height, 1.55);
  });

  test('snackbar: 14 message at 1.4, 14/700 inverse-primary action', () {
    expectStyle(
      styles.snackbarMessage,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onInverseSurface,
    );
    expect(styles.snackbarMessage.height, 1.4);
    expectStyle(
      styles.snackbarAction,
      size: 14,
      weight: FontWeight.w700,
      color: scheme.inversePrimary,
    );
  });
```

Append to `test/core/theme/mx_derived_colors_test.dart`, inside `main`:

```dart
  test('warningBorder: warning at 26% light, 32% dark (O6)', () {
    expect(light.warningBorder, isColorCloseTo(0x42F59E0B));
    expect(dark.warningBorder, isColorCloseTo(0x52FFC658));
  });
```

Append to `test/core/theme/foundations_test.dart`, inside `main`. Add `import 'package:memox/core/theme/foundations/app_effects.dart';` if it is missing.

```dart
  test('the scrim is drawn at 45% (spec §5)', () {
    expect(AppEffects.scrimOpacity, 0.45);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme`
Expected: FAIL to compile, because `compactTitle`, `warningBorder` and `scrimOpacity` are not defined.

- [ ] **Step 3: Implement**

In `lib/core/theme/mx_text_styles.dart`, add three constants after `_donutLabelSize`:

```dart
  static const double _compactTitleTracking = -0.2;
  static const double _bannerHeight = 1.55;
  static const double _snackbarHeight = 1.4;
```

Then add these members before `trayLabel`:

```dart
  /// Compact title (ErrorState, DeckPickerSheet head, Dialog): 16/700, -0.2.
  TextStyle get compactTitle => AppTypography.withWeight(
    _texts.bodyLarge!,
    FontWeight.w700,
  ).copyWith(letterSpacing: _compactTitleTracking, color: _scheme.onSurface);

  /// Dialog body: 14 in onSurface (O5).
  TextStyle get dialogBody =>
      _texts.bodyMedium!.copyWith(color: _scheme.onSurface);

  /// InlineBanner title: 12/700 at line-height 1.55, onSurface.
  TextStyle get bannerTitle => AppTypography.withWeight(
    _texts.labelSmall!,
    FontWeight.w700,
  ).copyWith(height: _bannerHeight, color: _scheme.onSurface);

  /// InlineBanner message: the caption role at 1.55 (I5, O6). It is the
  /// onSurface lead without a title, and the onSurfaceVariant detail under
  /// one.
  TextStyle bannerMessage({required bool isLead}) =>
      _texts.labelSmall!.copyWith(
        height: _bannerHeight,
        color: isLead ? _scheme.onSurface : _scheme.onSurfaceVariant,
      );

  /// Snackbar message: 14 at line-height 1.4 on the inverse surface.
  TextStyle get snackbarMessage => _texts.bodyMedium!.copyWith(
    height: _snackbarHeight,
    color: _scheme.onInverseSurface,
  );

  /// Snackbar action: 14/700 in inversePrimary.
  TextStyle get snackbarAction => AppTypography.withWeight(
    _texts.bodyMedium!,
    FontWeight.w700,
  ).copyWith(color: _scheme.inversePrimary);
```

In `lib/core/theme/mx_derived_colors.dart`:
- Add `required this.warningBorder,` to the private constructor after `required this.warningSoft,`.
- In `resolve`, after `warningSoft: …,`, add:

```dart
      // The theme gap the InlineBanner contract reports: warning-border is
      // not in the derived registry. Its ratios come from that contract (O6).
      warningBorder: semantic.warning.withValues(
        alpha: isDark ? _warningBorderDark : _warningBorderLight,
      ),
```

- Add the ratios after `_warningSoftDark`:

```dart
  static const double _warningBorderLight = 0.26;
  static const double _warningBorderDark = 0.32;
```

- Add the field after `warningSoft`:

```dart
  /// InlineBanner warning edge.
  final Color warningBorder;
```

In `lib/core/theme/foundations/app_effects.dart`, add before the closing `}`:

```dart

  /// Alpha of the `scrim` behind a dialog or a bottom sheet (spec §5, O8).
  static const double scrimOpacity = 0.45;
```

In `lib/core/theme/foundations/app_icons.dart`, add after the `reminder` line:

```dart
  static const IconData offline = Icons.cloud_off_outlined; // cloud-off
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/core/theme`
Expected: PASS.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/core/theme test/core/theme
git commit -m "feat(theme): phase 6 overlay and banner styles, warning border, scrim opacity

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: analyze is clean, and the guard reports `Errors: 0 | Warnings: 0`.

---

### Task 2: MxSpinner and MxSkeleton

**Files:**
- Create: `lib/shared/widgets/mx_spinner.dart`, `lib/shared/widgets/mx_skeleton.dart`, `test/shared/widgets/loading_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_spinner_test.dart`, `test/shared/widgets/mx_skeleton_test.dart`

**Interfaces:**
- Produces:
  - `enum MxSpinnerSize { inline, compact, standard, large }` (16, 20, 24, 32)
  - `MxSpinner({MxSpinnerSize size = MxSpinnerSize.inline, bool isOnFill = false})`
  - `MxSkeleton({double? width, double height = 12, bool isCircle = false})`
  - `MxSkeletonRow()`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_spinner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/widget_harness.dart';

RenderObject _ring(WidgetTester tester) => tester.renderObject(
  find
      .descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(CustomPaint),
      )
      .first,
);

double _turns(WidgetTester tester) => tester
    .widget<RotationTransition>(
      find.descendant(
        of: find.byType(MxSpinner),
        matching: find.byType(RotationTransition),
      ),
    )
    .turns
    .value;

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('four sizes off the icon scale; 16 by default', (tester) async {
    for (final (size, box) in [
      (MxSpinnerSize.inline, 16.0),
      (MxSpinnerSize.compact, 20.0),
      (MxSpinnerSize.standard, 24.0),
      (MxSpinnerSize.large, 32.0),
    ]) {
      await pumpMx(tester, MxSpinner(size: size));

      expect(tester.getSize(find.byType(MxSpinner)), Size.square(box));
    }
    await pumpMx(tester, const MxSpinner());
    expect(tester.getSize(find.byType(MxSpinner)), const Size.square(16));
  });

  testWidgets('a 2px ring: primary on a surface, onPrimary on a fill', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner());
    expect(
      _ring(tester),
      paints..arc(
        color: scheme.primary,
        strokeWidth: 2,
        style: PaintingStyle.stroke,
      ),
    );

    await pumpMx(tester, const MxSpinner(isOnFill: true));
    expect(_ring(tester), paints..arc(color: scheme.onPrimary));
  });

  testWidgets('a quarter turn every 0.2s, also under reduced motion (O1)', (
    tester,
  ) async {
    await pumpMx(tester, const MxSpinner());
    await tester.pump(const Duration(milliseconds: 200));
    expect(_turns(tester), closeTo(0.25, 0.01));

    await pumpMx(tester, _still(const MxSpinner(key: ValueKey('still'))));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_turns(tester), closeTo(0.25, 0.01));
  });
}
```

`test/shared/widgets/mx_skeleton_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../support/widget_harness.dart';

BoxDecoration _block(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxSkeleton),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(MxSkeleton),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('12 tall, radius 6, full width, surfaceContainerHigh', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxSkeleton()));

    expect(tester.getSize(find.byType(MxSkeleton)), const Size(300, 12));
    expect(_block(tester).color, scheme.surfaceContainerHigh);
    expect(_block(tester).borderRadius, BorderRadius.circular(6));
  });

  testWidgets('a circle is its height wide with a full radius', (
    tester,
  ) async {
    await pumpMx(tester, const MxSkeleton(height: 28, isCircle: true));

    expect(tester.getSize(find.byType(MxSkeleton)), const Size.square(28));
    expect(_block(tester).borderRadius, BorderRadius.circular(999));
  });

  testWidgets('pulses 0.45 → 0.75 → 0.45 over 1.4s', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxSkeleton()));
    expect(_opacity(tester), closeTo(0.45, 0.001));

    await tester.pump(const Duration(milliseconds: 700));
    expect(_opacity(tester), closeTo(0.75, 0.001));

    await tester.pump(const Duration(milliseconds: 700));
    expect(_opacity(tester), closeTo(0.45, 0.001));
  });

  testWidgets('reduced motion: rests at 0.5 and nothing runs (RF4)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _still(const SizedBox(width: 300, child: MxSkeleton())),
    );

    expect(find.byType(FadeTransition), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxSkeleton),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.5,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('skeleton row: a 28 tile and bars at 70% and 45%', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 360, child: MxSkeletonRow()));
    final sizes = tester
        .widgetList<MxSkeleton>(find.byType(MxSkeleton))
        .map((skeleton) => tester.getSize(find.byWidget(skeleton)))
        .toList();

    // The text column is 360 − 16 − 16 − 28 − 12 = 288 wide.
    expect(sizes, [
      const Size.square(28),
      const Size(288 * 0.7, 12),
      const Size(288 * 0.45, 12),
    ]);
  });
}
```

`test/shared/widgets/loading_widgets_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxSpinner and MxSkeleton', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_spinner_skeleton',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 16,
            children: [
              MxSpinner(),
              MxSpinner(size: MxSpinnerSize.compact),
              MxSpinner(size: MxSpinnerSize.standard),
              MxSpinner(size: MxSpinnerSize.large),
            ],
          ),
          MxSkeletonRow(),
          MxSkeletonRow(),
          MxSkeleton(width: 200),
          MxSkeleton(height: 40, isCircle: true),
        ],
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_spinner_test.dart test/shared/widgets/mx_skeleton_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_spinner.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The icon step a spinner is drawn at, so it drops into a button, a row or a
/// card without a new number.
enum MxSpinnerSize { inline, compact, standard, large }

/// The indeterminate ring: 2px, one quarter open, one turn every 0.8s. It
/// keeps turning under reduced motion (ruling O1), because it is the only
/// sign that work is in flight.
class MxSpinner extends StatefulWidget {
  const MxSpinner({
    super.key,
    this.size = MxSpinnerSize.inline,
    this.isOnFill = false,
  });

  final MxSpinnerSize size;

  /// Inside a filled (primary or destructive) button: onPrimary, not primary
  /// (ruling O2).
  final bool isOnFill;

  @override
  State<MxSpinner> createState() => _MxSpinnerState();
}

class _MxSpinnerState extends State<MxSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: AppDurations.spinnerCycle,
  )..repeat();

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = switch (widget.size) {
      MxSpinnerSize.inline => AppIconSize.inline,
      MxSpinnerSize.compact => AppIconSize.compact,
      MxSpinnerSize.standard => AppIconSize.standard,
      MxSpinnerSize.large => AppIconSize.large,
    };
    return SizedBox.square(
      dimension: dimension,
      child: RotationTransition(
        turns: _turns,
        child: CustomPaint(
          painter: _RingPainter(
            color: widget.isOnFill ? colors.onPrimary : colors.primary,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  /// Three quarters drawn, one open.
  static const double _sweep = 1.5 * math.pi;
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = (Offset.zero & size).deflate(AppStroke.indicator / 2);
    canvas.drawArc(
      ring,
      _start,
      _sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.indicator,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}
```

`lib/shared/widgets/mx_skeleton.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One placeholder shape. It pulses: opacity travels 0.45 ↔ 0.75 over 1.4s,
/// with no shimmer sweep. Under reduced motion it rests at 0.5.
class MxSkeleton extends StatefulWidget {
  const MxSkeleton({
    super.key,
    this.width,
    this.height = _defaultHeight,
    this.isCircle = false,
  });

  /// Null fills the available width.
  final double? width;
  final double height;

  /// A circle as wide as it is tall, with a full radius.
  final bool isCircle;

  static const double _defaultHeight = 12;

  /// Ruling O3: the contract's 6 has no radius token.
  static const double _radius = 6;
  static const double _restingOpacity = 0.5;
  static const double _lowOpacity = 0.45;
  static const double _highOpacity = 0.75;

  @override
  State<MxSkeleton> createState() => _MxSkeletonState();
}

class _MxSkeletonState extends State<MxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.skeletonPulse,
  );
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: MxSkeleton._lowOpacity,
        end: MxSkeleton._highOpacity,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: MxSkeleton._highOpacity,
        end: MxSkeleton._lowOpacity,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1,
    ),
  ]).animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = SizedBox(
      width: widget.isCircle ? widget.height : widget.width ?? double.infinity,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(
            widget.isCircle ? AppRadius.full : MxSkeleton._radius,
          ),
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return Opacity(opacity: MxSkeleton._restingOpacity, child: shape);
    }
    return FadeTransition(opacity: _opacity, child: shape);
  }
}

/// The standard list placeholder (ruling O3): a tile and two bars at 70% and
/// 45% of the text column, on ListRow's padding and gap.
class MxSkeletonRow extends StatelessWidget {
  const MxSkeletonRow({super.key});

  static const double _tileSize = 28;
  static const double _titleShare = 0.7;
  static const double _subtitleShare = 0.45;

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.gutter,
      vertical: AppSpacing.grouped,
    ),
    child: Row(
      spacing: AppSpacing.grouped,
      children: [
        MxSkeleton(width: _tileSize, height: _tileSize),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.control,
            children: [
              FractionallySizedBox(
                widthFactor: _titleShare,
                child: MxSkeleton(),
              ),
              FractionallySizedBox(
                widthFactor: _subtitleShare,
                child: MxSkeleton(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_spinner_test.dart test/shared/widgets/mx_skeleton_test.dart`
Expected: PASS, 3 + 5 tests.

The 70% and 45% bar widths are floating-point products. If `Size` equality fails by a rounding step, compare each dimension with `closeTo(…, 0.01)` and record a test-only ruling.

- [ ] **Step 5: Golden, gate, commit**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/loading_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/loading_widgets_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(ui): MxSpinner, MxSkeleton

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check the golden:
- The four rings are 16, 20, 24 and 32, each a three-quarter ring in primary.
- The skeleton rows are a tile plus two bars.
- Every shape is a flat surfaceContainerHigh at pulse opacity.

---

### Task 3: Adopt MxSpinner in MxButton, MxListRow and MxStepper

**Files:**
- Modify: `lib/shared/widgets/mx_button.dart`, `lib/shared/widgets/mx_list_row.dart`, `lib/shared/widgets/mx_stepper.dart`
- Modify: `test/shared/widgets/mx_button_test.dart`, `test/shared/widgets/mx_list_row_test.dart`, `test/shared/widgets/mx_stepper_test.dart`
- Modify: the goldens that contain a spinner (button loading, list row busy, stepper busy, and the app gallery).

**Interfaces:**
- Consumes: `MxSpinner({isOnFill})`.

- [ ] **Step 1: Write the failing tests**

In the three test files:
- Replace `find.byType(CircularProgressIndicator)` with `find.byType(MxSpinner)`.
- Add `import 'package:memox/shared/widgets/mx_spinner.dart';`.

Append to `test/shared/widgets/mx_button_test.dart`, inside `main`:

```dart
  testWidgets('loading: a filled button spins onPrimary, outline primary', (
    tester,
  ) async {
    for (final (tone, isOnFill) in [
      (MxButtonTone.primary, true),
      (MxButtonTone.destructive, true),
      (MxButtonTone.secondary, false),
      (MxButtonTone.outline, false),
    ]) {
      await pumpMx(
        tester,
        MxButton(
          label: 'Save',
          tone: tone,
          isLoading: true,
          onPressed: () {},
        ),
      );

      expect(
        tester.widget<MxSpinner>(find.byType(MxSpinner)).isOnFill,
        isOnFill,
      );
    }
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_button_test.dart test/shared/widgets/mx_list_row_test.dart test/shared/widgets/mx_stepper_test.dart`
Expected: FAIL, because no `MxSpinner` is found in the loading button, the busy row or the busy stepper.

- [ ] **Step 3: Implement**

In `lib/shared/widgets/mx_button.dart`, in the loading `Stack`, replace:

```dart
        SizedBox.square(
          dimension: AppIconSize.inline,
          child: CircularProgressIndicator(
            strokeWidth: AppStroke.indicator,
            color: ink,
          ),
        ),
```

with:

```dart
        // Ruling O2: onPrimary inside a filled button, primary on the rest.
        MxSpinner(
          isOnFill:
              tone == MxButtonTone.primary || tone == MxButtonTone.destructive,
        ),
```

In `lib/shared/widgets/mx_list_row.dart`, replace the `(true, _) => SizedBox.square(… CircularProgressIndicator(…))` arm with `(true, _) => const MxSpinner(),`.

In `lib/shared/widgets/mx_stepper.dart`, replace the `SizedBox.square(… CircularProgressIndicator(…))` branch with `const MxSpinner()`.

In all three files:
- Add `import 'package:memox/shared/widgets/mx_spinner.dart';`.
- Remove any import `flutter analyze` then reports as unused (for example `app_stroke.dart`).
- If the `ink` parameter of `MxButton._content` is left unused, keep it, since it still colours the label and glyph.

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_button_test.dart test/shared/widgets/mx_list_row_test.dart test/shared/widgets/mx_stepper_test.dart`
Expected: PASS.

- [ ] **Step 5: Regenerate the changed goldens, look, gate, commit**

```bash
flutter test --tags golden test/shared/widgets test/app
```

Expected: the only failures are these goldens, each of which contains a spinner:
- The MxButton golden in `shared_widgets_golden_test.dart`.
- `mx_list_row` in `surface_widgets_golden_test.dart`.
- `mx_stepper` in `input_widgets_golden_test.dart`.
- `app_gallery_*` in `test/app`.

Record any other failure as a finding before regenerating.

```bash
flutter test --update-goldens --tags golden test/shared/widgets test/app
flutter test --tags golden test/shared/widgets test/app
rm -rf test/shared/widgets/failures test/app/failures
```

Open the regenerated files. Each spinner must be a fixed three-quarter ring:
- onPrimary inside the primary loading button.
- primary in the list row and the stepper.

Nothing else in these images may change.

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets test/shared/widgets test/app
git commit -m "refactor(ui): MxButton, MxListRow and MxStepper spin MxSpinner

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: MxErrorState

**Files:**
- Create: `lib/shared/widgets/mx_error_state.dart`
- Modify: `test/shared/widgets/loading_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_error_state_test.dart`

**Interfaces:**
- Consumes: `MxCard(isFullBleed: true)`, `MxButton(icon:, isLoading:)`, `compactTitle`, `emptyBody`, `derivedColors.dangerSoft`, `AppIcons.offline`/`retry`.
- Produces: `MxErrorState({required String title, required String body, IconData icon = AppIcons.offline, String? retryLabel, VoidCallback? onRetry, bool isRetrying = false})`

- [ ] **Step 1: Write the failing test**

`test/shared/widgets/mx_error_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../../support/widget_harness.dart';

const _title = 'Could not load decks';
const _body = 'Nothing was lost. Try again in a moment.';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a 52 danger-soft tile with a 24 error glyph, 40 from the top', (
    tester,
  ) async {
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(tester, const MxErrorState(title: _title, body: _body));
    final tile = find.descendant(
      of: find.byType(MxErrorState),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            (widget.decoration as BoxDecoration).color == derived.dangerSoft,
      ),
    );

    expect(tester.getSize(tile), const Size.square(52));
    expect(
      (tester.widget<DecoratedBox>(tile).decoration as BoxDecoration)
          .borderRadius,
      BorderRadius.circular(16),
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.offline));
    expect((glyph.size, glyph.color), (24, scheme.error));
    expect(
      tester.getTopLeft(tile).dy - tester.getTopLeft(find.byType(MxCard)).dy,
      40,
    );
  });

  testWidgets('title 16/700, 4 above a 14 body at 1.55; no Retry by default', (
    tester,
  ) async {
    await pumpMx(tester, const MxErrorState(title: _title, body: _body));
    final title = tester.widget<Text>(find.text(_title)).style!;
    final body = tester.widget<Text>(find.text(_body)).style!;

    expect((title.fontSize, title.fontWeight), (16, FontWeight.w700));
    expect(title.color, scheme.onSurface);
    expect((body.fontSize, body.height), (14, 1.55));
    expect(body.color, scheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.text(_body)).dy -
          tester.getBottomLeft(find.text(_title)).dy,
      4,
    );
    expect(find.byType(MxButton), findsNothing);
  });

  testWidgets('a primary Retry with the refresh glyph, 16 below the body', (
    tester,
  ) async {
    var retries = 0;
    await pumpMx(
      tester,
      MxErrorState(
        title: _title,
        body: _body,
        retryLabel: 'Retry',
        onRetry: () => retries++,
      ),
    );
    final retry = tester.widget<MxButton>(find.byType(MxButton));

    expect((retry.tone, retry.icon), (MxButtonTone.primary, AppIcons.retry));
    expect(
      tester.getTopLeft(find.byType(MxButton)).dy -
          tester.getBottomLeft(find.text(_body)).dy,
      16,
    );
    await tester.tap(find.byType(MxButton));
    expect(retries, 1);
  });

  testWidgets('retrying holds a spinner in the Retry', (tester) async {
    await pumpMx(
      tester,
      MxErrorState(
        title: _title,
        body: _body,
        retryLabel: 'Retry',
        onRetry: () {},
        isRetrying: true,
      ),
    );

    expect(tester.widget<MxButton>(find.byType(MxButton)).isLoading, isTrue);
  });

  test('retryLabel and onRetry come together', () {
    expect(
      () => MxErrorState(title: _title, body: _body, retryLabel: 'Retry'),
      throwsAssertionError,
    );
  });
}
```

Before the closing `}` of `loading_widgets_golden_test.dart`, append the test below. Add imports for `mx_error_state.dart` and `package:memox/core/theme/foundations/app_icons.dart`.

```dart
  testWidgets('MxErrorState with and without Retry', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_error_state',
      Column(
        spacing: 16,
        children: [
          MxErrorState(
            title: 'Could not load decks',
            body: 'Nothing was lost. Try again in a moment.',
            retryLabel: 'Retry',
            onRetry: () {},
          ),
          const MxErrorState(
            title: 'Deck not found',
            body: 'It may have been deleted on this device.',
            icon: AppIcons.alert,
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_error_state_test.dart`
Expected: FAIL to compile, because `mx_error_state.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_error_state.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// An inline load failure with a Retry. It has EmptyState's anatomy at a
/// smaller scale and a danger tone. The body says first that nothing was
/// lost, then offers the retry. Without [onRetry] it is the "not found" form.
class MxErrorState extends StatelessWidget {
  const MxErrorState({
    super.key,
    required this.title,
    required this.body,
    this.icon = AppIcons.offline,
    this.retryLabel,
    this.onRetry,
    this.isRetrying = false,
  }) : assert(
         (retryLabel == null) == (onRetry == null),
         'retryLabel and onRetry come together',
       );

  final String title;
  final String body;
  final IconData icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  /// The Retry holds a spinner while the reload runs.
  final bool isRetrying;

  static const double _verticalPadding = 40;
  static const double _tileSize = 52;
  static const double _titleGap = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return MxCard(
      isFullBleed: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.section,
          vertical: _verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: _tileSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.derivedColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: AppIconSize.standard,
                    color: colors.error,
                  ),
                ),
              ),
            ),
            // Ruling O4: the tile → title gap is UNSPECIFIED; EmptyState's.
            const SizedBox(height: AppSpacing.gutter),
            Text(title, textAlign: TextAlign.center, style: styles.compactTitle),
            const SizedBox(height: _titleGap),
            Text(body, textAlign: TextAlign.center, style: styles.emptyBody),
            if ((retryLabel, onRetry) case (
              final label?,
              final onPressed?,
            )) ...[
              const SizedBox(height: AppSpacing.gutter),
              MxButton(
                label: label,
                icon: AppIcons.retry,
                onPressed: onPressed,
                isLoading: isRetrying,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_error_state_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 2 Step 5 for `loading_widgets_golden_test.dart`. Commit message: `feat(ui): MxErrorState`.

Check the golden:
- The red-tinted 52 tile has a cloud-off glyph.
- The title is centred, with the reassurance line under it.
- The first card has a primary Retry with the refresh glyph; the second has none.

---

### Task 5: MxSheetActions and MxInlineBanner

**Files:**
- Create: `lib/shared/widgets/mx_sheet_actions.dart`, `lib/shared/widgets/mx_inline_banner.dart`, `test/shared/widgets/overlay_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_sheet_actions_test.dart`, `test/shared/widgets/mx_inline_banner_test.dart`

**Interfaces:**
- Consumes: `MxButton(tone:, icon:, isBlock:)`, `bannerTitle`, `bannerMessage`, `derivedColors.{warningSoft,warningBorder,dangerSoft,dangerBorder,ghostBorder}`, `AppIcons.alert`.
- Produces:
  - `MxSheetActions({required String cancelLabel, required VoidCallback onCancel, required String confirmLabel, required VoidCallback? onConfirm, IconData? confirmIcon, bool isDestructive = false, bool isInSheet = false})`
  - `MxSheetActions.custom({required List<Widget> children, bool isInSheet = false})`
  - `enum MxBannerTone { warning, danger }`
  - `MxInlineBanner({required MxBannerTone tone, required String message, String? title, List<Widget> actions = const [], bool isInCommitBar = false})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_sheet_actions_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/widget_harness.dart';

Finder _button(String label) => find.widgetWithText(MxButton, label);

Widget _width(Widget child) => SizedBox(width: 340, child: child);

void main() {
  testWidgets('cancel outline at 1 share, confirm primary at 1.3; 16 inset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
        ),
      ),
    );
    // 340 − 16 − 16 − 8 = 300, split 10 : 13.
    expect(tester.getSize(_button('Cancel')).width, closeTo(300 * 10 / 23, 0.01));
    expect(tester.getSize(_button('Move')).width, closeTo(300 * 13 / 23, 0.01));
    expect(tester.widget<MxButton>(_button('Cancel')).tone, MxButtonTone.outline);
    expect(tester.widget<MxButton>(_button('Move')).tone, MxButtonTone.primary);
    expect(
      tester.getTopLeft(_button('Cancel')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(16, 16),
    );
  });

  testWidgets('a destructive confirm, with its glyph passed through', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Delete',
          onConfirm: () {},
          confirmIcon: AppIcons.delete,
          isDestructive: true,
        ),
      ),
    );
    final confirm = tester.widget<MxButton>(_button('Delete'));

    expect(
      (confirm.tone, confirm.icon),
      (MxButtonTone.destructive, AppIcons.delete),
    );
  });

  testWidgets('a disabled confirm leaves Cancel live (RF3)', (tester) async {
    var cancels = 0;
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () => cancels++,
          confirmLabel: 'Move',
          onConfirm: null,
        ),
      ),
    );

    expect(tester.widget<MxButton>(_button('Move')).onPressed, isNull);
    await tester.tap(_button('Cancel'));
    expect(cancels, 1);
  });

  testWidgets('in a sheet: a ghost rule on top, then 8 16 16', (tester) async {
    final ghost = MxDerivedColors.resolve(
      AppColorSchemes.light,
      MxSemanticColors.light,
    ).ghostBorder;
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
          isInSheet: true,
        ),
      ),
    );
    final edge =
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxSheetActions),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .border! as Border;

    expect(edge.top, BorderSide(color: ghost));
    expect(
      tester.getTopLeft(_button('Cancel')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(16, 8),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSheetActions)).dy -
          tester.getBottomLeft(_button('Cancel')).dy,
      16,
    );
  });

  testWidgets('custom children replace the pair', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions.custom(
          children: [
            Expanded(child: MxButton(label: 'OK', onPressed: () {})),
          ],
        ),
      ),
    );

    expect(find.byType(MxButton), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });
}
```

`test/shared/widgets/mx_inline_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../support/widget_harness.dart';

const _message = 'The export could not be written.';

Widget _width(Widget child) => SizedBox(width: 328, child: child);

BoxDecoration _ground(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxInlineBanner),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;
  final derived = MxDerivedColors.resolve(scheme, semantic);

  testWidgets('warning: amber ground, warning border, amber 16 glyph', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.warning, message: _message),
      ),
    );
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));

    expect(_ground(tester).color, derived.warningSoft);
    expect(_ground(tester).border, Border.all(color: derived.warningBorder));
    expect(_ground(tester).borderRadius, BorderRadius.circular(12));
    expect((glyph.size, glyph.color), (16, semantic.warning));
  });

  testWidgets('danger: red ground, danger border, error glyph', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.danger, message: _message),
      ),
    );

    expect(_ground(tester).color, derived.dangerSoft);
    expect(_ground(tester).border, Border.all(color: derived.dangerBorder));
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      scheme.error,
    );
  });

  testWidgets('titled: a 700 title 2 above the detail; untitled: the lead', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.danger,
          title: 'Export failed',
          message: _message,
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Export failed')).style!.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      scheme.onSurfaceVariant,
    );
    expect(
      tester.getTopLeft(find.text(_message)).dy -
          tester.getBottomLeft(find.text('Export failed')).dy,
      2,
    );

    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.danger, message: _message),
      ),
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      scheme.onSurface,
    );
  });

  testWidgets('padding 12 16 after the hairline, 16 below; 8 12 and 0 in a bar',
      (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(tone: MxBannerTone.warning, message: _message),
      ),
    );
    final banner = tester.getTopLeft(find.byType(MxInlineBanner));
    expect(tester.getTopLeft(find.byType(Icon)).dx - banner.dx, 17);
    expect(tester.getTopLeft(find.text(_message)) - banner, const Offset(41, 13));
    expect(
      tester.getSize(find.byType(MxInlineBanner)).height -
          tester
              .getSize(
                find
                    .descendant(
                      of: find.byType(MxInlineBanner),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .height,
      16,
    );

    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.warning,
          message: _message,
          isInCommitBar: true,
        ),
      ),
    );
    final bar = tester.getTopLeft(find.byType(MxInlineBanner));
    expect(tester.getTopLeft(find.text(_message)) - bar, const Offset(37, 9));
    expect(
      tester.getBottomLeft(find.byType(MxInlineBanner)).dy,
      tester
          .getBottomLeft(
            find
                .descendant(
                  of: find.byType(MxInlineBanner),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .dy,
    );
  });

  testWidgets('actions sit 8 under the message, 8 apart; a live region', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _width(
        MxInlineBanner(
          tone: MxBannerTone.danger,
          message: _message,
          actions: [
            MxButton(
              label: 'Retry',
              size: MxButtonSize.compact,
              onPressed: () {},
            ),
            MxButton(
              label: 'Details',
              size: MxButtonSize.compact,
              tone: MxButtonTone.outline,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    final retry = find.widgetWithText(MxButton, 'Retry');
    final details = find.widgetWithText(MxButton, 'Details');

    // The compact Button paints 32 inside a 48 target, so its box starts 8
    // above the painted edge.
    expect(
      tester.getTopLeft(retry).dy - tester.getBottomLeft(find.text(_message)).dy,
      8,
    );
    expect(tester.getTopLeft(details).dx - tester.getTopRight(retry).dx, 8);
    expect(
      tester.getSemantics(find.text(_message)),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
```

`test/shared/widgets/overlay_widgets_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxSheetActions and MxInlineBanner', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_sheet_actions_banner',
      Column(
        spacing: 16,
        children: [
          MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () {},
            confirmLabel: 'Move to Trash',
            onConfirm: () {},
            confirmIcon: AppIcons.delete,
            isDestructive: true,
          ),
          MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () {},
            confirmLabel: 'Move',
            onConfirm: null,
            isInSheet: true,
          ),
          const MxInlineBanner(
            tone: MxBannerTone.warning,
            title: 'Ten tags at most',
            message: 'Remove a tag before adding another one.',
          ),
          MxInlineBanner(
            tone: MxBannerTone.danger,
            message:
                'The export could not be written. Nothing on this device '
                'changed.',
            actions: [
              MxButton(
                label: 'Retry',
                icon: AppIcons.retry,
                size: MxButtonSize.compact,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_sheet_actions_test.dart test/shared/widgets/mx_inline_banner_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_sheet_actions.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// The footer every dialog and sheet ends with. The confirm takes 1.3 shares
/// to Cancel's 1, so a real verb ("Move to Trash") keeps its line and Cancel
/// gives up width first.
class MxSheetActions extends StatelessWidget {
  const MxSheetActions({
    super.key,
    required String this.cancelLabel,
    required VoidCallback this.onCancel,
    required String this.confirmLabel,
    required this.onConfirm,
    this.confirmIcon,
    this.isDestructive = false,
    this.isInSheet = false,
  }) : children = const [];

  /// A custom footer (Trash restore / delete-forever, a single OK) in place
  /// of the pair (ruling O10).
  const MxSheetActions.custom({
    super.key,
    required this.children,
    this.isInSheet = false,
  }) : assert(children.length > 0, 'a custom footer has children'),
       cancelLabel = null,
       onCancel = null,
       confirmLabel = null,
       onConfirm = null,
       confirmIcon = null,
       isDestructive = false;

  final String? cancelLabel;
  final VoidCallback? onCancel;
  final String? confirmLabel;

  /// Null disables the confirm; Cancel stays live.
  final VoidCallback? onConfirm;
  final IconData? confirmIcon;

  /// The destructive Button tone on the confirm.
  final bool isDestructive;

  /// The sheet form: a ghost rule on top and 8 16 16 padding, instead of 16
  /// all round.
  final bool isInSheet;
  final List<Widget> children;

  static const int _cancelShare = 10;
  static const int _confirmShare = 13;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      spacing: AppSpacing.control,
      children: children.isNotEmpty
          ? children
          : [
              Expanded(
                flex: _cancelShare,
                child: MxButton(
                  label: cancelLabel!,
                  onPressed: onCancel,
                  tone: MxButtonTone.outline,
                  isBlock: true,
                ),
              ),
              Expanded(
                flex: _confirmShare,
                child: MxButton(
                  label: confirmLabel!,
                  onPressed: onConfirm,
                  icon: confirmIcon,
                  tone: isDestructive
                      ? MxButtonTone.destructive
                      : MxButtonTone.primary,
                  isBlock: true,
                ),
              ),
            ],
    );
    if (!isInSheet) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: row,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.derivedColors.ghostBorder,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.control,
          AppSpacing.gutter,
          AppSpacing.gutter,
        ),
        child: row,
      ),
    );
  }
}
```

`lib/shared/widgets/mx_inline_banner.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Warning is a refusal or a limit, and nothing was lost. Danger means an
/// operation failed.
enum MxBannerTone { warning, danger }

/// One in-place message about an operation or an object, with the compact
/// Buttons that resolve it. It is not a Note (info, no action) and not an
/// ErrorState (a whole-card load failure). It wraps and never truncates.
class MxInlineBanner extends StatelessWidget {
  const MxInlineBanner({
    super.key,
    required this.tone,
    required this.message,
    this.title,
    this.actions = const [],
    this.isInCommitBar = false,
  });

  final MxBannerTone tone;
  final String message;

  /// The bold lead line of the two-line form.
  final String? title;

  /// Compact MxButtons, under the message (ruling O6).
  final List<Widget> actions;

  /// The commit-bar variant: 8 12 padding and no margin below.
  final bool isInCommitBar;

  static const double _titleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final derived = context.derivedColors;
    final styles = context.textStyles;
    final (ground, edge, ink) = switch (tone) {
      MxBannerTone.warning => (
        derived.warningSoft,
        derived.warningBorder,
        context.semanticColors.warning,
      ),
      MxBannerTone.danger => (
        derived.dangerSoft,
        derived.dangerBorder,
        colors.error,
      ),
    };
    final messageStyle = styles.bannerMessage(isLead: title == null);
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(messageStyle.fontSize!) *
        messageStyle.height!;
    final glyphInset = math.max(0.0, (firstLine - AppIconSize.inline) / 2);
    // A DecoratedBox border does not inset its child: the padding starts
    // after the hairline, as in the kit's CSS box (and MxNote).
    final padding = isInCommitBar
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.grouped + AppStroke.hairline,
            vertical: AppSpacing.control + AppStroke.hairline,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter + AppStroke.hairline,
            vertical: AppSpacing.grouped + AppStroke.hairline,
          );
    return Padding(
      padding: isInCommitBar
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: edge, width: AppStroke.hairline),
          ),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                // The title and the message share the 12 × 1.55 first line.
                Padding(
                  padding: EdgeInsets.only(top: glyphInset),
                  child: Icon(
                    AppIcons.alert,
                    size: AppIconSize.inline,
                    color: ink,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title case final lead?) ...[
                        Text(lead, style: styles.bannerTitle),
                        const SizedBox(height: _titleGap),
                      ],
                      Text(message, style: messageStyle),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.control),
                        Wrap(
                          spacing: AppSpacing.control,
                          runSpacing: AppSpacing.control,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

The test offsets include the 1px border:
- The glyph sits at 1 + 16 = 17.
- The text sits at (17 + 16 + 8, 1 + 12) = (41, 13).
- In the commit bar, the text sits at (1 + 12 + 16 + 8, 1 + 8) = (37, 9).

The action test measures a compact Button's layout box, which is 48 tall around its 32 paint. It therefore starts 8 below the message only if the Wrap places the 48 box directly after the 8 gap. If Flutter reports the painted box instead, assert on the gap the harness measures and record a test-only ruling.

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_sheet_actions_test.dart test/shared/widgets/mx_inline_banner_test.dart`
Expected: PASS, 5 + 5 tests.

- [ ] **Step 5: Golden, gate, commit**

```bash
flutter test --update-goldens --tags golden test/shared/widgets/overlay_widgets_golden_test.dart
flutter test --tags golden test/shared/widgets/overlay_widgets_golden_test.dart
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/shared/widgets test/shared/widgets
git commit -m "feat(ui): MxSheetActions, MxInlineBanner

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Check the golden:
- "Move to Trash" is red with a trash glyph and wider than Cancel.
- The sheet footer has a hairline on top, and its confirm is dimmed.
- The banners are amber and red, with a tinted border and a glyph on the first line.
- The danger banner has Retry under its message.

---

### Task 6: MxDialog and MxBottomSheet

**Files:**
- Create: `lib/shared/widgets/mx_dialog.dart`, `lib/shared/widgets/mx_bottom_sheet.dart`
- Modify: `test/shared/widgets/overlay_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_dialog_test.dart`, `test/shared/widgets/mx_bottom_sheet_test.dart`

**Interfaces:**
- Consumes: `compactTitle`, `dialogBody`, `AppShadows.overlay`/`chrome`, `AppEffects.scrimOpacity`, `AppDurations.standard`/`sheet`, `MxSheetActions`.
- Produces:
  - `enum MxDialogWidth { small, medium, large }`
  - `MxDialog({String? title, String? body, Widget? content, Widget? actions, MxDialogWidth width = MxDialogWidth.large})`
  - `Future<T?> showMxDialog<T>(BuildContext context, {required WidgetBuilder builder})`
  - `MxBottomSheet({required Widget child, Widget? header, Widget? footer, bool hasGrabber = true})`
  - `Future<T?> showMxBottomSheet<T>(BuildContext context, {required WidgetBuilder builder})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/widget_harness.dart';

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(MxDialog), matching: find.byType(Material))
      .first,
);

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('surfaceContainerHigh at radius 20 with the overlay shadow', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
    final shadow =
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxDialog),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .boxShadow;

    expect(_surface(tester).color, scheme.surfaceContainerHigh);
    expect(
      (_surface(tester).shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(20),
    );
    expect(shadow, AppShadows.overlay(scheme));
  });

  testWidgets('width: the column 20 in from each edge, capped at 340/320/300', (
    tester,
  ) async {
    await pumpMx(tester, const MxDialog(title: 'Delete deck?'));
    expect(tester.getSize(find.byType(Material).last).width, 320);

    tester.view.physicalSize = const Size(600, 800);
    for (final (width, cap) in [
      (MxDialogWidth.large, 340.0),
      (MxDialogWidth.medium, 320.0),
      (MxDialogWidth.small, 300.0),
    ]) {
      await tester.pumpWidget(const SizedBox());
      await pumpMxAt(tester, MxDialog(title: 'Delete deck?', width: width));

      expect(tester.getSize(find.byType(Material).last).width, cap);
    }
  });

  testWidgets('title 16/700 over a 14 body, 20 in; the route is named', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxDialog(title: 'Delete deck?', body: 'Its cards move to Trash.'),
    );
    final surface = tester.getTopLeft(find.byType(Material).last);

    expect(
      tester.widget<Text>(find.text('Delete deck?')).style!.fontSize,
      16,
    );
    expect(
      tester.widget<Text>(find.text('Its cards move to Trash.')).style!.color,
      scheme.onSurface,
    );
    expect(
      tester.getTopLeft(find.text('Delete deck?')) - surface,
      const Offset(20, 20),
    );
    expect(
      tester.getSemantics(find.text('Delete deck?')),
      isSemantics(namesRoute: true, scopesRoute: true),
    );
    handle.dispose();
  });

  testWidgets('at 2x a long body scrolls and the actions stay', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxDialog(
        title: 'Delete deck?',
        body: List.filled(40, 'Its cards move to Trash.').join(' '),
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Delete',
          onConfirm: () {},
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byType(MxSheetActions)).dy,
      lessThanOrEqualTo(800),
    );
  });

  testWidgets('showMxDialog: a 45% scrim; a scrim tap returns null (RF2)', (
    tester,
  ) async {
    String? result = 'unset';
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () async => result = await showMxDialog<String>(
            context,
            builder: (_) => const MxDialog(title: 'Delete deck?'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsOneWidget);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      scheme.scrim.withValues(alpha: 0.45),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('reduced motion opens with no transition (RF4)', (tester) async {
    await pumpMx(
      tester,
      _still(
        Builder(
          builder: (context) => MxButton(
            label: 'Open',
            onPressed: () => showMxDialog<void>(
              context,
              builder: (_) => const MxDialog(title: 'Delete deck?'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(
      tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.byType(MxDialog),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value,
      1,
    );
  });
}
```

This test uses a helper `pumpMxAt` that pumps without resetting the view size. Add it to `test/support/widget_harness.dart` after `pumpMx`:

```dart
/// [pumpMx] at the view size the test already set.
Future<void> pumpMxAt(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  ),
);
```

`test/shared/widgets/mx_bottom_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

const _grabberKey = ValueKey('mx-sheet-grabber');
const _footerKey = ValueKey('footer');
const _rowKey = ValueKey('row');

Widget _rows(int count) => Column(
  children: [
    for (var i = 0; i < count; i++)
      SizedBox(key: ValueKey('row-$i'), height: 48, width: double.infinity),
  ],
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('surface: container-high, top radius 20, the chrome shadow', (
    tester,
  ) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(2)));
    final shadow =
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxBottomSheet),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .boxShadow;
    final surface = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(MxBottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(surface.color, scheme.surfaceContainerHigh);
    expect(
      (surface.shape! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(20)),
    );
    expect(shadow, AppShadows.chrome(scheme));
  });

  testWidgets('a 36×4 outlineVariant grabber, 8 above and 4 below', (
    tester,
  ) async {
    await pumpMx(tester, MxBottomSheet(child: _rows(1)));
    final bar = find.descendant(
      of: find.byKey(_grabberKey),
      matching: find.byType(DecoratedBox),
    );

    expect(tester.getSize(bar), const Size(36, 4));
    expect(
      (tester.widget<DecoratedBox>(bar).decoration as BoxDecoration).color,
      scheme.outlineVariant,
    );
    expect(tester.getSize(find.byKey(_grabberKey)).height, 16);

    await pumpMx(tester, MxBottomSheet(hasGrabber: false, child: _rows(1)));
    expect(find.byKey(_grabberKey), findsNothing);
  });

  testWidgets('long content stops at 85%, scrolls; the footer stays (RF1)', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxBottomSheet(
        footer: MxButton(
          key: _footerKey,
          label: 'Cancel',
          onPressed: () => taps++,
        ),
        child: _rows(40),
      ),
    );

    expect(
      tester.getSize(find.byType(MxBottomSheet)).height,
      lessThanOrEqualTo(800 * 0.85),
    );
    final before = tester.getTopLeft(find.byKey(const ValueKey('row-10'))).dy;
    await tester.drag(
      find.byKey(const ValueKey('row-2')),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row-10'))).dy,
      lessThan(before),
    );
    await tester.tap(find.byKey(_footerKey));
    expect(taps, 1);
  });

  testWidgets('a row ripple paints on the sheet; the gesture inset is kept', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxBottomSheet(
        footer: const SizedBox(key: _footerKey, height: 40),
        child: InkWell(
          key: _rowKey,
          onTap: () {},
          child: const SizedBox(height: 48),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24),
    );

    expect(
      tester.widget<Material>(
        find
            .ancestor(of: find.byKey(_rowKey), matching: find.byType(Material))
            .first,
      ),
      same(
        tester.widget<Material>(
          find
              .descendant(
                of: find.byType(MxBottomSheet),
                matching: find.byType(Material),
              )
              .first,
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.byType(MxBottomSheet)).dy -
          tester.getBottomLeft(find.byKey(_footerKey)).dy,
      24,
    );
  });

  testWidgets('showMxBottomSheet: a 45% scrim; a scrim tap closes it (RF2)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Open',
          onPressed: () => showMxBottomSheet<void>(
            context,
            builder: (_) => MxBottomSheet(child: _rows(2)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(MxBottomSheet), findsOneWidget);
    expect(
      tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
      scheme.scrim.withValues(alpha: 0.45),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(MxBottomSheet), findsNothing);
  });
}
```

Before the closing `}` of `overlay_widgets_golden_test.dart`, append the tests below. Add imports for `mx_dialog.dart`, `mx_bottom_sheet.dart` and `mx_action_sheet_command_row.dart`.

```dart
  testWidgets('MxDialog with a destructive footer', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_dialog',
      MxDialog(
        title: 'Delete this deck?',
        body: 'Its 42 cards move to Trash, where they stay for 30 days.',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move to Trash',
          onConfirm: () {},
          isDestructive: true,
        ),
      ),
    );
  });

  testWidgets('MxBottomSheet with command rows', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_bottom_sheet',
      Align(
        alignment: Alignment.bottomCenter,
        child: MxBottomSheet(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                MxActionSheetCommandRow(
                  icon: AppIcons.edit,
                  label: 'Rename',
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: 'Move',
                  hasChevron: true,
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  subtitle: 'Recoverable for 30 days',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_dialog_test.dart test/shared/widgets/mx_bottom_sheet_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The width cap: 340, 320 or 300, never wider than the column.
enum MxDialogWidth { small, medium, large }

const double _enterScale = 0.94;

/// Opens [builder] (usually an MxDialog) over a 45% scrim. The dialog fades
/// in and scales from 0.94 over 200ms; it opens instantly under reduced
/// motion (ruling O7). A scrim tap dismisses it with null.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: context.colors.scrim.withValues(
    alpha: AppEffects.scrimOpacity,
  ),
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : AppDurations.standard,
  pageBuilder: (dialogContext, _, _) => builder(dialogContext),
  transitionBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: Easing.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
        child: child,
      ),
    );
  },
);

/// The centred modal for confirmations and short forms. The text sits 20 in
/// (ruling O5) and scrolls if it outgrows the screen; [actions], usually
/// MxSheetActions, stay below it.
class MxDialog extends StatelessWidget {
  const MxDialog({
    super.key,
    this.title,
    this.body,
    this.content,
    this.actions,
    this.width = MxDialogWidth.large,
  });

  final String? title;
  final String? body;

  /// A short form under the body.
  final Widget? content;
  final Widget? actions;
  final MxDialogWidth width;

  static const double _largeWidth = 340;
  static const double _mediumWidth = 320;
  static const double _smallWidth = 300;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final radius = BorderRadius.circular(AppRadius.xl);
    final hasText = title != null || body != null || content != null;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.card,
            vertical: AppSpacing.section,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: switch (width) {
                MxDialogWidth.large => _largeWidth,
                MxDialogWidth.medium => _mediumWidth,
                MxDialogWidth.small => _smallWidth,
              },
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: AppShadows.overlay(colors),
              ),
              child: Material(
                color: colors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: radius),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasText)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: actions == null
                              ? const EdgeInsets.all(AppSpacing.card)
                              : const EdgeInsetsDirectional.only(
                                  start: AppSpacing.card,
                                  end: AppSpacing.card,
                                  top: AppSpacing.card,
                                ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.control,
                            children: [
                              if (title case final text?)
                                Text(text, style: styles.compactTitle),
                              if (body case final text?)
                                Text(text, style: styles.dialogBody),
                              ?content,
                            ],
                          ),
                        ),
                      ),
                    ?actions,
                  ],
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

`lib/shared/widgets/mx_bottom_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

const _topRadius = BorderRadius.vertical(top: Radius.circular(AppRadius.xl));

/// Opens [builder] (usually an MxBottomSheet) on the platform modal route
/// over a 45% scrim, sliding up over 260ms. It opens instantly under reduced
/// motion (ruling O7). A scrim tap or a drag down dismisses it.
Future<T?> showMxBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.surfaceContainerHigh,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: _topRadius),
    barrierColor: colors.scrim.withValues(alpha: AppEffects.scrimOpacity),
    sheetAnimationStyle: AnimationStyle(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.sheet,
      curve: Easing.standard,
    ),
  );
}

/// The bottom-anchored modal for action lists and pickers. It stops at 85% of
/// the screen:
/// - only [child] scrolls, so [header] and [footer] stay in view (ruling
///   O12);
/// - the fill runs under the gesture bar, and the content stays above it.
///
/// It is a Material, so the ripple of a row inside is visible.
class MxBottomSheet extends StatelessWidget {
  const MxBottomSheet({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.hasGrabber = true,
  });

  final Widget child;
  final Widget? header;

  /// Usually MxSheetActions in its sheet form.
  final Widget? footer;

  /// The drag affordance; off for a sheet that is not draggable.
  final bool hasGrabber;

  static const double _maxHeightShare = 0.85;
  static const double _grabberWidth = 36;
  static const double _grabberHeight = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * _maxHeightShare,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _topRadius,
          boxShadow: AppShadows.chrome(colors),
        ),
        child: Material(
          color: colors.surfaceContainerHigh,
          shape: const RoundedRectangleBorder(borderRadius: _topRadius),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasGrabber)
                  Padding(
                    key: const ValueKey('mx-sheet-grabber'),
                    padding: const EdgeInsets.only(
                      top: AppSpacing.control,
                      bottom: AppSpacing.micro,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: _grabberWidth,
                        height: _grabberHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(
                              AppRadius.full,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ?header,
                Flexible(child: SingleChildScrollView(child: child)),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_dialog_test.dart test/shared/widgets/mx_bottom_sheet_test.dart`
Expected: PASS, 6 + 5 tests.

In the dialog width test, `find.byType(Material).last` is meant to be the dialog's surface, because the Scaffold's Material comes first in tree order. If it resolves to another Material, find the surface through `find.descendant(of: find.byType(MxDialog), …)` as `_surface` does, and record a test-only ruling.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 5 Step 5. Commit message: `feat(ui): MxDialog, MxBottomSheet`.

Check the golden:
- The dialog is a rounded surfaceContainerHigh card with a soft shadow, a 16/700 title, a body, and the footer with a red "Move to Trash".
- The sheet sits at the bottom, with a grabber, top-rounded corners and command rows.

---

### Task 7: Snackbar and MxDeckPickerSheet

**Files:**
- Create: `lib/shared/widgets/mx_snackbar.dart`, `lib/shared/widgets/mx_deck_picker_sheet.dart`
- Modify: `test/shared/widgets/overlay_widgets_golden_test.dart`
- Test: `test/shared/widgets/mx_snackbar_test.dart`, `test/shared/widgets/mx_deck_picker_sheet_test.dart`

**Interfaces:**
- Consumes: `snackbarMessage`, `snackbarAction`, `mxButtonStyle`, `MxBottomSheet(header:, footer:)`, `MxSheetActions.custom`, `MxListRow`, `MxIconTile`, `MxEmptyState`, `compactTitle`, `noteText`.
- Produces:
  - `MxSnackbarContent({required String message, String? actionLabel, VoidCallback? onAction})`
  - `SnackBar buildMxSnackBar(BuildContext context, {required String message, String? actionLabel, VoidCallback? onAction})`
  - `ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMxSnackbar(BuildContext context, {required String message, String? actionLabel, VoidCallback? onAction})`
  - `MxPickerCandidate({required String label, required VoidCallback onTap, String? reason, IconData icon = AppIcons.library, bool isEnabled = true})`
  - `MxDeckPickerSheet({required String title, required String rule, required List<MxPickerCandidate> candidates, required String dismissLabel, required VoidCallback onDismiss, required String emptyTitle, String? emptyBody})`

- [ ] **Step 1: Write the failing tests**

`test/shared/widgets/mx_snackbar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/widget_harness.dart';

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('a floating inverse toast: radius 12, padding 10 16', (
    tester,
  ) async {
    late SnackBar bar;
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          bar = buildMxSnackBar(context, message: 'Saved');
          return const SizedBox();
        },
      ),
    );

    expect(bar.backgroundColor, scheme.inverseSurface);
    expect(bar.behavior, SnackBarBehavior.floating);
    expect(
      (bar.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(12),
    );
    expect(
      bar.padding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  });

  testWidgets('14 message on the inverse surface; a 32 action in 48', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSnackbarContent(
          message: 'Moved to Trash',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
    );
    final message = tester.widget<Text>(find.text('Moved to Trash')).style!;
    final painted = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    );

    expect((message.fontSize, message.height), (14, 1.4));
    expect(message.color, scheme.onInverseSurface);
    expect(tester.getSize(painted.first).height, 32);
    expect(
      tester.getTopLeft(find.byType(TextButton)).dx -
          tester.getTopRight(find.text('Moved to Trash')).dx,
      12,
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('Undo hides the toast and calls onAction once (RF5)', (
    tester,
  ) async {
    var undos = 0;
    await pumpMx(
      tester,
      Builder(
        builder: (context) => MxButton(
          label: 'Delete',
          onPressed: () => showMxSnackbar(
            context,
            message: 'Moved to Trash',
            actionLabel: 'Undo',
            onAction: () => undos++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Moved to Trash'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undos, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a long message wraps; the action keeps its width (RF5)', (
    tester,
  ) async {
    Future<void> pumpMessage(String message) => pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSnackbarContent(
          message: message,
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
    );

    await pumpMessage('Saved');
    final action = tester.getSize(find.byType(TextButton)).width;
    final oneLine = tester.getSize(find.text('Saved')).height;

    final long = List.filled(10, 'Moved to Trash').join(' ');
    await pumpMessage(long);
    expect(tester.getSize(find.byType(TextButton)).width, action);
    expect(tester.getSize(find.text(long)).height, greaterThan(oneLine));
  });

  test('actionLabel and onAction come together', () {
    expect(
      () => MxSnackbarContent(message: 'Saved', actionLabel: 'Undo'),
      throwsAssertionError,
    );
  });
}
```

`test/shared/widgets/mx_deck_picker_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/widget_harness.dart';

MxDeckPickerSheet _picker(
  List<MxPickerCandidate> candidates, {
  VoidCallback? onDismiss,
}) => MxDeckPickerSheet(
  title: 'Move to deck',
  rule: 'Cards keep their progress.',
  candidates: candidates,
  dismissLabel: 'Cancel',
  onDismiss: onDismiss ?? () {},
  emptyTitle: 'Nowhere to move',
);

void main() {
  testWidgets('head: a 16/700 title and a 12 rule, 20 in and 4 down', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _picker([MxPickerCandidate(label: 'Kana', onTap: () {})]),
    );
    final sheet = tester.getTopLeft(find.byType(MxBottomSheet));

    expect(tester.widget<Text>(find.text('Move to deck')).style!.fontSize, 16);
    expect(
      tester.widget<Text>(find.text('Cards keep their progress.')).style!
          .fontSize,
      12,
    );
    // The grabber block is 8 + 4 + 4 = 16, then the head's 4.
    expect(
      tester.getTopLeft(find.text('Move to deck')) - sheet,
      const Offset(20, 20),
    );
  });

  testWidgets('candidates are chevron rows; an ineligible one keeps its reason',
      (tester) async {
    var picked = '';
    await pumpMx(
      tester,
      _picker([
        MxPickerCandidate(label: 'Kana', onTap: () => picked = 'Kana'),
        MxPickerCandidate(
          label: 'Grammar',
          reason: 'Holds other decks',
          isEnabled: false,
          onTap: () => picked = 'Grammar',
        ),
      ]),
    );
    final rows = tester.widgetList<MxListRow>(find.byType(MxListRow)).toList();

    expect(rows.map((row) => row.hasChevron), [true, true]);
    expect(rows.last.isEnabled, isFalse);
    expect(rows.last.subtitle, 'Holds other decks');
    expect(rows.map((row) => row.hasDivider), [true, false]);
    await tester.tap(find.text('Kana'));
    expect(picked, 'Kana');
    expect(
      tester.widget<MxButton>(find.byType(MxButton)).tone,
      MxButtonTone.outline,
    );
  });

  testWidgets('nowhere to go: a neutral compact EmptyState and one primary', (
    tester,
  ) async {
    await pumpMx(tester, _picker(const []));
    final empty = tester.widget<MxEmptyState>(find.byType(MxEmptyState));

    expect((empty.tone, empty.isCompact), (MxEmptyStateTone.neutral, true));
    expect(find.byType(MxListRow), findsNothing);
    expect(
      tester.widget<MxButton>(find.byType(MxButton)).tone,
      MxButtonTone.primary,
    );
  });

  testWidgets('many candidates scroll; the footer stays tappable (RF1)', (
    tester,
  ) async {
    var dismissed = 0;
    await pumpMx(
      tester,
      _picker([
        for (var i = 0; i < 30; i++)
          MxPickerCandidate(label: 'Deck $i', onTap: () {}),
      ], onDismiss: () => dismissed++),
    );

    expect(
      tester.getSize(find.byType(MxBottomSheet)).height,
      lessThanOrEqualTo(800 * 0.85),
    );
    await tester.tap(find.text('Cancel'));
    expect(dismissed, 1);
  });
}
```

Before the closing `}` of `overlay_widgets_golden_test.dart`, append the tests below. Add imports for `mx_snackbar.dart` and `mx_deck_picker_sheet.dart`.

```dart
  testWidgets('MxSnackbarContent on its inverse surface', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_snackbar',
      Builder(
        builder: (context) {
          // The surface buildMxSnackBar configures (ruling O9).
          Widget toast(Widget content) => DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: content,
            ),
          );
          return Column(
            spacing: 16,
            children: [
              toast(const MxSnackbarContent(message: 'Deck saved')),
              toast(
                MxSnackbarContent(
                  message: 'Moved to Trash',
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
              ),
              toast(
                MxSnackbarContent(
                  message:
                      'The export was saved to Downloads and is ready to '
                      'share with another device.',
                  actionLabel: 'Open',
                  onAction: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  });

  testWidgets('MxDeckPickerSheet with targets and with none', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_deck_picker',
      Column(
        spacing: 16,
        children: [
          MxDeckPickerSheet(
            title: 'Move to deck',
            rule: 'Cards keep their progress. Decks that hold other decks '
                'are not offered.',
            candidates: [
              MxPickerCandidate(label: 'Kana', onTap: () {}),
              MxPickerCandidate(label: 'Kanji N5', onTap: () {}),
              MxPickerCandidate(
                label: 'Grammar',
                reason: 'Holds other decks',
                isEnabled: false,
                onTap: () {},
              ),
            ],
            dismissLabel: 'Cancel',
            onDismiss: () {},
            emptyTitle: 'Nowhere to move',
          ),
          MxDeckPickerSheet(
            title: 'Move to deck',
            rule: 'Cards keep their progress.',
            candidates: const [],
            dismissLabel: 'OK',
            onDismiss: () {},
            emptyTitle: 'Nowhere to move',
            emptyBody: 'Create another deck first.',
          ),
        ],
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_snackbar_test.dart test/shared/widgets/mx_deck_picker_sheet_test.dart`
Expected: FAIL to compile, because the widget files do not exist.

- [ ] **Step 3: Implement**

`lib/shared/widgets/mx_snackbar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button_style.dart';

const double _verticalPadding = 10;

/// Shows the MemoX toast: a message and one optional action on the inverse
/// surface, which does not flip with the theme. Tapping the action hides the
/// toast first. How long it stays is the platform's call.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMxSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) => ScaffoldMessenger.of(context).showSnackBar(
  buildMxSnackBar(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  ),
);

/// The platform SnackBar that [showMxSnackbar] shows, configured with the
/// contract's surface (ruling O9).
SnackBar buildMxSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return SnackBar(
    backgroundColor: context.colors.inverseSurface,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsetsDirectional.only(
      start: AppSpacing.gutter,
      end: AppSpacing.gutter,
      bottom: AppSpacing.gutter,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gutter,
      vertical: _verticalPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    content: MxSnackbarContent(
      message: message,
      actionLabel: actionLabel,
      onAction: switch (onAction) {
        null => null,
        final action => () {
          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
          action();
        },
      },
    ),
  );
}

/// The toast's content: the message, which wraps, and the trailing action,
/// which keeps its width.
class MxSnackbarContent extends StatelessWidget {
  const MxSnackbarContent({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction come together',
       );

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The 48 minimum, less the 10 + 10 the SnackBar pads around this.
  static const double _minHeight = AppSize.touchTarget - 2 * _verticalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          Expanded(child: Text(message, style: styles.snackbarMessage)),
          if ((actionLabel, onAction) case (final label?, final onPressed?))
            TextButton(
              onPressed: onPressed,
              // Ruling O9: 32 painted inside the 48 target; the radius is
              // UNSPECIFIED and uses 8.
              style: mxButtonStyle(
                fill: null,
                ink: colors.inversePrimary,
                edge: BorderSide.none,
                focusColor: colors.inversePrimary,
                height: AppSize.buttonCompact,
                radius: AppRadius.sm,
                padding: AppSpacing.control,
                label: styles.snackbarAction,
              ),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
```

`lib/shared/widgets/mx_deck_picker_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// One destination in an MxDeckPickerSheet. It is generic: which decks are
/// eligible, and why, is the caller's (spec §5).
@immutable
final class MxPickerCandidate {
  const MxPickerCandidate({
    required this.label,
    required this.onTap,
    this.reason,
    this.icon = AppIcons.library,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback onTap;

  /// Why an ineligible destination cannot take the payload, shown as its
  /// sub-line.
  final String? reason;
  final IconData icon;
  final bool isEnabled;
}

/// Choose the deck this goes to: deck move, card move, Trash restore. It owns
/// the head typography and the scroll region that keeps the footer in view,
/// and nothing about eligibility. An ineligible candidate stays visible,
/// dimmed, with its reason.
class MxDeckPickerSheet extends StatelessWidget {
  const MxDeckPickerSheet({
    super.key,
    required this.title,
    required this.rule,
    required this.candidates,
    required this.dismissLabel,
    required this.onDismiss,
    required this.emptyTitle,
    this.emptyBody,
  });

  final String title;

  /// The one sentence stating what travels and what is not offered.
  final String rule;
  final List<MxPickerCandidate> candidates;

  /// Cancel with targets; OK when there is nowhere to go (ruling O11).
  final String dismissLabel;
  final VoidCallback onDismiss;
  final String emptyTitle;
  final String? emptyBody;

  /// Ruling O11: the title → rule gap is UNSPECIFIED.
  static const double _ruleGap = 4;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final isEmpty = candidates.isEmpty;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _ruleGap,
          children: [
            Text(title, style: styles.compactTitle),
            Text(rule, style: styles.noteText),
          ],
        ),
      ),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: dismissLabel,
              onPressed: onDismiss,
              tone: isEmpty ? MxButtonTone.primary : MxButtonTone.outline,
              isBlock: true,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.control,
          end: AppSpacing.control,
          bottom: AppSpacing.control,
        ),
        child: isEmpty
            ? MxEmptyState(
                icon: AppIcons.folder,
                title: emptyTitle,
                body: emptyBody,
                tone: MxEmptyStateTone.neutral,
                isCompact: true,
              )
            : Column(
                children: [
                  for (final (index, candidate) in candidates.indexed)
                    MxListRow(
                      title: candidate.label,
                      subtitle: candidate.reason,
                      leading: MxIconTile(icon: candidate.icon),
                      hasChevron: true,
                      onTap: candidate.onTap,
                      isEnabled: candidate.isEnabled,
                      hasDivider: index < candidates.length - 1,
                    ),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/shared/widgets/mx_snackbar_test.dart test/shared/widgets/mx_deck_picker_sheet_test.dart`
Expected: PASS, 5 + 4 tests.

- [ ] **Step 5: Golden, gate, commit**

Run the same commands as Task 5 Step 5. Commit message: `feat(ui): Snackbar, MxDeckPickerSheet`.

Check the golden:
- The toasts are the same dark surface in both themes, with a light-indigo action.
- The long message wraps, and its action keeps its size.
- The picker has a title, a rule line, and chevron rows; Grammar is dimmed with its reason.
- The picker has one Cancel at the bottom.
- The empty picker shows a compact neutral EmptyState and one primary OK.

---

### Task 8: Gallery, spec, gate

**Files:**
- Create: `lib/app/gallery/gallery_overlays_section.dart`
- Modify: `lib/app/gallery/gallery_states_section.dart`, `lib/app/gallery/gallery_screen.dart`, `test/app/gallery_test.dart`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`

- [ ] **Step 1: Write the failing gallery test**

In `test/app/gallery_test.dart`, add `'F · Overlays & feedback'` after `'E · Status & metadata'` in "every built group is present".

Also append this test, inside `main`:

```dart
  testWidgets('group F opens a dialog, a sheet and a snackbar', (
    tester,
  ) async {
    await _pumpGallery(tester);
    for (final (label, overlay) in [
      ('Dialog', find.byType(MxDialog)),
      ('Sheet', find.byType(MxBottomSheet)),
      ('Deck picker', find.byType(MxDeckPickerSheet)),
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 400));
      expect(overlay, findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.tap(find.text('Snackbar'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SnackBar), findsOneWidget);
  });
```

Add imports for `mx_dialog.dart`, `mx_bottom_sheet.dart` and `mx_deck_picker_sheet.dart`. The gallery holds spinners that never settle, so the test pumps fixed durations instead of calling `pumpAndSettle`.

Run: `flutter test test/app/gallery_test.dart`
Expected: FAIL, because 'F · Overlays & feedback' is not found.

- [ ] **Step 2: Create group F and extend group G**

`lib/app/gallery/gallery_overlays_section.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Group F: SheetActions and InlineBanner in place; the dialog, the sheets
/// and the snackbar open live.
class GalleryOverlaysSection extends StatelessWidget {
  const GalleryOverlaysSection({super.key});

  static const int _candidateCount = 8;

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'F · Overlays & feedback',
    children: [
      MxSheetActions(
        cancelLabel: 'Cancel',
        onCancel: () {},
        confirmLabel: 'Move to Trash',
        onConfirm: () {},
        isDestructive: true,
      ),
      const MxInlineBanner(
        tone: MxBannerTone.warning,
        title: 'Ten tags at most',
        message: 'Remove a tag before adding another one.',
      ),
      MxInlineBanner(
        tone: MxBannerTone.danger,
        message: 'The export could not be written.',
        actions: [
          MxButton(
            label: 'Retry',
            icon: AppIcons.retry,
            size: MxButtonSize.compact,
            onPressed: () {},
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxButton(
            label: 'Dialog',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openDialog(context)),
          ),
          MxButton(
            label: 'Sheet',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openSheet(context)),
          ),
          MxButton(
            label: 'Deck picker',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openPicker(context)),
          ),
          MxButton(
            label: 'Snackbar',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => showMxSnackbar(
              context,
              message: 'Moved to Trash',
              actionLabel: 'Undo',
              onAction: () {},
            ),
          ),
        ],
      ),
    ],
  );

  static Future<void> _openDialog(BuildContext context) => showMxDialog<void>(
    context,
    builder: (dialogContext) => MxDialog(
      title: 'Delete this deck?',
      body: 'Its 42 cards move to Trash, where they stay for 30 days.',
      actions: MxSheetActions(
        cancelLabel: 'Cancel',
        onCancel: () => Navigator.pop(dialogContext),
        confirmLabel: 'Move to Trash',
        onConfirm: () => Navigator.pop(dialogContext),
        isDestructive: true,
      ),
    ),
  );

  static Future<void> _openSheet(BuildContext context) =>
      showMxBottomSheet<void>(
        context,
        builder: (sheetContext) => MxBottomSheet(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
            child: Column(
              children: [
                MxActionSheetCommandRow(
                  icon: AppIcons.edit,
                  label: 'Rename',
                  onTap: () => Navigator.pop(sheetContext),
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: 'Move',
                  hasChevron: true,
                  onTap: () => Navigator.pop(sheetContext),
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  subtitle: 'Recoverable for 30 days',
                  isDestructive: true,
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        ),
      );

  static Future<void> _openPicker(BuildContext context) =>
      showMxBottomSheet<void>(
        context,
        builder: (sheetContext) => MxDeckPickerSheet(
          title: 'Move to deck',
          rule: 'Cards keep their progress. Decks that hold other decks are '
              'not offered.',
          candidates: [
            for (var i = 1; i <= _candidateCount; i++)
              MxPickerCandidate(
                label: 'Deck ${i.toString()}',
                onTap: () => Navigator.pop(sheetContext),
              ),
            MxPickerCandidate(
              label: 'Grammar',
              reason: 'Holds other decks',
              isEnabled: false,
              onTap: () {},
            ),
          ],
          dismissLabel: 'Cancel',
          onDismiss: () => Navigator.pop(sheetContext),
          emptyTitle: 'Nowhere to move',
        ),
      );
}
```

In `gallery_states_section.dart`:
- Add imports for `mx_error_state.dart`, `mx_skeleton.dart`, `mx_spinner.dart` and `app_spacing.dart`.
- Update the class doc to read: `/// Group G: loading, empty and error.`
- Append these children after the EmptyState loop:

```dart
      const MxSkeletonRow(),
      const MxSkeletonRow(),
      const Row(
        spacing: AppSpacing.gutter,
        children: [
          MxSpinner(),
          MxSpinner(size: MxSpinnerSize.compact),
          MxSpinner(size: MxSpinnerSize.standard),
          MxSpinner(size: MxSpinnerSize.large),
        ],
      ),
      MxErrorState(
        title: 'Could not load decks',
        body: 'Nothing was lost. Try again in a moment.',
        retryLabel: 'Retry',
        onRetry: () {},
      ),
      const MxErrorState(
        title: 'Deck not found',
        body: 'It may have been deleted on this device.',
        icon: AppIcons.alert,
      ),
```

In `gallery_screen.dart`:
- Import `gallery_overlays_section.dart`.
- Add `GalleryOverlaysSection(),` right after `GalleryStatusSection(),`.

Run: `flutter test test/app/gallery_test.dart`
Expected: PASS, including the 2x render with no exception.

- [ ] **Step 3: Check the app goldens**

```bash
flutter test --tags golden test/app/app_golden_test.dart
```

Expected: PASS. Task 3 already regenerated the gallery golden for the new spinner, and groups F and G sit below the first screen.

If `app_gallery_*` changes anyway:
1. Regenerate it with `--update-goldens`.
2. Open it and confirm that only the new groups differ.
3. Record a ruling.

- [ ] **Step 4: Record the rulings in spec §9**

Append after the last row (44):

```markdown
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
```

- [ ] **Step 5: Gate, scope, commit**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python tools/docs/check.py
git add lib/app test/app docs/superpowers
git commit -m "feat(app): phase 6 widgets in the gallery; record phase 6 rulings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git diff --name-only origin/master...HEAD
```

Expected:
- Every gate command exits 0.
- The guard reports 0 errors and 0 warnings.
- The diff lists only `lib/core/theme/`, `lib/shared/widgets/`, `lib/app/gallery/`, `test/` and `docs/superpowers/`.

---

### Task 9: The native impeccable audit over the gallery

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9, audit rows)

- [ ] **Step 1: Run the audit**

Invoke the Skill tool with `impeccable:impeccable`, arguments `audit lib/app/gallery (native Flutter)`. Follow its native audit reference (`reference/audit.native.md`). The target is:
- The gallery screen and its sections: `lib/app/gallery/*.dart`.
- The widgets they render: `lib/shared/widgets/*.dart`.
- The theme: `lib/core/theme/`.

The visual evidence is the committed goldens: `test/app/goldens/*.png` and `test/shared/widgets/goldens/*.png`. There is no emulator on this machine (row 18).

The audit changes no code and no token (spec §8.3, ruling O13).

- [ ] **Step 2: Record the findings**

Append one §9 row per finding, from row 55 on, in the form `| n | <finding, with the file and the measured value> | phase 6 audit |`.
- A finding that restates an existing row names that row instead of repeating it.
- If the audit finds nothing new, append one row that says so.

- [ ] **Step 3: Gate and commit**

```bash
python tools/docs/check.py
git add docs/superpowers
git commit -m "docs(spec): record the phase 6 impeccable audit

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Report to the user in Vietnamese:
- Counts and results.
- Every execution ruling.
- The audit findings.
- The new goldens, sent with SendUserFile.

Then ask through AskUserQuestion whether to open the PR and merge it. This is the last phase of the sub-project.
