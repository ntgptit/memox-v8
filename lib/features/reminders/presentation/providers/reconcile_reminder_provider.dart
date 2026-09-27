import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/usecases/reconcile_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reconcile_reminder_provider.g.dart';

/// Reconcile (UC-REMINDER-001 step 6) as the app runs it: through the gate,
/// so it never interleaves with an Enable or a Disable (BE-B5b).
@riverpod
Future<Outcome<DateTime?, ReminderRejection>> Function() reconcileReminder(
  Ref ref,
) {
  final reconcile = ReconcileReminderUseCase(
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderPlatformRepositoryProvider),
    ref.watch(dayClockProvider),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return () => gate.run(reconcile.call);
}
