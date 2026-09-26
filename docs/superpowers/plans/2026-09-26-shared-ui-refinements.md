# Shared UI refinements, phase 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the shared half of the owner's screen 06 review on `master`. Pairs of
footer buttons stop truncating or wrapping, cards use radius 12, a selecting checkbox
is vertically centred, and the overline reads as a section boundary.

**Architecture:**
- `MxButton` gains a single-line mode and can measure its own natural width. A new
  `MxActionPair` uses that measurement to place two buttons side by side or stacked.
- The card radius changes at its single source, `AppDecorations.raisedCard`, and every
  card tone derives from it.
- The overline changes at its single source, `MxTextStyles.overline`.
- The card list row centres its checkbox with `IntrinsicHeight` while selecting.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, flutter_test, Riverpod (untouched).

**Spec:** `docs/superpowers/specs/2026-09-26-shared-ui-refinements-design.md`

## Global Constraints

- Tokens only: no literal colour, spacing, radius or type size in widget code. A new
  numeric value is a named `static const` (the guard bans magic values).
- Radius: `MxCard` and every `AppDecorations.*Card` use `AppRadius.md` (12). Dialogs,
  bottom sheets, the empty-state 64 tile and the `meaning`/`term` text fields keep
  `AppRadius.xl` (20).
- Overline: 13/700, 0.6 tracking, tabular figures, colour `onSurface`, upper-cased by
  its callers as today.
- The gap between paired buttons is `AppSpacing.control` (8), in both layouts.
- A paired button's label never wraps and never ellipsizes.
- Goldens are rewritten only in this Linux container, after the unmodified suite has
  been shown green here. Never on Windows.
- Register rows 113–116 go into §9 of
  `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`, because FE-B1 uses
  108–112.

## Review Focus

1. **Vietnamese labels are longer than English ones.** A pair that fits in English must
   stack in Vietnamese. Task 2 tests with the vi label "Học lại bộ thẻ này" beside
   "Xong".
2. **Large text (text scale 2.0).** The pair must stack, and no label may be clipped.
   Task 2 has a test at scale 2.0.
3. **A disabled button (null `onPressed`).** It is wrapped in `Opacity`, and
   `naturalWidth` must still measure its label. Task 1 tests a disabled button.
4. **A loading button.** It keeps its width through `Visibility.maintain`, so
   `naturalWidth` ignores the spinner. Task 1 tests a loading button.
5. **A card list row with a two-line back or several tags.** The checkbox must be
   centred on the taller row, not on the first line. Task 5 tests a row with tags.

---

### Task 1: `MxButton.isSingleLine` and `MxButton.naturalWidth`

**Files:**
- Modify: `lib/shared/widgets/mx_button.dart`
- Test: `test/shared/widgets/mx_button_test.dart`

**Interfaces:**
- Produces:
  - `final bool isSingleLine` (constructor parameter `this.isSingleLine = false`):
    when true, the label renders with `maxLines: 1` and `softWrap: false`, whatever
    the size;
  - `double naturalWidth(BuildContext context)`: the width the button needs to show
    its label on one line. It is the label width at the button's label style and the
    context's `TextScaler`, plus the icon (`AppIconSize.inline`) and the
    `AppSpacing.micro` gap when there is an icon, plus twice the geometry's
    horizontal padding. The result is rounded up to a whole logical pixel.

