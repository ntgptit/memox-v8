import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/di/reminder_operation_gate_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/usecases/reconcile_reminder_use_case.dart';
import 'package:memox/features/reminders/domain/usecases/reset_app_options_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_app_options_provider.g.dart';

/// Reset app options (UC-SETTINGS-001 A3) as `app/` hands it to screen 23:
/// through the gate, so the reset and its reconcile never interleave with
/// another reminder operation (DEV-218).
@riverpod
Future<Outcome<void, SettingsRejection>> Function() resetAppOptions(Ref ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final reset = ResetAppOptionsUseCase(
    ResetAppSettingsUseCase(settings),
    ReconcileReminderUseCase(
      settings,
      ref.watch(reminderPlatformRepositoryProvider),
      ref.watch(dayClockProvider),
    ),
  );
  final gate = ref.watch(reminderOperationGateProvider);
  return () => gate.run(reset.call);
}
