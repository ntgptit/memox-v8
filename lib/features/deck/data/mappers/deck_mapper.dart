import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A root's scheduler; null on a sub-deck (BR-DECK-025).
SchedulerType? schedulerTypeOf(Deck row) => switch (row.schedulerType) {
  final String code => SchedulerType.fromCode(code),
  null => null,
};

DeckEntity deckEntityOf(Deck row) => DeckEntity(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  rootId: row.rootId,
  depth: row.depth,
  contentType: DeckContentType.values.byName(row.contentType),
  schedulerType: schedulerTypeOf(row),
  generation: row.generation,
  firstAnsweredAt: row.firstAnsweredAt,
  siblingPosition: row.siblingPosition,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

DeckTile deckTileOf(DeckTileRow row, DateTime startOfToday) => DeckTile(
  id: row.id,
  name: row.name,
  siblingPosition: row.siblingPosition,
  createdAt: row.createdAt,
  schedulerType: SchedulerType.fromCode(row.schedulerType!),
  subDeckCount: row.subDeckCount,
  cardCount: row.cardCount,
  newCount: row.newCount,
  overdueCount: row.overdueCount,
  dueTodayCount: row.dueTodayCount,
  oldestDueAt: row.oldestDueAt,
  startOfToday: startOfToday,
);

/// [rows] run from the root down to the open deck.
DeckView? deckViewOf(List<Deck> rows) {
  if (rows.isEmpty) return null;
  final root = rows.first;
  return DeckView(
    deck: deckEntityOf(rows.last),
    schedulerType: schedulerTypeOf(root)!,
    isSchedulerLocked: root.firstAnsweredAt != null,
    breadcrumb: [
      for (final row in rows.take(rows.length - 1))
        DeckPathEntry(id: row.id, name: row.name),
    ],
  );
}

DeckTreeNode deckTreeNodeOf(DeckForestRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: row.isCandidate,
  contentType: DeckContentType.values.byName(row.contentType),
);
