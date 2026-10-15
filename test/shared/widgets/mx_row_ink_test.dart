import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import '../../support/theme_expect.dart';

import 'package:memox/shared/widgets/mx_row_ink.dart';

import '../../support/widget_harness.dart';

void main() {
  testWidgets('static: no ripple and nothing to focus', (tester) async {
    await pumpMx(
      tester,
      const MxRowInk(onTap: null, child: SizedBox(width: 200, height: 48)),
    );

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a border radius shapes the ink and the focus ring', (
    tester,
  ) async {
    final radius = BorderRadius.circular(24);
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () {},
        borderRadius: radius,
        child: const SizedBox(width: 200, height: 48),
      ),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).borderRadius, radius);
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(MxRowInk),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration)
          .borderRadius,
      radius,
    );
  });

  testWidgets('tappable: fires, and focus draws the 2px focus ring', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () => taps++,
        child: const SizedBox(width: 200, height: 48),
      ),
    );
    await tester.tap(find.byType(MxRowInk));
    expect(taps, 1);

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxRowInk),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(
      ring.border,
      Border.all(color: accentOf(lightColorScheme), width: 2),
    );
  });

  testWidgets('disabled: 0.38, no tap, a disabled button', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () => taps++,
        isEnabled: false,
        child: const Text('Move here'),
      ),
    );
    await tester.tap(find.byType(MxRowInk), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxRowInk),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
    expect(
      tester.getSemantics(find.text('Move here')),
      isSemantics(
        label: 'Move here',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets(
    'shouldDimWhenDisabled false blocks taps without painting opacity',
    (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxRowInk(
          onTap: () => taps++,
          isEnabled: false,
          shouldDimWhenDisabled: false,
          child: const SizedBox(height: 48, child: Text('Row')),
        ),
      );
      await tester.tap(find.text('Row'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        find.ancestor(of: find.text('Row'), matching: find.byType(Opacity)),
        findsNothing,
      );
    },
  );

  // SW-REV-005: a row that selects on a long-press (Card list, Trash) says
  // so through the row, not through a GestureDetector bolted around it.
  testWidgets('onLongPress: a long-press runs it, and TalkBack offers it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var held = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () {},
        onLongPress: () => held++,
        child: const SizedBox(width: 200, height: 56, child: Text('Row')),
      ),
    );
    await tester.longPress(find.text('Row'));

    expect(held, 1);
    expect(
      tester.getSemantics(find.text('Row')),
      isSemantics(hasTapAction: true, hasLongPressAction: true),
    );
    handle.dispose();
  });

  // M3F-10: a row that is a choice says so on its own node, so a consumer
  // needs no Semantics of its own around the row.
  for (final isSelected in [true, false]) {
    testWidgets('M3F-10: isSelected $isSelected is on the row node with its '
        'label and tap', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(
        tester,
        MxRowInk(
          onTap: () {},
          isSelected: isSelected,
          child: const SizedBox(width: 200, height: 56, child: Text('Row')),
        ),
      );

      expect(
        tester.getSemantics(find.text('Row')),
        isSemantics(
          label: 'Row',
          isButton: true,
          isSelected: isSelected,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  }

  testWidgets('M3F-10: a disabled selected row keeps the selected state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () {},
        isEnabled: false,
        isSelected: true,
        child: const Text('Row'),
      ),
    );

    expect(
      tester.getSemantics(find.text('Row')),
      isSemantics(
        label: 'Row',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('M3F-10: a static selected row still says it is selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxRowInk(onTap: null, isSelected: true, child: Text('Row')),
    );

    expect(
      tester.getSemantics(find.text('Row')),
      isSemantics(label: 'Row', isSelected: true, hasSelectedState: true),
    );
    handle.dispose();
  });

  testWidgets('M3F-10: no isSelected means no selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, MxRowInk(onTap: () {}, child: const Text('Row')));

    expect(
      tester.getSemantics(find.text('Row')),
      isSemantics(
        label: 'Row',
        isButton: true,
        hasSelectedState: false,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
