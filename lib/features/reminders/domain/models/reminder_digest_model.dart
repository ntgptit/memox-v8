import 'package:memox/core/text/folded_text.dart';

/// One root deck's cards due when the reminder fires: its whole tree, grouped
/// by `root_id` so that each card counts once (BR-REMINDER-007). Learned
/// cards only; a card still being learned is never due (BR-REMINDER-003).
final class ReminderDeckWorkload {
  const ReminderDeckWorkload({
    required this.deckId,
    required this.name,
    required this.overdueCount,
    required this.overdueDays,
    required this.dueTodayCount,
  });

  final String deckId;
  final String name;

  /// Due before the start of today (BR-STUDY-068).
  final int overdueCount;

  /// The local day boundaries passed since the oldest due card fell due; 0
  /// when nothing is overdue (BR-STUDY-067).
  final int overdueDays;

  /// Due from the start of today up to now (BR-STUDY-068).
  final int dueTodayCount;

  int get dueCount => overdueCount + dueTodayCount;
}

/// BR-REMINDER-006: the most urgent first. Overdue cards, then the oldest
/// overdue age, then the cards due today, each descending; then the folded
/// name (`foldText`, as Study Home sorts), then the id, so that no two roots
/// tie.
int compareReminderDecks(ReminderDeckWorkload a, ReminderDeckWorkload b) {
  final overdue = b.overdueCount.compareTo(a.overdueCount);
  if (overdue != 0) return overdue;
  final age = b.overdueDays.compareTo(a.overdueDays);
  if (age != 0) return age;
  final dueToday = b.dueTodayCount.compareTo(a.dueTodayCount);
  if (dueToday != 0) return dueToday;
  final name = foldText(a.name).compareTo(foldText(b.name));
  if (name != 0) return name;
  return a.deckId.compareTo(b.deckId);
}

/// What the day's one notification may say (BR-REMINDER-005): the most
/// urgent root deck, that deck's own due count, and how many other root
/// decks have cards due (reminders spec D9). Never a card, a tag or a
/// history.
final class ReminderDigest {
  const ReminderDigest({
    required this.deckName,
    required this.dueCount,
    required this.otherDeckCount,
  });

  final String deckName;
  final int dueCount;
  final int otherDeckCount;
}

/// The digest of [workloads], or null when no root deck has a card due: the
/// reminder then shows nothing (BR-REMINDER-003).
ReminderDigest? reminderDigestOf(List<ReminderDeckWorkload> workloads) {
  final due = [
    for (final workload in workloads)
      if (workload.dueCount > 0) workload,
  ]..sort(compareReminderDecks);
  if (due.isEmpty) return null;
  final top = due.first;
  return ReminderDigest(
    deckName: top.name,
    dueCount: top.dueCount,
    otherDeckCount: due.length - 1,
  );
}
