import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

/// Screen 24's "What it says": what the notification would say now, read
/// once, as the notification reads once when it fires (BR-REMINDER-003,
/// BR-REMINDER-005). Null when nothing is due. A database error leaves as
/// its `Failure` (critique 2026-09-30 part 1; ADR-011 D4/D5).
final class ReadReminderPreviewUseCase {
  const ReadReminderPreviewUseCase(this._workloads, this._clock);

  final ReminderWorkloadRepository _workloads;
  final DayClock _clock;

  Future<ReminderDigest?> call() async {
    final now = _clock.now();
    final workloads = await _workloads.rootWorkloads(
      now: now,
      startOfToday: startOfLocalDay(now),
    );
    return reminderDigestOf(workloads);
  }
}
