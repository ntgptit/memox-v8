import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/topik_screen_fixtures.dart';
import '../../../../screen_audit.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    libraryTest('screen 35, ${locale.languageCode}', (tester, env) async {
      // The longest rows: a test in progress with a best score.
      final tests = topikScreenTests();
      final test = tests.firstWhere(
        (t) => t.level == TopikLevel.topik2 && t.round == 96,
      );
      await topikSeedCompleted(env, test, startedAt: libraryToday, correct: 41);
      await topikSeedInProgress(
        env,
        test,
        startedAt: libraryToday.add(const Duration(hours: 1)),
      );
      await auditProductionScreen(
        tester,
        screen: TopikTestListScreen,
        pump: (brightness, scale) => pumpLibraryScreen(
          tester,
          env,
          TopikTestListScreen(level: TopikLevel.topik2, onOpenTest: (_) {}),
          brightness: brightness,
          textScale: scale,
          locale: locale,
          overrides: topikContentOverrides(tests),
        ),
      );
    });
  }
}