- [ ] **Step 1: Write the failing tests** (append to `mx_button_test.dart`'s `main`)

```dart
  testWidgets('isSingleLine keeps a long label on one line', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 120,
        child: MxButton(
          label: 'Delete for good forever',
          isBlock: true,
          isSingleLine: true,
          onPressed: () {},
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Delete for good forever'));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
  });

  testWidgets('naturalWidth is the one-line label plus icon and padding', (
    tester,
  ) async {
    late double measured;
    const button = MxButton(
      label: 'Restore',
      icon: Icons.restore,
      onPressed: null,
    );
    await pumpMx(
      tester,
      Builder(
        builder: (context) {
          measured = button.naturalWidth(context);
          return const UnconstrainedBox(child: button);
        },
      ),
    );
    // Unconstrained, the button lays out at its natural width.
    expect(measured, tester.getSize(find.byType(TextButton)).width.ceilToDouble());
  });

  testWidgets('naturalWidth grows with the text scale', (tester) async {
    late double atOne;
    late double atTwo;
    final button = MxButton(label: 'Restore', onPressed: () {});
    await pumpMx(
      tester,
      Builder(builder: (context) {
        atOne = button.naturalWidth(context);
        return button;
      }),
    );
    await pumpMx(
      tester,
      Builder(builder: (context) {
        atTwo = button.naturalWidth(context);
        return button;
      }),
      textScale: 2,
    );
    expect(atTwo, greaterThan(atOne));
  });

  testWidgets('naturalWidth of a loading button still measures its label', (
    tester,
  ) async {
    late double idle;
    late double loading;
    await pumpMx(
      tester,
      Builder(builder: (context) {
        idle = MxButton(label: 'Save', onPressed: () {}).naturalWidth(context);
        loading = MxButton(
          label: 'Save',
          isLoading: true,
          onPressed: () {},
        ).naturalWidth(context);
        return const SizedBox();
      }),
    );
    expect(loading, idle);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_button_test.dart`
Expected: compile errors: `isSingleLine` and `naturalWidth` are not defined.

- [ ] **Step 3: Implement**

`TextPainter` comes with `package:flutter/material.dart`, so no new import is needed.
Then:

```dart
  const MxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = MxButtonTone.primary,
    this.size = MxButtonSize.regular,
    this.icon,
    this.isBlock = false,
    this.isLoading = false,
    this.isSingleLine = false,
    this.detail,
  }) : assert(
         detail == null ||
             size == MxButtonSize.regular ||
             size == MxButtonSize.small ||
             size == MxButtonSize.study,
         'a detail line needs a regular, small or study button',
       );

  /// Keeps the label on one line whatever the size: a caller that has
  /// checked [naturalWidth] (MxActionPair) never lets it wrap.
  final bool isSingleLine;

  /// The width this button needs to show its label on one line: the label at
  /// its style and the context's text scale, the icon and its gap, and the
  /// horizontal padding on both sides.
  double naturalWidth(BuildContext context) {
    final geometry = _geometryFor(size, hasIcon: icon != null);
    final style = geometry.isSmallType
        ? context.textStyles.buttonLabelSmall
        : context.textStyles.buttonLabel;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final iconWidth = icon == null ? 0 : AppIconSize.inline + AppSpacing.micro;
    final width = painter.width + iconWidth + geometry.padding * 2;
    painter.dispose();
    return width.ceilToDouble();
  }
```

In `_content`, replace the `labelText` construction with:

```dart
    final canWrap = geometry.canWrap && !isSingleLine;
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: canWrap ? _maxWrappedLines : 1,
      softWrap: canWrap,
    );
```

If the measured width in the second test is off by the `DefaultTextStyle` letter
spacing or font, resolve `style` the way `TextButton` does:
`DefaultTextStyle.of(context).style.merge(style)`. Keep the test as the judge.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_button_test.dart`
Expected: all tests pass, old and new.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_button.dart test/shared/widgets/mx_button_test.dart
git commit -m "feat(ui): MxButton single-line mode and natural width"
```

---

### Task 2: `MxActionPair`

**Files:**
- Create: `lib/shared/widgets/mx_action_pair.dart`
- Test: `test/shared/widgets/mx_action_pair_test.dart`

**Interfaces:**
- Consumes: `MxButton.isSingleLine`, `MxButton.naturalWidth(BuildContext)` (Task 1).
- Produces:

```dart
class MxActionPair extends StatelessWidget {
  const MxActionPair({
    super.key,
    this.leading,
    required this.trailing,
    this.leadingFlex = 1,
    this.trailingFlex = 1,
  });
  final MxButton? leading;
  final MxButton trailing;
  final int leadingFlex;
  final int trailingFlex;
}
```

Both buttons must be built with `isBlock: true, isSingleLine: true`; the constructor
does not assert this (it is `const`). `build` asserts it in debug mode.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

MxButton _button(String label, {IconData? icon}) => MxButton(
  label: label,
  icon: icon,
  isBlock: true,
  isSingleLine: true,
  onPressed: () {},
);

Widget _bar(MxActionPair pair) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: pair,
);

