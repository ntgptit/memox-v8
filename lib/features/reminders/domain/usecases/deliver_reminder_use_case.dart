import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_fire_report_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_time_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

/// UC-REMINDER-001 step 4: what runs when the reminder fires, from the
/// platform's background callback (BE-B5b). It reads the settings and the
/// workload again, at fire time (BR-REMINDER-003), shows at most one digest
/// a local day (BR-REMINDER-004) and schedules the next fire. The only write
/// is the last delivery (reminders spec D16).
///
/// The report holds typed reasons and counts only (BR-REMINDER-005).
final class DeliverReminderUseCase {
  const DeliverReminderUseCase(
    this._settings,
    this._workloads,
    this._platform,
    this._clock,
  );

  final SettingsRepository _settings;
  final ReminderWorkloadRepository _workloads;
  final ReminderPlatformRepository _platform;
  final DayClock _clock;

  Future<ReminderFireReport> call() async {
    if (await _platform.capability() == ReminderCapability.unsupported) {
      return const ReminderFireReport(outcome: ReminderFireOutcome.unsupported);
    }
    final ReminderSnapshot snapshot;
    try {
      snapshot = await _settings.reminderSnapshot();
    } on Failure {
      return const ReminderFireReport(
        outcome: ReminderFireOutcome.settingsUnreadable,
      );
    }
    final now = _clock.now();
    final check = reminderFireCheckOf(
      reminder: snapshot.reminder,
      now: now,
      lastDeliveredAt: snapshot.lastDeliveredAt,
    );
    return switch (check) {
      ReminderFireCheck.disabled => const ReminderFireReport(
        outcome: ReminderFireOutcome.disabled,
      ),
      ReminderFireCheck.beforeReminderTime => _skipped(
        ReminderFireOutcome.beforeReminderTime,
        snapshot,
        now,
      ),
      ReminderFireCheck.alreadyDeliveredToday => _skipped(
        ReminderFireOutcome.alreadyDeliveredToday,
        snapshot,
        now,
      ),
      ReminderFireCheck.due => _deliver(snapshot, now),
    };
  }

  Future<ReminderFireReport> _deliver(
    ReminderSnapshot snapshot,
    DateTime now,
  ) async {
    final List<ReminderDeckWorkload> workloads;
    try {
      workloads = await _workloads.rootWorkloads(
        now: now,
        startOfToday: startOfLocalDay(now),
      );
    } on Failure {
      return _skipped(ReminderFireOutcome.workloadUnreadable, snapshot, now);
    }
    final digest = reminderDigestOf(workloads);
    if (digest == null) {
      return _skipped(ReminderFireOutcome.nothingDue, snapshot, now);
    }
    final shown = await _platform.show(
      digest: digest,
      language: snapshot.language,
    );
    if (shown case Rejected()) {
      return _skipped(ReminderFireOutcome.couldNotShow, snapshot, now);
    }
    return ReminderFireReport(
      outcome: ReminderFireOutcome.delivered,
      dueCount: digest.dueCount,
      otherDeckCount: digest.otherDeckCount,
      isRecorded: await _recorded(now),
      nextAt: await _scheduleNext(snapshot, now, deliveredAt: now),
    );
  }

  /// A fire that showed nothing: the day stays open, and the next fire is
  /// scheduled.
  Future<ReminderFireReport> _skipped(
    ReminderFireOutcome outcome,
    ReminderSnapshot snapshot,
    DateTime now,
  ) async => ReminderFireReport(
    outcome: outcome,
    nextAt: await _scheduleNext(
      snapshot,
      now,
      deliveredAt: snapshot.lastDeliveredAt,
    ),
  );

  /// Records the delivery at [at]. A record that fails is reported, not
  /// thrown: the digest is on the screen already.
  Future<bool> _recorded(DateTime at) async {
    try {
      await _settings.recordReminderDelivered(at: at);
      return true;
    } on Failure {
      return false;
    }
  }

  /// The next fire, scheduled; null when the platform refused it.
  Future<DateTime?> _scheduleNext(
    ReminderSnapshot snapshot,
    DateTime now, {
    required DateTime? deliveredAt,
  }) async {
    final nextAt = nextReminderAt(
      now: now,
      minuteOfDay: snapshot.reminder.minuteOfDay,
      lastDeliveredAt: deliveredAt,
    );
    return switch (await _platform.schedule(at: nextAt)) {
      Ok() => nextAt,
      Rejected() => null,
    };
  }
}
