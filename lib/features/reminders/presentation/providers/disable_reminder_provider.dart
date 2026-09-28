import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/disable_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'disable_reminder_provider.g.dart';

/// Disable (UC-REMINDER-001 A2) as screen 24 runs it, through the gate.
@riverpod
Future<Outcome<void, ReminderRejection>> Function() disableReminder(Ref ref) {
  final disable = DisableReminderUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return () => gate.run(disable.call);
}
