import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/text/folded_text.dart';

part 'card_sync_dao.g.dart';

/// Syncs `card` (library and study sync spec §3.1). The folded columns are
/// not on the wire: a pulled card is folded here as the repository folds.
@DriftAccessor(
  include: {'package:memox/core/database/queries/sync_card_queries.drift'},
)
class CardSyncDao extends DatabaseAccessor<AppDatabase>
    with _$CardSyncDaoMixin, EntitySyncAdapter {
  CardSyncDao(super.attachedDatabase);

  static const type = 'card';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final card = await syncCardRow(id).getSingleOrNull();
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
    await upsertSyncedCard(
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
      await deleteSyncedCardTags(id);
      for (final tagId in (row['tagIds'] as List).cast<String>()) {
        await linkSyncedCardTag(id, tagId);
      }
    }
  }

  @override
  Future<void> deleteFromServer(String id) => deleteSyncedCard(id);

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      acknowledgeCard(serverVersion, id);

  Future<List<String>> _tagIds(String cardId) => syncCardTagIds(cardId).get();

  /// Drift stores whole seconds; the wire drops the fraction so a round trip
  /// is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
