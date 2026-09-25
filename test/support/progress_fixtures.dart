import 'package:memox/core/database/app_database.dart';

import 'card_fixtures.dart';

var _answers = 0;

/// A learned card of [deckId], so an answer of any kind suits it (schema
/// invariant 25). The caller locks its root's scheduler (invariant 30).
Future<void> learnedCard(AppDatabase db, String deckId, String id) =>
    insertCard(
      db,
      id: id,
      deckId: deckId,
      back: 'meaning $id',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
    );

/// An answer to [cardId] at [at], as the study flow records it
/// (BR-SRS-016).
Future<void> answer(
  AppDatabase db,
  String cardId,
  DateTime at, {
  String kind = 'scheduled',
  String mode = 'recall',
}) => logReview(
  db,
  id: 'answer ${_answers++}',
  cardId: cardId,
  at: at,
  kind: kind,
  mode: mode,
);

/// [hour]:[minute] local time in Hanoi (UTC+7), as the instant it is.
DateTime hanoi(int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, month, day, hour - 7, minute);
