import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';

/// Every write reads the rows its rules need and writes inside one
/// transaction, so a rule never judges data another write has changed.
final class DeckRepositoryImpl implements DeckRepository {
  DeckRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = DeckDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DeckDao _dao;
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
      return Ok(_toEntity((await _dao.findRow(id))!));
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
      await _refreshContentType(parentId, at);
      return Ok(_toEntity((await _dao.findRow(id))!));
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
      final movingRoot = await _dao.findRow(moving.rootId);
      final targetRoot = await _dao.findRow(target.rootId);
      if (movingRoot == null || targetRoot == null) {
        return const Rejected(DeckRejection.notFound);
      }
      final rule = DeckEntity.checkMove(
        movingId: deckId,
        targetParentId: newParentId,
        targetAncestorIds: await _dao.ancestorIds(newParentId),
        targetDepth: target.depth,
        subtreeHeight: await _dao.subtreeHeight(
          deckId,
          cap: DeckEntity.maxDepth,
        ),
        targetContentType: DeckContentType.values.byName(target.contentType),
        movingRootScheduler: _schedulerOf(movingRoot),
        movingRootGeneration: movingRoot.generation,
        targetRootScheduler: _schedulerOf(targetRoot),
        targetRootGeneration: targetRoot.generation,
      );
      if (_refusal(rule) case final reason?) return Rejected(reason);

      await _dao.moveSubtree(
        deckId,
        parentId: newParentId,
        rootId: target.rootId,
        depthShift: target.depth + 1 - moving.depth,
        siblingPosition: await _dao.nextSiblingPosition(newParentId),
        now: at,
      );
      await _refreshContentType(oldParentId, at);
      await _refreshContentType(newParentId, at);
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
  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) {
    final at = _now();
    return _write(() async {
      final deck = await _dao.findRow(deckId);
      if (deck == null) return const Rejected(DeckRejection.notFound);
      // Sub-decks, cards, schedule rows, review logs and sessions go with it
      // by cascade (BR-DECK-022).
      await _dao.delete(deckId);
      if (deck.parentId case final parentId?) {
        await _refreshContentType(parentId, at);
      }
      return const Ok(null);
    });
  }

  @override
  Future<DeckEntity?> findById(String id) => _mapped(() async {
    final row = await _dao.findRow(id);
    return row == null ? null : _toEntity(row);
  });

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
  /// BR-DECK-015); a root is always a deck of decks (BR-DECK-004).
  Future<void> _refreshContentType(String deckId, DateTime at) async {
    final deck = await _dao.findRow(deckId);
    if (deck == null || deck.parentId == null) return;
    final contentType = await _dao.contentTypeFromChildren(deckId);
    if (contentType == deck.contentType) return;
    await _dao.setContentType(deckId, contentType, at);
  }

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

SchedulerType? _schedulerOf(Deck row) => switch (row.schedulerType) {
  final String code => SchedulerType.fromCode(code),
  null => null,
};

DeckEntity _toEntity(Deck row) => DeckEntity(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  rootId: row.rootId,
  depth: row.depth,
  contentType: DeckContentType.values.byName(row.contentType),
  schedulerType: _schedulerOf(row),
  generation: row.generation,
  firstAnsweredAt: row.firstAnsweredAt,
  siblingPosition: row.siblingPosition,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);
