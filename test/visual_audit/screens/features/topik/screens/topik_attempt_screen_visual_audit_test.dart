import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_attempt_fixtures.dart';
import '../../../../../support/topik_content_fixtures.dart';
import '../../../../../support/topik_fakes.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 37, ${locale.languageCode}', (tester, env) async {
      // Listening at its fullest: the audio bar, the script shown, an
      // option chosen.
      final test = topikTestFixture(section: TopikSection.listening);
      final store = TopikAttemptRepositoryImpl(env.db);
      final attempt = topikOk(await store.start(test, now: libraryToday));
      topikOk(
        await store.answer(
          attemptId: attempt.id,
          questionNo: test.questions.first.no,
          selectedIdx: 2,
          elapsedMs: 0,
          now: libraryToday,
        ),
      );
      await auditProductionScreen(
        tester,
        screen: TopikAttemptScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikAttemptScreen(
            attemptId: attempt.id,
            onClose: () {},
            onSubmitted: (_) {},
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
