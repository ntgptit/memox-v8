import 'dart:math';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import 'card_fixtures.dart';
import 'deck_fixtures.dart';
import 'invariant_queries.dart';

// The study repositories and the reads the study tests check them with.

/// The study entry repository over [db], reading the options through the
/// real settings repository and the time from [now], and shuffling with a
/// seeded source, so every order a test sees repeats.
StudyEntryRepositoryImpl studyEntryRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
}) => StudyEntryRepositoryImpl(
  db,
  SettingsRepositoryImpl(db, now: now),
  now: now,
  random: Random(seed),
);

/// The study session repository over [db], composing the real srs and card
/// repositories, reading the time from [now] and shuffling with a seeded
/// source. [schedules] stands in for the real srs writes when a test injects
/// a fault into them.
StudySessionRepositoryImpl studySessionRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
  ScheduleRepository? schedules,
}) {
  schedules ??= ScheduleRepositoryImpl(db, now: now);
  return StudySessionRepositoryImpl(
    db,
    schedules,
    CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: now),
      now: now,
    ),
    now: now,
    random: Random(seed),
  );
}

/// No invariant query of schema.md returns a row, and at most one session
/// of the app is open (spec D2).
Future<void> expectStudyInvariants(AppDatabase db) async {
  for (final MapEntry(key: number, value: query) in invariantQueries.entries) {
    expect(
      await db.customSelect(query).get(),
      isEmpty,
      reason: 'invariant $number: ${invariantSummaries[number]}',
    );
  }
  final open = await db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_session WHERE status = 'in_progress'",
      )
      .getSingle();
  expect(open.read<int>('n'), lessThanOrEqualTo(1), reason: 'spec D2');
}

Future<QueryRow> sessionOf(AppDatabase db, String sessionId) => db
    .customSelect(
      'SELECT * FROM study_session WHERE id = ?',
      variables: [Variable(sessionId)],
    )
    .getSingle();

/// The cards of [sessionId]'s rows in [mode] and [round], in serving order.
Future<List<String>> queueOf(
  AppDatabase db,
  String sessionId,
  String mode, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id FROM study_queue_items '
            'WHERE session_id = ? AND mode = ? AND round = ? ORDER BY position',
            variables: [Variable(sessionId), Variable(mode), Variable(round)],
          )
          .get())
    row.read<String>('card_id'),
];

/// The modes [sessionId] has rows in, in the order of the chain.
Future<List<String>> modesOf(AppDatabase db, String sessionId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT mode FROM study_queue_items WHERE session_id = ? '
            'GROUP BY mode ORDER BY MIN(rowid)',
            variables: [Variable(sessionId)],
          )
          .get())
    row.read<String>('mode'),
];

/// The card [sessionId] serves next, as schema.md's `cursor` and
/// `available_at` read it (BR-STUDY-005): in the current mode's lowest round
/// with a pending row, the first by position among the rows due at the
/// cursor, else the one due soonest. Null when nothing is served.
Future<String?> servedCard(AppDatabase db, String sessionId) async {
  final row = await db
      .customSelect(
        'SELECT q.card_id FROM study_queue_items q'
        ' JOIN study_session s ON s.id = q.session_id'
        " WHERE q.session_id = ? AND q.mode = s.current_mode AND q.status = 'pending'"
        ' AND q.position >= 0 AND q.round = (SELECT MIN(p.round)'
        '  FROM study_queue_items p WHERE p.session_id = q.session_id'
        "  AND p.mode = q.mode AND p.status = 'pending')"
        ' ORDER BY q.available_at > s.cursor,'
        ' CASE WHEN q.available_at > s.cursor THEN q.available_at ELSE 0 END,'
        ' q.position LIMIT 1',
        variables: [Variable(sessionId)],
      )
      .getSingleOrNull();
  return row?.read<String>('card_id');
}

/// The kinds of [cardId]'s turns, in the order they were written.
Future<List<String>> turnKindsOf(AppDatabase db, String cardId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT kind FROM review_log WHERE card_id = ? ORDER BY rowid',
            variables: [Variable(cardId)],
          )
          .get())
    row.read<String>('kind'),
];

/// The options of [cardId]'s question in [round] of `guess`, in the order
/// shown (graded modes spec §6.2).
Future<List<String>> optionsOf(
  AppDatabase db,
  String sessionId,
  String cardId, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT option_card_id FROM study_guess_options'
            ' WHERE session_id = ? AND round = ? AND card_id = ? ORDER BY slot',
            variables: [Variable(sessionId), Variable(round), Variable(cardId)],
          )
          .get())
    row.read<String>('option_card_id'),
];

