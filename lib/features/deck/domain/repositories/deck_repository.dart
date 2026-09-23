import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
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

  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  });

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId});

  Future<DeckEntity?> findById(String id);
}
