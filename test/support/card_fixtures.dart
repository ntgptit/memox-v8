import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

import 'trash_fixtures.dart';

/// A card and its schedule row written straight to the tables, in one
/// transaction, so a read test can set any schedule state and the watchers
/// hear of it once. The schedule row follows the root's scheduler, at the
/// root's generation; [learnedAt] null makes the card New.
Future<void> insertCard(
  AppDatabase db, {
  required String id,
  required String deckId,
  String front = 'front',
  String back = 'back',
  String? example,
  String? hint,
  bool isFlagged = false,
  DateTime? learnedAt,
  DateTime? dueAt,
  int box = 1,
  int intervalDays = 1,
  String? deleteBatchId,
  DateTime? createdAt,
}) => db.transaction(() async {
  final created = createdAt ?? DateTime(2026, 9, 1);
  if (deleteBatchId != null) {
    await insertDeleteBatch(
      db,
      deleteBatchId,
      itemType: 'card',
      rootItemId: id,
    );
  }
  await db.customUpdate(
    "UPDATE deck SET content_type = 'card' "
    'WHERE id = ? AND parent_id IS NOT NULL',
    variables: [Variable<String>(deckId)],
    updates: {db.deck},
  );
  await db.customInsert(
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'example, hint, is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable<String>(id),
      Variable<String>(deckId),
      Variable<String>(front),
      Variable<String>(back),
      Variable<String>(front.trim().toLowerCase()),
      Variable<String>(back.trim().toLowerCase()),
      Variable<String>(example),
      Variable<String>(hint),
      Variable<bool>(isFlagged),
      Variable<String>(deleteBatchId),
      Variable<DateTime>(created),
      Variable<DateTime>(created),
    ],
    updates: {db.card},
  );
  await db.customInsert(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, '
    'generation, learned_at, due_at, current_box, ease_factor, '
    'interval_days, repetitions) '
    'SELECT ?, r.scheduler_type, r.scheduler_version, r.generation, ?, ?, '
    "CASE r.scheduler_type WHEN 'eight_box' THEN ? END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 2.5 END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN ? END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 1 END "
    'FROM deck d JOIN deck r ON r.id = d.root_id WHERE d.id = ?',
    variables: [
      Variable<String>(id),
      Variable<DateTime>(learnedAt),
      Variable<DateTime>(dueAt),
      Variable<int>(box),
      Variable<int>(intervalDays),
      Variable<String>(deckId),
    ],
    updates: {db.cardSchedule},
  );
});

/// A card made through the real repository. A refusal here is a broken
/// fixture, so it throws.
extension CardFixtures on CardRepository {
  Future<CardEntity> card(
    String deckId, [
    CardDraft draft = const CardDraft(front: 'front', back: 'back'),
  ]) async => switch (await createCard(deckId: deckId, draft: draft)) {
    Ok(:final value) => value,
    Rejected(:final reason) => throw StateError(
      'fixture card refused: $reason',
    ),
  };
}

/// A review_log row as the study flow writes it (BR-CARD-016). The history
/// shows it by [at], newest first. `usedHint` goes with `fill` only and
/// `isTimedOut` with `recall` only (schema invariants 22, 23).
Future<void> logReview(
  AppDatabase db, {
  required String id,
  required String cardId,
  required DateTime at,
  int generation = 1,
  String schedulerType = 'eight_box',
  String kind = 'scheduled',
  String mode = 'recall',
  String action = 'remembered',
  DateTime? nextDueAt,
  int? previousBox,
  int? nextBox,
  double? previousEase,
  double? nextEase,
  int? previousInterval,
  int? nextInterval,
  bool? usedHint,
  bool isTimedOut = false,
}) => db.customInsert(
  'INSERT INTO review_log (id, card_id, session_id, scheduler_type, '
  'generation, kind, mode, outcome_reason, used_hint, "action", answered_at, '
  'next_due_at, previous_box, next_box, previous_ease_factor, '
  'next_ease_factor, previous_interval_days, next_interval_days) '
  "VALUES (?, ?, 's', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
  variables: [
    Variable<String>(id),
    Variable<String>(cardId),
    Variable<String>(schedulerType),
    Variable<int>(generation),
    Variable<String>(kind),
    Variable<String>(mode),
    Variable<String>(isTimedOut ? 'timeout' : null),
    Variable<bool>(usedHint),
    Variable<String>(action),
    Variable<DateTime>(at),
    Variable<DateTime>(nextDueAt),
    Variable<int>(previousBox),
    Variable<int>(nextBox),
    Variable<double>(previousEase),
    Variable<double>(nextEase),
    Variable<int>(previousInterval),
    Variable<int>(nextInterval),
  ],
  updates: {db.reviewLog},
);
