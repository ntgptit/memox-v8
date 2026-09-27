/// Why a reminder action did not do what was asked (ADR-011 D6). The
/// reminder screen shows each as a state of its own (UC-REMINDER-001).
enum ReminderRejection {
  /// This platform has no reminders (BR-REMINDER-012, E2).
  unsupported,

  /// The person refused the notification permission; nothing was saved or
  /// scheduled (BR-REMINDER-011, E1).
  permissionDenied,

  /// The minute is outside 0 to 1439 (BR-REMINDER-002).
  minuteOutOfRange,

  /// The platform refused to schedule; the stored reminder is as it was
  /// (E3).
  couldNotSchedule,

  /// The platform refused to cancel. When the reminder was being turned off,
  /// the settings are off already: only the pending reminder may remain
  /// (E6).
  couldNotCancel,

  /// The platform refused to show the digest. Only a delivery meets it.
  couldNotShow,
}
