/// What a turn reads of its card (graded modes spec §7.2).
final class TurnCard {
  const TurnCard({
    required this.cardId,
    required this.frontFolded,
    required this.backFolded,
  });

  final String cardId;

  /// `fill` compares the typed term with it (BR-STUDY-026).
  final String frontFolded;

  /// `match` compares two meanings by it (spec D3).
  final String backFolded;
}

/// The facts a mode judges a turn on. The session reads them in the turn's
/// transaction, so the judging itself stays a pure function (spec §7.2).
final class TurnContext {
  const TurnContext({
    required this.card,
    this.isRevealed = false,
    this.isHintShown = false,
    this.guessOptionIds,
    this.boardMeanings = const {},
  });

  final TurnCard card;

  /// `recall`: the answer of this turn has been revealed (BR-STUDY-065).
  final bool isRevealed;

  /// `fill`: the hint of this turn has been shown (BR-STUDY-028).
  final bool isHintShown;

  /// `guess`: the stored options of the row, in the order shown; a question
  /// without five takes no answer (BR-STUDY-040). Null in the other modes.
  final List<String>? guessOptionIds;

  /// `match`: the pending pairs of the current board, card id to
  /// `back_folded`.
  final Map<String, String> boardMeanings;
}

/// Why a wrong outcome was recorded without the person choosing it, stored
/// as its code on `review_log.outcome_reason` (BR-STUDY-034).
enum OutcomeReason {
  timeout('timeout');

  const OutcomeReason(this.code);

  final String code;
}

/// What a mode makes of a turn (spec §7.2): the action it records, whether a
/// graded answer was right, what `review_log` keeps of the turn, and for
/// `match` the card whose meaning slot the turn's card takes.
final class TurnVerdict {
  const TurnVerdict({
    required this.action,
    this.isCorrect,
    this.outcomeReason,
    this.comparisonVersion,
    this.usedHint,
    this.takesMeaningSlotOf,
  });

  /// One of the scheduler's actions; null for `browse`, which records none.
  final Object? action;

  /// Null for `browse` and `self_assess`, whose result the person chose.
  final bool? isCorrect;
  final OutcomeReason? outcomeReason;

  /// `fill` only (BR-STUDY-027).
  final int? comparisonVersion;

  /// `fill` only (BR-STUDY-028).
  final bool? usedHint;

  /// `match`: a right pair on another card's equal meaning. The two rows swap
  /// their meaning slots, so the tile the person tapped is the one matched
  /// (spec §7.6).
  final String? takesMeaningSlotOf;
}
