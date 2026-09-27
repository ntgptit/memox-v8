import 'package:memox/features/srs/domain/models/due_date_model.dart';

/// When the next card of a caught-up Study Home falls due, as its body says
/// it (FE-A8 S2): on the local day, the one boundary due dates split on
/// (BR-STUDY-074).
sealed class CaughtUpWhen {
  const CaughtUpWhen();
}

/// No learned card waits: every card is simply resting.
final class CaughtUpResting extends CaughtUpWhen {
  const CaughtUpResting();
}

/// The next card falls due on the next local day.
final class CaughtUpTomorrow extends CaughtUpWhen {
  const CaughtUpTomorrow();
}

/// The next card falls due on [day], a later local day.
final class CaughtUpOnDay extends CaughtUpWhen {
  const CaughtUpOnDay(this.day);

  final DateTime day;
}

/// [nextDueAt] read against [now]'s local day. A time later today, which a
/// caught-up snapshot never holds, reads as tomorrow rather than a past day.
CaughtUpWhen caughtUpWhenOf(DateTime? nextDueAt, DateTime now) {
  if (nextDueAt == null) return const CaughtUpResting();
  final day = startOfLocalDay(nextDueAt);
  if (!day.isAfter(dueAtLocalMidnight(now, 1))) return const CaughtUpTomorrow();
  return CaughtUpOnDay(day);
}
