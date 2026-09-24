import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/presentation/providers/create_root_deck_use_case_provider.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
}
