import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/enable_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'enable_reminder_provider.g.dart';

/// Enable (UC-REMINDER-001 steps 2-3) as screen 24 runs it: through the
/// gate, so it never interleaves with another reminder operation (§14).
@riverpod
Future<Outcome<DateTime, ReminderRejection>> Function(int minuteOfDay)
enableReminder(Ref ref) {
  final enable = EnableReminderUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
    ref.watch(dayClockProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return (minuteOfDay) => gate.run(() => enable(minuteOfDay: minuteOfDay));
}
