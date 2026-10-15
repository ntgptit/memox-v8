import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_attempt_screen_fixtures.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_fakes.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 39, ${locale.languageCode}', (tester, env) async {
      // Listening at its fullest: audio, the open script, a wrong answer
      // with its explanation and word.
      final test = topikTestFixture(section: TopikSection.listening);
      final first = test.questions.first;
      final done = await topikSeedSubmitted(
        env,
        test,
        answers: {first.no: first.answerIdx % 4 + 1},
      );
      await auditProductionScreen(
        tester,
        screen: TopikReviewScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikReviewScreen(
            attemptId: done.id,
            onBack: () {},
            onBackToSummary: () {},
          ),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: [
            ...topikContentOverrides([test]),
            topikAudioRepositoryProvider.overrideWithValue(
              FakeTopikAudioRepository(),
            ),
          ],
        ),
      );
    });
  }
}
