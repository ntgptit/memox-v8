import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const Offset _swipeLeft = Offset(-300, 0);
const double _swipeSpeed = 1000;

/// A deck of three cards on a browse-only queue, in_progress today.
Future<({String rootId, String deckId})> _browseSession(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  for (var i = 0; i < 3; i++) {
    await insertCard(
      env.db,
      id: 'c$i',
      deckId: leaf.id,
      front: 'f$i',
      back: 'b$i',
    );
  }
  await insertSession(
    env.db,
    id: 's',
    deckId: leaf.id,
    rootId: root.id,
    startedAt: libraryToday,
  );
  for (var i = 0; i < 3; i++) {
    await insertQueueItem(
      env.db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c$i',
      position: i,
    );
  }
  return (rootId: root.id, deckId: leaf.id);
}

/// The session pushed over a page, as the router does (spec D2), so leaving
/// it has somewhere to go back to.
Future<void> _openSession(
  WidgetTester tester,
  LibraryEnv env, {
  List<Override> overrides = const [],
}) async {
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
    overrides: overrides,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Browse writes no review action (BR-MODE-005): a card it moved past is a
/// completed queue row.
Future<int> _advanced(LibraryEnv env) async {
  final row = await env.db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_queue_items WHERE status = 'completed'",
      )
      .getSingle();
  return row.read<int>('n');
}

void main() {
  libraryTest('shows both faces, and a swipe left records one turn and '
      'advances (BR-MODE-005, BR-MODE-006)', (tester, env) async {
    await _browseSession(env);
    await _openSession(tester, env);

    expect(find.text('f0'), findsOneWidget);
    expect(find.text('b0'), findsOneWidget);

    await tester.fling(find.text('f0'), _swipeLeft, _swipeSpeed);
    await tester.pumpAndSettle();

    expect(find.text('f1'), findsOneWidget);
    expect(await _advanced(env), 1);
  });

  libraryTest('a swipe right looks back without recording (BR-STUDY-048)', (
    tester,
    env,
  ) async {
    await _browseSession(env);
    await _openSession(tester, env);
    await tester.fling(find.text('f0'), _swipeLeft, _swipeSpeed);
    await tester.pumpAndSettle();

    await tester.fling(find.text('f1'), -_swipeLeft, _swipeSpeed);
    await tester.pumpAndSettle();

    expect(find.text('f0'), findsOneWidget);
    expect(await _advanced(env), 1);
  });

  libraryTest('the close icon asks first; Keep studying changes nothing '
      '(spec D8, IT-CONT-004)', (tester, env) async {
    await _browseSession(env);
    await _openSession(tester, env);

    await tester.tap(find.byTooltip(_en.studySessionExitLabel));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsOneWidget);

    await tester.tap(find.text(_en.studyExitKeep));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsNothing);
    expect(find.text('f0'), findsOneWidget);
    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'in_progress');
  });

  libraryTest('Stop from system Back abandons as user_exit and the same '
      'route shows the summary (spec D2, D8, IT-NAV-010)', (tester, env) async {
    await _browseSession(env);
    await _openSession(tester, env);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.studyExitTitle), findsOneWidget);

    await tester.tap(find.text(_en.studyExitStop));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.text(_en.studySummaryTitle), findsOneWidget);
    final row = await sessionOf(env.db, 's');
    expect(row.read<String>('status'), 'abandoned');
    expect(row.read<String>('end_reason'), 'user_exit');
  });

  libraryTest('a locked write shows an inline error on the same card, and '
      'Retry advances once it succeeds (UC-STUDY-001 E2)', (tester, env) async {
    await _browseSession(env);
    final real = StudySessionRepositoryImpl(
      env.db,
      ScheduleRepositoryImpl(env.db),
      env.cards,
      now: env.clock.now,
    );
    await _openSession(
      tester,
      env,
      overrides: [
        answerStudyTurnUseCaseProvider.overrideWithValue(
          AnswerStudyTurnUseCase(_LockedOnce(real)),
        ),
      ],
    );

    await tester.fling(find.text('f0'), _swipeLeft, _swipeSpeed);
    await tester.pumpAndSettle();

    expect(find.text(_en.studySessionLockedRetryTitle), findsOneWidget);
    expect(find.text('f0'), findsOneWidget);
    expect(await _advanced(env), 0);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text('f1'), findsOneWidget);
    expect(find.text(_en.studySessionLockedRetryTitle), findsNothing);
  });

  libraryTest('a stale generation leaves the session with a message and '
      'records nothing (UC-STUDY-001 E4)', (tester, env) async {
    final ids = await _browseSession(env);
    // A reset elsewhere moved the root's generation after the session opened.
    await env.db.customUpdate(
      'UPDATE deck SET generation = generation + 1 WHERE id = ?',
      variables: [Variable<String>(ids.rootId)],
    );
    await _openSession(tester, env);

    await tester.fling(find.text('f0'), _swipeLeft, _swipeSpeed);
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsNothing);
    expect(find.text(_en.studySessionStaleSnackbar), findsOneWidget);
    expect(await _advanced(env), 0);
  });

  libraryTest('the deck deleted mid-session leaves the session '
      '(UC-STUDY-001 A5, IT-CONT-007)', (tester, env) async {
    final ids = await _browseSession(env);
    await _openSession(tester, env);

    await env.db.customUpdate(
      'DELETE FROM deck WHERE id = ?',
      variables: [Variable<String>(ids.deckId)],
      // The cascade removes the session and its queue; tell the streams.
      updates: {env.db.deck, env.db.studySession, env.db.studyQueueItems},
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsNothing);
    expect(find.text(_en.studySessionGoneSnackbar), findsOneWidget);
  });
}

/// Fails the first answer with a lock, then answers through [real].
final class _LockedOnce implements StudySessionRepository {
  _LockedOnce(this.real);

  final StudySessionRepository real;
  bool _hasFailed = false;

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) {
    if (!_hasFailed) {
      _hasFailed = true;
      throw const DatabaseLockedFailure(cause: 'test');
    }
    return real.answerTurn(
      sessionId: sessionId,
      cardId: cardId,
      answer: answer,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