void main() {
  testWidgets('short labels sit side by side at equal widths, 8 apart', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _bar(MxActionPair(leading: _button('Back'), trailing: _button('Done'))),
    );
    final back = tester.getRect(find.widgetWithText(MxButton, 'Back'));
    final done = tester.getRect(find.widgetWithText(MxButton, 'Done'));

    expect(back.top, done.top);
    expect(back.width, done.width);
    expect(done.left - back.right, 8);
    expect(back.width + done.width + 8, 328);
  });

  testWidgets('side by side honours the flex shares', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Study'),
          trailing: _button('Done'),
          leadingFlex: 5,
          trailingFlex: 6,
        ),
      ),
    );
    final study = tester.getRect(find.widgetWithText(MxButton, 'Study'));
    final done = tester.getRect(find.widgetWithText(MxButton, 'Done'));

    expect(study.width / done.width, closeTo(5 / 6, 0.02));
  });

  testWidgets('a label that cannot fit its share stacks the pair, leading on '
      'top, full width, 8 apart', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Học lại bộ thẻ này', icon: Icons.play_arrow),
          trailing: _button('Xoá vĩnh viễn khỏi thùng rác', icon: Icons.delete),
        ),
      ),
    );
    final top = tester.getRect(
      find.widgetWithText(MxButton, 'Học lại bộ thẻ này'),
    );
    final bottom = tester.getRect(
      find.widgetWithText(MxButton, 'Xoá vĩnh viễn khỏi thùng rác'),
    );

    expect(top.width, 328);
    expect(bottom.width, 328);
    expect(bottom.top - top.bottom, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 2.0 stacks a pair that fits at 1.0', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Import another'),
          trailing: _button('View cards', icon: Icons.style),
        ),
      ),
      textScale: 2,
    );
    final first = tester.getRect(
      find.widgetWithText(MxButton, 'Import another'),
    );
    final second = tester.getRect(find.widgetWithText(MxButton, 'View cards'));

    expect(second.top, greaterThan(first.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no leading: the trailing button alone, full width', (
    tester,
  ) async {
    await pumpMx(tester, _bar(MxActionPair(trailing: _button('Close'))));

    expect(tester.getSize(find.byType(MxButton)).width, 328);
  });

  testWidgets('no paired label is ever ellipsized or wrapped', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Restore 2 cards', icon: Icons.restore),
          trailing: _button('Delete for good', icon: Icons.delete),
        ),
      ),
    );
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    }
    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    );
    for (final paragraph in paragraphs) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });
}
```

(Add `import 'package:flutter/rendering.dart';` for `RenderParagraph`.)

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/shared/widgets/mx_action_pair_test.dart`
Expected: compile error: `mx_action_pair.dart` does not exist.

- [ ] **Step 3: Implement** `lib/shared/widgets/mx_action_pair.dart`

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Two footer actions (spec 2026-09-26 D3): side by side when both labels
/// fit their share on one line, otherwise stacked full width, [leading] on
/// top. A paired label never wraps or ellipsizes, so its icon stays on the
/// line. Both buttons are built with `isBlock: true, isSingleLine: true`.
class MxActionPair extends StatelessWidget {
  const MxActionPair({
    super.key,
    this.leading,
    required this.trailing,
    this.leadingFlex = 1,
    this.trailingFlex = 1,
  });

  final MxButton? leading;
  final MxButton trailing;
  final int leadingFlex;
  final int trailingFlex;

  static const double _gap = AppSpacing.control;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    assert(
      [?leading, trailing].every((b) => b.isBlock && b.isSingleLine),
      'a paired button is block and single-line',
    );
    if (leading == null) return trailing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shared = constraints.maxWidth - _gap;
        final leadingShare =
            shared * leadingFlex / (leadingFlex + trailingFlex);
        final trailingShare = shared - leadingShare;
        final fits =
            leading.naturalWidth(context) <= leadingShare &&
            trailing.naturalWidth(context) <= trailingShare;
        if (!fits) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: _gap,
            children: [leading, trailing],
          );
        }
        return Row(
          spacing: _gap,
          children: [
            Expanded(flex: leadingFlex, child: leading),
            Expanded(flex: trailingFlex, child: trailing),
          ],
        );
      },
    );
  }
}
```

If the analyzer's Dart version rejects `[?leading, trailing]` (null-aware elements),
write `[if (leading != null) leading, trailing]`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/shared/widgets/mx_action_pair_test.dart`
Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_action_pair.dart test/shared/widgets/mx_action_pair_test.dart
git commit -m "feat(ui): MxActionPair stacks a footer pair that cannot fit"
```

---

### Task 3: Move the two paired footers to `MxActionPair`

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/session_summary_widget.dart`
- Modify: `lib/features/transfer/presentation/screens/card_import_screen.dart`
- Test: the existing tests of both screens (`test/features/study/...`,
  `test/features/transfer/...`). Find them with
  `grep -rln "SessionSummaryWidget\|CardImportScreen" test`.

