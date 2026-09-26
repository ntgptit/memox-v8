import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The Study Entry of a deck (UC-STUDY-001 steps 1–2 and 4; spec §8.1). The
/// UI builds its actions and the stage chain from the domain (BR-STUDY-009).
final class StudyEntry {
  const StudyEntry({
    required this.schedulerType,
    required this.cardLimit,
    required this.newCardCount,
    required this.dueCardCount,
    required this.overdueCardCount,
    required this.nextDueAt,
    required this.reviewModes,
    required this.resumable,
  });

  final SchedulerType schedulerType;

  /// The distinct cards a session takes (BR-STUDY-003).
  final int cardLimit;

  /// The new and the due cards of the deck and its subtree. The two sets are
  /// disjoint and never capped (BR-STUDY-051, IT-STUDY-001).
  final int newCardCount;
  final int dueCardCount;

  /// The due cards whose due day is before today, the boundary the Library
  /// hero counts with (BR-STUDY-068); a part of [dueCardCount] (FE-A6 D15).
  final int overdueCardCount;

  /// The earliest `due_at` after now, for the empty state (E1,
  /// BR-STUDY-008); null when no learned card waits.
  final DateTime? nextDueAt;

  /// One per review mode of [schedulerType] (BR-STUDY-055).
  final List<ReviewModeOption> reviewModes;

  /// This deck's open session, when Continue can take it up (BR-STUDY-075),
  /// with what the resume banner says of it (FE-A6 D15).
  final ResumableSession? resumable;
}

/// A review mode as the Study Entry offers it (BR-STUDY-044, BR-MODE-009).
final class ReviewModeOption {
  const ReviewModeOption({
    required this.mode,
    required this.cardCount,
    required this.unavailableReason,
    required this.isDirectionRequired,
  });

  final StudyMode mode;

  /// The cards a review in [mode] would ask now.
  final int cardCount;

  /// Why [mode] cannot run on those cards; null when it can.
  final ModeUnavailableReason? unavailableReason;

  /// Whether opening it needs a direction (BR-MODE-013).
  final bool isDirectionRequired;
}

/// The review modes of [type] (BR-STUDY-055) on [dueCards], the cards a
/// review would take, through the same eligibility an opening runs (spec
/// §5.3), so the entry and the session cannot disagree (BR-STUDY-044).
List<ReviewModeOption> reviewModeOptions(
  SchedulerType type,
  List<StudyCardFacts> dueCards, {
  required int distinctMeaningCount,
}) => [
  for (final mode in reviewModesOf(type))
    switch (mode.handler.eligibility(
      dueCards,
      distinctMeaningCount: distinctMeaningCount,
    )) {
      StageRuns(:final cardIds) => ReviewModeOption(
        mode: mode,
        cardCount: cardIds.length,
        unavailableReason: null,
        isDirectionRequired: acceptsDirection(
          SessionKind.reviewing,
          type,
          mode,
        ),
      ),
      StageSkipped(:final reason) => ReviewModeOption(
        mode: mode,
        cardCount: 0,
        unavailableReason: reason,
        isDirectionRequired: acceptsDirection(
          SessionKind.reviewing,
          type,
          mode,
        ),
      ),
    },
];
