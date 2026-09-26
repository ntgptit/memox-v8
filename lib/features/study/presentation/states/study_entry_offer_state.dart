import 'dart:math';

import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The study modes the app has a screen for. It grows each phase and goes
/// once all six are built (FE-A6 spec §3): an unbuilt stage is never
/// offered.
const Set<StudyMode> builtStudyModes = <StudyMode>{};

/// How the entry shows a review mode.
enum ReviewOfferStatus {
  /// Runnable and built: it can be picked.
  available,

  /// The cards cannot run it; its reason shows (BR-STUDY-044, BR-MODE-009).
  unavailable,

  /// Runnable, but the app has no screen for it yet (spec §3).
  comingSoon,
}

/// A review mode and how the entry shows it.
final class ReviewOffer {
  const ReviewOffer({required this.option, required this.status});

  final ReviewModeOption option;
  final ReviewOfferStatus status;
}

/// What the Study Entry offers (UC-STUDY-001 steps 2–4; spec §3).
final class StudyEntryOffer {
  const StudyEntryOffer({
    required this.isNothingDue,
    required this.canLearn,
    required this.isLearnComingSoon,
    required this.learnShown,
    required this.reviews,
    required this.canContinue,
  });

  /// Nothing new and nothing due (BR-STUDY-008, BR-STUDY-054).
  final bool isNothingDue;

  /// New cards exist and every stage of the sequence is built (BR-MODE-004).
  final bool canLearn;

  /// New cards exist but a stage of the sequence is not built.
  final bool isLearnComingSoon;

  /// The new cards a learning session would take, capped by the session
  /// limit (BR-STUDY-003).
  final int learnShown;
  final List<ReviewOffer> reviews;

  /// A resumable session whose current mode is built (BR-STUDY-075).
  final bool canContinue;
}

/// What [entry] offers when the app has built the modes in [built].
StudyEntryOffer studyEntryOfferOf(
  StudyEntry entry, {
  Set<StudyMode> built = builtStudyModes,
}) {
  final hasNew = entry.newCardCount > 0;
  final isSequenceBuilt = stageSequenceOf(entry.schedulerType)
      .every(built.contains);
  final resumable = entry.resumable;
  return StudyEntryOffer(
    isNothingDue: entry.newCardCount == 0 && entry.dueCardCount == 0,
    canLearn: hasNew && isSequenceBuilt,
    isLearnComingSoon: hasNew && !isSequenceBuilt,
    learnShown: min(entry.newCardCount, entry.cardLimit),
    reviews: [
      for (final option in entry.reviewModes)
        ReviewOffer(option: option, status: _statusOf(option, built)),
    ],
    canContinue: resumable != null && built.contains(resumable.mode),
  );
}

ReviewOfferStatus _statusOf(ReviewModeOption option, Set<StudyMode> built) {
  if (option.unavailableReason != null) return ReviewOfferStatus.unavailable;
  if (built.contains(option.mode)) return ReviewOfferStatus.available;
  return ReviewOfferStatus.comingSoon;
}
