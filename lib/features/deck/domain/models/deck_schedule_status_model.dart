/// Where a deck's reviews stand today (BR-STUDY-067): derived on read, never
/// stored.
enum DeckScheduleStatus {
  notDue,
  dueToday,
  overdue;

  /// From the `due_at` of the subtree's oldest Due card (null when none is
  /// Due) and the start of the local day.
  static DeckScheduleStatus of(DateTime? oldestDueAt, DateTime startOfToday) {
    if (oldestDueAt == null) return notDue;
    if (oldestDueAt.isBefore(startOfToday)) return overdue;
    return dueToday;
  }

  /// The local day boundaries completed between the oldest Due card's
  /// `due_at` and today; 0 when nothing is overdue. Counted on calendar
  /// dates: hours / 24 is wrong across a clock change (BR-STUDY-067).
  static int overdueDays(DateTime? oldestDueAt, DateTime startOfToday) {
    if (oldestDueAt == null || !oldestDueAt.isBefore(startOfToday)) return 0;
    final due = oldestDueAt.toLocal();
    final today = startOfToday.toLocal();
    return DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(due.year, due.month, due.day)).inDays;
  }
}
