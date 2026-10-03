import 'package:flutter/foundation.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/presentation/providers/add_starter_deck_use_case_provider.dart';
import 'package:memox/features/starter_decks/presentation/states/starter_add_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'starter_add_controller.g.dart';

/// The algorithm sheet's add (UC-STARTER-001 step 8, A2; FE-B4 spec D6). It
/// lives while the sheet does, so each sheet starts clean.
@riverpod
class StarterAddController extends _$StarterAddController {
  @override
  StarterAddState build() => const StarterAddState();

  /// Adds [templateId] under [schedulerType]. Null keeps the sheet open: an
  /// add while one runs is ignored, and a failed one sets
  /// [StarterAddState.hasFailed]. `templateNotFound` reads as a failure,
  /// never as its own message (spec §6).
  Future<StarterAddResult?> add({
    required String templateId,
    required SchedulerType schedulerType,
    required bool allowSecondCopy,
  }) async {
    if (state.isAdding) return null;
    state = const StarterAddState(isAdding: true);
    try {
      final outcome = await ref.read(addStarterDeckUseCaseProvider)(
        templateId: templateId,
        schedulerType: schedulerType,
        allowSecondCopy: allowSecondCopy,
      );
      final result = switch (outcome) {
        Ok(:final value) => StarterAdded(value),
        Rejected(reason: StarterRejection.alreadyInLibrary) =>
          const StarterAlreadyPresent(),
        Rejected(reason: StarterRejection.templateNotFound) => null,
      };
      if (ref.mounted) state = StarterAddState(hasFailed: result == null);
      return result;
    } on Object catch (error, stack) {
      // A database `Failure` reads as a failed add; anything else the add
      // threw is reported as the import undo's catch-all does. Both end in
      // hasFailed, so the sheet reads "Try again" and Back is released
      // (SP2b 2.29).
      if (error is! Failure) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'starter add',
          ),
        );
      }
      if (ref.mounted) state = const StarterAddState(hasFailed: true);
      return null;
    }
  }
}
