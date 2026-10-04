import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/change_reminder_time_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'change_reminder_time_provider.g.dart';

/// Change time (UC-REMINDER-001 A1) as screen 24 runs it, through the gate.
@riverpod
Future<Outcome<DateTime?, ReminderRejection>> Function(int minuteOfDay)
changeReminderTime(Ref ref) {
  final change = ChangeReminderTimeUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
    ref.watch(dayClockProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return (minuteOfDay) => gate.run(() => change(minuteOfDay: minuteOfDay));
}
