import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/mappers/deck_mapper.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';

/// Every write reads the rows its rules need and writes inside one
/// transaction, so a rule never judges data another write has changed.
final class DeckRepositoryImpl implements DeckRepository {
  DeckRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = DeckDao(_db),
      _tree = DeckTreeDataSource(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DeckDao _dao;
  final DeckTreeDataSource _tree;
  final DateTime Function() _now;

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      final id = newId();
      await _dao.insert(
        DeckCompanion.insert(
          id: id,
          name: name.trim(),
          rootId: id,
          depth: 1,
          contentType: Value(DeckContentType.deck.name),
          schedulerType: Value(schedulerType.code),
          schedulerVersion: Value(schedulerFor(schedulerType).version),
          generation: const Value(1),
          siblingPosition: await _dao.nextSiblingPosition(null),
          createdAt: at,
          updatedAt: at,
        ),
      );
      return Ok(deckEntityOf((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      final parent = await _dao.findRow(parentId);
      if (parent == null) return const Rejected(DeckRejection.notFound);
      final rule = DeckEntity.checkCreateSubDeck(
        parentDepth: parent.depth,
        parentContentType: DeckContentType.values.byName(parent.contentType),
      );
      if (_refusal(rule) case final reason?) return Rejected(reason);

      final id = newId();
      await _dao.insert(
        DeckCompanion.insert(
          id: id,
          name: name.trim(),
          parentId: Value(parentId),
          rootId: parent.rootId,
          depth: parent.depth + 1,
          contentType: Value(DeckContentType.unset.name),
          siblingPosition: await _dao.nextSiblingPosition(parentId),
          createdAt: at,
          updatedAt: at,
        ),
      );
      await _tree.refreshContentType(parentId, at);
      return Ok(deckEntityOf((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final moving = await _dao.findRow(deckId);
      final target = await _dao.findRow(newParentId);
      if (moving == null || target == null) {
        return const Rejected(DeckRejection.notFound);
      }
      final oldParentId = moving.parentId;
      if (oldParentId == null) {
        return const Rejected(DeckRejection.rootCannotMove);
      }
      if (oldParentId == newParentId) {
        return const Rejected(DeckRejection.sameParent);
      }
      if (await _tree.refusalUnder(target, moving) case final reason?) {
        return Rejected(reason);
      }

      await _tree.moveUnder(
        target,
        moving,
        siblingPosition: await _dao.nextSiblingPosition(newParentId),
        at: at,
      );
      await _tree.refreshContentType(oldParentId, at);
      await _tree.refreshContentType(newParentId, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      if (await _dao.findRow(deckId) == null) {
        return const Rejected(DeckRejection.notFound);
      }
      await _dao.rename(deckId, name.trim(), at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final deck = await _dao.findRow(deckId);
      final anchor = await _dao.findRow(anchorId);
      if (deck == null || anchor == null) {
        return const Rejected(DeckRejection.notFound);
      }
      if (deck.parentId != anchor.parentId) {
        return const Rejected(DeckRejection.notSiblings);
      }
      final siblings = await _dao.siblingRows(deck.parentId);
      final order = DeckEntity.reorder(
        [for (final row in siblings) row.id],
        movingId: deckId,
        anchorId: anchorId,
        placement: placement,
      );
      final positionOf = {
        for (final row in siblings) row.id: row.siblingPosition,
      };
      for (final (position, id) in order.indexed) {
        if (positionOf[id] == position) continue;
        await _dao.setSiblingPosition(id, position, at);
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<DeckDeletionSummary, DeckRejection>> deletionSummary(
    String deckId,
  ) => _mapped(() async {
    final row = await _dao.deletionSummary(deckId);
    if (row == null) return const Rejected(DeckRejection.notFound);
    return Ok(
      DeckDeletionSummary(
        subDeckCount: row.subDeckCount,
        cardCount: row.cardCount,
      ),
    );
  });

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final deck = await _dao.findRow(deckId);
      if (deck == null) return const Rejected(DeckRejection.notFound);
      // The rows stay where they are, marked: only a purge deletes them, by
      // cascade (BR-DECK-022, BR-TRASH-010).
      final batchId = newId();
      await _dao.insertBatch(batchId, deckId, at);
      await _dao.markSubtree(deckId, batchId);
      if (deck.parentId case final parentId?) {
        await _tree.refreshContentType(parentId, at);
      }
      await _dao.closeSessionsTouching(batchId, at);
      return Ok(batchId);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> restoreDecks({
    required Set<String> batchIds,
    required String? parentId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final items = <String, Deck>{};
      for (final batchId in batchIds) {
        final item = await _dao.itemRootOf(batchId);
        if (item == null) return const Rejected(DeckRejection.notFound);
        items[batchId] = item;
      }
      if (parentId == null) {
        if (items.values.any((item) => item.parentId != null)) {
          return const Rejected(DeckRejection.subDeckNeedsParent);
        }
        for (final MapEntry(key: batchId, value: item) in items.entries) {
          await _dao.restoreBatch(batchId);
          final position = await _dao.nextSiblingPosition(null);
          await _dao.setSiblingPosition(item.id, position, at);
        }
        return const Ok(null);
      }
      if (items.values.any((item) => item.parentId == null)) {
        return const Rejected(DeckRejection.rootRestoresToTopLevel);
      }
      final target = await _dao.findRow(parentId);
      if (target == null) return Rejected(await _tree.missingTarget(parentId));
      for (final item in items.values) {
        if (await _tree.refusalUnder(target, item) case final reason?) {
          return Rejected(reason);
        }
      }
      for (final MapEntry(key: batchId, value: item) in items.entries) {
        await _dao.restoreBatch(batchId);
        // Read again: an item restored before it may have carried it along,
        // when this batch lies inside that one (D10).
        await _tree.moveUnder(
          target,
          (await _dao.findRow(item.id))!,
          siblingPosition: await _dao.nextSiblingPosition(target.id),
          at: at,
        );
      }
      await _tree.refreshContentType(target.id, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> undoDeckDeletion({
    required String batchId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final item = await _dao.itemRootOf(batchId);
      if (item == null) return const Rejected(DeckRejection.notFound);
      final parentId = item.parentId;
      if (parentId == null) {
        await _dao.restoreBatch(batchId);
        return const Ok(null);
      }
      final target = await _dao.findRow(parentId);
      if (target == null) return Rejected(await _tree.missingTarget(parentId));
      if (await _tree.refusalUnder(target, item) case final reason?) {
        return Rejected(reason);
      }
      await _dao.restoreBatch(batchId);
      // Its old place: nothing took that position, since a new sibling's
      // position counts the tombstones (trash spec D9).
      await _tree.moveUnder(
        target,
        item,
        siblingPosition: item.siblingPosition,
        at: at,
      );
      await _tree.refreshContentType(target.id, at);
      return const Ok(null);
    });
  }

  @override
  Future<DeckEntity?> findById(String id) => _mapped(() async {
    final row = await _dao.findRow(id);
    return row == null ? null : deckEntityOf(row);
  });

  @override
  Stream<List<DeckTile>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) => _dao
      .watchLevel(parentId: parentId, now: now, startOfToday: startOfToday)
      .map((rows) => [for (final row in rows) deckTileOf(row, startOfToday)])
      .mapDatabaseErrors();

  @override
  Stream<DeckView?> watchDeck(String deckId) =>
      _dao.watchDeckAndAncestors(deckId).map(deckViewOf).mapDatabaseErrors();

  @override
  Stream<List<DeckMoveTarget>> watchMoveTargets(String deckId) => _dao
      .watchMoveTargetRows(deckId, maxDepth: DeckEntity.maxDepth)
      .map(
        (rows) => candidatesInTreeOrder(
          [for (final row in rows) deckTreeNodeOf(row)],
          (node, path) =>
              DeckMoveTarget(id: node.id, name: node.name, path: path),
        ),
      )
      .mapDatabaseErrors();

  @override
  Stream<List<DeckSearchHit>> watchSearch({
    required String? scopeDeckId,
    required String foldedTerm,
  }) => _dao
      .watchSearchRows(scopeDeckId)
      .map(
        (rows) => [
          for (final hit in candidatesInTreeOrder(
            [for (final row in rows) deckTreeNodeOf(row)],
            (node, path) => DeckSearchHit(
              id: node.id,
              name: node.name,
              path: path,
              contentType: node.contentType,
            ),
          ))
            if (foldText(hit.name).contains(foldedTerm)) hit,
        ],
      )
      .mapDatabaseErrors();

  /// One transaction; see [_mapped] for what leaves it on an error.
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  /// An unexpected database error leaves as the [Failure] `mapDatabaseError`
  /// makes of it, with its stack trace. A transaction has rolled back by then.
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

DeckRejection? _refusal(Outcome<void, DeckRejection> check) => switch (check) {
  Ok() => null,
  Rejected(:final reason) => reason,
};
