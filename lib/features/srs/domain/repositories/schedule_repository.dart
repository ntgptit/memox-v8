import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
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

  /// Records one answer of a study session (BR-SRS-019). Only a `scheduled`
  /// turn changes the schedule; `learning` and `relearning` turns stamp
  /// `last_answered_at` and nothing else (BR-SRS-016, BR-SRS-017,
  /// BR-SRS-018). Refused, writing nothing, for a card that is gone or in the
  /// Trash (notFound), a turn of another generation (staleGeneration) and an
  /// action the root scheduler does not support (unsupportedAction). A
  /// `scheduled` turn on a card still learning is a bug: it throws and
  /// writes nothing (BR-STUDY-058). Joins the caller's transaction.
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn);

  /// The stored schedule of [cardId] and the scheduler it runs under, for a
  /// read-only preview (FE-A6 D11); null when the card is gone or in the
  /// Trash. It writes nothing.
  Future<(SchedulerType, CardScheduleState)?> scheduleOf({
    required String cardId,
  });

  /// A card finished learning (BR-STUDY-053): its schedule starts at the
  /// lowest level, due at the next local midnight, and no `review_log` row is
  /// written. The first completion of a generation also locks the root's
  /// scheduler, in one write with it (BR-SRS-003). Refused, writing nothing,
  /// for a card that is gone or in the Trash (notFound) and another
  /// generation (staleGeneration). Completing a learned card is a bug: it
  /// throws and writes nothing. Joins the caller's transaction.
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  });

  /// Reset learning progress (UC-SRS-001), all of it or nothing of it
  /// (BR-SRS-027): a new generation, every schedule row of the tree back to
  /// the start values of the scheduler it ends up with, the scheduler
  /// unlocked, the open sessions closed. A [schedulerType] other than the
  /// root's switches the scheduler too; null keeps it. This is the only way
  /// to change the scheduler of a locked tree (BR-SRS-024).
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  });

  /// What a reset of [rootDeckId] would clear, for its confirmation
  /// (UC-SRS-001 step 2): notFound when the root does not exist or is in the
  /// Trash, notARootDeck for a sub-deck.
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
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
