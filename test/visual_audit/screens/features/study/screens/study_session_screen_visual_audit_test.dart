import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/study_fixtures.dart';
import '../../../../screen_audit.dart';

Future<void> _audit(WidgetTester tester, LibraryEnv env) =>
    auditProductionScreen(
      tester,
      screen: StudySessionScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const StudySessionScreen(sessionId: 's'),
        brightness: brightness,
        textScale: scale,
      ),
    );

void main() {
  libraryTest('screen 16, a Browse stage in progress', (tester, env) async {
    await seedBrowseSession(env.db, env.decks, startedAt: libraryToday);
    await _audit(tester, env);
  });

  libraryTest('screen 21, a finished review', (tester, env) async {
    await seedEndedSession(env.db, env.decks, status: 'completed');
    await _audit(tester, env);
  });

  libraryTest('screen 21, left early', (tester, env) async {
    await seedEndedSession(
      env.db,
      env.decks,
      status: 'abandoned',
      endReason: 'user_exit',
    );
    await _audit(tester, env);
  });
}
