import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/text/folded_text.dart';

/// Syncs `card` (library and study sync spec §3.1). The folded columns are
/// not on the wire: a pulled card is folded here as the repository folds.
class CardSyncAdapter implements EntitySyncAdapter {
  CardSyncAdapter(this._db);

  static const type = 'card';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final card = await (_db.select(
      _db.card,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (card == null) {
      return null;
    }
    return {
      'id': card.id,
      'deckId': card.deckId,
      'front': card.front,
      'back': card.back,
      'isFlagged': card.isFlagged == 1,
      'example': card.example,
      'hint': card.hint,
      'pronunciation': card.pronunciation,
      'deleteBatchId': card.deleteBatchId,
      'createdAt': _time(card.createdAt),
      'updatedAt': _time(card.updatedAt),
      'tagIds': await _tagIds(card.id),
    };
  }

  @override
  Future<void> upsertFromServer(
    Map<String, Object?> row,
    int serverVersion,
  ) async {
    final front = row['front'] as String;
    final back = row['back'] as String;
    await _db
        .into(_db.card)
        .insertOnConflictUpdate(
          CardCompanion.insert(
            id: row['id'] as String,
            deckId: row['deckId'] as String,
            front: front,
            back: back,
            frontFolded: Value(foldText(front)),
            backFolded: Value(foldText(back)),
            isFlagged: Value((row['isFlagged'] as bool) ? 1 : 0),
            example: Value(row['example'] as String?),
            hint: Value(row['hint'] as String?),
            pronunciation: Value(row['pronunciation'] as String?),
            deleteBatchId: Value(row['deleteBatchId'] as String?),
            createdAt: fromWireTime(row['createdAt'])!,
            updatedAt: fromWireTime(row['updatedAt'])!,
            serverVersion: Value(serverVersion),
          ),
        );
    // R10: a row without tagIds leaves the links as they are.
    if (row.containsKey('tagIds')) {
      final id = row['id'] as String;
      await (_db.delete(_db.cardTags)..where((l) => l.cardId.equals(id))).go();
      for (final tagId in (row['tagIds'] as List).cast<String>()) {
        await _db
            .into(_db.cardTags)
            .insert(
              CardTagsCompanion.insert(cardId: id, tagId: tagId),
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
  }

  @override
  Future<void> deleteFromServer(String id) =>
      (_db.delete(_db.card)..where((c) => c.id.equals(id))).go();

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      (_db.update(_db.card)..where((c) => c.id.equals(id))).write(
        CardCompanion(serverVersion: Value(serverVersion)),
      );

  Future<List<String>> _tagIds(String cardId) async => [
    for (final link
        in await (_db.select(_db.cardTags)
              ..where((l) => l.cardId.equals(cardId))
              ..orderBy([(l) => OrderingTerm(expression: l.tagId)]))
            .get())
      link.tagId,
  ];

  /// Gives every card without a schedule the row a new card starts with
  /// (BR-CARD-004): its root's scheduler at the root's generation, nothing
  /// learned. The values are `CardScheduleState.initial`'s; `lib/core` cannot
  /// call the srs feature, and `card_sync_adapter_test.dart` holds the two
  /// equal. Runs at the end of a pull, under `applying_remote`.
  Future<void> ensureSchedules() => _db.customStatement(
    'INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, '
    'generation, answer_count, lapse_count, current_box, ease_factor, '
    'interval_days, repetitions) '
    'SELECT c.id, r.scheduler_type, r.scheduler_version, r.generation, 0, 0, '
    "CASE r.scheduler_type WHEN 'eight_box' THEN 1 END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 2.5 END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 0 END, "
    "CASE r.scheduler_type WHEN 'sm2' THEN 0 END "
    'FROM card c JOIN deck d ON d.id = c.deck_id JOIN deck r ON r.id = d.root_id '
    'WHERE NOT EXISTS (SELECT 1 FROM card_schedule s WHERE s.card_id = c.id)',
  );

  /// Drift stores whole seconds; the wire drops the fraction so a round trip
  /// is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
