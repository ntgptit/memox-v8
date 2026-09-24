import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// UC-DECK-001: a new root deck and the scheduler its cards will follow.
final class CreateRootDeckUseCase {
  const CreateRootDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<DeckEntity, DeckRejection>> call({
    required String name,
    required SchedulerType schedulerType,
  }) => _decks.createRootDeck(name: name, schedulerType: schedulerType);
}
