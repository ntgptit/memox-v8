import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

/// The cards due when the reminder fires. The one implementation is
/// `ReminderWorkloadRepositoryImpl` (data layer); the contract exists for
/// ADR-010's reason: domain stays framework-free and tests substitute a fake.
abstract interface class ReminderWorkloadRepository {
  /// Every root deck outside the Trash with the cards of its whole tree due
  /// at [now], split at [startOfToday] into overdue and due today
  /// (BR-STUDY-068), read once, at fire time (BR-REMINDER-003). A database
  /// error leaves as its `Failure`.
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  });
}
