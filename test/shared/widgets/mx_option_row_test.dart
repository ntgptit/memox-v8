import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../support/widget_harness.dart';

const _radioKey = ValueKey('mx-option-radio');

Border _ring(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(find.byKey(_radioKey)).decoration
                as BoxDecoration)
            .border!
        as Border;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unselected 2px outline ring; selected 6px primaryInk', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
    );
    expect(_ring(tester).top, BorderSide(color: scheme.outline, width: 2));
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(20));

    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
    );
    expect(
      _ring(tester).top,
      BorderSide(color: MxDerivedColors.primaryInkOf(scheme), width: 6),
    );
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(20));
  });

  // Spec 2026-09-27: the ring is a stroke glyph, so it inks in primaryInk.
  // The dark primary reads 2.46:1 on a sheet, below the 3:1 of a state.
  testWidgets('dark: the selected ring is primaryInk', (tester) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
      brightness: Brightness.dark,
    );
    expect(
      _ring(tester).top.color,
      MxDerivedColors.primaryInkOf(AppColorSchemes.dark),
    );
  });

  testWidgets('at least 48 tall; a description wraps and grows the row', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          isSelected: false,
          onSelected: () {},
        ),
      ),
    );
    final short = tester.getSize(find.byType(MxOptionRow)).height;
    expect(short, greaterThanOrEqualTo(48));

    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          description:
              'Cards climb eight boxes, each a longer interval than the '
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
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () => taps++),
    );
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
    await pumpMx(
      tester,
      MxOptionRow(
        title: 'A',
        isSelected: false,
        onSelected: () {},
        hasDivider: false,
      ),
    );
    expect(
      tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(MxOptionRow),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where(
            (box) =>
                (box.decoration as BoxDecoration).border is Border &&
                box.key != _radioKey,
          ),
      isEmpty,
    );

    await pumpMx(
      tester,
      const MxOptionRow(title: 'A', isSelected: false, onSelected: null),
    );
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byKey(_radioKey),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });

  testWidgets('a row not selectable yet can keep full contrast: isDimmed '
      'false (FE-A6 spec §3)', (tester) async {
    await pumpMx(
      tester,
      const MxOptionRow(
        title: 'Recall',
        isSelected: false,
        onSelected: null,
        isDimmed: false,
      ),
    );

    expect(
      find.ancestor(of: find.text('Recall'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });
}
