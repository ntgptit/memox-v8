import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/widget_harness.dart';

// Critique 2026-09-30 part 3c-2, R1: an action swapped in place under the
// finger takes no tap for 400 ms.

Widget _guarded(Object phase, VoidCallback onTap, {bool isStill = false}) =>
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: isStill),
        child: StudySettleGuardWidget(
          phase: phase,
          child: MxButton(label: 'Go', onPressed: onTap),
        ),
      ),
    );

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(StudySettleGuardWidget),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('the first build takes a tap at once', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++));

    await tester.tap(find.text('Go'));

    expect(taps, 1);
    expect(_opacity(tester), 1);
  });

  testWidgets('after a swap the row takes no tap for 400 ms and eases in '
      'from muted, then takes one', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++));
    await pumpMx(tester, _guarded(true, () => taps++));
    await tester.pump(const Duration(milliseconds: 100));

    expect(_opacity(tester), inExclusiveRange(AppOpacity.muted, 1));
    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
    expect(_opacity(tester), 1);
  });

  testWidgets('under Remove animations the row shows at full opacity and is '
      'still guarded', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++, isStill: true));
    await pumpMx(tester, _guarded(true, () => taps++, isStill: true));
    await tester.pump(const Duration(milliseconds: 100));

    expect(_opacity(tester), 1);
    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('the platform Remove animations flag does not shorten the '
      'guard (Review Focus 1)', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var taps = 0;
    await pumpMx(tester, _guarded(false, () => taps++));
    await pumpMx(tester, _guarded(true, () => taps++));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Go'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('the same phase rebuilt is not a swap', (tester) async {
    var taps = 0;
    await pumpMx(tester, _guarded(true, () => taps++));
    await pumpMx(tester, _guarded(true, () => taps++));

    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });
}