/// The meaning slot of each card of [round] of `match`, in position order
/// (graded modes spec §6.1).
Future<Map<String, int?>> meaningSlotsOf(
  AppDatabase db,
  String sessionId, {
  int round = 1,
}) async => {
  for (final row
      in await db
          .customSelect(
            'SELECT card_id, meaning_slot FROM study_queue_items'
            " WHERE session_id = ? AND mode = 'match' AND round = ?"
            ' ORDER BY position',
            variables: [Variable(sessionId), Variable(round)],
          )
          .get())
    row.read<String>('card_id'): row.read<int?>('meaning_slot'),
};

/// Five learned eight_box cards `ST-01`…`ST-05` in [rootName] > Lesson, due
/// in that order, of five meanings, each with an example and a hint: the
/// cards of SETUP-STUDY-EB-5-FULL once learned, so a review opens straight in
/// the mode a test takes. Returns the lesson deck.
Future<DeckEntity> insertFiveDue(
  AppDatabase db,
  DeckRepository decks, [
  String rootName = 'Korean',
]) async {
  final root = await decks.root(rootName);
  final leaf = await decks.sub(root.id, 'Lesson');
  const meanings = ['apple', 'banana', 'cherry', 'date', 'elder'];
  for (final (index, meaning) in meanings.indexed) {
    await insertCard(
      db,
      id: 'ST-0${index + 1}',
      deckId: leaf.id,
      front: 'term ${index + 1}',
      back: meaning,
      example: 'example ${index + 1}',
      hint: 'hint ${index + 1}',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 10 + index),
    );
  }
  await lockScheduler(db, root.id);
  return leaf;
}

/// Answers the card [sessionId] serves in its current mode, or [cardId],
/// the way a person who knows it ([right]) or does not would, each mode with
/// its own input (graded modes spec §7.1). A `recall` answer reveals first.
/// A refusal fails the test.
Future<TurnResult> answerServed(
  AppDatabase db,
  StudySessionRepositoryImpl sessions,
  String sessionId, {
  required bool right,
  String? cardId,
}) async {
  final mode = (await sessionOf(db, sessionId)).read<String>('current_mode');
  final card = cardId ?? (await servedCard(db, sessionId))!;
  final outcome = await sessions.answerTurn(
    sessionId: sessionId,
    cardId: card,
    answer: await _answerOf(db, sessions, sessionId, mode, card, right: right),
  );
  expect(
    outcome,
    isA<Ok<TurnResult, StudyRejection>>(),
    reason: 'answer on $card',
  );
  return (outcome as Ok<TurnResult, StudyRejection>).value;
}

Future<StudyAnswer> _answerOf(
  AppDatabase db,
  StudySessionRepositoryImpl sessions,
  String sessionId,
  String mode,
  String cardId, {
  required bool right,
}) async {
  switch (mode) {
    case 'browse':
      return const AdvanceAnswer();
    case 'self_assess':
      return SelfAssessAnswer(right ? Sm2Action.good : Sm2Action.again);
    case 'fill':
      final front =
          (await db
                  .customSelect(
                    'SELECT front FROM card WHERE id = ?',
                    variables: [Variable(cardId)],
                  )
                  .getSingle())
              .read<String>('front');
      return FillAnswer(right ? front : '$front?');
    case 'recall':
      await sessions.revealRecallAnswer(
        sessionId: sessionId,
        cardId: cardId,
        remainingMs: 10000,
      );
      return RecallAnswer(
        right ? RecallOutcome.remembered : RecallOutcome.forgot,
      );
    case 'guess':
      if (right) return GuessAnswer(cardId);
      final round = await _servedRound(db, sessionId, cardId);
      final options = await optionsOf(db, sessionId, cardId, round: round);
      return GuessAnswer(options.firstWhere((id) => id != cardId));
    case 'match':
      return MatchAnswer(
        right ? cardId : await _otherPair(db, sessionId, cardId),
      );
  }
  throw ArgumentError.value(mode, 'mode');
}

/// The round in which [cardId]'s row of the current mode is served.
Future<int> _servedRound(
  AppDatabase db,
  String sessionId,
  String cardId,
) async =>
    (await db
            .customSelect(
              'SELECT MIN(q.round) AS round FROM study_queue_items q'
              ' JOIN study_session s ON s.id = q.session_id'
              ' WHERE q.session_id = ? AND q.mode = s.current_mode'
              " AND q.card_id = ? AND q.status = 'pending' AND q.position >= 0",
              variables: [Variable(sessionId), Variable(cardId)],
            )
            .getSingle())
        .read<int>('round');

