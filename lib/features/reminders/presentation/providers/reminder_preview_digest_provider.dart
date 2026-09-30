import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/reminders/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/usecases/read_reminder_preview_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_preview_digest_provider.g.dart';

/// Screen 24's "What it says", read once when the screen opens through
/// [ReadReminderPreviewUseCase]. Null when nothing is due.
@riverpod
Future<ReminderDigest?> reminderPreviewDigest(Ref ref) =>
    ReadReminderPreviewUseCase(
      ref.watch(reminderWorkloadRepositoryProvider),
      ref.watch(dayClockProvider),
    )();
