import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

part 'search_dao.g.dart';

/// A deck as the search reads the tree (Search spec §6.1).
typedef SearchDeckRow = ({
  String id,
  String name,
  String? parentId,
  int siblingPosition,
  String contentType,
  DateTime createdAt,
});

/// A card that holds the term, once (Search spec §6.2): the tier of each
/// face, null when the face does not hold the term, its own tier, the best
/// of its faces and tags, and the name of its best matching tag.
typedef SearchCardRow = ({
  String id,
  String deckId,
  String front,
  String back,
  String frontFolded,
  DateTime createdAt,
  SearchTier? frontTier,
  SearchTier? backTier,
  SearchTier tier,
  String? tagName,
});

/// No tier: the field does not hold the term (`search_queries.drift`'s 3).
final _noTier = SearchTier.values.length;

/// The reads of the library search (Search spec §6,
/// `search_queries.drift`). They write nothing (BR-SEARCH-008).
@DriftAccessor(
  include: {'package:memox/core/database/queries/search_queries.drift'},
)
final class SearchDao extends DatabaseAccessor<AppDatabase>
    with _$SearchDaoMixin {
  SearchDao(super.attachedDatabase);

  /// Every active deck in one statement: the decks to match, and the paths
  /// of every hit of the snapshot (BR-SEARCH-009).
  Future<List<SearchDeckRow>> deckForest() async {
    final rows = await searchDeckForest().get();
    return [
      for (final row in rows)
        (
          id: row.id,
          name: row.name,
          parentId: row.parentId,
          siblingPosition: row.siblingPosition,
          contentType: row.contentType,
          createdAt: row.createdAt,
        ),
    ];
  }

  /// The live cards whose front, back or tag name holds [term], one row
  /// each, in the card group's order: after [after], through [through], at
  /// most [limit] rows, never an `OFFSET` (BR-SEARCH-001, BR-SEARCH-004,
  /// BR-SEARCH-006, BR-SEARCH-007).
  Future<List<SearchCardRow>> cardHits({
    required String term,
    SearchCursor? after,
    SearchCursor? through,
    int? limit,
  }) async {
    final rows = await searchCardHits(
      term,
      after?.tier.index,
      after?.sortText,
      after?.createdAt,
      after?.id,
      through?.tier.index,
      through?.sortText,
      through?.createdAt,
      through?.id,
      limit,
    ).get();
    return [for (final row in rows) _cardRowOf(row)];
  }

  /// Fires once when listened to, then after every write to the decks, the
  /// cards, the tags or the tags on cards (BR-SEARCH-008).
  Stream<void> changes() => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.card,
    attachedDatabase.cardTags,
    attachedDatabase.tags,
  ]);
}

/// Drift reads `MIN(front_tier, back_tier, tag_tier)` as nullable; it never
/// is, since the statement keeps only rows whose tier is below 3.
SearchCardRow _cardRowOf(SearchCardHitRow row) => (
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  frontFolded: row.frontFolded,
  createdAt: row.createdAt,
  frontTier: _tierAt(row.frontTier),
  backTier: _tierAt(row.backTier),
  tier: SearchTier.values[row.tier!],
  tagName: row.tagName,
);

SearchTier? _tierAt(int index) =>
    index < _noTier ? SearchTier.values[index] : null;
