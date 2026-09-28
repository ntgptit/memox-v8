import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/domain/usecases/watch_reminder_use_case.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_status_provider.g.dart';

/// Screen 24's data (UC-REMINDER-001 step 1): the platform's capability and
/// the stored reminder, again after every save; a read that fails is E7.
@riverpod
Stream<ReminderStatus> reminderStatus(Ref ref) => WatchReminderUseCase(
  ref.watch(settingsRepositoryProvider),
  ref.watch(reminderPlatformRepositoryProvider),
)();
