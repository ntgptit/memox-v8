import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
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

  testWidgets('tappable: fires, and focus draws the 2px primary ring', (
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
      Border.all(color: AppColorSchemes.light.primary, width: 2),
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
}
