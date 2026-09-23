import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The one implementation is `ScheduleRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class ScheduleRepository {
  /// Writes the schedule row of a card just created (BR-CARD-004): the start
  /// values of its root's scheduler, at the root's generation. Joins the
  /// caller's transaction. Throws [StateError] when the card does not exist:
  /// the caller inserts the card first, in that same transaction, so a
  /// missing card is a bug, not a business outcome.
  Future<void> initializeCard({required String cardId});

  Future<Outcome<void, SrsRejection>> recordReview({
    required String cardId,
    required String sessionId,
    required Object action,
    DateTime? now,
  });

  /// Reset learning progress: a new generation, every schedule row of the
  /// tree back to its start values, the scheduler unlocked, the open sessions
  /// closed.
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
  });

  /// Changes the scheduler of an unlocked tree: every schedule row of the tree
  /// starts over under [newType] at the same generation, and the open sessions
  /// are closed. The scheduler the root already runs changes nothing.
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType newType,
  });
}
