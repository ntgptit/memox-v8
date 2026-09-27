import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('a completed review shows its facts (loaded)', (
    tester,
    env,
  ) async {
    await seedEndedSession(env.db, env.decks, status: 'completed');
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleReview), findsOneWidget);
    expect(find.text('4'), findsWidgets); // answered and/or total turns.
    expect(find.text('1'), findsWidgets); // wrong turns.
  });

  libraryTest('a completed learning session shows learning copy', (
    tester,
    env,
  ) async {
    await seedEndedSession(
      env.db,
      env.decks,
      status: 'completed',
      sessionKind: 'learning',
    );
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleLearning), findsOneWidget);
  });

  libraryTest('abandoned/user_exit shows leftEarly, turns kept', (
    tester,
    env,
  ) async {
    await seedEndedSession(
      env.db,
      env.decks,
      status: 'abandoned',
      endReason: 'user_exit',
    );
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleLeftEarly), findsOneWidget);
  });

  libraryTest('abandoned/interrupted shows interrupted copy', (
    tester,
    env,
  ) async {
    await seedEndedSession(
      env.db,
      env.decks,
      status: 'abandoned',
      endReason: 'interrupted',
    );
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleInterrupted), findsOneWidget);
  });

  libraryTest('invalidated/scheduler_reset shows reset copy', (
    tester,
    env,
  ) async {
    await seedEndedSession(
      env.db,
      env.decks,
      status: 'invalidated',
      endReason: 'scheduler_reset',
    );
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleReset), findsOneWidget);
  });

  libraryTest('invalidated/scheduler_changed shows its copy and no facts '
      'card (handoff 21: "no BR limits the summary" does not apply here — '
      'the kit itself draws none)', (tester, env) async {
    await seedEndedSession(
      env.db,
      env.decks,
      status: 'invalidated',
      endReason: 'scheduler_changed',
    );
    await pumpLibraryScreen(
      tester,
      env,
      const StudySessionScreen(sessionId: 's'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.studySummaryTitleSchedulerChanged), findsOneWidget);
    expect(find.text(_en.studySummaryFactsHeader), findsNothing);
  });

  libraryTest(
    'failed/persistence_error shows the save-error copy, turns kept',
    (tester, env) async {
      await seedEndedSession(
        env.db,
        env.decks,
        status: 'failed',
        endReason: 'persistence_error',
      );
      await pumpLibraryScreen(
        tester,
        env,
        const StudySessionScreen(sessionId: 's'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(_en.studySummaryTitleSaveError), findsOneWidget);
    },
  );

  libraryTest('Done pops the session route', (tester, env) async {
    await seedEndedSession(env.db, env.decks, status: 'completed');
    await pumpLibraryScreen(
      tester,
      env,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StudySessionScreen(sessionId: 's'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.studySummaryDone));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsNothing);
  });
}
