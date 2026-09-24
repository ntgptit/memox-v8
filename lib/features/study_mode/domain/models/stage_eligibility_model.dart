/// What a stage's data condition reads of one card (BR-STUDY-071).
final class StudyCardFacts {
  const StudyCardFacts({required this.cardId, required this.hasExample});

  final String cardId;
  final bool hasExample;
}

/// Why a stage cannot run on a set of cards (BR-MODE-009): a learning
/// session skips it, a review shows the mode disabled with this reason.
enum ModeUnavailableReason {
  /// No card of the set has an `example` (`fill`, BR-STUDY-044).
  noExample,

  /// Fewer than two cards: one pair is its own answer (`match`,
  /// BR-STUDY-045).
  tooFewPairs,

  /// Fewer than five distinct meanings to draw the options from (`guess`,
  /// BR-STUDY-037, BR-STUDY-040; spec D5).
  tooFewMeanings,
}

/// Whether a stage runs on a set of cards, and on which of them
/// (BR-MODE-009, BR-STUDY-025).
sealed class StageEligibility {
  const StageEligibility();
}

/// The stage asks [cardIds]; every other card of the set is skipped in this
/// stage only (BR-STUDY-071).
final class StageRuns extends StageEligibility {
  const StageRuns(this.cardIds);

  final List<String> cardIds;
}

final class StageSkipped extends StageEligibility {
  const StageSkipped(this.reason);

  final ModeUnavailableReason reason;
}