**Interfaces:**
- Consumes: `MxActionPair` (Task 2), `MxButton.isSingleLine` (Task 1).

- [ ] **Step 1: Write the failing test** (in the session summary widget test file)

```dart
  testWidgets('the footer is one MxActionPair: Study this deck 5, Done 6', (
    tester,
  ) async {
    // Pump the summary exactly as that file's first test does, with an
    // outcome whose canStudyAgain is true.
    final pair = tester.widget<MxActionPair>(find.byType(MxActionPair));
    expect(pair.leadingFlex, 5);
    expect(pair.trailingFlex, 6);
    expect(pair.leading!.isSingleLine, isTrue);
  });
```

In the card import screen test file, add the same kind of test for the results
footer: `find.byType(MxActionPair)` finds one pair, and its `leading` is the outline
button.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test <the two test files>`
Expected: FAIL: no `MxActionPair` is found.

- [ ] **Step 3: Implement**

`session_summary_widget.dart`: replace the footer's `Row` with:

```dart
        child: MxActionPair(
          leading: outcome.canStudyAgain
              ? MxButton(
                  label: l10n.studyThisDeck,
                  tone: MxButtonTone.outline,
                  icon: AppIcons.play,
                  isBlock: true,
                  isSingleLine: true,
                  onPressed: onStudyDeck,
                )
              : null,
          trailing: MxButton(
            label: l10n.summaryDone,
            icon: AppIcons.check,
            isBlock: true,
            isSingleLine: true,
            onPressed: onDone,
          ),
          leadingFlex: _studyFlex,
          trailingFlex: _doneFlex,
        ),
```

Import `package:memox/shared/widgets/mx_action_pair.dart`. Drop the `app_spacing.dart`
import only if nothing else in the file uses `AppSpacing`.

`card_import_screen.dart`, `_resultShell`: replace the footer's `Row` with:

```dart
        child: MxActionPair(
          leading: switch (secondary) {
            (final label, final onPressed) => MxButton(
              label: label,
              tone: MxButtonTone.outline,
              isBlock: true,
              isSingleLine: true,
              onPressed: onPressed,
            ),
            null => null,
          },
          trailing: MxButton(
            label: primary.$1,
            icon: primary.$3,
            isBlock: true,
            isSingleLine: true,
            onPressed: primary.$2,
          ),
        ),
```

Import `mx_action_pair.dart`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/study test/features/transfer --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/study/presentation/widgets/sections/session_summary_widget.dart \
  lib/features/transfer/presentation/screens/card_import_screen.dart <the test files>
git commit -m "refactor(ui): summary and import results footers use MxActionPair"
```

---

### Task 4: Card radius 12

**Files:**
- Modify: `lib/core/theme/app_decorations.dart:9-21` (`raisedCard` radius and doc)
- Modify: `lib/core/theme/foundations/app_radius.dart` (doc comments of `md` and `xl`)
- Test: `test/core/theme/app_decorations_test.dart:20,44`,
  `test/shared/widgets/mx_card_test.dart:37-48`

**Interfaces:** none new. Every `AppDecorations.*Card` derives from `raisedCard`, so
`MxCard` in every tone, and `MxEmptyState`'s card surface, follow.

- [ ] **Step 1: Update the tests to the new contract (they fail)**

- `app_decorations_test.dart` line 20: `BorderRadius.circular(12)`. Line 44:
  `BorderRadius.circular(12)`.
