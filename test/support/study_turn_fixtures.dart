import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import 'study_fixtures.dart';

// Outcomes, openers and log reads the study data and domain tests share.

/// A refusal for [reason], whatever [T] the refused call would have given.
Matcher refusedWith<T>(StudyRejection reason) =>
    isA<Rejected<T, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

/// A turn the person was judged on, as right or wrong.
Matcher judged({required bool isCorrect}) =>
    isA<Ok<TurnResult, StudyRejection>>().having(
      (ok) => ok.value.isCorrect,
      'isCorrect',
      isCorrect,
    );

/// The id of the session [outcome] opened; a refusal fails the test.
String openedSessionId(Outcome<String, StudyRejection> outcome) =>
    switch (outcome) {
      Ok(:final value) => value,
      Rejected(:final reason) => fail('opening refused: $reason'),
    };

/// A review session of [deckId] in [mode], opened through [entries].
Future<String> openReview(
  StudyEntryRepositoryImpl entries,
  String deckId,
  StudyMode mode,
) async => ((await entries.openReviewSession(
  deckId: deckId,
  mode: mode,
)) as Ok<String, StudyRejection>).value;

/// Answers the card [sessionId] serves with [answer], and fails the test on
/// a refusal.
Future<void> acceptAnswer(
  AppDatabase db,
  StudySessionRepository sessions,
  String sessionId,
  StudyAnswer answer,
) async {
  final cardId = await servedCard(db, sessionId);
  expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: cardId!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
    reason: 'answer on $cardId',
  );
}

/// How many turns the review log holds.
Future<int> reviewLogCount(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM review_log').getSingle())
        .read<int>('n');

/// The review log rows of [cardId], in the order they were written.
Future<List<QueryRow>> reviewLogsOf(AppDatabase db, String cardId) => db
    .customSelect(
      'SELECT * FROM review_log WHERE card_id = ? ORDER BY rowid',
      variables: [Variable<String>(cardId)],
    )
    .get();
