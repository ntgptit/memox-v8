import 'dart:math';

import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// How the entry shows a review mode.
enum ReviewOfferStatus {
  /// The cards can run it: it can be picked.
  available,

  /// The cards cannot run it; its reason shows (BR-STUDY-044, BR-MODE-009).
  unavailable,
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
    required this.learnShown,
    required this.reviews,
    required this.reviewTarget,
    required this.canContinue,
  });

  /// Nothing new and nothing due (BR-STUDY-008, BR-STUDY-054).
  final bool isNothingDue;

  /// New cards exist: a learning session runs the whole stage sequence
  /// (BR-MODE-004), every stage of which has its screen (FE-A6 P4).
  final bool canLearn;

  /// The new cards a learning session would take, capped by the session
  /// limit (BR-STUDY-003).
  final int learnShown;
  final List<ReviewOffer> reviews;

  /// The review the footer starts: the picked mode while it is available,
  /// else the first available one (FE-A6 P3, E1); null with none.
  final ReviewModeOption? reviewTarget;

  /// A session can be resumed (BR-STUDY-075).
  final bool canContinue;
}

/// What [entry] offers, with [picked] the review mode the person picked
/// (E1).
StudyEntryOffer studyEntryOfferOf(StudyEntry entry, {StudyMode? picked}) {
  final reviews = [
    for (final option in entry.reviewModes)
      ReviewOffer(
        option: option,
        status: option.unavailableReason == null
            ? ReviewOfferStatus.available
            : ReviewOfferStatus.unavailable,
      ),
  ];
  // A mode runs on no due cards too; a review still needs a card to ask.
  final available = [
    for (final review in reviews)
      if (review.status == ReviewOfferStatus.available &&
          review.option.cardCount > 0)
        review.option,
  ];
  return StudyEntryOffer(
    isNothingDue: entry.newCardCount == 0 && entry.dueCardCount == 0,
    canLearn: entry.newCardCount > 0,
    learnShown: min(entry.newCardCount, entry.cardLimit),
    reviews: reviews,
    reviewTarget: _targetOf(available, picked),
    canContinue: entry.resumable != null,
  );
}

ReviewModeOption? _targetOf(
  List<ReviewModeOption> available,
  StudyMode? picked,
) {
  for (final option in available) {
    if (option.mode == picked) return option;
  }
  return available.isEmpty ? null : available.first;
}

/// The footer's one action (screen 14): a review when there is one to start,
/// else Learn; none when neither can run, and the footer is not drawn.
enum EntryFooterAction { review, learn }

EntryFooterAction? entryFooterActionOf(StudyEntryOffer offer) {
  if (offer.reviewTarget != null) return EntryFooterAction.review;
  if (offer.canLearn) return EntryFooterAction.learn;
  return null;
}
