import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

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

  /// The local profile's tag [id] (tag management spec D13).
  Future<Tag?> findById(String id) =>
      (_db.select(_db.tags)
            ..where((tag) => tag.ownerId.isNull() & tag.id.equals(id)))
          .getSingleOrNull();

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

  /// Every tag of the local profile whose folded name holds [foldedTerm],
  /// with the active cards carrying it, in [deckId] when given; by folded
  /// name then id. One statement (tag management spec §5); `instr` finds an
  /// empty term everywhere.
  Future<List<QueryRow>> countRows({
    String? deckId,
    required String foldedTerm,
  }) => _db
      .customSelect(
        'SELECT t.id, t.name, ('
        'SELECT COUNT(*) FROM card_tags ct JOIN card c ON c.id = ct.card_id'
        ' WHERE ct.tag_id = t.id AND c.delete_batch_id IS NULL'
        ' AND (?1 IS NULL OR c.deck_id = ?1)'
        ') AS card_count FROM tags t'
        ' WHERE t.owner_id IS NULL AND instr(t.name_folded, ?2) > 0'
        ' ORDER BY t.name_folded, t.id',
        variables: [Variable<String>(deckId), Variable<String>(foldedTerm)],
        readsFrom: {_db.tags, _db.cardTags, _db.card},
      )
      .get();

  /// Fires once, then after every write to the tags, their links or the
  /// cards: a card entering the Trash or moving decks changes a count.
  Stream<void> countChanges() =>
      tableChanges(_db, [_db.tags, _db.cardTags, _db.card]);

  /// The distinct active cards carrying any of [tagIds]: a card in the Trash
  /// is not counted (BR-TAG-010).
  Future<int> activeCardCount(Set<String> tagIds) async {
    final count = _db.cardTags.cardId.count(distinct: true);
    final query =
        _db.selectOnly(_db.cardTags).join([
            innerJoin(
              _db.card,
              _db.card.id.equalsExp(_db.cardTags.cardId),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..where(
            _db.cardTags.tagId.isIn(tagIds) & _db.card.deleteBatchId.isNull(),
          );
    return (await query.getSingle()).read(count)!;
  }

  /// Renames [tagId] in place: its id and links stay (BR-TAG-006).
  Future<void> rename(
    String tagId, {
    required String name,
    required String nameFolded,
  }) => (_db.update(_db.tags)..where((tag) => tag.id.equals(tagId))).write(
    TagsCompanion(name: Value(name), nameFolded: Value(nameFolded)),
  );

  /// Links every card of [sourceId], in the Trash or not, to [targetId],
  /// then deletes [sourceId] (BR-TAG-007, BR-TAG-010). A card carrying both
  /// keeps the target once: `OR IGNORE` skips the link it has.
  Future<void> merge({
    required String sourceId,
    required String targetId,
  }) async {
    await _db.customInsert(
      'INSERT OR IGNORE INTO card_tags (card_id, tag_id) '
      'SELECT card_id, ? FROM card_tags WHERE tag_id = ?',
      variables: [Variable<String>(targetId), Variable<String>(sourceId)],
      updates: {_db.cardTags},
    );
    await deleteTag(sourceId);
  }

  /// Deletes [tagId]. Its links go by the cascade of `card_tags`, and drift's
  /// update rule for that key tells the watchers of `card_tags` as well.
  Future<void> deleteTag(String tagId) => _db.customUpdate(
    'DELETE FROM tags WHERE id = ?',
    variables: [Variable<String>(tagId)],
    updates: {_db.tags},
    updateKind: UpdateKind.delete,
  );
}
