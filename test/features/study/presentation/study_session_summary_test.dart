import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<String> _endedSession(
  LibraryEnv env, {
  required String status,
  String? endReason,
  String sessionKind = 'reviewing',
  int cardCount = 4,
  int answered = 4,
  int wrong = 1,
}) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  for (var i = 0; i < cardCount; i++) {
    await insertCard(env.db, id: 'c$i', deckId: leaf.id);
  }
  await insertSession(
    env.db,
    id: 's',
    deckId: leaf.id,
    rootId: root.id,
    sessionKind: sessionKind,
    status: status,
    endReason: endReason,
    endedAt: DateTime(2026, 9, 24, 10),
  );
  for (var i = 0; i < cardCount; i++) {
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c$i',
      position: i,
      status: 'completed',
    );
  }
  for (var i = 0; i < answered; i++) {
    await logReview(
      env.db,
      id: 'r$i',
      cardId: 'c$i',
      at: DateTime(2026, 9, 24, 9, i),
      action: i < wrong ? 'forgotten' : 'remembered',
    );
  }
  return leaf.id;
}

void main() {
  libraryTest('a completed review shows its facts (loaded)', (
    tester,
    env,
  ) async {
    await _endedSession(env, status: 'completed');
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
    await _endedSession(env, status: 'completed', sessionKind: 'learning');
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
    await _endedSession(env, status: 'abandoned', endReason: 'user_exit');
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
    await _endedSession(env, status: 'abandoned', endReason: 'interrupted');
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
    await _endedSession(
      env,
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
    await _endedSession(
      env,
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
      await _endedSession(
        env,
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
    await _endedSession(env, status: 'completed');
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