/// Another pending pair of the `match` board [cardId] is on, whose meaning
/// is a wrong one for it.
Future<String> _otherPair(
  AppDatabase db,
  String sessionId,
  String cardId,
) async =>
    (await db
            .customSelect(
              'SELECT q.card_id FROM study_queue_items q'
              ' JOIN study_queue_items me ON me.session_id = q.session_id'
              '  AND me.mode = q.mode AND me.round = q.round'
              " WHERE me.session_id = ? AND me.mode = 'match' AND me.card_id = ?"
              " AND me.status = 'pending' AND me.position >= 0"
              " AND q.status = 'pending' AND q.card_id <> me.card_id"
              ' AND q.position / 5 = me.position / 5 ORDER BY q.position LIMIT 1',
              variables: [Variable(sessionId), Variable(cardId)],
            )
            .getSingle())
        .read<String>('card_id');

/// A `study_session` row exactly as production writes it (schema.md), for a
/// test that seeds a session state directly instead of driving the full
/// production flow — P1's screens are exercised this way because P1 builds
/// only `browse`, one stage short of any scheduler's whole chain
/// (BR-MODE-004; spec §3).
Future<void> insertSession(
  AppDatabase db, {
  required String id,
  required String deckId,
  required String rootId,
  String sessionKind = 'learning',
  String currentMode = 'browse',
  String status = 'in_progress',
  String? endReason,
  int generation = 1,
  int cursor = 0,
  int cardLimit = 20,
  DateTime? startedAt,
  DateTime? endedAt,
}) => db.customInsert(
  'INSERT INTO study_session (id, deck_id, root_id, generation, '
  'session_kind, current_mode, status, end_reason, cursor, card_limit, '
  'started_at, ended_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
  variables: [
    Variable<String>(id),
    Variable<String>(deckId),
    Variable<String>(rootId),
    Variable<int>(generation),
    Variable<String>(sessionKind),
    Variable<String>(currentMode),
    Variable<String>(status),
    Variable<String>(endReason),
    Variable<int>(cursor),
    Variable<int>(cardLimit),
    Variable<DateTime>(startedAt ?? DateTime(2026, 9, 24, 9)),
    Variable<DateTime>(endedAt),
  ],
  updates: {db.studySession},
);

/// A `study_queue_items` row exactly as production writes it.
Future<void> insertQueueItem(
  AppDatabase db, {
  required String sessionId,
  required String mode,
  required String cardId,
  required int position,
  int round = 1,
  String status = 'pending',
  int answersInSession = 0,
}) => db.customInsert(
  'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
  'position, status, answers_in_session) VALUES (?, ?, ?, ?, ?, ?, ?)',
  variables: [
    Variable<String>(sessionId),
    Variable<String>(mode),
    Variable<int>(round),
    Variable<String>(cardId),
    Variable<int>(position),
    Variable<String>(status),
    Variable<int>(answersInSession),
  ],
  updates: {db.studyQueueItems},
);

/// Session `s`: a deck of [count] cards on a browse-only learning queue,
/// in progress since [startedAt] (screens 16, 21; study UI P1).
Future<({String rootId, String deckId})> seedBrowseSession(
  AppDatabase db,
  DeckRepository decks, {
  required DateTime startedAt,
  int count = 3,
}) async {
  final root = await decks.root('Korean');
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 0; i < count; i++) {
    await insertCard(db, id: 'c$i', deckId: leaf.id, front: 'f$i', back: 'b$i');
  }
  await insertSession(
    db,
    id: 's',
    deckId: leaf.id,
    rootId: root.id,
    startedAt: startedAt,
  );
  for (var i = 0; i < count; i++) {
    await insertQueueItem(
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c$i',
      position: i,
    );
  }
  return (rootId: root.id, deckId: leaf.id);
}

/// Session `s`, ended with [status] and [endReason]: [cardCount] cards on
/// its queue, the first [answered] answered once, the first [wrong] of them
/// forgotten (screen 21).
Future<String> seedEndedSession(
  AppDatabase db,
  DeckRepository decks, {
  required String status,
  String? endReason,
  String sessionKind = 'reviewing',
  int cardCount = 4,
  int answered = 4,
  int wrong = 1,
}) async {
  final root = await decks.root('Korean');
  final leaf = await decks.sub(root.id, 'Lesson');
  for (var i = 0; i < cardCount; i++) {
    await insertCard(db, id: 'c$i', deckId: leaf.id);
  }
  await insertSession(
    db,
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
      db,
      sessionId: 's',
      mode: 'browse',
      cardId: 'c$i',
      position: i,
      status: 'completed',
    );
  }
  for (var i = 0; i < answered; i++) {
    await logReview(
      db,
      id: 'r$i',
      cardId: 'c$i',
      at: DateTime(2026, 9, 24, 9, i),
      action: i < wrong ? 'forgotten' : 'remembered',
    );
  }
  return leaf.id;
}
