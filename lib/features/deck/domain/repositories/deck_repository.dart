import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The one implementation is `DeckRepositoryImpl` (data layer, Task 7). The
/// contract exists so `domain/` stays framework-free and tests substitute a
/// fake — see ADR-010's "concrete architectural reason" note.
abstract interface class DeckRepository {
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
    DateTime? now,
  });

  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
    DateTime? now,
  });

  /// BR-DECK-020: the trimmed name replaces the old one.
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  });

  /// BR-SRS-007: [deckId] moves just before or after [anchorId], a deck with
  /// the same parent, and the group is numbered again from 0.
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  });

  /// BR-DECK-023: what deleting [deckId] would take with it.
  Future<Outcome<DeckDeletionSummary, DeckRejection>> deletionSummary(
    String deckId,
  );

  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  });

  /// UC-DECK-002: [deckId] and every active deck and card under it go to the
  /// Trash as one batch, whose id comes back for an Undo (BR-DECK-022,
  /// BR-TRASH-001). The sessions it touches end (BR-TRASH-004).
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  });

  /// UC-TRASH-001 steps 5-7: the decks of [batchIds] come back under
  /// [parentId], or to the top level when it is null, each last among its
  /// new siblings, in the order given, all or none. A root deck goes back to
  /// the top level only, a sub-deck under a deck only, and each passes the
  /// rules of a move (BR-TRASH-006, BR-TRASH-007).
  Future<Outcome<void, DeckRejection>> restoreDecks({
    required Set<String> batchIds,
    required String? parentId,
    DateTime? now,
  });

  /// BR-TRASH-008: the deck of [batchId] goes back where it was, at its old
  /// position; refused, typed, when that place no longer takes it.
  Future<Outcome<void, DeckRejection>> undoDeckDeletion({
    required String batchId,
    DateTime? now,
  });

  /// UC-TRASH-001 step 5: where the decks of [batchIds] may go back, again
  /// on every change of the decks or the batches (BR-TRASH-006, E1, E2).
  Stream<DeckRestoreTargets> watchRestoreTargets(Set<String> batchIds);

  Future<DeckEntity?> findById(String id);

  /// UC-DECK-003: the decks under [parentId], the roots when it is null, in
  /// manual order, with the counts of their subtrees as of [now] and the
  /// local day starting at [startOfToday]. Emits again on every change.
  Stream<List<DeckTile>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  });

  /// An open deck, again on every change; null once it is gone or in the
  /// Trash.
  Stream<DeckView?> watchDeck(String deckId);

  /// UC-DECK-005: where [deckId] may move, in tree order; empty for a root.
  Stream<List<DeckMoveTarget>> watchMoveTargets(String deckId);
}
