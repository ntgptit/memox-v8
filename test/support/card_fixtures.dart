import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

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
  bool isFlagged = false,
  DateTime? learnedAt,
  DateTime? dueAt,
  int box = 1,
  int intervalDays = 1,
  String? deleteBatchId,
  DateTime? createdAt,
}) => db.transaction(() async {
  final created = createdAt ?? DateTime(2026, 9, 1);
  await db.customUpdate(
    "UPDATE deck SET content_type = 'card' "
    'WHERE id = ? AND parent_id IS NOT NULL',
    variables: [Variable<String>(deckId)],
    updates: {db.deck},
  );
  await db.customInsert(
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable<String>(id),
      Variable<String>(deckId),
      Variable<String>(front),
      Variable<String>(back),
      Variable<String>(front.trim().toLowerCase()),
      Variable<String>(back.trim().toLowerCase()),
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
