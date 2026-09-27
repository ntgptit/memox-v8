import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/repositories/starter_library_repository.dart';

/// UC-STARTER-001 steps 6-8 and A2: a template becomes a deck tree of the
/// person's own under the scheduler they chose; a second copy only when they
/// confirm one (BR-STARTER-008).
final class AddStarterDeckUseCase {
  const AddStarterDeckUseCase(this._library);

  final StarterLibraryRepository _library;

  Future<Outcome<AddedStarterDeck, StarterRejection>> call({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
  }) => _library.addStarterDeck(
    templateId: templateId,
    schedulerType: schedulerType,
    allowSecondCopy: allowSecondCopy,
  );
}