- `mx_card_test.dart`: rename the first test to `'light: raised fill, radius 12, 20
  padding, whisper, no edge'` and expect `BorderRadius.circular(12)` on line 48.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/theme/app_decorations_test.dart test/shared/widgets/mx_card_test.dart`
Expected: FAIL: expected radius 12, actual 20.

- [ ] **Step 3: Implement**

`app_decorations.dart`:

```dart
  /// The Card surface: surface-raised fill and radius 12, the one radius of
  /// every in-flow surface (spec 2026-09-26 D2; kit: 20, register row 113);
  /// the whisper shadow in light and a 1px ghost border in dark, which has no
  /// shadow.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.md),
```

`app_radius.dart`:

```dart
  /// Card, button, input, note, banner, snackbar, 36–44 icon tile, small
  /// controls: the one radius of in-flow surfaces (spec 2026-09-26 D2).
  static const double md = 12;
```

```dart
  /// Dialog, bottom-sheet top corners, 64 empty-state tile, the meaning and
  /// term text fields: surfaces that float above the content.
  static const double xl = 20;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/theme test/shared/widgets --exclude-tags golden`
Expected: all pass. Dialog and bottom-sheet tests still expect 20.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_decorations.dart lib/core/theme/foundations/app_radius.dart \
  test/core/theme/app_decorations_test.dart test/shared/widgets/mx_card_test.dart
git commit -m "feat(ui): cards take radius 12, the in-flow surface radius"
```

---

### Task 5: Centre the card list's selecting checkbox

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_row_widget.dart:60-85`
- Test: `test/features/card/presentation/card_row_test.dart`

**Interfaces:** none new.

- [ ] **Step 1: Write the failing test** (append to `card_row_test.dart`'s `main`)

```dart
  libraryTest('while selecting, the checkbox is centred on a tall row', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host([
        CardRowWidget(
          item: _item(
            back: 'a back long enough to need its full line in the row',
            isFlagged: true,
            tags: ['hay nham', 'TOPIK I', 'dong tu'],
          ),
          isSelecting: true,
          isSelected: false,
        ),
      ]),
    );
    final box = tester.getRect(find.byType(MxSelectionCheckbox));
    final card = tester.getRect(
      find.descendant(
        of: find.byType(CardRowWidget),
        matching: find.byType(MxCard),
      ),
    );

    expect(box.center.dy, closeTo(card.center.dy, 0.5));
  });
```

(Import `package:memox/shared/widgets/mx_card.dart`.)

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/card/presentation/card_row_test.dart`
Expected: FAIL: the checkbox centre sits above the card centre.

- [ ] **Step 3: Implement**

In `CardRowWidget.build`, build the row as below. The leading slot changes only while
selecting. `IntrinsicHeight` gives the row a definite height so `Align` can centre
the checkbox; it is applied only while selecting, so the idle list pays nothing.

```dart
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.grouped,
      children: [
        if (isSelecting)
          Align(child: MxSelectionCheckbox(isChecked: isSelected))
        else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.micro),
            // The status line already says it: one announcement per row.
            child: ExcludeSemantics(
              child: MxStatusBadge(
                status: mxCardStatus(status),
                label: context.l10n.cardStatus(status),
                isDot: true,
              ),
            ),
          ),
        Expanded(child: _Content(item: item)),
        _Trailing(item: item),
      ],
    );
```

Then use `isSelecting ? IntrinsicHeight(child: row) : row` as the child of the
`Padding(padding: const EdgeInsets.all(_rowPadding), ...)`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card/presentation --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card/presentation/widgets/items/card_row_widget.dart \
  test/features/card/presentation/card_row_test.dart
git commit -m "feat(card): centre the selecting checkbox on the row"
```

---

### Task 6: Overline 13/700 in `onSurface`

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart:26` (constants) and `:260-268`
  (`overline`)
- Test: `test/core/theme/mx_text_styles_test.dart:240-252`

**Interfaces:** `MxTextStyles.overline` keeps its name and type. `statLabel` stays equal
to it (the test at line 424 still holds).

- [ ] **Step 1: Update the test (it fails)**

```dart
  test('overline 13/700 at 0.6, tabular, onSurface (spec 2026-09-26 D5)', () {
    expectStyle(
      styles.overline,
      size: 13,
      weight: FontWeight.w700,
      tracking: 0.6,
      color: scheme.onSurface,
    );
    expect(
      styles.overline.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/theme/mx_text_styles_test.dart`
