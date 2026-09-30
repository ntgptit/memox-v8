import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/reminders/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_preview_digest_provider.g.dart';

/// Screen 24's "What it says": what the notification would say now, read
/// once when the screen opens, as the notification reads once when it fires
/// (BR-REMINDER-003, BR-REMINDER-005). Null when nothing is due. No use
/// case: one read through an existing domain function (critique 2026-09-30
/// part 1, spec §5.5).
@riverpod
Future<ReminderDigest?> reminderPreviewDigest(Ref ref) async {
  final now = ref.watch(dayClockProvider).now();
  final workloads = await ref
      .watch(reminderWorkloadRepositoryProvider)
      .rootWorkloads(now: now, startOfToday: startOfLocalDay(now));
  return reminderDigestOf(workloads);
}
