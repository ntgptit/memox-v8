import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_attempt_screen_fixtures.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 38, ${locale.languageCode}', (tester, env) async {
      // A mixed result: every status, the weakest type.
      final test = topikTestFixture();
      final done = await topikSeedSubmitted(
        env,
        test,
        answers: {
          for (final (i, q) in test.questions.indexed)
            if (i.isEven) q.no: i % 4 == 0 ? q.answerIdx : q.answerIdx % 4 + 1,
        },
      );
      await auditProductionScreen(
        tester,
        screen: TopikSummaryScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikSummaryScreen(
            attemptId: done.id,
            onReview: (_) {},
            onDone: () {},
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
