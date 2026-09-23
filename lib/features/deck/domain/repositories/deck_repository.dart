import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
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

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId});

  Future<DeckEntity?> findById(String id);
}
