import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminders/domain/usecases/deliver_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deliver_reminder_use_case_provider.g.dart';

/// What the alarm runs in the background (UC-REMINDER-001 step 4). Not
/// gated: it runs in its own isolate and reads the settings at fire time
/// (reminders spec D12, §14).
@riverpod
DeliverReminderUseCase deliverReminderUseCase(Ref ref) =>
    DeliverReminderUseCase(
      ref.watch(settingsRepositoryProvider),
      ref.watch(reminderWorkloadRepositoryProvider),
      ref.watch(reminderPlatformRepositoryProvider),
      ref.watch(dayClockProvider),
    );