Expected: FAIL: size 12 and colour `onSurfaceVariant`.

- [ ] **Step 3: Implement**

Beside `_overlineTracking`, add `static const double _overlineSize = 13;`. Then:

```dart
  /// Overline (Section, ListSectionHeader, field labels): 13/700, 0.6
  /// tracking, onSurface, so a group title reads as a boundary (spec
  /// 2026-09-26 D5; kit: 12 onSurfaceVariant, register row 114). Tabular, so
  /// a trailing static count lines up. The widget upper-cases the text.
  TextStyle get overline =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w700).copyWith(
        fontSize: _overlineSize,
        letterSpacing: _overlineTracking,
        fontFeatures: _tabular,
        color: _scheme.onSurface,
      );
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/theme test/shared/widgets --exclude-tags golden`
Expected: all pass. If a widget test pins the overline's colour, such as
`mx_list_section_header_test.dart` or `mx_section_test.dart`, update it to
`onSurface` in this task.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/mx_text_styles.dart test/core/theme/mx_text_styles_test.dart <any header test updated>
git commit -m "feat(ui): overline 13/700 onSurface, a clear group boundary"
```

---

### Task 7: Register rows, goldens and the gate

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9 table,
  after row 107)
- Modify: every golden PNG the changes above alter (`test/**/goldens/*.png`)

- [ ] **Step 1: Add the register rows** after row 107 of §9:

```markdown
| 113 | `MxCard` and every card surface use radius 12 (kit: 20), the one radius of in-flow surfaces with banners, notes and buttons; dialogs and sheets keep 20 | owner 2026-09-26, spec shared-ui-refinements D2 |
| 114 | `overline` is 13/700 in `onSurface` (kit: 12/700 `onSurfaceVariant`), so a group title reads as a boundary | owner 2026-09-26, D5 |
| 115 | A selecting row's checkbox is centred vertically on the row (kit: top-aligned with the title) | owner 2026-09-26, D4 |
| 116 | A footer pair stacks full width when a label cannot fit its share on one line (kit: always side by side, labels wrap) | owner 2026-09-26, D3 |
```

- [ ] **Step 2: Prove the container agrees with the committed goldens**

Use a scratch worktree of `origin/master`, so the branch is untouched:

```bash
git worktree add /tmp/claude-0/-home-user-memox-v8/017bbbf8-8b19-5f73-a1f9-ba2b801a72c2/scratchpad/master-wt origin/master
cd /tmp/claude-0/-home-user-memox-v8/017bbbf8-8b19-5f73-a1f9-ba2b801a72c2/scratchpad/master-wt
flutter pub get && flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/prepare_test_fonts.sh
TZ=UTC flutter test --tags golden
```

Expected: `All tests passed!`. If it fails, stop: the container disagrees with the
committed pictures, and regenerating from it is unsafe. Report the blocker instead.

- [ ] **Step 3: Regenerate the goldens on the branch**

```bash
cd /home/user/memox-v8
bash .claude/skills/flutter-workflow/scripts/prepare_test_fonts.sh
TZ=UTC flutter test --tags golden --update-goldens
git status --short -- 'test/**/goldens/*.png' | wc -l
```

- [ ] **Step 4: Check every changed golden by eye**

For each changed PNG, open the new file (Read tool) and confirm that only the
intended changes appear:
- card corners are 12;
- overline text is 13 and dark;
- the summary and import footers show the right layout;
- the card list's selecting checkbox is centred.

Nothing else may move. Any other difference is a bug: fix it in the owning task
before continuing.

- [ ] **Step 5: Run the goldens once more, without update**

Run: `TZ=UTC flutter test --tags golden`
Expected: `All tests passed!`

- [ ] **Step 6: The full gate, once**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: `✓ mechanical gates passed`.

- [ ] **Step 7: Commit, remove the worktree**

```bash
git add docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md test
git commit -m "test(ui): goldens for radius 12, overline, action pair; register 113-116"
git worktree remove /tmp/claude-0/-home-user-memox-v8/017bbbf8-8b19-5f73-a1f9-ba2b801a72c2/scratchpad/master-wt
```
