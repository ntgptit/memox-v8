import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_cta_row_widget.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

// FE-A6 P4: the turn clock (19; pre-plan rulings V2, V3, V5, V9) and the
// kit's StudyCtaRow.

Widget _host(Widget child, {bool isStill = false}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: isStill),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _fillOf(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  libraryTest('the clock is one node, its caption with the seconds left as '
      'its value, and its fill is the time left (V3, V5)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const RecallCountdownBarWidget(
          caption: 'Time to recall',
          remainingMs: 13400,
          isTimedOut: false,
        ),
      ),
    );

    expect(find.text('14s / 20s'), findsOneWidget);
    final node = tester.getSemantics(find.byType(RecallCountdownBarWidget));
    expect(node.label, 'Time to recall');
    expect(node.value, '14 seconds left');
    expect(_fillOf(tester), closeTo(13400 / 20000, 1e-9));
    handle.dispose();
  });

  libraryTest('under Remove animations the fill steps by whole seconds (V9)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        const RecallCountdownBarWidget(
          caption: 'c',
          remainingMs: 13400,
          isTimedOut: false,
        ),
        isStill: true,
      ),
    );

    expect(_fillOf(tester), 14000 / 20000);
  });

  libraryTest('two actions share the row; at large text they stack', (
    tester,
    env,
  ) async {
    const row = StudyCtaRowWidget(
      children: [
        MxButton(label: 'Forgot', isBlock: true, onPressed: null),
        MxButton(label: 'Remembered', isBlock: true, onPressed: null),
      ],
    );
    await pumpLibraryScreen(tester, env, _host(row));
    expect(
      tester.getCenter(find.text('Forgot')).dy,
      tester.getCenter(find.text('Remembered')).dy,
    );
    expect(tester.getSize(find.byType(MxButton).first).width, 160);

    await pumpLibraryScreen(tester, env, _host(row), textScale: 1.3);
    expect(
      tester.getCenter(find.text('Forgot')).dy,
      lessThan(tester.getCenter(find.text('Remembered')).dy),
    );
  });
}
