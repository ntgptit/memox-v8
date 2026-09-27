@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

const _session = StudySessionScreen(sessionId: 's');

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('study session, browse, $theme', (tester, env) async {
      await seedBrowseSession(env.db, env.decks, startedAt: libraryToday);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _session, brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_session_browse_$theme.png',
        );
      });
    });

    libraryTest('study summary, review finished, $theme', (tester, env) async {
      await seedEndedSession(env.db, env.decks, status: 'completed');
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _session, brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_summary_review_$theme.png',
        );
      });
    });

    libraryTest('study summary, left early, $theme', (tester, env) async {
      await seedEndedSession(
        env.db,
        env.decks,
        status: 'abandoned',
        endReason: 'user_exit',
        answered: 2,
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _session, brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_summary_left_early_$theme.png',
        );
      });
    });
  }
}
