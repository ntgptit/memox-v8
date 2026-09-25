import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

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

/// Out of the Trash, on the table aliased [alias]: the one predicate every
/// read of the search uses (BR-SEARCH-001; Search spec D8).
String _live(String alias) => '$alias.delete_batch_id IS NULL';

/// Past the last tier: the field does not hold the term.
final _noTier = SearchTier.values.length;

/// [folded]'s tier for the term `?1`, the index of the `SearchTier` that
/// `searchTierOf` gives, by `=` and `instr`: never `LIKE`, so `%` and `_`
/// are plain characters, and never `lower()` (Search spec D4).
String _tierOf(String folded) =>
    'CASE WHEN $folded = ?1 THEN ${SearchTier.exact.index}'
    ' WHEN instr($folded, ?1) = 1 THEN ${SearchTier.prefix.index}'
    ' WHEN instr($folded, ?1) > 0 THEN ${SearchTier.contains.index}'
    ' ELSE $_noTier END';

/// The tags of the card `c`, for a correlated subquery (Search spec D7).
const _tagsOfCard =
    'FROM card_tags ct JOIN tags t ON t.id = ct.tag_id'
    ' WHERE ct.card_id = c.id';

/// Every live card with the tier of its front, its back and its best tag,
/// and the name of its best matching tag: one row per card, from correlated
/// subqueries, never `DISTINCT` over a join (BR-SEARCH-006); then its tier,
/// the best of the three, and only the cards that have one (BR-SEARCH-004).
final _cardHits =
    'WITH hits AS (SELECT c.id, c.deck_id, c.front, c.back, c.front_folded,'
    ' c.created_at,'
    ' ${_tierOf('c.front_folded')} AS front_tier,'
    ' ${_tierOf('c.back_folded')} AS back_tier,'
    ' COALESCE((SELECT MIN(${_tierOf('t.name_folded')}) $_tagsOfCard),'
    ' $_noTier) AS tag_tier,'
    ' (SELECT t.name $_tagsOfCard AND instr(t.name_folded, ?1) > 0'
    ' ORDER BY ${_tierOf('t.name_folded')}, t.name_folded, t.id'
    ' LIMIT 1) AS tag_name'
    ' FROM card c JOIN deck k ON k.id = c.deck_id'
    ' WHERE ${_live('c')} AND ${_live('k')}),'
    ' tiered AS (SELECT hits.*, MIN(front_tier, back_tier, tag_tier) AS tier'
    ' FROM hits)'
    ' SELECT * FROM tiered WHERE tier < $_noTier';

/// A card's key, in the order of `SearchCursor` (BR-SEARCH-007).
const _key = '(tier, front_folded, created_at, id)';

/// The reads of the library search (Search spec §6). They write nothing
/// (BR-SEARCH-008).
final class SearchDao {
  const SearchDao(this._db);

  final AppDatabase _db;

  /// Every active deck in one statement: the decks to match, and the paths
  /// of every hit of the snapshot (BR-SEARCH-009).
  Future<List<SearchDeckRow>> deckForest() async {
    final rows = await _db
        .customSelect(
          'SELECT d.id, d.name, d.parent_id, d.sibling_position,'
          ' d.content_type, d.created_at'
          ' FROM deck d WHERE ${_live('d')}',
          readsFrom: {_db.deck},
        )
        .get();
    return [
      for (final row in rows)
        (
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          parentId: row.readNullable<String>('parent_id'),
          siblingPosition: row.read<int>('sibling_position'),
          contentType: row.read<String>('content_type'),
          createdAt: row.read<DateTime>('created_at'),
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
    final rows = await _db
        .customSelect(
          '$_cardHits'
          '${after == null ? '' : ' AND $_key > (?, ?, ?, ?)'}'
          '${through == null ? '' : ' AND $_key <= (?, ?, ?, ?)'}'
          ' ORDER BY tier, front_folded, created_at, id'
          '${limit == null ? '' : ' LIMIT ?'}',
          variables: [
            Variable<String>(term),
            ...?_keyOf(after),
            ...?_keyOf(through),
            if (limit != null) Variable<int>(limit),
          ],
          readsFrom: {_db.card, _db.deck, _db.cardTags, _db.tags},
        )
        .get();
    return [for (final row in rows) _cardRowOf(row)];
  }

  /// Fires once when listened to, then after every write to the decks, the
  /// cards, the tags or the tags on cards (BR-SEARCH-008).
  Stream<void> changes() =>
      tableChanges(_db, [_db.deck, _db.card, _db.cardTags, _db.tags]);
}

List<Variable<Object>>? _keyOf(SearchCursor? cursor) => cursor == null
    ? null
    : [
        Variable<int>(cursor.tier.index),
        Variable<String>(cursor.sortText),
        Variable<DateTime>(cursor.createdAt),
        Variable<String>(cursor.id),
      ];

SearchCardRow _cardRowOf(QueryRow row) => (
  id: row.read<String>('id'),
  deckId: row.read<String>('deck_id'),
  front: row.read<String>('front'),
  back: row.read<String>('back'),
  frontFolded: row.read<String>('front_folded'),
  createdAt: row.read<DateTime>('created_at'),
  frontTier: _tierAt(row.read<int>('front_tier')),
  backTier: _tierAt(row.read<int>('back_tier')),
  tier: SearchTier.values[row.read<int>('tier')],
  tagName: row.readNullable<String>('tag_name'),
);

SearchTier? _tierAt(int index) =>
    index < _noTier ? SearchTier.values[index] : null;
