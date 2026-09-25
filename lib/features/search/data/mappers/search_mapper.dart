import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';

/// Every deck reached from a root, with its trail: the root first and the
/// deck last, walked once over one read of the tree (BR-SEARCH-009).
Map<String, List<DeckPathEntry>> trailsOf(List<SearchDeckRow> rows) => {
  for (final (id, trail) in candidatesInTreeOrder(
    [for (final row in rows) _nodeOf(row)],
    (node, path) =>
        (node.id, [...path, DeckPathEntry(id: node.id, name: node.name)]),
  ))
    id: trail,
};

/// The decks of [rows] that the walk reached, each with its ancestors
/// (Search spec §6.1).
List<SearchableDeck> searchableDecksOf(
  List<SearchDeckRow> rows,
  Map<String, List<DeckPathEntry>> trails,
) => [
  for (final row in rows)
    if (trails[row.id] case final trail?)
      SearchableDeck(
        deckId: row.id,
        name: row.name,
        createdAt: row.createdAt,
        path: trail.sublist(0, trail.length - 1),
        contentType: DeckContentType.values.byName(row.contentType),
      ),
];

DeckTreeNode _nodeOf(SearchDeckRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: true,
  contentType: DeckContentType.values.byName(row.contentType),
);
