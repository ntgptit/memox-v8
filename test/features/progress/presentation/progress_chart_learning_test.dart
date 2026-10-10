import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22's bars use colours that hold 3:1 on the card (critique
// 2026-10-02, F5): learning in its colour, reviewing in primary.
void main() {
  libraryTest('the learning series is the learning fill', (tester, env) async {
    await progressLibrary(env);
    await pumpLibraryScreen(
      tester,
      env,
      ProgressScreen(onOpenDeck: (_) {}, onStartStudying: () {}),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final chart = tester.widget<MxStackedDayBars>(
      find.byType(MxStackedDayBars),
    );
    final context = tester.element(find.byType(MxStackedDayBars));
    expect(chart.top.color, context.semanticColors.statusLearning);
    expect(chart.base.color, context.colors.primary);
  });
}
