import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

/// The entries of the Trash, newest first, from its rows (UC-TRASH-001
/// steps 3-4). Each origin is walked through [forest], the whole deck tree
/// with the Trash in it, so a deck in the Trash is on the path of what was in
/// it (BR-TRASH-012).
List<TrashEntry> trashEntriesOf({
  required List<TrashDeckEntryRow> decks,
  required List<TrashCardEntryRow> cards,
  required List<TrashForestRow> forest,
}) {
  final byId = {for (final row in forest) row.id: row};

  /// [deckId] and every deck above it, root first. Cycle-safe.
  List<DeckPathEntry> pathThrough(String? deckId) {
    final path = <DeckPathEntry>[];
    final seen = <String>{};
    for (var row = byId[deckId]; row != null; row = byId[row.parentId]) {
      if (!seen.add(row.id)) break;
      path.insert(0, DeckPathEntry(id: row.id, name: row.name));
    }
    return path;
  }

  return [
    for (final row in decks)
      TrashDeckEntry(
        batchId: row.batchId,
        deletedAt: row.deletedAt,
        origin: pathThrough(row.parentId),
        deckId: row.deckId,
        name: row.name,
        isRoot: row.parentId == null,
        subDeckCount: row.subDeckCount,
        cardCount: row.cardCount,
      ),
    for (final row in cards)
      TrashCardEntry(
        batchId: row.batchId,
        deletedAt: row.deletedAt,
        origin: pathThrough(row.deckId),
        cardId: row.cardId,
        front: row.front,
        back: row.back,
      ),
  ]..sort(_newestFirst);
}

/// `deleted_at` descending, then the batch id (trash spec §9).
int _newestFirst(TrashEntry a, TrashEntry b) {
  final byTime = b.deletedAt.compareTo(a.deletedAt);
  return byTime != 0 ? byTime : a.batchId.compareTo(b.batchId);
}
