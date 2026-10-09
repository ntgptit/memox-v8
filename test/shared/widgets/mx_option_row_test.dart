import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../support/widget_harness.dart';

const _radioKey = ValueKey('mx-option-radio');

Border _ring(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(find.byKey(_radioKey)).decoration
                as BoxDecoration)
            .border!
        as Border;

// The painted focus ring: the one CustomPaint whose painter is the shared one.
Finder _ringFinder() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
);

MxFocusRingPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_ringFinder()).foregroundPainter!
        as MxFocusRingPainter;

void _showFocusRings() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unselected 2px outline ring; selected 6px primaryForeground', (
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
      BorderSide(color: MxSemanticColors.light.primaryForeground, width: 6),
    );
    expect(tester.getSize(find.byKey(_radioKey)), const Size.square(20));
  });

  // The ring is a stroke glyph, so it inks in primaryForeground: the dark
  // primary reads 2.46:1 on a sheet, below the 3:1 of a state.
  testWidgets('dark: the selected ring is primaryForeground', (tester) async {
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
      brightness: Brightness.dark,
    );
    expect(_ring(tester).top.color, MxSemanticColors.dark.primaryForeground);
  });

  testWidgets('both themes: the unselected ring is outline, the selected '
      'ring primaryForeground', (tester) async {
    for (final brightness in Brightness.values) {
      final isLight = brightness == Brightness.light;
      final colors = isLight ? AppColorSchemes.light : AppColorSchemes.dark;
      final semantic = isLight ? MxSemanticColors.light : MxSemanticColors.dark;
      await pumpMx(
        tester,
        MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(_ring(tester).top.color, colors.outline);
      await pumpMx(
        tester,
        MxOptionRow(title: 'SM-2', isSelected: true, onSelected: () {}),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(_ring(tester).top.color, semantic.primaryForeground);
    }
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

  testWidgets('a dimmed row keeps its description at full ink', (tester) async {
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

  testWidgets('focus: the shared ring inside the row in primaryForeground', (
    tester,
  ) async {
    _showFocusRings();
    await pumpMx(
      tester,
      MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
    );
    expect(_ringFinder(), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(_ringFinder(), findsOneWidget);
    expect(_painter(tester).color, MxSemanticColors.light.primaryForeground);
    expect(_painter(tester).placement, MxFocusRingPlacement.inside);
  });

  testWidgets('a row without onSelected takes no focus and paints no ring', (
    tester,
  ) async {
    _showFocusRings();
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: false, onSelected: null),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(_ringFinder(), findsNothing);
  });
}
