import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/mappers/deck_mapper.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

/// The tree writes that several deck writes share, inside the caller's
/// transaction: whether a deck may go under another, putting it there with
/// its subtree, and the content type that follows what a deck holds. A move
/// and a restore ask the same rules (BR-TRASH-006).
final class DeckTreeDataSource {
  DeckTreeDataSource(AppDatabase db) : _dao = DeckDao(db);

  final DeckDao _dao;

  /// Why [moving] may not go under [target], by the rules of a move
  /// (BR-DECK-001, BR-DECK-009, BR-DECK-017, BR-DECK-024): null when it may.
  /// [moving] may be in the Trash, and so may its root: a restore asks this
  /// too (BR-TRASH-006).
  Future<DeckRejection?> refusalUnder(Deck target, Deck moving) async {
    final movingRoot = await _dao.rowInAnyState(moving.rootId);
    final targetRoot = await _dao.findRow(target.rootId);
    if (movingRoot == null || targetRoot == null) {
      return DeckRejection.notFound;
    }
    final rule = DeckEntity.checkMove(
      movingId: moving.id,
      targetParentId: target.id,
      targetAncestorIds: await _dao.ancestorIds(target.id),
      targetDepth: target.depth,
      subtreeHeight: await _dao.subtreeHeight(
        moving.id,
        cap: DeckEntity.maxDepth,
      ),
      targetContentType: DeckContentType.values.byName(target.contentType),
      movingRootScheduler: schedulerTypeOf(movingRoot),
      movingRootGeneration: movingRoot.generation,
      targetRootScheduler: schedulerTypeOf(targetRoot),
      targetRootGeneration: targetRoot.generation,
    );
    return switch (rule) {
      Ok() => null,
      Rejected(:final reason) => reason,
    };
  }

  /// [moving] and its whole subtree under [target] at [siblingPosition]:
  /// the root and depths follow, tombstones inside included (BR-DECK-018,
  /// trash spec D10).
  Future<void> moveUnder(
    Deck target,
    Deck moving, {
    required int siblingPosition,
    required DateTime at,
  }) => _dao.moveSubtree(
    moving.id,
    parentId: target.id,
    rootId: target.rootId,
    depthShift: target.depth + 1 - moving.depth,
    siblingPosition: siblingPosition,
    now: at,
  );

  /// Why [deckId] cannot take a restore: it is in the Trash, or it is gone
  /// (BR-TRASH-006).
  Future<DeckRejection> missingTarget(String deckId) async =>
      await _dao.isInTrash(deckId)
      ? DeckRejection.targetInTrash
      : DeckRejection.targetNotFound;

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
  /// BR-DECK-015); a root is always a deck of decks (BR-DECK-004).
  Future<void> refreshContentType(String deckId, DateTime at) async {
    final deck = await _dao.findRow(deckId);
    if (deck == null || deck.parentId == null) return;
    final contentType = await _dao.contentTypeFromChildren(deckId);
    if (contentType == deck.contentType) return;
    await _dao.setContentType(deckId, contentType, at);
  }
}
