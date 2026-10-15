import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 36, ${locale.languageCode}', (tester, env) async {
      // Overview at its fullest: completed attempts and one in progress.
      final test = topikTestFixture();
      for (final day in [3, 2]) {
        await topikSeedCompleted(
          env,
          test,
          startedAt: libraryToday.subtract(Duration(days: day)),
          correct: 30,
        );
      }
      await topikSeedInProgress(
        env,
        test,
        startedAt: libraryToday.subtract(const Duration(hours: 2)),
      );
      await auditProductionScreen(
        tester,
        screen: TopikTestDetailScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikTestDetailScreen(
            testId: test.testId,
            onOpenAttempt: (_) {},
            onOpenSummary: (_) {},
            onOpenReview: (_) {},
            onBackToTests: () {},
          ),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: topikContentOverrides([test]),
        ),
      );
    });
  }
}
