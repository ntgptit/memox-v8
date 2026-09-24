import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/providers/create_root_deck_use_case_provider.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memox/features/deck/presentation/providers/change_deck_scheduler_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/reorder_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/reset_learning_progress_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/move_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/rename_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/providers/create_sub_deck_use_case_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';

part 'deck_actions_controller.g.dart';

/// The deck writes the Library triggers.
///
/// Each command calls exactly one use case (AD-12) and hands back its
/// `Outcome`, and the widget chooses the feedback. A database `Failure` is
/// thrown through for the widget to show. The controller holds no state.
@riverpod
class DeckActionsController extends _$DeckActionsController {
  @override
  void build() {}

  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
  }) => ref.read(createRootDeckUseCaseProvider)(
    name: name,
    schedulerType: schedulerType,
  );

  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
  }) => ref.read(createSubDeckUseCaseProvider)(parentId: parentId, name: name);

  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
  }) => ref.read(renameDeckUseCaseProvider)(deckId: deckId, name: name);

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) =>
      ref.read(deleteDeckUseCaseProvider)(deckId: deckId);

  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
  }) => ref.read(moveDeckUseCaseProvider)(
    deckId: deckId,
    newParentId: newParentId,
  );

  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
  }) => ref.read(reorderDeckUseCaseProvider)(
    deckId: deckId,
    anchorId: anchorId,
    placement: placement,
  );

  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => ref.read(changeDeckSchedulerUseCaseProvider)(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );

  /// UC-SRS-001 steps 3 to 5: a new cycle for [rootDeckId]'s tree, keeping
  /// its algorithm or switching to [schedulerType].
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) => ref.read(resetLearningProgressUseCaseProvider)(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
}
