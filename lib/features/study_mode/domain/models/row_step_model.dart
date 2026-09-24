/// What a turn does to its queue row (spec §5.5). The study session applies
/// it in the turn's transaction.
sealed class RowStep {
  const RowStep();
}

/// The row is done (BR-STUDY-007).
final class Leave extends RowStep {
  const Leave();
}

/// `self_assess`: the same row stays pending and is served again once
/// [afterTurns] other turns have passed, or at the end when fewer remain
/// (BR-STUDY-005).
final class ComeBack extends RowStep {
  const ComeBack({required this.afterTurns});

  final int afterTurns;
}

/// `self_assess` at its cap: the row is done even though the card was
/// forgotten, and the card is flagged (BR-STUDY-073).
final class LeaveAtCap extends RowStep {
  const LeaveAtCap();
}

/// `match`: the row stays on the board, and the card joins the next round
/// once (BR-STUDY-062).
final class StayAndEnroll extends RowStep {
  const StayAndEnroll();
}

/// `guess`, `recall`, `fill`: the row is done, and the card joins the next
/// round once (BR-STUDY-059, BR-STUDY-060).
final class LeaveAndEnroll extends RowStep {
  const LeaveAndEnroll();
}
