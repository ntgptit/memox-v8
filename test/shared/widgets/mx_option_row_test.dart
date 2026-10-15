import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/theme_expect.dart';

import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../support/widget_harness.dart';

const _radioKey = ValueKey('mx-option-radio');
const _dotKey = ValueKey('mx-option-radio-dot');

Border _ring(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(find.byKey(_radioKey)).decoration
                as BoxDecoration)
            .border!
        as Border;

BoxDecoration _dot(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byKey(_dotKey)).decoration
        as BoxDecoration;

void main() {
  final scheme = lightColorScheme;

  // Material 3 radio: an 18 ring stroked 2, a 9 dot (inner radius 4.5) when
  // selected; the unselected ring is onSurfaceVariant.
  testWidgets('unselected: a 2px onSurfaceVariant ring, no dot', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
    );
    expect(
      _ring(tester).top,
      BorderSide(color: scheme.onSurfaceVariant, width: 2),
    );
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(18));
    expect(find.byKey(_dotKey), findsNothing);
  });

  testWidgets('selected: the same 2px ring and a 9 dot, both accent', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
    );
    expect(_ring(tester).top, BorderSide(color: accentOf(scheme), width: 2));
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(18));
    expect(tester.getSize(find.byKey(_dotKey)), const Size.square(9));
    expect(_dot(tester).color, accentOf(scheme));
    expect(_dot(tester).shape, BoxShape.circle);
    expect(
      tester.getCenter(find.byKey(_dotKey)),
      tester.getCenter(find.byKey(_radioKey)),
    );
  });

  // The ring is a stroke glyph, so it reads the accent colour.
  // The dark primary reads 2.46:1 on a sheet, below the 3:1 of a state.
  testWidgets('dark: the selected ring and dot are the accent colour', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
      brightness: Brightness.dark,
    );
    expect(_ring(tester).top.color, accentOf(darkColorScheme));
    expect(_dot(tester).color, accentOf(darkColorScheme));

    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
      brightness: Brightness.dark,
    );
    expect(_ring(tester).top.color, darkColorScheme.onSurfaceVariant);
  });

  testWidgets('56 tall, 72 with a description; a long one grows the row', (
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
    expect(short, 56);

    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxOptionRow(
          title: 'Eight box',
          description: 'Eight intervals',
          isSelected: false,
          onSelected: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(MxOptionRow)).height, 72);

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
    expect(tester.getSize(find.byType(MxOptionRow)).height, greaterThan(72));
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

  testWidgets('disabled at 0.38', (tester) async {
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

  testWidgets('a selected row that cannot change is not dimmed (critique '
      '2026-09-30: the locked algorithm)', (tester) async {
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: true, onSelected: null),
    );
    expect(
      find.ancestor(of: find.text('SM-2'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('a dimmed row keeps its description at full strength', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxOptionRow(
        title: 'Guess',
        description: 'Needs five different meanings',
        isSelected: false,
        onSelected: null,
      ),
    );
    expect(
      find.ancestor(of: find.text('Guess'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Needs five different meanings'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  // SW-REV-006: a row that cannot be picked is announced as disabled.
  testWidgets('a row that cannot be picked is a disabled radio to TalkBack', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: false, onSelected: null),
    );
    expect(
      tester.getSemantics(find.text('SM-2')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  // M3F-05: the row was a bare InkWell, so a keyboard user saw only the
  // theme's focus layer. MxRowInk draws the shared 2px primary ring.
  for (final brightness in Brightness.values) {
    final focusScheme = brightness == Brightness.light
        ? lightColorScheme
        : darkColorScheme;
    testWidgets('M3F-05: a focused row draws the 2px primary ring '
        '(${brightness.name})', (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () => taps++),
        brightness: brightness,
      );
      useKeyboardFocusHighlight();
      expect(
        tester.renderObject(find.byType(MxOptionRow)),
        isNot(paintsFocusRing(focusScheme.primary)),
      );

      await tabTo(tester, find.text('SM-2'));

      expect(focusedRender(tester), paintsFocusRing(focusScheme.primary));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });
  }

  testWidgets('M3F-05: a row that cannot be picked takes no focus', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: false, onSelected: null),
    );
    useKeyboardFocusHighlight();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      tester.renderObject(find.byType(MxOptionRow)),
      isNot(paintsFocusRing(lightColorScheme.primary)),
    );
  });
}
