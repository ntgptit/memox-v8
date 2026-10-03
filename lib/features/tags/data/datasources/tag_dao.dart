import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/database/table_changes.dart';

part 'tag_dao.g.dart';

/// Row access for `tags` and `card_tags`, plus the existence check of `card`
/// rows (`tag_queries.drift`). It returns Drift rows, never domain
/// entities, and runs inside the caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/tag_queries.drift'},
)
final class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.attachedDatabase);

  /// The local profile's tag with [nameFolded]: `owner_id` is NULL for it
  /// (schema.md), as the unique index `COALESCE(owner_id, '')` reads it.
  Future<Tag?> findByFoldedName(String nameFolded) =>
      localTagByFoldedName(nameFolded).getSingleOrNull();

  /// The local profile's tag [id] (tag management spec D13).
  Future<Tag?> findById(String id) => localTagById(id).getSingleOrNull();

  Future<void> insertTag(TagsCompanion row) => createTag(row);

  /// How many of [cardIds] exist as live cards; tombstones do not count.
  /// Counted in chunks (BE-C2).
  Future<int> liveCardCount(Set<String> cardIds) async {
    var total = 0;
    for (final chunk in idChunks(cardIds)) {
      total += await liveCardCountIn(chunk).getSingle();
    }
    return total;
  }

  /// The ids of [cardIds] that exist as live cards, read in chunks (BE-C2).
  Future<Set<String>> liveCardIds(Set<String> cardIds) async => {
    for (final chunk in idChunks(cardIds)) ...await liveCardIdsIn(chunk).get(),
  };

  /// The tag ids [cardId] carries.
  Future<Set<String>> tagIdsOf(String cardId) async =>
      (await tagIdsOfCard(cardId).get()).toSet();

  /// The cards of [cardIds] that already carry [tagId], read in chunks
  /// (BE-C2).
  Future<Set<String>> cardsCarrying(Set<String> cardIds, String tagId) async =>
      {
        for (final chunk in idChunks(cardIds))
          ...await cardsCarryingTagIn(chunk, tagId).get(),
      };

  /// How many tags each of [cardIds] carries; a card with none is absent.
  /// Read in chunks of cards, which never share a card (BE-C2).
  Future<Map<String, int>> tagCounts(Set<String> cardIds) async => {
    for (final chunk in idChunks(cardIds))
      for (final row in await tagCountsOfCardsIn(chunk).get())
        row.cardId: row.tagCount,
  };

  Future<void> link(String cardId, String tagId) => linkCardTag(cardId, tagId);

  /// Unlinks [tagId] from [cardIds], in chunks (BE-C2).
  Future<void> unlink(Set<String> cardIds, String tagId) async {
    for (final chunk in idChunks(cardIds)) {
      await unlinkCardsFromTagIn(chunk, tagId);
    }
  }

  /// Every tag of the local profile whose folded name holds [foldedTerm],
  /// with the active cards carrying it, in [deckId] when given; by folded
  /// name then id. One statement (tag management spec §5).
  Future<List<TagCountRow>> countRows({
    String? deckId,
    required String foldedTerm,
  }) => tagCountRows(deckId, foldedTerm).get();

  /// Fires once, then after every write to the tags, their links or the
  /// cards: a card entering the Trash or moving decks changes a count.
  Stream<void> countChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.tags,
    attachedDatabase.cardTags,
    attachedDatabase.card,
  ]);

  /// The distinct active cards carrying any of [tagIds]: a card in the Trash
  /// is not counted (BR-TAG-010).
  Future<int> activeCardCount(Set<String> tagIds) =>
      activeCardCountOfTags(tagIds.toList()).getSingle();

  /// Renames [tagId] in place: its id and links stay (BR-TAG-006).
  Future<void> rename(
    String tagId, {
    required String name,
    required String nameFolded,
  }) => renameTagRow(name, nameFolded, tagId);

  /// Links every card of [sourceId], in the Trash or not, to [targetId],
  /// then deletes [sourceId] (BR-TAG-007, BR-TAG-010).
  Future<void> merge({
    required String sourceId,
    required String targetId,
  }) async {
    await mergeTagLinks(targetId, sourceId);
    await deleteTag(sourceId);
  }

  /// Deletes [tagId]. Its links go by the cascade of `card_tags`, and drift's
  /// update rule for that key tells the watchers of `card_tags` as well.
  Future<void> deleteTag(String tagId) => deleteTagRow(tagId);
}
