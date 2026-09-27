/// What a fire of the reminder ended in (reminders spec §9).
enum ReminderFireOutcome {
  /// The digest was shown.
  delivered,

  /// The platform has no reminders.
  unsupported,

  /// The settings could not be read: nothing is shown and nothing is
  /// rescheduled, and the next reconcile restores the schedule (spec D16).
  settingsUnreadable,

  /// The reminder is off: a fire left over from before, not rescheduled.
  disabled,

  /// The local time has not reached the reminder's minute (spec D12).
  beforeReminderTime,

  /// The local day already had its digest (BR-REMINDER-004).
  alreadyDeliveredToday,

  /// The workload could not be read: nothing is shown (UC-REMINDER-001 E5).
  workloadUnreadable,

  /// No card is due (BR-REMINDER-003; UC-REMINDER-001 A3, A4).
  nothingDue,

  /// The platform refused to show the digest; nothing is recorded.
  couldNotShow,
}

/// A fire of the reminder, told in typed reasons and counts only, so that a
/// log line built from it can never carry a deck name, a card or the
/// digest's text (BR-REMINDER-005).
final class ReminderFireReport {
  const ReminderFireReport({
    required this.outcome,
    this.dueCount = 0,
    this.otherDeckCount = 0,
    this.isRecorded = false,
    this.nextAt,
  });

  final ReminderFireOutcome outcome;

  /// The digest's two counts; 0 unless it was delivered.
  final int dueCount;
  final int otherDeckCount;

  /// Whether the delivery was recorded; false unless it was delivered.
  final bool isRecorded;

  /// The next fire; null when nothing was scheduled.
  final DateTime? nextAt;
}
