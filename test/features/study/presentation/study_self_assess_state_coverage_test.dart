import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';

// The States rows of screen 16a (Study · Self-assess) whose detail file
// cites no executed test: saveFailed, on a busy database (the answer is kept
// for Retry) and on any other Failure (the session is closed as failed and
// the summary opens).

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

Future<void> _reveal(WidgetTester tester) async {
  await tester.tap(find.text(_en.studySelfAssessShowAnswer));
  await tester.pumpAndSettle();
}

/// The real session repository, except that every answer meets a fatal
/// database error that is not a busy one.
final class _FatalAnswers implements StudySessionRepository {
  _FatalAnswers(this._inner);

  final StudySessionRepository _inner;

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: 'malformed'));

  @override
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _inner.revealRecallAnswer(
    sessionId: sessionId,
    cardId: cardId,
    remainingMs: remainingMs,
    now: now,
  );

  @override
  Future<Outcome<void, StudyRejection>> saveRecallTime({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _inner.saveRecallTime(
    sessionId: sessionId,
    cardId: cardId,
    remainingMs: remainingMs,
    now: now,
  );

  @override
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
  }) => _inner.showFillHint(sessionId: sessionId, cardId: cardId, now: now);

  @override
  Future<void> failSession({required String sessionId, DateTime? now}) =>
      _inner.failSession(sessionId: sessionId, now: now);

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  }) => _inner.abandonSession(sessionId: sessionId, now: now);

  @override
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  }) => _inner.resumeSession(sessionId: sessionId, now: now);

  @override
  Future<void> abandonStaleSessions({DateTime? now}) =>
      _inner.abandonStaleSessions(now: now);
}

void main() {
  libraryTest('saveFailed: a grade met by a busy database keeps the card and '
      'the answer and shows the unsaved-answer banner; Retry saves it '
      '(UC-STUDY-001 E2)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    env.sessions.isLocked = true;
    await pumpLibraryScreen(tester, env, _screen(id));
    await _reveal(tester);

    await tester.tap(find.text(_en.cardActionGood));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyAnswerBusyTitle), findsOneWidget);
    expect(find.text(_en.studyAnswerBusyBody), findsOneWidget);
    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('meaning 1'), findsOneWidget);
    expect(await turnKindsOf(env.db, 'R1'), isEmpty);

    env.sessions.isLocked = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyAnswerBusyTitle), findsNothing);
    expect(await turnKindsOf(env.db, 'R1'), ['scheduled']);
    expect(find.text('term 2'), findsOneWidget);
    expect(find.text('meaning 2'), findsNothing);
  });

  libraryTest('saveFailed: any other Failure resets the turn, closes the '
      'session as failed and opens the summary with its save error '
      '(BR-STUDY-018)', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(id),
      overrides: [
        answerStudyTurnUseCaseProvider.overrideWithValue(
          AnswerStudyTurnUseCase(_FatalAnswers(env.sessions)),
        ),
      ],
    );
    await _reveal(tester);

    await tester.tap(find.text(_en.cardActionGood));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyAnswerBusyTitle), findsNothing);
    expect(find.text(_en.summarySaveErrorBody), findsOneWidget);
    final session = await sessionOf(env.db, id);
    expect(session.read<String>('status'), 'failed');
    expect(session.read<String>('end_reason'), 'persistence_error');
    expect(await turnKindsOf(env.db, 'R1'), isEmpty);
  });
}
