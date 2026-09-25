/// A built row of a round, as preparing the round reads it (graded modes
/// spec §7.7).
final class RoundRowFacts {
  const RoundRowFacts({
    required this.cardId,
    required this.position,
    required this.isPending,
    required this.meaningSlot,
    required this.optionCount,
    required this.meaningFolded,
  });

  final String cardId;
  final int position;
  final bool isPending;

  /// `match`: the row's meaning slot, null until the round is prepared.
  final int? meaningSlot;

  /// `guess`: how many options the row's question has stored.
  final int optionCount;

  /// The card's `back_folded`.
  final String meaningFolded;
}

/// A card the options of a `guess` question can come from: its id and its
/// meaning, compared folded (BR-STUDY-038, BR-STUDY-039).
typedef MeaningCard = ({String cardId, String meaningFolded});

/// What preparing a round writes (spec §7.7). Empty when the round has all
/// it needs.
final class RoundPreparation {
  const RoundPreparation({
    this.meaningSlots = const {},
    this.questions = const {},
  });

  /// `match`: the meaning slot of each card of a board that lacked one.
  final Map<String, int> meaningSlots;

  /// `guess`: each card whose question is built again, with its five options
  /// in the order shown, or null when it cannot be built (BR-STUDY-040).
  final Map<String, List<String>?> questions;

  bool get isEmpty => meaningSlots.isEmpty && questions.isEmpty;
}
