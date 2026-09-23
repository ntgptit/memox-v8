import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for `tags` and `card_tags`, plus the existence check of `card`
/// rows. It returns Drift rows, never domain entities, and runs inside the
/// caller's transaction.
final class TagDao {
  TagDao(this._db);

  final AppDatabase _db;

  /// The local profile's tag with [nameFolded]: `owner_id` is NULL for it
  /// (schema.md), as the unique index `COALESCE(owner_id, '')` reads it.
  Future<Tag?> findByFoldedName(String nameFolded) =>
      (_db.select(_db.tags)..where(
            (tag) => tag.ownerId.isNull() & tag.nameFolded.equals(nameFolded),
          ))
          .getSingleOrNull();

  Future<Tag?> findById(String id) => (_db.select(
    _db.tags,
  )..where((tag) => tag.id.equals(id))).getSingleOrNull();

  Future<void> insertTag(TagsCompanion row) => _db.into(_db.tags).insert(row);

  /// How many of [cardIds] exist as live cards; tombstones do not count.
  Future<int> liveCardCount(Set<String> cardIds) async {
    final count = _db.card.id.count();
    final query = _db.selectOnly(_db.card)
      ..addColumns([count])
      ..where(_db.card.id.isIn(cardIds) & _db.card.deleteBatchId.isNull());
    return (await query.getSingle()).read(count)!;
  }

  /// The tag ids [cardId] carries.
  Future<Set<String>> tagIdsOf(String cardId) async {
    final rows = await (_db.select(
      _db.cardTags,
    )..where((link) => link.cardId.equals(cardId))).get();
    return {for (final row in rows) row.tagId};
  }

  /// The cards of [cardIds] that already carry [tagId].
  Future<Set<String>> cardsCarrying(Set<String> cardIds, String tagId) async {
    final rows =
        await (_db.select(_db.cardTags)..where(
              (link) => link.cardId.isIn(cardIds) & link.tagId.equals(tagId),
            ))
            .get();
    return {for (final row in rows) row.cardId};
  }

  /// How many tags each of [cardIds] carries; a card with none is absent.
  Future<Map<String, int>> tagCounts(Set<String> cardIds) async {
    final count = _db.cardTags.tagId.count();
    final query = _db.selectOnly(_db.cardTags)
      ..addColumns([_db.cardTags.cardId, count])
      ..where(_db.cardTags.cardId.isIn(cardIds))
      ..groupBy([_db.cardTags.cardId]);
    return {
      for (final row in await query.get())
        row.read(_db.cardTags.cardId)!: row.read(count)!,
    };
  }

  Future<void> link(String cardId, String tagId) => _db
      .into(_db.cardTags)
      .insert(CardTagsCompanion.insert(cardId: cardId, tagId: tagId));

  Future<void> unlink(Set<String> cardIds, String tagId) =>
      (_db.delete(_db.cardTags)..where(
            (link) => link.cardId.isIn(cardIds) & link.tagId.equals(tagId),
          ))
          .go();
}
