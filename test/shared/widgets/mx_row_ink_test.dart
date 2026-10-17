import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

void main() {
  testWidgets('static: no ripple and nothing to focus', (tester) async {
    await pumpMx(
      tester,
      const MxRowInk(onTap: null, child: SizedBox(width: 200, height: 48)),
    );

    expect(find.byType(FTappable), findsNothing);
    // Nothing in it takes the keyboard focus.
    useKeyboardFocusHighlight();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(MxRowInk),
        matching: find.byWidgetPredicate(
          (widget) => widget is Focus && widget.focusNode?.hasFocus == true,
        ),
      ),
      findsNothing,
    );
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

    final outline = tester.widget<FFocusedOutline>(
      find.descendant(
        of: find.byType(MxRowInk),
        matching: find.byType(FFocusedOutline),
      ),
    );
    expect(
      outline
          .style(
            forUiTheme(tester, find.byType(MxRowInk)).style.focusedOutlineStyle,
          )
          .borderRadius,
      radius,
    );
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

  testWidgets('tappable: fires, and focus draws the theme focus ring', (
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
    await tester.pumpAndSettle();
    expect(taps, 1);

    useKeyboardFocusHighlight();
    final ring = forUiTheme(
      tester,
      find.byType(MxRowInk),
    ).style.focusedOutlineStyle;
    expect(
      tester.renderObject(find.byType(FFocusedOutline)),
      isNot(paintsFocusRing(ring.color, width: ring.width)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      focusRingRender(tester),
      paintsFocusRing(ring.color, width: ring.width),
    );
  });

  testWidgets("press: the ground shows within a frame, as ForUI's item "
      'press layer does (not after the 100 ms tappable default)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxRowInk(onTap: () {}, child: const SizedBox(width: 200, height: 48)),
    );
    final theme = forUiTheme(tester, find.byType(MxRowInk));
    Color? ground() {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxRowInk),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    expect(ground(), isNull);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MxRowInk)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(ground(), theme.colors.secondary);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(ground(), isNull);
  });

  testWidgets('disabled: dimmed, no tap, a disabled button', (tester) async {
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
      appLightColors.disabledOpacity,
    );
    expect(
      tester.getSemantics(find.text('Move here')),
      isSemantics(
        label: 'Move here',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        // ForUI's tappable always reports a selected state, never selected.
        hasSelectedState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('M3F-17: disabled blocks a control inside the row and keeps its '
      'node, with and without a tap', (tester) async {
    final handle = tester.ensureSemantics();
    var inner = 0;
    for (final onTap in <VoidCallback?>[() {}, null]) {
      await pumpMx(
        tester,
        MxRowInk(
          onTap: onTap,
          isEnabled: false,
          child: MxButton(
            label: 'Go',
            tone: MxButtonTone.text,
            onPressed: () => inner++,
          ),
        ),
      );
      await tester.tap(find.text('Go'), warnIfMissed: false);
      expect(inner, 0);
      expect(
        tester.getSemantics(find.text('Go')),
        isSemantics(label: 'Go', hasTapAction: false),
      );
    }
    handle.dispose();
  });

  testWidgets('M3F-17: an enabled static row leaves its controls live', (
    tester,
  ) async {
    var inner = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: null,
        child: MxButton(
          label: 'Go',
          tone: MxButtonTone.text,
          onPressed: () => inner++,
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(inner, 1);
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
    await tester.pumpAndSettle();

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

  testWidgets('M3F-10: no isSelected means never selected', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, MxRowInk(onTap: () {}, child: const Text('Row')));

    // ForUI's tappable reports a selected state on every button: never
    // selected here.
    expect(
      tester.getSemantics(find.text('Row')),
      isSemantics(
        label: 'Row',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    await pumpMx(tester, const MxRowInk(onTap: null, child: Text('Static')));
    expect(
      tester.getSemantics(find.text('Static')),
      isSemantics(label: 'Static', hasSelectedState: false),
    );
    handle.dispose();
  });
}
