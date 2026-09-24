import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// What resetting the learning progress of a root's tree would clear, told to
/// the person before they confirm (UC-SRS-001 step 2). The lists of what is
/// kept and what is lost are copy (BR-SRS-030); these are the facts behind
/// them.
final class ResetLearningSummary {
  const ResetLearningSummary({
    required this.schedulerType,
    required this.isSchedulerLocked,
    required this.cardCount,
    required this.learnedCardCount,
    required this.openSessionCount,
  });

  /// The scheduler the tree runs now; the reset keeps it or picks another
  /// (UC-SRS-001 step 3).
  final SchedulerType schedulerType;

  /// A card of the tree finished learning, which locks the scheduler
  /// (BR-SRS-003); only a reset unlocks it (BR-SRS-024).
  final bool isSchedulerLocked;

  /// The cards of the tree at any depth, outside the Trash.
  final int cardCount;

  /// The cards among them that finished learning: the reset makes them new
  /// again (BR-SRS-022).
  final int learnedCardCount;

  /// The sessions of the tree still in progress: the reset closes them
  /// (BR-STUDY-015).
  final int openSessionCount;

  /// False when the reset would take nothing away, which UC-SRS-001 A2 tells
  /// the person.
  bool get hasProgressToLose => learnedCardCount > 0 || openSessionCount > 0;
}
