import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// A deck as the search reads the tree (Search spec §6.1).
typedef SearchDeckRow = ({
  String id,
  String name,
  String? parentId,
  int siblingPosition,
  String contentType,
  DateTime createdAt,
});

/// Out of the Trash, on the table aliased [alias]: the one predicate every
/// read of the search uses (BR-SEARCH-001; Search spec D8).
String _live(String alias) => '$alias.delete_batch_id IS NULL';

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

  /// Fires once when listened to, then after every write to the decks
  /// (BR-SEARCH-008).
  Stream<void> changes() => tableChanges(_db, [_db.deck]);
}
